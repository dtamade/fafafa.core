{$CODEPAGE UTF8}
unit test_checked_exit_edges;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry, SysUtils, Classes,
  fafafa.core.process;

type
  TTestCase_CheckedExit_Edges = class(TTestCase)
  published
    procedure OutputChecked_LargeStdOut_ShouldSucceed_ExitZero;
    procedure StatusChecked_StderrMerged_ExitNonZero_Raises;
  end;

implementation

procedure TTestCase_CheckedExit_Edges.OutputChecked_LargeStdOut_ShouldSucceed_ExitZero;
var
  B: IProcessBuilder;
  S: string;
  N, i: Integer;
  Payload: string;
begin
  // 生成较大的输出：~1MB
  N := 1024; // 行数
  {$IFDEF WINDOWS}
  // 使用 cmd 循环生成大输出，避免在 Pascal 源里嵌入超长/多行字符串
  B := NewProcessBuilder
        .Command('cmd.exe')
        .Args(['/c','for /L %i in (1,1,1024) do @echo 0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF'])
        .CaptureOutput;
  {$ELSE}
  // Unix: 使用 /bin/sh 生成
  B := NewProcessBuilder
        .Command('/bin/sh')
        .Args(['-c','/usr/bin/yes 0123456789ABCDEF | head -n 65536']);
  {$ENDIF}
  S := B.OutputChecked; // 应不抛异常（退出码 0）
  AssertTrue('large output should not be empty', Length(S) > 0);
end;

procedure TTestCase_CheckedExit_Edges.StatusChecked_StderrMerged_ExitNonZero_Raises;
var
  B: IProcessBuilder;
  RaisedErr: Boolean = False;
begin
  {$IFDEF WINDOWS}
  // cmd 合流: 2>&1 后 exit 5
  B := NewProcessBuilder
        .Command('cmd.exe')
        .Args(['/c','(echo ERR 1>&2) & cmd /c exit 5'])
        .StdErrToStdOut
        .CaptureOutput; // 强制合流后捕获
  {$ELSE}
  B := NewProcessBuilder
        .Command('/bin/sh')
        .Args(['-c','(echo ERR 1>&2); exit 5'])
        .StdErrToStdOut
        .CaptureOutput;
  {$ENDIF}
  try
    B.StatusChecked;
  except
    on E: EProcessExitError do RaisedErr := True;
  end;
  AssertTrue('non-zero exit with merged stderr should raise', RaisedErr);
end;

initialization
  RegisterTest(TTestCase_CheckedExit_Edges);
end.

