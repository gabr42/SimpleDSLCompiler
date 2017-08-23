unit SimpleDSLCompiler.Compiler.Codegen;

interface

uses
  Winapi.Windows,
  System.Generics.Collections,
  SimpleDSLCompiler.Runnable;

type
  PExecContext = ^TExecContext;

  TFunction = reference to function(execContext: PExecContext;
    const parameters: TParameters): integer;

  TExecContext = record
    Functions: TArray<TFunction>;
  end;

  TContext = record
    Exec  : PExecContext;
    Params: TParameters;
    Result: integer;
  end;

  TExpression = reference to function (var context: TContext): integer;
  TStatement = reference to procedure (var context: TContext);
  TStatements = TArray<TStatement>;
  TFuncCallParams = TArray<TExpression>;
  TMemoizer = TDictionary<TParameters,integer>;

function  CodegenAdd(const expr1, expr2: TExpression): TExpression;
function  CodegenBlock(const statements: TStatements): TStatement;
function  CodegenConstant(value: integer): TExpression;
function  CodegenFunction(const block: TStatement): TFunction;
function  CodegenFunctionCall(funcIndex: integer; const params: TFuncCallParams):
  TExpression;
function  CodegenIfStatement(const condition: TExpression; const thenBlock,
  elseBlock: TStatement): TStatement;
function  CodegenIsLess(const expr1, expr2: TExpression): TExpression;
function  CodegenMemoizedFunction(const block: TStatement; memoizer: TMemoizer): TFunction;
function  CodegenReturnStatement(const expression: TExpression): TStatement;
function  CodegenSubtract(const expr1, expr2: TExpression): TExpression;
function  CodegenVariable(varIndex: integer): TExpression;

implementation

function CodegenBlock(const statements: TStatements): TStatement;
begin
  Result :=
    procedure (var context: TContext)
    var
      stmt: TStatement;
    begin
      for stmt in statements do
        stmt(context);
    end;
end;

function CodegenFunction(const block: TStatement): TFunction;
begin
  Result :=
    function (execContext: PExecContext; const params: TParameters): integer
    var
      context: TContext;
    begin
      context.Exec := execContext;
      context.Params := params;
      context.Result := 0;
      block(context);
      Result := context.Result;
    end;
end;

function CodegenReturnStatement(const expression: TExpression): TStatement;
begin
  Result :=
    procedure (var context: TContext)
    begin
      context.Result := expression(context);
    end;
end;

function CodegenIfStatement(const condition: TExpression; const thenBlock,
  elseBlock: TStatement): TStatement;
begin
  Result :=
    procedure (var context: TContext)
    begin
      if condition(context) <> 0 then
        thenBlock(context)
      else
        elseBlock(context);
    end;
end;

function CodegenAdd(const expr1, expr2: TExpression): TExpression;
begin
  Result :=
    function (var context: TContext): integer
    begin
      Result := expr1(context) + expr2(context);
    end;
end;

function CodegenSubtract(const expr1, expr2: TExpression): TExpression;
begin
  Result :=
    function (var context: TContext): integer
    begin
      Result := expr1(context) - expr2(context);
    end;
end;

function CodegenIsLess(const expr1, expr2: TExpression): TExpression;
begin
  Result :=
    function (var context: TContext): integer
    var
      diff: integer;
    begin
      diff := expr1(context) - expr2(context);
      if diff < 0 then
        Result := 1
      else
        Result := 0;
    end;
end;

function CodegenConstant(value: integer): TExpression;
begin
  Result :=
    function (var context: TContext): integer
    begin
      Result := value;
    end;
end;

function CodegenVariable(varIndex: integer): TExpression;
begin
  Result :=
    function (var context: TContext): integer
    begin
      Result := context.Params[varIndex];
    end;
end;

function CodegenFunctionCall(funcIndex: integer; const params: TFuncCallParams):
  TExpression;
begin
  Result :=
    function (var context: TContext): integer
    var
      funcParams: TParameters;
      iParam    : Integer;
    begin
      SetLength(funcParams, Length(params));
      for iParam := Low(params) to High(params) do
        funcParams[iParam] := params[iParam](context);
      Result := context.Exec.Functions[funcIndex](context.Exec, funcParams);
    end;
end;

function CodegenMemoizedFunction(const block: TStatement; memoizer: TMemoizer): TFunction;
begin
  Result :=
    function (execContext: PExecContext; const params: TParameters): integer
    var
      context: TContext;
    begin
      if not memoizer.TryGetValue(params, Result) then begin
        context.Exec := execContext;
        context.Params := params;
        context.Result := 0;
        block(context);
        Result := context.Result;
        memoizer.Add(params, Result);
      end;
    end;
end;

end.
