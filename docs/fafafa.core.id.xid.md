# fafafa.core.id.xid 模块说明

XID 是 MongoDB ObjectId 的现代替代方案，专为分布式系统设计的全局唯一、可排序 ID。

## 特性

- 12 字节 (96 位)
- 布局: 4 字节时间戳 + 3 字节机器 ID + 2 字节进程 ID + 3 字节计数器
- Base32 编码 (Crockford 变种): 20 字符
- 可排序: 时间戳在高位
- 线程安全
- 对标: https://github.com/rs/xid

## 快速开始

```pascal
uses fafafa.core.id.xid;

var
  X: TXid96;
  S: string;
begin
  // 生成 XID
  X := Xid;

  // 生成字符串格式
  S := XidString;  // "9m4e2mr0ui3e8a215n4g"

  // 指定时间生成
  X := XidFromTime(Now);
  X := XidFromUnix(1234567890);
end;
```

## XID 结构

```
| 字节 | 位范围 | 内容 |
|------|--------|------|
| 0-3  | 0-31   | Unix 时间戳 (秒, 大端) |
| 4-6  | 32-55  | 机器 ID (随机) |
| 7-8  | 56-71  | 进程 ID |
| 9-11 | 72-95  | 原子计数器 (随机起始) |
```

## 编码/解码

```pascal
var
  X: TXid96;
  S: string;
  Ok: Boolean;
begin
  // 编码为字符串
  X := Xid;
  S := XidToString(X);  // 20 字符 Base32

  // 解码
  X := XidFromString(S);

  // 安全解码 (不抛异常)
  Ok := TryXidFromString(S, X);
  if Ok then
    WriteLn('解析成功');
end;
```

## 组件提取

```pascal
var
  X: TXid96;
  T: TDateTime;
  Unix: Int64;
  MachineId: UInt32;
  ProcessId: Word;
  Counter: UInt32;
begin
  X := Xid;

  // 提取时间戳
  T := XidTimestamp(X);        // TDateTime
  Unix := XidUnixTime(X);      // Unix 秒

  // 提取其他组件
  MachineId := XidMachineId(X);  // 3 字节机器 ID
  ProcessId := XidProcessId(X); // 2 字节进程 ID
  Counter := XidCounter(X);    // 3 字节计数器
end;
```

## 批量生成

```pascal
var
  Ids: TStringArray;
  Arr: TXid96Array;
begin
  // 批量生成字符串
  Ids := XidN(100);

  // 批量生成原始字节
  Arr := XidBatchN(100);
end;
```

## 验证与比较

```pascal
var
  X1, X2: TXid96;
  Nil_X: TXid96;
begin
  X1 := Xid;
  X2 := Xid;

  // 验证字符串
  if IsValidXidString('9m4e2mr0ui3e8a215n4g') then
    WriteLn('有效 XID');

  // 比较
  if XidEquals(X1, X2) then
    WriteLn('相等');

  case XidCompare(X1, X2) of
    -1: WriteLn('X1 < X2');
     0: WriteLn('X1 = X2');
     1: WriteLn('X1 > X2');
  end;

  // 空值检查
  Nil_X := XidNil;
  if XidIsNil(Nil_X) then
    WriteLn('空 XID');
end;
```

## 生成器模式

```pascal
var
  Gen: IXidGenerator;
  X: TXid96;
  S: string;
  Ids: TStringArray;
begin
  Gen := CreateXidGenerator;

  X := Gen.Next;           // 原始字节
  S := Gen.NextString;     // 字符串格式
  Ids := Gen.NextN(100);   // 批量字符串
end;
```

## 与 MongoDB ObjectId 的对比

| 特性 | XID | ObjectId |
|------|-----|----------|
| 大小 | 12 字节 | 12 字节 |
| 字符串长度 | 20 | 24 |
| 编码 | Base32 | Hex |
| 时间精度 | 秒 | 秒 |
| 机器 ID | 3 字节 (随机) | 3 字节 (MD5) |
| 进程 ID | 2 字节 | 2 字节 |
| 计数器 | 3 字节 | 3 字节 |

## API 参考

### 类型

| 类型 | 说明 |
|------|------|
| `TXid96` | XID 原始类型 (12 字节数组) |
| `TXid96Array` | XID 数组 |
| `IXidGenerator` | XID 生成器接口 |
| `EInvalidXid` | 无效 XID 异常 |

### 常量

| 常量 | 值 | 说明 |
|------|-----|------|
| `XID_STRING_LENGTH` | 20 | Base32 字符串长度 |
| `XID_BYTE_LENGTH` | 12 | 字节长度 |

### 函数

| 函数 | 说明 |
|------|------|
| `Xid: TXid96` | 生成 XID |
| `XidString: string` | 生成字符串格式 |
| `XidFromTime(ATime): TXid96` | 指定时间生成 |
| `XidFromUnix(UnixSec): TXid96` | 指定 Unix 时间戳生成 |
| `XidN(Count): TStringArray` | 批量生成字符串 |
| `XidBatchN(Count): TXid96Array` | 批量生成原始数组 |
| `XidToString(X): string` | 编码为字符串 |
| `XidFromString(S): TXid96` | 从字符串解码 |
| `TryXidFromString(S, X): Boolean` | 安全解码 |
| `XidTimestamp(X): TDateTime` | 提取时间戳 |
| `XidUnixTime(X): Int64` | 提取 Unix 时间 |
| `XidMachineId(X): UInt32` | 提取机器 ID |
| `XidProcessId(X): Word` | 提取进程 ID |
| `XidCounter(X): UInt32` | 提取计数器 |
| `IsValidXidString(S): Boolean` | 验证字符串 |
| `XidIsNil(X): Boolean` | 检查空值 |
| `XidNil: TXid96` | 返回空 XID |
| `XidCompare(A, B): Integer` | 比较 |
| `XidEquals(A, B): Boolean` | 相等检查 |
| `CreateXidGenerator: IXidGenerator` | 创建生成器 |
