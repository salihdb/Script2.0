/*
Rhodeus Script (c) by Talha Zekeriya Durmuş

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/

module lexer;
import std.ascii: isHexDigit, isWhite, isAlphaNum, isAlpha, isDigit;
import std.conv : text, parse;
enum {NUMBER, WORD, STRING, NEWLINE,

// Operators (+,-,*,/,%,|,&,~,^,<<,>>, ||, &&, !, <, <=, >, >=, ==, !=)
PLUS, MINUS, TIMES, DIVIDE, MOD,
OR, AND, NOT, XOR, LSHIFT, RSHIFT,
LOR, LAND, LNOT,
LT, LE, GT, GE, EQ, NE,

// Assignment (=, *=, /=, %=, +=, -=, <<=, >>=, &=, ^=, |=)
EQUALS, TIMESEQUAL, DIVEQUAL, MODEQUAL, PLUSEQUAL, MINUSEQUAL,
LSHIFTEQUAL,RSHIFTEQUAL, ANDEQUAL, XOREQUAL, OREQUAL,

// Increment/decrement (++,--)
PLUSPLUS, MINUSMINUS,

// Structure dereference (->)
ARROW,

// Ternary operator (?)
TERNARY,

// Delimeters ( ) [ ] { } , . ; :
LPAREN, RPAREN,
LBRACKET, RBRACKET,
LBRACE, RBRACE,
COMMA, PERIOD, SEMI, COLON,

// Ellipsis (...)
ELLIPSIS,

// COMMENT /* */
COMMENT
}
class Lexer{
	private Token[] tokens;
	private char[] codes;
	private char* size;
	private ulong line = 1;
	private char[char] chars;
	private LexMap[char] lexmap;

	this(){
		chars= ['n': '\n', 't': '\t', 'r': '\r', 'a': '\a','f': '\f', 'b': '\b', 'v': '\v', '\"': '\"','?': '?', '\\': '\\', '\'': '\''];
		lexmap = [
			'+': LexMap(PLUS, [
				'+': LexMap(PLUSPLUS),
				'=': LexMap(PLUSEQUAL)
			]),
			'-': LexMap(MINUS, [
				'-': LexMap(MINUSMINUS),
				'>': LexMap(ARROW),
				'=': LexMap(MINUSEQUAL)
			]),
			'*': LexMap(TIMES,[
				'=': LexMap(TIMESEQUAL)
			]),
			'/': LexMap(DIVIDE,[
				'=': LexMap(DIVEQUAL),
				'*': LexMap(COMMENT,"*/"),
				'/': LexMap(COMMENT,"\n")
			]),
			'%': LexMap(MOD,[
				'=': LexMap(MODEQUAL)
			]),
			'<': LexMap(LT,[
				'=': LexMap(LE),
				'<': LexMap(LSHIFT, [
					'=': LexMap(LSHIFTEQUAL)
				]),
			]),
			'>': LexMap(GT,[
				'=': LexMap(GE),
				'>': LexMap(RSHIFT,[
					'=': LexMap(RSHIFTEQUAL)
				]),
			]),
			'=': LexMap(EQUALS,[
				'=': LexMap(EQ),
			]),
			'!': LexMap(LNOT,[
				'=': LexMap(NE),
			]),
			'|': LexMap(OR,[
				'|': LexMap(LOR),
				'=': LexMap(OREQUAL)
			]),
			'&': LexMap(AND,[
				'&': LexMap(LAND),
				'=': LexMap(ANDEQUAL)
			]),
			'~': LexMap(NOT),
			'^': LexMap(XOR, [
				'=': LexMap(XOREQUAL)
			]),
			'?': LexMap(TERNARY),
			'(': LexMap(LPAREN),
			')': LexMap(RPAREN),
			'[': LexMap(LBRACKET),
			']': LexMap(RBRACKET),
			'{': LexMap(LBRACE),
			'}': LexMap(RBRACE),
			',': LexMap(COMMA),
			'.': LexMap(PERIOD),
			';': LexMap(SEMI),
			':': LexMap(COLON),
		];


	}
	void load(string S){
		tokens = null;
		codes = cast(char[]) S;
		size = codes.ptr + codes.length;
		line = 1;
	}
	Token[] lexy(){
		auto c = codes.ptr;
		string tmp;
		while (c<size){
			if (isWhite(*c)){
				if (*c=='\n' || *c=='\r'){addToken(NEWLINE,text(*c)); line++;}
			}else if (*c == '\"' || *c == '\''){
				tmp = "";
				int tmpf = 0;
				char wait = *c;
				c++;
			stringStart:
				while (c < size){
					if (*c == wait){
						c++;
						goto stringEnd;
						break;
					}
					else if (*c == '\\') {c++; goto stringSlash;}
					else tmp ~= *c;
					c++;
				}
				goto stringError;

			stringSlash:
				if (c < size){
					int ii = 0, iim = 3;
					if (*c == 'u'){
						iim = 4;
						c++;
					}else if (*c == 'x'){
						iim = 2;
						c++;
					}else if (*c == 'U') { iim = 8; c++; }
					else if (*c in chars){
						tmp ~= chars[*c];
						c++;
						goto stringStart;
					}else{
						tmpf = 0;
						c++;
						tmp ~= *c;
						goto stringStart;
					}
					string tmp2 = "";
					while (c < size && ii < iim){
						if (!isHexDigit(*c)) goto stringStart;
						tmp2 ~= *c;
						c++;
						ii++;
					}
					if (ii != iim) throw new Exception(text(iim-ii)~" adet karakter bekleniyordu!");
					if (iim == 3) tmp ~= parse!int(tmp2, 8);
					else tmp ~= parse!int(tmp2, 16);
					goto stringStart;
				}

			stringError:
				throw new Exception("Beklenen karakter: \"");
			stringEnd:
				addToken(STRING,tmp);
				continue;
     		}else if (isAlpha(*c) || (*c>127 && *c<255) || *c=='_'){
				tmp = "";
				/*				if (c=='r' && c+1<size && (*c=='\'' || *(c+1)=='"' ) ){
				c++;
				StringR();
				return;
				}
				*/
				while (c < size){
					if (isAlphaNum(*c) || (*c>127 && *c<255) || *c=='_'){
						tmp ~= *c;
						c++;
					}else
						break;
				}
				addToken(WORD, tmp);
				continue;
			}else if (isDigit(*c)){
				tmp = "";
				if ((c+1 < size) && *(c+1) == 'x'){
					c+=2;
					goto HexD;
				}else if(*c=='-'){
					tmp ~= "-";
					c++;
				}
				bool dot, e;
				while (c < size){
					if (isDigit(*c)){
						tmp ~= *c;
						c++;
					}else if ('.' == *c && !dot && isDigit(*(c+1))){
						dot = true;
						tmp ~= *c;
						c++;
					}else if (*c == 'e' && !e){
						c++;
						e = true;
						tmp ~= *c;
						if(*c=='-'){
							tmp ~= *c;
							c++;
						}
					}
					else break;
				}
				addToken(NUMBER,tmp);
				continue;
			}else{
				tmp = "";
				LexMap* z = *c in lexmap;
				if(z is null){
					throw new Exception("Beklenmeyn karakter:"~*c);
				}else{
				sl:
					if((*z).finish !is null){
						tmp = "";
						c++;
						atla:
						while(c < size){
							foreach(i,l;(*z).finish){
								if(*(c+i) != l) {tmp ~= *c;c++; goto atla;}
							}
							c+=(*z).finish.length-1;
							goto atla2;
						}
						atla2:
						addToken((*z).name, tmp);
					}else{
						tmp ~= *c;
						LexMap* b= *(c+1) in (*z).map;
						if(b is null) addToken((*z).name,tmp);
						else{
							z = b;
							c++;
							goto sl;
						}
					}
				}
			}
			c++;
			continue;
		HexD:
			tmp = "";
			while (c < size){
				if (isHexDigit(*c)){
					tmp ~= *c;
					c++;
				}else break;
			}
			try{
				addToken(NUMBER, text(parse!int(tmp, 16)));
			}catch(Throwable x){
				throw new Exception("Hata: " ~x.msg);
			}
			c++;
		}
		return tokens;
	}
	void addToken(int type, string val){
		this.tokens ~= Token(line, type, val);
	}
}

struct Token{
	ulong line;
	int typ;
	string value;
}

struct LexMap{
	int name;
	LexMap[char] map;
	string finish;
	this(int name,  LexMap[char] map = null){
		this.name = name;
		this.map = map;
	}
	this(int name, string finish){
		this.name = name;
		this.finish = finish;
	}
}