// This program presents a gentle introduction into the 'compiler-compiler' topic.
// It is written in a Literal Programming manner and is intended to be read as a story
// from top to bottom.

program introduction;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.Character,
  System.Generics.Collections;

// Our problem: We want to calculate expressions in form
//    number1 + number2 + ... + numberN
// All numbers are non-negative integers, the only operator is addition, overflows are ignored.

// To do that, we will parse each expression into a very simple AST.

type
  TTerm = class abstract
  end;

  TAST = TTerm;

// At the top of our tree is a 'term'. A term can be either a constant or an addition.

// A constant, as it could be expected, contains an integer value.

// We are not consistent here - the language only allows positive integers but AST is more
// open and allows negative integers. We'll just ignore that.

  TConstant = class(TTerm)
  strict private
    FValue: integer;
  public
    constructor Create(AValue: integer);
    property Value: integer read FValue write FValue;
  end;

// An addition is a binary operation which operates on two terms (left and right side).

  TAddition = class(TTerm)
  strict private
    FTerm1: TTerm;
    FTerm2: TTerm;
  public
    constructor Create(ATerm1, ATerm2: TTerm);
    destructor  Destroy; override;
    property Term1: TTerm read FTerm1 write FTerm1;
    property Term2: TTerm read FTerm2 write FTerm2;
  end;

constructor TConstant.Create(AValue: integer);
begin
  inherited Create;
  FValue := AValue;
end;

constructor TAddition.Create(ATerm1, ATerm2: TTerm);
begin
  inherited Create;
  FTerm1 := ATerm1;
  FTerm2 := ATerm2;
end;

// A TAddition object takes ownership of its children.

destructor TAddition.Destroy;
begin
  FreeAndNil(FTerm1);
  FreeAndNil(FTerm2);
  inherited;
end;

// The following function builds an AST from an array of integers.
// Owner is responsible for destroying the resulting AST.

function CreateAST(const values: TArray<integer>): TAST;
var
  iValue: integer;
begin
  if Length(values) = 0 then
    Exit(nil);

  // We will create terms from the back of the array towards the end and use each
  // intermediate result as an Term in the next term.

  Result := TConstant.Create(values[High(values)]);

  for iValue := High(values) - 1 downto Low(values) do
    Result := TAddition.Create(TConstant.Create(values[iValue]), Result);
end;

// Calling CreateAST([1, 2, 3]) will create the following AST with three nodes:
//
// TAddition
//   Term1 = TConstant
//           Value = 1
//   Term2 = TAddition
//           Term1 = TConstant
//                   Value = 2
//           Term2 = TConstant
//                   Value = 3
//
// Let's make this into a test.

// First, some helpers which test and cast at the same time.

function IsConstant(term: TTerm; out add: TConstant): boolean;
begin
  Result := term is TConstant;
  if Result then
    add := TConstant(term);
end;

function IsAddition(term: TTerm; out add: TAddition): boolean;
begin
  Result := term is TAddition;
  if Result then
    add := TAddition(term);
end;

// And now the real test.

procedure TestCreateAST;
var
  add1  : TAddition;
  add2  : TAddition;
  ast   : TAST;
  const1: TConstant;
  const2: TConstant;
  const3: TConstant;
begin
  ast := CreateAST([1, 2, 3]);
  try
    if assigned(ast)
       and IsAddition(ast, add1)
       and IsConstant(add1.Term1, const1) and (const1.Value = 1)
       and IsAddition(add1.Term2, add2)
       and IsConstant(add2.Term1, const2) and (const2.Value = 2)
       and IsConstant(add2.Term2, const3) and (const3.Value = 3)
    then
      // everything is fine
    else
      raise Exception.Create('CreateAST is not working correctly!');
  finally FreeAndNil(ast); end;
end;

// We will write a simple parser which will create an AST from an expression
// in form 'number1 + number2 + ... numberN'.

// Our 'language' has only two tokens: a 'number' and an 'addition'. Whitespace is not
// important and will be ignored in the tokenizer (lexer).
// All unrecognized characters are returned as a token 'unknown'.

type
  TTokenKind = (tkNumber, tkAddition, tkUnknown);

// More formal definition of tokens
//   tkNumber accepts a \d+
//   tkAddition accepts \+
//   \s+ is skipped
//   tkUnknown accepts anything else: [^\d\+\s]

// Tokenizer and parser only need the following information:
//   1) Input string.
//   2) Current position.
// A `TStringStream` class wraps all that so we'll just reuse it.

  TParserState = TStringStream;

// The only tokenizer funcion returns next token and its value as 'var' parameters and
// returns True if token/value pair was returned or False if end of stream was reached.

// This implementation is very simple but also extremely unoptimized.

function GetToken(state: TParserState; var token: TTokenKind; var value: string): boolean;
var
  nextChar: string;
  position: int64;
begin
  repeat
    nextChar := state.ReadString(1);
    Result := (nextChar <> '');
    // Ignore whitespace
  until (not Result) or (not nextChar[1].IsWhiteSpace);

  if Result then begin
    value := nextChar[1];

    // Addition
     if value = '+' then
      token := tkAddition

    // Number
    else if value[1].IsNumber then begin
      token := tkNumber;
      repeat
        position := state.Position;
        nextChar := state.ReadString(1);

        // End of stream, stop
        if nextChar = '' then
          break //repeat

        // Another number, append
        else if nextChar[1].IsNumber then
          value := value + nextChar[1]

        // Read too far, retract
        else begin
          state.Position := position;
          break; //repeat
        end;
      until false;
    end

    // Unexpected input
    else
      token := tkUnknown;
  end;
end;

// Some tests for the tokenizer are needed ...

// ExpectFail(state) calls GetToken and expects it to return False

procedure ExpectFail(state: TParserState);
var
  token: TTokenKind;
  value: string;
begin
  if GetToken(state, token, value) then
    raise Exception.Create('ExpectFail failed');
end;

// Expect(State, token, value) calls GetNextToken and expects it to return True
// and the same token/value as passed in the parameters.

procedure Expect(state: TParserState; expectedToken: TTokenKind; expectedValue: string);
var
  token: TTokenKind;
  value: string;
begin
  if not GetToken(state, token, value) then
    raise Exception.Create('Expect failed')
  else if token <> expectedToken then
    raise Exception.CreateFmt('Expect encountered invalid token kind (%d, expected %d)',
                              [Ord(token), Ord(expectedToken)])
  else if value <> expectedValue then
    raise Exception.CreateFmt('Expect encountered invalid value (%s, expected %s)',
                              [value, expectedValue])
end;

procedure TestGetToken;
var
  state: TParserState;
begin
  state := TParserState.Create('');
  ExpectFail(state);
  FreeAndNil(state);

  state := TParserState.Create('1');
  Expect(state, tkNumber, '1');
  ExpectFail(state);
  FreeAndNil(state);

  state := TParserState.Create('1+22 333 Ab');
  Expect(state, tkNumber, '1');
  Expect(state, tkAddition, '+');
  Expect(state, tkNumber, '22');
  Expect(state, tkNumber, '333');
  Expect(state, tkUnknown, 'A');
  Expect(state, tkUnknown, 'b');
  ExpectFail(state);
  FreeAndNil(state);
end;

// Parser accepts any valid string and converts it into an AST.
// If a program is valid, it will create an AST for the program, return it in the `ast`
// parameter, and set result to True.
// If a program is not valid, `ast` will be nil and result will be False.

// Accepted grammar is
//   S -> Term
//   Term -> number
//   Term -> Term '+' Term

// Empty input is not accepted.

function Parse(const prog: string; var ast: TAST): boolean;
var
  accept : TTokenKind;
  numbers: TList<integer>;
  state  : TParserState;
  token  : TTokenKind;
  value  : string;
begin
  // We can easily see that the above grammar generates exactly the following sequence of tokens:
  //   tkNumber (tkAddition tkNumber)*
  // (The proof is left out as an excercise for the reader.

  // The code will check the syntax and extract all numbers in an TArray<integer>.
  // At the end it will pass this array to the CreateAST function to create the AST.

  ast := nil;
  Result := false;

  state := TParserState.Create(prog);
  try
    numbers := TList<integer>.Create;
    try
      accept := tkNumber;
      while GetToken(state, token, value) do begin
        if token <> accept then
          Exit;
        if accept = tkNumber then begin
          numbers.Add(StrToInt(value));
          accept := tkAddition;
        end
        else
          accept := tkNumber;
      end;

      if accept = tkNumber then
        // Last token in the program was tkAddition, which is not allowed.
        Exit;

      if numbers.Count > 0 then begin
        ast := CreateAST(numbers.ToArray);
        Result := true;
      end;
    finally FreeAndNil(numbers); end;
  finally FreeAndNil(state); end;
end;

// We need more tests ...

procedure TestParse;
var
  add1  : TAddition;
  add2  : TAddition;
  ast   : TAST;
  const1: TConstant;
  const2: TConstant;
  const3: TConstant;
begin
  if not Parse('1+2 + 3', ast) then
    raise Exception.Create('Parser failed');
  try
    if assigned(ast)
       and IsAddition(ast, add1)
       and IsConstant(add1.Term1, const1) and (const1.Value = 1)
       and IsAddition(add1.Term2, add2)
       and IsConstant(add2.Term1, const2) and (const2.Value = 2)
       and IsConstant(add2.Term2, const3) and (const3.Value = 3)
    then
      // everything is fine
    else
      raise Exception.Create('CreateAST is not working correctly!');
  finally FreeAndNil(ast); end;

  if Parse('1+2 +', ast) then begin
    if assigned(ast) then
      raise Exception.Create('Invalid program resulted in an AST!)')
    else
      raise Exception.Create('Invalid program compiled into an empty AST!');
  end;

end;

// To interpret this AST, we will use a simple recursion.

function InterpretAST(ast: TAST): integer;
var
  add1  : TAddition;
  const1: TConstant;
begin
  if not assigned(ast) then
    raise Exception.Create('Result is undefined!');
  // Alternatively, we could use Nullable<integer> as result, with Nullable.Null as a
  // default value.

  if IsConstant(ast, const1) then
    Result := const1.Value
  else if IsAddition(ast, add1) then
    Result := InterpretAST(add1.Term1) + InterpretAST(add1.Term2)
  else
    raise Exception.Create('Internal error. Unknown AST element: ' + ast.ClassName);
end;

// Some sanity tests are always welcome ...

procedure TestInterpretAST;

  procedure Test(const testName: string; const values: TArray<integer>; expectedResult: integer);
  var
    ast       : TAST;
    calcResult: integer;
  begin
    ast := CreateAST(values);
    if not assigned(ast) then
      raise Exception.CreateFmt('Compilation failed in test %s', [testName]);

    try
      calcResult := InterpretAST(ast);
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
//   The first is an anonymous function which calculates the value of the left term and
//   the second is an anonymous function which calculates the value of the right term.

// Variable capture mechanism takes care of grabbing the correct inputs.

function MakeConstant(value: integer): TFunc<integer>;
begin
  Result :=
    function: integer
    begin
      Result := value;
    end;
end;

function MakeAddition(const term1, term2: TFunc<integer>): TFunc<integer>;
begin
  Result :=
    function: integer
    begin
      Result := term1() + term2();
    end;
end;

// The important point here is that neither MakeConstant nor MakeAddition does any
// calculation. They merely set up an anonymous method and return a reference to it,
// which is more or less the same as creating an object and returning an interface to it,
// but with the added value of variable capturing.

// BTW, as our "language" just calculates integer expressions that always return an integer,
// a 'function returning an integer' or TFunc<integer> exactly matches our requirements.

// To 'compile' an AST we have to use recursion as we need to create a
// child-calculating anonymous functions _before_ we can use them (as a parameter)
// to create an anonymous function calculating the parent node.

function CompileAST(ast: TTerm): TFunc<integer>;
var
  add1: TAddition;
  const1: TConstant;
begin
  if IsConstant(ast, const1) then
    // this node represents a constant
    Result := MakeConstant(const1.Value)
  else if IsAddition(ast, add1) then
    // this node represent an expression
    Result := MakeAddition(CompileAST(add1.Term1), CompileAST(add1.Term2))
  else
    raise Exception.Create('Internal error. Unknown AST element: ' + ast.ClassName);

  // This code works correctly because compiler captures the _value_ of `const1.Value`,
  // not a _reference_ (pointer) to it. How do I know? Because function `TestCompileAST`
  // explicitly tests for this behaviour.
end;

// Calling CompileAST(CreateAST[1,2,3]) will generate the following anonymous function(*):
//
// function: integer
// begin
//   Result :=
//     (function: integer
//      begin
//        Result := 1;
//      end)()
//     +
//     (function: integer
//      begin
//        Result :=
//          (function: integer
//           begin
//             Result := 2;
//           end)()
//          +
//          (function: integer
//           begin
//             Result := 3;
//           end)();
//      end)();
// end;
//
// (*): I'm aware that this will result in a memory leak.

// It is hard to verify if generated anonymous function is in correct form, but we can
// execute it for some number of test cases and hope that everything is ok ;)

procedure TestCompileAST;

  procedure Test(const testName: string; const prog: string; expectedResult: integer);
  var
    add1      : TAddition;
    ast       : TAST;
    calcResult: integer;
    code      : TFunc<integer>;
    const1    : TConstant;
  begin
    if not (Parse(prog, ast) and assigned(ast)) then
      raise Exception.CreateFmt('Parser failed in test %s', [testName]);

    try
      code := CompileAST(ast);
      if not assigned(code) then
        raise Exception.CreateFmt('Compilation failed in test %s', [testName]);

      // Let's make sure that `ast.Value` was captured by value and not by reference.
      // Changing AST now should not affect the compiled code.
      if (IsAddition(ast, add1) and IsConstant(add1.Term1, const1))
         or IsConstant(ast, const1)
      then
        const1.Value := const1.Value + 1
      else
        raise Exception.CreateFmt('Unexpected AST format in test %s', [testName]);

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
  Test('1', '42', 42);
  Test('2', '1 + 2 + 3', 6);
  Test('3', '2 + 2 +3+3', 10);
end;

// If all tests pass, we'll run a Read-Eval-Print Loop so that user can test our compiler.

procedure RunREPL;
var
  ast : TAST;
  prog: string;
begin
  repeat
    Write('Enter an expression (empty line exits): ');
    Readln(prog);
    if prog = '' then
      break;

    if not Parse(prog, ast) then
      Writeln('Syntax is not valid')
    else
      Writeln('Result is: ', CompileAST(ast)());
  until false;
end;

begin
  try
    // Run all unit tests to verify program correctness.

    Writeln('Running AST creation tests ...');
    TestCreateAST;

    Writeln('Running tokenizer tests ...');
    TestGetToken;

    Writeln('Running parser test ...');
    TestParse;

    Writeln('Running AST interpreter tests ...');
    TestInterpretAST;

    Writeln('Running AST compilation tests ...');
    TestCompileAST;

    RunREPL;
  except
    on E: Exception do begin
      Writeln(E.ClassName, ': ', E.Message);
      Readln;
    end;
  end;
end.
