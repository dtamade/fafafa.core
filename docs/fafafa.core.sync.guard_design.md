# fafafa.core.sync 通用 Guard 设计

## 概述

在 `fafafa.core.sync.base` 中定义了通用的 `IGuard` 接口，为所有同步原语提供统一的 RAII（Resource Acquisition Is Initialization）守护机制。

## 接口层次结构

```pascal
IGuard (通用守护接口)
├── IsLocked: Boolean
│
├── IMutexGuard (互斥锁守护)
│   └── 继承 IGuard.IsLocked
│
├── IReadGuard (读锁守护)  
│   └── 继承 IGuard.IsLocked
│
└── IWriteGuard (写锁守护)
    └── 继承 IGuard.IsLocked
```

## 核心接口定义

### IGuard - 通用守护接口
```pascal
IGuard = interface
  ['{F1E2D3C4-B5A6-9780-CDEF-123456789ABC}']
  function IsLocked: Boolean;
  procedure Release;  // 手动释放锁（可选，析构时自动调用）
end;
```

### 专用守护接口
```pascal
// 互斥锁守护
IMutexGuard = interface(IGuard)
  ['{D1E2F3A4-B5C6-7D8E-9F0A-1B2C3D4E5F6A}']
  // 继承 IGuard.IsLocked: Boolean
end;

// 读锁守护
IReadGuard = interface(IGuard)
  ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
  // 继承 IGuard.IsLocked: Boolean
end;

// 写锁守护
IWriteGuard = interface(IGuard)
  ['{B2C3D4E5-F6A7-8901-BCDE-F12345678901}']
  // 继承 IGuard.IsLocked: Boolean
end;
```

## 使用示例

### 基本使用
```pascal
var
  m: IMutex;
  guard: IMutexGuard;
begin
  m := MakeMutex;
  
  // RAII 模式：自动获取锁
  guard := m.Lock;
  try
    // 临界区代码
    WriteLn('锁状态: ', guard.IsLocked);
  finally
    guard := nil; // 自动释放锁
  end;
end;
```

### 多态使用
```pascal
var
  m: IMutex;
  baseGuard: IGuard;
begin
  m := MakeMutex;
  
  // 向上转型到通用接口
  baseGuard := m.Lock;
  
  // 使用通用接口
  if baseGuard.IsLocked then
    WriteLn('锁已获取');
    
  baseGuard := nil; // 自动释放
end;
```

### 泛型容器支持
```pascal
var
  guards: array of IGuard;
  m: IMutex;
begin
  m := MakeMutex;
  
  // 存储不同类型的守护对象
  SetLength(guards, 3);
  guards[0] := m.Lock;
  guards[1] := m.TryLock;
  // guards[2] := rwLock.ReadLock;  // 未来的读写锁
  
  // 统一处理
  for guard in guards do
    if Assigned(guard) and guard.IsLocked then
      WriteLn('守护对象已锁定');
end;
```

## 设计优势

### 1. **统一性**
- 所有同步原语共享相同的 RAII 接口
- 一致的使用模式和行为

### 2. **多态性**
- 支持向上转型到通用 `IGuard` 接口
- 便于编写通用的同步代码

### 3. **扩展性**
- 新的同步原语只需实现 `IGuard` 接口
- 无需修改现有代码

### 4. **类型安全**
- 编译时类型检查
- 防止错误的守护对象使用

### 5. **内存安全**
- 自动资源管理
- 异常安全保证

## 实现要求

### 守护对象实现类必须：

1. **构造时获取资源**
```pascal
constructor TMutexGuard.Create(AMutex: TMutex; ATryLock: Boolean);
begin
  inherited Create;
  FMutex := AMutex;
  
  if ATryLock then
    FLocked := FMutex.TryAcquire
  else
  begin
    FMutex.Acquire;
    FLocked := True;
  end;
end;
```

2. **析构时释放资源**
```pascal
destructor TMutexGuard.Destroy;
begin
  if FLocked then
    FMutex.Release;
  inherited Destroy;
end;
```

3. **实现状态查询**
```pascal
function TMutexGuard.IsLocked: Boolean;
begin
  Result := FLocked;
end;
```

## 与其他语言对比

| 语言 | RAII 机制 | 通用接口 | 多态支持 |
|------|-----------|----------|----------|
| **fafafa.core** | ✅ IGuard | ✅ 统一接口 | ✅ 接口继承 |
| **Rust** | ✅ Drop trait | ❌ 各自独立 | ✅ trait 对象 |
| **C++** | ✅ RAII | ❌ 各自独立 | ✅ 虚函数 |
| **Java** | ❌ try-with-resources | ❌ 各自独立 | ✅ 接口 |
| **Go** | ❌ defer | ❌ 各自独立 | ✅ 接口 |

## 未来扩展

通用 `IGuard` 设计为未来的同步原语扩展奠定了基础：

- **信号量守护**: `ISemaphoreGuard`
- **条件变量守护**: `IConditionGuard`  
- **屏障守护**: `IBarrierGuard`
- **自定义同步原语**: 实现 `IGuard` 即可

## 总结

通用 Guard 设计是 fafafa.core.sync 框架的核心创新之一，它提供了：

- 🎯 **统一的 RAII 接口**
- 🔄 **多态和泛型支持**
- 🚀 **优秀的扩展性**
- 🛡️ **类型和内存安全**

这种设计让 fafafa.core 在同步原语的易用性和安全性方面达到了业界领先水平。
