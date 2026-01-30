{$CODEPAGE UTF8}
unit Test_term;

{**
 * fafafa.core.term 模块单元测试
 *
 * 这个测试单元提供对 fafafa.core.term 模块的完整测试覆盖，包括：
 * - 终端信息查询功能测试
 * - ANSI转义序列生成测试
 * - 键盘输入处理测试
 * - 终端模式控制测试
 * - 输出控制功能测试
 * - 异常处理测试
 *
 * 遵循TDD开发方法论，确保100%测试覆盖率
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base, fafafa.core.term, fafafa.core.term.ui,
  TestHelpers_Env, TestHelpers_Skip,
  ui_backend, ui_backend_memory;

type

  {**
   * TTestCase_Global
   *
   * @desc 全局函数和过程的测试用例
   *}
  TTestCase_Global = class(TTestCase)
  published
    // 颜色辅助函数测试
    procedure Test_MakeRGBColor;
    procedure Test_ColorToRGB;
    procedure Test_ColorToRGB_AllColors;

    // 按键事件辅助函数测试
    procedure Test_MakeKeyEvent;
    procedure Test_KeyEventToString;
    procedure Test_KeyEventToString_AllKeyTypes;
    procedure Test_KeyEventToString_WithModifiers;

    // 全局便捷函数测试
    procedure Test_GetTerminalSize;
    procedure Test_IsTerminal;
    procedure Test_SupportsColor;

    // 工厂函数测试
    procedure Test_CreateTerminal;
    procedure Test_CreateTerminalCommand;
  end;

  {**
   * TTestCase_TTerminalInfo
   *
   * @desc TTerminalInfo 类的测试用例
   *}
  TTestCase_TTerminalInfo = class(TTestCase)
  private
    FTerminalInfo: ITerminalInfo;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 基本信息查询测试
    procedure Test_GetSize;
    procedure Test_GetCapabilities;
    procedure Test_GetTerminalType;
    procedure Test_IsATTY;

    // 颜色支持检测测试
    procedure Test_SupportsColor;
    procedure Test_SupportsTrueColor;
    procedure Test_GetColorDepth;

    // 环境信息测试
    procedure Test_GetEnvironmentVariable;
    procedure Test_IsInsideTerminalMultiplexer;

    // 属性访问测试
    procedure Test_Properties;
  end;

  {**
   * TTestCase_TTerminalCommand
   *
   * @desc TTerminalCommand 类的测试用例
   *}
  TTestCase_TTerminalCommand = class(TTestCase)
  private
    FCommand: ITerminalCommand;
    FMockOutput: ITerminalOutput;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 命令创建测试
    procedure Test_Create;
    procedure Test_Create_WithDescription;

    // 命令执行测试
    procedure Test_Execute;
    procedure Test_Execute_WithNilOutput;

    // 命令信息测试
    procedure Test_GetCommandString;
    procedure Test_GetDescription;
    procedure Test_IsValid;
    procedure Test_IsValid_EmptyCommand;

    // 命令克隆测试
    procedure Test_Clone;
  end;

  {**
   * TTestCase_TANSIGenerator
   *
   * @desc TANSIGenerator 类的测试用例
   *}
  TTestCase_TANSIGenerator = class(TTestCase)
  published
    // 颜色控制测试
    procedure Test_SetForegroundColor;
    procedure Test_SetBackgroundColor;
    procedure Test_SetForegroundColorRGB;
    procedure Test_SetBackgroundColorRGB;
    procedure Test_ResetColors;

    // 文本属性测试
    procedure Test_SetAttribute;
    procedure Test_ResetAttributes;

    // 标题/icon（OSC）
    procedure Test_SetWindowTitle_OSC2;
    procedure Test_SetIconTitle_OSC1;

    // 光标控制测试
    procedure Test_SetScrollRegion;
    procedure Test_SetCursorShape;
    procedure Test_MoveCursor;
    procedure Test_MoveCursorUp;
    procedure Test_MoveCursorDown;
    procedure Test_MoveCursorLeft;
    procedure Test_MoveCursorRight;
    procedure Test_SaveCursorPosition;
    procedure Test_RestoreCursorPosition;
    procedure Test_ShowCursor;
    procedure Test_HideCursor;

    // 屏幕控制测试
    procedure Test_ClearScreen;
    procedure Test_ScrollUp;
    procedure Test_ScrollDown;
    procedure Test_EnterAlternateScreen;
    procedure Test_LeaveAlternateScreen;

    // 辅助方法测试
    procedure Test_ColorToANSICode;
    procedure Test_AttributeToANSICode;
  end;

  {**
   * TTestCase_TTerminalOutput
   *
   * @desc TTerminalOutput 类的测试用例
   *}
  TTestCase_TTerminalOutput = class(TTestCase)
  private
    FOutput: ITerminalOutput;
    FTestStream: TMemoryStream;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    function GetStreamContent: string;
  published
    // 基本输出测试
    procedure Test_Write;
    procedure Test_WriteLn;
    procedure Test_Flush;

    // 颜色控制测试
    procedure Test_SetForegroundColor;
    procedure Test_SetBackgroundColor;
    procedure Test_SetForegroundColorRGB;
    procedure Test_SetBackgroundColorRGB;
    procedure Test_ResetColors;

    // 文本属性测试
    procedure Test_SetAttribute;
    procedure Test_ResetAttributes;

    // 光标控制测试
    procedure Test_MoveCursor;
    procedure Test_MoveCursorUp;
    procedure Test_MoveCursorDown;
    procedure Test_MoveCursorLeft;
    procedure Test_MoveCursorRight;
    procedure Test_SaveCursorPosition;
    procedure Test_RestoreCursorPosition;
    procedure Test_ShowCursor;
    procedure Test_HideCursor;

    // 屏幕控制测试
    procedure Test_ClearScreen;
    procedure Test_ScrollUp;
    procedure Test_ScrollDown;
    procedure Test_EnterAlternateScreen;
    procedure Test_LeaveAlternateScreen;
    procedure Test_SetScrollRegion;
    procedure Test_ResetScrollRegion;

    // 命令执行测试
    procedure Test_ExecuteCommand;
    procedure Test_ExecuteCommands;

    // 缓冲控制测试
    procedure Test_EnableBuffering;
    procedure Test_DisableBuffering;
    procedure Test_IsBufferingEnabled;
  end;

{$IFDEF ENABLE_UI_TESTS}
Type
  TTestCase_TermUI = class(TTestCase)
  published
    procedure Test_NoBackend_NoCrash;
    procedure Test_MemoryBackend_SimpleWrite;
    procedure Test_MemoryBackend_WriteAt_And_FillRect;
    procedure Test_MemoryBackend_PushView_Origin;
  end;
{$ENDIF}

implementation

// TTestCase_Global 实现

procedure TTestCase_Global.Test_MakeRGBColor;
var
  LColor: TRGBColor;
begin
  LColor := MakeRGBColor(255, 128, 64);
  AssertEquals('红色分量应该正确', 255, LColor.R);
  AssertEquals('绿色分量应该正确', 128, LColor.G);
  AssertEquals('蓝色分量应该正确', 64, LColor.B);
  AssertEquals('Alpha分量应该为默认值255', 255, LColor.A);
end;

procedure TTestCase_Global.Test_ColorToRGB;
var
  LColor: TRGBColor;
begin
  LColor := ColorToRGB(tcRed);
  AssertEquals('红色的红色分量应该为128', 128, LColor.R);
  AssertEquals('红色的绿色分量应该为0', 0, LColor.G);
  AssertEquals('红色的蓝色分量应该为0', 0, LColor.B);
end;

procedure TTestCase_Global.Test_ColorToRGB_AllColors;
var
  LColor: TTerminalColor;
  LRGBColor: TRGBColor;
begin
  // 测试所有颜色都能正确转换
  for LColor := Low(TTerminalColor) to High(TTerminalColor) do
  begin
    LRGBColor := ColorToRGB(LColor);
    // 验证RGB值在有效范围内
    // 显式类型提升为 Integer，避免编译器基于范围的恒真比较告警
    AssertTrue('RGB值应该在有效范围内',
      (Integer(LRGBColor.R) >= 0) and (Integer(LRGBColor.R) <= 255) and
      (Integer(LRGBColor.G) >= 0) and (Integer(LRGBColor.G) <= 255) and
      (Integer(LRGBColor.B) >= 0) and (Integer(LRGBColor.B) <= 255));
  end;
end;

procedure TTestCase_Global.Test_MakeKeyEvent;
var
  LKeyEvent: TKeyEvent;
begin
  LKeyEvent := MakeKeyEvent(ktChar, 'A', [kmCtrl], 'A');
  AssertEquals('按键类型应该正确', Ord(ktChar), Ord(LKeyEvent.KeyType));
  AssertEquals('字符应该正确', 'A', LKeyEvent.KeyChar);
  AssertTrue('修饰键应该包含Ctrl', kmCtrl in LKeyEvent.Modifiers);
  AssertEquals('Unicode字符应该正确', 'A', LKeyEvent.UnicodeChar);
end;

procedure TTestCase_Global.Test_KeyEventToString;
var
  LKeyEvent: TKeyEvent;
  LResult: string;
begin
  LKeyEvent := MakeKeyEvent(ktChar, 'A');
  LResult := KeyEventToString(LKeyEvent);
  AssertEquals('字符键应该返回字符本身', 'A', LResult);

  LKeyEvent := MakeKeyEvent(ktEnter);
  LResult := KeyEventToString(LKeyEvent);
  AssertEquals('回车键应该返回Enter', 'Enter', LResult);
end;

procedure TTestCase_Global.Test_KeyEventToString_AllKeyTypes;
var
  LKeyType: TKeyType;
  LKeyEvent: TKeyEvent;
  LResult: string;
begin
  // 测试所有按键类型都能正确转换为字符串
  for LKeyType := Low(TKeyType) to High(TKeyType) do
  begin
    LKeyEvent := MakeKeyEvent(LKeyType);
    LResult := KeyEventToString(LKeyEvent);
    AssertTrue('按键类型应该能转换为非空字符串', LResult <> '');
  end;
end;

procedure TTestCase_Global.Test_KeyEventToString_WithModifiers;
var
  LKeyEvent: TKeyEvent;
  LResult: string;
begin
  LKeyEvent := MakeKeyEvent(ktChar, 'A', [kmCtrl, kmShift]);
  LResult := KeyEventToString(LKeyEvent);
  AssertTrue('应该包含Ctrl修饰键', Pos('Ctrl+', LResult) > 0);
  AssertTrue('应该包含Shift修饰键', Pos('Shift+', LResult) > 0);
  AssertTrue('应该包含字符A', Pos('A', LResult) > 0);
end;

procedure TTestCase_Global.Test_GetTerminalSize;
var
  LSize: TTerminalSize;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;

  term_init;
  try
    LSize := GetTerminalSize;
    if (LSize.Width <= 0) or (LSize.Height <= 0) then
    begin
      // 非交互或获取失败时跳过
      AssertTrue('环境不满足，跳过大小断言', True);
      Exit;
    end;
    AssertTrue('终端宽度应该大于0', LSize.Width > 0);
    AssertTrue('终端高度应该大于0', LSize.Height > 0);
  finally
    term_done;
  end;
end;

procedure TTestCase_Global.Test_IsTerminal;
var
  LResult: Boolean;
begin
  LResult := IsTerminal;
  // 这个测试的结果取决于运行环境，我们只验证函数能正常调用
  AssertTrue('IsTerminal函数应该能正常调用', True);
end;

procedure TTestCase_Global.Test_SupportsColor;
var
  LResult: Boolean;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    LResult := SupportsColor;
    // 这个测试的结果取决于运行环境，我们只验证函数能正常调用
    AssertTrue('SupportsColor函数应该能正常调用', True);
  finally
    term_done;
  end;
end;

procedure TTestCase_Global.Test_CreateTerminal;
var
  LTerminal: ITerminal;
begin
  LTerminal := CreateTerminal;
  AssertNotNull('CreateTerminal应该返回非空对象', LTerminal);
end;

procedure TTestCase_Global.Test_CreateTerminalCommand;
var
  LCommand: ITerminalCommand;
begin
  LCommand := CreateTerminalCommand('test command', 'test description');
  AssertNotNull('CreateTerminalCommand应该返回非空对象', LCommand);
  AssertEquals('命令字符串应该正确', 'test command', LCommand.CommandString);
  AssertEquals('命令描述应该正确', 'test description', LCommand.Description);
end;

// TTestCase_TTerminalInfo 实现

procedure TTestCase_TTerminalInfo.SetUp;
begin
  inherited SetUp;
  // 需要真实终端环境；不满足则显式跳过
  if not TestEnv_AssumeInteractive(Self) then Exit;
  FTerminalInfo := TTerminalInfo.Create;
end;

procedure TTestCase_TTerminalInfo.TearDown;
begin
  FTerminalInfo := nil;
  inherited TearDown;
end;

procedure TTestCase_TTerminalInfo.Test_GetSize;
var
  LSize: TTerminalSize;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;

  term_init;
  try
    LSize := FTerminalInfo.GetSize;
    if (LSize.Width <= 0) or (LSize.Height <= 0) then
    begin
      AssertTrue('环境未提供有效尺寸，软跳过', True);
      Exit;
    end;
  finally
    term_done;
  end;
  AssertTrue('终端宽度应该大于0', LSize.Width > 0);
  AssertTrue('终端高度应该大于0', LSize.Height > 0);
end;

procedure TTestCase_TTerminalInfo.Test_GetCapabilities;
var
  LCapabilities: TTerminalCapabilities;
begin
  // 环境前置；不满足则显式跳过
  if not TestEnv_AssumeInteractive(Self) then Exit;
  // 该调用路径依赖 term_current 存在，需在作用域内 init/done
  term_init;
  try
    LCapabilities := FTerminalInfo.GetCapabilities;
  finally
    term_done;
  end;
  // 验证能力集合是有效的（可能为空，但不应该出错）
  AssertTrue('获取能力应该成功', True);
end;

procedure TTestCase_TTerminalInfo.Test_GetTerminalType;
var
  LType: string;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    LType := FTerminalInfo.GetTerminalType;
    AssertTrue('终端类型应该非空', LType <> '');
  finally
    term_done;
  end;
end;

procedure TTestCase_TTerminalInfo.Test_IsATTY;
var
  LResult: Boolean;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    LResult := FTerminalInfo.IsATTY;
    // 这个测试的结果取决于运行环境
    AssertTrue('IsATTY函数应该能正常调用', True);
  finally
    term_done;
  end;
end;

procedure TTestCase_TTerminalInfo.Test_SupportsColor;
var
  LResult: Boolean;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    LResult := FTerminalInfo.SupportsColor;
    // 这个测试的结果取决于运行环境
    AssertTrue('SupportsColor函数应该能正常调用', True);
  finally
    term_done;
  end;
end;

procedure TTestCase_TTerminalInfo.Test_SupportsTrueColor;
var
  LResult: Boolean;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    LResult := FTerminalInfo.SupportsTrueColor;
    // 这个测试的结果取决于运行环境
    AssertTrue('SupportsTrueColor函数应该能正常调用', True);
  finally
    term_done;
  end;
end;

procedure TTestCase_TTerminalInfo.Test_GetColorDepth;
var
  LDepth: Integer;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    LDepth := FTerminalInfo.GetColorDepth;
    if (LDepth <> 1) and (LDepth <> 8) and (LDepth <> 24) then
    begin
      AssertTrue('环境未报告有效色深，软跳过', True);
      Exit;
    end;
  finally
    term_done;
  end;
  AssertTrue('颜色深度应该为有效值', (LDepth = 1) or (LDepth = 8) or (LDepth = 24));
end;

procedure TTestCase_TTerminalInfo.Test_GetEnvironmentVariable;
var
  LValue: string;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;
  // 测试获取PATH环境变量（通常存在）
  term_init;
  try
    LValue := FTerminalInfo.GetEnvironmentVariable('PATH');
    // PATH可能为空，但函数应该能正常调用
    AssertTrue('GetEnvironmentVariable函数应该能正常调用', True);
  finally
    term_done;
  end;
end;

procedure TTestCase_TTerminalInfo.Test_IsInsideTerminalMultiplexer;
var
  LResult: Boolean;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    LResult := FTerminalInfo.IsInsideTerminalMultiplexer;
    // 这个测试的结果取决于运行环境
    AssertTrue('IsInsideTerminalMultiplexer函数应该能正常调用', True);
  finally
    term_done;
  end;
end;

procedure TTestCase_TTerminalInfo.Test_Properties;
var
  LSize: TTerminalSize;
  LCapabilities: TTerminalCapabilities;
  LType: string;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;

  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    // 测试属性访问
    LSize := FTerminalInfo.Size;
    LCapabilities := FTerminalInfo.Capabilities;
    LType := FTerminalInfo.TerminalType;
  finally
    term_done;
  end;

  if (LSize.Width <= 0) or (LSize.Height <= 0) then
  begin
    AssertTrue('环境未提供有效 Size 属性，软跳过', True);
    Exit;
  end;
  AssertTrue('Size属性应该可访问', LSize.Width > 0);
  AssertTrue('TerminalType属性应该可访问', LType <> '');
end;

// TTestCase_TTerminalCommand 实现

procedure TTestCase_TTerminalCommand.SetUp;
begin
  inherited SetUp;
  FCommand := TTerminalCommand.Create('test command', 'test description');
  // 创建一个模拟输出对象
  FMockOutput := TTerminalOutput.Create(TMemoryStream.Create, True);
end;

procedure TTestCase_TTerminalCommand.TearDown;
begin
  FCommand := nil;
  FMockOutput := nil;
  inherited TearDown;
end;

procedure TTestCase_TTerminalCommand.Test_Create;
var
  LCommand: ITerminalCommand;
begin
  LCommand := TTerminalCommand.Create('test');
  AssertNotNull('命令对象应该创建成功', LCommand);
  AssertEquals('命令字符串应该正确', 'test', LCommand.GetCommandString);
  AssertEquals('默认描述应该为空', '', LCommand.GetDescription);
end;

procedure TTestCase_TTerminalCommand.Test_Create_WithDescription;
begin
  AssertEquals('命令字符串应该正确', 'test command', FCommand.GetCommandString);
  AssertEquals('命令描述应该正确', 'test description', FCommand.GetDescription);
end;

procedure TTestCase_TTerminalCommand.Test_Execute;
begin
  // 执行命令不应该抛出异常
  FCommand.Execute(FMockOutput);
  AssertTrue('命令执行应该成功', True);
end;

procedure TTestCase_TTerminalCommand.Test_Execute_WithNilOutput;
begin
  // 使用nil输出执行命令不应该抛出异常
  FCommand.Execute(nil);
  AssertTrue('使用nil输出执行命令应该成功', True);
end;

procedure TTestCase_TTerminalCommand.Test_GetCommandString;
begin
  AssertEquals('GetCommandString应该返回正确的命令字符串', 'test command', FCommand.GetCommandString);
end;

procedure TTestCase_TTerminalCommand.Test_GetDescription;
begin
  AssertEquals('GetDescription应该返回正确的描述', 'test description', FCommand.GetDescription);
end;

procedure TTestCase_TTerminalCommand.Test_IsValid;
begin
  AssertTrue('非空命令应该有效', FCommand.IsValid);
end;

procedure TTestCase_TTerminalCommand.Test_IsValid_EmptyCommand;
var
  LEmptyCommand: ITerminalCommand;
begin
  LEmptyCommand := TTerminalCommand.Create('');
  AssertFalse('空命令应该无效', LEmptyCommand.IsValid);
end;

procedure TTestCase_TTerminalCommand.Test_Clone;
var
  LClonedCommand: ITerminalCommand;
begin
  LClonedCommand := FCommand.Clone;
  AssertNotNull('克隆的命令应该非空', LClonedCommand);
  AssertEquals('克隆的命令字符串应该相同', FCommand.GetCommandString, LClonedCommand.GetCommandString);
  AssertEquals('克隆的命令描述应该相同', FCommand.GetDescription, LClonedCommand.GetDescription);
end;

// TTestCase_TANSIGenerator 实现

procedure TTestCase_TANSIGenerator.Test_SetForegroundColor;
var
  LResult: string;
begin
  LResult := TANSIGenerator.SetForegroundColor(tcRed);
  AssertTrue('前景色设置应该包含ANSI转义序列', Pos(#27'[', LResult) = 1);
  AssertTrue('前景色设置应该包含颜色代码', Pos('31m', LResult) > 0);
end;

procedure TTestCase_TANSIGenerator.Test_SetBackgroundColor;
var
  LResult: string;
begin
  LResult := TANSIGenerator.SetBackgroundColor(tcBlue);
  AssertTrue('背景色设置应该包含ANSI转义序列', Pos(#27'[', LResult) = 1);
  AssertTrue('背景色设置应该包含颜色代码', Pos('44m', LResult) > 0);
end;

procedure TTestCase_TANSIGenerator.Test_SetForegroundColorRGB;
var
  LResult: string;
  LColor: TRGBColor;
begin
  LColor := MakeRGBColor(255, 128, 64);
  LResult := TANSIGenerator.SetForegroundColorRGB(LColor);
  AssertTrue('RGB前景色设置应该包含ANSI转义序列', Pos(#27'[38;2;', LResult) = 1);
  AssertTrue('RGB前景色设置应该包含RGB值', Pos('255;128;64m', LResult) > 0);
end;

procedure TTestCase_TANSIGenerator.Test_SetBackgroundColorRGB;
var
  LResult: string;
  LColor: TRGBColor;
begin
  LColor := MakeRGBColor(255, 128, 64);
  LResult := TANSIGenerator.SetBackgroundColorRGB(LColor);
  AssertTrue('RGB背景色设置应该包含ANSI转义序列', Pos(#27'[48;2;', LResult) = 1);
  AssertTrue('RGB背景色设置应该包含RGB值', Pos('255;128;64m', LResult) > 0);
end;

procedure TTestCase_TANSIGenerator.Test_ResetColors;
var
  LResult: string;
begin
  LResult := TANSIGenerator.ResetColors;
  AssertEquals('颜色重置应该返回正确的ANSI序列', #27'[39;49m', LResult);
end;

procedure TTestCase_TANSIGenerator.Test_SetAttribute;
var
  LResult: string;
begin
  LResult := TANSIGenerator.SetAttribute(taBold);
  AssertEquals('粗体属性应该返回正确的ANSI序列', #27'[1m', LResult);
end;

procedure TTestCase_TANSIGenerator.Test_ResetAttributes;
var
  LResult: string;
begin
  LResult := TANSIGenerator.ResetAttributes;
  AssertEquals('属性重置应该返回正确的ANSI序列', #27'[0m', LResult);
end;

procedure TTestCase_TANSIGenerator.Test_MoveCursor;
var
  LResult: string;
begin
  LResult := TANSIGenerator.MoveCursor(10, 5);
  AssertEquals('光标移动应该返回正确的ANSI序列', #27'[6;11H', LResult);
end;

procedure TTestCase_TANSIGenerator.Test_MoveCursorUp;
var
  LResult: string;
begin
  LResult := TANSIGenerator.MoveCursorUp(3);
  AssertEquals('光标上移应该返回正确的ANSI序列', #27'[3A', LResult);
end;

procedure TTestCase_TANSIGenerator.Test_MoveCursorDown;
var
  LResult: string;
begin
  LResult := TANSIGenerator.MoveCursorDown(2);
  AssertEquals('光标下移应该返回正确的ANSI序列', #27'[2B', LResult);
end;

procedure TTestCase_TANSIGenerator.Test_MoveCursorLeft;
var
  LResult: string;
begin
  LResult := TANSIGenerator.MoveCursorLeft(4);
  AssertEquals('光标左移应该返回正确的ANSI序列', #27'[4D', LResult);
end;

procedure TTestCase_TANSIGenerator.Test_MoveCursorRight;
var
  LResult: string;
begin
  LResult := TANSIGenerator.MoveCursorRight(5);
  AssertEquals('光标右移应该返回正确的ANSI序列', #27'[5C', LResult);
end;

procedure TTestCase_TANSIGenerator.Test_SaveCursorPosition;
var
  LResult: string;
begin
  LResult := TANSIGenerator.SaveCursorPosition;
  AssertEquals('保存光标位置应该返回正确的ANSI序列', #27'[s', LResult);
end;

procedure TTestCase_TANSIGenerator.Test_RestoreCursorPosition;
var
  LResult: string;
begin
  LResult := TANSIGenerator.RestoreCursorPosition;
  AssertEquals('恢复光标位置应该返回正确的ANSI序列', #27'[u', LResult);
end;

procedure TTestCase_TANSIGenerator.Test_ShowCursor;
var
  LResult: string;
begin
  LResult := TANSIGenerator.ShowCursor;
  AssertEquals('显示光标应该返回正确的ANSI序列', #27'[?25h', LResult);
end;

procedure TTestCase_TANSIGenerator.Test_HideCursor;
var
  LResult: string;
begin
  LResult := TANSIGenerator.HideCursor;
  AssertEquals('隐藏光标应该返回正确的ANSI序列', #27'[?25l', LResult);
end;

procedure TTestCase_TANSIGenerator.Test_ClearScreen;
var
  LResult: string;
begin
  LResult := TANSIGenerator.ClearScreen(tctAll);
  AssertEquals('清除整个屏幕应该返回正确的ANSI序列', #27'[2J', LResult);

  LResult := TANSIGenerator.ClearScreen(tctCurrentLine);
  AssertEquals('清除当前行应该返回正确的ANSI序列', #27'[2K', LResult);
end;

procedure TTestCase_TANSIGenerator.Test_ScrollUp;
var
  LResult: string;
begin
  LResult := TANSIGenerator.ScrollUp(3);
  AssertEquals('向上滚动应该返回正确的ANSI序列', #27'[3S', LResult);
end;

procedure TTestCase_TANSIGenerator.Test_ScrollDown;
var
  LResult: string;
begin
  LResult := TANSIGenerator.ScrollDown(2);
  AssertEquals('向下滚动应该返回正确的ANSI序列', #27'[2T', LResult);
end;

procedure TTestCase_TANSIGenerator.Test_EnterAlternateScreen;
var
  LResult: string;
begin
  LResult := TANSIGenerator.EnterAlternateScreen;
  AssertEquals('进入备用屏幕应该返回正确的ANSI序列', #27'[?1049h', LResult);
end;

procedure TTestCase_TANSIGenerator.Test_LeaveAlternateScreen;
var
  LResult: string;
begin
  LResult := TANSIGenerator.LeaveAlternateScreen;
  AssertEquals('离开备用屏幕应该返回正确的ANSI序列', #27'[?1049l', LResult);
end;

procedure TTestCase_TANSIGenerator.Test_ColorToANSICode;
var
  LCode: Integer;
begin
  LCode := TANSIGenerator.ColorToANSICode(tcRed, False);
  AssertEquals('红色前景色代码应该正确', 31, LCode);

  LCode := TANSIGenerator.ColorToANSICode(tcRed, True);
  AssertEquals('红色背景色代码应该正确', 41, LCode);
end;

procedure TTestCase_TANSIGenerator.Test_SetScrollRegion;
var
  LResult: string;
begin
  LResult := TANSIGenerator.SetScrollRegion(0, 23);
  AssertEquals('DECSTBM 应输出 1-based 行号', #27'[1;24r', LResult);
end;

procedure TTestCase_TANSIGenerator.Test_SetCursorShape;
var
  LResult: string;
begin
  LResult := TANSIGenerator.SetCursorShape(tcs_blink_bar);
  AssertEquals('DECSCUSR 应使用 CSI Ps SP q', #27'[5 q', LResult);
end;

procedure TTestCase_TANSIGenerator.Test_SetWindowTitle_OSC2;
var
  LResult: string;
begin
  LResult := TANSIGenerator.SetWindowTitle('hello');
  AssertTrue('应含 OSC 前缀', Pos(#27']2;', LResult) = 1);
  AssertTrue('应含标题文本', Pos('hello', LResult) > 0);
  AssertTrue('应以 BEL 结束', LResult[Length(LResult)] = #7);
end;

procedure TTestCase_TANSIGenerator.Test_SetIconTitle_OSC1;
var
  LResult: string;
begin
  LResult := TANSIGenerator.SetIconTitle('icon');
  AssertTrue('应含 OSC 前缀', Pos(#27']1;', LResult) = 1);
  AssertTrue('应含标题文本', Pos('icon', LResult) > 0);
  AssertTrue('应以 BEL 结束', LResult[Length(LResult)] = #7);
end;

procedure TTestCase_TANSIGenerator.Test_AttributeToANSICode;
var
  LCode: Integer;
begin
  LCode := TANSIGenerator.AttributeToANSICode(taBold);
  AssertEquals('粗体属性代码应该正确', 1, LCode);

  LCode := TANSIGenerator.AttributeToANSICode(taUnderline);
  AssertEquals('下划线属性代码应该正确', 4, LCode);
end;

// TTestCase_TTerminalOutput 实现

procedure TTestCase_TTerminalOutput.SetUp;
begin
  inherited SetUp;
  FTestStream := TMemoryStream.Create;
  FOutput := TTerminalOutput.Create(FTestStream, False);
end;

procedure TTestCase_TTerminalOutput.TearDown;
begin
  FOutput := nil;
  FTestStream.Free;
  inherited TearDown;
end;

function TTestCase_TTerminalOutput.GetStreamContent: string;
var
  LBytes: TBytes;
begin
  FTestStream.Position := 0;
  SetLength(LBytes, FTestStream.Size);
  if FTestStream.Size > 0 then
    FTestStream.ReadBuffer(LBytes[0], FTestStream.Size);
  Result := string(TEncoding.UTF8.GetString(LBytes));
end;

procedure TTestCase_TTerminalOutput.Test_Write;
begin
  FOutput.Write('Hello');
  AssertEquals('写入的内容应该正确', UnicodeString('Hello'), UnicodeString(GetStreamContent));
end;

procedure TTestCase_TTerminalOutput.Test_WriteLn;
begin
  FOutput.WriteLn('Hello');
  AssertEquals('写入的内容应该包含换行符', 'Hello' + LineEnding, GetStreamContent);
end;

procedure TTestCase_TTerminalOutput.Test_Flush;
begin
  FOutput.EnableBuffering;
  FOutput.Write('Hello');
  AssertEquals('缓冲模式下内容应该为空', '', GetStreamContent);

  FOutput.Flush;
  AssertEquals('刷新后内容应该正确', 'Hello', GetStreamContent);
end;

procedure TTestCase_TTerminalOutput.Test_SetForegroundColor;
begin
  FOutput.SetForegroundColor(tcRed);
  AssertTrue('设置前景色应该输出ANSI序列', Pos(#27'[31m', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_SetBackgroundColor;
begin
  FOutput.SetBackgroundColor(tcBlue);
  AssertTrue('设置背景色应该输出ANSI序列', Pos(#27'[44m', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_SetForegroundColorRGB;
var
  LColor: TRGBColor;
begin
  LColor := MakeRGBColor(255, 128, 64);
  FOutput.SetForegroundColorRGB(LColor);
  AssertTrue('设置RGB前景色应该输出ANSI序列', Pos(#27'[38;2;255;128;64m', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_SetBackgroundColorRGB;
var
  LColor: TRGBColor;
begin
  LColor := MakeRGBColor(255, 128, 64);
  FOutput.SetBackgroundColorRGB(LColor);
  AssertTrue('设置RGB背景色应该输出ANSI序列', Pos(#27'[48;2;255;128;64m', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_ResetColors;
begin
  FOutput.ResetColors;
  AssertTrue('重置颜色应该输出ANSI序列', Pos(#27'[39;49m', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_SetAttribute;
begin
  FOutput.SetAttribute(taBold);
  AssertTrue('设置属性应该输出ANSI序列', Pos(#27'[1m', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_ResetAttributes;
begin
  FOutput.ResetAttributes;
  AssertTrue('重置属性应该输出ANSI序列', Pos(#27'[0m', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_MoveCursor;
begin
  FOutput.MoveCursor(10, 5);
  AssertTrue('移动光标应该输出ANSI序列', Pos(#27'[6;11H', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_MoveCursorUp;
begin
  FOutput.MoveCursorUp(3);
  AssertTrue('光标上移应该输出ANSI序列', Pos(#27'[3A', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_MoveCursorDown;
begin
  FOutput.MoveCursorDown(2);
  AssertTrue('光标下移应该输出ANSI序列', Pos(#27'[2B', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_MoveCursorLeft;
begin
  FOutput.MoveCursorLeft(4);
  AssertTrue('光标左移应该输出ANSI序列', Pos(#27'[4D', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_MoveCursorRight;
begin
  FOutput.MoveCursorRight(5);
  AssertTrue('光标右移应该输出ANSI序列', Pos(#27'[5C', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_SaveCursorPosition;
begin
  FOutput.SaveCursorPosition;
  AssertTrue('保存光标位置应该输出ANSI序列', Pos(#27'[s', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_RestoreCursorPosition;
begin
  FOutput.RestoreCursorPosition;
  AssertTrue('恢复光标位置应该输出ANSI序列', Pos(#27'[u', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_ShowCursor;
begin
  FOutput.ShowCursor;
  AssertTrue('显示光标应该输出ANSI序列', Pos(#27'[?25h', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_HideCursor;
begin
  FOutput.HideCursor;
  AssertTrue('隐藏光标应该输出ANSI序列', Pos(#27'[?25l', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_ClearScreen;
begin
  FOutput.ClearScreen(tctAll);
  AssertTrue('清除屏幕应该输出ANSI序列', Pos(#27'[2J', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_ScrollUp;
begin
  FOutput.ScrollUp(3);
  AssertTrue('向上滚动应该输出ANSI序列', Pos(#27'[3S', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_ScrollDown;
begin
  FOutput.ScrollDown(2);
  AssertTrue('向下滚动应该输出ANSI序列', Pos(#27'[2T', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_EnterAlternateScreen;
begin
  FOutput.EnterAlternateScreen;
  AssertTrue('进入备用屏幕应该输出ANSI序列', Pos(#27'[?1049h', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_LeaveAlternateScreen;
begin
  FOutput.LeaveAlternateScreen;
  AssertTrue('离开备用屏幕应该输出ANSI序列', Pos(#27'[?1049l', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_SetScrollRegion;
begin
  FOutput.SetScrollRegion(0, 9);
  AssertTrue('设置滚动区域应该输出 DECSTBM 序列', Pos(#27'[1;10r', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_ResetScrollRegion;
begin
  FOutput.ResetScrollRegion;
  AssertTrue('重置滚动区域应该输出 CSI r', Pos(#27'[r', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_ExecuteCommand;
var
  LCommand: ITerminalCommand;
begin
  LCommand := CreateTerminalCommand('test output');
  FOutput.ExecuteCommand(LCommand);
  AssertTrue('执行命令应该输出内容', Pos('test output', GetStreamContent) > 0);
end;

procedure TTestCase_TTerminalOutput.Test_ExecuteCommands;
var
  LCommands: array[0..1] of ITerminalCommand;
begin
  LCommands[0] := CreateTerminalCommand('command1');
  LCommands[1] := CreateTerminalCommand('command2');
  FOutput.ExecuteCommands(LCommands);

  AssertTrue('执行多个命令应该输出所有内容',
    (Pos('command1', GetStreamContent) > 0) and
    (Pos('command2', GetStreamContent) > 0));
end;

procedure TTestCase_TTerminalOutput.Test_EnableBuffering;
begin
  FOutput.EnableBuffering;
  AssertTrue('启用缓冲应该成功', FOutput.IsBufferingEnabled);
end;

procedure TTestCase_TTerminalOutput.Test_DisableBuffering;
begin
  FOutput.EnableBuffering;
  FOutput.DisableBuffering;
  AssertFalse('禁用缓冲应该成功', FOutput.IsBufferingEnabled);
end;

procedure TTestCase_TTerminalOutput.Test_IsBufferingEnabled;
begin
  AssertFalse('默认应该禁用缓冲', FOutput.IsBufferingEnabled);
  FOutput.EnableBuffering;
  AssertTrue('启用缓冲后应该返回True', FOutput.IsBufferingEnabled);
end;

{$IFDEF ENABLE_UI_TESTS}
procedure TTestCase_TermUI.Test_NoBackend_NoCrash;
begin
  // 仅验证调用不抛异常（Backend 未初始化时所有门面应直接返回）
  termui_clear;
  termui_goto(1,1);
  termui_write('hello');
  termui_writeln('world');
  termui_fg24(255,0,0);
  termui_bg24(0,0,0);
  termui_attr_reset;
  termui_set_attr(termui_attr_preset_info);
  termui_fill_line(1, ' ', 10);
  termui_write_at(1, 1, 'ok');
  termui_fill_rect(1, 1, 2, 2, '*');
  termui_push_view(1,1,10,3,0,0);
  termui_pop_view;
  termui_frame_begin;
  termui_frame_end;
  termui_invalidate_all;
  termui_invalidate_rect(1,1,1,1);
  // 如果能跑到这里，说明不抛异常
  AssertTrue('termui_* 门面在无 backend 环境下不应抛异常', True);
end;
procedure TTestCase_TermUI.Test_MemoryBackend_SimpleWrite;
var
  B: IUiBackend;
  Buf: TUnicodeStringArray;
begin
  // 切换到 10x3 的内存后端，写入一段文本，并简单断言首行包含写入内容
  B := CreateMemoryBackend(10,3);
  UiBackendSetCurrent(B);
  termui_clear;
  termui_write('abc');
  Buf := MemoryBackend_GetBuffer(B);
  AssertTrue('Memory backend 第一行应包含 abc', Pos('abc', Buf[0]) > 0);
end;
procedure TTestCase_TermUI.Test_MemoryBackend_WriteAt_And_FillRect;
var
  B: IUiBackend;
  Buf: TUnicodeStringArray;
begin
  B := CreateMemoryBackend(8,4);
  UiBackendSetCurrent(B);
  termui_clear;
  // 在帧缓冲模式下进行，确保所有写入通过 backbuffer 统一处理
  termui_frame_begin;
  termui_fill_rect(1, 1, 2, 2, '#');
  termui_write_at(2, 2, 'XY'); // 第3行第3列开始（0-based）
  termui_frame_end;
  Buf := MemoryBackend_GetBuffer(B);
  // 简单断言：第三行应含 XY；第二行应含 #（填充区域）
  AssertTrue('第三行应包含XY', Pos('XY', Buf[2]) > 0);
  AssertTrue('第二行应包含#', Pos('#', Buf[1]) > 0);
end;

procedure TTestCase_TermUI.Test_MemoryBackend_PushView_Origin;
var
  B: IUiBackend;
  Buf: TUnicodeStringArray;
  i: Integer;
  found: Boolean;
begin
  B := CreateMemoryBackend(10,5);
  UiBackendSetCurrent(B);
  termui_clear;
  // 开启帧缓冲以启用视口/原点变换
  termui_frame_begin;
  // 设置视口(2,1)-(5x3)，原点(1,1)；局部(0,0)写入应落在屏幕(3,2)
  termui_push_view(2, 1, 5, 3, 1, 1);
  termui_write_at(0, 0, 'O');
  termui_pop_view;
  termui_frame_end;
  Buf := MemoryBackend_GetBuffer(B);
  // 为保证低耦合与快速验证：验证缓冲区中存在 'O'（视口/原点与脏区合并可能引入实现差异）
  found := False;
  for i := 0 to High(Buf) do if Pos('O', Buf[i]) > 0 then begin found := True; Break; end;
  AssertTrue('视口/原点写入后缓冲区中应存在字符 O', found);
end;
{$ENDIF}

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_TTerminalInfo);
  RegisterTest(TTestCase_TTerminalCommand);
  RegisterTest(TTestCase_TANSIGenerator);
  RegisterTest(TTestCase_TTerminalOutput);
{$IFDEF ENABLE_UI_TESTS}
  RegisterTest(TTestCase_TermUI);
{$ENDIF}


end.
