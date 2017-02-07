/* File:  dpp.l
 * ----------------
 * Lex inupt file to generate the scanner for the compiler.
 */

%{

#include <stdio.h>
#include <string.h>
#include "scanner.h"
#include "utility.h" // for PrintDebug()
#include "errors.h"
#include <map>


static uint64_t djb2(char **entry) {
	unsigned long hash = 5381;
	for(char *c = *entry; *c; ++c) {
		hash = ((hash << 5) + hash) + *c;
	}
	return hash;
}


struct entry {
	uint64_t hash;
	char line[128];
};

std::map<string, string> mapOfWords;

char actDefName[128];


int line_num = 1;


//struct entry entryRead;

%}


%x comment
%x definition
%x c_string
%%

\"[^"\n]*\"? {printf(yytext);} 

"//"[^\n]* ;

"/*"  BEGIN(comment);
<comment>[^*\n]* 
<comment>"*"+[^*/\n]*
<comment>\n   {++line_num;
	printf("\n");}
<comment>"*"+"/"  {BEGIN(INITIAL);}
	
<comment><<EOF>> {
	ReportError::UntermComment();
	yyterminate();
}

\#define[ \t][A-Z ]*	{
		BEGIN(definition);
		
		strcpy(actDefName, yytext+8);
		
		}
		
\#define[ \t][a-z0-9 ]*	{
				
				ReportError::InvalidDirective(line_num);
				}

<definition>[^\n].*	{
		
		BEGIN(INITIAL);
		
		trim(actDefName);
		//printf("Mapping %s with %s", actDefName, yytext);
		mapOfWords.insert(std::make_pair(actDefName, yytext));

		}

\#[A-Z]*	{
		if (mapOfWords.find(yytext+1) != mapOfWords.end())
			printf("%s", mapOfWords.find(yytext+1)->second.c_str());
		else
			ReportError::InvalidDirective(line_num);
		
		}
		
\#[a-z]* {
			ReportError::InvalidDirective(line_num);
		}
\n {
	printf("\n");
	++line_num;
}
%%


int main(int argc, char *argv[])
{
	
	int ch;

	FILE *fp;
	fp=stdin;
  	yylex(); 

  while ((ch = getc(fp)) != EOF)
    putc(ch, stdout);
  return 0;
}
