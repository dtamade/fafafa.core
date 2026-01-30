program example_pipeline_best_practices;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.process,
  fafafa.core.pipeline;

procedure DemoMergedOutput;
var
  P: IPipeline;
  S: string;
begin
  Writeln('=== Pipeline Best Practice: Merged output at tail ===');
  {$IFDEF WINDOWS}
  P := NewPipeline
        .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','echo HELLO']))
        .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','(echo OK & echo ERR 1>&2)']))
        .CaptureOutput(True)
        .MergeStdErr(True)
        .Start;
  {$ELSE}
  P := NewPipeline
        .Add(NewProcessBuilder.Command('/bin/echo').Args(['HELLO']))
        .Add(NewProcessBuilder.Command('/bin/sh').Args(['-c','(echo OK; echo ERR 1>&2)']))
        .CaptureOutput(True)
        .MergeStdErr(True)
        .Start;
  {$ENDIF}
  if P.WaitForExit(3000) then
  begin
    S := P.Output;
    Writeln(S);
  end;
end;

procedure DemoSplitOutput;
var
  P: IPipeline;
  OutText, ErrText: string;
begin
  Writeln('=== Pipeline Best Practice: Split output at tail ===');
  {$IFDEF WINDOWS}
  P := NewPipeline
        .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','echo HELLO']))
        .Add(NewProcessBuilder.Command('cmd.exe').Args(['/c','(echo OK & echo ERR 1>&2)']))
        .CaptureOutput(True)
        .MergeStdErr(False)
        .Start;
  {$ELSE}
  P := NewPipeline
        .Add(NewProcessBuilder.Command('/bin/echo').Args(['HELLO']))
        .Add(NewProcessBuilder.Command('/bin/sh').Args(['-c','(echo OK; echo ERR 1>&2)']))
        .CaptureOutput(True)
        .MergeStdErr(False)
        .Start;
  {$ENDIF}
  if P.WaitForExit(3000) then
  begin
    OutText := P.Output;
    ErrText := P.ErrorText;
    Writeln('[stdout]'); Writeln(OutText);
    Writeln('[stderr]'); Writeln(ErrText);
  end;
end;

begin
  try
    DemoMergedOutput;
    DemoSplitOutput;
  except
    on E: Exception do Writeln('Error: ', E.Message);
  end;
end.

