{$mode objfpc}{$H+}
program benchmark_rwlock_fast;

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.rwlock,
  fafafa.core.sync.rwlock.base;

const
  ITERATIONS = 1000000;

procedure BenchmarkDefault;
var
  RWLock: IRWLock;
  i: Integer;
  StartTime, EndTime: QWord;
begin
  RWLock := MakeRWLock(DefaultRWLockOptions);

  // 测试读操作
  StartTime := GetTickCount64;
  for i := 1 to ITERATIONS do
  begin
    RWLock.AcquireRead;
    RWLock.ReleaseRead;
  end;
  EndTime := GetTickCount64;

  WriteLn('DefaultRWLock Read:');
  WriteLn(Format('  Time: %d ms', [EndTime - StartTime]));
  WriteLn(Format('  Ops/sec: %.0f', [ITERATIONS * 1000.0 / (EndTime - StartTime)]));
  WriteLn(Format('  ns/op: %.1f', [(EndTime - StartTime) * 1000000.0 / ITERATIONS]));
  WriteLn;
end;

procedure BenchmarkFast;
var
  RWLock: IRWLock;
  i: Integer;
  StartTime, EndTime: QWord;
begin
  RWLock := MakeRWLock(FastRWLockOptions);

  // 测试读操作
  StartTime := GetTickCount64;
  for i := 1 to ITERATIONS do
  begin
    RWLock.AcquireRead;
    RWLock.ReleaseRead;
  end;
  EndTime := GetTickCount64;

  WriteLn('FastRWLock Read:');
  WriteLn(Format('  Time: %d ms', [EndTime - StartTime]));
  WriteLn(Format('  Ops/sec: %.0f', [ITERATIONS * 1000.0 / (EndTime - StartTime)]));
  WriteLn(Format('  ns/op: %.1f', [(EndTime - StartTime) * 1000000.0 / ITERATIONS]));
  WriteLn;
end;

procedure BenchmarkWriteDefault;
var
  RWLock: IRWLock;
  i: Integer;
  StartTime, EndTime: QWord;
begin
  RWLock := MakeRWLock(DefaultRWLockOptions);

  // 测试写操作
  StartTime := GetTickCount64;
  for i := 1 to ITERATIONS do
  begin
    RWLock.AcquireWrite;
    RWLock.ReleaseWrite;
  end;
  EndTime := GetTickCount64;

  WriteLn('DefaultRWLock Write:');
  WriteLn(Format('  Time: %d ms', [EndTime - StartTime]));
  WriteLn(Format('  Ops/sec: %.0f', [ITERATIONS * 1000.0 / (EndTime - StartTime)]));
  WriteLn(Format('  ns/op: %.1f', [(EndTime - StartTime) * 1000000.0 / ITERATIONS]));
  WriteLn;
end;

procedure BenchmarkWriteFast;
var
  RWLock: IRWLock;
  i: Integer;
  StartTime, EndTime: QWord;
begin
  RWLock := MakeRWLock(FastRWLockOptions);

  // 测试写操作
  StartTime := GetTickCount64;
  for i := 1 to ITERATIONS do
  begin
    RWLock.AcquireWrite;
    RWLock.ReleaseWrite;
  end;
  EndTime := GetTickCount64;

  WriteLn('FastRWLock Write:');
  WriteLn(Format('  Time: %d ms', [EndTime - StartTime]));
  WriteLn(Format('  Ops/sec: %.0f', [ITERATIONS * 1000.0 / (EndTime - StartTime)]));
  WriteLn(Format('  ns/op: %.1f', [(EndTime - StartTime) * 1000000.0 / ITERATIONS]));
  WriteLn;
end;

begin
  WriteLn('=== RWLock Performance Comparison ===');
  WriteLn(Format('Iterations: %d', [ITERATIONS]));
  WriteLn;

  BenchmarkDefault;
  BenchmarkFast;
  BenchmarkWriteDefault;
  BenchmarkWriteFast;

  WriteLn('=== Summary ===');
  WriteLn('FastRWLockOptions: AllowReentrancy=False, EnablePoisoning=False, MaxReaders=MaxInt');
  WriteLn('Use FastRWLockOptions for simple scenarios where reentrancy is not needed.');
end.
