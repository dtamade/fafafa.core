program final_demo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.term;

var
  LWidth, LHeight: term_size_t;
  LRedColor, LGreenColor, LBlueColor: term_color_24bit_t;
  i: Integer;

begin
  WriteLn('=== 最终版演示 ===');
  WriteLn;

  if not term_init then
  begin
    WriteLn('错误：无法初始化终端');
    Halt(1);
  end;

  // 显示终端信息
  if term_size(LWidth, LHeight) then
    WriteLn('终端大小：', LWidth, ' x ', LHeight);

  // 基本颜色演示
  LRedColor := term_color_24bit_rgb(255, 0, 0);
  LGreenColor := term_color_24bit_rgb(0, 255, 0);
  LBlueColor := term_color_24bit_rgb(0, 0, 255);

  term_attr_foreground_set(LRedColor);
  term_writeln('红色文本');
  term_attr_reset;

  term_attr_foreground_set(LGreenColor);
  term_writeln('绿色文本');
  term_attr_reset;

  term_attr_foreground_set(LBlueColor);
  term_writeln('蓝色文本');
  term_attr_reset;
  WriteLn;

  // 背景+前景
  term_attr_background_set(term_color_24bit_gray(128));
  term_attr_foreground_set(term_color_24bit_rgb(255, 255, 255));
  term_write(' 白字灰底 ');
  term_attr_reset;
  WriteLn;

  // 渐变
  WriteLn('渐变：');
  for i := 0 to 31 do
  begin
    term_attr_foreground_set(term_color_24bit_rgb(255 - i * 8, i * 8, 128));
    term_write('█');
  end;
  term_attr_reset;
  WriteLn;

  term_writeln('完成，按回车退出');
  ReadLn;
end.

