program simple_demo;

{**
 * fafafa.core.term 简化兼容层演示程序
 * 展示如何使用简化版的 C 风格 API
 *}

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.term;

var
  LWidth, LHeight: term_size_t;
  LX, LY: term_size_t;
  LRedColor, LGreenColor, LBlueColor: term_color_24bit_t;
  i: Integer;

begin
  WriteLn('=== fafafa.core.term 简化兼容层演示 ===');
  WriteLn;
  WriteLn('正在初始化终端...');
  if not term_init then Halt(1);
  WriteLn('版本：', term_version);
  WriteLn('终端名称：', term_name);
  if term_size(LWidth, LHeight) then
  begin
    WriteLn('终端大小：', LWidth, ' x ', LHeight);
    WriteLn('宽度：', term_size_width);
    WriteLn('高度：', term_size_height);
  end;

  if term_title_set('fafafa.core.term 简化兼容层演示') then ;

  if term_cursor_get(LX, LY) then
    WriteLn('当前光标位置：(', LX, ', ', LY, ')');

  WriteLn('移动光标到 (10, 5)...');
  if term_cursor_set(10, 5) then
  begin
    term_write('这里是 (10, 5) 位置');
    WriteLn;
  end;

  term_cursor_home;
  term_write('原点位置');
  WriteLn; WriteLn;

  WriteLn('=== 颜色演示 ===');
  LRedColor := term_color_24bit_rgb(255, 0, 0);
  LGreenColor := term_color_24bit_rgb(0, 255, 0);
  LBlueColor := term_color_24bit_hex('#0000FF');

  term_attr_foreground_set(LRedColor); term_write('这是红色文本'); term_attr_reset; WriteLn;
  term_attr_foreground_set(LGreenColor); term_write('这是绿色文本'); term_attr_reset; WriteLn;
  term_attr_foreground_set(LBlueColor); term_write('这是蓝色文本'); term_attr_reset; WriteLn;

  term_attr_background_set(term_color_24bit_gray(128));
  term_attr_foreground_set(term_color_24bit_rgb(255,255,255));
  term_write('白字灰底'); term_attr_reset; WriteLn; WriteLn;

  WriteLn('=== term_writeln 演示 ===');
  term_writeln('这是使用 term_writeln 输出的文本');
  term_writeln('支持中文：你好世界！');
  term_writeln('支持特殊字符：★☆♠♣♥♦');
  WriteLn;

  WriteLn('=== 彩色文本组合 ===');
  term_attr_foreground_set(term_color_24bit_rgb(255,100,100)); term_write('浅红色 ');
  term_attr_foreground_set(term_color_24bit_rgb(100,255,100)); term_write('浅绿色 ');
  term_attr_foreground_set(term_color_24bit_rgb(100,100,255)); term_write('浅蓝色');
  term_attr_reset; WriteLn; WriteLn;

  Write('渐变：');
  for i := 0 to 15 do
  begin
    term_attr_foreground_set(term_color_24bit_rgb(255 - i*16, i*16, 128));
    term_write('█');
  end;
  term_attr_reset; WriteLn; WriteLn;

  WriteLn('按回车键清屏...'); ReadLn;
  if term_clear then begin term_writeln('屏幕已清除！'); term_writeln('这是清屏后的内容'); end;

  WriteLn; WriteLn('按回车键测试蜂鸣...'); ReadLn;
  if term_beep then term_writeln('蜂鸣成功（如果支持的话）') else term_writeln('蜂鸣失败或不支持');

  WriteLn; WriteLn('按回车键隐藏光标...'); ReadLn;
  if term_cursor_visible_set(False) then
  begin
    term_writeln('光标已隐藏'); WriteLn('按回车键显示光标...'); ReadLn;
    if term_cursor_visible_set(True) then term_writeln('光标已显示') else term_writeln('显示光标失败');
  end else term_writeln('隐藏光标失败');

  WriteLn; WriteLn('=== 演示结束 ===');
  WriteLn('这个简化版演示展示了基本功能：');
  WriteLn('- 终端初始化和信息获取');
  WriteLn('- 光标位置控制');
  WriteLn('- 24位真彩色支持');
  WriteLn('- 文本输出和格式化');
  WriteLn('- 基本终端操作（清屏、蜂鸣等）');
  WriteLn; WriteLn('按回车键退出...'); ReadLn;
end.

