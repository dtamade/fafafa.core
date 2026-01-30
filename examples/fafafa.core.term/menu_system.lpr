{$CODEPAGE UTF8}
program menu_system;

{**
 * 菜单系统示例
 *
 * 这个示例演示了如何创建交互式菜单系统：
 * - 主菜单和子菜单
 * - 键盘导航
 * - 菜单项选择和执行
 * - 动态菜单更新
 * - 上下文菜单
 * - 菜单主题和样式
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
   * 菜单项类型
   *}
  TMenuItemType = (
    mitAction,    // 执行动作
    mitSubmenu,   // 子菜单
    mitSeparator, // 分隔符
    mitToggle,    // 开关项
    mitRadio      // 单选项
  );

  {**
   * 菜单项动作回调
   *}
  TMenuAction = procedure of object;

  {**
   * 菜单项
   *}
  TMenuItem = class
  private
    FText: string;
    FItemType: TMenuItemType;
    FAction: TMenuAction;
    FSubmenu: TMenu;
    FEnabled: Boolean;
    FChecked: Boolean;
    FShortcut: string;
    FTag: Integer;
  public
    constructor Create(const aText: string; aItemType: TMenuItemType = mitAction);
    destructor Destroy; override;
    
    property Text: string read FText write FText;
    property ItemType: TMenuItemType read FItemType write FItemType;
    property Action: TMenuAction read FAction write FAction;
    property Submenu: TMenu read FSubmenu write FSubmenu;
    property Enabled: Boolean read FEnabled write FEnabled;
    property Checked: Boolean read FChecked write FChecked;
    property Shortcut: string read FShortcut write FShortcut;
    property Tag: Integer read FTag write FTag;
  end;

  {**
   * 菜单类
   *}
  TMenu = class
  private
    FItems: TList;
    FTitle: string;
    FSelectedIndex: Integer;
    FVisible: Boolean;
    FX, FY: Integer;
    FWidth: Integer;
    FParentMenu: TMenu;

    function GetItem(aIndex: Integer): TMenuItem;
    function GetItemCount: Integer;
    procedure CalculateWidth;
  public
    constructor Create(const aTitle: string = '');
    destructor Destroy; override;
    
    procedure AddItem(aItem: TMenuItem);
    procedure AddAction(const aText: string; aAction: TMenuAction; const aShortcut: string = '');
    procedure AddSubmenu(const aText: string; aSubmenu: TMenu);
    procedure AddSeparator;
    procedure AddToggle(const aText: string; aAction: TMenuAction; aChecked: Boolean = False);
    
    procedure SetPosition(aX, aY: Integer);
    procedure Show(aOutput: ITerminalOutput);
    procedure Hide(aOutput: ITerminalOutput);
    procedure SelectNext;
    procedure SelectPrevious;
    function ExecuteSelected: TMenu; // 返回要显示的下一个菜单
    
    property Items[aIndex: Integer]: TMenuItem read GetItem;
    property ItemCount: Integer read GetItemCount;
    property Title: string read FTitle write FTitle;
    property SelectedIndex: Integer read FSelectedIndex write FSelectedIndex;
    property Visible: Boolean read FVisible;
    property ParentMenu: TMenu read FParentMenu write FParentMenu;
  end;

  {**
   * 菜单系统
   *}
  TMenuSystem = class
  private
    FTerminal: ITerminal;
    FOutput: ITerminalOutput;
    FInput: ITerminalInput;
    FMainMenu: TMenu;
    FCurrentMenu: TMenu;
    FMenuStack: TList;
    FRunning: Boolean;

    procedure InitializeMenus;
    procedure ProcessInput;
    procedure ShowCurrentMenu;
    procedure PushMenu(aMenu: TMenu);
    procedure PopMenu;
    
    // 菜单动作
    procedure ActionNewFile;
    procedure ActionOpenFile;
    procedure ActionSaveFile;
    procedure ActionExit;
    procedure ActionAbout;
    procedure ActionSettings;
    procedure ActionToggleOption;
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure Run;
  end;

// TMenuItem 实现

constructor TMenuItem.Create(const aText: string; aItemType: TMenuItemType = mitAction);
begin
  inherited Create;
  FText := aText;
  FItemType := aItemType;
  FAction := nil;
  FSubmenu := nil;
  FEnabled := True;
  FChecked := False;
  FShortcut := '';
  FTag := 0;
end;

destructor TMenuItem.Destroy;
begin
  // 注意：不要释放 FSubmenu，因为它可能被其他地方引用
  inherited Destroy;
end;

// TMenu 实现

constructor TMenu.Create(const aTitle: string = '');
begin
  inherited Create;
  FItems := TList.Create;
  FTitle := aTitle;
  FSelectedIndex := 0;
  FVisible := False;
  FX := 0;
  FY := 0;
  FWidth := 0;
  FParentMenu := nil;
end;

destructor TMenu.Destroy;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    TMenuItem(FItems[I]).Free;
  FItems.Free;
  inherited Destroy;
end;

function TMenu.GetItem(aIndex: Integer): TMenuItem;
begin
  if (aIndex >= 0) and (aIndex < FItems.Count) then
    Result := TMenuItem(FItems[aIndex])
  else
    Result := nil;
end;

function TMenu.GetItemCount: Integer;
begin
  Result := FItems.Count;
end;

procedure TMenu.CalculateWidth;
var
  I: Integer;
  LItem: TMenuItem;
  LItemWidth: Integer;
begin
  FWidth := Length(FTitle) + 4;
  
  for I := 0 to FItems.Count - 1 do
  begin
    LItem := TMenuItem(FItems[I]);
    if LItem.ItemType = mitSeparator then
      LItemWidth := 10
    else
    begin
      LItemWidth := Length(LItem.Text) + 4;
      if LItem.Shortcut <> '' then
        LItemWidth := LItemWidth + Length(LItem.Shortcut) + 3;
    end;
    
    if LItemWidth > FWidth then
      FWidth := LItemWidth;
  end;
  
  if FWidth < 20 then
    FWidth := 20;
end;

procedure TMenu.AddItem(aItem: TMenuItem);
begin
  FItems.Add(aItem);
  CalculateWidth;
end;

procedure TMenu.AddAction(const aText: string; aAction: TMenuAction; const aShortcut: string = '');
var
  LItem: TMenuItem;
begin
  LItem := TMenuItem.Create(aText, mitAction);
  LItem.Action := aAction;
  LItem.Shortcut := aShortcut;
  AddItem(LItem);
end;

procedure TMenu.AddSubmenu(const aText: string; aSubmenu: TMenu);
var
  LItem: TMenuItem;
begin
  LItem := TMenuItem.Create(aText, mitSubmenu);
  LItem.Submenu := aSubmenu;
  aSubmenu.ParentMenu := Self;
  AddItem(LItem);
end;

procedure TMenu.AddSeparator;
var
  LItem: TMenuItem;
begin
  LItem := TMenuItem.Create('', mitSeparator);
  AddItem(LItem);
end;

procedure TMenu.AddToggle(const aText: string; aAction: TMenuAction; aChecked: Boolean = False);
var
  LItem: TMenuItem;
begin
  LItem := TMenuItem.Create(aText, mitToggle);
  LItem.Action := aAction;
  LItem.Checked := aChecked;
  AddItem(LItem);
end;

procedure TMenu.SetPosition(aX, aY: Integer);
begin
  FX := aX;
  FY := aY;
end;

procedure TMenu.Show(aOutput: ITerminalOutput);
var
  I: Integer;
  LItem: TMenuItem;
  LItemText: string;
  LY: Integer;
begin
  if FVisible then
    Exit;
    
  CalculateWidth;
  
  // 绘制菜单边框和标题
  aOutput.MoveCursor(FX, FY);
  aOutput.SetForegroundColor(tcWhite);
  aOutput.SetBackgroundColor(tcBlue);
  aOutput.Write('┌' + StringOfChar('─', FWidth - 2) + '┐');
  
  if FTitle <> '' then
  begin
    aOutput.MoveCursor(FX, FY + 1);
    aOutput.Write('│ ' + FTitle + StringOfChar(' ', FWidth - Length(FTitle) - 3) + '│');
    aOutput.MoveCursor(FX, FY + 2);
    aOutput.Write('├' + StringOfChar('─', FWidth - 2) + '┤');
    LY := FY + 3;
  end
  else
    LY := FY + 1;
  
  // 绘制菜单项
  for I := 0 to FItems.Count - 1 do
  begin
    LItem := TMenuItem(FItems[I]);
    aOutput.MoveCursor(FX, LY + I);
    
    if I = FSelectedIndex then
    begin
      aOutput.SetForegroundColor(tcBlack);
      aOutput.SetBackgroundColor(tcWhite);
    end
    else
    begin
      aOutput.SetForegroundColor(tcWhite);
      aOutput.SetBackgroundColor(tcBlue);
    end;
    
    if LItem.ItemType = mitSeparator then
    begin
      aOutput.Write('├' + StringOfChar('─', FWidth - 2) + '┤');
    end
    else
    begin
      LItemText := '│ ';
      
      if LItem.ItemType = mitToggle then
      begin
        if LItem.Checked then
          LItemText := LItemText + '[✓] '
        else
          LItemText := LItemText + '[ ] ';
      end;
      
      LItemText := LItemText + LItem.Text;
      
      if LItem.Shortcut <> '' then
      begin
        LItemText := LItemText + StringOfChar(' ', FWidth - Length(LItemText) - Length(LItem.Shortcut) - 3);
        LItemText := LItemText + LItem.Shortcut;
      end
      else
        LItemText := LItemText + StringOfChar(' ', FWidth - Length(LItemText) - 1);
      
      LItemText := LItemText + '│';
      aOutput.Write(LItemText);
    end;
  end;
  
  // 绘制底部边框
  aOutput.MoveCursor(FX, LY + FItems.Count);
  aOutput.Write('└' + StringOfChar('─', FWidth - 2) + '┘');
  
  aOutput.ResetColors;
  FVisible := True;
end;

procedure TMenu.Hide(aOutput: ITerminalOutput);
var
  I: Integer;
  LHeight: Integer;
begin
  if not FVisible then
    Exit;
    
  LHeight := FItems.Count + 3;
  if FTitle <> '' then
    Inc(LHeight, 2);
    
  for I := 0 to LHeight do
  begin
    aOutput.MoveCursor(FX, FY + I);
    aOutput.Write(StringOfChar(' ', FWidth));
  end;
  
  FVisible := False;
end;

procedure TMenu.SelectNext;
begin
  repeat
    FSelectedIndex := (FSelectedIndex + 1) mod FItems.Count;
  until (Items[FSelectedIndex].ItemType <> mitSeparator) or (FItems.Count = 1);
end;

procedure TMenu.SelectPrevious;
begin
  repeat
    Dec(FSelectedIndex);
    if FSelectedIndex < 0 then
      FSelectedIndex := FItems.Count - 1;
  until (Items[FSelectedIndex].ItemType <> mitSeparator) or (FItems.Count = 1);
end;

function TMenu.ExecuteSelected: TMenu;
var
  LItem: TMenuItem;
begin
  Result := nil;
  
  if (FSelectedIndex >= 0) and (FSelectedIndex < FItems.Count) then
  begin
    LItem := Items[FSelectedIndex];
    
    if not LItem.Enabled then
      Exit;
      
    case LItem.ItemType of
      mitAction:
      begin
        if Assigned(LItem.Action) then
          LItem.Action();
      end;
      
      mitSubmenu:
      begin
        if Assigned(LItem.Submenu) then
          Result := LItem.Submenu;
      end;
      
      mitToggle:
      begin
        LItem.Checked := not LItem.Checked;
        if Assigned(LItem.Action) then
          LItem.Action();
      end;
    end;
  end;
end;

// TMenuSystem 实现

constructor TMenuSystem.Create;
begin
  inherited Create;
  FTerminal := CreateTerminal;
  FOutput := FTerminal.Output;
  FInput := FTerminal.Input;
  FMenuStack := TList.Create;
  FRunning := False;
  
  InitializeMenus;
end;

destructor TMenuSystem.Destroy;
begin
  FMenuStack.Free;
  FMainMenu.Free;
  inherited Destroy;
end;

procedure TMenuSystem.InitializeMenus;
var
  LFileMenu, LEditMenu, LHelpMenu: TMenu;
begin
  // 创建主菜单
  FMainMenu := TMenu.Create('主菜单');
  
  // 文件菜单
  LFileMenu := TMenu.Create('文件');
  LFileMenu.AddAction('新建', @ActionNewFile, 'Ctrl+N');
  LFileMenu.AddAction('打开', @ActionOpenFile, 'Ctrl+O');
  LFileMenu.AddAction('保存', @ActionSaveFile, 'Ctrl+S');
  LFileMenu.AddSeparator;
  LFileMenu.AddAction('退出', @ActionExit, 'Ctrl+Q');
  
  // 编辑菜单
  LEditMenu := TMenu.Create('编辑');
  LEditMenu.AddAction('设置', @ActionSettings);
  LEditMenu.AddToggle('自动保存', @ActionToggleOption, False);
  LEditMenu.AddToggle('显示行号', @ActionToggleOption, True);
  
  // 帮助菜单
  LHelpMenu := TMenu.Create('帮助');
  LHelpMenu.AddAction('关于', @ActionAbout);
  
  // 添加到主菜单
  FMainMenu.AddSubmenu('文件', LFileMenu);
  FMainMenu.AddSubmenu('编辑', LEditMenu);
  FMainMenu.AddSubmenu('帮助', LHelpMenu);
  FMainMenu.AddSeparator;
  FMainMenu.AddAction('退出', @ActionExit);
  
  FCurrentMenu := FMainMenu;
end;

procedure TMenuSystem.ProcessInput;
var
  LKeyEvent: TKeyEvent;
  LNextMenu: TMenu;
begin
  LKeyEvent := FInput.ReadKey;
  
  case LKeyEvent.KeyType of
    ktArrowUp:
      FCurrentMenu.SelectPrevious;
      
    ktArrowDown:
      FCurrentMenu.SelectNext;
      
    ktEnter:
    begin
      LNextMenu := FCurrentMenu.ExecuteSelected;
      if Assigned(LNextMenu) then
        PushMenu(LNextMenu);
    end;
    
    ktEscape:
    begin
      if FMenuStack.Count > 0 then
        PopMenu
      else
        FRunning := False;
    end;
    
    ktBackspace:
    begin
      if FMenuStack.Count > 0 then
        PopMenu;
    end;
  end;
end;

procedure TMenuSystem.ShowCurrentMenu;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.MoveCursor(0, 0);
  
  FOutput.SetForegroundColor(tcYellow);
  FOutput.WriteLn('菜单系统演示 - 使用方向键导航，回车选择，ESC返回');
  FOutput.ResetColors;
  FOutput.WriteLn;
  
  FCurrentMenu.SetPosition(5, 3);
  FCurrentMenu.Show(FOutput);
end;

procedure TMenuSystem.PushMenu(aMenu: TMenu);
begin
  FCurrentMenu.Hide(FOutput);
  FMenuStack.Add(FCurrentMenu);
  FCurrentMenu := aMenu;
end;

procedure TMenuSystem.PopMenu;
begin
  if FMenuStack.Count > 0 then
  begin
    FCurrentMenu.Hide(FOutput);
    FCurrentMenu := TMenu(FMenuStack[FMenuStack.Count - 1]);
    FMenuStack.Delete(FMenuStack.Count - 1);
  end;
end;

procedure TMenuSystem.ActionNewFile;
begin
  FOutput.MoveCursor(0, 20);
  FOutput.SetForegroundColor(tcGreen);
  FOutput.WriteLn('执行：新建文件');
  FOutput.ResetColors;
  Sleep(1000);
end;

procedure TMenuSystem.ActionOpenFile;
begin
  FOutput.MoveCursor(0, 20);
  FOutput.SetForegroundColor(tcGreen);
  FOutput.WriteLn('执行：打开文件');
  FOutput.ResetColors;
  Sleep(1000);
end;

procedure TMenuSystem.ActionSaveFile;
begin
  FOutput.MoveCursor(0, 20);
  FOutput.SetForegroundColor(tcGreen);
  FOutput.WriteLn('执行：保存文件');
  FOutput.ResetColors;
  Sleep(1000);
end;

procedure TMenuSystem.ActionExit;
begin
  FRunning := False;
end;

procedure TMenuSystem.ActionAbout;
begin
  FOutput.MoveCursor(0, 20);
  FOutput.SetForegroundColor(tcCyan);
  FOutput.WriteLn('关于：fafafa.core.term 菜单系统演示 v1.0');
  FOutput.ResetColors;
  Sleep(2000);
end;

procedure TMenuSystem.ActionSettings;
begin
  FOutput.MoveCursor(0, 20);
  FOutput.SetForegroundColor(tcYellow);
  FOutput.WriteLn('打开设置对话框...');
  FOutput.ResetColors;
  Sleep(1000);
end;

procedure TMenuSystem.ActionToggleOption;
begin
  FOutput.MoveCursor(0, 20);
  FOutput.SetForegroundColor(tcMagenta);
  FOutput.WriteLn('切换选项状态');
  FOutput.ResetColors;
  Sleep(500);
end;

procedure TMenuSystem.Run;
begin
  try
    FTerminal.EnterRawMode;
    FRunning := True;
    
    while FRunning do
    begin
      ShowCurrentMenu;
      ProcessInput;
    end;
    
  finally
    FTerminal.LeaveRawMode;
    FOutput.ClearScreen(tctAll);
    FOutput.MoveCursor(0, 0);
    WriteLn('菜单系统演示结束！');
  end;
end;

var
  LMenuSystem: TMenuSystem;

begin
  try
    LMenuSystem := TMenuSystem.Create;
    try
      LMenuSystem.Run;
    finally
      LMenuSystem.Free;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('菜单系统错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
