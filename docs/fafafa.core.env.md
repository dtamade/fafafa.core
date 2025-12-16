# fafafa.core.env

现代化、跨平台的环境变量与用户目录辅助模块。设计参考 Rust std::env 与 Go os。

## 目标与范围
- 统一环境变量读写：env_get/env_set/env_unset/env_vars
- 字符串展开：支持 $VAR/${VAR}（Unix），Windows 额外支持 %VAR%
- PATH 工具：env_split_paths/env_join_paths，自动使用平台分隔符
- 进程目录与信息：env_current_dir/env_set_current_dir/env_executable_path
- 用户目录：env_home_dir/env_temp_dir/env_user_config_dir/env_user_cache_dir

## API 概览

### 基本操作
- function env_get(const AName: string): string;
- function env_lookup(const AName: string; out AValue: string): Boolean; // 区分未定义 vs 空字符串
- function env_get_or(const AName, ADefault: string): string; // 带默认值
- function env_set(const AName, AValue: string): Boolean;
- function env_unset(const AName: string): Boolean;
- function env_has(const AName: string): Boolean; // 检查是否存在
- procedure env_vars(const ADest: TStrings);
- procedure env_vars_masked(const ADest: TStrings); // 填充 NAME=VALUE，并对敏感名自动脱敏

### RAII 临时覆写
- function env_override(const AName, AValue: string): TEnvOverrideGuard;
- function env_override_unset(const AName: string): TEnvOverrideGuard; // 临时取消设置
- function env_overrides(const Pairs: array of TEnvKV): TEnvOverridesGuard; // 批量覆写

### 字符串展开
- function env_expand(const S: string): string; // 委托 env_expand_env
- type TEnvResolver = function(const Key: string; out Value: string): Boolean;
- function env_expand_with(const S: string; Resolver: TEnvResolver): string;
- function env_expand_env(const S: string): string; // 当前进程环境展开

### PATH 工具
- function env_path_list_separator: Char;
- function env_split_paths(const S: string): TStringArray;
- function env_join_paths(const Paths: array of string): string;
- function env_join_paths_checked(const Paths: array of string; out ErrIndex: Integer): string;

### 目录与进程
- function env_current_dir: string;
- function env_set_current_dir(const APath: string): Boolean;
- function env_home_dir: string;
- function env_temp_dir: string;
- function env_executable_path: string;
- function env_user_config_dir: string;
- function env_user_cache_dir: string;

### 安全辅助函数
- function env_is_sensitive_name(const AName: string): Boolean; // 检查环境变量名是否可能包含敏感信息
- function env_mask_value(const AValue: string): string; // 为日志记录屏蔽敏感值
- function env_validate_name(const AName: string): Boolean; // 验证环境变量名格式

### 高价值便捷 API（对标 Rust std::env）
- function env_required(const AName: string): string; // 获取必须存在的环境变量，否则抛 EEnvVarNotFound
- function env_keys: TStringArray; // 获取所有环境变量名（不含值）
- function env_count: Integer; // 获取环境变量数量

### 类型化 Getters
- function env_get_bool(const AName: string; ADefault: Boolean = False): Boolean;
  // 解析布尔值：true/1/yes/on → True，false/0/no/off → False，其他返回默认值
- function env_get_int(const AName: string; ADefault: Integer = 0): Integer;
  // 解析整数（Int32），失败或未定义时返回默认值
- function env_get_int64(const AName: string; ADefault: Int64 = 0): Int64;
  // 解析整数（Int64），失败或未定义时返回默认值
- function env_get_uint(const AName: string; ADefault: Cardinal = 0): Cardinal;
  // 解析无符号整数（UInt32/Cardinal），失败/未定义/负数/溢出时返回默认值
- function env_get_uint64(const AName: string; ADefault: QWord = 0): QWord;
  // 解析无符号整数（UInt64/QWord），失败/未定义/负数/溢出时返回默认值
- function env_get_duration_ms(const AName: string; ADefault: QWord = 0): QWord;
  // 解析持续时间（毫秒），支持后缀 ms/s/m/h/d（大小写不敏感）；无后缀视为毫秒；失败/溢出时返回默认值
- function env_get_size_bytes(const AName: string; ADefault: QWord = 0): QWord;
  // 解析字节大小，支持 B/KB/MB/GB 和 KiB/MiB/GiB（大小写不敏感；可含空格，如 "10 MB"）；无后缀视为字节；失败/溢出时返回默认值
- function env_get_float(const AName: string; ADefault: Double = 0.0): Double;
  // 解析浮点数（Double），使用 '.' 作为小数点（locale-invariant），支持科学计数法（如 1e3）
- function env_get_list(const AName: string; ASeparator: Char = ','): TStringArray;
  // 按分隔符拆分为数组，未定义时返回空数组
- function env_get_paths(const AName: string): TStringArray;
  // 读取环境变量并按平台 PATH 分隔符拆分（等价 env_split_paths(env_get(AName))，未定义/空串返回空数组）

### 便捷与安全辅助
- function env_lookup_nonempty(const AName: string; out AValue: string): Boolean;
  // 仅当“已定义且非空”时返回 True；空字符串视为 False
- function env_has_nonempty(const AName: string): Boolean;
- function env_get_nonempty_or(const AName, ADefault: string): string;
  // 仅当值非空时使用环境变量，否则返回默认值
- function env_mask_value_for_name(const AName, AValue: string): string;
  // 若变量名敏感（env_is_sensitive_name），则返回 env_mask_value(AValue)，否则原样返回
- procedure env_vars_masked(const ADest: TStrings);
  // 安全地导出当前环境快照：敏感名自动脱敏（适用于日志/诊断）

### 平台常量（对标 Rust std::env::consts）
- function env_os: string; // 当前 OS: Windows/Linux/Darwin/FreeBSD/OpenBSD/NetBSD
- function env_arch: string; // 当前架构: x86_64/aarch64/i386/arm/powerpc64/riscv64
- function env_family: string; // OS 家族: unix/windows
- function env_is_windows: Boolean; // True on Windows
- function env_is_unix: Boolean; // True on Unix-like (Linux/Darwin/BSD)
- function env_is_darwin: Boolean; // True on macOS

### 危险操作（沙盒/测试用）
- procedure env_clear_all; // 清空所有环境变量（危险！仅用于沙盒隔离场景）

### 迭代器 API（对标 Rust std::env::vars()）
- type TEnvKVPair = record Key, Value: string end;
- type TEnvVarsEnumerator = record ... end; // 支持 for-in 遍历
- function env_iter: TEnvVarsEnumerator; // 返回只读迭代器

### 命令行参数 API（对标 Rust std::env::args）
- function env_args: TStringArray; // 获取所有命令行参数（包括程序名）
- function env_args_count: Integer; // 获取参数数量（ParamCount + 1）
- function env_arg(Index: Integer): string; // 按索引获取参数（0 = 程序名）

### Result 风格 API（新增）
为便于与 Rust/Go 语义对齐，新增 Result 风格包装函数（原 C 风格 API 保持不变）：

- function env_get_result(const AName: string): TResult<string, EVarError>;
- function env_join_paths_result(const Paths: array of string): TResult<string, EPathJoinError>;
- function env_current_dir_result: TResult<string, EIOError>;
- function env_set_current_dir_result(const APath: string): TResult<Boolean, EIOError>;

错误类型：
- EVarErrorKind = (vekNotDefined)
- EVarError = record Kind: EVarErrorKind; Name, Msg: string end;
- EPathJoinErrorKind = (pjekContainsSeparator)
- EPathJoinError = record Kind: EPathJoinErrorKind; Index: Integer; Separator: Char; Segment, Msg: string end;
- EIOErrorKind = (ioekGetcwdFailed, ioekChdirFailed, ioekHomeDirFailed, ioekTempDirFailed, ioekExePathFailed, ioekUserConfigDirFailed, ioekUserCacheDirFailed)
- EIOError = record Kind: EIOErrorKind; Op, Path: string; Code: Integer; SysMsg: string; Msg: string end;

使用建议：
- 需要明确区分成功/失败且携带诊断信息（变量未定义、PATH 片段非法、IO 失败）时，优先使用 Result 风格；
- 脚本式/快速路径可继续沿用 C 风格（空串/False）。

示例：
```pascal
var r1: specialize TResult<string, EVarError>;
    r2: specialize TResult<string, EPathJoinError>;
    r3: specialize TResult<string, EIOError>;
    r4: specialize TResult<Boolean, EIOError>;
begin
  r1 := env_get_result('HOME');
  if r1.IsOk then Writeln('HOME=', r1.Unwrap)
  else Writeln('Missing: ', r1.UnwrapErr.Name);

  r2 := env_join_paths_result(['a', 'b']);
  if r2.IsErr then Writeln('Bad segment at ', r2.UnwrapErr.Index, ': ', r2.UnwrapErr.Segment);

  r3 := env_current_dir_result;
  r4 := env_set_current_dir_result('C:\\');
end;
```


#### 更多查询型 Result 包装（新增）
- function env_home_dir_result: TResult<string, EIOError>
- function env_temp_dir_result: TResult<string, EIOError>
- function env_executable_path_result: TResult<string, EIOError>
- function env_user_config_dir_result: TResult<string, EIOError>
- function env_user_cache_dir_result: TResult<string, EIOError>

说明：
- Ok 分支：返回非空字符串（目录/路径）。
- Err 分支：使用 EIOError，Kind 为结构化错误类型（便于 switch/case），Op 为字符串操作名；Code 为 OS 错误码（若可用，否则为 0）；SysMsg 为 SysErrorMessage(Code)（若可用，否则为空）；Msg 为失败原因（通常包含 code=...）。

## 设计要点
- 作为门面层封装 `fafafa.core.os` 中已存在的跨平台实现（get/set/unset/environ、home、temp、exe）。
- PATH 分隔符：Windows 为 `;`，其他平台为 `:`。
- 展开策略：默认使用 env_expand_env（支持 $$/%% 转义；未定义替换为空；Windows 大小写不敏感），也可使用 env_expand_with 提供自定义解析行为。
- 不抛异常，遵循模块通用“C 风格”约定：失败返回空或 False。

## 用例示例

### 基本使用
```pascal
var s: string; arr: TStringArray; cfg: string;
begin
  env_set('HELLO', 'world');
  s := env_expand('HOME=$HOME, HELLO=${HELLO}');
  arr := env_split_paths(env_get('PATH'));
  cfg := env_user_config_dir;
end;
```

### 安全使用示例
```pascal
var
  envName, envValue, logValue: string;
begin
  envName := 'API_SECRET';

  // 验证环境变量名格式
  if not env_validate_name(envName) then
    raise Exception.Create('Invalid environment variable name');

  // 安全地记录日志
  if env_has(envName) then
  begin
    envValue := env_get(envName);
    logValue := env_mask_value_for_name(envName, envValue);
    WriteLn('Environment variable ', envName, ' = ', logValue);
  end;
end;
```

### 测试中的临时覆写（RAII）
```pascal
var g: TEnvOverrideGuard;
begin
  g := env_override('KEY', 'VALUE');
  try
    // 期间: env_get('KEY') = 'VALUE'
  finally
    g.Done; // 回滚原值（若原本不存在则恢复为未定义）
  end;
end;
```

### 必须存在的环境变量（env_required）
```pascal
var dbHost: string;
begin
  // 若 DATABASE_HOST 未定义，抛 EEnvVarNotFound 异常
  dbHost := env_required('DATABASE_HOST');
  WriteLn('Connecting to: ', dbHost);
end;
```

### 平台检测与条件逻辑
```pascal
begin
  WriteLn('OS: ', env_os);       // Linux/Windows/Darwin
  WriteLn('Arch: ', env_arch);   // x86_64/aarch64
  WriteLn('Family: ', env_family); // unix/windows

  if env_is_windows then
    WriteLn('Running on Windows')
  else if env_is_darwin then
    WriteLn('Running on macOS')
  else if env_is_unix then
    WriteLn('Running on Unix-like system');
end;
```

### 环境变量枚举
```pascal
var keys: TStringArray; i: Integer;
begin
  WriteLn('Total env vars: ', env_count);
  keys := env_keys;
  for i := 0 to High(keys) do
    WriteLn('  ', keys[i]);
end;
```

### 环境变量迭代器（for-in 遍历）
```pascal
var kv: TEnvKVPair;
begin
  // 类似 Rust: for (key, value) in std::env::vars()
  for kv in env_iter do
    WriteLn(kv.Key, '=', kv.Value);
end;
```

说明：
- Unix：`env_iter` 直接遍历 libc environ（更少分配）；迭代过程中如修改环境变量，行为未定义。
- Windows：`env_iter` 直接遍历 `GetEnvironmentStringsW` 返回的环境块（跳过 `=C:=...` 等伪变量）；迭代过程中如修改环境变量，行为未定义。
- 需要稳定快照：先用 `env_vars`/`env_keys` 获取列表再遍历。

### 命令行参数处理
```pascal
var args: TStringArray; i: Integer;
begin
  // 获取所有参数
  args := env_args;
  WriteLn('Program: ', args[0]);
  WriteLn('Arg count: ', env_args_count);
  
  // 按索引访问
  for i := 1 to env_args_count - 1 do
    WriteLn('Arg ', i, ': ', env_arg(i));
end;
```

### 类型化环境变量读取
```pascal
var
  debug: Boolean;
  port: Integer;
  limitBytes: Int64;
  seed: QWord;
  timeoutMs: QWord;
  uploadLimitBytes: QWord;
  sampleRate: Double;
  hosts: TStringArray;
  i: Integer;
begin
  // 布尔值：DEBUG=true/1/yes/on -> True
  debug := env_get_bool('DEBUG', False);

  // 整数：PORT=8080
  port := env_get_int('PORT', 3000); // 无效或未定义时返回 3000

  // Int64：LIMIT_BYTES=9223372036854775807
  limitBytes := env_get_int64('LIMIT_BYTES', 0);

  // UInt64/QWord：SEED=18446744073709551615
  seed := env_get_uint64('SEED', 0);

  // Duration: REQUEST_TIMEOUT=1500ms / 2s / 1m / 1h / 1d
  timeoutMs := env_get_duration_ms('REQUEST_TIMEOUT', 5000);

  // Size: UPLOAD_LIMIT=10MB / 1GiB / 512
  uploadLimitBytes := env_get_size_bytes('UPLOAD_LIMIT', 0);

  // 浮点数：SAMPLE_RATE=0.25 / 1e-3
  sampleRate := env_get_float('SAMPLE_RATE', 1.0);

  // 列表：ALLOWED_HOSTS=localhost,127.0.0.1,::1
  hosts := env_get_list('ALLOWED_HOSTS');
  for i := 0 to High(hosts) do
    WriteLn('Host: ', hosts[i]);

  // 自定义分隔符：PATH_EXTRA=/usr/local/bin:/opt/bin
  hosts := env_get_list('PATH_EXTRA', ':');
end;
```

### 非空值便捷读取
```pascal
var
  v: string;
begin
  // 仅当值非空才认为有效
  v := env_get_nonempty_or('LOG_LEVEL', 'info');

  if env_lookup_nonempty('DATABASE_URL', v) then
    WriteLn('DB: ', v)
  else
    WriteLn('DATABASE_URL missing/empty');
end;
```
## 平台差异
- 大小写：
  - Windows 环境变量名通常不区分大小写；env_lookup 和 env_expand_env 会按不区分大小写解析。
  - Unix 区分大小写。
- PATH 分隔符：Windows 为 `;`，Unix 为 `:`，使用 `env_path_list_separator()` 自适应。
- 展开语法：
  - 统一支持 `$VAR` 与 `${VAR}`；Windows 额外支持 `%VAR%`。
  - `$` 后首字符需为字母或 `_`；否则按字面 `$` 处理（例如 `$5`）。
- 用户目录映射：
  - Windows：config -> APPDATA，cache -> LOCALAPPDATA；回退至用户目录下 AppData 层级。
  - Unix：遵循 XDG（XDG_CONFIG_HOME、XDG_CACHE_HOME）；无则回退到 `~/.config` 与 `~/.cache`。
  - macOS：config -> `~/Library/Application Support`，cache -> `~/Library/Caches`。

## 设计与契约
- env_expand/env_expand_env/env_expand_with：
  - 扫描规则：`$VAR` 与 `${VAR}`；在 Windows 上也支持 `%VAR%`。
  - `$VAR` 标识符：首字符必须是 `[A-Za-z_]`，后续为 `[A-Za-z0-9_]`；否则 `$` 视作字面量（例如 `pre$5x` -> `pre$5x`）。
  - `${VAR}`：若遇到未闭合的 `}`，将收集到字符串结尾并按“最佳努力”展开（如 `${HOME` -> 展开 HOME），以提升容错性。
  - 嵌套花括号不支持：`${A${B}}` 将按遇到的第一个 `}` 截断展开变量名 `A${B`，尾部多余 `}` 保留为字面量。
  - 转义：`$$` -> `$`，Windows 下 `%%` -> `%`。
  - 未定义变量：默认替换为空串；如需自定义策略，请使用 `env_expand_with` 并提供 resolver。
- PATH 工具：
  - env_split_paths：忽略空段（连续分隔符不产生空项）。
  - env_join_paths：忽略空字符串项，使用平台分隔符拼接。

示例：
```pascal
// 展开（Unix 通用示例）
env_set('HELLO','world');
AssertEquals('pre-world-post', env_expand('pre-$HELLO-post'));
AssertEquals('pre-world-post', env_expand('pre-${HELLO}-post'));
// `$` 后非字母/下划线，按字面量
AssertEquals('pre$5x', env_expand('pre$5x'));
// 未闭合花括号最佳努力
AssertEquals('world', env_expand('${HELLO'));
{$IFDEF WINDOWS}
// Windows 的 %VAR%
AssertEquals('pre-world-post', env_expand('pre-%HELLO%-post'));
AssertEquals('%HELLO', env_expand('%HELLO')); // 不成对保留
{$ENDIF}

// PATH
AssertEquals(2, Length(env_split_paths('a' + env_path_list_separator + env_path_list_separator + 'b')));
AssertEquals('a' + env_path_list_separator + 'b', env_join_paths(['a','','b']));
```


> 另见：docs/partials/env.contracts.md（可复用的“环境模块契约”摘录，供其他模块/文档引用）


## 最佳实践

### 基本使用原则
- 库代码避免修改全局环境变量，优先在进程构建时指定环境：
  - 使用 `fafafa.core.process` 的 `Env/SetEnv/UnsetEnv/ClearEnv/InheritEnv` 管理子进程环境。
- 测试中修改环境需回滚：
  - 推荐使用 `env_override` 守卫；批量修改使用 `env_overrides`，显式取消使用 `env_override_unset`。
  - 避免跨测试共享环境污染，始终在 try/finally 中调用 Done 回滚。

### 安全最佳实践（2024）
- **避免敏感信息**：不要在环境变量中存储密码、API密钥、私钥等敏感信息
  - 优先使用专门的密钥管理系统（如 HashiCorp Vault、AWS Secrets Manager）
  - 如必须使用环境变量，确保运行环境的安全性和访问控制
- **输入验证**：对从环境变量读取的值进行验证和清理
  - 验证格式、长度和字符集
  - 防止注入攻击（特别是在构建命令行或SQL时）
- **最小权限原则**：只暴露必要的环境变量给子进程
  - 使用 `fafafa.core.process` 的 `ClearEnv()` 清空继承的环境
  - 显式设置需要的环境变量
- **日志安全**：避免在日志中记录敏感的环境变量值
  - 使用 `env_has()` 检查存在性而不是 `env_get()` 获取值
  - 记录日志时对敏感值进行脱敏处理

## 与 fafafa.core.os 的关系
- env_* 作为更聚焦的“环境”门面；os_* 提供更广泛的系统信息能力。

