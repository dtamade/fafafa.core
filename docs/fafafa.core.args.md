# fafafa.core.args — Best‑in‑class Args Module

## Goals

## Positioning and Scope (Core vs Extensions)

- Core (stable, minimal, no implicit output)
  - Parsing: GNU/Windows styles, double-dash sentinel, case-insensitive keys (opt), short-flags combo (opt), negative-number ambiguity control, no-prefix negation
  - Subcommands: arbitrary depth, aliases, default subcommand, Run/RunPath
  - Behavior: return integer codes only; printing help/errors is the caller’s responsibility
- Extensions (opt-in, small helpers, no behavior forced)
  - Usage rendering: RenderUsage(Node) returns text; the caller decides whether/when to print
  - Light schema: describe flags/positionals only for rendering and metadata (not a heavy DSL)
  - ENV → argv: ArgvFromEnv('APP_') → ['--foo=1','--debug']
  - CONFIG (TOML) → argv: ArgvFromToml('config.toml')
    - Flattens tables to dot-keys; keys lower-cased with '_'→'-'
    - Scalars → '--key=value'; arrays of scalars → repeated '--key=value'
  - Persistent flags (registration-time propagation): parent → child, first-wins (child keeps same-name flags)
- Reserved (not implemented yet)
  - ArgvFromJson: stub
- Out of scope (unless strong demand later)
  - Auto help/auto error printing, complex validation (mutex/depends/choices/range), did-you-mean, heavy styling/i18n/completion generators

## Versioning (proposal)
- Core v1.0.0: parsing + routing API frozen, tests all green
- Extensions v1.1.0: RenderUsage/Schema/ENV/PersistentFlags available (opt-in)

### 平台与编码（Windows 宽字符 argv）
- Windows 平台默认启用“宽字符 argv 收集”（FAFAFA_ARGS_WIN_WIDE）：内部调用 CommandLineToArgvW 并统一转 UTF‑8，以避免中文/路径在本地代码页下被误读
- 非 Windows 平台不受影响；关闭该宏可回退到 RTL 的 ParamStr 收集


### ENV → argv（过滤与值规范化扩展）
- 基础函数：`ArgvFromEnv(Prefix)`（保持不变）
- 扩展函数：`ArgvFromEnvEx(Prefix, Allow, Deny, Flags)`
  - 键名匹配基于“归一化后的键”（去前缀、小写、`_`→`-`）
  - Allow 非空时仅包含 Allow 命中的键；随后移除 Deny 中的键
  - Flags：
    - `efTrimValues`：去除值两端空白
    - `efLowercaseBools`：将 `TRUE`/`FALSE` 规范为 `true`/`false`
  - 令牌构造与基础函数一致：空值 → `--name`；非空 → `--name=value`

示例：
```pascal
// APP_DEBUG=  TRUE  , APP_TAG=  x  , APP_TMP=
var a := ArgvFromEnvEx('APP_', [], [], [efTrimValues, efLowercaseBools]);
// a 包含 --debug=true, --tag=x, --tmp

var b := ArgvFromEnvEx('APP_', ['debug'], [], []); // 仅允许 debug
// b 仅包含 --debug=true

var c := ArgvFromEnvEx('APP_', [], ['tag'], []); // 排除 tag
// c 不包含 --tag=...
```

- JSON/Completion: reserved; integrate by real demand and dependency readiness

## Examples index
- Default subcommand and caller-owned help
  - examples/fafafa.core.args.command/example_usage_default
- Schema + Usage rendering (caller prints)
  - examples/fafafa.core.args.command/example_help_schema
- ENV → argv merge
  - examples/fafafa.core.args.command/example_env_merge

- Simple to use, robust in behavior, framework‑grade quality
- First‑class support for Windows/Unix CLI styles
- Backed by unit tests and iterative evolution

## Quick Start

Convenience functions (no breaking changes):

```pascal
var v: string;
if ArgsTryGetValue('json', v) then ...
if ArgsHasFlag('no-console') then ...
for s in ArgsPositionals do ...
if ArgsIsHelpRequested then ShowHelp;
```

Object‑oriented API (recommended):

```pascal
var A: TArgs; n: Int64; d: Double; b: Boolean;
A := TArgs.FromProcess;
if A.TryGetInt64('samples', n) then ...
if A.TryGetDouble('rate', d) then ...
if A.TryGetBool('enabled', b) then ...
for var it in A do HandleItem(it);            // items (args + options)
for var s in A.GetArgEnumerator do UseArg(s); // positionals
for var opt in A.GetOptionEnumerator do UseOpt(opt);
```

## Parsing Rules
- Long options: `--k`, `--k=v`, `--k:v`, `--k v`
- Short options:
  - Short flags combo: `-abc` => `-a -b -c`
  - Key/value: `-o=out`, `-o:out`, `-o out`
- Windows style: `/k`, `/k=v`, `/k:v`, `/long`, `/long=value`, `/long:value`
- Double dash: `--` stops parsing; everything after is positional（当 StopAtDoubleDash=False 时，`--` 本身作为位置参数保留，且后续同样视为位置参数）
- Negative numbers: `-1.23` not split into short flags; accepted as values when appropriate
- Case: keys are case‑insensitive by default

## API Reference

Types:
- `TArgKind = (akArg, akOptionShort, akOptionLong)`
- `TArgItem = record Name, Value: string; HasValue: boolean; Kind: TArgKind end;`

Options:
- `function ArgsOptionsDefault: TArgsOptions;`
- `TArgsOptions` fields: `CaseInsensitiveKeys`, `AllowShortFlagsCombo`, `AllowShortKeyValue`, `StopAtDoubleDash`, `TreatNegativeNumbersAsPositionals`, `EnableNoPrefixNegation`

Core parse:
- `procedure ParseArgs(const Args: array of string; const Opts: TArgsOptions; out Ctx: TArgsContext);`

OO API:
- `TArgs.FromProcess`, `TArgs.FromArray(Args, Opts)`
- Queries: `Count`, `Items(i): TArgItem`, `Positionals: TStringArray`
- Lookups: `HasFlag`, `TryGetValue(key, out string)`, `GetAll(key): TStringArray`
- Typed getters: `TryGetInt64`, `TryGetDouble`, `TryGetBool`, and `Get*Default` variants
- Iterators: `GetEnumerator` (all items), `GetArgEnumerator` (positionals), `GetOptionEnumerator` (options only)

Convenience:
- `ArgsHasFlag`, `ArgsTryGetValue`, `ArgsGetAll`, `ArgsPositionals`, `ArgsIsHelpRequested`

## Best Practices
- Prefer long option names for clarity, use short flags for ergonomics
- Normalize keys to lower case in help/docs to align with case‑insensitive default
- Use `GetAll` for repeatable options (e.g., `--tag=a --tag=b`)
- Always keep `--` behavior predictable; pass literal arguments after it
- For numeric parameters, use typed getters to avoid parsing boilerplate

## Examples

Basic CLI:
```pascal
var A := TArgs.FromProcess;
if A.HasFlag('help') then ShowHelpAndExit;
var input := A.GetStringDefault('input', 'stdin');
var threads := A.GetInt64Default('threads', 4);
var tags := A.GetAll('tag');
for var f in A.GetArgEnumerator do ProcessFile(f);
```

Windows/Unix mixed and literal arguments after "--":
```pascal
var opts := ArgsOptionsDefault;
// StopAtDoubleDash=True (default), everything after "--" treated as positionals
var A := TArgs.FromArray(['--input=file', '/v', '--', '--not-flag', '/x', 'file2'], opts);
// A.Positionals = ['--not-flag','/x','file2']

// StopAtDoubleDash=False, "--" itself is kept as a positional and the rest are also positionals
opts.StopAtDoubleDash := False;
A := TArgs.FromArray(['pos1','--','/x'], opts);
// A.Positionals = ['pos1','--','/x']
```

No-prefix negation with overrides (last value wins):
```pascal
var opts := ArgsOptionsDefault; opts.EnableNoPrefixNegation := True;
var A := TArgs.FromArray(['--no-color', '--color=true', '--color=false'], opts);
// TryGetValue('color') -> 'false'
```

Short key with space-separated value:
```pascal
var opts := ArgsOptionsDefault;
var A := TArgs.FromArray(['-o', 'out.txt'], opts);
// TryGetValue('o') -> 'out.txt'
```

## Behavior Details
### 键名归一化与 no- 前缀（Dash→Dot 兼容）

- Dash→Dot：为了与配置键（如 TOML/JSON 的 `app.name`）统一，解析阶段会将选项名中的 `-` 视为分段分隔并转换为 `.`。因此 `--app-name` 与 `--app.name` 等价。
- 不影响检测：为确保 `--no-xxx` 正确识别，内部先用“检测态归一化”（不做 Dash→Dot）判断是否存在 `no-` 前缀，再对基础键做完整归一化存储。
- 无值 negation：`--no-color` 解析为 `color=false`；`-no-debug` 同理。
- 显式赋值：`--no-cache=false` 会同步影响 `cache=false`（并保留 `no-cache=false` 记录），保证“最后一次赋值覆盖”在基础键上生效。
- Windows 风格：`/no-verbose` 同样遵循上述规则。

示例：

```pascal
var opts := ArgsOptionsDefault; opts.EnableNoPrefixNegation := True;
var A := TArgs.FromArray(['--no-color','--color=true','--color=false'], opts);
// TryGetValue('color') -> 'false'
A := TArgs.FromArray(['--no-cache=false'], opts);
// TryGetBool('cache') -> False
```


- Value detection rules（NextIsValue）：
  - 下一个 token 为 `--` 时不作为值；
  - 以 `-` 开头的 token 仅在 `TreatNegativeNumbersAsPositionals=True` 且匹配负数样式时（如 `-1`, `-1.2`）才作为值；否则视为下一个选项/旗；
  - 以 `/` 开头的 token（Windows 选项风格）不作为值；
- `--no-xxx` 无值时，在 `EnableNoPrefixNegation=True` 下解析为 `xxx=false`；显式赋值（如 `--color=true/false`、`--no-cache=true/false`）按“后者覆盖前者”处理；
- `TryGetValue/Get*Default/TryGet*` 均遵循“最后一次赋值覆盖”规则。

## Compatibility Notes

- Windows-style options: tokens starting with '/' are treated as options; such tokens are never considered as values of the previous key.
- Short option bundles: when AllowShortFlagsCombo=True, '-abc' expands to '-a -b -c'; when False, '-abc' is a single flag name 'abc'.
- Double dash '--': StopAtDoubleDash=True (default) stops parsing and treats the rest as positionals; when False, '--' itself is kept as a positional and the rest are also positionals.
- Negative numbers: only considered as a value when TreatNegativeNumbersAsPositionals=True and the token looks like a negative number; '--' and '/'-prefixed tokens are never values.
- No-prefix negation: EnableNoPrefixNegation=False by default; when enabled, '--no-xxx' maps to 'xxx=false'. Explicit assignments (e.g. '--color=true/false') follow last-write-wins.
- Windows no- with assignment: when EnableNoPrefixNegation=True, '/no-xxx=value' and '/no-xxx:value' also map the base key 'xxx' to 'value' (and keep the literal no- key record), preserving last-write-wins semantics across long and Windows forms.


Example (Windows/Unix mix with StopAtDoubleDash=False):
```pascal
var opts := ArgsOptionsDefault; opts.StopAtDoubleDash := False;
var A := TArgs.FromArray(['pos1','--','/x','--not-flag'], opts);
// A.Positionals = ['pos1','--','/x','--not-flag']
```

## 与 GetOpt / CustApp 的对比与迁移

- 设计差异
  - GetOpt：过程式解析；需手工维护短/长选项、值提取与错误处理；无子命令树抽象
  - CustApp：基于 TCustomApplication 的 OO 框架；适合简单应用；对子命令、别名、兼容 Windows/Unix 混合风格支持较弱
  - fafafa.core.args：
    - 统一 GNU/Windows 风格；可选大小写不敏感、短旗帜合并、no- 否定与双横线哨兵
    - 子命令树、别名、默认子命令；帮助渲染由调用方控制（不隐式输出）
    - 轻量扩展：ENV/CONFIG → argv 映射，便于按“CONFIG→ENV→CLI”合并

- 最小迁移示例：从 GetOpt 迁移到 TArgs

旧（示意）：

```pascal
uses GetOpt;
var Opts: string = 'hv:o:'; LongOpts: array[1..2] of TOption = (
  (Name:'help'; Has_arg:0; Flag:nil; Value:'h'),
  (Name:'output'; Has_arg:1; Flag:nil; Value:'o')
);
var c: char;
begin
  repeat
    c := GetLongOpts(Opts, @LongOpts[1], c);
    case c of
      'h': ShowHelpAndExit;
      'o': Output := OptArg;
    end;
  until c = EndOfOptions;
end.
```

新（等价最小化）：

```pascal
uses fafafa.core.args;
var A: TArgs; outPath: string;
begin
  A := TArgs.FromProcess;
  if A.HasFlag('help') or A.HasFlag('h') or A.HasFlag('?') then ShowHelpAndExit;
  outPath := A.GetStringDefault('output', 'out.txt'); // 支持 --output= 也支持 -o
  // 其余逻辑...
end.
```

- 从 CustApp 迁移到子命令（示意）

## 常见陷阱与规约（强烈建议阅读）

- 大小写一致性
  - 默认键名大小写不敏感；建议在文档与帮助文本统一使用小写，避免困惑
  - 如需严格区分大小写，可通过 Options 切换

- Dash→Dot 归一
  - 解析阶段将选项名中的 `-` 视为分段分隔并转换为 `.`，`--app-name` 与 `--app.name` 等价
  - 与 CONFIG/ENV 的扁平键策略一致（点分路径）

- 双横线 `--` 哨兵
  - StopAtDoubleDash=True（默认）：`--` 后所有 token 视为位置参数
  - StopAtDoubleDash=False：`--` 本身也作为位置参数保留

- 负数值判定
  - TreatNegativeNumbersAsPositionals=True 时，`-1`、`-1.2` 等负数样式可作为值；否则视作“短选项起始”，避免误判
  - 以 `--`、`/` 起始的 token 永不作为值

- Windows 形式
  - 以 `/` 起始的 token 一律视为选项；绝不作为前一键的值

- no- 前缀与覆盖策略（EnableNoPrefixNegation）
  - `--no-x` → `x=false`
  - 显式赋值：`--no-cache=false` 同步影响 `cache=false`，并保留 `no-cache=false` 记录；Windows `/no-x=value`、`/no-x:value` 同理
  - 多次赋值遵循“最后一次赋值覆盖”（TryGetValue/Typed getters 走尾到头查找）

- 短旗帜合并
  - AllowShortFlagsCombo=True：`-abc` 展开为 `-a -b -c`；False：作为单个 flag 名 `abc`

- 多次赋值与全部收集
  - 若需收集全部值（如重复 `--tag`），使用 `GetAll`；否则默认“尾写覆盖”

- 空值与有值约定
  - `--k` 表示“无值”的存在开关；`--k=` 表示存在空字符串值（区分对待）

- 字面量参数的传递
  - 使用 `--` 将剩余 token 按原样作为位置参数传递（如 `-- --not-flag /x`）


```pascal
uses fafafa.core.args, fafafa.core.args.command;

function RunBuild(const X: IArgs): Integer; begin if X=nil then; Writeln('build'); Exit(0); end;
function RunTest(const X: IArgs): Integer; begin if X=nil then; Writeln('test'); Exit(0); end;

var Root: IRootCommand; opts: TArgsOptions;
begin
  Root := NewRootCommand;
  Root.Register(NewCommandPath(['build'], @RunBuild));
  Root.Register(NewCommandPath(['test'], @RunTest));
  opts := ArgsOptionsDefault;
  Halt(Root.Run(opts));
end.
```

注意：示例不改变现有库的行为；帮助/Usage 的打印时机完全由调用方决定。
## Source Precedence (recommended)

- Merge order: CONFIG -> ENV -> CLI (later sources override earlier ones)
- Example:
  - CONFIG (toml/json): count=2
  - ENV: APP_COUNT=3, APP_DEBUG=
  - CLI: --count=5
  - Effective: count=5, debug=true

## 可选数据源与降级策略（最佳实践）

- 默认仅使用 ENV + CLI；不做任何隐式文件读取
- CONFIG 文件（TOML/JSON/YAML）为“可选依赖”，通过条件编译宏显式启用：
  - {$DEFINE FAFAFA_ARGS_CONFIG_TOML} / {$DEFINE FAFAFA_ARGS_CONFIG_JSON}
  - 未启用或解析失败时，ArgvFromToml/ArgvFromJson/ArgvFromYaml 返回空数组（不抛错、不打印日志）
- 合并顺序固定：CONFIG -> ENV -> CLI（后者覆盖前者；库内部查值遵循“最后一次赋值覆盖”）
- 是否读取哪个配置文件、在哪里查找，由应用自行决定（库不扫描默认路径）

示例：合并 CONFIG、ENV 与 CLI（启用相应宏时）
```pascal
var
  opts: TArgsOptions;
  cfgArgv, envArgv, cliArgv, merged: TStringArray;
begin
  opts := ArgsOptionsDefault;
  // 1) CONFIG（可选，需启用相应宏；未启用或文件缺失将返回空数组）
  {$IFDEF FAFAFA_ARGS_CONFIG_TOML}
  cfgArgv := ArgvFromToml('config.toml');
  {$ELSEIF DEFINED(FAFAFA_ARGS_CONFIG_JSON)}
  cfgArgv := ArgvFromJson('config.json');
  {$ELSE}
  SetLength(cfgArgv, 0);
  {$ENDIF}

  // 2) ENV（推荐作“轻量配置”，使用固定前缀，例：APP_）
  envArgv := ArgvFromEnv('APP_');

  // 3) CLI（真实进程参数，此处仅示例）
  cliArgv := ['run','--count=5'];

  // 按顺序合并（后覆盖前）
  merged := cfgArgv + envArgv + cliArgv;
  Halt(NewRootCommand.Run(merged, opts));
end;
```


### Usage 渲染选项（纯文本、可配置）
- RenderUsageOptions 现新增：
  - showSectionHeaders: 是否显示分节标题（Aliases/Flags/Args），默认 true
  - groupFlagsBy/groupPositionalsBy: 分组/排序策略，默认 gbNone
    - gbNone：保持现有顺序
    - gbRequired：先必选再可选（组内稳定字母序）
    - gbAlpha：按名称字母序
- 其他：保持纯文本输出，不引入颜色；wrap/width 行为不变

示例：
```pascal
var Opts := RenderUsageOptionsDefault;
Opts.width := 80;
Opts.groupFlagsBy := gbRequired;
Opts.groupPositionalsBy := gbAlpha;
Opts.showSectionHeaders := False;
Writeln(RenderUsage(Cmd, Opts));
```

#### 无分节标题（showSectionHeaders = False）版式规范
- 目标：保持与默认模式一致的行内结构与对齐，仅隐藏 “Aliases/Flags/Args” 标题，不改变块内内容顺序
- 空行策略：
  - 顶部保留 1 行空白
  - 各块之间不额外插入空行（避免“去掉标题后又多出一行空白”的抖动）
- 对齐与换行：
  - 仍使用空格对齐（等宽字体效果最佳）；wrap/width 生效逻辑与默认一致
  - 标注顺序为：标签列 → 元信息（required/default/type）→ 描述；软换行时在描述段处理
- 分组/排序：遵循 groupFlagsBy / groupPositionalsBy 的设定

#### 控制台与 GUI 的使用建议
- 渲染结果为纯文本（无 ANSI 颜色），与输出介质解耦：
  - 控制台：直接 Writeln(RenderUsage(...))；如需稳定宽度，显式设置 Opts.width
  - GUI：
    - 方案 A：使用等宽字体的文本控件展示渲染文本（对齐一致、集成成本低）
    - 方案 B：基于规格对象（Flags/Positionals）自行构建界面组件，获得更丰富的交互/样式
- 提示：GUI 中若使用比例字体，文本列对齐会受影响，推荐改用组件化渲染或等宽字体


## Notes
- The module aims to be minimal yet complete. If you need an extended Help builder or command sub‑parsers, we can evolve this unit accordingly.
- Behavior is covered by unit tests. Please add tests when changing parsing rules.

