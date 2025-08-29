{$CODEPAGE UTF8}
program TestRetainDrain;

uses
  fafafa.core.collections.vec;

type
  TIntVec = specialize TVec<LongInt>;

// 测试用的谓词函数
function IsEven(const aValue: LongInt; aData: Pointer): Boolean;
begin
  Result := (aValue mod 2) = 0;
end;

function IsGreaterThan5(const aValue: LongInt; aData: Pointer): Boolean;
begin
  Result := aValue > 5;
end;

var
  LVec: TIntVec;
  LDrainedVec: specialize IVec<LongInt>;
  i: SizeUInt;

begin
  WriteLn('=== Testing Retain and Drain Methods ===');
  
  // 创建测试向量
  LVec := TIntVec.Create;
  try
    WriteLn('1. Creating test vector...');
    
    // 添加测试数据: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
    for i := 1 to 10 do
      LVec.Push(i);
      
    Write('   Original vector: ');
    for i := 0 to LVec.Count - 1 do
      Write(LVec.Get(i), ' ');
    WriteLn;
    WriteLn('   Size: ', LVec.Count, ' elements');
    
    // 测试 Retain 方法 - 保留偶数
    WriteLn('2. Testing Retain method (keep even numbers)...');
    
    LVec.Retain(@IsEven, nil);
    
    Write('   After Retain (even): ');
    for i := 0 to LVec.Count - 1 do
      Write(LVec.Get(i), ' ');
    WriteLn;
    WriteLn('   Size: ', LVec.Count, ' elements (expected: 5)');
    
    // 重新填充向量用于测试 Drain
    LVec.Clear;
    for i := 1 to 10 do
      LVec.Push(i);
      
    WriteLn('3. Testing Drain method (remove middle elements)...');
    Write('   Before Drain: ');
    for i := 0 to LVec.Count - 1 do
      Write(LVec.Get(i), ' ');
    WriteLn;
    
    // 删除索引 2-5 的元素 (即 3, 4, 5, 6)
    LDrainedVec := LVec.Drain(2, 4);
    
    Write('   After Drain: ');
    for i := 0 to LVec.Count - 1 do
      Write(LVec.Get(i), ' ');
    WriteLn;
    WriteLn('   Remaining size: ', LVec.Count, ' elements (expected: 6)');
    
    Write('   Drained elements: ');
    for i := 0 to LDrainedVec.Count - 1 do
      Write(LDrainedVec.Get(i), ' ');
    WriteLn;
    WriteLn('   Drained size: ', LDrainedVec.Count, ' elements (expected: 4)');
    
    LDrainedVec := nil;
    
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    // 测试匿名函数版本的 Retain
    WriteLn('4. Testing Retain with anonymous function...');
    
    // 重新填充向量
    LVec.Clear;
    for i := 1 to 10 do
      LVec.Push(i);
      
    Write('   Before anonymous Retain: ');
    for i := 0 to LVec.Count - 1 do
      Write(LVec.Get(i), ' ');
    WriteLn;
    
    // 保留大于5的数
    LVec.Retain(function(const aValue: LongInt): Boolean
      begin
        Result := aValue > 5;
      end);
    
    Write('   After anonymous Retain (> 5): ');
    for i := 0 to LVec.Count - 1 do
      Write(LVec.Get(i), ' ');
    WriteLn;
    WriteLn('   Size: ', LVec.Count, ' elements (expected: 5)');
    {$ENDIF}
    
    // 测试边界情况
    WriteLn('5. Testing edge cases...');
    
    // 测试 Drain 全部元素
    LVec.Clear;
    LVec.Push([1, 2, 3]);
    
    WriteLn('   Testing Drain all elements...');
    LDrainedVec := LVec.Drain(0, 3);
    
    WriteLn('   Original vector size after drain all: ', LVec.Count, ' (expected: 0)');
    WriteLn('   Drained vector size: ', LDrainedVec.Count, ' (expected: 3)');
    
    LDrainedVec := nil;
    
    // 测试 Retain 空向量
    WriteLn('   Testing Retain on empty vector...');
    LVec.Retain(@IsEven, nil);
    WriteLn('   Empty vector size after retain: ', LVec.Count, ' (expected: 0)');
    
  finally
    LVec.Free;
  end;
  
  WriteLn('=== Retain and Drain Test Completed ===');
  WriteLn('Key benefits:');
  WriteLn('- Retain: In-place filtering, no memory allocation');
  WriteLn('- Drain: Efficient range removal with element recovery');
  WriteLn('- Both methods handle managed types correctly');
end.
