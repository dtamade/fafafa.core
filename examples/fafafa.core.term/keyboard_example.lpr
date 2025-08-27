{$CODEPAGE UTF8}
program keyboard_example;

{**
 * fafafa.core.term 键盘输入示例
 *
 * 这个示例专门演示键盘输入处理功能：
 * - 原始模式键盘输入
 * - 特殊键检测
 * - 修饰键处理
 * - 非阻塞输入
 *}

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.term;

procedure ShowKeyboardDemo;
var
  LTerminal: ITerminal;
  LInput: ITerminalInput;
  LOutput: ITerminalOutput;
  LKeyEvent: TKeyEvent;
  LDone: Boolean;
begin
  WriteLn('键盘输入演示');
  WriteLn('============');
  WriteLn('按任意键查看按键信息');
  WriteLn('特殊操作:');
  WriteLn('  ESC - 退出程序');
  WriteLn('  F1  - 显示帮助');
  WriteLn('  Ctrl+C - 显示组合键示例');
  WriteLn;
  
  LTerminal := CreateTerminal;
  LInput := LTerminal.Input;
  LOutput := LTerminal.Output;
  
  // 进入原始模式以捕获所有按键
  LTerminal.EnterRawMode;
  
  try
    LDone := False;
    while not LDone do
    begin
      try
        // 检查是否有输入可用（非阻塞）
        if LInput.HasInput then
        begin
          LKeyEvent := LInput.ReadKey;
          
          // 显示按键信息
          LOutput.SetForegroundColor(tcCyan);
          LOutput.Write('按键类型: ');
          LOutput.ResetColors;
          
          case LKeyEvent.KeyType of
            ktChar:
            begin
              LOutput.SetForegroundColor(tcGreen);
              LOutput.Write('字符键');
              LOutput.ResetColors;
              LOutput.Write(' - 字符: ');
              LOutput.SetForegroundColor(tcYellow);
              LOutput.Write('"' + LKeyEvent.KeyChar + '"');
              LOutput.ResetColors;
            end;
            ktEnter:
            begin
              LOutput.SetForegroundColor(tcGreen);
              LOutput.Write('回车键');
              LOutput.ResetColors;
            end;
            ktBackspace:
            begin
              LOutput.SetForegroundColor(tcGreen);
              LOutput.Write('退格键');
              LOutput.ResetColors;
            end;
            ktTab:
            begin
              LOutput.SetForegroundColor(tcGreen);
              LOutput.Write('Tab键');
              LOutput.ResetColors;
            end;
            ktEscape:
            begin
              LOutput.SetForegroundColor(tcRed);
              LOutput.Write('ESC键 - 退出程序');
              LOutput.ResetColors;
              LDone := True;
            end;
            ktArrowUp, ktArrowDown, ktArrowLeft, ktArrowRight:
            begin
              LOutput.SetForegroundColor(tcMagenta);
              LOutput.Write('方向键 - ');
              case LKeyEvent.KeyType of
                ktArrowUp: LOutput.Write('上');
                ktArrowDown: LOutput.Write('下');
                ktArrowLeft: LOutput.Write('左');
                ktArrowRight: LOutput.Write('右');
              end;
              LOutput.ResetColors;
            end;
            ktF1:
            begin
              LOutput.SetForegroundColor(tcBlue);
              LOutput.Write('F1键 - 显示帮助');
              LOutput.ResetColors;
              LOutput.WriteLn;
              LOutput.WriteLn('帮助信息:');
              LOutput.WriteLn('  这是一个键盘输入演示程序');
              LOutput.WriteLn('  支持检测各种按键和组合键');
              LOutput.WriteLn('  按ESC退出程序');
              LOutput.Write('继续按键测试: ');
              continue;
            end;
            ktF2..ktF12:
            begin
              LOutput.SetForegroundColor(tcBlue);
              LOutput.Write('功能键 - F' + IntToStr(Ord(LKeyEvent.KeyType) - Ord(ktF1) + 1));
              LOutput.ResetColors;
            end;
          else
            LOutput.SetForegroundColor(tcWhite);
            LOutput.Write('其他按键');
            LOutput.ResetColors;
          end;
          
          // 显示修饰键
          if LKeyEvent.Modifiers <> [] then
          begin
            LOutput.Write(' + 修饰键: ');
            LOutput.SetForegroundColor(tcRed);
            if kmCtrl in LKeyEvent.Modifiers then
              LOutput.Write('Ctrl ');
            if kmAlt in LKeyEvent.Modifiers then
              LOutput.Write('Alt ');
            if kmShift in LKeyEvent.Modifiers then
              LOutput.Write('Shift ');
            { Meta 修饰键当前未纳入枚举 }
            LOutput.ResetColors;
            
            // 特殊组合键处理
            if (LKeyEvent.KeyType = ktChar) and (LKeyEvent.KeyChar = 'C') and (kmCtrl in LKeyEvent.Modifiers) then
            begin
              LOutput.WriteLn;
              LOutput.SetForegroundColor(tcYellow);
              LOutput.WriteLn('检测到 Ctrl+C 组合键！');
              LOutput.WriteLn('这通常用于中断程序，但在原始模式下我们可以捕获它。');
              LOutput.ResetColors;
              LOutput.Write('继续按键测试: ');
              continue;
            end;
          end;
          
          LOutput.WriteLn;
          LOutput.Write('继续按键测试: ');
        end
        else
        begin
          // 没有输入时可以做其他事情
          Sleep(10);
        end;
        
      except
        on E: Exception do
        begin
          LOutput.SetForegroundColor(tcRed);
          LOutput.WriteLn('读取按键时发生错误: ' + E.Message);
          LOutput.ResetColors;
          Break;
        end;
      end;
    end;
  finally
    // 确保离开原始模式
    LTerminal.LeaveRawMode;
  end;
end;

begin
  try
    ShowKeyboardDemo;
    WriteLn;
    WriteLn('键盘输入演示结束！');
    
  except
    on E: Exception do
    begin
      WriteLn('程序错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
