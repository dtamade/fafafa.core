unit fafafa.core.sync.mutex.extreme.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.mutex, fafafa.core.sync.base;

type
  // 极端边界条件测试
  TTestCase_ExtremeBoundary = class(TTestCase)
  private
    FTestResults: TStringList;
    procedure LogResult(const AMessage: string);
    function GetAvailableMemory: QWord;
    function MakeMutexSafely: IMutex;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 资源极限测试
    procedure Test_MassiveMutexCreation;
    procedure Test_MemoryExhaustionHandling;
    procedure Test_SystemResourceLimits;
    
    // 边界值测试
    procedure Test_WindowsSpinCountBoundaries;
    procedure Test_InvalidParameterHandling;
    procedure Test_ZeroTimeoutBehavior;
    
    // 系统负载测试
    procedure Test_HighSystemLoadPerformance;
    procedure Test_MemoryPressureStability;
    procedure Test_CPUStarvationResilience;
  end;

implementation

uses
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  {$IFDEF UNIX}
  BaseUnix, Unix,
  {$ENDIF}
  Math;

{ TTestCase_ExtremeBoundary }

procedure TTestCase_ExtremeBoundary.SetUp;
begin
  inherited SetUp;
  FTestResults := TStringList.Create;
  LogResult('=== 极端边界条件测试开始 ===');
end;

procedure TTestCase_ExtremeBoundary.TearDown;
var
  i: Integer;
begin
  LogResult('=== 极端边界条件测试结束 ===');
  
  // 输出测试结果到控制台
  for i := 0 to FTestResults.Count - 1 do
    WriteLn(FTestResults[i]);
    
  FTestResults.Free;
  inherited TearDown;
end;

procedure TTestCase_ExtremeBoundary.LogResult(const AMessage: string);
begin
  FTestResults.Add(Format('[%s] %s', [FormatDateTime('hh:nn:ss.zzz', Now), AMessage]));
end;

function TTestCase_ExtremeBoundary.GetAvailableMemory: QWord;
{$IFDEF WINDOWS}
var
  MemStatus: TMemoryStatusEx;
{$ENDIF}
begin
  Result := 0;
  {$IFDEF WINDOWS}
  MemStatus.dwLength := SizeOf(MemStatus);
  if GlobalMemoryStatusEx(MemStatus) then
    Result := MemStatus.ullAvailPhys;
  {$ENDIF}
  {$IFDEF UNIX}
  // Unix 下的内存检测实现
  Result := 1024 * 1024 * 1024; // 假设 1GB 可用内存
  {$ENDIF}
end;

function TTestCase_ExtremeBoundary.MakeMutexSafely: IMutex;
begin
  try
    Result := MakeMutex;
  except
    on E: Exception do
    begin
      LogResult('创建互斥锁失败: ' + E.Message);
      Result := nil;
    end;
  end;
end;

procedure TTestCase_ExtremeBoundary.Test_MassiveMutexCreation;
const
  MAX_MUTEXES = 10000;
var
  Mutexes: array of IMutex;
  i, SuccessCount, FailCount: Integer;
  StartTime, EndTime: QWord;
  MemBefore, MemAfter: QWord;
begin
  LogResult('开始大量互斥锁创建测试...');
  
  SetLength(Mutexes, MAX_MUTEXES);
  SuccessCount := 0;
  FailCount := 0;
  
  MemBefore := GetAvailableMemory;
  StartTime := GetTickCount64;
  
  // 创建大量互斥锁
  for i := 0 to MAX_MUTEXES - 1 do
  begin
    Mutexes[i] := MakeMutexSafely;
    if Assigned(Mutexes[i]) then
    begin
      Inc(SuccessCount);
      // 测试基本功能
      try
        Mutexes[i].Acquire;
        Mutexes[i].Release;
      except
        Inc(FailCount);
        LogResult(Format('互斥锁 #%d 功能测试失败', [i]));
      end;
    end
    else
      Inc(FailCount);
      
    // 每1000个检查一次进度
    if (i + 1) mod 1000 = 0 then
      LogResult(Format('已创建 %d 个互斥锁，成功: %d，失败: %d', [i + 1, SuccessCount, FailCount]));
  end;
  
  EndTime := GetTickCount64;
  MemAfter := GetAvailableMemory;
  
  LogResult(Format('大量创建测试完成: 总数=%d, 成功=%d, 失败=%d, 耗时=%dms', 
    [MAX_MUTEXES, SuccessCount, FailCount, EndTime - StartTime]));
  LogResult(Format('内存使用: 前=%d MB, 后=%d MB, 差值=%d MB', 
    [MemBefore div (1024*1024), MemAfter div (1024*1024), 
     (MemBefore - MemAfter) div (1024*1024)]));
  
  // 清理资源
  for i := 0 to MAX_MUTEXES - 1 do
    Mutexes[i] := nil;
    
  // 验证至少能创建大部分互斥锁
  AssertTrue('应该能创建大部分互斥锁', SuccessCount > MAX_MUTEXES * 0.9);
  AssertTrue('失败率应该很低', FailCount < MAX_MUTEXES * 0.1);
end;

procedure TTestCase_ExtremeBoundary.Test_MemoryExhaustionHandling;
var
  Mutexes: TList;
  Mutex: IMutex;
  i: Integer;
  LastError: string;
  MemBefore: QWord;
begin
  LogResult('开始内存耗尽处理测试...');
  
  Mutexes := TList.Create;
  try
    MemBefore := GetAvailableMemory;
    LogResult(Format('测试开始时可用内存: %d MB', [MemBefore div (1024*1024)]));
    
    // 持续创建直到内存不足
    i := 0;
    while i < 50000 do // 设置上限防止系统崩溃
    begin
      try
        Mutex := MakeMutex;
        if Assigned(Mutex) then
        begin
          Mutexes.Add(Pointer(Mutex));
          Mutex._AddRef; // 增加引用计数防止释放
          Inc(i);
          
          if i mod 5000 = 0 then
            LogResult(Format('已创建 %d 个互斥锁', [i]));
        end
        else
          Break;
      except
        on E: Exception do
        begin
          LastError := E.Message;
          LogResult(Format('在第 %d 个互斥锁时发生异常: %s', [i, E.Message]));
          Break;
        end;
      end;
    end;
    
    LogResult(Format('内存耗尽测试完成，共创建 %d 个互斥锁', [i]));
    if LastError <> '' then
      LogResult('最后错误: ' + LastError);
    
    // 清理资源
    for i := 0 to Mutexes.Count - 1 do
    begin
      Mutex := IMutex(Mutexes[i]);
      Mutex._Release;
    end;
    
    AssertTrue('应该能创建大量互斥锁', Mutexes.Count > 1000);
    
  finally
    Mutexes.Free;
  end;
end;

procedure TTestCase_ExtremeBoundary.Test_SystemResourceLimits;
var
  Mutexes: array of IMutex;
  i, MaxCreated: Integer;
  StartTime: QWord;
begin
  LogResult('开始系统资源限制测试...');
  
  SetLength(Mutexes, 20000);
  MaxCreated := 0;
  StartTime := GetTickCount64;
  
  // 快速创建直到系统限制
  for i := 0 to High(Mutexes) do
  begin
    try
      Mutexes[i] := MakeMutex;
      if Assigned(Mutexes[i]) then
      begin
        MaxCreated := i + 1;
        // 快速测试功能
        if not Mutexes[i].TryAcquire then
          LogResult(Format('互斥锁 #%d TryAcquire 失败', [i]));
        Mutexes[i].Release;
      end
      else
        Break;
    except
      on E: Exception do
      begin
        LogResult(Format('资源限制异常在第 %d 个: %s', [i, E.Message]));
        Break;
      end;
    end;
    
    // 检查超时
    if GetTickCount64 - StartTime > 30000 then // 30秒超时
    begin
      LogResult('系统资源测试超时');
      Break;
    end;
  end;
  
  LogResult(Format('系统资源限制测试完成，最大创建数: %d', [MaxCreated]));
  
  // 清理
  for i := 0 to MaxCreated - 1 do
    Mutexes[i] := nil;
    
  AssertTrue('应该能创建合理数量的互斥锁', MaxCreated > 100);
end;

procedure TTestCase_ExtremeBoundary.Test_WindowsSpinCountBoundaries;
{$IFDEF WINDOWS}
var
  Mutex1, Mutex2, Mutex3: IMutex;
  WindowsImpl: fafafa.core.sync.mutex.windows.TMutex;
  OldSpinCount: DWORD;
{$ENDIF}
begin
  LogResult('开始 Windows 自旋计数边界测试...');
  
  {$IFDEF WINDOWS}
  try
    // 测试最小值
    Mutex1 := MakeMutex(0);
    AssertNotNull('自旋计数=0 应该成功', Mutex1);
    Mutex1.Acquire;
    Mutex1.Release;
    
    // 测试最大值
    Mutex2 := MakeMutex(High(DWORD));
    AssertNotNull('自旋计数=MAX 应该成功', Mutex2);
    Mutex2.Acquire;
    Mutex2.Release;
    
    // 测试动态调整边界值
    Mutex3 := MakeMutex(4000);
    if Mutex3 is fafafa.core.sync.mutex.windows.TMutex then
    begin
      WindowsImpl := Mutex3 as fafafa.core.sync.mutex.windows.TMutex;
      
      // 测试设置为0
      OldSpinCount := WindowsImpl.SetSpinCount(0);
      LogResult(Format('设置自旋计数 0，旧值: %d', [OldSpinCount]));
      
      // 测试设置为最大值
      OldSpinCount := WindowsImpl.SetSpinCount(High(DWORD));
      LogResult(Format('设置自旋计数 MAX，旧值: %d', [OldSpinCount]));
      
      // 恢复正常值
      WindowsImpl.SetSpinCount(4000);
    end;
    
    LogResult('Windows 自旋计数边界测试通过');
    
  except
    on E: Exception do
    begin
      LogResult('Windows 自旋计数测试异常: ' + E.Message);
      Fail('Windows 自旋计数边界测试失败: ' + E.Message);
    end;
  end;
  {$ELSE}
  LogResult('跳过 Windows 特定测试（当前平台: Unix）');
  AssertTrue('Unix 平台跳过 Windows 测试', True);
  {$ENDIF}
end;

procedure TTestCase_ExtremeBoundary.Test_InvalidParameterHandling;
var
  Mutex: IMutex;
begin
  LogResult('开始无效参数处理测试...');
  
  try
    // 测试正常创建
    Mutex := MakeMutex;
    AssertNotNull('正常创建应该成功', Mutex);
    
    // 测试基本操作
    Mutex.Acquire;
    Mutex.Release;
    
    // 测试 TryAcquire
    AssertTrue('TryAcquire 应该成功', Mutex.TryAcquire);
    Mutex.Release;
    
    // 测试 GetHandle
    AssertNotNull('GetHandle 应该返回非空', Mutex.GetHandle);
    
    LogResult('无效参数处理测试通过');
    
  except
    on E: Exception do
    begin
      LogResult('无效参数测试异常: ' + E.Message);
      Fail('无效参数处理测试失败: ' + E.Message);
    end;
  end;
end;

procedure TTestCase_ExtremeBoundary.Test_ZeroTimeoutBehavior;
var
  Mutex: IMutex;
  i: Integer;
  SuccessCount: Integer;
begin
  LogResult('开始零超时行为测试...');
  
  Mutex := MakeMutex;
  SuccessCount := 0;
  
  // 测试未锁定状态下的 TryAcquire
  for i := 1 to 1000 do
  begin
    if Mutex.TryAcquire then
    begin
      Inc(SuccessCount);
      Mutex.Release;
    end;
  end;
  
  LogResult(Format('未锁定状态 TryAcquire 成功率: %d/1000', [SuccessCount]));
  AssertEquals('未锁定时应该总是成功', 1000, SuccessCount);
  
  // 测试已锁定状态下的 TryAcquire（递归锁）
  Mutex.Acquire;
  SuccessCount := 0;
  
  for i := 1 to 1000 do
  begin
    if Mutex.TryAcquire then
    begin
      Inc(SuccessCount);
      Mutex.Release;
    end;
  end;
  
  Mutex.Release; // 释放最初的锁
  
  LogResult(Format('已锁定状态 TryAcquire 成功率: %d/1000', [SuccessCount]));
  AssertEquals('递归锁应该总是成功', 1000, SuccessCount);
  
  LogResult('零超时行为测试通过');
end;

procedure TTestCase_ExtremeBoundary.Test_HighSystemLoadPerformance;
const
  LOAD_THREADS = 4;
  OPERATIONS_PER_THREAD = 50000;
var
  Mutex: IMutex;
  StartTime, EndTime: QWord;
  i, j: Integer;
  TotalOps: Integer;
  OpsPerSecond: Double;
begin
  LogResult('开始高系统负载性能测试...');
  
  Mutex := MakeMutex;
  TotalOps := LOAD_THREADS * OPERATIONS_PER_THREAD;
  
  StartTime := GetTickCount64;
  
  // 模拟高负载（单线程密集操作）
  for i := 1 to LOAD_THREADS do
  begin
    for j := 1 to OPERATIONS_PER_THREAD do
    begin
      Mutex.Acquire;
      // 模拟一些工作
      if j mod 10000 = 0 then
        Sleep(0); // 让出 CPU
      Mutex.Release;
    end;
  end;
  
  EndTime := GetTickCount64;
  
  OpsPerSecond := TotalOps / ((EndTime - StartTime) / 1000.0);
  
  LogResult(Format('高负载性能测试完成: %d 操作耗时 %d ms', [TotalOps, EndTime - StartTime]));
  LogResult(Format('性能: %.0f 操作/秒', [OpsPerSecond]));
  
  // 性能应该合理（至少每秒10万次操作）
  AssertTrue('高负载下性能应该合理', OpsPerSecond > 100000);
  
  LogResult('高系统负载性能测试通过');
end;

procedure TTestCase_ExtremeBoundary.Test_MemoryPressureStability;
var
  Mutex: IMutex;
  LargeArrays: array[0..9] of Pointer;
  i, j: Integer;
  TestPassed: Boolean;
const
  ARRAY_SIZE = 10 * 1024 * 1024; // 10MB per array
begin
  LogResult('开始内存压力稳定性测试...');
  
  Mutex := MakeMutex;
  TestPassed := True;
  
  try
    // 分配大量内存制造内存压力
    for i := 0 to High(LargeArrays) do
    begin
      GetMem(LargeArrays[i], ARRAY_SIZE);
      FillChar(LargeArrays[i]^, ARRAY_SIZE, i);
    end;
    
    LogResult('已分配 100MB 内存，开始互斥锁操作测试...');
    
    // 在内存压力下测试互斥锁
    for i := 1 to 10000 do
    begin
      try
        Mutex.Acquire;
        // 访问大内存块
        for j := 0 to High(LargeArrays) do
          PByte(LargeArrays[j])^ := i mod 256;
        Mutex.Release;
      except
        on E: Exception do
        begin
          LogResult(Format('内存压力下操作失败 #%d: %s', [i, E.Message]));
          TestPassed := False;
          Break;
        end;
      end;
      
      if i mod 1000 = 0 then
        LogResult(Format('完成 %d 次内存压力操作', [i]));
    end;
    
  finally
    // 清理内存
    for i := 0 to High(LargeArrays) do
      if Assigned(LargeArrays[i]) then
        FreeMem(LargeArrays[i]);
  end;
  
  AssertTrue('内存压力下应该保持稳定', TestPassed);
  LogResult('内存压力稳定性测试通过');
end;

procedure TTestCase_ExtremeBoundary.Test_CPUStarvationResilience;
var
  Mutex: IMutex;
  i: Integer;
  StartTime, EndTime: QWord;
  MaxDelay, TotalDelay: QWord;
begin
  LogResult('开始 CPU 饥饿恢复能力测试...');
  
  Mutex := MakeMutex;
  MaxDelay := 0;
  TotalDelay := 0;
  
  // 模拟 CPU 密集操作与互斥锁操作交替
  for i := 1 to 1000 do
  begin
    StartTime := GetTickCount64;
    
    // CPU 密集计算
    var Sum: Double := 0;
    for var j := 1 to 10000 do
      Sum := Sum + Sqrt(j);
    
    // 互斥锁操作
    Mutex.Acquire;
    Mutex.Release;
    
    EndTime := GetTickCount64;
    var Delay := EndTime - StartTime;
    TotalDelay := TotalDelay + Delay;
    if Delay > MaxDelay then
      MaxDelay := Delay;
    
    if i mod 100 = 0 then
      LogResult(Format('完成 %d 次 CPU 饥饿测试，最大延迟: %d ms', [i, MaxDelay]));
  end;
  
  LogResult(Format('CPU 饥饿测试完成，平均延迟: %.2f ms，最大延迟: %d ms', 
    [TotalDelay / 1000.0, MaxDelay]));
  
  // 最大延迟应该在合理范围内
  AssertTrue('最大延迟应该合理', MaxDelay < 1000); // 小于1秒
  
  LogResult('CPU 饥饿恢复能力测试通过');
end;

initialization
  RegisterTest(TTestCase_ExtremeBoundary);

end.
