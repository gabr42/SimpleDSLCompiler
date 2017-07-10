unit SimpleDSLCompiler.AST;

interface

uses
  System.Generics.Collections;

type
  IASTTerm = interface ['{74B36C0D-30A4-47E6-B359-E45C4E94580C}']
  end; { IASTTerm }

  TBinaryOperation = (opNone, opAdd, opSubtract, opCompareLess);

  IASTExpression = interface ['{086BECB3-C733-4875-ABE0-EE71DCC0011D}']
    function  GetBinaryOp: TBinaryOperation;
    function  GetTerm1: IASTTerm;
    function  GetTerm2: IASTTerm;
    procedure SetBinaryOp(const value: TBinaryOperation);
    procedure SetTerm1(const value: IASTTerm);
    procedure SetTerm2(const value: IASTTerm);
  //
    property Term1: IASTTerm read GetTerm1 write SetTerm1;
    property Term2: IASTTerm read GetTerm2 write SetTerm2;
    property BinaryOp: TBinaryOperation read GetBinaryOp write SetBinaryOp;
  end; { IASTExpression }

  IASTBlock = interface;

  TStatementType = (stIf, stReturn);

  IASTStatement = interface ['{372AF2FA-E139-4EFB-8282-57FFE0EDAEC8}']
  end; { IASTStatement }

  IASTIfStatement = interface(IASTStatement) ['{A6BE8E87-39EC-4832-9F4A-D5BF0901DA17}']
    function  GetCondition: IASTExpression;
    function  GetElseBlock: IASTBlock;
    function  GetThenBlock: IASTBlock;
    procedure SetCondition(const value: IASTExpression);
    procedure SetElseBlock(const value: IASTBlock);
    procedure SetThenBlock(const value: IASTBlock);
  //
    property Condition: IASTExpression read GetCondition write SetCondition;
    property ThenBlock: IASTBlock read GetThenBlock write SetThenBlock;
    property ElseBlock: IASTBlock read GetElseBlock write SetElseBlock;
  end; { IASTIfStatement }

  IASTReturnStatement = interface(IASTStatement) ['{61F7403E-CB08-43FC-AF37-A96B05BB2F9C}']
    function  GetExpression: IASTExpression;
    procedure SetExpression(const value: IASTExpression);
  //
    property Expression: IASTExpression read GetExpression write SetExpression;
  end; { IASTReturnStatement }

  IASTBlock = interface ['{450D40D0-4866-4CD2-98E8-88387F5B9904}']
    function  GetStatement: IASTStatement;
    procedure SetStatement(const value: IASTStatement);
  //
    property Statement: IASTStatement read GetStatement write SetStatement;
  end; { IASTBlock }

  TParameterList = TList<string>;

  IASTFunction = interface ['{FA4F603A-FE89-40D4-8F96-5607E4EBE511}']
    function  GetBody: IASTBlock;
    function  GetName: string;
    function  GetParamNames: TParameterList;
    procedure SetBody(const value: IASTBlock);
    procedure SetName(const value: string);
    procedure SetParamNames(const value: TParameterList);
  //
    property Name: string read GetName write SetName;
    property ParamNames: TParameterList read GetParamNames write SetParamNames;
    property Body: IASTBlock read GetBody write SetBody;
  end; { IASTFunction }

  IASTFunctions = interface ['{95A0897F-ED13-40F5-B955-9917AC911EDB}']
    function  GetItems(idxFunction: integer): IASTFunction;
  //
    function  Add(const funct: IASTFunction): integer;
    function  Count: integer;
    property Items[idxFunction: integer]: IASTFunction read GetItems; default;
  end; { IASTFunctions }

  ISimpleDSLASTFactory = interface ['{1284482C-CA38-4D9B-A84A-B2BAED9CC8E2}']
    function  CreateBlock: IASTBlock;
    function  CreateExpression: IASTExpression;
    function  CreateFunction: IASTFunction;
    function  CreateStatement(statementType: TStatementType): IASTStatement;
    function  CreateTerm: IASTTerm;
  end; { ISimpleDSLASTFactory }

  ISimpleDSLAST = interface(ISimpleDSLASTFactory) ['{114E494C-8319-45F1-91C8-4102AED1809E}']
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
  TASTTerm = class(TInterfacedObject, IASTTerm)

  end; { TASTTerm }

  TASTExpression = class(TInterfacedObject, IASTExpression)
  strict private
    FBinaryOp: TBinaryOperation;
    FTerm1   : IASTTerm;
    FTerm2   : IASTTerm;
  strict protected
    function  GetBinaryOp: TBinaryOperation; inline;
    function  GetTerm1: IASTTerm; inline;
    function  GetTerm2: IASTTerm; inline;
    procedure SetBinaryOp(const value: TBinaryOperation); inline;
    procedure SetTerm1(const value: IASTTerm); inline;
    procedure SetTerm2(const value: IASTTerm); inline;
  public
    property Term1: IASTTerm read GetTerm1 write SetTerm1;
    property Term2: IASTTerm read GetTerm2 write SetTerm2;
    property BinaryOp: TBinaryOperation read GetBinaryOp write SetBinaryOp;
  end; { TASTExpression }

  TASTStatement = class(TInterfacedObject, IASTStatement)
  end; { TASTStatement }

  TASTIfStatement = class(TASTStatement, IASTIfStatement)
  strict private
    FCondition: IASTExpression;
    FElseBlock: IASTBlock;
    FThenBlock: IASTBlock;
  strict protected
    function  GetCondition: IASTExpression; inline;
    function  GetElseBlock: IASTBlock; inline;
    function  GetThenBlock: IASTBlock; inline;
    procedure SetCondition(const value: IASTExpression); inline;
    procedure SetElseBlock(const value: IASTBlock); inline;
    procedure SetThenBlock(const value: IASTBlock); inline;
  public
    property Condition: IASTExpression read GetCondition write SetCondition;
    property ThenBlock: IASTBlock read GetThenBlock write SetThenBlock;
    property ElseBlock: IASTBlock read GetElseBlock write SetElseBlock;
  end; { TASTIfStatement }

  TASTReturnStatement = class(TASTStatement, IASTReturnStatement)
  strict private
    FExpression: IASTExpression;
  strict protected
    function  GetExpression: IASTExpression; inline;
    procedure SetExpression(const value: IASTExpression); inline;
  public
    property Expression: IASTExpression read GetExpression write SetExpression;
  end; { TASTReturnStatement }

  TASTBlock = class(TInterfacedObject, IASTBlock)
  strict private
    FStatement: IASTStatement;
  strict protected
    function  GetStatement: IASTStatement;
    procedure SetStatement(const value: IASTStatement);
  public
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
    procedure SetBody(const value: IASTBlock); inline;
    procedure SetName(const value: string); inline;
    procedure SetParamNames(const value: TParameterList); inline;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    property Name: string read GetName write SetName;
    property ParamNames: TParameterList read GetParamNames write SetParamNames;
    property Body: IASTBlock read GetBody write SetBody;
  end; { TASTFunction }

  TASTFunctions = class(TInterfacedObject, IASTFunctions)
  strict private
    FFunctions: TList<IASTFunction>;
  strict protected
    function  GetItems(idxFunction: integer): IASTFunction; inline;
  public
    function  Add(const funct: IASTFunction): integer;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    function  Count: integer; inline;
    property Items[idxFunction: integer]: IASTFunction read GetItems; default;
  end; { TASTFunctions }

  TSimpleDSLASTMaker = class(TInterfacedObject, ISimpleDSLASTFactory)
  public
    function  CreateBlock: IASTBlock;
    function  CreateExpression: IASTExpression;
    function  CreateFunction: IASTFunction;
    function  CreateStatement(statementType: TStatementType): IASTStatement;
    function  CreateTerm: IASTTerm;
  end; { TSimpleDSLASTMaker }

  TSimpleDSLAST = class(TSimpleDSLASTMaker, ISimpleDSLAST)
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

{ TASTExpression }

function TASTExpression.GetBinaryOp: TBinaryOperation;
begin
  Result := FBinaryOp;
end; { TASTExpression.GetBinaryOp }

function TASTExpression.GetTerm1: IASTTerm;
begin
  Result := FTerm1;
end; { TASTExpression.GetTerm1 }

function TASTExpression.GetTerm2: IASTTerm;
begin
  Result := FTerm2;
end; { TASTExpression.GetTerm2 }

procedure TASTExpression.SetBinaryOp(const value: TBinaryOperation);
begin
  FBinaryOp := value;
end; { TASTExpression.SetBinaryOp }

procedure TASTExpression.SetTerm1(const value: IASTTerm);
begin
  FTerm1 := value;
end; { TASTExpression.SetTerm1 }

procedure TASTExpression.SetTerm2(const value: IASTTerm);
begin
  FTerm2 := value;
end; { TASTExpression.SetTerm2 }

{ TASTIfStatement }

function TASTIfStatement.GetCondition: IASTExpression;
begin
  Result := FCondition;
end; { TASTIfStatement.GetCondition }

function TASTIfStatement.GetElseBlock: IASTBlock;
begin
  Result := FElseBlock;
end; { TASTIfStatement.GetElseBlock }

function TASTIfStatement.GetThenBlock: IASTBlock;
begin
  Result := FThenBlock;
end; { TASTIfStatement.GetThenBlock }

procedure TASTIfStatement.SetCondition(const value: IASTExpression);
begin
  FCondition := value;
end; { TASTIfStatement.SetCondition }

procedure TASTIfStatement.SetElseBlock(const value: IASTBlock);
begin
  FElseBlock := value;
end; { TASTIfStatement.SetElseBlock }

procedure TASTIfStatement.SetThenBlock(const value: IASTBlock);
begin
  FThenBlock := value;
end; { TASTIfStatement.SetThenBlock }

{ TASTReturnStatement }

function TASTReturnStatement.GetExpression: IASTExpression;
begin
  Result := FExpression;
end; { TASTReturnStatement.GetExpression }

procedure TASTReturnStatement.SetExpression(const value: IASTExpression);
begin
  FExpression := value;
end; { TASTReturnStatement.SetExpression }

{ TASTBlock }

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

procedure TASTFunction.SetBody(const value: IASTBlock);
begin
  FBody := value;
end; { TASTFunction.SetBody }

procedure TASTFunction.SetName(const value: string);
begin
  FName := value;
end; { TASTFunction.SetName }

procedure TASTFunction.SetParamNames(const value: TParameterList);
begin
  FParamNames := value;
end; { TASTFunction.SetParamNames }

{ TASTFunctions }

function TASTFunctions.Add(const funct: IASTFunction): integer;
begin
  Result := FFunctions.Add(funct);
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

{ TSimpleDSLASTMaker }

function TSimpleDSLASTMaker.CreateBlock: IASTBlock;
begin
  Result := TASTBlock.Create;
end; { TSimpleDSLASTMaker.CreateBlock }

function TSimpleDSLASTMaker.CreateExpression: IASTExpression;
begin
  Result := TASTExpression.Create;
end; { TSimpleDSLASTMaker.CreateExpression }

function TSimpleDSLASTMaker.CreateFunction: IASTFunction;
begin
  Result := TASTFunction.Create;
end; { TSimpleDSLASTMaker.CreateFunction }

function TSimpleDSLASTMaker.CreateStatement(statementType: TStatementType): IASTStatement;
begin
  case statementType of
    stIf:     Result := TASTIfStatement.Create;
    stReturn: Result := TASTReturnStatement.Create;
    else raise Exception.Create('<AST Factory> CreateStatement: Unexpected statement type');
  end;
end; { TSimpleDSLASTMaker.CreateStatement }

function TSimpleDSLASTMaker.CreateTerm: IASTTerm;
begin
  Result := TASTTerm.Create;
end; { TSimpleDSLASTMaker.CreateTerm }

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
