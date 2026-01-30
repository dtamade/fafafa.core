{$CODEPAGE UTF8}
program example_group;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, fafafa.core.process;

var
  G: IProcessGroup;
  C1, C2: IChild;
begin
  WriteLn('fafafa.core.process - example_group');
  {$IFDEF FAFAFA_PROCESS_GROUPS}
  G := NewProcessGroup;
  C1 := NewProcessBuilder.Exe('cmd.exe').Args(['/c','ping','-n','3','127.0.0.1']).WithGroup(G).Start;
  C2 := NewProcessBuilder.Exe('cmd.exe').Args(['/c','ping','-n','3','127.0.0.1']).StartIntoGroup(G);
  Sleep(1000);
  Writeln('Terminate group...');
  G.TerminateGroup(99);
  C1.WaitForExit(3000);
  C2.WaitForExit(3000);
  Writeln('Done');
  {$ELSE}
  Writeln('FAFAFA_PROCESS_GROUPS not enabled.');
  {$ENDIF}
end.

