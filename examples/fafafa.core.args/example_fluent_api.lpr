program example_fluent_api;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.args,
  fafafa.core.args.fluent,
  fafafa.core.args.validation;

// 自定义验证器示例
function ValidatePositiveNumber(const Value: string; out ErrorMsg: string): Boolean;
var
  Num: Integer;
begin
  Result := TryStrToInt(Value, Num) and (Num > 0);
  if not Result then
    ErrorMsg := 'Value must be a positive number';
end;

procedure DemoBasicFluentAPI;
var
  App: IFluentArgs;
  Port: Int64;
  Verbose: Boolean;
  ConfigFile: string;
begin
  WriteLn('=== 基础流式 API 演示 ===');
  
  App := Args
    .WithHelp('A simple web server application')
    .WithVersion('1.0.0')
    .WithUsage('webserver [OPTIONS]')
    
    // 配置选项
    .Option('port')
      .WithAlias('p')
      .WithDescription('Server port number')
      .WithDefaultValue('8080')
      .AsInteger
      .WithRange(1024, 65535)
      .WithExample('--port 3000')
    .EndOption
    
    .Flag('verbose')
      .WithAlias('v')
      .WithDescription('Enable verbose logging')
    .EndOption
    
    .RequiredOption('config')
      .WithAlias('c')
      .WithDescription('Configuration file path')
      .AsFile
      .WithFileCompletion('*.conf;*.toml;*.yaml')
      .WithExample('--config server.conf')
    .EndOption
    
    // 解析参数（模拟）
    .Parse(['--port=3000', '--verbose', '--config=server.conf']);
  
  // 获取解析结果
  Port := App.GetInt('port');
  Verbose := App.GetBool('verbose');
  ConfigFile := App.GetValue('config');
  
  WriteLn('✅ 解析结果：');
  WriteLn('  端口: ', Port);
  WriteLn('  详细模式: ', Verbose);
  WriteLn('  配置文件: ', ConfigFile);
  WriteLn;
end;

procedure DemoAdvancedValidation;
var
  App: IFluentArgs;
  ValidationResult: TValidationResult;
  i: Integer;
begin
  WriteLn('=== 高级验证演示 ===');
  
  App := Args
    .WithHelp('Database migration tool')
    
    .Option('host')
      .WithDescription('Database host')
      .WithDefaultValue('localhost')
      .WithPattern('^[a-zA-Z0-9.-]+$')
    .EndOption
    
    .Option('port')
      .WithDescription('Database port')
      .AsInteger
      .WithRange(1, 65535)
      .WithCustomValidator(@ValidatePositiveNumber)
    .EndOption
    
    .Option('username')
      .WithDescription('Database username')
      .Required
      .WithMinLength(3)
      .WithMaxLength(50)
    .EndOption
    
    .Option('password')
      .WithDescription('Database password')
      .Required
      .WithMinLength(8)
    .EndOption
    
    .Option('database')
      .WithDescription('Database name')
      .Required
      .WithEnum(['production', 'staging', 'development'])
    .EndOption
    
    // 解析参数（故意包含错误）
    .Parse(['--host=invalid_host!', '--port=0', '--username=ab', '--database=invalid']);
  
  // 执行验证
  ValidationResult := App.Validate
    .Required('username')
    .Required('password')
    .Required('database')
    .Range('port', 1, 65535)
    .MinLength('username', 3)
    .Enum('database', ['production', 'staging', 'development'])
    .Check;
  
  if ValidationResult.IsValid then
    WriteLn('✅ 所有验证通过')
  else
  begin
    WriteLn('❌ 验证失败，错误数量: ', ValidationResult.ErrorCount);
    for i := 0 to ValidationResult.ErrorCount - 1 do
      WriteLn('  - ', ValidationResult.Errors[i].ToString);
  end;
  
  WriteLn;
end;

procedure DemoCommandsAndSubcommands;
var
  App: IFluentArgs;
  ExitCode: Integer;
begin
  WriteLn('=== 命令和子命令演示 ===');
  
  App := Args
    .WithHelp('Git-like version control tool')
    .WithVersion('2.0.0')
    
    // 全局选项
    .Flag('verbose')
      .WithAlias('v')
      .WithDescription('Enable verbose output')
    .EndOption
    
    // 主命令
    .Command('init')
      .WithDescription('Initialize a new repository')
      .WithExample('vcs init', 'Initialize current directory')
      .WithExample('vcs init myproject', 'Initialize new directory')
    .EndCommand
    
    .Command('add')
      .WithDescription('Add files to staging area')
      .Option('all')
        .WithAlias('A')
        .WithDescription('Add all files')
        .AsBoolean
      .EndOption
    .EndCommand
    
    .Command('commit')
      .WithDescription('Commit staged changes')
      .RequiredOption('message')
        .WithAlias('m')
        .WithDescription('Commit message')
        .WithMinLength(10)
        .WithExample('--message "Fix critical bug"')
      .EndOption
    .EndCommand
    
    // 子命令
    .Command('remote')
      .WithDescription('Manage remote repositories')
      .SubCommand('add')
        .WithDescription('Add a new remote')
        .RequiredOption('name')
          .WithDescription('Remote name')
        .EndOption
        .RequiredOption('url')
          .WithDescription('Remote URL')
          .WithPattern('^https?://.*')
        .EndOption
      .EndCommand
      .SubCommand('remove')
        .WithDescription('Remove a remote')
        .RequiredOption('name')
          .WithDescription('Remote name to remove')
        .EndOption
      .EndCommand
    .EndCommand;
  
  WriteLn('✅ 命令树构建完成');
  WriteLn('支持的命令：');
  WriteLn('  - init: 初始化仓库');
  WriteLn('  - add: 添加文件到暂存区');
  WriteLn('  - commit: 提交更改');
  WriteLn('  - remote add: 添加远程仓库');
  WriteLn('  - remote remove: 删除远程仓库');
  WriteLn;
end;

procedure DemoErrorHandling;
var
  App: IFluentArgs;
  ErrorHandled: Boolean;
begin
  WriteLn('=== 错误处理演示 ===');
  
  ErrorHandled := False;
  
  App := Args
    .WithHelp('Error handling demo')
    
    .RequiredOption('input')
      .WithDescription('Input file')
      .AsFile
    .EndOption
    
    .Option('output')
      .WithDescription('Output file')
      .AsFile
    .EndOption
    
    // 设置错误处理器
    .OnError(procedure(E: Exception)
      begin
        WriteLn('❌ 捕获到错误: ', E.Message);
        ErrorHandled := True;
      end)
    
    .OnValidationError(procedure(Result: TValidationResult)
      var i: Integer;
      begin
        WriteLn('❌ 验证错误:');
        for i := 0 to Result.ErrorCount - 1 do
          WriteLn('  - ', Result.Errors[i].ToString);
      end);
  
  try
    // 解析缺少必需参数的命令行
    App.Parse(['--output=result.txt']);
    
    // 尝试验证
    App.Validate
      .Required('input')
      .CheckAndThrow;
      
  except
    on E: Exception do
      WriteLn('❌ 异常: ', E.Message);
  end;
  
  if ErrorHandled then
    WriteLn('✅ 错误处理器正常工作')
  else
    WriteLn('⚠️  错误处理器未被调用');
  
  WriteLn;
end;

procedure DemoFluentChaining;
var
  App: IFluentArgs;
  Result: string;
begin
  WriteLn('=== 流式链式调用演示 ===');
  
  // 展示完整的链式调用
  Result := Args
    .WithHelp('File processing tool')
    .WithVersion('1.2.3')
    .CaseInsensitive
    .AllowShortCombo
    
    .Option('input')
      .WithAlias('i')
      .WithDescription('Input file path')
      .AsFile
      .Required
      .WithFileCompletion('*.txt;*.csv;*.json')
      .WithExample('--input data.csv')
    .EndOption
    
    .Option('output')
      .WithAlias('o')
      .WithDescription('Output file path')
      .AsFile
      .Optional
      .WithDefaultValue('output.txt')
      .WithFileCompletion('*.txt;*.csv;*.json')
    .EndOption
    
    .Option('format')
      .WithAlias('f')
      .WithDescription('Output format')
      .WithEnum(['json', 'csv', 'xml', 'yaml'])
      .WithDefaultValue('json')
      .WithEnumCompletion(['json', 'csv', 'xml', 'yaml'])
    .EndOption
    
    .Flag('compress')
      .WithDescription('Compress output file')
    .EndOption
    
    .WithCompletion
    .Parse(['--input=data.csv', '--format=json', '--compress'])
    .GetValueOr('output', 'default_output.txt');
  
  WriteLn('✅ 链式调用完成');
  WriteLn('输出文件: ', Result);
  WriteLn;
end;

procedure DemoCompletionGeneration;
var
  App: IFluentArgs;
  BashCompletion: string;
begin
  WriteLn('=== 自动补全生成演示 ===');
  
  App := Args
    .WithHelp('CLI tool with completion support')
    
    .Option('config')
      .WithDescription('Configuration file')
      .WithFileCompletion('*.conf;*.toml')
    .EndOption
    
    .Option('format')
      .WithDescription('Output format')
      .WithEnumCompletion(['json', 'xml', 'yaml'])
    .EndOption
    
    .Option('output-dir')
      .WithDescription('Output directory')
      .WithDirectoryCompletion
    .EndOption
    
    .WithCompletion;
  
  BashCompletion := App.GenerateCompletion(stBash);
  
  WriteLn('✅ 生成的 Bash 补全脚本长度: ', Length(BashCompletion), ' 字符');
  WriteLn('前 200 字符预览:');
  WriteLn('----------------------------------------');
  WriteLn(Copy(BashCompletion, 1, 200), '...');
  WriteLn('----------------------------------------');
  WriteLn;
end;

procedure ShowAPIComparison;
begin
  WriteLn('=== API 风格对比 ===');
  WriteLn;
  WriteLn('传统 API 风格：');
  WriteLn('  var Args: IArgs;');
  WriteLn('      Options: TArgsOptions;');
  WriteLn('  Options := ArgsOptionsDefault;');
  WriteLn('  Args := TArgs.FromProcess(Options);');
  WriteLn('  if Args.TryGetValue(''port'', Value) then');
  WriteLn('    Port := StrToInt(Value);');
  WriteLn;
  WriteLn('流式 API 风格：');
  WriteLn('  Port := Args');
  WriteLn('    .Option(''port'').AsInteger.WithRange(1024, 65535).EndOption');
  WriteLn('    .ParseProcess');
  WriteLn('    .GetInt(''port'');');
  WriteLn;
  WriteLn('流式 API 优势：');
  WriteLn('  ✓ 链式调用，代码更简洁');
  WriteLn('  ✓ 类型安全，编译时检查');
  WriteLn('  ✓ 内置验证，减少样板代码');
  WriteLn('  ✓ 自动补全支持');
  WriteLn('  ✓ 声明式配置');
  WriteLn('  ✓ 更好的可读性');
  WriteLn;
end;

begin
  WriteLn('fafafa.core.args 流式 API 演示');
  WriteLn('==============================');
  WriteLn;
  
  DemoBasicFluentAPI;
  DemoAdvancedValidation;
  DemoCommandsAndSubcommands;
  DemoErrorHandling;
  DemoFluentChaining;
  DemoCompletionGeneration;
  ShowAPIComparison;
  
  WriteLn('演示完成！');
  WriteLn;
  WriteLn('流式 API 特性：');
  WriteLn('- 链式调用支持');
  WriteLn('- Builder 模式实现');
  WriteLn('- 函数式编程风格');
  WriteLn('- 类型安全的参数获取');
  WriteLn('- 内置验证框架集成');
  WriteLn('- 自动补全生成集成');
  WriteLn('- 增强帮助系统集成');
  WriteLn('- 错误处理机制');
  WriteLn('- 与传统 API 完全兼容');
  WriteLn('- 声明式配置风格');
end.
