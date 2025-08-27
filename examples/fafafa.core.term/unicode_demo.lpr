{$CODEPAGE UTF8}
program unicode_demo;

{**
 * Unicode支持演示
 *
 * 这个示例演示了如何使用 fafafa.core.term 的Unicode功能：
 * - Unicode字符分析
 * - 文本宽度计算
 * - Emoji支持
 * - 双宽字符处理
 * - 文本截断和换行
 * - 字符编码转换
 *}

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.base, fafafa.core.term;

type
  {**
   * Unicode演示器
   *}
  TUnicodeDemo = class
  private
    FTerminal: ITerminal;
    FOutput: ITerminalOutput;
    FInput: ITerminalInput;
    // FUnicode: ITerminalUnicode;  // removed: not available in current API
    FRunning: Boolean;

    procedure ShowMenu;
    procedure DemoCharacterAnalysis;
    procedure DemoTextWidth;
    procedure DemoEmojiSupport;
    procedure DemoTextTruncation;
    procedure DemoTextWrapping;
    procedure DemoCharacterEncoding;
    procedure ShowUnicodeInfo;
    procedure WaitForKey(const aPrompt: string = '按任意键继续...');
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure Run;
  end;

constructor TUnicodeDemo.Create;
begin
  inherited Create;
  FTerminal := CreateTerminal;
  FOutput := FTerminal.Output;
  FInput := FTerminal.Input;
  // Unicode helper not available; using base term API only
  FRunning := False;
end;

destructor TUnicodeDemo.Destroy;
begin
  FTerminal := nil;
  inherited Destroy;
end;

procedure TUnicodeDemo.ShowMenu;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.MoveCursor(0, 0);
  
  FOutput.SetForegroundColor(tcYellow);
  FOutput.WriteLn('fafafa.core.term Unicode支持演示');
  FOutput.WriteLn('===============================');
  FOutput.ResetColors;
  FOutput.WriteLn;
  
  FOutput.WriteLn('请选择演示项目:');
  FOutput.WriteLn;
  FOutput.WriteLn('1. 字符分析演示');
  FOutput.WriteLn('2. 文本宽度演示');
  FOutput.WriteLn('3. Emoji支持演示');
  FOutput.WriteLn('4. 文本截断演示');
  FOutput.WriteLn('5. 文本换行演示');
  FOutput.WriteLn('6. 字符编码演示');
  FOutput.WriteLn('7. 显示Unicode信息');
  FOutput.WriteLn('0. 退出');
  FOutput.WriteLn;
  FOutput.Write('请输入选择 (0-7): ');
end;

procedure TUnicodeDemo.DemoCharacterAnalysis;
const
  LTestChars: array[0..4] of UCS4Char = (65, 20013, 128512, 8364, 9733);
  LCharNames: array[0..4] of string = ('A', '中', '😀', '€', '★');
var
  I: Integer;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('字符展示（简化）');
  FOutput.WriteLn('==============');
  FOutput.WriteLn;
  for I := 0 to High(LTestChars) do
  begin
    FOutput.WriteLn(Format('字符: %s  码点: U+%4.4X', [LCharNames[I], LTestChars[I]]));
  end;
  WaitForKey;
end;

procedure TUnicodeDemo.DemoTextWidth;
var
  LTestTexts: array[0..5] of string = (
    'Hello World',
    '你好世界',
    'Hello 世界',
    '😀😃😄😁',
    'A中文B',
    'Tab	Test'
  );
var
  I: Integer;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('文本宽度演示');
  FOutput.WriteLn('============');
  FOutput.WriteLn;
  
  FOutput.WriteLn('测试各种文本的显示宽度:');
  FOutput.WriteLn;
  
  for I := 0 to High(LTestTexts) do
  begin
    FOutput.WriteLn(Format('文本: "%s"', [LTestTexts[I]]));
    FOutput.WriteLn;
  end;
  
  WaitForKey;
end;

procedure TUnicodeDemo.DemoEmojiSupport;
const
  LEmojiTexts: array[0..19] of string = (
    '😀', '😃', '😄', '😁', '😆',
    '🌟', '🎉', '🎊', '🎈', '🎁',
    '❤️', '💙', '💚', '💛', '💜',
    '👍', '👎', '👌', '✌️', '🤞'
  );
var
  I: Integer;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('Emoji展示');
  FOutput.WriteLn('=========');
  FOutput.WriteLn;

  for I := 0 to High(LEmojiTexts) do
  begin
    FOutput.Write(LEmojiTexts[I] + ' ');
    
    if (I + 1) mod 5 = 0 then
      FOutput.WriteLn;
  end;
  
  FOutput.WriteLn;
  FOutput.WriteLn;
  
  FOutput.WriteLn;
  WaitForKey;
end;

procedure TUnicodeDemo.DemoTextTruncation;
const
  LMaxWidths: array[0..3] of Integer = (10, 15, 20, 25);
var
  LTestText: string;
  I: Integer;
  LTruncated: string;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('文本截断演示');
  FOutput.WriteLn('============');
  FOutput.WriteLn;
  
  LTestText := 'Hello 世界! This is a test 测试 😀😃😄';
  
  FOutput.WriteLn('原始文本: ' + LTestText);
  FOutput.WriteLn('（宽度测量与截断功能尚未实装，以下为占位展示）');
  FOutput.WriteLn;
  FOutput.WriteLn('不同宽度的截断结果示例:');
  for I := 0 to High(LMaxWidths) do
    FOutput.WriteLn(Format('宽度 %d: "%s"', [LMaxWidths[I], LTestText]));
  
  WaitForKey;
end;

procedure TUnicodeDemo.DemoTextWrapping;
var
  LTestText: string;
  LMaxWidth: Integer;
  LWrappedLines: array of string;
  I: Integer;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('文本换行演示');
  FOutput.WriteLn('============');
  FOutput.WriteLn;
  
  LTestText := 'This is a long text that needs to be wrapped. 这是一段需要换行的长文本。It contains both English and Chinese characters.';
  LMaxWidth := 30;
  
  FOutput.WriteLn('原始文本:');
  FOutput.WriteLn(LTestText);
  FOutput.WriteLn;
  FOutput.WriteLn(Format('最大宽度: %d', [LMaxWidth]));
  FOutput.WriteLn;
  
  FOutput.WriteLn('（自动换行尚未实装，以下为占位展示）');
  FOutput.WriteLn('换行结果:');
  for I := 1 to 3 do
    FOutput.WriteLn(Format('第%d行: "%s"', [I, LTestText]));

  
  WaitForKey;
end;

procedure TUnicodeDemo.DemoCharacterEncoding;
var
  LTestText: string;
  // Unicode 编码详尽接口未提供，这里暂不展示码点数组
  LConvertedBack: string;
  LIsValid: Boolean;
  I: Integer;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('字符编码演示');
  FOutput.WriteLn('============');
  FOutput.WriteLn;
  
  LTestText := 'Hello 世界 😀';
  
  FOutput.WriteLn('原始文本: ' + LTestText);
  FOutput.WriteLn('UTF-8字节长度: ' + IntToStr(Length(LTestText)));
  
  // 这里简化为只展示 UTF-8 字节长度
  FOutput.WriteLn('（编码分析与转换尚未实装）');
  
  WaitForKey;
end;

procedure TUnicodeDemo.ShowUnicodeInfo;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('Unicode信息');
  FOutput.WriteLn('===========');
  FOutput.WriteLn;
  
  FOutput.WriteLn('（Unicode 详尽信息接口尚未实装）');
  FOutput.WriteLn;
  FOutput.WriteLn('基础支持：');
  FOutput.WriteLn('  ✓ UTF-8 输出（字符串/宽字符/UCS4）');
  FOutput.WriteLn('  ✓ 颜色与属性');
  FOutput.WriteLn('  ✓ 光标/清屏/尺寸查询');
  
  WaitForKey;
end;

procedure TUnicodeDemo.WaitForKey(const aPrompt: string = '按任意键继续...');
begin
  FOutput.WriteLn;
  FOutput.Write(aPrompt);
  FInput.ReadKey;
end;

procedure TUnicodeDemo.Run;
var
  LChoice: string;
begin
  FRunning := True;
  
  while FRunning do
  begin
    ShowMenu;
    ReadLn(LChoice);
    
    case LChoice of
      '1': DemoCharacterAnalysis;
      '2': DemoTextWidth;
      '3': DemoEmojiSupport;
      '4': DemoTextTruncation;
      '5': DemoTextWrapping;
      '6': DemoCharacterEncoding;
      '7': ShowUnicodeInfo;
      '0': FRunning := False;
    else
      begin
        FOutput.WriteLn('无效选择，请重新输入');
        WaitForKey;
      end;
    end;
  end;
  
  FOutput.WriteLn('感谢使用Unicode支持演示！');
end;

var
  LDemo: TUnicodeDemo;

begin
  try
    LDemo := TUnicodeDemo.Create;
    try
      LDemo.Run;
    finally
      LDemo.Free;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('Unicode演示失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
