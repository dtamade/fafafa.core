{$CODEPAGE UTF8}
program basic_example;

{**
 * fafafa.core.term 基础示例
 *
 * 这个简单的示例演示了最基本的终端控制功能：
 * - 创建终端对象
 * - 设置颜色
 * - 移动光标
 * - 清除屏幕
 *}

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.term;

var
  LTerminal: ITerminal;
  LOutput: ITerminalOutput;
  LInfo: ITerminalInfo;
  LSize: TTerminalSize;

begin
  try
    WriteLn('fafafa.core.term 基础示例');
    WriteLn('========================');
    WriteLn;
    
    // 创建终端对象
    LTerminal := CreateTerminal;
    LOutput := LTerminal.Output;
    LInfo := LTerminal.Info;
    
    // 获取终端信息
    LSize := LInfo.Size;
    WriteLn('终端尺寸: ', LSize.Width, ' x ', LSize.Height);
    WriteLn('支持颜色: ', BoolToStr(LInfo.SupportsColor, True));
    WriteLn;
    
    // 设置颜色并输出文本
    LOutput.SetForegroundColor(tcRed);
    LOutput.WriteLn('这是红色文本');
    
    LOutput.SetForegroundColor(tcGreen);
    LOutput.WriteLn('这是绿色文本');
    
    LOutput.SetForegroundColor(tcBlue);
    LOutput.WriteLn('这是蓝色文本');
    
    // 重置颜色
    LOutput.ResetColors;
    WriteLn('颜色已重置');
    WriteLn;
    
    // 演示光标控制
    LOutput.Write('移动光标到 (10, 2): ');
    LOutput.MoveCursor(10, 2);
    LOutput.WriteLn('这里!');
    
    // 演示文本属性
    LOutput.SetAttribute(taBold);
    LOutput.Write('粗体文本 ');
    
    LOutput.SetAttribute(taUnderline);
    LOutput.Write('下划线文本');
    
    LOutput.ResetAttributes;
    WriteLn;
    WriteLn;
    
    WriteLn('基础示例完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
