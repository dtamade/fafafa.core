program fafafa.core.sync.timeout.test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.base,
  fafafa.core.time.duration,
  fafafa.core.sync.waitgroup,
  fafafa.core.sync.latch,
  fafafa.core.sync.parker;

var
  TestsPassed: Integer = 0;
  TestsFailed: Integer = 0;

procedure Check(Condition: Boolean; const TestName: string);
begin
  if Condition then
  begin
    Inc(TestsPassed);
    WriteLn('[PASS] ', TestName);
  end
  else
  begin
    Inc(TestsFailed);
    WriteLn('[FAIL] ', TestName);
  end;
end;

// ==================== WaitGroup TDuration API Tests ====================

procedure Test_WaitGroup_WaitDuration_Zero_ReturnsImmediately;
var
  WG: IWaitGroup;
  R: TWaitResult;
begin
  WG := MakeWaitGroup;
  WG.Add(1);
  R := WG.WaitDuration(TDuration.Zero);
  Check(R = wrTimeout, 'WaitGroup.WaitDuration(Zero) returns wrTimeout');
  WG.Done;
end;

procedure Test_WaitGroup_WaitDuration_AlreadyDone_ReturnsSignaled;
var
  WG: IWaitGroup;
  R: TWaitResult;
begin
  WG := MakeWaitGroup;
  // Count is 0, should return immediately
  R := WG.WaitDuration(TDuration.FromMs(100));
  Check(R = wrSignaled, 'WaitGroup.WaitDuration(AlreadyDone) returns wrSignaled');
end;

procedure Test_WaitGroup_WaitDuration_Timeout_ReturnsTimeout;
var
  WG: IWaitGroup;
  R: TWaitResult;
begin
  WG := MakeWaitGroup;
  WG.Add(1);
  R := WG.WaitDuration(TDuration.FromMs(10));
  Check(R = wrTimeout, 'WaitGroup.WaitDuration(10ms) returns wrTimeout when not done');
  WG.Done;
end;

procedure Test_WaitGroup_WaitDuration_FromSec_Works;
var
  WG: IWaitGroup;
  R: TWaitResult;
begin
  WG := MakeWaitGroup;
  WG.Add(1);
  // Use 10ms = 0.01 sec
  R := WG.WaitDuration(TDuration.FromSecF(0.01));
  Check(R = wrTimeout, 'WaitGroup.WaitDuration(FromSecF) works');
  WG.Done;
end;

// ==================== Latch TDuration API Tests ====================

procedure Test_Latch_AwaitDuration_Zero_ReturnsImmediately;
var
  L: ILatch;
  R: TWaitResult;
begin
  L := MakeLatch(1);
  R := L.AwaitDuration(TDuration.Zero);
  Check(R = wrTimeout, 'Latch.AwaitDuration(Zero) returns wrTimeout');
  L.CountDown;
end;

procedure Test_Latch_AwaitDuration_AlreadyOpen_ReturnsSignaled;
var
  L: ILatch;
  R: TWaitResult;
begin
  L := MakeLatch(0);
  R := L.AwaitDuration(TDuration.FromMs(100));
  Check(R = wrSignaled, 'Latch.AwaitDuration(AlreadyOpen) returns wrSignaled');
end;

procedure Test_Latch_AwaitDuration_Timeout_ReturnsTimeout;
var
  L: ILatch;
  R: TWaitResult;
begin
  L := MakeLatch(1);
  R := L.AwaitDuration(TDuration.FromMs(10));
  Check(R = wrTimeout, 'Latch.AwaitDuration(10ms) returns wrTimeout when not open');
  L.CountDown;
end;

procedure Test_Latch_AwaitDuration_Microseconds_Works;
var
  L: ILatch;
  R: TWaitResult;
begin
  L := MakeLatch(1);
  // 10000 us = 10 ms
  R := L.AwaitDuration(TDuration.FromUs(10000));
  Check(R = wrTimeout, 'Latch.AwaitDuration(FromUs) works');
  L.CountDown;
end;

// ==================== Parker TDuration API Tests ====================

procedure Test_Parker_ParkDuration_Zero_ReturnsImmediately;
var
  P: IParker;
  R: TWaitResult;
begin
  P := MakeParker;
  R := P.ParkDuration(TDuration.Zero);
  Check(R = wrTimeout, 'Parker.ParkDuration(Zero) returns wrTimeout');
end;

procedure Test_Parker_ParkDuration_WithPermit_ReturnsSignaled;
var
  P: IParker;
  R: TWaitResult;
begin
  P := MakeParker;
  P.Unpark;  // Give permit
  R := P.ParkDuration(TDuration.FromMs(100));
  Check(R = wrSignaled, 'Parker.ParkDuration(WithPermit) returns wrSignaled');
end;

procedure Test_Parker_ParkDuration_Timeout_ReturnsTimeout;
var
  P: IParker;
  R: TWaitResult;
begin
  P := MakeParker;
  R := P.ParkDuration(TDuration.FromMs(10));
  Check(R = wrTimeout, 'Parker.ParkDuration(10ms) returns wrTimeout when no permit');
end;

procedure Test_Parker_ParkDuration_Nanoseconds_Works;
var
  P: IParker;
  R: TWaitResult;
begin
  P := MakeParker;
  // 10000000 ns = 10 ms
  R := P.ParkDuration(TDuration.FromNs(10000000));
  Check(R = wrTimeout, 'Parker.ParkDuration(FromNs) works');
end;

// ==================== Main ====================

begin
  WriteLn('=== Phase 2.1: Unified Timeout API Tests ===');
  WriteLn;
  
  WriteLn('--- WaitGroup TDuration API ---');
  Test_WaitGroup_WaitDuration_Zero_ReturnsImmediately;
  Test_WaitGroup_WaitDuration_AlreadyDone_ReturnsSignaled;
  Test_WaitGroup_WaitDuration_Timeout_ReturnsTimeout;
  Test_WaitGroup_WaitDuration_FromSec_Works;
  WriteLn;
  
  WriteLn('--- Latch TDuration API ---');
  Test_Latch_AwaitDuration_Zero_ReturnsImmediately;
  Test_Latch_AwaitDuration_AlreadyOpen_ReturnsSignaled;
  Test_Latch_AwaitDuration_Timeout_ReturnsTimeout;
  Test_Latch_AwaitDuration_Microseconds_Works;
  WriteLn;
  
  WriteLn('--- Parker TDuration API ---');
  Test_Parker_ParkDuration_Zero_ReturnsImmediately;
  Test_Parker_ParkDuration_WithPermit_ReturnsSignaled;
  Test_Parker_ParkDuration_Timeout_ReturnsTimeout;
  Test_Parker_ParkDuration_Nanoseconds_Works;
  WriteLn;
  
  WriteLn('===========================================');
  WriteLn('Total: ', TestsPassed + TestsFailed, ' | Passed: ', TestsPassed, ' | Failed: ', TestsFailed);
  
  if TestsFailed > 0 then
    Halt(1);
end.
