# fafafa.core.sync.barrier - 屏障同步模块

## 📋 概述

`fafafa.core.sync.barrier` 模块提供了高性能的屏障同步实现，适用于多线程协调和同步。该模块采用跨平台架构设计，支持多种平台原生实现和 fallback 策略，提供统一的接口。

## 🏗️ 架构设计

### 模块结构
```
fafafa.core.sync.barrier/
├── fafafa.core.sync.barrier.pas          # 主模块，平台无关接口
├── fafafa.core.sync.barrier.base.pas     # 基础接口定义
├── fafafa.core.sync.barrier.windows.pas  # Windows 平台实现 (SynchronizationBarrier)
└── fafafa.core.sync.barrier.unix.pas     # Unix/Linux 平台实现 (pthread_barrier_t)
```

### 接口层次
```
ISynchronizable (基础同步接口)
  └── IBarrier (屏障同步接口)
        └── TBarrier (平台特定实现)
```

### 平台实现策略

**Windows 平台**：
- 优先使用 `SynchronizationBarrier` API (Windows Vista+)
- 自动 fallback 到 mutex + condition variable 实现
- 支持运行时检测和切换

**Unix/Linux 平台**：
- 优先使用 `pthread_barrier_t` 系统实现
- 自动 fallback 到 mutex + condition variable 实现
- 跨 Unix 系统兼容性

## 📚 API 参考

### 核心接口

```pascal
IBarrier = interface(ISynchronizable)
  // 屏障同步操作
  function Wait: Boolean;
  function GetParticipantCount: Integer;
end;
```

### 工厂函数

```pascal
function MakeBarrier(AParticipantCount: Integer): IBarrier;
```

## 💡 使用示例

### 基本用法

```pascal
uses
  fafafa.core.sync.barrier;

var
  Barrier: IBarrier;
  
begin
  // 创建 4 线程屏障
  Barrier := MakeBarrier(4);
  
  // 在每个线程中调用
  if Barrier.Wait then
    WriteLn('我是串行线程')
  else
    WriteLn('我是非串行线程');
end;
```

### 多线程协调

```pascal
type
  TWorkerThread = class(TThread)
  private
    FBarrier: IBarrier;
    FThreadId: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ABarrier: IBarrier; AThreadId: Integer);
  end;

constructor TWorkerThread.Create(ABarrier: IBarrier; AThreadId: Integer);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FBarrier := ABarrier;
  FThreadId := AThreadId;
end;

procedure TWorkerThread.Execute;
begin
  // 第一阶段工作
  WriteLn(Format('线程 %d: 完成第一阶段', [FThreadId]));

  // 等待所有线程完成第一阶段
  if FBarrier.Wait then
    WriteLn('所有线程完成第一阶段，开始第二阶段');

  // 第二阶段工作
  WriteLn(Format('线程 %d: 完成第二阶段', [FThreadId]));
end;

// 主程序
var
  Barrier: IBarrier;
  Threads: array[0..3] of TWorkerThread;
  i: Integer;
begin
  Barrier := MakeBarrier(4);
  
  // 创建工作线程
  for i := 0 to 3 do
    Threads[i] := TWorkerThread.Create(Barrier, i);
  
  // 等待所有线程完成
  for i := 0 to 3 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
end;
```

### 屏障重用

```pascal
var
  Barrier: IBarrier;
  Round: Integer;
begin
  Barrier := MakeBarrier(2);
  
  for Round := 1 to 5 do
  begin
    WriteLn(Format('轮次 %d 开始', [Round]));
    
    // 屏障可以重复使用
    if Barrier.Wait then
      WriteLn(Format('轮次 %d 完成', [Round]));
  end;
end;
```

## 🔧 特性说明

### 串行线程识别
- `Wait` 方法返回 `True` 表示当前线程是串行线程
- 每轮同步只有一个线程返回 `True`
- 串行线程可以执行特殊的协调任务

### 屏障重用
- 屏障实例可以重复使用多轮同步
- 每轮同步后自动重置状态
- 支持无限次重用

### 异常安全
- 基于接口的自动内存管理
- 异常情况下自动清理资源
- 线程安全的状态管理

## ⚠️ 注意事项

### 使用限制
- 参与线程数量必须 > 0
- 所有参与线程都必须调用 `Wait`
- 不支持动态改变参与者数量

### 性能考虑
- 适用于需要精确同步的场景
- 短时间等待的性能最佳
- 避免在屏障等待期间执行长时间操作

### 死锁预防
- 确保所有参与线程都能到达屏障点
- 避免在屏障等待期间获取其他锁
- 合理设计线程执行路径

## 🧪 测试覆盖

模块包含完整的单元测试，覆盖：
- ✅ 工厂函数测试
- ✅ 基础功能测试  
- ✅ 多线程同步测试
- ✅ 串行线程识别测试
- ✅ 屏障重用测试
- ✅ 边界条件测试
- ✅ 错误处理测试
- ✅ 平台特定测试

## 📊 性能特征

### 适用场景
- ✅ **多阶段计算**：需要阶段间同步的并行算法
- ✅ **数据并行**：多线程处理数据后需要汇总
- ✅ **流水线同步**：多线程流水线的阶段同步
- ✅ **批处理协调**：批量任务的协调和同步

### 性能优势
- ✅ **平台优化**：使用系统原生 API 获得最佳性能
- ✅ **自动 fallback**：确保跨平台兼容性
- ✅ **低开销**：最小化同步开销
- ✅ **可重用**：避免重复创建的开销
