module rexlang

import strings

pub struct ExecutionFlags {
pub:
	verbose bool
}

pub fn interpret(code string, input string, exec_flags ExecutionFlags) !string {
	rules := compile(code)!
	mut cur := input

	outer: for {
		for rule in rules {
			match_result := captures(rule.pattern.runes(), cur.runes()) or {
				continue
			}

			mut sb := strings.new_builder(rule.result.len)
			for token in rule.result {
				sb.write_string(match token {
					i32 { match_result[token - 1] }
					rune { token.str() }
				})
			}

			new_cur := sb.str()

			if exec_flags.verbose {
				println('[info] ${cur} -> ${new_cur} (Rule ${rule.str()})')
			}

			cur = new_cur
			if rule.is_terminal {
				return cur
			}
			continue outer
		}
		return cur
	}
	return error('Unreachable code')
}

type Token = rune | i32

type Result = []Token

struct Rule {
	pattern     string
	result      Result
	is_terminal bool
}

fn (rule Rule) str() string {
	sep := if rule.is_terminal { term_rule_sep } else { reg_rule_sep }
	return '${rule.pattern} ${sep} ${rule.result.str()}'
}

fn (res Result) str() string {
	mut sb := strings.new_builder(res.len)

	for token in res {
		match token {
			rune { sb.write_rune(token) }
			i32 { sb.write_string('[${token}]') }
		}
	}
	return sb.str()
}

const term_rule_sep = '!>'
const reg_rule_sep = '->'

fn split_line_pattern_result(line string) !(string, string, bool) {
	mut a := 0
	mut b := 0
	mut is_terminal := false

	term_rule_marker_idx := line.index(term_rule_sep)
	if term_rule_marker_idx == none {
		reg_rule_marker_idx := line.index(reg_rule_sep)
		if reg_rule_marker_idx == none {
			return error("expected pattern-result separator: '${reg_rule_sep}' or '${term_rule_sep}'")
		}
		a = reg_rule_marker_idx
		b = a + reg_rule_sep.len
	} else {
		is_terminal = true
		a = term_rule_marker_idx
		b = a + term_rule_sep.len
	}

	pattern := line[..a]
	if !pattern.is_blank() {
		if !line[a - 1].is_space() {
			return error("space between pattern and '${reg_rule_sep}' or '${term_rule_sep}' is required, " +
				'if the pattern is not empty')
		}
	}
	result := line[b..]
	if !result.is_blank() {
		if !line[b].is_space() {
			return error("space between '${reg_rule_sep}' or '${term_rule_sep}' and result is required, " +
				'if the result is not empty')
		}
	}
	return pattern.trim_space(), result.trim_space(), is_terminal
}

fn parse_result(result_str string, matchers_count int) !Result {
	mut result := Result{}
	rs := result_str.runes()

	for i := 0; i < rs.len; i++ {
		if rs[i] == `[` {
			if matchers_count == 0 {
				return error('unexpected start of placeholder in result with no matchers in pattern')
			}
			s := i + 1
			for i < rs.len && rs[i] != `]` {
				i++
			}
			if i >= rs.len {
				return error("expected corresponding closing ']'")
			}
			e := i
			number := i32(rs[s..e].string().parse_int(10, 32) or {
				return error("expected number between '[' and ']'")
			})
			if number <= 0 {
				return error("placeholder's number must be greater than 0")
			}
			if number > matchers_count {
				return error("placeholder's number can't be greater than number of matchers in pattern (${matchers_count})")
			}
			result << number
			continue
		}
		result << rs[i]
	}
	return result
}

fn compile(code string) ![]Rule {
	mut rules := []Rule{}

	for ind, line_bytes in code.split_into_lines() {
		if line_bytes.starts_with('#') || line_bytes.is_blank() {
			continue
		}

		pattern, result_str, is_terminal := split_line_pattern_result(line_bytes) or {
			return error('Line ${ind + 1}: ${err.msg()}')
		}

		matchers_count := pattern.count('*') + pattern.count('?')
		result := parse_result(result_str, matchers_count) or {
			return error('Line ${ind + 1}: ${err.msg()}')
		}

		rules << Rule{
			pattern:     pattern
			result:      result
			is_terminal: is_terminal
		}
	}

	return rules
}

// TODO: compilation and IR
