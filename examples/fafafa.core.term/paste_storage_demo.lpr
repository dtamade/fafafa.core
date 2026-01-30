{$CODEPAGE UTF8}
program paste_storage_demo;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, fafafa.core.term;
var
  id: SizeUInt;
  txt: string;
begin
  term_paste_defaults_ex(4*1024, 64*1024, 'tui');
  id := term_paste_store_text(StringOfChar('A', 20000));
  term_writeln('stored id=' + IntToStr(id));
  term_writeln('count=' + IntToStr(term_paste_get_count));
  term_writeln('total=' + IntToStr(term_paste_get_total_bytes));
  txt := term_paste_get_text(id);
  term_writeln('retrieved length=' + IntToStr(Length(txt)));
end.

