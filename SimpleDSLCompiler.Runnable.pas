unit SimpleDSLCompiler.Runnable;

interface

type
  TParameters = TArray<integer>;

  ISimpleDSLProgram = interface ['{2B93BEE7-EF20-41F4-B599-4C28131D6655}']
    function Call(const func: string; const params: TParameters; var return: integer): boolean;
  end; { ISimpleDSLProgram }

  TSimpleDSLProgramFactory = reference to function: ISimpleDSLProgram;

function CreateSimpleDSLProgram: ISimpleDSLProgram;

implementation

uses
  SimpleDSLCompiler.Base;

type
  TSimpleDSLProgram = class(TSimpleDSLCompilerBase, ISimpleDSLProgram)
  public
    function Call(const func: string; const params: TParameters; var return: integer): boolean;
  end; { TSimpleDSLProgram }

{ exports }

function CreateSimpleDSLProgram: ISimpleDSLProgram;
begin
  Result := TSimpleDSLProgram.Create;
end; { CreateSimpleDSLProgram }

function TSimpleDSLProgram.Call(const func: string; const params: TParameters;
  var return: integer): boolean;
begin
  Result := false;
  // TODO 1 -oPrimoz Gabrijelcic : implement: TSimpleDSLProgram.Call
end; { TSimpleDSLProgram.Call }

end.
