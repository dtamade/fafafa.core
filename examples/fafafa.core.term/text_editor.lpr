{$CODEPAGE UTF8}
program text_editor;

{**
 * 简单文本编辑器示例
 *
 * 这个示例演示了如何使用 fafafa.core.term 创建一个功能完整的文本编辑器：
 * - 多行文本编辑
 * - 光标控制和导航
 * - 文件加载和保存
 * - 状态栏显示
 * - 键盘快捷键
 * - 语法高亮（简单）
 *}

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, StrUtils,
  fafafa.core.base, fafafa.core.term;

type
  {**
   * 简单文本编辑器
   *}
  TTextEditor = class
  private
    FTerminal: ITerminal;
    FOutput: ITerminalOutput;
    FInput: ITerminalInput;
    FLines: TStringList;
    FCursorX, FCursorY: Integer;
    FScrollY: Integer;
    FFileName: string;
    FModified: Boolean;
    FTerminalSize: TTerminalSize;
    FRunning: Boolean;

    procedure InitializeEditor;
    procedure FinalizeEditor;
    procedure UpdateDisplay;
    procedure DrawStatusBar;
    procedure DrawLineNumbers;
    procedure DrawContent;
    procedure ProcessKey(const aKeyEvent: TKeyEvent);
    procedure MoveCursor(aDeltaX, aDeltaY: Integer);
    procedure InsertChar(aChar: Char);
    procedure DeleteChar;
    procedure InsertLine;
    procedure DeleteLine;
    procedure LoadFile(const aFileName: string);
    procedure SaveFile;
    procedure ShowHelp;
    function GetCurrentLine: string;
    procedure SetCurrentLine(const aLine: string);
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure Run(const aFileName: string = '');
  end;

constructor TTextEditor.Create;
begin
  inherited Create;
  FTerminal := CreateTerminal;
  FOutput := FTerminal.Output;
  FInput := FTerminal.Input;
  FLines := TStringList.Create;
  FCursorX := 0;
  FCursorY := 0;
  FScrollY := 0;
  FFileName := '';
  FModified := False;
  FRunning := False;
end;

destructor TTextEditor.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

procedure TTextEditor.InitializeEditor;
begin
  FTerminalSize := FTerminal.Info.Size;
  FTerminal.EnterRawMode;
  FOutput.ClearScreen(tctAll);
  FOutput.HideCursor;
  
  // 如果没有内容，添加一个空行
  if FLines.Count = 0 then
    FLines.Add('');
end;

procedure TTextEditor.FinalizeEditor;
begin
  FOutput.ShowCursor;
  FOutput.ResetColors;
  FOutput.ClearScreen(tctAll);
  FOutput.MoveCursor(0, 0);
  FTerminal.LeaveRawMode;
end;

procedure TTextEditor.UpdateDisplay;
begin
  FOutput.MoveCursor(0, 0);
  DrawContent;
  DrawStatusBar;
  
  // 显示光标
  FOutput.MoveCursor(FCursorX + 4, FCursorY - FScrollY); // +4 for line numbers
  FOutput.ShowCursor;
end;

procedure TTextEditor.DrawStatusBar;
var
  LStatusText: string;
  LPadding: string;
begin
  // 移动到最后一行
  FOutput.MoveCursor(0, FTerminalSize.Height - 1);
  
  // 设置状态栏颜色
  FOutput.SetBackgroundColor(tcBlue);
  FOutput.SetForegroundColor(tcWhite);
  
  // 构建状态文本
  LStatusText := Format(' %s %s | Line: %d, Col: %d | Ctrl+S: Save, Ctrl+Q: Quit, F1: Help ',
    [IfThen(FFileName <> '', ExtractFileName(FFileName), 'Untitled'),
     IfThen(FModified, '[Modified]', ''),
     FCursorY + 1,
     FCursorX + 1]);
  
  // 填充到终端宽度
  if Length(LStatusText) < FTerminalSize.Width then
  begin
    LPadding := StringOfChar(' ', FTerminalSize.Width - Length(LStatusText));
    LStatusText := LStatusText + LPadding;
  end
  else
    LStatusText := Copy(LStatusText, 1, FTerminalSize.Width);
  
  FOutput.Write(LStatusText);
  FOutput.ResetColors;
end;

procedure TTextEditor.DrawLineNumbers;
var
  I: Integer;
  LLineNum: string;
begin
  for I := 0 to FTerminalSize.Height - 3 do // -2 for status bar, -1 for 0-based
  begin
    FOutput.MoveCursor(0, I);
    
    if (FScrollY + I) < FLines.Count then
    begin
      LLineNum := Format('%3d ', [FScrollY + I + 1]);
      FOutput.SetForegroundColor(tcCyan);
      FOutput.Write(LLineNum);
      FOutput.ResetColors;
    end
    else
    begin
      FOutput.Write('    ');
    end;
  end;
end;

procedure TTextEditor.DrawContent;
var
  I: Integer;
  LLine: string;
  LDisplayLine: string;
begin
  // 清除内容区域
  for I := 0 to FTerminalSize.Height - 2 do
  begin
    FOutput.MoveCursor(0, I);
    FOutput.Write(StringOfChar(' ', FTerminalSize.Width));
  end;
  
  // 绘制行号
  DrawLineNumbers;
  
  // 绘制内容
  for I := 0 to FTerminalSize.Height - 3 do
  begin
    if (FScrollY + I) < FLines.Count then
    begin
      LLine := FLines[FScrollY + I];
      
      // 截断或填充行内容
      if Length(LLine) > FTerminalSize.Width - 4 then
        LDisplayLine := Copy(LLine, 1, FTerminalSize.Width - 4)
      else
        LDisplayLine := LLine;
      
      FOutput.MoveCursor(4, I);
      FOutput.Write(LDisplayLine);
    end;
  end;
end;

procedure TTextEditor.ProcessKey(const aKeyEvent: TKeyEvent);
begin
  case aKeyEvent.KeyType of
    ktChar:
    begin
      if kmCtrl in aKeyEvent.Modifiers then
      begin
        case UpCase(aKeyEvent.KeyChar) of
          'Q': FRunning := False; // Quit
          'S': SaveFile;          // Save
          'H': ShowHelp;          // Help
        end;
      end
      else
        InsertChar(aKeyEvent.KeyChar);
    end;
    
    ktF1: ShowHelp;
    ktEscape: FRunning := False;
    ktEnter: InsertLine;
    ktBackspace: DeleteChar;
    ktDelete: DeleteChar;
    
    ktArrowUp: MoveCursor(0, -1);
    ktArrowDown: MoveCursor(0, 1);
    ktArrowLeft: MoveCursor(-1, 0);
    ktArrowRight: MoveCursor(1, 0);
    
    ktHome: FCursorX := 0;
    ktEnd: FCursorX := Length(GetCurrentLine);
    
    ktPageUp: MoveCursor(0, -(FTerminalSize.Height div 2));
    ktPageDown: MoveCursor(0, FTerminalSize.Height div 2);
  end;
end;

procedure TTextEditor.MoveCursor(aDeltaX, aDeltaY: Integer);
var
  LNewX, LNewY: Integer;
begin
  LNewX := FCursorX + aDeltaX;
  LNewY := FCursorY + aDeltaY;
  
  // 限制Y坐标
  if LNewY < 0 then
    LNewY := 0
  else if LNewY >= FLines.Count then
    LNewY := FLines.Count - 1;
  
  FCursorY := LNewY;
  
  // 限制X坐标
  if LNewX < 0 then
    LNewX := 0
  else if LNewX > Length(GetCurrentLine) then
    LNewX := Length(GetCurrentLine);
  
  FCursorX := LNewX;
  
  // 调整滚动
  if FCursorY < FScrollY then
    FScrollY := FCursorY
  else if FCursorY >= FScrollY + FTerminalSize.Height - 2 then
    FScrollY := FCursorY - FTerminalSize.Height + 3;
end;

procedure TTextEditor.InsertChar(aChar: Char);
var
  LLine: string;
begin
  LLine := GetCurrentLine;
  Insert(aChar, LLine, FCursorX + 1);
  SetCurrentLine(LLine);
  Inc(FCursorX);
  FModified := True;
end;

procedure TTextEditor.DeleteChar;
var
  LLine: string;
begin
  if FCursorX > 0 then
  begin
    LLine := GetCurrentLine;
    Delete(LLine, FCursorX, 1);
    SetCurrentLine(LLine);
    Dec(FCursorX);
    FModified := True;
  end
  else if FCursorY > 0 then
  begin
    // 合并到上一行
    FCursorX := Length(FLines[FCursorY - 1]);
    FLines[FCursorY - 1] := FLines[FCursorY - 1] + GetCurrentLine;
    FLines.Delete(FCursorY);
    Dec(FCursorY);
    FModified := True;
  end;
end;

procedure TTextEditor.InsertLine;
var
  LLine: string;
  LNewLine: string;
begin
  LLine := GetCurrentLine;
  LNewLine := Copy(LLine, FCursorX + 1, Length(LLine));
  SetCurrentLine(Copy(LLine, 1, FCursorX));
  
  Inc(FCursorY);
  FLines.Insert(FCursorY, LNewLine);
  FCursorX := 0;
  FModified := True;
end;

procedure TTextEditor.DeleteLine;
begin
  if FLines.Count > 1 then
  begin
    FLines.Delete(FCursorY);
    if FCursorY >= FLines.Count then
      FCursorY := FLines.Count - 1;
    FCursorX := 0;
    FModified := True;
  end;
end;

procedure TTextEditor.LoadFile(const aFileName: string);
begin
  if FileExists(aFileName) then
  begin
    FLines.LoadFromFile(aFileName);
    FFileName := aFileName;
    FModified := False;
    FCursorX := 0;
    FCursorY := 0;
    FScrollY := 0;
  end
  else
  begin
    FLines.Clear;
    FLines.Add('');
    FFileName := aFileName;
    FModified := False;
  end;
end;

procedure TTextEditor.SaveFile;
begin
  if FFileName = '' then
    FFileName := 'untitled.txt';
    
  try
    FLines.SaveToFile(FFileName);
    FModified := False;
  except
    on E: Exception do
    begin
      // 显示错误信息
      FOutput.MoveCursor(0, FTerminalSize.Height - 2);
      FOutput.SetForegroundColor(tcRed);
      FOutput.Write('Error saving file: ' + E.Message);
      FOutput.ResetColors;
      Sleep(2000);
    end;
  end;
end;

procedure TTextEditor.ShowHelp;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.MoveCursor(0, 0);
  
  FOutput.SetForegroundColor(tcYellow);
  FOutput.WriteLn('Simple Text Editor - Help');
  FOutput.WriteLn('========================');
  FOutput.ResetColors;
  FOutput.WriteLn;
  FOutput.WriteLn('Navigation:');
  FOutput.WriteLn('  Arrow Keys  - Move cursor');
  FOutput.WriteLn('  Home/End    - Beginning/End of line');
  FOutput.WriteLn('  Page Up/Dn  - Scroll up/down');
  FOutput.WriteLn;
  FOutput.WriteLn('Editing:');
  FOutput.WriteLn('  Type        - Insert text');
  FOutput.WriteLn('  Enter       - New line');
  FOutput.WriteLn('  Backspace   - Delete character');
  FOutput.WriteLn;
  FOutput.WriteLn('Commands:');
  FOutput.WriteLn('  Ctrl+S      - Save file');
  FOutput.WriteLn('  Ctrl+Q      - Quit');
  FOutput.WriteLn('  F1          - Show this help');
  FOutput.WriteLn('  Esc         - Quit');
  FOutput.WriteLn;
  FOutput.WriteLn('Press any key to continue...');
  
  FInput.ReadKey;
end;

function TTextEditor.GetCurrentLine: string;
begin
  if (FCursorY >= 0) and (FCursorY < FLines.Count) then
    Result := FLines[FCursorY]
  else
    Result := '';
end;

procedure TTextEditor.SetCurrentLine(const aLine: string);
begin
  if (FCursorY >= 0) and (FCursorY < FLines.Count) then
    FLines[FCursorY] := aLine;
end;

procedure TTextEditor.Run(const aFileName: string = '');
var
  LKeyEvent: TKeyEvent;
begin
  try
    if aFileName <> '' then
      LoadFile(aFileName);
      
    InitializeEditor;
    FRunning := True;
    
    while FRunning do
    begin
      UpdateDisplay;
      
      try
        LKeyEvent := FInput.ReadKey;
        ProcessKey(LKeyEvent);
      except
        on E: Exception do
        begin
          // 显示错误并继续
          FOutput.MoveCursor(0, FTerminalSize.Height - 2);
          FOutput.SetForegroundColor(tcRed);
          FOutput.Write('Error: ' + E.Message);
          FOutput.ResetColors;
          Sleep(1000);
        end;
      end;
    end;
    
  finally
    FinalizeEditor;
  end;
end;

var
  LEditor: TTextEditor;
  LFileName: string;

begin
  try
    LEditor := TTextEditor.Create;
    try
      // 检查命令行参数
      if ParamCount > 0 then
        LFileName := ParamStr(1)
      else
        LFileName := '';
        
      LEditor.Run(LFileName);
      
    finally
      LEditor.Free;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('Text editor error: ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
