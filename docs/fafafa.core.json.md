# fafafa.core.json 模块说明

本文档概述 JSON 读写与可变（Mutable）API 的使用方式与实现要点，包括 Writer flags、Mutable 模型、迭代器行为，以及删除/插入的注意事项与常见坑位。

> 推荐阅读：字符串读取/比较的 UTF-8 最佳实践见 docs/json-utf8.md（统一以 UTF-8 为基线，避免系统码页影响）。


## 快速开始（Facade）

```pascal
uses fafafa.core.json, fafafa.core.json.core;

var R: IJsonReader; W: IJsonWriter; Doc: IJsonDocument; V: IJsonValue; S: String;
begin
  R := NewJsonReader(nil);
  Doc := R.ReadFromString('{"a":1,"b":[true,null],"c":"hi"}', []);

  // 指针
  V := JsonPointerGet(Doc, '/b/0'); // => true

  // TryGet 对象键/数组项
  if JsonTryGetObjectValue(Doc.Root, 'a', V) then Writeln(V.GetInteger);
  if JsonTryGetArrayItem(Doc.Root, 0, V) then Writeln(V.GetType);

  // ForEach（可提前停止）
  JsonArrayForEach(Doc.Root, function(I: SizeUInt; Item: IJsonValue): Boolean
  begin
    if Item.IsBoolean then Writeln('bool');
    Result := True; // 返回 False 提前停止
  end);

  JsonObjectForEach(Doc.Root, function(const Key: String; Val: IJsonValue): Boolean
  begin
    Writeln(Key);
    Result := True;
  end);


  // Raw-Key 对象遍历（避免为 Key 分配 String）
  JsonObjectForEachRaw(Doc.Root, function(KeyPtr: PChar; KeyLen: SizeUInt; Val: IJsonValue): Boolean
  begin
    // 可按需转换为 String：
    var Key: String; SetString(Key, KeyPtr, KeyLen);
    Result := True;
  end);

  // Typed TryGet / OrDefault（不抛异常）
  var b: Boolean; i: Int64; u: UInt64; f: Double; str: String;
  if JsonTryGetBool(V, b) then Writeln(b);
  i := JsonGetIntOrDefault(V, -1);
  u := JsonGetUIntOrDefault(V, 0);
  f := JsonGetFloatOrDefault(V, 0.0);
  str := JsonGetStrOrDefault(V, '');

  // 写回
  W := NewJsonWriter;
  S := W.WriteToString(Doc, [jwfPretty]);
  Writeln(S);
end;
```

## Facade 便捷函数速览
- JsonPointerGet(ARoot|ADoc, '/path')
- JsonTryGetObjectValue(Obj, 'key', out V) / JsonTryGetArrayItem(Arr, idx, out V)
- JsonArrayForEach(Arr, (i, v) => bool) / JsonObjectForEach(Obj, (key, v) => bool)
  - JsonObjectForEachRaw(Obj, (keyPtr, keyLen, v) => bool) // 避免为 Key 分配 String，极端热路径更省分配

- JsonTryGetInt/UInt/Bool/Float/Str
- JsonGetIntOrDefault/UInt/Bool/Float/Str


## 变更速览（迁移指南：fixed → core）

### 门面最小化原则
- 门面单元（fafafa.core.json）仅保留接口、工厂（New*/Create*）与便捷函数（Pointer/TryGet/ForEach/Typed TryGet/OrDefault），全部逻辑委派到 core 实现（原 fixed）
- 额外接口文件（fafafa.core.json.interfaces）仅作为“别名/转发”，不再重复声明接口与 GUID，避免漂移

### 门面→core 委派映射表（核对清单；原 fixed）
- IJsonReader
  - ReadFromString / ReadFromStringN → JsonReadOpts（Allocator 透传）
- IJsonWriter
  - WriteToString → JsonWriteToString
- IJsonDocument
  - Root/Allocator/BytesRead/ValuesRead → TJsonDocument 对应字段
- IJsonValue
  - 类型判断：JsonIs*/UnsafeIs*
  - 数值获取：JsonGetBool/JsonGetInt/JsonGetUint/JsonGetNum
  - 字符串：JsonGetStr/JsonGetLen
  - 数组/对象：JsonGetLen/JsonArrGet/JsonObjGetN
- 便捷函数
  - JsonPointerGet → json.ptr.JsonPtrGet
  - JsonArrayForEach/JsonObjectForEach/JsonObjectForEachRaw → JsonArrIter*/JsonObjIter*
  - JsonTryGet*/JsonGet*OrDefault → IJsonValue.* + core.* 组合

### 错误消息规范
- 所有门面异常消息统一使用 src/fafafa.core.json.errors.pas 的常量（例如：Value is not a ...）
- 若底层 Err.Message 为空，则使用 JsonDefaultMessageFor(Err.Code) 的标准化文案

### 迁移步骤（最佳实践）
- 代码：将 uses 中的 `fafafa.core.json.fixed` 全部替换为 `fafafa.core.json.core`
- 构建：执行 tests/fafafa.core.json/BuildOrTest.bat test 或 bash tests/fafafa.core.json/BuildOrTest.sh test 验证 112/112 通过
- 文档/示例：将片段中的 uses 与文件路径（如 src/fafafa.core.json.fixed.pas）统一为 core
- 门面：继续通过 `fafafa.core.json` 暴露接口与便捷函数（内部委派 core），避免直接依赖实现层
- 命名：对外请统一使用 `core` 名称；仅在历史背景说明中提及 “fixed”

### 兼容性说明
- API：无行为变更；core 即原 fixed 的实现与语义
- 测试：迁移后全量测试保持全绿（92/92），验证安全性
- 性能：与原 fixed 一致；仅命名与组织结构收敛



- 新增（Facade）：
  - NewJsonReader/NewJsonWriter（与 Create* 等价，推荐使用 New* 风格；Create* 已标记为 deprecated）
  - JsonPointerGet 重载（IJsonValue/IJsonDocument）
  - JsonTryGetObjectValue / JsonTryGetArrayItem
  - JsonArrayForEach / JsonObjectForEach（回调返回 False 可“提前停止”）
  - Typed TryGet：JsonTryGetInt/UInt/Bool/Float/Str
  - OrDefault：JsonGetIntOrDefault/UInt/Bool/Float/Str
- 建议替换：
  - 业务不希望抛异常的 Get* => 换用 TryGet 或 OrDefault
  - 手写 for/while 遍历 => 使用 JsonArrayForEach/JsonObjectForEach 提升可读性与一致性
- Flags 命名注意：
  - Reader 常用命名保持稳定：jrfAllowComments/jrfAllowTrailingCommas/jrfStopWhenDone/jrfAllowInfNan/jrfAllowInvalidUnicode
  - Writer 推荐使用：jwfPretty/jwfEscapeSlashes/jwfAllowInfNanAsNull（若旧项目使用不同命名，请参考源码枚举适配）
- 行为兼容性：
  - Facade 为薄封装，不改变 core 层行为；对象遍历会为 Key 创建一次 String，值保持零拷贝

## 与 yyjson 的 API 映射（更完整）

| yyjson (C)                               | fafafa.core.json.core                     | Facade / Notes                                  |
|------------------------------------------|-------------------------------------------|-------------------------------------------------|
| yyjson_read / yyjson_read_opts           | JsonRead / JsonReadOpts                   | Facade: IJsonReader.ReadFromString/ReadFromStringN |
  - Reader 默认分配器：若构造 IJsonReader 时未显式提供分配器（Allocator=nil），ReadFromString/ReadFromStringN 会自动回退至 GetRtlAllocator，避免“Invalid allocator”错误

| yyjson_write                              | JsonWriteToString（内部流式实现）         | Facade: IJsonWriter.WriteToString               |
| yyjson_get_type / subtype / tag          | JsonGetType / JsonGetSubtype / JsonGetTag | IJsonValue.GetType (枚举包装)                  |
| yyjson_get_bool / num / str / len        | JsonGetBool/Num/Str/Len                   | IJsonValue.GetBoolean/GetFloat/GetStringLength  |
| yyjson_equals_str / equals_strn          | JsonEqualsStr / JsonEqualsStrN            | —                                               |
| yyjson_mut_doc_new                        | JsonMutDocNew (若有)                      | —                                               |
| yyjson_mut_null/true/false/uint/sint/... | JsonMutNull/True/False/Uint/Sint/...      | —                                               |
| yyjson_mut_arr/obj                        | JsonMutArr/Obj                            | —                                               |
| yyjson_mut_arr_size/get/set/...           | JsonMutArrSize/Get/Set/...                | —                                               |
| yyjson_mut_arr_iter_*                     | JsonMutArrIter*                           | —                                               |
| yyjson_mut_obj_size/get/getn              | JsonMutObjSize/Get/GetN                   | —                                               |
| yyjson_mut_obj_iter_*                     | JsonMutObjIter*                           | —                                               |
| yyjson_obj_get/obj_getn (immutable)       | JsonObjGet/JsonObjGetN                    | Facade: JsonTryGetObjectValue                   |
| yyjson_arr_get (immutable)                | JsonArrGet                                | Facade: JsonTryGetArrayItem                     |
| yyjson_arr_iter_* (immutable)             | JsonArrIter*                              | Facade: JsonArrayForEach                        |
| yyjson_obj_iter_* (immutable)             | JsonObjIter*                              | Facade: JsonObjectForEach                       |
| —                                         | UnsafeIs*/UnsafeGet*                      | Facade 上的 Typed TryGet/OrDefault 基于 Is*/Get* |

说明：表格未列全所有可变对象操作（Add/Put/Insert/Remove 等），完整参考 src/fafafa.core.json.core.pas 与相关单测。


示例：异常改为宽容
```pascal
// 旧：类型不符会抛 EJsonValueError
val := V.GetInteger;

// 新：容错（不抛异常）
if JsonTryGetInt(V, i) then ... else ...;
// 或
i := JsonGetIntOrDefault(V, -1);
```

示例：遍历改造
```pascal
// 旧：手写下标/键
for i := 0 to Arr.GetArraySize-1 do ...

// 新：便捷 ForEach
JsonArrayForEach(Arr, function(I: SizeUInt; Item: IJsonValue): Boolean
begin
  ...
  Result := True;
end);
```


## Writer 概述与 Flags

- 默认（jwfDefault）：
  - 紧凑输出（minify）
  - 默认不写出 NaN/Infinity；默认不转义 Unicode/斜杠
  - 注意：Writer 内部已改为流式序列化实现，避免大对象/数组的字符串拼接退化
- jwfPretty：美化输出（缩进、换行）
- jwfEscapeUnicode：将非 ASCII 字符转义为 \uXXXX
- jwfEscapeSlashes：转义 "/"
- jwfAllowInfAndNan：允许写出 Inf/NaN（非标准）
- jwfInfAndNanAsNull：将 Inf/NaN 写成 null
- 若两者均未开启且文档中包含 NaN/Infinity，将返回写入错误（NanOrInf）
- jwfAllowInvalidUnicode：写入时放宽非法 Unicode

建议：
- 跨平台比对字符串时，优先采用 round-trip（写回->再读->再写）校验；仅在 jwfEscapeUnicode 路径使用严格 \uXXXX 断言。

## 热路径最佳实践（Performance Hot Path）

- 优先使用 Raw-Key 对象遍历，避免在热路径上为键名分配字符串：

  ```pascal
  JsonObjectForEachRaw(Root, function(KeyPtr: PChar; KeyLen: SizeUInt; Val: IJsonValue): Boolean
  begin
    // 避免临时 String，直接比较内容：
    if (KeyLen=4) and (StrLComp(KeyPtr, 'name', 4)=0) then ...;
    // 如需少量日志/调试时再转换：
    // var S: String; SetString(S, KeyPtr, KeyLen);
    Result := True;
  end);
  ```

- 值访问：在类型不确定或非关键路径中使用 TryGet/OrDefault，避免异常开销与分支噪声；在热路径已知类型的场景直接走 Get*（门面会在类型不匹配时抛异常，便于早暴露逻辑错误）。

  ```pascal
  var v: IJsonValue; i: Int64;
  if JsonTryGetObjectValue(Root, 'count', v) then
    if JsonTryGetInt(v, i) then ... else ...
  else
    i := 0; // OrDefault 也可
  ```

- Reader Flags 收敛：性能敏感路径下仅启用必要标志，避免多余的宽容/检查开销。
  - 例如默认严格模式 []；仅在需要时开启 jrfAllowComments/jrfAllowTrailingCommas。
  - 对流式/增量读取，分块大小以 64KB–256KB 量级为宜（避免过多系统调用与过大缓冲）。

- Writer 选择：
  - 批量/日志输出使用紧凑模式（不启用 jwfPretty），减少内存与格式化开销。
  - 大量字符串包含非 ASCII 时，谨慎开启 jwfEscapeUnicode；可用 round-trip 校验替代严格逐字符断言。

- 分配器复用：
  - Reader 默认 GetRtlAllocator() 已足够；如上层存在高频解析，可考虑为每个工作线程复用一个 TAllocator，避免频繁创建/销毁带来的碎片与锁竞争（保持线程隔离）。

- 迭代器与指针：
  - 优先使用零分配迭代器（JsonArrIter*/JsonObjIter*），通过门面 JsonArrayForEach/JsonObjectForEach/JsonObjectForEachRaw 即可享受零分配遍历。
  - JSON Pointer 用于“偶发”路径访问；热路径建议在解析后缓存目标节点的直接指针/接口引用（注意生命周期与文档所有权）。

- 错误与断言：
  - 热路径尽量少抛异常；将“可预期但非致命”的情况转为 Try* 或 OrDefault 分支。
  - 测试中对序列化字符串的断言，优先采用 round-trip 以降低平台差异造成的脆弱性。


## Mutable 模型

- 存储结构：
  - 数组：循环单链表，arr^.Data.Ptr 指向“最后一个元素”，最后元素 Next 指向第一个元素
  - 对象：循环单链表，以“键、值”成对串联；obj^.Data.Ptr 指向“最后一个键”，最后键的值的 Next 指向“第一个键”
- 长度：容器的长度存储在 Tag 的高位（UnsafeGetLen/UnsafeSetLen）

### 常用 API（节选）
- 数组：
  - JsonMutArrInsert/Append/Prepend/Replace/Remove/RemoveFirst/RemoveLast/Clear
  - 迭代器：JsonMutArrIterInit/HasNext/Next/IterRemove
- 对象：
  - JsonMutObjAdd/Put/Insert/Remove/RemoveKey/RemoveKeyN/Clear/Replace
  - 迭代器：JsonMutObjIterInit/HasNext/Next/IterGetVal/IterGet/IterGetN/IterRemove
  - 便捷添加：JsonMutObjAddNull/Bool/Uint/Sint/Real/Str/Arr/Obj 等

### 迭代器行为
- 初始化：迭代器 Cur 指向“最后元素/最后键”，第一次 Next 返回“第一个元素/第一个键”
- 删除：使用 IterRemove 删除“当前”元素（数组）或“当前键值对”（对象）；实现会维护 last 指针与长度
- 注意：迭代过程中不要调用其它修改函数（除 IterRemove），否则游标可能失效

## 删除/插入的实现要点与注意事项

- 对象删除（JsonMutObjRemoveKeyN）：
  - 删除最后键时需将 obj^.Data.Ptr 回退到上一键
  - 当对象仅 1 对键值对时，删除需将指针设为 nil 且长度置 0
  - 多次删除需正确维护“上一键/上一值/当前键”游标
- 对象插入（Insert at index）：
  - 若 idx < size，需要临时旋转 last 指针到 idx 位置之前，再尾部插入，最后还原 last
  - 若 idx == size，等价于 Add（尾插）
- Put 去重：
  - 第一次命中键时替换对应值，其后命中同键则删除（去重）；若全未命中则尾部追加
- 数组：
  - RemoveAt/RemoveFirst/RemoveLast 清除时更新 last 指针与长度
  - Clear 需将长度置 0 且 Ptr 设为 nil

## 测试覆盖摘要

核心用例（tests/fafafa.core.json）：
- Writer：转义、Unicode、Pretty、斜杠、Inf/NaN 等
- Reader：基础类型、注释、尾逗号、无效 Unicode 容忍、科学计数等
- Mutable：
  - 对象：Add/Put/Insert/Remove、边界删除（首/尾）、迭代删除、顺序稳定性、重复键去重
  - 数组：Append/Insert/Replace/Remove/IterRemove/Clear、越界保护
  - 嵌套结构：对象+数组组合构造与结构断言

## JSON Patch Helpers（合并补丁与操作补丁）

提供在 Facade 层对不可变文档应用补丁的便捷函数（helpers 单元：src/fafafa.core.json.patch.helpers.pas）：

- TryApplyJsonMergePatch(ADoc, PatchJson, out Updated, out Err)
  - 输入 PatchJson 必须是一个“对象”（RFC 7386）
  - 语义：对象字段合并；当 Patch 中字段值为 null 时表示删除该字段
- TryApplyJsonPatch(ADoc, PatchJson, out Updated, out Err)
  - 输入 PatchJson 必须是一个“数组”（RFC 6902），元素为 {op, path, ...}
  - 支持基本操作：add/replace/remove（其余 op 可逐步扩充）

注意：
- 不会修改传入的 ADoc，成功时返回一个新的 IJsonDocument
- 失败返回 False，并在 Err 中给出简短原因（如 'invalid arguments' / 'invalid patch' / 'clone failed'）
- 内部流程：Facade 写出字符串 -> core 读入为不可变 -> 克隆为 mutable -> 应用补丁 -> mutable 写回字符串 -> Facade 读入 -> 返回

示例（Merge Patch）

```pascal
uses fafafa.core.json, fafafa.core.json.patch.helpers;
var R: IJsonReader; D,U: IJsonDocument; Ok: Boolean; Err: String;
begin
  R := NewJsonReader(GetRtlAllocator);
  D := R.ReadFromString('{"o":{"x":1,"y":2}}');
  Ok := TryApplyJsonMergePatch(D, '{"o":{"y":null,"z":3}}', U, Err);
  if Ok then Writeln('z=', JsonPointerGet(U, '/o/z').GetInteger);
end.
```

示例（JSON Patch）

```pascal
var Patch: String; Ok: Boolean; Err: String;
begin
  D := R.ReadFromString('{"a":[1]}');
  Patch := '[{"op":"add","path":"/a/-","value":2},' +
           '{"op":"replace","path":"/a/0","value":9},' +
           '{"op":"remove","path":"/a/1"}]';
  Ok := TryApplyJsonPatch(D, Patch, U, Err);
  if Ok then Writeln(JsonPointerGet(U, '/a/0').GetInteger);
end.
```

何时使用 Merge Patch vs JSON Patch
- Merge Patch：按字段“合并 + null 表示删除”，适合整体替换/合并对象
- JSON Patch：精确路径操作，适合对数组插入（/a/-）与局部替换/删除

错误处理建议
- 边界检查：
  - Merge Patch 传入非对象（例如数组或标量）应返回 'invalid patch'
  - JSON Patch 传入非数组，应返回 'invalid patch'
  - 操作中路径不存在或类型不匹配时，返回 Err 并保持 ADoc 不变
- 断言风格：业务层优先断言返回值和关键字段变化；必要时只检查 Err 包含关键短语

## 示例

见 examples/fafafa.core.json/example_json.lpr：构造对象/数组，Pretty 输出，演示 Mutable API 的典型用法。

## 常见坑位

- 迭代器初始游标语义：Cur 指向最后，第一次 Next 返回第一个
- 删除时必须同步维护：
  - last 指针（Data.Ptr）
  - 长度（UnsafeSetLen）
  - 对象删除时，注意键值成对跳步（key->val->nextKey）
- 字符串比对：在非 EscapeUnicode 模式下跨平台断言应使用 round-trip

## 路线图（后续工作）

- Incremental Reader（流式/分块解析）
- JSON Pointer 与 Patch/Merge Patch
- 性能优化与基准



---

# Facade API Quick Guide

Modern, high‑performance JSON core for FreePascal with a clean facade and a yyjson‑aligned engine.

- Engine: src/fafafa.core.json.core.pas (yyjson‑like data layout and algorithms)
- Facade: src/fafafa.core.json.pas (stable, minimal surface)
- Goals: zero‑copy string access, fast parsing/writing, clean abstractions, cross‑platform

## Architecture & Layering

```
User code ──> Facade (interfaces) ──> Core engine (impl) ──> Allocator
```

## Public Facade APIs

- Reader
  - CreateJsonReader(Allocator: TAllocator = nil): IJsonReader
  - IJsonReader.ReadFromString(const S: String; Flags: TJsonReadFlags = []): IJsonDocument
  - IJsonReader.ReadFromStringN(P: PChar; Len: SizeUInt; Flags: TJsonReadFlags = []): IJsonDocument
- Writer
  - CreateJsonWriter: IJsonWriter
  - IJsonWriter.WriteToString(Doc: IJsonDocument; Flags: TJsonWriteFlags = []): String
- Document/Value
  - IJsonDocument.Root: IJsonValue
  - IJsonDocument.Allocator/BytesRead/ValuesRead
  - IJsonValue type checks: IsNull/IsBoolean/IsNumber/IsString/IsArray/IsObject
  - IJsonValue getters: GetBoolean/GetInteger/GetUInteger/GetFloat/GetString/GetStringLength
  - IJsonValue array/object: GetArraySize/GetArrayItem/GetObjectSize/GetObjectValue/HasObjectKey

Helper:
- JsonWrapDocument(ADoc: TJsonDocument): IJsonDocument
- JsonPointerGet(Doc: IJsonDocument; const Ptr: String): IJsonValue  // e.g. JsonPointerGet(D, '/a/1/k')

## Flags

Read: jrfDefault, jrfAllowComments, jrfAllowTrailingCommas, jrfAllowInvalidUnicode, jrfAllowBOM, jrfStopWhenDone, jrfNumberAsRaw, jrfBignumAsRaw, jrfAllowInfAndNan

- jrfAllowTrailingCommas 行为边界：
  - 允许：对象键值对、数组元素的尾随逗号（包括多层嵌套）
  - 不允许：根级的额外逗号行（仅以逗号作为一个独立项的场景会被拒绝）

Write: jwfDefault, jwfPretty, jwfEscapeUnicode, jwfEscapeSlashes, jwfAllowInfAndNan, jwfInfAndNanAsNull, jwfAllowInvalidUnicode

## Error Model

- Facade throws EJsonParseError when core returns error (Code/Position/Message)
- Error messages are normalized (capitalized) for stable assertions

## Examples

Reader with Flags（允许注释与尾随逗号）

```pascal
var Doc: TJsonDocument; Err: TJsonError; Root: PJsonValue;
const S = '{//c\n"a":1, "b":[1,2,],}';
begin
  Doc := JsonReadOpts(PChar(S), Length(S), [jrfAllowComments, jrfAllowTrailingCommas], GetRtlAllocator(), Err);
  if not Assigned(Doc) then Halt(1);
  Root := JsonDocGetRoot(Doc);
  // 访问 /b
  if JsonArrSize(JsonPtrGet(Root, '/b')) <> 2 then Halt(2);
  Doc.Free;
end;
```

StopWhenDone vs 默认严格模式

```pascal
var D: TJsonDocument; E: TJsonError;
const S = '123 456';
begin
  // 默认严格：后续字符导致失败（返回 nil）
  D := JsonReadOpts(PChar(S), Length(S), [], GetRtlAllocator(), E);
  if Assigned(D) then Halt(1);
  // StopWhenDone：读取首个值成功
  D := JsonReadOpts(PChar(S), Length(S), [jrfStopWhenDone], GetRtlAllocator(), E);
  if not Assigned(D) then Halt(2);
  D.Free;
end;
```

- Read & Traverse (facade)

```pascal
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
uses SysUtils, fafafa.core.mem.allocator, fafafa.core.json;
var R: IJsonReader; D: IJsonDocument; V: IJsonValue;
begin
  R := CreateJsonReader(GetRtlAllocator);
  D := R.ReadFromString('{"name":"Alice","age":30}', [jrfDefault]);
  V := D.Root;
  Writeln('name=', V.GetObjectValue('name').GetString);
end.
```

- Write (facade)

```pascal
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
uses SysUtils, fafafa.core.mem.allocator, fafafa.core.json.core, fafafa.core.json;
var D: TJsonDocument; S: String; W: IJsonWriter; Doc: IJsonDocument;
begin
  D := JsonRead(PChar('{"a":1}'), 6, [jrfDefault]);
  Doc := JsonWrapDocument(D);
  W := NewJsonWriter;
  S := W.WriteToString(Doc, [jwfPretty]);
  Writeln(S);
end.
```



## 统一错误消息策略（Error Message Policy）

- 统一常量与辅助
  - 常用类型断言失败文案集中于 src/fafafa.core.json.errors.pas：
    - JSON_ERR_VALUE_NOT_BOOLEAN / NUMBER / STRING / ARRAY / OBJECT
  - 默认消息与格式化：
    - JsonDefaultMessageFor(Code: TJsonErrorCode): string
    - JsonFormatErrorMessage(Err: TJsonError; IncludePosition: Boolean = True): string

- Facade 抛错
  - IJsonValue 的 Getter 在类型不匹配时抛出 EJsonParseError（Code=jecInvalidParameter；Message 使用上述常量）
  - 这样可以避免分散硬编码，确保测试断言稳定

- No-Exception（读取重载）
  - 捕获 EJsonParseError：回填 Err.Code/Err.Position；若 E.Message 为空则回退 JsonFormatErrorMessage(Err, True)
  - 捕获其他 Exception：Err.Code=jecInvalidParameter；若 E.Message 为空则回退 JsonDefaultMessageFor(jecInvalidParameter)

- 建议
  - 业务层断言优先基于错误码（Err.Code 或异常 Code），必要时仅断言消息包含关键短语
  - 如需国际化或统一风格，可集中修改 errors 单元而无需改动调用处

## JSON Pointer 便捷方法（Facade）

- 提供只读路径访问的便捷函数（内部委派 core.ptr）：
  - JsonPointerGet(ADoc: IJsonDocument; const APointer: String): IJsonValue
  - JsonPointerGet(ARoot: IJsonValue; const APointer: String): IJsonValue
  - TryJsonPointerGet(ARoot: IJsonValue; const APointer: String; out AValue: IJsonValue): Boolean
- 未命中返回 nil（或 Try* 返回 False），不抛异常；不修改文档内容

语义说明（实现兼容但非完全 RFC 6901）：
- 空指针 "" 返回根值
- 单独斜杠 "/" 被视为非法（不支持空 token 作为键名），返回 nil
- 双斜杠导致空 token（如 "/a//x"）为非法，返回 nil
- 反转义规则：~0 → ~，~1 → /（示例：键名 "a/b" 对应路径 token "a~1b"）

示例

```pascal
uses fafafa.core.mem.allocator, fafafa.core.json;
var R: IJsonReader; D: IJsonDocument; V: IJsonValue;
begin
  R := NewJsonReader(GetRtlAllocator);
  D := R.ReadFromString('{"a":[{"k":"v"},{"k":"v2"}],"o":{"a/b":1}}', [jrfDefault]);
  V := JsonPointerGet(D, '/a/1/k');
  if (V <> nil) and V.IsString then Writeln(V.GetString);
  // 反转义示例：访问键 "a/b"
  V := JsonPointerGet(D, '/o/a~1b');
  if (V <> nil) and V.IsNumber then Writeln(V.GetInteger);
  // 非法路径示例："/" 或 "/a//x" 返回 nil
end.
```


### 快速示例（Facade + Pointer 一把过）

```pascal
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json;
var R: IJsonReader; D: IJsonDocument; V: IJsonValue;
begin
  R := NewJsonReader(GetRtlAllocator);
  D := R.ReadFromString('{"a":[{"k":"v"},{"k":"v2"}],"b":123}', [jrfDefault]);
  V := JsonPointerGet(D, '/a/1/k');
  if (V <> nil) and V.IsString then
    Writeln('a[1].k = ', V.GetString)
  else
    Writeln('not found');
end.
```

## Facade 工厂风格与 No-Exception 用法

- 推荐使用 NewJsonReader/NewJsonWriter（与框架风格一致）；Create* 已标记为 deprecated，仅保留兼容，不建议在新代码中使用
- 纯门面单元：src/fafafa.core.json.pas（接口+委派），实现细节在 .core 与 .facade

### 快速示例（No-Exception 读取）

```
uses fafafa.core.json.noexcept;
var R: TJsonReaderNoExcept; D: IJsonDocument; Code: Integer;
begin
  R := TJsonReaderNoExcept.New(GetRtlAllocator);
  Code := R.ReadFromString('{"a":1}', D, [jrfDefault]);
  if Code = 0 then Writeln('ok') else Writeln('err=', Code);
end.
```

### 快速示例（No-Exception 写入）

```
uses fafafa.core.json.noexcept, fafafa.core.json;
var R: TJsonReaderNoExcept; D: IJsonDocument; S: String; Code: Integer;
begin
  R := TJsonReaderNoExcept.New(GetRtlAllocator);
  Code := R.ReadFromString('{"ok":true}', D, [jrfDefault]);
  if Code <> 0 then Halt(1);
  Code := TJsonWriterNoExcept.WriteToString(D, S, [jwfPretty]);
  if Code = 0 then Writeln(S);
end.
```

### 运行示例

- Windows
  - examples\fafafa.core.json\BuildOrRun_NoExcept.bat
  - examples\fafafa.core.json\BuildOrRun_NoExcept_Writer.bat
- Linux/macOS
  - bash examples/fafafa.core.json/BuildOrRun_NoExcept.sh
  - bash examples/fafafa.core.json/BuildOrRun_NoExcept_Writer.sh


## Streaming Reader（增量/分块读取）

- No-Exception 风格：通过 IJsonStreamReader 进行分块喂入与尝试解析
- 返回码：0 成功；Ord(jecMore) 需要继续喂入；其他为错误

最小示例：

```
var SR: IJsonStreamReader; Doc: IJsonDocument; Code: Integer;
SR := NewJsonStreamReader(64*1024, GetRtlAllocator, [jrfDefault]);
// 每次读取一块数据后：
Code := SR.Feed(PChar(@Buf[0]), ReadBytes);
Code := SR.TryRead(Doc);
if Code = 0 then { 使用 Doc } else if Code = Ord(jecMore) then { 继续读取 };
```

注意：
- 对于非常大的输入，推荐 Streaming Reader；一次性 ReadFromStream 会将全部数据读入内存
- UTF-8 跨块会被正确处理；遇到不完整数据将返回 jecMore

## 构建与运行示例（Win/Linux/macOS）

- 输出目录
  - 可执行：examples/fafafa.core.json/bin/
  - 中间文件：examples/fafafa.core.json/lib/

- Windows（推荐）
  - 最小示例：examples\fafafa.core.json\BuildOrRun_Min.bat
  - 全量示例：examples\fafafa.core.json\BuildAndRunExamples.bat
  - No-Exception：examples\fafafa.core.json\BuildOrRun_NoExcept.bat / BuildOrRun_NoExcept_Writer.bat
  - 说明：脚本会优先使用 tools\lazbuild.bat；若缺失则回退到系统 PATH 中的 lazbuild。构建或运行失败会输出 [BUILD]/[RUN] 前缀并返回非零退出码。

- Linux/macOS（推荐）
  - 最小示例：bash examples/fafafa.core.json/BuildOrRun_Min.sh
  - 单例示例：bash examples/fafafa.core.json/BuildOrRun.sh
  - No-Exception：bash examples/fafafa.core.json/BuildOrRun_NoExcept.sh / BuildOrRun_NoExcept_Writer.sh
  - 说明：可通过环境变量覆盖 LAZBUILD，例如 LAZBUILD=/opt/lazarus/lazbuild bash BuildOrRun.sh；构建或运行失败会输出 [BUILD]/[RUN] 前缀并返回非零退出码。

- 注意事项
  - 脚本默认使用 Debug 构建（--bm=Debug），并在 GUI 环境下使用 --ws=nogui 以减少不必要依赖。
  - 示例程序含中文输出，确保终端使用 UTF‑8（Windows Terminal/PowerShell 建议设置编码为 UTF‑8）。
  - 库源码不添加 {$CODEPAGE UTF8}；仅示例/测试程序添加。


---

## 本轮更新（2025-08-17）
- 测试基线确认：112/112 全绿；统一建议使用 tests/fafafa.core.json/BuildOrTest.bat test 或 bash tests/fafafa.core.json/BuildOrTest.sh test
- 后续将统一 examples 构建脚本为 lazbuild，并补强快速示例与 README


## Facade 最小化设计草案（委派映射，草案，不落代码）

目标：json.pas 仅保留接口/工厂/便捷函数，全部委派至 core 引擎（原 fixed）；避免重复实现，降低维护成本。

- Reader
  - IJsonReader.ReadFromString/ReadFromStringN → JsonReadOpts(..., Allocator, Err) 成功则 JsonWrapDocument
- Writer
  - IJsonWriter.WriteToString → JsonWriteToString(Doc, Flags)
- Document/Value
  - IJsonDocument.Root → TJsonValueImpl(Core.Root)
  - IJsonValue.* → UnsafeIs*/JsonGet*/JsonArr* / JsonObj*
- Pointer/Helpers（只读）
  - JsonPointerGet(ARoot/ADoc, Ptr) → json.ptr.JsonPtrGet(...)
- 便捷函数（不改变行为）
  - JsonTryGet*/JsonGet*OrDefault → 基于 Is*/Get* 组合
  - ForEach → 基于 JsonArrIter*/JsonObjIter*

委派策略：
- Facade 不持有额外状态，不做缓存；仅桥接接口与 core
- 异常模型：解析失败抛 EJsonParseError；类型断言失败抛 EJsonValueError，消息来自 json.errors 常量
- 迁移边界：现已统一为 .core 为主实现；json.pas 作为门面对外，避免使用 fixed 命名
