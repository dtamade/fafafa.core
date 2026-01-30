{$CODEPAGE UTF8}
unit test_graceful_shutdown;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.process;

Type
  TTestCase_GracefulShutdown = class(TTestCase)
  published
    procedure Test_GracefulShutdown_TerminatesWithinTimeout;
    procedure Test_GracefulShutdown_TimesOut_ThenKill;
  end;

implementation

procedure TTestCase_GracefulShutdown.Test_GracefulShutdown_TerminatesWithinTimeout;
var
  C: IChild;
begin
  // 启动一个快速退出的命令，优雅终止应在超时内返回 True
  C := NewProcessBuilder
        .Exe('cmd.exe')
        .Args(['/c','ping','-n','1','127.0.0.1' ]) // ~1秒
        .Start;
  CheckTrue(C.GracefulShutdown(3000), '应在时间内退出');
end;

procedure TTestCase_GracefulShutdown.Test_GracefulShutdown_TimesOut_ThenKill;
var
  C: IChild;
  TimedOut: Boolean;
begin
  // 启动一个长时间运行的命令，先优雅终止（很可能超时），然后 Kill 兜底
  C := NewProcessBuilder
        .Exe('cmd.exe')
        .Args(['/c','ping','-n','10','127.0.0.1' ]) // ~10秒
        .Start;
  TimedOut := not C.GracefulShutdown(500); // 500ms 超时
  if TimedOut then
  begin
    C.Kill;
    CheckTrue(C.WaitForExit(3000), 'Kill 后应尽快退出');
  end;
end;

initialization
  RegisterTest(TTestCase_GracefulShutdown);

end.

