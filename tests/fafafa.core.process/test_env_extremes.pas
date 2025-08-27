{$CODEPAGE UTF8}
unit test_env_extremes;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, SysUtils,
  fafafa.core.process;

type
  TTestCase_Env_Extremes = class(TTestCase)
  published
    procedure Test_VeryLongEnvValue_ShouldStart;
    procedure Test_LargeEnvCount_ShouldStart;
  end;

implementation

function RepeatChar(C: Char; N: Integer): string;
begin
  SetLength(Result, N);
  if N > 0 then FillChar(Result[1], N, Ord(C));
end;

procedure TTestCase_Env_Extremes.Test_VeryLongEnvValue_ShouldStart;
var
  B: IProcessBuilder;
  C: IChild;
  ok: Boolean;
  V: string;
begin
  V := RepeatChar('X', 32 * 1024); // 32KB 单变量值（远低于环境块总上限）
  B := NewProcessBuilder;
  {$IFDEF WINDOWS}
  B.Command('cmd.exe').Args(['/c','echo','OK']);
  {$ELSE}
  B.Command('/bin/echo').Args(['OK']);
  {$ENDIF}
  B.Env('LONG_ENV', V);
  C := B.Start;
  ok := C.WaitForExit(5000);
  AssertTrue('process should finish with very long env value', ok);
end;

procedure TTestCase_Env_Extremes.Test_LargeEnvCount_ShouldStart;
var
  B: IProcessBuilder;
  C: IChild;
  ok: Boolean;
  I: Integer;
begin
  B := NewProcessBuilder;
  {$IFDEF WINDOWS}
  B.Command('cmd.exe').Args(['/c','echo','OK']);
  {$ELSE}
  B.Command('/bin/echo').Args(['OK']);
  {$ENDIF}
  // 添加 200 个较短的环境变量，覆盖排序与去重路径
  for I := 0 to 199 do B.Env('K'+IntToStr(I), 'V'+IntToStr(I));
  C := B.Start;
  ok := C.WaitForExit(5000);
  AssertTrue('process should finish with many env variables', ok);
end;

initialization
  RegisterTest(TTestCase_Env_Extremes);
end.

