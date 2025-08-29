{$CODEPAGE UTF8}
program TestFilterPerformance;

uses
  fafafa.core.collections.vec;

type
  TIntVec = specialize TVec<LongInt>;

// 测试用的谓词函数
function IsEven(const aValue: LongInt; aData: Pointer): Boolean;
begin
  Result := (aValue mod 2) = 0;
end;

var
  LVec: TIntVec;
  LFilteredVec: specialize IVec<LongInt>;
  i: SizeUInt;

begin
  WriteLn('=== Testing Optimized Filter Performance ===');
  
  // 创建测试向量
  LVec := TIntVec.Create;
  try
    WriteLn('1. Creating vector with 50,000 elements...');
    
    // 添加测试数据
    for i := 1 to 50000 do
      LVec.Push(i);
      
    WriteLn('   Vector size: ', LVec.Count, ' elements');
    WriteLn('   Vector capacity: ', LVec.GetCapacity, ' elements');
    
    // 测试优化后的 Filter 性能
    WriteLn('2. Testing optimized Filter...');
    
    LFilteredVec := LVec.Filter(@IsEven, nil);
    
    WriteLn('   Filtered result size: ', LFilteredVec.Count, ' elements');
    WriteLn('   Expected size: 25000 elements');
    
    // 验证结果正确性
    Write('   First 10 filtered elements: ');
    for i := 0 to 9 do
      Write(LFilteredVec.Get(i), ' ');
    WriteLn;
    
    Write('   Last 10 filtered elements: ');
    for i := LFilteredVec.Count - 10 to LFilteredVec.Count - 1 do
      Write(LFilteredVec.Get(i), ' ');
    WriteLn;
    
    LFilteredVec := nil;
    
    // 测试 Clone 性能
    WriteLn('3. Testing optimized Clone...');

    // 先获取一个引用用于克隆
    LFilteredVec := LVec.Filter(@IsEven, nil);
    LVec.Free;
    LVec := LFilteredVec.Clone as TIntVec;
    LFilteredVec := nil;

    WriteLn('   Clone completed successfully');
    WriteLn('   Cloned vector size: ', LVec.Count, ' elements');
    
  finally
    LVec.Free;
  end;
  
  WriteLn('=== Performance Test Completed Successfully ===');
end.
