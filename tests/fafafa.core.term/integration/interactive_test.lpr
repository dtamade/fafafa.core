{$CODEPAGE UTF8}
program interactive_test;

{**
 * 交互式集成测试
 *
 * 这个程序需要用户交互来测试各种功能：
 * - 键盘输入测试
 * - 鼠标事件测试
 * - 剪贴板操作测试
 * - 窗口大小变化测试
 * - 实时响应性测试
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
   * 交互式测试器
   *}
  TInteractiveTester = class
  private
    FTerminal: ITerminal;
    FOutput: ITerminalOutput;
    FInput: ITerminalInput;
    FMouse: ITerminalMouse;
    FClipboard: ITerminalClipboard;
    FResize: ITerminalResize;
    FRunning: Boolean;

    procedure ShowMenu;
    procedure TestKeyboardInput;
    procedure TestMouseInput;
    procedure TestClipboardOperations;
    procedure TestResizeEvents;
    procedure TestRealTimeResponse;
    procedure TestColorAndFormatting;
    procedure TestCursorAndScreen;
    procedure ShowTerminalInfo;
    procedure WaitForKey(const aPrompt: string = '按任意键继续...');
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure Run;
  end;

constructor TInteractiveTester.Create;
begin
  inherited Create;
  FTerminal := CreateTerminal;
  FOutput := FTerminal.Output;
  FInput := FTerminal.Input;
  FMouse := FTerminal.Mouse;
  FClipboard := FTerminal.Clipboard;
  FResize := FTerminal.Resize;
  FRunning := False;
end;

destructor TInteractiveTester.Destroy;
begin
  FTerminal := nil;
  inherited Destroy;
end;

procedure TInteractiveTester.ShowMenu;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.MoveCursor(0, 0);
  
  FOutput.SetForegroundColor(tcYellow);
  FOutput.WriteLn('fafafa.core.term 交互式测试');
  FOutput.WriteLn('===========================');
  FOutput.ResetColors;
  FOutput.WriteLn;
  
  FOutput.WriteLn('请选择测试项目:');
  FOutput.WriteLn;
  FOutput.WriteLn('1. 键盘输入测试');
  FOutput.WriteLn('2. 鼠标输入测试');
  FOutput.WriteLn('3. 剪贴板操作测试');
  FOutput.WriteLn('4. 窗口大小变化测试');
  FOutput.WriteLn('5. 实时响应性测试');
  FOutput.WriteLn('6. 颜色和格式测试');
  FOutput.WriteLn('7. 光标和屏幕测试');
  FOutput.WriteLn('8. 显示终端信息');
  FOutput.WriteLn('0. 退出');
  FOutput.WriteLn;
  FOutput.Write('请输入选择 (0-8): ');
end;

procedure TInteractiveTester.TestKeyboardInput;
var
  LKeyEvent: TKeyEvent;
  LDone: Boolean;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('键盘输入测试');
  FOutput.WriteLn('============');
  FOutput.WriteLn;
  FOutput.WriteLn('请按各种键测试输入处理，按 ESC 退出');
  FOutput.WriteLn;
  
  FTerminal.EnterRawMode;
  try
    LDone := False;
    while not LDone do
    begin
      try
        LKeyEvent := FInput.ReadKey;
        
        FOutput.Write('按键: ');
        FOutput.SetForegroundColor(tcCyan);
        FOutput.Write(KeyEventToString(LKeyEvent));
        FOutput.ResetColors;
        FOutput.WriteLn;
        
        if LKeyEvent.KeyType = ktEscape then
          LDone := True;
          
      except
        on E: Exception do
        begin
          FOutput.SetForegroundColor(tcRed);
          FOutput.WriteLn('错误: ' + E.Message);
          FOutput.ResetColors;
        end;
      end;
    end;
    
  finally
    FTerminal.LeaveRawMode;
  end;
  
  WaitForKey;
end;

procedure TInteractiveTester.TestMouseInput;
var
  LMouseEvent: TMouseEvent;
  LDone: Boolean;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('鼠标输入测试');
  FOutput.WriteLn('============');
  FOutput.WriteLn;
  
  if not FTerminal.Info.SupportsMouseInput then
  begin
    FOutput.SetForegroundColor(tcRed);
    FOutput.WriteLn('当前终端不支持鼠标输入');
    FOutput.ResetColors;
    WaitForKey;
    Exit;
  end;
  
  FOutput.WriteLn('启用鼠标跟踪，请移动鼠标和点击测试，按 ESC 退出');
  FOutput.WriteLn;
  
  FMouse.EnableMouseTracking;
  FTerminal.EnterRawMode;
  
  try
    LDone := False;
    while not LDone do
    begin
      try
        if FMouse.TryReadMouseEvent(LMouseEvent) then
        begin
          FOutput.Write('鼠标: ');
          FOutput.SetForegroundColor(tcGreen);
          FOutput.Write(MouseEventToString(LMouseEvent));
          FOutput.ResetColors;
          FOutput.WriteLn;
        end;
        
        // 检查键盘输入
        if FInput.HasInput then
        begin
          if FInput.ReadKey.KeyType = ktEscape then
            LDone := True;
        end;
        
        Sleep(10);
        
      except
        on E: Exception do
        begin
          FOutput.SetForegroundColor(tcRed);
          FOutput.WriteLn('错误: ' + E.Message);
          FOutput.ResetColors;
        end;
      end;
    end;
    
  finally
    FMouse.DisableMouseTracking;
    FTerminal.LeaveRawMode;
  end;
  
  WaitForKey;
end;

procedure TInteractiveTester.TestClipboardOperations;
var
  LTestText: string;
  LClipboardText: string;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('剪贴板操作测试');
  FOutput.WriteLn('==============');
  FOutput.WriteLn;
  
  if not FTerminal.Info.SupportsClipboard then
  begin
    FOutput.SetForegroundColor(tcRed);
    FOutput.WriteLn('当前终端不支持剪贴板操作');
    FOutput.ResetColors;
    WaitForKey;
    Exit;
  end;
  
  // 测试写入剪贴板
  LTestText := 'fafafa.core.term 剪贴板测试文本 ' + FormatDateTime('hh:nn:ss', Now);
  FOutput.WriteLn('1. 写入测试文本到剪贴板...');
  FOutput.WriteLn('   文本: ' + LTestText);
  
  try
    FClipboard.SetText(LTestText);
    FOutput.SetForegroundColor(tcGreen);
    FOutput.WriteLn('   写入成功');
    FOutput.ResetColors;
  except
    on E: Exception do
    begin
      FOutput.SetForegroundColor(tcRed);
      FOutput.WriteLn('   写入失败: ' + E.Message);
      FOutput.ResetColors;
    end;
  end;
  
  FOutput.WriteLn;
  
  // 测试读取剪贴板
  FOutput.WriteLn('2. 从剪贴板读取文本...');
  
  try
    LClipboardText := FClipboard.GetText;
    FOutput.WriteLn('   读取到: ' + LClipboardText);
    
    if LClipboardText = LTestText then
    begin
      FOutput.SetForegroundColor(tcGreen);
      FOutput.WriteLn('   验证成功：读取的文本与写入的文本一致');
      FOutput.ResetColors;
    end
    else
    begin
      FOutput.SetForegroundColor(tcYellow);
      FOutput.WriteLn('   注意：读取的文本与写入的文本不一致（可能是其他程序修改了剪贴板）');
      FOutput.ResetColors;
    end;
    
  except
    on E: Exception do
    begin
      FOutput.SetForegroundColor(tcRed);
      FOutput.WriteLn('   读取失败: ' + E.Message);
      FOutput.ResetColors;
    end;
  end;
  
  FOutput.WriteLn;
  FOutput.WriteLn('3. 请手动复制一些文本，然后按回车键测试读取...');
  ReadLn;
  
  try
    LClipboardText := FClipboard.GetText;
    FOutput.WriteLn('   手动复制的文本: ' + LClipboardText);
  except
    on E: Exception do
    begin
      FOutput.SetForegroundColor(tcRed);
      FOutput.WriteLn('   读取失败: ' + E.Message);
      FOutput.ResetColors;
    end;
  end;
  
  WaitForKey;
end;

procedure TInteractiveTester.TestResizeEvents;
var
  LCurrentSize: TTerminalSize;
  LStartTime: QWord;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('窗口大小变化测试');
  FOutput.WriteLn('================');
  FOutput.WriteLn;
  
  LCurrentSize := FTerminal.Info.GetSize;
  FOutput.WriteLn(Format('当前终端尺寸: %dx%d', [LCurrentSize.Width, LCurrentSize.Height]));
  FOutput.WriteLn;
  FOutput.WriteLn('请调整终端窗口大小，程序将检测变化...');
  FOutput.WriteLn('按 ESC 退出测试');
  FOutput.WriteLn;
  
  FResize.EnableResizeMonitoring;
  FTerminal.EnterRawMode;
  
  try
    LStartTime := GetTickCount64;
    
    while True do
    begin
      // 检查大小变化
      if FResize.HasResizeEvent then
      begin
        LCurrentSize := FTerminal.Info.GetSize;
        FOutput.WriteLn(Format('[%s] 检测到尺寸变化: %dx%d', [
          FormatDateTime('hh:nn:ss', Now),
          LCurrentSize.Width, 
          LCurrentSize.Height
        ]));
      end;
      
      // 检查键盘输入
      if FInput.HasInput then
      begin
        if FInput.ReadKey.KeyType = ktEscape then
          Break;
      end;
      
      Sleep(100);
      
      // 每5秒显示一次当前状态
      if (GetTickCount64 - LStartTime) > 5000 then
      begin
        LCurrentSize := FTerminal.Info.GetSize;
        FOutput.WriteLn(Format('[状态] 当前尺寸: %dx%d', [LCurrentSize.Width, LCurrentSize.Height]));
        LStartTime := GetTickCount64;
      end;
    end;
    
  finally
    FResize.DisableResizeMonitoring;
    FTerminal.LeaveRawMode;
  end;
  
  WaitForKey;
end;

procedure TInteractiveTester.TestRealTimeResponse;
var
  LStartTime: QWord;
  LKeyEvent: TKeyEvent;
  LCounter: Integer;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('实时响应性测试');
  FOutput.WriteLn('==============');
  FOutput.WriteLn;
  FOutput.WriteLn('这个测试将显示实时计数器，同时响应键盘输入');
  FOutput.WriteLn('按任意键查看响应时间，按 ESC 退出');
  FOutput.WriteLn;
  
  FTerminal.EnterRawMode;
  try
    LStartTime := GetTickCount64;
    LCounter := 0;
    
    while True do
    begin
      // 更新计数器显示
      if (GetTickCount64 - LStartTime) > 100 then
      begin
        FOutput.MoveCursor(0, 5);
        FOutput.Write(Format('计数器: %6d  运行时间: %d 秒', [
          LCounter, 
          (GetTickCount64 - LStartTime) div 1000
        ]));
        Inc(LCounter);
        LStartTime := GetTickCount64;
      end;
      
      // 检查键盘输入
      if FInput.TryReadKey(LKeyEvent) then
      begin
        FOutput.MoveCursor(0, 7);
        FOutput.Write(Format('按键响应: %s (时间: %s)', [
          KeyEventToString(LKeyEvent),
          FormatDateTime('hh:nn:ss.zzz', Now)
        ]));
        
        if LKeyEvent.KeyType = ktEscape then
          Break;
      end;
      
      Sleep(10);
    end;
    
  finally
    FTerminal.LeaveRawMode;
  end;
  
  WaitForKey;
end;

procedure TInteractiveTester.TestColorAndFormatting;
var
  LColor: TTerminalColor;
  LAttr: TTerminalAttribute;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('颜色和格式测试');
  FOutput.WriteLn('==============');
  FOutput.WriteLn;
  
  // 测试基本颜色
  FOutput.WriteLn('基本颜色测试:');
  for LColor := Low(TTerminalColor) to High(TTerminalColor) do
  begin
    FOutput.SetForegroundColor(LColor);
    FOutput.Write(Format('%-10s', [
      case LColor of
        tcBlack: 'Black';
        tcRed: 'Red';
        tcGreen: 'Green';
        tcYellow: 'Yellow';
        tcBlue: 'Blue';
        tcMagenta: 'Magenta';
        tcCyan: 'Cyan';
        tcWhite: 'White';
      end
    ]));
  end;
  FOutput.ResetColors;
  FOutput.WriteLn;
  FOutput.WriteLn;
  
  // 测试文本属性
  FOutput.WriteLn('文本属性测试:');
  for LAttr := Low(TTerminalAttribute) to High(TTerminalAttribute) do
  begin
    FOutput.SetAttribute(LAttr);
    FOutput.Write(Format('%-15s', [
      case LAttr of
        taBold: 'Bold';
        taItalic: 'Italic';
        taUnderline: 'Underline';
        taBlink: 'Blink';
        taReverse: 'Reverse';
        taStrikethrough: 'Strike';
        taDoubleUnderline: 'DblUnder';
      end
    ]));
    FOutput.ResetAttributes;
    FOutput.Write(' ');
  end;
  FOutput.WriteLn;
  FOutput.WriteLn;
  
  // 测试真彩色
  if FTerminal.Info.SupportsTrueColor then
  begin
    FOutput.WriteLn('真彩色渐变测试:');
    var I: Integer;
    for I := 0 to 255 do
    begin
      FOutput.SetForegroundColorRGB(I, 255 - I, 128);
      FOutput.Write('█');
    end;
    FOutput.ResetColors;
    FOutput.WriteLn;
  end;
  
  WaitForKey;
end;

procedure TInteractiveTester.TestCursorAndScreen;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('光标和屏幕测试');
  FOutput.WriteLn('==============');
  FOutput.WriteLn;
  
  // 测试光标移动
  FOutput.WriteLn('1. 光标移动测试');
  var I: Integer;
  for I := 1 to 10 do
  begin
    FOutput.MoveCursor(I * 2, 5 + I);
    FOutput.Write('*');
    Sleep(200);
  end;
  
  FOutput.MoveCursor(0, 17);
  FOutput.WriteLn('2. 光标显示/隐藏测试');
  FOutput.Write('光标将隐藏3秒...');
  FOutput.HideCursor;
  Sleep(3000);
  FOutput.ShowCursor;
  FOutput.WriteLn(' 光标已恢复');
  
  // 测试备用屏幕
  if tcAltScreenSupport in FTerminal.Info.GetCapabilities then
  begin
    FOutput.WriteLn('3. 备用屏幕测试（3秒后切换）');
    Sleep(3000);
    
    FOutput.EnterAlternateScreen;
    FOutput.ClearScreen(tctAll);
    FOutput.SetForegroundColor(tcYellow);
    FOutput.WriteLn('这是备用屏幕');
    FOutput.WriteLn('3秒后返回主屏幕...');
    FOutput.ResetColors;
    Sleep(3000);
    
    FOutput.LeaveAlternateScreen;
    FOutput.WriteLn('已返回主屏幕');
  end;
  
  WaitForKey;
end;

procedure TInteractiveTester.ShowTerminalInfo;
var
  LInfo: ITerminalInfo;
  LSize: TTerminalSize;
  LCapabilities: TTerminalCapabilities;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('终端信息');
  FOutput.WriteLn('========');
  FOutput.WriteLn;
  
  LInfo := FTerminal.Info;
  LSize := LInfo.GetSize;
  LCapabilities := LInfo.GetCapabilities;
  
  FOutput.WriteLn('基本信息:');
  FOutput.WriteLn('  类型: ' + LInfo.GetTerminalType);
  FOutput.WriteLn('  厂商: ' + LInfo.GetTerminalVendor);
  FOutput.WriteLn('  版本: ' + LInfo.GetTerminalVersion);
  FOutput.WriteLn(Format('  尺寸: %dx%d', [LSize.Width, LSize.Height]));
  FOutput.WriteLn('  颜色深度: ' + IntToStr(LInfo.GetColorDepth));
  FOutput.WriteLn('  最大颜色数: ' + IntToStr(LInfo.GetMaxColors));
  FOutput.WriteLn('  Tab宽度: ' + IntToStr(LInfo.GetTabWidth));
  FOutput.WriteLn;
  
  FOutput.WriteLn('支持的功能:');
  FOutput.WriteLn('  颜色支持: ' + BoolToStr(LInfo.SupportsColor, '是', '否'));
  FOutput.WriteLn('  真彩色: ' + BoolToStr(LInfo.SupportsTrueColor, '是', '否'));
  FOutput.WriteLn('  Unicode: ' + BoolToStr(LInfo.SupportsUnicode, '是', '否'));
  FOutput.WriteLn('  鼠标输入: ' + BoolToStr(LInfo.SupportsMouseInput, '是', '否'));
  FOutput.WriteLn('  剪贴板: ' + BoolToStr(LInfo.SupportsClipboard, '是', '否'));
  FOutput.WriteLn('  斜体: ' + BoolToStr(LInfo.SupportsItalic, '是', '否'));
  FOutput.WriteLn('  下划线: ' + BoolToStr(LInfo.SupportsUnderline, '是', '否'));
  FOutput.WriteLn('  超链接: ' + BoolToStr(LInfo.SupportsHyperlink, '是', '否'));
  FOutput.WriteLn('  图像: ' + BoolToStr(LInfo.SupportsImage, '是', '否'));
  FOutput.WriteLn('  同步输出: ' + BoolToStr(LInfo.SupportsSynchronizedOutput, '是', '否'));
  
  WaitForKey;
end;

procedure TInteractiveTester.WaitForKey(const aPrompt: string = '按任意键继续...');
begin
  FOutput.WriteLn;
  FOutput.Write(aPrompt);
  ReadLn;
end;

procedure TInteractiveTester.Run;
var
  LChoice: string;
begin
  FRunning := True;
  
  while FRunning do
  begin
    ShowMenu;
    ReadLn(LChoice);
    
    case LChoice of
      '1': TestKeyboardInput;
      '2': TestMouseInput;
      '3': TestClipboardOperations;
      '4': TestResizeEvents;
      '5': TestRealTimeResponse;
      '6': TestColorAndFormatting;
      '7': TestCursorAndScreen;
      '8': ShowTerminalInfo;
      '0': FRunning := False;
    else
      begin
        FOutput.SetForegroundColor(tcRed);
        FOutput.WriteLn('无效选择，请重新输入');
        FOutput.ResetColors;
        WaitForKey;
      end;
    end;
  end;
  
  FOutput.WriteLn('感谢使用 fafafa.core.term 交互式测试！');
end;

var
  LTester: TInteractiveTester;

begin
  try
    LTester := TInteractiveTester.Create;
    try
      LTester.Run;
    finally
      LTester.Free;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('交互式测试失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
