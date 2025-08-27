program pipeline_where_to_file;
{$mode objfpc}{$H+}

uses
  SysUtils, fafafa.core.process, fafafa.core.pipeline;

var
  P: IPipeline;
begin
  P := NewPipeline
    .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','where','/r','.', '*.pas']))
    .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','findstr','/i','process']))
    .RedirectStdOutToFile('out.log', False)
    .Start;

  if P.WaitForExit(15000) and P.Success then
    Writeln('done: out.log')
  else
    Writeln('Pipeline failed');
end.

