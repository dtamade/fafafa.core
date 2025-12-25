# fafafa.core.id 模块架构

本文档描述 fafafa.core.id 模块的整体架构、设计决策和扩展指南。

## 模块概览

fafafa.core.id 是一个全面的唯一标识符生成库，支持多种 ID 格式：

```
fafafa.core.id                    # 门面单元 (主入口)
├── fafafa.core.id.uuid           # UUID 核心实现
├── fafafa.core.id.ulid           # ULID 实现
├── fafafa.core.id.ksuid          # KSUID 实现
├── fafafa.core.id.snowflake      # Snowflake 实现
├── fafafa.core.id.xid            # XID 实现
├── fafafa.core.id.nanoid         # NanoID 实现
├── fafafa.core.id.cuid2          # CUID2 实现
├── fafafa.core.id.typeid         # TypeID 实现
├── fafafa.core.id.objectid       # ObjectId 实现
├── fafafa.core.id.timeflake      # Timeflake 实现
└── fafafa.core.id.builder        # 统一 Builder API
```

## 依赖关系图

```
                    fafafa.core.id (门面)
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
    fafafa.core.id.uuid  fafafa.core.id.ulid  ...
           │               │
           ▼               ▼
    fafafa.core.id.rng (共享 RNG)
           │
           ▼
    fafafa.core.crypto.random (底层密码学随机)
```

## 核心设计原则

### 1. 接口驱动

所有 ID 生成器都实现标准接口：

```pascal
// 通用生成器接口模式
IXxxGenerator = interface
  function Next: TXxx;           // 生成单个
  function NextN(Count): TArray; // 批量生成
end;
```

### 2. 线程安全

所有全局生成器都是线程安全的：

- 使用 `TCriticalSection` 保护共享状态
- 使用内存屏障确保可见性
- 原子计数器用于序列号

### 3. 双重检查锁定 (DCL)

单例初始化使用 DCL 模式：

```pascal
function GetDefaultGenerator: IGenerator;
var
  LocalGen: IGenerator;
begin
  LocalGen := GDefaultGenerator;
  ReadWriteBarrier;
  if LocalGen <> nil then Exit(LocalGen);

  GInitLock.Acquire;
  try
    if GDefaultGenerator = nil then
    begin
      LocalGen := CreateGenerator;
      ReadWriteBarrier;
      GDefaultGenerator := LocalGen;
    end;
    Result := GDefaultGenerator;
  finally
    GInitLock.Release;
  end;
end;
```

### 4. 安全清理

敏感数据在 `finalization` 时清零：

```pascal
finalization
  FillChar(GMachineId[0], SizeOf(GMachineId), 0);
  GProcessId := 0;
```

## 类型定义

### 基础 ID 类型

| 类型 | 大小 | 用途 |
|------|------|------|
| `TUuid128` | 16 字节 | UUID v4/v5/v6/v7 |
| `TUlid128` | 16 字节 | ULID |
| `TKsuid160` | 20 字节 | KSUID |
| `TSnowflakeID` | Int64 | Snowflake |
| `TXid96` | 12 字节 | XID |
| `TObjectId` | 12 字节 | ObjectId |
| `TTimeflake` | 16 字节 | Timeflake |

### 编码格式

| ID 类型 | 编码 | 字符串长度 |
|---------|------|------------|
| UUID | Hex + 破折号 | 36 |
| ULID | Crockford Base32 | 26 |
| KSUID | Base62 | 27 |
| Snowflake | 十进制 | 可变 |
| XID | Crockford Base32 | 20 |
| ObjectId | Hex | 24 |
| Timeflake | Base62 | 22 |
| NanoID | 可配置 | 默认 21 |
| CUID2 | Base36 | 默认 24 |
| TypeID | Base32 + 前缀 | 可变 |

## 时间戳布局

### 毫秒精度 (48 位)

UUID v7, ULID, Timeflake 使用 48 位毫秒时间戳：

```
[0-5] 48 位 Unix 毫秒时间戳 (大端)
[6-15] 随机/序列数据
```

### 秒精度 (32 位)

XID, ObjectId, KSUID 使用 32 位秒时间戳：

```
[0-3] 32 位 Unix 秒时间戳 (大端)
[4-N] 机器 ID / 随机 / 计数器
```

## 单调性保证

### 同毫秒递增

UUID v7 Monotonic, ULID, Timeflake Monotonic 在同毫秒内递增随机部分：

```pascal
if Ms = FLastMs then
begin
  // 递增 80 位随机部分
  Carry := 1;
  for I := 9 downto 0 do
  begin
    Carry := Carry + FLastRandom[I];
    FLastRandom[I] := Carry and $FF;
    Carry := Carry shr 8;
    if Carry = 0 then Break;
  end;
end;
```

### 溢出处理策略

| 策略 | 说明 |
|------|------|
| WaitNextMs | 等待下一毫秒 |
| WrapToZero | 序列回绕到 0 |
| RaiseError | 抛出异常 |

## 随机数生成

### 缓冲 RNG

`fafafa.core.id.rng` 提供优化的缓冲随机数生成：

```pascal
procedure IdRngFillBytes(out Buf; Count: Integer);
```

优势：
- 减少系统调用开销
- 预填充随机缓冲区
- 线程安全

### 密码学安全

底层使用 `fafafa.core.crypto.random`：
- Linux: `/dev/urandom`
- Windows: `BCryptGenRandom`

## 扩展指南

### 添加新 ID 类型

1. 创建单元 `fafafa.core.id.myid.pas`
2. 定义类型：`TMyId = array[0..N] of Byte`
3. 实现生成函数：`function MyId: TMyId`
4. 实现字符串转换：`MyIdToString`, `MyIdFromString`
5. 实现生成器接口：`IMyIdGenerator`
6. 添加线程安全保护
7. 添加 finalization 清理
8. 在 `fafafa.core.id` 门面中导出

### 示例骨架

```pascal
unit fafafa.core.id.myid;

interface

type
  TMyId = array[0..N] of Byte;

  IMyIdGenerator = interface
    function Next: TMyId;
    function NextString: string;
  end;

function MyId: TMyId;
function MyIdToString(const Id: TMyId): string;
function CreateMyIdGenerator: IMyIdGenerator;

implementation

uses SyncObjs, fafafa.core.id.rng;

var
  GGenerator: IMyIdGenerator;
  GLock: TCriticalSection;

function GetDefaultGenerator: IMyIdGenerator;
begin
  // DCL 模式实现
end;

function MyId: TMyId;
begin
  Result := GetDefaultGenerator.Next;
end;

initialization
  GLock := TCriticalSection.Create;

finalization
  GGenerator := nil;
  GLock.Free;

end.
```

## 性能考虑

### 热路径优化

- 使用栈分配而非堆分配
- 预计算查表
- 避免字符串拼接，使用 `SetLength` + 直接索引

### 锁粒度

- 单调生成器：每次生成加锁
- 非单调生成器：无锁（仅随机填充）

### 批量生成

批量 API 减少锁获取次数：

```pascal
function NextN(Count: Integer): TArray;
begin
  FLock.Acquire;
  try
    SetLength(Result, Count);
    for I := 0 to Count - 1 do
      Result[I] := GenerateInternal;
  finally
    FLock.Release;
  end;
end;
```

## 测试策略

### 测试类型

1. **单元测试**: 格式验证、编解码往返
2. **线程安全测试**: 多线程并发生成唯一性
3. **时钟回拨测试**: 模拟时间倒退场景
4. **边界条件测试**: Worker ID 边界、序列溢出

### 测试位置

```
tests/fafafa.core.id/
├── Test_fafafa_core_id_global.pas       # 门面测试
├── Test_fafafa_core_id_threadsafe.pas   # 线程安全
├── Test_fafafa_core_id_clockrollback.pas # 时钟回拨
├── Test_fafafa_core_id_boundary.pas     # 边界条件
└── ...
```

## 安全注意事项

1. **不要暴露内部状态**: 机器 ID、进程 ID 等不应可查询
2. **使用密码学安全随机**: 不要使用 `Random()`
3. **清理敏感数据**: finalization 时清零
4. **防止时间戳泄露**: 某些 ID 可提取时间，注意隐私

## 版本兼容性

- 生成的 ID 格式遵循各自规范，跨语言兼容
- 内部实现可能变化，但外部 API 稳定
