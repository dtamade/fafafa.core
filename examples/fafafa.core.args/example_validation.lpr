program example_validation;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.args,
  fafafa.core.args.validation,
  fafafa.core.args.errors;

// 自定义验证器示例
function ValidatePassword(const Value: string; out ErrorMsg: string): Boolean;
begin
  Result := True;
  ErrorMsg := '';
  
  if Length(Value) < 8 then
  begin
    Result := False;
    ErrorMsg := 'Password must be at least 8 characters long';
    Exit;
  end;
  
  if not (ContainsStr(Value, '0123456789') or 
          ContainsStr(Value, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ') or
          ContainsStr(Value, 'abcdefghijklmnopqrstuvwxyz')) then
  begin
    Result := False;
    ErrorMsg := 'Password must contain at least one letter and one number';
  end;
end;

procedure DemoBasicValidation;
var
  Args: IArgs;
  Validator: TArgsValidator;
  ValidationResult: TValidationResult;
  i: Integer;
begin
  WriteLn('=== 基础验证演示 ===');
  
  // 模拟参数：--port=8080 --name=myapp --threads=4
  Args := TArgs.FromArray(['--port=8080', '--name=myapp', '--threads=4'], ArgsOptionsDefault);
  
  Validator := ValidateArgs(Args);
  ValidationResult := Validator
    .Required('port')
    .Range('port', 1024, 65535)
    .Required('name')
    .MinLength('name', 3)
    .MaxLength('name', 20)
    .Optional('threads')
    .Range('threads', 1, 32)
    .Validate;
  
  if ValidationResult.IsValid then
    WriteLn('✅ 所有参数验证通过')
  else
  begin
    WriteLn('❌ 验证失败，错误数量: ', ValidationResult.ErrorCount);
    for i := 0 to ValidationResult.ErrorCount - 1 do
      WriteLn('  - ', ValidationResult.Errors[i].ToString);
  end;
  
  WriteLn;
end;

procedure DemoAdvancedValidation;
var
  Args: IArgs;
  Validator: TArgsValidator;
  ValidationResult: TValidationResult;
  i: Integer;
begin
  WriteLn('=== 高级验证演示 ===');
  
  // 模拟参数：--email=user@example.com --url=https://example.com --ip=192.168.1.1
  Args := TArgs.FromArray(['--email=user@example.com', '--url=https://example.com', '--ip=192.168.1.1'], ArgsOptionsDefault);
  
  Validator := ValidateArgs(Args);
  ValidationResult := Validator
    .Required('email')
    .Email('email')
    .Required('url')
    .Url('url')
    .Required('ip')
    .IPAddress('ip')
    .Validate;
  
  if ValidationResult.IsValid then
    WriteLn('✅ 所有参数验证通过')
  else
  begin
    WriteLn('❌ 验证失败，错误数量: ', ValidationResult.ErrorCount);
    for i := 0 to ValidationResult.ErrorCount - 1 do
      WriteLn('  - ', ValidationResult.Errors[i].ToString);
  end;
  
  WriteLn;
end;

procedure DemoEnumValidation;
var
  Args: IArgs;
  Validator: TArgsValidator;
  ValidationResult: TValidationResult;
  i: Integer;
begin
  WriteLn('=== 枚举验证演示 ===');
  
  // 模拟参数：--format=json --level=debug
  Args := TArgs.FromArray(['--format=json', '--level=debug'], ArgsOptionsDefault);
  
  Validator := ValidateArgs(Args);
  ValidationResult := Validator
    .Required('format')
    .Enum('format', ['json', 'xml', 'yaml', 'csv'])
    .Required('level')
    .Enum('level', ['trace', 'debug', 'info', 'warn', 'error'])
    .Validate;
  
  if ValidationResult.IsValid then
    WriteLn('✅ 所有参数验证通过')
  else
  begin
    WriteLn('❌ 验证失败，错误数量: ', ValidationResult.ErrorCount);
    for i := 0 to ValidationResult.ErrorCount - 1 do
      WriteLn('  - ', ValidationResult.Errors[i].ToString);
  end;
  
  WriteLn;
end;

procedure DemoFileValidation;
var
  Args: IArgs;
  Validator: TArgsValidator;
  ValidationResult: TValidationResult;
  i: Integer;
begin
  WriteLn('=== 文件验证演示 ===');
  
  // 模拟参数：--config=config.txt --output-dir=/tmp
  Args := TArgs.FromArray(['--config=config.txt', '--output-dir=/tmp'], ArgsOptionsDefault);
  
  Validator := ValidateArgs(Args);
  ValidationResult := Validator
    .Required('config')
    .FileExists('config')
    .Required('output-dir')
    .DirectoryExists('output-dir')
    .Validate;
  
  if ValidationResult.IsValid then
    WriteLn('✅ 所有参数验证通过')
  else
  begin
    WriteLn('❌ 验证失败，错误数量: ', ValidationResult.ErrorCount);
    for i := 0 to ValidationResult.ErrorCount - 1 do
      WriteLn('  - ', ValidationResult.Errors[i].ToString);
  end;
  
  WriteLn;
end;

procedure DemoCustomValidation;
var
  Args: IArgs;
  Validator: TArgsValidator;
  ValidationResult: TValidationResult;
  i: Integer;
begin
  WriteLn('=== 自定义验证演示 ===');
  
  // 模拟参数：--password=mypassword123
  Args := TArgs.FromArray(['--password=mypassword123'], ArgsOptionsDefault);
  
  Validator := ValidateArgs(Args);
  ValidationResult := Validator
    .Required('password')
    .Custom('password', @ValidatePassword, 'Password validation failed')
    .Validate;
  
  if ValidationResult.IsValid then
    WriteLn('✅ 所有参数验证通过')
  else
  begin
    WriteLn('❌ 验证失败，错误数量: ', ValidationResult.ErrorCount);
    for i := 0 to ValidationResult.ErrorCount - 1 do
      WriteLn('  - ', ValidationResult.Errors[i].ToString);
  end;
  
  WriteLn;
end;

procedure DemoPatternValidation;
var
  Args: IArgs;
  Validator: TArgsValidator;
  ValidationResult: TValidationResult;
  i: Integer;
begin
  WriteLn('=== 正则表达式验证演示 ===');
  
  // 模拟参数：--version=1.2.3 --phone=+86-138-0013-8000
  Args := TArgs.FromArray(['--version=1.2.3', '--phone=+86-138-0013-8000'], ArgsOptionsDefault);
  
  Validator := ValidateArgs(Args);
  ValidationResult := Validator
    .Required('version')
    .Pattern('version', '^\d+\.\d+\.\d+$')  // 版本号格式
    .Required('phone')
    .Pattern('phone', '^\+\d{2}-\d{3}-\d{4}-\d{4}$')  // 电话号码格式
    .Validate;
  
  if ValidationResult.IsValid then
    WriteLn('✅ 所有参数验证通过')
  else
  begin
    WriteLn('❌ 验证失败，错误数量: ', ValidationResult.ErrorCount);
    for i := 0 to ValidationResult.ErrorCount - 1 do
      WriteLn('  - ', ValidationResult.Errors[i].ToString);
  end;
  
  WriteLn;
end;

procedure DemoValidationWithErrors;
var
  Args: IArgs;
  Validator: TArgsValidator;
  ValidationResult: TValidationResult;
  i: Integer;
begin
  WriteLn('=== 验证错误演示 ===');
  
  // 模拟无效参数：--port=80 --email=invalid --format=txt
  Args := TArgs.FromArray(['--port=80', '--email=invalid', '--format=txt'], ArgsOptionsDefault);
  
  Validator := ValidateArgs(Args);
  ValidationResult := Validator
    .Required('port')
    .Range('port', 1024, 65535)  // 端口太小
    .Required('email')
    .Email('email')              // 邮箱格式无效
    .Required('format')
    .Enum('format', ['json', 'xml', 'yaml'])  // 格式无效
    .Required('missing')         // 缺少参数
    .Validate;
  
  WriteLn('❌ 验证失败，错误数量: ', ValidationResult.ErrorCount);
  for i := 0 to ValidationResult.ErrorCount - 1 do
    WriteLn('  - ', ValidationResult.Errors[i].ToDetailedString);
  
  WriteLn;
end;

procedure DemoStopOnFirstError;
var
  Args: IArgs;
  Validator: TArgsValidator;
  ValidationResult: TValidationResult;
  i: Integer;
begin
  WriteLn('=== 遇到第一个错误即停止演示 ===');
  
  // 模拟多个无效参数
  Args := TArgs.FromArray(['--port=80', '--email=invalid'], ArgsOptionsDefault);
  
  Validator := ValidateArgs(Args);
  ValidationResult := Validator
    .StopOnFirstError(True)
    .Required('port')
    .Range('port', 1024, 65535)  // 第一个错误
    .Required('email')
    .Email('email')              // 第二个错误（不会检查）
    .Validate;
  
  WriteLn('❌ 验证失败，错误数量: ', ValidationResult.ErrorCount);
  WriteLn('（只显示第一个错误，后续验证被跳过）');
  for i := 0 to ValidationResult.ErrorCount - 1 do
    WriteLn('  - ', ValidationResult.Errors[i].ToString);
  
  WriteLn;
end;

begin
  WriteLn('fafafa.core.args 验证框架演示');
  WriteLn('=============================');
  WriteLn;
  
  DemoBasicValidation;
  DemoAdvancedValidation;
  DemoEnumValidation;
  DemoFileValidation;
  DemoCustomValidation;
  DemoPatternValidation;
  DemoValidationWithErrors;
  DemoStopOnFirstError;
  
  WriteLn('演示完成！');
  WriteLn;
  WriteLn('验证框架特性：');
  WriteLn('- 丰富的内置验证器（范围、长度、格式等）');
  WriteLn('- 预定义验证器（邮箱、URL、IP地址等）');
  WriteLn('- 自定义验证器支持');
  WriteLn('- 正则表达式验证');
  WriteLn('- 文件和目录存在性验证');
  WriteLn('- 链式调用语法');
  WriteLn('- 详细的错误信息');
  WriteLn('- 可配置的错误处理策略');
end.
