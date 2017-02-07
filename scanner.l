/* File:  scanner.l
 * ----------------
 * Lex inupt file to generate the scanner for the compiler.
 */

%{

#include <string.h>
#include "scanner.h"
#include "utility.h" // for PrintDebug()
#include "errors.h"

YYSTYPE yylval;  // manually declared for pp1, later Yacc provides

struct yyltype yylloc; // manually dclared for pp1, later Yacc provides

int line_num;

int first_col;

int last_col;

static void DoBeforeEachAction(); 
#define YY_USER_ACTION DoBeforeEachAction();

%}
DEC_DIGIT [0-9]
HEX_DIGIT [0-9a-fA-F]
LETTER [a-zA-Z]

%x string_constant
%%            

void        return T_Void;
int         return T_Int;
double      return T_Double;
bool        return T_Bool;
string      return T_String;
class       return T_Class;
interface   return T_Interface;
null        return T_Null;
this        return T_This;
extends     return T_Extends;
implements  return T_Implements;
for         return T_For;
while       return T_While;
if          return T_If;
else        return T_Else;
return      return T_Return;
break       return T_Break;
New         return T_New;
NewArray    return T_NewArray;

"+"  return '+';
"-"  return '-';
"*"  return '*';
"/"  return '/';
"%"  return '%';
"<"  return '<';
">"  return '>';
"="  return '=';
"!"  return '!';
";"  return ';';
","  return ',';
"."  return '.';
"["  return '[';
"]"  return ']';
"("  return '(';
")"  return ')';
"{"  return '{';
"}"  return '}';

"<=" return T_LessEqual;
">=" return T_GreaterEqual;
"==" return T_Equal;
"!=" return T_NotEqual;
"&&" return T_And;
"||" return T_Or;
"[]" return T_Dims;

0[xX]{HEX_DIGIT}+|{DEC_DIGIT}+ { // Hex Digit
	yylval.integerConstant = strtol(yytext, NULL, 0);
	return T_IntConstant;
}

{DEC_DIGIT}+\.{DEC_DIGIT}*([eE][-+]?{DEC_DIGIT}+)? { // Double
	yylval.doubleConstant = strtod(yytext, NULL);
	return T_DoubleConstant;
}

true|false { // Boolean
	yylval.boolConstant = strcmp(yytext, "true") == 0 ? true : false;
	return T_BoolConstant;
}

\"[^"\n]*\"? { // String constant
	yylval.stringConstant = strdup(yytext);

	size_t len = strlen(yytext);
	if (len == 1 || yytext[len - 1] != '"')
		ReportError::UntermString(&yylloc, yytext);
	else
		return T_StringConstant;
}

{LETTER}({LETTER}*|{DEC_DIGIT}*|_*)* { // Identifier
	strncpy(yylval.identifier, yytext, MaxIdentLen);
	yylval.identifier[MaxIdentLen] = '\0';
	if (strlen(yytext) > MaxIdentLen)
		ReportError::LongIdentifier(&yylloc, yytext);
	return T_Identifier;
}

 /* Skip over white space */
<INITIAL>[ \t\n] {
	if (strcmp(yytext, "\n") == 0) {
		++line_num;
		first_col = 1;
		last_col = 1;
	}
}

. {
	ReportError::UnrecogChar(&yylloc, yytext[0]);
}

%%


/* Function: InitScanner
 * ---------------------
 * This function will be called before any calls to yylex().  It is designed
 * to give you an opportunity to do anything that must be done to initialize
 * the scanner (set global variables, configure starting state, etc.). One
 * thing it already does for you is assign the value of the global variable
 * yy_flex_debug that controls whether flex controls debugging information
 * about each token and what rule was matched. If set to false, no information
 * is printed. Setting it to true will give you a running trail that might
 * be helpful when debugging your scanner. Please be sure the variable is
 * set to false when submitting your final version.
 */
void InitScanner() {
    PrintDebug("lex", "Initializing scanner");
    yy_flex_debug = false;
    /* Initialize the global line number counter. The first line in the source
     * input is labeled as line 1.
     */
    line_num = 1;
    /* Initialize the global starting and ending column counters. The first
     * column in each source line is labeled as column 1
     */
    first_col = 1;
    last_col = 1;
}


/* Function: DoBeforeEachAction()
 * ------------------------------
 * This function is installed as the YY_USER_ACTION. This is a place
 * to group code common to all actions.
 */
static void DoBeforeEachAction() {
	first_col = last_col;
	last_col += strlen(yytext);

	yylloc.first_line = yylloc.last_line = line_num;
	yylloc.first_column = first_col;
	yylloc.last_column = last_col - 1;

}
