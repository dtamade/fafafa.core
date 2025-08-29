program policy_validation_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.spin.base,
  fafafa.core.sync.spin;

type
  TTestThread = class(TThread)
  private
    FSpinLock: ISpinLock;
    FHoldTime: Integer;
    FIterations: Integer;
  public
    constructor Create(ASpinLock: ISpinLock; AHoldTime, AIterations: Integer);
    procedure Execute; override;
  end;

constructor TTestThread.Create(ASpinLock: ISpinLock; AHoldTime, AIterations: Integer);
begin
  inherited Create(False);
  FSpinLock := ASpinLock;
  FHoldTime := AHoldTime;
  FIterations := AIterations;
end;

procedure TTestThread.Execute;
var
  i: Integer;
begin
  for i := 1 to FIterations do
  begin
    FSpinLock.Acquire;
    try
      Sleep(FHoldTime); // 模拟工作
    finally
      FSpinLock.Release;
    end;
  end;
end;

var
  Policy: TSpinLockPolicy;
  SpinLock: ISpinLock;
  WithStats: ISpinLockWithStats;
  Stats: TSpinLockStats;
  Thread1, Thread2: TTestThread;
  StartTime: QWord;

begin
  WriteLn('测试自旋策略参数是否生效...');
  WriteLn('');
  
  // 测试1: 低自旋次数策略
  WriteLn('1. 测试低自旋次数策略 (MaxSpins=8)...');
  Policy := DefaultSpinLockPolicy;
  Policy.MaxSpins := 8;
  Policy.BackoffStrategy := sbsLinear;
  Policy.MaxBackoffMs := 5;
  Policy.EnableStats := True;
  
  SpinLock := MakeSpinLock(Policy);
  SpinLock.QueryInterface(ISpinLockWithStats, WithStats);
  
  StartTime := GetTickCount64;
  
  // 创建两个线程来产生竞争
  Thread1 := TTestThread.Create(SpinLock, 10, 20); // 持锁10ms，20次
  Thread2 := TTestThread.Create(SpinLock, 10, 20);
  
  Thread1.WaitFor;
  Thread2.WaitFor;
  
  Stats := WithStats.GetStats;
  WriteLn('   总获取次数: ', Stats.AcquireCount);
  WriteLn('   竞争次数: ', Stats.ContentionCount);
  WriteLn('   总自旋次数: ', Stats.TotalSpinCount);
  WriteLn('   平均自旋次数: ', Stats.AvgSpinsPerAcquire:0:2);
  WriteLn('   竞争率: ', WithStats.GetContentionRate:0:2);
  WriteLn('   执行时间: ', GetTickCount64 - StartTime, ' ms');
  
  Thread1.Free;
  Thread2.Free;
  
  WriteLn('');
  
  // 测试2: 高自旋次数策略
  WriteLn('2. 测试高自旋次数策略 (MaxSpins=128)...');
  Policy.MaxSpins := 128;
  Policy.BackoffStrategy := sbsExponential;
  Policy.MaxBackoffMs := 16;
  
  SpinLock := MakeSpinLock(Policy);
  SpinLock.QueryInterface(ISpinLockWithStats, WithStats);
  
  StartTime := GetTickCount64;
  
  Thread1 := TTestThread.Create(SpinLock, 5, 30); // 持锁5ms，30次
  Thread2 := TTestThread.Create(SpinLock, 5, 30);
  
  Thread1.WaitFor;
  Thread2.WaitFor;
  
  Stats := WithStats.GetStats;
  WriteLn('   总获取次数: ', Stats.AcquireCount);
  WriteLn('   竞争次数: ', Stats.ContentionCount);
  WriteLn('   总自旋次数: ', Stats.TotalSpinCount);
  WriteLn('   平均自旋次数: ', Stats.AvgSpinsPerAcquire:0:2);
  WriteLn('   竞争率: ', WithStats.GetContentionRate:0:2);
  WriteLn('   执行时间: ', GetTickCount64 - StartTime, ' ms');
  
  Thread1.Free;
  Thread2.Free;
  
  WriteLn('');
  
  // 测试3: 验证策略更新
  WriteLn('3. 测试策略动态更新...');
  SpinLock := MakeSpinLock(DefaultSpinLockPolicy);
  
  WriteLn('   初始 MaxSpins: ', SpinLock.GetSpinCount);
  
  SpinLock.SetSpinCount(256);
  WriteLn('   更新后 MaxSpins: ', SpinLock.GetSpinCount);
  
  Policy := SpinLock.GetPolicy;
  Policy.BackoffStrategy := sbsAdaptive;
  Policy.MaxBackoffMs := 32;
  SpinLock.UpdatePolicy(Policy);
  
  Policy := SpinLock.GetPolicy;
  WriteLn('   更新后 BackoffStrategy: ', Ord(Policy.BackoffStrategy));
  WriteLn('   更新后 MaxBackoffMs: ', Policy.MaxBackoffMs);
  
  WriteLn('');
  WriteLn('策略参数验证测试完成！');
end.
