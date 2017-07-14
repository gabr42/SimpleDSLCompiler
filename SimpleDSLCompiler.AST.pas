unit SimpleDSLCompiler.AST;

interface

uses
  System.Generics.Collections;

type
  TASTTermType = (termConstant, termVariable, termFunctionCall);

  TASTTerm = class(TInterfacedObject, IASTTerm)
  end; { TASTTerm }

  TASTTermConstant = class(TASTTerm, IASTTermConstant)
  strict private
    FValue: integer;
  strict protected
    function  GetValue: integer; inline;
    procedure SetValue(const value: integer); inline;
  public
    property Value: integer read GetValue write SetValue;
  end; { TASTTermConstant }

  TASTTermVariable = class(TASTTerm, IASTTermVariable)
  strict private
    FVariableIdx: integer;
  strict protected
    function  GetVariableIdx: integer; inline;
    procedure SetVariableIdx(const value: integer); inline;
  public
    property VariableIdx: integer read GetVariableIdx write SetVariableIdx;
  end; { TASTTermVariable }

  TExpressionList = TList<IASTExpression>;

  TASTTermFunctionCall = class(TASTTerm, IASTTermFunctionCall)
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

  TASTStatementType = (stIf, stReturn);

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

  TStatementList = TList<IASTStatement>;

  TASTBlock = class(TInterfacedObject, IASTBlock)
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

  TASTFunction = class(TInterfacedObject, IASTFunction)
  strict private
    FAttributes: TAttributeList;
    FBody      : IASTBlock;
    FName      : string;
    FParamNames: TParameterList;
  strict protected
    function  GetAttributes: TAttributeList; inline;
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
    property Attributes: TAttributeList read GetAttributes;
    property ParamNames: TParameterList read GetParamNames write SetParamNames;
    property Body: IASTBlock read GetBody write SetBody;
  end; { TASTFunction }

  TASTFunctions = class(TInterfacedObject, IASTFunctions)
  strict private
    FFunctions: TList<IASTFunction>;
  strict protected
    function  GetItems(idxFunction: integer): IASTFunction; inline;
  public
    function  Add(const func: IASTFunction): integer;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    function  Count: integer; inline;
    function  IndexOf(const name: string): integer;
    property Items[idxFunction: integer]: IASTFunction read GetItems; default;
  end; { TASTFunctions }

  TSimpleDSLASTMaker = class(TInterfacedObject, ISimpleDSLASTFactory)
  public
    function  CreateBlock: IASTBlock;
    function  CreateExpression: IASTExpression;
    function  CreateFunction: IASTFunction;
    function  CreateStatement(statementType: TASTStatementType): IASTStatement;
    function  CreateTerm(termType: TASTTermType): IASTTerm;
  end; { TSimpleDSLASTMaker }

  TSimpleDSLAST = class(TSimpleDSLASTMaker, ISimpleDSLAST)
  strict private
    FFunctions: IASTFunctions;
  public
    procedure AfterConstruction; override;
    function  GetFunctions: IASTFunctions; inline;
    property Functions: IASTFunctions read GetFunctions;
  end; { TSimpleDSLAST }

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
  FreeAndNil(FParamNames);
  FreeAndNil(FAttributes);
  inherited;
end; { TASTFunction.BeforeDestruction }

function TASTFunction.GetAttributes: TAttributeList;
begin
  Result := FAttributes;
end; { TASTFunction.GetAttributes }

function TASTFunction.GetBody: IASTBlock;
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

function TASTFunctions.Add(const func: IASTFunction): integer;
begin
  Result := FFunctions.Add(func);
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

function TASTFunctions.IndexOf(const name: string): integer;
begin
  for Result := 0 to Count - 1 do
    if SameText(Items[Result].Name, name) then
      Exit;

  Result := -1;
end; { TASTFunctions.IndexOf }

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

function TSimpleDSLASTMaker.CreateStatement(statementType: TASTStatementType): IASTStatement;
begin
  case statementType of
    stIf:     Result := TASTIfStatement.Create;
    stReturn: Result := TASTReturnStatement.Create;
    else raise Exception.Create('<AST Factory> CreateStatement: Unexpected statement type');
  end;
end; { TSimpleDSLASTMaker.CreateStatement }

function TSimpleDSLASTMaker.CreateTerm(termType: TASTTermType): IASTTerm;
begin
  case termType of
    termConstant:     Result := TASTTermConstant.Create;
    termVariable:     Result := TASTTermVariable.Create;
    termFunctionCall: Result := TASTTermFunctionCall.Create;
    else raise Exception.Create('<AST Factory> CreateTerm: Unexpected term type');
  end;
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
