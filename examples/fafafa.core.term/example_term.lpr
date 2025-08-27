{$CODEPAGE UTF8}
program example_term;

{**
 * fafafa.core.term 模块示例程序
 *
 * 这个示例程序演示了 fafafa.core.term 模块的主要功能：
 * - 终端信息查询
 * - 颜色和文本属性控制
 * - 光标控制
 * - 键盘输入处理
 * - 屏幕控制
 *
 * 运行此程序可以看到各种终端控制效果
 *}

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.base, fafafa.core.term;

procedure ShowTerminalInfo;
var
  LTerminal: ITerminal;
  LInfo: ITerminalInfo;
  LSize: TTerminalSize;
  LCapabilities: TTerminalCapabilities;
begin
  WriteLn('=== 终端信息查询示例 ===');
  WriteLn;
  
  LTerminal := CreateTerminal;
  LInfo := LTerminal.Info;
  
  // 显示终端基本信息
  WriteLn('终端类型: ', LInfo.TerminalType);
  WriteLn('是否为TTY: ', BoolToStr(LInfo.IsATTY, True));
  
  // 显示终端尺寸
  LSize := LInfo.Size;
  WriteLn('终端尺寸: ', LSize.Width, ' x ', LSize.Height);
  
  // 显示颜色支持
  WriteLn('支持颜色: ', BoolToStr(LInfo.SupportsColor, True));
  WriteLn('支持真彩色: ', BoolToStr(LInfo.SupportsTrueColor, True));
  WriteLn('颜色深度: ', LInfo.GetColorDepth, ' 位');
  
  // 显示环境信息
  WriteLn('在终端复用器中: ', BoolToStr(LInfo.IsInsideTerminalMultiplexer, True));
  
  WriteLn;
end;

procedure ShowColorDemo;
var
  LTerminal: ITerminal;
  LOutput: ITerminalOutput;
  LColor: TTerminalColor;
  LRGBColor: TRGBColor;
begin
  WriteLn('=== 颜色控制示例 ===');
  WriteLn;
  
  LTerminal := CreateTerminal;
  LOutput := LTerminal.Output;
  
  // 标准颜色演示
  WriteLn('标准颜色演示:');
  for LColor := tcBlack to tcBrightWhite do
  begin
    LOutput.SetForegroundColor(LColor);
    LOutput.Write('■ ');
  end;
  LOutput.ResetColors;
  WriteLn;
  
  // RGB颜色演示
  WriteLn('RGB颜色演示:');
  LRGBColor := MakeRGBColor(255, 100, 100);
  LOutput.SetForegroundColorRGB(LRGBColor);
  LOutput.Write('红色渐变 ');
  
  LRGBColor := MakeRGBColor(100, 255, 100);
  LOutput.SetForegroundColorRGB(LRGBColor);
  LOutput.Write('绿色渐变 ');
  
  LRGBColor := MakeRGBColor(100, 100, 255);
  LOutput.SetForegroundColorRGB(LRGBColor);
  LOutput.Write('蓝色渐变');
  
  LOutput.ResetColors;
  WriteLn;
  WriteLn;
end;

procedure ShowAttributeDemo;
var
  LTerminal: ITerminal;
  LOutput: ITerminalOutput;
begin
  WriteLn('=== 文本属性示例 ===');
  WriteLn;
  
  LTerminal := CreateTerminal;
  LOutput := LTerminal.Output;
  
  // 粗体
  LOutput.SetAttribute(taBold);
  LOutput.Write('粗体文本 ');
  LOutput.ResetAttributes;
  
  // 斜体
  LOutput.SetAttribute(taItalic);
  LOutput.Write('斜体文本 ');
  LOutput.ResetAttributes;
  
  // 下划线
  LOutput.SetAttribute(taUnderline);
  LOutput.Write('下划线文本 ');
  LOutput.ResetAttributes;
  
  // 反色
  LOutput.SetAttribute(taReverse);
  LOutput.Write('反色文本');
  LOutput.ResetAttributes;
  
  WriteLn;
  WriteLn;
end;

procedure ShowCursorDemo;
var
  LTerminal: ITerminal;
  LOutput: ITerminalOutput;
  I: Integer;
begin
  WriteLn('=== 光标控制示例 ===');
  WriteLn;
  
  LTerminal := CreateTerminal;
  LOutput := LTerminal.Output;
  
  // 保存当前光标位置
  LOutput.SaveCursorPosition;
  
  // 移动光标并绘制
  for I := 0 to 4 do
  begin
    LOutput.MoveCursor(I * 2, I);
    LOutput.Write('*');
  end;
  
  // 恢复光标位置
  LOutput.RestoreCursorPosition;
  
  WriteLn;
  WriteLn('绘制了一个对角线');
  WriteLn;
end;

procedure ShowKeyInputDemo;
var
  LTerminal: ITerminal;
  LInput: ITerminalInput;
  LOutput: ITerminalOutput;
  LKeyEvent: TKeyEvent;
  LDone: Boolean;
begin
  WriteLn('=== 键盘输入示例 ===');
  WriteLn('按任意键查看按键信息，按 ESC 退出');
  WriteLn;
  
  LTerminal := CreateTerminal;
  LInput := LTerminal.Input;
  LOutput := LTerminal.Output;
  
  // 进入原始模式
  LTerminal.EnterRawMode;
  
  try
    LDone := False;
    while not LDone do
    begin
      try
        LKeyEvent := LInput.ReadKey;
        
        LOutput.Write('按键: ');
        LOutput.SetForegroundColor(tcGreen);
        LOutput.Write(KeyEventToString(LKeyEvent));
        LOutput.ResetColors;
        LOutput.WriteLn;
        
        // ESC 键退出
        if LKeyEvent.KeyType = ktEscape then
          LDone := True;
          
      except
        on E: Exception do
        begin
          LOutput.SetForegroundColor(tcRed);
          LOutput.WriteLn('错误: ' + E.Message);
          LOutput.ResetColors;
          Break;
        end;
      end;
    end;
  finally
    // 离开原始模式
    LTerminal.LeaveRawMode;
  end;
  
  WriteLn;
end;

procedure ShowScreenDemo;
var
  LTerminal: ITerminal;
  LOutput: ITerminalOutput;
begin
  WriteLn('=== 屏幕控制示例 ===');
  WriteLn;
  
  LTerminal := CreateTerminal;
  LOutput := LTerminal.Output;
  
  // 清除屏幕
  LOutput.ClearScreen(tctAll);
  LOutput.MoveCursor(0, 0);
  
  // 绘制边框
  LOutput.SetForegroundColor(tcBlue);
  LOutput.WriteLn('┌─────────────────────────────────────┐');
  LOutput.WriteLn('│         fafafa.core.term            │');
  LOutput.WriteLn('│         屏幕控制演示                │');
  LOutput.WriteLn('└─────────────────────────────────────┘');
  LOutput.ResetColors;
  
  WriteLn;
  WriteLn('屏幕已清除并绘制了边框');
  WriteLn('按回车键继续...');
  ReadLn;
end;

procedure ShowBufferingDemo;
var
  LTerminal: ITerminal;
  LOutput: ITerminalOutput;
  I: Integer;
begin
  WriteLn('=== 缓冲控制示例 ===');
  WriteLn;
  
  LTerminal := CreateTerminal;
  LOutput := LTerminal.Output;
  
  WriteLn('启用缓冲模式，快速输出...');
  
  // 启用缓冲
  LOutput.EnableBuffering;
  
  for I := 1 to 1000 do
  begin
    LOutput.SetForegroundColor(TTerminalColor(I mod Ord(High(TTerminalColor))));
    LOutput.Write('*');
  end;
  
  // 刷新缓冲区
  LOutput.Flush;
  LOutput.ResetColors;
  
  WriteLn;
  WriteLn('缓冲输出完成');
  WriteLn;
end;

begin
  try
    WriteLn('fafafa.core.term 模块功能演示');
    WriteLn('==============================');
    WriteLn;
    
    // 显示各种功能演示
    ShowTerminalInfo;
    ShowColorDemo;
    ShowAttributeDemo;
    ShowCursorDemo;
    ShowBufferingDemo;
    ShowScreenDemo;
    ShowKeyInputDemo;
    
    WriteLn('演示完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('发生错误: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
