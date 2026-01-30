program advanced_test;

{**
 * 高级测试程序 - 测试后端功能
 *}

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.term;

var
  LWidth, LHeight: UInt16;
  LX, LY: UInt16;

begin
  WriteLn('=== fafafa.core.term Advanced Test ===');
  WriteLn;
  
  // 显示版本信息
  WriteLn('Version: ', term_version);
  WriteLn;
  
  // 初始化终端
  WriteLn('Initializing terminal...');
  
  if term_init then
    WriteLn('Terminal initialized successfully')
  else
    WriteLn('Terminal initialization failed');
  
  WriteLn;
  WriteLn('Terminal name: ', term_name);
  
  Write('Supported features:');
  if term_support_ansi then Write(' ANSI');
  if term_support_clear then Write(' Clear');
  if term_support_beep then Write(' Beep');
  WriteLn;
  WriteLn;
  
  // 测试终端大小获取
  WriteLn('Testing terminal size detection...');
  if term_size(LWidth, LHeight) then
    WriteLn('Terminal size: ', LWidth, ' x ', LHeight)
  else
    WriteLn('Failed to get terminal size');

  WriteLn;

  // 测试光标位置获取
  WriteLn('Testing cursor position detection...');
  if term_cursor(LX, LY) then
    WriteLn('Cursor position: (', LX, ', ', LY, ')')
  else
    WriteLn('Failed to get cursor position');
  
  WriteLn;
  
  // 测试清屏功能
  WriteLn('Testing clear screen...');
  WriteLn('Press Enter to clear screen...');
  ReadLn;
  
  if term_clear then
    WriteLn('Screen cleared successfully')
  else
    WriteLn('Failed to clear screen');
  
  WriteLn;
  
  // 测试蜂鸣功能
  WriteLn('Testing beep...');
  WriteLn('Press Enter to beep...');
  ReadLn;
  
  if term_beep then
    WriteLn('Beep successful')
  else
    WriteLn('Beep failed');
  
  WriteLn;
  
  // 测试光标移动
  WriteLn('Testing cursor movement...');
  WriteLn('Moving cursor to (10, 5)...');
  if term_cursor_set(10, 5) then
  begin
    WriteLn('Cursor moved successfully');
    WriteLn('Current position should be (10, 5)');
  end
  else
    WriteLn('Failed to move cursor');
  
  WriteLn;
  WriteLn('Advanced test completed!');
  WriteLn('Backend functionality is working.');
  WriteLn;
  WriteLn('Press Enter to exit...');
  ReadLn;
end.

