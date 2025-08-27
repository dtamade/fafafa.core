program fixed_slab_smoke_test;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.mem.pool,
  fafafa.core.mem.allocator;

procedure AssertTrue(Cond: Boolean; const Msg: string);
begin
  if not Cond then raise Exception.Create(Msg);
end;

procedure AssertEqual(A, B: SizeUInt; const Msg: string);
begin
  if A <> B then raise Exception.Create(Msg + Format(' (got=%d, expect=%d)', [A, B]));
end;

procedure Test_Basic;
var
  Pool: IFixedSlabPool;
  A, B, C: Pointer;
  i: Integer;
  cap: SizeUInt;
begin
  Pool := MakeFixedSlabPool(64 * 1024, GetRtlAllocator, 3);
  cap := Pool.Capacity;
  AssertTrue(cap >= 64*1024, 'capacity too small');

  A := Pool.GetMem(64);
  AssertTrue(A <> nil, 'GetMem(64) failed');
  FillByte(A^, 64, 1);

  B := Pool.ReallocMem(A, 128);
  AssertTrue(B <> nil, 'Realloc grow failed');
  // first 64 bytes kept
  for i := 0 to 63 do AssertTrue(PByte(B)[i] = 1, 'Data not preserved on grow');

  C := Pool.ReallocMem(B, 32);
  AssertTrue(C <> nil, 'Realloc shrink failed');
  for i := 0 to 31 do AssertTrue(PByte(C)[i] = 1, 'Data not preserved on shrink');

  Pool.FreeMem(C);
  Pool.Reset; // should not crash
end;

procedure Test_Exhaust_Reset;
const
  N = 8192; // attempt many tiny allocations
var
  Pool: IFixedSlabPool;
  P: array[0..N-1] of Pointer;
  i, count: Integer;
begin
  Pool := MakeFixedSlabPool(64 * 1024, GetRtlAllocator, 3);
  FillChar(P, SizeOf(P), 0);
  count := 0;
  for i := 0 to N-1 do begin
    P[i] := Pool.GetMem(8);
    if P[i] <> nil then Inc(count) else Break;
  end;
  AssertTrue(count > 0, 'no allocations succeeded');
  // free them
  while (count > 0) do begin
    Dec(count);
    Pool.FreeMem(P[count]);
  end;
  // after reset should work again
  Pool.Reset;
  AssertTrue(Pool.GetMem(8) <> nil, 'alloc after reset failed');
end;

procedure Test_Random_Fuzz;
const
  SLOTS = 4096;
var
  Pool: IFixedSlabPool;
  Arr: array[0..SLOTS-1] of Pointer;
  Sz: array[0..SLOTS-1] of SizeUInt;
  i, iters, idx: Integer;
  p: Pointer;
  s: SizeUInt;
begin
  Randomize;
  Pool := MakeFixedSlabPool(256 * 1024, GetRtlAllocator, 3);
  FillChar(Arr, SizeOf(Arr), 0);
  FillChar(Sz, SizeOf(Sz), 0);
  iters := 20000;
  for i := 1 to iters do begin
    idx := Random(SLOTS);
    try
      if (Arr[idx] <> nil) and (Random(2) = 0) then begin
        Pool.FreeMem(Arr[idx]);
        Arr[idx] := nil;
        Sz[idx] := 0;
      end else begin
        s := 1 + Random(4096); // up to one page
        p := Pool.GetMem(s);
        // replace existing
        if Arr[idx] <> nil then Pool.FreeMem(Arr[idx]);
        Arr[idx] := p;
        Sz[idx] := s;
        if p <> nil then begin
          // minimal alignment expectation: 8-byte
          AssertTrue((PtrUInt(p) and 7) = 0, 'alignment < 8 bytes');
        end;
      end;
    except
      on E: Exception do begin
        Writeln(Format('Fuzz crash at iter=%d idx=%d size=%d ptr=%p: %s', [i, idx, s, p, E.Message]));
        raise;
      end;
    end;
    if (i mod 2000)=0 then Writeln('...fuzz iter ', i);
  end;
  // cleanup
  for i := 0 to SLOTS-1 do if Arr[i] <> nil then Pool.FreeMem(Arr[i]);
end;

procedure Test_Big_MultiPage;
var
  Pool: IFixedSlabPool;
  P: Pointer;
begin
  Pool := MakeFixedSlabPool(256 * 1024, GetRtlAllocator, 3);
  // allocate > 4096 to ensure multi-page path
  P := Pool.GetMem(8192 + 128);
  AssertTrue(P <> nil, 'big alloc failed');
  // page alignment expectation
  AssertTrue((PtrUInt(P) and (4096-1)) = 0, 'big alloc not page-aligned');
  Pool.FreeMem(P);
end;

procedure Test_InvalidFree_NoCrash;
var
  Pool: IFixedSlabPool;
  X: Pointer;
begin
  Pool := MakeFixedSlabPool(64 * 1024, GetRtlAllocator, 3);
  X := @Pool; // stack-ish foreign ptr
  // should be ignored by range check and not crash
  Pool.FreeMem(nil);
  Pool.FreeMem(X);
end;

begin
  try
    Writeln('RUN Test_Basic');
    Test_Basic;
    Writeln('OK  Test_Basic');

    Writeln('RUN Test_Exhaust_Reset');
    Test_Exhaust_Reset;
    Writeln('OK  Test_Exhaust_Reset');

    Writeln('RUN Test_Random_Fuzz');
    Test_Random_Fuzz;
    Writeln('OK  Test_Random_Fuzz');

    Writeln('RUN Test_Big_MultiPage');
    Test_Big_MultiPage;
    Writeln('OK  Test_Big_MultiPage');

    Writeln('RUN Test_InvalidFree_NoCrash');
    Test_InvalidFree_NoCrash;
    Writeln('OK  Test_InvalidFree_NoCrash');

    Writeln('fixed_slab_smoke_test OK');
  except
    on E: Exception do begin
      Writeln('fixed_slab_smoke_test FAILED: ', E.Message);
      Halt(1);
    end;
  end;
end.

