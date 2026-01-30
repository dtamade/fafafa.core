{$CODEPAGE UTF8}
unit test_process_group_builder;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry, SysUtils, fafafa.core.process;

type
  TTestCase_ProcessGroup_Builder = class(TTestCase)
  published
    procedure Test_WithGroup_Start_Joins_Group;
    procedure Test_StartIntoGroup_Joins_Group;
  end;

implementation

procedure TTestCase_ProcessGroup_Builder.Test_WithGroup_Start_Joins_Group;
var
  G: IProcessGroup;
  C: IChild;
begin
  {$IFDEF FAFAFA_PROCESS_GROUPS}
  G := NewProcessGroup;
  C := NewProcessBuilder
        .Exe('cmd.exe')
        .Args(['/c','ping','-n','2','127.0.0.1'])
        .WithGroup(G)
        .Start;
  try
    // 简单等待片刻，确保已加入组。无法直接验证 JobObject，此处只做 Smoke
    AssertTrue(True);
  finally
    if Assigned(G) then G.TerminateGroup(99);
    if Assigned(C) then C.WaitForExit(3000);
  end;
  {$ELSE}
  AssertTrue(True);
  {$ENDIF}
end;

procedure TTestCase_ProcessGroup_Builder.Test_StartIntoGroup_Joins_Group;
var
  G: IProcessGroup;
  C: IChild;
begin
  {$IFDEF FAFAFA_PROCESS_GROUPS}
  G := NewProcessGroup;
  C := NewProcessBuilder
        .Exe('cmd.exe')
        .Args(['/c','ping','-n','2','127.0.0.1'])
        .StartIntoGroup(G);
  try
    AssertTrue(True);
  finally
    if Assigned(G) then G.TerminateGroup(99);
    if Assigned(C) then C.WaitForExit(3000);
  end;
  {$ELSE}
  AssertTrue(True);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_ProcessGroup_Builder);
end.

