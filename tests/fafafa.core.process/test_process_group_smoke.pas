{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
unit test_process_group_smoke;

interface
uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.process;

type
  TTestCase_ProcessGroup_Smoke = class(TTestCase)
  published
    procedure Test_Assign_And_TerminateGroup_Smoke;
  end;

implementation

procedure TTestCase_ProcessGroup_Smoke.Test_Assign_And_TerminateGroup_Smoke;
var
  B: IProcessBuilder;
  G: IProcessGroup;
  C: IChild;
begin
  {$IFNDEF FAFAFA_PROCESS_GROUPS}
  Skip('FAFAFA_PROCESS_GROUPS disabled');
  Exit;
  {$ENDIF}
  {$IFNDEF WINDOWS}
  Skip('Windows-only smoke');
  Exit;
  {$ENDIF}

  G := NewProcessGroup;
  AssertNotNull('Group should be created', TObject(G));

  B := NewProcessBuilder()
    .Command('powershell.exe')
    .Args(['-NoProfile','-Command','Start-Sleep -Seconds 10'])
    .WindowHidden;

  C := B.StartIntoGroup(G);
  AssertTrue('Child should have valid pid', C.ProcessId <> 0);

  Sleep(300);
  G.TerminateGroup(1);

  AssertTrue('Child should exit after group termination', C.WaitForExit(5000));
  AssertEquals('ExitCode should be group code', 1, C.ExitCode);
end;

initialization
  RegisterTest(TTestCase_ProcessGroup_Smoke);
end.

