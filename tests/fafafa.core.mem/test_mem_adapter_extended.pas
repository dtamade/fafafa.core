{
  Extended tests for fafafa.core.mem.adapter

  Focus: Realloc paths when wrapping IAlloc implementations that need the
  old allocation size (e.g., TAlignedAlloc which falls back to TAllocBase
  default DoRealloc).
}
unit test_mem_adapter_extended;

{$mode objfpc}{$H+}

interface

procedure RunAllTests;

implementation

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.mem.alloc,
  fafafa.core.mem.adapter,
  fafafa.core.mem.layout;

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

procedure Test_AllocToAllocator_ReallocMem_PreservesData_WithAlignedAlloc;
var
  Aligned: IAlloc;
  Adapter: IAllocator;
  P: PByte;
  I: Integer;
begin
  WriteLn('=== Test_AllocToAllocator_ReallocMem_PreservesData_WithAlignedAlloc ===');

  Aligned := TAlignedAlloc.Create;
  Adapter := WrapAsAllocator(Aligned);

  // initial alloc
  P := Adapter.GetMem(64);
  Check(P <> nil, 'Initial GetMem succeeds');

  // fill pattern
  for I := 0 to 63 do
    P[I] := I;

  // realloc to bigger size
  P := Adapter.ReallocMem(P, 128);
  Check(P <> nil, 'ReallocMem succeeds');

  // verify pattern retained
  for I := 0 to 63 do
    Check(P[I] = I, Format('Byte %d preserved after realloc', [I]));

  Adapter.FreeMem(P);
end;

procedure RunAllTests;
begin
  WriteLn('');
  WriteLn('========================================');
  WriteLn('  Memory Adapter Extended Test Suite');
  WriteLn('========================================');
  WriteLn('');

  Test_AllocToAllocator_ReallocMem_PreservesData_WithAlignedAlloc;

  WriteLn('');
  WriteLn('========================================');
  WriteLn(Format('  Results: %d/%d passed', [PassCount, TestCount]));
  WriteLn('========================================');

  if PassCount < TestCount then
    Halt(1);
end;

end.
