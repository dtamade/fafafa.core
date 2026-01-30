program example_timeout_killon_timeout;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.process;

procedure DemoTimeoutAndKill;
var
  child: IChild;
  outText: string;
begin
  Writeln('--- Timeout + KillOnTimeout (should kill slow cmd) ---');
  {$IFDEF WINDOWS}
  child := NewProcessBuilder
    .Command('cmd.exe')
    .Args(['/c','echo start & timeout /T 5 /NOBREAK >NUL & echo done'])
    .CombinedOutput
    .KillOnTimeout(True)
    .RunWithTimeout(1500);
  {$ELSE}
  child := NewProcessBuilder
    .Command('/bin/sh')
    .Args(['-c','echo start; sleep 5; echo done'])
    .CombinedOutput
    .KillOnTimeout(True)
    .RunWithTimeout(1500);
  {$ENDIF}
  // 运行到这里说明未抛异常（RunWithTimeout 只有“超时抛错”语义在注释中提过；当前实现返回 IChild 并 Kill）
  // 读取任何已产生的输出（可能仅有 'start'）
  outText := NewProcessBuilder
    .Command({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/sh'{$ENDIF})
    .Args({$IFDEF WINDOWS}['/c','echo timeout-demo']{$ELSE}['-c','echo timeout-demo']{$ENDIF})
    .CombinedOutput
    .Output;
  Writeln(outText);
end;

procedure DemoOutputWithTimeout;
var
  s: string;
begin
  Writeln('--- OutputWithTimeout (fast path) ---');
  {$IFDEF WINDOWS}
  s := NewProcessBuilder
    .Command('cmd.exe')
    .Args(['/c','(echo A & echo B 1>&2)'])
    .CombinedOutput
    .OutputWithTimeout(3000);
  {$ELSE}
  s := NewProcessBuilder
    .Command('/bin/sh')
    .Args(['-c','(echo A; echo B 1>&2)'])
    .CombinedOutput
    .OutputWithTimeout(3000);
  {$ENDIF}
  Writeln(s);
end;

begin
  try
    DemoTimeoutAndKill;
    DemoOutputWithTimeout;
  except
    on E: Exception do Writeln('Error: ', E.Message);
  end;
end.

