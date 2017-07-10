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
  strict private
    FAST      : ISimpleDSLAST;
    FTokenizer: ISimpleDSLTokenizer;
  strict protected
    function  FetchToken(allowed: TTokenKinds; skipOver: TTokenKinds;
      var ident: string; var token: TTokenKind): boolean; overload;
    function  FetchToken(allowed: TTokenKinds; var ident: string): boolean; overload; inline;
    function  FetchToken(allowed: TTokenKinds): boolean; overload; inline;
    function  ParseBlock(const block: IASTBlock): boolean;
    function  ParseFunction: boolean;
    function  ParseStatement(const block: IASTBlock; var statement: IASTStatement): boolean;
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

function TSimpleDSLParser.FetchToken(allowed: TTokenKinds; skipOver: TTokenKinds;
  var ident: string; var token: TTokenKind): boolean;
var
  loc: TPoint;
begin
  Result := false;
  while FTokenizer.GetToken(token, ident) do
    if token in allowed then
      Exit(true)
    else if (token = tkWhitespace) or (token in skipOver) then
      // do nothing
    else begin
      loc := FTokenizer.CurrentLocation;
      LastError := Format('Invalid syntax in line %d, character %d', [loc.X, loc.Y]);
    end;
end; { TSimpleDSLParser.FetchToken }

function TSimpleDSLParser.FetchToken(allowed: TTokenKinds; var ident: string): boolean;
var
  token: TTokenKind;
begin
  Result := FetchToken(allowed, [], ident, token);
end; { TSimpleDSLParser.FetchToken }

function TSimpleDSLParser.FetchToken(allowed: TTokenKinds): boolean;
var
  ident: string;
begin
  Result := FetchToken(allowed, ident);
end; { TSimpleDSLParser.FetchToken }

function TSimpleDSLParser.Parse(const code: string; const tokenizer: ISimpleDSLTokenizer;
  const ast: ISimpleDSLAST): boolean;
begin
  Result := false;
  FTokenizer := tokenizer;
  FAST := ast;
  tokenizer.Initialize(code);
  while not tokenizer.IsAtEnd do
    if not ParseFunction then
      Exit;
  Result := true;
end; { TSimpleDSLParser.Parse }

function TSimpleDSLParser.ParseBlock(const block: IASTBlock): boolean;
var
  statement: IASTStatement;
begin
  Result := false;

  if not ParseStatement(statement) then
    Exit;

  block.Statement := statement;

  if not FetchToken([tkNewLine]) then
    Exit;

  Result := true;
end; { TSimpleDSLParser.ParseBlock }

function TSimpleDSLParser.ParseFunction: boolean;
var
  expected: TTokenKinds;
  func    : IASTFunction;
  funcName: string;
  ident   : string;
  token   : TTokenKind;
begin
  Result := false;

  /// function = identifier "(" [ identifier { "," identifier } ] ")" NL block

  // function name
  if not FetchToken([tkIdent], [tkNewLine], funcName, token) then
    Exit;

  func := FAST.Functions.Add;
  func.Name := funcName;

  // (
  if not FetchToken([tkLeftParen]) then
    Exit;

  // parameter list
  expected := [tkIdent, tkRightParen];
  repeat
    if not FetchToken(expected, [], ident, token) then
      Exit;
    if token = tkRightParen then
      break //repeat
    else if token = tkIdent then begin
      func.ParamNames.Add(ident);
      expected := expected - [tkIdent] + [tkComma];
    end
    else if token = tkComma then
      expected := expected + [tkIdent] - [tkComma]
    else begin
      LastError := 'Internal error in ParseFunction';
      Exit;
    end;
  until false;

  if not FetchToken([tkNewLine]) then
    Exit;

  Result := ParseBlock(func.Body);
end; { TSimpleDSLParser.ParseFunction }

function TSimpleDSLParser.ParseStatement(const block: IASTBlock;
  var statement: IASTStatement): boolean;
var
  ident: string;
  loc  : TPoint;
begin
  Result := false;

  if not FetchToken([tkIdent], ident) then
    Exit;

  if SameText(ident, 'if') then begin
    statement := block.CreateStatement(stIf);
    Result := ParseIf(statement as IASTIfStatement);
  end
  else if SameText(ident, 'return') then begin
    statement := block.CreateStatement(stReturn);
    Result := ParseReturn(statement as IASTReturnStatement);
  end
  else begin
    loc := FTokenizer.CurrentLocation;
    LastError := Format('Invalid reserved word %s in line %d, column %d', [ident, loc.X, loc.Y]);
  end;
end; { TSimpleDSLParser.ParseStatement }

end.
