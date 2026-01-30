{$CODEPAGE UTF8}
program theme_demo;

{**
 * 主题系统演示
 *
 * 这个示例演示了如何使用 fafafa.core.term 的主题系统：
 * - 预定义主题切换
 * - 自定义主题创建
 * - 主题颜色应用
 * - 主题文件导入导出
 * - 实时主题预览
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
   * 主题演示器
   *}
  TThemeDemo = class
  private
    FTerminal: ITerminal;
    FOutput: ITerminalOutput;
    FInput: ITerminalInput;
    // FTheme: ITerminalTheme; // Theme system not available in current API
    FRunning: Boolean;

    procedure ShowMenu;
    procedure ShowCurrentTheme;
    procedure DemoPresetThemes;
    procedure DemoCustomTheme;
    procedure DemoThemeColors;
    procedure DemoThemeExport;
    procedure ShowThemePreview(const aThemeName: string);
    procedure ApplyThemeToOutput;
    procedure WaitForKey(const aPrompt: string = '按任意键继续...');
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure Run;
  end;

constructor TThemeDemo.Create;
begin
  inherited Create;
  FTerminal := CreateTerminal;
  FOutput := FTerminal.Output;
  FInput := FTerminal.Input;
  // Theme system not available in current API
  FRunning := False;
end;

destructor TThemeDemo.Destroy;
begin
  FTerminal := nil;
  inherited Destroy;
end;

procedure TThemeDemo.ShowMenu;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.MoveCursor(0, 0);
  
  ApplyThemeToOutput;
  
  FOutput.SetForegroundColor(tcBrightCyan);
  FOutput.WriteLn('fafafa.core.term 主题系统演示');
  FOutput.WriteLn('============================');
  FOutput.ResetColors;
  FOutput.WriteLn;
  
  FOutput.WriteLn('当前主题: (无)');
  FOutput.WriteLn;
  
  FOutput.WriteLn('请选择演示项目:');
  FOutput.WriteLn;
  FOutput.WriteLn('1. 显示当前主题信息');
  FOutput.WriteLn('2. 预设主题演示');
  FOutput.WriteLn('3. 自定义主题演示');
  FOutput.WriteLn('4. 主题颜色演示');
  FOutput.WriteLn('5. 主题导出演示');
  FOutput.WriteLn('0. 退出');
  FOutput.WriteLn;
  FOutput.Write('请输入选择 (0-5): ');
end;

procedure TThemeDemo.ShowCurrentTheme;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('当前主题信息（简化）');
  FOutput.WriteLn('==================');
  FOutput.WriteLn;

  FOutput.WriteLn('主题系统尚未提供：这里展示基础颜色示例');
  FOutput.WriteLn;

  // 用固定 RGB 示例代替
  FOutput.Write('前景色示例: ');
  FOutput.SetForegroundColorRGB(MakeRGBColor(200, 200, 200));
  FOutput.Write('███');
  FOutput.ResetColors;
  FOutput.WriteLn(' #C8C8C8');

  FOutput.Write('强调色示例: ');
  FOutput.SetForegroundColorRGB(MakeRGBColor(0, 170, 255));
  FOutput.Write('███');
  FOutput.ResetColors;
  FOutput.WriteLn(' #00AAFF');

  FOutput.Write('成功色示例: ');
  FOutput.SetForegroundColorRGB(MakeRGBColor(80, 200, 120));
  FOutput.Write('███');
  FOutput.ResetColors;
  FOutput.WriteLn(' #50C878');

  FOutput.Write('警告色示例: ');
  FOutput.SetForegroundColorRGB(MakeRGBColor(255, 193, 7));
  FOutput.Write('███');
  FOutput.ResetColors;
  FOutput.WriteLn(' #FFC107');

  FOutput.Write('错误色示例: ');
  FOutput.SetForegroundColorRGB(MakeRGBColor(220, 53, 69));
  FOutput.Write('███');
  FOutput.ResetColors;
  FOutput.WriteLn(' #DC3545');

  WaitForKey;
end;

procedure TThemeDemo.DemoPresetThemes;
var
  LChoice: string;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('预设主题演示（简化）');
  FOutput.WriteLn('==================');
  FOutput.WriteLn;

  FOutput.WriteLn('当前版本未提供主题列表接口；展示固定两套配色预设：');
  FOutput.WriteLn('1. 亮色预设 (浅背景 深前景 + 青色强调)');
  FOutput.WriteLn('2. 暗色预设 (深背景 浅前景 + 橙色强调)');
  FOutput.WriteLn;

  FOutput.Write('请选择预设 (1-2): ');
  ReadLn(LChoice);

  case LChoice of
    '1': ShowThemePreview('Light Preset');
    '2': ShowThemePreview('Dark Preset');
  else
    FOutput.WriteLn('无效选择');
    WaitForKey;
  end;
end;

procedure TThemeDemo.DemoCustomTheme;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('自定义主题演示（简化）');
  FOutput.WriteLn('====================');
  FOutput.WriteLn;

  FOutput.WriteLn('当前版本未提供主题配置接口；展示模拟的“自定义主题”预览：');
  ShowThemePreview('My Custom Theme');
end;

procedure TThemeDemo.DemoThemeColors;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('主题颜色演示');
  FOutput.WriteLn('============');
  FOutput.WriteLn;
  
  // 固定配色演示（主题系统简化占位）
  FOutput.SetForegroundColorRGB(MakeRGBColor(0, 170, 255));
  FOutput.WriteLn('这是强调色文本');
  FOutput.ResetColors;

  FOutput.SetForegroundColorRGB(MakeRGBColor(80, 200, 120));
  FOutput.WriteLn('✓ 这是成功消息');
  FOutput.ResetColors;

  FOutput.SetForegroundColorRGB(MakeRGBColor(255, 193, 7));
  FOutput.WriteLn('⚠ 这是警告消息');
  FOutput.ResetColors;

  FOutput.SetForegroundColorRGB(MakeRGBColor(220, 53, 69));
  FOutput.WriteLn('✗ 这是错误消息');
  FOutput.ResetColors;

  FOutput.SetForegroundColorRGB(MakeRGBColor(150, 150, 150));
  FOutput.WriteLn('这是静音文本');
  FOutput.ResetColors;

  WaitForKey;
end;

procedure TThemeDemo.DemoThemeExport;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('主题导出演示（简化）');
  FOutput.WriteLn('==================');
  FOutput.WriteLn;

  FOutput.WriteLn('当前版本未提供主题导出接口');
  WaitForKey;
end;

procedure TThemeDemo.ShowThemePreview(const aThemeName: string);
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('主题预览: ' + aThemeName);
  FOutput.WriteLn('===================');
  FOutput.WriteLn;
  
  ApplyThemeToOutput;
  
  FOutput.WriteLn('这是主题预览界面');
  FOutput.WriteLn;
  
  // 显示各种颜色效果（基于固定配色）
  DemoThemeColors;
end;

procedure TThemeDemo.ApplyThemeToOutput;
begin
  // 主题系统简化：此处不从主题读取，使用默认前景色
  FOutput.ResetColors;
end;

procedure TThemeDemo.WaitForKey(const aPrompt: string = '按任意键继续...');
begin
  FOutput.WriteLn;
  FOutput.Write(aPrompt);
  FInput.ReadKey;
end;

procedure TThemeDemo.Run;
var
  LChoice: string;
begin
  FRunning := True;
  
  while FRunning do
  begin
    ShowMenu;
    ReadLn(LChoice);
    
    case LChoice of // 只使用简化演示项
      '1': ShowCurrentTheme;
      '2': DemoPresetThemes;
      '3': DemoCustomTheme;
      '4': DemoThemeColors;
      '5': DemoThemeExport; // 简化为说明文本
      '0': FRunning := False;
    else
      begin
        FOutput.WriteLn('无效选择，请重新输入');
        WaitForKey;
      end;
    end;
  end;
  
  FOutput.WriteLn('感谢使用主题系统演示！');
end;

var
  LDemo: TThemeDemo;

begin
  try
    LDemo := TThemeDemo.Create;
    try
      LDemo.Run;
    finally
      LDemo.Free;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('主题演示失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
