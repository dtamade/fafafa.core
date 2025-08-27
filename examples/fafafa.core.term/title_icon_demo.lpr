{$CODEPAGE UTF8}
program title_icon_demo;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, fafafa.core.term;

begin
  if not term_init then Halt(1);
  try
    term_writeln('Setting window title and icon title (if supported)...');

    if term_support_title_set then
    begin
      if term_title_set('fafafa.core.term - Title Demo') then
        term_writeln('Title set ok')
      else
        term_writeln('Title set attempted but not applied');
    end
    else
      term_writeln('Title set not supported');

    if term_support_icon_set then
    begin
      if term_icon_set('Icon Demo') then
        term_writeln('Icon title set ok')
      else
        term_writeln('Icon title set attempted but not applied');
    end
    else
      term_writeln('Icon title set not supported');

    term_writeln('Sleep 1s, then exit...');
    Sleep(1000);
  finally
    term_done;
  end;
end.

