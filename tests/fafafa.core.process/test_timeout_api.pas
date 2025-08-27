{$CODEPAGE UTF8}
unit test_timeout_api;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, SysUtils,
  fafafa.core.process;

type
  TTestCase_TimeoutAPI = class(TTestCase)
  published
    procedure Test_RunWithTimeout_ShouldTimeoutAndKill;
    procedure Test_OutputWithTimeout_ShouldSucceedWithinTime;
    procedure Test_WithTimeout_Default_Applied;
    procedure Test_NegativeTimeout_TreatedAsZero;

  end;


implementation

procedure TTestCase_TimeoutAPI.Test_RunWithTimeout_ShouldTimeoutAndKill;
var
  B: IProcessBuilder;
  Caught: Boolean;
begin
  Caught := False;
  {$IFDEF WINDOWS}
  B := NewProcessBuilder
        .Command('cmd.exe')
        .Args(['/c','powershell','-NoProfile','-Command','Start-Sleep -Seconds 1']);
  {$ELSE}
  B := NewProcessBuilder
        .Command('/bin/sh')
        .Args(['-c','sleep 1']);
  {$ENDIF}

  try
    // 500ms 超时应触发 EProcessTimeoutError，并 Kill 子进程
    B.RunWithTimeout(500);
  except
    on E: EProcessTimeoutError do Caught := True;
  end;
  AssertTrue('Expect EProcessTimeoutError on timeout', Caught);
end;

procedure TTestCase_TimeoutAPI.Test_OutputWithTimeout_ShouldSucceedWithinTime;
var
  B: IProcessBuilder;
  S: string;
begin
  {$IFDEF WINDOWS}
  B := NewProcessBuilder.Command('cmd.exe').Args(['/c','echo','HELLO']);
  {$ELSE}
  B := NewProcessBuilder.Command('/bin/echo').Args(['HELLO']);
  {$ENDIF}
  S := B.OutputWithTimeout(2000);
  AssertTrue('should contain HELLO', Pos('HELLO', S) > 0);
end;

procedure TTestCase_TimeoutAPI.Test_WithTimeout_Default_Applied;
var
  B: IProcessBuilder;
  Caught: Boolean;
begin
  Caught := False;
  {$IFDEF WINDOWS}
  B := NewProcessBuilder.Command('cmd.exe').Args(['/c','powershell','-NoProfile','-Command','Start-Sleep -Seconds 1']).WithTimeout(500);
  {$ELSE}
  B := NewProcessBuilder.Command('/bin/sh').Args(['-c','sleep 1']).WithTimeout(500);
  {$ENDIF}
  try
    // 传入 <=0 时应回退到 WithTimeout 的默认值
    B.RunWithTimeout(0);
  except
    on E: EProcessTimeoutError do Caught := True;
  end;
  AssertTrue('Expect default timeout applied', Caught);
end;

procedure TTestCase_TimeoutAPI.Test_NegativeTimeout_TreatedAsZero;
var
  B: IProcessBuilder;
  S: string;
begin
  // 负值按 0 处理：不启用超时，应成功
  {$IFDEF WINDOWS}
  B := NewProcessBuilder.Command('cmd.exe').Args(['/c','echo','OK']);
  {$ELSE}
  B := NewProcessBuilder.Command('/bin/echo').Args(['OK']);
  {$ENDIF}
  S := B.OutputWithTimeout(-1);
  AssertTrue('should contain OK', Pos('OK', S) > 0);
end;

initialization
  RegisterTest(TTestCase_TimeoutAPI);
end.

