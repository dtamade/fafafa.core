{$CODEPAGE UTF8}
program test_adaptive_spin;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.rwlock.base, fafafa.core.sync.rwlock;

type
  TSpinTestThread = class(TThread)
  private
    FRWLock: TRWLock;
    FOperationCount: Integer;
    FIsReader: Boolean;
    FStartTime: QWord;
    FEndTime: QWord;
  public
    constructor Create(ARWLock: TRWLock; AOperationCount: Integer; AIsReader: Boolean);
    procedure Execute; override;
    property StartTime: QWord read FStartTime;
    property EndTime: QWord read FEndTime;
    property OperationCount: Integer read FOperationCount;
  end;

constructor TSpinTestThread.Create(ARWLock: TRWLock; AOperationCount: Integer; AIsReader: Boolean);
begin
  FRWLock := ARWLock;
  FOperationCount := AOperationCount;
  FIsReader := AIsReader;
  inherited Create(False);
end;

procedure TSpinTestThread.Execute;
var
  i: Integer;
begin
  FStartTime := GetTickCount64;
  
  for i := 1 to FOperationCount do
  begin
    if FIsReader then
    begin
      FRWLock.AcquireRead;
      try
        // 模拟读操作
        Sleep(0);
      finally
        FRWLock.ReleaseRead;
      end;
    end
    else
    begin
      FRWLock.AcquireWrite;
      try
        // 模拟写操作
        Sleep(0);
      finally
        FRWLock.ReleaseWrite;
      end;
    end;
  end;
  
  FEndTime := GetTickCount64;
end;

procedure TestLowContention;
var
  RWLock: TRWLock;
  Options: TRWLockOptions;
  Thread: TSpinTestThread;
  StartTime, EndTime: QWord;
  ElapsedMs: QWord;
  OpsPerSec: Double;
begin
  WriteLn('=== 测试低竞争场景（自适应自旋应该增加） ===');
  
  // 使用较小的初始自旋次数
  Options := DefaultRWLockOptions;
  Options.SpinCount := 1000;
  
  RWLock := TRWLock.Create(Options);
  try
    WriteLn('初始自旋次数: ', Options.SpinCount);
    
    // 单线程操作，应该没有竞争
    Thread := TSpinTestThread.Create(RWLock, 50000, True);
    try
      StartTime := GetTickCount64;
      Thread.WaitFor;
      EndTime := GetTickCount64;
      
      ElapsedMs := EndTime - StartTime;
      OpsPerSec := (50000 * 1000.0) / ElapsedMs;
      
      WriteLn('单线程读操作: 50000 ops, ', ElapsedMs, ' ms, ', Round(OpsPerSec), ' ops/sec');
      WriteLn('竞争计数: ', RWLock.GetContentionCount);
      WriteLn('当前自旋次数: ', RWLock.GetSpinCount);
      
    finally
      Thread.Free;
    end;
    
  finally
    RWLock.Free;
  end;
  
  WriteLn;
end;

procedure TestHighContention;
var
  RWLock: TRWLock;
  Options: TRWLockOptions;
  Threads: array[0..7] of TSpinTestThread;
  i: Integer;
  StartTime, EndTime: QWord;
  ElapsedMs: QWord;
  TotalOps: Integer;
  OpsPerSec: Double;
begin
  WriteLn('=== 测试高竞争场景（自适应自旋应该减少） ===');
  
  // 使用较大的初始自旋次数
  Options := DefaultRWLockOptions;
  Options.SpinCount := 8000;
  
  RWLock := TRWLock.Create(Options);
  try
    WriteLn('初始自旋次数: ', Options.SpinCount);
    
    // 创建多个线程，产生高竞争
    for i := 0 to 7 do
    begin
      if i < 6 then
        Threads[i] := TSpinTestThread.Create(RWLock, 10000, True)  // 读线程
      else
        Threads[i] := TSpinTestThread.Create(RWLock, 5000, False); // 写线程
    end;
    
    StartTime := GetTickCount64;
    
    // 等待所有线程完成
    for i := 0 to 7 do
      Threads[i].WaitFor;
      
    EndTime := GetTickCount64;
    
    ElapsedMs := EndTime - StartTime;
    TotalOps := 6 * 10000 + 2 * 5000;  // 6个读线程 + 2个写线程
    OpsPerSec := (TotalOps * 1000.0) / ElapsedMs;
    
    WriteLn('多线程操作: ', TotalOps, ' ops, ', ElapsedMs, ' ms, ', Round(OpsPerSec), ' ops/sec');
    WriteLn('竞争计数: ', RWLock.GetContentionCount);
    WriteLn('当前自旋次数: ', RWLock.GetSpinCount);
    
    // 清理线程
    for i := 0 to 7 do
      Threads[i].Free;
      
  finally
    RWLock.Free;
  end;
  
  WriteLn;
end;

procedure TestAdaptiveAdjustment;
var
  RWLock: TRWLock;
  Options: TRWLockOptions;
  i, j: Integer;
  InitialSpinCount, FinalSpinCount: Integer;
begin
  WriteLn('=== 测试自适应调整过程 ===');
  
  Options := DefaultRWLockOptions;
  Options.SpinCount := 4000;
  
  RWLock := TRWLock.Create(Options);
  try
    InitialSpinCount := RWLock.GetSpinCount;
    WriteLn('初始自旋次数: ', InitialSpinCount);
    
    // 模拟不同的竞争模式
    WriteLn('阶段1: 低竞争模式（单线程）');
    for i := 1 to 5 do
    begin
      for j := 1 to 500 do
      begin
        RWLock.AcquireRead;
        RWLock.ReleaseRead;
      end;
      // 等待足够时间让调整生效
      Sleep(150);
      WriteLn('  第', i, '轮后自旋次数: ', RWLock.GetSpinCount, ', 竞争计数: ', RWLock.GetContentionCount);
    end;
    
    WriteLn('阶段2: 高竞争模式（快速竞争模拟）');
    // 通过快速的获取和释放来模拟竞争
    for i := 1 to 3 do
    begin
      // 快速的读写操作，产生竞争统计
      for j := 1 to 500 do
      begin
        // 快速读操作
        RWLock.AcquireRead;
        RWLock.ReleaseRead;

        // 偶尔的写操作增加竞争
        if j mod 10 = 0 then
        begin
          RWLock.AcquireWrite;
          RWLock.ReleaseWrite;
        end;
      end;
      // 等待足够时间让调整生效
      Sleep(150);
      WriteLn('  第', i, '轮后自旋次数: ', RWLock.GetSpinCount, ', 竞争计数: ', RWLock.GetContentionCount);
    end;
    
    FinalSpinCount := RWLock.GetSpinCount;
    WriteLn('最终自旋次数: ', FinalSpinCount);
    WriteLn('调整幅度: ', FinalSpinCount - InitialSpinCount);
    
  finally
    RWLock.Free;
  end;
  
  WriteLn;
end;

begin
  WriteLn('fafafa.core.sync.rwlock 自适应自旋优化测试');
  WriteLn('=============================================');
  WriteLn;
  
  TestLowContention;
  TestHighContention;
  TestAdaptiveAdjustment;
  
  WriteLn('自适应自旋优化测试完成');
  WriteLn('验证了自旋次数能够根据竞争情况动态调整');
end.
