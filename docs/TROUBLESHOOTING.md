# 故障排查指南

本文档记录 fafafa.core 项目中遇到的重大技术问题及其解决方案。

## 目录
- [FreePascal 编译器性能问题](#freepascal-编译器性能问题)
  - [问题描述](#问题描述)
  - [根本原因](#根本原因)
  - [解决方案](#解决方案)
  - [技术洞察](#技术洞察)
  - [最佳实践](#最佳实践)

---

## FreePascal 编译器性能问题

### 问题描述

**症状**：
- 测试程序编译时间超过 120 秒（超时）
- 编译器 CPU 使用率 100%，但无进展
- 其他模块编译正常（< 1 秒）

**影响范围**：
- 模块：`fafafa.core.sync.once`
- 文件：`tests/fafafa.core.sync.once/fafafa.core.sync.once.testcase.pas`
- 具体方法：`TTestCase_Concurrency.Test_Execute_Concurrent_MethodCallback`

**环境信息**：
- 编译器：Free Pascal Compiler version 3.2.2
- 平台：Linux x86_64
- 代码行数：8,855 行

---

### 根本原因

#### 触发编译器性能瓶颈的代码模式

```pascal
// ❌ 问题代码：复杂嵌套结构
procedure TTestCase_Concurrency.Test_Execute_Concurrent_MethodCallback;
var
  Threads: array[0..ThreadCount-1] of TThread;
  Once: IOnce;
  ExecutionCount: Integer;
  
  // 嵌套过程（捕获局部变量）
  procedure TestMethod;
  begin
    InterlockedIncrement(ExecutionCount);
  end;

begin
  // 匿名线程中嵌套匿名过程
  for i := 0 to ThreadCount-1 do
  begin
    Threads[i] := TThread.CreateAnonymousThread(
      procedure
      begin
        Once.Execute(
          procedure
          begin
            TestMethod;  // 调用嵌套过程
          end);
      end);
  end;
end;
```

#### 问题组合

1. **嵌套过程** (`TestMethod` 在方法内部定义)
2. **匿名线程** (`TThread.CreateAnonymousThread`)
3. **闭包捕获** (捕获局部变量 `ExecutionCount` 和 `Once`)
4. **多层嵌套** (匿名线程中再嵌套匿名过程)

这种组合导致 FreePascal 编译器需要进行复杂的作用域分析和闭包捕获处理，编译时间从 0.4 秒暴增到 >120 秒（**300 倍差异**）。

#### 系统性验证

通过注释测试程序的不同部分，确认了问题根源：

| 测试场景 | 编译时间 | 结果 |
|---------|---------|------|
| 完整测试程序 | >120 秒 | ❌ 超时 |
| 注释掉 `TTestCase_Concurrency` | 0.433 秒 | ✅ 成功 |
| 注释掉 `Test_Execute_Concurrent_MethodCallback` | 0.4 秒 | ✅ 成功 |

**编译时间差异**：277-300 倍

---

### 解决方案

#### 最终实现：专用线程类模式

```pascal
// ✅ 解决方案：使用专用线程类，避免嵌套匿名过程

// 1. 定义专用线程类
type
  TOnceMethodCallbackThread = class(TThread)
  private
    FOnce: IOnce;
    FCallback: TOnceAnonymousProc;
  protected
    procedure Execute; override;
  public
    constructor Create(const AOnce: IOnce; const ACallback: TOnceAnonymousProc);
  end;

constructor TOnceMethodCallbackThread.Create(const AOnce: IOnce; const ACallback: TOnceAnonymousProc);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FOnce := AOnce;
  FCallback := ACallback;
end;

procedure TOnceMethodCallbackThread.Execute;
begin
  try
    FOnce.Execute(FCallback);
  except
    // 忽略异常
  end;
end;

// 2. 将嵌套过程提取为类方法
type
  TTestCase_Concurrency = class(TTestCase)
  private
    FOnce: IOnce;
    FExecutionCount: Integer;
    procedure ConcurrentTestMethod;  // 提取为类方法
  end;

procedure TTestCase_Concurrency.ConcurrentTestMethod;
begin
  InterlockedIncrement(FExecutionCount);
end;

// 3. 在主线程创建回调，使用专用线程类
procedure TTestCase_Concurrency.Test_Execute_Concurrent_MethodCallback;
const
  ThreadCount = 5;
var
  Threads: array[0..ThreadCount-1] of TOnceMethodCallbackThread;
  i: Integer;
  Callback: TOnceAnonymousProc;
begin
  FExecutionCount := 0;
  FOnce := MakeOnce;

  // 在主线程中创建回调（避免嵌套）
  Callback := procedure
  begin
    ConcurrentTestMethod;
  end;

  // 使用专用线程类
  for i := 0 to ThreadCount-1 do
    Threads[i] := TOnceMethodCallbackThread.Create(FOnce, Callback);

  try
    for i := 0 to ThreadCount-1 do
      Threads[i].WaitFor;

    AssertEquals('Method callback: only one execution', 1, FExecutionCount);
    AssertTrue('Once should be completed', FOnce.Completed);
  finally
    for i := 0 to ThreadCount-1 do
      Threads[i].Free;
  end;
end;
```

#### 关键改进

1. **提取嵌套过程为类方法** (`ConcurrentTestMethod`)
   - 消除嵌套过程定义
   - 使用类字段替代局部变量

2. **在主线程创建回调**
   - 避免在线程中嵌套创建匿名过程
   - 回调在主线程创建，传递给线程类

3. **使用专用线程类**
   - 替代 `TThread.CreateAnonymousThread` 的嵌套模式
   - 保持代码结构扁平化

4. **消除多层嵌套**
   - 避免匿名线程中再嵌套匿名过程
   - 减少编译器的作用域分析负担

---

### 性能对比

| 场景 | 编译时间 | 测试结果 | 改善倍数 |
|------|---------|---------|---------|
| **原始代码（嵌套结构）** | >120 秒 (超时) | ❌ 超时 | - |
| **最终方案（专用线程类）** | **0.423 秒** | ✅ 26/26 通过 | **283 倍提升** |

**编译输出**：
```
8855 lines compiled, 0.4 sec, 1002064 bytes code, 489760 bytes data
```

**测试结果**：
```
Number of run tests: 26
Number of errors:    0
Number of failures:  0
```

---

### 技术洞察

#### FreePascal 编译器限制

1. **嵌套匿名过程性能问题**
   - 嵌套匿名过程 + 闭包捕获会导致编译器性能急剧下降
   - 编译器在处理多层嵌套的作用域分析时存在性能瓶颈
   - 某些嵌套模式会触发编译器内部错误（Internal error 2022011001）

2. **闭包捕获开销**
   - 编译器需要追踪多层嵌套的变量捕获关系
   - 每增加一层嵌套，分析复杂度呈指数级增长
   - 局部变量捕获比类字段访问开销更大

3. **匿名线程的特殊性**
   - `TThread.CreateAnonymousThread` 本身就涉及闭包
   - 在匿名线程中再嵌套匿名过程会加剧问题
   - 编译器需要处理跨线程的变量生命周期

#### 为什么专用线程类有效

1. **消除嵌套层次**
   - 线程类的 `Execute` 方法是普通方法，不是匿名过程
   - 回调在主线程创建，作用域清晰
   - 编译器只需处理单层闭包

2. **明确的生命周期**
   - 线程类的字段生命周期明确
   - 不需要复杂的闭包捕获分析
   - 编译器可以使用更简单的代码生成策略

3. **代码结构扁平化**
   - 每个组件职责单一
   - 减少编译器的分析负担
   - 更容易优化和维护

---

### 最佳实践

#### ✅ 推荐做法

1. **避免嵌套匿名过程**
   ```pascal
   // ✅ 好：在主线程创建回调
   Callback := procedure
   begin
     DoSomething;
   end;
   
   Thread := TMyThread.Create(Callback);
   ```

2. **使用辅助类**
   ```pascal
   // ✅ 好：专用线程类
   type
     TMyWorkerThread = class(TThread)
     private
       FCallback: TProc;
     protected
       procedure Execute; override;
     end;
   ```

3. **优先使用类字段**
   ```pascal
   // ✅ 好：类字段
   type
     TMyTest = class
     private
       FCounter: Integer;
       procedure IncrementCounter;
     end;
   ```

4. **保持代码扁平化**
   ```pascal
   // ✅ 好：单层结构
   procedure DoWork;
   begin
     Thread := TThread.CreateAnonymousThread(
       procedure
       begin
         ProcessData;
       end);
   end;
   ```

#### ❌ 避免的模式

1. **嵌套匿名过程**
   ```pascal
   // ❌ 差：多层嵌套
   TThread.CreateAnonymousThread(
     procedure
     begin
       Once.Execute(
         procedure
         begin
           DoSomething;
         end);
     end);
   ```

2. **嵌套过程 + 闭包捕获**
   ```pascal
   // ❌ 差：嵌套过程捕获局部变量
   procedure Test;
   var
     Counter: Integer;
     
     procedure Nested;
     begin
       Inc(Counter);  // 捕获局部变量
     end;
   begin
     TThread.CreateAnonymousThread(
       procedure
       begin
         Nested;  // 调用嵌套过程
       end);
   end;
   ```

3. **过度使用匿名方法**
   ```pascal
   // ❌ 差：不必要的匿名方法
   for i := 0 to 10 do
   begin
     TThread.CreateAnonymousThread(
       procedure
       var
         j: Integer;
       begin
         j := i;  // 捕获循环变量
         Process(j);
       end);
   end;
   ```

#### 并发测试的推荐模式

```pascal
// ✅ 推荐：专用线程类 + 类字段 + 主线程回调

type
  // 1. 定义专用线程类
  TTestWorkerThread = class(TThread)
  private
    FCallback: TProc;
  protected
    procedure Execute; override;
  public
    constructor Create(const ACallback: TProc);
  end;

  // 2. 测试类使用字段
  TMyTest = class(TTestCase)
  private
    FCounter: Integer;
    procedure IncrementCounter;
  published
    procedure TestConcurrency;
  end;

// 3. 在主线程创建回调
procedure TMyTest.TestConcurrency;
var
  Threads: array[0..4] of TTestWorkerThread;
  Callback: TProc;
begin
  FCounter := 0;
  
  // 主线程创建回调
  Callback := procedure
  begin
    IncrementCounter;
  end;
  
  // 使用专用线程类
  for i := 0 to 4 do
    Threads[i] := TTestWorkerThread.Create(Callback);
  
  // 等待和清理
  try
    for i := 0 to 4 do
      Threads[i].WaitFor;
  finally
    for i := 0 to 4 do
      Threads[i].Free;
  end;
end;
```

---

### 故障排查流程

如果遇到类似的编译性能问题，建议按以下步骤排查：

1. **确认问题范围**
   - 注释掉不同的测试类/方法
   - 找出导致编译超时的具体代码

2. **识别问题模式**
   - 检查是否有嵌套匿名过程
   - 检查是否有复杂的闭包捕获
   - 检查是否有多层嵌套结构

3. **应用简化策略**
   - 提取嵌套过程为类方法
   - 使用类字段替代局部变量
   - 创建专用线程类

4. **验证修复效果**
   - 测量编译时间
   - 运行测试验证功能
   - 确认性能改善

---

### 相关资源

- **FreePascal 文档**：https://www.freepascal.org/docs.html
- **匿名方法最佳实践**：https://wiki.freepascal.org/Anonymous_methods
- **线程编程指南**：https://wiki.freepascal.org/Multithreaded_Application_Tutorial

---

### 更新历史

- **2026-01-31**：初始版本，记录 `fafafa.core.sync.once` 编译超时问题及解决方案
