{$CODEPAGE UTF8}
unit Test_mapped_slab_pool;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry, fafafa.core.mem.mappedSlabPool;

type
  TTestCase_MappedSlabPool = class(TTestCase)
  private
    function MakeTempFile(const prefix, suffix: string): string;
    function MakeSharedName(const prefix: string): string;
  published
    procedure Test_CreateFile_Basic;
    procedure Test_CreateShared_Basic;
    procedure Test_CreateAnonymous_Basic;
    procedure Test_Alloc_Free_Basic;
    procedure Test_Large_Allocations;
    procedure Test_Stats_Tracking;
    procedure Test_Flush_Operations;
    procedure Test_Reset_Functionality;
    procedure Test_Manager_Basic;
  end;

implementation

function TTestCase_MappedSlabPool.MakeTempFile(const prefix, suffix: string): string;
begin
  Result := GetTempDir + prefix + IntToHex(Random(MaxInt), 8) + suffix;
end;

function TTestCase_MappedSlabPool.MakeSharedName(const prefix: string): string;
begin
  Result := prefix + IntToHex(Random(MaxInt), 8);
end;

procedure TTestCase_MappedSlabPool.Test_CreateFile_Basic;
var
  filePath: string;
  pool: TMappedSlabPool;
const
  POOL_SIZE = 1024 * 1024; // 1MB
  PAGE_SIZE = 4096;
  MAX_SIZE_CLASS = 2048;
begin
  filePath := MakeTempFile('msp_file_', '.dat');
  try
    pool := TMappedSlabPool.Create;
    try
      AssertTrue('CreateFile should succeed', 
        pool.CreateFile(filePath, POOL_SIZE, PAGE_SIZE, MAX_SIZE_CLASS));
      
      AssertTrue('Should be creator', pool.IsCreator);
      AssertTrue('Should be valid', pool.IsValid);
      AssertEquals('Mode should be file', Ord(mspFile), Ord(pool.Mode));
      AssertEquals('PoolSize should match', UInt64(POOL_SIZE), pool.PoolSize);
      AssertEquals('PageSize should match', UInt32(PAGE_SIZE), pool.PageSize);
      AssertEquals('MaxSizeClass should match', UInt32(MAX_SIZE_CLASS), pool.MaxSizeClass);
      AssertTrue('BaseAddress should not be nil', pool.BaseAddress <> nil);
    finally
      TObject(pool).Free;
    end;
  finally
    if FileExists(filePath) then DeleteFile(filePath);
  end;
end;

procedure TTestCase_MappedSlabPool.Test_CreateShared_Basic;
var
  name: string;
  pool: TMappedSlabPool;
const
  POOL_SIZE = 512 * 1024; // 512KB
begin
  name := MakeSharedName('MSP_Shared_');
  
  pool := TMappedSlabPool.Create;
  try
    AssertTrue('CreateShared should succeed', 
      pool.CreateShared(name, POOL_SIZE));
    
    AssertTrue('Should be valid', pool.IsValid);
    AssertEquals('Mode should be shared', Ord(mspShared), Ord(pool.Mode));
    AssertEquals('PoolSize should match', UInt64(POOL_SIZE), pool.PoolSize);
    AssertTrue('BaseAddress should not be nil', pool.BaseAddress <> nil);
  finally
    TObject(pool).Free;
  end;
end;

procedure TTestCase_MappedSlabPool.Test_CreateAnonymous_Basic;
var
  pool: TMappedSlabPool;
const
  POOL_SIZE = 256 * 1024; // 256KB
begin
  pool := TMappedSlabPool.Create;
  try
    AssertTrue('CreateAnonymous should succeed', 
      pool.CreateAnonymous(POOL_SIZE));
    
    AssertTrue('Should be creator', pool.IsCreator);
    AssertTrue('Should be valid', pool.IsValid);
    AssertEquals('Mode should be anonymous', Ord(mspAnonymous), Ord(pool.Mode));
    AssertEquals('PoolSize should match', UInt64(POOL_SIZE), pool.PoolSize);
    AssertTrue('BaseAddress should not be nil', pool.BaseAddress <> nil);
  finally
    TObject(pool).Free;
  end;
end;

procedure TTestCase_MappedSlabPool.Test_Alloc_Free_Basic;
var
  pool: TMappedSlabPool;
  ptr1, ptr2, ptr3: Pointer;
const
  POOL_SIZE = 1024 * 1024; // 1MB
begin
  pool := TMappedSlabPool.Create;
  try
    AssertTrue('CreateAnonymous should succeed', 
      pool.CreateAnonymous(POOL_SIZE));
    
    // 测试基本分配
    ptr1 := pool.Alloc(64);
    AssertTrue('First allocation should succeed', ptr1 <> nil);
    
    ptr2 := pool.Alloc(128);
    AssertTrue('Second allocation should succeed', ptr2 <> nil);
    AssertTrue('Pointers should be different', ptr1 <> ptr2);
    
    ptr3 := pool.Alloc(256);
    AssertTrue('Third allocation should succeed', ptr3 <> nil);
    AssertTrue('Third pointer should be different', (ptr3 <> ptr1) and (ptr3 <> ptr2));
    
    // 测试释放
    pool.FreeBlock(ptr1);
    pool.FreeBlock(ptr2);
    pool.FreeBlock(ptr3);
    
    // 测试零大小分配
    ptr1 := pool.Alloc(0);
    AssertTrue('Zero size allocation should fail', ptr1 = nil);
    
    // 测试超大分配
    ptr1 := pool.Alloc(pool.MaxSizeClass + 1);
    AssertTrue('Oversized allocation should fail', ptr1 = nil);
    
  finally
    TObject(pool).Free;
  end;
end;

procedure TTestCase_MappedSlabPool.Test_Large_Allocations;
var
  pool: TMappedSlabPool;
  ptrs: array[0..99] of Pointer;
  i: Integer;
const
  POOL_SIZE = 4 * 1024 * 1024; // 4MB
  ALLOC_SIZE = 1024; // 1KB each
begin
  pool := TMappedSlabPool.Create;
  try
    AssertTrue('CreateAnonymous should succeed', 
      pool.CreateAnonymous(POOL_SIZE));
    
    // 分配多个块
    for i := 0 to High(ptrs) do
    begin
      ptrs[i] := pool.Alloc(ALLOC_SIZE);
      AssertTrue(Format('Allocation %d should succeed', [i]), ptrs[i] <> nil);
    end;
    
    // 验证指针都不相同
    for i := 0 to High(ptrs) - 1 do
    begin
      AssertTrue(Format('Pointer %d should be unique', [i]), 
        ptrs[i] <> ptrs[i + 1]);
    end;
    
    // 释放所有块
    for i := 0 to High(ptrs) do
    begin
      pool.FreeBlock(ptrs[i]);
    end;
    
  finally
    TObject(pool).Free;
  end;
end;

procedure TTestCase_MappedSlabPool.Test_Stats_Tracking;
var
  pool: TMappedSlabPool;
  ptr1, ptr2: Pointer;
  totalAllocs, totalFrees, failedAllocs: UInt64;
  usedPages, totalPages: UInt32;
const
  POOL_SIZE = 1024 * 1024; // 1MB
begin
  pool := TMappedSlabPool.Create;
  try
    AssertTrue('CreateAnonymous should succeed', 
      pool.CreateAnonymous(POOL_SIZE));
    
    // 初始统计
    pool.GetStats(totalAllocs, totalFrees, failedAllocs, usedPages, totalPages);
    AssertEquals('Initial allocs should be 0', 0, totalAllocs);
    AssertEquals('Initial frees should be 0', 0, totalFrees);
    AssertEquals('Initial failed allocs should be 0', 0, failedAllocs);
    AssertTrue('Total pages should be > 0', totalPages > 0);
    
    // 分配一些内存
    ptr1 := pool.Alloc(64);
    ptr2 := pool.Alloc(128);
    
    pool.GetStats(totalAllocs, totalFrees, failedAllocs, usedPages, totalPages);
    AssertEquals('Should have 2 allocs', 2, totalAllocs);
    AssertEquals('Should have 0 frees', 0, totalFrees);
    
    // 释放内存
    pool.FreeBlock(ptr1);
    pool.FreeBlock(ptr2);
    
    pool.GetStats(totalAllocs, totalFrees, failedAllocs, usedPages, totalPages);
    AssertEquals('Should have 2 allocs', 2, totalAllocs);
    AssertEquals('Should have 2 frees', 2, totalFrees);
    
    // 测试失败分配
    ptr1 := pool.Alloc(0);
    pool.GetStats(totalAllocs, totalFrees, failedAllocs, usedPages, totalPages);
    AssertTrue('Should have failed allocs', failedAllocs > 0);
    
  finally
    TObject(pool).Free;
  end;
end;

procedure TTestCase_MappedSlabPool.Test_Flush_Operations;
var
  filePath: string;
  pool: TMappedSlabPool;
  ptr: Pointer;
const
  POOL_SIZE = 1024 * 1024; // 1MB
begin
  filePath := MakeTempFile('msp_flush_', '.dat');
  try
    pool := TMappedSlabPool.Create;
    try
      AssertTrue('CreateFile should succeed', 
        pool.CreateFile(filePath, POOL_SIZE));
      
      // 分配一些内存
      ptr := pool.Alloc(256);
      AssertTrue('Allocation should succeed', ptr <> nil);
      
      // 写入一些数据
      FillChar(ptr^, 256, $42);
      
      // 测试刷新
      AssertTrue('Flush should succeed', pool.Flush);
      AssertTrue('FlushRange should succeed', pool.FlushRange(0, 4096));
      
      pool.FreeBlock(ptr);
      
    finally
      TObject(pool).Free;
    end;
  finally
    if FileExists(filePath) then DeleteFile(filePath);
  end;
end;

procedure TTestCase_MappedSlabPool.Test_Reset_Functionality;
var
  pool: TMappedSlabPool;
  ptr1, ptr2: Pointer;
  totalAllocs, totalFrees, failedAllocs: UInt64;
  usedPages, totalPages: UInt32;
const
  POOL_SIZE = 1024 * 1024; // 1MB
begin
  pool := TMappedSlabPool.Create;
  try
    AssertTrue('CreateAnonymous should succeed', 
      pool.CreateAnonymous(POOL_SIZE));
    
    // 分配一些内存
    ptr1 := pool.Alloc(64);
    ptr2 := pool.Alloc(128);
    pool.FreeBlock(ptr1);
    
    // 检查统计
    pool.GetStats(totalAllocs, totalFrees, failedAllocs, usedPages, totalPages);
    AssertTrue('Should have allocs before reset', totalAllocs > 0);
    
    // 重置池
    pool.Reset;
    
    // 检查重置后的统计
    pool.GetStats(totalAllocs, totalFrees, failedAllocs, usedPages, totalPages);
    AssertEquals('Allocs should be 0 after reset', 0, totalAllocs);
    AssertEquals('Frees should be 0 after reset', 0, totalFrees);
    AssertEquals('Failed allocs should be 0 after reset', 0, failedAllocs);
    AssertEquals('Used pages should be 0 after reset', 0, usedPages);
    
    // 重置后应该能正常分配
    ptr1 := pool.Alloc(256);
    AssertTrue('Allocation after reset should succeed', ptr1 <> nil);
    
  finally
    TObject(pool).Free;
  end;
end;

procedure TTestCase_MappedSlabPool.Test_Manager_Basic;
var
  manager: TMappedSlabPoolManager;
  ptr1, ptr2, ptr3: Pointer;
  totalAllocs, totalFrees, failedAllocs: UInt64;
  usedMemory, totalMemory: UInt64;
begin
  manager := TMappedSlabPoolManager.Create(mspAnonymous);
  try
    // 测试不同大小的分配
    ptr1 := manager.AllocAny(64);
    AssertTrue('Small allocation should succeed', ptr1 <> nil);
    
    ptr2 := manager.AllocAny(1024);
    AssertTrue('Medium allocation should succeed', ptr2 <> nil);
    
    ptr3 := manager.AllocAny(4096);
    AssertTrue('Large allocation should succeed', ptr3 <> nil);
    
    // 测试统计
    manager.GetTotalStats(totalAllocs, totalFrees, failedAllocs, usedMemory, totalMemory);
    AssertTrue('Should have allocs', totalAllocs > 0);
    AssertTrue('Should have used memory', usedMemory > 0);
    AssertTrue('Should have total memory', totalMemory > 0);
    
    // 释放内存
    manager.FreeAny(ptr1);
    manager.FreeAny(ptr2);
    manager.FreeAny(ptr3);
    
    // 测试刷新
    AssertTrue('FlushAll should succeed', manager.FlushAll);
    
  finally
    manager.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_MappedSlabPool);

end.
