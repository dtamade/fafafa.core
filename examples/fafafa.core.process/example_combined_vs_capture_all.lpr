program example_combined_vs_capture_all;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fafafa.core.process;

procedure DemoCombinedOutput;
var
  text: string;
begin
  Writeln('--- CombinedOutput (merged) ---');
  text := NewProcessBuilder
    .Command({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/sh'{$ENDIF})
    .Args({$IFDEF WINDOWS}['/c','(echo OUT & echo ERR 1>&2)']{$ELSE}['-c','(echo OUT; echo ERR 1>&2)']{$ENDIF})
    .CombinedOutput
    .Output;
  Writeln(text);
end;

procedure DemoCaptureAll;
var
  c: IChild;
  s: TStringStream;
  outText, errText: string;
begin
  Writeln('--- CaptureAll (separate) ---');
  c := NewProcessBuilder
    .Command({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/sh'{$ENDIF})
    .Args({$IFDEF WINDOWS}['/c','(echo OUT & echo ERR 1>&2)']{$ELSE}['-c','(echo OUT; echo ERR 1>&2)']{$ENDIF})
    .CaptureAll
    .Start;
  if c.WaitForExit(5000) then
  begin
    if Assigned(c.StandardOutput) then
    begin
      s := TStringStream.Create('');
      try
        s.CopyFrom(c.StandardOutput, 0);
        outText := s.DataString;
      finally
        s.Free;
      end;
    end;
    if Assigned(c.StandardError) then
    begin
      s := TStringStream.Create('');
      try
        s.CopyFrom(c.StandardError, 0);
        errText := s.DataString;
      finally
        s.Free;
      end;
    end;
    Writeln('[stdout]'); Writeln(outText);
    Writeln('[stderr]'); Writeln(errText);
  end;
end;

begin
  try
    DemoCombinedOutput;
    DemoCaptureAll;
  except
    on E: Exception do
      Writeln('Error: ', E.Message);
  end;
end.

