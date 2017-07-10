unit SimpleDSLCompiler.AST;

interface

uses
  System.Generics.Collections;

type
  TStatementType = (stIf, stReturn);

  IASTStatement = interface ['{372AF2FA-E139-4EFB-8282-57FFE0EDAEC8}']
  end; { IASTStatement }

  IASTIfStatement = interface(IASTStatement) ['{A6BE8E87-39EC-4832-9F4A-D5BF0901DA17}']
  end; { IASTIfStatement }

  IASTReturnStatement = interface(IASTStatement) ['{61F7403E-CB08-43FC-AF37-A96B05BB2F9C}']
  end; { IASTReturnStatement }

  IASTBlock = interface ['{450D40D0-4866-4CD2-98E8-88387F5B9904}']
    function  GetStatement: IASTStatement;
    procedure SetStatement(const value: IASTStatement);
  //
    function CreateStatement(statementType: TStatementType): IASTStatement;
    property Statement: IASTStatement read GetStatement write SetStatement;
  end; { IASTBlock }

  TParameterList = TList<string>;

  IASTFunction = interface ['{FA4F603A-FE89-40D4-8F96-5607E4EBE511}']
    function  GetBody: IASTBlock;
    function  GetName: string;
    function  GetParamNames: TParameterList;
    procedure SetName(const value: string);
    procedure SetParamNames(const value: TParameterList);
  //
    property Name: string read GetName write SetName;
    property ParamNames: TParameterList read GetParamNames write SetParamNames;
    property Body: IASTBlock read GetBody;
  end; { IASTFunction }

  IASTFunctions = interface ['{95A0897F-ED13-40F5-B955-9917AC911EDB}']
    function  GetItems(idxFunction: integer): IASTFunction;
  //
    function  Add: IASTFunction;
    function  Count: integer;
    property Items[idxFunction: integer]: IASTFunction read GetItems; default;
  end; { IASTFunctions }

  ISimpleDSLAST = interface ['{114E494C-8319-45F1-91C8-4102AED1809E}']
    function GetFunctions: IASTFunctions;
  //
    property Functions: IASTFunctions read GetFunctions;
  end; { ISimpleDSLAST }

  TSimpleDSLASTFactory = reference to function: ISimpleDSLAST;

function CreateSimpleDSLAST: ISimpleDSLAST;

implementation

uses
  System.SysUtils;

type
  TASTStatement = class(TInterfacedObject, IASTStatement)
  end; { TASTStatement }

  TASTIfStatement = class(TASTStatement)
  end; { TASTIfStatement }

  TASTReturnStatement = class(TASTStatement)
  end; { TASTReturnStatement }

  TASTBlock = class(TInterfacedObject, IASTBlock)
  strict private
    FStatement: IASTStatement;
  strict protected
    function GetStatement: IASTStatement;
    procedure SetStatement(const value: IASTStatement);
  public
    function CreateStatement(statementType: TStatementType): IASTStatement;
    property Statement: IASTStatement read GetStatement write SetStatement;
  end; { IASTBlock }

  TASTFunction = class(TInterfacedObject, IASTFunction)
  strict private
    FBody      : IASTBlock;
    FName      : string;
    FParamNames: TParameterList;
  strict protected
    function  GetBody: IASTBlock;
    function  GetName: string; inline;
    function  GetParamNames: TParameterList; inline;
    procedure SetName(const value: string); inline;
    procedure SetParamNames(const value: TParameterList); inline;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    property Name: string read GetName write SetName;
    property ParamNames: TParameterList read GetParamNames write SetParamNames;
    property Body: IASTBlock read GetBody;
  end; { TASTFunction }

  TASTFunctions = class(TInterfacedObject, IASTFunctions)
  strict private
    FFunctions: TList<IASTFunction>;
  strict protected
    function  GetItems(idxFunction: integer): IASTFunction; inline;
  public
    function  Add: IASTFunction;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    function  Count: integer; inline;
    property Items[idxFunction: integer]: IASTFunction read GetItems; default;
  end; { TASTFunctions }

  TSimpleDSLAST = class(TInterfacedObject, ISimpleDSLAST)
  strict private
    FFunctions: IASTFunctions;
  public
    procedure AfterConstruction; override;
    function  GetFunctions: IASTFunctions; inline;
    property Functions: IASTFunctions read GetFunctions;
  end; { TSimpleDSLAST }

{ exports }

function CreateSimpleDSLAST: ISimpleDSLAST;
begin
  Result := TSimpleDSLAST.Create;
end; { CreateSimpleDSLAST }

function TASTBlock.CreateStatement(statementType: TStatementType): IASTStatement;
begin
  case statementType of
    stIf:     Result := TASTIfStatement.Create;
    stReturn: Result := TASTReturnStatement.Create;
    else raise Exception.Create('TASTBlock.CreateStatement: Unexpected statement type');
  end;
end; { TASTBlock.CreateStatement }

function TASTBlock.GetStatement: IASTStatement;
begin
  Result := FStatement;
end; { TASTBlock.GetStatement }

procedure TASTBlock.SetStatement(const value: IASTStatement);
begin
  FStatement := value;
end; { TASTBlock.SetStatement }

{ TASTFunction }

procedure TASTFunction.AfterConstruction;
begin
  inherited;
  FParamNames := TParameterList.Create;
end; { TASTFunction.AfterConstruction }

procedure TASTFunction.BeforeDestruction;
begin
  FreeAndNil(FParamNames);
  inherited;
end; { TASTFunction.BeforeDestruction }

function TASTFunction.GetBody: IASTBlock;
begin
  Result := FBody;
end;

function TASTFunction.GetName: string;
begin
  Result := FName;
end; { TASTFunction.GetName }

function TASTFunction.GetParamNames: TParameterList;
begin
  Result := FParamNames;
end; { TASTFunction.GetParamNames }

procedure TASTFunction.SetName(const value: string);
begin
  FName := value;
end; { TASTFunction.SetName }

procedure TASTFunction.SetParamNames(const value: TParameterList);
begin
  FParamNames := value;
end; { TASTFunction.SetParamNames }

{ TASTFunctions }

function TASTFunctions.Add: IASTFunction;
begin
  Result := TASTFunction.Create;

end; { TASTFunctions.Add }

procedure TASTFunctions.AfterConstruction;
begin
  inherited;
  FFunctions := TList<IASTFunction>.Create;
end; { TASTFunctions.AfterConstruction }

procedure TASTFunctions.BeforeDestruction;
begin
  FreeAndNil(FFunctions);
  inherited;
end; { TASTFunctions.BeforeDestruction }

function TASTFunctions.Count: integer;
begin
  Result := FFunctions.Count;
end; { TASTFunctions.Count }

function TASTFunctions.GetItems(idxFunction: integer): IASTFunction;
begin
  Result := FFunctions[idxFunction];
end; { TASTFunctions.GetItems }

{ TSimpleDSLAST }

procedure TSimpleDSLAST.AfterConstruction;
begin
  inherited;
  FFunctions := TASTFunctions.Create;
end; { TSimpleDSLAST.AfterConstruction }

function TSimpleDSLAST.GetFunctions: IASTFunctions;
begin
  Result := FFunctions;
end; { TSimpleDSLAST.GetFunctions }

end.
