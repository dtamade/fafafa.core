program example_background_foreground;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.process;

procedure DemoBackground;
var
  c: IChild;
begin
  Writeln('--- Background (hidden + low priority) ---');
  c := NewProcessBuilder
    .Command({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/sh'{$ENDIF})
    .Args({$IFDEF WINDOWS}['/c','echo BG task && timeout /T 2 /NOBREAK >NUL']{$ELSE}['-c','echo BG task; sleep 2']{$ENDIF})
    .Background
    .Start;
  if not c.WaitForExit(5000) then
    Writeln('Background did not finish in 5s');
end;

procedure DemoForeground;
var
  c: IChild;
begin
  Writeln('--- Foreground (normal window + normal priority) ---');
  c := NewProcessBuilder
    .Command({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/sh'{$ENDIF})
    .Args({$IFDEF WINDOWS}['/c','echo FG task']{$ELSE}['-c','echo FG task']{$ENDIF})
    .Foreground
    .Start;
  c.WaitForExit(3000);
end;

begin
  try
    DemoBackground;
    DemoForeground;
  except
    on E: Exception do Writeln('Error: ', E.Message);
  end;
end.

