program test_debug_overflow;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.atomic,
  fafafa.core.lockfree.hashmap;

// 简单的字符串比较器
function SimpleStringComparer(const A, B: string): Boolean;
begin
  Result := A = B;
end;

// 最小化测试来定位溢出问题
procedure TestMinimal;
var
  LHashMap: TStringIntHashMap;
  LHash: QWord;
  LValue: Integer;
begin
  WriteLn('开始最小化测试...');

  try
    WriteLn('1. 创建哈希表...');
    LHashMap := TStringIntHashMap.Create(4, @DefaultStringHash, @SimpleStringComparer);

    try
      WriteLn('2. 测试哈希函数...');
      LHash := DefaultStringHash('test');
      WriteLn('   哈希值: ', LHash);

      WriteLn('3. 测试插入单个元素...');
      if LHashMap.insert('test', 123) then
        WriteLn('   插入成功')
      else
        WriteLn('   插入失败');

      WriteLn('4. 测试查找...');
      if LHashMap.find('test', LValue) then
        WriteLn('   找到值: ', LValue)
      else
        WriteLn('   未找到');

    finally
      LHashMap.Free;
    end;

    WriteLn('✅ 最小化测试完成');

  except
    on E: Exception do
    begin
      WriteLn('❌ 测试失败: ', E.Message);
      WriteLn('   异常类: ', E.ClassName);
      raise;
    end;
  end;
end;

// 测试原子操作
procedure TestAtomicOperations;
var
  LTaggedPtr: tagged_ptr;
  LPtr: Pointer;
  LExtractedPtr: Pointer;
  LTag: Word;
  LLoadedPtr: tagged_ptr;
begin
  WriteLn('测试原子操作...');

  try
    WriteLn('1. 测试 make_tagged_ptr...');
    GetMem(LPtr, 100);
    LTaggedPtr := make_tagged_ptr(LPtr, 1);
    WriteLn('   Tagged pointer 创建成功');

    WriteLn('2. 测试 get_ptr...');
    LExtractedPtr := get_ptr(LTaggedPtr);
    WriteLn('   指针提取成功: ', PtrUInt(LExtractedPtr));

    WriteLn('3. 测试 get_tag...');
    LTag := get_tag(LTaggedPtr);
    WriteLn('   标签提取成功: ', LTag);

    WriteLn('4. 测试原子加载...');
    LLoadedPtr := atomic_load_tagged_ptr(LTaggedPtr, memory_order_relaxed);
    WriteLn('   原子加载成功');

    FreeMem(LPtr);
    WriteLn('✅ 原子操作测试完成');

  except
    on E: Exception do
    begin
      WriteLn('❌ 原子操作测试失败: ', E.Message);
      WriteLn('   异常类: ', E.ClassName);
      raise;
    end;
  end;
end;

// 测试哈希函数
procedure TestHashFunctions;
var
  LHash1, LHash2, LHash3: QWord;
  LIntHash1, LIntHash2: QWord;
begin
  WriteLn('测试哈希函数...');

  try
    WriteLn('1. 测试字符串哈希...');
    LHash1 := DefaultStringHash('a');
    WriteLn('   "a" 的哈希值: ', LHash1);

    LHash2 := DefaultStringHash('test');
    WriteLn('   "test" 的哈希值: ', LHash2);

    LHash3 := DefaultStringHash('collision_key_1');
    WriteLn('   "collision_key_1" 的哈希值: ', LHash3);

    WriteLn('2. 测试整数哈希...');
    LIntHash1 := DefaultIntegerHash(1);
    WriteLn('   1 的哈希值: ', LIntHash1);

    LIntHash2 := DefaultIntegerHash(12345);
    WriteLn('   12345 的哈希值: ', LIntHash2);

    WriteLn('✅ 哈希函数测试完成');

  except
    on E: Exception do
    begin
      WriteLn('❌ 哈希函数测试失败: ', E.Message);
      WriteLn('   异常类: ', E.ClassName);
      raise;
    end;
  end;
end;

begin
  WriteLn('Debug 模式溢出问题定位测试');
  WriteLn('============================');
  WriteLn;
  
  try
    TestHashFunctions;
    WriteLn;
    
    TestAtomicOperations;
    WriteLn;
    
    TestMinimal;
    WriteLn;
    
    WriteLn('🎉 所有测试通过！');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 测试失败: ', E.Message);
      WriteLn('   异常类: ', E.ClassName);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
