{$CODEPAGE UTF8}
unit test_process_group_unix_basic;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry, SysUtils, fafafa.core.process;

type
  {$IFDEF UNIX}
  TTestCase_ProcessGroup_Unix_Basic = class(TTestCase)
  published
    procedure Test_TerminateGroup_Kills_Sleep_Chain;
  end;
  {$ENDIF}

implementation

{$IFDEF UNIX}
procedure TTestCase_ProcessGroup_Unix_Basic.Test_TerminateGroup_Kills_Sleep_Chain;
var
  G: IProcessGroup;
  C: IChild;
  B: IProcessBuilder;
begin
  G := NewProcessGroup;
  // /bin/sh -c "sh -c 'sleep 5'"
  B := NewProcessBuilder.Exe('/bin/sh').Args(['-c', 'sh -c "sleep 5"']);
  C := B.StartIntoGroup(G);
  Sleep(200);
  G.TerminateGroup(123);
  AssertTrue('unix chain should exit quickly', C.WaitForExit(3000));
end;
{$ENDIF}

initialization
  {$IFDEF UNIX}
  RegisterTest(TTestCase_ProcessGroup_Unix_Basic);
  {$ENDIF}
end.

