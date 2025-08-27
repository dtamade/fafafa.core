unit Test_core_args_edges;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.args,
  args_test_helper;

procedure RegisterTests;

implementation

type
  TTestCase_Core_Args_Edges = class(TTestCase)
  published
    procedure Test_StopAtDoubleDash_On_WindowsOption_After_Is_Positional;
    procedure Test_ShortKey_SpaceValue_Disabled_Becomes_Positional;
    procedure Test_TreatNegative_As_Positionals_On;
    procedure Test_NoPrefixNegation_With_CI_LastWins;
    procedure Test_ShortFlagsCombo_Off_With_WindowsSlash;
  end;

procedure TTestCase_Core_Args_Edges.Test_StopAtDoubleDash_On_WindowsOption_After_Is_Positional;
var opts: TArgsOptions; a: TArgs; arr: array of string;
begin
  opts := MakeDefaultOpts;
  opts.StopAtDoubleDash := True; // default behavior: "--" is a sentinel and not included in positionals
  SetLength(arr, 3);
  arr[0] := '--';
  arr[1] := '/x';
  arr[2] := '--literal';
  a := TArgs.FromArray(arr, opts);
  AssertEquals(2, Length(a.Positionals));
  AssertEquals('/x', a.Positionals[0]);
  AssertEquals('--literal', a.Positionals[1]);
end;

procedure TTestCase_Core_Args_Edges.Test_ShortKey_SpaceValue_Disabled_Becomes_Positional;
var opts: TArgsOptions; a: TArgs; arr: array of string; v: string;
begin
  opts := MakeDefaultOpts;
  opts.AllowShortKeyValue := False; // disable "-o out.txt" pairing
  SetLength(arr, 2);
  arr[0] := '-o';
  arr[1] := 'out.txt';
  a := TArgs.FromArray(arr, opts);
  // -o should be a flag without value, 'out.txt' becomes positional
  AssertTrue(a.HasFlag('o'));
  AssertFalse(a.TryGetValue('o', v));
  AssertEquals(1, Length(a.Positionals));
  AssertEquals('out.txt', a.Positionals[0]);
end;

procedure TTestCase_Core_Args_Edges.Test_TreatNegative_As_Positionals_On;
var opts: TArgsOptions; a: TArgs; arr: array of string; v: string;
begin
  opts := MakeDefaultOpts;
  opts.TreatNegativeNumbersAsPositionals := True;
  SetLength(arr, 3);
  arr[0] := '--n';
  arr[1] := '--';
  arr[2] := '-1';
  a := TArgs.FromArray(arr, opts);
  // With TreatNegativeNumbersAsPositionals=True, negative numbers are not consumed as values even before "--";
  // placing "--" ensures any following tokens are positionals.
  AssertTrue(a.HasFlag('n'));
  AssertFalse(a.TryGetValue('n', v));
  AssertEquals(1, Length(a.Positionals));
  AssertEquals('-1', a.Positionals[0]);
end;

procedure RegisterTests;
begin
  RegisterTest('TTestCase_Core_Args_Edges', TTestCase_Core_Args_Edges.Suite);
end;

procedure TTestCase_Core_Args_Edges.Test_NoPrefixNegation_With_CI_LastWins;
var opts: TArgsOptions; a: TArgs; arr: array of string; b: boolean;
begin
  opts := MakeDefaultOpts; // EnableNoPrefixNegation=True by default
  opts.CaseInsensitiveKeys := True;
  SetLength(arr, 4);
  arr[0] := '--Foo';
  arr[1] := '--no-foo';
  arr[2] := '--foo=true';
  arr[3] := '--NO-FOO=false';
  a := TArgs.FromArray(arr, opts);
  // CI + last-wins: 最后一次 --no-foo 覆盖到 False
  AssertTrue(a.TryGetBool('foo', b));
  AssertFalse(b);
end;

procedure TTestCase_Core_Args_Edges.Test_ShortFlagsCombo_Off_With_WindowsSlash;
var opts: TArgsOptions; a: TArgs; arr: array of string;
begin
  opts := MakeDefaultOpts;
  opts.AllowShortFlagsCombo := False;
  SetLength(arr, 2);
  arr[0] := '/ab'; // Windows slash 前缀
  arr[1] := '-ab'; // Unix 风格短旗组合
  a := TArgs.FromArray(arr, opts);
  // 组合被禁用，/ab 与 -ab 都应作为单个短flag，而不是 a 和 b 的组合
  AssertTrue(a.HasFlag('ab'));
  AssertFalse(a.HasFlag('a'));
  AssertFalse(a.HasFlag('b'));
end;

end.

