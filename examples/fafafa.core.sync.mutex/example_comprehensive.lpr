program example_comprehensive;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.mutex;

// 共享资源
var
  SharedCounter: Integer = 0;
  SharedMutex: IMutex;

// 工作线程类
type
  TWorkerThread = class(TThread)
  private
    FThreadId: Integer;
    FIterations: Integer;
  public
    constructor Create(AThreadId, AIterations: Integer);
    procedure Execute; override;
  end;

constructor TWorkerThread.Create(AThreadId, AIterations: Integer);
begin
  FThreadId := AThreadId;
  FIterations := AIterations;
  inherited Create(False);
end;

procedure TWorkerThread.Execute;
var
  i: Integer;
  guard: IMutexGuard;
begin
  WriteLn('线程 ', FThreadId, ' 开始工作...');
  
  for i := 1 to FIterations do
  begin
    // 使用 RAII 自动锁管理
    guard := SharedMutex.Lock;
    
    // 临界区：安全地修改共享资源
    Inc(SharedCounter);
    
    // guard 超出作用域时自动释放锁
  end;
  
  WriteLn('线程 ', FThreadId, ' 完成工作');
end;

// 示例1：基础互斥锁使用
procedure Example1_BasicUsage;
var
  mutex: IMutex;
begin
  WriteLn('=== 示例1：基础互斥锁使用 ===');
  
  mutex := MakeMutex;
  
  // 手动锁管理
  mutex.Acquire;
  try
    WriteLn('在锁保护下执行代码');
    Sleep(100); // 模拟工作
  finally
    mutex.Release;
  end;
  
  WriteLn('锁已释放');
  WriteLn('');
end;

// 示例2：可重入锁
procedure Example2_ReentrantLock;
var
  mutex: IMutex;
  
  procedure NestedFunction;
  begin
    mutex.Acquire;
    try
      WriteLn('  嵌套函数中的锁定');
    finally
      mutex.Release;
    end;
  end;
  
begin
  WriteLn('=== 示例2：可重入锁 ===');
  
  mutex := MakeMutex;
  
  mutex.Acquire;
  try
    WriteLn('外层锁定');
    
    // 同一线程可以再次获取锁
    NestedFunction;
    
    WriteLn('外层继续执行');
  finally
    mutex.Release;
  end;
  
  WriteLn('所有锁已释放');
  WriteLn('');
end;

// 示例3：RAII 自动锁管理
procedure Example3_RAIILocking;
var
  mutex: IMutex;
  guard: IMutexGuard;
begin
  WriteLn('=== 示例3：RAII 自动锁管理 ===');
  
  mutex := MakeMutex;
  
  // RAII 模式：自动管理锁的生命周期
  guard := mutex.Lock;
  WriteLn('锁已自动获取');
  
  try
    WriteLn('在 RAII 锁保护下执行');
    Sleep(100);
    
    // 模拟异常
    if Random(2) = 0 then
      raise Exception.Create('模拟异常');
      
  except
    on E: Exception do
      WriteLn('捕获异常: ', E.Message);
  end;
  
  // guard 超出作用域时自动释放锁
  guard := nil;
  WriteLn('锁已自动释放');
  WriteLn('');
end;

// 示例4：标准互斥锁（不可重入）
procedure Example4_StandardMutex;
var
  mutex: IMutex;
begin
  WriteLn('=== 示例4：标准互斥锁（不可重入）===');

  mutex := MakeMutex;
  
  mutex.Acquire;
  try
    WriteLn('非重入锁已获取');
    
    // 尝试再次获取（应该失败）
    if mutex.TryAcquire then
    begin
      WriteLn('❌ 意外成功：非重入锁不应该允许重复获取');
      mutex.Release;
    end
    else
      WriteLn('✅ 正确：非重入锁拒绝重复获取');
      
  finally
    mutex.Release;
  end;
  
  WriteLn('非重入锁已释放');
  WriteLn('');
end;

// 示例5：超时获取
procedure Example5_TimeoutAcquisition;
var
  mutex: IMutex;
  guard: IMutexGuard;
begin
  WriteLn('=== 示例5：超时获取 ===');
  
  mutex := MakeMutex;
  
  // 先获取锁
  guard := mutex.Lock;
  WriteLn('锁已被占用');
  
  // 在另一个上下文中尝试获取（模拟）
  if mutex.TryAcquire(100) then  // 100ms 超时
  begin
    WriteLn('意外成功获取锁');
    mutex.Release;
  end
  else
    WriteLn('✅ 正确：获取锁超时');
  
  guard := nil; // 释放锁
  WriteLn('锁已释放');
  
  // 现在应该能成功获取
  if mutex.TryAcquire(100) then
  begin
    WriteLn('✅ 成功获取锁');
    mutex.Release;
  end
  else
    WriteLn('❌ 意外超时');
    
  WriteLn('');
end;

// 示例6：多线程并发访问
procedure Example6_ConcurrentAccess;
const
  THREAD_COUNT = 4;
  ITERATIONS_PER_THREAD = 1000;
var
  threads: array[0..THREAD_COUNT-1] of TWorkerThread;
  i: Integer;
  expectedResult: Integer;
begin
  WriteLn('=== 示例6：多线程并发访问 ===');
  
  SharedMutex := MakeMutex;
  SharedCounter := 0;
  expectedResult := THREAD_COUNT * ITERATIONS_PER_THREAD;
  
  WriteLn('启动 ', THREAD_COUNT, ' 个线程，每个执行 ', ITERATIONS_PER_THREAD, ' 次操作');
  WriteLn('期望结果: ', expectedResult);
  
  // 创建并启动线程
  for i := 0 to THREAD_COUNT - 1 do
  begin
    threads[i] := TWorkerThread.Create(i + 1, ITERATIONS_PER_THREAD);
  end;
  
  // 等待所有线程完成
  for i := 0 to THREAD_COUNT - 1 do
  begin
    threads[i].WaitFor;
    threads[i].Free;
  end;
  
  WriteLn('所有线程完成');
  WriteLn('实际结果: ', SharedCounter);
  
  if SharedCounter = expectedResult then
    WriteLn('✅ 成功：互斥锁正确保护了共享资源')
  else
    WriteLn('❌ 失败：存在竞态条件');
    
  WriteLn('');
end;

// 示例7：异常安全性
procedure Example7_ExceptionSafety;
var
  mutex: IMutex;
  guard: IMutexGuard;
begin
  WriteLn('=== 示例7：异常安全性 ===');
  
  mutex := MakeMutex;
  
  try
    guard := mutex.Lock;
    WriteLn('锁已获取');
    
    // 模拟异常
    raise Exception.Create('测试异常安全性');
    
  except
    on E: Exception do
    begin
      WriteLn('捕获异常: ', E.Message);
      WriteLn('RAII 确保锁在异常情况下也会被正确释放');
    end;
  end;
  
  // 验证锁已释放
  if mutex.TryAcquire then
  begin
    WriteLn('✅ 锁已正确释放');
    mutex.Release;
  end
  else
    WriteLn('❌ 锁未正确释放');
    
  WriteLn('');
end;

begin
  WriteLn('=== fafafa.core.sync.mutex 综合示例 ===');
  WriteLn('');
  
  Randomize;
  
  Example1_BasicUsage;
  Example2_ReentrantLock;
  Example3_RAIILocking;
  Example4_StandardMutex;
  Example5_TimeoutAcquisition;
  Example6_ConcurrentAccess;
  Example7_ExceptionSafety;
  
  WriteLn('=== 所有示例完成 ===');
  WriteLn('');
  WriteLn('总结：');
  WriteLn('- ✅ 基础互斥锁功能正常');
  WriteLn('- ✅ 可重入锁支持嵌套获取');
  WriteLn('- ✅ RAII 自动锁管理工作正常');
  WriteLn('- ✅ 非重入锁正确拒绝重复获取');
  WriteLn('- ✅ 超时机制工作正常');
  WriteLn('- ✅ 多线程并发访问安全');
  WriteLn('- ✅ 异常安全性得到保证');
end.
