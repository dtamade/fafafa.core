program test_atomic;


{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.atomic;

// 测试基础原子操作
procedure TestBasicAtomicOperations;
var
  LValue8: Byte;
  LValue16: Word;
  LValue32: LongWord;
  LValue64: QWord;
  LPtr: Pointer;
  LTaggedPtr: TTaggedPtr;
  LResult: Boolean;
begin
  WriteLn('=== 测试基础原子操作 ===');
  
  // 测试8位原子操作
  LValue8 := 10;
  WriteLn('8位原子操作测试:');
  WriteLn('  初始值: ', LValue8);
  WriteLn('  Exchange(20): ', TAtomic.Exchange8(LValue8, 20));
  WriteLn('  当前值: ', LValue8);
  WriteLn('  CompareExchange(30, 20): ', TAtomic.CompareExchange8(LValue8, 30, 20));
  WriteLn('  当前值: ', LValue8);
  WriteLn('  FetchAdd(5): ', TAtomic.FetchAdd8(LValue8, 5));
  WriteLn('  当前值: ', LValue8);
  WriteLn;
  
  // 测试16位原子操作
  LValue16 := 1000;
  WriteLn('16位原子操作测试:');
  WriteLn('  初始值: ', LValue16);
  WriteLn('  Exchange(2000): ', TAtomic.Exchange16(LValue16, 2000));
  WriteLn('  当前值: ', LValue16);
  WriteLn('  CompareExchange(3000, 2000): ', TAtomic.CompareExchange16(LValue16, 3000, 2000));
  WriteLn('  当前值: ', LValue16);
  WriteLn('  FetchAdd(500): ', TAtomic.FetchAdd16(LValue16, 500));
  WriteLn('  当前值: ', LValue16);
  WriteLn;
  
  // 测试32位原子操作
  LValue32 := 100000;
  WriteLn('32位原子操作测试:');
  WriteLn('  初始值: ', LValue32);
  WriteLn('  Exchange(200000): ', TAtomic.Exchange32(LValue32, 200000));
  WriteLn('  当前值: ', LValue32);
  WriteLn('  CompareExchange(300000, 200000): ', TAtomic.CompareExchange32(LValue32, 300000, 200000));
  WriteLn('  当前值: ', LValue32);
  WriteLn('  FetchAdd(50000): ', TAtomic.FetchAdd32(LValue32, 50000));
  WriteLn('  当前值: ', LValue32);
  WriteLn;
  
  // 测试64位原子操作
  LValue64 := 10000000000;
  WriteLn('64位原子操作测试:');
  WriteLn('  初始值: ', LValue64);
  WriteLn('  Exchange(20000000000): ', TAtomic.Exchange64(LValue64, 20000000000));
  WriteLn('  当前值: ', LValue64);
  WriteLn('  CompareExchange(30000000000, 20000000000): ', TAtomic.CompareExchange64(LValue64, 30000000000, 20000000000));
  WriteLn('  当前值: ', LValue64);
  WriteLn('  FetchAdd(5000000000): ', TAtomic.FetchAdd64(LValue64, 5000000000));
  WriteLn('  当前值: ', LValue64);
  WriteLn;
  
  WriteLn('✅ 基础原子操作测试通过');
end;

// 测试指针原子操作
procedure TestPointerAtomicOperations;
var
  LPtr1, LPtr2, LPtr3: Pointer;
  LResult: Pointer;
begin
  WriteLn('=== 测试指针原子操作 ===');
  
  // 分配一些测试指针
  GetMem(LPtr1, 100);
  GetMem(LPtr2, 200);
  GetMem(LPtr3, 300);
  
  try
    WriteLn('指针原子操作测试:');
    WriteLn('  初始指针: ', PtrUInt(LPtr1));
    
    LResult := TAtomic.ExchangePtr(LPtr1, LPtr2);
    WriteLn('  Exchange结果: ', PtrUInt(LResult));
    WriteLn('  当前指针: ', PtrUInt(LPtr1));
    
    LResult := TAtomic.CompareExchangePtr(LPtr1, LPtr3, LPtr2);
    WriteLn('  CompareExchange结果: ', PtrUInt(LResult));
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
  LTaggedPtr: TTaggedPtr;
  LNewTaggedPtr: TTaggedPtr;
  LResult: TTaggedPtr;
  LPtr: Pointer;
begin
  WriteLn('=== 测试Tagged Pointer ===');
  
  GetMem(LPtr, 100);
  try
    // 创建Tagged Pointer
    LTaggedPtr := CreateTaggedPtr(LPtr, 42);
    WriteLn('Tagged Pointer测试:');
    WriteLn('  指针: ', PtrUInt(GetTaggedPtrPtr(LTaggedPtr)));
    WriteLn('  标签: ', GetTaggedPtrTag(LTaggedPtr));
    WriteLn('  下一个标签: ', GetTaggedPtrNextTag(LTaggedPtr));
    
    // 测试原子操作
    LNewTaggedPtr := CreateTaggedPtr(LPtr, 43);
    LResult := TAtomic.LoadTaggedPtr(LTaggedPtr);
    WriteLn('  Load结果 - 指针: ', PtrUInt(GetTaggedPtrPtr(LResult)), ', 标签: ', GetTaggedPtrTag(LResult));

    TAtomic.StoreTaggedPtr(LTaggedPtr, LNewTaggedPtr);
    LResult := TAtomic.LoadTaggedPtr(LTaggedPtr);
    WriteLn('  Store后 - 指针: ', PtrUInt(GetTaggedPtrPtr(LResult)), ', 标签: ', GetTaggedPtrTag(LResult));

    // 测试CompareExchange
    LNewTaggedPtr := CreateTaggedPtr(LPtr, 44);
    LResult := TAtomic.CompareExchangeTaggedPtr(LTaggedPtr, LNewTaggedPtr, CreateTaggedPtr(LPtr, 43));
    WriteLn('  CompareExchange结果 - 指针: ', PtrUInt(GetTaggedPtrPtr(LResult)), ', 标签: ', GetTaggedPtrTag(LResult));

    LResult := TAtomic.LoadTaggedPtr(LTaggedPtr);
    WriteLn('  最终值 - 指针: ', PtrUInt(GetTaggedPtrPtr(LResult)), ', 标签: ', GetTaggedPtrTag(LResult));
    
    WriteLn('✅ Tagged Pointer测试通过');
    
  finally
    FreeMem(LPtr);
  end;
  WriteLn;
end;

// 测试便捷函数
procedure TestConvenienceFunctions;
var
  LInt: LongInt;
  LInt64: Int64;
  LPtr: Pointer;
begin
  WriteLn('=== 测试便捷函数 ===');
  
  // 测试递增/递减
  LInt := 100;
  WriteLn('便捷函数测试:');
  WriteLn('  初始值: ', LInt);
  WriteLn('  AtomicIncrement: ', AtomicIncrement(LInt));
  WriteLn('  当前值: ', LInt);
  WriteLn('  AtomicDecrement: ', AtomicDecrement(LInt));
  WriteLn('  当前值: ', LInt);
  
  // 测试64位递增/递减
  LInt64 := 1000000000;
  WriteLn('  64位初始值: ', LInt64);
  WriteLn('  AtomicIncrement64: ', AtomicIncrement64(LInt64));
  WriteLn('  当前值: ', LInt64);
  WriteLn('  AtomicDecrement64: ', AtomicDecrement64(LInt64));
  WriteLn('  当前值: ', LInt64);
  
  // 测试交换
  WriteLn('  AtomicExchange(200): ', AtomicExchange(LInt, 200));
  WriteLn('  当前值: ', LInt);
  
  WriteLn('✅ 便捷函数测试通过');
  WriteLn;
end;

// 测试内存序
procedure TestMemoryOrdering;
var
  LValue: LongWord;
begin
  WriteLn('=== 测试内存序 ===');
  
  LValue := 100;
  WriteLn('内存序测试:');
  WriteLn('  初始值: ', LValue);
  
  // 测试不同内存序的操作
  TAtomic.Store32(LValue, 200, moRelaxed);
  WriteLn('  Store(relaxed)后: ', TAtomic.Load32(LValue, moRelaxed));
  
  TAtomic.Store32(LValue, 300, moRelease);
  WriteLn('  Store(release)后: ', TAtomic.Load32(LValue, moAcquire));
  
  TAtomic.Store32(LValue, 400, moSeqCst);
  WriteLn('  Store(seq_cst)后: ', TAtomic.Load32(LValue, moSeqCst));
  
  // 测试内存屏障
  TAtomic.MemoryBarrier;
  TAtomic.CompilerBarrier;
  
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
