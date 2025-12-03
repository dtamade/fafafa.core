unit Test_Algorithms;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

{**
 * TDD 测试用例: 泛型算法模块
 * 
 * 测试目标:
 * 1. Sort - 排序算法
 * 2. BinarySearch - 二分查找
 * 3. FindIf - 条件查找
 * 4. Partition - 分区
 * 5. Unique - 去重
 * 6. Rotate - 旋转
 *}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections.base,
  fafafa.core.collections.vec,
  fafafa.core.collections,
  fafafa.core.collections.algorithms;

type
  { TTestAlgorithms }
  TTestAlgorithms = class(TTestCase)
  private
    class function IntCompare(const A, B: Integer; aData: Pointer): SizeInt; static;
    class function IntDescCompare(const A, B: Integer; aData: Pointer): SizeInt; static;
    class function IsEven(const aElement: Integer; aData: Pointer): Boolean; static;
    class function IsGreaterThan5(const aElement: Integer; aData: Pointer): Boolean; static;
  published
    // Sort 测试
    procedure Test_Sort_Ascending;
    procedure Test_Sort_Descending;
    procedure Test_Sort_AlreadySorted;
    procedure Test_Sort_ReverseSorted;
    procedure Test_Sort_Empty;
    procedure Test_Sort_SingleElement;
    procedure Test_Sort_Duplicates;
    
    // BinarySearch 测试
    procedure Test_BinarySearch_Found;
    procedure Test_BinarySearch_NotFound;
    procedure Test_BinarySearch_FirstElement;
    procedure Test_BinarySearch_LastElement;
    procedure Test_BinarySearch_Empty;
    
    // FindIf 测试
    procedure Test_FindIf_Found;
    procedure Test_FindIf_NotFound;
    procedure Test_FindIf_Empty;
    procedure Test_FindIf_FirstMatch;
    
    // Partition 测试
    procedure Test_Partition_EvenOdd;
    procedure Test_Partition_AllMatch;
    procedure Test_Partition_NoneMatch;
    procedure Test_Partition_Empty;
    
    // Unique 测试
    procedure Test_Unique_WithDuplicates;
    procedure Test_Unique_NoDuplicates;
    procedure Test_Unique_AllSame;
    procedure Test_Unique_Empty;
    
    // Rotate 测试
    procedure Test_Rotate_Left;
    procedure Test_Rotate_Right;
    procedure Test_Rotate_Zero;
    procedure Test_Rotate_FullRotation;
    procedure Test_Rotate_Empty;
    
    // 内存泄漏测试
    procedure Test_LargeScale_NoLeak;
  end;

implementation

{ Helper functions }

class function TTestAlgorithms.IntCompare(const A, B: Integer; aData: Pointer): SizeInt;
begin
  if A < B then Result := -1
  else if A > B then Result := 1
  else Result := 0;
end;

class function TTestAlgorithms.IntDescCompare(const A, B: Integer; aData: Pointer): SizeInt;
begin
  if A > B then Result := -1
  else if A < B then Result := 1
  else Result := 0;
end;

class function TTestAlgorithms.IsEven(const aElement: Integer; aData: Pointer): Boolean;
begin
  Result := (aElement mod 2) = 0;
end;

class function TTestAlgorithms.IsGreaterThan5(const aElement: Integer; aData: Pointer): Boolean;
begin
  Result := aElement > 5;
end;

{ Sort Tests }

procedure TTestAlgorithms.Test_Sort_Ascending;
var
  Arr: array of Integer;
begin
  Arr := [5, 2, 8, 1, 9, 3, 7, 4, 6];
  specialize Sort<Integer>(Arr, @IntCompare, nil);
  
  AssertEquals(1, Arr[0]);
  AssertEquals(2, Arr[1]);
  AssertEquals(3, Arr[2]);
  AssertEquals(4, Arr[3]);
  AssertEquals(5, Arr[4]);
  AssertEquals(6, Arr[5]);
  AssertEquals(7, Arr[6]);
  AssertEquals(8, Arr[7]);
  AssertEquals(9, Arr[8]);
end;

procedure TTestAlgorithms.Test_Sort_Descending;
var
  Arr: array of Integer;
begin
  Arr := [5, 2, 8, 1, 9];
  specialize Sort<Integer>(Arr, @IntDescCompare, nil);
  
  AssertEquals(9, Arr[0]);
  AssertEquals(8, Arr[1]);
  AssertEquals(5, Arr[2]);
  AssertEquals(2, Arr[3]);
  AssertEquals(1, Arr[4]);
end;

procedure TTestAlgorithms.Test_Sort_AlreadySorted;
var
  Arr: array of Integer;
begin
  Arr := [1, 2, 3, 4, 5];
  specialize Sort<Integer>(Arr, @IntCompare, nil);
  
  AssertEquals(1, Arr[0]);
  AssertEquals(2, Arr[1]);
  AssertEquals(3, Arr[2]);
  AssertEquals(4, Arr[3]);
  AssertEquals(5, Arr[4]);
end;

procedure TTestAlgorithms.Test_Sort_ReverseSorted;
var
  Arr: array of Integer;
begin
  Arr := [5, 4, 3, 2, 1];
  specialize Sort<Integer>(Arr, @IntCompare, nil);
  
  AssertEquals(1, Arr[0]);
  AssertEquals(2, Arr[1]);
  AssertEquals(3, Arr[2]);
  AssertEquals(4, Arr[3]);
  AssertEquals(5, Arr[4]);
end;

procedure TTestAlgorithms.Test_Sort_Empty;
var
  Arr: array of Integer;
begin
  SetLength(Arr, 0);
  specialize Sort<Integer>(Arr, @IntCompare, nil);
  AssertEquals(0, Length(Arr));
end;

procedure TTestAlgorithms.Test_Sort_SingleElement;
var
  Arr: array of Integer;
begin
  Arr := [42];
  specialize Sort<Integer>(Arr, @IntCompare, nil);
  AssertEquals(42, Arr[0]);
end;

procedure TTestAlgorithms.Test_Sort_Duplicates;
var
  Arr: array of Integer;
begin
  Arr := [3, 1, 2, 1, 3, 2, 1];
  specialize Sort<Integer>(Arr, @IntCompare, nil);
  
  AssertEquals(1, Arr[0]);
  AssertEquals(1, Arr[1]);
  AssertEquals(1, Arr[2]);
  AssertEquals(2, Arr[3]);
  AssertEquals(2, Arr[4]);
  AssertEquals(3, Arr[5]);
  AssertEquals(3, Arr[6]);
end;

{ BinarySearch Tests }

procedure TTestAlgorithms.Test_BinarySearch_Found;
var
  Arr: array of Integer;
  Idx: SizeInt;
begin
  Arr := [1, 2, 3, 4, 5, 6, 7, 8, 9];
  AssertTrue(specialize BinarySearch<Integer>(Arr, 5, @IntCompare, nil, Idx));
  AssertEquals(4, Idx);
end;

procedure TTestAlgorithms.Test_BinarySearch_NotFound;
var
  Arr: array of Integer;
  Idx: SizeInt;
begin
  Arr := [1, 2, 3, 4, 5, 6, 7, 8, 9];
  AssertFalse(specialize BinarySearch<Integer>(Arr, 10, @IntCompare, nil, Idx));
end;

procedure TTestAlgorithms.Test_BinarySearch_FirstElement;
var
  Arr: array of Integer;
  Idx: SizeInt;
begin
  Arr := [1, 2, 3, 4, 5];
  AssertTrue(specialize BinarySearch<Integer>(Arr, 1, @IntCompare, nil, Idx));
  AssertEquals(0, Idx);
end;

procedure TTestAlgorithms.Test_BinarySearch_LastElement;
var
  Arr: array of Integer;
  Idx: SizeInt;
begin
  Arr := [1, 2, 3, 4, 5];
  AssertTrue(specialize BinarySearch<Integer>(Arr, 5, @IntCompare, nil, Idx));
  AssertEquals(4, Idx);
end;

procedure TTestAlgorithms.Test_BinarySearch_Empty;
var
  Arr: array of Integer;
  Idx: SizeInt;
begin
  SetLength(Arr, 0);
  AssertFalse(specialize BinarySearch<Integer>(Arr, 1, @IntCompare, nil, Idx));
end;

{ FindIf Tests }

procedure TTestAlgorithms.Test_FindIf_Found;
var
  Arr: array of Integer;
  Idx: SizeInt;
begin
  Arr := [1, 3, 5, 6, 7, 9];
  AssertTrue(specialize FindIf<Integer>(Arr, @IsEven, nil, Idx));
  AssertEquals(3, Idx); // 6 is at index 3
end;

procedure TTestAlgorithms.Test_FindIf_NotFound;
var
  Arr: array of Integer;
  Idx: SizeInt;
begin
  Arr := [1, 3, 5, 7, 9];
  AssertFalse(specialize FindIf<Integer>(Arr, @IsEven, nil, Idx));
end;

procedure TTestAlgorithms.Test_FindIf_Empty;
var
  Arr: array of Integer;
  Idx: SizeInt;
begin
  SetLength(Arr, 0);
  AssertFalse(specialize FindIf<Integer>(Arr, @IsEven, nil, Idx));
end;

procedure TTestAlgorithms.Test_FindIf_FirstMatch;
var
  Arr: array of Integer;
  Idx: SizeInt;
begin
  Arr := [2, 4, 6, 8];
  AssertTrue(specialize FindIf<Integer>(Arr, @IsEven, nil, Idx));
  AssertEquals(0, Idx);
end;

{ Partition Tests }

procedure TTestAlgorithms.Test_Partition_EvenOdd;
var
  Arr: array of Integer;
  Pivot: SizeInt;
  i: Integer;
begin
  Arr := [1, 2, 3, 4, 5, 6, 7, 8];
  Pivot := specialize Partition<Integer>(Arr, @IsEven, nil);
  
  // All elements before pivot should be even
  for i := 0 to Pivot - 1 do
    AssertTrue('Element should be even', (Arr[i] mod 2) = 0);
  
  // All elements from pivot should be odd
  for i := Pivot to High(Arr) do
    AssertTrue('Element should be odd', (Arr[i] mod 2) <> 0);
end;

procedure TTestAlgorithms.Test_Partition_AllMatch;
var
  Arr: array of Integer;
  Pivot: SizeInt;
begin
  Arr := [2, 4, 6, 8];
  Pivot := specialize Partition<Integer>(Arr, @IsEven, nil);
  AssertEquals(4, Pivot); // All elements match
end;

procedure TTestAlgorithms.Test_Partition_NoneMatch;
var
  Arr: array of Integer;
  Pivot: SizeInt;
begin
  Arr := [1, 3, 5, 7];
  Pivot := specialize Partition<Integer>(Arr, @IsEven, nil);
  AssertEquals(0, Pivot); // No elements match
end;

procedure TTestAlgorithms.Test_Partition_Empty;
var
  Arr: array of Integer;
  Pivot: SizeInt;
begin
  SetLength(Arr, 0);
  Pivot := specialize Partition<Integer>(Arr, @IsEven, nil);
  AssertEquals(0, Pivot);
end;

{ Unique Tests }

procedure TTestAlgorithms.Test_Unique_WithDuplicates;
var
  Arr: array of Integer;
  NewLen: SizeInt;
begin
  Arr := [1, 1, 2, 2, 2, 3, 3, 4, 5, 5];
  NewLen := specialize Unique<Integer>(Arr, @IntCompare, nil);
  
  AssertEquals(5, NewLen);
  AssertEquals(1, Arr[0]);
  AssertEquals(2, Arr[1]);
  AssertEquals(3, Arr[2]);
  AssertEquals(4, Arr[3]);
  AssertEquals(5, Arr[4]);
end;

procedure TTestAlgorithms.Test_Unique_NoDuplicates;
var
  Arr: array of Integer;
  NewLen: SizeInt;
begin
  Arr := [1, 2, 3, 4, 5];
  NewLen := specialize Unique<Integer>(Arr, @IntCompare, nil);
  
  AssertEquals(5, NewLen);
end;

procedure TTestAlgorithms.Test_Unique_AllSame;
var
  Arr: array of Integer;
  NewLen: SizeInt;
begin
  Arr := [7, 7, 7, 7, 7];
  NewLen := specialize Unique<Integer>(Arr, @IntCompare, nil);
  
  AssertEquals(1, NewLen);
  AssertEquals(7, Arr[0]);
end;

procedure TTestAlgorithms.Test_Unique_Empty;
var
  Arr: array of Integer;
  NewLen: SizeInt;
begin
  SetLength(Arr, 0);
  NewLen := specialize Unique<Integer>(Arr, @IntCompare, nil);
  AssertEquals(0, NewLen);
end;

{ Rotate Tests }

procedure TTestAlgorithms.Test_Rotate_Left;
var
  Arr: array of Integer;
begin
  Arr := [1, 2, 3, 4, 5];
  specialize RotateLeft<Integer>(Arr, 2);
  
  AssertEquals(3, Arr[0]);
  AssertEquals(4, Arr[1]);
  AssertEquals(5, Arr[2]);
  AssertEquals(1, Arr[3]);
  AssertEquals(2, Arr[4]);
end;

procedure TTestAlgorithms.Test_Rotate_Right;
var
  Arr: array of Integer;
begin
  Arr := [1, 2, 3, 4, 5];
  specialize RotateRight<Integer>(Arr, 2);
  
  AssertEquals(4, Arr[0]);
  AssertEquals(5, Arr[1]);
  AssertEquals(1, Arr[2]);
  AssertEquals(2, Arr[3]);
  AssertEquals(3, Arr[4]);
end;

procedure TTestAlgorithms.Test_Rotate_Zero;
var
  Arr: array of Integer;
begin
  Arr := [1, 2, 3, 4, 5];
  specialize RotateLeft<Integer>(Arr, 0);
  
  AssertEquals(1, Arr[0]);
  AssertEquals(2, Arr[1]);
  AssertEquals(3, Arr[2]);
  AssertEquals(4, Arr[3]);
  AssertEquals(5, Arr[4]);
end;

procedure TTestAlgorithms.Test_Rotate_FullRotation;
var
  Arr: array of Integer;
begin
  Arr := [1, 2, 3, 4, 5];
  specialize RotateLeft<Integer>(Arr, 5);
  
  // Full rotation = no change
  AssertEquals(1, Arr[0]);
  AssertEquals(2, Arr[1]);
  AssertEquals(3, Arr[2]);
  AssertEquals(4, Arr[3]);
  AssertEquals(5, Arr[4]);
end;

procedure TTestAlgorithms.Test_Rotate_Empty;
var
  Arr: array of Integer;
begin
  SetLength(Arr, 0);
  specialize RotateLeft<Integer>(Arr, 2);
  AssertEquals(0, Length(Arr));
end;

{ Memory Leak Test }

procedure TTestAlgorithms.Test_LargeScale_NoLeak;
var
  Arr: array of Integer;
  i: Integer;
  Idx: SizeInt;
begin
  SetLength(Arr, 10000);
  for i := 0 to 9999 do
    Arr[i] := Random(10000);
  
  // Sort
  specialize Sort<Integer>(Arr, @IntCompare, nil);
  
  // Verify sorted
  for i := 0 to 9998 do
    AssertTrue('Array should be sorted', Arr[i] <= Arr[i+1]);
  
  // Binary search
  specialize BinarySearch<Integer>(Arr, Arr[5000], @IntCompare, nil, Idx);
  
  // Unique (on sorted array)
  specialize Unique<Integer>(Arr, @IntCompare, nil);
  
  // HeapTrc will report if there are leaks
end;

initialization
  RegisterTest(TTestAlgorithms);

end.
