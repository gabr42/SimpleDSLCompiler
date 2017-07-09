unit SimpleDSLCompiler.Runnable;

interface

type
  TParameters = TArray<integer>;

  ISimpleDSLProgram = interface ['{2B93BEE7-EF20-41F4-B599-4C28131D6655}']
    function Call(const func: string; const params: TParameters): integer;
  end; { ISimpleDSLProgram }

  TSimpleDSLProgramFactory = reference to function: ISimpleDSLProgram;

function CreateSimpleDSLProgram: ISimpleDSLProgram;

implementation

type
  TSimpleDSLProgram = class(TInterfacedObject, ISimpleDSLProgram)
  public
    function Call(const func: string; const params: TParameters): integer;
  end; { TSimpleDSLProgram }

{ exports }

function CreateSimpleDSLProgram: ISimpleDSLProgram;
begin
  Result := TSimpleDSLProgram.Create;
end; { CreateSimpleDSLProgram }

function TSimpleDSLProgram.Call(const func: string; const params: TParameters): integer;
begin
  Result := 0;
  // TODO 1 -oPrimoz Gabrijelcic : implement: TSimpleDSLProgram.Call
end; { TSimpleDSLProgram.Call }

end.
