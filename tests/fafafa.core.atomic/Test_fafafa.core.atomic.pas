unit Test_fafafa.core.atomic;

{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.atomic;

procedure RegisterAtomicTests;

implementation
 {$PUSH}
 {$WARN 4055 OFF}

// 全局函数族测试
// 位操作 RMW、指针字节加减、atomic_flag、is_lock_free、tagged_ptr

type
  TTestCase_Global = class(TTestCase)
  published
    // RMW 位操作
    procedure Test_atomic_fetch_and_32;
    procedure Test_atomic_fetch_or_32;
    procedure Test_atomic_fetch_xor_32;
    {$IFDEF CPU64}
    procedure Test_atomic_fetch_and_64;
    procedure Test_atomic_fetch_or_64;
    procedure Test_atomic_fetch_xor_64;
    {$ENDIF}

    // 指针加减
    procedure Test_atomic_fetch_add_ptr_bytes;
    procedure Test_atomic_fetch_sub_ptr_bytes;

    // 基础 load/store/exchange/compare/inc/dec
    procedure Test_atomic_load_store_32;
    procedure Test_atomic_exchange_ptr;
    procedure Test_atomic_compare_exchange_strong_32;
    procedure Test_atomic_compare_exchange_weak_32;
    procedure Test_atomic_increment_decrement_32;
    {$IFDEF CPU64}
    procedure Test_atomic_load_store_64;
    procedure Test_atomic_exchange_64;
    procedure Test_atomic_compare_exchange_strong_64;
    procedure Test_atomic_compare_exchange_weak_64;
    procedure Test_atomic_increment_decrement_64;
    {$ENDIF}

    // 其它
    procedure Test_atomic_flag;
    procedure Test_atomic_is_lock_free;
    procedure Test_atomic_thread_fence_smoke;

    // 更多覆盖
    procedure Test_atomic_load_store_orders_32;
    procedure Test_atomic_load_store_orders_ptr;
    {$IFDEF CPU64}
    procedure Test_atomic_load_store_orders_64;
    {$ENDIF}
    procedure Test_atomic_compare_exchange_strong_ptr;
    procedure Test_atomic_compare_exchange_weak_ptr;
    procedure Test_atomic_compare_exchange_strong_ptrint;
    procedure Test_atomic_fetch_sub_ptr_bytes_variant;
    procedure Test_atomic_uint32_fetch_ops;
    procedure Test_atomic_bitmask_variants_32;
    procedure Test_atomic_fetch_add_sub_boundaries_32;
    {$IFDEF CPU64}
    procedure Test_atomic_fetch_add_sub_boundaries_64;
    procedure Test_atomic_uint64_fetch_ops;
    {$ENDIF}

    procedure Test_ptruint_pointer_fetch_smoke;
    {$IFDEF CPU64}
    procedure Test_uint64_add_sub_fetch_paths;
    procedure Test_uint64_bitwise_boundary_extremes;
    {$ENDIF}

    procedure Test_compare_exchange_expected_writeback_consistency;
    procedure Test_pointer_fetch_add_negative_boundary;
    procedure Test_tagged_ptr_weak_and_exchange;
    procedure Test_tagged_ptr_tag_wraparound;
    procedure Test_atomic_compare_exchange_loops_32;
  end;

  TTestCase_Concurrent = class(TTestCase)
  published
    procedure Test_concurrent_fetch_add_32;
    procedure Test_concurrent_bit_or_32;
    procedure Test_concurrent_tagged_ptr_increment_tag;
    procedure Test_concurrent_cas_increment_32;
    procedure Test_thread_fence_visibility;
    procedure Test_seq_cst_total_order_three_threads;
  end;

procedure TTestCase_Global.Test_atomic_fetch_and_32;
var i, r: Int32;
begin
  i := $0F0F0F0F;
  r := atomic_fetch_and(i, $00F0F0F0);
  AssertEquals($0F0F0F0F, r);
  AssertEquals(0, i and $FF00FF0F); // 剩余位为0
end;

procedure TTestCase_Global.Test_atomic_fetch_or_32;
var i, r: Int32;
begin
  i := $000F0F00;
  r := atomic_fetch_or(i, $000000F0);
  AssertEquals($000F0F00, r);
  AssertEquals($000F0FF0, i);
end;

procedure TTestCase_Global.Test_atomic_fetch_xor_32;
var i, r: Int32;
begin
  i := $000F0FF0;
  r := atomic_fetch_xor(i, $0000000F);
  AssertEquals($000F0FF0, r);
  AssertEquals($000F0FFF, i);
end;

{$IFDEF CPU64}
procedure TTestCase_Global.Test_atomic_fetch_and_64;
var i, r: Int64;
begin
  i := $00FF00FF00FF00FF;
  r := atomic_fetch_and(i, $0F0F0F0F0F0F0F0F);
  AssertEquals(QWord($00FF00FF00FF00FF), QWord(r));
  AssertEquals(QWord($000F000F000F000F), QWord(i));
end;

procedure TTestCase_Global.Test_atomic_fetch_or_64;
var i, r: Int64;
begin
  i := $000F000F000F000F;
  r := atomic_fetch_or(i, $F0);
  AssertEquals(QWord($000F000F000F000F), QWord(r));
  AssertEquals(QWord($000F000F000F00FF), QWord(i));
end;

procedure TTestCase_Global.Test_atomic_fetch_xor_64;
var i, r: Int64;
begin
  i := $000F000F000F00FF;
  r := atomic_fetch_xor(i, $0F);
  AssertEquals(QWord($000F000F000F00FF), QWord(r));
  AssertEquals(QWord($000F000F000F00F0), QWord(i));
end;
{$ENDIF}

procedure TTestCase_Global.Test_atomic_fetch_add_ptr_bytes;
var p, oldp: Pointer;
begin
  p := Pointer(PtrUInt(1000));
  oldp := atomic_fetch_add(p, PtrInt(16));
  AssertTrue(PtrUInt(oldp) = 1000);
  AssertTrue(PtrUInt(p) = 1016);
end;

procedure TTestCase_Global.Test_atomic_fetch_sub_ptr_bytes;
var p, oldp: Pointer;
begin
  p := Pointer(PtrUInt(1016));
  oldp := atomic_fetch_add(p, -PtrInt(8));
  AssertTrue(PtrUInt(oldp) = 1016);
  AssertTrue(PtrUInt(p) = 1008);
end;

procedure TTestCase_Global.Test_atomic_flag;
var f: atomic_flag_t;
begin
  f := 0;
  AssertFalse(atomic_flag_test_and_set(f));
  AssertTrue(atomic_flag_test_and_set(f));
  atomic_flag_clear(f);
  AssertFalse(atomic_flag_test_and_set(f));
end;

procedure TTestCase_Global.Test_atomic_load_store_32;
var v: Int32;
begin
  v := 0;
  atomic_store(v, 123);
  AssertEquals(123, atomic_load(v));
end;

procedure TTestCase_Global.Test_atomic_exchange_ptr;
var p, oldp: Pointer;
begin
  p := Pointer(PtrUInt(100));
  oldp := atomic_exchange(p, Pointer(PtrUInt(200)));
  AssertTrue(PtrUInt(oldp) = 100);
  AssertTrue(PtrUInt(p) = 200);
end;

procedure TTestCase_Global.Test_atomic_compare_exchange_strong_32;
var v, exp: Int32;
begin
  v := 10; exp := 10;
  AssertTrue(atomic_compare_exchange_strong(v, exp, 20));
  AssertEquals(20, v);
  exp := 10;
  AssertFalse(atomic_compare_exchange_strong(v, exp, 30));
  AssertEquals(20, v);
  AssertEquals(20, exp);
end;

procedure TTestCase_Global.Test_atomic_increment_decrement_32;
var v: Int32;
begin
  v := 0;
  AssertEquals(0, atomic_fetch_add(v, 0));
  AssertEquals(0, v);
  AssertEquals(0, atomic_fetch_add(v, 1));
  AssertEquals(1, v);
  AssertEquals(1, atomic_fetch_add(v, 2));
  AssertEquals(3, v);
  AssertEquals(3, atomic_fetch_sub(v, 1));
  AssertEquals(2, v);
  AssertEquals(3, atomic_increment(v));
  AssertEquals(3, v);
  AssertEquals(2, atomic_decrement(v));
  AssertEquals(2, v);
end;

{$IFDEF CPU64}
procedure TTestCase_Global.Test_atomic_load_store_64;
var v: Int64;
begin
  v := 0;
  atomic_store_64(v, 123);
  AssertEquals(QWord(123), QWord(atomic_load_64(v)));
end;

procedure TTestCase_Global.Test_atomic_exchange_64;
var v, oldv: Int64;
begin
  v := 100; oldv := atomic_exchange_64(v, 200);
  AssertEquals(QWord(100), QWord(oldv));
  AssertEquals(QWord(200), QWord(v));
end;

procedure TTestCase_Global.Test_atomic_compare_exchange_strong_64;
var v, exp: Int64;
begin
  v := 10; exp := 10;
  AssertTrue(atomic_compare_exchange_strong_64(v, exp, 20));
  AssertEquals(QWord(20), QWord(v));
  exp := 10;
  AssertFalse(atomic_compare_exchange_strong_64(v, exp, 30));
  AssertEquals(QWord(20), QWord(v));
  AssertEquals(QWord(20), QWord(exp));
end;
{$ENDIF}


procedure TTestCase_Global.Test_atomic_compare_exchange_weak_32;
var v, exp: Int32;
begin
  v := 10; exp := 10;
  // weak=strong 语义：成功路径
  AssertTrue(atomic_compare_exchange_weak(v, exp, 20));
  AssertEquals(20, v);
  // 失败路径：预期值不匹配时 expected 会被写回实际旧值
  exp := 10;
  AssertFalse(atomic_compare_exchange_weak(v, exp, 30));
  AssertEquals(20, v);
  AssertEquals(20, exp);
end;

procedure TTestCase_Global.Test_atomic_increment_decrement_64;
var v: Int64;
begin
  v := 0;
  AssertEquals(QWord(0), QWord(atomic_fetch_add_64(v, 0)));
  AssertEquals(QWord(0), QWord(v));
  AssertEquals(QWord(0), QWord(atomic_fetch_add_64(v, 1)));
  AssertEquals(QWord(1), QWord(v));
  AssertEquals(QWord(1), QWord(atomic_fetch_add_64(v, 2)));
  AssertEquals(QWord(3), QWord(v));
  AssertEquals(QWord(3), QWord(atomic_fetch_sub_64(v, 1)));
  AssertEquals(QWord(2), QWord(v));
  AssertEquals(QWord(3), QWord(atomic_increment_64(v)));
  AssertEquals(QWord(3), QWord(v));
  AssertEquals(QWord(2), QWord(atomic_decrement_64(v)));
  AssertEquals(QWord(2), QWord(v));
end;

{$IFDEF CPU64}
procedure TTestCase_Global.Test_atomic_compare_exchange_weak_64;
var v, exp: Int64;
begin
  v := 10; exp := 10;
  // weak=strong 语义：成功路径
  AssertTrue(atomic_compare_exchange_weak_64(v, exp, 20));
  AssertEquals(QWord(20), QWord(v));
  // 失败路径：预期值不匹配时 expected 会被写回实际旧值
  exp := 10;
  AssertFalse(atomic_compare_exchange_weak_64(v, exp, 30));
  AssertEquals(QWord(20), QWord(v));
  AssertEquals(QWord(20), QWord(exp));
end;
{$ENDIF}
procedure TTestCase_Global.Test_atomic_load_store_orders_32;
var v: Int32;
begin
  v := 0;
  atomic_store(v, 1, mo_relaxed);
  AssertEquals(1, atomic_load(v, mo_relaxed));
  atomic_store(v, 2, mo_release);
  AssertEquals(2, atomic_load(v, mo_acquire));
  atomic_store(v, 3, mo_seq_cst);
  AssertEquals(3, atomic_load(v, mo_seq_cst));
end;

procedure TTestCase_Global.Test_atomic_load_store_orders_ptr;
var p: Pointer;
begin
  p := nil;
  atomic_store(p, Pointer(PtrUInt(1)), mo_release);
  AssertTrue(PtrUInt(atomic_load(p, mo_acquire)) = 1);
  atomic_store(p, Pointer(PtrUInt(2)), mo_seq_cst);
  AssertTrue(PtrUInt(atomic_load(p, mo_seq_cst)) = 2);
end;

{$IFDEF CPU64}
procedure TTestCase_Global.Test_atomic_load_store_orders_64;
var v: Int64;
begin
  v := 0;
  atomic_store_64(v, 1, mo_relaxed);
  AssertEquals(QWord(1), QWord(atomic_load_64(v, mo_relaxed)));
  atomic_store_64(v, 2, mo_release);
  AssertEquals(QWord(2), QWord(atomic_load_64(v, mo_acquire)));
  atomic_store_64(v, 3, mo_seq_cst);
  AssertEquals(QWord(3), QWord(atomic_load_64(v, mo_seq_cst)));
end;
{$ENDIF}

procedure TTestCase_Global.Test_atomic_compare_exchange_strong_ptr;
var p, exp, des: Pointer;
begin
  p := nil; exp := nil; des := Pointer(PtrUInt(123));
  AssertTrue(atomic_compare_exchange_strong(p, exp, des));
  AssertTrue(PtrUInt(p) = 123);
  exp := nil;
  AssertFalse(atomic_compare_exchange_strong(p, exp, Pointer(PtrUInt(456))));
  AssertTrue(PtrUInt(p) = 123);
  AssertTrue(PtrUInt(exp) = 123);
end;

procedure TTestCase_Global.Test_atomic_compare_exchange_weak_ptr;
var p, exp, des: Pointer;
begin
  p := nil; exp := nil; des := Pointer(PtrUInt(123));
  AssertTrue(atomic_compare_exchange_weak(p, exp, des));
  AssertTrue(PtrUInt(p) = 123);
  exp := nil;
  AssertFalse(atomic_compare_exchange_weak(p, exp, Pointer(PtrUInt(456))));
  AssertTrue(PtrUInt(p) = 123);
  AssertTrue(PtrUInt(exp) = 123);
end;

procedure TTestCase_Global.Test_atomic_compare_exchange_strong_ptrint;
var v, exp: PtrInt;
begin
  v := 10; exp := 10;
  AssertTrue(atomic_compare_exchange_strong(v, exp, 20));
  AssertEquals(20, v);
  exp := 10;
  AssertFalse(atomic_compare_exchange_strong(v, exp, 30));
  AssertEquals(20, v);
  AssertEquals(20, exp);
end;

procedure TTestCase_Global.Test_atomic_fetch_sub_ptr_bytes_variant;
var p, oldp: Pointer;
begin
  p := Pointer(PtrUInt(1008));
  oldp := atomic_fetch_sub(p, PtrInt(8));
  AssertTrue(PtrUInt(oldp) = 1008);
  AssertTrue(PtrUInt(p) = 1000);
end;

procedure TTestCase_Global.Test_atomic_uint32_fetch_ops;
var u, r: UInt32;
begin
  u := $FFFF0000;
  r := atomic_fetch_and(u, $0F0F0F0F);
  AssertEquals($FFFF0000, r);
  AssertEquals($0F0F0000, u);
  r := atomic_fetch_or(u, $F0);
  AssertEquals($0F0F0000, r);
  AssertEquals($0F0F00F0, u);
  r := atomic_fetch_xor(u, $FF);
  AssertEquals($0F0F00F0, r);
  AssertEquals($0F0F000F, u);
end;
procedure TTestCase_Global.Test_atomic_bitmask_variants_32;
var v, r: UInt32;
begin
  v := 0; r := atomic_fetch_and(v, UInt32($FFFFFFFF)); AssertEquals(UInt32(0), r); AssertEquals(UInt32(0), v);
  v := UInt32($FFFFFFFF); r := atomic_fetch_and(v, UInt32(0)); AssertEquals(UInt32($FFFFFFFF), r); AssertEquals(UInt32(0), v);
  v := UInt32($80000000); r := atomic_fetch_or(v, UInt32($7FFFFFFF)); AssertEquals(UInt32($80000000), r); AssertEquals(UInt32($FFFFFFFF), v);
  v := UInt32($FFFFFFFF); r := atomic_fetch_xor(v, UInt32($FFFFFFFF)); AssertEquals(UInt32($FFFFFFFF), r); AssertEquals(UInt32(0), v);
end;

procedure TTestCase_Global.Test_atomic_fetch_add_sub_boundaries_32;
var v, old: Int32;
begin
  v := High(Int32)-1; old := atomic_fetch_add(v, 1); AssertEquals(High(Int32)-1, old); AssertEquals(High(Int32), v);
  old := atomic_fetch_sub(v, 1); AssertEquals(High(Int32), old); AssertEquals(High(Int32)-1, v);
end;

{$IFDEF CPU64}
procedure TTestCase_Global.Test_atomic_fetch_add_sub_boundaries_64;
var v: Int64; old: Int64;
begin
  v := High(Int64)-1; old := atomic_fetch_add_64(v, 1); AssertEquals(QWord(High(Int64)-1), QWord(old)); AssertEquals(QWord(High(Int64)), QWord(v));
  old := atomic_fetch_sub_64(v, 1); AssertEquals(QWord(High(Int64)), QWord(old)); AssertEquals(QWord(High(Int64)-1), QWord(v));
end;

procedure TTestCase_Global.Test_atomic_uint64_fetch_ops;
var u, r: UInt64;
begin
  u := QWord($FFFF000000000000); r := atomic_fetch_and_64(u, QWord($0F0F0F0F0F0F0F0F)); AssertEquals(QWord($FFFF000000000000), QWord(r)); AssertEquals(QWord($0F0F000000000000), QWord(u));
  r := atomic_fetch_or_64(u, QWord($F0)); AssertEquals(QWord($0F0F000000000000), QWord(r)); AssertEquals(QWord($0F0F0000000000F0), QWord(u));
  r := atomic_fetch_xor_64(u, QWord($FF)); AssertEquals(QWord($0F0F0000000000F0), QWord(r)); AssertEquals(QWord($0F0F00000000000F), QWord(u));
end;
{$ENDIF}


procedure TTestCase_Global.Test_atomic_thread_fence_smoke;
var x, y: Int32;
begin
  x := 0; y := 0;
  // 这里仅做可编译与基本序语义走通的冒烟测试
  atomic_store(x, 1, mo_release);
  atomic_thread_fence(mo_acquire);
  y := atomic_load(x, mo_acquire);
  AssertTrue(y >= 0);
end;

procedure TTestCase_Global.Test_atomic_is_lock_free;
begin
  AssertTrue(atomic_is_lock_free_32);
  {$IFDEF CPU64}AssertTrue(atomic_is_lock_free_64);{$ENDIF}
  AssertTrue(atomic_is_lock_free_ptr);
end;

procedure TTestCase_Global.Test_tagged_ptr_weak_and_exchange;
var tp, prev, exp, des: atomic_tagged_ptr_t;
begin
  tp := atomic_tagged_ptr(nil, 1);
  exp := tp;
  des := atomic_tagged_ptr(nil, 2);
  AssertTrue(atomic_tagged_ptr_compare_exchange_weak(tp, exp, des));
  AssertEquals(2, Integer(atomic_tagged_ptr_get_tag(tp)));
  prev := atomic_tagged_ptr_exchange(tp, atomic_tagged_ptr(nil, 3));
  AssertEquals(2, Integer(atomic_tagged_ptr_get_tag(prev)));
  AssertEquals(3, Integer(atomic_tagged_ptr_get_tag(tp)));
end;

procedure TTestCase_Global.Test_tagged_ptr_tag_wraparound;
var tp: atomic_tagged_ptr_t; i: UInt32; last: UInt32;
begin
  // 从接近最大 tag 开始，触发一次回卷
  tp := atomic_tagged_ptr(nil, {$IFDEF CPU64}UInt16($FFFE){$ELSE}UInt32($FFFFFFFE){$ENDIF});
  for i := 1 to 3 do begin
    tp := atomic_tagged_ptr(atomic_tagged_ptr_get_ptr(tp), atomic_tagged_ptr_next(tp));
  end;
  last := atomic_tagged_ptr_get_tag(tp);
  // 期望：FFFE -> FFFF -> 1 -> 2
  AssertEquals(Integer(2), Integer(last));
end;

procedure TTestCase_Global.Test_atomic_compare_exchange_loops_32;
var v, exp: Int32; k, succCount, failCount: Integer;
begin
  v := 0; succCount := 0; failCount := 0;
  // 连续成功
  for k := 1 to 10 do begin
    exp := k-1;
    if atomic_compare_exchange_weak(v, exp, k) then Inc(succCount) else Inc(failCount);
  end;
  AssertEquals(10, succCount);
  AssertEquals(0, failCount);
  // 连续失败，expected 应写回旧值
  exp := -1;
  AssertFalse(atomic_compare_exchange_strong(v, exp, 100));
  AssertEquals(10, v);
  AssertEquals(10, exp);
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
    FTp: ^atomic_tagged_ptr_t;
    FNPer: Integer;
  protected
    procedure Execute; override;
  published
    // guard fields for test robustness
    // (no code, just to reserve spots to avoid accidental name collisions)
  public
    constructor CreateShared(var Tp: atomic_tagged_ptr_t; NPer: Integer);
  end;


procedure TTestCase_Concurrent.Test_concurrent_cas_increment_32;
const NThreads = 4; NPer = 4000;
var i: Integer; v: Int32; th: array of TThread = nil;
  function MakeThread: TThread;
  begin
    Result := TThread.CreateAnonymousThread(
      procedure
      var k: Integer; exp: Int32; spins: Integer;
      begin


        for k := 1 to NPer do
        begin
          spins := 0;
          repeat
            exp := v;
            Inc(spins);
            if (spins and 1023)=0 then TThread.Yield;
            if spins > 1000000 then raise Exception.Create('CAS timeout (concurrent_cas_increment_32)');
          until atomic_compare_exchange_weak(v, exp, exp+1);
        end;
      end);
    Result.FreeOnTerminate := False;
  end;
begin
  v := 0;
  SetLength(th, NThreads);
  for i := 0 to NThreads-1 do begin th[i] := MakeThread; th[i].Start; end;
  for i := 0 to NThreads-1 do begin th[i].WaitFor; th[i].Free; end;
  AssertEquals(NThreads*NPer, v);
end;

procedure TTestCase_Concurrent.Test_thread_fence_visibility;
var x, y: Int32; writer, reader: TThread;
begin
  x := 0; y := 0;
  writer := TThread.CreateAnonymousThread(
    procedure
    begin
      atomic_store(x, 1, mo_release);
    end);
  writer.FreeOnTerminate := False;
  reader := TThread.CreateAnonymousThread(
    procedure
    var r: Int32; k: Integer;
    begin
      // 用 acquire 轮询直到观测到 writer 的 release
      for k := 1 to 100000 do
      begin
        r := atomic_load(x, mo_acquire);
        if r <> 0 then break;
        TThread.Yield;
      end;
      y := atomic_load(x, mo_acquire);
    end);
  reader.FreeOnTerminate := False;
  writer.Start; reader.Start; writer.WaitFor; reader.WaitFor; writer.Free; reader.Free;
  AssertEquals(1, y);
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
    atomic_fetch_add(FCounter^, 1);
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
  atomic_fetch_or(FBits^, 1 shl FBitIndex);
end;

constructor TTaggedIncThread.CreateShared(var Tp: atomic_tagged_ptr_t; NPer: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FTp := @Tp;
  FNPer := NPer;
end;

procedure TTaggedIncThread.Execute;
var k, spins: Integer; exp, des: atomic_tagged_ptr_t;
begin
  for k := 1 to FNPer do
  begin
    spins := 0;
    repeat
      exp := FTp^;
      des := atomic_tagged_ptr(atomic_tagged_ptr_get_ptr(exp), atomic_tagged_ptr_next(exp));
      Inc(spins);
      if (spins and 1023)=0 then TThread.Yield;
      if spins > 1000000 then raise Exception.Create('CAS timeout (tagged_inc)');
    until atomic_tagged_ptr_compare_exchange_weak(FTp^, exp, des);
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
var i, total: Integer; tp, tmp: atomic_tagged_ptr_t; th: array of TTaggedIncThread = nil; expected: UInt32;
begin
  tp := atomic_tagged_ptr(nil, 0);
  SetLength(th, NThreads);
  for i := 0 to NThreads-1 do begin
    th[i] := TTaggedIncThread.CreateShared(tp, NPer);
    th[i].Start;
  end;
  for i := 0 to NThreads-1 do begin
    th[i].WaitFor;
    th[i].Free;
  end;
  // 计算期望的 tag（用相同 next 规则模拟 N 次递增）
  total := NThreads * NPer;
  tmp := atomic_tagged_ptr(nil, 0);
  for i := 1 to total do
    tmp := atomic_tagged_ptr(atomic_tagged_ptr_get_ptr(tmp), atomic_tagged_ptr_next(tmp));
  expected := atomic_tagged_ptr_get_tag(tmp);
  AssertEquals(Integer(expected), Integer(atomic_tagged_ptr_get_tag(tp)));
end;



// 内存序对照与桥接余缺
procedure TTestCase_Concurrent.Test_seq_cst_total_order_three_threads;
var a, b, c: Int32; t1, t2, t3: TThread;
begin
  a := 0; b := 0; c := 0;
  t1 := TThread.CreateAnonymousThread(procedure begin atomic_store(a, 1, mo_seq_cst); end);
  t2 := TThread.CreateAnonymousThread(
    procedure
    var k: Integer;
    begin
      for k := 1 to 100000 do
      begin
        if atomic_load(a, mo_seq_cst) = 1 then begin atomic_store(b, 1, mo_seq_cst); break; end;
        if (k and 1023)=0 then TThread.Yield;
      end;
    end);
  t3 := TThread.CreateAnonymousThread(
    procedure
    var k: Integer;
    begin
      for k := 1 to 100000 do
      begin
        if atomic_load(b, mo_seq_cst) = 1 then begin atomic_store(c, 1, mo_seq_cst); break; end;
        if (k and 1023)=0 then TThread.Yield;
      end;
    end);
  t1.FreeOnTerminate := False; t2.FreeOnTerminate := False; t3.FreeOnTerminate := False;
  t1.Start; t2.Start; t3.Start; t1.WaitFor; t2.WaitFor; t3.WaitFor; t1.Free; t2.Free; t3.Free;
  AssertEquals(1, c);
end;

procedure TTestCase_Global.Test_ptruint_pointer_fetch_smoke;
var pu, ru: PtrUInt; pp, rp: Pointer;
begin
  // PtrUInt fetch_and/or/xor
  pu := PtrUInt($FF00); ru := atomic_fetch_and(pu, PtrUInt($0F0F)); AssertEquals(PtrUInt($FF00), ru); AssertEquals(PtrUInt($0F00), pu);
  ru := atomic_fetch_or(pu, PtrUInt($00F0)); AssertEquals(PtrUInt($0F00), ru); AssertEquals(PtrUInt($0FF0), pu);
  ru := atomic_fetch_xor(pu, PtrUInt($00FF)); AssertEquals(PtrUInt($0FF0), ru); AssertEquals(PtrUInt($0F0F), pu);
  // Pointer fetch_and/or/xor 通过整数桥接（不关心位义，只测路径）
  pp := Pointer(PtrUInt($FF00)); rp := atomic_fetch_and(pp, Pointer(PtrUInt($0F0F))); AssertEquals(PtrUInt($FF00), PtrUInt(rp)); AssertEquals(PtrUInt($0F00), PtrUInt(pp));
  rp := atomic_fetch_or(pp, Pointer(PtrUInt($00F0))); AssertEquals(PtrUInt($0F00), PtrUInt(rp)); AssertEquals(PtrUInt($0FF0), PtrUInt(pp));
  rp := atomic_fetch_xor(pp, Pointer(PtrUInt($00FF))); AssertEquals(PtrUInt($0FF0), PtrUInt(rp)); AssertEquals(PtrUInt($0F0F), PtrUInt(pp));
end;

{$IFDEF CPU64}
procedure TTestCase_Global.Test_uint64_add_sub_fetch_paths;
var u, r: UInt64;
begin
  u := 1; r := atomic_fetch_add_64(u, 2); AssertEquals(QWord(1), QWord(r)); AssertEquals(QWord(3), QWord(u));
  r := atomic_fetch_sub_64(u, 1); AssertEquals(QWord(3), QWord(r)); AssertEquals(QWord(2), QWord(u));
end;

{$IFDEF CPU64}
procedure TTestCase_Global.Test_uint64_bitwise_boundary_extremes;
var u, r: UInt64;
begin
  // All 1s -> All 0s via AND
  u := QWord($FFFFFFFFFFFFFFFF); r := atomic_fetch_and_64(u, QWord(0));
  AssertEquals(QWord($FFFFFFFFFFFFFFFF), QWord(r)); AssertEquals(QWord(0), QWord(u));

  // All 0s -> All 1s via OR
  u := QWord(0); r := atomic_fetch_or_64(u, QWord($FFFFFFFFFFFFFFFF));
  AssertEquals(QWord(0), QWord(r)); AssertEquals(QWord($FFFFFFFFFFFFFFFF), QWord(u));

  // All 1s -> All 0s via XOR
  u := QWord($FFFFFFFFFFFFFFFF); r := atomic_fetch_xor_64(u, QWord($FFFFFFFFFFFFFFFF));
  AssertEquals(QWord($FFFFFFFFFFFFFFFF), QWord(r)); AssertEquals(QWord(0), QWord(u));

  // Sign bit flip: 0x8000... <-> 0x7FFF...
  u := QWord($8000000000000000); r := atomic_fetch_xor_64(u, QWord($FFFFFFFFFFFFFFFF));
  AssertEquals(QWord($8000000000000000), QWord(r)); AssertEquals(QWord($7FFFFFFFFFFFFFFF), QWord(u));

  // High/Low boundary: High(Int64) AND with Low mask
  u := QWord($7FFFFFFFFFFFFFFF); r := atomic_fetch_and_64(u, QWord($00000000FFFFFFFF));
  AssertEquals(QWord($7FFFFFFFFFFFFFFF), QWord(r)); AssertEquals(QWord($00000000FFFFFFFF), QWord(u));
end;
{$ENDIF}

procedure TTestCase_Global.Test_compare_exchange_expected_writeback_consistency;
var
  pi: PtrInt; exp_pi: PtrInt;
  pu: PtrUInt; exp_pu: PtrUInt;
  pp: Pointer; exp_pp: Pointer;
  success: Boolean;
begin
  // PtrInt: Success -> Fail -> Success sequence, check expected writeback
  pi := 100; exp_pi := 100; success := atomic_compare_exchange_strong(pi, exp_pi, 200);
  AssertTrue(success); AssertEquals(100, exp_pi); AssertEquals(200, pi);

  exp_pi := 999; success := atomic_compare_exchange_strong(pi, exp_pi, 300); // should fail
  AssertFalse(success); AssertEquals(200, exp_pi); AssertEquals(200, pi); // expected written back

  exp_pi := 200; success := atomic_compare_exchange_strong(pi, exp_pi, 400);
  AssertTrue(success); AssertEquals(200, exp_pi); AssertEquals(400, pi);

  // PtrUInt: similar sequence
  pu := PtrUInt(500); exp_pu := PtrUInt(500); success := atomic_compare_exchange_strong(pu, exp_pu, PtrUInt(600));
  AssertTrue(success); AssertEquals(PtrUInt(500), exp_pu); AssertEquals(PtrUInt(600), pu);

  exp_pu := PtrUInt(777); success := atomic_compare_exchange_strong(pu, exp_pu, PtrUInt(700));
  AssertFalse(success); AssertEquals(PtrUInt(600), exp_pu); AssertEquals(PtrUInt(600), pu);

  // Pointer: cast through PtrUInt for comparison
  pp := Pointer(PtrUInt(1000)); exp_pp := Pointer(PtrUInt(1000));
  success := atomic_compare_exchange_strong(pp, exp_pp, Pointer(PtrUInt(2000)));
  AssertTrue(success); AssertEquals(PtrUInt(1000), PtrUInt(exp_pp)); AssertEquals(PtrUInt(2000), PtrUInt(pp));

  exp_pp := Pointer(PtrUInt(3333)); success := atomic_compare_exchange_strong(pp, exp_pp, Pointer(PtrUInt(4000)));
  AssertFalse(success); AssertEquals(PtrUInt(2000), PtrUInt(exp_pp)); AssertEquals(PtrUInt(2000), PtrUInt(pp));
end;

procedure TTestCase_Global.Test_pointer_fetch_add_negative_boundary;
var p, r: Pointer; offset: PtrInt;
begin
  // Start at a "high" address, subtract to approach zero (but not cross)
  p := Pointer(PtrUInt(10000)); offset := -5000;
  r := atomic_fetch_add(p, offset);
  AssertEquals(PtrUInt(10000), PtrUInt(r)); AssertEquals(PtrUInt(5000), PtrUInt(p));

  // Subtract more to approach zero boundary
  offset := -4999;
  r := atomic_fetch_add(p, offset);
  AssertEquals(PtrUInt(5000), PtrUInt(r)); AssertEquals(PtrUInt(1), PtrUInt(p));

  // Add back to verify bidirectional
  offset := 999;
  r := atomic_fetch_add(p, offset);
  AssertEquals(PtrUInt(1), PtrUInt(r)); AssertEquals(PtrUInt(1000), PtrUInt(p));

  // Test pointer subtraction variant (fetch_sub)
  r := atomic_fetch_sub(p, PtrInt(500));
  AssertEquals(PtrUInt(1000), PtrUInt(r)); AssertEquals(PtrUInt(500), PtrUInt(p));
end;
{$ENDIF}

// 内存序对照与桥接余缺


{$POP}
end.
