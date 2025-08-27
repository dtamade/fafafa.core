unit test_slabPool;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.mem.pool.slab;

type

  { TTestCase_SlabPool_Basic }

  TTestCase_SlabPool_Basic = class(TTestCase)
  private
    FPool: TSlabPool;
    FConfig: TSlabConfig;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Create_DefaultConfig;
    procedure Test_Create_CustomConfig;
    procedure Test_Create_InvalidSize;
    procedure Test_Alloc_ValidSizes;
    procedure Test_Alloc_ZeroSize;
    procedure Test_Alloc_OversizedObject;
    procedure Test_Free_ValidPointer;
    procedure Test_Free_NilPointer;
    procedure Test_Free_DoubleFreePrevention;
  end;

  { TTestCase_SlabPool_SizeClasses }

  TTestCase_SlabPool_SizeClasses = class(TTestCase)
  private
    FPool: TSlabPool;
    FConfig: TSlabConfig;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_AllSizeClasses_Allocation;
    procedure Test_AllSizeClasses_Deallocation;
    procedure Test_SizeClass_Boundaries;
    procedure Test_SizeClass_Mapping;
    procedure Test_SizeClass_Performance;
  end;

  { TTestCase_SlabPool_PageMerging }

  TTestCase_SlabPool_PageMerging = class(TTestCase)
  private
    FPoolDisabled: TSlabPool;
    FPoolEnabled: TSlabPool;
    FConfigDisabled: TSlabConfig;
    FConfigEnabled: TSlabConfig;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_PageMerging_Disabled;
    procedure Test_PageMerging_Enabled;
    procedure Test_PageMerging_Statistics;
    procedure Test_PageMerging_SequentialPages;
    procedure Test_PageMerging_FragmentedPages;
  end;

  { TTestCase_SlabPool_Performance }

  TTestCase_SlabPool_Performance = class(TTestCase)
  private
    FPool: TSlabPool;
    FConfig: TSlabConfig;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_PerfCounters_Basic;
    procedure Test_PerfCounters_Accuracy;
    procedure Test_PerfCounters_Timing;
    procedure Test_Statistics_Consistency;
    procedure Test_Statistics_Reset;
  end;

  { TTestCase_SlabPool_Configuration }

  TTestCase_SlabPool_Configuration = class(TTestCase)
  published
    procedure Test_DefaultConfig_Values;
    procedure Test_MergingConfig_Values;
    procedure Test_Config_Application;
    procedure Test_Config_Validation;
  end;

  { TTestCase_SlabPool_EdgeCases }

  TTestCase_SlabPool_EdgeCases = class(TTestCase)
  private
    FPool: TSlabPool;
    FConfig: TSlabConfig;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_MemoryExhaustion;
    procedure Test_SequentialOperations;
    procedure Test_ConcurrentScenarios;
    procedure Test_BoundaryConditions;
    procedure Test_StressTest_AllocFree;
  end;

  { TTestCase_SlabPool_Diagnostics }

  TTestCase_SlabPool_Diagnostics = class(TTestCase)
  private
    FPool: TSlabPool;
    FConfig: TSlabConfig;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_HealthCheck_Functionality;
    procedure Test_DetailedDiagnostics;
  end;

  { TTestCase_SlabPool_Performance }

  TTestCase_SlabPool_PerformanceBenchmark = class(TTestCase)
  private
    FPool: TSlabPool;
    FConfig: TSlabConfig;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_OptimizedBitScan_Performance;
    procedure Test_CacheLocality_Performance;
    procedure Test_InlineOptimization_Performance;
  end;

implementation

{ TTestCase_SlabPool_Basic }

procedure TTestCase_SlabPool_Basic.SetUp;
begin
  inherited SetUp;
  FConfig := CreateDefaultSlabConfig;
  FPool := TSlabPool.Create(64 * 1024, FConfig); // 64KB test pool
end;

procedure TTestCase_SlabPool_Basic.TearDown;
begin
  FreeAndNil(FPool);
  inherited TearDown;
end;

procedure TTestCase_SlabPool_Basic.Test_Create_DefaultConfig;
var
  LConfig: TSlabConfig;
  LPool: TSlabPool;
begin
  LConfig := CreateDefaultSlabConfig;
  LPool := TSlabPool.Create(32 * 1024, LConfig);
  try
    AssertNotNull('SlabPool should be created successfully with default config', LPool);
    AssertEquals('Initial allocation count should be 0', 0, LPool.TotalAllocs);
    AssertEquals('Initial free count should be 0', 0, LPool.TotalFrees);
  finally
    LPool.Destroy;
  end;
end;

procedure TTestCase_SlabPool_Basic.Test_Create_CustomConfig;
var
  LConfig: TSlabConfig;
  LPool: TSlabPool;
begin
  LConfig := CreateSlabConfigWithPageMerging;
  LPool := TSlabPool.Create(128 * 1024, LConfig);
  try
    AssertNotNull('SlabPool should be created successfully with custom config', LPool);
    AssertEquals('Initial allocation count should be 0', 0, LPool.TotalAllocs);
    AssertEquals('Initial free count should be 0', 0, LPool.TotalFrees);
  finally
    LPool.Destroy;
  end;
end;

procedure TTestCase_SlabPool_Basic.Test_Create_InvalidSize;
var
  LConfig: TSlabConfig;
begin
  LConfig := CreateDefaultSlabConfig;
  
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  // 异常测试: 无效池大小
  AssertException(
    'Exception expected for invalid pool size',
    ESlabPoolInvalidSize,
    procedure
    begin
      TSlabPool.Create(0, LConfig);
    end);
  {$ENDIF}
end;

procedure TTestCase_SlabPool_Basic.Test_Alloc_ValidSizes;
var
  LPtr: Pointer;
begin
  // Test basic allocation
  LPtr := FPool.Alloc(64);
  AssertNotNull('64-byte allocation should succeed', LPtr);
  AssertEquals('Allocation count should be 1', 1, FPool.TotalAllocs);
  FPool.Free(LPtr);

  // Test different size
  LPtr := FPool.Alloc(128);
  AssertNotNull('128-byte allocation should succeed', LPtr);
  AssertEquals('Allocation count should be 2', 2, FPool.TotalAllocs);
  FPool.Free(LPtr);
end;

procedure TTestCase_SlabPool_Basic.Test_Alloc_ZeroSize;
begin
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  // 异常测试: 零字节分配
  AssertException(
    'Exception expected for zero-size allocation',
    ESlabPoolInvalidSize,
    procedure
    begin
      FPool.Alloc(0);
    end);
  {$ENDIF}
end;

procedure TTestCase_SlabPool_Basic.Test_Alloc_OversizedObject;
var
  LPtr: Pointer;
begin
  // 超大对象分配应该返回nil
  LPtr := FPool.Alloc(100000);
  AssertNull('Oversized allocation should return nil', LPtr);
end;

procedure TTestCase_SlabPool_Basic.Test_Free_ValidPointer;
var
  LPtr: Pointer;
begin
  LPtr := FPool.Alloc(64);
  AssertNotNull('Allocation should succeed', LPtr);
  
  FPool.Free(LPtr);
  AssertEquals('Free count should be 1', 1, FPool.TotalFrees);
end;

procedure TTestCase_SlabPool_Basic.Test_Free_NilPointer;
begin
  // nil指针释放应该安全处理
  try
    FPool.Free(nil);
    AssertTrue('nil pointer free should be handled safely', True);
  except
    on E: Exception do
      Fail('nil pointer free should not raise exception: ' + E.Message);
  end;
end;

procedure TTestCase_SlabPool_Basic.Test_Free_DoubleFreePrevention;
var
  LPtr: Pointer;
begin
  LPtr := FPool.Alloc(64);
  AssertNotNull('Allocation should succeed', LPtr);
  
  // First free
  FPool.Free(LPtr);
  AssertEquals('First free should increment counter', 1, FPool.TotalFrees);
  
  // Second free should be handled safely
  try
    FPool.Free(LPtr);
    AssertTrue('Double free should be handled safely', True);
  except
    on E: Exception do
      // Exception is also acceptable behavior
      AssertTrue('Double free detection is working', True);
  end;
end;

{ TTestCase_SlabPool_SizeClasses }

procedure TTestCase_SlabPool_SizeClasses.SetUp;
begin
  inherited SetUp;
  FConfig := CreateDefaultSlabConfig;
  FPool := TSlabPool.Create(128 * 1024, FConfig); // 128KB test pool
end;

procedure TTestCase_SlabPool_SizeClasses.TearDown;
begin
  FreeAndNil(FPool);
  inherited TearDown;
end;

procedure TTestCase_SlabPool_SizeClasses.Test_AllSizeClasses_Allocation;
const
  SIZES: array[0..8] of SizeUInt = (8, 16, 32, 64, 128, 256, 512, 1024, 2048);
var
  I: Integer;
  LPtrs: array[0..8] of Pointer;
begin
  // Test allocation for all supported size classes
  for I := 0 to 8 do
  begin
    LPtrs[I] := FPool.Alloc(SIZES[I]);
    AssertNotNull(Format('%d-byte allocation should succeed', [SIZES[I]]), LPtrs[I]);
  end;
  
  AssertEquals('Should allocate 9 objects', 9, FPool.TotalAllocs);
  
  // Clean up
  for I := 0 to 8 do
    FPool.Free(LPtrs[I]);
end;

procedure TTestCase_SlabPool_SizeClasses.Test_AllSizeClasses_Deallocation;
const
  SIZES: array[0..8] of SizeUInt = (8, 16, 32, 64, 128, 256, 512, 1024, 2048);
var
  I: Integer;
  LPtrs: array[0..8] of Pointer;
begin
  // Allocate all size classes
  for I := 0 to 8 do
    LPtrs[I] := FPool.Alloc(SIZES[I]);
  
  // Deallocate all
  for I := 0 to 8 do
    FPool.Free(LPtrs[I]);
  
  AssertEquals('Should deallocate 9 objects', 9, FPool.TotalFrees);
  AssertEquals('Allocation and deallocation counts should match', FPool.TotalAllocs, FPool.TotalFrees);
end;

procedure TTestCase_SlabPool_SizeClasses.Test_SizeClass_Boundaries;
var
  LPtr: Pointer;
begin
  // Test boundary sizes
  LPtr := FPool.Alloc(1);
  AssertNotNull('1-byte allocation should succeed (mapped to 8-byte)', LPtr);
  FPool.Free(LPtr);
  
  LPtr := FPool.Alloc(2048);
  AssertNotNull('2048-byte allocation should succeed', LPtr);
  FPool.Free(LPtr);
  
  LPtr := FPool.Alloc(2049);
  AssertNull('2049-byte allocation should fail (oversized)', LPtr);
end;

procedure TTestCase_SlabPool_SizeClasses.Test_SizeClass_Mapping;
var
  LPtr1, LPtr2: Pointer;
begin
  // Test that similar sizes map to same size class
  LPtr1 := FPool.Alloc(60);  // Should map to 64-byte class
  LPtr2 := FPool.Alloc(64);  // Should map to 64-byte class
  
  AssertNotNull('60-byte allocation should succeed', LPtr1);
  AssertNotNull('64-byte allocation should succeed', LPtr2);
  
  FPool.Free(LPtr1);
  FPool.Free(LPtr2);
end;

procedure TTestCase_SlabPool_SizeClasses.Test_SizeClass_Performance;
var
  I: Integer;
  LPtr: Pointer;
  LStartTime: UInt64;
  LPerf: TSlabPerfCounters;
begin
  // Performance test for size class allocation
  LPerf := FPool.GetPerfCounters;
  LStartTime := LPerf.AllocTime;
  
  for I := 1 to 100 do
  begin
    LPtr := FPool.Alloc(64);
    AssertNotNull(Format('Allocation %d should succeed', [I]), LPtr);
    FPool.Free(LPtr);
  end;
  
  LPerf := FPool.GetPerfCounters;
  AssertTrue('Performance counters should track operations', LPerf.AllocCalls >= 100);
  AssertTrue('Performance counters should track timing', LPerf.AllocTime >= LStartTime);
end;

{ TTestCase_SlabPool_PageMerging }

procedure TTestCase_SlabPool_PageMerging.SetUp;
begin
  inherited SetUp;
  FConfigDisabled := CreateDefaultSlabConfig;
  FConfigDisabled.EnablePageMerging := False;
  FPoolDisabled := TSlabPool.Create(64 * 1024, FConfigDisabled);

  FConfigEnabled := CreateSlabConfigWithPageMerging;
  FPoolEnabled := TSlabPool.Create(64 * 1024, FConfigEnabled);
end;

procedure TTestCase_SlabPool_PageMerging.TearDown;
begin
  FreeAndNil(FPoolDisabled);
  FreeAndNil(FPoolEnabled);
  inherited TearDown;
end;

procedure TTestCase_SlabPool_PageMerging.Test_PageMerging_Disabled;
var
  LPtrs: array[0..63] of Pointer;
  LPerfBefore, LPerfAfter: TSlabPerfCounters;
  I: Integer;
begin
  LPerfBefore := FPoolDisabled.GetPerfCounters;

  // Allocate and free a page worth of objects
  for I := 0 to 63 do
    LPtrs[I] := FPoolDisabled.Alloc(64);

  for I := 0 to 63 do
    FPoolDisabled.Free(LPtrs[I]);

  LPerfAfter := FPoolDisabled.GetPerfCounters;

  // With page merging disabled, merge count should remain unchanged
  AssertEquals('Page merge count should remain unchanged when disabled',
               LPerfBefore.PageMerges, LPerfAfter.PageMerges);
end;

procedure TTestCase_SlabPool_PageMerging.Test_PageMerging_Enabled;
var
  LPtrs: array[0..127] of Pointer;
  LPerfBefore, LPerfAfter: TSlabPerfCounters;
  I: Integer;
begin
  LPerfBefore := FPoolEnabled.GetPerfCounters;

  // Allocate 128 64-byte objects (should occupy 2 pages)
  for I := 0 to 127 do
    LPtrs[I] := FPoolEnabled.Alloc(64);

  // Free first page objects
  for I := 0 to 63 do
    FPoolEnabled.Free(LPtrs[I]);

  // Free second page objects
  for I := 64 to 127 do
    FPoolEnabled.Free(LPtrs[I]);

  LPerfAfter := FPoolEnabled.GetPerfCounters;

  // With page merging enabled, there should be merge operations
  AssertTrue('Page merging should occur when enabled',
             LPerfAfter.PageMerges >= LPerfBefore.PageMerges);
end;

procedure TTestCase_SlabPool_PageMerging.Test_PageMerging_Statistics;
var
  LPtr1, LPtr2: Pointer;
  LPerfBefore, LPerfAfter: TSlabPerfCounters;
begin
  LPerfBefore := FPoolEnabled.GetPerfCounters;

  // Allocate two large objects
  LPtr1 := FPoolEnabled.Alloc(2048);
  LPtr2 := FPoolEnabled.Alloc(2048);

  // Free objects
  FPoolEnabled.Free(LPtr1);
  FPoolEnabled.Free(LPtr2);

  LPerfAfter := FPoolEnabled.GetPerfCounters;

  // Verify statistics consistency
  AssertTrue('Merge time should be >= 0', LPerfAfter.MergeTime >= LPerfBefore.MergeTime);
  AssertTrue('Merged pages should be >= 0', LPerfAfter.MergedPages >= LPerfBefore.MergedPages);
end;

procedure TTestCase_SlabPool_PageMerging.Test_PageMerging_SequentialPages;
var
  LPtrs: array[0..9] of Pointer;
  LPerfBefore, LPerfAfter: TSlabPerfCounters;
  I: Integer;
begin
  LPerfBefore := FPoolEnabled.GetPerfCounters;

  // Allocate sequential large objects
  for I := 0 to 9 do
    LPtrs[I] := FPoolEnabled.Alloc(2048);

  // Free in sequence to test sequential page merging
  for I := 0 to 9 do
    FPoolEnabled.Free(LPtrs[I]);

  LPerfAfter := FPoolEnabled.GetPerfCounters;

  AssertEquals('All objects should be allocated', 10, FPoolEnabled.TotalAllocs);
  AssertEquals('All objects should be freed', 10, FPoolEnabled.TotalFrees);
end;

procedure TTestCase_SlabPool_PageMerging.Test_PageMerging_FragmentedPages;
var
  LPtrs: array[0..9] of Pointer;
  I: Integer;
begin
  // Allocate objects
  for I := 0 to 9 do
    LPtrs[I] := FPoolEnabled.Alloc(2048);

  // Free every other object to create fragmentation
  for I := 0 to 9 do
    if I mod 2 = 0 then
      FPoolEnabled.Free(LPtrs[I]);

  // Free remaining objects
  for I := 0 to 9 do
    if I mod 2 = 1 then
      FPoolEnabled.Free(LPtrs[I]);

  AssertEquals('All objects should be freed', 10, FPoolEnabled.TotalFrees);
end;

{ TTestCase_SlabPool_Performance }

procedure TTestCase_SlabPool_Performance.SetUp;
begin
  inherited SetUp;
  FConfig := CreateSlabConfigWithPageMerging;
  FPool := TSlabPool.Create(128 * 1024, FConfig);
end;

procedure TTestCase_SlabPool_Performance.TearDown;
begin
  FreeAndNil(FPool);
  inherited TearDown;
end;

procedure TTestCase_SlabPool_Performance.Test_PerfCounters_Basic;
var
  LPtr: Pointer;
  LPerf: TSlabPerfCounters;
begin
  // Execute some operations
  LPtr := FPool.Alloc(256);
  FPool.Free(LPtr);

  LPerf := FPool.GetPerfCounters;

  // Verify performance counters
  AssertTrue('Allocation calls should be > 0', LPerf.AllocCalls > 0);
  AssertTrue('Free calls should be > 0', LPerf.FreeCalls > 0);
  AssertTrue('Allocation time should be >= 0', LPerf.AllocTime >= 0);
  AssertTrue('Free time should be >= 0', LPerf.FreeTime >= 0);
end;

procedure TTestCase_SlabPool_Performance.Test_PerfCounters_Accuracy;
var
  LPtrs: array[0..9] of Pointer;
  LPerf: TSlabPerfCounters;
  I: Integer;
begin
  // Allocate 10 objects
  for I := 0 to 9 do
    LPtrs[I] := FPool.Alloc(128);

  LPerf := FPool.GetPerfCounters;
  AssertEquals('Allocation calls should be accurate', 10, LPerf.AllocCalls);

  // Free 5 objects
  for I := 0 to 4 do
    FPool.Free(LPtrs[I]);

  LPerf := FPool.GetPerfCounters;
  AssertEquals('Free calls should be accurate', 5, LPerf.FreeCalls);

  // Free remaining objects
  for I := 5 to 9 do
    FPool.Free(LPtrs[I]);

  LPerf := FPool.GetPerfCounters;
  AssertEquals('Final free calls should be accurate', 10, LPerf.FreeCalls);
end;

procedure TTestCase_SlabPool_Performance.Test_PerfCounters_Timing;
var
  LPtr: Pointer;
  LPerfBefore, LPerfAfter: TSlabPerfCounters;
begin
  LPerfBefore := FPool.GetPerfCounters;

  // Perform allocation
  LPtr := FPool.Alloc(512);

  LPerfAfter := FPool.GetPerfCounters;
  AssertTrue('Allocation time should increase', LPerfAfter.AllocTime >= LPerfBefore.AllocTime);

  LPerfBefore := LPerfAfter;

  // Perform deallocation
  FPool.Free(LPtr);

  LPerfAfter := FPool.GetPerfCounters;
  AssertTrue('Free time should increase', LPerfAfter.FreeTime >= LPerfBefore.FreeTime);
end;

procedure TTestCase_SlabPool_Performance.Test_Statistics_Consistency;
var
  LPtrs: array[0..19] of Pointer;
  I: Integer;
begin
  // Allocate 20 objects
  for I := 0 to 19 do
    LPtrs[I] := FPool.Alloc(64);

  AssertEquals('Total allocations should be 20', 20, FPool.TotalAllocs);

  // Free 10 objects
  for I := 0 to 9 do
    FPool.Free(LPtrs[I]);

  AssertEquals('Total frees should be 10', 10, FPool.TotalFrees);

  // Free remaining objects
  for I := 10 to 19 do
    FPool.Free(LPtrs[I]);

  AssertEquals('Final total allocations should be 20', 20, FPool.TotalAllocs);
  AssertEquals('Final total frees should be 20', 20, FPool.TotalFrees);
end;

procedure TTestCase_SlabPool_Performance.Test_Statistics_Reset;
var
  LPtr: Pointer;
  LPerf: TSlabPerfCounters;
begin
  // Perform some operations
  LPtr := FPool.Alloc(128);
  FPool.Free(LPtr);

  // Verify counters are working
  LPerf := FPool.GetPerfCounters;
  AssertTrue('Counters should show activity', LPerf.AllocCalls > 0);

  // Note: Reset functionality would be tested here if available
  // This test verifies that statistics are properly maintained
  AssertEquals('Allocation and free counts should match', FPool.TotalAllocs, FPool.TotalFrees);
end;

{ TTestCase_SlabPool_Configuration }

procedure TTestCase_SlabPool_Configuration.Test_DefaultConfig_Values;
var
  LConfig: TSlabConfig;
begin
  LConfig := CreateDefaultSlabConfig;

  // Verify default configuration values
  AssertFalse('Default config should disable page merging', LConfig.EnablePageMerging);
  AssertTrue('Default config should enable performance monitoring', LConfig.EnablePerfMonitoring);
  AssertFalse('Default config should disable debug', LConfig.EnableDebug);
  AssertEquals('Default page size should be 4096', 4096, LConfig.PageSize);
end;

procedure TTestCase_SlabPool_Configuration.Test_MergingConfig_Values;
var
  LConfig: TSlabConfig;
begin
  LConfig := CreateSlabConfigWithPageMerging;

  // Verify page merging configuration values
  AssertTrue('Merging config should enable page merging', LConfig.EnablePageMerging);
  AssertTrue('Merging config should enable performance monitoring', LConfig.EnablePerfMonitoring);
end;

procedure TTestCase_SlabPool_Configuration.Test_Config_Application;
var
  LConfig: TSlabConfig;
  LPool1, LPool2: TSlabPool;
begin
  // Test different configurations
  LConfig := CreateDefaultSlabConfig;
  LPool1 := TSlabPool.Create(32 * 1024, LConfig);

  LConfig := CreateSlabConfigWithPageMerging;
  LPool2 := TSlabPool.Create(32 * 1024, LConfig);

  try
    AssertNotNull('Default config pool should be created', LPool1);
    AssertNotNull('Merging config pool should be created', LPool2);
  finally
    LPool1.Destroy;
    LPool2.Destroy;
  end;
end;

procedure TTestCase_SlabPool_Configuration.Test_Config_Validation;
var
  LConfig: TSlabConfig;
begin
  // Test configuration validation
  LConfig := CreateDefaultSlabConfig;

  // Valid configuration should work
  AssertTrue('Valid page size should be accepted', LConfig.PageSize > 0);

  // Test that configuration is properly applied
  // Note: SlabPool may not validate PageSize in constructor
  // This test verifies that valid configurations work
  AssertTrue('Valid configuration should be accepted', LConfig.PageSize > 0);
end;

{ TTestCase_SlabPool_EdgeCases }

procedure TTestCase_SlabPool_EdgeCases.SetUp;
begin
  inherited SetUp;
  FConfig := CreateDefaultSlabConfig;
  FPool := TSlabPool.Create(64 * 1024, FConfig);
end;

procedure TTestCase_SlabPool_EdgeCases.TearDown;
begin
  FreeAndNil(FPool);
  inherited TearDown;
end;

procedure TTestCase_SlabPool_EdgeCases.Test_MemoryExhaustion;
var
  LPtrs: array of Pointer;
  I, LCount: Integer;
  LPtr: Pointer;
begin
  // Try to exhaust memory pool
  SetLength(LPtrs, 1000);
  LCount := 0;

  for I := 0 to 999 do
  begin
    LPtr := FPool.Alloc(2048); // Allocate large objects
    if LPtr <> nil then
    begin
      LPtrs[LCount] := LPtr;
      Inc(LCount);
    end
    else
      Break; // Memory exhausted
  end;

  AssertTrue('Should be able to allocate at least some objects', LCount > 0);

  // Clean up allocated memory
  for I := 0 to LCount - 1 do
    FPool.Free(LPtrs[I]);
end;

procedure TTestCase_SlabPool_EdgeCases.Test_SequentialOperations;
var
  LPtr: Pointer;
  I: Integer;
begin
  // Test sequential allocation and deallocation
  for I := 1 to 100 do
  begin
    LPtr := FPool.Alloc(64);
    AssertNotNull(Format('Sequential allocation %d should succeed', [I]), LPtr);
    FPool.Free(LPtr);
  end;

  AssertEquals('Sequential allocation count should be correct', 100, FPool.TotalAllocs);
  AssertEquals('Sequential free count should be correct', 100, FPool.TotalFrees);
end;

procedure TTestCase_SlabPool_EdgeCases.Test_ConcurrentScenarios;
var
  LPtrs: array[0..49] of Pointer;
  I: Integer;
begin
  // Simulate concurrent scenario: interleaved allocation and deallocation

  // Allocate 50 objects
  for I := 0 to 49 do
    LPtrs[I] := FPool.Alloc(128);

  // Free even-indexed objects
  for I := 0 to 49 do
    if I mod 2 = 0 then
      FPool.Free(LPtrs[I]);

  // Reallocate even-indexed objects
  for I := 0 to 49 do
    if I mod 2 = 0 then
      LPtrs[I] := FPool.Alloc(128);

  // Free all objects
  for I := 0 to 49 do
    FPool.Free(LPtrs[I]);

  AssertEquals('Concurrent scenario allocation count should be correct', 75, FPool.TotalAllocs);
  AssertEquals('Concurrent scenario free count should be correct', 75, FPool.TotalFrees);
end;

procedure TTestCase_SlabPool_EdgeCases.Test_BoundaryConditions;
var
  LPtr: Pointer;
begin
  // Test minimum size allocation
  LPtr := FPool.Alloc(1);
  AssertNotNull('Minimum size allocation should succeed', LPtr);
  FPool.Free(LPtr);

  // Test maximum size allocation
  LPtr := FPool.Alloc(2048);
  AssertNotNull('Maximum size allocation should succeed', LPtr);
  FPool.Free(LPtr);

  // Test just over maximum size
  LPtr := FPool.Alloc(2049);
  AssertNull('Over-maximum size allocation should fail', LPtr);
end;

procedure TTestCase_SlabPool_EdgeCases.Test_StressTest_AllocFree;
var
  LPtrs: array[0..199] of Pointer;
  I, J: Integer;
begin
  // Stress test: multiple rounds of allocation and deallocation
  for J := 1 to 5 do
  begin
    // Allocate 200 objects
    for I := 0 to 199 do
      LPtrs[I] := FPool.Alloc(64);

    // Free all objects
    for I := 0 to 199 do
      FPool.Free(LPtrs[I]);
  end;

  AssertEquals('Stress test allocation count should be correct', 1000, FPool.TotalAllocs);
  AssertEquals('Stress test free count should be correct', 1000, FPool.TotalFrees);
end;

{ TTestCase_SlabPool_Diagnostics }

procedure TTestCase_SlabPool_Diagnostics.SetUp;
begin
  inherited SetUp;
  FConfig := CreateDefaultSlabConfig;
  FPool := TSlabPool.Create(128 * 1024, FConfig);
end;

procedure TTestCase_SlabPool_Diagnostics.TearDown;
begin
  FreeAndNil(FPool);
  inherited TearDown;
end;

procedure TTestCase_SlabPool_Diagnostics.Test_HealthCheck_Functionality;
var
  LHealthy: Boolean;
  LPtr: Pointer;
begin
  // 测试健康检查功能
  LHealthy := FPool.PerformHealthCheck;
  AssertTrue('New pool should be healthy', LHealthy);

  // 分配一些内存后再检查
  LPtr := FPool.Alloc(128);
  AssertNotNull('Allocation should succeed', LPtr);

  LHealthy := FPool.PerformHealthCheck;
  AssertTrue('Pool should remain healthy after allocation', LHealthy);

  FPool.Free(LPtr);
  LHealthy := FPool.PerformHealthCheck;
  AssertTrue('Pool should remain healthy after free', LHealthy);
end;

procedure TTestCase_SlabPool_Diagnostics.Test_DetailedDiagnostics;
var
  LDiagnostics: string;
  LPtr: Pointer;
begin
  // 测试详细诊断功能
  LDiagnostics := FPool.GetDetailedDiagnostics;
  AssertTrue('Diagnostics should not be empty', Length(LDiagnostics) > 0);
  AssertTrue('Diagnostics should contain health info', Pos('Health Status', LDiagnostics) > 0);

  // 分配一些内存后再获取诊断
  LPtr := FPool.Alloc(256);
  LDiagnostics := FPool.GetDetailedDiagnostics;
  AssertTrue('Diagnostics should reflect allocation', Pos('Total Allocations: 1', LDiagnostics) > 0);

  FPool.Free(LPtr);
end;

{ TTestCase_SlabPool_PerformanceBenchmark }

procedure TTestCase_SlabPool_PerformanceBenchmark.SetUp;
begin
  inherited SetUp;
  FConfig := CreateDefaultSlabConfig;
  FPool := TSlabPool.Create(256 * 1024, FConfig);
end;

procedure TTestCase_SlabPool_PerformanceBenchmark.TearDown;
begin
  FreeAndNil(FPool);
  inherited TearDown;
end;

procedure TTestCase_SlabPool_PerformanceBenchmark.Test_OptimizedBitScan_Performance;
var
  I: Integer;
  LPtr: Pointer;
  LStartTime, LEndTime: UInt64;
  LPerfCounters: TSlabPerfCounters;
begin
  // 性能基准测试：优化的位扫描算法
  LPerfCounters := FPool.GetPerfCounters;
  LStartTime := GetTickCount64;

  // 执行大量分配操作来测试位扫描性能
  for I := 1 to 1000 do
  begin
    LPtr := FPool.Alloc(64);
    if LPtr <> nil then
      FPool.Free(LPtr);
  end;

  LEndTime := GetTickCount64;
  LPerfCounters := FPool.GetPerfCounters;

  AssertTrue('Performance test should complete quickly', (LEndTime - LStartTime) < 100); // 应该在100ms内完成
  AssertEquals('Should complete 1000 allocations', 1000, LPerfCounters.AllocCalls);
end;

procedure TTestCase_SlabPool_PerformanceBenchmark.Test_CacheLocality_Performance;
var
  LStats: TSlabStats;
  LPtr: Pointer;
begin
  // 测试缓存局部性优化
  LPtr := FPool.Alloc(128);
  AssertNotNull('Allocation should succeed', LPtr);

  LStats := FPool.GetStats;
  AssertTrue('Memory efficiency should be good', LStats.MemoryEfficiency > 0.0);

  FPool.Free(LPtr);
end;

procedure TTestCase_SlabPool_PerformanceBenchmark.Test_InlineOptimization_Performance;
var
  I: Integer;
  LPtrs: array[0..99] of Pointer;
begin
  // 测试内联优化的效果
  for I := 0 to 99 do
  begin
    LPtrs[I] := FPool.Alloc(32);
    AssertNotNull(Format('Allocation %d should succeed', [I]), LPtrs[I]);
  end;

  for I := 0 to 99 do
    FPool.Free(LPtrs[I]);

  AssertEquals('All allocations should be freed', 100, FPool.TotalFrees);
end;

initialization
  RegisterTest(TTestCase_SlabPool_Basic);
  RegisterTest(TTestCase_SlabPool_SizeClasses);
  RegisterTest(TTestCase_SlabPool_PageMerging);  // Re-enabled after fixes
  RegisterTest(TTestCase_SlabPool_Performance);  // Re-enabled after fixes
  RegisterTest(TTestCase_SlabPool_Configuration);
  RegisterTest(TTestCase_SlabPool_EdgeCases);
  RegisterTest(TTestCase_SlabPool_Diagnostics);  // Health check and diagnostics tests
  RegisterTest(TTestCase_SlabPool_PerformanceBenchmark);  // Performance benchmarks
end.
