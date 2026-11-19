module rexlang

fn test_captures() {
	res := captures('*abc*'.runes(), 'aaabccc'.runes()) or {
		assert false
	}
	assert res == ['aa', 'cc']
}
