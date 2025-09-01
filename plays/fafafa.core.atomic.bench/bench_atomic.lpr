program bench_atomic;

{$APPTYPE CONSOLE}
{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  Windows, SysUtils, Classes,
  fafafa.core.atomic;

type
  TUnary32 = function(var v: Int32): Int32;
  TUnary64 = function(var v: Int64): Int64;
  TXadd32  = function(var v: Int32; delta: Int32): Int32;
  TXadd64  = function(var v: Int64; delta: Int64): Int64;
  TXchg32  = function(var v: Int32; desired: Int32): Int32;
  TXchg64  = function(var v: Int64; desired: Int64): Int64;
  TCas32   = function(var v: Int32; expected, desired: Int32): Boolean;
  TCas64   = function(var v: Int64; expected, desired: Int64): Boolean;
  TBinop32 = function(var v: Int32; m: Int32): Int32;
  TBinop64 = function(var v: Int64; m: Int64): Int64;

function TicksPerSecond: Int64;
var f: Int64;
begin
  if not QueryPerformanceFrequency(f) then f := 0;
  Result := f;
end;

function GetTicks: Int64; inline;
var t: Int64;
begin
  QueryPerformanceCounter(t);
  Result := t;
end;

function NsPerTick: Double;
var fps: Int64;
begin
  fps := TicksPerSecond;
  if fps = 0 then Result := 0 else Result := 1e9 / fps;
end;

procedure PrintHeader;
begin
  Writeln('fafafa.core.atomic vs RTL Interlocked (Win64)');
  Writeln('ns/tick=', FormatFloat('0.000', NsPerTick));
  Writeln;
end;

// RTL wrappers (Win64)
function rtl_inc32(var v: Int32): Int32; inline; begin Result := InterlockedIncrement(v); end;
function rtl_dec32(var v: Int32): Int32; inline; begin Result := InterlockedDecrement(v); end;
function rtl_xchg32(var v: Int32; desired: Int32): Int32; inline; begin Result := InterlockedExchange(v, desired); end;
function rtl_xadd32(var v: Int32; delta: Int32): Int32; inline; begin Result := InterlockedExchangeAdd(v, delta); end;
function rtl_cas32(var v: Int32; expected, desired: Int32): Boolean; inline;
begin Result := InterlockedCompareExchange(v, desired, expected) = expected; end;

function rtl_inc64(var v: Int64): Int64; inline; begin Result := InterlockedIncrement64(v); end;
function rtl_dec64(var v: Int64): Int64; inline; begin Result := InterlockedDecrement64(v); end;
function rtl_xchg64(var v: Int64; desired: Int64): Int64; inline; begin Result := InterlockedExchange64(v, desired); end;
function rtl_xadd64(var v: Int64; delta: Int64): Int64; inline; begin Result := InterlockedExchangeAdd64(v, delta); end;
function rtl_cas64(var v: Int64; expected, desired: Int64): Boolean; inline;
begin Result := InterlockedCompareExchange64(v, desired, expected) = expected; end;

// Bench helpers
procedure BenchUnary32(const name, impl: AnsiString; iters: QWord; func: TUnary32);
var i: QWord; t0,t1: Int64; v: Int32; ns: Double;
begin
  v := 0; // warm
  for i := 1 to 1000 do func(v);
  t0 := GetTicks;
  v := 0;
  for i := 1 to iters do func(v);
  t1 := GetTicks;
  ns := (t1 - t0) * NsPerTick / iters;
  Writeln(Format('%-28s %-10s iters=%10d  ns/op=%.2f  v=%d', [name, impl, iters, ns, v]));
end;

procedure BenchUnary64(const name, impl: AnsiString; iters: QWord; func: TUnary64);
// Bitwise RMW (emulated via CAS loops for RTL side)
function rtl_and32(var v: Int32; m: Int32): Int32; inline;
var oldv, newv: Int32;
begin
  repeat
    oldv := v;
    newv := oldv and m;
  until InterlockedCompareExchange(v, newv, oldv) = oldv;
  Result := oldv;
end;

function rtl_or32(var v: Int32; m: Int32): Int32; inline;
var oldv, newv: Int32;
begin
  repeat
    oldv := v;
    newv := oldv or m;
  until InterlockedCompareExchange(v, newv, oldv) = oldv;
  Result := oldv;
end;

function rtl_xor32(var v: Int32; m: Int32): Int32; inline;
var oldv, newv: Int32;
begin
  repeat
    oldv := v;
    newv := oldv xor m;
  until InterlockedCompareExchange(v, newv, oldv) = oldv;
  Result := oldv;
end;

function rtl_and64(var v: Int64; m: Int64): Int64; inline;
var oldv, newv: Int64;
begin
  repeat
    oldv := v;
    newv := oldv and m;
  until InterlockedCompareExchange64(v, newv, oldv) = oldv;
  Result := oldv;
end;

function rtl_or64(var v: Int64; m: Int64): Int64; inline;
var oldv, newv: Int64;
begin
  repeat
    oldv := v;
    newv := oldv or m;
  until InterlockedCompareExchange64(v, newv, oldv) = oldv;
  Result := oldv;
end;

function rtl_xor64(var v: Int64; m: Int64): Int64; inline;
var oldv, newv: Int64;
begin
  repeat
    oldv := v;
    newv := oldv xor m;
  until InterlockedCompareExchange64(v, newv, oldv) = oldv;
  Result := oldv;
end;

// Our bitwise wrappers
function our_and32(var v: Int32; m: Int32): Int32; inline; begin Result := atomic_fetch_and(v, m); end;
function our_or32(var v: Int32; m: Int32): Int32; inline; begin Result := atomic_fetch_or(v, m); end;
function our_xor32(var v: Int32; m: Int32): Int32; inline; begin Result := atomic_fetch_xor(v, m); end;
function our_and64(var v: Int64; m: Int64): Int64; inline; begin Result := atomic_fetch_and_64(v, m); end;
function our_or64(var v: Int64; m: Int64): Int64; inline; begin Result := atomic_fetch_or_64(v, m); end;
function our_xor64(var v: Int64; m: Int64): Int64; inline; begin Result := atomic_fetch_xor_64(v, m); end;

var i: QWord; t0,t1: Int64; v: Int64; ns: Double;
begin
  v := 0; for i := 1 to 1000 do func(v);
  t0 := GetTicks;
  v := 0;
  for i := 1 to iters do func(v);
  t1 := GetTicks;
  ns := (t1 - t0) * NsPerTick / iters;
  Writeln(Format('%-28s %-10s iters=%10d  ns/op=%.2f  v=%d', [name, impl, iters, ns, v]));
end;

procedure BenchXadd32(const name, impl: AnsiString; iters: QWord; func: TXadd32);
var i: QWord; t0,t1: Int64; v: Int32; ns: Double;
begin
  v := 0; for i := 1 to 1000 do func(v, 1);
  t0 := GetTicks;
  v := 0;
  for i := 1 to iters do func(v, 1);
  t1 := GetTicks;
  ns := (t1 - t0) * NsPerTick / iters;
  Writeln(Format('%-28s %-10s iters=%10d  ns/op=%.2f  v=%d', [name, impl, iters, ns, v]));
end;

procedure BenchXadd64(const name, impl: AnsiString; iters: QWord; func: TXadd64);
var i: QWord; t0,t1: Int64; v: Int64; ns: Double;
begin
  v := 0; for i := 1 to 1000 do func(v, 1);
  t0 := GetTicks;
  v := 0;
  for i := 1 to iters do func(v, 1);
  t1 := GetTicks;
  ns := (t1 - t0) * NsPerTick / iters;
  Writeln(Format('%-28s %-10s iters=%10d  ns/op=%.2f  v=%d', [name, impl, iters, ns, v]));
end;

procedure BenchXchg32(const name, impl: AnsiString; iters: QWord; func: TXchg32);
var i: QWord; t0,t1: Int64; v: Int32; ns: Double;
begin
  v := 0; for i := 1 to 1000 do func(v, 1);
  t0 := GetTicks;
  v := 0;
  for i := 1 to iters do func(v, 1);
  t1 := GetTicks;
  ns := (t1 - t0) * NsPerTick / iters;
  Writeln(Format('%-28s %-10s iters=%10d  ns/op=%.2f  v=%d', [name, impl, iters, ns, v]));
end;

procedure BenchXchg64(const name, impl: AnsiString; iters: QWord; func: TXchg64);
var i: QWord; t0,t1: Int64; v: Int64; ns: Double;
begin
  v := 0; for i := 1 to 1000 do func(v, 1);
  t0 := GetTicks;
  v := 0;
  for i := 1 to iters do func(v, 1);
  t1 := GetTicks;
  ns := (t1 - t0) * NsPerTick / iters;
  Writeln(Format('%-28s %-10s iters=%10d  ns/op=%.2f  v=%d', [name, impl, iters, ns, v]));

procedure BenchBinop32(const name, impl: AnsiString; iters: QWord; mask: Int32; func: TBinop32);
var i: QWord; t0,t1: Int64; v, r: Int32; ns: Double;
begin
  v := -1; for i := 1 to 1000 do r := func(v, mask);
  t0 := GetTicks;
  v := -1;
  for i := 1 to iters do r := func(v, mask);
  t1 := GetTicks;
  ns := (t1 - t0) * NsPerTick / iters;
  Writeln(Format('%-28s %-10s iters=%10d  ns/op=%.2f  v=%d  r=%d', [name, impl, iters, ns, v, r]));
end;

procedure BenchBinop64(const name, impl: AnsiString; iters: QWord; mask: Int64; func: TBinop64);
var i: QWord; t0,t1: Int64; v, r: Int64; ns: Double;
begin
  v := -1; for i := 1 to 1000 do r := func(v, mask);
  t0 := GetTicks;
  v := -1;
  for i := 1 to iters do r := func(v, mask);
  t1 := GetTicks;
  ns := (t1 - t0) * NsPerTick / iters;
  Writeln(Format('%-28s %-10s iters=%10d  ns/op=%.2f  v=%d  r=%d', [name, impl, iters, ns, v, r]));
end;

procedure BenchXadd32Delta(const name, impl: AnsiString; iters: QWord; delta: Int32; func: TXadd32);
var i: QWord; t0,t1: Int64; v: Int32; ns: Double;
begin
  v := 0; for i := 1 to 1000 do func(v, delta);
  t0 := GetTicks;
  v := 0;
  for i := 1 to iters do func(v, delta);
  t1 := GetTicks;
  ns := (t1 - t0) * NsPerTick / iters;
  Writeln(Format('%-28s %-10s iters=%10d  ns/op=%.2f  v=%d', [name, impl, iters, ns, v]));
end;

procedure BenchXadd64Delta(const name, impl: AnsiString; iters: QWord; delta: Int64; func: TXadd64);
var i: QWord; t0,t1: Int64; v: Int64; ns: Double;
begin
  v := 0; for i := 1 to 1000 do func(v, delta);

// Global bitwise RMW wrappers (RTL via CAS loops)
function rtl_and32(var v: Int32; m: Int32): Int32; inline;
var oldv, newv: Int32;
begin
  repeat oldv := v; newv := oldv and m; until InterlockedCompareExchange(v, newv, oldv) = oldv;
  Result := oldv;
end;
function rtl_or32(var v: Int32; m: Int32): Int32; inline;
var oldv, newv: Int32;
begin
  repeat oldv := v; newv := oldv or m; until InterlockedCompareExchange(v, newv, oldv) = oldv;
  Result := oldv;
end;
function rtl_xor32(var v: Int32; m: Int32): Int32; inline;
var oldv, newv: Int32;
begin
  repeat oldv := v; newv := oldv xor m; until InterlockedCompareExchange(v, newv, oldv) = oldv;
  Result := oldv;
end;
function rtl_and64(var v: Int64; m: Int64): Int64; inline;
var oldv, newv: Int64;
begin
  repeat oldv := v; newv := oldv and m; until InterlockedCompareExchange64(v, newv, oldv) = oldv;
  Result := oldv;
end;
function rtl_or64(var v: Int64; m: Int64): Int64; inline;
var oldv, newv: Int64;
begin
  repeat oldv := v; newv := oldv or m; until InterlockedCompareExchange64(v, newv, oldv) = oldv;
  Result := oldv;
end;
function rtl_xor64(var v: Int64; m: Int64): Int64; inline;
var oldv, newv: Int64;
begin
  repeat oldv := v; newv := oldv xor m; until InterlockedCompareExchange64(v, newv, oldv) = oldv;
  Result := oldv;
end;

function our_and32(var v: Int32; m: Int32): Int32; inline; begin Result := atomic_fetch_and(v, m); end;
function our_or32(var v: Int32; m: Int32): Int32; inline; begin Result := atomic_fetch_or(v, m); end;
function our_xor32(var v: Int32; m: Int32): Int32; inline; begin Result := atomic_fetch_xor(v, m); end;
function our_and64(var v: Int64; m: Int64): Int64; inline; begin Result := atomic_fetch_and_64(v, m); end;
function our_or64(var v: Int64; m: Int64): Int64; inline; begin Result := atomic_fetch_or_64(v, m); end;
function our_xor64(var v: Int64; m: Int64): Int64; inline; begin Result := atomic_fetch_xor_64(v, m); end;

// Pointer add/sub wrappers
type
  TPtrAdd = function(var p: Pointer; delta: PtrInt): Pointer;

function rtl_ptr_add(var p: Pointer; delta: PtrInt): Pointer; inline;
begin
  {$IF SIZEOF(Pointer)=8}
  Result := Pointer(InterlockedExchangeAdd64(PInt64(@p)^, delta));
  {$ELSE}
  Result := Pointer(InterlockedExchangeAdd(PInt32(@p)^, delta));
  {$ENDIF}
end;

function our_ptr_add(var p: Pointer; delta: PtrInt): Pointer; inline;
begin
  Result := atomic_fetch_add(p, delta);
end;

procedure BenchPtrAdd(const name, impl: AnsiString; iters: QWord; delta: PtrInt; func: TPtrAdd);
var i: QWord; t0,t1: Int64; p, r: Pointer; ns: Double;
begin
  p := Pointer(0);
  for i := 1 to 1000 do r := func(p, delta);
  t0 := GetTicks;
  p := Pointer(0);
  for i := 1 to iters do r := func(p, delta);
  t1 := GetTicks;
  ns := (t1 - t0) * NsPerTick / iters;
  Writeln(Format('%-28s %-10s iters=%10d  ns/op=%.2f  p=%d  r=%d', [name, impl, iters, ns, PtrUInt(p), PtrUInt(r)]));
end;

  t0 := GetTicks;
  v := 0;
  for i := 1 to iters do func(v, delta);
  t1 := GetTicks;
  ns := (t1 - t0) * NsPerTick / iters;
  Writeln(Format('%-28s %-10s iters=%10d  ns/op=%.2f  v=%d', [name, impl, iters, ns, v]));
end;

end;

procedure BenchCasLoop32(const name, impl: AnsiString; iters: QWord; casFunc: TCas32);
var i: QWord; t0,t1: Int64; v, exp: Int32; ns: Double;
begin
  // Single-thread CAS loop (always succeed)
  v := 0; for i := 1 to 1000 do begin exp := i-1; casFunc(v, exp, i); end;
  t0 := GetTicks;
  v := 0;
  for i := 1 to iters do begin exp := i-1; casFunc(v, exp, i); end;
  t1 := GetTicks;
  ns := (t1 - t0) * NsPerTick / iters;
  Writeln(Format('%-28s %-10s iters=%10d  ns/op=%.2f  v=%d', [name, impl, iters, ns, v]));
end;

procedure BenchCasLoop64(const name, impl: AnsiString; iters: QWord; casFunc: TCas64);
var i: QWord; t0,t1: Int64; v, exp: Int64; ns: Double;
begin
  v := 0; for i := 1 to 1000 do begin exp := i-1; casFunc(v, exp, i); end;
  t0 := GetTicks;
  v := 0;

  for i := 1 to iters do begin exp := i-1; casFunc(v, exp, i); end;
  t1 := GetTicks;
  ns := (t1 - t0) * NsPerTick / iters;
  Writeln(Format('%-28s %-10s iters=%10d  ns/op=%.2f  v=%d', [name, impl, iters, ns, v]));
end;

// Our wrappers
function our_inc32(var v: Int32): Int32; inline; begin Result := atomic_increment(v); end;
function our_dec32(var v: Int32): Int32; inline; begin Result := atomic_decrement(v); end;
function our_xchg32(var v: Int32; desired: Int32): Int32; inline; begin Result := atomic_exchange(v, desired); end;
function our_xadd32(var v: Int32; delta: Int32): Int32; inline; begin Result := atomic_fetch_add(v, delta); end;
function our_cas32(var v: Int32; expected, desired: Int32): Boolean; inline; begin Result := atomic_compare_exchange_strong(v, expected, desired); end;

function our_inc64(var v: Int64): Int64; inline; begin Result := atomic_increment_64(v); end;
function our_dec64(var v: Int64): Int64; inline; begin Result := atomic_decrement_64(v); end;
function our_xchg64(var v: Int64; desired: Int64): Int64; inline; begin Result := atomic_exchange_64(v, desired); end;
function our_xadd64(var v: Int64; delta: Int64): Int64; inline; begin Result := atomic_fetch_add_64(v, delta); end;
function our_cas64(var v: Int64; expected, desired: Int64): Boolean; inline; begin Result := atomic_compare_exchange_strong_64(v, expected, desired); end;

procedure RunSingleThread(iters: QWord);
begin
  Writeln('--- Single-thread (iters=', iters, ') ---');
  // 32-bit
  BenchUnary32('inc32', 'rtl', iters, @rtl_inc32);
  BenchUnary32('inc32', 'our', iters, @our_inc32);
  BenchUnary32('dec32', 'rtl', iters, @rtl_dec32);
  BenchUnary32('dec32', 'our', iters, @our_dec32);
  BenchXadd32('fetch_add32 +1', 'rtl', iters, @rtl_xadd32);
  BenchXadd32('fetch_add32 +1', 'our', iters, @our_xadd32);
  BenchXchg32('exchange32 ->1', 'rtl', iters, @rtl_xchg32);
  BenchXchg32('exchange32 ->1', 'our', iters, @our_xchg32);
  BenchCasLoop32('cas_loop32 ++', 'rtl', iters, @rtl_cas32);
  BenchCasLoop32('cas_loop32 ++', 'our', iters, @our_cas32);
  // 64-bit
  BenchUnary64('inc64', 'rtl', iters, @rtl_inc64);
  BenchUnary64('inc64', 'our', iters, @our_inc64);
  BenchUnary64('dec64', 'rtl', iters, @rtl_dec64);
  BenchUnary64('dec64', 'our', iters, @our_dec64);
  BenchXadd64('fetch_add64 +1', 'rtl', iters, @rtl_xadd64);
  BenchXadd64('fetch_add64 +1', 'our', iters, @our_xadd64);
  BenchXchg64('exchange64 ->1', 'rtl', iters, @rtl_xchg64);
  BenchXchg64('exchange64 ->1', 'our', iters, @our_xchg64);
  BenchCasLoop64('cas_loop64 ++', 'rtl', iters, @rtl_cas64);
  BenchCasLoop64('cas_loop64 ++', 'our', iters, @our_cas64);

  // Bitwise RMW 32-bit
  BenchBinop32('fetch_and32  &0x0F0F0F0F', 'rtl', iters, Int32($0F0F0F0F), @rtl_and32);
  BenchBinop32('fetch_and32  &0x0F0F0F0F', 'our', iters, Int32($0F0F0F0F), @our_and32);
  BenchBinop32('fetch_or32   |0xF0F0F0F0', 'rtl', iters, Int32($F0F0F0F0), @rtl_or32);
  BenchBinop32('fetch_or32   |0xF0F0F0F0', 'our', iters, Int32($F0F0F0F0), @our_or32);
  BenchBinop32('fetch_xor32  ^0x00FF00FF', 'rtl', iters, Int32($00FF00FF), @rtl_xor32);
  BenchBinop32('fetch_xor32  ^0x00FF00FF', 'our', iters, Int32($00FF00FF), @our_xor32);

  // Bitwise RMW 64-bit
  BenchBinop64('fetch_and64  &0x0F0F0F0F0F0F0F0F', 'rtl', iters, Int64($0F0F0F0F0F0F0F0F), @rtl_and64);
  BenchBinop64('fetch_and64  &0x0F0F0F0F0F0F0F0F', 'our', iters, Int64($0F0F0F0F0F0F0F0F), @our_and64);
  BenchBinop64('fetch_or64   |0x00FF00FF00FF00FF', 'rtl', iters, Int64($00FF00FF00FF00FF), @rtl_or64);
  BenchBinop64('fetch_or64   |0x00FF00FF00FF00FF', 'our', iters, Int64($00FF00FF00FF00FF), @our_or64);
  BenchBinop64('fetch_xor64  ^0x0F0F0F0F00FF00FF', 'rtl', iters, Int64($0F0F0F0F00FF00FF), @rtl_xor64);
  BenchBinop64('fetch_xor64  ^0x0F0F0F0F00FF00FF', 'our', iters, Int64($0F0F0F0F00FF00FF), @our_xor64);

  // Pointer add/sub (byte steps)
  BenchPtrAdd('ptr_add +1', 'rtl', iters, 1, @rtl_ptr_add);
  BenchPtrAdd('ptr_add +1', 'our', iters, 1, @our_ptr_add);
  BenchPtrAdd('ptr_add +8', 'rtl', iters, 8, @rtl_ptr_add);
  BenchPtrAdd('ptr_add +8', 'our', iters, 8, @our_ptr_add);
  BenchPtrAdd('ptr_add -1', 'rtl', iters, -1, @rtl_ptr_add);
  BenchPtrAdd('ptr_add -1', 'our', iters, -1, @our_ptr_add);

  // Add negative delta variants via xadd
  BenchXadd32Delta('fetch_add32 -1', 'rtl', iters, -1, @rtl_xadd32);
  BenchXadd32Delta('fetch_add32 -1', 'our', iters, -1, @our_xadd32);
  BenchXadd64Delta('fetch_add64 -1', 'rtl', iters, -1, @rtl_xadd64);
  BenchXadd64Delta('fetch_add64 -1', 'our', iters, -1, @our_xadd64);

  Writeln;
end;

type
  POp32 = ^Int32;

type
  TWorker32 = class(TThread)
  private
    FCounter: PInt32;
    FIters: QWord;
    FMode: Integer; // 0=inc,1=xadd,2=cas
    FUseOur: Boolean;
    FStartFlag: PLongInt;
  protected
    procedure Execute; override;
  public
    constructor CreateShared(var Counter: Int32; Iters: QWord; Mode: Integer; UseOur: Boolean; var StartFlag: LongInt);
  end;

constructor TWorker32.CreateShared(var Counter: Int32; Iters: QWord; Mode: Integer; UseOur: Boolean; var StartFlag: LongInt);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FCounter := @Counter;
  FIters := Iters;
  FMode := Mode;
  FUseOur := UseOur;
  FStartFlag := @StartFlag;
end;

procedure TWorker32.Execute;
var i: QWord; v, exp: Int32;
begin
  while InterlockedCompareExchange(FStartFlag^, 1, 1) <> 1 do Sleep(0);
  case FMode of
    0: begin // inc
      if FUseOur then for i := 1 to FIters do v := atomic_increment(FCounter^)
                  else for i := 1 to FIters do v := InterlockedIncrement(FCounter^);
    end;
    1: begin // xadd +1
      if FUseOur then for i := 1 to FIters do v := atomic_fetch_add(FCounter^, 1)
                  else for i := 1 to FIters do v := InterlockedExchangeAdd(FCounter^, 1);
    end;
    2: begin // cas loop ++
      if FUseOur then begin
        for i := 1 to FIters do begin
          repeat
            exp := FCounter^;
          until atomic_compare_exchange_weak(FCounter^, exp, exp+1);
        end;
      end else begin
        for i := 1 to FIters do begin
          repeat
            exp := FCounter^;
          until InterlockedCompareExchange(FCounter^, exp+1, exp) = exp;
        end;
      end;
    end;
  end;
end;

procedure RunMultiThread(itersPerThread: QWord; threads: Integer);
var i: Integer; startFlag: LongInt; t0,t1: Int64; ns: Double; counter: Int32; workers: array of TWorker32;
begin
  Writeln('--- Multi-thread (threads=', threads, ', iters/thread=', itersPerThread, ') ---');
  SetLength(workers, threads);
  // inc 32
  counter := 0; startFlag := 0; for i := 0 to threads-1 do begin workers[i] := TWorker32.CreateShared(counter, itersPerThread, 0, False, startFlag); workers[i].Start; end;
  t0 := GetTicks; InterlockedExchange(startFlag, 1);
  for i := 0 to threads-1 do begin workers[i].WaitFor; workers[i].Free; end; t1 := GetTicks;
  ns := (t1-t0) * NsPerTick / (itersPerThread*threads);
  Writeln(Format('%-28s %-10s ns/op=%.2f total=%d', ['inc32', 'rtl', ns, counter]));

  counter := 0; startFlag := 0; for i := 0 to threads-1 do begin workers[i] := TWorker32.CreateShared(counter, itersPerThread, 0, True, startFlag); workers[i].Start; end;
  t0 := GetTicks; InterlockedExchange(startFlag, 1);
  for i := 0 to threads-1 do begin workers[i].WaitFor; workers[i].Free; end; t1 := GetTicks;
  ns := (t1-t0) * NsPerTick / (itersPerThread*threads);
  Writeln(Format('%-28s %-10s ns/op=%.2f total=%d', ['inc32', 'our', ns, counter]));

  // xadd 32
  counter := 0; startFlag := 0; for i := 0 to threads-1 do begin workers[i] := TWorker32.CreateShared(counter, itersPerThread, 1, False, startFlag); workers[i].Start; end;
  t0 := GetTicks; InterlockedExchange(startFlag, 1);
  for i := 0 to threads-1 do begin workers[i].WaitFor; workers[i].Free; end; t1 := GetTicks;
  ns := (t1-t0) * NsPerTick / (itersPerThread*threads);
  Writeln(Format('%-28s %-10s ns/op=%.2f total=%d', ['fetch_add32 +1', 'rtl', ns, counter]));

  counter := 0; startFlag := 0; for i := 0 to threads-1 do begin workers[i] := TWorker32.CreateShared(counter, itersPerThread, 1, True, startFlag); workers[i].Start; end;
  t0 := GetTicks; InterlockedExchange(startFlag, 1);
  for i := 0 to threads-1 do begin workers[i].WaitFor; workers[i].Free; end; t1 := GetTicks;
  ns := (t1-t0) * NsPerTick / (itersPerThread*threads);
  Writeln(Format('%-28s %-10s ns/op=%.2f total=%d', ['fetch_add32 +1', 'our', ns, counter]));

  // cas loop 32
  counter := 0; startFlag := 0; for i := 0 to threads-1 do begin workers[i] := TWorker32.CreateShared(counter, itersPerThread, 2, False, startFlag); workers[i].Start; end;
  t0 := GetTicks; InterlockedExchange(startFlag, 1);
  for i := 0 to threads-1 do begin workers[i].WaitFor; workers[i].Free; end; t1 := GetTicks;
  ns := (t1-t0) * NsPerTick / (itersPerThread*threads);
  Writeln(Format('%-28s %-10s ns/op=%.2f total=%d', ['cas_loop32 ++', 'rtl', ns, counter]));

  counter := 0; startFlag := 0; for i := 0 to threads-1 do begin workers[i] := TWorker32.CreateShared(counter, itersPerThread, 2, True, startFlag); workers[i].Start; end;
  t0 := GetTicks; InterlockedExchange(startFlag, 1);
  for i := 0 to threads-1 do begin workers[i].WaitFor; workers[i].Free; end; t1 := GetTicks;
  ns := (t1-t0) * NsPerTick / (itersPerThread*threads);
  Writeln(Format('%-28s %-10s ns/op=%.2f total=%d', ['cas_loop32 ++', 'our', ns, counter]));

  Writeln;
end;

var iters: QWord;
begin
  PrintHeader;
  iters := 100000000; // 1e8
  RunSingleThread(iters);
  RunMultiThread(25000000, 4); // 25M per thread, 4 threads
end.

