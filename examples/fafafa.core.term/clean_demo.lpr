program clean_demo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.term;

var
  LWidth, LHeight: term_size_t;
  LColor: term_color_24bit_t;
  i: Integer;

begin
  WriteLn('=== 简洁版 fafafa.core.term 演示 ===');
  WriteLn;

  // 基本信息
  WriteLn('版本：', term_version);
  Write('平台：');
  WriteLn('(能力已自动检测与降级)');
  WriteLn;

  // 终端大小
  if term_size(LWidth, LHeight) then
    WriteLn('终端大小：', LWidth, ' x ', LHeight);
  WriteLn;

  // 光标控制演示
  WriteLn('=== 光标控制演示 ===');
  term_write('移动光标到 (15, 8)：');
  term_cursor_set(15, 8);
  term_write('这里！');
  term_cursor_home;
  WriteLn;
  WriteLn;

  // 颜色演示
  WriteLn('=== 颜色演示 ===');

  LColor := term_color_24bit_rgb(255, 0, 0);
  term_attr_foreground_set(LColor);
  term_write('红色 ');

  LColor := term_color_24bit_rgb(0, 255, 0);
  term_attr_foreground_set(LColor);
  term_write('绿色 ');

  LColor := term_color_24bit_hex('#0000FF');
  term_attr_foreground_set(LColor);
  term_write('蓝色');

  term_attr_reset;
  WriteLn;
  WriteLn;

  // 文本样式演示（用颜色代替样式，适配降级环境）
  WriteLn('=== 文本样式演示 ===');
  term_attr_foreground_set(term_color_24bit_rgb(255, 255, 0));
  term_write('模拟粗体 ');
  term_attr_reset;

  term_attr_foreground_set(term_color_24bit_rgb(255, 0, 255));
  term_write('模拟斜体 ');
  term_attr_reset;

  term_attr_foreground_set(term_color_24bit_rgb(0, 255, 255));
  term_write('模拟下划线');
  term_attr_reset;
  WriteLn;
  WriteLn;

  // 渐变演示
  WriteLn('=== 渐变演示 ===');
  Write('渐变：');
  for i := 0 to 20 do
  begin
    LColor := term_color_24bit_rgb(255 - i * 12, i * 12, 128);
    term_attr_foreground_set(LColor);
    term_write('█');
  end;
  term_attr_reset;
  WriteLn;
  WriteLn;

  // Unicode 测试
  WriteLn('=== Unicode 测试 ===');
  term_writeln('中文：你好世界！');
  term_writeln('日文：こんにちは！');
  term_writeln('符号：★☆♠♣♥♦');
  term_writeln('Emoji：😀🌍🚀');
  WriteLn;

  // 清屏演示
  WriteLn('按回车键清屏...');
  ReadLn;

  term_clear;
  term_writeln('屏幕已清除！');
  WriteLn;

  WriteLn('=== 演示结束 ===');
  WriteLn('按回车键退出...');
  ReadLn;
end.

