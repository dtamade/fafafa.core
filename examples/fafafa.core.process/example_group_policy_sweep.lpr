program example_group_policy_sweep;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, DateUtils,
  fafafa.core.process;

function StrToUIntDefEx(const S: string; const ADefault: Cardinal): Cardinal;
var
  V: QWord;
begin
  try
    V := StrToQWord(S);
    if V > High(Cardinal) then Exit(ADefault);
    Result := V;
  except
    Result := ADefault;
  end;
end;

procedure RunOnce(const AGracefulMs: Cardinal);
var
  policy: TProcessGroupPolicy;
  g: IProcessGroup;
  c: IChild;
  t0, t1: QWord;
begin
  {$IFDEF WINDOWS}
  policy.EnableCtrlBreak := True;
  policy.EnableWmClose := True;
  policy.GracefulWaitMs := AGracefulMs;
  g := NewProcessGroup(policy);

  Writeln('--- Sweep GracefulWaitMs = ', AGracefulMs, ' ---');

  // 启动一个会等待几秒的命令
  c := NewProcessBuilder
    .Command('cmd.exe')
    .Args(['/c','(echo start & timeout /T 3 /NOBREAK >NUL & echo end)'])
    .StartIntoGroup(g);

  Sleep(200); // 给子进程一点启动时间
  t0 := GetTickCount64;
  g.TerminateGroup(9);
  c.WaitForExit(5000);
  t1 := GetTickCount64;

  Writeln('elapsedAfterTerminate(ms)=', (t1 - t0));
  {$ELSE}
  Writeln('Not Windows; sweep skipped.');
  {$ENDIF}
end;

var
  ms: Cardinal;
begin
  try
    ms := 500;
    if ParamCount >= 1 then
      ms := StrToUIntDefEx(ParamStr(1), 500);
    RunOnce(ms);
  except
    on E: Exception do Writeln('Error: ', E.Message);
  end;
end.

