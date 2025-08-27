program pipeline_sort_filter;
{$mode objfpc}{$H+}

uses
  SysUtils, fafafa.core.process, fafafa.core.pipeline;

var
  P: IPipeline;
begin
  P := NewPipeline
    .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','(echo apple & echo banana & echo apple & echo cherry)']))
    .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','sort']))
    .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','findstr','/i','a']))
    .CaptureOutput
    .Start;

  if P.WaitForExit(5000) and P.Success then
    Writeln(P.Output)
  else
    Writeln('Pipeline failed');
end.

