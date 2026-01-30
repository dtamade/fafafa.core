# fafafa.core.sync.sem 守卫机制详解

## 📋 概述

信号量守卫 (`ISemGuard`) 是一种 **RAII (Resource Acquisition Is Initialization)** 模式的实现，用于自动管理信号量许可的获取和释放，确保资源安全和异常安全。

## 🎯 守卫的核心原理

### 1. **RAII 模式**
```pascal
// 传统手动管理 - 容易出错
Sem.Acquire;
try
  // 临界区代码
  // 如果这里抛异常，Release 可能不会被调用
finally
  Sem.Release;  // 必须记住释放
end;

// RAII 守卫 - 自动安全
var Guard := Sem.AcquireGuard;
// 临界区代码
// Guard 析构时自动释放，即使发生异常
```

### 2. **接口继承设计**
```pascal
ISemGuard = interface(ILockGuard)
  ['{8B3E4A75-9C2D-4B6E-8C9F-0D1E2F3A4B5C}']
  function GetCount: Integer;  // 信号量特有：获取持有的许可数量
  // 继承 ILockGuard.Release - 手动释放许可
end;
```

## 🔧 守卫实现机制

### TSemGuard 类结构
```pascal
TSemGuard = class(TInterfacedObject, ISemGuard)
private
  FSem: ISem;      // 持有的信号量引用
  FCount: Integer; // 持有的许可数量
public
  constructor Create(const ASem: ISem; ACount: Integer);
  destructor Destroy; override;
  function GetCount: Integer;
  procedure Release;  // ILockGuard.Release
end;
```

### 关键方法实现

#### 1. **构造函数 - 不获取许可**
```pascal
constructor TSemGuard.Create(const ASem: ISem; ACount: Integer);
begin
  inherited Create;
  FSem := ASem;
  FCount := ACount;  // 记录已获取的许可数量
end;
```
**注意**: 构造函数不获取许可，许可在调用 `AcquireGuard` 时已经获取。

#### 2. **析构函数 - 自动释放**
```pascal
destructor TSemGuard.Destroy;
begin
  if Assigned(FSem) and (FCount > 0) then
    FSem.Release(FCount);  // 自动释放持有的许可
  inherited Destroy;
end;
```

#### 3. **手动释放 - 提前释放**
```pascal
procedure TSemGuard.Release;
begin
  if Assigned(FSem) and (FCount > 0) then
  begin
    FSem.Release(FCount);
    FCount := 0;  // 防止重复释放
  end;
end;
```

#### 4. **许可数量查询**
```pascal
function TSemGuard.GetCount: Integer;
begin
  Result := FCount;
end;
```

## 🚀 守卫的创建过程

### AcquireGuard 方法
```pascal
function TSemaphore.AcquireGuard: ISemGuard;
begin
  Acquire(1);                        // 1. 先获取许可
  Result := TSemGuard.Create(Self, 1); // 2. 创建守卫记录已获取的许可
end;

function TSemaphore.AcquireGuard(ACount: Integer): ISemGuard;
begin
  Acquire(ACount);                      // 1. 先获取指定数量的许可
  Result := TSemGuard.Create(Self, ACount); // 2. 创建守卫
end;
```

### TryAcquireGuard 方法
```pascal
function TSemaphore.TryAcquireGuard: ISemGuard;
begin
  if TryAcquire(1) then                 // 1. 尝试获取许可
    Result := TSemGuard.Create(Self, 1) // 2. 成功则创建守卫
  else
    Result := nil;                      // 3. 失败返回 nil
end;
```

## 💡 使用模式详解

### 1. **基础 RAII 模式**
```pascal
procedure UseBasicGuard;
var
  Sem: ISem;
  Guard: ISemGuard;
begin
  Sem := MakeSem(1, 3);
  
  Guard := Sem.AcquireGuard;  // 获取1个许可
  try
    // 临界区代码
    WriteLn('持有许可数: ', Guard.GetCount);
  finally
    // Guard := nil; // 可选，超出作用域时自动调用析构
  end;
end; // Guard 自动析构，释放许可
```

### 2. **with 语句模式 - 最简洁**
```pascal
procedure UseWithGuard;
var
  Sem: ISem;
begin
  Sem := MakeSem(2, 5);
  
  with Sem.AcquireGuard(2) do  // 获取2个许可
  begin
    // 临界区代码
    WriteLn('持有许可数: ', GetCount);
  end; // 自动释放
end;
```

### 3. **内联变量模式 - 现代风格**
```pascal
procedure UseInlineGuard;
var
  Sem: ISem;
begin
  Sem := MakeSem(1, 2);
  
  begin
    var Guard := Sem.AcquireGuard;
    // 临界区代码
    WriteLn('可用许可: ', Sem.GetAvailableCount);
  end; // Guard 自动析构
end;
```

### 4. **条件获取模式**
```pascal
procedure UseConditionalGuard;
var
  Sem: ISem;
  Guard: ISemGuard;
begin
  Sem := MakeSem(0, 1);  // 初始无许可
  
  Guard := Sem.TryAcquireGuard;
  if Guard <> nil then
  begin
    // 成功获取许可
    WriteLn('获取成功');
  end
  else
    WriteLn('无可用许可');
  // Guard 自动释放（如果不为 nil）
end;
```

### 5. **手动释放模式**
```pascal
procedure UseManualRelease;
var
  Sem: ISem;
  Guard: ISemGuard;
begin
  Sem := MakeSem(2, 3);
  
  Guard := Sem.AcquireGuard(2);
  try
    // 临界区代码
    if SomeCondition then
    begin
      Guard.Release;  // 提前手动释放
      // 继续执行其他代码，不持有许可
    end;
  finally
    // 如果已手动释放，析构函数不会重复释放
  end;
end;
```

## 🛡️ 安全保证

### 1. **异常安全**
```pascal
procedure ExceptionSafeExample;
var
  Sem: ISem;
  Guard: ISemGuard;
begin
  Sem := MakeSem(1, 1);
  
  Guard := Sem.AcquireGuard;
  // 即使下面的代码抛异常，Guard 也会在栈展开时自动释放许可
  raise Exception.Create('测试异常');
end; // Guard 析构函数确保许可被释放
```

### 2. **重复释放保护**
```pascal
procedure DoubleReleaseSafe;
var
  Sem: ISem;
  Guard: ISemGuard;
begin
  Sem := MakeSem(1, 1);
  
  Guard := Sem.AcquireGuard;
  Guard.Release;  // 手动释放
  Guard.Release;  // 第二次调用是安全的，不会重复释放
end; // 析构函数也不会重复释放
```

### 3. **空引用保护**
```pascal
procedure NullSafeExample;
var
  Sem: ISem;
  Guard: ISemGuard;
begin
  Sem := MakeSem(0, 1);
  
  Guard := Sem.TryAcquireGuard;  // 可能返回 nil
  if Guard <> nil then
    Guard.Release;  // 安全调用
  // 即使 Guard 为 nil，也不会出错
end;
```

## 🔄 与其他 Guard 的一致性

### 多态使用
```pascal
procedure PolymorphicGuard;
var
  Sem: ISem;
  LockGuard: ILockGuard;  // 通用守卫接口
  SemGuard: ISemGuard;    // 信号量特有守卫
begin
  Sem := MakeSem(1, 2);
  
  SemGuard := Sem.AcquireGuard;
  LockGuard := SemGuard;  // 向上转型
  
  // 使用通用接口
  LockGuard.Release;
  
  // 使用信号量特有功能
  WriteLn('许可数: ', SemGuard.GetCount);
end;
```

## 📊 性能特性

### 1. **零开销抽象**
- 守卫对象只包含必要的字段（信号量引用 + 计数）
- 内联函数优化
- 接口引用计数管理自动析构

### 2. **内存效率**
```pascal
// TSemGuard 内存布局
TSemGuard = class(TInterfacedObject, ISemGuard)
private
  FSem: ISem;      // 8 字节 (接口引用)
  FCount: Integer; // 4 字节
  // 总计: ~16 字节 + 对象头
end;
```

## 🎉 总结

信号量守卫机制提供了：

- ✅ **自动资源管理**: RAII 模式确保许可自动释放
- ✅ **异常安全**: 即使发生异常也能正确释放资源
- ✅ **灵活使用**: 支持多种使用模式
- ✅ **框架一致**: 与其他同步原语的守卫保持一致
- ✅ **性能优化**: 零开销抽象，高效实现
- ✅ **安全保证**: 防止重复释放和空引用错误

这种设计让信号量的使用更加安全、简洁和现代化！🚀
