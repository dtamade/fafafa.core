{$CODEPAGE UTF8}
unit Test_enhanced_stack_pool;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry, fafafa.core.mem.enhancedStackPool;

type
  TTestCase_EnhancedStackPool = class(TTestCase)
  private
    function CreateTestPolicy: TStackPoolPolicy;
  published
    procedure Test_Basic_Operations;
    procedure Test_Scope_Management;
    procedure Test_Nested_Scopes;
    procedure Test_Auto_Scope;
    procedure Test_State_Stack;
    procedure Test_Specialized_Alloc;
    procedure Test_Statistics_Tracking;
    procedure Test_Auto_Growth;
    procedure Test_Policy_Configuration;
    procedure Test_RAII_Pattern;
  end;

implementation

function TTestCase_EnhancedStackPool.CreateTestPolicy: TStackPoolPolicy;
begin
  Result := CreateDefaultStackPolicy;
  Result.EnableStatistics := True;
  Result.EnableScopeTracking := True;
  Result.EnableAutoGrow := True;
  Result.MaxSize := 1024 * 1024; // 1MB
end;

procedure TTestCase_EnhancedStackPool.Test_Basic_Operations;
var
  pool: TEnhancedStackPool;
  policy: TStackPoolPolicy;
  ptr1, ptr2: Pointer;
const
  POOL_SIZE = 4096;
begin
  policy := CreateTestPolicy;
  pool := TEnhancedStackPool.Create(POOL_SIZE, policy);
  try
    AssertEquals('Initial used size should be 0', 0, pool.UsedSize);
    AssertEquals('Total size should match', POOL_SIZE, pool.TotalSize);
    AssertTrue('Should be empty initially', pool.IsEmpty);
    AssertFalse('Should not be full initially', pool.IsFull);
    
    // 基本分配
    ptr1 := pool.Alloc(64);
    AssertTrue('First allocation should succeed', ptr1 <> nil);
    AssertTrue('Used size should increase', pool.UsedSize > 0);
    AssertFalse('Should not be empty after allocation', pool.IsEmpty);
    
    ptr2 := pool.Alloc(128);
    AssertTrue('Second allocation should succeed', ptr2 <> nil);
    AssertTrue('Pointers should be different', ptr1 <> ptr2);
    
    // 重置池
    pool.Reset;
    AssertEquals('Used size should be 0 after reset', 0, pool.UsedSize);
    AssertTrue('Should be empty after reset', pool.IsEmpty);
    
  finally
    pool.Free;
  end;
end;

procedure TTestCase_EnhancedStackPool.Test_Scope_Management;
var
  pool: TEnhancedStackPool;
  policy: TStackPoolPolicy;
  scope1, scope2: TStackScope;
  ptr1, ptr2: Pointer;
  initialUsed, afterScope1, afterScope2: SizeUInt;
const
  POOL_SIZE = 4096;
begin
  policy := CreateTestPolicy;
  pool := TEnhancedStackPool.Create(POOL_SIZE, policy);
  try
    initialUsed := pool.UsedSize;
    
    // 创建第一个作用域
    scope1 := pool.CreateScope;
    try
      ptr1 := scope1.Alloc(64);
      AssertTrue('Scope allocation should succeed', ptr1 <> nil);
      afterScope1 := pool.UsedSize;
      AssertTrue('Used size should increase', afterScope1 > initialUsed);
      
      // 创建第二个作用域
      scope2 := pool.CreateScope;
      try
        ptr2 := scope2.Alloc(128);
        AssertTrue('Second scope allocation should succeed', ptr2 <> nil);
        afterScope2 := pool.UsedSize;
        AssertTrue('Used size should increase more', afterScope2 > afterScope1);
      finally
        scope2.Free; // 自动恢复到 scope1 状态
      end;
      
      // 验证第二个作用域被正确释放
      AssertEquals('Should restore to scope1 state', afterScope1, pool.UsedSize);
      
    finally
      scope1.Free; // 自动恢复到初始状态
    end;
    
    // 验证第一个作用域被正确释放
    AssertEquals('Should restore to initial state', initialUsed, pool.UsedSize);
    
  finally
    pool.Free;
  end;
end;

procedure TTestCase_EnhancedStackPool.Test_Nested_Scopes;
var
  pool: TEnhancedStackPool;
  policy: TStackPoolPolicy;
  manager: TStackScopeManager;
  ptr: Pointer;
  i: Integer;
const
  POOL_SIZE = 4096;
  SCOPE_COUNT = 5;
begin
  policy := CreateTestPolicy;
  pool := TEnhancedStackPool.Create(POOL_SIZE, policy);
  try
    manager := pool.ScopeManager;
    AssertTrue('Should have scope manager', manager <> nil);
    
    // 创建嵌套作用域
    for i := 1 to SCOPE_COUNT do
    begin
      manager.PushScope;
      AssertEquals('Scope depth should match', i, manager.GetScopeDepth);
      
      ptr := manager.GetCurrentScope.Alloc(64);
      AssertTrue(Format('Allocation in scope %d should succeed', [i]), ptr <> nil);
    end;
    
    // 验证最大深度
    var stats := pool.GetStatistics;
    AssertEquals('Max scope depth should match', SCOPE_COUNT, stats.MaxScopeDepth);
    
    // 逐层弹出作用域
    for i := SCOPE_COUNT downto 1 do
    begin
      manager.PopScope;
      AssertEquals('Scope depth should decrease', i - 1, manager.GetScopeDepth);
    end;
    
    AssertEquals('Should have no scopes', 0, manager.GetScopeDepth);
    
  finally
    pool.Free;
  end;
end;

procedure TTestCase_EnhancedStackPool.Test_Auto_Scope;
var
  pool: TEnhancedStackPool;
  policy: TStackPoolPolicy;
  autoScope: TAutoStackScope;
  ptr: Pointer;
  initialUsed, afterAlloc: SizeUInt;
const
  POOL_SIZE = 4096;
begin
  policy := CreateTestPolicy;
  pool := TEnhancedStackPool.Create(POOL_SIZE, policy);
  try
    initialUsed := pool.UsedSize;
    
    // 使用自动作用域
    autoScope := TAutoStackScope.Initialize(pool);
    try
      AssertTrue('Auto scope should be active', autoScope.Active);
      
      ptr := autoScope.Alloc(256);
      AssertTrue('Auto scope allocation should succeed', ptr <> nil);
      afterAlloc := pool.UsedSize;
      AssertTrue('Used size should increase', afterAlloc > initialUsed);
      
    finally
      autoScope.Finalize; // 自动释放
    end;
    
    // 验证自动释放
    AssertEquals('Should restore to initial state', initialUsed, pool.UsedSize);
    AssertFalse('Auto scope should be inactive', autoScope.Active);
    
  finally
    pool.Free;
  end;
end;

procedure TTestCase_EnhancedStackPool.Test_State_Stack;
var
  pool: TEnhancedStackPool;
  policy: TStackPoolPolicy;
  ptr: Pointer;
  i: Integer;
const
  POOL_SIZE = 4096;
  PUSH_COUNT = 3;
begin
  policy := CreateTestPolicy;
  pool := TEnhancedStackPool.Create(POOL_SIZE, policy);
  try
    AssertEquals('Initial state stack depth should be 0', 0, pool.GetStateStackDepth);
    
    // 推入多个状态
    for i := 1 to PUSH_COUNT do
    begin
      AssertTrue(Format('PushState %d should succeed', [i]), pool.PushState);
      AssertEquals('State stack depth should increase', i, pool.GetStateStackDepth);
      
      ptr := pool.Alloc(64);
      AssertTrue(Format('Allocation after push %d should succeed', [i]), ptr <> nil);
    end;
    
    // 弹出状态
    for i := PUSH_COUNT downto 1 do
    begin
      AssertTrue(Format('PopState %d should succeed', [i]), pool.PopState);
      AssertEquals('State stack depth should decrease', i - 1, pool.GetStateStackDepth);
    end;
    
    AssertEquals('Final state stack depth should be 0', 0, pool.GetStateStackDepth);
    
  finally
    pool.Free;
  end;
end;

procedure TTestCase_EnhancedStackPool.Test_Specialized_Alloc;
var
  pool: TEnhancedStackPool;
  policy: TStackPoolPolicy;
  ptr: Pointer;
  str: PChar;
  arr: Pointer;
const
  POOL_SIZE = 4096;
begin
  policy := CreateTestPolicy;
  pool := TEnhancedStackPool.Create(POOL_SIZE, policy);
  try
    // 测试对齐分配
    ptr := pool.AllocAligned(100, 16);
    AssertTrue('Aligned allocation should succeed', ptr <> nil);
    AssertEquals('Should be 16-byte aligned', 0, PtrUInt(ptr) mod 16);
    
    // 测试清零分配
    ptr := pool.AllocZeroed(64);
    AssertTrue('Zeroed allocation should succeed', ptr <> nil);
    AssertEquals('First byte should be zero', 0, PByte(ptr)^);
    
    // 测试字符串分配
    str := pool.AllocString(10);
    AssertTrue('String allocation should succeed', str <> nil);
    AssertEquals('String should be null-terminated', 0, Ord(str[10]));
    
    // 测试数组分配
    arr := pool.AllocArray(SizeOf(Integer), 5);
    AssertTrue('Array allocation should succeed', arr <> nil);
    
  finally
    pool.Free;
  end;
end;

procedure TTestCase_EnhancedStackPool.Test_Statistics_Tracking;
var
  pool: TEnhancedStackPool;
  policy: TStackPoolPolicy;
  stats: TStackPoolStatistics;
  scope: TStackScope;
  ptr: Pointer;
const
  POOL_SIZE = 4096;
begin
  policy := CreateTestPolicy;
  policy.EnableStatistics := True;
  
  pool := TEnhancedStackPool.Create(POOL_SIZE, policy);
  try
    // 重置统计信息
    pool.ResetStatistics;
    stats := pool.GetStatistics;
    AssertEquals('Initial allocations should be 0', 0, stats.TotalAllocations);
    
    // 执行一些操作
    ptr := pool.Alloc(64);
    ptr := pool.Alloc(128);
    
    scope := pool.CreateScope;
    try
      ptr := scope.Alloc(256);
    finally
      scope.Free;
    end;
    
    // 检查统计信息
    stats := pool.GetStatistics;
    AssertTrue('Should have allocations', stats.TotalAllocations > 0);
    AssertTrue('Should have total bytes', stats.TotalBytes > 0);
    AssertTrue('Should have scope creations', stats.ScopeCreations > 0);
    AssertTrue('Should have scope destructions', stats.ScopeDestructions > 0);
    AssertTrue('Peak usage should be > 0', stats.PeakUsage > 0);
    
    // 测试碎片化
    var fragmentation := pool.GetFragmentation;
    AssertTrue('Fragmentation should be valid', (fragmentation >= 0.0) and (fragmentation <= 1.0));
    
  finally
    pool.Free;
  end;
end;

procedure TTestCase_EnhancedStackPool.Test_Auto_Growth;
var
  pool: TEnhancedStackPool;
  policy: TStackPoolPolicy;
  ptr: Pointer;
  initialSize: SizeUInt;
const
  SMALL_POOL_SIZE = 256;
  LARGE_ALLOC_SIZE = 512; // 大于初始池大小
begin
  policy := CreateTestPolicy;
  policy.EnableAutoGrow := True;
  policy.GrowthFactor := 2.0;
  
  pool := TEnhancedStackPool.Create(SMALL_POOL_SIZE, policy);
  try
    initialSize := pool.TotalSize;
    AssertEquals('Initial size should match', SMALL_POOL_SIZE, initialSize);
    
    // 分配超过初始大小的内存，应该触发自动增长
    ptr := pool.Alloc(LARGE_ALLOC_SIZE);
    AssertTrue('Large allocation should succeed with auto-growth', ptr <> nil);
    AssertTrue('Pool should have grown', pool.TotalSize > initialSize);
    
  finally
    pool.Free;
  end;
end;

procedure TTestCase_EnhancedStackPool.Test_Policy_Configuration;
var
  pool: TEnhancedStackPool;
  policy: TStackPoolPolicy;
const
  POOL_SIZE = 4096;
begin
  // 测试不同的策略
  policy := CreateHighPerformanceStackPolicy;
  pool := TEnhancedStackPool.Create(POOL_SIZE, policy);
  try
    AssertFalse('High performance policy should disable statistics', policy.EnableStatistics);
    AssertFalse('High performance policy should disable scope tracking', policy.EnableScopeTracking);
  finally
    pool.Free;
  end;
  
  policy := CreateDebugStackPolicy;
  pool := TEnhancedStackPool.Create(POOL_SIZE, policy);
  try
    AssertTrue('Debug policy should enable debug mode', policy.EnableDebugMode);
    AssertTrue('Debug policy should enable statistics', policy.EnableStatistics);
  finally
    pool.Free;
  end;
end;

procedure TTestCase_EnhancedStackPool.Test_RAII_Pattern;
var
  pool: TEnhancedStackPool;
  policy: TStackPoolPolicy;
  initialUsed: SizeUInt;
  
  procedure TestNestedFunction;
  var
    scope: TStackScope;
    ptr: Pointer;
  begin
    scope := pool.CreateScope;
    try
      ptr := scope.Alloc(128);
      AssertTrue('Nested allocation should succeed', ptr <> nil);
    finally
      scope.Free; // RAII 自动清理
    end;
  end;
  
const
  POOL_SIZE = 4096;
begin
  policy := CreateTestPolicy;
  pool := TEnhancedStackPool.Create(POOL_SIZE, policy);
  try
    initialUsed := pool.UsedSize;
    
    // 调用嵌套函数，测试 RAII 模式
    TestNestedFunction;
    
    // 验证内存被正确释放
    AssertEquals('Memory should be released after RAII', initialUsed, pool.UsedSize);
    
  finally
    pool.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_EnhancedStackPool);

end.
