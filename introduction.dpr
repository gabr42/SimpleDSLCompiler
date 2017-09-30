program introduction;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils;

// We want to calculate expressions in form
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
  // Alternatively, we could use Nullable<integer> as result, with Nullable.Null as a
  // default value.

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
    ast: TExpression;
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

begin
  try
    // Make sure we are always running all unit tests
    TestCreateAST;
    TestEvaluateAST;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

  // Over and out.
  Write('All done. Press Enter to exit.');
  Readln;
end.
