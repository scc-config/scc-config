{
	const morphism = options.morphism

	function convertCodePoint(str, line, col) {
		var num = parseInt("0x" + str);

		if (
			!isFinite(num) ||
			Math.floor(num) != num ||
			num < 0 ||
			num > 0x10FFFF ||
			(num > 0xD7FF && num < 0xE000)
		) {
			genError("Invalid Unicode escape code: " + str, line, col);
		} else {
			return fromCodePoint(num);
		}
	}
	function fromCodePoint() {
		var MAX_SIZE = 0x4000;
		var codeUnits = [];
		var highSurrogate;
		var lowSurrogate;
		var index = -1;
		var length = arguments.length;
		if (!length) {
			return '';
		}
		var result = '';
		while (++index < length) {
			var codePoint = Number(arguments[index]);
			if (codePoint <= 0xFFFF) { // BMP code point
				codeUnits.push(codePoint);
			} else { // Astral code point; split in surrogate halves
				// http://mathiasbynens.be/notes/javascript-encoding#surrogate-formulae
				codePoint -= 0x10000;
				highSurrogate = (codePoint >> 10) + 0xD800;
				lowSurrogate = (codePoint % 0x400) + 0xDC00;
				codeUnits.push(highSurrogate, lowSurrogate);
			}
			if (index + 1 == length || codeUnits.length > MAX_SIZE) {
				result += String.fromCharCode.apply(null, codeUnits);
				codeUnits.length = 0;
			}
		}
		return result;
	}
	function commute(selector, morph){
		return function(store){
			if(selector.match(store.coget())){
				store.cofocus(selector.cofocus).ap(morph)
			}
		}
	}
}


start = array_sep* morphs:seqPart* array_sep* { return morphism.join(morphs) }

// morphs
morph
	= it:string  { return morphism.put(it) }
	/ it:float   { return morphism.put(it) }
	/ it:integer { return morphism.put(it) }
	/ it:boolean { return morphism.put(it) }
	/ selected
	/ focused
	/ array
	/ object
	/ sequence

// focusing
focus_path
	= parts:dot_ended_foci_part+ name:foci_part    { return parts.concat(name) }
	/ name:foci_part                                    { return [name] }

foci_part = key / quoted_key

dot_ended_foci_part
	= name:key S* '.' S*               { return name }
	/ name:quoted_key S* '.' S*        { return name }

focused
	= focus_path:focus_path S* op:ASSIGN_OPERATOR S* m:morph {
		return morphism.deepFocus(focus_path, morphism.opmap[op](m))
	}
key
	= chars:ASCII_BASIC+ { return chars.join('') }
quoted_key
	= node:double_quoted_single_line_string { return node }
	/ node:single_quoted_single_line_string { return node }

// selecting
selected
	= selector:selector S* (':' S*)? morph:morph { return commute({match : selector.match, cofocus: lens => lens}, morph) }
	/ selector:selector S* '>' S* morph:morph { return commute(selector, morph) }
selector
	= 'if' S+ key:key { return { match : cot => cot && cot[key], cofocus : lens => lens.focus(key) } }

// composite
array_sep
	= S / NL / comment
array
	= '[' array_sep* morphs:seqPart* array_sep* ']' { 
		return l => l.pad([]).ap(morphism.join(morphs.map((m, j) => s => m(s.focus(l => l.focus(j)))))) 
	}

object
	= '{' array_sep* morphs:seqPart* array_sep* '}' { return l => l.pad({}).ap(morphism.join(morphs)) }

sequence
	= '(' array_sep* morphs:seqPart* array_sep* ')' { return morphism.join(morphs) }

seqPart
	= array_sep* a:morph array_sep* (';' / NL) array_sep*     { return a }
	/ array_sep* a:morph                                      { return a }

// primitives
string
	= double_quoted_multiline_string
	/ double_quoted_single_line_string
	/ single_quoted_multiline_string
	/ single_quoted_single_line_string

double_quoted_multiline_string
	= '"""' NL? chars:multiline_string_char* '"""'  { return chars.join('') }
double_quoted_single_line_string
	= '"' chars:string_char* '"'                    { return chars.join('') }
single_quoted_multiline_string
	= "'''" NL? chars:multiline_literal_char* "'''" { return chars.join('') }
single_quoted_single_line_string
	= "'" chars:literal_char* "'"                   { return chars.join('') }

string_char
	= ESCAPED / (!'"' char:. { return char })

literal_char
	= (!"'" char:. { return char })

multiline_string_char
	= ESCAPED / multiline_string_delim / (!'"""' char:. { return char })

multiline_string_delim
	= '\\' NL NLS*                        { return '' }

multiline_literal_char
	= (!"'''" char:. { return char })

float
	= left:(float_text / integer_text) ('e' / 'E') right:integer_text { return parseFloat(left + 'e' + right) }
	/ text:float_text                                                 { return parseFloat(text) }

float_text
	= '+'? digits:(DIGITS '.' DIGITS)     { return digits.join('') }
	/ '-'  digits:(DIGITS '.' DIGITS)     { return '-' + digits.join('') }

integer
	= text:integer_text                   { return parseInt(text, 10) }

integer_text
	= '+'? digits:DIGIT+ !'.'             { return digits.join('') }
	/ '-'  digits:DIGIT+ !'.'             { return '-' + digits.join('') }

boolean
	= 'true'                              { return true }
	/ 'false'                             { return false }


// lexicals
ASSIGN_OPERATOR  = '=' / '<-' / ':=' / ':' / '++=' / '+=' / '-=' / '*=' / '/=' / '%='
comment          = '#' (!(NL / EOF) .)*
S                = [ \t]
NL               = "\n" / "\r" "\n"
NLS              = NL / S
EOF              = !.
HEX              = [0-9a-f]i
DIGIT            = DIGIT_OR_UNDER
DIGIT_OR_UNDER   = [0-9]
								 / '_'                  { return "" }
ASCII_BASIC      = [A-Za-z0-9_\-]
DIGITS           = d:DIGIT_OR_UNDER+    { return d.join('') }
ESCAPED          = '\\"'                { return '"'  }
								 / '\\\\'               { return '\\' }
								 / '\\b'                { return '\b' }
								 / '\\t'                { return '\t' }
								 / '\\n'                { return '\n' }
								 / '\\f'                { return '\f' }
								 / '\\r'                { return '\r' }
								 / ESCAPED_UNICODE
ESCAPED_UNICODE  = "\\U" digits:(HEX HEX HEX HEX HEX HEX HEX HEX) { return convertCodePoint(digits.join('')) }
								 / "\\u" digits:(HEX HEX HEX HEX) { return convertCodePoint(digits.join('')) }