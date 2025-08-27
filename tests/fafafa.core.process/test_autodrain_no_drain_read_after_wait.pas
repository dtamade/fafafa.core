unit test_autodrain_no_drain_read_after_wait;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.process;

type
  TTestCase_NoDrain_ReadAfterWait = class(TTestCase)
  published
    procedure Test_NoDrain_ReadStdOut_After_Wait_Should_Work;
  end;

implementation

procedure TTestCase_NoDrain_ReadAfterWait.Test_NoDrain_ReadStdOut_After_Wait_Should_Work;
var
  SI: IProcessStartInfo;
  P: IProcess;
  S: TStringStream;
  OutText: string;
begin
  // Arrange: 生成有限的输出，但不启用 DrainOutput
  SI := TProcessStartInfo.Create;
  {$IFDEF WINDOWS}
  SI.FileName := 'cmd.exe';
  SI.Arguments := '/c for /L %i in (1,1,10) do @echo ND-%i';
  {$ELSE}
  SI.FileName := '/bin/sh';
  SI.Arguments := '-c "for i in $(seq 1 10); do echo ND-$i; done"';
  {$ENDIF}
  SI.RedirectStandardOutput := True;
  SI.RedirectStandardError := True;
  SI.SetDrainOutput(False); // 关键：不启用后台排水

  P := TProcess.Create(SI);
  P.Start;

  // Act: 等待进程退出
  CheckTrue(P.WaitForExit(10000), 'Process should exit');

  // Assert: 即使未启用 DrainOutput，也应仍可从 StandardOutput 读取全部输出
  OutText := '';
  if Assigned(P.StandardOutput) then
  begin
    S := TStringStream.Create('');
    try
      S.CopyFrom(P.StandardOutput, 0);
      OutText := S.DataString;
    finally
      S.Free;
    end;
  end;

  CheckNotEquals(0, Pos('ND-', OutText), 'Output should contain lines when no drain is enabled');
end;

initialization
  RegisterTest(TTestCase_NoDrain_ReadAfterWait);

end.

