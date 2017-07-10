unit SimpleDSLCompiler.Base;

interface

uses
  SimpleDSLCompiler.ErrorInfo;

type
  TSimpleDSLCompilerBase = class(TInterfacedObject, ISimpleDSLErrorInfo)
  strict private
    FLastError: string;
  strict protected
    procedure SetLastError(const value: string);
  protected
    property LastError: string read FLastError write SetLastError;
  public
    function  ErrorInfo: string;
  end; { TSimpleDSLCompilerBase }

implementation

function TSimpleDSLCompilerBase.ErrorInfo: string;
begin
  Result := FLastError;
end; { TSimpleDSLCompilerBase.ErrorInfo }

procedure TSimpleDSLCompilerBase.SetLastError(const value: string);
begin
  FLastError := value;
end;

end.
