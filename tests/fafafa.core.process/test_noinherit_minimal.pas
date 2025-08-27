unit test_noinherit_minimal;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.process;

type
  { TTestCase_NoInherit_Minimal }
  TTestCase_NoInherit_Minimal = class(TTestCase)
  published
    procedure Start_NoRedirect_ShouldExit_WithinTimeout;
  end;

implementation

procedure TTestCase_NoInherit_Minimal.Start_NoRedirect_ShouldExit_WithinTimeout;
var
  SI: IProcessStartInfo;
  P: IProcess;
  Ok: Boolean;
begin
  {$IFDEF WINDOWS}
  // 无任何重定向/合流：应当 bInheritHandles=False 仍能正常启动并退出
  SI := TProcessStartInfo.Create('cmd.exe', '/c echo NoInheritOK');
  // 不设置任何 Redirect*
  P := TProcess.Create(SI);
  P.Start;
  Ok := P.WaitForExit(3000);
  AssertTrue('Process should exit within timeout without redirection', Ok);
  AssertEquals('Exit code should be 0', 0, P.ExitCode);
  {$ELSE}
  // 非 Windows 平台跳过
  AssertTrue('Skip on non-Windows', True);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_NoInherit_Minimal);

end.

