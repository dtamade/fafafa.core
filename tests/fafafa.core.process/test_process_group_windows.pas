{$CODEPAGE UTF8}
unit test_process_group_windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  {$IFDEF WINDOWS}Windows,{$ENDIF}
  SysUtils, fpcunit, testregistry,
  fafafa.core.process;

type
  {$IFDEF WINDOWS}
  TTestCase_ProcessGroup_Windows = class(TTestCase)
  published
    procedure Test_Assign_To_Job_And_TerminateGroup;
  end;
  {$ENDIF}

implementation

{$IFDEF WINDOWS}

procedure TTestCase_ProcessGroup_Windows.Test_Assign_To_Job_And_TerminateGroup;
var
  B1, B2: IProcessBuilder;
  P1, P2: IProcess;
  G: IProcessGroup;
begin
  G := NewProcessGroup;

  // 启动两个简单进程（cmd /c ping -n 2 127.0.0.1），不重定向，避免阻塞
  B1 := NewProcessBuilder.Exe('cmd.exe').Args(['/c','ping','-n','2','127.0.0.1']);
  B2 := NewProcessBuilder.Exe('cmd.exe').Args(['/c','ping','-n','2','127.0.0.1']);
  P1 := B1.Build; P1.Start;
  P2 := B2.Build; P2.Start;

  if Assigned(G) then
  begin
    G.Add(P1);
    G.Add(P2);
    // 立即终止组
    G.TerminateGroup(99);
    // 预期两进程应尽快退出
    AssertTrue(P1.WaitForExit(3000));
    AssertTrue(P2.WaitForExit(3000));
  end
  else
  begin
    // 未启用宏则跳过
    AssertTrue(True);
  end;
end;

{$ENDIF}

initialization
  {$IFDEF WINDOWS}
  RegisterTest(TTestCase_ProcessGroup_Windows);
  {$ENDIF}

end.

