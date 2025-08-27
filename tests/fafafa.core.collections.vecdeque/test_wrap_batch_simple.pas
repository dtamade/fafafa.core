program test_wrap_batch_simple;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.vecdeque;

procedure Check(const Title: string; Cond: Boolean; var Fail: Integer);
begin
  if not Cond then
  begin
    WriteLn('[FAIL] ', Title);
    Inc(Fail);
  end;
end;

procedure Test_Wraparound_SmallCapacity2_Back(var Fail: Integer);
var
  D: specialize TVecDeque<Integer>;
  i, v: Integer;
begin
  D := specialize TVecDeque<Integer>.Create(2);
  try
    for i := 1 to 10 do
    begin
      D.PushBack(i);
      Check('back after push', D.Back = i, Fail);
      if i mod 2 = 0 then
      begin
        v := D.PopFront; Check('pop front returns previous', v = i-1, Fail);
        v := D.PopBack;  Check('pop back returns current',   v = i,   Fail);
        Check('empty after two pops', D.IsEmpty, Fail);
      end;
    end;
  finally
    D.Free;
  end;
end;

procedure Test_Wraparound_SmallCapacity2_Front(var Fail: Integer);
var
  D: specialize TVecDeque<Integer>;
  i, v: Integer;
begin
  D := specialize TVecDeque<Integer>.Create(2);
  try
    for i := 1 to 6 do
    begin
      D.PushFront(i);
      Check('front equals pushed', D.Front = i, Fail);
      if i mod 2 = 0 then
      begin
        v := D.PopBack;  Check('pop back returns previous', v = i-1, Fail);
        v := D.PopFront; Check('pop front returns current', v = i,   Fail);
        Check('empty after two pops', D.IsEmpty, Fail);
      end;
    end;
  finally
    D.Free;
  end;
end;

procedure Test_Batch_PushFront_CrossBoundary(var Fail: Integer);
var
  D: specialize TVecDeque<Integer>;
  Cap, i: SizeUInt;
  Batch: array of Integer;
begin
  D := specialize TVecDeque<Integer>.Create;
  try
    Cap := D.Capacity;
    D.PushBack(100);
    D.PushBack(200);
    // avoid Math.Max; compute inline to keep unit-free
    if Cap div 2 < 2 then
      SetLength(Batch, 2)
    else
      SetLength(Batch, {%H-}SizeInt(Cap div 2));
    for i := 0 to High(Batch) do Batch[i] := 1000 + i;
    D.PushFront(Batch);

    for i := 0 to High(Batch) do
      Check('PushFront cross-boundary keeps order', D.Get(i) = 1000 + i, Fail);
    Check('Existing element follows #1', D.Get(Length(Batch)) = 100, Fail);
    Check('Existing element follows #2', D.Get(Length(Batch)+1) = 200, Fail);
  finally
    D.Free;
  end;
end;

procedure Test_Batch_PushBack_CrossBoundary(var Fail: Integer);
var
  D: specialize TVecDeque<Integer>;
  Cap, i: SizeUInt;
  Batch: array of Integer;
  Cnt: SizeUInt;
begin
  D := specialize TVecDeque<Integer>.Create;
  try
    Cap := D.Capacity;
    if Cap > 2 then
      for i := 1 to Cap - 2 do D.PushBack(i);

    SetLength(Batch, 5);
    for i := 0 to High(Batch) do Batch[i] := 2000 + i;
    D.PushBack(Batch);

    Cnt := D.Count;
    Check('batch[0]', D.Get(Cnt - 5) = 2000, Fail);
    Check('batch[1]', D.Get(Cnt - 4) = 2001, Fail);
    Check('batch[2]', D.Get(Cnt - 3) = 2002, Fail);
    Check('batch[3]', D.Get(Cnt - 2) = 2003, Fail);
    Check('batch[4]', D.Get(Cnt - 1) = 2004, Fail);
  finally
    D.Free;
  end;
end;

procedure Run;
var
  Fail: Integer = 0;
begin
  WriteLn('=== wrap+batch simple tests ===');
  Test_Wraparound_SmallCapacity2_Back(Fail);
  Test_Wraparound_SmallCapacity2_Front(Fail);
  Test_Batch_PushFront_CrossBoundary(Fail);
  Test_Batch_PushBack_CrossBoundary(Fail);
  if Fail = 0 then
  begin
    WriteLn('[PASS] wrap+batch simple passed');
    Halt(0);
  end
  else
  begin
    WriteLn('[FAIL] wrap+batch simple failed, count=', Fail);
    Halt(1);
  end;
end;

begin
  Run;
end.

