module Transform

import Syntax;
import Resolve;
import AST;
import CST2AST;
import ParseTree;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
  list[AQuestion] aqs = [];
	for(question <- f.questions) {
		aqs += flatten(question, boolean("true"));
	}
	return form(f.name, aqs);
}

list[AQuestion] flatten(AQuestion question, AExpr condition) {
  list[AQuestion] flattenedQuestions = [];
  switch(question) {
    case GeneralQuestion(_, _, _): {
      flattenedQuestions += IfThen(condition, [question]);
    }
    case ComputedQuestion(_, _, _, _): {
      flattenedQuestions += IfThen(condition, [question]);
    }
    case IfThen(AExpr expr, list[AQuestion] ifqs): {
       for(q <- ifqs) {
        flattenedQuestions += flatten(q, and(condition, expr));
      }
    }
    case IfThenElse(AExpr expr, list[AQuestion] ifqs, list[AQuestion] elseqs): {
      for(q <- ifqs) {
        flattenedQuestions += flatten(q, and(condition, expr));
      }
      for(q <- elseqs) { 
        flattenedQuestions += flatten(q, and(condition, not(expr)));
      }
    }
  }
  return flattenedQuestions;
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
  set[loc] locations = {};
  
  if(useOrDef in useDef<0>) {
    if(<useOrDef, loc def> <- useDef) {
      locations += { def };
      locations += { u | <loc u, def> <- useDef };
    }
  } else {
    locations += { useOrDef };
    locations += { u | <loc u, useOrDef> <- useDef };
  }
   
  if(locations == {}) {
    return f;
  }
  
  return visit (f) {
    case Id x => [Id]newName when x.src in locations
  }
} 
 
 
 

