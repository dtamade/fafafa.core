{$CODEPAGE UTF8}
unit test_process_group_forceonly;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, SysUtils,
  fafafa.core.process;

type
  {$IFDEF WINDOWS}
  TTestCase_ProcessGroup_ForceOnly = class(TTestCase)
  published
    procedure Test_ForceOnly_Terminates_Quickly;
  end;
  {$ENDIF}

implementation

{$IFDEF WINDOWS}
procedure TTestCase_ProcessGroup_ForceOnly.Test_ForceOnly_Terminates_Quickly;
var
  G: IProcessGroup;
  C: IChild;
  T0, T1: QWord;
begin
  // empty/default policy means no graceful stage configured
  G := NewProcessGroup(Default(TProcessGroupPolicy));
  {$IFDEF WINDOWS}
  C := NewProcessBuilder.Command('cmd.exe').Args(['/c','(echo force-test & timeout /T 2 /NOBREAK >NUL)']).StartIntoGroup(G);
  {$ELSE}
  C := NewProcessBuilder.Command('/bin/sh').Args(['-c','(echo force-test; sleep 2)']).StartIntoGroup(G);
  {$ENDIF}
  Sleep(200);
  T0 := GetTickCount64;
  G.TerminateGroup(9);
  CheckTrue(C.WaitForExit(2000), 'ForceOnly should finish quickly');
  T1 := GetTickCount64;
  CheckTrue((T1 - T0) < 1200, 'Should not wait too long without graceful stage');
end;
{$ENDIF}

initialization
  {$IFDEF WINDOWS}
  RegisterTest(TTestCase_ProcessGroup_ForceOnly);
  {$ENDIF}
end.

