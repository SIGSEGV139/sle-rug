module Compile

import AST;
import Resolve;
import IO;
import lang::html::AST; // see standard library
import lang::html::IO;

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTMLElement type and the `str writeHTMLString(HTMLElement x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, writeHTMLString(form2html(f)));
}

//HTML PART

str convertExprToString(AExpr expr) {
  switch (expr) {
    case parentheses(AExpr arg): return "(" + convertExprToString(arg) + ")";
    case not(AExpr arg): return "!" + convertExprToString(arg);
    case multiply(AExpr lhs, AExpr rhs): return convertExprToString(lhs) + "*" + convertExprToString(rhs);
    case divide(AExpr lhs, AExpr rhs): return convertExprToString(lhs) + "/" + convertExprToString(rhs);
    case add(AExpr lhs, AExpr rhs): return convertExprToString(lhs) + "+" + convertExprToString(rhs);
    case subtract(AExpr lhs, AExpr rhs): return convertExprToString(lhs) + "-" + convertExprToString(rhs);
    case gtr(AExpr lhs, AExpr rhs): return convertExprToString(lhs) + "\>" + convertExprToString(rhs);
    case less(AExpr lhs, AExpr rhs): return convertExprToString(lhs) + "\<" + convertExprToString(rhs);
    case geq(AExpr lhs, AExpr rhs): return convertExprToString(lhs) + "\>=" + convertExprToString(rhs);
    case leq(AExpr lhs, AExpr rhs): return convertExprToString(lhs) + "\<=" + convertExprToString(rhs);
    case neq(AExpr lhs, AExpr rhs): return convertExprToString(lhs) + "!=" + convertExprToString(rhs);
    case eq(AExpr lhs, AExpr rhs): return convertExprToString(lhs) + "==" + convertExprToString(rhs);
    case and(AExpr lhs, AExpr rhs): return convertExprToString(lhs) + "&&" + convertExprToString(rhs);
    case or(AExpr lhs, AExpr rhs): return convertExprToString(lhs) + "||" + convertExprToString(rhs);
    case ref(id(str x)): return x;
    case boolean(str boolean): return "<boolean>";
    case integer(int integer): return "<integer>";
    case string(str string): return "<string>";
    default: return "";
  }
}

HTMLElement form2html(AForm f) {
  list[HTMLElement] htmlquestion = [];
  for (AQuestion q <- f.questions) {
    htmlquestion += q2html(q);
  }

  HTMLElement submit = button([text("Submit")], \type = "submit");
  HTMLElement metaElem = meta(\name = "viewport", \content = "width=device-width, initial-scale=1.0");

  HTMLElement htmlElem =
  html([
    head([
      title([text(f.name)]),
      metaElem,
      script([], src=f.src[extension="js"].file)
    ]),
    body([
      form(htmlquestion),
      submit
    ])
  ]);
  htmlElem.\lang = "en";
  return htmlElem;
}

list[HTMLElement] stdQ2HTML(str questionType, AQuestion q) {
  list[HTMLElement] htmlElements = [
    label([text(q.qText)], \for = q.qId.name), 
    br()
  ];

  str inputType = "";
  switch (q.qType.typeName) {
    case "string": inputType = "text";
    case "boolean": inputType = "checkbox";
    case "integer": inputType = "number";
  }

  str onChange = "onChange_" + q.qId.name + "(this)";
  HTMLElement inp = input(\type = inputType, id = q.qId.name, onchange = onChange);

  if (questionType == "ComputedQuestion") {
    inp.disabled = "true";
  }
  
  htmlElements += inp;
  htmlElements += br();
  return htmlElements;
}

HTMLElement blockQ2HTML(AExpr expr, list[AQuestion] ifelsePart, str flag) {
  list[HTMLElement] question_set = [q2html(question) | question <- ifelsePart];
  HTMLElement divBlock = div(question_set);
  switch (flag) {
    case "if": divBlock.id = "if" + convertExprToString(expr);
    case "else": divBlock.id = "else" + convertExprToString(expr);
  }
  return divBlock;
}

HTMLElement q2html(AQuestion q) {
  list[HTMLElement] htmlelements = [];
  str divId = "";
  switch(q) {
    case GeneralQuestion(_, _, _): {
      htmlelements += stdQ2HTML("GeneralQuestion", q);
      divId = "div_<q.qId.name>";
    }

    case ComputedQuestion(_, _, _, _): {
      htmlelements += stdQ2HTML("ComputedQuestion", q);
      divId = "div_<q.qId.name>";
    }
     
    case IfThen(AExpr expr, list[AQuestion] ifPart): {
      htmlelements += blockQ2HTML(expr, ifPart, "if");
      divId = "IfThenBlock"; 
    }

    case IfThenElse(AExpr expr, list[AQuestion] ifPart, list[AQuestion] elsePart): {
      htmlelements += blockQ2HTML(expr, ifPart, "if");
      htmlelements += blockQ2HTML(expr, elsePart, "else");
      divId = "IfThenElseBlock";
    }
  }
  return div(htmlelements, id = divId);
}

// JS PART

str default_value(AType qtype) {
  switch (qtype) {
    case \type("integer"): return "0";
    case \type("boolean"): return "false";
    case \type("string"): return "\"\"";
    default: return "Unknown Type!";
  }
}

str parse_value(AType qtype, str code) {
  switch (qtype) {
    case \type("integer"): return "parseInt(<code>)";
    case \type("boolean"): return "<code>";
    case \type("string"): return  "<code>";
    default: return "Unknown type!";
  }
}

str eventHandling(Use uses, AForm f, AId qId) {
  str code = "";
  bool flag = false;
  set[str] seenCQS = {};
  for (<loc use, str name> <- uses) {
    if (name == qId.name) {
      for (/AQuestion q <- f) {
        for (/AId id <- q, id.src == use) {  
          if (q is ComputedQuestion) {
            code += "update_" + q.qId.name + "();\n";
            seenCQS += q.qId.name;
          } else {
            if (!flag) {
              code += "update_conditions();\n";
              flag = true;
            }
            if (q is IfThen || q is IfThenElse) {
              for (/AQuestion subQ <- q.ifPart) {
                if (subQ is ComputedQuestion && !(subQ.qId.name in seenCQS)) {
                  code += "update_" + subQ.qId.name + "();\n";
                  seenCQS += subQ.qId.name;
                }
              }
            }
          }
        }
      }
    }
  }
  return code;
}

str getNormalQS(AForm f) {
  str code = "";
  RefGraph refGraph = resolve(f);
  
  for (/AQuestion q <- f) {
    if (q is GeneralQuestion) {
      str inputId = q.qId.name;
      str funName = "onChange_<inputId>";
      str varName = inputId;
      str field = (q.qType.typeName == "boolean") ? "input.checked" : "input.value";

      code += "function <funName>(input) {\n";
      code += "<varName> = <parse_value(q.qType, field)>;\n";
      code += eventHandling(refGraph.uses, f, q.qId);
      code += "}\n\n";
    }

    if (q is ComputedQuestion) {
      str inputId = q.qId.name;
      str funName = "update_<inputId>";
      str varName = "input_<inputId>";
      str field = (q.qType.typeName == "boolean") ? "checked" : "value";

      code += "function <funName>() {\n";
      code += "let <varName> = document.querySelector(\"#<inputId>\");\n";
      code += "<varName>.<field> = <convertExprToString(q.qExpr)>;\n";
      code += "}\n\n";
      code += "document.addEventListener(\"DOMContentLoaded\", () =\> <funName>());\n\n";
    }
  }
  return code;
}

str displayQS(list[AQuestion] questions, bool show) {
  str code = "";
  for (/AQuestion q <- questions) {
    if (q is GeneralQuestion || q is ComputedQuestion) {
      code += "document.querySelector(\"#div_" + q.qId.name + "\").style.display = \"" + (show ? "block" : "none") + "\";\n";
    } else {
      code += getCondQS(q);
    }
  }
  return code;
}

str getCondQS(AQuestion q) {
  str code = "";
  seenQS += q;
  if (q is IfThen) {
    code += "if (<convertExprToString(q.condition)>) {\n";
    code += displayQS(q.ifPart, true);
    code += "} else {\n";
    code += displayQS(q.ifPart, false);
    code += "}\n";
  }
  if (q is IfThenElse) {
    code += "if (<convertExprToString(q.condition)>) {\n";
    code += displayQS(q.ifPart, true);
    code += "} else {\n";
    code += displayQS(q.ifPart, false);
    code += "}\n";
  }
  return code;
}

set[AQuestion] seenQS = {};

str form2js(AForm f) {
  str code = "";
  for (/AQuestion q <- f, q is GeneralQuestion) {
    code += "let " + q.qId.name + " = " + default_value(q.qType) + ";\n";
  }
  code += "\n";
  code += "function update_conditions() {\n";
  for (/AQuestion q <- f.questions, (q is IfThen || q is IfThenElse) && !(q in seenQS)) {
    code += getCondQS(q);
  }
  code += "}\n\n";
  code += getNormalQS(f);
  code += "document.addEventListener(\"DOMContentLoaded\", () =\> update_conditions());";
  return code;
}