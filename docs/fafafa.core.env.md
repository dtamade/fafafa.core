# fafafa.core.env

现代化、跨平台的环境变量与用户目录辅助模块。设计参考 Rust std::env 与 Go os。

## 目标与范围
- 统一环境变量读写：env_get/env_set/env_unset/env_vars
- 字符串展开：支持 $VAR/${VAR}（Unix），Windows 额外支持 %VAR%
- PATH 工具：env_split_paths/env_join_paths，自动使用平台分隔符
- 进程目录与信息：env_current_dir/env_set_current_dir/env_executable_path
- 用户目录：env_home_dir/env_temp_dir/env_user_config_dir/env_user_cache_dir

## API 概览
- function env_get(const AName: string): string;
- function env_lookup(const AName: string; out AValue: string): Boolean; // 区分未定义 vs 空字符串
- function env_set(const AName, AValue: string): Boolean;
- function env_unset(const AName: string): Boolean;
- procedure env_vars(const ADest: TStrings);
- function env_override(const AName, AValue: string): TEnvOverrideGuard; // RAII 临时覆写
- function env_expand(const S: string): string; // 委托 env_expand_env
- type TEnvResolver = function(const Key: string; out Value: string): Boolean;
- function env_expand_with(const S: string; Resolver: TEnvResolver): string;
- function env_expand_env(const S: string): string; // 当前进程环境展开
- function env_path_list_separator: Char;
- function env_split_paths(const S: string): TStringArray;
- function env_join_paths(const Paths: array of string): string;
- function env_current_dir: string;
- function env_set_current_dir(const APath: string): Boolean;
- function env_home_dir: string;
- function env_temp_dir: string;
- function env_executable_path: string;
- function env_user_config_dir: string;
- function env_user_cache_dir: string;


### Result 风格 API（新增）
为便于与 Rust/Go 语义对齐，新增 Result 风格包装函数（原 C 风格 API 保持不变）：

- function env_get_result(const AName: string): TResult<string, EVarError>;
- function env_join_paths_result(const Paths: array of string): TResult<string, EPathJoinError>;
- function env_current_dir_result: TResult<string, EIOError>;
- function env_set_current_dir_result(const APath: string): TResult<Boolean, EIOError>;

错误类型：
- EVarError = record Name, Msg: string end;
- EPathJoinError = record Index: Integer; Segment, Msg: string end;
- EIOError = record Op, Path, Msg: string end;

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
- Err 分支：使用 EIOError，Op 分别为 'homedir'/'tempdir'/'exepath'/'user_config_dir'/'user_cache_dir'，Msg 为失败原因。

## 设计要点
- 作为门面层封装 `fafafa.core.os` 中已存在的跨平台实现（get/set/unset/environ、home、temp、exe）。
- PATH 分隔符：Windows 为 `;`，其他平台为 `:`。
- 展开策略：默认使用 env_expand_env（支持 $$/%% 转义；未定义替换为空；Windows 大小写不敏感），也可使用 env_expand_with 提供自定义解析行为。
- 不抛异常，遵循模块通用“C 风格”约定：失败返回空或 False。

## 用例示例
```pascal
var s: string; arr: TStringArray; cfg: string;
begin
  env_set('HELLO', 'world');
  s := env_expand('HOME=$HOME, HELLO=${HELLO}');
  arr := env_split_paths(env_get('PATH'));
  cfg := env_user_config_dir;
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
- 库代码避免修改全局环境变量，优先在进程构建时指定环境：
  - 使用 `fafafa.core.process` 的 `Env/SetEnv/UnsetEnv/ClearEnv/InheritEnv` 管理子进程环境。
- 测试中修改环境需回滚：
  - 推荐使用 `env_override` 守卫；批量修改使用 `env_overrides`，显式取消使用 `env_override_unset`。
  - 避免跨测试共享环境污染，始终在 try/finally 中调用 Done 回滚。

## 与 fafafa.core.os 的关系
- env_* 作为更聚焦的“环境”门面；os_* 提供更广泛的系统信息能力。

## 后续计划
- 支持 `env_vars` 的可迭代快照接口（只读迭代器）。
- env_override: 后续考虑提供多变量批量覆写、作用域嵌套检测与自动析构（析构时自动 Done）。

