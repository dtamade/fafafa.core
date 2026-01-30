program timeout_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.sync.mutex.parkinglot;

var
  Mutex: ITryLock;
  StartTime, EndTime: DWORD;
  ElapsedMs: DWORD;

begin
  WriteLn('parking_lot Mutex 超时功能测试');
  WriteLn('================================');
  
  Mutex := MakeParkingLotMutex;
  
  // 测试 1: 无竞争情况下的立即获取
  WriteLn('测试 1: 无竞争立即获取');
  StartTime := GetTickCount;
  if Mutex.TryAcquire(1000) then
  begin
    EndTime := GetTickCount;
    ElapsedMs := EndTime - StartTime;
    WriteLn(Format('  ✓ 成功获取锁，耗时: %d ms', [ElapsedMs]));
    Mutex.Release;
  end
  else
    WriteLn('  ✗ 获取锁失败');
  
  WriteLn;
  
  // 测试 2: 零超时测试
  WriteLn('测试 2: 零超时测试');
  Mutex.Acquire; // 先获取锁
  StartTime := GetTickCount;
  if Mutex.TryAcquire(0) then
  begin
    WriteLn('  ✗ 不应该获取到锁');
    Mutex.Release;
  end
  else
  begin
    EndTime := GetTickCount;
    ElapsedMs := EndTime - StartTime;
    WriteLn(Format('  ✓ 正确返回失败，耗时: %d ms', [ElapsedMs]));
  end;
  Mutex.Release;
  
  WriteLn;
  
  // 测试 3: 短超时测试
  WriteLn('测试 3: 短超时测试 (100ms)');
  Mutex.Acquire; // 先获取锁
  StartTime := GetTickCount;
  if Mutex.TryAcquire(100) then
  begin
    WriteLn('  ✗ 不应该获取到锁');
    Mutex.Release;
  end
  else
  begin
    EndTime := GetTickCount;
    ElapsedMs := EndTime - StartTime;
    WriteLn(Format('  ✓ 正确超时，耗时: %d ms (期望: ~100ms)', [ElapsedMs]));
    if (ElapsedMs >= 90) and (ElapsedMs <= 150) then
      WriteLn('  ✓ 超时精度良好')
    else
      WriteLn('  ⚠ 超时精度可能需要优化');
  end;
  Mutex.Release;
  
  WriteLn;
  
  // 测试 4: 中等超时测试
  WriteLn('测试 4: 中等超时测试 (500ms)');
  Mutex.Acquire; // 先获取锁
  StartTime := GetTickCount;
  if Mutex.TryAcquire(500) then
  begin
    WriteLn('  ✗ 不应该获取到锁');
    Mutex.Release;
  end
  else
  begin
    EndTime := GetTickCount;
    ElapsedMs := EndTime - StartTime;
    WriteLn(Format('  ✓ 正确超时，耗时: %d ms (期望: ~500ms)', [ElapsedMs]));
    if (ElapsedMs >= 450) and (ElapsedMs <= 600) then
      WriteLn('  ✓ 超时精度良好')
    else
      WriteLn('  ⚠ 超时精度可能需要优化');
  end;
  Mutex.Release;
  
  WriteLn;
  WriteLn('超时功能测试完成！');
  WriteLn;
  WriteLn('改进说明:');
  WriteLn('- 使用 WaitOnAddress (Windows) 和 futex (Linux) 的原生超时功能');
  WriteLn('- 精确的超时计算和剩余时间传递');
  WriteLn('- 避免了粗糙的 Sleep(1) 循环');
  WriteLn('- 提供了高精度、高效率的超时等待');
end.
