{$CODEPAGE UTF8}
program SimpleRetainDrainTest;

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
  LDrainedVec: specialize IVec<LongInt>;
  i: SizeUInt;

begin
  WriteLn('=== Simple Retain and Drain Test ===');
  
  // 创建测试向量
  LVec := TIntVec.Create;
  try
    WriteLn('1. Testing Retain method...');
    
    // 添加测试数据: 1, 2, 3, 4, 5, 6
    LVec.Push([1, 2, 3, 4, 5, 6]);
      
    Write('   Before Retain: ');
    for i := 0 to LVec.Count - 1 do
      Write(LVec.Get(i), ' ');
    WriteLn;
    
    // 保留偶数
    LVec.Retain(@IsEven, nil);
    
    Write('   After Retain (even): ');
    for i := 0 to LVec.Count - 1 do
      Write(LVec.Get(i), ' ');
    WriteLn;
    WriteLn('   Size: ', LVec.Count, ' elements (expected: 3)');
    
    WriteLn('2. Testing Drain method...');
    
    // 重新填充向量
    LVec.Clear;
    LVec.Push([1, 2, 3, 4, 5]);
      
    Write('   Before Drain: ');
    for i := 0 to LVec.Count - 1 do
      Write(LVec.Get(i), ' ');
    WriteLn;
    
    // 删除中间的元素 (索引 1-2, 即 2, 3)
    LDrainedVec := LVec.Drain(1, 2);
    
    Write('   After Drain: ');
    for i := 0 to LVec.Count - 1 do
      Write(LVec.Get(i), ' ');
    WriteLn;
    WriteLn('   Remaining size: ', LVec.Count, ' elements (expected: 3)');
    
    Write('   Drained elements: ');
    for i := 0 to LDrainedVec.Count - 1 do
      Write(LDrainedVec.Get(i), ' ');
    WriteLn;
    WriteLn('   Drained size: ', LDrainedVec.Count, ' elements (expected: 2)');
    
    LDrainedVec := nil;
    
  finally
    LVec.Free;
  end;
  
  WriteLn('=== Test Completed Successfully ===');
end.
