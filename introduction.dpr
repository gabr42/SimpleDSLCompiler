// This program presents a gentle introduction into the 'compiler-compiler' topic.
// It is written in a Literal Programming manner and is intended to be read as a story
// from top to bottom.

program introduction;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils;

// Our problem: We want to calculate expressions in form
//    number1 + number2 + ... + numberN
// All numbers are integers, the only operator is addition, overflows are ignored.

// To do that, we will parse each expression into a very simple AST.

type
  TExpression = class
  strict private
    FValue     : integer;
    FExpression: TExpression;
  public
    constructor CreateConst(AValue: integer);
    constructor CreateSum(AValue: integer; AExpression: TExpression);
    destructor  Destroy; override;
    property Value: integer read FValue write FValue;
    property Expression: TExpression read FExpression write FExpression;
  end;

// An expression can represent either a constant value (Value property contains the value
// and Expression is nil) or an addition (Value property contains the first operand and
// Expression points to the second operand, which may be a constant or an expression).

constructor TExpression.CreateConst(AValue: integer);
begin
  inherited Create;
  FValue := AValue;
end;

constructor TExpression.CreateSum(AValue: integer; AExpression: TExpression);
begin
  inherited Create;
  FValue := AValue;
  FExpression := AExpression;
end;

destructor TExpression.Destroy;
begin
  FreeAndNil(FExpression);
  inherited;
end;

// The following function builds an AST from an array of integers.
// Owner is responsible for destroying the resulting AST.

function CreateAST(const values: TArray<integer>): TExpression;
var
  iValue: integer;
begin
  if Length(values) = 0 then
    Exit(nil);

  // We will create terms from the back of the array towards the end and use each
  // intermediate result as an Expression in the next term.
  Result := TExpression.CreateConst(values[High(values)]);
  for iValue := High(values) - 1 downto Low(values) do
    Result := TExpression.CreateSum(values[iValue], Result);
end;

// Calling CreateAST([1, 2, 3]) will create the following AST with three nodes:
//    Expr1
//    Value = 1; Expression = Expr2
//                            Value = 2; Expression = Expr3
//                                                    Value = 3; Expression = nil

// Let's make this into a test.

procedure TestCreateAST;
var
  ast: TExpression;
begin
  ast := CreateAST([1, 2, 3]);
  if assigned(ast) and (ast.Value = 1)
     and assigned(ast.Expression) and (ast.Expression.Value = 2)
     and assigned(ast.Expression.Expression) and (ast.Expression.Expression.Value = 3)
     and (not assigned(ast.Expression.Expression.Expression))
  then
    // everything is fine
  else
    raise Exception.Create('CreateAST is not working correctly!');
end;

// It is very easy to run an interpreter over this AST.

function EvaluateAST(ast: TExpression): integer;
begin
  if not assigned(ast) then
    raise Exception.Create('Result is undefined!');
  // [Alternatively, we could use Nullable<integer> as result, with Nullable.Null as a
  //  return value when AST is empty.]

  Result := ast.Value;
  while assigned(ast.Expression) do begin
    ast := ast.Expression;
    Result := Result + ast.Value;
  end;
end;

// Some sanity tests are always welcome ...

procedure TestEvaluateAST;

  procedure Test(const testName: string; const values: TArray<integer>; expectedResult: integer);
  var
    ast       : TExpression;
    calcResult: integer;
  begin
    ast := CreateAST(values);
    if not assigned(ast) then
      raise Exception.CreateFmt('Compilation failed in test %s', [testName]);

    try
      calcResult := EvaluateAST(ast);

      if calcResult <> expectedResult then
        raise Exception.CreateFmt(
                'Evaluation failed in test %s. Calculated result %d <> expected result %d',
                [testName, calcResult, expectedResult]);

    finally
      FreeAndNil(ast);
    end;
  end;

begin
  Test('1', [42], 42);
  Test('2', [1, 2, 3], 6);
  Test('3', [2, -2, 3, -3], 0);
end;

// To compile this AST, we have to:
// - Change each 'constant' node into an anonymous function that returns the value of that node.
// - Change each 'summation' node into an anonymous function that returns the sum of two parameters.
//   The first is a constant value (left term in the summation) and the second is an anonymous
//   function which calculates the value of the right term.

// Variable capture mechanism takes care of grabbing the correct inputs.

function MakeConstant(value: integer): TFunc<integer>;
begin
  Result :=
    function: integer
    begin
      Result := value;
    end;
end;

function MakeSummation(value: integer; const expression: TFunc<integer>): TFunc<integer>;
begin
  Result :=
    function: integer
    begin
      Result := value + expression();
    end;
end;

// The important point here is that neither MakeConstant nor MakeSummation does any
// calculation. They merely set up an anonymous method and return a reference to it,
// which is more or less the same as creating an object and returning an interface to it,
// but with the added value of variable capturing.

// BTW, as our "language" just calculates integer expressions that always return an integer,
// a 'function returning an integer' or TFunc<integer> exactly matches our requirements.

// To 'compile' an AST we have to use some recursion as we need to create a
// child-calculating anonymous function _before_ we can use it (as a parameter)
// to create an anonymous function calculating the parent node.

function CompileAST(ast: TExpression): TFunc<integer>;
begin
  if ast.Expression = nil then
    // this node represents a constant
    Result := MakeConstant(ast.Value)
  else
    // this node represent an expression
    Result := MakeSummation(ast.Value, CompileAST(ast.Expression));

  // This code works correctly because compiler captures the _value_ of `ast.Value`,
  // not a _reference_ (pointer) to it. How do I know? Because function `TestCompileAST`
  // explicitly tests for this behaviour.
end;

// Calling CompileAST(CreateAST[1,2,3]) will generate the following anonymous function(*):
//
// function: integer
// begin
//   Result := 1 +
//     (function: integer
//     begin
//       Result := 2 +
//         (function: integer
//         begin
//           Result := 3;
//         end)()
//     end)();
// end;
//
// (*): I'm aware that this will result in a memory leak.

// It is hard to verify if generated anonymous function is in correct form, but we can
// execute it for some number of test cases and hope that everything is ok ;)

procedure TestCompileAST;

  procedure Test(const testName: string; const values: TArray<integer>; expectedResult: integer);
  var
    ast       : TExpression;
    calcResult: integer;
    code      : TFunc<integer>;
  begin
    ast := CreateAST(values);
    if not assigned(ast) then
      raise Exception.CreateFmt('Compilation failed in test %s', [testName]);

    try
      code := CompileAST(ast);
      if not assigned(code) then
        raise Exception.CreateFmt('Codegen failed in test %s', [testName]);

      // Let's make sure that `ast.Value` was captured by value and not by reference.
      // Changing AST now should not affect the compiled code.
      ast.Value := ast.Value + 1;

      calcResult := code(); //execute the compiled code

      if calcResult <> expectedResult then
        raise Exception.CreateFmt(
                'Evaluation failed in test %s. Codegen result %d <> expected result %d',
                [testName, calcResult, expectedResult]);

    finally
      FreeAndNil(ast);
    end;
  end;

begin
  Test('1', [42], 42);
  Test('2', [1, 2, 3], 6);
  Test('3', [2, -2, 3, -3], 0);
end;

begin
  try
    // Run all unit tests to verify program correctness.
    TestCreateAST;
    TestEvaluateAST;
    TestCompileAST;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

  // Over and out.
  Write('All done. Press Enter to exit.');
  Readln;
end.
