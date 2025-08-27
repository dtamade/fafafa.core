program test_capacity_pushfront_simple;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.collections.vecdeque;

type
  TIntDeque = specialize TVecDeque<Integer>;

var
  dq: TIntDeque;
  i: SizeUInt;
  capAfter: SizeUInt;
  ok: Boolean;
  arr: array[0..7] of Integer = (101,102,103,104,105,106,107,108);
begin
  ok := True;
  dq := TIntDeque.Create;
  try
    // ShrinkToFitExact should fit to NextPowerOfTwo(Max(Count,16))
    // Fill 10 items => expected capacity after ShrinkToFitExact is 16
    for i := 1 to 10 do dq.PushBack(i);
    dq.ShrinkToFitExact;
    capAfter := dq.GetCapacity;
    if capAfter <> 16 then
    begin
      Writeln('FAIL: ShrinkToFitExact expected capacity 16, got ', capAfter);
      Halt(1);
    end;

    // Validate PushFront batch that crosses the buffer boundary keeps order
    dq.ClearAndReserve(16);
    // push 12 items to back so head=0, tail=12
    for i := 1 to 12 do dq.PushBack(i);
    // now PushFront 8 elements; since head=0 and count=12, this will wrap and use split path
    dq.PushFront(arr);

    if dq.Count <> 20 then
    begin
      Writeln('FAIL: Count expected 20, got ', dq.Count);
      Halt(1);
    end;

    // Check front segment equals arr in-order
    for i := 0 to 7 do
      if dq.Get(i) <> 101 + i then
      begin
        Writeln('FAIL: Front segment mismatch at ', i, ' got ', dq.Get(i));
        Halt(1);
      end;

    // Check following segment remains 1..12
    for i := 0 to 11 do
      if dq.Get(8 + i) <> (i + 1) then
      begin
        Writeln('FAIL: Back segment mismatch at ', i, ' got ', dq.Get(8 + i));
        Halt(1);
      end;
  finally
    dq.Free;
  end;
  Writeln('OK');
end.

