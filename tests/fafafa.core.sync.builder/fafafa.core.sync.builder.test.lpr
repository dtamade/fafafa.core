program fafafa_core_sync_builder_test;

{**
 * Builder 模式测试
 *
 * 测试同步原语的 Builder 模式 API：
 *   - MutexBuilder
 *   - SemBuilder
 *   - RWLockBuilder
 *
 * 遵循 TDD 规范：红 → 绿 → 重构
 *}

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex,
  fafafa.core.sync.sem,
  fafafa.core.sync.rwlock,
  fafafa.core.sync.event,
  fafafa.core.sync.waitgroup,
  fafafa.core.sync.latch,
  fafafa.core.sync.builder;

var
  TestsPassed: Integer = 0;
  TestsFailed: Integer = 0;

procedure AssertTrue(const Cond: Boolean; const Msg: string);
begin
  if not Cond then
  begin
    WriteLn('FAIL: ', Msg);
    Inc(TestsFailed);
  end
  else
  begin
    WriteLn('OK:   ', Msg);
    Inc(TestsPassed);
  end;
end;

// ===== Tests for MutexBuilder =====

procedure Test_MutexBuilder_Default_CreatesMutex;
var
  Mutex: IMutex;
begin
  // Act: 使用默认配置创建 Mutex
  Mutex := MutexBuilder.Build;
  
  // Assert
  AssertTrue(Assigned(Mutex), 'MutexBuilder.Build 应该返回有效的 IMutex');
  
  // 验证基本功能
  Mutex.Acquire;
  Mutex.Release;
end;

procedure Test_MutexBuilder_Fluent_CreatesMutex;
var
  Mutex: IMutex;
begin
  // Act: 使用流式 API（即使目前没有配置选项，也验证链式调用）
  Mutex := MutexBuilder
    .Build;
  
  // Assert
  AssertTrue(Assigned(Mutex), 'MutexBuilder 流式 API 应该返回有效的 IMutex');
end;

// ===== Tests for SemBuilder =====

procedure Test_SemBuilder_Default_CreatesSemaphore;
var
  Sem: ISem;
begin
  // Act: 使用默认配置创建 Semaphore
  Sem := SemBuilder.Build;
  
  // Assert
  AssertTrue(Assigned(Sem), 'SemBuilder.Build 应该返回有效的 ISem');
  AssertTrue(Sem.GetMaxCount = 1, 'SemBuilder 默认 MaxCount 应该为 1');
end;

procedure Test_SemBuilder_WithMaxCount_CreatesSemaphore;
var
  Sem: ISem;
begin
  // Act: 配置最大计数
  Sem := SemBuilder
    .WithMaxCount(5)
    .Build;
  
  // Assert
  AssertTrue(Assigned(Sem), 'SemBuilder.WithMaxCount.Build 应该返回有效的 ISem');
  AssertTrue(Sem.GetMaxCount = 5, 'SemBuilder MaxCount 应该为 5');
end;

procedure Test_SemBuilder_WithInitialCount_CreatesSemaphore;
var
  Sem: ISem;
begin
  // Act: 配置初始计数
  Sem := SemBuilder
    .WithMaxCount(10)
    .WithInitialCount(3)
    .Build;
  
  // Assert
  AssertTrue(Assigned(Sem), 'SemBuilder.WithInitialCount.Build 应该返回有效的 ISem');
  AssertTrue(Sem.GetAvailableCount = 3, 'SemBuilder InitialCount 应该为 3');
  AssertTrue(Sem.GetMaxCount = 10, 'SemBuilder MaxCount 应该为 10');
end;

procedure Test_SemBuilder_Fluent_ChainedConfig;
var
  Sem: ISem;
begin
  // Act: 完整的流式配置
  Sem := SemBuilder
    .WithMaxCount(100)
    .WithInitialCount(50)
    .Build;
  
  // Assert
  AssertTrue(Sem.GetAvailableCount = 50, 'SemBuilder 流式配置 InitialCount');
  AssertTrue(Sem.GetMaxCount = 100, 'SemBuilder 流式配置 MaxCount');
end;

// ===== Tests for RWLockBuilder =====

procedure Test_RWLockBuilder_Default_CreatesRWLock;
var
  RWLock: IRWLock;
begin
  // Act: 使用默认配置创建 RWLock
  RWLock := RWLockBuilder.Build;
  
  // Assert
  AssertTrue(Assigned(RWLock), 'RWLockBuilder.Build 应该返回有效的 IRWLock');
  
  // 验证基本功能
  RWLock.AcquireRead;
  RWLock.ReleaseRead;
end;

procedure Test_RWLockBuilder_Fluent_CreatesRWLock;
var
  RWLock: IRWLock;
begin
  // Act: 使用流式 API
  RWLock := RWLockBuilder
    .Build;
  
  // Assert
  AssertTrue(Assigned(RWLock), 'RWLockBuilder 流式 API 应该返回有效的 IRWLock');
end;

// ===== Tests for enhanced RWLockBuilder =====

procedure Test_RWLockBuilder_WithWriterPriority;
var
  RWLock: IRWLock;
begin
  // Act
  RWLock := RWLockBuilder
    .WithWriterPriority
    .Build;
  
  // Assert
  AssertTrue(Assigned(RWLock), 'RWLockBuilder.WithWriterPriority.Build 应该返回有效的 IRWLock');
end;

procedure Test_RWLockBuilder_WithFairMode;
var
  RWLock: IRWLock;
begin
  // Act
  RWLock := RWLockBuilder
    .WithFairMode
    .Build;
  
  // Assert
  AssertTrue(Assigned(RWLock), 'RWLockBuilder.WithFairMode.Build 应该返回有效的 IRWLock');
end;

procedure Test_RWLockBuilder_WithMaxReaders;
var
  RWLock: IRWLock;
begin
  // Act
  RWLock := RWLockBuilder
    .WithMaxReaders(100)
    .Build;
  
  // Assert
  AssertTrue(Assigned(RWLock), 'RWLockBuilder.WithMaxReaders.Build 应该返回有效的 IRWLock');
  AssertTrue(RWLock.GetMaxReaders = 100, 'RWLockBuilder MaxReaders 应该为 100');
end;

procedure Test_RWLockBuilder_ChainedConfig;
var
  RWLock: IRWLock;
begin
  // Act: 链式配置
  RWLock := RWLockBuilder
    .WithWriterPriority
    .WithMaxReaders(50)
    .Build;
  
  // Assert
  AssertTrue(Assigned(RWLock), 'RWLockBuilder 链式配置应该返回有效的 IRWLock');
  AssertTrue(RWLock.GetMaxReaders = 50, 'RWLockBuilder MaxReaders 应该为 50');
end;

// ===== Tests for EventBuilder =====

procedure Test_EventBuilder_Default_CreatesEvent;
var
  Event: IEvent;
begin
  // Act: 使用默认配置创建 Event
  Event := EventBuilder.Build;
  
  // Assert
  AssertTrue(Assigned(Event), 'EventBuilder.Build 应该返回有效的 IEvent');
end;

procedure Test_EventBuilder_WithManualReset;
var
  Event: IEvent;
begin
  // Act
  Event := EventBuilder
    .WithManualReset
    .Build;
  
  // Assert
  AssertTrue(Assigned(Event), 'EventBuilder.WithManualReset.Build 应该返回有效的 IEvent');
end;

procedure Test_EventBuilder_WithInitialState;
var
  Event: IEvent;
begin
  // Act
  Event := EventBuilder
    .WithInitialState(True)
    .Build;
  
  // Assert
  AssertTrue(Assigned(Event), 'EventBuilder.WithInitialState.Build 应该返回有效的 IEvent');
end;

procedure Test_EventBuilder_ChainedConfig;
var
  Event: IEvent;
begin
  // Act: 链式配置
  Event := EventBuilder
    .WithManualReset
    .WithInitialState(True)
    .Build;
  
  // Assert
  AssertTrue(Assigned(Event), 'EventBuilder 链式配置应该返回有效的 IEvent');
end;

// ===== Tests for WaitGroupBuilder =====

procedure Test_WaitGroupBuilder_Default_CreatesWaitGroup;
var
  WG: IWaitGroup;
begin
  // Act: 使用默认配置创建 WaitGroup
  WG := WaitGroupBuilder.Build;
  
  // Assert
  AssertTrue(Assigned(WG), 'WaitGroupBuilder.Build 应该返回有效的 IWaitGroup');
  AssertTrue(WG.GetCount = 0, 'WaitGroupBuilder 默认计数应该为 0');
end;

procedure Test_WaitGroupBuilder_WithInitialCount;
var
  WG: IWaitGroup;
begin
  // Act
  WG := WaitGroupBuilder
    .WithInitialCount(5)
    .Build;
  
  // Assert
  AssertTrue(Assigned(WG), 'WaitGroupBuilder.WithInitialCount.Build 应该返回有效的 IWaitGroup');
  AssertTrue(WG.GetCount = 5, 'WaitGroupBuilder 初始计数应该为 5');
end;

// ===== Tests for LatchBuilder =====

procedure Test_LatchBuilder_Default_CreatesLatch;
var
  Latch: ILatch;
begin
  // Act: 使用默认配置创建 Latch
  Latch := LatchBuilder.Build;
  
  // Assert
  AssertTrue(Assigned(Latch), 'LatchBuilder.Build 应该返回有效的 ILatch');
  AssertTrue(Latch.GetCount = 1, 'LatchBuilder 默认计数应该为 1');
end;

procedure Test_LatchBuilder_WithCount;
var
  Latch: ILatch;
begin
  // Act
  Latch := LatchBuilder
    .WithCount(10)
    .Build;
  
  // Assert
  AssertTrue(Assigned(Latch), 'LatchBuilder.WithCount.Build 应该返回有效的 ILatch');
  AssertTrue(Latch.GetCount = 10, 'LatchBuilder 计数应该为 10');
end;

// ===== Main =====

begin
  WriteLn('=== fafafa.core.sync.builder 测试 ===');
  WriteLn;
  
  WriteLn('--- MutexBuilder 测试 ---');
  Test_MutexBuilder_Default_CreatesMutex;
  Test_MutexBuilder_Fluent_CreatesMutex;
  
  WriteLn;
  WriteLn('--- SemBuilder 测试 ---');
  Test_SemBuilder_Default_CreatesSemaphore;
  Test_SemBuilder_WithMaxCount_CreatesSemaphore;
  Test_SemBuilder_WithInitialCount_CreatesSemaphore;
  Test_SemBuilder_Fluent_ChainedConfig;
  
  WriteLn;
  WriteLn('--- RWLockBuilder 测试 ---');
  Test_RWLockBuilder_Default_CreatesRWLock;
  Test_RWLockBuilder_Fluent_CreatesRWLock;
  
  WriteLn;
  WriteLn('--- RWLockBuilder 增强测试 ---');
  Test_RWLockBuilder_WithWriterPriority;
  Test_RWLockBuilder_WithFairMode;
  Test_RWLockBuilder_WithMaxReaders;
  Test_RWLockBuilder_ChainedConfig;
  
  WriteLn;
  WriteLn('--- EventBuilder 测试 ---');
  Test_EventBuilder_Default_CreatesEvent;
  Test_EventBuilder_WithManualReset;
  Test_EventBuilder_WithInitialState;
  Test_EventBuilder_ChainedConfig;
  
  WriteLn;
  WriteLn('--- WaitGroupBuilder 测试 ---');
  Test_WaitGroupBuilder_Default_CreatesWaitGroup;
  Test_WaitGroupBuilder_WithInitialCount;
  
  WriteLn;
  WriteLn('--- LatchBuilder 测试 ---');
  Test_LatchBuilder_Default_CreatesLatch;
  Test_LatchBuilder_WithCount;
  
  WriteLn;
  WriteLn('========================================');
  WriteLn('测试结果: ', TestsPassed, ' 通过, ', TestsFailed, ' 失败');
  WriteLn('========================================');
  
  if TestsFailed > 0 then
    Halt(1)
  else
    Halt(0);
end.
