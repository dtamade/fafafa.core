program capability_demo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.term;

procedure PrintBool(const Name: string; V: Boolean);
begin
  if V then term_writeln(Name + ': yes') else term_writeln(Name + ': no');
end;

begin
  WriteLn('=== 终端能力自检与回退提示 ===');
  WriteLn;

  if not term_init then
  begin
    WriteLn('错误：无法初始化终端');
    Halt(1);
  end;

  term_writeln('基本能力:');
  PrintBool('ANSI', term_support_ansi);
  PrintBool('清屏', term_support_clear);
  PrintBool('蜂鸣', term_support_beep);
  PrintBool('备用屏', term_support_alternate_screen);
  PrintBool('鼠标', term_support_mouse);

  term_writeln('颜色能力:');
  PrintBool('16色', term_support_color_16);
  PrintBool('256色', term_support_color_256);
  PrintBool('24位色', term_support_color_24bit);
  PrintBool('16色调色板', term_support_color_16_palette);
  PrintBool('256色调色板', term_support_color_256_palette);
  PrintBool('调色板栈', term_support_color_palette_stack);

  term_writeln('回退建议（如显示异常，可考虑）：');
  term_writeln('- Windows: 在控制台启用 UTF-8 代码页与 VT 支持');
  term_writeln('- 远程/容器: 使用支持 ANSI/真彩的终端（如 Windows Terminal, iTerm2, wezterm 等）');
  term_writeln('- SSH: 传递正确的 TERM 环境变量，避免 dumb/ansi 过度降级');

  term_writeln('按回车退出');
  ReadLn;
end.

