program simple_stress_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.spin.base,
  fafafa.core.sync.spin;

type
  TSimpleTestThread = class(TThread)
  private
    FSpinLock: ISpinLock;
    FCounter: PInteger;
    FIterations: Integer;
  public
    constructor Create(ASpinLock: ISpinLock; ACounter: PInteger; AIterations: Integer);
    procedure Execute; override;
  end;

constructor TSimpleTestThread.Create(ASpinLock: ISpinLock; ACounter: PInteger; AIterations: Integer);
begin
  FSpinLock := ASpinLock;
  FCounter := ACounter;
  FIterations := AIterations;
  inherited Create(False);
end;

procedure TSimpleTestThread.Execute;
var
  i: Integer;
  localValue: Integer;
begin
  for i := 1 to FIterations do
  begin
    FSpinLock.Acquire;
    try
      localValue := FCounter^;
      Inc(localValue);
      FCounter^ := localValue;
    finally
      FSpinLock.Release;
    end;
  end;
end;

var
  Policy: TSpinLockPolicy;
  SpinLock: ISpinLock;
  Threads: array[1..4] of TSimpleTestThread;
  Counter: Integer;
  i: Integer;
  ExpectedValue: Integer;

begin
  WriteLn('Simple SpinLock Stress Test');
  WriteLn('===========================');
  
  // 创建不启用统计的自旋锁（排除统计干扰）
  Policy := DefaultSpinLockPolicy;
  Policy.EnableStats := False;
  
  SpinLock := MakeSpinLock(Policy);
  Counter := 0;
  
  WriteLn('Starting test with 4 threads, 1000 iterations each...');
  
  // 创建并启动线程
  for i := 1 to 4 do
  begin
    Threads[i] := TSimpleTestThread.Create(SpinLock, @Counter, 1000);
  end;
  
  // 等待所有线程完成
  for i := 1 to 4 do
  begin
    Threads[i].WaitFor;
    Threads[i].Free;
  end;
  
  // 检查结果
  ExpectedValue := 4 * 1000; // 4线程 * 1000次迭代
  
  WriteLn;
  WriteLn('Results:');
  WriteLn('--------');
  WriteLn('Expected Counter Value: ', ExpectedValue);
  WriteLn('Actual Counter Value: ', Counter);
  
  if Counter = ExpectedValue then
    WriteLn('✅ SIMPLE STRESS TEST PASSED')
  else
    WriteLn('❌ SIMPLE STRESS TEST FAILED');
end.
