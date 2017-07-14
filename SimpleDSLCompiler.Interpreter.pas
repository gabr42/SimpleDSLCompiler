unit SimpleDSLCompiler.Interpreter;

interface

uses
  SimpleDSLCompiler.AST,
  SimpleDSLCompiler.Runnable;

function CreateSimpleDSLInterpreter(const ast: ISimpleDSLAST): ISimpleDSLProgram;

implementation

uses
  Winapi.Windows,
  System.SysUtils,
  System.Generics.Collections,
  SimpleDSLCompiler.Base,
  SimpleDSLCompiler.Parser;

type
  TContext = record
    Params: TParameters;
    Result: integer;
  end; { TContext }

  TMemoizer = TDictionary<TParameters, integer>;

  TSimpleDSLInterpreter = class(TSimpleDSLCompilerBase, ISimpleDSLProgram)
  strict private
    FAST      : ISimpleDSLAST;
    FMemoizers: TObjectDictionary<TASTFunction, TMemoizer>;
  strict protected
    function  CallFunction(const func: TASTFunction; const params: TParameters;
      var return: integer): boolean;
    function  EvalBlock(var context: TContext; const block: TASTBlock): boolean;
    function  EvalExpression(var context: TContext; const expression: TASTExpression;
      var value: integer): boolean;
    function  EvalFunctionCall(var context: TContext; const functionCall: TASTTermFunctionCall;
      var value: integer): boolean;
    function  EvalIfStatement(var context: TContext; const statement: TASTIfStatement): boolean;
    function  EvalReturnStatement(var context: TContext; const statement: TASTReturnStatement): boolean;
    function  EvalStatement(var context: TContext; const statement: TASTStatement): boolean;
    function  EvalTerm(var context: TContext; const term: TASTTerm; var value: integer): boolean;
  public
    constructor Create(const ast: ISimpleDSLAST);
    destructor  Destroy; override;
    function  Call(const functionName: string; const params: TParameters;
      var return: integer): boolean;
    function  Make(const functionName: string): TFunctionCall;
  end; { TSimpleDSLInterpreter }

{ exports }

function CreateSimpleDSLInterpreter(const ast: ISimpleDSLAST): ISimpleDSLProgram;
begin
  Result := TSimpleDSLInterpreter.Create(ast);
end; { CreateSimpleDSLInterpreter }

{ TSimpleDSLInterpreter }

constructor TSimpleDSLInterpreter.Create(const ast: ISimpleDSLAST);
begin
  inherited Create;
  FAST := ast;
  FMemoizers := TObjectDictionary<TASTFunction, TMemoizer>.Create([doOwnsValues]);
end; { TSimpleDSLInterpreter.Create }

destructor TSimpleDSLInterpreter.Destroy;
begin
  FreeAndNil(FMemoizers);
  inherited;
end; { TSimpleDSLInterpreter.Destroy }

function TSimpleDSLInterpreter.Call(const functionName: string; const params: TParameters;
  var return: integer): boolean;
var
  iFunc: integer;
begin
  for iFunc := 0 to FAST.Functions.Count - 1 do
    if SameText(functionName, FAST.Functions[iFunc].Name) then
      Exit(CallFunction(FAST.Functions[iFunc], params, return));

  Result := SetError('Unknown function');
end; { TSimpleDSLInterpreter.Call }

function TSimpleDSLInterpreter.CallFunction(const func: TASTFunction; const params:
  TParameters; var return: integer): boolean;
var
  context : TContext;
  memoizer: TMemoizer;
begin
  if Length(params) <> func.ParamNames.Count then
    Exit(SetError('Invalid number of parameters'));

  memoizer := nil;
  if func.Attributes.Contains('memo') then begin
    if not FMemoizers.TryGetValue(func, memoizer) then begin
      memoizer := TMemoizer.Create;
      FMemoizers.Add(func, memoizer);
    end;
    if memoizer.TryGetValue(params, return) then
      Exit(true);
  end;

  context.Params := params;
  context.Result := 0;
  Result := EvalBlock(context, func.Body);
  if Result then begin
    return := context.Result;
    if assigned(memoizer) then
      memoizer.Add(params, return);
  end;
end; { TSimpleDSLInterpreter.CallFunction }

function TSimpleDSLInterpreter.EvalBlock(var context: TContext; const block: TASTBlock):
  boolean;
var
  statement: TASTStatement;
begin
  Result := false;

  for statement in block.Statements do
    if not EvalStatement(context, statement) then
      Exit;

  Result := true;
end; { TSimpleDSLInterpreter.EvalBlock }

function TSimpleDSLInterpreter.EvalExpression(var context: TContext; const expression:
  TASTExpression; var value: integer): boolean;
var
  term1: integer;
  term2: integer;
begin
  Result := false;
  if not EvalTerm(context, expression.Term1, term1) then
    Exit;

  if expression.BinaryOp = opNone then begin
    value := term1;
    Result := true;
    Exit;
  end;

  if not EvalTerm(context, expression.Term2, term2) then
    Exit;

  case expression.BinaryOp of
    opAdd:
      value := term1 + term2;
    opSubtract:
      value := term1 - term2;
    opCompareLess:
      if term1 < term2 then
        value := 1
      else
        value := 0;
    else Exit(SetError('*** Unexpected binary operation'));
  end;

  Result := true;
end; { TSimpleDSLInterpreter.EvalExpression }

function TSimpleDSLInterpreter.EvalFunctionCall(var context: TContext; const
  functionCall: TASTTermFunctionCall; var value: integer): boolean;
var
  funcReturn: integer;
  iParam    : integer;
  parameters: TParameters;
  paramValue: integer;
begin
  Result := false;
  if (functionCall.FunctionIdx < 0) or (functionCall.FunctionIdx >= FAST.Functions.Count) then
    Exit(SetError('*** Invalid function'));

  SetLength(parameters, functionCall.Parameters.Count);
  for iParam := 0 to functionCall.Parameters.Count - 1 do begin
    if not EvalExpression(context, functionCall.Parameters[iParam], paramValue) then
      Exit;
    parameters[iParam] := paramValue;
  end;

  if not CallFunction(FAST.Functions[functionCall.FunctionIdx], parameters, funcReturn) then
    Exit;

  value := funcReturn;
  Result := true;
end; { TSimpleDSLInterpreter.EvalFunctionCall }

function TSimpleDSLInterpreter.EvalIfStatement(var context: TContext; const statement:
  TASTIfStatement): boolean;
var
  value: integer;
begin
  Result := EvalExpression(context, statement.Condition, value);
  if Result then begin
    if value <> 0 then
      Result := EvalBlock(context, statement.ThenBlock)
    else
      Result := EvalBlock(context, statement.ElseBlock);
  end;
end; { TSimpleDSLInterpreter.EvalIfStatement }

function TSimpleDSLInterpreter.EvalReturnStatement(var context: TContext; const
  statement: TASTReturnStatement): boolean;
var
  value: integer;
begin
  Result := EvalExpression(context, statement.Expression, value);
  if Result then
    context.Result := value;
end; { TSimpleDSLInterpreter.EvalReturnStatement }

function TSimpleDSLInterpreter.EvalStatement(var context: TContext; const statement:
  TASTStatement): boolean;
begin
  if statement.ClassType = TASTIfStatement then
    Result := EvalIfStatement(context, TASTIfStatement(statement))
  else if statement.ClassType = TASTReturnStatement then
    Result := EvalReturnStatement(context, TASTReturnStatement(statement))
  else
    Result := SetError('*** Unknown statement');
end; { TSimpleDSLInterpreter.EvalStatement }

function TSimpleDSLInterpreter.EvalTerm(var context: TContext; const term: TASTTerm;
  var value: integer): boolean;
var
  funcResult: integer;
begin
  Result := true;
  if term.ClassType = TASTTermConstant then
    value := TASTTermConstant(term).Value
  else if term.ClassType = TASTTermVariable then begin
    if (TASTTermVariable(term).VariableIdx < Low(context.Params))
       or (TASTTermVariable(term).VariableIdx > High(context.Params))
    then
      Result := SetError('*** Invalid variable')
    else
      value := context.Params[TASTTermVariable(term).VariableIdx];
  end
  else if term.ClassType = TASTTermFunctionCall then begin
    Result := EvalFunctionCall(context, TASTTermFunctionCall(term), funcResult);
    if Result then
      value := funcResult;
  end
  else
    Result := SetError('*** Unexpected term');
end; { TSimpleDSLInterpreter.EvalTerm }

function TSimpleDSLInterpreter.Make(const functionName: string): TFunctionCall;
var
  iFunc: integer;
begin
  for iFunc := 0 to FAST.Functions.Count - 1 do
    if SameText(functionName, FAST.Functions[iFunc].Name) then begin
      Result :=
        function (const parameters: TParameters): integer
        begin
          Result := 0;
          if not CallFunction(FAST.Functions[iFunc], parameters, Result) then
            raise Exception.Create('Execution failed with error: ' + LastError);
        end;
      Exit;
    end;

  raise Exception.CreateFmt('TSimpleDSLInterpreter.Make: Function not found: %s', [functionName]);
end; { TSimpleDSLInterpreter.Make }

end.
