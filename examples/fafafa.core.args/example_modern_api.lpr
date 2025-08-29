program example_modern_api;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.args,
  fafafa.core.args.modern,
  fafafa.core.args.errors,
  fafafa.core.result,
  fafafa.core.option;

procedure DemoResultStyleAPI;
var
  Args: IArgsModern;
  PortResult: TArgsResultInt;
  NameResult: TArgsResult;
  VerboseResult: TArgsResultBool;
begin
  WriteLn('=== Result 风格 API 演示 ===');
  
  // 模拟参数：--port=8080 --name=myapp --verbose
  Args := ModernArgsFromArray(['--port=8080', '--name=myapp', '--verbose'], ArgsOptionsDefault);
  
  // 获取端口号（带类型检查）
  PortResult := Args.GetInt('port');
  if PortResult.IsOk then
    WriteLn('端口: ', PortResult.Unwrap)
  else
    WriteLn('端口错误: ', PortResult.UnwrapErr.ToString);
  
  // 获取应用名称
  NameResult := Args.GetValue('name');
  if NameResult.IsOk then
    WriteLn('应用名: ', NameResult.Unwrap)
  else
    WriteLn('应用名错误: ', NameResult.UnwrapErr.ToString);
  
  // 获取详细模式标志
  VerboseResult := Args.GetBool('verbose');
  if VerboseResult.IsOk then
    WriteLn('详细模式: ', VerboseResult.Unwrap)
  else
    WriteLn('详细模式错误: ', VerboseResult.UnwrapErr.ToString);
  
  WriteLn;
end;

procedure DemoOptionStyleAPI;
var
  Args: IArgsModern;
  PortOpt: specialize TOption<Int64>;
  NameOpt: specialize TOption<string>;
  VerboseOpt: specialize TOption<Boolean>;
begin
  WriteLn('=== Option 风格 API 演示 ===');
  
  // 模拟参数：--port=invalid --debug
  Args := ModernArgsFromArray(['--port=invalid', '--debug'], ArgsOptionsDefault);
  
  // 获取端口号（无效值会返回 None）
  PortOpt := Args.GetIntOpt('port');
  if PortOpt.IsSome then
    WriteLn('端口: ', PortOpt.Unwrap)
  else
    WriteLn('端口: 未提供或无效，使用默认值 3000');
  
  // 获取应用名称（未提供）
  NameOpt := Args.GetValueOpt('name');
  WriteLn('应用名: ', NameOpt.UnwrapOr('默认应用'));
  
  // 获取调试模式
  VerboseOpt := Args.GetBoolOpt('debug');
  if VerboseOpt.IsSome then
    WriteLn('调试模式: ', VerboseOpt.Unwrap)
  else
    WriteLn('调试模式: 未启用');
  
  WriteLn;
end;

procedure DemoValidationAPI;
var
  Args: IArgsModern;
  ValidationResult: specialize TResult<Boolean, TArgsError>;
begin
  WriteLn('=== 验证 API 演示 ===');
  
  // 模拟参数：--port=8080 --threads=4 --format=json
  Args := ModernArgsFromArray(['--port=8080', '--threads=4', '--format=json'], ArgsOptionsDefault);
  
  // 链式验证
  ValidationResult := Args.Validate
    .Required('port')
    .Range('port', 1024, 65535)
    .Optional('threads')
    .Range('threads', 1, 32)
    .Enum('format', ['json', 'xml', 'yaml'])
    .Check;
  
  if ValidationResult.IsOk then
    WriteLn('✅ 所有参数验证通过')
  else
    WriteLn('❌ 验证失败: ', ValidationResult.UnwrapErr.ToString);
  
  WriteLn;
end;

procedure DemoValidationWithErrors;
var
  Args: IArgsModern;
  ValidationResult: specialize TResult<Boolean, TArgsError>;
begin
  WriteLn('=== 验证错误演示 ===');
  
  // 模拟无效参数：--port=80 --threads=100 --format=csv
  Args := ModernArgsFromArray(['--port=80', '--threads=100', '--format=csv'], ArgsOptionsDefault);
  
  // 验证（会失败）
  ValidationResult := Args.Validate
    .Required('port')
    .Range('port', 1024, 65535)  // 端口太小
    .Range('threads', 1, 32)     // 线程数太大
    .Enum('format', ['json', 'xml', 'yaml'])  // 格式无效
    .Check;
  
  if ValidationResult.IsOk then
    WriteLn('✅ 验证通过')
  else
    WriteLn('❌ 验证失败: ', ValidationResult.UnwrapErr.ToDetailedString);
  
  WriteLn;
end;

procedure DemoAdvancedValidation;
var
  Args: IArgsModern;
  PortResult: TArgsResultInt;
  EmailResult: TArgsResult;
  ModeResult: TArgsResult;
begin
  WriteLn('=== 高级验证演示 ===');
  
  // 模拟参数：--port=8080 --email=user@example.com --mode=production
  Args := ModernArgsFromArray(['--port=8080', '--email=user@example.com', '--mode=production'], ArgsOptionsDefault);
  
  // 带范围验证的整数获取
  PortResult := Args.GetIntRange('port', 1024, 65535);
  if PortResult.IsOk then
    WriteLn('端口: ', PortResult.Unwrap)
  else
    WriteLn('端口错误: ', PortResult.UnwrapErr.ToString);
  
  // 带正则表达式验证的字符串获取
  EmailResult := Args.GetPattern('email', '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  if EmailResult.IsOk then
    WriteLn('邮箱: ', EmailResult.Unwrap)
  else
    WriteLn('邮箱错误: ', EmailResult.UnwrapErr.ToString);
  
  // 带枚举验证的字符串获取
  ModeResult := Args.GetEnum('mode', ['development', 'staging', 'production']);
  if ModeResult.IsOk then
    WriteLn('模式: ', ModeResult.Unwrap)
  else
    WriteLn('模式错误: ', ModeResult.UnwrapErr.ToString);
  
  WriteLn;
end;

procedure DemoMutuallyExclusiveValidation;
var
  Args: IArgsModern;
  ValidationResult: specialize TResult<Boolean, TArgsError>;
begin
  WriteLn('=== 互斥选项验证演示 ===');
  
  // 模拟冲突参数：--quiet --verbose
  Args := ModernArgsFromArray(['--quiet', '--verbose'], ArgsOptionsDefault);
  
  ValidationResult := Args.Validate
    .MutuallyExclusive('quiet', 'verbose')
    .Check;
  
  if ValidationResult.IsOk then
    WriteLn('✅ 验证通过')
  else
    WriteLn('❌ 验证失败: ', ValidationResult.UnwrapErr.ToString);
  
  WriteLn;
end;

procedure DemoLegacyCompatibility;
var
  ModernArgs: IArgsModern;
  LegacyArgs: IArgs;
  Value: string;
begin
  WriteLn('=== 传统兼容性演示 ===');
  
  ModernArgs := ModernArgsFromArray(['--config=app.conf', '--debug'], ArgsOptionsDefault);
  
  // 获取传统接口
  LegacyArgs := ModernArgs.AsLegacy;
  
  // 使用传统 API
  if LegacyArgs.TryGetValue('config', Value) then
    WriteLn('配置文件: ', Value);
  
  if LegacyArgs.HasFlag('debug') then
    WriteLn('调试模式已启用');
  
  WriteLn;
end;

begin
  WriteLn('fafafa.core.args 现代化 API 演示');
  WriteLn('================================');
  WriteLn;
  
  DemoResultStyleAPI;
  DemoOptionStyleAPI;
  DemoValidationAPI;
  DemoValidationWithErrors;
  DemoAdvancedValidation;
  DemoMutuallyExclusiveValidation;
  DemoLegacyCompatibility;
  
  WriteLn('演示完成！');
  WriteLn;
  WriteLn('现代化 API 的优势：');
  WriteLn('- 类型安全的参数获取');
  WriteLn('- 明确的错误处理（Result/Option）');
  WriteLn('- 链式验证支持');
  WriteLn('- 丰富的验证规则');
  WriteLn('- 与传统 API 完全兼容');
end.
