program example_silent_interactive;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.process;

procedure DemoSilent;
var
  text: string;
begin
  Writeln('--- Silent (hidden + capture) ---');
  text := NewProcessBuilder
    .Command({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/sh'{$ENDIF})
    .Args({$IFDEF WINDOWS}['/c','(echo Visible? & echo Silent Mode 1>&2)']{$ELSE}['-c','(echo Visible?; echo Silent Mode 1>&2)']{$ENDIF})
    .Silent
    .Output;
  Writeln(text);
end;

procedure DemoInteractive;
var
  c: IChild;
begin
  Writeln('--- Interactive (visible + no redirect) ---');
  c := NewProcessBuilder
    .Command({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/sh'{$ENDIF})
    .Args({$IFDEF WINDOWS}['/c','echo Hello Interactive']{$ELSE}['-c','echo Hello Interactive']{$ENDIF})
    .Interactive
    .Start;
  c.WaitForExit(3000);
end;

begin
  try
    DemoSilent;
    DemoInteractive;
  except
    on E: Exception do Writeln('Error: ', E.Message);
  end;
end.

