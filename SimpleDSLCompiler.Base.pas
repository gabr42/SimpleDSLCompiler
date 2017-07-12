unit SimpleDSLCompiler.Base;

interface

uses
  SimpleDSLCompiler.ErrorInfo;

type
  TSimpleDSLCompilerBase = class(TInterfacedObject, ISimpleDSLErrorInfo)
  strict private
    FLastError: string;
  protected
    function  SetError(const error: string): boolean;
    property LastError: string read FLastError write FLastError;
  public
    function  ErrorInfo: string;
  end; { TSimpleDSLCompilerBase }

implementation

function TSimpleDSLCompilerBase.ErrorInfo: string;
begin
  Result := FLastError;
end; { TSimpleDSLCompilerBase.ErrorInfo }

function TSimpleDSLCompilerBase.SetError(const error: string): boolean;
begin
  FLastError := error;
  Result := false;
end; { TSimpleDSLCompilerBase.SetError }

end.
