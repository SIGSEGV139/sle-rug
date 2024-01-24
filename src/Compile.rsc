module Compile

import AST;
import Resolve;
import IO;
import lang::html::AST; // see standard library
import lang::html::IO;

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is  type- and name-correct
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

HTMLElement form2html(AForm f) {
   HTMLElement htmlElement = html([
    head([
      title("QL Form")
    ]),
    body([
      div([
        h1(text(f.name)), 
        questions2HTML(f.questions) 
      ])
    ])
  ]);

  return htmlElement;
}

str expression2str(AExpr expr){
  switch(expr){
    case  parentheses(AExpr expr) :             return ("(" + expression2str(expr) + ")"); 
    case  not(AExpr expr) :                     return ("!" + expression2str(expr));
    case  divide(AExpr expr1, AExpr expr2) :    return (expression2str(expr1) + "/" + expression2str(expr2));
    case  multiply(AExpr expr1, AExpr expr2):   return (expression2str(expr1) + "*" + expression2str(expr2));
    case  add(AExpr expr1, AExpr expr2):        return (expression2str(expr1) + "+" + expression2str(expr2));
    case  subtract(AExpr expr1, AExpr expr2):   return (expression2str(expr1) + "-" + expression2str(expr2));
    case  less(AExpr expr1, AExpr expr2):       return (expression2str(expr1) + "<" + expression2str(expr2));
    case  gtr(AExpr expr1, AExpr expr2):        return (expression2str(expr1) + ">" + expression2str(expr2));
    case  leq(AExpr expr1, AExpr expr2):        return (expression2str(expr1) + "<=" + expression2str(expr2));
    case  geq(AExpr expr1, AExpr expr2):        return (expression2str(expr1) + ">=" + expression2str(expr2));
    case  eq(AExpr expr1, AExpr expr2):         return (expression2str(expr1) + "==" + expression2str(expr2));
    case  neq(AExpr expr1, AExpr expr2):        return (expression2str(expr1) + "!=" + expression2str(expr2));
    case  and(AExpr expr1, AExpr expr2):        return (expression2str(expr1) + "&&" + expression2str(expr2));
    case  or(AExpr expr1, AExpr expr2):         return (expression2str(expr1) + "||" + expression2str(expr2));
    case  ref(AId id) :                         return toString(id);
    case  integer(int n) :                      return toString(n);
    case  boolean(str boolValue) :              return boolValue;
    case  string(str strValue) :                return strValue;
  }
}


str computedQuestion2HTML(str id, AType varType, AExpr expr, str label) {
  switch (varType) {
    case \type(integer) : return "    \<computed-question id=\"<id>\" label=<label> v-bind:value=\"<id>\"\>\</computed-question\>\n";
    case \type(boolean) : return "    \<computed-question id=\"<id>\" label=<label> v-bind:value=\"<id>\"\>\</computed-question\>\n";
    case \type(string) : return  "    \<computed-question id=\"<id>\" label=<label> v-bind:value=\"<id>\"\>\</computed-question\>\n";
    default: throw "Unsupported type <varType>";
  }
}

str generalQuestion2HTML(str id, AType varType, str label) {
  switch (varType) {
    case integer(): return "    \<integer  id=\"<id>\" label=<label> v-model=\"<id>\"\>\</integer\>\n";
    case boolean(): return "    \<boolean id=\"<id>\" label=<label> v-model=\"<id>\"\>\</boolean\>\n";
    case string(): return "     \<string  id=\"<id>\" label=<label> v-model=\"<id>\"\>\</string\>\n";
    default: throw "Unsupported type <varType>";
  }
}

str questions2HTML(list[AQuestion] questions){
  result = "";
  for (AQuestion question <- questions){
    switch(question) {
      case generalQuestion(AId qId, AType qType, str qText):
        result = result + generalQuestion2HTML(qId, qType, qText);
      case computedQuestion(AId qId, AType qType, AExpr qExpr, str qText):
        result = result + computedQuestion2HTML(qId, qType, qExpr, qText);
      case IfThenElse(AExpr condition, list[AQuestion] ifPart, list[AQuestion] elsePart):
        result = result + question2HTML(question);
    }
  }
  return result;
}

str question2Html(AQuestion q) {
  result = "";
  switch(q) {
    case GeneralQuestion(strg(str label), ref(id(str sid), src = loc u), AType varType, src = loc q):
      result = result + generalQuestion2HTML(sid, varType, label);
    case ComputedQuestion(strg(str label), ref(id(str sid), src= loc u), AType varType, AExpr expr, src=loc q):
      result = result + computedQuestion2HTML(sid, varType, expr, label);
    case IfThenElse(AExpr condition, list[AQuestion] ifPart, list[AQuestion] elsePart):
      result = result + "\<div v-if=\"" + expression2str(condition) + "\"\>\n" +
               questions2HTML(ifPart) +
               '\</div\>\n' +
               '\<div v-else\>\n' +
               questions2HTML(elsePart) +
               '\</div\>\n";
    case IfThen(AExpr condition, list[AQuestion] ifPart):
      result = result + "\<div v-if=\"" + expression2str(condition) + "\"\>\n" +
               questions2HTML(ifPart) +
               '\</div\>\n';
    default : 
        result = result;
  }
  return result;
}
str form2js(AForm f) {
  return "";
}
