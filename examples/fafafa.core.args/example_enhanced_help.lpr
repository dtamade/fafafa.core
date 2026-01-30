program example_enhanced_help;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.args,
  fafafa.core.args.command,
  fafafa.core.args.help.enhanced;

procedure DemoColorfulHelp;
var
  Renderer: TEnhancedHelpRenderer;
  Options: TEnhancedRenderOptions;
  MockCommand: IBaseCommand;
  HelpText: string;
begin
  WriteLn('=== 彩色帮助系统演示 ===');
  
  Options := TEnhancedRenderOptions.Colorful;
  Renderer := TEnhancedHelpRenderer.Create(Options);
  
  try
    // 注意：这里使用模拟的命令对象
    // 实际使用时应该传入真实的命令对象
    WriteLn('生成的彩色帮助文本：');
    WriteLn('----------------------------------------');
    
    // 演示各种颜色格式化
    WriteLn(Renderer.FormatHeader('USAGE:'));
    WriteLn('  myapp [OPTIONS] [COMMAND]');
    WriteLn;
    
    WriteLn(Renderer.FormatHeader('DESCRIPTION:'));
    WriteLn('  A powerful command-line tool with enhanced help system');
    WriteLn;
    
    WriteLn(Renderer.FormatHeader('OPTIONS:'));
    WriteLn('  ', Renderer.FormatOption('--help'), '     Show this help message');
    WriteLn('  ', Renderer.FormatOption('--version'), '  Show version information');
    WriteLn('  ', Renderer.FormatOption('--verbose'), '  Enable verbose output');
    WriteLn('  ', Renderer.FormatOption('--config'), '   Configuration file path ', Renderer.FormatRequired('(required)'));
    WriteLn('  ', Renderer.FormatOption('--format'), '   Output format ', Renderer.FormatDefault('[default: json]'));
    WriteLn;
    
    WriteLn(Renderer.FormatHeader('COMMANDS:'));
    WriteLn('  ', Renderer.FormatCommand('build'), '    Build the project');
    WriteLn('  ', Renderer.FormatCommand('test'), '     Run tests');
    WriteLn('  ', Renderer.FormatCommand('deploy'), '   Deploy to production');
    WriteLn;
    
    WriteLn(Renderer.FormatHeader('EXAMPLES:'));
    WriteLn('  ', Renderer.FormatExample('myapp build --verbose'));
    WriteLn('    Build with verbose output');
    WriteLn('  ', Renderer.FormatExample('myapp test --format=xml'));
    WriteLn('    Run tests with XML output');
    WriteLn;
    
    WriteLn('----------------------------------------');
  finally
    Renderer.Free;
  end;
  
  WriteLn;
end;

procedure DemoPlainHelp;
var
  Renderer: TEnhancedHelpRenderer;
  Options: TEnhancedRenderOptions;
begin
  WriteLn('=== 纯文本帮助系统演示 ===');
  
  Options := TEnhancedRenderOptions.Plain;
  Renderer := TEnhancedHelpRenderer.Create(Options);
  
  try
    WriteLn('生成的纯文本帮助：');
    WriteLn('----------------------------------------');
    
    WriteLn(Renderer.FormatHeader('USAGE:'));
    WriteLn('  myapp [OPTIONS] [COMMAND]');
    WriteLn;
    
    WriteLn(Renderer.FormatHeader('OPTIONS:'));
    WriteLn('  ', Renderer.FormatOption('--help'), '     Show this help message');
    WriteLn('  ', Renderer.FormatOption('--version'), '  Show version information');
    WriteLn('  ', Renderer.FormatOption('--config'), '   Configuration file path ', Renderer.FormatRequired('(required)'));
    WriteLn;
    
    WriteLn('----------------------------------------');
  finally
    Renderer.Free;
  end;
  
  WriteLn;
end;

procedure DemoCompactHelp;
var
  Renderer: TEnhancedHelpRenderer;
  Options: TEnhancedRenderOptions;
begin
  WriteLn('=== 紧凑模式帮助演示 ===');
  
  Options := TEnhancedRenderOptions.Compact;
  Renderer := TEnhancedHelpRenderer.Create(Options);
  
  try
    WriteLn('生成的紧凑帮助：');
    WriteLn('----------------------------------------');
    
    WriteLn(Renderer.FormatHeader('USAGE:'));
    WriteLn(' myapp [OPTIONS]');
    WriteLn(Renderer.FormatHeader('OPTIONS:'));
    WriteLn(' ', Renderer.FormatOption('--help'), ' Show help');
    WriteLn(' ', Renderer.FormatOption('--version'), ' Show version');
    WriteLn(' ', Renderer.FormatOption('--config'), ' Config file ', Renderer.FormatRequired('(required)'));
    
    WriteLn('----------------------------------------');
  finally
    Renderer.Free;
  end;
  
  WriteLn;
end;

procedure DemoColorFunctions;
begin
  WriteLn('=== 颜色工具函数演示 ===');
  
  WriteLn('文本样式：');
  WriteLn('  ', Bold('粗体文本'));
  WriteLn('  ', Italic('斜体文本'));
  WriteLn('  ', Underline('下划线文本'));
  WriteLn('  ', Dim('暗淡文本'));
  WriteLn;
  
  WriteLn('颜色文本：');
  WriteLn('  ', Red('红色文本'));
  WriteLn('  ', Green('绿色文本'));
  WriteLn('  ', Yellow('黄色文本'));
  WriteLn('  ', Blue('蓝色文本'));
  WriteLn('  ', Cyan('青色文本'));
  WriteLn('  ', Magenta('洋红色文本'));
  WriteLn;
end;

procedure DemoCustomOptions;
var
  Renderer: TEnhancedHelpRenderer;
  Options: TEnhancedRenderOptions;
begin
  WriteLn('=== 自定义选项演示 ===');
  
  Options := TEnhancedRenderOptions.Default;
  Options.EnableColors := True;
  Options.UseUnicodeSymbols := True;
  Options.ShowSectionSeparators := True;
  Options.IndentSize := 4;
  Options.HeaderColor := ecBrightMagenta;
  Options.OptionColor := ecBrightCyan;
  Options.RequiredColor := ecBrightYellow;
  
  Renderer := TEnhancedHelpRenderer.Create(Options);
  
  try
    WriteLn('自定义颜色配置的帮助：');
    WriteLn('----------------------------------------');
    
    WriteLn(Renderer.FormatHeader('CUSTOM STYLED HELP'));
    WriteLn;
    WriteLn(Renderer.FormatHeader('OPTIONS:'));
    WriteLn('    ', Renderer.FormatOption('--input'), '    Input file path ', Renderer.FormatRequired('(required)'));
    WriteLn('    ', Renderer.FormatOption('--output'), '   Output file path');
    WriteLn('    ', Renderer.FormatOption('--format'), '   Output format ', Renderer.FormatDefault('[default: json]'));
    WriteLn;
    
    WriteLn('----------------------------------------');
  finally
    Renderer.Free;
  end;
  
  WriteLn;
end;

procedure DemoTerminalWidthDetection;
var
  Renderer: TEnhancedHelpRenderer;
  Options: TEnhancedRenderOptions;
  Width: Integer;
begin
  WriteLn('=== 终端宽度检测演示 ===');
  
  Options := TEnhancedRenderOptions.Default;
  Renderer := TEnhancedHelpRenderer.Create(Options);
  
  try
    Width := Renderer.GetTerminalWidth;
    WriteLn('检测到的终端宽度: ', Width, ' 字符');
    WriteLn('当前配置的最大描述宽度: ', Options.MaxDescriptionWidth, ' 字符');
    WriteLn;
    
    WriteLn('长描述文本换行演示：');
    WriteLn('----------------------------------------');
    WriteLn(Renderer.WrapDescription(
      'This is a very long description that should be wrapped according to the terminal width. ' +
      'It demonstrates how the enhanced help system can automatically format text to fit within ' +
      'the available space while maintaining readability.', 2));
    WriteLn('----------------------------------------');
  finally
    Renderer.Free;
  end;
  
  WriteLn;
end;

procedure ShowFeatureComparison;
begin
  WriteLn('=== 功能对比 ===');
  WriteLn;
  WriteLn('原有帮助系统 vs 增强帮助系统：');
  WriteLn;
  WriteLn('原有功能：');
  WriteLn('  ✓ 基础文本格式化');
  WriteLn('  ✓ 选项和命令列表');
  WriteLn('  ✓ 描述文本换行');
  WriteLn('  ✓ 终端宽度检测');
  WriteLn;
  WriteLn('增强功能：');
  WriteLn('  ✓ ', Green('彩色输出支持'));
  WriteLn('  ✓ ', Yellow('Unicode 符号'));
  WriteLn('  ✓ ', Blue('多种文本样式'));
  WriteLn('  ✓ ', Cyan('自定义颜色配置'));
  WriteLn('  ✓ ', Magenta('紧凑模式'));
  WriteLn('  ✓ ', Red('必需参数标记'));
  WriteLn('  ✓ ', Dim('默认值显示'));
  WriteLn('  ✓ ', Bold('分节分隔符'));
  WriteLn('  ✓ ', Underline('示例展示'));
  WriteLn('  ✓ ', Italic('环境变量信息'));
  WriteLn;
end;

procedure ShowUsageInstructions;
begin
  WriteLn('=== 使用说明 ===');
  WriteLn;
  WriteLn('如何在您的应用中使用增强帮助系统：');
  WriteLn;
  WriteLn('1. 创建增强渲染器：');
  WriteLn('   var Renderer: TEnhancedHelpRenderer;');
  WriteLn('   Renderer := CreateEnhancedRenderer(True); // 启用颜色');
  WriteLn;
  WriteLn('2. 自定义渲染选项：');
  WriteLn('   var Options: TEnhancedRenderOptions;');
  WriteLn('   Options := TEnhancedRenderOptions.Colorful;');
  WriteLn('   Options.HeaderColor := ecBrightBlue;');
  WriteLn('   Renderer := TEnhancedHelpRenderer.Create(Options);');
  WriteLn;
  WriteLn('3. 渲染帮助文本：');
  WriteLn('   HelpText := Renderer.RenderComplete(YourCommand);');
  WriteLn('   WriteLn(HelpText);');
  WriteLn;
  WriteLn('4. 使用颜色工具函数：');
  WriteLn('   WriteLn(Bold(''重要信息''));');
  WriteLn('   WriteLn(Red(''错误消息''));');
  WriteLn('   WriteLn(Green(''成功消息''));');
  WriteLn;
end;

begin
  WriteLn('fafafa.core.args 增强帮助系统演示');
  WriteLn('==================================');
  WriteLn;
  
  DemoColorfulHelp;
  DemoPlainHelp;
  DemoCompactHelp;
  DemoColorFunctions;
  DemoCustomOptions;
  DemoTerminalWidthDetection;
  ShowFeatureComparison;
  ShowUsageInstructions;
  
  WriteLn('演示完成！');
  WriteLn;
  WriteLn('增强帮助系统特性：');
  WriteLn('- 丰富的彩色输出支持');
  WriteLn('- 多种文本样式（粗体、斜体、下划线等）');
  WriteLn('- Unicode 符号支持');
  WriteLn('- 自适应终端宽度');
  WriteLn('- 可自定义的颜色配置');
  WriteLn('- 紧凑模式和详细模式');
  WriteLn('- 必需参数和默认值标记');
  WriteLn('- 分组和分类显示');
  WriteLn('- 示例代码展示');
  WriteLn('- 环境变量信息');
  WriteLn('- 与原有系统完全兼容');
end.
