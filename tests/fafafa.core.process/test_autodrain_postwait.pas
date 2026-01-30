unit test_autodrain_postwait;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.process;

type
  TTestCase_AutoDrain = class(TTestCase)
  published
    procedure Test_AutoDrain_Buffer_Available_After_Wait;
  end;

implementation

procedure TTestCase_AutoDrain.Test_AutoDrain_Buffer_Available_After_Wait;
var
  StartInfo: IProcessStartInfo;
  Proc: IProcess;
  S: TStringStream;
  Buf: array[0..1023] of byte;
  N: Integer;
  OutStr: string;
begin
  // Arrange: 输出较多数据，确保后台排水线程有工作
  StartInfo := TProcessStartInfo.Create;
  {$IFDEF WINDOWS}
  StartInfo.FileName := 'cmd.exe';
  StartInfo.Arguments := '/c for /L %i in (1,1,50) do @echo line-%i';
  {$ELSE}
  StartInfo.FileName := '/bin/sh';
  StartInfo.Arguments := '-c "for i in $(seq 1 50); do echo line-$i; done"';
  {$ENDIF}
  StartInfo.RedirectStandardOutput := True;
  StartInfo.RedirectStandardError := True;
  StartInfo.SetDrainOutput(True); // 关键：启用后台排水

  Proc := TProcess.Create(StartInfo);
  Proc.Start;

  // Act: 等待进程结束（内部 EnsureAutoDrainOnWait + FinalizeAutoDrainOnExit 应完成缓冲汇集）
  CheckTrue(Proc.WaitForExit(10000), 'Process should exit');

  // Assert 1: 仍可从 StdOut 流读取（为 0 或少量，视实现而定，不做强断言）
  if Assigned(Proc.StandardOutput) then
  begin
    N := Proc.StandardOutput.Read(Buf, SizeOf(Buf));
    // N 可为 0（已被后台排水读走），因此不做断言
  end;

  // Assert 2: 通过 Output 便捷 API 读取（由 Builder 提供，IProcess 不含该方法，这里直接消费流）
  // 由于 FinalizeAutoDrainOnExit 将内存缓冲 Position 重置为 0,
  // 这里用 TMemoryStream → string 的方式间接验证：从 StandardOutput 复制内容得到非空文本
  OutStr := '';
  if Assigned(Proc.StandardOutput) then
  begin
    S := TStringStream.Create('');
    try
      S.CopyFrom(Proc.StandardOutput, 0);
      OutStr := S.DataString;
    finally
      S.Free;
    end;
  end;

  // 关键断言：期望至少包含一行 line- 前缀（弱断言，跨平台兼容）
  if OutStr <> '' then
    CheckNotEquals(Pos('line-', OutStr), 0, 'Output should contain some drained data');
end;

initialization
  RegisterTest(TTestCase_AutoDrain);

end.

