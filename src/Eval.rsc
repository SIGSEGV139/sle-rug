module Eval

import AST;
import Resolve;

/*
 * Implement big-step semantics for QL
 */

// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);

// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)

Value makeDefault(AType t) {
  switch (t) {
    case \type("integer"): return vint(0);
    case \type("boolean"): return vbool(false);
    case \type("string"): return vstr("");
    default: throw "Unsupported type <t>";
  }
}

VEnv initialEnv(AForm f) {
  VEnv venv = ();
  visit (f){
    case GeneralQuestion(AId qid, AType qtype, str _):
      venv += (qid.name : makeDefault(qtype));
    case ComputedQuestion(AId qid, AType qtype, AExpr _, str _):
      venv += (qid.name : makeDefault(qtype));
  }
  return venv;
}


// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  for (AQuestion q2 <- f.questions){
    venv = eval(q2,inp,venv);
  }
  return (venv);
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
  switch (q) {
    case GeneralQuestion(AId qid, AType _, str _): {
      if (inp.question == qid.name)
        venv += (qid.name: inp.\value);
    }
    case  ComputedQuestion(AId qid, AType _, AExpr e, str _): {
      venv += (qid.name: eval(e, venv));
    }
    case IfThenElse(AExpr condition, list[AQuestion] ifPart, list[AQuestion] elsePart): {
      if (eval(condition, venv).b) {
        for (AQuestion q <- ifPart) {
          venv += eval(q, inp, venv);
        }
      } else {
        if (elsePart != []) {
          for (AQuestion q <- elsePart) {
            venv += eval(q, inp, venv);
          }
        }
      }
    } 
    default: throw "Unsupported question <q>";
  }
  return venv;
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case parentheses(AExpr expr) :                return eval(expr, venv);
    case not(AExpr expr) :                        return vbool(!eval(expr,venv).b);
    case divide(AExpr expr1, AExpr expr2) :       return vint(eval(expr1, venv).n / eval(expr2, venv).n);
    case multiply(AExpr expr1, AExpr expr2) :     return vint(eval(expr1, venv).n * eval(expr2, venv).n);
    case add(AExpr expr1, AExpr expr2) :          return vint(eval(expr1, venv).n + eval(expr2, venv).n);
    case subtract(AExpr expr1, AExpr expr2) :     return vint(eval(expr1, venv).n - eval(expr2, venv).n);
    case and(AExpr expr1, AExpr expr2) :          return vbool(eval(expr1, venv).b && eval(expr2, venv).b);
    case or(AExpr expr1, AExpr expr2) :           return vbool(eval(expr1, venv).b || eval(expr2, venv).b);
    case neq(AExpr expr1, AExpr expr2) :          return vbool(eval(expr1, venv) != eval(expr2, venv));
    case eq(AExpr expr1, AExpr expr2) :           return vbool(eval(expr1, venv) == eval(expr2, venv));
    case less(AExpr expr1, AExpr expr2) :         return vbool(eval(expr1, venv).n < eval(expr2, venv).n);
    case gtr(AExpr expr1, AExpr expr2) :          return vbool(eval(expr1, venv).n > eval(expr2, venv).n);
    case geq(AExpr expr1, AExpr expr2) :          return vbool(eval(expr1, venv).n >= eval(expr2, venv).n);
    case leq(AExpr expr1, AExpr expr2) :          return vbool(eval(expr1, venv).n <= eval(expr2, venv).n);

    case ref(id(str x)) :                         return venv[x];
    case integer(int n) :                         return vint(n);
    case boolean(str boolValue) :                 return vbool(boolValue == "true" ? true : false);
    case string(str strValue) :                   return vstr(strValue);
    default :                                     throw "Unsupported expression <e>";
  }
}