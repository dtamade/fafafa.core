{$MODE OBJFPC}{$H+}
{ 文档示例代码验证测试 - 验证 docs/fafafa.core.env.md 中的示例可编译运行 }
program doc_examples_test;

uses
  SysUtils, Classes,
  fafafa.core.env;

var
  TestsFailed: Integer = 0;
  TestsPassed: Integer = 0;

procedure Check(const TestName: string; Condition: Boolean);
begin
  if Condition then
  begin
    Inc(TestsPassed);
    WriteLn('[PASS] ', TestName);
  end
  else
  begin
    Inc(TestsFailed);
    WriteLn('[FAIL] ', TestName);
  end;
end;

{ === 基本使用示例 === }
procedure Test_BasicUsage;
var
  s: string;
  arr: TStringArray;
  cfg: string;
begin
  WriteLn;
  WriteLn('=== 基本使用示例 ===');

  env_set('HELLO', 'world');
  s := env_expand('HOME=$HOME, HELLO=${HELLO}');
  Check('env_expand works', Pos('world', s) > 0);

  arr := env_split_paths(env_get('PATH'));
  Check('env_split_paths returns array', Length(arr) > 0);

  cfg := env_user_config_dir;
  Check('env_user_config_dir returns path', cfg <> '');
end;

{ === 安全使用示例 === }
procedure Test_SecurityUsage;
var
  envName, envValue, logValue: string;
  isSensitive: Boolean;
begin
  WriteLn;
  WriteLn('=== 安全使用示例 ===');

  envName := 'API_SECRET';

  // 检查环境变量名是否敏感
  isSensitive := env_is_sensitive_name(envName);
  Check('env_is_sensitive_name detects SECRET', isSensitive);

  // 验证环境变量名格式
  Check('env_validate_name accepts valid name', env_validate_name(envName));
  Check('env_validate_name rejects empty', not env_validate_name(''));
  Check('env_validate_name rejects leading digit', not env_validate_name('1INVALID'));

  // 安全地记录日志
  env_set('API_SECRET', 'my-secret-key-12345');
  if env_has('API_SECRET') then
  begin
    envValue := env_get('API_SECRET');
    logValue := env_mask_value(envValue);
    Check('env_mask_value masks value', (logValue <> envValue) and (Pos('*', logValue) > 0));
  end;
  env_unset('API_SECRET');
end;

{ === RAII 临时覆写示例 === }
procedure Test_RAIIOverride;
var
  g: TEnvOverrideGuard;
  original: string;
begin
  WriteLn;
  WriteLn('=== RAII 临时覆写示例 ===');

  env_set('TEST_KEY', 'original');
  original := env_get('TEST_KEY');

  g := env_override('TEST_KEY', 'overridden');
  try
    Check('override changes value', env_get('TEST_KEY') = 'overridden');
  finally
    g.Done;
  end;

  Check('done restores original', env_get('TEST_KEY') = original);
  env_unset('TEST_KEY');
end;

{ === env_required 示例 === }
procedure Test_EnvRequired;
var
  dbHost: string;
  exceptionRaised: Boolean;
begin
  WriteLn;
  WriteLn('=== env_required 示例 ===');

  // 设置变量后应成功
  env_set('DATABASE_HOST', 'localhost:5432');
  dbHost := env_required('DATABASE_HOST');
  Check('env_required returns value when set', dbHost = 'localhost:5432');
  env_unset('DATABASE_HOST');

  // 未设置时应抛异常
  exceptionRaised := False;
  try
    dbHost := env_required('NONEXISTENT_VAR_12345');
  except
    on E: EEnvVarNotFound do
      exceptionRaised := True;
  end;
  Check('env_required raises EEnvVarNotFound', exceptionRaised);
end;

{ === 平台检测示例 === }
procedure Test_PlatformDetection;
begin
  WriteLn;
  WriteLn('=== 平台检测示例 ===');

  WriteLn('  OS: ', env_os);
  WriteLn('  Arch: ', env_arch);
  WriteLn('  Family: ', env_family);

  Check('env_os returns value', env_os <> '');
  Check('env_arch returns value', env_arch <> '');
  Check('env_family returns unix or windows', (env_family = 'unix') or (env_family = 'windows'));

  {$IFDEF LINUX}
  Check('env_is_unix on Linux', env_is_unix);
  Check('not env_is_windows on Linux', not env_is_windows);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Check('env_is_windows on Windows', env_is_windows);
  Check('not env_is_unix on Windows', not env_is_unix);
  {$ENDIF}
end;

{ === 环境变量枚举示例 === }
procedure Test_EnvEnumeration;
var
  keys: TStringArray;
  count: Integer;
begin
  WriteLn;
  WriteLn('=== 环境变量枚举示例 ===');

  count := env_count;
  WriteLn('  Total env vars: ', count);

  keys := env_keys;
  Check('env_count matches env_keys length', count = Length(keys));
  Check('env_count > 0', count > 0);
end;

{ === 迭代器示例 === }
procedure Test_Iterator;
var
  kv: TEnvKVPair;
  iterCount: Integer;
begin
  WriteLn;
  WriteLn('=== 迭代器示例 ===');

  iterCount := 0;
  for kv in env_iter do
  begin
    Inc(iterCount);
    if iterCount <= 3 then
      WriteLn('  ', kv.Key, '=', Copy(kv.Value, 1, 30), '...');
  end;

  Check('env_iter iterates all vars', iterCount = env_count);
end;

{ === 命令行参数示例 === }
procedure Test_CommandLineArgs;
var
  args: TStringArray;
begin
  WriteLn;
  WriteLn('=== 命令行参数示例 ===');

  args := env_args;
  WriteLn('  Program: ', args[0]);
  WriteLn('  Arg count: ', env_args_count);

  Check('env_args[0] = env_arg(0)', args[0] = env_arg(0));
  Check('env_args_count >= 1', env_args_count >= 1);
end;

{ === PATH 处理示例 === }
procedure Test_PathHandling;
var
  sep: Char;
  parts: TStringArray;
  joined: string;
begin
  WriteLn;
  WriteLn('=== PATH 处理示例 ===');

  sep := env_path_list_separator;
  {$IFDEF WINDOWS}
  Check('PATH separator is ; on Windows', sep = ';');
  {$ELSE}
  Check('PATH separator is : on Unix', sep = ':');
  {$ENDIF}

  // Split
  parts := env_split_paths('a' + sep + sep + 'b');
  Check('env_split_paths ignores empty segments', Length(parts) = 2);

  // Join
  joined := env_join_paths(['a', '', 'b']);
  Check('env_join_paths ignores empty', joined = 'a' + sep + 'b');
end;

{ === Main === }
begin
  WriteLn('============================================================');
  WriteLn('fafafa.core.env 文档示例代码验证测试');
  WriteLn('============================================================');

  Test_BasicUsage;
  Test_SecurityUsage;
  Test_RAIIOverride;
  Test_EnvRequired;
  Test_PlatformDetection;
  Test_EnvEnumeration;
  Test_Iterator;
  Test_CommandLineArgs;
  Test_PathHandling;

  WriteLn;
  WriteLn('============================================================');
  WriteLn('结果: ', TestsPassed, ' 通过, ', TestsFailed, ' 失败');
  WriteLn('============================================================');

  if TestsFailed > 0 then
    Halt(1);
end.
