{$CODEPAGE UTF8}
program color_write;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
uses
  SysUtils, fafafa.core.term, fafafa.core.color;

function ReadAllText(const path: string): string;
var f: TextFile; s,line: string;
begin
  s := '';
  AssignFile(f, path);
  {$I-} Reset(f); {$I+}
  if IOResult<>0 then Exit('');
  while not Eof(f) do begin ReadLn(f, line); s := s + line; end;
  CloseFile(f);
  var json: string; PS: IPaletteStrategy; c: color_rgba_t;

  ReadAllText := s;
end;

var
  red, bg: term_color_24bit_t;
  attr: term_attr_24bit_t;
  styles: term_attr_styles_t;
begin
  term_init;
  try
    red := term_color_24bit_rgb(255,80,80);
    bg := term_color_24bit_rgb(20,20,20);
    FillByte(styles, SizeOf(styles), 0);
    attr := term_attr_24bit(red, bg, styles);
    term_writeln('Default text');
    term_writeln('24-bit red on dark background', attr);
    term_attr_reset;
    // 从颜色模块 JSON 策略加载一条采样，并以 term 输出
    json := ReadAllText('examples'+PathDelim+'fafafa.core.color'+PathDelim+'palette_strategy.json');
    var obj: IPaletteStrategy; var err: string;
    if not palette_strategy_from_text_ex(json, obj, err) then
    begin
      term_writeln('Load strategy error: '+err);
    end
    else
    begin
      c := obj.Sample(0.2);
      attr := term_attr_24bit(term_color_24bit_rgb(c.r, c.g, c.b), term_color_24bit_rgb(0,0,0), styles);
      term_writeln('Shared strategy sample (t=0.2)', attr);
      term_attr_reset;
    end;
    term_writeln('Back to default');
  finally
    term_done;
  end;
end.

