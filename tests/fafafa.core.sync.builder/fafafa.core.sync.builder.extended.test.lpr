program fafafa.core.sync.builder.extended.test;

{**
 * TDD Tests for Extended Builders: TCondVarBuilder, TBarrierBuilder, TOnceBuilder
 *
 * Following TDD: Red -> Green -> Refactor
 * This test file should FAIL initially (Red phase)
 *}

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.sync.builder,
  fafafa.core.sync.condvar.base,
  fafafa.core.sync.barrier.base,
  fafafa.core.sync.once.base;

var
  TestCount: Integer = 0;
  PassCount: Integer = 0;
  FailCount: Integer = 0;

procedure Check(ACondition: Boolean; const ATestName: string);
begin
  Inc(TestCount);
  if ACondition then
  begin
    Inc(PassCount);
    WriteLn('[PASS] ', ATestName);
  end
  else
  begin
    Inc(FailCount);
    WriteLn('[FAIL] ', ATestName);
  end;
end;

// ========== TCondVarBuilder Tests ==========

procedure Test_CondVarBuilder_Build_ReturnsValidCondVar;
var
  CondVar: ICondVar;
begin
  // Arrange & Act
  CondVar := CondVarBuilder.Build;

  // Assert
  Check(CondVar <> nil, 'CondVarBuilder_Build_ReturnsValidCondVar');
end;

// ========== TBarrierBuilder Tests ==========

procedure Test_BarrierBuilder_WithParticipantCount_Build;
var
  Barrier: IBarrier;
begin
  // Arrange & Act
  Barrier := BarrierBuilder.WithParticipantCount(3).Build;

  // Assert
  Check(Barrier <> nil, 'BarrierBuilder_WithParticipantCount_Build (not nil)');
  Check(Barrier.GetParticipantCount = 3, 'BarrierBuilder_WithParticipantCount_Build (count = 3)');
end;

procedure Test_BarrierBuilder_DefaultCount_IsTwo;
var
  Barrier: IBarrier;
begin
  // Arrange & Act - Build without specifying count
  Barrier := BarrierBuilder.Build;

  // Assert - Default should be 2 (minimum sensible value)
  Check(Barrier <> nil, 'BarrierBuilder_DefaultCount_IsTwo (not nil)');
  Check(Barrier.GetParticipantCount = 2, 'BarrierBuilder_DefaultCount_IsTwo (count = 2)');
end;

procedure Test_BarrierBuilder_ChainedConfig;
var
  Barrier: IBarrier;
begin
  // Arrange & Act - Chain multiple calls
  Barrier := BarrierBuilder.WithParticipantCount(5).Build;

  // Assert
  Check(Barrier <> nil, 'BarrierBuilder_ChainedConfig (not nil)');
  Check(Barrier.GetParticipantCount = 5, 'BarrierBuilder_ChainedConfig (count = 5)');
end;

// ========== TOnceBuilder Tests ==========

procedure Test_OnceBuilder_Build_ReturnsValidOnce;
var
  Once: IOnce;
begin
  // Arrange & Act
  Once := OnceBuilder.Build;

  // Assert
  Check(Once <> nil, 'OnceBuilder_Build_ReturnsValidOnce');
  Check(Once.State = osNotStarted, 'OnceBuilder_Build_InitialState');
end;

procedure Test_OnceBuilder_WithCallback_Proc;
var
  Once: IOnce;
  Counter: Integer;

  procedure IncrementCounter;
  begin
    Inc(Counter);
  end;

begin
  // Arrange
  Counter := 0;

  // Act
  Once := OnceBuilder.WithCallback(@IncrementCounter).Build;
  Once.Execute;

  // Assert
  Check(Counter = 1, 'OnceBuilder_WithCallback_Proc (counter = 1)');
  Check(Once.Completed, 'OnceBuilder_WithCallback_Proc (completed)');
end;

procedure Test_OnceBuilder_WithCallback_ExecutedOnce;
var
  Once: IOnce;
  Counter: Integer;

  procedure IncrementCounter;
  begin
    Inc(Counter);
  end;

begin
  // Arrange
  Counter := 0;
  Once := OnceBuilder.WithCallback(@IncrementCounter).Build;

  // Act - Execute multiple times
  Once.Execute;
  Once.Execute;
  Once.Execute;

  // Assert - Should only increment once
  Check(Counter = 1, 'OnceBuilder_WithCallback_ExecutedOnce');
end;

// ========== Main ==========

begin
  WriteLn('=== TCondVarBuilder / TBarrierBuilder / TOnceBuilder Tests ===');
  WriteLn;

  // CondVar Builder tests
  Test_CondVarBuilder_Build_ReturnsValidCondVar;

  // Barrier Builder tests
  Test_BarrierBuilder_WithParticipantCount_Build;
  Test_BarrierBuilder_DefaultCount_IsTwo;
  Test_BarrierBuilder_ChainedConfig;

  // Once Builder tests
  Test_OnceBuilder_Build_ReturnsValidOnce;
  Test_OnceBuilder_WithCallback_Proc;
  Test_OnceBuilder_WithCallback_ExecutedOnce;

  WriteLn;
  WriteLn('=== Results ===');
  WriteLn('Total: ', TestCount, ' | Pass: ', PassCount, ' | Fail: ', FailCount);

  if FailCount > 0 then
    Halt(1);
end.
