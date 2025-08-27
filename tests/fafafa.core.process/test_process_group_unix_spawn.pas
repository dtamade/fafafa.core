unit test_process_group_unix_spawn;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{.$DEFINE LOCAL_ENABLE_SPAWN_UNIT_TEST} // 若全局未开宏，可临时在本单元强制开（不默认启用）

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.process;

type
  {$IFDEF UNIX}
  TTestCase_ProcessGroup_Unix_Spawn = class(TTestCase)
  published
    procedure Test_Spawn_PGID_TerminateGroup_Smoke;
  end;
  {$ENDIF}

implementation

{$IFDEF UNIX}
procedure TTestCase_ProcessGroup_Unix_Spawn.Test_Spawn_PGID_TerminateGroup_Smoke;
var
  G: IProcessGroup;
  C: IChild;
  B: IProcessBuilder;
  Cmd: string;
begin
  {$IFNDEF FAFAFA_PROCESS_USE_POSIX_SPAWN}
  // 若未启用 spawn 快路径，则跳过（保持子集脚本控制）
  Exit;
  {$ENDIF}

  {$IFDEF DARWIN}
  Cmd := '/bin/sh';
  {$ELSE}
  Cmd := '/bin/sh';
  {$ENDIF}

  G := NewProcessGroup;
  CheckNotNull(G, 'ProcessGroup should be available on UNIX');

  B := NewProcessBuilder
        .Command(Cmd)
        .Args(['-c','sleep 2; echo ok']);

  // 进组启动
  C := B.StartIntoGroup(G);
  try
    // 立刻终止进程组（应发送 SIGTERM→SIGKILL），不要求输出
    G.TerminateGroup(9);
    // 等待子进程结束（短等待）
    CheckTrue(C.WaitForExit(3000), 'Child should exit after group termination');
  finally
    // 无需额外清理；组对象与子进程适配器由测试框架回收
  end;
end;
{$ENDIF}

initialization
  {$IFDEF UNIX}
  RegisterTest(TTestCase_ProcessGroup_Unix_Spawn);
  {$ENDIF}

end.

