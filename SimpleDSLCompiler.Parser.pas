unit SimpleDSLCompiler.Parser;

interface

uses
  SimpleDSLCompiler.AST;

type
  ISimpleDSLParser = interface ['{73F3CBB3-3DEF-4573-B079-7EFB00631560}']
    function Parse(const code: string; const ast: ISimpleDSLAST): boolean;
  end; { ISimpleDSLParser }

  TSimpleDSLParserFactory = reference to function: ISimpleDSLParser;

function CreateSimpleDSLParser: ISimpleDSLParser;

implementation

uses
  SimpleDSLCompiler.Base,
  SimpleDSLCompiler.ErrorInfo;

type
  TSimpleDSLParser = class(TSimpleDSLCompilerBase, ISimpleDSLParser)
  public
    function Parse(const code: string; const ast: ISimpleDSLAST): boolean;
  end; { TSimpleDSLParser }

{ exports }

function CreateSimpleDSLParser: ISimpleDSLParser;
begin
  Result := TSimpleDSLParser.Create;
end; { CreateSimpleDSLParser }

{ TSimpleDSLParser }

function TSimpleDSLParser.Parse(const code: string; const ast: ISimpleDSLAST): boolean;
begin
  Result := false;
  // TODO 1 -oPrimoz Gabrijelcic : implement: TSimpleDSLParser.Parse
end; { TSimpleDSLParser.Parse }

end.
