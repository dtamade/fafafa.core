# 环境模块契约（env contracts）

适用于 fafafa.core.env 模块的设计与行为约定，供其他文档/模块复用。

## 总则
- 门面层遵循“C 风格”错误处理：返回空串/False，不抛异常。
- 跨平台一致性优先，个别平台差异通过条件分支明示。

## 字符串展开（env_expand）
- 处理顺序：先执行 Unix 风格 `$VAR` 与 `${VAR}`；在 Windows 平台上随后处理 `%VAR%`。
- `$VAR` 规则：
  - 变量名首字符必须为 `[A-Za-z_]`，后续字符为 `[A-Za-z0-9_]`。
  - 若 `$` 后不满足规则（如 `$5`），按字面量处理，不展开。
- `${VAR}` 规则：
  - 收集到遇到的第一个 `}` 为止作为变量名；若未遇到 `}`（未闭合），按“最佳努力”对已收集的变量名进行展开。
  - 不支持嵌套花括号：例如 `${A${B}}` 将以 `A${B` 作为变量名展开，尾部多余 `}` 保留为字面量。
- Windows `%VAR%` 规则：
  - 仅在 Windows 上生效。
  - 必须成对 `%` 才会展开；不成对的 `%` 作为字面量保留（如 `%FOO` -> `%FOO`）。
- 未定义变量：展开为空串。

### 示例
```pascal
// 先 Unix 风格
env_set('HELLO','world');
AssertEquals('pre-world-post', env_expand('pre-$HELLO-post'));
AssertEquals('pre-world-post', env_expand('pre-${HELLO}-post'));
// `$` 后不是 [A-Za-z_] -> 字面量
AssertEquals('pre$5x', env_expand('pre$5x'));
// 未闭合花括号：最佳努力
AssertEquals('world', env_expand('${HELLO'));
{$IFDEF WINDOWS}
// Windows：%VAR% 需成对
AssertEquals('pre-world-post', env_expand('pre-%HELLO%-post'));
AssertEquals('%HELLO', env_expand('%HELLO')); // 不成对保留
{$ENDIF}
```

## PATH 辅助（split/join）
- 分隔符：
  - Windows 使用 `;`，其他平台使用 `:`；通过 `env_path_list_separator()` 查询。
- env_split_paths：
  - 忽略空段（连续分隔符不产生空项）。
- env_join_paths：
  - 忽略空字符串项；使用平台分隔符拼接。

### 示例
```pascal
var sep: Char; arr: TStringArray;
sep := env_path_list_separator();
arr := env_split_paths('a' + sep + sep + 'b');
AssertEquals(2, Length(arr));
AssertEquals('a' + sep + 'b', env_join_paths(['a','','b']));
```

## 平台大小写与目录
- 大小写：
  - Windows：系统层面环境变量名通常不区分大小写；门面不做强制规范化，按传入名查询。
  - Unix：变量名区分大小写。
- 用户目录：
  - Windows：config -> APPDATA，cache -> LOCALAPPDATA；若缺失回退至用户目录内 AppData 路径。
  - macOS：config -> `~/Library/Application Support`，cache -> `~/Library/Caches`。
  - Unix：遵循 XDG（XDG_CONFIG_HOME、XDG_CACHE_HOME），缺失时回退到 `~/.config` 与 `~/.cache`。
  - Android：优先解析 App sandbox（无需依赖 Java/Context）：
    - 若设置 `FAFAFA_ANDROID_DATA_DIR`：直接使用该路径作为应用数据目录，并派生：config/home -> `${DATA_DIR}/files`，cache/temp -> `${DATA_DIR}/cache`。
    - 否则：从 `/proc/self/cmdline` 获取包名（并剥离 `:service` 后缀），结合 uid 推导 userId（uid/100000），探测 `/data/user/<userId>/<pkg>`、`/data/data/<pkg>`。
    - 若仍无法解析：回退到 Unix/XDG（`XDG_*` / `HOME`）。

