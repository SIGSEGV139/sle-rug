module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id name "{" Question* questions "}"; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question 
  = GeneralQuestion
  | IfThenElse
  ;

// Example: "What was the selling price?" sellingPrice: integer = valueResidue
syntax GeneralQuestion 
  = Str Id ":" Type ( "=" Expr )?
  ;

// Example: if (privateDebt > 0) {"Did you sell a house in 2010?" hasSoldHouse: boolean}
// "else" block is optional
syntax IfThenElse
  = "if" "(" Expr ")" "{" Question* "}" ( "else" "{" Question* "}" )?
  ;


// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr  
  = "(" Expr ")" | "!" Expr
  > non-assoc (Expr "/" Expr | Expr "*" Expr)
  > non-assoc (Expr "+" Expr | Expr "-" Expr)
  > non-assoc (Expr "\<" Expr | Expr "\>" Expr | Expr "\<=" Expr | Expr "\>=" Expr)
  > non-assoc (Expr "==" Expr | Expr "!=" Expr)
  > left Expr "&&" Expr
  > left Expr "||" Expr
  >  Id \ "true" \ "false" // true/false are reserved keywords (only for booleans).
  | Bool
  | Int
  ;

// int, bool
syntax Type 
  = "integer"
  | "boolean"
  ;

// Examples: "Did you enter a loan?" , "Is the number between 15 and 17" , etc.
lexical Str 
  = "\"" ([a-zA-Z0-9_]*|" ")* [?:]? "\""
  ;

lexical Int 
  = [0-9]*
  ;

lexical Bool 
  = "true"
  | "false"
  ;



