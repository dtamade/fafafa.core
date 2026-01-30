# JSON 字符串 UTF-8 最佳实践

目标
- 统一字符串读取/比较的编码语义，以 UTF-8 为基线，避免系统码页带来的不确定性
- 保持接口层兼容（String），同时提供 UTF8String 直通路径用于底层/字节级操作

核心 API
- 读取（底层字节直通）：`JsonGetStrUtf8(PJsonValue): UTF8String`
- 比较（字节级，不涉系统码页）：`JsonEqualsStrUtf8(PJsonValue, UTF8String): Boolean`
- 接口层：
  - `IJsonValue.GetString: String`（内部使用 UTF-8 安全路径）
  - `IJsonValue.GetUtf8String: UTF8String`
- 默认值：`JsonGetUtf8OrDefault(IJsonValue, UTF8String)`

推荐用法
- 读取为 String（UI/业务层常见）：
  - `S := Val.GetString;` 或 `S := String(JsonGetStrUtf8(V));`
- 读取为 UTF8String（底层/协议/字节操作）：
  - `U := Val.GetUtf8String;` 或 `U := JsonGetStrUtf8(V);`
- 比较字符串：
  - `JsonEqualsStrUtf8(V, UTF8String('literal'))`
- 提供默认值：
  - `JsonGetUtf8OrDefault(Val, '')`
- 字节级操作：
  - `U := JsonGetStrUtf8(V); Move(PAnsiChar(U)^, Bytes[0], N);`

常见误区
- `SetString(Result, JsonGetStr(V), JsonGetLen(V))` 可能受系统码页影响，应避免
- `JsonEqualsStr` + String 常量比较，可能隐含转换，应改为 `JsonEqualsStrUtf8`
- 以 PChar/长度进行“字符串语义”处理，容易混淆“字节长度 vs 字符长度”，尽量用 UTF-8 API

迁移与兼容
- 新增的 UTF-8 API 不破坏既有签名，旧代码可逐步迁移
- 接口层 `GetString` 已经内部统一走 UTF-8 路径，维持上层调用的兼容
- 单测与示例已替换为 UTF-8 安全 API，建议新代码遵循本指南

FAQ
- 问：为何不直接在所有地方强制 UTF8String？
  - 答：保持现有 String 接口有助于与框架/现有模块兼容；同时通过 `GetUtf8String` 提供零转换路径
- 问：如何在不同模块之间传递文本？
  - 答：约定边界：文本（String）或字节（UTF8String/RawByteString）。需要 UI/本地化则用 String；需要协议/二进制一致性用 UTF8String

参考位置
- 核心实现：`src/fafafa.core.json.core.pas`（JsonGetStrUtf8、JsonEqualsStrUtf8）
- 接口层：`src/fafafa.core.json.pas`（IJsonValue.GetUtf8String、JsonGetUtf8OrDefault）

