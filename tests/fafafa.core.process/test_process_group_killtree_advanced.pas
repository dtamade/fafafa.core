{$CODEPAGE UTF8}
unit test_process_group_killtree_advanced;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry, SysUtils, fafafa.core.process;

type
  {$IFDEF WINDOWS}
  TTestCase_ProcessGroup_KillTree_Advanced = class(TTestCase)
  published
    procedure Test_TerminateGroup_Kills_Deeply_Nested_Chain;
    procedure Test_TerminateGroup_Multiple_Processes_Exit_Quickly;
  end;
  {$ENDIF}

implementation

{$IFDEF WINDOWS}
procedure TTestCase_ProcessGroup_KillTree_Advanced.Test_TerminateGroup_Kills_Deeply_Nested_Chain;
var
  G: IProcessGroup;
  C: IChild;
  B: IProcessBuilder;
begin
  G := NewProcessGroup;
  // 三层嵌套：cmd -> cmd -> ping（较长延时）
  B := NewProcessBuilder
        .Exe('cmd.exe')
        .Args(['/c', 'cmd', '/c', 'cmd', '/c', 'ping', '-n', '10', '127.0.0.1', '>nul']);
  C := B.StartIntoGroup(G);
  Sleep(500);
  G.TerminateGroup(200);
  AssertTrue('deep nested should exit quickly after KillTree', C.WaitForExit(5000));
end;

procedure TTestCase_ProcessGroup_KillTree_Advanced.Test_TerminateGroup_Multiple_Processes_Exit_Quickly;
var
  G: IProcessGroup;
  C1, C2: IChild;
begin
  G := NewProcessGroup;
  C1 := NewProcessBuilder.Exe('cmd.exe').Args(['/c','ping','-n','10','127.0.0.1','>nul']).StartIntoGroup(G);
  C2 := NewProcessBuilder.Exe('cmd.exe').Args(['/c','ping','-n','10','127.0.0.1','>nul']).StartIntoGroup(G);
  Sleep(300);
  G.TerminateGroup(201);
  AssertTrue('proc1 should exit', C1.WaitForExit(5000));
  AssertTrue('proc2 should exit', C2.WaitForExit(5000));
end;
{$ENDIF}

initialization
  {$IFDEF WINDOWS}
  RegisterTest(TTestCase_ProcessGroup_KillTree_Advanced);
  {$ENDIF}
end.

