grammar SciscoGrammer;

options {
  language = Java;
}

@header {
  package org.scisco.grammer;
  import java.util.HashMap;
  import org.scisco.grammer.semantics.*;
  import org.scisco.carver.DPTable;
}

@lexer::header {
  package org.scisco.grammer;
}

@members {
  HashMap memory = new HashMap();

  public String stripQuotes(String str)
  {
    return str.replaceAll("^\"|\"$", "");
  }
}

rule: statement+ EOF;


statement : (capturable
          | hypothesis
          | export
          | store
          | assign | print) SEMICOLON;

capturable : carver | getrule;
hyp_engine : BAYESIAN | FISHERIAN | NEYPEARS;
carv_engine : FILESTRUCT | CONTENTCARV | BIFRAGMENTGAP | HEADFOOT;
output_format  : SVG | XML | TEXT | RAW;
class_type : KNEAREST | DECISION_TREE | VECTOR_SUPPORT;


ALL : 'all';
CHECKSUM : 'checksum';
USING : 'using';
FOREACH : 'FOREACH';
IN : 'in';
BAYESIAN : 'bayesian';
FISHERIAN : 'fisherian';
NEYPEARS : 'neyman-pearson';
HEADFOOT : 'header-footer';
FILESTRUCT : 'file-structure';
CONTENTCARV : 'content-based-carving';
BIFRAGMENTGAP : 'bifragment-gap';
SVG : 'svg';
XML : 'xml';
RAW : 'raw';
LOCATION : 'location';
MEMORY : 'memory';
LOCALDISK : 'localdisk';
GET : 'get';
SOME : 'some';
FROM : 'from' ;
CARV : 'carve';
HYP : 'hyp';
CLASS_TYPE : 'classification_type';
KMEANS : 'k-means';
KNEAREST : 'k-nearest';
DECISION_TREE : 'decision_tree';
TEXT : 'text';
STORE : 'store';
VECTOR_SUPPORT : 'vector_support';
FUZZYKMEANS : 'fuzzykmeans';
CANOPY : 'canopy';
DIRICHLET : 'dirichlet';
FILTER : 'filter';
BY : 'by';
EXPORT : 'export';
AND : 'and';
DFS : 'dfs';
WITH : 'with';
TO : 'to';
AS : 'as';
PRINT : 'print';
SET : 'set';
PATH :'path';
WORDCOUNT:'wordcount';
SUM:'sum';
AGGREGATE : 'aggregate';

storage_engine
  : MEMORY | LOCALDISK | DFS;


cluster
  :   KMEANS | FUZZYKMEANS | CANOPY | DIRICHLET;


agg returns [Token t]: maintype=AGGREGATE (func=WORDCOUNT | func=SUM)
            {
              t = $func;
            };
getrule returns [DPTable dp]: GET (what=TEXT | what=ALL | what=SOME | what=CHECKSUM  | agg{what = $agg.t;}) FROM where=IDENTIFIER (filter_statement)?
          (USING CLASS_TYPE)?
          {
            Select s = (Select)new Select().setMem(memory);
            s.setWhere($where.text).setWhat($what.text);
            s.execute();
          };

hypothesis : HYP STRING USING hyp_engine WITH evidence;


carver returns [DPTable dp]: CARV what=whatrule FROM STRING (USING using=carv_engine)?
          {
            Carver c = (Carver)new Carver(stripQuotes($STRING.text)).setMem(memory);
            c.setEngine($carv_engine.text).setWhat($what.text);

            if($using.text != null){
              c.setUsing($using.text);
            }

            $dp =  c.execute();

          };

store :
  STORE IDENTIFIER IN LOCATION USING storage_engine;

condstatement : FOREACH LPAREN IDENTIFIER AS IDENTIFIER RPAREN statement;

expression returns [Object value]:
               IDENTIFIER
               {
                  $value = memory.get($IDENTIFIER.text);
                  if($value == null){
                    System.err.println("undefined variable " + $IDENTIFIER.text);
                    $value = (Object)new Empty();
                  }
               }
               | DIGIT
               {
                  $value = Integer.parseInt($DIGIT.text);
               }
               | STRING
               {
                  $value = $STRING.text;
               }
               | carver
               {
                  $value = $carver.dp;
               };

assign : (SET PATH)? IDENTIFIER ASSIGN expression
          {
            if($PATH != null){
              HashMap p = (HashMap)memory.get("paths");

              if(p == null){
                p = new HashMap<String, String>();
                p.put($IDENTIFIER.text, stripQuotes((String)$expression.value));
                memory.put("paths", p);
              }
               p.put($IDENTIFIER.text, stripQuotes((String)$expression.value));
            }else{
              Object finalVal;
              if($expression.value instanceof String){
                finalVal = (Object)stripQuotes((String)$expression.value);
              }else{
                finalVal = $expression.value;
              }
              memory.put($IDENTIFIER.text, finalVal);
            }
          };

filter_statement : FILTER BY criteria;

export : EXPORT IDENTIFIER USING storage_engine TO STRING AS output_format;

criteria : IDENTIFIER ASSIGN STRING (AND IDENTIFIER ASSIGN STRING)*;

evidence : STRING (COMMA STRING)*;
whatrule : IDENTIFIER (COMMA IDENTIFIER)*;
print : PRINT expression
      {
        System.out.println($expression.value.toString());
      };


COLON : ':' ;
COMMA : ',' ;
SEMICOLON : ';' ;
QUOTE:'\'';

LPAREN : '(' ;
RPAREN : ')' ;

ASSIGN : '=' ;
EQUAL : '==';
NOTEQUAL1 : '<>' ;
NOTEQUAL2 : '!=' ;
LESSTHANOREQUALTO1 : '<=' ;
LESSTHAN : '<' ;
GREATERTHANOREQUALTO1 : '>=' ;
GREATERTHAN : '>' ;

DIVIDE : '/' ;
PLUS : '+' ;
MINUS : '-' ;
MULTI : '*' ;
MOD : '%' ;

AMPERSAND : '&' ;
TILDE : '~' ;
BITWISEOR : '|' ;
BITWISEXOR : '^' ;

Whitespace
    : (' ' | '\t' | '\n' | '\r' | '\f')+ {$channel=HIDDEN;}
    ;

MultilineComment
    : '/*' (('*' ~ '/')=>'*' | ~ '*')* '*/' {$channel=HIDDEN;}
    ;

SinglelineComment
    : '//'  (('?' ~'>')=>'?' | ~('\n'|'?'))* {$channel=HIDDEN;}
    ;

DIGIT : '0'..'9'+;
LETTER : 'a'..'z' | 'A'..'Z' | '_' | '#' | '@' | '\u0080'..'\ufffe';
IDENTIFIER : ('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'_'|'.')* ;
STRING :   '"' ~'"'* '"';


