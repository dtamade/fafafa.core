{$mode objfpc}{$H+}
program test_bitset_leak;

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.collections.bitset;

procedure Test1_BasicOps;
var
  BS: TBitSet;
begin
  WriteLn('[Test 1] Basic operations');
  BS := TBitSet.Create;
  try
    BS.SetBit(0);
    BS.SetBit(5);
    BS.SetBit(10);
    WriteLn('  Pass: Bit 5 is set = ', BS.Test(5));
    BS.ClearBit(5);
    WriteLn('  Pass: Bit 5 after clear = ', BS.Test(5));
    WriteLn('  Pass: Cardinality = ', BS.Cardinality);
  finally
    BS.Free;
  end;
end;

procedure Test2_BitwiseOps;
var
  BS1, BS2: TBitSet;
  BSResult: IBitSet;  // 使用接口类型，自动管理内存
begin
  WriteLn('[Test 2] Bitwise operations (AND/OR/XOR/NOT)');
  BS1 := TBitSet.Create;
  BS2 := TBitSet.Create;
  try
    // BS1: bits 0,1,2,3
    BS1.SetBit(0);
    BS1.SetBit(1);
    BS1.SetBit(2);
    BS1.SetBit(3);

    // BS2: bits 2,3,4,5
    BS2.SetBit(2);
    BS2.SetBit(3);
    BS2.SetBit(4);
    BS2.SetBit(5);

    // AND: should be bits 2,3
    BSResult := BS1.AndWith(BS2);
    WriteLn('  Pass: AND cardinality = ', BSResult.Cardinality);

    // OR: should be bits 0,1,2,3,4,5
    BSResult := BS1.OrWith(BS2);
    WriteLn('  Pass: OR cardinality = ', BSResult.Cardinality);

    // XOR: should be bits 0,1,4,5
    BSResult := BS1.XorWith(BS2);
    WriteLn('  Pass: XOR cardinality = ', BSResult.Cardinality);

    // NOT
    BSResult := BS1.NotBits;
    WriteLn('  Pass: NOT operation completed');
  finally
    BS2.Free;
    BS1.Free;
  end;
end;

procedure Test3_SetAllClearAll;
var
  BS: TBitSet;
begin
  WriteLn('[Test 3] SetAll/ClearAll operations');
  BS := TBitSet.Create(100);  // Initial capacity 100 bits
  try
    BS.SetAll;
    WriteLn('  Pass: After SetAll, cardinality = ', BS.Cardinality);
    BS.ClearAll;
    WriteLn('  Pass: After ClearAll, cardinality = ', BS.Cardinality);
  finally
    BS.Free;
  end;
end;

procedure Test4_DynamicGrowth;
var
  BS: TBitSet;
  I: Integer;
begin
  WriteLn('[Test 4] Dynamic growth');
  BS := TBitSet.Create;
  try
    // Set bits at various positions to trigger growth
    BS.SetBit(10);
    BS.SetBit(100);
    BS.SetBit(1000);
    BS.SetBit(5000);
    WriteLn('  Pass: BitCapacity after growth = ', BS.BitCapacity);
    WriteLn('  Pass: Cardinality = ', BS.Cardinality);
  finally
    BS.Free;
  end;
end;

procedure Test5_StressTest;
var
  BS: TBitSet;
  I: Integer;
begin
  WriteLn('[Test 5] Stress test (10000 bits)');
  BS := TBitSet.Create;
  try
    // Set 5000 even bits
    for I := 0 to 9999 do
      if (I mod 2 = 0) then
        BS.SetBit(I);
    WriteLn('  Pass: Set 5000 bits, cardinality = ', BS.Cardinality);

    // Flip all bits
    for I := 0 to 9999 do
      BS.Flip(I);
    WriteLn('  Pass: After flip, cardinality = ', BS.Cardinality);

    // Clear all
    BS.Clear;
    WriteLn('  Pass: After clear, cardinality = ', BS.Cardinality);
  finally
    BS.Free;
  end;
end;

begin
  WriteLn('======================================');
  WriteLn('TBitSet Memory Leak Test');
  WriteLn('======================================');
  WriteLn;

  Test1_BasicOps;
  WriteLn;

  Test2_BitwiseOps;
  WriteLn;

  Test3_SetAllClearAll;
  WriteLn;

  Test4_DynamicGrowth;
  WriteLn;

  Test5_StressTest;
  WriteLn;

  WriteLn('======================================');
  WriteLn('All tests completed!');
  WriteLn('Check below for memory leak report:');
  WriteLn('Look for "0 unfreed memory blocks"');
  WriteLn('======================================');
end.