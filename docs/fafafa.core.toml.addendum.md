# fafafa.core.toml Addendum: Quoted Keys and Unicode Escapes

This addendum clarifies the behavior of quoted keys and how Unicode escapes are handled in the reader.

## Quoted keys follow the same rules as basic strings

- Quoted keys (e.g., "name") are parsed using the same escape rules as TOML basic strings.
- Supported escapes: `\"`, `\\`, `\n`, `\r`, `\t`, `\b`, `\f`, `\uXXXX`, `\UXXXXXXXX`.
- Unicode escapes:
  - `\uXXXX` requires exactly 4 hex digits
  - `\UXXXXXXXX` requires exactly 8 hex digits
  - Maximum code point is `U+10FFFF`
  - Surrogate range `U+D800`–`U+DFFF` is forbidden
- Unknown or malformed escapes cause parsing to fail with an error.
- Quoted keys must be closed by a matching `"`; otherwise parsing fails.

## Consistency guarantee

- The reader now parses quoted keys by delegating to the same routine used for basic strings, so behavior is identical between keys and values.
- This removes historical divergence and prevents subtle bugs.

## Practical implications

- To express the key `A` using an escape, you can write `"\u0041"` or `"\U00000041"`.
- Invalid examples that will fail to parse:
  - `"a\u12"` (too short)
  - `"a\uZZZZ"` (non-hex)
  - `"a\uD800"` (surrogate)
  - `"a\U110000"` (out of range)

## Test coverage

- The test suite includes positive and negative cases for quoted keys with Unicode escapes, table headers, and inline tables. All tests pass.

# fafafa.core.toml（补充说明）

本补充文档同步当前实现与最佳实践，涵盖键名、字符串转义、数值、Writer 输出策略等关键点。

## 键名（Keys）
- 大小写敏感：foo 与 Foo 视为不同键
- bare 键：允许字符集 [A-Za-z0-9_-]；否则必须使用 quoted 键
- quoted 键：使用双引号包裹，可使用转义序列（见下）
- 路径：dotted 与表头 [table]/[[array-of-tables]] 共享相同解析规则，逐段 ensure 子表，最终段写值
- 冲突：同一路径重复定义或类型冲突立即报错

## 字符串与转义（Strings & Escapes）
- 支持普通双引号、三引号多行；单引号字面量与其三引号多行（字面量不解析转义）
- 普通双引号字符串转义序列：
  - 通用：\" \\ \n \r \t \b \f
  - Unicode：\uXXXX（4 位十六进制）、\UXXXXXXXX（8 位十六进制）
    - 码点范围：0..10FFFF
    - 禁止代理项码点（D800–DFFF）；\u 形式不允许表示代理对；\U 必须是完整码点
    - 非法形式/越界/位数不足/非 hex 均报错
- Writer 输出：
  - 字符串按需转义上述字符；非 ASCII 字符直接以 UTF‑8 输出（不强制 unicode 转义）

## 数值（Numbers）
- 整数/浮点：遵循 TOML 规范的下划线位置合法性；浮点小数点使用 '.'
- 禁止：NaN、Inf、-Inf（任何大小写变种均不接受）

### 数字负例清单（与测试用例一致）
- 非法下划线（整数/浮点/指数）：
  - _1、1_、1__2
  - 1e（缺指数数字）、1e+、1e-、1e_10、1e10_、1e1__0、1e+_10、1e+-10、1e-+10
  - _1.0（小数点前导下划线）
- 进制前缀整数（0x/0o/0b）非法下划线：
  - 0x_1、0x1_、0x1__2
  - 0o_7、0o7_、0o7__1
  - 0b_1、0b1_、0b1__0
- 前导零（当前实现允许，暂列为 TODO 观察）
  - 01、00.1

## Writer 输出策略（稳定性优先）
- 键顺序：每个表内按“标量 → AoT（数组表） → 子表”输出；开启 SortKeys 时按字典序
- 等号风格：
  - 默认 key = value（等号两侧空格，更可读）
  - 开关：twfSpacesAroundEquals（与默认一致）、twfTightEquals（切换为 key=value；若同时指定，以 Tight 优先）
- 表头：
  - 子表：[path]
  - 数组表：[[path]]（逐项展开）
- 键名引号：当键包含非 bare 集字符时自动加引号，且转义必要字符

## 错误处理
- 错误包含：Code、Message、Position（字节偏移）、Line、Column
- 错误消息简短稳定，便于测试断言；精确定位首个出错位置

## 测试与验证
- 回归测试：Reader/Writer 全路径覆盖；负例包含：
  - 非法下划线、重复键、路径冲突、无等号
  - 非法转义/非法码点/越界 unicode、NaN/Inf
- 新增用例：\b/\f、\u0061、\U0001F600 等
- 命令：tests/fafafa.core.toml/BuildOrTest.bat test

## FAQ（常见问题）
- 为什么 Writer 不强制将非 ASCII 转义为 \u？
  - 为保持可读性与大小（且 TOML 允许 UTF‑8），我们保留原字符，仅在必要字符处转义
- dotted 与 [table] 谁先输出？
  - Writer 在一个表的上下文中，先输出该表内的标量，然后 AoT，最后子表。子表递归同样规则


