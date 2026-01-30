unit Test_vecdeque_span;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.collections.base,
  fafafa.core.collections.vecdeque,
  fafafa.core.collections.slice,
  fafafa.core.mem.utils,
  fafafa.core.mem.allocator;

type
  TTestCase_VecDeque_Span = class(TTestCase)
  published
    procedure Test_SliceView_Empty;
    procedure Test_MakeContiguous_FromWrap;
    procedure Test_SliceView_TailSingle;
    procedure Test_SliceView_TwoSegments;
    procedure Test_SliceView_SubSpan2;
    procedure Test_MakeContiguous_Idempotent;
    procedure Test_SliceView_GetBlock;
    // 新增边界用例：SubSpan 空段、A 段内、跨 A->B、B 段内；GetBlock 边界
    procedure Test_SliceView_SubSpan_Empty;
    procedure Test_SliceView_SubSpan_InA;
    procedure Test_SliceView_SubSpan_CrossAB;
    procedure Test_SliceView_SubSpan_InB;
    procedure Test_SliceView_GetBlock_Boundaries;
  end;

implementation

procedure TTestCase_VecDeque_Span.Test_SliceView_Empty;
var
  D: specialize TVecDeque<Integer>;
  S: specialize TReadOnlySpan2<Integer>;
begin
  D := specialize TVecDeque<Integer>.Create;
  try
    S := D.SliceView(0, 0);
    AssertTrue(S.IsEmpty);
    AssertEquals(SizeUInt(0), S.Count);
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Span.Test_SliceView_TailSingle;
var
  D: specialize TVecDeque<Integer>;
  S: specialize TReadOnlySpan2<Integer>;
begin
  D := specialize TVecDeque<Integer>.Create;
  try
    D.Append([7,8,9]);
    S := D.SliceView(2, 1);
    AssertEquals(SizeUInt(1), S.Count);
    AssertEquals(9, S.Get(0));
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Span.Test_SliceView_TwoSegments;
var
  D: specialize TVecDeque<Integer>;
  S2: specialize TReadOnlySpan2<Integer>;
  i: SizeUInt;
begin
  D := specialize TVecDeque<Integer>.Create;
  try
    D.ReserveExact(8);
    D.Append([0,1,2,3,4]);    // [0..4]
    D.PopFront; D.PopFront;    // [2,3,4]
    D.Append([5,6,7,8,9]);     // wrap, logical [2..9]

    S2 := D.SliceView(0, D.GetCount);
    AssertEquals(SizeUInt(8), S2.Count);

    // 验证顺序
    for i := 0 to S2.Count-1 do
      AssertEquals(2 + Integer(i), S2.Get(i));
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Span.Test_SliceView_SubSpan2;
var
  D: specialize TVecDeque<Integer>;
  S2, Sub: specialize TReadOnlySpan2<Integer>;
begin
  D := specialize TVecDeque<Integer>.Create;
  try
    D.ReserveExact(8);
    D.Append([0,1,2,3,4]);
    D.PopFront; D.PopFront;
    D.Append([5,6,7,8,9]);

    S2 := D.SliceView(0, D.GetCount);
    Sub := S2.SubSpan(1, 6);
    AssertEquals(SizeUInt(6), Sub.Count);
    AssertEquals(3, Sub.Get(0));
    AssertEquals(8, Sub.Get(5));
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Span.Test_SliceView_GetBlock;
var
  D: specialize TVecDeque<Integer>;
  S2: specialize TReadOnlySpan2<Integer>;
  p: Pointer; len: SizeUInt;
  v: Integer;
begin
  D := specialize TVecDeque<Integer>.Create;
  try
    D.ReserveExact(8);
    D.Append([0,1,2,3,4]);
    D.PopFront; D.PopFront; // [2,3,4]
    D.Append([5,6,7,8,9]);

    S2 := D.SliceView(0, D.GetCount);

    // 从索引2开始块（可能在 A 段尾或 B 段头）
    AssertTrue(S2.GetBlock(2, p, len));
    AssertTrue(len > 0);
    v := PInteger(p)^;
    AssertEquals(4, v);
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Span.Test_MakeContiguous_FromWrap;
var
  D: specialize TVecDeque<Integer>;
  p1, p2: Pointer; l1, l2: SizeUInt;
  i: Integer;
begin
  D := specialize TVecDeque<Integer>.Create;
  try
    D.ReserveExact(8);
    D.Append([1,2,3,4]);
    D.PopFront; D.PopFront; // [3,4]
    D.Append([5,6,7,8,9,10]); // wrap -> logical [3..10]

    // Before make contiguous, AsSlices2 应返回两段
    D.AsSlices(p1, l1, p2, l2);
    AssertTrue(l1 > 0);
    AssertTrue(l2 > 0);
    AssertEquals(SizeUInt(D.GetCount), l1 + l2);

    // MakeContiguous 后应只有一段且内容按逻辑顺序连续
    D.MakeContiguous;
    D.AsSlices(p1, l1, p2, l2);
    AssertEquals(SizeUInt(D.GetCount), l1);
    AssertEquals(SizeUInt(0), l2);
    for i := 0 to D.GetCount - 1 do
      AssertEquals(3 + i, PInteger(fafafa.core.mem.utils.AddPtr(p1, i*SizeUInt(SizeOf(Integer))))^);
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Span.Test_MakeContiguous_Idempotent;
var
  D: specialize TVecDeque<Integer>;
  p1, p2: Pointer; l1, l2: SizeUInt;
  i: Integer;
begin
  D := specialize TVecDeque<Integer>.Create;
  try
    // 已经连续的情况下 MakeContiguous 不应改变数据/布局
    D.Append([1,2,3,4]);
    D.AsSlices(p1,l1,p2,l2);
    AssertTrue(l2 = 0);
    D.MakeContiguous;
    D.AsSlices(p1,l1,p2,l2);
    AssertTrue(l2 = 0);
    for i := 0 to D.GetCount-1 do AssertEquals(1+i, PInteger(fafafa.core.mem.utils.AddPtr(p1, i*SizeOf(Integer)))^);
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Span.Test_SliceView_SubSpan_Empty;
var
  D: specialize TVecDeque<Integer>;
  S2, Sub: specialize TReadOnlySpan2<Integer>;
begin
  D := specialize TVecDeque<Integer>.Create;
  try
    D.Append([1,2,3]);
    S2 := D.SliceView(0, D.GetCount);
    Sub := S2.SubSpan(1, 0);
    AssertTrue(Sub.IsEmpty);
    AssertEquals(SizeUInt(0), Sub.Count);
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Span.Test_SliceView_SubSpan_InA;
var
  D: specialize TVecDeque<Integer>;
  S2, Sub: specialize TReadOnlySpan2<Integer>;
  p1, p2: Pointer; l1, l2: SizeUInt;
  i: SizeUInt;
begin
  D := specialize TVecDeque<Integer>.Create;
  try
    D.ReserveExact(8);
    D.Append([0,1,2,3,4]);
    D.PopFront; D.PopFront; // [2,3,4]
    D.Append([5,6,7,8,9]);  // wrap
    D.AsSlices(p1,l1,p2,l2);
    AssertTrue((l1>0) and (l2>0));
    S2 := D.SliceView(0, D.GetCount);
    // 取落在 A 段内的子段（最多取2个）
    if l1 > 1 then Sub := S2.SubSpan(0, 2) else Sub := S2.SubSpan(0, 1);
    for i := 0 to Sub.Count-1 do
      AssertEquals(D.Get(Integer(i)), Sub.Get(i));
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Span.Test_SliceView_SubSpan_CrossAB;
var
  D: specialize TVecDeque<Integer>;
  S2, Sub: specialize TReadOnlySpan2<Integer>;
  p1, p2: Pointer; l1, l2: SizeUInt;
  i, start, len: SizeUInt;
begin
  D := specialize TVecDeque<Integer>.Create;
  try
    D.ReserveExact(8);
    D.Append([0,1,2,3,4]);
    D.PopFront; D.PopFront; // [2,3,4]
    D.Append([5,6,7,8,9]);  // wrap
    D.AsSlices(p1,l1,p2,l2);
    AssertTrue((l1>0) and (l2>0));
    S2 := D.SliceView(0, D.GetCount);
    // 从 A 段末尾往后跨到 B 段
    if l1>0 then start := l1-1 else start := 0;
    if S2.Count - start >= 3 then len := 3 else len := S2.Count - start;
    Sub := S2.SubSpan(start, len);
    for i := 0 to Sub.Count-1 do
      AssertEquals(D.Get(Integer(start + i)), Sub.Get(i));
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Span.Test_SliceView_SubSpan_InB;
var
  D: specialize TVecDeque<Integer>;
  S2, Sub: specialize TReadOnlySpan2<Integer>;
  p1, p2: Pointer; l1, l2: SizeUInt;
  i, start, len: SizeUInt;
begin
  D := specialize TVecDeque<Integer>.Create;
  try
    D.ReserveExact(8);
    D.Append([0,1,2,3,4]);
    D.PopFront; D.PopFront; // [2,3,4]
    D.Append([5,6,7,8,9]);  // wrap
    D.AsSlices(p1,l1,p2,l2);
    AssertTrue((l1>0) and (l2>0));
    S2 := D.SliceView(0, D.GetCount);
    start := l1;
    if l2 >= 2 then len := 2 else len := 1;
    Sub := S2.SubSpan(start, len);
    for i := 0 to Sub.Count-1 do
      AssertEquals(D.Get(Integer(start + i)), Sub.Get(i));
  finally
    D.Free;
  end;
end;

procedure TTestCase_VecDeque_Span.Test_SliceView_GetBlock_Boundaries;
var
  D: specialize TVecDeque<Integer>;
  S2: specialize TReadOnlySpan2<Integer>;
  p1, p2, p: Pointer; l1, l2, len: SizeUInt;
  v: Integer;
begin
  D := specialize TVecDeque<Integer>.Create;
  try
    D.ReserveExact(8);
    D.Append([0,1,2,3,4]);
    D.PopFront; D.PopFront; // [2,3,4]
    D.Append([5,6,7,8,9]);  // wrap
    D.AsSlices(p1,l1,p2,l2);
    AssertTrue((l1>0) and (l2>0));
    S2 := D.SliceView(0, D.GetCount);
    // A 段末尾
    AssertTrue(S2.GetBlock(l1-1, p, len));
    v := PInteger(p)^; AssertEquals(D.Get(Integer(l1-1)), v);
    AssertTrue(len >= 1);
    // B 段起点
    AssertTrue(S2.GetBlock(l1, p, len));
    v := PInteger(p)^; AssertEquals(D.Get(Integer(l1)), v);
    AssertTrue(len >= 1);
  finally
    D.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_VecDeque_Span);

end.
