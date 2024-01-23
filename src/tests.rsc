module tests
import Syntax;
import AST;
import CST2AST;
import ParseTree;
import Resolve;
import Check;
import Transform;
import Eval;
import IO;
import vis::Text;

// SYNTAX TEST
void testsyn() {
    str fileContent = readFile(|cwd:///examples/binary.myql|);
    Tree t = parse(#start[Form], fileContent);
    println("Tree: ");
    println(t);
}

// AST TEST
void testast() {
    str fileContent = readFile(|cwd:///examples/binary.myql|);
    AForm t = cst2ast(parse(#start[Form], fileContent));
    println("AForm: ");
    println(t);
}

// RESOLVE TEST
void testresolve() {
    RefGraph res_a = resolve(form("formName", [ GeneralQuestion( id("hasSoldHouse"), \type("integer"), "cool label1" ), 
                                                ComputedQuestion( id("hasMaintLoan"), \type("boolean"), add(integer(1), integer(2)), "cool label2") ]));
    println(res_a);
}

// CHECK TEST
void testcheck() { 
    println("TEST 1");
    set[Message] res = testhelper(readFile(|cwd:///examples/test.myql|));
    println(res);
    assert res == {};

    println("TEST 2");
    res = testhelper(readFile(|cwd:///examples/errors.myql|));
    print(res);
    assert res == {};
}

set[Message] testhelper(str file) {
    Tree parsed = parse(#start[Form], file);
    AForm ast = cst2ast(parsed);
    RefGraph g = resolve(ast);
    TEnv tenv = collect(ast);
    set[Message] msgs = check(ast, tenv, g.useDef);
    return msgs;
}

// EVAL TEST
void testeval() {
    println("TEST 1");
    res = testEval(readFile(|cwd:///examples/test.myql|), 
                   ("sellingPrice": 123456,
                    "privateDebt": 3456
                   ));
    assert res["valueResidue"] == vint(0);

    println("\nTEST 2");
    res = testEval(readFile(|cwd:///examples/test.myql|), 
                  ("sellingPrice": 123456, 
                   "privateDebt": 3456,
                   "hasSoldHouse": (true && false) || (true || false)
                   ));
    assert res["valueResidue"] == vint(120000);
    assert res["possibleSellingPrice"] == vint(0);

    println("\nTEST 3");
    res = testEval(readFile(|cwd:///examples/test.myql|), 
                  ("sellingPrice": 123456, 
                   "privateDebt": 3456,
                   "hasSoldHouse": false
                   ));
    assert res["valueResidue"] == vint(0);
    assert res["possibleSellingPrice"] == vint(100);
}

Value getVValue(value v) {
  switch (v) {
    case int n: return vint(n);
    case bool b: return vbool(b);
    case str s: return vstr(s);
  }
  throw "Unsupported value <v>";
}

VEnv testEval(str fileContent, map[str, value] inputs) {
    AForm ast = cst2ast(parse(#start[Form], fileContent));
    TEnv tenv = collect(ast);
    
    println("pre-eval");
    VEnv env = initialEnv(ast);
    println(env);

    for(k <- inputs) {
        Input i = input(k, getVValue(inputs[k]));
        env = eval(ast, i, env);
    }
    println("post-eval");
    println(env);
    return env;
}