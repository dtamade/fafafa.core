program basic_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.term;

begin
  WriteLn('=== fafafa.core.term 基础测试 ===');
  WriteLn;

  // 显示版本信息
  WriteLn('版本：', term_version);
  WriteLn;

  // 初始化终端
  WriteLn('正在初始化终端...');

  if term_init then
    WriteLn('终端初始化成功')
  else
    WriteLn('终端初始化失败');

  WriteLn;
  WriteLn('终端名称：', term_name);

  Write('支持的功能：');
  if term_support_ansi then Write(' ANSI');
  if term_support_clear then Write(' 清屏');
  if term_support_beep then Write(' 蜂鸣');
  WriteLn;

  WriteLn;
  WriteLn('基础功能测试完成！');
  WriteLn('按回车键退出...');
  ReadLn;
end.

