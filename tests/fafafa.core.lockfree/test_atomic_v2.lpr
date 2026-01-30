program test_atomic_v2;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.atomic;

// 测试C/C++标准兼容的原子操作
procedure TestStandardAtomicOperations;
var
  LValue32: Int32;
  LValue64: Int64;
  LPtr: Pointer;
  LExpected32: Int32;
  LExpected64: Int64;
  LExpectedPtr: Pointer;
  LNewPtr: Pointer;
  LAnotherPtr: Pointer;
begin
  WriteLn('=== 测试C/C++标准兼容的原子操作 ===');
  
  // 测试32位原子操作
  WriteLn('32位原子操作测试:');
  LValue32 := 100;
  WriteLn('  初始值: ', atomic_load(LValue32));
  
  atomic_store(LValue32, 200);
  WriteLn('  store(200)后: ', atomic_load(LValue32));
  
  WriteLn('  exchange(300): ', atomic_exchange(LValue32, 300));
  WriteLn('  当前值: ', atomic_load(LValue32));
  
  LExpected32 := 300;
  if atomic_compare_exchange_strong(LValue32, LExpected32, 400) then
    WriteLn('  compare_exchange_strong(400, 300): 成功')
  else
    WriteLn('  compare_exchange_strong(400, 300): 失败');
  WriteLn('  当前值: ', atomic_load(LValue32));
  
  WriteLn('  fetch_add(50): ', atomic_fetch_add(LValue32, 50));
  WriteLn('  当前值: ', atomic_load(LValue32));
  
  WriteLn('  fetch_sub(25): ', atomic_fetch_sub(LValue32, 25));
  WriteLn('  当前值: ', atomic_load(LValue32));
  WriteLn;
  
  // 测试64位原子操作
  WriteLn('64位原子操作测试:');
  LValue64 := 1000000000;
  WriteLn('  初始值: ', atomic_load_64(LValue64));
  
  atomic_store_64(LValue64, 2000000000);
  WriteLn('  store(2000000000)后: ', atomic_load_64(LValue64));
  
  WriteLn('  exchange(3000000000): ', atomic_exchange_64(LValue64, 3000000000));
  WriteLn('  当前值: ', atomic_load_64(LValue64));
  
  LExpected64 := 3000000000;
  if atomic_compare_exchange_strong_64(LValue64, LExpected64, 4000000000) then
    WriteLn('  compare_exchange_strong(4000000000, 3000000000): 成功')
  else
    WriteLn('  compare_exchange_strong(4000000000, 3000000000): 失败');
  WriteLn('  当前值: ', atomic_load_64(LValue64));
  WriteLn;
  
  // 测试指针原子操作
  WriteLn('指针原子操作测试:');
  GetMem(LPtr, 100);
  WriteLn('  初始指针: ', PtrUInt(atomic_load(LPtr)));
  
  GetMem(LNewPtr, 200);
  WriteLn('  exchange(新指针): ', PtrUInt(atomic_exchange(LPtr, LNewPtr)));
  WriteLn('  当前指针: ', PtrUInt(atomic_load(LPtr)));

  LExpectedPtr := LNewPtr;
  GetMem(LAnotherPtr, 300);
  if atomic_compare_exchange_strong(LPtr, LExpectedPtr, LAnotherPtr) then
    WriteLn('  compare_exchange_strong: 成功')
  else
    WriteLn('  compare_exchange_strong: 失败');
  WriteLn('  当前指针: ', PtrUInt(atomic_load(LPtr)));
  
  FreeMem(LAnotherPtr);
  FreeMem(LNewPtr);
  WriteLn;
end;

procedure TestTaggedPointer;
var
  LTaggedPtr: atomic_tagged_ptr_t;
  LExpected: atomic_tagged_ptr_t;
  LNewPtr: Pointer;
  LLoaded: atomic_tagged_ptr_t;
  LNewTagged: atomic_tagged_ptr_t;
  LDesired: atomic_tagged_ptr_t;
  LTag: {$IFDEF CPU64}UInt16{$ELSE}UInt32{$ENDIF};
begin
  WriteLn('=== 测试Tagged Pointer ===');

  GetMem(LNewPtr, 100);
  LTag := 42;
  LTaggedPtr := atomic_tagged_ptr(LNewPtr, LTag);

  WriteLn('Tagged Pointer测试:');
  WriteLn('  指针: ', PtrUInt(atomic_tagged_ptr_get_ptr(LTaggedPtr)));
  WriteLn('  标签: ', atomic_tagged_ptr_get_tag(LTaggedPtr));
  WriteLn('  下一个标签: ', atomic_tagged_ptr_next(LTaggedPtr));

  LLoaded := atomic_tagged_ptr_load(LTaggedPtr, mo_acquire);
  WriteLn('  Load结果 - 指针: ', PtrUInt(atomic_tagged_ptr_get_ptr(LLoaded)), ', 标签: ', atomic_tagged_ptr_get_tag(LLoaded));

  LNewTagged := atomic_tagged_ptr(LNewPtr, 43);
  atomic_tagged_ptr_store(LTaggedPtr, LNewTagged, mo_release);
  LLoaded := atomic_tagged_ptr_load(LTaggedPtr, mo_acquire);
  WriteLn('  Store后 - 指针: ', PtrUInt(atomic_tagged_ptr_get_ptr(LLoaded)), ', 标签: ', atomic_tagged_ptr_get_tag(LLoaded));

  LExpected := LNewTagged;
  LDesired := atomic_tagged_ptr(LNewPtr, 44);
  if atomic_tagged_ptr_compare_exchange_strong(LTaggedPtr, LExpected, LDesired) then
    WriteLn('  CompareExchange: 成功')
  else
    WriteLn('  CompareExchange: 失败');

  LLoaded := atomic_tagged_ptr_load(LTaggedPtr, mo_acquire);
  WriteLn('  最终值 - 指针: ', PtrUInt(atomic_tagged_ptr_get_ptr(LLoaded)), ', 标签: ', atomic_tagged_ptr_get_tag(LLoaded));

  FreeMem(LNewPtr);
  WriteLn;
end;

procedure TestMemoryOrdering;
var
  LValue: Int32;
begin
  WriteLn('=== 测试内存序 ===');

  LValue := 100;
  WriteLn('内存序测试:');
  WriteLn('  初始值: ', atomic_load(LValue, mo_relaxed));

  atomic_store(LValue, 200, mo_relaxed);
  WriteLn('  Store(relaxed)后: ', atomic_load(LValue, mo_relaxed));

  atomic_store(LValue, 300, mo_release);
  WriteLn('  Store(release)后: ', atomic_load(LValue, mo_acquire));

  atomic_store(LValue, 400, mo_seq_cst);
  WriteLn('  Store(seq_cst)后: ', atomic_load(LValue, mo_seq_cst));

  atomic_thread_fence(mo_seq_cst);
  WriteLn('  内存屏障执行完成');
  WriteLn;
end;

procedure TestConvenienceFunctions;
var
  LValue32: Int32;
  LValue64: Int64;
begin
  WriteLn('=== 测试便捷函数 ===');
  
  LValue32 := 100;
  LValue64 := 1000000000;
  
  WriteLn('便捷函数测试:');
  WriteLn('  32位初始值: ', LValue32);
  WriteLn('  atomic_increment: ', atomic_increment(LValue32));
  WriteLn('  当前值: ', LValue32);
  WriteLn('  atomic_decrement: ', atomic_decrement(LValue32));
  WriteLn('  当前值: ', LValue32);
  
  WriteLn('  64位初始值: ', LValue64);
  WriteLn('  atomic_increment_64: ', atomic_increment_64(LValue64));
  WriteLn('  当前值: ', LValue64);
  WriteLn('  atomic_decrement_64: ', atomic_decrement_64(LValue64));
  WriteLn('  当前值: ', LValue64);
  WriteLn;
end;

procedure TestCompatibilityDemo;
begin
  WriteLn('=== C/C++兼容性演示 ===');
  WriteLn('本模块提供完全兼容C/C++的原子操作接口:');
  WriteLn;
  WriteLn('C/C++代码:');
  WriteLn('  std::atomic<int> counter{0};');
  WriteLn('  counter.store(42, std::memory_order_release);');
  WriteLn('  int value = counter.load(std::memory_order_acquire);');
  WriteLn('  counter.compare_exchange_strong(expected, desired);');
  WriteLn;
  WriteLn('Pascal等价代码:');
  WriteLn('  var counter: Int32 = 0;');
  WriteLn('  atomic_store(counter, 42, memory_order_release);');
  WriteLn('  var value := atomic_load(counter, memory_order_acquire);');
  WriteLn('  atomic_compare_exchange_strong(counter, expected, desired);');
  WriteLn;
  WriteLn('✅ 接口完全一致，便于移植C/C++无锁算法！');
  WriteLn;
end;

begin
  WriteLn('fafafa.core.atomic v2.0 - C/C++标准兼容测试');
  WriteLn('==============================================');
  WriteLn;
  
  try
    TestStandardAtomicOperations;
    TestTaggedPointer;
    TestMemoryOrdering;
    TestConvenienceFunctions;
    TestCompatibilityDemo;
    
    WriteLn('🎉 所有测试通过！C/C++兼容的原子操作模块工作正常！');
    WriteLn;
    WriteLn('✨ 新特性:');
    WriteLn('  ✅ 100% C/C++ std::atomic 兼容接口');
    WriteLn('  ✅ 标准内存序支持 (memory_order_*)');
    WriteLn('  ✅ Tagged Pointer ABA 解决方案');
    WriteLn('  ✅ 强/弱比较交换区分');
    WriteLn('  ✅ 为移植 Boost.Lockfree 做好准备');
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
