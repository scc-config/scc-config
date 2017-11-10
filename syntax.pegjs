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
			if(selector.match(store.coget(), store)){
				store.cofocus(selector.cofocus).ap(morph)
			}
		}
	}
	function enumerated(enumerator, morph){
		return function(store){
			const {key, range:Range, cofocus} = enumerator;
			const cot = store.coget();
			const range = Range(store);
			const recov = cot[key]
			for(let k of range) {
				cot[key] = k;
				store.cofocus(cofocus).ap(morph);
			}
			cot[key] = recov;
		}
	}
	function reflectMorph(m){
		return store => {
			const cot = store.coget();
			if(!cot) return void 0;
			else return store.put(cot[store.fresh().ap(m).get()]);
		}
	}
	function LetMorph(key, m){
		return store => {
			const v = store.fresh().ap(m).get();
			store.cofocus(lens => lens.focus(key)).coput(v);
			return store
		}
	}
}


start = array_sep* morphs:seqPart* array_sep* { return morphism.join(morphs) }

// morphs
morph = focused / directive / bool

// focusing
focus_path
	= parts:dot_ended_foci_part+ name:foci_part    { return parts.concat(name) }
	/ name:foci_part                               { return [name] }

foci_part
	= key
	/ quoted_key
	/ ".(" S* m:expr S* ')' { return s => s.fresh().ap(m).get() }

dot_ended_foci_part = name:foci_part S* '.' S*     { return name }

focused
	= focus_path:focus_path S* op:ASSIGN_OPERATOR S* m:morph {
		return morphism.deepFocus(focus_path, morphism.opmap[op](m))
	}
key
	= chars:ASCII_BASIC+ { return chars.join('') }
quoted_key
	= node:double_quoted_single_line_string { return node }
	/ node:single_quoted_single_line_string { return node }

// directives
directive
	// Common selector directive
	= "if" selector:selector S* (':' S*)? morph:morph {
		return commute({match : selector.match, cofocus: lens => lens}, morph)
	}
	// Focusing selector directive
	/ "if" selector:selector S* ':>' S* morph:morph {
		return commute(selector, morph)
	}
	// Common loop directive
	/ "for" enumerator:enumerator S* (':' S*)? morph:morph {
		return enumerated(Object.assign(enumerator, {cofocus:lens => lens}), morph)
	}
	// Focusing loop directive
	/ "for" enumerator:enumerator S* ':>' S* morph:morph {
		return enumerated(Object.assign(enumerator), morph)
	}
	// Let directive
	/ "let" S* "$" key:key S* "=" S* m:expr {
		return LetMorph(key, m)
	}
	// Section directive
	/ "section" S+ key:key S* (':' S*)? m:morph { return m }

selector
	= S* "(" S* m:expr S* ")" {
		return {
			match: (cot, s)=> s.fresh().ap(m).get(),
			cofocus: lens => lens.focus(key)
		}
	}
	/ S+ key:key {
		return {
			match : cot => cot && cot[key],
			cofocus : lens => lens.focus(key)
		}
	}

enumerator
	= S* "(" S* "$" key:key S* ":" S* m:expr S* ")" {
		return {
			key: key,
			range: store => store.fresh().ap(m).get(),
			cofocus: lens => lens.focus(key)
		}
	}

expr = bool
bool
	= head:comp rears:bool_rear* {
		return rears.reduce(function(sofar,newitem){
			return morphism.popmap[newitem.op](sofar, newitem.item)
		}, head)
	}
bool_rear = S+ op:BOOL_OPERATOR S+ item:comp { return {item, op} }

comp
	= head:struct rears:comp_rear* {
		return rears.reduce(function(sofar,newitem){
			return morphism.popmap[newitem.op](sofar, newitem.item)
		}, head)
	}
comp_rear = S+ op:COMP_OPERATOR S+ item:struct { return {item, op} }

struct
	= head:plus rears:struct_rear* {
		return rears.reduce(function(sofar,newitem){
			return morphism.popmap[newitem.op](sofar, newitem.item)
		}, head)
	}
struct_rear = S+ op:STRUCT_OPERATOR S+ item:plus { return {item, op} }

plus
	= head:mult rears:plus_rear* {
		return rears.reduce(function(sofar,newitem){
			return morphism.popmap[newitem.op](sofar, newitem.item)
		}, head)
	}
plus_rear = S+ op:PLUS_OPERATOR S+ item:mult { return {item, op} }

mult
	= head:part rears:mult_rear* {
		return rears.reduce(function(sofar,newitem){
			return morphism.popmap[newitem.op](sofar, newitem.item)
		}, head)
	}
mult_rear = S+ op:MULT_OPERATOR S+ item:part { return {item, op} }

part
	= head:prime rears:part_rear* {
		return rears.reduce(function(sofar,newitem){
			return morphism.popmap[newitem.op](sofar, newitem.item)
		}, head)
	}
part_rear = S+ op:PART_OPERATOR S+ item:prime { return {item, op} }

prime
	= it:string  { return morphism.put(it) }
	/ it:float   { return morphism.put(it) }
	/ it:integer { return morphism.put(it) }
	/ it:boolean { return morphism.put(it) }
	/ it:reflect { return reflectMorph(it) }
	/ negation
	/ array
	/ object
	/ sequence

// reflection
reflect
	= "$" it:key { return morphism.put(it) }
	/ "$" it:prime { return it }
// negation
negation
	= NOT_OPERATOR it:prime { return morphism.popmap['uni!'](it) }
	/ NEGATE_OPERATOR it:prime { return morphism.popmap['uni-'](it) }

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
	= "0" ("x"/"X") text:hex_text         { return parseInt(text, 16) }
	/ text:integer_text                   { return parseInt(text, 10) }

integer_text
	= '+'? digits:DIGIT+ !'.'             { return digits.join('') }
	/ '-'  digits:DIGIT+ !'.'             { return '-' + digits.join('') }

hex_text
	= digits:HEX+                         { return digits.join('') }

boolean
	= 'true'                              { return true }
	/ 'false'                             { return false }


// lexicals
ASSIGN_OPERATOR  = '=' / '<-' / ':=' / ':' / '++=' / '+=' / '-=' / '*=' / '/=' / '%='
BOOL_OPERATOR    = '/\\' / '\\/'
COMP_OPERATOR    = '==' / '<<@' / '<' / '>' / '<=' / '>=' / '=/='
STRUCT_OPERATOR  = '++' / ':+:'
PLUS_OPERATOR    = '+' / '-'
MULT_OPERATOR    = '*' / '/'
PART_OPERATOR    = '<>'
NOT_OPERATOR     = '!'
NEGATE_OPERATOR  = '-'
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