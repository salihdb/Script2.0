/*
Rhodeus Script (c) by Talha Zekeriya Durmuş

Rhodeus Script is licensed under a
Creative Commons Attribution-NoDerivs 3.0 Unported License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by-nd/3.0/>.
*/

module main;
import std.stdio, std.file, std.datetime;
import lexer, parser;
void main(string[] argv){
	auto lexer = new Lexer();	
	lexer.load("2 + 2\n a += a++ + 2");
	auto lexed = lexer.lexy();
	writeln(lexed);
	while(1){}
	return;
}
