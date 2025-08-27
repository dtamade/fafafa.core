{$CODEPAGE UTF8}
program terminal_compatibility_test;

{**
 * 终端兼容性集成测试
 *
 * 这个程序在真实终端环境中测试 fafafa.core.term 的兼容性：
 * - 检测终端类型和版本
 * - 测试基本功能在不同终端中的表现
 * - 验证ANSI序列支持
 * - 测试颜色和格式支持
 * - 验证键盘输入处理
 * - 测试鼠标和剪贴板功能
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
   * 测试结果枚举
   *}
  TTestResult = (
    trPassed,     // 通过
    trFailed,     // 失败
    trSkipped,    // 跳过
    trPartial     // 部分支持
  );

  {**
   * 测试用例记录
   *}
  TTestCase = record
    Name: string;
    Description: string;
    Result: TTestResult;
    Details: string;
    Duration: Integer; // 毫秒
  end;

  {**
   * 终端兼容性测试器
   *}
  TTerminalCompatibilityTester = class
  private
    FTerminal: ITerminal;
    FOutput: ITerminalOutput;
    FInput: ITerminalInput;
    FInfo: ITerminalInfo;
    FTestResults: array of TTestCase;
    FCurrentTest: Integer;
    FTotalTests: Integer;
    FPassedTests: Integer;
    FFailedTests: Integer;
    FSkippedTests: Integer;

    procedure AddTestResult(const aName, aDescription: string; aResult: TTestResult; 
      const aDetails: string = ''; aDuration: Integer = 0);
    function RunSingleTest(const aTestName: string; aTestProc: TProcedure): TTestResult;
    procedure PrintTestHeader(const aTestName: string);
    procedure PrintTestResult(aResult: TTestResult; const aDetails: string = '');
    
    // 具体测试方法
    procedure TestTerminalDetection;
    procedure TestBasicOutput;
    procedure TestColorSupport;
    procedure TestCursorControl;
    procedure TestScreenControl;
    procedure TestKeyboardInput;
    procedure TestMouseSupport;
    procedure TestClipboardSupport;
    procedure TestAdvancedFeatures;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure RunAllTests;
    procedure PrintSummary;
    procedure SaveReport(const aFileName: string);
  end;

constructor TTerminalCompatibilityTester.Create;
begin
  inherited Create;
  FTerminal := CreateTerminal;
  FOutput := FTerminal.Output;
  FInput := FTerminal.Input;
  FInfo := FTerminal.Info;
  
  SetLength(FTestResults, 0);
  FCurrentTest := 0;
  FTotalTests := 0;
  FPassedTests := 0;
  FFailedTests := 0;
  FSkippedTests := 0;
end;

destructor TTerminalCompatibilityTester.Destroy;
begin
  FTerminal := nil;
  inherited Destroy;
end;

procedure TTerminalCompatibilityTester.AddTestResult(const aName, aDescription: string; 
  aResult: TTestResult; const aDetails: string = ''; aDuration: Integer = 0);
begin
  SetLength(FTestResults, Length(FTestResults) + 1);
  with FTestResults[High(FTestResults)] do
  begin
    Name := aName;
    Description := aDescription;
    Result := aResult;
    Details := aDetails;
    Duration := aDuration;
  end;
  
  case aResult of
    trPassed: Inc(FPassedTests);
    trFailed: Inc(FFailedTests);
    trSkipped: Inc(FSkippedTests);
  end;
  
  Inc(FTotalTests);
end;

function TTerminalCompatibilityTester.RunSingleTest(const aTestName: string; aTestProc: TProcedure): TTestResult;
var
  LStartTime: QWord;
  LDuration: Integer;
begin
  Result := trFailed;
  PrintTestHeader(aTestName);
  
  LStartTime := GetTickCount64;
  try
    aTestProc();
    Result := trPassed;
  except
    on E: Exception do
    begin
      PrintTestResult(trFailed, E.Message);
      Exit;
    end;
  end;
  
  LDuration := GetTickCount64 - LStartTime;
  PrintTestResult(Result);
end;

procedure TTerminalCompatibilityTester.PrintTestHeader(const aTestName: string);
begin
  Write(Format('%-40s ... ', [aTestName]));
end;

procedure TTerminalCompatibilityTester.PrintTestResult(aResult: TTestResult; const aDetails: string = '');
begin
  case aResult of
    trPassed:  WriteLn('PASSED');
    trFailed:  WriteLn('FAILED' + IfThen(aDetails <> '', ' (' + aDetails + ')', ''));
    trSkipped: WriteLn('SKIPPED');
    trPartial: WriteLn('PARTIAL');
  end;
end;

procedure TTerminalCompatibilityTester.TestTerminalDetection;
var
  LTermType: string;
  LSize: TTerminalSize;
  LCapabilities: TTerminalCapabilities;
begin
  // 测试终端类型检测
  LTermType := FInfo.GetTerminalType;
  if LTermType = '' then
    raise Exception.Create('无法检测终端类型');
    
  AddTestResult('终端类型检测', '检测当前终端类型', trPassed, 
    Format('类型: %s', [LTermType]));
  
  // 测试尺寸检测
  LSize := FInfo.GetSize;
  if (LSize.Width = 0) or (LSize.Height = 0) then
    raise Exception.Create('无法检测终端尺寸');
    
  AddTestResult('终端尺寸检测', '检测终端窗口尺寸', trPassed, 
    Format('%dx%d', [LSize.Width, LSize.Height]));
  
  // 测试能力检测
  LCapabilities := FInfo.GetCapabilities;
  AddTestResult('终端能力检测', '检测终端支持的功能', trPassed, 
    Format('支持%d项功能', [Integer(LCapabilities)]));
end;

procedure TTerminalCompatibilityTester.TestBasicOutput;
begin
  // 测试基本文本输出
  FOutput.Write('测试文本输出...');
  FOutput.WriteLn(' 完成');
  
  AddTestResult('基本文本输出', '测试基本的文本输出功能', trPassed);
  
  // 测试缓冲输出
  FOutput.EnableBuffering;
  FOutput.Write('缓冲输出测试');
  FOutput.Flush;
  FOutput.DisableBuffering;
  FOutput.WriteLn(' 完成');
  
  AddTestResult('缓冲输出', '测试缓冲输出功能', trPassed);
end;

procedure TTerminalCompatibilityTester.TestColorSupport;
var
  LColor: TTerminalColor;
begin
  if not FInfo.SupportsColor then
  begin
    AddTestResult('颜色支持', '测试颜色输出功能', trSkipped, '终端不支持颜色');
    Exit;
  end;
  
  // 测试基本颜色
  for LColor := Low(TTerminalColor) to High(TTerminalColor) do
  begin
    FOutput.SetForegroundColor(LColor);
    FOutput.Write('■');
  end;
  FOutput.ResetColors;
  FOutput.WriteLn(' 颜色测试完成');
  
  AddTestResult('基本颜色', '测试16色输出', trPassed);
  
  // 测试真彩色
  if FInfo.SupportsTrueColor then
  begin
    FOutput.SetForegroundColorRGB(255, 0, 0);
    FOutput.Write('红');
    FOutput.SetForegroundColorRGB(0, 255, 0);
    FOutput.Write('绿');
    FOutput.SetForegroundColorRGB(0, 0, 255);
    FOutput.Write('蓝');
    FOutput.ResetColors;
    FOutput.WriteLn(' 真彩色测试完成');
    
    AddTestResult('真彩色', '测试24位真彩色输出', trPassed);
  end
  else
    AddTestResult('真彩色', '测试24位真彩色输出', trSkipped, '终端不支持真彩色');
end;

procedure TTerminalCompatibilityTester.TestCursorControl;
var
  LOriginalPos: TCursorPosition;
begin
  // 保存当前位置
  LOriginalPos := FOutput.GetCursorPosition;
  
  // 测试光标移动
  FOutput.MoveCursor(10, 5);
  FOutput.Write('光标测试');
  
  // 测试光标控制
  FOutput.HideCursor;
  Sleep(500);
  FOutput.ShowCursor;
  
  // 恢复位置
  FOutput.MoveCursor(LOriginalPos.X, LOriginalPos.Y);
  FOutput.WriteLn('光标控制测试完成');
  
  AddTestResult('光标控制', '测试光标移动和显示控制', trPassed);
end;

procedure TTerminalCompatibilityTester.TestScreenControl;
begin
  // 测试屏幕清除
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('屏幕已清除');
  
  // 测试备用屏幕
  if tcAltScreenSupport in FInfo.GetCapabilities then
  begin
    FOutput.EnterAlternateScreen;
    FOutput.WriteLn('进入备用屏幕');
    Sleep(1000);
    FOutput.LeaveAlternateScreen;
    FOutput.WriteLn('返回主屏幕');
    
    AddTestResult('备用屏幕', '测试备用屏幕切换', trPassed);
  end
  else
    AddTestResult('备用屏幕', '测试备用屏幕切换', trSkipped, '终端不支持备用屏幕');
end;

procedure TTerminalCompatibilityTester.TestKeyboardInput;
begin
  WriteLn('键盘输入测试需要用户交互，跳过自动测试');
  AddTestResult('键盘输入', '测试键盘输入处理', trSkipped, '需要用户交互');
end;

procedure TTerminalCompatibilityTester.TestMouseSupport;
begin
  if not FInfo.SupportsMouseInput then
  begin
    AddTestResult('鼠标支持', '测试鼠标事件处理', trSkipped, '终端不支持鼠标');
    Exit;
  end;
  
  WriteLn('鼠标支持测试需要用户交互，跳过自动测试');
  AddTestResult('鼠标支持', '测试鼠标事件处理', trSkipped, '需要用户交互');
end;

procedure TTerminalCompatibilityTester.TestClipboardSupport;
begin
  if not FInfo.SupportsClipboard then
  begin
    AddTestResult('剪贴板支持', '测试剪贴板操作', trSkipped, '终端不支持剪贴板');
    Exit;
  end;
  
  WriteLn('剪贴板支持测试需要用户交互，跳过自动测试');
  AddTestResult('剪贴板支持', '测试剪贴板操作', trSkipped, '需要用户交互');
end;

procedure TTerminalCompatibilityTester.TestAdvancedFeatures;
begin
  // 测试超链接支持
  if FInfo.SupportsHyperlink then
  begin
    FOutput.WriteLn('测试超链接: \e]8;;https://example.com\e\\链接文本\e]8;;\e\\');
    AddTestResult('超链接支持', '测试超链接输出', trPassed);
  end
  else
    AddTestResult('超链接支持', '测试超链接输出', trSkipped, '终端不支持超链接');
    
  // 测试同步输出
  if FInfo.SupportsSynchronizedOutput then
  begin
    FOutput.BeginSynchronizedUpdate;
    FOutput.WriteLn('同步输出测试');
    FOutput.EndSynchronizedUpdate;
    AddTestResult('同步输出', '测试同步输出功能', trPassed);
  end
  else
    AddTestResult('同步输出', '测试同步输出功能', trSkipped, '终端不支持同步输出');
end;

procedure TTerminalCompatibilityTester.RunAllTests;
begin
  WriteLn('fafafa.core.term 终端兼容性测试');
  WriteLn('================================');
  WriteLn;
  
  WriteLn('环境信息:');
  WriteLn('  终端类型: ', FInfo.GetTerminalType);
  WriteLn('  终端尺寸: ', FInfo.GetSize.Width, 'x', FInfo.GetSize.Height);
  WriteLn('  颜色深度: ', FInfo.GetColorDepth);
  WriteLn;
  
  WriteLn('开始测试...');
  WriteLn;
  
  TestTerminalDetection;
  TestBasicOutput;
  TestColorSupport;
  TestCursorControl;
  TestScreenControl;
  TestKeyboardInput;
  TestMouseSupport;
  TestClipboardSupport;
  TestAdvancedFeatures;
  
  WriteLn;
  WriteLn('测试完成！');
end;

procedure TTerminalCompatibilityTester.PrintSummary;
begin
  WriteLn;
  WriteLn('测试总结');
  WriteLn('========');
  WriteLn('总测试数: ', FTotalTests);
  WriteLn('通过: ', FPassedTests);
  WriteLn('失败: ', FFailedTests);
  WriteLn('跳过: ', FSkippedTests);
  WriteLn;
  
  if FFailedTests = 0 then
    WriteLn('所有测试通过！')
  else
    WriteLn('有 ', FFailedTests, ' 个测试失败');
end;

procedure TTerminalCompatibilityTester.SaveReport(const aFileName: string);
var
  LFile: TextFile;
  I: Integer;
begin
  AssignFile(LFile, aFileName);
  Rewrite(LFile);
  
  try
    WriteLn(LFile, 'fafafa.core.term 终端兼容性测试报告');
    WriteLn(LFile, '测试时间: ', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    WriteLn(LFile, '终端类型: ', FInfo.GetTerminalType);
    WriteLn(LFile, '');
    
    for I := 0 to High(FTestResults) do
    begin
      with FTestResults[I] do
      begin
        WriteLn(LFile, Format('测试: %s', [Name]));
        WriteLn(LFile, Format('  描述: %s', [Description]));
        WriteLn(LFile, Format('  结果: %s', [
          case Result of
            trPassed: '通过';
            trFailed: '失败';
            trSkipped: '跳过';
            trPartial: '部分支持';
          end
        ]));
        if Details <> '' then
          WriteLn(LFile, Format('  详情: %s', [Details]));
        if Duration > 0 then
          WriteLn(LFile, Format('  耗时: %d ms', [Duration]));
        WriteLn(LFile, '');
      end;
    end;
    
    WriteLn(LFile, Format('总结: %d/%d 测试通过', [FPassedTests, FTotalTests]));
    
  finally
    CloseFile(LFile);
  end;
end;

var
  LTester: TTerminalCompatibilityTester;

begin
  try
    LTester := TTerminalCompatibilityTester.Create;
    try
      LTester.RunAllTests;
      LTester.PrintSummary;
      LTester.SaveReport('compatibility_report.txt');
      
      WriteLn('详细报告已保存到 compatibility_report.txt');
      
    finally
      LTester.Free;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('兼容性测试失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
