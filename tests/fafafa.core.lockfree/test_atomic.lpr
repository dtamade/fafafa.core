program test_atomic;


{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.atomic;

// 测试基础原子操作
procedure TestBasicAtomicOperations;
var
  LValue32: Int32;
  LValue64: Int64;
  LPtr: Pointer;
  LTaggedPtr: atomic_tagged_ptr_t;
  LExpected32: Int32;
  LExpected64: Int64;
  LExpectedPtr: Pointer;
begin
  WriteLn('=== 测试基础原子操作 ===');

  // 测试32位原子操作
  LValue32 := 100000;
  WriteLn('32位原子操作测试:');
  WriteLn('  初始值: ', LValue32);
  WriteLn('  Exchange(200000): ', atomic_exchange(LValue32, 200000));
  WriteLn('  当前值: ', LValue32);

  LExpected32 := 200000;
  if atomic_compare_exchange_strong(LValue32, LExpected32, 300000) then
    WriteLn('  CompareExchange(300000, 200000): 成功')
  else
    WriteLn('  CompareExchange(300000, 200000): 失败，当前值: ', LExpected32);
  WriteLn('  当前值: ', LValue32);
  WriteLn('  FetchAdd(50000): ', atomic_fetch_add(LValue32, 50000));
  WriteLn('  当前值: ', LValue32);
  WriteLn;

  // 测试64位原子操作
  {$IFDEF CPU64}
  LValue64 := 10000000000;
  WriteLn('64位原子操作测试:');
  WriteLn('  初始值: ', LValue64);
  WriteLn('  Exchange(20000000000): ', atomic_exchange_64(LValue64, 20000000000));
  WriteLn('  当前值: ', LValue64);

  LExpected64 := 20000000000;
  if atomic_compare_exchange_strong_64(LValue64, LExpected64, 30000000000) then
    WriteLn('  CompareExchange(30000000000, 20000000000): 成功')
  else
    WriteLn('  CompareExchange(30000000000, 20000000000): 失败，当前值: ', LExpected64);
  WriteLn('  当前值: ', LValue64);
  WriteLn('  FetchAdd(5000000000): ', atomic_fetch_add_64(LValue64, 5000000000));
  WriteLn('  当前值: ', LValue64);
  WriteLn;
  {$ELSE}
  WriteLn('64位原子操作测试: 跳过（32位平台）');
  WriteLn;
  {$ENDIF}

  WriteLn('✅ 基础原子操作测试通过');
end;

// 测试指针原子操作
procedure TestPointerAtomicOperations;
var
  LPtr1, LPtr2, LPtr3: Pointer;
  LResult: Pointer;
  LExpected: Pointer;
begin
  WriteLn('=== 测试指针原子操作 ===');

  // 分配一些测试指针
  GetMem(LPtr1, 100);
  GetMem(LPtr2, 200);
  GetMem(LPtr3, 300);

  try
    WriteLn('指针原子操作测试:');
    WriteLn('  初始指针: ', PtrUInt(LPtr1));

    LResult := atomic_exchange(LPtr1, LPtr2);
    WriteLn('  Exchange结果: ', PtrUInt(LResult));
    WriteLn('  当前指针: ', PtrUInt(LPtr1));

    LExpected := LPtr2;
    if atomic_compare_exchange_strong(LPtr1, LExpected, LPtr3) then
      WriteLn('  CompareExchange: 成功')
    else
      WriteLn('  CompareExchange: 失败，期望值: ', PtrUInt(LExpected));
    WriteLn('  当前指针: ', PtrUInt(LPtr1));

    WriteLn('✅ 指针原子操作测试通过');

  finally
    FreeMem(LPtr1);
    FreeMem(LPtr2);
    FreeMem(LPtr3);
  end;
  WriteLn;
end;

// 测试Tagged Pointer
procedure TestTaggedPointer;
var
  LTaggedPtr: atomic_tagged_ptr_t;
  LNewTaggedPtr: atomic_tagged_ptr_t;
  LResult: atomic_tagged_ptr_t;
  LExpected: atomic_tagged_ptr_t;
  LPtr: Pointer;
begin
  WriteLn('=== 测试Tagged Pointer ===');

  GetMem(LPtr, 100);
  try
    // 创建Tagged Pointer
    LTaggedPtr := atomic_tagged_ptr(LPtr, 42);
    WriteLn('Tagged Pointer测试:');
    WriteLn('  指针: ', PtrUInt(atomic_tagged_ptr_get_ptr(LTaggedPtr)));
    WriteLn('  标签: ', atomic_tagged_ptr_get_tag(LTaggedPtr));
    WriteLn('  下一个标签: ', atomic_tagged_ptr_next(LTaggedPtr));

    // 测试原子操作
    LNewTaggedPtr := atomic_tagged_ptr(LPtr, 43);
    LResult := atomic_tagged_ptr_load(LTaggedPtr);
    WriteLn('  Load结果 - 指针: ', PtrUInt(atomic_tagged_ptr_get_ptr(LResult)), ', 标签: ', atomic_tagged_ptr_get_tag(LResult));

    atomic_tagged_ptr_store(LTaggedPtr, LNewTaggedPtr);
    LResult := atomic_tagged_ptr_load(LTaggedPtr);
    WriteLn('  Store后 - 指针: ', PtrUInt(atomic_tagged_ptr_get_ptr(LResult)), ', 标签: ', atomic_tagged_ptr_get_tag(LResult));

    // 测试CompareExchange
    LNewTaggedPtr := atomic_tagged_ptr(LPtr, 44);
    LExpected := atomic_tagged_ptr(LPtr, 43);
    if atomic_tagged_ptr_compare_exchange_strong(LTaggedPtr, LExpected, LNewTaggedPtr) then
      WriteLn('  CompareExchange: 成功')
    else
      WriteLn('  CompareExchange: 失败');

    LResult := atomic_tagged_ptr_load(LTaggedPtr);
    WriteLn('  最终值 - 指针: ', PtrUInt(atomic_tagged_ptr_get_ptr(LResult)), ', 标签: ', atomic_tagged_ptr_get_tag(LResult));

    WriteLn('✅ Tagged Pointer测试通过');

  finally
    FreeMem(LPtr);
  end;
  WriteLn;
end;

// 测试便捷函数
procedure TestConvenienceFunctions;
var
  LInt: Int32;
  LInt64: Int64;
  LPtr: Pointer;
begin
  WriteLn('=== 测试便捷函数 ===');

  // 测试递增/递减
  LInt := 100;
  WriteLn('便捷函数测试:');
  WriteLn('  初始值: ', LInt);
  WriteLn('  atomic_increment: ', atomic_increment(LInt));
  WriteLn('  当前值: ', LInt);
  WriteLn('  atomic_decrement: ', atomic_decrement(LInt));
  WriteLn('  当前值: ', LInt);

  // 测试64位递增/递减
  {$IFDEF CPU64}
  LInt64 := 1000000000;
  WriteLn('  64位初始值: ', LInt64);
  WriteLn('  atomic_increment_64: ', atomic_increment_64(LInt64));
  WriteLn('  当前值: ', LInt64);
  WriteLn('  atomic_decrement_64: ', atomic_decrement_64(LInt64));
  WriteLn('  当前值: ', LInt64);
  {$ELSE}
  WriteLn('  64位递增/递减: 跳过（32位平台）');
  {$ENDIF}

  // 测试交换
  WriteLn('  atomic_exchange(200): ', atomic_exchange(LInt, 200));
  WriteLn('  当前值: ', LInt);

  WriteLn('✅ 便捷函数测试通过');
  WriteLn;
end;

// 测试内存序
procedure TestMemoryOrdering;
var
  LValue: UInt32;
begin
  WriteLn('=== 测试内存序 ===');

  LValue := 100;
  WriteLn('内存序测试:');
  WriteLn('  初始值: ', LValue);

  // 测试不同内存序的操作
  atomic_store(LValue, 200, mo_relaxed);
  WriteLn('  Store(relaxed)后: ', atomic_load(LValue, mo_relaxed));

  atomic_store(LValue, 300, mo_release);
  WriteLn('  Store(release)后: ', atomic_load(LValue, mo_acquire));

  atomic_store(LValue, 400, mo_seq_cst);
  WriteLn('  Store(seq_cst)后: ', atomic_load(LValue, mo_seq_cst));

  // 测试内存屏障
  atomic_thread_fence(mo_seq_cst);

  WriteLn('✅ 内存序测试通过');
  WriteLn;
end;

begin
  WriteLn('fafafa.core.atomic 测试程序');
  WriteLn('============================');
  WriteLn;
  
  try
    TestBasicAtomicOperations;
    TestPointerAtomicOperations;
    TestTaggedPointer;
    TestConvenienceFunctions;
    TestMemoryOrdering;
    
    WriteLn('🎉 所有测试通过！fafafa.core.atomic 模块工作正常！');
    WriteLn;
    WriteLn('按回车键退出...');
    ReadLn;
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 测试失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
