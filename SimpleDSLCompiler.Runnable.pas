unit SimpleDSLCompiler.Runnable;

interface

type
  TParameters = TArray<integer>;

  ISimpleDSLProgram = interface ['{2B93BEE7-EF20-41F4-B599-4C28131D6655}']
    function Call(const func: string; const params: TParameters; var return: integer): boolean;
  end; { ISimpleDSLProgram }

implementation

end.
