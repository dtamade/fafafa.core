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
    // === Basic Operations ===
    procedure Test_env_get_set_unset_rollback;
    procedure Test_env_get_or_fallback;
    procedure Test_env_lookup_defined_empty_vs_undefined;
    procedure Test_env_has_defined_and_undefined;
    procedure Test_env_vars_snapshot;
    procedure Test_env_functions_with_empty_names;
    procedure Test_env_vars_with_nil_destination;

    // === RAII Override Guards ===
    procedure Test_env_overrides_basic_restore;
    procedure Test_env_overrides_duplicate_keys;
    procedure Test_env_override_unset_behavior;

    // === String Expansion ===
    procedure Test_env_expand_basic;
    procedure Test_env_expand_edges;
    procedure Test_env_expand_doubledollar_escape;
    procedure Test_env_expand_env_delegates;
    procedure Test_env_expand_with_custom_mapper;
    procedure Test_env_expand_trailing_dollar_literal;
    procedure Test_env_expand_braced_empty_name;
    procedure Test_env_expand_name_with_hyphen_stops_before;
    procedure Test_env_expand_with_unicode_braced_name;
    procedure Test_env_expand_with_nil_resolver;
    procedure Test_env_expand_with_very_long_string;
    {$IFDEF WINDOWS}
    procedure Test_env_expand_doublepercent_escape;
    procedure Test_env_expand_case_insensitive;
    procedure Test_env_expand_unmatched_percent_literal_windows;
    procedure Test_env_expand_percent_with_space_name_windows;
    {$ENDIF}

    // === PATH Handling ===
    procedure Test_env_path_list_separator_platform;
    procedure Test_env_split_join_paths_roundtrip;
    procedure Test_env_split_join_paths_roundtrip2;
    procedure Test_env_join_paths_skip_empty_segments;
    procedure Test_env_join_paths_checked_reports_error;
    procedure Test_env_split_paths_preserve_spaces_and_dot_segments;
    procedure Test_env_join_paths_preserve_segments_verbatim;
    procedure Test_env_split_paths_multiple_separators_collapsed;
    procedure Test_env_join_paths_with_relative_and_dots_roundtrip;
    procedure Test_env_split_paths_with_empty_string;

    // === Directories & Process ===
    procedure Test_env_cwd_and_exepath;
    procedure Test_env_user_dirs_best_effort;

    // === Security Helpers ===
    procedure Test_env_is_sensitive_name;
    procedure Test_env_mask_value;
    procedure Test_env_validate_name;

    // === Convenience APIs ===
    procedure Test_env_required_returns_value_when_defined;
    procedure Test_env_required_raises_when_undefined;
    procedure Test_env_keys_returns_all_names;
    procedure Test_env_count_returns_correct_number;

    // === Platform Constants ===
    procedure Test_env_os_returns_valid_os_name;
    procedure Test_env_arch_returns_valid_arch;
    procedure Test_env_family_returns_valid_family;
    procedure Test_env_is_platform_functions;

    // === Iterator API ===
    procedure Test_env_iter_for_in_syntax;
    procedure Test_env_iter_count_matches_env_count;
    procedure Test_env_iter_keys_have_no_equals;

    // === Command-line Arguments ===
    procedure Test_env_args_returns_array;
    procedure Test_env_args_count_matches_paramcount;
    procedure Test_env_arg_returns_paramstr;

    // === Sandbox Operations ===
    procedure Test_env_clear_all_removes_all_vars;

    // === Result API ===
    procedure Test_env_get_result_ok;
    procedure Test_env_get_result_err;
    procedure Test_env_join_paths_result_ok;
    procedure Test_env_join_paths_result_err;
    procedure Test_env_current_dir_result_ok;
    procedure Test_env_set_current_dir_result_ok;
    procedure Test_env_set_current_dir_result_err;
    procedure Test_env_home_temp_exe_user_dirs_result_ok;

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
  arr := nil;
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
  AssertTrue(Length(cfg) >= 0);  // Use cfg to suppress hint
  AssertTrue(Length(cache) >= 0); // Use cache to suppress hint
end;


procedure TTestCase_Global.Test_env_join_paths_checked_reports_error;
var arr: array of string; j: string; idx: Integer;
begin
  arr := nil;
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
  kvs := nil;
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
  kvs := nil;
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
  arr := nil;
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
  arr1 := nil;
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
  arr := nil;
  SetLength(arr, 2); arr[0] := 'a'; arr[1] := 'b';
  r := env_join_paths_result(arr);
  AssertTrue(r.IsOk);
end;

procedure TTestCase_Global.Test_env_join_paths_result_err;
var arr: array of string; r: specialize TResult<string, EPathJoinError>; idx: Integer;
begin
  arr := nil;
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

// Additional edge case tests for improved coverage
procedure TTestCase_Global.Test_env_functions_with_empty_names;
var result_str: string; result_bool: Boolean;
begin
  // Test that functions handle empty names gracefully
  result_str := env_get('');
  AssertEquals('', result_str);

  result_str := env_get_or('', 'default');
  AssertEquals('default', result_str);

  result_bool := env_set('', 'value');
  AssertFalse(result_bool);

  result_bool := env_unset('');
  AssertFalse(result_bool);

  result_bool := env_has('');
  AssertFalse(result_bool);
end;

procedure TTestCase_Global.Test_env_vars_with_nil_destination;
begin
  // Test that env_vars handles nil destination gracefully
  env_vars(nil); // Should not crash
  AssertTrue(True); // If we get here, the test passed
end;

procedure TTestCase_Global.Test_env_expand_with_nil_resolver;
var s: string;
begin
  // Test that env_expand_with handles nil resolver gracefully
  s := env_expand_with('$HOME', nil);
  // Should return empty expansion for all variables
  AssertEquals('', s);
end;

procedure TTestCase_Global.Test_env_expand_with_very_long_string;
var s, input: string; i: Integer;
begin
  // Test performance with a very long string
  input := '';
  for i := 1 to 1000 do
    input := input + 'text';

  s := env_expand(input);
  AssertEquals(input, s); // Should return unchanged since no variables
end;

procedure TTestCase_Global.Test_env_split_paths_with_empty_string;
var arr: TStringArray;
begin
  // Test that env_split_paths handles empty string gracefully
  arr := env_split_paths('');
  AssertEquals(0, Length(arr));
end;

// Security helper tests
procedure TTestCase_Global.Test_env_is_sensitive_name;
begin
  // Test sensitive name detection
  AssertTrue(env_is_sensitive_name('PASSWORD'));
  AssertTrue(env_is_sensitive_name('API_KEY'));
  AssertTrue(env_is_sensitive_name('SECRET_TOKEN'));
  AssertTrue(env_is_sensitive_name('DB_PASSWORD'));
  AssertTrue(env_is_sensitive_name('PRIVATE_KEY'));
  AssertTrue(env_is_sensitive_name('SSL_CERT'));
  AssertTrue(env_is_sensitive_name('AUTH_TOKEN'));

  // Test non-sensitive names
  AssertFalse(env_is_sensitive_name('PATH'));
  AssertFalse(env_is_sensitive_name('HOME'));
  AssertFalse(env_is_sensitive_name('USER'));
  AssertFalse(env_is_sensitive_name('TEMP'));
  AssertFalse(env_is_sensitive_name(''));
end;

procedure TTestCase_Global.Test_env_mask_value;
var masked: string;
begin
  // Test value masking
  masked := env_mask_value('');
  AssertEquals('', masked);

  masked := env_mask_value('abc');
  AssertEquals('***', masked);

  masked := env_mask_value('abcd');
  AssertEquals('***', masked);

  masked := env_mask_value('abcde');
  AssertEquals('ab*de', masked);

  masked := env_mask_value('secret123456');
  AssertEquals('se********56', masked); // 12 chars: 2 + (12-4) + 2 = 12
end;

procedure TTestCase_Global.Test_env_validate_name;
begin
  // Test valid names
  AssertTrue(env_validate_name('PATH'));
  AssertTrue(env_validate_name('_PRIVATE'));
  AssertTrue(env_validate_name('VAR123'));
  AssertTrue(env_validate_name('MY_VAR_NAME'));

  // Test invalid names
  AssertFalse(env_validate_name(''));
  AssertFalse(env_validate_name('123VAR')); // starts with digit
  AssertFalse(env_validate_name('VAR-NAME')); // contains hyphen
  AssertFalse(env_validate_name('VAR.NAME')); // contains dot
  AssertFalse(env_validate_name('VAR NAME')); // contains space
end;

// P1: High-value convenience API tests
procedure TTestCase_Global.Test_env_required_returns_value_when_defined;
var g: TEnvOverrideGuard;
begin
  g := env_override('FA_ENV_REQ_TEST', 'expected_value');
  try
    AssertEquals('expected_value', env_required('FA_ENV_REQ_TEST'));
  finally
    g.Done;
  end;
end;

procedure TTestCase_Global.Test_env_required_raises_when_undefined;
var raised: Boolean;
begin
  env_unset('FA_ENV_REQ_MISSING');
  raised := False;
  try
    env_required('FA_ENV_REQ_MISSING');
  except
    on E: Exception do
      raised := True;
  end;
  AssertTrue('env_required should raise for undefined var', raised);
end;

procedure TTestCase_Global.Test_env_keys_returns_all_names;
var keys: TStringArray; i: Integer; foundPath: Boolean;
begin
  keys := env_keys;
  AssertTrue('env_keys should return at least one key', Length(keys) > 0);
  // PATH should be present on most systems
  foundPath := False;
  for i := 0 to High(keys) do
    if UpperCase(keys[i]) = 'PATH' then begin foundPath := True; Break; end;
  AssertTrue('PATH should be in env_keys', foundPath);
  // Keys should not contain ''='' (values)
  for i := 0 to High(keys) do
    AssertTrue('Key should not contain =', Pos('=', keys[i]) = 0);
end;

procedure TTestCase_Global.Test_env_count_returns_correct_number;
var cnt: Integer; lst: TStringList;
begin
  cnt := env_count;
  AssertTrue('env_count should be > 0', cnt > 0);
  // Verify against env_vars
  lst := TStringList.Create;
  try
    env_vars(lst);
    AssertEquals(lst.Count, cnt);
  finally
    lst.Free;
  end;
end;

// P2: Platform constants tests
procedure TTestCase_Global.Test_env_os_returns_valid_os_name;
var os: string;
begin
  os := env_os;
  AssertTrue('env_os should not be empty', os <> '');
  // Should be one of known OS names
  AssertTrue('env_os should be valid',
    (os = 'Windows') or (os = 'Linux') or (os = 'Darwin') or
    (os = 'FreeBSD') or (os = 'OpenBSD') or (os = 'NetBSD'));
end;

procedure TTestCase_Global.Test_env_arch_returns_valid_arch;
var arch: string;
begin
  arch := env_arch;
  AssertTrue('env_arch should not be empty', arch <> '');
  // Common architectures
  AssertTrue('env_arch should be valid',
    (arch = 'x86_64') or (arch = 'aarch64') or (arch = 'i386') or
    (arch = 'arm') or (arch = 'powerpc64') or (arch = 'riscv64'));
end;

procedure TTestCase_Global.Test_env_family_returns_valid_family;
var fam: string;
begin
  fam := env_family;
  AssertTrue('env_family should not be empty', fam <> '');
  AssertTrue('env_family should be unix or windows',
    (fam = 'unix') or (fam = 'windows'));
end;

procedure TTestCase_Global.Test_env_is_platform_functions;
begin
  // At least one should be true
  AssertTrue('At least one platform should match',
    env_is_windows or env_is_unix or env_is_darwin);
  // Darwin implies Unix
  if env_is_darwin then
    AssertTrue('Darwin should also be Unix', env_is_unix);
  // Consistency with env_family
  if env_is_windows then
    AssertEquals('windows', env_family)
  else
    AssertEquals('unix', env_family);
end;

// P3: env_clear_all test
procedure TTestCase_Global.Test_env_clear_all_removes_all_vars;
var kvs: array of TEnvKV; countAfter: Integer;
    lst: TStringList; i: Integer;
begin
  // Save current env to restore later
  lst := TStringList.Create;
  try
    env_vars(lst);
    // Build restore array
    kvs := nil;
    SetLength(kvs, lst.Count);
    for i := 0 to lst.Count - 1 do
    begin
      kvs[i].Name := lst.Names[i];
      kvs[i].Value := lst.ValueFromIndex[i];
      kvs[i].HasValue := True;
    end;
    // Clear all
    env_clear_all;
    countAfter := env_count;
    AssertEquals('env_clear_all should remove all vars', 0, countAfter);
    // Restore (manual, since guards need existing state)
    for i := 0 to High(kvs) do
      env_set(kvs[i].Name, kvs[i].Value);
  finally
    lst.Free;
  end;
end;

// P4: Iterator API tests
procedure TTestCase_Global.Test_env_iter_for_in_syntax;
var kv: TEnvKVPair; cnt: Integer;
begin
  cnt := 0;
  for kv in env_iter do
  begin
    Inc(cnt);
    AssertTrue('Key should not be empty', kv.Key <> '');
  end;
  AssertTrue('Should iterate at least one var', cnt > 0);
end;

procedure TTestCase_Global.Test_env_iter_count_matches_env_count;
var kv: TEnvKVPair; cnt: Integer;
begin
  cnt := 0;
  for kv in env_iter do
    Inc(cnt);
  AssertEquals(env_count, cnt);
end;

procedure TTestCase_Global.Test_env_iter_keys_have_no_equals;
var kv: TEnvKVPair;
begin
  for kv in env_iter do
  begin
    AssertTrue('Key should not contain =', Pos('=', kv.Key) = 0);
  end;
end;

// P5: Command-line arguments API tests
procedure TTestCase_Global.Test_env_args_returns_array;
var args: TStringArray;
begin
  args := env_args;
  // Should have at least one element (the program name)
  AssertTrue('env_args should have at least one element', Length(args) > 0);
  // First element should be the executable
  AssertTrue('First arg should not be empty', args[0] <> '');
end;

procedure TTestCase_Global.Test_env_args_count_matches_paramcount;
begin
  // env_args_count should equal ParamCount + 1 (including program name)
  AssertEquals(ParamCount + 1, env_args_count);
end;

procedure TTestCase_Global.Test_env_arg_returns_paramstr;
var i: Integer;
begin
  // env_arg(i) should match ParamStr(i)
  for i := 0 to ParamCount do
    AssertEquals(ParamStr(i), env_arg(i));
  // Out of range should return empty
  AssertEquals('', env_arg(-1));
  AssertEquals('', env_arg(ParamCount + 100));
end;


initialization
  RegisterTest(TTestCase_Global);

end.

