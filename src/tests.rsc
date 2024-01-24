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
    Tree parsedTree = parse(#start[Form], readFile(|cwd:///examples/binary.myql|));
    println(parsedTree);
}

// AST TEST
void testast() {
    AForm aForm = cst2ast(parse(#start[Form], readFile(|cwd:///examples/binary.myql|)));
    println(aForm);
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
    AForm ast = cst2ast(parse(#start[Form], file));
    RefGraph refGraph = resolve(ast);
    TEnv tenv = collect(ast);
    return check(ast, tenv, refGraph.useDef);
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
                   "hasSoldHouse": !(true || (true && false))
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
    print("initial: ");
    VEnv env = initialEnv(ast);
    println(env);
    for(j <- inputs) {
        Input i = input(j, getVValue(inputs[j]));
        env = eval(ast, i, env);
    }
    print("final: ");
    println(env);
    return env;
}

//TRANSFORM TEST
void testtransform() {
    AForm flat = flatten(cst2ast(parse(#start[Form], readFile(|cwd:///examples/binary.myql|))));
    printFlatForm(flat);

    Tree parsedTree = parse(#start[Form], readFile(|cwd:///examples/test.myql|));
    hasSoldHouse_loc = |unknown:///|(264,12,<14,6>,<14,18>);
    start[Form] newForm = rename(parsedTree, hasSoldHouse_loc, "PIZZA", resolve(flat).useDef);
    println(newForm);
}

void printFlatForm(AForm flat) {
    for (AQuestion q <- flat.questions) {
        if (q is IfThen) {
            AExpr e = q.condition;
            list[AQuestion] innerQuestions = q.ifPart;
            if (size(innerQuestions) > 0) {
                AQuestion innerQ = innerQuestions[0];
                switch (innerQ) {
                    case GeneralQuestion(id, _, _):
                        println("GeneralQuestion \"<id.name>\": <e>\n");
                    case ComputedQuestion(id, _, _, _):
                        println("ComputedQuestion \"<id.name>\": <e>\n");
                    default:
                        throw "Unexpected question type!";
                }
            }
        }
    }
}
