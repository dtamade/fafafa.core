{$CODEPAGE UTF8}
unit test_graceful_shutdown_unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.process
  {$IFDEF UNIX}, BaseUnix{$ENDIF}
  ;

{$IFDEF UNIX}

type
  TTestCase_GracefulShutdown_Unix = class(TTestCase)
  published
    procedure Test_GracefulShutdown_TerminatesWithinTimeout_Unix;
    procedure Test_GracefulShutdown_TimesOut_ThenKill_Unix;
  end;

{$ENDIF}

implementation

{$IFDEF UNIX}

procedure TTestCase_GracefulShutdown_Unix.Test_GracefulShutdown_TerminatesWithinTimeout_Unix;
var
  C: IChild;
begin
  // 使用 /bin/sh -c 'sleep 1'，优雅终止应在超时内返回 True
  C := NewProcessBuilder
         .Exe('/bin/sh')
         .Args(['-c','sleep 1'])
         .Start;
  CheckTrue('应在时间内退出', C.GracefulShutdown(3000));
end;

procedure TTestCase_GracefulShutdown_Unix.Test_GracefulShutdown_TimesOut_ThenKill_Unix;
var
  C: IChild;
  TimedOut: Boolean;
begin
  // 使用 /bin/sh -c 'sleep 10' 模拟长任务：先优雅终止（预计超时），再 Kill 兜底
  C := NewProcessBuilder
         .Exe('/bin/sh')
         .Args(['-c','sleep 10'])
         .Start;
  TimedOut := not C.GracefulShutdown(300); // 300ms 超时
  if TimedOut then
  begin
    C.Kill;
    CheckTrue('Kill 后应尽快退出', C.WaitForExit(3000));
  end;
end;

{$ENDIF}

initialization
{$IFDEF UNIX}
  RegisterTest(TTestCase_GracefulShutdown_Unix);
{$ENDIF}

end.

