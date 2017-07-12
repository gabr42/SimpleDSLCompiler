unit SimpleDSLCompiler.Compiler;

interface

uses
  SimpleDSLCompiler.AST,
  SimpleDSLCompiler.Runnable;

type
  ISimpleDSLCodegen = interface ['{C359C174-E324-4709-86EF-EE61AFE3B1FD}']
    function Generate(const ast: ISimpleDSLAST; var runnable: ISimpleDSLProgram): boolean;
  end; { ISimpleDSLCodegen }

  TSimpleDSLCodegenFactory = reference to function: ISimpleDSLCodegen;

function CreateSimpleDSLCodegen: ISimpleDSLCodegen;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  SimpleDSLCompiler.Base,
  SimpleDSLCompiler.Compiler.Codegen;

type
  ISimpleDSLProgramEx = interface ['{4CEF7C78-FF69-47E2-9F63-706E167AF3A9}']
    procedure DeclareFunction(idx: integer; const name: string; const code: TFunction);
  end; { ISimpleDSLProgramEx }

  TSimpleDSLProgram = class(TSimpleDSLCompilerBase, ISimpleDSLProgram,
                                                    ISimpleDSLProgramEx)
  strict private type
    TFunctionInfo = record
      Name: string;
      Code: TFunction;
    end; { TFunctionInfo }
  var
    FFunctions: TList<TFunctionInfo>;
  strict protected
    procedure SetupContext(var context: TExecContext);
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    function  Call(const functionName: string; const params: TParameters; var return: integer): boolean;
    procedure DeclareFunction(idx: integer; const name: string; const code: TFunction);
  end; { TSimpleDSLProgram }

  TSimpleDSLCodegen = class(TSimpleDSLCompilerBase, ISimpleDSLCodegen)
  strict private
    FAST: ISimpleDSLAST;
  strict protected
    function  CompileBlock(const astBlock: IASTBlock; var codeBlock: TStatement): boolean;
    function  CompileExpression(const astExpression: IASTExpression;
      var codeExpression: TExpression): boolean;
    function  CompileFunctionCall(const astFuncCall: IASTTermFunctionCall;
      var codeExpression: TExpression): boolean;
    function  CompileIfStatement(const astStatement: IASTIfStatement;
      var codeStatement: TStatement): boolean;
    function  CompileReturnStatement(const astStatement: IASTReturnStatement;
      var codeStatement: TStatement): boolean;
    function  CompileStatement(const astStatement: IASTStatement;
      var codeStatement: TStatement): boolean;
    function  CompileTerm(const astTerm: IASTTerm; var codeTerm: TExpression): boolean;
  public
    function  Generate(const ast: ISimpleDSLAST; var runnable: ISimpleDSLProgram): boolean;
  end; { TSimpleDSLCodegen }

{ exports }

function CreateSimpleDSLCodegen: ISimpleDSLCodegen;
begin
  Result := TSimpleDSLCodegen.Create;
end; { CreateSimpleDSLCodegen }

{ TSimpleDSLProgram }

procedure TSimpleDSLProgram.AfterConstruction;
begin
  inherited;
  FFunctions := TList<TFunctionInfo>.Create;
end; { TSimpleDSLProgram.AfterConstruction }

procedure TSimpleDSLProgram.BeforeDestruction;
begin
  FreeAndNil(FFunctions);
  inherited;
end; { TSimpleDSLProgram.BeforeDestruction }

function TSimpleDSLProgram.Call(const functionName: string; const params: TParameters;
  var return: integer): boolean;
var
  context : TExecContext;
  funcInfo: TFunctionInfo;
begin
  Result := false;
  for funcInfo in FFunctions do begin
    if SameText(functionName, funcInfo.Name) then begin
      SetupContext(context);
      return := funcInfo.Code(@context, params);
      Exit(true);
    end;
  end;
  LastError := 'Function not found';
end; { TSimpleDSLProgram.Call }

procedure TSimpleDSLProgram.DeclareFunction(idx: integer; const name: string;
  const code: TFunction);
var
  funcInfo: TFunctionInfo;
begin
  Assert(idx = FFunctions.Count);
  funcInfo.Name := name;
  funcInfo.Code := code;
  FFunctions.Add(funcInfo);
end; { TSimpleDSLProgram.DeclareFunction }

procedure TSimpleDSLProgram.SetupContext(var context: TExecContext);
var
  iFunc: integer;
begin
  SetLength(context.Functions, FFunctions.Count);
  for iFunc := 0 to FFunctions.Count - 1 do
    context.Functions[iFunc] := FFunctions[iFunc].Code;
end; { TSimpleDSLProgram.SetupContext }

{ TSimpleDSLCodegen }

function TSimpleDSLCodegen.CompileBlock(const astBlock: IASTBlock; var codeBlock:
  TStatement): boolean;
var
  codeStatement: TStatement;
  statements   : TStatements;
begin
  Result := CompileStatement(astBlock.Statement, codeStatement);
  if Result then begin
    SetLength(statements, 1);
    statements[0] := codeStatement;
    codeBlock := CodegenBlock(statements);
  end;
end; { TSimpleDSLCodegen.CompileBlock }

function TSimpleDSLCodegen.CompileExpression(const astExpression: IASTExpression;
  var codeExpression: TExpression): boolean;
var
  term1: TExpression;
  term2: TExpression;
begin
  Result := false;
  if not CompileTerm(astExpression.Term1, term1) then
    Exit;

  if astExpression.BinaryOp = opNone then begin
    codeExpression := term1;
    Result := true;
  end
  else begin
    if not CompileTerm(astExpression.Term2, term2) then
      Exit;
    Result := true;
    case astExpression.BinaryOp of
      opAdd:         codeExpression := CodegenAdd(term1, term2);
      opSubtract:    codeExpression := CodegenSubtract(term1, term2);
      opCompareLess: codeExpression := CodegenIsLess(term1, term2);
      else           Result := SetError('*** Unexpected operator');
    end;
  end;
end; { TSimpleDSLCodegen.CompileExpression }

function TSimpleDSLCodegen.CompileFunctionCall(const astFuncCall: IASTTermFunctionCall;
  var codeExpression: TExpression): boolean;
var
  func      : IASTFunction;
  iParam    : integer;
  parameters: TFuncCallParams;
  paramExpr : TExpression;
begin
  Result := false;
  if astFuncCall.FunctionIdx >= FAST.Functions.Count then
    LastError := '*** Invalid function'
  else begin
    func := FAST.Functions[astFuncCall.FunctionIdx];
    if func.ParamNames.Count <> astFuncCall.Parameters.Count then
      LastError := Format('Invalid number of parameters in %s() call', [func.Name])
    else begin
      SetLength(parameters, astFuncCall.Parameters.Count);
      for iParam := 0 to astFuncCall.Parameters.Count - 1 do begin
        if not CompileExpression(astFuncCall.Parameters[iParam], paramExpr) then
          Exit;
        parameters[iParam] := paramExpr;
      end;
      codeExpression := CodegenFunctionCall(astFuncCall.FunctionIdx, parameters);
      Result := true;
    end;
  end;
end;

function TSimpleDSLCodegen.CompileIfStatement(const astStatement: IASTIfStatement;
  var codeStatement: TStatement): boolean;
var
  condition: TExpression;
  elseBlock: TStatement;
  thenBlock: TStatement;
begin
  Result := false;
  if not CompileExpression(astStatement.Condition, condition) then
    Exit;
  if not CompileBlock(astStatement.ThenBlock, thenBlock) then
    Exit;
  if not CompileBlock(astStatement.ElseBlock, elseBlock) then
    Exit;

  codeStatement := CodegenIfStatement(condition, thenBlock, elseBlock);
  Result := true;
end; { TSimpleDSLCodegen.CompileIfStatement }

function TSimpleDSLCodegen.CompileReturnStatement(const astStatement:
  IASTReturnStatement; var codeStatement: TStatement): boolean;
var
  expression: TExpression;
begin
  Result := CompileExpression(astStatement.Expression, expression);
  if Result then
    codeStatement := CodegenReturnStatement(expression);
end; { TSimpleDSLCodegen.CompileReturnStatement }

function TSimpleDSLCodegen.CompileStatement(const astStatement: IASTStatement;
  var codeStatement: TStatement): boolean;
var
  stmIf    : IASTIfStatement;
  stmReturn: IASTReturnStatement;
begin
  if Supports(astStatement, IASTIfStatement, stmIf) then
    Result := CompileIfStatement(stmIf, codeStatement)
  else if Supports(astStatement, IASTReturnStatement, stmReturn) then
    Result := CompileReturnStatement(stmReturn, codeStatement)
  else
    Result := SetError('*** Unknown statement');
end; { TSimpleDSLCodegen.CompileStatement }

function TSimpleDSLCodegen.CompileTerm(const astTerm: IASTTerm; var codeTerm:
  TExpression): boolean;
var
  termConst   : IASTTermConstant;
  termFuncCall: IASTTermFunctionCall;
  termVar     : IASTTermVariable;
begin
  Result := true;
  if Supports(astTerm, IASTTermConstant, termConst) then
    codeTerm := CodegenConstant(termConst.Value)
  else if Supports(astTerm, IASTTermVariable, termVar) then
    codeTerm := CodegenVariable(termVar.VariableIdx)
  else if Supports(astTerm, IASTTermFunctionCall, termFuncCall) then
    Result := CompileFunctionCall(termFuncCall, codeTerm)
  else
    Result := SetError('*** Unexpected term');
end; { TSimpleDSLCodegen.CompileTerm }

function TSimpleDSLCodegen.Generate(const ast: ISimpleDSLAST; var runnable:
  ISimpleDSLProgram): boolean;
var
  block      : TStatement;
  i          : integer;
  runnableInt: ISimpleDSLProgramEx;
begin
  Result := false; //to keep compiler happy
  FAST := ast;
  runnable := TSimpleDSLProgram.Create;
  runnableInt := runnable as ISimpleDSLProgramEx;
  for i := 0 to ast.Functions.Count - 1 do begin
    if not CompileBlock(ast.Functions[i].Body, block) then
      Exit;
    runnableInt.DeclareFunction(i, ast.Functions[i].Name, CodegenFunction(block));
  end;
  Result := true;
end; { TSimpleDSLCodegen.Generate }

end.
