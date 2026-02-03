# fafafa.core.sync.mutex.guard

Rust 风格的带数据保护的互斥锁容器。

## 概述

`fafafa.core.sync.mutex.guard` 模块实现了 Rust `std::sync::Mutex<T>` 的语义：将数据与锁绑定，确保只能在持有锁时访问数据。这提供了比传统 mutex 更强的类型安全保证。

## 核心理念

传统方式：
```pascal
// 锁和数据分离，容易忘记加锁
var
  Mutex: IMutex;
  Counter: Integer;  // 数据与锁分离！
begin
  Counter := Counter + 1;  // 危险！忘记加锁
end;
```

Guard 方式：
```pascal
// 数据被锁保护，必须先获取锁才能访问
var
  Guard: specialize TMutexGuard<Integer>;
begin
  Guard.LockPtr^ := Guard.LockPtr^ + 1;  // 编译时强制获取锁
  Guard.Unlock;
end;
```

## 安装

```pascal
uses
  fafafa.core.sync.mutex.guard;
```

## API 参考

### TMutexGuard<T> 泛型类

```pascal
type
  generic TMutexGuard<T> = class
  public type
    PT = ^T;  // 值类型的指针

  public
    // 创建带初始值的 Guard
    constructor Create(const AValue: T);
    destructor Destroy; override;

    // 锁操作
    function LockPtr: PT;           // 获取锁，返回数据指针
    function Lock: PT;              // LockPtr 的别名
    function TryLock: PT;           // 非阻塞尝试获取锁
    function TryLockTimeout(ATimeoutMs: Cardinal): PT;  // 带超时
    procedure Unlock;               // 释放锁

    // 便捷方法
    function GetValue: T;           // 获取值的副本（自动加解锁）
    procedure SetValue(const AValue: T);  // 设置值（自动加解锁）

    // 状态查询
    function IsLocked: Boolean;     // 是否被当前上下文锁定

    // 函数式更新
    procedure Update(AFunc: TUpdateFunc);   // 函数式更新
    procedure Update(AProc: TUpdateProc);   // 过程式就地更新
  end;
```

## 使用示例

### 基本用法

```pascal
var
  Counter: specialize TMutexGuard<Integer>;
begin
  Counter := specialize TMutexGuard<Integer>.Create(0);
  try
    // 获取锁并修改数据
    Counter.LockPtr^ := Counter.LockPtr^ + 1;
    Counter.Unlock;

    // 读取数据
    WriteLn('Counter = ', Counter.GetValue);
  finally
    Counter.Free;
  end;
end;
```

### 保护复杂类型

```pascal
type
  TUserData = record
    Name: string;
    Age: Integer;
    Score: Double;
  end;

var
  UserGuard: specialize TMutexGuard<TUserData>;
  P: ^TUserData;
begin
  UserGuard := specialize TMutexGuard<TUserData>.Create(Default(TUserData));
  try
    P := UserGuard.Lock;
    try
      P^.Name := 'Alice';
      P^.Age := 25;
      P^.Score := 95.5;
    finally
      UserGuard.Unlock;
    end;
  finally
    UserGuard.Free;
  end;
end;
```

### 使用 TryLock 避免阻塞

```pascal
var
  SharedData: specialize TMutexGuard<string>;
  P: ^string;
begin
  SharedData := specialize TMutexGuard<string>.Create('initial');
  try
    P := SharedData.TryLock;
    if P <> nil then
    try
      P^ := 'updated';
    finally
      SharedData.Unlock;
    end
    else
      WriteLn('锁被其他线程持有，跳过更新');
  finally
    SharedData.Free;
  end;
end;
```

### 函数式更新

```pascal
function Increment(const V: Integer): Integer;
begin
  Result := V + 1;
end;

// 使用函数式更新
Counter.Update(@Increment);

// 或使用匿名过程
Counter.Update(procedure(var V: Integer)
begin
  V := V * 2;
end);
```

### 便捷方法

```pascal
// GetValue/SetValue 自动处理加解锁
var Value: Integer;
begin
  Value := Counter.GetValue;     // 自动 Lock + 读取 + Unlock
  Counter.SetValue(Value + 1);   // 自动 Lock + 写入 + Unlock
end;
```

## 多线程示例

```pascal
type
  TCounterThread = class(TThread)
  private
    FCounter: specialize TMutexGuard<Integer>;
  protected
    procedure Execute; override;
  public
    constructor Create(ACounter: specialize TMutexGuard<Integer>);
  end;

procedure TCounterThread.Execute;
var
  I: Integer;
  P: PInteger;
begin
  for I := 1 to 10000 do
  begin
    P := FCounter.LockPtr;
    try
      Inc(P^);
    finally
      FCounter.Unlock;
    end;
  end;
end;

// 主程序
var
  Counter: specialize TMutexGuard<Integer>;
  T1, T2: TCounterThread;
begin
  Counter := specialize TMutexGuard<Integer>.Create(0);
  try
    T1 := TCounterThread.Create(Counter);
    T2 := TCounterThread.Create(Counter);
    T1.WaitFor;
    T2.WaitFor;
    T1.Free;
    T2.Free;

    WriteLn('Final count: ', Counter.GetValue);  // 应该是 20000
  finally
    Counter.Free;
  end;
end;
```

## 与 Rust Mutex<T> 对比

| 特性 | TMutexGuard<T> | Rust Mutex<T> |
|------|----------------|---------------|
| 数据与锁绑定 | ✅ | ✅ |
| 编译时安全 | 部分（运行时检查） | ✅（借用检查器）|
| RAII 释放 | ✅（析构函数）| ✅（Drop trait）|
| 中毒机制 | ❌ | ✅ |

## 注意事项

1. **不要存储指针**: `LockPtr` 返回的指针在 `Unlock` 后失效
2. **确保 Unlock**: 每次 `Lock`/`LockPtr` 后必须调用 `Unlock`
3. **析构时自动解锁**: 如果对象被销毁时仍持有锁，会自动释放

## 相关模块

- `fafafa.core.sync.rwlock.guard` - 读写锁版本的 Guard
- `fafafa.core.sync.mutex` - 底层互斥锁

## 版本历史

- v1.0.0 (2025-12): 初始版本，实现 Rust Mutex<T> 语义
