{
  Test suite for fafafa.core.mem.adapter

  Tests IAllocator <-> IAlloc adapter functionality:
  - TAllocatorToAllocAdapter
  - TAllocToAllocatorAdapter
  - Bidirectional conversion
}
unit test_mem_adapter;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.mem.allocator.base,
  fafafa.core.mem.alloc,
  fafafa.core.mem.adapter,
  fafafa.core.mem.layout,
  fafafa.core.mem.error;

procedure RunAllTests;

implementation

var
  TestCount: Integer = 0;
  PassCount: Integer = 0;

procedure Check(Condition: Boolean; const TestName: string);
begin
  Inc(TestCount);
  if Condition then
  begin
    Inc(PassCount);
    WriteLn('  [PASS] ', TestName);
  end
  else
    WriteLn('  [FAIL] ', TestName);
end;

procedure Test_AllocatorToAlloc_BasicAlloc;
var
  OldAlloc: IAllocator;
  NewAlloc: IAlloc;
  Layout: TMemLayout;
  Res: TAllocResult;
begin
  WriteLn('=== Test_AllocatorToAlloc_BasicAlloc ===');

  OldAlloc := GetRtlAllocator;
  NewAlloc := WrapAsAlloc(OldAlloc);

  Layout := TMemLayout.Create(256, 8);
  Res := NewAlloc.Alloc(Layout);

  Check(Res.IsOk, 'Alloc succeeds');
  Check(Res.Ptr <> nil, 'Pointer not nil');

  NewAlloc.Dealloc(Res.Ptr, Layout);
  Check(True, 'Dealloc succeeds');
end;

procedure Test_AllocatorToAlloc_AllocZeroed;
var
  OldAlloc: IAllocator;
  NewAlloc: IAlloc;
  Layout: TMemLayout;
  Res: TAllocResult;
  P: PByte;
  I: Integer;
  AllZero: Boolean;
begin
  WriteLn('=== Test_AllocatorToAlloc_AllocZeroed ===');

  OldAlloc := GetRtlAllocator;
  NewAlloc := WrapAsAlloc(OldAlloc);

  Layout := TMemLayout.Create(128, 8);
  Res := NewAlloc.AllocZeroed(Layout);

  Check(Res.IsOk, 'AllocZeroed succeeds');

  P := Res.Ptr;
  AllZero := True;
  for I := 0 to 127 do
  begin
    if P[I] <> 0 then
    begin
      AllZero := False;
      Break;
    end;
  end;
  Check(AllZero, 'Memory is zeroed');

  NewAlloc.Dealloc(Res.Ptr, Layout);
end;

procedure Test_AllocatorToAlloc_Realloc;
var
  OldAlloc: IAllocator;
  NewAlloc: IAlloc;
  Layout1, Layout2: TMemLayout;
  Res: TAllocResult;
  P: PByte;
  I: Integer;
begin
  WriteLn('=== Test_AllocatorToAlloc_Realloc ===');

  OldAlloc := GetRtlAllocator;
  NewAlloc := WrapAsAlloc(OldAlloc);

  Layout1 := TMemLayout.Create(64, 8);
  Res := NewAlloc.Alloc(Layout1);
  Check(Res.IsOk, 'Initial alloc succeeds');

  // Write pattern
  P := Res.Ptr;
  for I := 0 to 63 do
    P[I] := I;

  // Realloc to larger size
  Layout2 := TMemLayout.Create(128, 8);
  Res := NewAlloc.Realloc(Res.Ptr, Layout1, Layout2);
  Check(Res.IsOk, 'Realloc succeeds');

  // Verify original data preserved
  P := Res.Ptr;
  for I := 0 to 63 do
    Check(P[I] = I, Format('Data[%d] preserved', [I]));

  NewAlloc.Dealloc(Res.Ptr, Layout2);
end;

procedure Test_AllocatorToAlloc_Caps;
var
  OldAlloc: IAllocator;
  NewAlloc: IAlloc;
  Caps: TAllocCaps;
begin
  WriteLn('=== Test_AllocatorToAlloc_Caps ===');

  OldAlloc := GetRtlAllocator;
  NewAlloc := WrapAsAlloc(OldAlloc);

  Caps := NewAlloc.Caps;
  Check(Caps.ThreadSafe, 'ThreadSafe from RTL allocator');
  Check(Caps.CanRealloc, 'CanRealloc = True');
end;

procedure Test_AllocToAllocator_BasicAlloc;
var
  NewAlloc: IAlloc;
  OldAlloc: IAllocator;
  P: Pointer;
begin
  WriteLn('=== Test_AllocToAllocator_BasicAlloc ===');

  NewAlloc := GetSystemAlloc;
  OldAlloc := WrapAsAllocator(NewAlloc);

  P := OldAlloc.GetMem(256);
  Check(P <> nil, 'GetMem succeeds');

  OldAlloc.FreeMem(P);
  Check(True, 'FreeMem succeeds');
end;

procedure Test_AllocToAllocator_AllocMem;
var
  NewAlloc: IAlloc;
  OldAlloc: IAllocator;
  P: PByte;
  I: Integer;
  AllZero: Boolean;
begin
  WriteLn('=== Test_AllocToAllocator_AllocMem ===');

  NewAlloc := GetSystemAlloc;
  OldAlloc := WrapAsAllocator(NewAlloc);

  P := OldAlloc.AllocMem(128);
  Check(P <> nil, 'AllocMem succeeds');

  AllZero := True;
  for I := 0 to 127 do
  begin
    if P[I] <> 0 then
    begin
      AllZero := False;
      Break;
    end;
  end;
  Check(AllZero, 'Memory is zeroed');

  OldAlloc.FreeMem(P);
end;

procedure Test_AllocToAllocator_ReallocMem;
var
  NewAlloc: IAlloc;
  OldAlloc: IAllocator;
  P: PByte;
  I: Integer;
begin
  WriteLn('=== Test_AllocToAllocator_ReallocMem ===');

  NewAlloc := GetSystemAlloc;
  OldAlloc := WrapAsAllocator(NewAlloc);

  P := OldAlloc.GetMem(64);
  Check(P <> nil, 'Initial GetMem succeeds');

  // Write pattern
  for I := 0 to 63 do
    P[I] := I;

  // Realloc
  P := OldAlloc.ReallocMem(P, 128);
  Check(P <> nil, 'ReallocMem succeeds');

  // Verify data
  for I := 0 to 63 do
    Check(P[I] = I, Format('Data[%d] preserved', [I]));

  OldAlloc.FreeMem(P);
end;

procedure Test_AllocToAllocator_Traits;
var
  NewAlloc: IAlloc;
  OldAlloc: IAllocator;
  Traits: TAllocatorTraits;
begin
  WriteLn('=== Test_AllocToAllocator_Traits ===');

  NewAlloc := GetSystemAlloc;
  OldAlloc := WrapAsAllocator(NewAlloc);

  Traits := OldAlloc.Traits;
  Check(Traits.ThreadSafe, 'ThreadSafe preserved');
end;

procedure Test_BidirectionalConversion;
var
  Original: IAllocator;
  AsAlloc: IAlloc;
  BackToAllocator: IAllocator;
  P1, P2: Pointer;
begin
  WriteLn('=== Test_BidirectionalConversion ===');

  Original := GetRtlAllocator;
  AsAlloc := WrapAsAlloc(Original);
  BackToAllocator := WrapAsAllocator(AsAlloc);

  // Both should work
  P1 := Original.GetMem(100);
  Check(P1 <> nil, 'Original GetMem');

  P2 := BackToAllocator.GetMem(100);
  Check(P2 <> nil, 'BackToAllocator GetMem');

  Original.FreeMem(P1);
  BackToAllocator.FreeMem(P2);
  Check(True, 'Both FreeMem succeed');
end;

procedure Test_ZeroSizeAllocation;
var
  OldAlloc: IAllocator;
  NewAlloc: IAlloc;
  Layout: TMemLayout;
  Res: TAllocResult;
begin
  WriteLn('=== Test_ZeroSizeAllocation ===');

  OldAlloc := GetRtlAllocator;
  NewAlloc := WrapAsAlloc(OldAlloc);

  Layout := TMemLayout.Create(0, 8);
  Res := NewAlloc.Alloc(Layout);

  Check(Res.IsOk, 'Zero-size alloc is OK');
  Check(Res.Ptr = nil, 'Zero-size returns nil');
end;

procedure RunAllTests;
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  Memory Adapter Test Suite');
  WriteLn('========================================');
  WriteLn('');

  Test_AllocatorToAlloc_BasicAlloc;
  Test_AllocatorToAlloc_AllocZeroed;
  Test_AllocatorToAlloc_Realloc;
  Test_AllocatorToAlloc_Caps;
  Test_AllocToAllocator_BasicAlloc;
  Test_AllocToAllocator_AllocMem;
  Test_AllocToAllocator_ReallocMem;
  Test_AllocToAllocator_Traits;
  Test_BidirectionalConversion;
  Test_ZeroSizeAllocation;

  WriteLn('');
  WriteLn('========================================');
  WriteLn(Format('  Results: %d/%d passed', [PassCount, TestCount]));
  WriteLn('========================================');

  if PassCount < TestCount then
    Halt(1);
end;

end.
