program example_group_policy;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.process;

procedure DemoGroupPolicy;
var
  policy: TProcessGroupPolicy;
  g: IProcessGroup;
  c: IChild;
begin
  Writeln('--- Process Group Policy (Windows Job Object) ---');
  {$IFDEF WINDOWS}
  policy.EnableCtrlBreak := True;
  policy.EnableWmClose := True;
  policy.GracefulWaitMs := 500; // 先尝试优雅，超时后强制
  g := NewProcessGroup(policy);

  // 启动一个简单进程并加入组
  c := NewProcessBuilder
    .Command('cmd.exe')
    .Args(['/c','(echo in-group & timeout /T 2 /NOBREAK >NUL)'])
    .StartIntoGroup(g);

  // 等 200ms 后终止整组（将触发 CtrlBreak / WmClose -> 等待 -> 强制）
  Sleep(200);
  g.TerminateGroup(9);
  if not c.WaitForExit(3000) then
    Writeln('Group termination did not complete in time');
  {$ELSE}
  Writeln('Not Windows; group policy demo skipped.');
  {$ENDIF}
end;

procedure DemoCtrlBreakOnly;
var
  policy: TProcessGroupPolicy;
  g: IProcessGroup;
  c: IChild;
begin
  {$IFDEF WINDOWS}
  Writeln('--- Group Policy: CtrlBreak only ---');
  policy.EnableCtrlBreak := True;
  policy.EnableWmClose := False;
  policy.GracefulWaitMs := 300;
  g := NewProcessGroup(policy);
  c := NewProcessBuilder.Command('cmd.exe').Args(['/c','(echo ctrlbreak-only & timeout /T 2 /NOBREAK >NUL)']).StartIntoGroup(g);
  Sleep(200);
  g.TerminateGroup(9);
  c.WaitForExit(2000);
  {$ENDIF}
end;

procedure DemoWmCloseOnly;
var
  policy: TProcessGroupPolicy;
  g: IProcessGroup;
  c: IChild;
begin
  {$IFDEF WINDOWS}
  Writeln('--- Group Policy: WmClose only ---');
  policy.EnableCtrlBreak := False;
  policy.EnableWmClose := True;
  policy.GracefulWaitMs := 300;
  g := NewProcessGroup(policy);
  c := NewProcessBuilder.Command('cmd.exe').Args(['/c','(echo wmclose-only & timeout /T 2 /NOBREAK >NUL)']).StartIntoGroup(g);
  Sleep(200);
  g.TerminateGroup(9);
  c.WaitForExit(2000);
  {$ENDIF}
end;

procedure DemoForceOnly;
var
  g: IProcessGroup;
  c: IChild;
begin
  {$IFDEF WINDOWS}
  Writeln('--- Group Policy: Force only (no graceful) ---');
  // 不设置任意优雅策略，直接建立空策略的组
  g := NewProcessGroup(Default(TProcessGroupPolicy));
  c := NewProcessBuilder.Command('cmd.exe').Args(['/c','(echo force-only & timeout /T 3 /NOBREAK >NUL)']).StartIntoGroup(g);
  Sleep(200);
  // 直接强制终止整组
  g.TerminateGroup(9);
  c.WaitForExit(2000);
  {$ENDIF}
end;

begin
  try
    DemoGroupPolicy;
    DemoCtrlBreakOnly;
    DemoWmCloseOnly;
    DemoForceOnly;
  except
    on E: Exception do Writeln('Error: ', E.Message);
  end;
end.
