program robust_concurrent_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.mutex,
  fafafa.core.sync.recMutex;

type
  // 线程安全的测试结果记录器
  TTestResults = class
  private
    FLock: IMutex;
    FResults: array of string;
    FCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddResult(const AResult: string);
    procedure PrintResults;
    function GetCount: Integer;
  end;

var
  TestResults: TTestResults;

{ TTestResults }

constructor TTestResults.Create;
begin
  inherited Create;
  FLock := MakeMutex;
  SetLength(FResults, 100);
  FCount := 0;
end;

destructor TTestResults.Destroy;
begin
  FLock := nil; // 释放接口引用
  inherited Destroy;
end;

procedure TTestResults.AddResult(const AResult: string);
begin
  FLock.Acquire;
  try
    if FCount < Length(FResults) then
    begin
      FResults[FCount] := AResult;
      Inc(FCount);
    end;
  finally
    FLock.Release;
  end;
end;

procedure TTestResults.PrintResults;
var i: Integer;
begin
  FLock.Acquire;
  try
    for i := 0 to FCount - 1 do
      WriteLn(FResults[i]);
  finally
    FLock.Release;
  end;
end;

function TTestResults.GetCount: Integer;
begin
  FLock.Acquire;
  try
    Result := FCount;
  finally
    FLock.Release;
  end;
end;

// 测试跨线程互斥
procedure TestCrossThreadExclusion;
var
  m: IMutex;
  otherThreadAcquired: Boolean;
  t: TThread;
begin
  WriteLn('=== 测试跨线程互斥 ===');
  
  m := MakeMutex;
  otherThreadAcquired := False;
  
  // 主线程获取锁
  m.Acquire;
  TestResults.AddResult('主线程获取锁成功');
  
  // 创建测试线程
  t := TThread.CreateAnonymousThread(
    procedure
    begin
      Sleep(50); // 确保主线程先获取锁
      otherThreadAcquired := m.TryAcquire(100);
      if otherThreadAcquired then
      begin
        TestResults.AddResult('❌ 其他线程意外获取到锁！');
        m.Release;
      end
      else
        TestResults.AddResult('✅ 其他线程正确被阻塞');
    end);
  
  t.Start;
  Sleep(200); // 让子线程有时间尝试
  t.WaitFor;
  t.Free;
  
  // 释放主线程的锁
  m.Release;
  TestResults.AddResult('主线程释放锁成功');
  
  if not otherThreadAcquired then
    TestResults.AddResult('✅ 跨线程互斥测试通过')
  else
    TestResults.AddResult('❌ 跨线程互斥测试失败');
end;

// 测试多线程竞争
procedure TestMultiThreadContention;
const
  THREAD_COUNT = 3;
  OPERATIONS_PER_THREAD = 10;
var
  m: IMutex;
  threads: array[0..THREAD_COUNT-1] of TThread;
  sharedCounter: Integer;
  totalOperations: Integer;
  i: Integer;
begin
  WriteLn('=== 测试多线程竞争 ===');
  
  m := MakeMutex;
  sharedCounter := 0;
  totalOperations := 0;
  
  // 创建工作线程
  for i := 0 to THREAD_COUNT-1 do
  begin
    threads[i] := TThread.CreateAnonymousThread(
      procedure
      var j, localOps: Integer;
      begin
        localOps := 0;
        for j := 1 to OPERATIONS_PER_THREAD do
        begin
          if m.TryAcquire(100) then
          begin
            try
              Inc(sharedCounter);
              Inc(localOps);
              Sleep(1); // 模拟工作
            finally
              m.Release;
            end;
          end;
        end;
        
        // 原子更新总操作数
        InterLockedExchangeAdd(totalOperations, localOps);
      end);
    threads[i].Start;
  end;
  
  // 等待所有线程完成
  for i := 0 to THREAD_COUNT-1 do
  begin
    threads[i].WaitFor;
    threads[i].Free;
  end;
  
  TestResults.AddResult('共享计数器值: ' + IntToStr(sharedCounter));
  TestResults.AddResult('总成功操作数: ' + IntToStr(totalOperations));
  
  if sharedCounter = totalOperations then
    TestResults.AddResult('✅ 多线程竞争测试通过')
  else
    TestResults.AddResult('❌ 多线程竞争测试失败');
end;

// 测试可重入互斥锁
procedure TestReentrantMutex;
var
  m: IRecMutex;
  success: Boolean;
begin
  WriteLn('=== 测试可重入互斥锁 ===');
  
  m := MakeRecMutex;
  
  // 第一次获取
  m.Acquire;
  TestResults.AddResult('第一次获取成功');
  
  // 同线程重入
  success := m.TryAcquire;
  if success then
  begin
    TestResults.AddResult('✅ 可重入获取成功');
    m.Release; // 释放重入
    m.Release; // 释放第一次
    TestResults.AddResult('✅ 可重入互斥锁测试通过');
  end
  else
  begin
    m.Release; // 释放第一次
    TestResults.AddResult('❌ 可重入互斥锁测试失败');
  end;
end;

begin
  WriteLn('🚀 开始健壮的并发测试');
  WriteLn('');
  
  TestResults := TTestResults.Create;
  try
    TestCrossThreadExclusion;
    WriteLn('');
    
    TestMultiThreadContention;
    WriteLn('');
    
    TestReentrantMutex;
    WriteLn('');
    
    WriteLn('=== 测试结果汇总 ===');
    TestResults.PrintResults;
    WriteLn('');
    WriteLn('总共记录了 ', TestResults.GetCount, ' 条结果');
    WriteLn('🎉 健壮并发测试完成！');
    
  finally
    TestResults.Free;
  end;
end.
