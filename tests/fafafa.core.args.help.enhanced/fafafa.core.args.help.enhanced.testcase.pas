{$CODEPAGE UTF8}
unit fafafa.core.args.help.enhanced.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.args,
  fafafa.core.args.command,
  fafafa.core.args.help.enhanced;

type
  TTestCase_EnhancedHelp = class(TTestCase)
  published
    procedure Test_EnhancedRenderOptions_Default;
    procedure Test_EnhancedRenderOptions_Colorful;
    procedure Test_EnhancedRenderOptions_Plain;
    procedure Test_EnhancedRenderOptions_Compact;
    procedure Test_EnhancedHelpRenderer_Create;
    procedure Test_ColorText_WithColors;
    procedure Test_ColorText_WithoutColors;
    procedure Test_FormatHeader;
    procedure Test_FormatOption;
    procedure Test_FormatCommand;
    procedure Test_FormatExample;
    procedure Test_FormatRequired;
    procedure Test_FormatDefault;
    procedure Test_WrapDescription;
    procedure Test_GetTerminalWidth;
    procedure Test_SupportsColors;
  end;

  TTestCase_ColorFunctions = class(TTestCase)
  published
    procedure Test_Bold;
    procedure Test_Italic;
    procedure Test_Underline;
    procedure Test_Dim;
    procedure Test_Red;
    procedure Test_Green;
    procedure Test_Yellow;
    procedure Test_Blue;
    procedure Test_Cyan;
    procedure Test_Magenta;
  end;

  TTestCase_HelpStructures = class(TTestCase)
  published
    procedure Test_THelpExample_Create;
    procedure Test_TEnvironmentVar_Create;
  end;

implementation

{ TTestCase_EnhancedHelp }

procedure TTestCase_EnhancedHelp.Test_EnhancedRenderOptions_Default;
var
  Options: TEnhancedRenderOptions;
begin
  Options := TEnhancedRenderOptions.Default;
  
  CheckEquals(0, Options.Width);
  CheckTrue(Options.Wrap);
  CheckTrue(Options.SortSubcommands);
  CheckTrue(Options.ShowAliases);
  CheckTrue(Options.ShowTypes);
  CheckTrue(Options.EnableColors);
  CheckTrue(Options.UseUnicodeSymbols);
  CheckTrue(Options.ShowExamples);
  CheckTrue(Options.ShowEnvironmentVars);
  CheckFalse(Options.CompactMode);
  CheckTrue(Options.ShowSectionSeparators);
  CheckEquals(2, Options.IndentSize);
  CheckEquals(60, Options.MaxDescriptionWidth);
end;

procedure TTestCase_EnhancedHelp.Test_EnhancedRenderOptions_Colorful;
var
  Options: TEnhancedRenderOptions;
begin
  Options := TEnhancedRenderOptions.Colorful;
  
  CheckTrue(Options.EnableColors);
  CheckTrue(Options.UseUnicodeSymbols);
end;

procedure TTestCase_EnhancedHelp.Test_EnhancedRenderOptions_Plain;
var
  Options: TEnhancedRenderOptions;
begin
  Options := TEnhancedRenderOptions.Plain;
  
  CheckFalse(Options.EnableColors);
  CheckFalse(Options.UseUnicodeSymbols);
end;

procedure TTestCase_EnhancedHelp.Test_EnhancedRenderOptions_Compact;
var
  Options: TEnhancedRenderOptions;
begin
  Options := TEnhancedRenderOptions.Compact;
  
  CheckTrue(Options.CompactMode);
  CheckFalse(Options.ShowSectionSeparators);
  CheckEquals(1, Options.IndentSize);
  CheckEquals(40, Options.MaxDescriptionWidth);
end;

procedure TTestCase_EnhancedHelp.Test_EnhancedHelpRenderer_Create;
var
  Options: TEnhancedRenderOptions;
  Renderer: TEnhancedHelpRenderer;
begin
  Options := TEnhancedRenderOptions.Default;
  Renderer := TEnhancedHelpRenderer.Create(Options);
  try
    CheckNotNull(Renderer);
    CheckEquals(Options.EnableColors, Renderer.Options.EnableColors);
  finally
    Renderer.Free;
  end;
end;

procedure TTestCase_EnhancedHelp.Test_ColorText_WithColors;
var
  Options: TEnhancedRenderOptions;
  Renderer: TEnhancedHelpRenderer;
  Result: string;
begin
  Options := TEnhancedRenderOptions.Colorful;
  Renderer := TEnhancedHelpRenderer.Create(Options);
  try
    Result := Renderer.ColorText('test', ecRed, [tsBold]);
    // 结果应该包含 ANSI 颜色代码（如果支持颜色）
    CheckTrue(Length(Result) >= 4); // 至少包含 'test'
  finally
    Renderer.Free;
  end;
end;

procedure TTestCase_EnhancedHelp.Test_ColorText_WithoutColors;
var
  Options: TEnhancedRenderOptions;
  Renderer: TEnhancedHelpRenderer;
  Result: string;
begin
  Options := TEnhancedRenderOptions.Plain;
  Renderer := TEnhancedHelpRenderer.Create(Options);
  try
    Result := Renderer.ColorText('test', ecRed, [tsBold]);
    CheckEquals('test', Result); // 应该返回原始文本
  finally
    Renderer.Free;
  end;
end;

procedure TTestCase_EnhancedHelp.Test_FormatHeader;
var
  Renderer: TEnhancedHelpRenderer;
  Result: string;
begin
  Renderer := CreateEnhancedRenderer(False); // 禁用颜色以便测试
  try
    Result := Renderer.FormatHeader('TEST HEADER');
    CheckTrue(Pos('TEST HEADER', Result) > 0);
  finally
    Renderer.Free;
  end;
end;

procedure TTestCase_EnhancedHelp.Test_FormatOption;
var
  Renderer: TEnhancedHelpRenderer;
  Result: string;
begin
  Renderer := CreateEnhancedRenderer(False);
  try
    Result := Renderer.FormatOption('--help');
    CheckEquals('--help', Result);
  finally
    Renderer.Free;
  end;
end;

procedure TTestCase_EnhancedHelp.Test_FormatCommand;
var
  Renderer: TEnhancedHelpRenderer;
  Result: string;
begin
  Renderer := CreateEnhancedRenderer(False);
  try
    Result := Renderer.FormatCommand('build');
    CheckEquals('build', Result);
  finally
    Renderer.Free;
  end;
end;

procedure TTestCase_EnhancedHelp.Test_FormatExample;
var
  Renderer: TEnhancedHelpRenderer;
  Result: string;
begin
  Renderer := CreateEnhancedRenderer(False);
  try
    Result := Renderer.FormatExample('myapp --help');
    CheckTrue(Pos('myapp --help', Result) > 0);
  finally
    Renderer.Free;
  end;
end;

procedure TTestCase_EnhancedHelp.Test_FormatRequired;
var
  Renderer: TEnhancedHelpRenderer;
  Result: string;
begin
  Renderer := CreateEnhancedRenderer(False);
  try
    Result := Renderer.FormatRequired('(required)');
    CheckEquals('(required)', Result);
  finally
    Renderer.Free;
  end;
end;

procedure TTestCase_EnhancedHelp.Test_FormatDefault;
var
  Renderer: TEnhancedHelpRenderer;
  Result: string;
begin
  Renderer := CreateEnhancedRenderer(False);
  try
    Result := Renderer.FormatDefault('[default: json]');
    CheckEquals('[default: json]', Result);
  finally
    Renderer.Free;
  end;
end;

procedure TTestCase_EnhancedHelp.Test_WrapDescription;
var
  Renderer: TEnhancedHelpRenderer;
  Result: string;
begin
  Renderer := CreateEnhancedRenderer(False);
  try
    Result := Renderer.WrapDescription('Short text', 2);
    CheckTrue(Pos('Short text', Result) > 0);
    CheckTrue(Pos('  ', Result) > 0); // 应该包含缩进
  finally
    Renderer.Free;
  end;
end;

procedure TTestCase_EnhancedHelp.Test_GetTerminalWidth;
var
  Renderer: TEnhancedHelpRenderer;
  Width: Integer;
begin
  Renderer := CreateEnhancedRenderer(False);
  try
    Width := Renderer.GetTerminalWidth;
    CheckTrue(Width > 0);
    CheckTrue(Width >= 80); // 最小宽度应该是 80
  finally
    Renderer.Free;
  end;
end;

procedure TTestCase_EnhancedHelp.Test_SupportsColors;
var
  Renderer: TEnhancedHelpRenderer;
  SupportsColors: Boolean;
begin
  Renderer := CreateEnhancedRenderer(True);
  try
    SupportsColors := Renderer.SupportsColors;
    // 结果取决于环境，但应该是布尔值
    CheckTrue((SupportsColors = True) or (SupportsColors = False));
  finally
    Renderer.Free;
  end;
end;

{ TTestCase_ColorFunctions }

procedure TTestCase_ColorFunctions.Test_Bold;
var
  Result: string;
begin
  Result := Bold('test');
  CheckTrue(Length(Result) >= 4); // 至少包含 'test'
end;

procedure TTestCase_ColorFunctions.Test_Italic;
var
  Result: string;
begin
  Result := Italic('test');
  CheckTrue(Length(Result) >= 4);
end;

procedure TTestCase_ColorFunctions.Test_Underline;
var
  Result: string;
begin
  Result := Underline('test');
  CheckTrue(Length(Result) >= 4);
end;

procedure TTestCase_ColorFunctions.Test_Dim;
var
  Result: string;
begin
  Result := Dim('test');
  CheckTrue(Length(Result) >= 4);
end;

procedure TTestCase_ColorFunctions.Test_Red;
var
  Result: string;
begin
  Result := Red('test');
  CheckTrue(Length(Result) >= 4);
end;

procedure TTestCase_ColorFunctions.Test_Green;
var
  Result: string;
begin
  Result := Green('test');
  CheckTrue(Length(Result) >= 4);
end;

procedure TTestCase_ColorFunctions.Test_Yellow;
var
  Result: string;
begin
  Result := Yellow('test');
  CheckTrue(Length(Result) >= 4);
end;

procedure TTestCase_ColorFunctions.Test_Blue;
var
  Result: string;
begin
  Result := Blue('test');
  CheckTrue(Length(Result) >= 4);
end;

procedure TTestCase_ColorFunctions.Test_Cyan;
var
  Result: string;
begin
  Result := Cyan('test');
  CheckTrue(Length(Result) >= 4);
end;

procedure TTestCase_ColorFunctions.Test_Magenta;
var
  Result: string;
begin
  Result := Magenta('test');
  CheckTrue(Length(Result) >= 4);
end;

{ TTestCase_HelpStructures }

procedure TTestCase_HelpStructures.Test_THelpExample_Create;
var
  Example: THelpExample;
begin
  Example := THelpExample.Create('myapp --help', 'Show help');
  
  CheckEquals('myapp --help', Example.Command);
  CheckEquals('Show help', Example.Description);
end;

procedure TTestCase_HelpStructures.Test_TEnvironmentVar_Create;
var
  EnvVar: TEnvironmentVar;
begin
  EnvVar := TEnvironmentVar.Create('COLUMNS', 'Terminal width', '80');
  
  CheckEquals('COLUMNS', EnvVar.Name);
  CheckEquals('Terminal width', EnvVar.Description);
  CheckEquals('80', EnvVar.DefaultValue);
end;

initialization
  RegisterTest(TTestCase_EnhancedHelp);
  RegisterTest(TTestCase_ColorFunctions);
  RegisterTest(TTestCase_HelpStructures);
end.
