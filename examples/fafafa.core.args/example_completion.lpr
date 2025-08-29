program example_completion;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fafafa.core.args,
  fafafa.core.args.completion,
  fafafa.core.args.command;

// 自定义补全提供者示例
function DatabaseCompletionProvider(const Context: string): TArray<TCompletionItem>;
begin
  SetLength(Result, 3);
  Result[0] := TCompletionItem.Create('mysql', 'MySQL database', ctValue);
  Result[1] := TCompletionItem.Create('postgresql', 'PostgreSQL database', ctValue);
  Result[2] := TCompletionItem.Create('sqlite', 'SQLite database', ctValue);
end;

function LogLevelCompletionProvider(const Context: string): TArray<TCompletionItem>;
begin
  SetLength(Result, 5);
  Result[0] := TCompletionItem.Create('trace', 'Trace level logging', ctValue);
  Result[1] := TCompletionItem.Create('debug', 'Debug level logging', ctValue);
  Result[2] := TCompletionItem.Create('info', 'Info level logging', ctValue);
  Result[3] := TCompletionItem.Create('warn', 'Warning level logging', ctValue);
  Result[4] := TCompletionItem.Create('error', 'Error level logging', ctValue);
end;

procedure DemoBasicCompletion;
var
  Config: TCompletionConfig;
  BashScript, ZshScript, PowerShellScript: string;
begin
  WriteLn('=== 基础补全生成演示 ===');
  
  // 创建补全配置
  Config := CreateCompletionConfig('myapp', 'My Application with auto-completion');
  
  // 配置全局选项
  Config
    .AddGlobalOptions(['help', 'version', 'verbose', 'quiet', 'config'])
    
    // 配置文件补全
    .AddFileCompletion('config', '*.conf;*.ini;*.toml')
    .AddFileCompletion('input', '*.txt;*.csv;*.json')
    .AddFileCompletion('output', '*.txt;*.csv;*.json')
    
    // 配置目录补全
    .AddDirectoryCompletion('output-dir')
    .AddDirectoryCompletion('temp-dir')
    
    // 配置枚举补全
    .AddEnumCompletion('format', ['json', 'xml', 'yaml', 'csv'])
    .AddEnumCompletion('mode', ['development', 'staging', 'production'])
    
    // 配置自定义补全
    .AddCustomCompletion('database', @DatabaseCompletionProvider)
    .AddCustomCompletion('log-level', @LogLevelCompletionProvider);
  
  // 生成各种 Shell 的补全脚本
  BashScript := Config.GenerateBash;
  ZshScript := Config.GenerateZsh;
  PowerShellScript := Config.GeneratePowerShell;
  
  WriteLn('✅ 生成的补全脚本：');
  WriteLn('  - Bash 脚本长度: ', Length(BashScript), ' 字符');
  WriteLn('  - Zsh 脚本长度: ', Length(ZshScript), ' 字符');
  WriteLn('  - PowerShell 脚本长度: ', Length(PowerShellScript), ' 字符');
  
  Config.Free;
  WriteLn;
end;

procedure DemoCommandCompletion;
var
  RootCmd: IRootCommand;
  Config: TCompletionConfig;
  BashScript: string;
begin
  WriteLn('=== 子命令补全演示 ===');
  
  // 创建命令树（模拟 Git 风格）
  RootCmd := NewRootCommand;
  // 注意：这里简化了命令注册，实际使用时需要提供处理函数
  
  // 创建补全配置
  Config := CreateCompletionConfig('mygit', 'Git-like tool with completion', RootCmd);
  
  Config
    .AddGlobalOptions(['help', 'version', 'verbose'])
    .AddFileCompletion('config', '*.gitconfig')
    .AddEnumCompletion('format', ['short', 'medium', 'full', 'fuller']);
  
  BashScript := Config.GenerateBash;
  WriteLn('✅ 生成了支持子命令的 Bash 补全脚本');
  WriteLn('  脚本长度: ', Length(BashScript), ' 字符');
  
  Config.Free;
  WriteLn;
end;

procedure DemoSaveCompletionFiles;
var
  Config: TCompletionConfig;
  OutputDir: string;
begin
  WriteLn('=== 保存补全文件演示 ===');
  
  Config := CreateCompletionConfig('mytool', 'Example tool');
  Config
    .AddGlobalOptions(['help', 'version', 'debug'])
    .AddFileCompletion('input')
    .AddDirectoryCompletion('output-dir')
    .AddEnumCompletion('format', ['json', 'xml']);
  
  OutputDir := 'completions';
  
  try
    Config.SaveAll(OutputDir);
    WriteLn('✅ 补全文件已保存到目录: ', OutputDir);
    WriteLn('  - mytool.bash (Bash 补全)');
    WriteLn('  - _mytool (Zsh 补全)');
    WriteLn('  - mytool.ps1 (PowerShell 补全)');
    WriteLn('  - mytool.fish (Fish 补全)');
  except
    on E: Exception do
      WriteLn('❌ 保存失败: ', E.Message);
  end;
  
  Config.Free;
  WriteLn;
end;

procedure DemoAdvancedCompletion;
var
  Config: TCompletionConfig;
  BashScript: string;
begin
  WriteLn('=== 高级补全配置演示 ===');
  
  Config := CreateCompletionConfig('advanced-tool', 'Advanced tool with rich completion');
  
  // 复杂的补全配置
  Config
    // 基础选项
    .AddGlobalOptions(['help', 'version', 'verbose', 'quiet', 'dry-run'])
    
    // 配置文件相关
    .AddFileCompletion('config', '*.toml;*.yaml;*.json')
    .AddFileCompletion('key-file', '*.pem;*.key')
    .AddFileCompletion('cert-file', '*.crt;*.pem')
    .AddFileCompletion('input', '*.txt;*.csv;*.json;*.xml')
    .AddFileCompletion('script', '*.sh;*.ps1;*.bat')
    
    // 目录相关
    .AddDirectoryCompletion('output-dir')
    .AddDirectoryCompletion('cache-dir')
    .AddDirectoryCompletion('temp-dir')
    .AddDirectoryCompletion('work-dir')
    
    // 枚举选项
    .AddEnumCompletion('format', ['json', 'xml', 'yaml', 'csv', 'table'])
    .AddEnumCompletion('log-level', ['trace', 'debug', 'info', 'warn', 'error', 'fatal'])
    .AddEnumCompletion('compression', ['none', 'gzip', 'bzip2', 'xz', 'lz4'])
    .AddEnumCompletion('encoding', ['utf8', 'utf16', 'ascii', 'latin1'])
    .AddEnumCompletion('protocol', ['http', 'https', 'ftp', 'sftp', 'ssh'])
    
    // 自定义补全
    .AddCustomCompletion('database-type', @DatabaseCompletionProvider);
  
  BashScript := Config.GenerateBash;
  WriteLn('✅ 生成了高级 Bash 补全脚本');
  WriteLn('  脚本长度: ', Length(BashScript), ' 字符');
  WriteLn('  支持的补全类型:');
  WriteLn('    - 文件路径补全 (带扩展名过滤)');
  WriteLn('    - 目录路径补全');
  WriteLn('    - 枚举值补全');
  WriteLn('    - 自定义补全提供者');
  
  Config.Free;
  WriteLn;
end;

procedure ShowBashCompletionExample;
var
  Config: TCompletionConfig;
  BashScript: string;
  Lines: TStringList;
  i: Integer;
begin
  WriteLn('=== Bash 补全脚本示例 ===');
  
  Config := CreateCompletionConfig('example', 'Example application');
  Config
    .AddGlobalOptions(['help', 'version', 'verbose'])
    .AddFileCompletion('config', '*.conf')
    .AddEnumCompletion('format', ['json', 'xml']);
  
  BashScript := Config.GenerateBash;
  Lines := TStringList.Create;
  try
    Lines.Text := BashScript;
    WriteLn('生成的 Bash 补全脚本前 20 行：');
    WriteLn('----------------------------------------');
    for i := 0 to Min(19, Lines.Count - 1) do
      WriteLn(Format('%2d: %s', [i + 1, Lines[i]]));
    if Lines.Count > 20 then
      WriteLn('... (共 ', Lines.Count, ' 行)');
    WriteLn('----------------------------------------');
  finally
    Lines.Free;
  end;
  
  Config.Free;
  WriteLn;
end;

procedure ShowInstallationInstructions;
begin
  WriteLn('=== 安装说明 ===');
  WriteLn;
  WriteLn('生成补全脚本后，需要安装到系统中：');
  WriteLn;
  WriteLn('📋 Bash 补全安装：');
  WriteLn('  # 复制到系统补全目录');
  WriteLn('  sudo cp myapp.bash /etc/bash_completion.d/');
  WriteLn('  # 或者添加到用户配置');
  WriteLn('  echo "source /path/to/myapp.bash" >> ~/.bashrc');
  WriteLn;
  WriteLn('📋 Zsh 补全安装：');
  WriteLn('  # 复制到 Zsh 补全目录');
  WriteLn('  cp _myapp /usr/local/share/zsh/site-functions/');
  WriteLn('  # 或者添加到 fpath');
  WriteLn('  echo "fpath=(~/.zsh/completions $fpath)" >> ~/.zshrc');
  WriteLn('  echo "autoload -U compinit && compinit" >> ~/.zshrc');
  WriteLn;
  WriteLn('📋 PowerShell 补全安装：');
  WriteLn('  # 添加到 PowerShell 配置文件');
  WriteLn('  Add-Content $PROFILE ". /path/to/myapp.ps1"');
  WriteLn;
  WriteLn('💡 提示：');
  WriteLn('  - 安装后需要重新启动 Shell 或执行 source 命令');
  WriteLn('  - 可以通过 Tab 键触发自动补全');
  WriteLn('  - 支持选项名、选项值、文件路径等的补全');
  WriteLn;
end;

begin
  WriteLn('fafafa.core.args 自动补全生成演示');
  WriteLn('==================================');
  WriteLn;
  
  DemoBasicCompletion;
  DemoCommandCompletion;
  DemoSaveCompletionFiles;
  DemoAdvancedCompletion;
  ShowBashCompletionExample;
  ShowInstallationInstructions;
  
  WriteLn('演示完成！');
  WriteLn;
  WriteLn('自动补全功能特性：');
  WriteLn('- 支持 Bash、Zsh、PowerShell 三种主流 Shell');
  WriteLn('- 文件和目录路径补全（支持扩展名过滤）');
  WriteLn('- 枚举值补全');
  WriteLn('- 自定义补全提供者');
  WriteLn('- 子命令补全支持');
  WriteLn('- 一键生成和保存所有 Shell 的补全脚本');
  WriteLn('- 易于集成到现有应用程序');
end.
