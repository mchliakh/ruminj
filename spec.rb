=begin
Mikhail Chliakhovski
COMP 442
Assignment 1

Language specification.

Regular expressions specify operators, punctuation and 
reserved words. Order matters: tokens that are supersets 
of other tokens are consumed before their subsets. As all
reserved words are subsets of id tokens, they are consumed 
first, and must be followed by a character that cannot be 
part of an id (eg. whitespace) in order to be recognized. 
Otherwise the scanner assumes an id (eg. "classclass" would 
be parsed as an id).

=end

module Spec
	REG_EXPS = {
		wsp: /\A\s+/,
		comment: /\A\/\/.*$/,
		mlcomment: /\A\/\*.*\*\//m,
		bequal: /\A==/,
		nequal: /\A<>/,
		ltoequal: /\A<=/,
		gtoequal: /\A>=/,
		lthan: /\A</,
		gthan: /\A>/,
		semicol: /\A;/,
		comma: /\A,/,
		period: /\A\./,
		plus: /\A\+/,
		minus: /\A-/,
		mult: /\A\*/,
		divide: /\A\//,
		equal: /\A=/,
		band: /\Aand\s+/,
		bnot: /\Anot\s+/,
		bor: /\Aor\s+/,
		lbracket: /\A\(/,
		rbracket: /\A\)/,
		lcbrace: /\A\{/,
		rcbrace: /\A\}/,
		lsbracket: /\A\[/,
		rsbracket: /\A\]/,
		ifr: /\Aif\s+/,
		thenr: /\Athen\s+/,
		elser: /\Aelse\s+/,
		whiler: /\Awhile\s+/,
		dor: /\Ado\s+/,
		classr: /\Aclass\s+/,
		programr: /\Aprogram\s+/,
		integerr: /\Ainteger\s+/,
		realr: /\Areal\s+/,
		readr: /\Aread\s+/,
		writer: /\Awrite\s+/,
		returnr: /\Areturn\s+/,
		id: /\A[a-zA-Z]\w*/,
		int: /\A[1-9]\d*(?!\.)/,
		num: /\A([1-9]\d*|0)(.\d*[1-9]|.0)?/
	}
end