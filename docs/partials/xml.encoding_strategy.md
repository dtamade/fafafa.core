# Reader 编码策略设计草案

目标：在 ReadFromStream/ReadFromFile 中正确处理输入编码，兼容常见 BOM/声明 encoding 场景，提供“自动转码”与“原始字节 + 指定编码”两种策略。

## 现状
- ReadFromString：假定传入字符串已在正确编码（建议 UTF-8）。
- ReadFromStream：未内建 BOM/声明 encoding 解析，按字节读取。
- 当前实现（进行中）：默认 AssumeUTF8；当设置 xrfAutoDecodeEncoding 时，支持 UTF-16(LE/BE) 与 UTF-32(LE/BE) BOM 自动转码并解析。


## 场景与策略

- 场景A：通用 XML 文件，可能含 BOM 或声明 encoding
  - 策略A1（自动转码，默认）
    - 读取起始若干字节探测 BOM（UTF-8/UTF-16LE/UTF-16BE/UTF-32LE/UTF-32BE）
    - 若无 BOM，则解析 XML 声明中的 encoding（仅限 ASCII 可读范围）
    - 建立解码器，将底层流按目标编码转 UTF-8 供解析器使用
    - 优点：上层使用透明；缺点：解码开销与实现复杂度增加
  - 策略A2（原始字节 + 指定编码）
    - 解析器保持当前行为（按字节读取，视作 UTF-8）；额外暴露接口供调用方声明编码
    - 在需要获取文本值时，调用方自行转码
    - 优点：实现简单、性能基线稳定；缺点：上层负担增加

- 场景B：已知为 UTF-8 且无 BOM
  - 直接按现状读取；可通过 Flags 显式指示（如 xrfAssumeUTF8）以跳过探测

## 兼容性矩阵（概念草案）

- 输入 BOM / 声明 encoding | 策略A1 | 策略A2
- UTF-8 BOM / encoding=UTF-8 | 识别并转为 UTF-8 | 由上层声明/忽略
- UTF-16/UTF-32 BOM           | 识别并转为 UTF-8 | 由上层声明，或提前转码
- 无 BOM，encoding=ISO-8859-1 | 解析声明并转为 UTF-8 | 上层负责在 Value 层转码

## API 草案

- ReadFromStream(AStream, Flags, InitialBufCap): IXmlReader
  - 新增 Flags：
    - xrfAssumeUTF8：跳过 BOM/encoding 探测，按 UTF-8 处理
    - xrfAutoDecodeEncoding（默认开）：启用 BOM/声明 encoding 自动解码
- IXmlReader：
  - property DeclaredEncoding: String read GetDeclaredEncoding; // 若解析到声明 encoding，返回其值
  - property EffectiveEncoding: String read GetEffectiveEncoding; // 最终使用的输入编码（如 UTF-8）

## 实现要点

- 在拉流入口（首次 EnsureLookahead）提升探测流程：
  - 读取至多 4/8 字节用于 BOM 判定；
  - 若无 BOM，则读取一小段 ASCII 文本，尝试匹配 <?xml ... encoding="..."?>
- 自动转码实现：
  - 建立一个小型转换层（基于 ICU 替代、或内置若干常用单字节表 + UTF-16/32）；
  - 为避免复制过多，可边读边转写到内部 UTF-8 缓冲；
  - 流式窗口管理需兼容该转换层（以 UTF-8 字节为单位）。

## 迁移建议

- 短期：
  - 提供 xrfAssumeUTF8 与 xrfAutoDecodeEncoding 两个 Flags，默认开启自动解码，保持对常见文件的开箱即用；
  - 文档明确“若你已知输入始终 UTF-8，可关闭自动解码获取极致基线性能”。
- 中期：
  - 扩充单字节编码表覆盖常见西欧、拉美与东欧语系；
  - 提供错误恢复策略（替换字符/报错/跳过模式）。

