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
  | ComputedQuestion
  | IfThen
  | IfThenElse
  ;

// Example: "What was the selling price?" sellingPrice: integer
syntax GeneralQuestion 
  = Str label Id name ":" Type type
  ;

// Example: "What was the selling price?" sellingPrice: integer = sellingPrice - privateDebt
syntax ComputedQuestion 
  = Str label Id name ":" Type type "=" Expr expression
  ;

// Example: if (privateDebt > 0) {"Did you sell a house in 2010?" hasSoldHouse: boolean}
syntax IfThen
  = "if" "(" Expr expression ")" "{" Question* questions "}"
  ;

syntax IfThenElse
  = "if" "(" Expr expression ")" "{" Question* questions "}" "else" "{" Question* questions "}"
  ;

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
syntax Expr  
  = "(" Expr ")" | "!" Expr
  > left (Expr "/" Expr | Expr "*" Expr)
  > left (Expr "+" Expr | Expr "-" Expr)
  > left (Expr "\<" Expr | Expr "\>" Expr | Expr "\<=" Expr | Expr "\>=" Expr)
  > left (Expr "==" Expr | Expr "!=" Expr)
  > left Expr "&&" Expr
  > left Expr "||" Expr
  > Id \ "true" \ "false" // true/false are reserved keywords (only for booleans).
  | Bool
  | Int
  | Str
  ;

// int, bool
syntax Type 
  = "integer"
  | "boolean"
  | "string"
  ;

// Examples: "Did you enter a loan?" , "Is the number between 15 and 17" , etc.
lexical Str 
  = "\"" ([a-zA-Z0-9\ ])* [? | :]? "\""
  ;

lexical Int 
  = [0-9]+
  ;

lexical Bool 
  = "true"
  | "false"
  ;



