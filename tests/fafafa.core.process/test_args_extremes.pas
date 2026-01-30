{$CODEPAGE UTF8}
unit test_args_extremes;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, SysUtils,
  fafafa.core.process;

type
  TTestCase_Args_Extremes = class(TTestCase)
  published
    procedure Test_VeryLongSingleArgument_WindowsQuoting;
    procedure Test_ManyArguments_ShouldStart;
  end;

implementation

function RepeatChar(C: Char; N: Integer): string;
begin
  SetLength(Result, N);
  if N > 0 then FillChar(Result[1], N, Ord(C));
end;

procedure TTestCase_Args_Extremes.Test_VeryLongSingleArgument_WindowsQuoting;
var
  B: IProcessBuilder;
  Arg: string;
  C: IChild;
  ok: Boolean;
begin
  // 约 8K 字符，远小于 Windows 命令行上限，避免不稳定
  Arg := RepeatChar('A', 8 * 1024);
  {$IFDEF WINDOWS}
  B := NewProcessBuilder.Command('cmd.exe').Args(['/c','echo', Arg]);
  {$ELSE}
  B := NewProcessBuilder.Command('/bin/echo').Args([Arg]);
  {$ENDIF}
  // 不要求校验输出，仅校验能启动和退出
  C := B.Start;
  ok := C.WaitForExit(5000);
  AssertTrue('process should finish with very long single arg', ok);
end;

procedure TTestCase_Args_Extremes.Test_ManyArguments_ShouldStart;
var
  B: IProcessBuilder;
  I: Integer;
  Args: array of string;
  C: IChild;
  ok: Boolean;
begin
  // 组装 200 个短参数，覆盖构建器拼接与 Windows 引号行为
  SetLength(Args, 200);
  for I := 0 to High(Args) do Args[I] := 'arg' + IntToStr(I);
  {$IFDEF WINDOWS}
  B := NewProcessBuilder.Command('cmd.exe').Args(['/c','echo']);
  for I := 0 to High(Args) do B.Arg(Args[I]);
  {$ELSE}
  B := NewProcessBuilder.Command('/bin/echo');
  for I := 0 to High(Args) do B.Arg(Args[I]);
  {$ENDIF}
  C := B.Start;
  ok := C.WaitForExit(5000);
  AssertTrue('process should finish with many args', ok);
end;

initialization
  RegisterTest(TTestCase_Args_Extremes);
end.

