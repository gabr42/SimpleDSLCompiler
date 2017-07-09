unit SimpleDSLCompiler.Codegen;

interface

uses
  SimpleDSLCompiler.AST,
  SimpleDSLCompiler.Runnable;

type
  ISimpleDSLCodegen = interface ['{C359C174-E324-4709-86EF-EE61AFE3B1FD}']
    function Generate(const ast: ISimpleDSLAST; const runnable: ISimpleDSLProgram): boolean;
  end; { ISimpleDSLCodegen }

  TSimpleDSLCodegenFactory = reference to function: ISimpleDSLCodegen;

function CreateSimpleDSLCodegen: ISimpleDSLCodegen;

implementation

uses
  SimpleDSLCompiler.Base;

type
  TSimpleDSLCodegen = class(TSimpleDSLCompilerBase, ISimpleDSLCodegen)
  public
    function Generate(const ast: ISimpleDSLAST; const runnable: ISimpleDSLProgram): boolean;
  end; { TSimpleDSLCodegen }

{ exports }

function CreateSimpleDSLCodegen: ISimpleDSLCodegen;
begin
  Result := TSimpleDSLCodegen.Create;
end; { CreateSimpleDSLCodegen }

function TSimpleDSLCodegen.Generate(const ast: ISimpleDSLAST; const runnable:
  ISimpleDSLProgram): boolean;
begin
  Result := false;
  // TODO 1 -oPrimoz Gabrijelcic : implement: TSimpleDSLCodegen.Generate
end; { TSimpleDSLCodegen.Generate }

end.
