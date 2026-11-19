module main

import os
import rexlang
import flag

fn main() {
	mut fp := flag.new_flag_parser(os.args)

	fp.application('rexlang')
	fp.version('0.0.1')
	fp.description('CLI tool to interpret rexlang.')
	fp.usage_example("source.rx --input 'input-string' [options...]")
	fp.skip_executable()

	verbose := fp.bool('verbose-execution', `v`, false, 'show full execution process, not only the result')
	exec_flags := rexlang.ExecutionFlags{verbose}

	input_string := fp.string('input', `i`, '', 'program input')
	rest_args := fp.finalize() or { exit(1) }

	if rest_args.len < 1 {
		eprintln('Epected source code file.')
		exit(1)
	}

	// args_rest[0] - source code file
	source_code_text := os.read_file(rest_args[0]) or {
		eprintln("Can not open file '${rest_args[0]}': ${err.msg()}")
		exit(1)
	}

	result := rexlang.interpret(source_code_text, input_string, exec_flags) or {
		eprintln('Execution failed:')
		eprintln('${err.msg()}')
		exit(1)
	}
	println(result)
}
