unit fafafa.core.env.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.env,
  fafafa.core.result;

type
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_env_expand_basic;
    procedure Test_env_expand_edges;
    procedure Test_env_expand_doubledollar_escape;
    procedure Test_env_expand_env_delegates;
    procedure Test_env_expand_with_custom_mapper;
    {$IFDEF WINDOWS}
    procedure Test_env_expand_doublepercent_escape;
    procedure Test_env_expand_case_insensitive;
    {$ENDIF}
    procedure Test_env_join_paths_checked_reports_error;
    procedure Test_env_get_or_fallback;

    procedure Test_env_split_join_paths_roundtrip;
    procedure Test_env_split_join_paths_roundtrip2;
    procedure Test_env_get_set_unset_rollback;
    procedure Test_env_user_dirs_best_effort;

    procedure Test_env_vars_snapshot;
    procedure Test_env_cwd_and_exepath;
    procedure Test_env_overrides_basic_restore;
    procedure Test_env_overrides_duplicate_keys;

    // New tests for improved semantics
    procedure Test_env_lookup_defined_empty_vs_undefined;
    procedure Test_env_override_unset_behavior;
    procedure Test_env_has_defined_and_undefined;

    // Result API (env)
    procedure Test_env_get_result_ok;
    procedure Test_env_get_result_err;
    procedure Test_env_join_paths_result_ok;
    procedure Test_env_join_paths_result_err;

    // Result API (directories)
    procedure Test_env_current_dir_result_ok;
    procedure Test_env_set_current_dir_result_ok;
    procedure Test_env_set_current_dir_result_err;

    // Result API (queries)
    procedure Test_env_home_temp_exe_user_dirs_result_ok;

    // Additional boundary tests
    procedure Test_env_path_list_separator_platform;
    procedure Test_env_join_paths_skip_empty_segments;
    procedure Test_env_expand_trailing_dollar_literal;
    procedure Test_env_expand_braced_empty_name;
    procedure Test_env_expand_name_with_hyphen_stops_before;
    {$IFDEF WINDOWS}
    procedure Test_env_expand_unmatched_percent_literal_windows;
    {$ENDIF}

    // Extreme cases added later
    procedure Test_env_split_paths_preserve_spaces_and_dot_segments;
    procedure Test_env_join_paths_preserve_segments_verbatim;
    procedure Test_env_split_paths_multiple_separators_collapsed;
    procedure Test_env_expand_with_unicode_braced_name;
    {$IFDEF WINDOWS}
    procedure Test_env_expand_percent_with_space_name_windows;
    {$ENDIF}
    procedure Test_env_join_paths_with_relative_and_dots_roundtrip;

  end;

implementation

function Test_Env_Map_AB(const K: string; out V: string): Boolean;
begin
  if K = 'A' then begin V := '1'; Exit(True); end;
  if K = 'B' then begin V := '2'; Exit(True); end;
  V := '';
  Result := False;
end;


procedure TTestCase_Global.Test_env_path_list_separator_platform;
begin
  {$IFDEF WINDOWS}
  AssertEquals(';', env_path_list_separator);
  {$ELSE}
  AssertEquals(':', env_path_list_separator);
  {$ENDIF}
end;

procedure TTestCase_Global.Test_env_join_paths_skip_empty_segments;
var joined: string; arr: array of string;
begin
  SetLength(arr, 4);
  arr[0] := 'a';
  arr[1] := '';
  arr[2] := 'b';
  arr[3] := '';
  joined := env_join_paths(arr);
  AssertTrue(Pos('a', joined) > 0);
  AssertTrue(Pos('b', joined) > 0);
  {$IFDEF WINDOWS}
  AssertEquals('a;b', joined);
  {$ELSE}
  AssertEquals('a:b', joined);
  {$ENDIF}
end;

procedure TTestCase_Global.Test_env_expand_doubledollar_escape;
var s: string;
begin
  s := env_expand('cost=$$5');
  AssertEquals('cost=$5', s);
end;

procedure TTestCase_Global.Test_env_expand_env_delegates;
var s, old: string; had: boolean;
begin
  old := env_get('FA_ENV_DELEGATE'); had := old <> '';
  env_set('FA_ENV_DELEGATE', 'X');
  try
    s := env_expand_env('pre-$FA_ENV_DELEGATE-post');
    AssertEquals('pre-X-post', s);
  finally
    if had then env_set('FA_ENV_DELEGATE', old) else env_unset('FA_ENV_DELEGATE');
  end;
end;

procedure TTestCase_Global.Test_env_expand_with_custom_mapper;
var s: string;
begin
  s := env_expand_with('($A,$B,$C)', @Test_Env_Map_AB);
  AssertEquals('(1,2,)', s);
end;

{$IFDEF WINDOWS}
procedure TTestCase_Global.Test_env_expand_doublepercent_escape;
var s: string;
begin
  s := env_expand('100%% ready');
  AssertEquals('100% ready', s);
end;

procedure TTestCase_Global.Test_env_expand_case_insensitive;
var old: string; had: boolean; s: string;
begin
  old := env_get('FA_ENV_CASE'); had := old <> '';
  env_set('FA_ENV_CASE', 'hi');
  try
    s := env_expand('%fa_env_case%');
    AssertEquals('hi', s);
  finally
    if had then env_set('FA_ENV_CASE', old) else env_unset('FA_ENV_CASE');
  end;
end;
{$ENDIF}


procedure TTestCase_Global.Test_env_expand_basic;
var s, old: string; had: boolean;
begin
  old := env_get('FA_ENV_X'); had := old <> '';
  env_set('FA_ENV_X', '42');
  try
    s := env_expand('x=${FA_ENV_X} $FA_ENV_X');
    AssertTrue(Pos('42', s) > 0);
    {$IFDEF WINDOWS}
    s := env_expand('%FA_ENV_X%');
    AssertEquals('42', s);
    {$ENDIF}
  finally
    if had then env_set('FA_ENV_X', old) else env_unset('FA_ENV_X');
  end;
end;

procedure TTestCase_Global.Test_env_expand_edges;
var s: string;
begin
  // Lone '$' and invalid start like $5 should not expand
  s := env_expand('price is $$5');
  AssertEquals('price is $5', StringReplace(s,'$','$',[]));
  s := env_expand('num=$5');
  AssertEquals('num=$5', s);
  // Braced empty or missing close -> treat gracefully
  s := env_expand('${NOT_SET');
  AssertEquals('', s); // our impl stops at end and returns empty

  // Trailing '$' – should be literal '$'
  s := env_expand('end$');
  AssertEquals('end$', s);

  // Braced empty name: ${} -> empty resolution
  s := env_expand('${}');
  AssertEquals('', s);

  // Name with hyphen: stops before '-' and treats rest literally
  env_set('FA_HY', 'H');
  s := env_expand('$FA_HY-REST');
  AssertEquals('H-REST', s);
  env_unset('FA_HY');
end;

procedure TTestCase_Global.Test_env_split_join_paths_roundtrip;
var p: string; arr: array of string; j: string;
begin
  p := 'a' + env_path_list_separator + 'b' + env_path_list_separator + 'c';
  arr := env_split_paths(p);

  AssertEquals(3, Length(arr));

  j := env_join_paths(arr);
  AssertEquals(p, j);
end;

procedure TTestCase_Global.Test_env_split_join_paths_roundtrip2;
var p: string; arr: array of string; j: string;
begin
  p := env_path_list_separator + 'a' + env_path_list_separator + env_path_list_separator + 'b' + env_path_list_separator;
  arr := env_split_paths(p);
  AssertTrue(Length(arr) >= 2);
  j := env_join_paths(arr);
  AssertTrue(Pos('a', j) > 0);
  AssertTrue(Pos('b', j) > 0);
end;

procedure TTestCase_Global.Test_env_get_set_unset_rollback;
var name, old: string; had: boolean;
begin
  name := 'FA_ENV_TEMP_CASE';
  old := env_get(name); had := old <> '';
  try
    AssertTrue(env_set(name, 'hello'));
    AssertEquals('hello', env_get(name));
    AssertTrue(env_unset(name));
    AssertEquals('', env_get(name)); // by contract: absent -> ''
  finally
    if had then env_set(name, old) else env_unset(name);
  end;
end;

procedure TTestCase_Global.Test_env_user_dirs_best_effort;
var home, tmp, cfg, cache: string;
begin
  home := env_home_dir;
  tmp := env_temp_dir;
  cfg := env_user_config_dir;
  cache := env_user_cache_dir;
  AssertTrue(tmp <> '');
  AssertTrue(Length(tmp) > 0);
  AssertTrue(Length(home) >= 0);
end;


procedure TTestCase_Global.Test_env_join_paths_checked_reports_error;
var arr: array of string; j: string; idx: Integer;
begin
  SetLength(arr, 3);
  arr[0] := 'a';
  arr[1] := 'b' + env_path_list_separator + 'x'; // illegal
  arr[2] := 'c';
  j := env_join_paths_checked(arr, idx);
  AssertEquals('', j);
  AssertTrue(idx = 1);

  // Also check that embedded separator at index 0 fails and reports index 0
  SetLength(arr, 2);
  arr[0] := 'a' + env_path_list_separator + 'b';
  arr[1] := 'c';
  j := env_join_paths_checked(arr, idx);
  AssertEquals('', j);
  AssertTrue(idx = 0);
end;

procedure TTestCase_Global.Test_env_get_or_fallback;
var name, old, got: string; had: boolean;
begin
  name := 'FA_ENV_OR';
  old := env_get(name); had := old <> '';
  env_unset(name);
  try
    got := env_get_or(name, 'default');
    AssertEquals('default', got);
  finally
    if had then env_set(name, old) else env_unset(name);
  end;
end;

procedure TTestCase_Global.Test_env_vars_snapshot;
var lst: TStringList;
begin
  lst := TStringList.Create;
  try
    env_vars(lst);
    AssertTrue(lst.Count >= 0);
  finally
    lst.Free;
  end;
end;

procedure TTestCase_Global.Test_env_cwd_and_exepath;
var cwd: string;
begin
  cwd := env_current_dir;
  AssertTrue(DirectoryExists(cwd));
  AssertTrue(env_executable_path <> '');
end;

procedure TTestCase_Global.Test_env_overrides_basic_restore;
var g: TEnvOverridesGuard; aOld, bOld: string; aHad, bHad: boolean; kvs: array of TEnvKV;
begin
  aOld := env_get('FA_ENV_A'); aHad := aOld <> '';
  bOld := env_get('FA_ENV_B'); bHad := bOld <> '';

  SetLength(kvs, 2);
  kvs[0].Name := 'FA_ENV_A'; kvs[0].Value := '1'; kvs[0].HasValue := True;
  kvs[1].Name := 'FA_ENV_B'; kvs[1].HasValue := False;
  g := env_overrides(kvs);
  try
    AssertEquals('1', env_get('FA_ENV_A'));
    AssertEquals('', env_get('FA_ENV_B'));
  finally
    g.Done;
  end;
  if aHad then AssertEquals(aOld, env_get('FA_ENV_A')) else AssertEquals('', env_get('FA_ENV_A'));
  if bHad then AssertEquals(bOld, env_get('FA_ENV_B')) else AssertEquals('', env_get('FA_ENV_B'));
end;

procedure TTestCase_Global.Test_env_overrides_duplicate_keys;
var g: TEnvOverridesGuard; old: string; had: boolean; kvs: array of TEnvKV;
begin
  old := env_get('FA_ENV_DUP'); had := old <> '';

  SetLength(kvs, 4);
  kvs[0].Name := 'FA_ENV_DUP'; kvs[0].Value := 'x'; kvs[0].HasValue := True;
  kvs[1].Name := 'FA_ENV_DUP'; kvs[1].Value := 'y'; kvs[1].HasValue := True;
  kvs[2].Name := 'FA_ENV_DUP'; kvs[2].HasValue := False;
  kvs[3].Name := 'FA_ENV_DUP'; kvs[3].Value := 'z'; kvs[3].HasValue := True;
  g := env_overrides(kvs);
  try
    AssertEquals('z', env_get('FA_ENV_DUP'));
  finally
    g.Done;
  end;
  if had then AssertEquals(old, env_get('FA_ENV_DUP')) else AssertEquals('', env_get('FA_ENV_DUP'));
end;

procedure TTestCase_Global.Test_env_lookup_defined_empty_vs_undefined;
var name, old: string; had, ok: boolean; val: string;
begin
  name := 'FA_ENV_EMPTY_CASE';
  old := env_get(name); had := old <> '';
  try
    // Ensure undefined
    env_unset(name);
    ok := env_lookup(name, val);
    AssertFalse('undefined should return False', ok);

    // Defined but empty
    AssertTrue(env_set(name, ''));
    ok := env_lookup(name, val);
    AssertTrue('defined empty should return True', ok);
    AssertEquals('', val);
  finally
    if had then env_set(name, old) else env_unset(name);
  end;
end;

procedure TTestCase_Global.Test_env_override_unset_behavior;
var g: TEnvOverrideGuard; name, origBefore, preGuard: string; hadOrig: boolean;
begin
  name := 'FA_ENV_OVERRIDE_UNSET_CASE';
  // Snapshot original state before this test mutates the env
  origBefore := env_get(name); hadOrig := origBefore <> '';
  try
    // Set a value first (simulate existing var)
    AssertTrue(env_set(name, 'v'));
    preGuard := env_get(name);
    AssertEquals('v', preGuard);
    // Use explicit unset helper
    g := env_override_unset(name);
    try
      AssertEquals('', env_get(name));
    finally
      g.Done;
    end;
    // After guard.Done, it should restore to the value at guard construction time
    AssertEquals(preGuard, env_get(name));
  finally
    // Restore original state from before this test
    if hadOrig then env_set(name, origBefore) else env_unset(name);
  end;
end;

procedure TTestCase_Global.Test_env_split_paths_preserve_spaces_and_dot_segments;
var s: string; arr: array of string; sep: Char;
begin
  sep := env_path_list_separator;
  s := sep + 'a' + sep + ' . ' + sep + '..' + sep + 'b' + sep;
  arr := env_split_paths(s);
  AssertEquals(4, Length(arr));
  AssertEquals('a', arr[0]);
  AssertEquals(' . ', arr[1]);
  AssertEquals('..', arr[2]);
  AssertEquals('b', arr[3]);
end;

procedure TTestCase_Global.Test_env_join_paths_preserve_segments_verbatim;
var arr: array of string; joined, expect: string; sep: Char;
begin
  sep := env_path_list_separator;
  SetLength(arr, 5);
  arr[0] := 'a'; arr[1] := ' . '; arr[2] := '..'; arr[3] := 'b'; arr[4] := '';
  joined := env_join_paths(arr);
  expect := 'a' + sep + ' . ' + sep + '..' + sep + 'b';
  AssertEquals(expect, joined);
end;

procedure TTestCase_Global.Test_env_split_paths_multiple_separators_collapsed;
var s: string; arr: array of string; sep: Char;
begin
  sep := env_path_list_separator;
  s := 'a' + sep + sep + sep + 'b';
  arr := env_split_paths(s);
  AssertEquals(2, Length(arr));
  AssertEquals('a', arr[0]);
  AssertEquals('b', arr[1]);
end;

function Resolver_Unicode(const K: string; out V: string): Boolean;
begin
  if K = 'UNIC' then begin V := 'OK'; Exit(True); end;
  V := ''; Result := False;
end;

procedure TTestCase_Global.Test_env_expand_with_unicode_braced_name;
var s: string;
begin
  s := env_expand_with('x=${UNIC}', @Resolver_Unicode);
  AssertEquals('x=OK', s);
end;

{$IFDEF WINDOWS}
function Resolver_WinSpace(const K: string; out V: string): Boolean;
begin
  if K = 'FOO BAR' then begin V := 'OK'; Exit(True); end;
  V := ''; Result := False;
end;

procedure TTestCase_Global.Test_env_expand_percent_with_space_name_windows;
var s: string;
begin
  s := env_expand_with('%FOO BAR%', @Resolver_WinSpace);
  AssertEquals('OK', s);
end;
{$ENDIF}

procedure TTestCase_Global.Test_env_join_paths_with_relative_and_dots_roundtrip;
var arr1, arr2: array of string; joined: string; i, n: integer;
begin
  SetLength(arr1, 4);
  arr1[0] := '.';
  arr1[1] := '..';
  arr1[2] := 'a/b';
  arr1[3] := 'c';
  joined := env_join_paths(arr1);
  arr2 := env_split_paths(joined);
  n := Length(arr2);
  AssertEquals(4, n);
  for i := 0 to n-1 do
    AssertEquals(arr1[i], arr2[i]);
end;

procedure TTestCase_Global.Test_env_has_defined_and_undefined;
begin
  env_unset('FA_ENV_HAS_CASE');
  AssertFalse(env_has('FA_ENV_HAS_CASE'));
  AssertTrue(env_set('FA_ENV_HAS_CASE', ''));
  AssertTrue(env_has('FA_ENV_HAS_CASE')); // defined even if empty
  env_unset('FA_ENV_HAS_CASE');
end;

procedure TTestCase_Global.Test_env_expand_trailing_dollar_literal;
var s: string;
begin
  s := env_expand('abc$');
  AssertEquals('abc$', s);
end;

procedure TTestCase_Global.Test_env_expand_braced_empty_name;
var s: string;
begin
  s := env_expand('${}');
  AssertEquals('', s);
end;

procedure TTestCase_Global.Test_env_expand_name_with_hyphen_stops_before;
var s: string;
begin
  env_set('AB', 'X');
  s := env_expand('$AB-YYY');
  AssertEquals('X-YYY', s);
  env_unset('AB');
end;


// Result-style API tests
procedure TTestCase_Global.Test_env_get_result_ok;
var r: specialize TResult<string, EVarError>; old: string; had: boolean;
begin
  old := env_get('FA_ENV_R_GET'); had := old <> '';
  env_set('FA_ENV_R_GET', 'V');
  try
    r := env_get_result('FA_ENV_R_GET');
    AssertTrue(r.IsOk);
    AssertEquals('V', r.Unwrap);
  finally
    if had then env_set('FA_ENV_R_GET', old) else env_unset('FA_ENV_R_GET');
  end;
end;

procedure TTestCase_Global.Test_env_get_result_err;
var r: specialize TResult<string, EVarError>;
begin
  env_unset('FA_ENV_R_MISSING');
  r := env_get_result('FA_ENV_R_MISSING');
  AssertTrue(r.IsErr);
  AssertEquals('FA_ENV_R_MISSING', r.UnwrapErr.Name);
end;

procedure TTestCase_Global.Test_env_join_paths_result_ok;
var arr: array of string; r: specialize TResult<string, EPathJoinError>;
begin
  SetLength(arr, 2); arr[0] := 'a'; arr[1] := 'b';
  r := env_join_paths_result(arr);
  AssertTrue(r.IsOk);
end;

procedure TTestCase_Global.Test_env_join_paths_result_err;
var arr: array of string; r: specialize TResult<string, EPathJoinError>; idx: Integer;
begin
  SetLength(arr, 2);
  arr[0] := 'a' + env_path_list_separator + 'x';
  arr[1] := 'b';
  r := env_join_paths_result(arr);
  AssertTrue(r.IsErr);
  idx := r.UnwrapErr.Index;
  AssertTrue(idx = 0);
end;

procedure TTestCase_Global.Test_env_current_dir_result_ok;
var r: specialize TResult<string, EIOError>;
begin
  r := env_current_dir_result;
  AssertTrue(r.IsOk);
  AssertTrue(Length(r.Unwrap) > 0);
end;

procedure TTestCase_Global.Test_env_set_current_dir_result_ok;
var r: specialize TResult<Boolean, EIOError>; cwd: string;
begin
  cwd := env_current_dir;
  r := env_set_current_dir_result(cwd);
  AssertTrue(r.IsOk);
  AssertTrue(r.Unwrap);
end;

procedure TTestCase_Global.Test_env_set_current_dir_result_err;
var r: specialize TResult<Boolean, EIOError>;
begin
  r := env_set_current_dir_result('Z:\this\path\should\not\exist\__fa_test__');
  AssertTrue(r.IsErr);
  AssertEquals('chdir', r.UnwrapErr.Op);
end;

procedure TTestCase_Global.Test_env_home_temp_exe_user_dirs_result_ok;
var rh, rt, re, rcfg, rcac: specialize TResult<string, EIOError>;
begin
  rh := env_home_dir_result;  AssertTrue(rh.IsOk);
  rt := env_temp_dir_result;  AssertTrue(rt.IsOk);
  re := env_executable_path_result; AssertTrue(re.IsOk);
  rcfg := env_user_config_dir_result; AssertTrue(rcfg.IsOk);
  rcac := env_user_cache_dir_result;  AssertTrue(rcac.IsOk);
end;

{$IFDEF WINDOWS}
procedure TTestCase_Global.Test_env_expand_unmatched_percent_literal_windows;
var s: string;
begin
  s := env_expand('%FOO');
  AssertEquals('%FOO', s);
end;
{$ENDIF}



initialization
  RegisterTest(TTestCase_Global);

end.

