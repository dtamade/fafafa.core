unit Test_core_args;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry, fafafa.core.args, args_test_helper;

type
  TTestCase_Core_Args = class(TTestCase)
  published
    procedure Test_Long_Short_Windows_Forms;
    procedure Test_MultiValue_And_Positionals;
    procedure Test_DoubleDash_And_Negative;
    procedure Test_Typed_Getters;
    procedure Test_Iterators;
    procedure Test_Options_Toggles_CaseSensitivity;
    procedure Test_Options_Toggles_ShortFlagsCombo_Off;
    procedure Test_Options_Toggles_StopAtDoubleDash_Off;
    procedure Test_Options_Toggles_TreatNegative_As_Flags;
    procedure Test_NoPrefix_Negation_Enable;
    procedure Test_Windows_Help_Shortcut;
    procedure Test_Windows_Help_CaseInsensitive;
    procedure Test_ShortKey_SpaceSeparated_Value;
    procedure Test_StopAtDoubleDash_Off_WindowsOption_After;
    procedure Test_NoPrefix_Negation_Order_LastWins;
    procedure Test_DoubleDash_StopOff_WindowsLiteral; // new
    procedure Test_NoPrefix_Negation_With_Explicit_Override_Again; // new
    procedure Test_NoPrefix_Negation_Explicit_On_NoKey_LastWins_ReverseOrder; // new
    procedure Test_DoubleDash_StopOff_NoPrefixTokens_After_Are_Positionals; // new
    procedure Test_NoPrefix_Negation_DashToDot_Normalization; // new
    procedure Test_NoPrefix_Negation_Windows_Slash; // new
    procedure Test_NoPrefix_Negation_CI_DashDot; // new

    procedure Test_NoPrefix_Negation_Windows_CI_Override_LastWins; // new


  end;

procedure RegisterTests;

implementation

procedure TTestCase_Core_Args.Test_Long_Short_Windows_Forms;
var opts: TArgsOptions; arr: array of string; A: TArgs; v: string;
begin
  opts := MakeDefaultOpts;
  SetLength(arr, 6);
  arr[0] := '--json=out.json';
  arr[1] := '--console:file:log.txt';
  arr[2] := '-abc';
  arr[3] := '-o:out.txt';
  arr[4] := '/k=v';
  arr[5] := '/opt:val';
  A := TArgs.FromArray(arr, opts);
  AssertTrue(A.HasFlag('a'));
  AssertTrue(A.HasFlag('b'));
  AssertTrue(A.HasFlag('c'));
  AssertTrue(A.TryGetValue('json', v));
  AssertTrue(A.TryGetValue('o', v));
end;

procedure TTestCase_Core_Args.Test_MultiValue_And_Positionals;
var opts: TArgsOptions; arr: array of string; vals: TStringArray; A: TArgs;
begin
  opts := MakeDefaultOpts;
  SetLength(arr, 6);
  arr[0] := '--tag=a';
  arr[1] := '--tag=b';
  arr[2] := 'file1';
  arr[3] := '--';
  arr[4] := '--not-flag';
  arr[5] := 'file2';
  A := TArgs.FromArray(arr, opts);
  vals := A.GetAll('tag');
  AssertEquals(2, Length(vals));
  AssertEquals('file1', A.Positionals[0]);
  AssertEquals('--not-flag', A.Positionals[1]);
  AssertEquals('file2', A.Positionals[2]);
end;

procedure TTestCase_Core_Args.Test_DoubleDash_And_Negative;
var opts: TArgsOptions; arr: array of string; v: string; A: TArgs;
begin
  opts := MakeDefaultOpts;
  SetLength(arr, 3);
  arr[0] := '--value';
  arr[1] := '-1.23';
  arr[2] := '--';
  A := TArgs.FromArray(arr, opts);
  AssertTrue(A.TryGetValue('value', v));
  AssertEquals('-1.23', v);
end;

procedure TTestCase_Core_Args.Test_Typed_Getters;
var a: TArgs; opts: TArgsOptions;
    arr: array of string; n: Int64; d: Double; b: boolean;
begin
  opts := MakeDefaultOpts;
  SetLength(arr, 4);
  arr[0] := '--samples=10';
  arr[1] := '--rate:2.5';
  arr[2] := '--enabled=true';
  arr[3] := 'pos1';
  a := TArgs.FromArray(arr, opts);
  AssertTrue(a.TryGetInt64('samples', n)); AssertEquals(10, n);
  AssertTrue(a.TryGetDouble('rate', d)); AssertTrue(Abs(d-2.5) < 1e-9);
  AssertTrue(a.TryGetBool('enabled', b)); AssertTrue(b);
  AssertEquals('pos1', a.Positionals[0]);
end;

procedure TTestCase_Core_Args.Test_Iterators;
var a: TArgs; opts: TArgsOptions;
    arr: array of string; countAll, countOpts: Integer;
    eAll: TArgsEnumerator; eOpt: TArgsOptionEnumerator;
begin
  opts := ArgsOptionsDefault;
  SetLength(arr, 3);
  arr[0] := 'file';
  arr[1] := '--x=1';
  arr[2] := '-ab';
  a := TArgs.FromArray(arr, opts);
  countAll := 0;
  eAll := TArgsEnumerator(a.GetEnumerator);
  while eAll.MoveNext do Inc(countAll);
  AssertEquals(4, countAll); // file, --x, -a, -b

  countOpts := 0;
  eOpt := TArgsOptionEnumerator(a.GetOptionEnumerator);
  while eOpt.MoveNext do Inc(countOpts);
  AssertEquals(3, countOpts); // --x, -a, -b
end;

procedure TTestCase_Core_Args.Test_Options_Toggles_CaseSensitivity;
var opts: TArgsOptions; arr: array of string; v: string; A: TArgs;
begin
  opts := MakeDefaultOpts; opts.CaseInsensitiveKeys := False;
  SetLength(arr, 2);
  arr[0] := '--Json=Out';
  arr[1] := '--help';
  A := TArgs.FromArray(arr, opts);
  AssertFalse('case-sensitive key mismatch', A.TryGetValue('json', v));
  AssertTrue(A.TryGetValue('Json', v));
  AssertEquals('Out', v);
  AssertTrue(A.HasFlag('help'));
end;

procedure TTestCase_Core_Args.Test_Options_Toggles_ShortFlagsCombo_Off;
var opts: TArgsOptions; arr: array of string; A: TArgs;
begin
  opts := MakeDefaultOpts; opts.AllowShortFlagsCombo := False;
  SetLength(arr, 1);
  arr[0] := '-abc';
  A := TArgs.FromArray(arr, opts);
  // when combo off, treat as a single flag name 'abc'
  AssertTrue(A.HasFlag('abc'));
  AssertFalse(A.HasFlag('a'));
end;

procedure TTestCase_Core_Args.Test_Options_Toggles_StopAtDoubleDash_Off;
var opts: TArgsOptions; arr: array of string; A: TArgs;
begin
  opts := MakeDefaultOpts; opts.StopAtDoubleDash := False;
  SetLength(arr, 3);
  arr[0] := 'pos1';
  arr[1] := '--';
  arr[2] := '--x';
  A := TArgs.FromArray(arr, opts);
  // double dash is treated as a normal positional when StopAtDoubleDash=False
  AssertEquals(3, Length(A.Positionals));
  AssertEquals('pos1', A.Positionals[0]);
  AssertEquals('--', A.Positionals[1]);
  AssertEquals('--x', A.Positionals[2]);
end;

procedure TTestCase_Core_Args.Test_Options_Toggles_TreatNegative_As_Flags;
var opts: TArgsOptions; arr: array of string; v: string; A: TArgs;
begin
  opts := MakeDefaultOpts; opts.TreatNegativeNumbersAsPositionals := False;
  SetLength(arr, 2);
  arr[0] := '--n';
  arr[1] := '-1';
  A := TArgs.FromArray(arr, opts);
  // since TreatNegativeNumbersAsPositionals=False the -1 should not be forced into value; NextIsValue returns False
  // so --n is treated as flag, and -1 becomes short flag '1'
  AssertTrue(A.HasFlag('n'));
  AssertFalse(A.TryGetValue('n', v));
  AssertTrue(A.HasFlag('1'));
end;


procedure RegisterTests;
begin
  testregistry.RegisterTest(TTestCase_Core_Args);
end;


procedure TTestCase_Core_Args.Test_NoPrefix_Negation_Enable;
var opts: TArgsOptions; arr: array of string; A: TArgs; v: string; b: boolean;
begin
  opts := MakeDefaultOpts; opts.EnableNoPrefixNegation := True;
  SetLength(arr, 3);
  arr[0] := '--no-color';
  arr[1] := '/no-verbose';
  arr[2] := '-no-debug';
  A := TArgs.FromArray(arr, opts);
  AssertTrue(A.TryGetBool('color', b)); AssertFalse(b);
  AssertTrue(A.TryGetBool('verbose', b)); AssertFalse(b);
  AssertTrue(A.TryGetBool('debug', b)); AssertFalse(b);
  // explicit values still override
  SetLength(arr, 2);
  arr[0] := '--no-cache=true';
  arr[1] := '--no-cache=false';
  A := TArgs.FromArray(arr, opts);
  AssertTrue(A.TryGetValue('no-cache', v)); // treated as key 'no-cache' with value per explicit assignment
  AssertEquals('false', v);
end;

procedure TTestCase_Core_Args.Test_Windows_Help_Shortcut;
var opts: TArgsOptions; arr: array of string; A: TArgs;
begin
  opts := MakeDefaultOpts; SetLength(arr,1); arr[0] := '/?';
  A := TArgs.FromArray(arr, opts);
  AssertTrue(A.HasFlag('help'));
end;

procedure TTestCase_Core_Args.Test_Windows_Help_CaseInsensitive;
var opts: TArgsOptions; arr: array of string; A: TArgs;
begin
  opts := MakeDefaultOpts; SetLength(arr,1); arr[0] := '/Help';
  A := TArgs.FromArray(arr, opts);
  AssertTrue(A.HasFlag('help'));
end;

procedure TTestCase_Core_Args.Test_ShortKey_SpaceSeparated_Value;
var opts: TArgsOptions; arr: array of string; A: TArgs; v: string;
begin
  opts := MakeDefaultOpts;
  SetLength(arr, 2);
  arr[0] := '-o';
  arr[1] := 'out.txt';
  A := TArgs.FromArray(arr, opts);
  AssertTrue(A.TryGetValue('o', v));
  AssertEquals('out.txt', v);
end;

procedure TTestCase_Core_Args.Test_StopAtDoubleDash_Off_WindowsOption_After;
var opts: TArgsOptions; arr: array of string; A: TArgs;
begin
  opts := MakeDefaultOpts; opts.StopAtDoubleDash := False;
  SetLength(arr, 3);
  arr[0] := 'pos1';
  arr[1] := '--';
  arr[2] := '/x';
  A := TArgs.FromArray(arr, opts);
  AssertEquals(3, Length(A.Positionals));
  AssertEquals('pos1', A.Positionals[0]);
  AssertEquals('--', A.Positionals[1]);
  AssertEquals('/x', A.Positionals[2]);
end;

procedure TTestCase_Core_Args.Test_NoPrefix_Negation_Order_LastWins;
var opts: TArgsOptions; arr: array of string; A: TArgs; v: string; b: boolean;
begin
  opts := MakeDefaultOpts; opts.EnableNoPrefixNegation := True;
  SetLength(arr, 3);
  arr[0] := '--no-color';     // color=false
  arr[1] := '--color=true';   // explicit override -> true
  arr[2] := '--color=false';  // final override -> false
  A := TArgs.FromArray(arr, opts);
  AssertTrue(A.TryGetValue('color', v));
  AssertEquals('false', v);
  AssertTrue(A.TryGetBool('color', b));
  AssertFalse(b);
end;




procedure TTestCase_Core_Args.Test_DoubleDash_StopOff_WindowsLiteral;
var opts: TArgsOptions; arr: array of string; A: TArgs;
begin
  opts := ArgsOptionsDefault; opts.StopAtDoubleDash := False;
  SetLength(arr, 4);
  arr[0] := 'pos1';
  arr[1] := '--';
  arr[2] := '/x';
  arr[3] := '--literal';
  A := TArgs.FromArray(arr, opts);
  AssertEquals(4, Length(A.Positionals));
  AssertEquals('pos1', A.Positionals[0]);
  AssertEquals('--', A.Positionals[1]);
  AssertEquals('/x', A.Positionals[2]);
  AssertEquals('--literal', A.Positionals[3]);
end;

procedure TTestCase_Core_Args.Test_NoPrefix_Negation_With_Explicit_Override_Again;
var opts: TArgsOptions; arr: array of string; A: TArgs; v: string; b: boolean;
begin
  opts := MakeDefaultOpts; opts.EnableNoPrefixNegation := True;
  SetLength(arr, 3);
  arr[0] := '--no-cache';      // cache=false via no- prefix
  arr[1] := '--cache=true';    // explicit override -> true
  arr[2] := '--no-cache=false';// explicit assignment on no- key -> false (last wins)
  A := TArgs.FromArray(arr, opts);
  AssertTrue(A.TryGetValue('cache', v)); AssertEquals('false', v);
  AssertTrue(A.TryGetBool('cache', b)); AssertFalse(b);
end;

procedure TTestCase_Core_Args.Test_NoPrefix_Negation_Explicit_On_NoKey_LastWins_ReverseOrder;
var opts: TArgsOptions; arr: array of string; A: TArgs; v: string; b: boolean;
begin
  opts := ArgsOptionsDefault; opts.EnableNoPrefixNegation := True;
  SetLength(arr, 3);
  arr[0] := '--color=true';     // explicit sets true
  arr[1] := '--no-color=false'; // explicit on no- key sets false (should affect color)
  arr[2] := '--no-color';       // no-value negation -> color=false (last wins)
  A := TArgs.FromArray(arr, opts);
  AssertTrue(A.TryGetValue('color', v)); AssertEquals('false', v);
  AssertTrue(A.TryGetBool('color', b)); AssertFalse(b);
end;

procedure TTestCase_Core_Args.Test_DoubleDash_StopOff_NoPrefixTokens_After_Are_Positionals;
var opts: TArgsOptions; arr: array of string; A: TArgs;
begin
  opts := MakeDefaultOpts; opts.EnableNoPrefixNegation := True; opts.StopAtDoubleDash := False;
  SetLength(arr, 4);
  arr[0] := 'pos1';
  arr[1] := '--';
  arr[2] := '-no-x';
  arr[3] := '--no-y';
  A := TArgs.FromArray(arr, opts);
  AssertEquals(4, Length(A.Positionals));
  AssertEquals('pos1', A.Positionals[0]);
  AssertEquals('--', A.Positionals[1]);
  AssertEquals('-no-x', A.Positionals[2]);
  AssertEquals('--no-y', A.Positionals[3]);
end;

procedure TTestCase_Core_Args.Test_NoPrefix_Negation_DashToDot_Normalization;
var opts: TArgsOptions; arr: array of string; A: TArgs; v: string; b: boolean;
begin
  opts := MakeDefaultOpts; opts.EnableNoPrefixNegation := True;
  SetLength(arr, 2);
  arr[0] := '--no-app-name'; // should map to base key 'app.name' = false after dash->dot
  arr[1] := '--app.name=true'; // explicit override on dotted key -> true (last wins)
  A := TArgs.FromArray(arr, opts);
  AssertTrue(A.TryGetValue('app.name', v)); AssertEquals('true', v);
  AssertTrue(A.TryGetBool('app.name', b)); AssertTrue(b);
end;


procedure TTestCase_Core_Args.Test_NoPrefix_Negation_Windows_Slash;
var opts: TArgsOptions; arr: array of string; A: TArgs; b: boolean;
begin
  opts := ArgsOptionsDefault; opts.EnableNoPrefixNegation := True;
  SetLength(arr, 1);
  arr[0] := '/no-verbose';
  A := TArgs.FromArray(arr, opts);
  AssertTrue(A.TryGetBool('verbose', b));
  AssertFalse(b);
end;

procedure TTestCase_Core_Args.Test_NoPrefix_Negation_CI_DashDot;
var opts: TArgsOptions; arr: array of string; A: TArgs; b: boolean;
begin
  opts := MakeDefaultOpts; opts.EnableNoPrefixNegation := True; opts.CaseInsensitiveKeys := True;
  SetLength(arr, 2);
  arr[0] := '--no-App-Name';   // CI + dash
  arr[1] := '--APP.NAME=false';// CI + dot
  A := TArgs.FromArray(arr, opts);
  AssertTrue(A.TryGetBool('app.name', b));
  AssertFalse(b);
end;



procedure TTestCase_Core_Args.Test_NoPrefix_Negation_Windows_CI_Override_LastWins;
var opts: TArgsOptions; arr: array of string; A: TArgs; b: boolean; v: string;
begin
  opts := MakeDefaultOpts;
  opts.EnableNoPrefixNegation := True;
  opts.CaseInsensitiveKeys := True;
  SetLength(arr, 3);
  arr[0] := '/no-Verbose';     // CI + Windows slash
  arr[1] := '--VERBOSE=true';  // explicit override to true
  arr[2] := '/no-VERBOSE=false'; // explicit on no- key -> false (last wins)
  A := TArgs.FromArray(arr, opts);
  AssertTrue(A.TryGetBool('verbose', b)); AssertFalse(b);
  AssertTrue(A.TryGetValue('verbose', v)); AssertEquals('false', v);
end;

end.



