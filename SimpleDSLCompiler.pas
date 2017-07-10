unit SimpleDSLCompiler;

/// DSL definition
///
/// NL = #13#10
///
/// program = {function}
///
/// function = identifier "(" [ identifier { "," identifier } ] ")" block
///
/// block = { statement }
///
/// statement = if
///           | return
///
/// if = "if" expression block "else" block
///
/// return = "return" expression
///
/// expression = term
///            | term operator term
///
/// term = numeric_constant
///      | function_call
///      | identifier
///
/// operator = "+" | "-" | "<"
///
/// function_call = identifier "(" [expression { "," expression } ] ")"
///
/// - Spacing is ignored.
/// - Only data type is integer.
/// - "If" executes "then" block if expression is <> 0 and "else" block if expression = 0.
/// - There is no assignment.
/// - A block can only contain one statement
/// - Parameters are always passed by value.
/// - "Return" just sets a return value, it doesn't interrupt control flow.
/// - Function without a "return" statement returns 0.
///
/// Example:
/// fib(i) {
///   if i < 2 {
///     return 1
///   } else {
///     return fib(i-2) + fib(i-1)
///   }
/// }
///
/// mult(a,b) {
///   if b < 2 {
///     return a
///   } else {
///     return mult(a, b-1) + a
///   }
/// }

interface

uses
  SimpleDSLCompiler.Runnable,
  SimpleDSLCompiler.AST,
  SimpleDSLCompiler.Tokenizer,
  SimpleDSLCompiler.Parser,
  SimpleDSLCompiler.Codegen;

type
  ISimpleDSLCompiler = interface ['{7CF78EC7-023B-4571-B310-42873921B0BC}']
    function  GetASTFactory: TSimpleDSLASTFactory;
    function  GetCodegenFactory: TSimpleDSLCodegenFactory;
    function  GetParserFactory: TSimpleDSLParserFactory;
    function  GetProgramFactory: TSimpleDSLProgramFactory;
    function  GetTokenizerFactory: TSimpleDSLTokenizerFactory;
    procedure SetASTFactory(const value: TSimpleDSLASTFactory);
    procedure SetCodegenFactory(const value: TSimpleDSLCodegenFactory);
    procedure SetParserFactory(const value: TSimpleDSLParserFactory);
    procedure SetProgramFactory(const value: TSimpleDSLProgramFactory);
    procedure SetTokenizerFactory(const value: TSimpleDSLTokenizerFactory);
  //
    function Compile(const code: string): ISimpleDSLProgram;
    property ASTFactory: TSimpleDSLASTFactory read GetASTFactory write SetASTFactory;
    property CodegenFactory: TSimpleDSLCodegenFactory read GetCodegenFactory write
      SetCodegenFactory;
    property ParserFactory: TSimpleDSLParserFactory read GetParserFactory write
      SetParserFactory;
    property ProgramFactory: TSimpleDSLProgramFactory read GetProgramFactory write
      SetProgramFactory;
    property TokenizerFactory: TSimpleDSLTokenizerFactory read GetTokenizerFactory write
      SetTokenizerFactory;
  end; { TSimpleDSLCompiler }

function CreateSimpleDSLCompiler: ISimpleDSLCompiler;

implementation

uses
  SimpleDSLCompiler.Base,
  SimpleDSLCompiler.ErrorInfo;

type
  TSimpleDSLCompiler = class(TSimpleDSLCompilerBase, ISimpleDSLCompiler)
  strict private
    FASTFactory    : TSimpleDSLASTFactory;
    FCodegenFactory: TSimpleDSLCodegenFactory;
    FParserFactory : TSimpleDSLParserFactory;
    FProgramFactory: TSimpleDSLProgramFactory;
    FTokenizerFactory: TSimpleDSLTokenizerFactory;
  strict protected
    function  GetASTFactory: TSimpleDSLASTFactory; inline;
    function  GetCodegenFactory: TSimpleDSLCodegenFactory; inline;
    function  GetParserFactory: TSimpleDSLParserFactory; inline;
    function  GetProgramFactory: TSimpleDSLProgramFactory; inline;
    function  GetTokenizerFactory: TSimpleDSLTokenizerFactory; inline;
    procedure SetASTFactory(const value: TSimpleDSLASTFactory); inline;
    procedure SetCodegenFactory(const value: TSimpleDSLCodegenFactory); inline;
    procedure SetParserFactory(const value: TSimpleDSLParserFactory); inline;
    procedure SetProgramFactory(const value: TSimpleDSLProgramFactory); inline;
    procedure SetTokenizerFactory(const value: TSimpleDSLTokenizerFactory); inline;
  public
    constructor Create;
    function  Compile(const code: string): ISimpleDSLProgram;
    property ASTFactory: TSimpleDSLASTFactory read GetASTFactory write SetASTFactory;
    property CodegenFactory: TSimpleDSLCodegenFactory read GetCodegenFactory write
      SetCodegenFactory;
    property ParserFactory: TSimpleDSLParserFactory read GetParserFactory write
      SetParserFactory;
    property ProgramFactory: TSimpleDSLProgramFactory read GetProgramFactory write
      SetProgramFactory;
    property TokenizerFactory: TSimpleDSLTokenizerFactory read GetTokenizerFactory write
      SetTokenizerFactory;
  end; { TSimpleDSLCompiler }

{ exports }

function CreateSimpleDSLCompiler: ISimpleDSLCompiler;
begin
  Result := TSimpleDSLCompiler.Create;
end; { CreateSimpleDSLCompiler }

{ TSimpleDSLCompiler }

constructor TSimpleDSLCompiler.Create;
begin
  inherited Create;
  ASTFactory := CreateSimpleDSLAST;
  CodegenFactory := CreateSimpleDSLCodegen;
  ParserFactory := CreateSimpleDSLParser;
  ProgramFactory := CreateSimpleDSLProgram;
  TokenizerFactory := CreateSimpleDSLTokenizer;
end; { TSimpleDSLCompiler.Create }

function TSimpleDSLCompiler.Compile(const code: string): ISimpleDSLProgram;
var
  ast      : ISimpleDSLAST;
  codegen  : ISimpleDSLCodegen;
  parser   : ISimpleDSLParser;
  tokenizer: ISimpleDSLTokenizer;
begin
  LastError := '';
  parser := ParserFactory();
  tokenizer := TokenizerFactory();
  ast := ASTFactory();
  if not parser.Parse(code, tokenizer, ast) then
    LastError := (parser as ISimpleDSLErrorInfo).ErrorInfo
  else begin
    codegen := CodegenFactory();
    Result := ProgramFactory();
    if not codegen.Generate(ast, Result) then
      LastError := (codegen as ISimpleDSLErrorInfo).ErrorInfo;
  end;
end; { TSimpleDSLCompiler.Compile }

function TSimpleDSLCompiler.GetASTFactory: TSimpleDSLASTFactory;
begin
  Result := FASTFactory;
end; { TSimpleDSLCompiler.GetASTFactory }

function TSimpleDSLCompiler.GetCodegenFactory: TSimpleDSLCodegenFactory;
begin
  Result := FCodegenFactory;
end; { TSimpleDSLCompiler.GetCodegenFactory }

function TSimpleDSLCompiler.GetParserFactory: TSimpleDSLParserFactory;
begin
  Result := FParserFactory;
end; { TSimpleDSLCompiler.GetParserFactory }

function TSimpleDSLCompiler.GetProgramFactory: TSimpleDSLProgramFactory;
begin
  Result := FProgramFactory;
end; { TSimpleDSLCompiler.GetProgramFactory }

function TSimpleDSLCompiler.GetTokenizerFactory: TSimpleDSLTokenizerFactory;
begin
  Result := FTokenizerFactory;
end; { TSimpleDSLCompiler.GetTokenizerFactory }

procedure TSimpleDSLCompiler.SetASTFactory(const value: TSimpleDSLASTFactory);
begin
  FASTFactory := value;
end; { TSimpleDSLCompiler.SetASTFactory }

procedure TSimpleDSLCompiler.SetCodegenFactory(const value: TSimpleDSLCodegenFactory);
begin
  FCodegenFactory := value;
end; { TSimpleDSLCompiler.SetCodegenFactory }

procedure TSimpleDSLCompiler.SetParserFactory(const value: TSimpleDSLParserFactory);
begin
  FParserFactory := value;
end; { TSimpleDSLCompiler.SetParserFactory }

procedure TSimpleDSLCompiler.SetProgramFactory(const value: TSimpleDSLProgramFactory);
begin
  FProgramFactory := value;
end; { TSimpleDSLCompiler.SetProgramFactory }

procedure TSimpleDSLCompiler.SetTokenizerFactory(const value: TSimpleDSLTokenizerFactory);
begin
  FTokenizerFactory := value;
end; { TSimpleDSLCompiler.SetTokenizerFactory }

end.
