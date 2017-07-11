unit SimpleDSLCompiler.Codegen;

interface

uses
  SimpleDSLCompiler.AST,
  SimpleDSLCompiler.Runnable;

type
  ISimpleDSLCodegen = interface ['{C359C174-E324-4709-86EF-EE61AFE3B1FD}']
    function Generate(const ast: ISimpleDSLAST; var runnable: ISimpleDSLProgram): boolean;
  end; { ISimpleDSLCodegen }

  TSimpleDSLCodegenFactory = reference to function: ISimpleDSLCodegen;

function CreateSimpleDSLCodegen: ISimpleDSLCodegen;

implementation

uses
  SimpleDSLCompiler.Base;

type
  TSimpleDSLProgram = class(TSimpleDSLCompilerBase, ISimpleDSLProgram)
  public
    function Call(const func: string; const params: TParameters; var return: integer): boolean;
  end; { TSimpleDSLProgram }

  TSimpleDSLCodegen = class(TSimpleDSLCompilerBase, ISimpleDSLCodegen)
  public
    function Generate(const ast: ISimpleDSLAST; var runnable: ISimpleDSLProgram): boolean;
  end; { TSimpleDSLCodegen }

{ exports }

function CreateSimpleDSLCodegen: ISimpleDSLCodegen;
begin
  Result := TSimpleDSLCodegen.Create;
end; { CreateSimpleDSLCodegen }

{ TSimpleDSLProgram }

function TSimpleDSLProgram.Call(const func: string; const params: TParameters; var
  return: integer): boolean;
begin
  Result := false;
end; { TSimpleDSLProgram.Call }

{ TSimpleDSLCodegen }

function TSimpleDSLCodegen.Generate(const ast: ISimpleDSLAST; var runnable:
  ISimpleDSLProgram): boolean;
begin
  Result := false;
  // TODO 1 -oPrimoz Gabrijelcic : implement: TSimpleDSLCodegen.Generate
end; { TSimpleDSLCodegen.Generate }

end.
