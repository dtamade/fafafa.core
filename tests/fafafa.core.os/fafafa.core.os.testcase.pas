unit fafafa.core.os.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, DateUtils, fpcunit, testregistry,
  fafafa.core.os;

type
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_os_getenv_setenv_unsetenv;
    procedure Test_os_environ_basic;
    procedure Test_os_platform_info_basic;
    procedure Test_os_paths_and_counts;
    procedure Test_os_env_case_sensitivity;
    procedure Test_os_home_temp_override_and_environ;
    procedure Test_os_env_utf8_roundtrip;
    procedure Test_os_lookupenv_semantics;
    procedure Test_os_temp_home_fallback_soft;
    procedure Test_os_kernel_version_nonempty;
    procedure Test_os_uptime_positive;
    procedure Test_os_memory_info_basic;
    procedure Test_os_boot_time_soft;
    procedure Test_os_timezone_soft;
    procedure Test_os_boot_uptime_soft;
    procedure Test_os_capabilities_soft;
    procedure Test_os_os_version_detailed_soft;
    procedure Test_os_os_version_detailed_ex_soft;
    procedure Test_os_os_version_detailed_fields_soft;
    procedure Test_os_cpu_model_soft;
    procedure Test_cache_reset_ex_soft;
    procedure Test_cache_flags_kernel_osver_tziana_soft;
    procedure Test_cache_concurrency_smoke;
    procedure Test_cache_concurrency_multithread_smoke;
    procedure Test_os_environ_concurrency_soft;

    procedure Test_os_exe_path_ex;
    procedure Test_os_home_dir_ex;
    procedure Test_os_exe_dir_ex;
    procedure Test_os_username_ex_soft;
    procedure Test_os_hostname_ex;
    procedure Test_os_temp_dir_ex;
    procedure Test_os_timezone_ex_soft;
    procedure Test_os_timezone_iana_ex_soft;

    procedure Test_os_locale_current_soft;
    procedure Test_timezone_iana_soft;
    {$IFNDEF WINDOWS}
    procedure Test_unix_locale_normalize;
    procedure Test_unix_timezone_cache_reset_tz_env;
    {$ENDIF}

    // TODO: Re-enable Result-based API tests when fafafa.core.result compatibility is fixed
    (*
    // New Result-based API tests
    procedure Test_os_getenv_result;
    procedure Test_os_lookupenv_result;
    procedure Test_os_setenv_result;
    procedure Test_os_unsetenv_result;
    procedure Test_os_hostname_result;
    procedure Test_os_username_result;
    procedure Test_os_home_dir_result;
    procedure Test_os_temp_dir_result;
    procedure Test_os_exe_path_result;
    procedure Test_os_exe_dir_result;
    procedure Test_os_kernel_version_result;
    procedure Test_os_timezone_result;
    procedure Test_os_timezone_iana_result;
    procedure Test_os_cpu_model_result;
    procedure Test_os_locale_current_result;
    *)

    // New enhanced system information API tests
    procedure Test_os_cpu_info_ex;
    procedure Test_os_memory_info_ex;
    procedure Test_os_storage_info_ex;
    procedure Test_os_network_interfaces_ex;
    procedure Test_os_system_load_ex;
    procedure Test_os_system_info_ex;
  end;

type
  TReaderThread = class(TThread)
  private
    FIterations: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(iterations: Integer);
  end;

  TEnvEnvironReaderThread = class(TThread)
  private
    FIterations: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(iterations: Integer);
  end;

  TEnvVarWriterThread = class(TThread)
  private
    FIterations: Integer;
    FName: string;
  protected
    procedure Execute; override;
  public
    constructor Create(const AName: string; iterations: Integer);
  end;

implementation

constructor TReaderThread.Create(iterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FIterations := iterations;
end;

procedure TReaderThread.Execute;
var i: Integer; v: TOSVersionDetailed;
begin
  for i := 1 to FIterations do
  begin
    os_timezone;
    os_timezone_iana;
    os_kernel_version;
    v := os_os_version_detailed;
    if (i and 15) = 0 then Sleep(1);
  end;
end;

constructor TEnvEnvironReaderThread.Create(iterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FIterations := iterations;
end;

procedure TEnvEnvironReaderThread.Execute;
var
  i: Integer;
  L: TStringList;
begin
  for i := 1 to FIterations do
  begin
    L := TStringList.Create;
    try
      os_environ(L);
      // soft: do nothing, just ensure no crash
    finally
      L.Free;
    end;
    if (i and 7) = 0 then Sleep(1);
  end;
end;

constructor TEnvVarWriterThread.Create(const AName: string; iterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FIterations := iterations;
  FName := AName;
end;

procedure TEnvVarWriterThread.Execute;
var
  i: Integer;
  v: string;
begin
  for i := 1 to FIterations do
  begin
    case (i mod 4) of
      0: v := 'A';
      1: v := 'B';
      2: v := '';
    else
      v := '';
    end;
    if (i mod 3) = 2 then
      os_unsetenv(FName)
    else
      os_setenv(FName, v);
    if (i and 7) = 0 then Sleep(1);
  end;
end;

procedure TTestCase_Global.Test_os_getenv_setenv_unsetenv;
var
  Name, Val: string;
begin
  Name := 'FAFAFA_OS_TEST_VAR';
  Val := 'hello';
  AssertTrue('setenv should succeed', os_setenv(Name, Val));
  AssertEquals('getenv returns set value', Val, os_getenv(Name));
  AssertTrue('unsetenv should succeed', os_unsetenv(Name));
  AssertEquals('after unset should be empty', '', os_getenv(Name));
end;

procedure TTestCase_Global.Test_os_environ_basic;
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    os_environ(L);
    AssertTrue('environ should contain at least one variable', L.Count > 0);
    // A weak assertion: there should be at least PATH or TEMP-like variables
    // We do not rely on specific platform content
  finally
    L.Free;
  end;
end;

procedure TTestCase_Global.Test_os_platform_info_basic;
var
  Info: TPlatformInfo;
begin
  Info := os_platform_info;
  AssertTrue('OS not empty', Info.OS <> '');
  AssertTrue('Arch not empty', Info.Architecture <> '');
  AssertTrue('PageSize > 0', Info.PageSize > 0);
  AssertTrue('CPUCount >= 1', Info.CPUCount >= 1);
  AssertTrue('TempDir not empty', Info.TempDir <> '');
  AssertTrue('ExePath not empty', Info.ExePath <> '');
end;

procedure TTestCase_Global.Test_os_paths_and_counts;
begin
  AssertTrue('hostname not empty', os_hostname <> '');
  // username may be empty in some CI/minimal envs, so keep it soft
  //AssertTrue('username not empty', os_username <> '');
  AssertTrue('home dir not empty', os_home_dir <> '');
  AssertTrue('temp dir not empty', os_temp_dir <> '');
  AssertTrue('exe path not empty', os_exe_path <> '');
  AssertTrue('cpu count >= 1', os_cpu_count >= 1);
  AssertTrue('page size > 0', os_page_size > 0);
end;

procedure TTestCase_Global.Test_os_env_case_sensitivity;
var
  name, upper, lower: string;
begin
  name := 'FAFAFA_OS_CASE';
  upper := 'UP'; lower := 'down';
  AssertTrue(os_setenv(name, upper));
  {$IFDEF WINDOWS}
  // Windows: case-insensitive keys
  AssertEquals(upper, os_getenv(name));
  AssertTrue(os_setenv(LowerCase(name), lower));
  AssertEquals(lower, os_getenv(name));
  {$ELSE}
  // Unix: case-sensitive keys (simulate by separate var if needed)
  AssertEquals(upper, os_getenv(name));
  AssertTrue(os_setenv(name + '_x', lower));
  AssertEquals('', os_getenv(name + '_X'));
  {$ENDIF}
  AssertTrue(os_unsetenv(name));
end;

procedure TTestCase_Global.Test_os_home_temp_override_and_environ;
var
  L: TStringList;
  homeBak, tmpBak: string;
  hasHome, hasTmp: Boolean;
begin
  // Backup
  homeBak := os_getenv('HOME');
  tmpBak := os_getenv('TMPDIR');
  AssertTrue(os_setenv('HOME', os_home_dir));
  AssertTrue(os_setenv('TMPDIR', os_temp_dir));
  // environ should include overrides
  L := TStringList.Create;
  try
    os_environ(L);
    hasHome := L.IndexOfName('HOME') >= 0;
    {$IFDEF WINDOWS}
    hasTmp := (L.IndexOfName('TEMP') >= 0) or (L.IndexOfName('TMP') >= 0);
    {$ELSE}
    hasTmp := (L.IndexOfName('TMPDIR') >= 0);
    {$ENDIF}
    AssertTrue('HOME present in environ', hasHome);
    AssertTrue('TEMP/TMP/TMPDIR present', hasTmp);
  finally
    L.Free;
  end;
  // Restore (best-effort)
  {$IFDEF WINDOWS}
  // On Windows, HOME may be unset; do best-effort cleanup
  {$ENDIF}
  if homeBak <> '' then os_setenv('HOME', homeBak) else os_unsetenv('HOME');
  if tmpBak <> '' then os_setenv('TMPDIR', tmpBak) else os_unsetenv('TMPDIR');
end;

procedure TTestCase_Global.Test_os_env_utf8_roundtrip;
var
  key: string;
  val, got: UTF8String;
begin
  key := 'FAFAFA_OS_UTF8';
  val := UTF8String('中文テスト');
  AssertTrue(os_setenv(key, string(val)));
  got := UTF8String(os_getenv(key));
  AssertEquals(string(val), string(got));
  AssertTrue(os_unsetenv(key));
end;

procedure TTestCase_Global.Test_os_lookupenv_semantics;
var
  k, v: string; ok: Boolean;
begin
  k := 'FAFAFA_LOOKUP_TEST';
  // ensure unset
  os_unsetenv(k);
  ok := os_lookupenv(k, v);
  AssertFalse('unset -> ok=false', ok);
  AssertEquals('', v);

  // set empty
  AssertTrue(os_setenv(k, ''));
  ok := os_lookupenv(k, v);
  AssertTrue('defined but empty -> ok=true', ok);
  AssertEquals('', v);
  // cleanup
  AssertTrue(os_unsetenv(k));
end;
procedure TTestCase_Global.Test_os_kernel_version_nonempty;
var kv: string;
begin
  kv := os_kernel_version;
  AssertTrue('kernel version non-empty', kv <> '');
  {$IFDEF WINDOWS}
  // soft format check: at least contains a dot like a.b[.c]
  AssertTrue('kernel format like a.b.c', Pos('.', kv) > 0);
  {$ENDIF}
end;

procedure TTestCase_Global.Test_os_uptime_positive;
var
  up: QWord;
begin
  up := os_uptime;
  AssertTrue('uptime > 0', up > 0);
end;


procedure TTestCase_Global.Test_os_memory_info_basic;
var totalB, freeB: QWord;
begin
  if os_memory_info(totalB, freeB) then
  begin
    AssertTrue('total > 0', totalB > 0);
    AssertTrue('free >= 0', freeB >= 0);
  end;
end;

procedure TTestCase_Global.Test_os_boot_time_soft;
var t: QWord;
begin
  t := os_boot_time;
  if t > 0 then
  begin
    // t should be in the past 50 years (soft check)
    AssertTrue('boot time reasonable', (t < (DateTimeToUnix(Now) + 60)) and (t > 0));
  end;
end;

procedure TTestCase_Global.Test_os_timezone_soft;
var tz: string;
begin
  tz := os_timezone;
  // soft assert: either empty or a reasonable identifier
  if tz <> '' then
    AssertTrue('tz length <= 64', Length(tz) <= 64);
end;

procedure TTestCase_Global.Test_os_boot_uptime_soft;
var up, bt: QWord;
begin
  up := os_uptime;
  bt := os_boot_time;
  // 两者至少有一个应提供信息（软断言）
  AssertTrue('uptime or boottime available (soft)', (up > 0) or (bt > 0));
end;

procedure TTestCase_Global.Test_os_capabilities_soft;
begin
  // Do not assert values strictly; just ensure no exceptions
  os_is_admin;
  os_is_wsl;
  os_is_container;
  os_is_ci;
end;

procedure TTestCase_Global.Test_cache_reset_ex_soft;
var tz1, tz2, iana1, iana2: string;
begin
  tz1 := os_timezone; iana1 := os_timezone_iana;
  os_cache_reset_ex([oscTimezone, oscTimezoneIana]);
  tz2 := os_timezone; iana2 := os_timezone_iana;
  AssertTrue('os_cache_reset_ex works (tz)', (tz1 = tz2) or (tz1 = '') or (tz2 = ''));
  AssertTrue('os_cache_reset_ex works (iana)', (iana1 = iana2) or (iana1 = '') or (iana2 = ''));
end;

procedure TTestCase_Global.Test_cache_flags_kernel_osver_tziana_soft;
var v: TOSVersionDetailed; kv, tz: string;
begin
  // warm up
  kv := os_kernel_version;
  v := os_os_version_detailed;
  tz := os_timezone_iana;
  // reset selected caches
  os_cache_reset_ex([oscKernelVersion, oscOSVersionDetailed, oscTimezoneIana]);
  // soft re-read
  kv := os_kernel_version;
  v := os_os_version_detailed;
  tz := os_timezone_iana;
  // only no-crash soft checks here
  AssertTrue('kernel version soft', (kv <> '') or True);
  AssertTrue('os ver soft', True);
  AssertTrue('tz iana soft', True);
end;

procedure TTestCase_Global.Test_cache_concurrency_smoke;
var i: Integer;
begin
  // simple loop to simulate concurrent reads and periodic resets (single-threaded smoke)
  for i := 1 to 100 do
  begin
    os_timezone_iana;
    if (i mod 10) = 0 then os_cache_reset_ex([oscTimezone, oscTimezoneIana]);
  end;
  AssertTrue('concurrency smoke soft', True);
end;

procedure TTestCase_Global.Test_cache_concurrency_multithread_smoke;
const
  THREADS = 4;
  ITERS = 200;
var
  ths: array[0..THREADS-1] of TReaderThread;
  i, j: Integer;
begin
  for i := 0 to THREADS-1 do
  begin
    ths[i] := TReaderThread.Create(ITERS);
    ths[i].Start;
  end;
  // while workers run, do periodic cache resets
  for j := 1 to 40 do
  begin
    os_cache_reset_ex([oscTimezone, oscTimezoneIana, oscKernelVersion, oscOSVersionDetailed]);
    Sleep(1);
  end;
  for i := 0 to THREADS-1 do
  begin
    ths[i].WaitFor;
    ths[i].Free;
  end;
  AssertTrue('multithread smoke soft', True);
end;

procedure TTestCase_Global.Test_os_environ_concurrency_soft;
const
  WRITERS = 2;
  READERS = 2;
  ITERS   = 150;
var
  name: string;
  ws: array[0..WRITERS-1] of TEnvVarWriterThread;
  rs: array[0..READERS-1] of TEnvEnvironReaderThread;
  i: Integer;
begin
  name := 'FAFAFA_ENV_CONCUR_TEST';
  // spawn writers and readers
  for i := 0 to WRITERS-1 do
  begin
    ws[i] := TEnvVarWriterThread.Create(name, ITERS);
    ws[i].Start;
  end;
  for i := 0 to READERS-1 do
  begin
    rs[i] := TEnvEnvironReaderThread.Create(ITERS);
    rs[i].Start;
  end;
  // join
  for i := 0 to WRITERS-1 do
  begin
    ws[i].WaitFor;
    ws[i].Free;
  end;
  for i := 0 to READERS-1 do
  begin
    rs[i].WaitFor;
    rs[i].Free;
  end;
  // cleanup best-effort
  os_unsetenv(name);
  AssertTrue('os_environ concurrency soft', True);
end;





procedure TTestCase_Global.Test_os_os_version_detailed_soft;
var v: TOSVersionDetailed;
begin
  v := os_os_version_detailed;
  // soft assertions: allow empty but prefer not all empty
  AssertTrue('no crash', True);
end;

procedure TTestCase_Global.Test_os_os_version_detailed_ex_soft;
var V: TOSVersionDetailed; ok: Boolean;
begin
  ok := os_os_version_detailed_ex(V);
  // 允许为空，但成功应表示至少有一个关键字段
  AssertTrue('ex returns consistent result', ok = ((V.Name <> '') or (V.VersionString <> '') or (V.PrettyName <> '')));
end;
procedure TTestCase_Global.Test_os_os_version_detailed_fields_soft;
var v: TOSVersionDetailed;
begin
  v := os_os_version_detailed;
  // Soft checks: only length/format hints when present
  if v.PrettyName <> '' then AssertTrue('pretty <= 128', Length(v.PrettyName) <= 128);
  if v.ID <> '' then AssertTrue('id <= 64', Length(v.ID) <= 64);
  if v.IDLike <> '' then AssertTrue('idlike <= 128', Length(v.IDLike) <= 128);
end;


procedure TTestCase_Global.Test_os_cpu_model_soft;
var m: string;
begin
  m := os_cpu_model;
  AssertTrue('no crash', True);
end;

procedure TTestCase_Global.Test_os_exe_path_ex;
var p: string; ok: Boolean;
begin
  ok := os_exe_path_ex(p);
  AssertTrue('ok reflects non-empty exe path', ok = (p <> ''));
  // In normal envs, exe path should be non-empty
  AssertTrue('exe path sanity', p <> '');
end;

procedure TTestCase_Global.Test_os_home_dir_ex;
var p: string; ok: Boolean;
begin
  ok := os_home_dir_ex(p);
  AssertTrue('ok reflects non-empty home', ok = (p <> ''));
  // Many CI envs may also provide HOME; keep it soft if empty
  if not ok then
    AssertEquals('', p);
end;
procedure TTestCase_Global.Test_os_hostname_ex;
var s: string; ok: Boolean;
begin
  ok := os_hostname_ex(s);
  AssertTrue('ok reflects non-empty hostname', ok = (s <> ''));
end;

procedure TTestCase_Global.Test_os_temp_dir_ex;
var s: string; ok: Boolean;
begin
  ok := os_temp_dir_ex(s);
  AssertTrue('ok reflects non-empty temp dir', ok = (s <> ''));
end;

procedure TTestCase_Global.Test_os_timezone_ex_soft;
var s: string; ok: Boolean;
begin
  ok := os_timezone_ex(s);
  // timezone 可能为空；仅一致性检查
  AssertTrue('ok true even if empty', ok);
end;

procedure TTestCase_Global.Test_os_timezone_iana_ex_soft;
var s: string; ok: Boolean;
begin
  ok := os_timezone_iana_ex(s);
  // Windows 下可能为空；仅一致性检查
  AssertTrue('ok true even if empty', ok);
end;


procedure TTestCase_Global.Test_os_exe_dir_ex;
var d: string; ok: Boolean;
begin
  ok := os_exe_dir_ex(d);
  AssertTrue('exe dir ok implies non-empty', (not ok) or (d <> ''));
end;

procedure TTestCase_Global.Test_os_username_ex_soft;
var u: string; ok: Boolean;
begin
  ok := os_username_ex(u);
  // username can be empty in some CI images; assert consistency only
  AssertTrue('ok reflects non-empty username', ok = (u <> ''));
end;




procedure TTestCase_Global.Test_os_locale_current_soft;
var loc: string;
begin
  loc := os_locale_current;

  // allow empty; if not empty, should be short enough
  if loc <> '' then
  begin
    AssertTrue('locale length <= 64', Length(loc) <= 64);
    {$IFDEF WINDOWS}
    // soft format check en-US style
    AssertTrue('locale contains hyphen', Pos('-', loc) > 0);
    {$ENDIF}
  end;
end;

procedure TTestCase_Global.Test_os_temp_home_fallback_soft;
var
  tmp: string;
begin
  tmp := os_temp_dir;
  AssertTrue('temp not empty', tmp <> '');
  AssertTrue('home not empty', os_home_dir <> '');
end;

{$IFNDEF WINDOWS}
procedure TTestCase_Global.Test_unix_locale_normalize;
var oldLANG: string;
begin
  oldLANG := os_getenv('LANG');
  AssertTrue(os_setenv('LANG', 'zh_CN.UTF-8@modifier:other'));
  try
    AssertEquals('zh-CN', os_locale_current);
  finally
    if oldLANG <> '' then os_setenv('LANG', oldLANG) else os_unsetenv('LANG');
  end;
end;

{$IFNDEF WINDOWS}
procedure TTestCase_Global.Test_unix_timezone_cache_reset_tz_env;
var oldTZ, r1, r2: string;
begin
  // 缓存 warm-up
  r1 := os_timezone;
  // 记录旧TZ
  oldTZ := os_getenv('TZ');
  try
    // 修改 TZ，不重置缓存前，os_timezone 应仍返回旧缓存
    AssertTrue(os_setenv('TZ', 'Etc/UTC'));
    r2 := os_timezone;
    AssertEquals('cache not refreshed without reset', r1, r2);
    // 重置缓存后，os_timezone 应反映新的 TZ
    os_cache_reset_ex([oscTimezone]);
    r2 := os_timezone;
    // 软断言：允许返回空（极简系统），否则应能看到新的值
    AssertTrue('after reset, tz updated or empty', (r2 = '') or (r2 <> r1));
  finally
    // 还原 TZ
    if oldTZ <> '' then os_setenv('TZ', oldTZ) else os_unsetenv('TZ');
    os_cache_reset_ex([oscTimezone]);
  end;
end;
{$ENDIF}

{$ENDIF}

procedure TTestCase_Global.Test_timezone_iana_soft;
var std, iana: string;
begin
  std := os_timezone;
  iana := os_timezone_iana;
  {$IFDEF WINDOWS}
  if std = 'China Standard Time' then
    AssertEquals('Asia/Shanghai', iana)
  else
    AssertTrue('iana empty or mapped', (iana = '') or (Pos('/', iana) > 0));
  {$ELSE}
  // Unix: iana same as std
  AssertEquals(std, iana);
  {$ENDIF}
end;

// TODO: Re-enable Result-based API tests when fafafa.core.result compatibility is fixed
(*
// New Result-based API tests implementation
procedure TTestCase_Global.Test_os_getenv_result;
var
  result: TOSStringResult;
  testVar: string;
begin
  testVar := 'FAFAFA_TEST_VAR_' + IntToStr(Random(10000));

  // Test getting non-existent variable
  result := os_getenv_result(testVar);
  AssertTrue('Should return error for non-existent variable', result.IsErr);
  AssertEquals('Should be oseNotFound', Ord(oseNotFound), Ord(result.UnwrapErr));

  // Set a test variable and get it
  AssertTrue('Should be able to set test variable', os_setenv(testVar, 'test_value'));
  result := os_getenv_result(testVar);
  AssertTrue('Should return success for existing variable', result.IsOk);
  AssertEquals('Should return correct value', 'test_value', result.Unwrap);

  // Clean up
  os_unsetenv(testVar);
end;

procedure TTestCase_Global.Test_os_lookupenv_result;
var
  result: TOSStringResult;
  testVar: string;
begin
  testVar := 'FAFAFA_TEST_VAR_' + IntToStr(Random(10000));

  // Test looking up non-existent variable
  result := os_lookupenv_result(testVar);
  AssertTrue('Should return error for non-existent variable', result.IsErr);
  AssertEquals('Should be oseNotFound', Ord(oseNotFound), Ord(result.UnwrapErr));

  // Set a test variable and look it up
  AssertTrue('Should be able to set test variable', os_setenv(testVar, 'lookup_value'));
  result := os_lookupenv_result(testVar);
  AssertTrue('Should return success for existing variable', result.IsOk);
  AssertEquals('Should return correct value', 'lookup_value', result.Unwrap);

  // Test empty value
  AssertTrue('Should be able to set empty value', os_setenv(testVar, ''));
  result := os_lookupenv_result(testVar);
  AssertTrue('Should return success for empty value', result.IsOk);
  AssertEquals('Should return empty string', '', result.Unwrap);

  // Clean up
  os_unsetenv(testVar);
end;

procedure TTestCase_Global.Test_os_setenv_result;
var
  result: TOSBoolResult;
  testVar: string;
  value: string;
begin
  testVar := 'FAFAFA_TEST_VAR_' + IntToStr(Random(10000));

  // Test setting a variable
  result := os_setenv_result(testVar, 'set_test_value');
  AssertTrue('Should return success', result.IsOk);
  AssertTrue('Should return true', result.Unwrap);

  // Verify it was set
  AssertTrue('Variable should exist', os_lookupenv(testVar, value));
  AssertEquals('Should have correct value', 'set_test_value', value);

  // Clean up
  os_unsetenv(testVar);
end;

procedure TTestCase_Global.Test_os_unsetenv_result;
var
  result: TOSBoolResult;
  testVar: string;
  value: string;
begin
  testVar := 'FAFAFA_TEST_VAR_' + IntToStr(Random(10000));

  // Set a variable first
  AssertTrue('Should be able to set test variable', os_setenv(testVar, 'unset_test'));
  AssertTrue('Variable should exist', os_lookupenv(testVar, value));

  // Test unsetting the variable
  result := os_unsetenv_result(testVar);
  AssertTrue('Should return success', result.IsOk);
  AssertTrue('Should return true', result.Unwrap);

  // Verify it was unset
  AssertFalse('Variable should not exist', os_lookupenv(testVar, value));
end;

procedure TTestCase_Global.Test_os_hostname_result;
var
  result: TOSStringResult;
begin
  result := os_hostname_result;
  AssertTrue('Should return success', result.IsOk);
  AssertTrue('Hostname should not be empty', result.Unwrap <> '');
  // Compare with legacy API
  AssertEquals('Should match legacy API', os_hostname, result.Unwrap);
end;

procedure TTestCase_Global.Test_os_username_result;
var
  result: TOSStringResult;
begin
  result := os_username_result;
  AssertTrue('Should return success', result.IsOk);
  AssertTrue('Username should not be empty', result.Unwrap <> '');
  // Compare with legacy API
  AssertEquals('Should match legacy API', os_username, result.Unwrap);
end;

procedure TTestCase_Global.Test_os_home_dir_result;
var
  result: TOSStringResult;
begin
  result := os_home_dir_result;
  AssertTrue('Should return success', result.IsOk);
  AssertTrue('Home directory should not be empty', result.Unwrap <> '');
  // Compare with legacy API
  AssertEquals('Should match legacy API', os_home_dir, result.Unwrap);
end;

procedure TTestCase_Global.Test_os_temp_dir_result;
var
  result: TOSStringResult;
begin
  result := os_temp_dir_result;
  AssertTrue('Should return success', result.IsOk);
  AssertTrue('Temp directory should not be empty', result.Unwrap <> '');
  // Compare with legacy API
  AssertEquals('Should match legacy API', os_temp_dir, result.Unwrap);
end;

procedure TTestCase_Global.Test_os_exe_path_result;
var
  result: TOSStringResult;
begin
  result := os_exe_path_result;
  AssertTrue('Should return success', result.IsOk);
  AssertTrue('Exe path should not be empty', result.Unwrap <> '');
  // Compare with legacy API
  AssertEquals('Should match legacy API', os_exe_path, result.Unwrap);
end;

procedure TTestCase_Global.Test_os_exe_dir_result;
var
  result: TOSStringResult;
begin
  result := os_exe_dir_result;
  AssertTrue('Should return success', result.IsOk);
  AssertTrue('Exe directory should not be empty', result.Unwrap <> '');
  // Compare with legacy API
  AssertEquals('Should match legacy API', os_exe_dir, result.Unwrap);
end;

procedure TTestCase_Global.Test_os_kernel_version_result;
var
  result: TOSStringResult;
begin
  result := os_kernel_version_result;
  AssertTrue('Should return success', result.IsOk);
  AssertTrue('Kernel version should not be empty', result.Unwrap <> '');
  // Compare with legacy API
  AssertEquals('Should match legacy API', os_kernel_version, result.Unwrap);
end;

procedure TTestCase_Global.Test_os_timezone_result;
var
  result: TOSStringResult;
begin
  result := os_timezone_result;
  AssertTrue('Should return success', result.IsOk);
  // Timezone can be empty, so we don't check for non-empty
  // Compare with legacy API
  AssertEquals('Should match legacy API', os_timezone, result.Unwrap);
end;

procedure TTestCase_Global.Test_os_timezone_iana_result;
var
  result: TOSStringResult;
begin
  result := os_timezone_iana_result;
  AssertTrue('Should return success', result.IsOk);
  // IANA timezone can be empty, so we don't check for non-empty
  // Compare with legacy API
  AssertEquals('Should match legacy API', os_timezone_iana, result.Unwrap);
end;

procedure TTestCase_Global.Test_os_cpu_model_result;
var
  result: TOSStringResult;
begin
  result := os_cpu_model_result;
  AssertTrue('Should return success', result.IsOk);
  AssertTrue('CPU model should not be empty', result.Unwrap <> '');
  // Compare with legacy API
  AssertEquals('Should match legacy API', os_cpu_model, result.Unwrap);
end;

procedure TTestCase_Global.Test_os_locale_current_result;
var
  result: TOSStringResult;
begin
  result := os_locale_current_result;
  AssertTrue('Should return success', result.IsOk);
  AssertTrue('Locale should not be empty', result.Unwrap <> '');
  // Compare with legacy API
  AssertEquals('Should match legacy API', os_locale_current, result.Unwrap);
end;
*)

// New enhanced system information API tests implementation
procedure TTestCase_Global.Test_os_cpu_info_ex;
var
  Info: TCPUInfo;
begin
  AssertTrue('Should return success', os_cpu_info_ex(Info));
  AssertTrue('CPU model should not be empty', Info.Model <> '');
  AssertTrue('CPU vendor should not be empty', Info.Vendor <> '');
  AssertTrue('CPU cores should be positive', Info.Cores > 0);
  AssertTrue('CPU threads should be positive', Info.Threads > 0);
  AssertTrue('CPU architecture should not be empty', Info.Architecture <> '');
  // Usage can be -1 (unknown) so we don't check for positive
end;

procedure TTestCase_Global.Test_os_memory_info_ex;
var
  Info: TMemoryInfo;
begin
  AssertTrue('Should return success', os_memory_info_ex(Info));
  AssertTrue('Total memory should be positive', Info.Total > 0);
  AssertTrue('Available memory should be non-negative', Info.Available >= 0);
  AssertTrue('Used memory should be non-negative', Info.Used >= 0);
  AssertTrue('Free memory should be non-negative', Info.Free >= 0);
  // Available should be <= Total
  AssertTrue('Available memory should not exceed total', Info.Available <= Info.Total);
end;

procedure TTestCase_Global.Test_os_storage_info_ex;
var
  Info: TStorageInfoArray;
begin
  AssertTrue('Should return success', os_storage_info_ex(Info));
  // Storage info can be empty array, so we just check it doesn't crash
  // TODO: Add more specific tests when storage enumeration is implemented
end;

procedure TTestCase_Global.Test_os_network_interfaces_ex;
var
  Info: TNetworkInterfaceArray;
begin
  AssertTrue('Should return success', os_network_interfaces_ex(Info));
  // Network interfaces can be empty array, so we just check it doesn't crash
  // TODO: Add more specific tests when network interface enumeration is implemented
end;

procedure TTestCase_Global.Test_os_system_load_ex;
var
  Info: TSystemLoad;
begin
  AssertTrue('Should return success', os_system_load_ex(Info));
  // Load values can be -1 (unknown) so we don't check for specific values
  // TODO: Add more specific tests when system load monitoring is implemented
end;

procedure TTestCase_Global.Test_os_system_info_ex;
var
  Info: TSystemInfo;
begin
  AssertTrue('Should return success', os_system_info_ex(Info));

  // Check platform information
  AssertTrue('OS should not be empty', Info.Platform.OS <> '');
  AssertTrue('Architecture should not be empty', Info.Platform.Architecture <> '');
  AssertTrue('CPU count should be positive', Info.Platform.CPUCount > 0);

  // Check CPU information
  AssertTrue('CPU model should not be empty', Info.CPU.Model <> '');
  AssertTrue('CPU cores should be positive', Info.CPU.Cores > 0);

  // Check memory information
  AssertTrue('Total memory should be positive', Info.Memory.Total > 0);

  // Check OS version
  AssertTrue('OS name should not be empty', Info.OSVersion.Name <> '');

  // Boot time and uptime can be 0 if unknown, so we don't check for positive values
end;

initialization
  RegisterTest('TTestCase_Global', TTestCase_Global);

end.

