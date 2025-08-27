program example_pipeline_failfast;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.process,
  fafafa.core.pipeline;

procedure RunDemo;
var
  P: IPipeline;
  outStr: string;
begin
  WriteLn('=== Pipeline: MergeStdErr + CaptureOutput + FailFast ===');
  {$IFDEF WINDOWS}
  // stage1: 输出到 stdout
  // stage2: 产生错误输出并非零退出，触发 FailFast 杀掉其他阶段
  P := NewPipeline
        .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','echo','HELLO']))
        .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','powershell','-NoProfile','-Command','Write-Error "ERR"; exit 3']))
        .CaptureOutput(True)
        .MergeStdErr(True)
        .FailFast(True)
        .Start;
  {$ELSE}
  P := NewPipeline
        .Add(NewProcessBuilder.Command('/bin/echo').Args(['HELLO']))
        .Add(NewProcessBuilder.Command('/bin/sh').Args(['-c','echo ERR 1>&2; exit 3']))
        .CaptureOutput(True)
        .MergeStdErr(True)
        .FailFast(True)
        .Start;
  {$ENDIF}

  // 等待
  if P.WaitForExit(2000) then
  begin
    WriteLn('Status: ', P.Status, ' Success: ', P.Success);
    outStr := P.Output;
    WriteLn('Captured Output:');
    WriteLn(outStr);
  end
  else
  begin
    WriteLn('Timeout waiting pipeline');
    P.KillAll;
  end;
end;

begin
  try
    RunDemo;
  except
    on E: Exception do begin
      WriteLn('Error: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.

