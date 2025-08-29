unit fafafa.core.args.help.enhanced;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.args,
  fafafa.core.args.command,
  fafafa.core.args.help,
  fafafa.core.aliases;

type
  // 增强的颜色支持
  TEnhancedColor = (
    ecDefault, ecBlack, ecRed, ecGreen, ecYellow, ecBlue, ecMagenta, ecCyan, ecWhite,
    ecBrightBlack, ecBrightRed, ecBrightGreen, ecBrightYellow, 
    ecBrightBlue, ecBrightMagenta, ecBrightCyan, ecBrightWhite
  );

  // 文本样式
  TTextStyle = set of (tsNone, tsBold, tsItalic, tsUnderline, tsDim);

  // 增强的渲染选项
  TEnhancedRenderOptions = record
    // 基础选项（继承自原有系统）
    Width: Integer;
    Wrap: Boolean;
    SortSubcommands: Boolean;
    ShowAliases: Boolean;
    ShowTypes: Boolean;
    
    // 增强选项
    EnableColors: Boolean;           // 启用彩色输出
    UseUnicodeSymbols: Boolean;      // 使用 Unicode 符号
    ShowExamples: Boolean;           // 显示使用示例
    ShowEnvironmentVars: Boolean;    // 显示环境变量
    CompactMode: Boolean;            // 紧凑模式
    ShowSectionSeparators: Boolean;  // 显示分节分隔符
    IndentSize: Integer;             // 缩进大小
    MaxDescriptionWidth: Integer;    // 描述最大宽度
    
    // 颜色配置
    HeaderColor: TEnhancedColor;     // 标题颜色
    OptionColor: TEnhancedColor;     // 选项颜色
    CommandColor: TEnhancedColor;    // 命令颜色
    ExampleColor: TEnhancedColor;    // 示例颜色
    RequiredColor: TEnhancedColor;   // 必需标记颜色
    DefaultColor: TEnhancedColor;    // 默认值颜色
    
    class function Default: TEnhancedRenderOptions; static;
    class function Colorful: TEnhancedRenderOptions; static;
    class function Plain: TEnhancedRenderOptions; static;
    class function Compact: TEnhancedRenderOptions; static;
  end;

  // 增强的帮助渲染器
  TEnhancedHelpRenderer = class
  private
    FOptions: TEnhancedRenderOptions;
    
    function SupportsColors: Boolean;
    function GetTerminalWidth: Integer;
    function ColorText(const Text: string; Color: TEnhancedColor; Style: TTextStyle = []): string;
    function FormatHeader(const Text: string): string;
    function FormatOption(const Text: string): string;
    function FormatCommand(const Text: string): string;
    function FormatExample(const Text: string): string;
    function FormatRequired(const Text: string): string;
    function FormatDefault(const Text: string): string;
    function FormatSectionSeparator: string;
    function WrapDescription(const Text: string; Indent: Integer): string;
    
  public
    constructor Create(const AOptions: TEnhancedRenderOptions);
    
    function RenderUsage(const Command: IBaseCommand): string;
    function RenderDescription(const Command: IBaseCommand): string;
    function RenderOptions(const Command: IBaseCommand): string;
    function RenderCommands(const Command: IBaseCommand): string;
    function RenderExamples(const Command: IBaseCommand): string;
    function RenderEnvironment(const Command: IBaseCommand): string;
    function RenderComplete(const Command: IBaseCommand): string;
    
    property Options: TEnhancedRenderOptions read FOptions write FOptions;
  end;

  // 帮助示例
  THelpExample = record
    Command: string;
    Description: string;
    
    class function Create(const ACommand, ADescription: string): THelpExample; static;
  end;

  // 环境变量信息
  TEnvironmentVar = record
    Name: string;
    Description: string;
    DefaultValue: string;
    
    class function Create(const AName, ADescription, ADefaultValue: string): TEnvironmentVar; static;
  end;

  // 增强的命令接口扩展
  IEnhancedCommand = interface
    ['{12345678-1234-5678-9ABC-123456789012}']
    function GetExamples: TArray<THelpExample>;
    function GetEnvironmentVars: TArray<TEnvironmentVar>;
    function GetLongDescription: string;
    procedure SetExamples(const AExamples: array of THelpExample);
    procedure SetEnvironmentVars(const AVars: array of TEnvironmentVar);
    procedure SetLongDescription(const ADescription: string);
  end;

// 便利函数
function CreateEnhancedRenderer(EnableColors: Boolean = True): TEnhancedHelpRenderer;
function RenderEnhancedUsage(const Command: IBaseCommand; EnableColors: Boolean = True): string;

// 颜色工具函数
function Bold(const Text: string): string;
function Italic(const Text: string): string;
function Underline(const Text: string): string;
function Dim(const Text: string): string;
function Red(const Text: string): string;
function Green(const Text: string): string;
function Yellow(const Text: string): string;
function Blue(const Text: string): string;
function Cyan(const Text: string): string;
function Magenta(const Text: string): string;

implementation

{$IFDEF MSWINDOWS}
uses Windows;
{$ENDIF}

const
  // ANSI 颜色代码
  ANSI_RESET = #27'[0m';
  ANSI_BOLD = #27'[1m';
  ANSI_ITALIC = #27'[3m';
  ANSI_UNDERLINE = #27'[4m';
  ANSI_DIM = #27'[2m';
  
  ANSI_COLORS: array[TEnhancedColor] of string = (
    '',           // ecDefault
    #27'[30m',    // ecBlack
    #27'[31m',    // ecRed
    #27'[32m',    // ecGreen
    #27'[33m',    // ecYellow
    #27'[34m',    // ecBlue
    #27'[35m',    // ecMagenta
    #27'[36m',    // ecCyan
    #27'[37m',    // ecWhite
    #27'[90m',    // ecBrightBlack
    #27'[91m',    // ecBrightRed
    #27'[92m',    // ecBrightGreen
    #27'[93m',    // ecBrightYellow
    #27'[94m',    // ecBrightBlue
    #27'[95m',    // ecBrightMagenta
    #27'[96m',    // ecBrightCyan
    #27'[97m'     // ecBrightWhite
  );

  // Unicode 符号
  UNICODE_BULLET = '•';
  UNICODE_ARROW = '→';
  UNICODE_CHECK = '✓';
  UNICODE_CROSS = '✗';
  UNICODE_STAR = '★';

{ THelpExample }

class function THelpExample.Create(const ACommand, ADescription: string): THelpExample;
begin
  Result.Command := ACommand;
  Result.Description := ADescription;
end;

{ TEnvironmentVar }

class function TEnvironmentVar.Create(const AName, ADescription, ADefaultValue: string): TEnvironmentVar;
begin
  Result.Name := AName;
  Result.Description := ADescription;
  Result.DefaultValue := ADefaultValue;
end;

{ TEnhancedRenderOptions }

class function TEnhancedRenderOptions.Default: TEnhancedRenderOptions;
begin
  Result.Width := 0;  // 自动检测
  Result.Wrap := True;
  Result.SortSubcommands := True;
  Result.ShowAliases := True;
  Result.ShowTypes := True;
  Result.EnableColors := True;
  Result.UseUnicodeSymbols := True;
  Result.ShowExamples := True;
  Result.ShowEnvironmentVars := True;
  Result.CompactMode := False;
  Result.ShowSectionSeparators := True;
  Result.IndentSize := 2;
  Result.MaxDescriptionWidth := 60;
  
  // 默认颜色配置
  Result.HeaderColor := ecBrightYellow;
  Result.OptionColor := ecBrightGreen;
  Result.CommandColor := ecBrightBlue;
  Result.ExampleColor := ecBrightCyan;
  Result.RequiredColor := ecBrightRed;
  Result.DefaultColor := ecBrightBlack;
end;

class function TEnhancedRenderOptions.Colorful: TEnhancedRenderOptions;
begin
  Result := Default;
  Result.EnableColors := True;
  Result.UseUnicodeSymbols := True;
end;

class function TEnhancedRenderOptions.Plain: TEnhancedRenderOptions;
begin
  Result := Default;
  Result.EnableColors := False;
  Result.UseUnicodeSymbols := False;
end;

class function TEnhancedRenderOptions.Compact: TEnhancedRenderOptions;
begin
  Result := Default;
  Result.CompactMode := True;
  Result.ShowSectionSeparators := False;
  Result.IndentSize := 1;
  Result.MaxDescriptionWidth := 40;
end;

{ TEnhancedHelpRenderer }

constructor TEnhancedHelpRenderer.Create(const AOptions: TEnhancedRenderOptions);
begin
  inherited Create;
  FOptions := AOptions;
  if FOptions.Width <= 0 then
    FOptions.Width := GetTerminalWidth;
end;

function TEnhancedHelpRenderer.SupportsColors: Boolean;
begin
  {$IFDEF MSWINDOWS}
  Result := (Win32MajorVersion >= 10) and FOptions.EnableColors;
  {$ELSE}
  Result := FOptions.EnableColors and 
            (GetEnvironmentVariable('TERM') <> '') and 
            (GetEnvironmentVariable('TERM') <> 'dumb');
  {$ENDIF}
end;

function TEnhancedHelpRenderer.GetTerminalWidth: Integer;
{$IFDEF MSWINDOWS}
var
  ConsoleInfo: TConsoleScreenBufferInfo;
{$ENDIF}
begin
  Result := 80; // 默认宽度
  
  {$IFDEF MSWINDOWS}
  if GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), ConsoleInfo) then
    Result := ConsoleInfo.srWindow.Right - ConsoleInfo.srWindow.Left + 1;
  {$ELSE}
  if GetEnvironmentVariable('COLUMNS') <> '' then
    Result := StrToIntDef(GetEnvironmentVariable('COLUMNS'), 80);
  {$ENDIF}
end;

function TEnhancedHelpRenderer.ColorText(const Text: string; Color: TEnhancedColor; Style: TTextStyle): string;
var
  StyleCodes: string;
begin
  if not SupportsColors then
    Exit(Text);
  
  StyleCodes := '';
  
  // 添加样式代码
  if tsBold in Style then StyleCodes := StyleCodes + ANSI_BOLD;
  if tsItalic in Style then StyleCodes := StyleCodes + ANSI_ITALIC;
  if tsUnderline in Style then StyleCodes := StyleCodes + ANSI_UNDERLINE;
  if tsDim in Style then StyleCodes := StyleCodes + ANSI_DIM;
  
  // 添加颜色代码
  if Color <> ecDefault then
    StyleCodes := StyleCodes + ANSI_COLORS[Color];
  
  if StyleCodes <> '' then
    Result := StyleCodes + Text + ANSI_RESET
  else
    Result := Text;
end;

function TEnhancedHelpRenderer.FormatHeader(const Text: string): string;
begin
  Result := ColorText(Text, FOptions.HeaderColor, [tsBold]);
  if FOptions.UseUnicodeSymbols then
    Result := UNICODE_STAR + ' ' + Result;
end;

function TEnhancedHelpRenderer.FormatOption(const Text: string): string;
begin
  Result := ColorText(Text, FOptions.OptionColor);
end;

function TEnhancedHelpRenderer.FormatCommand(const Text: string): string;
begin
  Result := ColorText(Text, FOptions.CommandColor, [tsBold]);
end;

function TEnhancedHelpRenderer.FormatExample(const Text: string): string;
begin
  Result := ColorText(Text, FOptions.ExampleColor);
  if FOptions.UseUnicodeSymbols then
    Result := UNICODE_ARROW + ' ' + Result;
end;

function TEnhancedHelpRenderer.FormatRequired(const Text: string): string;
begin
  Result := ColorText(Text, FOptions.RequiredColor);
end;

function TEnhancedHelpRenderer.FormatDefault(const Text: string): string;
begin
  Result := ColorText(Text, FOptions.DefaultColor, [tsDim]);
end;

function TEnhancedHelpRenderer.FormatSectionSeparator: string;
begin
  if FOptions.ShowSectionSeparators and not FOptions.CompactMode then
    Result := sLineBreak
  else
    Result := '';
end;

function TEnhancedHelpRenderer.WrapDescription(const Text: string; Indent: Integer): string;
var
  Lines: TStringList;
  i: Integer;
  Line: string;
  IndentStr: string;
  MaxWidth: Integer;
begin
  if not FOptions.Wrap then
    Exit(StringOfChar(' ', Indent) + Text);
  
  Lines := TStringList.Create;
  try
    Lines.Text := Text;
    IndentStr := StringOfChar(' ', Indent);
    MaxWidth := FOptions.Width - Indent;
    Result := '';
    
    for i := 0 to Lines.Count - 1 do
    begin
      Line := Lines[i];
      if Length(Line) <= MaxWidth then
        Result := Result + IndentStr + Line + sLineBreak
      else
      begin
        // 简化的文本换行
        Result := Result + IndentStr + Line + sLineBreak;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

function TEnhancedHelpRenderer.RenderUsage(const Command: IBaseCommand): string;
begin
  Result := FormatHeader('USAGE:') + sLineBreak +
            StringOfChar(' ', FOptions.IndentSize) + 
            Command.GetName + ' [OPTIONS]' + sLineBreak;
end;

function TEnhancedHelpRenderer.RenderDescription(const Command: IBaseCommand): string;
var
  Desc: string;
begin
  Desc := Command.GetDescription;
  if Desc = '' then
    Exit('');
  
  Result := FormatHeader('DESCRIPTION:') + sLineBreak +
            WrapDescription(Desc, FOptions.IndentSize) +
            FormatSectionSeparator;
end;

function TEnhancedHelpRenderer.RenderOptions(const Command: IBaseCommand): string;
begin
  // 使用原有的帮助系统，但应用增强的格式化
  Result := FormatHeader('OPTIONS:') + sLineBreak;
  
  // 这里应该集成原有的选项渲染逻辑
  // 简化实现
  Result := Result + StringOfChar(' ', FOptions.IndentSize) + 
            FormatOption('--help') + '    Show this help message' + sLineBreak +
            StringOfChar(' ', FOptions.IndentSize) + 
            FormatOption('--version') + ' Show version information' + sLineBreak +
            FormatSectionSeparator;
end;

function TEnhancedHelpRenderer.RenderCommands(const Command: IBaseCommand): string;
begin
  Result := FormatHeader('COMMANDS:') + sLineBreak +
            StringOfChar(' ', FOptions.IndentSize) + 
            FormatCommand('help') + '    Show help for commands' + sLineBreak +
            FormatSectionSeparator;
end;

function TEnhancedHelpRenderer.RenderExamples(const Command: IBaseCommand): string;
begin
  if not FOptions.ShowExamples then
    Exit('');
  
  Result := FormatHeader('EXAMPLES:') + sLineBreak +
            StringOfChar(' ', FOptions.IndentSize) + 
            FormatExample(Command.GetName + ' --help') + sLineBreak +
            StringOfChar(' ', FOptions.IndentSize * 2) + 
            'Show help information' + sLineBreak +
            FormatSectionSeparator;
end;

function TEnhancedHelpRenderer.RenderEnvironment(const Command: IBaseCommand): string;
begin
  if not FOptions.ShowEnvironmentVars then
    Exit('');
  
  Result := FormatHeader('ENVIRONMENT:') + sLineBreak +
            StringOfChar(' ', FOptions.IndentSize) + 
            'COLUMNS    Terminal width for formatting' + sLineBreak +
            FormatSectionSeparator;
end;

function TEnhancedHelpRenderer.RenderComplete(const Command: IBaseCommand): string;
begin
  Result := RenderUsage(Command) + FormatSectionSeparator +
            RenderDescription(Command) +
            RenderOptions(Command) +
            RenderCommands(Command) +
            RenderExamples(Command) +
            RenderEnvironment(Command);
end;

// 便利函数实现
function CreateEnhancedRenderer(EnableColors: Boolean): TEnhancedHelpRenderer;
var
  Options: TEnhancedRenderOptions;
begin
  if EnableColors then
    Options := TEnhancedRenderOptions.Colorful
  else
    Options := TEnhancedRenderOptions.Plain;
  
  Result := TEnhancedHelpRenderer.Create(Options);
end;

function RenderEnhancedUsage(const Command: IBaseCommand; EnableColors: Boolean): string;
var
  Renderer: TEnhancedHelpRenderer;
begin
  Renderer := CreateEnhancedRenderer(EnableColors);
  try
    Result := Renderer.RenderComplete(Command);
  finally
    Renderer.Free;
  end;
end;

// 颜色工具函数实现
function Bold(const Text: string): string;
var
  Renderer: TEnhancedHelpRenderer;
begin
  Renderer := CreateEnhancedRenderer(True);
  try
    Result := Renderer.ColorText(Text, ecDefault, [tsBold]);
  finally
    Renderer.Free;
  end;
end;

function Italic(const Text: string): string;
var
  Renderer: TEnhancedHelpRenderer;
begin
  Renderer := CreateEnhancedRenderer(True);
  try
    Result := Renderer.ColorText(Text, ecDefault, [tsItalic]);
  finally
    Renderer.Free;
  end;
end;

function Underline(const Text: string): string;
var
  Renderer: TEnhancedHelpRenderer;
begin
  Renderer := CreateEnhancedRenderer(True);
  try
    Result := Renderer.ColorText(Text, ecDefault, [tsUnderline]);
  finally
    Renderer.Free;
  end;
end;

function Dim(const Text: string): string;
var
  Renderer: TEnhancedHelpRenderer;
begin
  Renderer := CreateEnhancedRenderer(True);
  try
    Result := Renderer.ColorText(Text, ecDefault, [tsDim]);
  finally
    Renderer.Free;
  end;
end;

function Red(const Text: string): string;
var
  Renderer: TEnhancedHelpRenderer;
begin
  Renderer := CreateEnhancedRenderer(True);
  try
    Result := Renderer.ColorText(Text, ecRed);
  finally
    Renderer.Free;
  end;
end;

function Green(const Text: string): string;
var
  Renderer: TEnhancedHelpRenderer;
begin
  Renderer := CreateEnhancedRenderer(True);
  try
    Result := Renderer.ColorText(Text, ecGreen);
  finally
    Renderer.Free;
  end;
end;

function Yellow(const Text: string): string;
var
  Renderer: TEnhancedHelpRenderer;
begin
  Renderer := CreateEnhancedRenderer(True);
  try
    Result := Renderer.ColorText(Text, ecYellow);
  finally
    Renderer.Free;
  end;
end;

function Blue(const Text: string): string;
var
  Renderer: TEnhancedHelpRenderer;
begin
  Renderer := CreateEnhancedRenderer(True);
  try
    Result := Renderer.ColorText(Text, ecBlue);
  finally
    Renderer.Free;
  end;
end;

function Cyan(const Text: string): string;
var
  Renderer: TEnhancedHelpRenderer;
begin
  Renderer := CreateEnhancedRenderer(True);
  try
    Result := Renderer.ColorText(Text, ecCyan);
  finally
    Renderer.Free;
  end;
end;

function Magenta(const Text: string): string;
var
  Renderer: TEnhancedHelpRenderer;
begin
  Renderer := CreateEnhancedRenderer(True);
  try
    Result := Renderer.ColorText(Text, ecMagenta);
  finally
    Renderer.Free;
  end;
end;

end.
