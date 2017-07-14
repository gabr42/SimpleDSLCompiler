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
    FCurrentFunc: TASTFunction;
    FDump       : TStringList;
    FErrors     : boolean;
    FText       : string;
  strict protected
    procedure DumpBlock(const indent: string; const block: TASTBlock);
    procedure DumpExpression(const expr: TASTExpression);
    procedure DumpFunction(const func: TASTFunction);
    procedure DumpFunctionCall(const funcCall: TASTTermFunctionCall);
    procedure DumpIfStatement(const indent: string; const statement: TASTIfStatement);
    procedure DumpReturnStatement(const indent: string; const statement: TASTReturnStatement);
    procedure DumpStatement(const indent: string; const statement: TASTStatement);
    procedure DumpTerm(const term: TASTTerm);
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

procedure TSimpleDSLCodegenDump.DumpBlock(const indent: string; const block: TASTBlock);
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
  WriteText(indent); WriteText('}');
end; { TSimpleDSLCodegenDump.DumpBlock }

procedure TSimpleDSLCodegenDump.DumpExpression(const expr: TASTExpression);
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

procedure TSimpleDSLCodegenDump.DumpFunction(const func: TASTFunction);
begin
  FCurrentFunc := func;
  WriteText(Format('%s(%s) ', [func.Name, ''.Join(',', func.ParamNames.ToArray)]));
  if func.Attributes.Count > 0 then
    WriteText('[' + ''.Join(',', func.Attributes.ToArray) + '] ');
  DumpBlock('', func.Body);
  FCurrentFunc := nil;
end; { TSimpleDSLCodegenDump.DumpFunction }

procedure TSimpleDSLCodegenDump.DumpFunctionCall(const funcCall: TASTTermFunctionCall);
var
  func  : TASTFunction;
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
  TASTIfStatement);
begin
  WriteText(indent);
  WriteText('if (');
  DumpExpression(statement.Condition);
  WriteText(')');
  DumpBlock(indent, statement.ThenBlock);
  WriteText(indent);
  WriteText('else');
  DumpBlock(indent, statement.ElseBlock);
end;

procedure TSimpleDSLCodegenDump.DumpReturnStatement(const indent: string; const
  statement: TASTReturnStatement);
begin
  WriteText(indent);
  WriteText('return ');
  DumpExpression(statement.Expression);
end; { TSimpleDSLCodegenDump.DumpReturnStatement }

procedure TSimpleDSLCodegenDump.DumpStatement(const indent: string; const statement:
  TASTStatement);
begin
  if statement.ClassType = TASTIfStatement then
    DumpIfStatement(indent, TASTIfStatement(statement))
  else if statement.ClassType = TASTReturnStatement then
    DumpReturnStatement(indent, TASTReturnStatement(statement))
  else begin
    WritelnText('*** Unknown statement');
    FErrors := true;
    Exit;
  end;
end; { TSimpleDSLCodegenDump.DumpStatement }

procedure TSimpleDSLCodegenDump.DumpTerm(const term: TASTTerm);
begin
  if term.ClassType = TASTTermConstant then
    WriteText(IntToStr(TASTTermConstant(term).Value))
  else if term.ClassType = TASTTermVariable then
    WriteText(FCurrentFunc.ParamNames[TASTTermVariable(term).VariableIdx])
  else if term.ClassType = TASTTermFunctionCall then
    DumpFunctionCall(TASTTermFunctionCall(term))
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
    if i > 0 then begin
      WritelnText;
      WritelnText;
    end;
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
