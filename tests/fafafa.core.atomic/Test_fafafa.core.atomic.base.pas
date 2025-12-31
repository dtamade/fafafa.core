unit Test_fafafa.core.atomic.base;

{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
{$MODE OBJFPC}{$H+}
{$MODESWITCH ADVANCEDRECORDS}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.atomic, fafafa.core.atomic.base;

procedure RegisterAtomicBaseTests;

implementation

type
  TTestCase_AtomicInt32 = class(TTestCase)
  published
    procedure Test_Create_and_Load;
    procedure Test_Store_and_Load;
    procedure Test_Exchange;
    procedure Test_CompareExchangeStrong;
    procedure Test_CompareExchangeWeak;
    procedure Test_FetchAdd;
    procedure Test_FetchSub;
    procedure Test_FetchAnd;
    procedure Test_FetchOr;
    procedure Test_FetchXor;
    procedure Test_Increment_Decrement;
    procedure Test_GetMut_IntoInner;
    procedure Test_MemoryOrders;
  end;

  TTestCase_AtomicBool = class(TTestCase)
  published
    procedure Test_Create_and_Load;
    procedure Test_Store_and_Load;
    procedure Test_Exchange;
    procedure Test_CompareExchange;
    procedure Test_FetchAnd;
    procedure Test_FetchOr;
    procedure Test_FetchXor;
    procedure Test_FetchNand;
  end;

  {$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
  TTestCase_AtomicInt64 = class(TTestCase)
  published
    procedure Test_Create_and_Load;
    procedure Test_Store_and_Load;
    procedure Test_FetchAdd;
    procedure Test_Increment_Decrement;
  end;
  {$ENDIF}

  TTestCase_AtomicPtr = class(TTestCase)
  published
    procedure Test_Create_and_Load;
    procedure Test_Store_and_Load;
    procedure Test_Exchange;
    procedure Test_CompareExchange;
  end;

{ TTestCase_AtomicInt32 }

procedure TTestCase_AtomicInt32.Test_Create_and_Load;
var
  a: TAtomicInt32;
begin
  a := TAtomicInt32.Create(42);
  AssertEquals(42, a.Load);
end;

procedure TTestCase_AtomicInt32.Test_Store_and_Load;
var
  a: TAtomicInt32;
begin
  a := TAtomicInt32.Create(0);
  a.Store(100);
  AssertEquals(100, a.Load);
  a.Store(-50);
  AssertEquals(-50, a.Load);
end;

procedure TTestCase_AtomicInt32.Test_Exchange;
var
  a: TAtomicInt32;
  old: Int32;
begin
  a := TAtomicInt32.Create(10);
  old := a.Exchange(20);
  AssertEquals(10, old);
  AssertEquals(20, a.Load);
end;

procedure TTestCase_AtomicInt32.Test_CompareExchangeStrong;
var
  a: TAtomicInt32;
  expected: Int32;
begin
  a := TAtomicInt32.Create(10);

  // 成功路径
  expected := 10;
  AssertTrue(a.CompareExchangeStrong(expected, 20));
  AssertEquals(20, a.Load);

  // 失败路径
  expected := 10;  // 错误的期望值
  AssertFalse(a.CompareExchangeStrong(expected, 30));
  AssertEquals(20, a.Load);
  AssertEquals(20, expected);  // expected 被更新为实际值
end;

procedure TTestCase_AtomicInt32.Test_CompareExchangeWeak;
var
  a: TAtomicInt32;
  expected: Int32;
begin
  a := TAtomicInt32.Create(10);

  expected := 10;
  AssertTrue(a.CompareExchangeWeak(expected, 20));
  AssertEquals(20, a.Load);
end;

procedure TTestCase_AtomicInt32.Test_FetchAdd;
var
  a: TAtomicInt32;
  old: Int32;
begin
  a := TAtomicInt32.Create(10);
  old := a.FetchAdd(5);
  AssertEquals(10, old);
  AssertEquals(15, a.Load);
end;

procedure TTestCase_AtomicInt32.Test_FetchSub;
var
  a: TAtomicInt32;
  old: Int32;
begin
  a := TAtomicInt32.Create(10);
  old := a.FetchSub(3);
  AssertEquals(10, old);
  AssertEquals(7, a.Load);
end;

procedure TTestCase_AtomicInt32.Test_FetchAnd;
var
  a: TAtomicInt32;
  old: Int32;
begin
  a := TAtomicInt32.Create($FF);
  old := a.FetchAnd($0F);
  AssertEquals($FF, old);
  AssertEquals($0F, a.Load);
end;

procedure TTestCase_AtomicInt32.Test_FetchOr;
var
  a: TAtomicInt32;
  old: Int32;
begin
  a := TAtomicInt32.Create($F0);
  old := a.FetchOr($0F);
  AssertEquals($F0, old);
  AssertEquals($FF, a.Load);
end;

procedure TTestCase_AtomicInt32.Test_FetchXor;
var
  a: TAtomicInt32;
  old: Int32;
begin
  a := TAtomicInt32.Create($FF);
  old := a.FetchXor($0F);
  AssertEquals($FF, old);
  AssertEquals($F0, a.Load);
end;

procedure TTestCase_AtomicInt32.Test_Increment_Decrement;
var
  a: TAtomicInt32;
begin
  a := TAtomicInt32.Create(10);
  AssertEquals(11, a.Increment);
  AssertEquals(11, a.Load);
  AssertEquals(10, a.Decrement);
  AssertEquals(10, a.Load);
end;

procedure TTestCase_AtomicInt32.Test_GetMut_IntoInner;
var
  a: TAtomicInt32;
  p: PInt32;
begin
  a := TAtomicInt32.Create(42);

  // IntoInner - 非原子读取
  AssertEquals(42, a.IntoInner);

  // GetMut - 获取可变指针
  p := a.GetMut;
  AssertEquals(42, p^);
  p^ := 100;  // 直接修改（非原子）
  AssertEquals(100, a.Load);
end;

procedure TTestCase_AtomicInt32.Test_MemoryOrders;
var
  a: TAtomicInt32;
begin
  a := TAtomicInt32.Create(0);

  // 测试不同内存序
  a.Store(1, mo_relaxed);
  AssertEquals(1, a.Load(mo_relaxed));

  a.Store(2, mo_release);
  AssertEquals(2, a.Load(mo_acquire));

  a.Store(3, mo_seq_cst);
  AssertEquals(3, a.Load(mo_seq_cst));
end;

{ TTestCase_AtomicBool }

procedure TTestCase_AtomicBool.Test_Create_and_Load;
var
  a: TAtomicBool;
begin
  a := TAtomicBool.Create(True);
  AssertTrue(a.Load);

  a := TAtomicBool.Create(False);
  AssertFalse(a.Load);
end;

procedure TTestCase_AtomicBool.Test_Store_and_Load;
var
  a: TAtomicBool;
begin
  a := TAtomicBool.Create(False);
  a.Store(True);
  AssertTrue(a.Load);
  a.Store(False);
  AssertFalse(a.Load);
end;

procedure TTestCase_AtomicBool.Test_Exchange;
var
  a: TAtomicBool;
  old: Boolean;
begin
  a := TAtomicBool.Create(False);
  old := a.Exchange(True);
  AssertFalse(old);
  AssertTrue(a.Load);
end;

procedure TTestCase_AtomicBool.Test_CompareExchange;
var
  a: TAtomicBool;
  expected: Boolean;
begin
  a := TAtomicBool.Create(False);

  // 成功路径
  expected := False;
  AssertTrue(a.CompareExchangeStrong(expected, True));
  AssertTrue(a.Load);

  // 失败路径
  expected := False;
  AssertFalse(a.CompareExchangeStrong(expected, False));
  AssertTrue(a.Load);
  AssertTrue(expected);  // expected 被更新
end;

procedure TTestCase_AtomicBool.Test_FetchAnd;
var
  a: TAtomicBool;
begin
  a := TAtomicBool.Create(True);
  AssertTrue(a.FetchAnd(True));   // True AND True = True, 返回旧值 True
  AssertTrue(a.Load);

  AssertTrue(a.FetchAnd(False));  // True AND False = False, 返回旧值 True
  AssertFalse(a.Load);
end;

procedure TTestCase_AtomicBool.Test_FetchOr;
var
  a: TAtomicBool;
begin
  a := TAtomicBool.Create(False);
  AssertFalse(a.FetchOr(False));  // False OR False = False, 返回旧值 False
  AssertFalse(a.Load);

  AssertFalse(a.FetchOr(True));   // False OR True = True, 返回旧值 False
  AssertTrue(a.Load);
end;

procedure TTestCase_AtomicBool.Test_FetchXor;
var
  a: TAtomicBool;
begin
  a := TAtomicBool.Create(True);
  AssertTrue(a.FetchXor(True));   // True XOR True = False, 返回旧值 True
  AssertFalse(a.Load);

  AssertFalse(a.FetchXor(True));  // False XOR True = True, 返回旧值 False
  AssertTrue(a.Load);
end;

procedure TTestCase_AtomicBool.Test_FetchNand;
var
  a: TAtomicBool;
begin
  a := TAtomicBool.Create(True);
  AssertTrue(a.FetchNand(True));  // NOT(True AND True) = False, 返回旧值 True
  AssertFalse(a.Load);

  AssertFalse(a.FetchNand(True)); // NOT(False AND True) = True, 返回旧值 False
  AssertTrue(a.Load);
end;

{$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
{ TTestCase_AtomicInt64 }

procedure TTestCase_AtomicInt64.Test_Create_and_Load;
var
  a: TAtomicInt64;
begin
  a := TAtomicInt64.Create(Int64($123456789ABCDEF0));
  AssertEquals(Int64($123456789ABCDEF0), a.Load);
end;

procedure TTestCase_AtomicInt64.Test_Store_and_Load;
var
  a: TAtomicInt64;
begin
  a := TAtomicInt64.Create(0);
  a.Store(High(Int64));
  AssertEquals(High(Int64), a.Load);
  a.Store(Low(Int64));
  AssertEquals(Low(Int64), a.Load);
end;

procedure TTestCase_AtomicInt64.Test_FetchAdd;
var
  a: TAtomicInt64;
  old: Int64;
begin
  a := TAtomicInt64.Create(100);
  old := a.FetchAdd(50);
  AssertEquals(Int64(100), old);
  AssertEquals(Int64(150), a.Load);
end;

procedure TTestCase_AtomicInt64.Test_Increment_Decrement;
var
  a: TAtomicInt64;
begin
  a := TAtomicInt64.Create(0);
  AssertEquals(Int64(1), a.Increment);
  AssertEquals(Int64(0), a.Decrement);
end;
{$ENDIF}

{ TTestCase_AtomicPtr }

type
  TMyRecord = record
    Value: Integer;
  end;
  PMyRecord = ^TMyRecord;

  TAtomicMyRecordPtr = specialize TAtomicPtr<TMyRecord>;

procedure TTestCase_AtomicPtr.Test_Create_and_Load;
var
  rec: TMyRecord;
  a: TAtomicMyRecordPtr;
begin
  rec.Value := 42;
  a := TAtomicMyRecordPtr.Create(@rec);
  AssertEquals(42, a.Load^.Value);
end;

procedure TTestCase_AtomicPtr.Test_Store_and_Load;
var
  rec1, rec2: TMyRecord;
  a: TAtomicMyRecordPtr;
begin
  rec1.Value := 10;
  rec2.Value := 20;

  a := TAtomicMyRecordPtr.Create(@rec1);
  AssertEquals(10, a.Load^.Value);

  a.Store(@rec2);
  AssertEquals(20, a.Load^.Value);
end;

procedure TTestCase_AtomicPtr.Test_Exchange;
var
  rec1, rec2: TMyRecord;
  a: TAtomicMyRecordPtr;
  old: PMyRecord;
begin
  rec1.Value := 10;
  rec2.Value := 20;

  a := TAtomicMyRecordPtr.Create(@rec1);
  old := a.Exchange(@rec2);

  AssertEquals(10, old^.Value);
  AssertEquals(20, a.Load^.Value);
end;

procedure TTestCase_AtomicPtr.Test_CompareExchange;
var
  rec1, rec2: TMyRecord;
  a: TAtomicMyRecordPtr;
  expected: PMyRecord;
begin
  rec1.Value := 10;
  rec2.Value := 20;

  a := TAtomicMyRecordPtr.Create(@rec1);

  // 成功路径
  expected := @rec1;
  AssertTrue(a.CompareExchangeStrong(expected, @rec2));
  AssertEquals(20, a.Load^.Value);

  // 失败路径
  expected := @rec1;  // 错误的期望值
  AssertFalse(a.CompareExchangeStrong(expected, @rec1));
  AssertTrue(expected = @rec2);  // expected 被更新为实际值
end;

procedure RegisterAtomicBaseTests;
begin
  RegisterTest('fafafa.core.atomic.base.TAtomicInt32', TTestCase_AtomicInt32);
  RegisterTest('fafafa.core.atomic.base.TAtomicBool', TTestCase_AtomicBool);
  {$IF DEFINED(CPU64) OR DEFINED(CPUX86)}
  RegisterTest('fafafa.core.atomic.base.TAtomicInt64', TTestCase_AtomicInt64);
  {$ENDIF}
  RegisterTest('fafafa.core.atomic.base.TAtomicPtr', TTestCase_AtomicPtr);
end;

end.
