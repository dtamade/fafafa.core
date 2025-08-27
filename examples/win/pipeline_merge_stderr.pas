program pipeline_merge_stderr;
{$mode objfpc}{$H+}

uses
  SysUtils, fafafa.core.process, fafafa.core.pipeline;

var
  P: IPipeline;
begin
  P := NewPipeline
    .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','(echo out & echo err 1>&2)']))
    .CaptureOutput
    .MergeStdErr(True)
    .Start;

  if P.WaitForExit(5000) and P.Success then
    Writeln(P.Output)
  else
    Writeln('Pipeline failed');
end.

