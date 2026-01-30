program test_basic_result;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.result;

type
  TIntResult = specialize TResult<Integer, string>;

procedure TestDefaultInitialization;
var
  R: TIntResult;
begin
  WriteLn('Testing default initialization...');
  if R.IsErr and (R.UnwrapErr = '') then
    WriteLn('  [PASS] Uninitialized result is Err with empty string')
  else
    WriteLn('  [FAIL] Uninitialized result not in expected state');
end;

procedure TestOkConstruction;
var
  R: TIntResult;
begin
  WriteLn('Testing Ok construction...');
  R := TIntResult.Ok(42);
  if R.IsOk and (R.Unwrap = 42) then
    WriteLn('  [PASS] Ok(42) works correctly')
  else
    WriteLn('  [FAIL] Ok construction failed');
end;

procedure TestErrConstruction;
var
  R: TIntResult;
begin
  WriteLn('Testing Err construction...');
  R := TIntResult.Err('error');
  if R.IsErr and (R.UnwrapErr = 'error') then
    WriteLn('  [PASS] Err("error") works correctly')
  else
    WriteLn('  [FAIL] Err construction failed');
end;

procedure TestAnd_;
var
  A, B, C: TIntResult;
begin
  WriteLn('Testing And_...');
  A := TIntResult.Ok(1);
  B := TIntResult.Ok(2);
  C := A.And_(B);
  if C.IsOk and (C.Unwrap = 2) then
    WriteLn('  [PASS] Ok.And_(Ok) returns second')
  else
    WriteLn('  [FAIL] And_ failed');
end;

procedure TestOr_;
var
  A, B, C: TIntResult;
begin
  WriteLn('Testing Or_...');
  A := TIntResult.Err('e');
  B := TIntResult.Ok(99);
  C := A.Or_(B);
  if C.IsOk and (C.Unwrap = 99) then
    WriteLn('  [PASS] Err.Or_(Ok) returns second')
  else
    WriteLn('  [FAIL] Or_ failed');
end;

procedure TestInspect;
var
  R: TIntResult;
  Inspected: Boolean;
  
  procedure InspectFunc(const X: Integer);
  begin
    Inspected := True;
  end;
  
begin
  WriteLn('Testing Inspect...');
  Inspected := False;
  R := TIntResult.Ok(77);
  R := R.Inspect(@InspectFunc);
  if Inspected and R.IsOk then
    WriteLn('  [PASS] Inspect called on Ok')
  else
    WriteLn('  [FAIL] Inspect not called or result changed');
end;

procedure TestResultMap;
var
  R, R2: TIntResult;
  
  function AddOne(const X: Integer): Integer;
  begin
    Result := X + 1;
  end;
  
begin
  WriteLn('Testing ResultMap...');
  R := TIntResult.Ok(5);
  R2 := specialize ResultMap<Integer, string, Integer>(R, @AddOne);
  if R2.IsOk and (R2.Unwrap = 6) then
    WriteLn('  [PASS] Map(Ok(5)) = Ok(6)')
  else
    WriteLn('  [FAIL] ResultMap failed');
end;

begin
  WriteLn('=== fafafa.core.result Smoke Tests ===');
  WriteLn;
  
  TestDefaultInitialization;
  TestOkConstruction;
  TestErrConstruction;
  TestAnd_;
  TestOr_;
  TestInspect;
  TestResultMap;
  
  WriteLn;
  WriteLn('=== All tests completed ===');
end.
