program palette_demo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.term;

var
  mode256: Boolean = True;
  showGray: Boolean = False;
  E: term_event_t;

  showCube: Boolean = False;

procedure Show16;
var i: Integer;
begin
  term_writeln('16色调色板:');
  for i := 0 to 15 do
  begin
    term_attr_foreground_set(i);
    term_write(Format('%2d ', [i]));
  end;
  term_attr_reset; term_writeln('');
end;

procedure Show256;
var i, startIdx, endIdx, colPerRow, count: Integer;
begin
  if showGray then
  begin
    term_writeln('256色调色板（灰阶 232..255）:');
    startIdx := 232; endIdx := 255; colPerRow := 24;
  end
  else if showCube then
  begin
    term_writeln('256色调色板（立方 16..231）:');
    startIdx := 16; endIdx := 231; colPerRow := 36; // 常见每行 36
  end
  else
  begin
    term_writeln('256色调色板（全量 0..255）:');
    startIdx := 0; endIdx := 255; colPerRow := 32;
  end;

  count := 0;
  for i := startIdx to endIdx do
  begin
    term_attr_foreground_set(term_color_256_t(i));
    term_write(Format('%3d ', [i]));
    Inc(count);
    if (count mod colPerRow) = 0 then begin term_attr_reset; term_writeln(''); end;
  end;
  term_attr_reset; term_writeln('');
end;

procedure ShowTrueColor;
var i: Integer;
begin
  term_writeln('24位真彩渐变示例:');
  for i := 0 to 63 do
  begin
    term_attr_foreground_set(term_color_24bit_rgb(255 - i*4, i*4, 128));
    term_write('█');
  end;
  term_attr_reset; term_writeln('');
end;

begin
  if not term_init then
  begin
    WriteLn('term_init 失败'); Halt(1);
  end;

  term_writeln('调色板与真彩演示');
  term_writeln('================');
  term_writeln('快捷键: [G] 只看灰阶(256色), [C] 立方(16..231), [A] 全部(0..255), [Q] 退出');
  Show16;
  if term_support_color_256 then
  begin
    Show256;
  end
  else
    term_writeln('终端不支持 256 色，跳过 256 色演示');
  ShowTrueColor;

  while True do
  begin
    if not term_event_poll(E, 30000) then break;
    if E.kind = tek_key then
    begin
      case E.key.key of
        KEY_Q: break;
        KEY_G: begin showGray := True;  showCube := False; end;
        KEY_C: begin showCube := True;  showGray := False; end;
        KEY_A: begin showGray := False; showCube := False; end;
      end;
      term_clear;
      term_writeln('调色板与真彩演示');
      term_writeln('================');
      term_writeln('快捷键: [G] 只看灰阶(256色), [C] 立方(16..231), [A] 全部(0..255), [Q] 退出');
      Show16;
      if term_support_color_256 then Show256;
      ShowTrueColor;
    end;
  end;

  term_writeln('完成，按回车退出');
  ReadLn;
end.

