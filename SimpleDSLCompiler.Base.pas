unit SimpleDSLCompiler.Base;

interface

uses
  SimpleDSLCompiler.ErrorInfo;

type
  TSimpleDSLCompilerBase = class(TInterfacedObject, ISimpleDSLErrorInfo)
  strict private
    FLastError: string;
  protected
    property LastError: string read FLastError write FLastError;
  public
    function  ErrorInfo: string;
  end; { TSimpleDSLCompilerBase }

implementation

function TSimpleDSLCompilerBase.ErrorInfo: string;
begin
  Result := FLastError;
end; { TSimpleDSLCompilerBase.ErrorInfo }

end.
