{$CODEPAGE UTF8}
program test_makevec_factory;

{$DEFINE FAFAFA_CORE_ANONYMOUS_REFERENCES}

uses
  fafafa.core.collections.vec,
  fafafa.core.collections.base;

type
  TIntVec = specialize TVec<Integer>;
  TIntIVec = specialize IVec<Integer>;

var
  LVec1, LVec2, LVec3, LVec4: TIntVec;
  LArray: array[0..4] of Integer = (10, 20, 30, 40, 50);
  LSourceVec: TIntVec;
  LFilteredVec: TIntIVec;
  LArray2: array of Integer;
  LClonedVec: TIntVec;
  i: Integer;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function IsEven(const aValue: Integer): Boolean;
begin
  Result := (aValue mod 2) = 0;
end;

function IsGreaterThan25(const aValue: Integer): Boolean;
begin
  Result := aValue > 25;
end;
{$ENDIF}

begin
  WriteLn('=== 测试 TVec 构造函数和函数式编程API ===');

  // 测试1: 默认容量创建
  WriteLn('1. 测试默认容量创建');
  LVec1 := TIntVec.Create;
  try
    WriteLn('   默认Vec创建成功，容量: ', LVec1.Capacity, ', 大小: ', LVec1.Count);
  finally
    LVec1.Free;
  end;

  // 测试2: 从数组创建
  WriteLn('2. 测试从数组创建');
  LVec3 := TIntVec.Create(LArray, nil, nil);
  try
    WriteLn('   从数组创建成功，容量: ', LVec3.Capacity, ', 大小: ', LVec3.Count);
    Write('   内容: ');
    for i := 0 to LVec3.Count - 1 do
      Write(LVec3.Get(i), ' ');
    WriteLn;

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    // 测试函数式编程API
    WriteLn('3. 测试函数式编程API');

    // 测试Filter - 过滤偶数
    WriteLn('   测试Filter - 过滤偶数:');
    LFilteredVec := LVec3.Filter(@IsEven);
    try
      Write('   偶数: ');
      for i := 0 to LFilteredVec.Count - 1 do
        Write(LFilteredVec.Get(i), ' ');
      WriteLn;
    finally
      LFilteredVec := nil;
    end;

    // 测试Any - 是否有大于25的数
    WriteLn('   测试Any - 是否有大于25的数: ', LVec3.Any(@IsGreaterThan25));

    // 测试All - 是否所有数都是偶数
    WriteLn('   测试All - 是否所有数都是偶数: ', LVec3.All(@IsEven));
    {$ENDIF}

    // 测试便利方法
    WriteLn('4. 测试便利方法');
    WriteLn('   IsEmpty: ', LVec3.IsEmpty);
    WriteLn('   First: ', LVec3.First);
    WriteLn('   Last: ', LVec3.Last);

    // 测试ToArray
    WriteLn('   测试ToArray:');
    LArray2 := LVec3.ToArray;
    Write('   ToArray: ');
    for i := 0 to High(LArray2) do
      Write(LArray2[i], ' ');
    WriteLn;

    // 测试Clone
    WriteLn('   测试Clone:');
    LClonedVec := LVec3.Clone as TIntVec;
    try
      Write('   Clone: ');
      for i := 0 to LClonedVec.Count - 1 do
        Write(LClonedVec.Get(i), ' ');
      WriteLn;
    finally
      LClonedVec.Free;
    end;

  finally
    LVec3.Free;
  end;

  WriteLn('=== 所有测试完成 ===');
end.
