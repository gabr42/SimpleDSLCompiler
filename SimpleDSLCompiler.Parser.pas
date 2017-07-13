unit SimpleDSLCompiler.Parser;

interface

uses
  SimpleDSLCompiler.Tokenizer,
  SimpleDSLCompiler.AST;

type
  ISimpleDSLParser = interface ['{73F3CBB3-3DEF-4573-B079-7EFB00631560}']
    function Parse(const code: string; const tokenizer: ISimpleDSLTokenizer;
      const ast: ISimpleDSLAST): boolean;
  end; { ISimpleDSLParser }

  TSimpleDSLParserFactory = reference to function: ISimpleDSLParser;

function CreateSimpleDSLParser: ISimpleDSLParser;

implementation

uses
  System.Types,
  System.SysUtils,
  System.Generics.Collections,
  SimpleDSLCompiler.Base,
  SimpleDSLCompiler.ErrorInfo;

type
  TTokenKinds = set of TTokenKind;

  TSimpleDSLParser = class(TSimpleDSLCompilerBase, ISimpleDSLParser)
  strict private type
    TContext = record
      CurrentFunc   : IASTFunction;
    end;
  var
    FAST           : ISimpleDSLAST;
    FContext       : TContext;
    FTokenizer     : ISimpleDSLTokenizer;
    FLookaheadToken: TTokenKind;
    FLookaheadIdent: string;
  strict protected
    function  FetchToken(allowed: TTokenKinds; var ident: string; var token: TTokenKind): boolean; overload;
    function  FetchToken(allowed: TTokenKinds; var ident: string): boolean; overload; inline;
    function  FetchToken(allowed: TTokenKinds): boolean; overload; inline;
    function  GetToken(var token: TTokenKind; var ident: string): boolean;
    function  IsFunction(const ident: string; var funcIdx: integer): boolean;
    function  IsVariable(const ident: string; var varIdx: integer): boolean;
    function  ParseBlock(var block: IASTBlock): boolean;
    function  ParseExpression(var expression: IASTExpression): boolean;
    function  ParseExpresionList(parameters: TExpressionList): boolean;
    function  ParseFunction: boolean;
    function  ParseReturn(var statement: IASTStatement): boolean;
    function  ParseIf(var statement: IASTStatement): boolean;
    function  ParseStatement(var statement: IASTStatement): boolean;
    function  ParseTerm(var term: IASTTerm): boolean;
    procedure PushBack(token: TTokenKind; const ident: string);
    property AST: ISimpleDSLAST read FAST;
  public
    function Parse(const code: string; const tokenizer: ISimpleDSLTokenizer;
      const ast: ISimpleDSLAST): boolean;
  end; { TSimpleDSLParser }

{ exports }

function CreateSimpleDSLParser: ISimpleDSLParser;
begin
  Result := TSimpleDSLParser.Create;
end; { CreateSimpleDSLParser }

{ TSimpleDSLParser }

function TSimpleDSLParser.FetchToken(allowed: TTokenKinds; var ident: string;
  var token: TTokenKind): boolean;
var
  loc: TPoint;
begin
  Result := false;
  while GetToken(token, ident) do
    if token in allowed then
      Exit(true)
    else if token = tkWhitespace then
      // do nothing
    else begin
      loc := FTokenizer.CurrentLocation;
      LastError := Format('Invalid syntax in line %d, character %d', [loc.X, loc.Y]);
      Exit;
    end;
end; { TSimpleDSLParser.FetchToken }

function TSimpleDSLParser.FetchToken(allowed: TTokenKinds; var ident: string): boolean;
var
  token: TTokenKind;
begin
  Result := FetchToken(allowed, ident, token);
end; { TSimpleDSLParser.FetchToken }

function TSimpleDSLParser.FetchToken(allowed: TTokenKinds): boolean;
var
  ident: string;
begin
  Result := FetchToken(allowed, ident);
end; { TSimpleDSLParser.FetchToken }

function TSimpleDSLParser.GetToken(var token: TTokenKind; var ident: string): boolean;
begin
  if FLookaheadIdent <> #0 then begin
    token := FLookaheadToken;
    ident := FLookaheadIdent;
    FLookaheadIdent := #0;
    Result := true;
  end
  else 
    Result := FTokenizer.GetToken(token, ident);
end; { TSimpleDSLParser.GetToken }

function TSimpleDSLParser.IsFunction(const ident: string; var funcIdx: integer): boolean;
begin
  funcIdx := AST.Functions.IndexOf(ident);
  Result := (funcIdx >= 0);
end; { TSimpleDSLParser.IsFunction }

function TSimpleDSLParser.IsVariable(const ident: string; var varIdx: integer): boolean;
begin
  Assert(assigned(FContext.CurrentFunc), 'TSimpleDSLParser.IsVariable: No active function');

  varIdx := FContext.CurrentFunc.ParamNames.IndexOf(ident);
  Result := (varIdx >= 0);
end; { TSimpleDSLParser.IsVariable }

function TSimpleDSLParser.Parse(const code: string; const tokenizer: ISimpleDSLTokenizer;
  const ast: ISimpleDSLAST): boolean;
begin
  Result := false;
  FTokenizer := tokenizer;
  FAST := ast;
  FLookaheadIdent := #0;
  tokenizer.Initialize(code);
  while not tokenizer.IsAtEnd do
    if not ParseFunction then
      Exit;
  Result := true;
end; { TSimpleDSLParser.Parse }

function TSimpleDSLParser.ParseBlock(var block: IASTBlock): boolean;
var
  ident     : string;
  statement : IASTStatement;
  statements: TStatementList;
  token     : TTokenKind;
begin
  Result := false;

  /// block = { statement {";" statement} [";"] }

  statements := TStatementList.Create;

  try
    if not FetchToken([tkLeftCurly]) then
      Exit;

    repeat
      if not ParseStatement(statement) then
        Exit;

      statements.Add(statement);

      if not FetchToken([tkSemicolon, tkRightCurly], ident, token) then
        Exit;

      if token = tkSemicolon then begin
        // semicolon doesn't automatically force new statement; it may be followed by a curly right brace
        if not FetchToken([tkRightCurly], ident, token) then
          PushBack(token, ident);
      end;
    until token = tkRightCurly;

    block := AST.CreateBlock;
    for statement in statements do
      block.Statements.Add(statement);
  finally FreeAndNil(statements); end;
  Result := true;
end; { TSimpleDSLParser.ParseBlock }

function TSimpleDSLParser.ParseExpresionList(parameters: TExpressionList): boolean;
var
  expected: TTokenKinds;
  expr    : IASTExpression;
  ident   : string;
  token   : TTokenKind;
begin
  Result := false;

  /// "(" [expression { "," expression } ] ")"

  if not FetchToken([tkLeftParen]) then
    Exit;

  expected := [tkRightParen];

  // parameter list, including ")"
  repeat
    if FetchToken(expected, ident, token) then begin
      if token = tkRightParen then
        break; //repeat
      // else - token = tkComma, parse next expression
    end
    else if expected = [tkRightParen] then
      // only the first time around: not a ")" so try parsing it is an expression
      PushBack(token, ident)
    else
      Exit;

    Result := ParseExpression(expr);
    if not Result then
      Exit;

    parameters.Add(expr);

    Include(expected, tkComma);
  until false;

  Result := true;
end; { TSimpleDSLParser.ParseExpresionList }

function TSimpleDSLParser.ParseExpression(var expression: IASTExpression): boolean;
var
  expr : IASTExpression;
  ident: string;
  term : IASTTerm;
  token: TTokenKind;
begin
  Result := false;

  /// expression = term
  ///            | term operator term
  ///
  /// operator = "+" | "-" | "<"

  expr := AST.CreateExpression;

  if not ParseTerm(term) then
    Exit;

  expr.Term1 := term;

  if not FetchToken([tkLessThan, tkPlus, tkMinus], ident, token) then begin
    PushBack(token, ident);
    expr.BinaryOp := opNone;
  end
  else begin
    case token of
      tkLessThan: expr.BinaryOp := opCompareLess;
      tkPlus:     expr.BinaryOp := opAdd;
      tkMinus:    expr.BinaryOp := opSubtract;
      else raise Exception.Create('TSimpleDSLParser.ParseExpression: Unexpected token');
    end;
    if not ParseTerm(term) then
      Exit;
    expr.Term2 := term;
  end;

  expression := expr;
  Result := true;
end; { TSimpleDSLParser.ParseExpression }

function TSimpleDSLParser.ParseFunction: boolean;
var
  block   : IASTBlock;
  expected: TTokenKinds;
  func    : IASTFunction;
  funcName: string;
  ident   : string;
  token   : TTokenKind;
begin
  Result := false;

  /// function = identifier "(" [ identifier { "," identifier } ] ")" block

  // function name
  if not FetchToken([tkIdent], funcName, token) then
    Exit(token = tkEOF);

  func := AST.CreateFunction;
  func.Name := funcName;
  AST.Functions.Add(func); // we might need this function in the global table for recursive calls

  FContext.CurrentFunc := func;
  try

    // "("
    if not FetchToken([tkLeftParen]) then
      Exit;

    // parameter list, including ")"
    expected := [tkIdent, tkRightParen];
    repeat
      if not FetchToken(expected, ident, token) then
        Exit;
      if token = tkRightParen then
        break //repeat
      else if token = tkIdent then begin
        func.ParamNames.Add(ident);
        expected := expected - [tkIdent] + [tkComma, tkRightParen];
      end
      else if token = tkComma then
        expected := expected + [tkIdent] - [tkComma, tkRightParen]
      else begin
        LastError := 'Internal error in ParseFunction';
        Exit;
      end;
    until false;

    // function body
    if not ParseBlock(block) then
      Exit;

    func.Body := block;
    Result := true;
  finally
    FContext.CurrentFunc := nil;
  end;
end; { TSimpleDSLParser.ParseFunction }

function TSimpleDSLParser.ParseIf(var statement: IASTStatement): boolean;
var
  condition: IASTExpression;
  elseBlock: IASTBlock;
  ident    : string;
  loc      : TPoint;
  stmt     : IASTIfStatement;
  thenBlock: IASTBlock;
begin
  Result := false;

  /// if = "if" expression block "else" block
  /// ("if" was already parsed)

  if not ParseExpression(condition) then
    Exit;

  if not ParseBlock(thenBlock) then
    Exit;

  if not FetchToken([tkIdent], ident) then
    Exit;

  if not SameText(ident, 'else') then begin
    loc := FTokenizer.CurrentLocation;
    LastError := Format('"else" expected in line %d, column %d', [loc.X, loc.Y]);
    Exit;
  end;

  if not ParseBlock(elseBlock) then
    Exit;

  stmt := AST.CreateStatement(stIf) as IASTIfStatement;
  stmt.Condition := condition;
  stmt.ThenBlock := thenBlock;
  stmt.ElseBlock := elseBlock;

  statement := stmt;
  Result := true;
end; { TSimpleDSLParser.ParseIf }

function TSimpleDSLParser.ParseReturn(var statement: IASTStatement): boolean;
var
  expression: IASTExpression;
  stmt      : IASTReturnStatement;
begin
  Result := false;

  /// return = "return" expression
  /// ("return" was already parsed)

  if not ParseExpression(expression) then
    Exit;

  stmt := Ast.CreateStatement(stReturn) as IASTReturnStatement;
  stmt.Expression := expression;

  statement := stmt;
  Result := true;
end; { TSimpleDSLParser.ParseReturn }

function TSimpleDSLParser.ParseStatement(var statement: IASTStatement): boolean;
var
  ident: string;
  loc  : TPoint;
begin
  Result := false;

  /// statement = if
  ///           | return

  if not FetchToken([tkIdent], ident) then
    Exit;

  if SameText(ident, 'if') then
    Result := ParseIf(statement)
  else if SameText(ident, 'return') then
    Result := ParseReturn(statement)
  else begin
    loc := FTokenizer.CurrentLocation;
    LastError := Format('Invalid reserved word %s in line %d, column %d', [ident, loc.X, loc.Y]);
  end;
end; { TSimpleDSLParser.ParseStatement }

function TSimpleDSLParser.ParseTerm(var term: IASTTerm): boolean;
var
  constant: IASTTermConstant;
  funcCall: IASTTermFunctionCall;
  funcIdx : integer;
  ident   : string;
  loc     : TPoint;
  token   : TTokenKind;
  variable: IASTTermVariable;
  varIdx  : integer;
begin
  Result := false;

  /// term = numeric_constant
  ///      | function_call
  ///      | identifier
  ///
  /// function_call = identifier "(" [expression { "," expression } ] ")"

  if not FetchToken([tkIdent, tkNumber], ident, token) then
    Exit;

  if token = tkNumber then begin
    // parse numeric constant
    constant := AST.CreateTerm(termConstant) as IASTTermConstant;
    constant.Value := StrToInt(ident);
    term := constant;
    Result := true;
  end
  else if IsFunction(ident, funcIdx) then begin
    // parse function call
    funcCall := AST.CreateTerm(termFunctionCall) as IASTTermFunctionCall;
    funcCall.FunctionIdx := funcIdx;
    Result := ParseExpresionList(funcCall.Parameters);
    if Result then
      term := funcCall;
  end
  else if IsVariable(ident, varIdx) then begin
    // parse variable
    variable := AST.CreateTerm(termVariable) as IASTTermVariable;
    variable.VariableIdx := varIdx;
    term := variable;
    Result := true;
  end
  else begin
    loc := FTokenizer.CurrentLocation;
    LastError := Format('Unexpected token in line %d, column %d (not a number, variable, or function)', [loc.X, loc.Y]);
  end;
end; { TSimpleDSLParser.ParseTerm }

procedure TSimpleDSLParser.PushBack(token: TTokenKind; const ident: string);
begin
  Assert(FLookaheadIdent = #0, 'TSimpleDSLParser: Lookahead buffer is not empty');
  FLookaheadToken := token;
  FLookaheadIdent := ident;
end; { TSimpleDSLParser.PushBack }

end.
