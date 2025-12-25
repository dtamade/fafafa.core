# fafafa.core.id.typeid 模块说明

TypeID 是 Stripe 风格的类型安全前缀 ID，将实体类型编码到 ID 中。

## 特性

- 格式: `<prefix>_<base32_uuid>` 如 `user_01h455vb4pex5vsknk084sn02q`
- 前缀: 只有小写字母 a-z (最多 63 字符)
- 后缀: UUIDv7 的 Crockford Base32 编码 (26 字符)
- 可排序: 底层使用 UUIDv7 保持时间顺序
- 对标: https://typeid.dev/

## 快速开始

```pascal
uses fafafa.core.id.typeid;

var
  Id: string;
begin
  // 生成带前缀的 TypeID
  Id := TypeId('user');     // "user_01h455vb4pex5vsknk084sn02q"
  Id := TypeId('order');    // "order_01h455vb4pex5vsknk084sn02q"
  Id := TypeId('invoice');  // "invoice_01h455vb4pex5vsknk084sn02q"
end;
```

## TypeID 结构

```
user_01h455vb4pex5vsknk084sn02q
^^^^_^^^^^^^^^^^^^^^^^^^^^^^^^^
 |         |
前缀      后缀 (Base32 UUID)
```

- **前缀**: 实体类型标识，小写字母 a-z，最多 63 字符
- **后缀**: UUIDv7 的 Crockford Base32 编码，26 字符

## 从 UUID 创建

```pascal
uses fafafa.core.id.typeid, fafafa.core.id;

var
  Uuid: TUuid128;
  Id: string;
begin
  // 从现有 UUID 创建
  Uuid := UuidV7_Raw;
  Id := TypeIdFromUuid('user', Uuid);

  // 创建空 TypeID
  Id := TypeIdNil('user');  // "user_00000000000000000000000000"
end;
```

## 解析

```pascal
var
  Parts: TTypeIdParts;
  Prefix: string;
  Uuid: TUuid128;
begin
  // 完整解析
  Parts := ParseTypeId('user_01h455vb4pex5vsknk084sn02q');
  Prefix := Parts.Prefix;  // "user"
  Uuid := Parts.Uuid;      // TUuid128

  // 安全解析
  if TryParseTypeId('user_01h...', Parts) then
    WriteLn('解析成功');

  // 单独提取组件
  Prefix := TypeIdGetPrefix('user_01h455vb4pex5vsknk084sn02q');
  Uuid := TypeIdGetUuid('user_01h455vb4pex5vsknk084sn02q');
end;
```

## 批量生成

```pascal
var
  Ids: TStringArray;
begin
  // 批量生成同类型 ID
  Ids := TypeIdN('user', 100);
end;
```

## 验证

```pascal
var
  Valid: Boolean;
begin
  // 验证前缀格式
  Valid := IsValidTypeIdPrefix('user');      // True
  Valid := IsValidTypeIdPrefix('User');      // False (大写)
  Valid := IsValidTypeIdPrefix('user123');   // False (含数字)

  // 验证完整 TypeID
  Valid := IsValidTypeId('user_01h455vb4pex5vsknk084sn02q');  // True

  // 验证并检查预期前缀
  Valid := IsValidTypeId('user_01h...', 'user');   // True
  Valid := IsValidTypeId('order_01h...', 'user');  // False
end;
```

## 生成器模式

```pascal
var
  Gen: ITypeIdGenerator;
  Id: string;
  Ids: TStringArray;
begin
  // 创建指定前缀的生成器
  Gen := CreateTypeIdGenerator('user');

  Id := Gen.Next;
  Ids := Gen.NextN(100);

  // 获取前缀
  WriteLn('Prefix: ', Gen.Prefix);  // "user"
end;
```

## 无前缀 TypeID

```pascal
var
  Id: string;
begin
  // 空前缀生成纯 Base32 UUID
  Id := TypeId('');  // "01h455vb4pex5vsknk084sn02q" (无下划线)
end;
```

## 编码/解码

```pascal
var
  Uuid: TUuid128;
  Suffix: string;
begin
  // 将 UUID 编码为 TypeID 后缀
  Uuid := UuidV7_Raw;
  Suffix := TypeIdEncode(Uuid);  // 26 字符 Base32

  // 将后缀解码为 UUID
  Uuid := TypeIdDecode('01h455vb4pex5vsknk084sn02q');
end;
```

## API 参考

### 类型

| 类型 | 说明 |
|------|------|
| `TTypeIdParts` | 解析结果 (Prefix, Uuid, Valid) |
| `ITypeIdGenerator` | TypeID 生成器接口 |
| `EInvalidTypeIdPrefix` | 无效前缀异常 |
| `EInvalidTypeId` | 无效 TypeID 异常 |

### 常量

| 常量 | 值 | 说明 |
|------|-----|------|
| `TYPEID_MAX_PREFIX_LENGTH` | 63 | 前缀最大长度 |
| `TYPEID_SUFFIX_LENGTH` | 26 | 后缀长度 |

### 函数

| 函数 | 说明 |
|------|------|
| `TypeId(Prefix): string` | 生成 TypeID |
| `TypeIdFromUuid(Prefix, Uuid): string` | 从 UUID 创建 |
| `TypeIdNil(Prefix): string` | 创建空 TypeID |
| `TypeIdN(Prefix, Count): TStringArray` | 批量生成 |
| `ParseTypeId(S): TTypeIdParts` | 解析 TypeID |
| `TryParseTypeId(S, Parts): Boolean` | 安全解析 |
| `TypeIdGetPrefix(S): string` | 提取前缀 |
| `TypeIdGetUuid(S): TUuid128` | 提取 UUID |
| `IsValidTypeIdPrefix(Prefix): Boolean` | 验证前缀 |
| `IsValidTypeId(S, ExpectedPrefix): Boolean` | 验证 TypeID |
| `CreateTypeIdGenerator(Prefix): ITypeIdGenerator` | 创建生成器 |
| `TypeIdEncode(Uuid): string` | 编码 UUID |
| `TypeIdDecode(Suffix): TUuid128` | 解码后缀 |
