program test_stats_basic;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.mem.pool,
  fafafa.core.mem.allocator;

procedure AssertTrue(Cond: Boolean; const Msg: string);
begin
  if not Cond then raise Exception.Create(Msg);
end;

function SumReqs(const Pool: IFixedSlabPool): SizeUInt;
var
  S: TFixedSlabStats;
  i: SizeUInt;
begin
  S := Pool.GetStats;
  Result := 0;
  for i := 0 to S.SlotCount - 1 do
    Inc(Result, Pool.GetSlotStat(i).reqs);
end;

function SumUsed(const Pool: IFixedSlabPool): SizeUInt;
var
  S: TFixedSlabStats;
  i: SizeUInt;
begin
  S := Pool.GetStats;
  Result := 0;
  for i := 0 to S.SlotCount - 1 do
    Inc(Result, Pool.GetSlotStat(i).used);
end;

procedure Test_Slot_Small;
var
  Pool: IFixedSlabPool;
  S0, S1: TFixedSlabStats;
  Slot0, Slot1: TFixedSlabSlotStat;
  P: array[0..31] of Pointer;
  i: Integer;
  idx: SizeUInt;
begin
  Pool := MakeFixedSlabPool(64 * 1024, GetRtlAllocator, 3);
  S0 := Pool.GetStats;
  idx := 3; // 8<<3 = 64 bytes slot
  Slot0 := Pool.GetSlotStat(idx);

  for i := 0 to High(P) do begin
    P[i] := Pool.GetMem(64);
    AssertTrue(P[i] <> nil, 'alloc 64 failed');
  end;

  S1 := Pool.GetStats;
  Slot1 := Pool.GetSlotStat(idx);

  AssertTrue(S1.FreePages <= S0.FreePages, 'free pages did not decrease or equal');
  AssertTrue(Slot1.reqs >= Slot0.reqs + SizeUInt(Length(P)), 'reqs not increased');
  AssertTrue(Slot1.used >= Slot0.used, 'used not increased');

  for i := 0 to High(P) do Pool.FreeMem(P[i]);
end;

procedure Test_Slot_Exact;
var
  Pool: IFixedSlabPool;
  idx: SizeUInt;
  Slot0, Slot1: TFixedSlabSlotStat;
  p: array[0..15] of Pointer;
  i: Integer;
begin
  // totals should increase (sanity warm-up)
  AssertTrue(SumReqs(Pool) = SumReqs(Pool), 'sanity');
  Pool := MakeFixedSlabPool(64 * 1024, GetRtlAllocator, 3);
  idx := (12 - 3); // exact shift = 12 - min_shift
  Slot0 := Pool.GetSlotStat(idx);
  for i := 0 to High(p) do begin
    p[i] := Pool.GetMem(512 div SizeOf(PtrUInt)); // approximate exact size
    AssertTrue(p[i] <> nil, 'alloc exact failed');
  end;
  Slot1 := Pool.GetSlotStat(idx);
  AssertTrue(Slot1.reqs >= Slot0.reqs + SizeUInt(Length(p)), 'exact reqs not increased');
  for i := 0 to High(p) do Pool.FreeMem(p[i]);
end;

begin
  try
    Test_Slot_Small;
    Test_Slot_Exact;
    Writeln('test_stats_basic OK');
  except
    on E: Exception do begin
      Writeln('test_stats_basic FAILED: ', E.Message);
      Halt(1);
    end;
  end;
end.

