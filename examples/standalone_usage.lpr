program standalone_usage;

{**
 * Standalone Usage Example
 * 独立使用示例
 * 
 * 演示如何在没有完整终端库的情况下使用 ANSI 和样式模块
 * Shows how to use ANSI and Style modules without the full terminal library
 *}

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  fafafa.core.term.ansi,
  fafafa.core.term.style;

procedure ShowWelcome;
begin
  WriteLn(term_text_bold(term_text_cyan('╔══════════════════════════════════════════════════════════════╗')));
  WriteLn(term_text_bold(term_text_cyan('║')) + term_text_bold('        Terminal Styling Library - Standalone Demo        ') + term_text_bold(term_text_cyan('║')));
  WriteLn(term_text_bold(term_text_cyan('║')) + term_text_bold('              终端样式库 - 独立演示程序                ') + term_text_bold(term_text_cyan('║')));
  WriteLn(term_text_bold(term_text_cyan('╚══════════════════════════════════════════════════════════════╝')));
  WriteLn;
end;

procedure DemoBasicUsage;
begin
  WriteLn(term_text_bold('🚀 Basic Usage / 基本用法'));
  WriteLn('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  WriteLn;
  
  WriteLn('Simple colored text / 简单彩色文本:');
  WriteLn('• ' + term_text_red('Red text / 红色文本'));
  WriteLn('• ' + term_text_green('Green text / 绿色文本'));
  WriteLn('• ' + term_text_blue('Blue text / 蓝色文本'));
  WriteLn;
  
  WriteLn('Text styles / 文本样式:');
  WriteLn('• ' + term_text_bold('Bold text / 粗体文本'));
  WriteLn('• ' + term_text_italic('Italic text / 斜体文本'));
  WriteLn('• ' + term_text_underline('Underlined text / 下划线文本'));
  WriteLn;
end;

procedure DemoMessageTypes;
begin
  WriteLn(term_text_bold('📢 Message Types / 消息类型'));
  WriteLn('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  WriteLn;
  
  WriteLn('Perfect for application logging / 完美适用于应用程序日志:');
  WriteLn(term_text_error('❌ Error: Database connection failed'));
  WriteLn(term_text_warning('⚠️  Warning: Low disk space detected'));
  WriteLn(term_text_success('✅ Success: File uploaded successfully'));
  WriteLn(term_text_info('ℹ️  Info: Processing 1000 records...'));
  WriteLn(term_text_highlight('⭐ Important: Please backup your data'));
  WriteLn;
end;

procedure DemoAdvancedColors;
begin
  WriteLn(term_text_bold('🌈 Advanced Colors / 高级颜色'));
  WriteLn('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  WriteLn;
  
  WriteLn('256-color palette / 256色调色板:');
  Write('Bright colors: ');
  Write(term_text_colored('█', 196)); // 亮红
  Write(term_text_colored('█', 46));  // 亮绿
  Write(term_text_colored('█', 21));  // 亮蓝
  Write(term_text_colored('█', 226)); // 亮黄
  Write(term_text_colored('█', 201)); // 粉红
  WriteLn;
  
  WriteLn('RGB true colors / RGB真彩色:');
  Write('Custom colors: ');
  Write(term_text_rgb('█', 255, 100, 0));   // 橙色
  Write(term_text_rgb('█', 128, 0, 128));   // 紫色
  Write(term_text_rgb('█', 0, 128, 128));   // 青绿色
  Write(term_text_rgb('█', 255, 192, 203)); // 粉色
  WriteLn;
  WriteLn;
end;

procedure DemoCustomStyles;
var
  LCustomStyle: term_text_style_t;
begin
  WriteLn(term_text_bold('⚙️ Custom Styles / 自定义样式'));
  WriteLn('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  WriteLn;
  
  WriteLn('Create your own style combinations / 创建自己的样式组合:');
  
  // 创建自定义样式
  LCustomStyle := term_style_create;
  term_style_add(LCustomStyle, ts_bold);
  term_style_add(LCustomStyle, ts_underline);
  term_style_set_fg_rgb(LCustomStyle, 255, 165, 0); // 橙色
  
  WriteLn('• ' + term_text_styled('Custom orange bold underlined text', LCustomStyle));
  
  // 另一个自定义样式
  LCustomStyle := term_style_create;
  term_style_add(LCustomStyle, ts_italic);
  term_style_set_fg_256(LCustomStyle, 129); // 紫色
  term_style_set_bg_16(LCustomStyle, 0);    // 黑色背景
  
  WriteLn('• ' + term_text_styled('Custom purple italic with black background', LCustomStyle));
  WriteLn;
end;

procedure DemoDirectANSI;
begin
  WriteLn(term_text_bold('🔧 Direct ANSI Usage / 直接使用ANSI'));
  WriteLn('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  WriteLn;
  
  WriteLn('For advanced users who need direct control / 为需要直接控制的高级用户:');
  
  // 直接使用ANSI序列
  Write('Direct ANSI: ');
  Write(ANSI_FG_RED);
  Write('Red text');
  Write(ANSI_RESET);
  Write(' ');
  Write(ansi_fg_color_rgb(0, 255, 0));
  Write('Green RGB');
  Write(ANSI_RESET);
  WriteLn;
  
  // 光标控制示例
  WriteLn('Cursor control example:');
  Write('Text at position... ');
  Write(ANSI_CURSOR_SAVE);
  Write('(saved) ');
  Write(ANSI_CURSOR_RESTORE);
  WriteLn('(restored)');
  WriteLn;
end;

procedure DemoRealWorldExample;
var
  i: Integer;
begin
  WriteLn(term_text_bold('💼 Real World Example / 实际应用示例'));
  WriteLn('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  WriteLn;

  WriteLn('Application startup log / 应用程序启动日志:');
  WriteLn(term_text_info('[INFO] Starting application...'));
  WriteLn(term_text_success('[OK] Configuration loaded'));
  WriteLn(term_text_success('[OK] Database connected'));
  WriteLn(term_text_warning('[WARN] Cache server unavailable, using fallback'));
  WriteLn(term_text_success('[OK] HTTP server started on port 8080'));
  WriteLn(term_text_highlight('[READY] Application is ready to serve requests'));
  WriteLn;

  WriteLn('Progress indicator / 进度指示器:');
  Write('Processing files: ');
  for i := 1 to 10 do
  begin
    if i <= 7 then
      Write(term_text_green('*'))
    else
      Write(term_text_red('.'));
  end;
  WriteLn(' 70% complete');
  WriteLn;
end;

procedure ShowInstallationInstructions;
begin
  WriteLn(term_text_bold('📦 Installation / 安装说明'));
  WriteLn('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  WriteLn;
  
  WriteLn('1. Copy these files to your project / 复制这些文件到你的项目:');
  WriteLn('   • ' + term_text_cyan('fafafa.core.term.ansi.pas'));
  WriteLn('   • ' + term_text_cyan('fafafa.core.term.style.pas'));
  WriteLn('   • ' + term_text_cyan('fafafa.core.settings.inc'));
  WriteLn;
  
  WriteLn('2. Add to your uses clause / 添加到uses子句:');
  WriteLn(term_text_yellow('   uses fafafa.core.term.ansi, fafafa.core.term.style;'));
  WriteLn;
  
  WriteLn('3. Start using! / 开始使用！');
  WriteLn(term_text_yellow('   WriteLn(term_text_success(''Hello, colorful world!''));'));
  WriteLn;
end;

begin
  ShowWelcome;
  DemoBasicUsage;
  DemoMessageTypes;
  DemoAdvancedColors;
  DemoCustomStyles;
  DemoDirectANSI;
  DemoRealWorldExample;
  ShowInstallationInstructions;
  
  WriteLn(term_text_bold(term_text_green('🎉 Demo completed! Ready for standalone use!')));
  WriteLn(term_text_bold(term_text_green('🎉 演示完成！可以独立使用了！')));
  WriteLn;
  WriteLn('Press Enter to exit... / 按回车键退出...');
  ReadLn;
end.
