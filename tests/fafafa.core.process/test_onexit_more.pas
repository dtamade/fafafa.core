{$CODEPAGE UTF8}
unit test_onexit_more;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry, SysUtils,
  fafafa.core.process;

type
  TTestCase_OnExit_More = class(TTestCase)
  published
    procedure OnExit_Immediate_WhenAlreadyExited;
    procedure OnExit_MultipleRegistration_AllInvoked;
  end;

implementation

procedure TTestCase_OnExit_More.OnExit_Immediate_WhenAlreadyExited;
var
  SI: IProcessStartInfo;
  P: IProcess;
  Flag: Boolean = False;
begin
  {$IFDEF WINDOWS}
  SI := TProcessStartInfo.Create('cmd.exe','/c echo OK');
  {$ELSE}
  SI := TProcessStartInfo.Create('/bin/echo','OK');
  {$ENDIF}
  P := TProcess.Create(SI);
  P.Start;
  P.WaitForExit(2000);
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  P.OnExit(
    procedure
    begin
      Flag := True;
    end
  );
  AssertTrue('OnExit should invoke immediately when already exited', Flag);
  {$ELSE}
  AssertTrue('Skip OnExit check when anonymous not available', True);
  {$ENDIF}
end;

procedure TTestCase_OnExit_More.OnExit_MultipleRegistration_AllInvoked;
var
  SI: IProcessStartInfo;
  P: IProcess;
  F1, F2: Boolean;
begin
  F1 := False; F2 := False;
  {$IFDEF WINDOWS}
  SI := TProcessStartInfo.Create('cmd.exe','/c echo OK');
  {$ELSE}
  SI := TProcessStartInfo.Create('/bin/echo','OK');
  {$ENDIF}
  P := TProcess.Create(SI);
  P.Start;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  P.OnExit(
    procedure
    begin
      F1 := True;
    end
  );
  P.OnExit(
    procedure
    begin
      F2 := True;
    end
  );
  {$ENDIF}
  P.WaitForExit(2000);
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  // 允许多次注册：都应被调用
  Sleep(10);
  AssertTrue('first callback should be invoked', F1);
  AssertTrue('second callback should be invoked', F2);
  {$ELSE}
  AssertTrue('Skip OnExit multiple registration when anonymous not available', True);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_OnExit_More);
end.

