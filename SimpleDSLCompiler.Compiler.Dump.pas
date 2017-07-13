unit SimpleDSLCompiler.Compiler.Dump;

interface

uses
  System.Classes,
  SimpleDSLCompiler.AST,
  SimpleDSLCompiler.Compiler;

function CreateSimpleDSLCodegenDump(dump: TStringList): ISimpleDSLCodegen;

implementation

uses
  Winapi.Windows,
  System.SysUtils,
  SimpleDSLCompiler.Base,
  SimpleDSLCompiler.Runnable;

type
  TSimpleDSLCodegenDump = class(TSimpleDSLCompilerBase, ISimpleDSLCodegen)
  strict private
    FAST        : ISimpleDSLAST;
    FCurrentFunc: IASTFunction;
    FDump       : TStringList;
    FErrors     : boolean;
    FText       : string;
  strict protected
    procedure DumpBlock(const indent: string; const block: IASTBlock);
    procedure DumpExpression(const expr: IASTExpression);
    procedure DumpFunction(const func: IASTFunction);
    procedure DumpFunctionCall(const funcCall: IASTTermFunctionCall);
    procedure DumpIfStatement(const indent: string; const statement: IASTIfStatement);
    procedure DumpReturnStatement(const indent: string; const statement: IASTReturnStatement);
    procedure DumpStatement(const indent: string; const statement: IASTStatement);
    procedure DumpTerm(const term: IASTTerm);
    procedure WriteText(const s: string);
    procedure WritelnText(const s: string = '');
  public
    constructor Create(dump: TStringList);
    function  Generate(const ast: ISimpleDSLAST; var runnable: ISimpleDSLProgram): boolean;
  end; { TSimpleDSLCodegenDump }

{ externals }

function CreateSimpleDSLCodegenDump(dump: TStringList): ISimpleDSLCodegen;
begin
  Result := TSimpleDSLCodegenDump.Create(dump);
end; { CreateSimpleDSLCodegenDump }

{ TSimpleDSLCodegenDump }

constructor TSimpleDSLCodegenDump.Create(dump: TStringList);
begin
  inherited Create;
  FDump := dump;
end; { TSimpleDSLCodegenDump.Create }

procedure TSimpleDSLCodegenDump.DumpBlock(const indent: string; const block: IASTBlock);
var
  iStatement: integer;
begin
  WriteText(indent); WritelnText('{');
  for iStatement := 0 to block.Statements.Count - 1 do begin
    DumpStatement(indent + '  ', block.Statements[iStatement]);
    if iStatement < (block.Statements.Count - 1) then
      WritelnText(';')
    else
      WritelnText;
  end;
  WriteText(indent); WritelnText('}');
end; { TSimpleDSLCodegenDump.DumpBlock }

procedure TSimpleDSLCodegenDump.DumpExpression(const expr: IASTExpression);
begin
  DumpTerm(expr.Term1);

  case expr.BinaryOp of
    opNone:        Exit;
    opAdd:         WriteText(' + ');
    opSubtract:    WriteText(' - ');
    opCompareLess: WriteText(' < ');
    else begin
      WritelnText('*** Unexpected operator');
      FErrors := true;
    end;
  end;

  DumpTerm(expr.Term2);
end; { TSimpleDSLCodegenDump.DumpExpression }

procedure TSimpleDSLCodegenDump.DumpFunction(const func: IASTFunction);
begin
  FCurrentFunc := func;
  WritelnText(Format('%s(%s)', [func.Name, ''.Join(',', func.ParamNames.ToArray)]));
  DumpBlock('', func.Body);
  FCurrentFunc := nil;
end; { TSimpleDSLCodegenDump.DumpFunction }

procedure TSimpleDSLCodegenDump.DumpFunctionCall(const funcCall: IASTTermFunctionCall);
var
  func  : IASTFunction;
  iParam: integer;
begin
  func := FAST.Functions[funcCall.FunctionIdx];
  WriteText(func.Name);
  WriteText('(');
  for iParam := 0 to funcCall.Parameters.Count - 1 do begin
    if iParam > 0 then
      WriteText(', ');
    DumpExpression(funcCall.Parameters[iParam]);
  end;
  WriteText(')');
end; { TSimpleDSLCodegenDump.DumpFunctionCall }

procedure TSimpleDSLCodegenDump.DumpIfStatement(const indent: string; const statement:
  IASTIfStatement);
begin
  WriteText(indent);
  WriteText('if (');
  DumpExpression(statement.Condition);
  WritelnText(')');
  DumpBlock(indent, statement.ThenBlock);
  WriteText(indent);
  WritelnText('else');
  DumpBlock(indent, statement.ElseBlock);
end;

procedure TSimpleDSLCodegenDump.DumpReturnStatement(const indent: string;
  const statement: IASTReturnStatement);
begin
  WriteText(indent);
  WriteText('return ');
  DumpExpression(statement.Expression);
end; { TSimpleDSLCodegenDump.DumpReturnStatement }

procedure TSimpleDSLCodegenDump.DumpStatement(const indent: string;
  const statement: IASTStatement);
var
  stmIf    : IASTIfStatement;
  stmReturn: IASTReturnStatement;
begin
  if Supports(statement, IASTIfStatement, stmIf) then
    DumpIfStatement(indent, stmIf)
  else if Supports(statement, IASTReturnStatement, stmReturn) then
    DumpReturnStatement(indent, stmReturn)
  else begin
    WritelnText('*** Unknown statement');
    FErrors := true;
    Exit;
  end;
end; { TSimpleDSLCodegenDump.DumpStatement }

procedure TSimpleDSLCodegenDump.DumpTerm(const term: IASTTerm);
var
  termConst   : IASTTermConstant;
  termFuncCall: IASTTermFunctionCall;
  termVar     : IASTTermVariable;
begin
  if Supports(term, IASTTermConstant, termConst) then
    WriteText(IntToStr(termConst.Value))
  else if Supports(term, IASTTermVariable, termVar) then
    WriteText(FCurrentFunc.ParamNames[termVar.VariableIdx])
  else if Supports(term, IASTTermFunctionCall, termFuncCall) then
    DumpFunctionCall(termFuncCall)
  else begin
    WritelnText('*** Unexpected term');
    FErrors := true;
  end;
end; { TSimpleDSLCodegenDump.DumpTerm }

function TSimpleDSLCodegenDump.Generate(const ast: ISimpleDSLAST;
  var runnable: ISimpleDSLProgram): boolean;
var
  i: integer;
begin
  FErrors := false;
  FAST := ast;
  for i := 0 to ast.Functions.Count - 1 do begin
    if i > 0 then
      WritelnText;
    DumpFunction(ast.Functions[i]);
  end;
  FDump.Text := FText;
  Result := not FErrors;
end; { TSimpleDSLCodegenDump.Generate }

procedure TSimpleDSLCodegenDump.WritelnText(const s: string);
begin
  WriteText(s);
  WriteText(#13#10);
end; { TSimpleDSLCodegenDump.WritelnText }

procedure TSimpleDSLCodegenDump.WriteText(const s: string);
begin
  FText := FText + s;
end; { TSimpleDSLCodegenDump.WriteText }

end.
