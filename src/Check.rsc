module Check

import AST;
import Resolve;
import Message; // see standard library

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

Type convertA2Ttype(AType t) {
  switch (t) {
    case \type("integer"): return tint();
    case \type("boolean"): return tbool();
    case \type("string"): return tstr();
    default: return tunknown();
  }
}

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  TEnv tenv = {};
  visit(f) {
    case GeneralQuestion(AId id, AType qType, str label):
      tenv += {<id.src, id.name, label, convertA2Ttype(qType)>};

    case ComputedQuestion(AId id, AType qType, _, str label):
      tenv += {<id.src, id.name, label, convertA2Ttype(qType)>};
  }
  return tenv;
}

set[Message] check(form(_,list[AQuestion] questions), TEnv tenv, UseDef useDef) {
  return {message | question <- questions, message <- check(question, tenv, useDef)};
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};

  switch (q) {
    case GeneralQuestion(AId id, AType qType, str qLabel):
      msgs += checkDuplicateNameAndLabel(id, qType, qLabel, tenv);
    
    case ComputedQuestion(AId id, AType qType, AExpr qExpr, str qLabel):
    {
      msgs += checkDuplicateNameAndLabel(id, qType, qLabel, tenv);

      exprEvaluationMsgs = check(qExpr, tenv, useDef);
      msgs += exprEvaluationMsgs;

      if (exprEvaluationMsgs == {} && typeOf(qExpr, tenv, useDef) != convertA2Ttype(qType)) {
        msgs += error("Types of evaluated value and declared one do not match!", qType.src);
      }
    }
    
    case IfThen(AExpr condition, list[AQuestion] ifPart):
    {
      exprEvaluationMsgs = check(condition, tenv, useDef);
      msgs += exprEvaluationMsgs;
    
      if (exprEvaluationMsgs == {} && typeOf(condition, tenv, useDef) != tbool()) {
        msgs += {error("Guard value does not evaluate to boolean!", condition.src)};
      }

      msgs += checkCondParts(ifPart, tenv, useDef);
    }

    case IfThenElse(AExpr condition, list[AQuestion] ifPart, list[AQuestion] elsePart): 
    {
      exprEvaluationMsgs = check(condition, tenv, useDef);
      msgs += exprEvaluationMsgs;
      
      if (exprEvaluationMsgs == {} && typeOf(condition, tenv, useDef) != tbool()) {
        msgs += {error("Guard value does not evaluate to boolean!", condition.src)};
      }

      msgs += checkCondParts(ifPart, tenv, useDef);
      msgs += checkCondParts(elsePart, tenv, useDef);
    }
  }
      
  return msgs; 
}

set[Message] checkDuplicateNameAndLabel(AId id, AType qType, str qLabel, TEnv tenv) {
  set[Message] msgs = {};
  set[str] encounteredLabels = {};

  for (<loc loc2, str name, str label, Type typee> <- tenv) {
    if (id.src != loc2 && name == id.name && convertA2Ttype(qType) != typee) {
      msgs += { error("Questions with the same name and different types!", id.src) };
    }
    if (id.src != loc2) {
      encounteredLabels += label;
    }
  }

  if (qLabel in encounteredLabels) {
    msgs += { warning("Duplicate labels detected!", id.src) };
  }

  return msgs;
}

set[Message] checkCondParts(list[AQuestion] questions, TEnv tenv, UseDef useDef) {
  return {message | question <- questions, message <- check(question, tenv, useDef)};
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case not(AExpr expr): 
    {
      msgs += check(expr, tenv, useDef);
      if (typeOf(expr, tenv, useDef) != tbool()) {
        msgs += { error("Incompatible expression type!", expr.src) };
      }
    }
    case parentheses(AExpr expr): msgs += check(expr, tenv, useDef);
    case ref(AId x): msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
    case divide(AExpr expr1, AExpr expr2): msgs += checkOperandTypes(expr1, expr2, tenv, useDef, tint(), e.src);
    case multiply(AExpr expr1, AExpr expr2): msgs += checkOperandTypes(expr1, expr2, tenv, useDef, tint(), e.src);
    case add(AExpr expr1, AExpr expr2): msgs += checkOperandTypes(expr1, expr2, tenv, useDef, tint(), e.src);
    case subtract(AExpr expr1, AExpr expr2): msgs += checkOperandTypes(expr1, expr2, tenv, useDef, tint(), e.src);
    case less(AExpr expr1, AExpr expr2): msgs += checkOperandTypes(expr1, expr2, tenv, useDef, tint(), e.src);
    case gtr(AExpr expr1, AExpr expr2): msgs += checkOperandTypes(expr1, expr2, tenv, useDef, tint(), e.src);
    case leq(AExpr expr1, AExpr expr2): msgs += checkOperandTypes(expr1, expr2, tenv, useDef, tint(), e.src);
    case geq(AExpr expr1, AExpr expr2): msgs += checkOperandTypes(expr1, expr2, tenv, useDef, tint(), e.src);
    case eq(AExpr expr1, AExpr expr2): msgs += checkOperandTypes(expr1, expr2, tenv, useDef, tint(), e.src);
    case neq(AExpr expr1, AExpr expr2): msgs += checkOperandTypes(expr1, expr2, tenv, useDef, tint(), e.src);
    case and(AExpr expr1, AExpr expr2): msgs += checkOperandTypes(expr1, expr2, tenv, useDef, tbool(), e.src);
    case or(AExpr expr1, AExpr expr2): msgs += checkOperandTypes(expr1, expr2, tenv, useDef, tbool(), e.src); 
  }
  
  return msgs; 
}

set[Message] checkOperandTypes(AExpr lhs, AExpr rhs, TEnv tenv, UseDef useDef, Type t, loc errLoc) {
  set[Message] msgs = {};

  msgs += check(lhs, tenv, useDef);
  msgs += check(rhs, tenv, useDef);
  
  typeLhs = typeOf(lhs, tenv, useDef);
  typeRhs = typeOf(rhs, tenv, useDef);
  
  if (typeLhs != t && typeLhs != tunknown()) {
    msgs += { error("Incompatible type!", lhs.src) };
  }
  if (typeRhs != t && typeRhs != tunknown()) {
    msgs += { error("Incompatible type!", rhs.src) };
  }
  if (typeLhs != typeRhs) {
    msgs += { error("Types do not match!", errLoc) };
  }
  
  return msgs;
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)):  
      if (<u, loc d> <- useDef, <d, _, _, Type t> <- tenv) {
        return t;
      }
    case parentheses(AExpr expr): return typeOf(expr, tenv, useDef);
    case not(_): return tbool();
    case divide(_, _): return tint();
    case multiply(_, _): return tint();
    case add(_, _): return tint();
    case subtract(_, _): return tint();
    case less(_, _): return tbool();
    case gtr(_, _): return tbool();
    case leq(_, _): return tbool();
    case geq(_, _): return tbool();
    case eq(_, _): return tbool();
    case neq(_, _): return tbool();
    case and(_, _): return tbool();
    case or(_, _): return tbool();
    case integer(_): return tint();
    case boolean(_): return tbool();
    case string(_): return tstr();
  }
  return tunknown(); 
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(id(_, src = loc u)), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 

