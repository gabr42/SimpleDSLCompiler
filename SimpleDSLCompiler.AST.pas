unit SimpleDSLCompiler.AST;

interface

uses
  System.Generics.Collections;

type
  TASTTerm = class
  end; { TASTTerm }

  TASTTermConstant = class(TASTTerm)
  strict private
    FValue: integer;
  strict protected
    function  GetValue: integer; inline;
    procedure SetValue(const value: integer); inline;
  public
    property Value: integer read GetValue write SetValue;
  end; { TASTTermConstant }

  TASTTermVariable = class(TASTTerm)
  strict private
    FVariableIdx: integer;
  strict protected
    function  GetVariableIdx: integer; inline;
    procedure SetVariableIdx(const value: integer); inline;
  public
    property VariableIdx: integer read GetVariableIdx write SetVariableIdx;
  end; { TASTTermVariable }

  TASTExpression = class;

  TExpressionList = TList<TASTExpression>;

  TASTTermFunctionCall = class(TASTTerm)
  strict private
    FFunctionIdx: integer;
    FParameters : TExpressionList;
  strict protected
    function  GetFunctionIdx: integer; inline;
    function  GetParameters: TExpressionList; inline;
    procedure SetFunctionIdx(const value: integer); inline;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    property FunctionIdx: integer read GetFunctionIdx write SetFunctionIdx;
    property Parameters: TExpressionList read GetParameters;
  end; { IASTTermFunctionCall }

  TBinaryOperation = (opNone, opAdd, opSubtract, opCompareLess);

  TASTExpression = class
  strict private
    FBinaryOp: TBinaryOperation;
    FTerm1   : TASTTerm;
    FTerm2   : TASTTerm;
  strict protected
    function  GetBinaryOp: TBinaryOperation; inline;
    function  GetTerm1: TASTTerm; inline;
    function  GetTerm2: TASTTerm; inline;
    procedure SetBinaryOp(const value: TBinaryOperation); inline;
    procedure SetTerm1(const value: TASTTerm);
    procedure SetTerm2(const value: TASTTerm);
  public
    procedure BeforeDestruction; override;
    property BinaryOp: TBinaryOperation read GetBinaryOp write SetBinaryOp;
    property Term1: TASTTerm read GetTerm1 write SetTerm1;
    property Term2: TASTTerm read GetTerm2 write SetTerm2;
  end; { TASTExpression }

  TASTBlock = class;

  TASTStatement = class
  end; { TASTStatement }

  TASTIfStatement = class(TASTStatement)
  strict private
    FCondition: TASTExpression;
    FElseBlock: TASTBlock;
    FThenBlock: TASTBlock;
  strict protected
    function  GetCondition: TASTExpression; inline;
    function  GetElseBlock: TASTBlock; inline;
    function  GetThenBlock: TASTBlock; inline;
    procedure SetCondition(const value: TASTExpression);
    procedure SetElseBlock(const value: TASTBlock);
    procedure SetThenBlock(const value: TASTBlock);
  public
    procedure BeforeDestruction; override;
    property Condition: TASTExpression read GetCondition write SetCondition;
    property ThenBlock: TASTBlock read GetThenBlock write SetThenBlock;
    property ElseBlock: TASTBlock read GetElseBlock write SetElseBlock;
  end; { TASTIfStatement }

  TASTReturnStatement = class(TASTStatement)
  strict private
    FExpression: TASTExpression;
  strict protected
    function  GetExpression: TASTExpression; inline;
    procedure SetExpression(const value: TASTExpression);
  public
    procedure BeforeDestruction; override;
    property Expression: TASTExpression read GetExpression write SetExpression;
  end; { TASTReturnStatement }

  TStatementList = TList<TASTStatement>;

  TASTBlock = class
  strict private
    FStatements: TStatementList;
  strict protected
    function  GetStatements: TStatementList; inline;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    property Statements: TStatementList read GetStatements;
  end; { IASTBlock }

  TAttributeList = TList<string>;
  TParameterList = TList<string>;

  TASTFunction = class
  strict private
    FAttributes: TAttributeList;
    FBody      : TASTBlock;
    FName      : string;
    FParamNames: TParameterList;
  strict protected
    function  GetAttributes: TAttributeList; inline;
    function  GetBody: TASTBlock; inline;
    function  GetName: string; inline;
    function  GetParamNames: TParameterList; inline;
    procedure SetBody(const value: TASTBlock);
    procedure SetName(const value: string); inline;
    procedure SetParamNames(const value: TParameterList); inline;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    property Name: string read GetName write SetName;
    property Attributes: TAttributeList read GetAttributes;
    property ParamNames: TParameterList read GetParamNames write SetParamNames;
    property Body: TASTBlock read GetBody write SetBody;
  end; { TASTFunction }

  TASTFunctions = class
  strict private
    FFunctions: TList<TASTFunction>;
  strict protected
    function  GetItems(idxFunction: integer): TASTFunction; inline;
  public
    function  Add(const func: TASTFunction): integer;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    function  Count: integer; inline;
    function  IndexOf(const name: string): integer;
    property Items[idxFunction: integer]: TASTFunction read GetItems; default;
  end; { TASTFunctions }

  ISimpleDSLAST = interface ['{114E494C-8319-45F1-91C8-4102AED1809E}']
    function GetFunctions: TASTFunctions;
    //
    property Functions: TASTFunctions read GetFunctions;
  end; { ISimpleDSLAST }

  TSimpleDSLASTFactory = reference to function: ISimpleDSLAST;

function CreateSimpleDSLAST: ISimpleDSLAST;

implementation

uses
  System.SysUtils;

type
  TSimpleDSLAST = class(TInterfacedObject, ISimpleDSLAST)
  strict private
    FFunctions: TASTFunctions;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    function GetFunctions: TASTFunctions; inline;
    property Functions: TASTFunctions read GetFunctions;
  end; { TSimpleDSLAST }

{ exports }

function CreateSimpleDSLAST: ISimpleDSLAST;
begin
  Result := TSimpleDSLAST.Create;
end; { CreateSimpleDSLAST }

{ TASTTermConstant }

function TASTTermConstant.GetValue: integer;
begin
  Result := FValue;
end; { TASTTermConstant.GetValue }

procedure TASTTermConstant.SetValue(const value: integer);
begin
  FValue := value;
end; { TASTTermConstant.SetValue }

{ TASTTermVariable }

function TASTTermVariable.GetVariableIdx: integer;
begin
  Result := FVariableIdx;
end; { TASTTermVariable.GetVariableIdx }

procedure TASTTermVariable.SetVariableIdx(const value: integer);
begin
  FVariableIdx := value;
end; { TASTTermVariable.SetVariableIdx }

{ TASTTermFunctionCall }

procedure TASTTermFunctionCall.AfterConstruction;
begin
  inherited;
  FParameters := TExpressionList.Create;
end; { TASTTermFunctionCall.AfterConstruction }

procedure TASTTermFunctionCall.BeforeDestruction;
begin
  FreeAndNil(FParameters);
  inherited;
end; { TASTTermFunctionCall.BeforeDestruction }

function TASTTermFunctionCall.GetFunctionIdx: integer;
begin
  Result := FFunctionIdx;
end; { TASTTermFunctionCall.GetFunctionIdx }

function TASTTermFunctionCall.GetParameters: TExpressionList;
begin
  Result := FParameters;
end; { TASTTermFunctionCall.GetParameters }

procedure TASTTermFunctionCall.SetFunctionIdx(const value: integer);
begin
  FFunctionIdx := value;
end; { TASTTermFunctionCall.SetFunctionIdx }

{ TASTExpression }

procedure TASTExpression.BeforeDestruction;
begin
  FreeAndNil(FTerm1);
  FreeAndNil(FTerm2);
  inherited;
end; { TASTExpression.BeforeDestruction }

function TASTExpression.GetBinaryOp: TBinaryOperation;
begin
  Result := FBinaryOp;
end; { TASTExpression.GetBinaryOp }

function TASTExpression.GetTerm1: TASTTerm;
begin
  Result := FTerm1;
end; { TASTExpression.GetTerm1 }

function TASTExpression.GetTerm2: TASTTerm;
begin
  Result := FTerm2;
end; { TASTExpression.GetTerm2 }

procedure TASTExpression.SetBinaryOp(const value: TBinaryOperation);
begin
  FBinaryOp := value;
end; { TASTExpression.SetBinaryOp }

procedure TASTExpression.SetTerm1(const value: TASTTerm);
begin
  if value <> FTerm1 then begin
    FTerm1.Free;
    FTerm1 := value;
  end;
end; { TASTExpression.SetTerm1 }

procedure TASTExpression.SetTerm2(const value: TASTTerm);
begin
  if value <> FTerm2 then begin
    FTerm2.Free;
    FTerm2 := value;
  end;
end; { TASTExpression.SetTerm2 }

{ TASTIfStatement }

procedure TASTIfStatement.BeforeDestruction;
begin
  FreeAndNil(FCondition);
  FreeAndNil(FThenBlock);
  FreeAndNil(FElseBlock);
  inherited;
end; { TASTIfStatement.BeforeDestruction }

function TASTIfStatement.GetCondition: TASTExpression;
begin
  Result := FCondition;
end; { TASTIfStatement.GetCondition }

function TASTIfStatement.GetElseBlock: TASTBlock;
begin
  Result := FElseBlock;
end; { TASTIfStatement.GetElseBlock }

function TASTIfStatement.GetThenBlock: TASTBlock;
begin
  Result := FThenBlock;
end; { TASTIfStatement.GetThenBlock }

procedure TASTIfStatement.SetCondition(const value: TASTExpression);
begin
  if value <> FCondition then begin
    FCondition.Free;
    FCondition := value;
  end;
end; { TASTIfStatement.SetCondition }

procedure TASTIfStatement.SetElseBlock(const value: TASTBlock);
begin
  if value <> FElseBlock then begin
    FElseBlock.Free;
    FElseBlock := value;
  end;
end; { TASTIfStatement.SetElseBlock }

procedure TASTIfStatement.SetThenBlock(const value: TASTBlock);
begin
  if value <> FThenBlock then begin
    FThenBlock.Free;
    FThenBlock := value;
  end;
end; { TASTIfStatement.SetThenBlock }

{ TASTReturnStatement }

procedure TASTReturnStatement.BeforeDestruction;
begin
  FreeAndNil(FExpression);
  inherited;
end; { TASTReturnStatement.BeforeDestruction }

function TASTReturnStatement.GetExpression: TASTExpression;
begin
  Result := FExpression;
end; { TASTReturnStatement.GetExpression }

procedure TASTReturnStatement.SetExpression(const value: TASTExpression);
begin
  if value <> FExpression then begin
    FExpression.Free;
    FExpression := value;
  end;
end; { TASTReturnStatement.SetExpression }

{ TASTBlock }

procedure TASTBlock.AfterConstruction;
begin
  inherited;
  FStatements := TStatementList.Create;
end; { TASTBlock.AfterConstruction }

procedure TASTBlock.BeforeDestruction;
begin
  FreeAndNil(FStatements);
  inherited;
end; { TASTBlock.BeforeDestruction }

function TASTBlock.GetStatements: TStatementList;
begin
  Result := FStatements;
end; { TASTBlock.GetStatements }

{ TASTFunction }

procedure TASTFunction.AfterConstruction;
begin
  inherited;
  FAttributes := TAttributeList.Create;
  FParamNames := TParameterList.Create;
end; { TASTFunction.AfterConstruction }

procedure TASTFunction.BeforeDestruction;
begin
  FreeAndNil(FBody);
  FreeAndNil(FParamNames);
  FreeAndNil(FAttributes);
  inherited;
end; { TASTFunction.BeforeDestruction }

function TASTFunction.GetAttributes: TAttributeList;
begin
  Result := FAttributes;
end; { TASTFunction.GetAttributes }

function TASTFunction.GetBody: TASTBlock;
begin
  Result := FBody;
end; { TASTFunction.GetBody }

function TASTFunction.GetName: string;
begin
  Result := FName;
end; { TASTFunction.GetName }

function TASTFunction.GetParamNames: TParameterList;
begin
  Result := FParamNames;
end; { TASTFunction.GetParamNames }

procedure TASTFunction.SetBody(const value: TASTBlock);
begin
  if value <> FBody then begin
    FBody.Free;
    FBody := value;
  end;
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

function TASTFunctions.Add(const func: TASTFunction): integer;
begin
  Result := FFunctions.Add(func);
end; { TASTFunctions.Add }

procedure TASTFunctions.AfterConstruction;
begin
  inherited;
  FFunctions := TList<TASTFunction>.Create;
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

function TASTFunctions.GetItems(idxFunction: integer): TASTFunction;
begin
  Result := FFunctions[idxFunction];
end; { TASTFunctions.GetItems }

function TASTFunctions.IndexOf(const name: string): integer;
begin
  for Result := 0 to Count - 1 do
    if SameText(Items[Result].Name, name) then
      Exit;

  Result := -1;
end; { TASTFunctions.IndexOf }

{ TSimpleDSLAST }

procedure TSimpleDSLAST.AfterConstruction;
begin
  inherited;
  FFunctions := TASTFunctions.Create;
end; { TSimpleDSLAST.AfterConstruction }

procedure TSimpleDSLAST.BeforeDestruction;
begin
  FreeAndNil(FFunctions);
  inherited;
end; { TSimpleDSLAST.BeforeDestruction }

function TSimpleDSLAST.GetFunctions: TASTFunctions;
begin
  Result := FFunctions;
end; { TSimpleDSLAST.GetFunctions }

end.
