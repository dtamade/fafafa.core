program spin_lock_example;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.sync;

type
  // 工作线程示例
  TWorkerThread = class(TThread)
  private
    FSpinLock: ISpinLock;
    FCounter: PInteger;
    FThreadId: Integer;
    FIterations: Integer;
  public
    constructor Create(const ASpinLock: ISpinLock; ACounter: PInteger; 
                      AThreadId, AIterations: Integer);
    procedure Execute; override;
  end;

var
  SpinLock: ISpinLock;
  Counter: Integer;
  Threads: array[1..4] of TWorkerThread;
  I: Integer;
  StartTime, EndTime: QWord;

{ TWorkerThread }

constructor TWorkerThread.Create(const ASpinLock: ISpinLock; ACounter: PInteger; 
                                AThreadId, AIterations: Integer);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FSpinLock := ASpinLock;
  FCounter := ACounter;
  FThreadId := AThreadId;
  FIterations := AIterations;
end;

procedure TWorkerThread.Execute;
var
  I: Integer;
begin
  WriteLn(Format('Thread %d started', [FThreadId]));
  
  for I := 1 to FIterations do
  begin
    // 使用自旋锁保护共享计数器
    FSpinLock.Acquire;
    try
      Inc(FCounter^);
      
      // 模拟一些短时间的工作
      // 注意：在实际应用中，自旋锁应该只保护非常短的临界区
      if (I mod 1000) = 0 then
        WriteLn(Format('Thread %d: %d iterations completed', [FThreadId, I]));
    finally
      FSpinLock.Release;
    end;
  end;
  
  WriteLn(Format('Thread %d finished', [FThreadId]));
end;

begin
  WriteLn('=== fafafa.core.sync.spin 示例程序 ===');
  WriteLn;
  
  // 1. 基本使用示例
  WriteLn('1. 基本使用示例');
  SpinLock := MakeSpinLock(1000);
  
  WriteLn('创建自旋锁，自旋次数: ', SpinLock.GetSpinCount);
  WriteLn('初始状态 - 已锁定: ', SpinLock.IsLocked);
  
  SpinLock.Acquire;
  WriteLn('获取锁后 - 已锁定: ', SpinLock.IsLocked);
  WriteLn('锁的拥有者线程ID: ', SpinLock.GetOwnerThread);
  
  SpinLock.Release;
  WriteLn('释放锁后 - 已锁定: ', SpinLock.IsLocked);
  WriteLn;
  
  // 2. TryAcquire 示例
  WriteLn('2. TryAcquire 示例');
  if SpinLock.TryAcquire then
  begin
    WriteLn('TryAcquire 成功');
    SpinLock.Release;
  end
  else
    WriteLn('TryAcquire 失败');
  
  // 带超时的 TryAcquire
  if SpinLock.TryAcquire(100) then
  begin
    WriteLn('TryAcquire(100ms) 成功');
    SpinLock.Release;
  end
  else
    WriteLn('TryAcquire(100ms) 超时');
  WriteLn;
  
  // 3. 多线程并发示例
  WriteLn('3. 多线程并发示例');
  Counter := 0;
  SpinLock := MakeSpinLock(2000); // 创建新的自旋锁用于多线程测试
  
  WriteLn('启动 4 个工作线程，每个线程执行 10000 次递增操作...');
  StartTime := GetTickCount64;
  
  // 创建并启动工作线程
  for I := 1 to 4 do
  begin
    Threads[I] := TWorkerThread.Create(SpinLock, @Counter, I, 10000);
    Threads[I].Start;
  end;
  
  // 等待所有线程完成
  for I := 1 to 4 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;
  
  EndTime := GetTickCount64;
  
  WriteLn;
  WriteLn('所有线程完成');
  WriteLn('最终计数器值: ', Counter);
  WriteLn('预期值: ', 4 * 10000);
  WriteLn('执行时间: ', EndTime - StartTime, ' ms');
  
  if Counter = 40000 then
    WriteLn('✓ 测试通过：计数器值正确')
  else
    WriteLn('✗ 测试失败：计数器值不正确');
  
  WriteLn;
  
  // 4. 自旋次数调优示例
  WriteLn('4. 自旋次数调优示例');
  SpinLock := MakeSpinLock(500);
  WriteLn('初始自旋次数: ', SpinLock.GetSpinCount);
  
  SpinLock.SetSpinCount(5000);
  WriteLn('调整后自旋次数: ', SpinLock.GetSpinCount);
  WriteLn;
  
  // 5. 性能对比示例（简单）
  WriteLn('5. 简单性能测试');
  const TestIterations = 100000;
  
  // 测试自旋锁性能
  SpinLock := MakeSpinLock(1000);
  StartTime := GetTickCount64;
  for I := 1 to TestIterations do
  begin
    SpinLock.Acquire;
    SpinLock.Release;
  end;
  EndTime := GetTickCount64;
  WriteLn('自旋锁 ', TestIterations, ' 次获取/释放耗时: ', EndTime - StartTime, ' ms');
  
  WriteLn;
  WriteLn('=== 示例程序完成 ===');
  
  WriteLn;
  WriteLn('使用建议:');
  WriteLn('- 自旋锁适用于非常短的临界区（< 100 条指令）');
  WriteLn('- 在高竞争场景下考虑使用互斥锁');
  WriteLn('- 根据系统负载动态调整自旋次数');
  WriteLn('- 避免在自旋锁中进行 I/O 操作或长时间计算');
end.
