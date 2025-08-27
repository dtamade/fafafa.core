program AtomicDemo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.sync;

{**
 * 演示基础原子操作
 *}
procedure DemoBasicAtomicOperations;
var
  LCounter: Integer;
  LValue: Int64;
  LPtr: Pointer;
  LFlag: Boolean;
  LResult: Integer;
begin
  WriteLn('=== 基础原子操作演示 ===');
  
  // 32位整数原子操作
  LCounter := 10;
  WriteLn('初始计数器: ', LCounter);
  
  LResult := TAtomic.Increment(LCounter);
  WriteLn('递增后: ', LCounter, ' (返回值: ', LResult, ')');
  
  LResult := TAtomic.Decrement(LCounter);
  WriteLn('递减后: ', LCounter, ' (返回值: ', LResult, ')');
  
  LResult := TAtomic.Add(LCounter, 5);
  WriteLn('加5后: ', LCounter, ' (返回值: ', LResult, ')');
  
  LResult := TAtomic.Exchange(LCounter, 100);
  WriteLn('交换为100: ', LCounter, ' (旧值: ', LResult, ')');
  
  LResult := TAtomic.CompareExchange(LCounter, 200, 100);
  WriteLn('比较交换(100->200): ', LCounter, ' (旧值: ', LResult, ')');
  
  LResult := TAtomic.CompareExchange(LCounter, 300, 150);
  WriteLn('比较交换失败(150->300): ', LCounter, ' (旧值: ', LResult, ')');
  
  // 64位整数原子操作
  WriteLn;
  WriteLn('64位原子操作:');
  LValue := 1000000000;
  WriteLn('初始64位值: ', LValue);
  
  LValue := TAtomic.Increment64(LValue);
  WriteLn('64位递增后: ', LValue);
  
  LValue := TAtomic.Add64(LValue, 999999999);
  WriteLn('64位加法后: ', LValue);
  
  // 布尔原子操作
  WriteLn;
  WriteLn('布尔原子操作:');
  LFlag := False;
  WriteLn('初始布尔值: ', BoolToStr(LFlag, 'True', 'False'));
  
  LFlag := TAtomic.ExchangeBool(LFlag, True);
  WriteLn('交换为True后: ', BoolToStr(LFlag, 'True', 'False'));
  
  WriteLn('基础原子操作演示完成');
  WriteLn;
end;

{**
 * 简单的工作线程类
 *}
type
  TAtomicWorkerThread = class(TThread)
  private
    FCounter: PInteger;
    FIterations: Integer;
  public
    constructor Create(ACounter: PInteger; AIterations: Integer);
    procedure Execute; override;
  end;

constructor TAtomicWorkerThread.Create(ACounter: PInteger; AIterations: Integer);
begin
  FCounter := ACounter;
  FIterations := AIterations;
  inherited Create(False);
end;

procedure TAtomicWorkerThread.Execute;
var
  I: Integer;
begin
  for I := 1 to FIterations do
    TAtomic.Increment(FCounter^);
end;

{**
 * 演示多线程原子操作
 *}
procedure DemoMultithreadedAtomicOperations;
var
  LSharedCounter: Integer;
  LThreads: array[0..4] of TAtomicWorkerThread;
  I: Integer;
begin
  WriteLn('=== 多线程原子操作演示 ===');

  LSharedCounter := 0;
  WriteLn('初始共享计数器: ', LSharedCounter);

  // 创建5个线程，每个线程递增计数器1000次
  for I := 0 to High(LThreads) do
  begin
    LThreads[I] := TAtomicWorkerThread.Create(@LSharedCounter, 1000);
  end;

  // 等待所有线程完成
  for I := 0 to High(LThreads) do
  begin
    LThreads[I].WaitFor;
    LThreads[I].Free;
  end;

  WriteLn('5个线程完成后的计数器: ', LSharedCounter);
  WriteLn('预期值: 5000');

  if LSharedCounter = 5000 then
    WriteLn('✅ 多线程原子操作成功！')
  else
    WriteLn('❌ 多线程原子操作失败！');

  WriteLn('多线程原子操作演示完成');
  WriteLn;
end;

{**
 * 演示原子操作的性能
 *}
procedure DemoAtomicPerformance;
var
  LCounter: Integer;
  LStartTime, LEndTime: QWord;
  LElapsed: QWord;
  I: Integer;
begin
  WriteLn('=== 原子操作性能演示 ===');
  
  LCounter := 0;
  
  // 测试100万次原子递增的性能
  WriteLn('执行100万次原子递增...');
  LStartTime := GetTickCount64;
  for I := 1 to 1000000 do
    TAtomic.Increment(LCounter);
  LEndTime := GetTickCount64;
  LElapsed := LEndTime - LStartTime;
  
  WriteLn('最终计数器值: ', LCounter);
  WriteLn('耗时: ', LElapsed, ' ms');
  WriteLn('平均每次操作: ', (LElapsed * 1000) / 1000000:0:3, ' μs');
  
  if LElapsed < 1000 then
    WriteLn('✅ 原子操作性能优秀！')
  else
    WriteLn('⚠️ 原子操作性能一般');
    
  WriteLn('原子操作性能演示完成');
  WriteLn;
end;

{**
 * 演示原子操作与锁的对比
 *}
procedure DemoAtomicVsLock;
var
  LAtomicCounter: Integer;
  LLockedCounter: Integer;
  LMutex: ILock;
  LStartTime, LEndTime: QWord;
  LAtomicTime, LLockedTime: QWord;
  I: Integer;
begin
  WriteLn('=== 原子操作 vs 锁性能对比 ===');
  
  LAtomicCounter := 0;
  LLockedCounter := 0;
  LMutex := TMutex.Create;
  
  // 测试原子操作性能
  WriteLn('测试10万次原子递增...');
  LStartTime := GetTickCount64;
  for I := 1 to 100000 do
    TAtomic.Increment(LAtomicCounter);
  LEndTime := GetTickCount64;
  LAtomicTime := LEndTime - LStartTime;
  
  // 测试锁保护的操作性能
  WriteLn('测试10万次锁保护递增...');
  LStartTime := GetTickCount64;
  for I := 1 to 100000 do
  begin
    LMutex.Acquire;
    try
      Inc(LLockedCounter);
    finally
      LMutex.Release;
    end;
  end;
  LEndTime := GetTickCount64;
  LLockedTime := LEndTime - LStartTime;
  
  WriteLn('原子操作结果: ', LAtomicCounter, ', 耗时: ', LAtomicTime, ' ms');
  WriteLn('锁保护操作结果: ', LLockedCounter, ', 耗时: ', LLockedTime, ' ms');
  
  if LAtomicTime < LLockedTime then
    WriteLn('✅ 原子操作比锁快 ', ((LLockedTime - LAtomicTime) * 100) div LLockedTime, '%')
  else
    WriteLn('⚠️ 锁操作比原子操作快');
    
  WriteLn('性能对比演示完成');
  WriteLn;
end;

{**
 * 主程序
 *}
begin
  WriteLn('fafafa.core.sync 原子操作演示');
  WriteLn('==============================');
  WriteLn;
  
  try
    DemoBasicAtomicOperations;
    DemoMultithreadedAtomicOperations;
    DemoAtomicPerformance;
    DemoAtomicVsLock;
    
    WriteLn('所有原子操作演示完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('演示过程中发生异常: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
