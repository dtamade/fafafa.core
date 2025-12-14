unit Test_Vec_RetainExtend;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

{**
 * TDD 测试用例: Vec.Retain 和 Vec.Extend
 * 
 * 测试目标:
 * 1. Retain - 保留满足条件的元素
 * 2. Extend - 从迭代器批量插入
 * 3. ExtendFrom - 从集合批量插入
 *}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections.base,
  fafafa.core.collections.vec,
  fafafa.core.collections;

type
  TIntVec = specialize TVec<Integer>;
  IIntVec = specialize IVec<Integer>;

  { TTestVecRetainExtend }
  TTestVecRetainExtend = class(TTestCase)
  private
    class function IsEven(const aElement: Integer; aData: Pointer): Boolean; static;
    class function IsPositive(const aElement: Integer; aData: Pointer): Boolean; static;
    class function IsGreaterThan(const aElement: Integer; aData: Pointer): Boolean; static;
  published
    // === Retain 测试 ===
    procedure Test_Retain_KeepEvenNumbers;
    procedure Test_Retain_KeepAllElements;
    procedure Test_Retain_KeepNoElements;
    procedure Test_Retain_Empty;
    procedure Test_Retain_WithUserData;
    
    // === Append/Extend 测试 (Append 就是 Rust 的 Extend) ===
    procedure Test_Append_FromArray;
    procedure Test_Append_FromCollection;
    procedure Test_Append_EmptySource;
    procedure Test_Append_ToEmpty;
    procedure Test_Append_LargeScale;
  end;

implementation

{ Helper functions }

class function TTestVecRetainExtend.IsEven(const aElement: Integer; aData: Pointer): Boolean;
begin
  Result := (aElement mod 2) = 0;
end;

class function TTestVecRetainExtend.IsPositive(const aElement: Integer; aData: Pointer): Boolean;
begin
  Result := aElement > 0;
end;

class function TTestVecRetainExtend.IsGreaterThan(const aElement: Integer; aData: Pointer): Boolean;
var
  Threshold: PInteger;
begin
  Threshold := PInteger(aData);
  Result := aElement > Threshold^;
end;

{ Retain Tests }

procedure TTestVecRetainExtend.Test_Retain_KeepEvenNumbers;
var
  Vec: IIntVec;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  
  Vec.Retain(@IsEven, nil);
  
  AssertEquals('Count after retain', 5, Vec.Count);
  AssertEquals('Element 0', 2, Vec.Get(0));
  AssertEquals('Element 1', 4, Vec.Get(1));
  AssertEquals('Element 2', 6, Vec.Get(2));
  AssertEquals('Element 3', 8, Vec.Get(3));
  AssertEquals('Element 4', 10, Vec.Get(4));
end;

procedure TTestVecRetainExtend.Test_Retain_KeepAllElements;
var
  Vec: IIntVec;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([2, 4, 6, 8, 10]);
  
  Vec.Retain(@IsEven, nil);
  
  AssertEquals('All elements kept', 5, Vec.Count);
end;

procedure TTestVecRetainExtend.Test_Retain_KeepNoElements;
var
  Vec: IIntVec;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 3, 5, 7, 9]);
  
  Vec.Retain(@IsEven, nil);
  
  AssertEquals('No elements kept', 0, Vec.Count);
end;

procedure TTestVecRetainExtend.Test_Retain_Empty;
var
  Vec: IIntVec;
begin
  Vec := specialize MakeVec<Integer>;
  
  Vec.Retain(@IsEven, nil);
  
  AssertEquals('Empty stays empty', 0, Vec.Count);
end;

procedure TTestVecRetainExtend.Test_Retain_WithUserData;
var
  Vec: IIntVec;
  Threshold: Integer;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 5, 10, 15, 20, 25]);
  
  Threshold := 10;
  Vec.Retain(@IsGreaterThan, @Threshold);
  
  AssertEquals('Count after retain', 3, Vec.Count);
  AssertEquals('Element 0', 15, Vec.Get(0));
  AssertEquals('Element 1', 20, Vec.Get(1));
  AssertEquals('Element 2', 25, Vec.Get(2));
end;

{ Append Tests (Append 等同于 Rust 的 Extend) }

procedure TTestVecRetainExtend.Test_Append_FromArray;
var
  Vec: IIntVec;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3]);
  
  Vec.Append([4, 5, 6]);  // Append 就是 Rust 的 extend
  
  AssertEquals('Count after append', 6, Vec.Count);
  AssertEquals('Element 3', 4, Vec.Get(3));
  AssertEquals('Element 4', 5, Vec.Get(4));
  AssertEquals('Element 5', 6, Vec.Get(5));
end;

procedure TTestVecRetainExtend.Test_Append_FromCollection;
var
  Vec1, Vec2: IIntVec;
begin
  Vec1 := specialize MakeVec<Integer>;
  Vec1.Append([1, 2, 3]);
  
  Vec2 := specialize MakeVec<Integer>;
  Vec2.Append([4, 5, 6]);
  
  Vec1.Append(Vec2 as TIntVec);  // Append 从集合追加
  
  AssertEquals('Count after append', 6, Vec1.Count);
  AssertEquals('Element 3', 4, Vec1.Get(3));
  AssertEquals('Element 4', 5, Vec1.Get(4));
  AssertEquals('Element 5', 6, Vec1.Get(5));
end;

procedure TTestVecRetainExtend.Test_Append_EmptySource;
var
  Vec: IIntVec;
begin
  Vec := specialize MakeVec<Integer>;
  Vec.Append([1, 2, 3]);
  
  Vec.Append([]);  // 追加空数组
  
  AssertEquals('Count unchanged', 3, Vec.Count);
end;

procedure TTestVecRetainExtend.Test_Append_ToEmpty;
var
  Vec: IIntVec;
begin
  Vec := specialize MakeVec<Integer>;
  
  Vec.Append([1, 2, 3]);
  
  AssertEquals('Count after append', 3, Vec.Count);
  AssertEquals('Element 0', 1, Vec.Get(0));
end;

procedure TTestVecRetainExtend.Test_Append_LargeScale;
var
  Vec1, Vec2: IIntVec;
  i: Integer;
begin
  Vec1 := specialize MakeVec<Integer>;
  for i := 0 to 499 do
    Vec1.Push(i);
    
  Vec2 := specialize MakeVec<Integer>;
  for i := 500 to 999 do
    Vec2.Push(i);
  
  Vec1.Append(Vec2 as TIntVec);  // 从另一个 Vec 追加
  
  AssertEquals('Count after append', 1000, Vec1.Count);
  AssertEquals('First element', 0, Vec1.Get(0));
  AssertEquals('Element 500', 500, Vec1.Get(500));
  AssertEquals('Last element', 999, Vec1.Get(999));
end;

initialization
  RegisterTest(TTestVecRetainExtend);

end.
