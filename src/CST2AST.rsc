module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  list[AQuestion] questions = [cst2ast(q) | q <- f.questions];
  return form("<f.name>", questions, src = f.src);
}

default AQuestion cst2ast(Question q) {
  switch (q) {
    case (Question)`<Str name> <Id i> : <Type t>`:
      return GeneralQuestion(id("<i>", src = i.src), cst2ast(t), "<name>", src = q.src);

    case (Question)`<Str name> <Id i> : <Type t> = <Expr e>`:
      return ComputedQuestion(id("<i>", src = i.src), cst2ast(t), cst2ast(e), "<name>", src = q.src);

    case (Question)`if ( <Expr expr> ) { <Question* x0> }`:
      return IfThenElse(cst2ast(expr), [cst2ast(q2) | q2 <- x0], [], src = q.src);

    case (Question)`if ( <Expr expr> ) { <Question* x0> } else { <Question* x1>}`:
      return IfThenElse(cst2ast(expr), [cst2ast(q2) | q2 <- x0], [cst2ast(q2) | q2 <- x1], src = q.src);

    default:
      throw "Unhandled question <q>";
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`(<Expr x>)`: return parentheses(cst2ast(x), src = e.src);
    case (Expr)`!<Expr x>` : return not(cst2ast(x), src = e.src);
    case (Expr)`<Expr x1> / <Expr x2>` : return divide(cst2ast(x1),cst2ast(x2), src = e.src);
    case (Expr)`<Expr x1> * <Expr x2>` : return multiply(cst2ast(x1),cst2ast(x2), src = e.src);
    case (Expr)`<Expr x1> + <Expr x2>` : return add(cst2ast(x1),cst2ast(x2), src = e.src);
    case (Expr)`<Expr x1> - <Expr x2>` : return subtract(cst2ast(x1),cst2ast(x2), src = e.src);
    case (Expr)`<Expr x1> \> <Expr x2>` : return gtr(cst2ast(x1),cst2ast(x2), src = e.src);
    case (Expr)`<Expr x1> \< <Expr x2>` : return less(cst2ast(x1),cst2ast(x2), src = e.src);
    case (Expr)`<Expr x1> \<= <Expr x2>` : return leq(cst2ast(x1),cst2ast(x2), src = e.src);
    case (Expr)`<Expr x1> \>= <Expr x2>` : return geq(cst2ast(x1),cst2ast(x2), src = e.src);
    case (Expr)`<Expr x1> == <Expr x2>` : return eq(cst2ast(x1),cst2ast(x2), src = e.src);
    case (Expr)`<Expr x1> != <Expr x2>` : return neq(cst2ast(x1),cst2ast(x2), src = e.src);
    case (Expr)`<Expr x1> && <Expr x2>` : return and(cst2ast(x1),cst2ast(x2), src = e.src);
    case (Expr)`<Expr x1> || <Expr x2>` : return or(cst2ast(x1),cst2ast(x2), src = e.src);
    case (Expr)`<Id x>`: return ref(id("<x>", src=x.src), src=x.src);
    case (Expr)`<Int n>` : return integer(toInt("<n>"), src = n.src);
    case (Expr)`<Bool b>` : return boolean("<b>", src = b.src);

    default: throw "Unhandled expression: <e>";
  }
}

default AType cst2ast(Type t) {
  switch(t) {
    case (Type)`integer`: return \type("integer", src = t.src);
    case (Type)`boolean`: return \type("boolean", src = t.src);
  
    default: throw "Unhandled type <t>";   
  }
}
