program example_pipeline_redirect_and_split;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.process,
  fafafa.core.pipeline;

procedure DemoRedirectFileAndSplitErr;
var
  P: IPipeline;
  OutFile: string;
  ErrText: string;
begin
  Writeln('=== Pipeline: stdout -> file, stderr -> memory (split) ===');
  {$IFDEF WINDOWS}
  OutFile := 'out_redirect.txt';
  P := NewPipeline
        .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','(echo LINE1 & echo ERR 1>&2 & echo LINE2)']))
        .CaptureOutput(True)
        .MergeStdErr(False)
        .RedirectStdOutToFile(OutFile, False)
        .Start;
  {$ELSE}
  OutFile := 'out_redirect.txt';
  P := NewPipeline
        .Add(NewProcessBuilder.Command('/bin/sh').Args(['-c','(echo LINE1; echo ERR 1>&2; echo LINE2)']))
        .CaptureOutput(True)
        .MergeStdErr(False)
        .RedirectStdOutToFile(OutFile, False)
        .Start;
  {$ENDIF}

  if P.WaitForExit(3000) then
  begin
    ErrText := P.ErrorText;
    Writeln('[stderr]');
    Writeln(ErrText);
    Writeln('[stdout -> file] ', OutFile);
  end;
end;

begin
  try
    DemoRedirectFileAndSplitErr;
  except
    on E: Exception do Writeln('Error: ', E.Message);
  end;
end.

