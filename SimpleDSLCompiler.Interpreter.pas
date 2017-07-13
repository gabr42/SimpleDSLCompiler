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
  SimpleDSLCompiler.Base, SimpleDSLCompiler.Parser;

type
  TContext = record
    Params: TParameters;
    Result: integer;
  end; { TContext }

  TSimpleDSLInterpreter = class(TSimpleDSLCompilerBase, ISimpleDSLProgram)
  strict private
    FAST: ISimpleDSLAST;
  strict protected
    function  CallFunction(const func: IASTFunction; const params: TParameters;
      var return: integer): boolean;
    function  EvalBlock(var context: TContext; const block: IASTBlock): boolean;
    function  EvalExpression(var context: TContext; const expression: IASTExpression; var value: integer): boolean;
    function  EvalFunctionCall(var context: TContext; const functionCall: IASTTermFunctionCall; var value: integer): boolean;
    function  EvalIfStatement(var context: TContext; const statement: IASTIfStatement): boolean;
    function  EvalReturnStatement(var context: TContext; const statement: IASTReturnStatement): boolean;
    function  EvalStatement(var context: TContext; const statement: IASTStatement): boolean;
    function  EvalTerm(var context: TContext; const term: IASTTerm; var value: integer): boolean;
  public
    constructor Create(const ast: ISimpleDSLAST);
    function  Call(const functionName: string; const params: TParameters;
      var return: integer): boolean;
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
end; { TSimpleDSLInterpreter.Create }

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

function TSimpleDSLInterpreter.CallFunction(const func: IASTFunction; const params:
  TParameters; var return: integer): boolean;
var
  context: TContext;
begin
  if Length(params) <> func.ParamNames.Count then
    Exit(SetError('Invalid number of parameters'));
  context.Params := params;
  context.Result := 0;
  Result := EvalBlock(context, func.Body);
  if Result then
    return := context.Result;
end; { TSimpleDSLInterpreter.CallFunction }

function TSimpleDSLInterpreter.EvalBlock(var context: TContext; const block: IASTBlock):
  boolean;
var
  statement: IASTStatement;
begin
  Result := false;

  for statement in block.Statements do
    if not EvalStatement(context, statement) then
      Exit;

  Result := true;
end; { TSimpleDSLInterpreter.EvalBlock }

function TSimpleDSLInterpreter.EvalExpression(var context: TContext; const expression:
  IASTExpression; var value: integer): boolean;
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

function TSimpleDSLInterpreter.EvalFunctionCall(var context: TContext;
  const functionCall: IASTTermFunctionCall; var value: integer): boolean;
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

function TSimpleDSLInterpreter.EvalIfStatement(var context: TContext;
  const statement: IASTIfStatement): boolean;
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

function TSimpleDSLInterpreter.EvalReturnStatement(var context: TContext;
  const statement: IASTReturnStatement): boolean;
var
  value: integer;
begin
  Result := EvalExpression(context, statement.Expression, value);
  if Result then
    context.Result := value;
end; { TSimpleDSLInterpreter.EvalReturnStatement }

function TSimpleDSLInterpreter.EvalStatement(var context: TContext; const statement:
  IASTStatement): boolean;
var
  stmIf    : IASTIfStatement;
  stmReturn: IASTReturnStatement;
begin
  if Supports(statement, IASTIfStatement, stmIf) then
    Result := EvalIfStatement(context, stmIf)
  else if Supports(statement, IASTReturnStatement, stmReturn) then
    Result := EvalReturnStatement(context, stmReturn)
  else
    Result := SetError('*** Unknown statement');
end; { TSimpleDSLInterpreter.EvalStatement }

function TSimpleDSLInterpreter.EvalTerm(var context: TContext; const term: IASTTerm;
  var value: integer): boolean;
var
  funcResult  : integer;
  termConst   : IASTTermConstant;
  termFuncCall: IASTTermFunctionCall;
  termVar     : IASTTermVariable;
begin
  Result := true;
  if Supports(term, IASTTermConstant, termConst) then
    value := termConst.Value
  else if Supports(term, IASTTermVariable, termVar) then begin
    if (termVar.VariableIdx < Low(context.Params)) or (termVar.VariableIdx > High(context.Params)) then
      Result := SetError('*** Invalida variable')
    else
      value := context.Params[termVar.VariableIdx];
  end
  else if Supports(term, IASTTermFunctionCall, termFuncCall) then begin
    Result := EvalFunctionCall(context, termFuncCall, funcResult);
    if Result then
      value := funcResult;
  end
  else
    Result := SetError('*** Unexpected term');
end; { TSimpleDSLInterpreter.EvalTerm }

end.
