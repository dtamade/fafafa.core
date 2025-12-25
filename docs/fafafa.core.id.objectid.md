# fafafa.core.id.objectid 模块说明

ObjectId 是 MongoDB 风格的 12 字节唯一标识符，适合分布式系统使用。

## 特性

- 12 字节 (96 位)
- 布局: 4 字节时间戳 + 5 字节随机 + 3 字节计数器
- 24 字符十六进制字符串表示
- 时间有序 (旧 ID 排在新 ID 之前)
- 线程安全计数器递增
- 可从 ID 提取时间戳

## 快速开始

```pascal
uses fafafa.core.id.objectid;

var
  Id: TObjectId;
  S: string;
begin
  // 生成 ObjectId
  Id := ObjectId;

  // 转换为字符串
  S := ObjectIdToString(Id);  // "507f1f77bcf86cd799439011"

  // 从字符串解析
  Id := ObjectIdFromString('507f1f77bcf86cd799439011');
end;
```

## ObjectId 结构

```
| 字节 | 位范围 | 内容 |
|------|--------|------|
| 0-3  | 0-31   | Unix 时间戳 (秒, 大端) |
| 4-8  | 32-71  | 随机值 (每进程唯一) |
| 9-11 | 72-95  | 原子计数器 (大端) |
```

## 时间戳提取

```pascal
var
  Id: TObjectId;
  T: TDateTime;
  Unix: UInt32;
begin
  Id := ObjectId;

  // 提取为 TDateTime
  T := ObjectIdTimestamp(Id);

  // 提取为 Unix 时间戳
  Unix := ObjectIdUnixTimestamp(Id);

  WriteLn('Created at: ', DateTimeToStr(T));
end;
```

## 批量生成

```pascal
var
  Ids: TObjectIdArray;
begin
  // 批量生成
  Ids := ObjectIdN(100);
end;
```

## 验证与比较

```pascal
var
  Id1, Id2, NilId: TObjectId;
begin
  Id1 := ObjectId;
  Id2 := ObjectId;

  // 验证字符串
  if IsValidObjectIdString('507f1f77bcf86cd799439011') then
    WriteLn('有效 ObjectId');

  // 相等检查
  if ObjectIdEquals(Id1, Id2) then
    WriteLn('相等');

  // 比较
  case ObjectIdCompare(Id1, Id2) of
    -1: WriteLn('Id1 < Id2');
     0: WriteLn('Id1 = Id2');
     1: WriteLn('Id1 > Id2');
  end;

  // 空值检查
  NilId := ObjectIdNil;
  if ObjectIdIsNil(NilId) then
    WriteLn('空 ObjectId');
end;
```

## 生成器模式

```pascal
var
  Gen: IObjectIdGenerator;
  Id: TObjectId;
  S: string;
  Ids: TObjectIdArray;
begin
  // 创建生成器
  Gen := CreateObjectIdGenerator;

  // 生成
  Id := Gen.Next;
  S := Gen.NextString;
  Ids := Gen.NextN(100);
end;
```

## 与 XID 的对比

| 特性 | ObjectId | XID |
|------|----------|-----|
| 大小 | 12 字节 | 12 字节 |
| 字符串长度 | 24 | 20 |
| 编码 | Hex | Base32 |
| 时间精度 | 秒 | 秒 |
| 机器标识 | 5 字节随机 | 3 字节随机 + 2 字节 PID |
| 计数器 | 3 字节 | 3 字节 |
| 兼容性 | MongoDB | Go rs/xid |

## API 参考

### 类型

| 类型 | 说明 |
|------|------|
| `TObjectId` | ObjectId 原始类型 (12 字节数组) |
| `TObjectIdArray` | ObjectId 数组 |
| `IObjectIdGenerator` | ObjectId 生成器接口 |

### 常量

| 常量 | 值 | 说明 |
|------|-----|------|
| `OBJECTID_SIZE` | 12 | 字节长度 |
| `OBJECTID_STRING_LENGTH` | 24 | Hex 字符串长度 |

### 函数

| 函数 | 说明 |
|------|------|
| `ObjectId: TObjectId` | 生成 ObjectId |
| `ObjectIdNil: TObjectId` | 返回空 ObjectId |
| `ObjectIdN(Count): TObjectIdArray` | 批量生成 |
| `ObjectIdToString(Id): string` | 转换为字符串 |
| `ObjectIdFromString(S): TObjectId` | 从字符串解析 |
| `IsValidObjectIdString(S): Boolean` | 验证字符串 |
| `ObjectIdTimestamp(Id): TDateTime` | 提取时间戳 |
| `ObjectIdUnixTimestamp(Id): UInt32` | 提取 Unix 时间戳 |
| `ObjectIdEquals(A, B): Boolean` | 相等检查 |
| `ObjectIdCompare(A, B): Integer` | 比较 |
| `ObjectIdIsNil(Id): Boolean` | 空值检查 |
| `CreateObjectIdGenerator: IObjectIdGenerator` | 创建生成器 |
