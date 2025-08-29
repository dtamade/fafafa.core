{$CODEPAGE UTF8}
program TestPerformanceImprovements;

uses
  fafafa.core.collections.vec,
  SysUtils;

type
  TIntVec = specialize TVec<LongInt>;

// 测试用的谓词函数
function IsEven(const aValue: LongInt; aData: Pointer): Boolean;
begin
  Result := (aValue mod 2) = 0;
end;

function IsGreaterThan10(const aValue: LongInt; aData: Pointer): Boolean;
begin
  Result := aValue > 10;
end;

var
  LVec: TIntVec;
  LFilteredVec: specialize IVec<LongInt>;
  LClonedVec: TIntVec;
  i: SizeUInt;
  LStartTime, LEndTime: QWord;

begin
  WriteLn('=== Testing Performance Improvements ===');
  
  // 创建大向量进行性能测试
  LVec := TIntVec.Create;
  try
    WriteLn('1. Creating large vector with 100,000 elements...');
    LStartTime := GetTickCount64;
    
    // 添加大量测试数据
    for i := 1 to 100000 do
      LVec.Push(i);
      
    LEndTime := GetTickCount64;
    WriteLn('   Time to create: ', LEndTime - LStartTime, ' ms');
    WriteLn('   Vector size: ', LVec.Count, ' elements');
    WriteLn('   Vector capacity: ', LVec.GetCapacity, ' elements');
    
    // 测试优化后的 Filter 性能
    WriteLn('2. Testing optimized Filter performance...');
    LStartTime := GetTickCount64;
    
    LFilteredVec := LVec.Filter(@IsEven, nil);
    
    LEndTime := GetTickCount64;
    WriteLn('   Filter (even numbers) time: ', LEndTime - LStartTime, ' ms');
    WriteLn('   Filtered result size: ', LFilteredVec.Count, ' elements');
    
    // 验证结果正确性
    Write('   First 10 filtered elements: ');
    for i := 0 to Min(9, LFilteredVec.Count - 1) do
      Write(LFilteredVec.Get(i), ' ');
    WriteLn;
    
    LFilteredVec := nil;
    
    // 测试另一个 Filter
    WriteLn('3. Testing Filter with different predicate...');
    LStartTime := GetTickCount64;
    
    LFilteredVec := LVec.Filter(@IsGreaterThan10, nil);
    
    LEndTime := GetTickCount64;
    WriteLn('   Filter (> 10) time: ', LEndTime - LStartTime, ' ms');
    WriteLn('   Filtered result size: ', LFilteredVec.Count, ' elements');
    
    LFilteredVec := nil;
    
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    // 测试匿名函数版本
    WriteLn('4. Testing anonymous function Filter...');
    LStartTime := GetTickCount64;
    
    LFilteredVec := LVec.Filter(function(const aValue: LongInt): Boolean
      begin
        Result := (aValue mod 5) = 0;  // 能被5整除
      end);
    
    LEndTime := GetTickCount64;
    WriteLn('   Anonymous Filter (divisible by 5) time: ', LEndTime - LStartTime, ' ms');
    WriteLn('   Filtered result size: ', LFilteredVec.Count, ' elements');
    
    LFilteredVec := nil;
    {$ENDIF}
    
    // 测试优化后的 Clone 性能
    WriteLn('5. Testing optimized Clone performance...');
    LStartTime := GetTickCount64;
    
    LClonedVec := LVec.Clone as TIntVec;
    
    LEndTime := GetTickCount64;
    WriteLn('   Clone time: ', LEndTime - LStartTime, ' ms');
    WriteLn('   Cloned vector size: ', LClonedVec.Count, ' elements');
    WriteLn('   Cloned vector capacity: ', LClonedVec.GetCapacity, ' elements');
    
    // 验证克隆正确性
    WriteLn('   First element - Original: ', LVec.Get(0), ', Cloned: ', LClonedVec.Get(0));
    WriteLn('   Last element - Original: ', LVec.Get(LVec.Count-1), ', Cloned: ', LClonedVec.Get(LClonedVec.Count-1));
    
    LClonedVec.Free;
    
    // 测试 Any 和 All 性能
    WriteLn('6. Testing Any/All performance...');
    LStartTime := GetTickCount64;
    
    WriteLn('   Has even numbers: ', LVec.Any(@IsEven, nil));
    WriteLn('   All greater than 0: ', LVec.All(@IsGreaterThan10, nil));
    
    LEndTime := GetTickCount64;
    WriteLn('   Any/All time: ', LEndTime - LStartTime, ' ms');
    
  finally
    LVec.Free;
  end;
  
  WriteLn('=== Performance Test Completed ===');
end.
