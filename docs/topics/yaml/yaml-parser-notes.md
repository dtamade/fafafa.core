# YAML 解析器（Phase‑1）实现说明

本文档简要说明 src/fafafa.core.yaml.impl.pas 中 Phase‑1 解析器的设计与实现，帮助后续维护与扩展。

## 支持范围（Phase‑1）
- 文档流/文档事件：STREAM_START/END, DOCUMENT_START/END
- 简单映射（mapping）：以 `key: value` 形式的若干对，支持：
  - 分隔符：逗号 `,` 与分号 `;`（可混用）
  - 注释：`#` 至行尾
  - 换行：CR/LF/CRLF
  - 空值：`key:` 允许 `value` 为空
- 标量（scalar）：非映射时按单行读取，裁剪尾随空白和注释
- 暂不支持（后续阶段）：序列、复杂标量样式、锚点/别名、标签/tag 等

## 配置
- `FYPCF_RESOLVE_DOCUMENT`：开启后，解析器尝试将文档解析为映射；否则退化为“整行标量”。

## 核心设计
解析以“统一扫描器 + 预取驱动状态机”为核心：
- 统一扫描器 `Parser_ScanNextPair`：自 `fromPos` 起，切分并返回下一对 `key/value`，并给出下一轮起点 `nextPos`
- 预取驱动：状态机在发出 value 之后，再次调用扫描器预取下一对，以决定后续切换，而非在状态机中散落扫描细节

### Key/Value 切分规约（Scanner）
1) 跳过：行结束(CR/LF/CRLF)、单个分隔符(, ;)及其后的空格、整行注释（`#` 至行尾）
2) Key：从当前位置到同一行的 `:` 之前，去掉尾随空白/换行；允许 Key 为空
3) Value：从 `:` 后首个非空格开始，直至 注释/分隔符/换行/EOF；再去掉尾随空白/换行，允许空值(len=0)
4) nextPos：位于本 value 的末尾，继续跳过空白/单个分隔符/整行注释/换行，作为下一轮起点
5) keyAtBOL：若本对 Key 出现在行首（上一字符是换行），置 True，用于多行末尾空值的收尾判定

### 状态机（简版）
- stage 0 -> STREAM_START
- stage 1 -> DOCUMENT_START
- stage 2 -> 若允许解析文档，则调用扫描器预取：
  - 命中：设置 mapping/has_pair，发 MAPPING_START
  - 未命中：按单行 SCALAR 读取（裁剪注释与尾随空白）
- stage 3 -> 若 mapping：发出 Key 的 SCALAR；否则 DOCUMENT_END
- stage 4 -> 若 mapping：
  - 若 has_pair=False：发 MAPPING_END
  - 否则：
    - 特例：若“Key 位于行首 + 最后一对 + 空值”，发 MAPPING_END（不发空标量）
    - 其余：发 Value 的 SCALAR，并预取下一对决定是否继续（设置 has_pair）
  - 非 mapping：STREAM_END
- 收尾序列：MAPPING_END -> DOCUMENT_END -> STREAM_END

### 状态转移图（Mermaid）
```mermaid
stateDiagram-v2
    [*] --> S0
    state S0 {
      [*] --> STREAM_START
      STREAM_START --> S1
    }
    state S1 {
      [*] --> DOCUMENT_START
      DOCUMENT_START --> S2
    }
    state S2 {
      [*] --> PreFetch
      PreFetch --> MAPPING_START: found pair
      PreFetch --> SCALAR: no pair (line scalar)
      SCALAR --> DOCUMENT_END --> STREAM_END --> [*]
      MAPPING_START --> S3
    }
    S3 --> KEY_SCALAR --> S4
    state S4 {
      [*] --> Decide
      Decide --> MAPPING_END: no next pair OR last-pair-empty-at-BOL
      Decide --> VALUE_SCALAR: normal value
      VALUE_SCALAR --> S3: next pair exists
      MAPPING_END --> DOCUMENT_END --> STREAM_END --> [*]
    }
```

## 事件与内存
- 仅在生成 `SCALAR` 事件时分配 `TFyToken`；释放由 `yaml_impl_parser_event_free` 统一处理
- 统一的收尾序列保证不会遗漏释放路径

## 示例
1) 单行映射，逗号分隔
```
a:1, b: 2 , c:3 # trailing comment
```
事件序列（省略 anchor/tag 等）：
- STREAM_START
- DOCUMENT_START
- MAPPING_START
- SCALAR(key=a), SCALAR(val=1)
- SCALAR(key=b), SCALAR(val=2)
- SCALAR(key=c), SCALAR(val=3)
- MAPPING_END
- DOCUMENT_END
- STREAM_END

2) 分号与注释混用
```
a:1 ; b:2 # cmt
; c: 3
```
- MAPPING_START
- (a,1)(b,2)(c,3)
- MAPPING_END ...

3) 多行 + 空值
```
a: 1
b:
c: 3
```
- 对 b: 的 value 为空；若为“最后一对 + key 位于行首 + 空值”，直接结束映射，不生成空标量（测试用例覆盖）

4) 非映射（未启用解析文档）
```
a: 1, b:2 # comment
```
- 按单行 SCALAR 输出，值为 `"a: 1, b:2"`（尾随注释与空白被裁剪）

## 实现定位
- 扫描器与状态机实现：`src/fafafa.core.yaml.impl.pas`
  - `Parser_ScanNextPair`：统一切分/预取/推进
  - `yaml_impl_parser_parse`：状态机驱动
- 类型与常量：`src/fafafa.core.yaml.types.pas`

## 测试
- 运行：tests/fafafa.core.yaml/buildOrTest.bat
- 当前 35 项全部通过；heaptrc 报告 0 未释放内存

## 维护建议
- 新增特性前，尽量在扫描器层补充能力（减少状态机分叉）
- 补充更多边界用例：
  - 多行中间空值 + 注释夹杂
  - 分隔符稀奇组合的容错策略（按需）
  - 复杂标量样式/引号等（后续阶段）

