{$CODEPAGE UTF8}
program layout_demo;

{**
 * 布局系统演示
 *
 * 这个示例演示了如何使用 fafafa.core.term 的布局系统：
 * - 创建和管理面板
 * - 窗口分割和合并
 * - 布局切换
 * - 面板焦点管理
 * - 自定义面板绘制
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
   * 布局演示器
   *}
  TLayoutDemo = class
  private
    FTerminal: ITerminal;
    FOutput: ITerminalOutput;
    FInput: ITerminalInput;
    FLayout: ITerminalLayout;
    FRunning: Boolean;
    FPanelContents: TStringList;

    procedure ShowMenu;
    procedure DemoBasicLayout;
    procedure DemoSplitPanels;
    procedure DemoCustomPanels;
    procedure DemoLayoutSwitching;
    procedure ShowLayoutInfo;
    procedure DrawPanelContent(const aPanelId: string; aX, aY, aWidth, aHeight: Integer);
    procedure WaitForKey(const aPrompt: string = '按任意键继续...');
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure Run;
  end;

constructor TLayoutDemo.Create;
begin
  inherited Create;
  FTerminal := CreateTerminal;
  FOutput := FTerminal.Output;
  FInput := FTerminal.Input;
  FLayout := FTerminal.Layout;
  FRunning := False;
  FPanelContents := TStringList.Create;
end;

destructor TLayoutDemo.Destroy;
begin
  FPanelContents.Free;
  FTerminal := nil;
  inherited Destroy;
end;

procedure TLayoutDemo.ShowMenu;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.MoveCursor(0, 0);
  
  FOutput.SetForegroundColor(tcYellow);
  FOutput.WriteLn('fafafa.core.term 布局系统演示');
  FOutput.WriteLn('============================');
  FOutput.ResetColors;
  FOutput.WriteLn;
  
  FOutput.WriteLn('请选择演示项目:');
  FOutput.WriteLn;
  FOutput.WriteLn('1. 基本布局演示');
  FOutput.WriteLn('2. 面板分割演示');
  FOutput.WriteLn('3. 自定义面板演示');
  FOutput.WriteLn('4. 布局切换演示');
  FOutput.WriteLn('5. 显示布局信息');
  FOutput.WriteLn('0. 退出');
  FOutput.WriteLn;
  FOutput.Write('请输入选择 (0-5): ');
end;

procedure TLayoutDemo.DemoBasicLayout;
var
  LTermSize: TTerminalSize;
  LPanel1, LPanel2, LPanel3: string;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('基本布局演示');
  FOutput.WriteLn('============');
  FOutput.WriteLn;
  
  // 获取终端尺寸
  LTermSize := FTerminal.Info.GetSize;
  
  // 创建三个面板
  LPanel1 := FLayout.CreatePanel('panel1', '面板 1', MakeRect(2, 3, 25, 8));
  LPanel2 := FLayout.CreatePanel('panel2', '面板 2', MakeRect(30, 3, 25, 8));
  LPanel3 := FLayout.CreatePanel('panel3', '面板 3', MakeRect(2, 12, 53, 8));
  
  // 设置面板内容
  FPanelContents.Values[LPanel1] := '这是第一个面板的内容';
  FPanelContents.Values[LPanel2] := '这是第二个面板的内容';
  FPanelContents.Values[LPanel3] := '这是第三个面板的内容，占据底部区域';
  
  // 设置绘制回调
  FLayout.SetPanelDrawCallback(LPanel1, @DrawPanelContent);
  FLayout.SetPanelDrawCallback(LPanel2, @DrawPanelContent);
  FLayout.SetPanelDrawCallback(LPanel3, @DrawPanelContent);
  
  // 应用布局
  FLayout.ApplyLayout;
  
  FOutput.MoveCursor(0, LTermSize.Height - 2);
  WaitForKey;
  
  // 清理
  FLayout.DestroyPanel(LPanel1);
  FLayout.DestroyPanel(LPanel2);
  FLayout.DestroyPanel(LPanel3);
end;

procedure TLayoutDemo.DemoSplitPanels;
var
  LMainPanel, LSplitPanel1, LSplitPanel2: string;
  LTermSize: TTerminalSize;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('面板分割演示');
  FOutput.WriteLn('============');
  FOutput.WriteLn;
  
  LTermSize := FTerminal.Info.GetSize;
  
  // 创建主面板
  LMainPanel := FLayout.CreatePanel('main', '主面板', MakeRect(2, 3, LTermSize.Width - 4, LTermSize.Height - 6));
  FPanelContents.Values[LMainPanel] := '这是主面板，将被分割';
  FLayout.SetPanelDrawCallback(LMainPanel, @DrawPanelContent);
  
  FLayout.ApplyLayout;
  FOutput.MoveCursor(0, LTermSize.Height - 2);
  FOutput.Write('主面板已创建，按回车进行垂直分割...');
  ReadLn;
  
  // 垂直分割
  LSplitPanel1 := FLayout.SplitPanel(LMainPanel, ldVertical, 0.6);
  FPanelContents.Values[LMainPanel] := '上部面板（60%）';
  FPanelContents.Values[LSplitPanel1] := '下部面板（40%）';
  FLayout.SetPanelDrawCallback(LSplitPanel1, @DrawPanelContent);
  
  FLayout.ApplyLayout;
  FOutput.MoveCursor(0, LTermSize.Height - 2);
  FOutput.Write('垂直分割完成，按回车进行水平分割...');
  ReadLn;
  
  // 水平分割下部面板
  LSplitPanel2 := FLayout.SplitPanel(LSplitPanel1, ldHorizontal, 0.5);
  FPanelContents.Values[LSplitPanel1] := '左下面板';
  FPanelContents.Values[LSplitPanel2] := '右下面板';
  FLayout.SetPanelDrawCallback(LSplitPanel2, @DrawPanelContent);
  
  FLayout.ApplyLayout;
  FOutput.MoveCursor(0, LTermSize.Height - 2);
  WaitForKey;
  
  // 清理
  FLayout.DestroyPanel(LMainPanel);
  FLayout.DestroyPanel(LSplitPanel1);
  FLayout.DestroyPanel(LSplitPanel2);
end;

procedure TLayoutDemo.DemoCustomPanels;
var
  LPanel1, LPanel2: string;
  LTermSize: TTerminalSize;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('自定义面板演示');
  FOutput.WriteLn('==============');
  FOutput.WriteLn;
  
  LTermSize := FTerminal.Info.GetSize;
  
  // 创建带不同边框样式的面板
  LPanel1 := FLayout.CreatePanel('custom1', '单线边框', MakeRect(2, 3, 35, 10));
  var LConfig1 := FLayout.GetPanel(LPanel1);
  LConfig1.BorderStyle := bsSingle;
  FLayout.SetPanel(LConfig1);
  
  LPanel2 := FLayout.CreatePanel('custom2', '双线边框', MakeRect(40, 3, 35, 10));
  var LConfig2 := FLayout.GetPanel(LPanel2);
  LConfig2.BorderStyle := bsDouble;
  FLayout.SetPanel(LConfig2);
  
  // 设置内容
  FPanelContents.Values[LPanel1] := '这个面板使用单线边框';
  FPanelContents.Values[LPanel2] := '这个面板使用双线边框';
  
  FLayout.SetPanelDrawCallback(LPanel1, @DrawPanelContent);
  FLayout.SetPanelDrawCallback(LPanel2, @DrawPanelContent);
  
  FLayout.ApplyLayout;
  
  FOutput.MoveCursor(0, 15);
  FOutput.WriteLn('演示面板焦点切换...');
  
  // 演示焦点切换
  FLayout.FocusPanel(LPanel1);
  FOutput.MoveCursor(0, 16);
  FOutput.Write('当前焦点: ' + LPanel1 + ' (3秒后切换)');
  Sleep(3000);
  
  FLayout.FocusPanel(LPanel2);
  FOutput.MoveCursor(0, 16);
  FOutput.Write('当前焦点: ' + LPanel2 + '                    ');
  
  FOutput.MoveCursor(0, LTermSize.Height - 2);
  WaitForKey;
  
  // 清理
  FLayout.DestroyPanel(LPanel1);
  FLayout.DestroyPanel(LPanel2);
end;

procedure TLayoutDemo.DemoLayoutSwitching;
var
  LLayouts: array of string;
  I: Integer;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('布局切换演示');
  FOutput.WriteLn('============');
  FOutput.WriteLn;
  
  LLayouts := FLayout.GetAvailableLayouts;
  
  FOutput.WriteLn('可用布局:');
  for I := 0 to High(LLayouts) do
    FOutput.WriteLn(Format('%d. %s', [I + 1, LLayouts[I]]));
  FOutput.WriteLn;
  
  // 演示每种布局
  for I := 0 to High(LLayouts) do
  begin
    FOutput.WriteLn('切换到布局: ' + LLayouts[I]);
    FLayout.SetLayout(LLayouts[I]);
    
    // 创建示例面板
    var LPanel := FLayout.CreatePanel('demo', '演示面板', MakeRect(5, 8, 30, 8));
    FPanelContents.Values[LPanel] := '当前布局: ' + LLayouts[I];
    FLayout.SetPanelDrawCallback(LPanel, @DrawPanelContent);
    
    FLayout.ApplyLayout;
    Sleep(2000);
    
    FLayout.DestroyPanel(LPanel);
  end;
  
  WaitForKey;
end;

procedure TLayoutDemo.ShowLayoutInfo;
var
  LLayout: TLayoutConfig;
  LPanels: array of string;
  I: Integer;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('布局信息');
  FOutput.WriteLn('========');
  FOutput.WriteLn;
  
  LLayout := FLayout.GetCurrentLayout;
  LPanels := FLayout.GetPanelList;
  
  FOutput.WriteLn('当前布局信息:');
  FOutput.WriteLn('  名称: ' + LLayout.Name);
  FOutput.WriteLn('  方向: ' + case LLayout.Direction of
    ldHorizontal: 'Horizontal';
    ldVertical: 'Vertical';
  end);
  FOutput.WriteLn('  面板数量: ' + IntToStr(Length(LLayout.Panels)));
  FOutput.WriteLn('  间距: ' + IntToStr(LLayout.Spacing));
  FOutput.WriteLn('  自动调整: ' + BoolToStr(LLayout.AutoResize, '是', '否'));
  FOutput.WriteLn;
  
  FOutput.WriteLn('面板列表:');
  for I := 0 to High(LPanels) do
  begin
    try
      var LPanel := FLayout.GetPanel(LPanels[I]);
      FOutput.WriteLn(Format('  %s: %s (%dx%d at %d,%d)', [
        LPanel.Id,
        LPanel.Title,
        LPanel.Bounds.Width,
        LPanel.Bounds.Height,
        LPanel.Bounds.X,
        LPanel.Bounds.Y
      ]));
    except
      FOutput.WriteLn('  ' + LPanels[I] + ': (信息获取失败)');
    end;
  end;
  
  WaitForKey;
end;

procedure TLayoutDemo.DrawPanelContent(const aPanelId: string; aX, aY, aWidth, aHeight: Integer);
var
  LContent: string;
  LLines: TStringList;
  I: Integer;
begin
  LContent := FPanelContents.Values[aPanelId];
  if LContent = '' then
    LContent := '面板内容: ' + aPanelId;
    
  LLines := TStringList.Create;
  try
    // 简单的文本换行
    LLines.Add(LContent);
    LLines.Add('');
    LLines.Add('尺寸: ' + IntToStr(aWidth) + 'x' + IntToStr(aHeight));
    LLines.Add('位置: (' + IntToStr(aX) + ',' + IntToStr(aY) + ')');
    LLines.Add('时间: ' + FormatDateTime('hh:nn:ss', Now));
    
    // 绘制内容
    for I := 0 to Min(LLines.Count - 1, aHeight - 1) do
    begin
      if I < LLines.Count then
      begin
        FOutput.MoveCursor(aX, aY + I);
        var LLine := LLines[I];
        if Length(LLine) > aWidth then
          LLine := Copy(LLine, 1, aWidth);
        FOutput.Write(LLine);
      end;
    end;
    
  finally
    LLines.Free;
  end;
end;

procedure TLayoutDemo.WaitForKey(const aPrompt: string = '按任意键继续...');
begin
  FOutput.Write(aPrompt);
  ReadLn;
end;

procedure TLayoutDemo.Run;
var
  LChoice: string;
begin
  FRunning := True;
  
  while FRunning do
  begin
    ShowMenu;
    ReadLn(LChoice);
    
    case LChoice of
      '1': DemoBasicLayout;
      '2': DemoSplitPanels;
      '3': DemoCustomPanels;
      '4': DemoLayoutSwitching;
      '5': ShowLayoutInfo;
      '0': FRunning := False;
    else
      begin
        FOutput.WriteLn('无效选择，请重新输入');
        WaitForKey;
      end;
    end;
  end;
  
  FOutput.WriteLn('感谢使用布局系统演示！');
end;

var
  LDemo: TLayoutDemo;

begin
  try
    LDemo := TLayoutDemo.Create;
    try
      LDemo.Run;
    finally
      LDemo.Free;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('布局演示失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
