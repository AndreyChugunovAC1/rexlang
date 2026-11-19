module rexlang

pub type Captures = []string

pub fn captures(pat []rune, str []rune) ?Captures {
	mut res := expect(str, 0, pat, 0)?

	res.reverse_in_place()
	return res
}

fn expect(str []rune, str_idx int, pat []rune, pat_idx int) ?Captures {
	str_ended := str_idx >= str.len
	pat_ended := pat_idx >= pat.len

	if str_ended && pat_ended { return [] }
	if pat_ended { return none }

	cur_pat_s := pat[pat_idx]

	if cur_pat_s == `*` {
		for i := str_idx; i <= str.len; i++ {
			mut res := expect(str, i, pat, pat_idx + 1) or {
				continue
			}
			res << str[str_idx..i].string()
			return res
		}
		return none
	}

	if str_ended { return none }

	cur_str_s := str[str_idx]

	if cur_pat_s == `?` {
		mut res := expect(str, str_idx + 1, pat, pat_idx + 1)?
		res << cur_str_s.str()
		return res
	}

	if cur_str_s != cur_pat_s {
		return none
	}
	return expect(str, str_idx + 1, pat, pat_idx + 1)
}
