program benchmark_mutex;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.mutex;

const
  ITERATIONS = 1000000;
  THREAD_COUNT = 4;

type
  TBenchmarkThread = class(TThread)
  private
    FMutex: IMutex;
    FIterations: Integer;
    FElapsedTime: QWord;
  public
    constructor Create(AMutex: IMutex; AIterations: Integer);
    procedure Execute; override;
    property ElapsedTime: QWord read FElapsedTime;
  end;

constructor TBenchmarkThread.Create(AMutex: IMutex; AIterations: Integer);
begin
  FMutex := AMutex;
  FIterations := AIterations;
  FElapsedTime := 0;
  inherited Create(False);
end;

procedure TBenchmarkThread.Execute;
var
  i: Integer;
  StartTime: QWord;
begin
  StartTime := GetTickCount64;
  
  for i := 1 to FIterations do
  begin
    FMutex.Acquire;
    try
      // 模拟一些工作
      // 这里故意留空，测试纯锁开销
    finally
      FMutex.Release;
    end;
  end;
  
  FElapsedTime := GetTickCount64 - StartTime;
end;

procedure BenchmarkBasicLocking;
var
  m: IMutex;
  i: Integer;
  StartTime, EndTime: QWord;
  OpsPerSecond: Double;
begin
  WriteLn('=== 基础锁定性能测试 ===');
  
  m := MakeMutex;
  
  WriteLn('测试 ', ITERATIONS, ' 次 Acquire/Release 操作...');
  StartTime := GetTickCount64;
  
  for i := 1 to ITERATIONS do
  begin
    m.Acquire;
    m.Release;
  end;
  
  EndTime := GetTickCount64;
  
  if EndTime > StartTime then
  begin
    OpsPerSecond := (ITERATIONS * 2.0) / ((EndTime - StartTime) / 1000.0);
    WriteLn('耗时: ', EndTime - StartTime, ' ms');
    WriteLn('性能: ', Round(OpsPerSecond), ' 操作/秒');
  end
  else
  begin
    WriteLn('耗时: < 1 ms (太快无法测量)');
    WriteLn('性能: > ', (ITERATIONS * 2), ' 操作/秒');
  end;
end;

procedure BenchmarkReentrantLocking;
var
  m: IMutex;
  i, j: Integer;
  StartTime, EndTime: QWord;
  OpsPerSecond: Double;
  TotalOps: Integer;
begin
  WriteLn('');
  WriteLn('=== 可重入锁定性能测试 ===');
  
  m := MakeMutex;
  TotalOps := ITERATIONS div 10; // 减少迭代次数，因为嵌套锁定更昂贵
  
  WriteLn('测试 ', TotalOps, ' 次嵌套锁定操作（深度3）...');
  StartTime := GetTickCount64;
  
  for i := 1 to TotalOps do
  begin
    m.Acquire;
    try
      m.Acquire;
      try
        m.Acquire;
        try
          // 模拟工作
        finally
          m.Release;
        end;
      finally
        m.Release;
      end;
    finally
      m.Release;
    end;
  end;
  
  EndTime := GetTickCount64;
  
  if EndTime > StartTime then
  begin
    OpsPerSecond := (TotalOps * 6.0) / ((EndTime - StartTime) / 1000.0); // 6 operations per iteration
    WriteLn('耗时: ', EndTime - StartTime, ' ms');
    WriteLn('性能: ', Round(OpsPerSecond), ' 操作/秒');
  end
  else
  begin
    WriteLn('耗时: < 1 ms');
    WriteLn('性能: > ', (TotalOps * 6), ' 操作/秒');
  end;
end;

procedure BenchmarkRAII;
var
  m: IMutex;
  i: Integer;
  StartTime, EndTime: QWord;
  OpsPerSecond: Double;
  guard: IMutexGuard;
begin
  WriteLn('');
  WriteLn('=== RAII 锁定性能测试 ===');
  
  m := MakeMutex;
  
  WriteLn('测试 ', ITERATIONS, ' 次 RAII Lock 操作...');
  StartTime := GetTickCount64;
  
  for i := 1 to ITERATIONS do
  begin
    guard := m.Lock;
    guard := nil; // 手动释放引用
  end;
  
  EndTime := GetTickCount64;
  
  if EndTime > StartTime then
  begin
    OpsPerSecond := (ITERATIONS * 2.0) / ((EndTime - StartTime) / 1000.0);
    WriteLn('耗时: ', EndTime - StartTime, ' ms');
    WriteLn('性能: ', Round(OpsPerSecond), ' 操作/秒');
  end
  else
  begin
    WriteLn('耗时: < 1 ms');
    WriteLn('性能: > ', (ITERATIONS * 2), ' 操作/秒');
  end;
end;

procedure BenchmarkConcurrentAccess;
var
  m: IMutex;
  threads: array[0..THREAD_COUNT-1] of TBenchmarkThread;
  i: Integer;
  StartTime, EndTime: QWord;
  TotalOps: Integer;
  TotalTime: QWord;
  OpsPerSecond: Double;
begin
  WriteLn('');
  WriteLn('=== 并发访问性能测试 ===');
  
  m := MakeMutex;
  TotalOps := ITERATIONS div 10; // 减少每线程的迭代次数
  
  WriteLn('启动 ', THREAD_COUNT, ' 个线程，每个执行 ', TotalOps, ' 次操作...');
  StartTime := GetTickCount64;
  
  // 创建并启动线程
  for i := 0 to THREAD_COUNT - 1 do
  begin
    threads[i] := TBenchmarkThread.Create(m, TotalOps);
  end;
  
  // 等待所有线程完成
  for i := 0 to THREAD_COUNT - 1 do
  begin
    threads[i].WaitFor;
  end;
  
  EndTime := GetTickCount64;
  
  // 计算统计信息
  TotalTime := 0;
  for i := 0 to THREAD_COUNT - 1 do
  begin
    TotalTime := TotalTime + threads[i].ElapsedTime;
    threads[i].Free;
  end;
  
  WriteLn('总耗时: ', EndTime - StartTime, ' ms');
  WriteLn('线程平均耗时: ', TotalTime div THREAD_COUNT, ' ms');
  
  if EndTime > StartTime then
  begin
    OpsPerSecond := (THREAD_COUNT * TotalOps * 2.0) / ((EndTime - StartTime) / 1000.0);
    WriteLn('总性能: ', Round(OpsPerSecond), ' 操作/秒');
  end
  else
  begin
    WriteLn('总性能: > ', (THREAD_COUNT * TotalOps * 2), ' 操作/秒');
  end;
end;

procedure BenchmarkNonReentrantMutex;
var
  m: INonReentrantMutex;
  i: Integer;
  StartTime, EndTime: QWord;
  OpsPerSecond: Double;
begin
  WriteLn('');
  WriteLn('=== 非重入锁性能测试 ===');
  
  m := MakeNonReentrantMutex;
  
  WriteLn('测试 ', ITERATIONS, ' 次非重入锁操作...');
  StartTime := GetTickCount64;
  
  for i := 1 to ITERATIONS do
  begin
    m.Acquire;
    m.Release;
  end;
  
  EndTime := GetTickCount64;
  
  if EndTime > StartTime then
  begin
    OpsPerSecond := (ITERATIONS * 2.0) / ((EndTime - StartTime) / 1000.0);
    WriteLn('耗时: ', EndTime - StartTime, ' ms');
    WriteLn('性能: ', Round(OpsPerSecond), ' 操作/秒');
  end
  else
  begin
    WriteLn('耗时: < 1 ms');
    WriteLn('性能: > ', (ITERATIONS * 2), ' 操作/秒');
  end;
end;

begin
  WriteLn('=== fafafa.core.sync.mutex 性能基准测试 ===');
  WriteLn('迭代次数: ', ITERATIONS);
  WriteLn('线程数量: ', THREAD_COUNT);
  WriteLn('');
  
  BenchmarkBasicLocking;
  BenchmarkReentrantLocking;
  BenchmarkRAII;
  BenchmarkNonReentrantMutex;
  BenchmarkConcurrentAccess;
  
  WriteLn('');
  WriteLn('=== 基准测试完成 ===');
end.
