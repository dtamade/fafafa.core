program example_both_redirect_to_file;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.process,
  fafafa.core.pipeline;

procedure RunDemo;
var
  P: IPipeline;
  ok: Boolean;
  OutFile, ErrFile: string;
begin
  WriteLn('=== Redirect both stdout and stderr to files via Pipeline ===');
  OutFile := 'both_out.txt';
  ErrFile := 'both_err.txt';

  {$IFDEF WINDOWS}
  P := NewPipeline
         .Add(NewProcessBuilder.Command('cmd.exe').Args([
           '/c','powershell','-NoProfile','-Command',
           'Write-Output "OUT_A"; Write-Error "ERR_A"; Write-Output "OUT_B"; Write-Error "ERR_B"; exit 0'
         ]))
         .RedirectStdOutToFile(OutFile)
         .RedirectStdErrToFile(ErrFile)
         .Start;
  {$ELSE}
  P := NewPipeline
         .Add(NewProcessBuilder.Command('/bin/sh').Args(['-c','echo OUT_A; echo ERR_A 1>&2; echo OUT_B; echo ERR_B 1>&2; exit 0']))
         .RedirectStdOutToFile(OutFile)
         .RedirectStdErrToFile(ErrFile)
         .Start;
  {$ENDIF}

  ok := P.WaitForExit(3000);
  if not ok then
  begin
    WriteLn('Timeout waiting pipeline, killing...');
    P.KillAll;
    Halt(1);
  end;

  WriteLn('Done. Files written:');
  WriteLn('  stdout -> ', OutFile);
  WriteLn('  stderr -> ', ErrFile);
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

