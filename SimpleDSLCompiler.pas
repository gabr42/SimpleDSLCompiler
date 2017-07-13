unit SimpleDSLCompiler;

/// DSL definition
///
/// program = {function}
///
/// function = identifier "(" [ identifier { "," identifier } ] ")" block
///
/// block = { statement {";" statement} [";"] }
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
/// - Only operations are: +, -, <.
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
    function  GetCode: ISimpleDSLProgram;
    function  GetCodegenFactory: TSimpleDSLCodegenFactory;
    function  GetParserFactory: TSimpleDSLParserFactory;
    function  GetTokenizerFactory: TSimpleDSLTokenizerFactory;
    procedure SetASTFactory(const value: TSimpleDSLASTFactory);
    procedure SetCodegenFactory(const value: TSimpleDSLCodegenFactory);
    procedure SetParserFactory(const value: TSimpleDSLParserFactory);
    procedure SetTokenizerFactory(const value: TSimpleDSLTokenizerFactory);
  //
    function  Codegen: boolean;
    function  Compile(const code: string): boolean;
    function  Parse(const code: string): boolean;
    property AST: ISimpleDSLAST read GetAST;
    property Code: ISimpleDSLProgram read GetCode;
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
    FCode            : ISimpleDSLProgram;
    FCodegenFactory  : TSimpleDSLCodegenFactory;
    FParserFactory   : TSimpleDSLParserFactory;
    FTokenizerFactory: TSimpleDSLTokenizerFactory;
  strict protected
    function  GetAST: ISimpleDSLAST;
    function  GetASTFactory: TSimpleDSLASTFactory; inline;
    function  GetCode: ISimpleDSLProgram; inline;
    function  GetCodegenFactory: TSimpleDSLCodegenFactory; inline;
    function  GetParserFactory: TSimpleDSLParserFactory; inline;
    function  GetTokenizerFactory: TSimpleDSLTokenizerFactory; inline;
    procedure SetASTFactory(const value: TSimpleDSLASTFactory); inline;
    procedure SetCodegenFactory(const value: TSimpleDSLCodegenFactory); inline;
    procedure SetParserFactory(const value: TSimpleDSLParserFactory); inline;
    procedure SetTokenizerFactory(const value: TSimpleDSLTokenizerFactory); inline;
  public
    constructor Create;
    function  Codegen: boolean;
    function  Compile(const code: string): boolean;
    function  Parse(const code: string): boolean;
    property AST: ISimpleDSLAST read GetAST;
    property Code: ISimpleDSLProgram read GetCode;
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

function TSimpleDSLCompiler.Codegen: boolean;
var
  codegen  : ISimpleDSLCodegen;
begin
  LastError := '';
  if not assigned(FAST) then
    Exit(SetError('Nothing to do'))
  else begin
    codegen := CodegenFactory();
    Result := codegen.Generate(FAST, FCode);
    if not Result then begin
      FCode := nil;
      LastError := (codegen as ISimpleDSLErrorInfo).ErrorInfo;
    end;
  end;
end; { TSimpleDSLCompiler.Codegen }

function TSimpleDSLCompiler.Compile(const code: string): boolean;
begin
  Result := Parse(code);
  if Result then
    Result := Codegen;
end; { TSimpleDSLCompiler.Compile }

function TSimpleDSLCompiler.GetAST: ISimpleDSLAST;
begin
  Result := FAST;
end; { TSimpleDSLCompiler.GetAST }

function TSimpleDSLCompiler.GetASTFactory: TSimpleDSLASTFactory;
begin
  Result := FASTFactory;
end; { TSimpleDSLCompiler.GetASTFactory }

function TSimpleDSLCompiler.GetCode: ISimpleDSLProgram;
begin
  Result := FCode;
end; { TSimpleDSLCompiler.GetCode }

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

function TSimpleDSLCompiler.Parse(const code: string): boolean;
var
  parser   : ISimpleDSLParser;
  tokenizer: ISimpleDSLTokenizer;
begin
  LastError := '';
  parser := ParserFactory();
  tokenizer := TokenizerFactory();
  FAST := ASTFactory();
  Result := parser.Parse(code, tokenizer, FAST);
  if not Result then begin
    FAST := nil;
    LastError := (parser as ISimpleDSLErrorInfo).ErrorInfo;
  end
end; { TSimpleDSLCompiler.Parse }

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
