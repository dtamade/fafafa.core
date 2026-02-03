# fafafa.core.sync.rwlock.guard

Rust 风格的带数据保护的读写锁容器。

## 概述

`fafafa.core.sync.rwlock.guard` 模块实现了 Rust `std::sync::RwLock<T>` 的语义：使用读写锁保护一个泛型值，提供读锁（共享）和写锁（独占）两种访问模式。

## 核心特性

- **读写分离**: 多个读者可以并发访问，写者独占访问
- **类型安全**: 数据与锁绑定，确保在持有锁时才能访问
- **RAII 风格**: 析构时自动释放锁
- **便捷 API**: 提供自动加解锁的 GetValue/SetValue 方法

## 安装

```pascal
uses
  fafafa.core.sync.rwlock.guard;
```

## API 参考

### TRwLockGuard<T> 泛型类

```pascal
type
  generic TRwLockGuard<T> = class
  public type
    PT = ^T;

  public
    constructor Create(const AValue: T);
    destructor Destroy; override;

    // 读锁 API
    function ReadLock: PT;              // 获取读锁
    function ReadLockPtr: PT;           // ReadLock 的别名
    function TryReadLock: PT;           // 非阻塞尝试
    function TryReadTimeout(ATimeoutMs: Cardinal): PT;  // 带超时
    procedure ReadUnlock;               // 释放读锁

    // 写锁 API
    function WriteLock: PT;             // 获取写锁
    function WriteLockPtr: PT;          // WriteLock 的别名
    function TryWriteLock: PT;          // 非阻塞尝试
    function TryWriteTimeout(ATimeoutMs: Cardinal): PT; // 带超时
    procedure WriteUnlock;              // 释放写锁

    // 便捷 API（自动加解锁）
    function GetValue: T;               // 读取值
    procedure SetValue(const AValue: T);  // 设置值

    // 函数式更新
    procedure Update(AFunc: TUpdateFunc);   // 函数式更新
    procedure Update(AProc: TUpdateProc);   // 过程式更新

    // 状态查询
    function IsReadLocked: Boolean;
    function IsWriteLocked: Boolean;

    // 高级 API
    function GetMut: PT;                // 无锁获取（调用方保证安全）
    function IntoInner: T;              // 消费容器获取值
  end;
```

## 使用示例

### 基本读写操作

```pascal
var
  Config: specialize TRwLockGuard<string>;
  P: ^string;
begin
  Config := specialize TRwLockGuard<string>.Create('default');
  try
    // 读取（多个线程可以并发读取）
    P := Config.ReadLock;
    WriteLn('当前配置: ', P^);
    Config.ReadUnlock;

    // 写入（独占访问）
    P := Config.WriteLock;
    P^ := 'new_value';
    Config.WriteUnlock;
  finally
    Config.Free;
  end;
end;
```

### 多读者并发访问

```pascal
type
  TReaderThread = class(TThread)
  private
    FGuard: specialize TRwLockGuard<TConfigData>;
  protected
    procedure Execute; override;
  end;

procedure TReaderThread.Execute;
var
  P: ^TConfigData;
begin
  while not Terminated do
  begin
    P := FGuard.ReadLock;
    try
      ProcessConfig(P^);  // 多个读者可同时执行
    finally
      FGuard.ReadUnlock;
    end;
    Sleep(10);
  end;
end;
```

### 独占写入

```pascal
type
  TWriterThread = class(TThread)
  private
    FGuard: specialize TRwLockGuard<TConfigData>;
  protected
    procedure Execute; override;
  end;

procedure TWriterThread.Execute;
var
  P: ^TConfigData;
begin
  P := FGuard.WriteLock;
  try
    P^.Version := P^.Version + 1;
    P^.LastModified := Now;
  finally
    FGuard.WriteUnlock;
  end;
end;
```

### 使用 TryReadLock/TryWriteLock

```pascal
// 非阻塞读取
P := Config.TryReadLock;
if P <> nil then
try
  DisplayValue(P^);
finally
  Config.ReadUnlock;
end
else
  WriteLn('读取跳过：有写者持有锁');

// 带超时的写入
P := Config.TryWriteTimeout(1000);  // 1秒超时
if P <> nil then
try
  P^ := ComputeNewValue;
finally
  Config.WriteUnlock;
end
else
  WriteLn('写入超时');
```

### 便捷方法

```pascal
// GetValue/SetValue 自动处理加解锁
var
  CurrentValue: string;
begin
  CurrentValue := Config.GetValue;   // 自动 ReadLock + 复制 + ReadUnlock
  Config.SetValue('new_value');      // 自动 WriteLock + 赋值 + WriteUnlock
end;
```

### 函数式更新

```pascal
// 使用函数更新
function UpperCase(const S: string): string;
begin
  Result := UpCase(S);
end;

Config.Update(@UpperCase);

// 使用匿名过程就地更新
Config.Update(procedure(var S: string)
begin
  S := S + '_modified';
end);
```

## 保护复杂数据结构

```pascal
type
  TSharedCache = record
    Data: TStringList;
    LastUpdate: TDateTime;
    HitCount: Integer;
  end;

var
  Cache: specialize TRwLockGuard<TSharedCache>;

// 读取缓存（并发安全）
function GetCacheData(const Key: string): string;
var
  P: ^TSharedCache;
begin
  P := Cache.ReadLock;
  try
    Inc(P^.HitCount);  // 注意：这里修改了数据！应该用 WriteLock
    Result := P^.Data.Values[Key];
  finally
    Cache.ReadUnlock;
  end;
end;

// 更新缓存（独占）
procedure UpdateCache(const Key, Value: string);
var
  P: ^TSharedCache;
begin
  P := Cache.WriteLock;
  try
    P^.Data.Values[Key] := Value;
    P^.LastUpdate := Now;
  finally
    Cache.WriteUnlock;
  end;
end;
```

## 与 Rust RwLock<T> 对比

| 特性 | TRwLockGuard<T> | Rust RwLock<T> |
|------|-----------------|----------------|
| 读写分离 | ✅ | ✅ |
| 编译时安全 | 部分 | ✅（借用检查器）|
| 中毒机制 | ❌ | ✅ |
| 降级支持 | ❌（使用独立模块）| ✅ |

## 注意事项

1. **不要嵌套锁定**: 已持有读锁时调用 `TryReadLock` 会抛出 `ELockError`
2. **写者优先**: 当有写者等待时，新的读者可能被阻塞
3. **指针生命周期**: `ReadLock`/`WriteLock` 返回的指针在对应 `Unlock` 后失效
4. **ReadLock 中不要修改数据**: 虽然技术上可行，但违反读写锁语义

## 相关模块

- `fafafa.core.sync.mutex.guard` - 互斥锁版本的 Guard
- `fafafa.core.sync.rwlock` - 底层读写锁
- `fafafa.core.sync.rwlock.downgrade` - 写锁降级为读锁

## 版本历史

- v1.0.0 (2025-12): 初始版本
