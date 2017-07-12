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

var
  compiler: ISimpleDSLCompiler;
  exec    : ISimpleDSLProgram;
  res     : integer;
  sl      : TStringList;
  time    : int64;

function fib(i: integer): integer;
begin
  if i < 3 then
    Result := 1
  else
    Result := fib(i-2) + fib(i-1);
end;

begin
  try
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
