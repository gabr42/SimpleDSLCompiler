unit SimpleDSLCompiler;

/// DSL definition
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
  SimpleDSLCompiler.Compiler;

type
  ISimpleDSLCompiler = interface ['{7CF78EC7-023B-4571-B310-42873921B0BC}']
    function  GetAST: ISimpleDSLAST;
    function  GetASTFactory: TSimpleDSLASTFactory;
    function  GetCodegenFactory: TSimpleDSLCodegenFactory;
    function  GetParserFactory: TSimpleDSLParserFactory;
    function  GetTokenizerFactory: TSimpleDSLTokenizerFactory;
    procedure SetASTFactory(const value: TSimpleDSLASTFactory);
    procedure SetCodegenFactory(const value: TSimpleDSLCodegenFactory);
    procedure SetParserFactory(const value: TSimpleDSLParserFactory);
    procedure SetTokenizerFactory(const value: TSimpleDSLTokenizerFactory);
  //
    function Compile(const code: string): ISimpleDSLProgram;
    property AST: ISimpleDSLAST read GetAST;
    property ASTFactory: TSimpleDSLASTFactory read GetASTFactory write SetASTFactory;
    property CodegenFactory: TSimpleDSLCodegenFactory read GetCodegenFactory write SetCodegenFactory;
    property ParserFactory: TSimpleDSLParserFactory read GetParserFactory write SetParserFactory;
    property TokenizerFactory: TSimpleDSLTokenizerFactory read GetTokenizerFactory write SetTokenizerFactory;
  end; { TSimpleDSLCompiler }

function CreateSimpleDSLCompiler: ISimpleDSLCompiler;

implementation

uses
  SimpleDSLCompiler.Base,
  SimpleDSLCompiler.ErrorInfo;

type
  TSimpleDSLCompiler = class(TSimpleDSLCompilerBase, ISimpleDSLCompiler)
  strict private
    FAST             : ISimpleDSLAST;
    FASTFactory      : TSimpleDSLASTFactory;
    FCodegenFactory  : TSimpleDSLCodegenFactory;
    FParserFactory   : TSimpleDSLParserFactory;
    FTokenizerFactory: TSimpleDSLTokenizerFactory;
  strict protected
    function  GetAST: ISimpleDSLAST;
    function  GetASTFactory: TSimpleDSLASTFactory; inline;
    function  GetCodegenFactory: TSimpleDSLCodegenFactory; inline;
    function  GetParserFactory: TSimpleDSLParserFactory; inline;
    function  GetTokenizerFactory: TSimpleDSLTokenizerFactory; inline;
    procedure SetASTFactory(const value: TSimpleDSLASTFactory); inline;
    procedure SetCodegenFactory(const value: TSimpleDSLCodegenFactory); inline;
    procedure SetParserFactory(const value: TSimpleDSLParserFactory); inline;
    procedure SetTokenizerFactory(const value: TSimpleDSLTokenizerFactory); inline;
  public
    constructor Create;
    function  Compile(const code: string): ISimpleDSLProgram;
    property AST: ISimpleDSLAST read GetAST;
    property ASTFactory: TSimpleDSLASTFactory read GetASTFactory write SetASTFactory;
    property CodegenFactory: TSimpleDSLCodegenFactory read GetCodegenFactory write SetCodegenFactory;
    property ParserFactory: TSimpleDSLParserFactory read GetParserFactory write SetParserFactory;
    property TokenizerFactory: TSimpleDSLTokenizerFactory read GetTokenizerFactory write SetTokenizerFactory;
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
  TokenizerFactory := CreateSimpleDSLTokenizer;
end; { TSimpleDSLCompiler.Create }

function TSimpleDSLCompiler.Compile(const code: string): ISimpleDSLProgram;
var
  codegen  : ISimpleDSLCodegen;
  parser   : ISimpleDSLParser;
  tokenizer: ISimpleDSLTokenizer;
begin
  LastError := '';
  parser := ParserFactory();
  tokenizer := TokenizerFactory();
  FAST := ASTFactory();
  if not parser.Parse(code, tokenizer, FAST) then begin
    FAST := nil;
    LastError := (parser as ISimpleDSLErrorInfo).ErrorInfo;
  end
  else begin
    codegen := CodegenFactory();
    if not codegen.Generate(FAST, Result) then
      LastError := (codegen as ISimpleDSLErrorInfo).ErrorInfo;
  end;
end; { TSimpleDSLCompiler.Compile }

function TSimpleDSLCompiler.GetAST: ISimpleDSLAST;
begin
  Result := FAST;
end; { TSimpleDSLCompiler.GetAST }

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

procedure TSimpleDSLCompiler.SetTokenizerFactory(const value: TSimpleDSLTokenizerFactory);
begin
  FTokenizerFactory := value;
end; { TSimpleDSLCompiler.SetTokenizerFactory }

end.
