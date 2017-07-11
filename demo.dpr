program demo;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  DSiWin32,
  SimpleDSLCompiler in 'SimpleDSLCompiler.pas',
  SimpleDSLCompiler.Parser in 'SimpleDSLCompiler.Parser.pas',
  SimpleDSLCompiler.AST in 'SimpleDSLCompiler.AST.pas',
  SimpleDSLCompiler.Runnable in 'SimpleDSLCompiler.Runnable.pas',
  SimpleDSLCompiler.Compiler in 'SimpleDSLCompiler.Compiler.pas',
  SimpleDSLCompiler.ErrorInfo in 'SimpleDSLCompiler.ErrorInfo.pas',
  SimpleDSLCompiler.Base in 'SimpleDSLCompiler.Base.pas',
  SimpleDSLCompiler.Tokenizer in 'SimpleDSLCompiler.Tokenizer.pas',
  SimpleDSLCompiler.Compiler.Dump in 'SimpleDSLCompiler.Compiler.Dump.pas',
  SimpleDSLCompiler.Compiler.Codegen in 'SimpleDSLCompiler.Compiler.Codegen.pas';

type
  TParams = TArray<integer>;

  TContext = record
    params: TParams;
    result: integer;
  end;

  TBlock = reference to procedure (var context: TContext);
  TExpression = reference to function (var context: TContext): integer;

  TFunction = TFunc<TParams, integer>;
  TExprParams = TArray<TExpression>;

  TMemo = TDictionary<TArray<integer>,integer>;

var
  functions: TArray<TFunction>;
  memo: TMemo;

  function CompileReturn(expr: TExpression): TBlock;
  begin
    Result :=
      procedure (var context: TContext)
      begin
        context.result := expr(context);
      end;
  end;

  function CompilePlus(expr1, expr2: TExpression): TExpression;
  begin
    Result :=
      function (var context: TContext): integer
      begin
        Result := expr1(context) + expr2(context);
      end;
  end;

  function CompileMinus(expr1, expr2: TExpression): TExpression;
  begin
    Result :=
      function (var context: TContext): integer
      begin
        Result := expr1(context) - expr2(context);
      end;
  end;

  function CompileIf(condition: TExpression; blockThen, blockElse: TBlock): TBlock;
  begin
    Result :=
      procedure (var context: TContext)
      begin
        if condition(context) <> 0 then
          blockThen(context)
        else
          blockElse(context);
      end;
  end;

  function CompileFunc(block: TBlock): TFunction;
  begin
    Result :=
      function (params: TArray<integer>): integer
      var
        context: TContext;
      begin
//        if memo.TryGetValue(params, Result) then
//          Exit;
        context := Default(TContext);
        context.params := params;
        block(context);
        Result := context.result;
//        memo.Add(params, Result);
      end;
  end;

  function CompileIsLess(expr1, expr2: TExpression): TExpression;
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

  function ConstExpr(i: integer): TExpression;
  begin
    Result :=
      function (var context: TContext): integer
      begin
        Result := i;
      end;
  end;

  function ParamExpr(i: integer): TExpression;
  begin
    Result :=
      function (var context: TContext): integer
      begin
        Result := context.params[i];
      end;
  end;

  function CallFunc(idxFunc: integer; const params: TExprParams): TExpression;
  begin
    Result :=
      function (var context: TContext): integer
      var
        funcParams: TArray<integer>;
        iParam    : Integer;
      begin
        SetLength(funcParams, Length(params));
        for iParam := Low(params) to High(params) do
          funcParams[iParam] := params[iParam](context);
        Result := functions[idxFunc](funcParams);
      end;
  end;

var
  compiler: ISimpleDSLCompiler;
  exec: ISimpleDSLProgram;
  res: integer;
  sl: TStringList;

const
  CMultiProcCode =
    'fib(i) {                       '#13#10 +
    '  if i < 3 {                   '#13#10 +
    '    return 1                   '#13#10 +
    '  } else {                     '#13#10 +
    '    return fib(i-2) + fib(i-1) '#13#10 +
    '  }                            '#13#10 +
    '}                              '#13#10 +
    'mult(a,b) {                    '#13#10 +
    '  if b < 2 {                   '#13#10 +
    '    return a                   '#13#10 +
    '  } else {                     '#13#10 +
    '    return mult(a, b-1) + a    '#13#10 +
    '  }                            '#13#10 +
    '}                              '#13#10;

function fib(i: integer): integer;
begin
  if i < 3 then
    Result := 1
  else
    Result := fib(i-2) + fib(i-1);
end;

var
  time: int64;

begin
  SetLength(functions, 2);

//fib(i)
//   if i < 2
//     return 1
//   else
//     return fib(i-2) + fib(i-1)
//
//main()
//   return fib(7)

  functions[0] := CompileFunc(
    CompileIf(
      CompileIsLess(
        ParamExpr(0),
        ConstExpr(3)),
      CompileReturn(
        ConstExpr(1)),
      CompileReturn(
        CompilePlus(
          CallFunc(0, [
            CompileMinus(
              ParamExpr(0),
              ConstExpr(2))]),
          CallFunc(0, [
            CompileMinus(
              ParamExpr(0),
              ConstExpr(1)
            )])))));

/// mult(a,b)
///   if b < 2
///     return a
///   else
///     return mult(a, b-1) + a

  functions[1] := CompileFunc(
    CompileIf(
      CompileIsLess(
        ParamExpr(1),
        ConstExpr(2)),
      CompileReturn(
        ParamExpr(0)),
      CompileReturn(
        CompilePlus(
          CallFunc(1, [
            ParamExpr(0),
            CompileMinus(
              ParamExpr(1),
              ConstExpr(1))]),
          ParamExpr(0)))));

  try
    memo := TMemo.Create;
    try
      Writeln(functions[0]([30])); // access by name would be nice; we need name-to-index mapping anyway
      Writeln(functions[1]([5,3]));
    finally FreeAndNil(memo); end;

    sl := TStringList.Create;
    try
      compiler := CreateSimpleDSLCompiler;
      compiler.CodegenFactory := function: ISimpleDSLCodegen begin Result := CreateSimpleDSLCodegenDump(sl); end;
      compiler.Compile(CMultiProcCode);
      Writeln(sl.Text);
    finally FreeAndNil(sl); end;

    compiler := CreateSimpleDSLCompiler;
    exec := compiler.Compile(CMultiProcCode);

    if not assigned(exec) then
      Writeln('Compilation/codegen error: ' + (compiler as ISimpleDSLErrorInfo).ErrorInfo)
    else begin
      if exec.Call('fib', [7], res) then
        Writeln('fib(7) = ', res)
      else
        Writeln('fib: ' + (exec as ISimpleDSLErrorInfo).ErrorInfo);
      if exec.Call('mult', [5,3], res) then
        Writeln('mult(5,3) = ', res)
      else
        Writeln('mult: ' + (exec as ISimpleDSLErrorInfo).ErrorInfo);
    end;

    writeln(fib(7));

    time := DSiTimeGetTime64;
    res := fib(30);
    time := DSiElapsedTime64(time);
    Writeln(res, ' in ', time, ' ms');

    time := DSiTimeGetTime64;
    exec.Call('fib', [30], res);
    time := DSiElapsedTime64(time);
    Writeln(res, ' in ', time, ' ms');

    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
