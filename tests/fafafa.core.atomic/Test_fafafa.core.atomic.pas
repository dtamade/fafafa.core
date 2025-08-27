unit Test_fafafa.core.atomic;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.atomic;

procedure RegisterAtomicTests;

implementation

// 全局函数族测试
// 位操作 RMW、指针字节加减、atomic_flag、is_lock_free、tagged_ptr

type
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_atomic_fetch_and_32;
    procedure Test_atomic_fetch_or_32;
    procedure Test_atomic_fetch_xor_32;
    procedure Test_atomic_fetch_and_64;
    procedure Test_atomic_fetch_or_64;
    procedure Test_atomic_fetch_xor_64;
    procedure Test_atomic_fetch_add_ptr_bytes;
    procedure Test_atomic_fetch_sub_ptr_bytes;
    procedure Test_atomic_flag;
    procedure Test_atomic_is_lock_free;
    procedure Test_tagged_ptr_weak_and_exchange;
  end;

  TTestCase_Concurrent = class(TTestCase)
  published
    procedure Test_concurrent_fetch_add_32;
    procedure Test_concurrent_bit_or_32;
    procedure Test_concurrent_tagged_ptr_increment_tag;
  end;

procedure TTestCase_Global.Test_atomic_fetch_and_32;
var i, r: Int32;
begin
  i := $0F0F0F0F;
  r := atomic_fetch_and(i, $00F0F0F0, memory_order_seq_cst);
  AssertEquals($0F0F0F0F, r);
  AssertEquals(0, i and $FF00FF0F); // 剩余位为0
end;

procedure TTestCase_Global.Test_atomic_fetch_or_32;
var i, r: Int32;
begin
  i := $000F0F00;
  r := atomic_fetch_or(i, $000000F0, memory_order_seq_cst);
  AssertEquals($000F0F00, r);
  AssertEquals($000F0FF0, i);
end;

procedure TTestCase_Global.Test_atomic_fetch_xor_32;
var i, r: Int32;
begin
  i := $000F0FF0;
  r := atomic_fetch_xor(i, $0000000F, memory_order_seq_cst);
  AssertEquals($000F0FF0, r);
  AssertEquals($000F0FFF, i);
end;

procedure TTestCase_Global.Test_atomic_fetch_and_64;
var i, r: Int64;
begin
  i := $00FF00FF00FF00FF;
  r := atomic_fetch_and_64(i, $0F0F0F0F0F0F0F0F, memory_order_seq_cst);
  AssertEquals(QWord($00FF00FF00FF00FF), QWord(r));
  AssertEquals(QWord($000F000F000F000F), QWord(i));
end;

procedure TTestCase_Global.Test_atomic_fetch_or_64;
var i, r: Int64;
begin
  i := $000F000F000F000F;
  r := atomic_fetch_or_64(i, $F0, memory_order_seq_cst);
  AssertEquals(QWord($000F000F000F000F), QWord(r));
  AssertEquals(QWord($000F000F000F00FF), QWord(i));
end;

procedure TTestCase_Global.Test_atomic_fetch_xor_64;
var i, r: Int64;
begin
  i := $000F000F000F00FF;
  r := atomic_fetch_xor_64(i, $0F, memory_order_seq_cst);
  AssertEquals(QWord($000F000F000F00FF), QWord(r));
  AssertEquals(QWord($000F000F000F00F0), QWord(i));
end;

procedure TTestCase_Global.Test_atomic_fetch_add_ptr_bytes;
var p, oldp: Pointer;
begin
  p := Pointer(PtrUInt(1000));
  oldp := atomic_fetch_add_ptr_bytes(p, 16, memory_order_seq_cst);
  AssertTrue(PtrUInt(oldp) = 1000);
  AssertTrue(PtrUInt(p) = 1016);
end;

procedure TTestCase_Global.Test_atomic_fetch_sub_ptr_bytes;
var p, oldp: Pointer;
begin
  p := Pointer(PtrUInt(1016));
  oldp := atomic_fetch_sub_ptr_bytes(p, 8, memory_order_seq_cst);
  AssertTrue(PtrUInt(oldp) = 1016);
  AssertTrue(PtrUInt(p) = 1008);
end;

procedure TTestCase_Global.Test_atomic_flag;
var f: atomic_flag;
begin
  f.v := 0;
  AssertFalse(atomic_flag_test_and_set(f, memory_order_seq_cst));
  AssertTrue(atomic_flag_test_and_set(f, memory_order_seq_cst));
  atomic_flag_clear(f, memory_order_seq_cst);
  AssertFalse(atomic_flag_test_and_set(f, memory_order_seq_cst));
end;

procedure TTestCase_Global.Test_atomic_is_lock_free;
begin
  AssertTrue(atomic_is_lock_free_32);
  {$IFDEF CPU64}AssertTrue(atomic_is_lock_free_64);{$ENDIF}
  AssertTrue(atomic_is_lock_free_ptr);
end;

procedure TTestCase_Global.Test_tagged_ptr_weak_and_exchange;
var tp, prev, exp, des: tagged_ptr;
begin
  tp := make_tagged_ptr(nil, 1);
  exp := tp;
  des := make_tagged_ptr(nil, 2);
  AssertTrue(atomic_compare_exchange_weak_tagged_ptr(tp, exp, des, memory_order_seq_cst));
  AssertEquals(2, Ord(get_tag(tp)));
  prev := atomic_exchange_tagged_ptr(tp, make_tagged_ptr(nil, 3), memory_order_seq_cst);
  AssertEquals(2, Ord(get_tag(prev)));
  AssertEquals(3, Ord(get_tag(tp)));
end;

procedure RegisterAtomicTests;
begin
  RegisterTest('fafafa.core.atomic.Global', TTestCase_Global);
  RegisterTest('fafafa.core.atomic.Concurrent', TTestCase_Concurrent);
end;

type
  TInc32Thread = class(TThread)
  private
    FCounter: PInt32;
    FNPer: Integer;
  protected
    procedure Execute; override;
  public
    constructor CreateShared(var Counter: Int32; NPer: Integer);
  end;

  TOr32Thread = class(TThread)
  private
    FBits: PInt32;
    FBitIndex: Integer;
  protected
    procedure Execute; override;
  public
    constructor CreateShared(var Bits: Int32; BitIndex: Integer);
  end;

  TTaggedIncThread = class(TThread)
  private
    FTp: ^tagged_ptr;
    FNPer: Integer;
  protected
    procedure Execute; override;
  public
    constructor CreateShared(var Tp: tagged_ptr; NPer: Integer);
  end;

constructor TInc32Thread.CreateShared(var Counter: Int32; NPer: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FCounter := @Counter;
  FNPer := NPer;
end;

procedure TInc32Thread.Execute;
var k: Integer;
begin
  for k := 1 to FNPer do
    atomic_fetch_add(FCounter^, 1, memory_order_relaxed);
end;

constructor TOr32Thread.CreateShared(var Bits: Int32; BitIndex: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FBits := @Bits;
  FBitIndex := BitIndex;
end;

procedure TOr32Thread.Execute;
begin
  atomic_fetch_or(FBits^, 1 shl FBitIndex, memory_order_relaxed);
end;

constructor TTaggedIncThread.CreateShared(var Tp: tagged_ptr; NPer: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FTp := @Tp;
  FNPer := NPer;
end;

procedure TTaggedIncThread.Execute;
var k: Integer; exp, des: tagged_ptr;
begin
  for k := 1 to FNPer do
  begin
    repeat
      exp := FTp^;
      des := make_tagged_ptr(get_ptr(exp), next_tag(exp));
    until atomic_compare_exchange_weak_tagged_ptr(FTp^, exp, des, memory_order_acq_rel);
  end;
end;

procedure TTestCase_Concurrent.Test_concurrent_fetch_add_32;
const NThreads = 4; NPer = 5000;
var i: Integer; counter: Int32; th: array of TInc32Thread = nil;
begin
  counter := 0;
  SetLength(th, NThreads);
  for i := 0 to NThreads-1 do begin
    th[i] := TInc32Thread.CreateShared(counter, NPer);
    th[i].Start;
  end;
  for i := 0 to NThreads-1 do begin
    th[i].WaitFor;
    th[i].Free;
  end;
  AssertEquals(NThreads*NPer, counter);
end;

procedure TTestCase_Concurrent.Test_concurrent_bit_or_32;
const NThreads = 8;
var i: Integer; bits: Int32; th: array of TOr32Thread = nil; mask: Int32;
begin
  bits := 0;
  SetLength(th, NThreads);
  for i := 0 to NThreads-1 do begin
    th[i] := TOr32Thread.CreateShared(bits, i);
    th[i].Start;
  end;
  for i := 0 to NThreads-1 do begin
    th[i].WaitFor;
    th[i].Free;
  end;
  mask := (1 shl NThreads) - 1;
  AssertEquals(mask, bits and mask);
end;

procedure TTestCase_Concurrent.Test_concurrent_tagged_ptr_increment_tag;
const NThreads = 4; NPer = 2000;
var i: Integer; tp: tagged_ptr; th: array of TTaggedIncThread = nil;
begin
  tp := make_tagged_ptr(nil, 0);
  SetLength(th, NThreads);
  for i := 0 to NThreads-1 do begin
    th[i] := TTaggedIncThread.CreateShared(tp, NPer);
    th[i].Start;
  end;
  for i := 0 to NThreads-1 do begin
    th[i].WaitFor;
    th[i].Free;
  end;
  AssertEquals(NThreads*NPer, Ord(get_tag(tp)));
end;


end.

