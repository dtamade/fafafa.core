unit test_edgecases_additional;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry, fafafa.core.process;

type
  TTestCase_Process_Edge = class(TTestCase)
  published
    procedure WaitForExit_WhenAlreadyExited_ReturnsTrue;
    {$IFDEF WINDOWS}
    procedure TerminateThenWait_GracefulTimeoutKills;
    {$ENDIF}
    procedure UsePathSearch_Disabled_RelativeNameFails;
  end;

implementation

{$IFDEF WINDOWS}
uses SysUtils;
{$ENDIF}

procedure TTestCase_Process_Edge.WaitForExit_WhenAlreadyExited_ReturnsTrue;
var
  P: IProcess;
begin
  P := TProcessBuilder.Create
        .Executable('echo')
        .Arg('ok')
        .UsePathSearch(True)
        .Build;
  P.Start;
  AssertTrue('process should exit', P.WaitForExit(3000));
  // already-exited path should fast return true and keep state consistent
  AssertTrue('already exited should return true', P.WaitForExit(0));
  AssertTrue('HasExited should be true', P.HasExited);
end;

{$IFDEF WINDOWS}
procedure TTestCase_Process_Edge.TerminateThenWait_GracefulTimeoutKills;
var
  Policy: TProcessGroupPolicy;
  G: IProcessGroup;
  P: IProcess;
begin
  Policy.EnableCtrlBreak := True;
  Policy.EnableWmClose := False;
  Policy.GracefulWaitMs := 300;
  G := NewProcessGroup(Policy);
  P := TProcessBuilder.Create
        .Executable('cmd')
        .Args(['/c','ping','-n','5','127.0.0.1','>NUL'])
        .Build;
  P.Start;
  G.Add(P);
  G.TerminateGroup(1);
  AssertTrue('process should exit after group termination', P.WaitForExit(2000));
  AssertTrue('HasExited should be true after termination', P.HasExited);
end;
{$ENDIF}

procedure TTestCase_Process_Edge.UsePathSearch_Disabled_RelativeNameFails;
var
  P: IProcess;
begin
  P := TProcessBuilder.Create
        .Executable('echo')
        .UsePathSearch(False)
        .Build;
  try
    P.Start;
    Fail('relative command should fail when UsePathSearch=False');
  except
    on E: EProcessStartError do ; // expected
  end;
end;

initialization
  RegisterTest(TTestCase_Process_Edge);

end.

