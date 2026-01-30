# fafafa.core.serialize 序列化模块设计蓝图 (serialize.md)

本文档旨在规划和指导 `fafafa.core.serialize` 模块的实现。该模块的目标是提供一个灵活、高性能的框架，用于将 Object Pascal 对象与多种数据格式（如 JSON、二进制）进行相互转换。

---

## 核心设计哲学

*   **接口驱动**: 序列化和反序列化过程由统一的 `ISerializer` 和 `IDeserializer` 接口驱动。
*   **格式可插拔**: 框架应能轻松支持新的序列化格式，而无需修改核心逻辑。
*   **自动化与手动并存**: 深度集成 RTTI 以实现对象的全自动序列化，同时提供手动序列化 API 以满足对性能和控制有极致要求的场景。
*   **流式处理**: 支持从 `TStream` 读取和写入，以高效处理大型数据，避免将所有内容一次性加载到内存。

---

## 开发路线图

### 阶段一: 核心接口与 JSON 实现

*目标: 搭建序列化框架的骨架，并实现最常用的 JSON 序列化功能。*

- [ ] **1.1. 创建 `fafafa.core.serialize.pas` 单元并定义核心接口**
    - `ISerializer`: `procedure Serialize(aObject: TObject; aStream: TStream);`
    - `IDeserializer`: `function Deserialize(aStream: TStream; aClass: TClass): TObject;`

- [ ] **1.2. 创建 `fafafa.core.serialize.json.pas` 并实现 JSON 序列化**
    - `TJsonSerializer = class(TInterfacedObject, ISerializer)`
    - `TJsonDeserializer = class(TInterfacedObject, IDeserializer)`
    - @desc: 实现将对象根据其 RTTI 信息转换为 JSON 文本，以及从 JSON 文本反序列化回对象。
    - **特性**: 支持属性的读写、支持嵌套对象和集合。

- [ ] **1.3. 设计 `TJsonWriter` 和 `TJsonReader`**
    - @desc: 提供底层的、流式的 JSON 生成和解析 API，这是 `TJsonSerializer` 的基础。
    - `TJsonWriter`: `WriteStartObject`, `WriteEndObject`, `WriteString`, `WriteNumber`, etc.
    - `TJsonReader`: `Read`, `TokenType`, `Value`, etc.

- [ ] **1.4. 设计序列化属性 (`Attributes`)**
    - @desc: 通过自定义属性来控制 RTTI 序列化的行为。
    - **示例**:
        ```pascal
        type
          [JsonIgnore]
          TMyClass = class
          private
            [JsonProperty('user_name')]
            FUserName: string;
          end;
        ```

---

### 阶段二: 高性能二进制序列化

*目标: 提供一个紧凑、快速的二进制序列化格式。*

- [ ] **2.1. 创建 `fafafa.core.serialize.binary.pas` 单元**
    - `TBinarySerializer = class(TInterfacedObject, ISerializer)`
    - `TBinaryDeserializer = class(TInterfacedObject, IDeserializer)`
    - @desc: 实现一个自定义的、注重性能和体积的二进制序列化协议。

- [ ] **2.2. 设计 `TBinaryWriter` 和 `TBinaryReader`**
    - @desc: 提供底层的二进制数据写入和读取工具，支持变长整数编码 (VarInt) 以节省空间。
    - `TBinaryWriter`: `WriteInt32`, `WriteVarInt`, `WriteString`, etc.
    - `TBinaryReader`: `ReadInt32`, `ReadVarInt`, `ReadString`, etc.

---

### 阶段三: 单元测试与集成

- [ ] **3.1. 编写详尽的单元测试**
    - [ ] `testcase_serialize_json.pas`: 测试各种数据类型、嵌套对象、数组和边界情况的 JSON 序列化。
    - [ ] `testcase_serialize_binary.pas`: 同上，针对二进制格式。
    - [ ] 测试自定义属性是否按预期工作。

- [ ] **3.2. 与集合模块集成**
    - [ ] 确保所有 `fafafa.core.collections` 中的容器都能被正确地序列化和反序列化。
