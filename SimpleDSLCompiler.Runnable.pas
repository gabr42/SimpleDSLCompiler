unit SimpleDSLCompiler.Runnable;

interface

uses
  System.SysUtils;

type
  TParameters = TArray<integer>;
  TFunctionCall = reference to function (const parameters: TParameters): integer;

  ISimpleDSLProgram = interface ['{2B93BEE7-EF20-41F4-B599-4C28131D6655}']
    function  Call(const functionName: string; const params: TParameters; var return: integer): boolean;
    function  Make(const functionName: string): TFunctionCall;
  end; { ISimpleDSLProgram }

implementation

end.
