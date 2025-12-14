unit Test_Algorithms_Advanced;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.collections.algorithms;

type
  { 带稳定性标记的记录，用于测试稳定排序 }
  TStableItem = packed record
    Key: Integer;
    Order: Integer;  // 原始顺序，用于验证稳定性
  end;
  TStableArray = array of TStableItem;

  { TTestAlgorithmsAdvanced }
  TTestAlgorithmsAdvanced = class(TTestCase)
  published
    // StableSort 测试
    procedure Test_StableSort_EmptyArray;
    procedure Test_StableSort_SingleElement;
    procedure Test_StableSort_AlreadySorted;
    procedure Test_StableSort_ReverseSorted;
    procedure Test_StableSort_PreservesRelativeOrder;
    procedure Test_StableSort_LargeArray;
    
    // Merge 测试
    procedure Test_Merge_BothEmpty;
    procedure Test_Merge_FirstEmpty;
    procedure Test_Merge_SecondEmpty;
    procedure Test_Merge_SimpleCase;
    procedure Test_Merge_Interleaved;
    procedure Test_Merge_AllFromFirst;
    procedure Test_Merge_AllFromSecond;
  end;

function CompareInt(const A, B: Integer; aData: Pointer): SizeInt;
function CompareStableItem(const A, B: TStableItem; aData: Pointer): SizeInt;

implementation

function CompareInt(const A, B: Integer; aData: Pointer): SizeInt;
begin
  if A < B then Result := -1
  else if A > B then Result := 1
  else Result := 0;
end;

function CompareStableItem(const A, B: TStableItem; aData: Pointer): SizeInt;
begin
  // 只按 Key 比较，不比较 Order
  if A.Key < B.Key then Result := -1
  else if A.Key > B.Key then Result := 1
  else Result := 0;
end;

{ TTestAlgorithmsAdvanced }

procedure TTestAlgorithmsAdvanced.Test_StableSort_EmptyArray;
var
  Arr: array of Integer;
begin
  SetLength(Arr, 0);
  specialize StableSort<Integer>(Arr, @CompareInt, nil);
  AssertEquals(0, Length(Arr));
end;

procedure TTestAlgorithmsAdvanced.Test_StableSort_SingleElement;
var
  Arr: array of Integer;
begin
  Arr := [42];
  specialize StableSort<Integer>(Arr, @CompareInt, nil);
  AssertEquals(1, Length(Arr));
  AssertEquals(42, Arr[0]);
end;

procedure TTestAlgorithmsAdvanced.Test_StableSort_AlreadySorted;
var
  Arr: array of Integer;
begin
  Arr := [1, 2, 3, 4, 5];
  specialize StableSort<Integer>(Arr, @CompareInt, nil);
  AssertEquals(1, Arr[0]);
  AssertEquals(2, Arr[1]);
  AssertEquals(3, Arr[2]);
  AssertEquals(4, Arr[3]);
  AssertEquals(5, Arr[4]);
end;

procedure TTestAlgorithmsAdvanced.Test_StableSort_ReverseSorted;
var
  Arr: array of Integer;
begin
  Arr := [5, 4, 3, 2, 1];
  specialize StableSort<Integer>(Arr, @CompareInt, nil);
  AssertEquals(1, Arr[0]);
  AssertEquals(2, Arr[1]);
  AssertEquals(3, Arr[2]);
  AssertEquals(4, Arr[3]);
  AssertEquals(5, Arr[4]);
end;

procedure TTestAlgorithmsAdvanced.Test_StableSort_PreservesRelativeOrder;
var
  Arr: TStableArray;
  i: Integer;
begin
  // 创建有重复 Key 的数组
  SetLength(Arr, 6);
  Arr[0].Key := 2; Arr[0].Order := 0;  // 第一个 2
  Arr[1].Key := 1; Arr[1].Order := 1;  // 第一个 1
  Arr[2].Key := 2; Arr[2].Order := 2;  // 第二个 2
  Arr[3].Key := 1; Arr[3].Order := 3;  // 第二个 1
  Arr[4].Key := 2; Arr[4].Order := 4;  // 第三个 2
  Arr[5].Key := 1; Arr[5].Order := 5;  // 第三个 1
  
  specialize StableSort<TStableItem>(Arr, @CompareStableItem, nil);
  
  // 检查排序结果：所有 1 在前，所有 2 在后
  AssertEquals('Key[0]', 1, Arr[0].Key);
  AssertEquals('Key[1]', 1, Arr[1].Key);
  AssertEquals('Key[2]', 1, Arr[2].Key);
  AssertEquals('Key[3]', 2, Arr[3].Key);
  AssertEquals('Key[4]', 2, Arr[4].Key);
  AssertEquals('Key[5]', 2, Arr[5].Key);
  
  // 关键：稳定排序必须保持相等元素的相对顺序
  // 所有 Key=1 的元素应按原始顺序：Order 1, 3, 5
  AssertEquals('Order of 1s[0]', 1, Arr[0].Order);
  AssertEquals('Order of 1s[1]', 3, Arr[1].Order);
  AssertEquals('Order of 1s[2]', 5, Arr[2].Order);
  
  // 所有 Key=2 的元素应按原始顺序：Order 0, 2, 4
  AssertEquals('Order of 2s[0]', 0, Arr[3].Order);
  AssertEquals('Order of 2s[1]', 2, Arr[4].Order);
  AssertEquals('Order of 2s[2]', 4, Arr[5].Order);
end;

procedure TTestAlgorithmsAdvanced.Test_StableSort_LargeArray;
var
  Arr: array of Integer;
  i: Integer;
begin
  SetLength(Arr, 1000);
  for i := 0 to 999 do
    Arr[i] := 999 - i;
  
  specialize StableSort<Integer>(Arr, @CompareInt, nil);
  
  // 验证排序正确
  for i := 0 to 999 do
    AssertEquals(i, Arr[i]);
end;

// Merge 测试

procedure TTestAlgorithmsAdvanced.Test_Merge_BothEmpty;
var
  A, B, C: array of Integer;
begin
  SetLength(A, 0);
  SetLength(B, 0);
  C := specialize Merge<Integer>(A, B, @CompareInt, nil);
  AssertEquals(0, Length(C));
end;

procedure TTestAlgorithmsAdvanced.Test_Merge_FirstEmpty;
var
  A, B, C: array of Integer;
begin
  SetLength(A, 0);
  B := [1, 2, 3];
  C := specialize Merge<Integer>(A, B, @CompareInt, nil);
  AssertEquals(3, Length(C));
  AssertEquals(1, C[0]);
  AssertEquals(2, C[1]);
  AssertEquals(3, C[2]);
end;

procedure TTestAlgorithmsAdvanced.Test_Merge_SecondEmpty;
var
  A, B, C: array of Integer;
begin
  A := [1, 2, 3];
  SetLength(B, 0);
  C := specialize Merge<Integer>(A, B, @CompareInt, nil);
  AssertEquals(3, Length(C));
  AssertEquals(1, C[0]);
  AssertEquals(2, C[1]);
  AssertEquals(3, C[2]);
end;

procedure TTestAlgorithmsAdvanced.Test_Merge_SimpleCase;
var
  A, B, C: array of Integer;
begin
  A := [1, 3, 5];
  B := [2, 4, 6];
  C := specialize Merge<Integer>(A, B, @CompareInt, nil);
  AssertEquals(6, Length(C));
  AssertEquals(1, C[0]);
  AssertEquals(2, C[1]);
  AssertEquals(3, C[2]);
  AssertEquals(4, C[3]);
  AssertEquals(5, C[4]);
  AssertEquals(6, C[5]);
end;

procedure TTestAlgorithmsAdvanced.Test_Merge_Interleaved;
var
  A, B, C: array of Integer;
begin
  A := [1, 4, 7];
  B := [2, 3, 5, 6, 8];
  C := specialize Merge<Integer>(A, B, @CompareInt, nil);
  AssertEquals(8, Length(C));
  AssertEquals(1, C[0]);
  AssertEquals(2, C[1]);
  AssertEquals(3, C[2]);
  AssertEquals(4, C[3]);
  AssertEquals(5, C[4]);
  AssertEquals(6, C[5]);
  AssertEquals(7, C[6]);
  AssertEquals(8, C[7]);
end;

procedure TTestAlgorithmsAdvanced.Test_Merge_AllFromFirst;
var
  A, B, C: array of Integer;
begin
  A := [1, 2, 3];
  B := [10, 20, 30];
  C := specialize Merge<Integer>(A, B, @CompareInt, nil);
  AssertEquals(6, Length(C));
  AssertEquals(1, C[0]);
  AssertEquals(2, C[1]);
  AssertEquals(3, C[2]);
  AssertEquals(10, C[3]);
  AssertEquals(20, C[4]);
  AssertEquals(30, C[5]);
end;

procedure TTestAlgorithmsAdvanced.Test_Merge_AllFromSecond;
var
  A, B, C: array of Integer;
begin
  A := [10, 20, 30];
  B := [1, 2, 3];
  C := specialize Merge<Integer>(A, B, @CompareInt, nil);
  AssertEquals(6, Length(C));
  AssertEquals(1, C[0]);
  AssertEquals(2, C[1]);
  AssertEquals(3, C[2]);
  AssertEquals(10, C[3]);
  AssertEquals(20, C[4]);
  AssertEquals(30, C[5]);
end;

initialization
  RegisterTest(TTestAlgorithmsAdvanced);

end.
