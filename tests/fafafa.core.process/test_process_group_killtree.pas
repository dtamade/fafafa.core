{$CODEPAGE UTF8}
unit test_process_group_killtree;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry, SysUtils, fafafa.core.process;

type
  {$IFDEF WINDOWS}
  TTestCase_ProcessGroup_KillTree = class(TTestCase)
  published
    procedure Test_TerminateGroup_Kills_Nested_Children;
  end;
  {$ENDIF}

implementation

{$IFDEF WINDOWS}
// 启动一个嵌套命令：外层 cmd /c 启动内层 cmd /c ping
procedure TTestCase_ProcessGroup_KillTree.Test_TerminateGroup_Kills_Nested_Children;
var
  G: IProcessGroup;
  C: IChild;
  B: IProcessBuilder;
begin
  G := NewProcessGroup;
  // 内层 ping 较短，外层延时确保处于运行态
  B := NewProcessBuilder
        .Exe('cmd.exe')
        .Args(['/c', 'cmd', '/c', 'ping', '-n', '5', '127.0.0.1']);
  C := B.StartIntoGroup(G);
  Sleep(500);
  // 终止整个组，验证能尽快退出
  G.TerminateGroup(77);
  AssertTrue('nested should exit quickly', C.WaitForExit(4000));
end;
{$ENDIF}

initialization
  {$IFDEF WINDOWS}
  RegisterTest(TTestCase_ProcessGroup_KillTree);
  {$ENDIF}
end.

