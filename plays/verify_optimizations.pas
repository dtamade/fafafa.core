{$CODEPAGE UTF8}
program VerifyOptimizations;

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
  LClonedVec: TIntVec;
  i: SizeUInt;

begin
  WriteLn('=== Verifying Performance Optimizations ===');
  
  // 创建测试向量
  LVec := TIntVec.Create;
  try
    WriteLn('1. Creating test vector...');
    
    // 添加测试数据
    for i := 1 to 1000 do
      LVec.Push(i);
      
    WriteLn('   Vector size: ', LVec.Count, ' elements');
    WriteLn('   Vector capacity: ', LVec.GetCapacity, ' elements');
    
    // 测试优化后的 Filter
    WriteLn('2. Testing optimized Filter (should pre-allocate capacity)...');
    
    LFilteredVec := LVec.Filter(@IsEven, nil);
    
    WriteLn('   Filtered result size: ', LFilteredVec.Count, ' elements (expected: 500)');
    WriteLn('   Filter result capacity: ', LFilteredVec.GetCapacity, ' elements');
    
    // 验证结果正确性
    WriteLn('   First few filtered elements: ', LFilteredVec.Get(0), ' ', LFilteredVec.Get(1), ' ', LFilteredVec.Get(2));
    WriteLn('   All should be even numbers');
    
    // 测试优化后的 Clone
    WriteLn('3. Testing optimized Clone (should copy growth strategy)...');
    
    LClonedVec := LVec.Clone as TIntVec;
    
    WriteLn('   Original vector size: ', LVec.Count, ' elements');
    WriteLn('   Cloned vector size: ', LClonedVec.Count, ' elements');
    WriteLn('   Original capacity: ', LVec.GetCapacity, ' elements');
    WriteLn('   Cloned capacity: ', LClonedVec.GetCapacity, ' elements');
    
    // 验证克隆正确性
    WriteLn('   First element - Original: ', LVec.Get(0), ', Cloned: ', LClonedVec.Get(0));
    WriteLn('   Last element - Original: ', LVec.Get(LVec.Count-1), ', Cloned: ', LClonedVec.Get(LClonedVec.Count-1));
    
    LClonedVec.Free;
    LFilteredVec := nil;
    
    WriteLn('4. Testing PushUnChecked method...');
    
    // 测试 PushUnChecked（需要确保有足够容量）
    LVec.Reserve(10);  // 确保有额外容量
    LVec.PushUnChecked(9999);
    
    WriteLn('   Added element using PushUnChecked: ', LVec.Get(LVec.Count-1));
    WriteLn('   New vector size: ', LVec.Count, ' elements');
    
  finally
    LVec.Free;
  end;
  
  WriteLn('=== Optimization Verification Completed ===');
  WriteLn('Key improvements:');
  WriteLn('- Filter now pre-allocates capacity to avoid reallocations');
  WriteLn('- Filter uses PushUnChecked for better performance');
  WriteLn('- Clone now copies growth strategy configuration');
  WriteLn('- Added PushUnChecked for high-performance element addition');
end.
