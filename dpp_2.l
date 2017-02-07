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

#include "stringHashMap.h"

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

char actDefName[128];

stringHashMap map;

int line_num;


//struct entry entryRead;

%}


%x comment
%x definition

%%

"//"[^\n]* ;

"/*"  BEGIN(comment);
<comment>[^*\n]* 
<comment>"*"+[^*/\n]*
<comment>\n   {printf("\n");}
<comment>"*"+"/"  {BEGIN(INITIAL);}
	
<comment><<EOF>> {
	ReportError::UntermComment();
	yyterminate();
}

\#define[ \t][A-Z]*	{
		BEGIN(definition);
		
		strcpy(actDefName, yytext+8);
		}

<definition>[^\n].*	{
		BEGIN(INITIAL);

		struct entry entryRead, *entryFound;

		char* key = actDefName;
		entryRead.hash = djb2(&key);
		strcpy(entryRead.line, yytext);

		entryFound = &entryRead;
		
		HashMapPutResult result = stringHashMapPut(&map, &entryFound, HMDR_FAIL);

		}

\#[A-Z]*	{
		struct entry entryRead, *entryFound;

		char* key = yytext+1;

		entryRead.hash = djb2(&key);
		
		entryFound = &entryRead;
		
		bool result = stringHashMapFind(&map, &entryFound);
			
		if(result) {
			printf("%s", entryFound->line);
		}else{
			//ReportError::InvalidDirective(line_num);
			printf("%s", yytext+1);
		}

		}
		
\#[a-z]* {
			ReportError::InvalidDirective(line_num);
		}
\n {
	printf("\n");
	++line_num;
}
%%


#define ENTRY_CMP(left, right) left->hash == right->hash
#define ENTRY_HASH(entry) entry->hash


DECLARE_HASHMAP(stringHashMap, ENTRY_CMP, ENTRY_HASH, free, realloc)

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
