unit Test_Contracts_IStack;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

{ 契约测试：IStack（TE 版工厂；批量与能力断言） }

interface

uses
  Classes, SysUtils, fpcunit, testregistry;

{$I test_config.inc}

implementation



uses
  Contracts_Factories_TE_Clean;

type
  TTestCase_IStack_Contracts_Integer = class(TTestCase)
  private
    S: IStackInt;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Stack_Empty_ToStart;
    procedure Test_Stack_Push_Pop_LIFO;
    procedure Test_Stack_TryPeek_OnEmpty_ReturnsFalse;
    procedure Test_Stack_PreAlloc_Bounded_Capacity_Behavior;
    procedure Test_Stack_Batch_APIs;
    procedure Test_Stack_Clear_Behavior;
    procedure Test_Stack_Capabilities;
    {$IFDEF FAFAFA_CORE_ENABLE_CONCURRENCY_TESTS}
    // procedure Test_Stack_Treiber_Smoke_MPMC; // 暂不启用
    // procedure Test_Stack_PreAlloc_Smoke_MPMC; // 暂不启用
    {$ENDIF}
  end;

procedure TTestCase_IStack_Contracts_Integer.SetUp;
begin
  S := GetDefaultStackFactory_Integer_TE.MakeTreiber;
end;

procedure TTestCase_IStack_Contracts_Integer.TearDown;
begin
  S := nil;
end;

procedure TTestCase_IStack_Contracts_Integer.Test_Stack_Empty_ToStart;
begin
  AssertTrue(S.IsEmpty);
  AssertEquals(0, S.Size);
end;

procedure TTestCase_IStack_Contracts_Integer.Test_Stack_Push_Pop_LIFO;
var x: Integer;
begin
  AssertTrue(S.Push(1));
  AssertTrue(S.Push(2));
  AssertTrue(S.TryPop(x)); AssertEquals(2, x);
  AssertTrue(S.TryPop(x)); AssertEquals(1, x);
  AssertTrue(S.IsEmpty);
end;

procedure TTestCase_IStack_Contracts_Integer.Test_Stack_TryPeek_OnEmpty_ReturnsFalse;
var x: Integer;
begin
  AssertTrue(S.IsEmpty);
  AssertFalse(S.TryPeek(x));
end;

procedure TTestCase_IStack_Contracts_Integer.Test_Stack_PreAlloc_Bounded_Capacity_Behavior;
var cap, i: Integer; St: IStackInt; x: Integer; ok: Boolean;
begin
  St := GetDefaultStackFactory_Integer_TE.MakePreAlloc(3);
  AssertTrue(St.Bounded);
  cap := St.Capacity; AssertEquals(3, cap);
  for i := 1 to cap do begin ok := St.Push(i); AssertTrue(ok); end;
  ok := St.Push(999);
  AssertFalse(ok);
  for i := cap downto 1 do begin AssertTrue(St.TryPop(x)); AssertEquals(i, x); end;
  AssertTrue(St.IsEmpty);
end;

procedure TTestCase_IStack_Contracts_Integer.Test_Stack_Batch_APIs;
var inArr: array[0..3] of Integer = (1,2,3,4); outArr: array[0..3] of Integer; n: Integer;
begin
  n := S.PushMany(inArr);
  AssertTrue(n >= 1);
  FillChar(outArr, SizeOf(outArr), 0);
  n := S.PopMany(outArr);
  AssertTrue(n >= 1);
end;

procedure TTestCase_IStack_Contracts_Integer.Test_Stack_Clear_Behavior;
var i: Integer; x: Integer;
begin
  for i := 1 to 5 do S.Push(i);
  S.Clear;
  AssertTrue(S.IsEmpty);
  AssertFalse(S.TryPop(x));
end;

procedure TTestCase_IStack_Contracts_Integer.Test_Stack_Capabilities;
begin
  // Treiber/PreAlloc 在 TE 包装下 HasStats=True
  AssertTrue(S.HasStats);
end;

{$IFDEF FAFAFA_CORE_ENABLE_CONCURRENCY_TESTS}
{$IFDEF FAFAFA_CORE_ENABLE_CONCURRENCY_SMOKE}
procedure TTestCase_IStack_Contracts_Integer.Test_Stack_Treiber_Smoke_MPMC;
var i, x: Integer; s: IStackInt;
begin
  s := GetDefaultStackFactory_Integer_TE.MakeTreiber;
  for i := 1 to 50 do AssertTrue(s.Push(i));
  for i := 50 downto 1 do begin AssertTrue(s.TryPop(x)); AssertEquals(i, x); end;
  AssertTrue(s.IsEmpty);
end;
{$ENDIF}

// 并发烟囱同前，略
{$ENDIF}

initialization
  RegisterTest(TTestCase_IStack_Contracts_Integer);

end.

