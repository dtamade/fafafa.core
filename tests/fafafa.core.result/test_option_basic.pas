program test_option_basic;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.option.base,
  fafafa.core.option;

type
  TIntOption = specialize TOption<Integer>;

procedure TestDefaultInitialization;
var
  O: TIntOption;
begin
  WriteLn('Testing default initialization...');
  if O.IsNone then
  begin
    WriteLn('  [PASS] Uninitialized option is None');
    // Also verify UnwrapOr works
    if O.UnwrapOr(999) = 999 then
      WriteLn('  [PASS] UnwrapOr on default-initialized None returns default')
    else
      WriteLn('  [FAIL] UnwrapOr behavior incorrect');
  end
  else
    WriteLn('  [FAIL] Uninitialized option not in expected state');
end;

procedure TestSomeConstruction;
var
  O: TIntOption;
begin
  WriteLn('Testing Some construction...');
  O := TIntOption.Some(42);
  if O.IsSome and (O.Unwrap = 42) then
    WriteLn('  [PASS] Some(42) works correctly')
  else
    WriteLn('  [FAIL] Some construction failed');
end;

procedure TestNoneConstruction;
var
  O: TIntOption;
begin
  WriteLn('Testing None construction...');
  O := TIntOption.None;
  if O.IsNone then
    WriteLn('  [PASS] None construction works correctly')
  else
    WriteLn('  [FAIL] None construction failed');
end;

procedure TestUnwrapOr;
var
  OSome, ONone: TIntOption;
begin
  WriteLn('Testing UnwrapOr...');
  OSome := TIntOption.Some(10);
  ONone := TIntOption.None;
  if (OSome.UnwrapOr(99) = 10) and (ONone.UnwrapOr(99) = 99) then
    WriteLn('  [PASS] UnwrapOr works correctly')
  else
    WriteLn('  [FAIL] UnwrapOr failed');
end;

procedure TestOptionMap;
var
  O, O2: TIntOption;
  
  function AddOne(const X: Integer): Integer;
  begin
    Result := X + 1;
  end;
  
begin
  WriteLn('Testing OptionMap...');
  O := TIntOption.Some(5);
  O2 := specialize OptionMap<Integer, Integer>(O, @AddOne);
  if O2.IsSome and (O2.Unwrap = 6) then
    WriteLn('  [PASS] Map(Some(5)) = Some(6)')
  else
    WriteLn('  [FAIL] OptionMap failed');
end;

procedure TestInspect;
var
  O: TIntOption;
  Inspected: Boolean;
  
  procedure InspectFunc(const X: Integer);
  begin
    Inspected := True;
  end;
  
begin
  WriteLn('Testing Inspect...');
  Inspected := False;
  O := TIntOption.Some(77);
  O := O.Inspect(@InspectFunc);
  if Inspected and O.IsSome then
    WriteLn('  [PASS] Inspect called on Some')
  else
    WriteLn('  [FAIL] Inspect not called or result changed');
end;

begin
  WriteLn('=== fafafa.core.option Smoke Tests ===');
  WriteLn;
  
  TestDefaultInitialization;
  TestSomeConstruction;
  TestNoneConstruction;
  TestUnwrapOr;
  TestOptionMap;
  TestInspect;
  
  WriteLn;
  WriteLn('=== All tests completed ===');
end.
