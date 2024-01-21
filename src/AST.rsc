module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ; 

data AQuestion(loc src = |tmp:///|)
  = GeneralQuestion(AId qId, AType qType, str qText)
  | ComputedQuestion(AId qId, AType qType, AExpr qExpr, str qText)
  | IfThenElse(AExpr condition, list[AQuestion] ifPart, list[AQuestion] elsePart)
  ;

data AExpr(loc src = |tmp:///|)
  = parentheses(AExpr expr)
  | not(AExpr expr)
  | divide(AExpr expr1, AExpr expr2)
  | multiply(AExpr expr1, AExpr expr2)
  | add(AExpr expr1, AExpr expr2)
  | subtract(AExpr expr1, AExpr expr2)
  | less(AExpr expr1, AExpr expr2)
  | gtr(AExpr expr1, AExpr expr2)
  | leq(AExpr expr1, AExpr expr2)
  | geq(AExpr expr1, AExpr expr2)
  | eq(AExpr expr1, AExpr expr2)
  | neq(AExpr expr1, AExpr expr2)
  | and(AExpr expr1, AExpr expr2)
  | or(AExpr expr1, AExpr expr2)
  | ref(AId id)
  | integer(int n)
  | boolean(str boolValue)
  ;

data AId(loc src = |tmp:///|)
  = id(str name);

data AType(loc src = |tmp:///|)
  = \type(str typeName)
  ;