unit fafafa.core.os.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, DateUtils, fpcunit, testregistry,
  fafafa.core.os, fafafa.core.result, fafafa.core.math;

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
    procedure Test_unix_timezone_cache_reset_tz_iana_env;
    procedure Test_SystemErrorToOSError_unix_mapping;
    procedure Test_unix_timezone_cache_reuse_ignores_env_change;
    procedure Test_nonlinux_advanced_probes_signal_not_supported; // compiled only when not LINUX
    procedure Test_nonlinux_advanced_probes_result_not_supported; // non-Linux: Result 应返回 oseNotSupported
    {$ENDIF}

    // Result-based API tests
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
    procedure Test_os_cpu_info_result;
    procedure Test_os_memory_info_result;
    procedure Test_os_storage_info_result;
    procedure Test_os_network_interfaces_result;
    procedure Test_os_system_load_result;
    procedure Test_os_system_info_result;

    // New enhanced system information API tests
    procedure Test_os_cpu_info_ex;
    procedure Test_os_memory_info_ex;
    procedure Test_os_storage_info_ex;
    procedure Test_os_network_interfaces_ex;
    procedure Test_os_system_load_ex;
    procedure Test_os_system_info_ex;
    {$IFDEF LINUX}
    procedure Test_os_storage_info_ex_linux;
    procedure Test_os_network_interfaces_ex_linux;
    procedure Test_os_system_load_ex_linux;
    procedure Test_os_system_info_ex_enhanced_linux;
    procedure Test_cache_probes_flag_enabled;
    procedure Test_os_storage_root_mount_linux;
    procedure Test_os_storage_root_readonly_matches_mount_opts_linux;
    procedure Test_os_storage_mountopts_remount_ro_not_readonly_linux;
    procedure Test_os_memory_info_ex_linux_details;
    procedure Test_os_network_loopback_has_ip_linux;
    procedure Test_os_network_sysfs_non_loopback_enumerated_linux;
    procedure Test_os_network_non_loopback_ipv4_present_linux;
    procedure Test_os_cpu_info_ex_features_frequency_linux;
    procedure Test_os_cpu_info_ex_cache_sizes_linux;
    procedure Test_os_cpu_info_usage_linux;
    {$ENDIF}
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

{$IFNDEF WINDOWS}
uses BaseUnix;
{$ENDIF}

constructor TReaderThread.Create(iterations: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FIterations := iterations;
end;

procedure TReaderThread.Execute;
var i: Integer;
begin
  for i := 1 to FIterations do
  begin
    os_timezone;
    os_timezone_iana;
    os_kernel_version;
    os_os_version_detailed;
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
    AssertTrue('free <= total', freeB <= totalB);
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

  // soft sanity checks
  if kv <> '' then AssertTrue('kernel version length <= 256', Length(kv) <= 256);
  if v.Name <> '' then AssertTrue('os name length <= 128', Length(v.Name) <= 128);
  if tz <> '' then AssertTrue('tz iana length <= 64', Length(tz) <= 64);
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
begin
  os_os_version_detailed;
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
var
  model: string;
begin
  model := os_cpu_model;
  // allow empty; if not empty, should be short enough
  if model <> '' then
    AssertTrue('cpu model length <= 256', Length(model) <= 256);
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

{$IFNDEF WINDOWS}
procedure TTestCase_Global.Test_unix_timezone_cache_reuse_ignores_env_change;
var
  oldTZ, first, second: string;
begin
  {$IFNDEF LINUX}
  // Only meaningful on Unix-like systems with TZ support; skip for other OS
  if not os_is_wsl then ; // touch to avoid hints
  {$ENDIF}
  oldTZ := os_getenv('TZ');
  try
    os_cache_reset_ex([oscTimezone, oscTimezoneIana]);
    os_setenv('TZ', 'UTC');
    first := os_timezone;

    // change env, but without cache reset the value should stay cached
    os_setenv('TZ', 'Etc/GMT-3');
    second := os_timezone;

    AssertEquals('cached timezone should ignore env change until cache reset', first, second);
  finally
    // restore
    if oldTZ <> '' then os_setenv('TZ', oldTZ) else os_unsetenv('TZ');
    os_cache_reset_ex([oscTimezone, oscTimezoneIana]);
  end;
end;

procedure TTestCase_Global.Test_nonlinux_advanced_probes_signal_not_supported;
var
  memOk, storOk, netOk, loadOk: Boolean;
  mem: TMemoryInfo;
  stor: TStorageInfoArray;
  net: TNetworkInterfaceArray;
  load: TSystemLoad;
begin
  {$IFDEF LINUX}
  Exit; // only run on non-Linux to validate signalling
  {$ENDIF}
  memOk := os_memory_info_ex(mem);
  storOk := os_storage_info_ex(stor);
  netOk := os_network_interfaces_ex(net);
  loadOk := os_system_load_ex(load);

  AssertFalse('memory info should report unsupported on non-Linux', memOk);
  AssertFalse('storage info should report unsupported on non-Linux', storOk);
  AssertFalse('network info should report unsupported on non-Linux', netOk);
  AssertFalse('system load should report unsupported on non-Linux', loadOk);
end;

procedure TTestCase_Global.Test_nonlinux_advanced_probes_result_not_supported;
var
  rMem: TMemoryInfoResult;
  rStor: TStorageInfoArrayResult;
  rNet: TNetworkInterfaceArrayResult;
  rLoad: TSystemLoadResult;
begin
  {$IFDEF LINUX}
  Exit; // only run on non-Linux
  {$ENDIF}
  rMem := os_memory_info_detailed;
  rStor := os_storage_info;
  rNet := os_network_interfaces;
  rLoad := os_system_load;

  AssertTrue('memory result should be Err', rMem.IsErr);
  AssertEquals('memory err = not supported', Ord(oseNotSupported), Ord(rMem.UnwrapErr));

  AssertTrue('storage result should be Err', rStor.IsErr);
  AssertEquals('storage err = not supported', Ord(oseNotSupported), Ord(rStor.UnwrapErr));

  AssertTrue('network result should be Err', rNet.IsErr);
  AssertEquals('network err = not supported', Ord(oseNotSupported), Ord(rNet.UnwrapErr));

  AssertTrue('load result should be Err', rLoad.IsErr);
  AssertEquals('load err = not supported', Ord(oseNotSupported), Ord(rLoad.UnwrapErr));
end;
{$ENDIF}

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

procedure TTestCase_Global.Test_unix_timezone_cache_reset_tz_iana_env;
var
  oldTZ, newTZ, r1, r2: string;
begin
  // 缓存 warm-up
  r1 := os_timezone;

  // 选一个确定“不同于旧值”的 TZ（os_timezone 对 env 不做校验，字符串即可）
  if r1 = 'Etc/UTC' then
    newTZ := 'Asia/Shanghai'
  else
    newTZ := 'Etc/UTC';

  oldTZ := os_getenv('TZ');
  try
    AssertTrue(os_setenv('TZ', newTZ));

    // 未 reset 前仍应返回旧缓存
    r2 := os_timezone;
    AssertEquals('cache not refreshed without reset', r1, r2);

    // reset IANA 也应刷新 Unix 的 timezone（因为 timezone_iana == timezone）
    os_cache_reset_ex([oscTimezoneIana]);
    r2 := os_timezone;

    // 软断言：允许返回空（极简系统），否则应等于 newTZ
    AssertTrue('after reset (iana), tz updated or empty', (r2 = '') or (r2 = newTZ));
  finally
    if oldTZ <> '' then os_setenv('TZ', oldTZ) else os_unsetenv('TZ');
    os_cache_reset_ex([oscTimezone, oscTimezoneIana]);
  end;
end;

procedure TTestCase_Global.Test_SystemErrorToOSError_unix_mapping;
begin
  AssertEquals(Integer(oseSuccess), Integer(SystemErrorToOSError(0)));
  AssertEquals(Integer(osePermissionDenied), Integer(SystemErrorToOSError(ESysEPERM)));
  AssertEquals(Integer(oseNotFound), Integer(SystemErrorToOSError(ESysENOENT)));
  AssertEquals(Integer(oseInterrupted), Integer(SystemErrorToOSError(ESysEINTR)));
  AssertEquals(Integer(oseOutOfMemory), Integer(SystemErrorToOSError(ESysENOMEM)));
  AssertEquals(Integer(osePermissionDenied), Integer(SystemErrorToOSError(ESysEACCES)));
  AssertEquals(Integer(oseAlreadyExists), Integer(SystemErrorToOSError(ESysEEXIST)));
  AssertEquals(Integer(oseInvalidInput), Integer(SystemErrorToOSError(ESysEINVAL)));
  AssertEquals(Integer(oseResourceBusy), Integer(SystemErrorToOSError(ESysEBUSY)));
  AssertEquals(Integer(oseTimeout), Integer(SystemErrorToOSError(ESysETIMEDOUT)));
end;
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

// Result-based API tests implementation
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

procedure TTestCase_Global.Test_os_cpu_info_result;
var
  r: specialize TResult<TCPUInfo, TOSError>;
begin
  r := os_cpu_info;
  AssertTrue('cpu info ok', r.IsOk);
  AssertTrue('model non-empty', r.Unwrap.Model <> '');
end;

procedure TTestCase_Global.Test_os_memory_info_result;
var
  r: specialize TResult<TMemoryInfo, TOSError>;
begin
  r := os_memory_info_detailed;
  {$IF DEFINED(LINUX) OR DEFINED(WINDOWS)}
  AssertTrue('memory info ok', r.IsOk);
  AssertTrue('total > 0', r.Unwrap.Total > 0);
  {$ELSE}
  // macOS: advanced memory probe not yet implemented, expect Err
  AssertTrue('memory info returns Err on macOS', r.IsErr);
  {$ENDIF}
end;

procedure TTestCase_Global.Test_os_storage_info_result;
var
  r: specialize TResult<TStorageInfoArray, TOSError>;
begin
  r := os_storage_info;
  {$IF DEFINED(LINUX) OR DEFINED(WINDOWS)}
  AssertTrue('storage info ok', r.IsOk);
  AssertTrue('at least one entry', Length(r.Unwrap) > 0);
  {$ELSE}
  // macOS: storage probe not yet implemented, expect Err
  AssertTrue('storage info returns Err on macOS', r.IsErr);
  {$ENDIF}
end;

procedure TTestCase_Global.Test_os_network_interfaces_result;
var
  r: specialize TResult<TNetworkInterfaceArray, TOSError>;
begin
  r := os_network_interfaces;
  {$IF DEFINED(LINUX) OR DEFINED(WINDOWS)}
  AssertTrue('network info ok', r.IsOk);
  AssertTrue('at least one interface', Length(r.Unwrap) > 0);
  {$ELSE}
  // macOS: network probe not yet implemented, expect Err
  AssertTrue('network info returns Err on macOS', r.IsErr);
  {$ENDIF}
end;

procedure TTestCase_Global.Test_os_system_load_result;
var
  r: specialize TResult<TSystemLoad, TOSError>;
begin
  r := os_system_load;
  {$IFDEF LINUX}
  AssertTrue('load ok', r.IsOk);
  AssertTrue('load1 >= 0', r.Unwrap.Load1Min >= 0);
  {$ELSE}
  {$IFDEF WINDOWS}
  // Windows: system load returns Ok but with -1 values (unknown)
  AssertTrue('load ok on Windows', r.IsOk);
  AssertTrue('load1 is -1 (unknown) on Windows', r.Unwrap.Load1Min = -1);
  {$ELSE}
  // macOS: system load not yet implemented, expect Err
  AssertTrue('load returns Err on macOS', r.IsErr);
  {$ENDIF}
  {$ENDIF}
end;

procedure TTestCase_Global.Test_os_system_info_result;
var
  r: specialize TResult<TSystemInfo, TOSError>;
begin
  r := os_system_info;
  AssertTrue('system info ok', r.IsOk);
  AssertTrue('platform OS non-empty', r.Unwrap.Platform.OS <> '');
  {$IFDEF LINUX}
  AssertTrue('network present', Length(r.Unwrap.Network) > 0);
  {$ELSE}
  // Windows/macOS: network info not yet implemented, may be empty
  // Just check it doesn't crash
  {$ENDIF}
end;

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
  LResult: Boolean;
begin
  LResult := os_memory_info_ex(Info);
  {$IF DEFINED(LINUX) OR DEFINED(WINDOWS)}
  AssertTrue('Should return success', LResult);
  AssertTrue('Total memory should be positive', Info.Total > 0);
  AssertTrue('Available memory should not exceed total', Info.Available <= Info.Total);
  AssertTrue('Used should not exceed total', Info.Used <= Info.Total);
  AssertTrue('Free should not exceed total', Info.Free <= Info.Total);
  {$ELSE}
  // macOS: advanced memory probe not yet implemented
  AssertFalse('Should return false on macOS', LResult);
  {$ENDIF}
end;

procedure TTestCase_Global.Test_os_storage_info_ex;
var
  Info: TStorageInfoArray;
  LResult: Boolean;
begin
  LResult := os_storage_info_ex(Info);
  {$IF DEFINED(LINUX) OR DEFINED(WINDOWS)}
  AssertTrue('Should return success', LResult);
  AssertTrue('Should have at least one entry', Length(Info) > 0);
  {$ELSE}
  // macOS: storage probe not yet implemented
  AssertFalse('Should return false on macOS', LResult);
  {$ENDIF}
end;

procedure TTestCase_Global.Test_os_network_interfaces_ex;
var
  Info: TNetworkInterfaceArray;
  LResult: Boolean;
begin
  LResult := os_network_interfaces_ex(Info);
  {$IF DEFINED(LINUX) OR DEFINED(WINDOWS)}
  AssertTrue('Should return success', LResult);
  AssertTrue('Should have at least one interface', Length(Info) > 0);
  {$ELSE}
  // macOS: network probe not yet implemented
  AssertFalse('Should return false on macOS', LResult);
  {$ENDIF}
end;

procedure TTestCase_Global.Test_os_system_load_ex;
var
  Info: TSystemLoad;
  LResult: Boolean;
begin
  LResult := os_system_load_ex(Info);
  {$IFDEF LINUX}
  AssertTrue('Should return success', LResult);
  AssertTrue('Load1Min should be >= 0', Info.Load1Min >= 0);
  {$ELSE}
  {$IFDEF WINDOWS}
  // Windows: system load returns True but with -1 values (unknown)
  AssertTrue('Should return success on Windows', LResult);
  AssertTrue('Load1Min should be -1 (unknown) on Windows', Info.Load1Min = -1);
  {$ELSE}
  // macOS: system load not yet implemented
  AssertFalse('Should return false on macOS', LResult);
  {$ENDIF}
  {$ENDIF}
end;

procedure TTestCase_Global.Test_os_system_info_ex;
var
  Info: TSystemInfo;
  expectedBt: QWord;
  nowEpoch: QWord;
  diff: Int64;
begin
  expectedBt := os_boot_time;
  AssertTrue('Should return success', os_system_info_ex(Info));

  // Check platform information
  AssertTrue('OS should not be empty', Info.Platform.OS <> '');
  AssertTrue('Architecture should not be empty', Info.Platform.Architecture <> '');
  AssertTrue('CPU count should be positive', Info.Platform.CPUCount > 0);

  // Check CPU information
  AssertTrue('CPU model should not be empty', Info.CPU.Model <> '');
  AssertTrue('CPU cores should be positive', Info.CPU.Cores > 0);

  // Check memory information
  {$IFDEF LINUX}
  AssertTrue('Total memory should be positive', Info.Memory.Total > 0);
  {$ELSE}
  // Windows/macOS: advanced memory probe not yet implemented, Memory.Total may be 0
  {$ENDIF}

  // Check OS version
  AssertTrue('OS name should not be empty', Info.OSVersion.Name <> '');

  // BootTime: epoch seconds (0 if unknown)
  if Info.BootTime > 0 then
  begin
    nowEpoch := DateTimeToUnix(Now, True);
    AssertTrue('boot time should not be in the future', Info.BootTime <= nowEpoch + 60);
    if expectedBt > 0 then
    begin
      diff := Int64(Info.BootTime) - Int64(expectedBt);
      if diff < 0 then diff := -diff;
      AssertTrue('boot time matches os_boot_time (soft)', diff <= 2);
    end;
  end;

  // Boot time and uptime can be 0 if unknown, so we don't check for positive values
end;
{$IFDEF LINUX}
procedure TTestCase_Global.Test_os_storage_info_ex_linux;
var
  Info: TStorageInfoArray;
  ok: Boolean;
begin
  ok := os_storage_info_ex(Info);
  AssertTrue('storage info ok', ok);
  AssertTrue('storage devices present', Length(Info) > 0);
  AssertTrue('first mount path not empty', Info[0].Path <> '');
  AssertTrue('total space positive', Info[0].Total > 0);
  AssertTrue('avail <= total', Info[0].Available <= Info[0].Total);
end;

procedure TTestCase_Global.Test_os_network_interfaces_ex_linux;
var
  Info: TNetworkInterfaceArray;
  ok: Boolean;
begin
  ok := os_network_interfaces_ex(Info);
  AssertTrue('network info ok', ok);
  AssertTrue('at least one interface', Length(Info) > 0);
  AssertTrue('interface name not empty', Info[0].Name <> '');
end;

procedure TTestCase_Global.Test_os_system_load_ex_linux;
var
  Info: TSystemLoad;
  ok: Boolean;
begin
  ok := os_system_load_ex(Info);
  AssertTrue('load info ok', ok);
  AssertTrue('load1 non-negative', Info.Load1Min >= 0);
  AssertTrue('load5 non-negative', Info.Load5Min >= 0);
  AssertTrue('load15 non-negative', Info.Load15Min >= 0);
  AssertTrue('running >= 0', Info.RunningProcesses >= 0);
  AssertTrue('total >= running or unknown', (Info.TotalProcesses = -1) or (Info.TotalProcesses >= Info.RunningProcesses));
end;

procedure TTestCase_Global.Test_os_system_info_ex_enhanced_linux;
var
  Info: TSystemInfo;
  ok: Boolean;
begin
  ok := os_system_info_ex(Info);
  AssertTrue('system info ok', ok);
  AssertTrue('storage populated', Length(Info.Storage) > 0);
  AssertTrue('network populated', Length(Info.Network) > 0);
  AssertTrue('load populated', Info.Load.Load1Min >= 0);
end;

procedure TTestCase_Global.Test_cache_probes_flag_enabled;
const
  CacheOn: Boolean = {$IFDEF FAFAFA_OS_CACHE_PROBES}True{$ELSE}False{$ENDIF};
begin
  AssertTrue('FAFAFA_OS_CACHE_PROBES must be enabled by default', CacheOn);
end;

procedure TTestCase_Global.Test_os_storage_root_mount_linux;
var
  Info: TStorageInfoArray;
  i: Integer;
  hasRoot: Boolean;
begin
  AssertTrue(os_storage_info_ex(Info));
  hasRoot := False;
  for i := 0 to High(Info) do
    if Info[i].Path = '/' then
      hasRoot := True;
  AssertTrue('root mount should exist', hasRoot);
end;

procedure TTestCase_Global.Test_os_storage_root_readonly_matches_mount_opts_linux;
var
  Info: TStorageInfoArray;
  i, rootIdx: Integer;
  expectedReadOnly: Boolean;
  f: Text;
  line, mnt, opts, rootOpts: string;
  p1, p2, p3: Integer;
begin
  // Read mount options for '/' from /proc/self/mounts
  rootOpts := '';
  Assign(f, '/proc/self/mounts');
  {$I-} Reset(f); {$I+}
  if IOResult = 0 then
  begin
    try
      while not EOF(f) do
      begin
        ReadLn(f, line);
        // format: dev mnt fs opts ...
        p1 := Pos(' ', line);
        if p1 = 0 then Continue;
        Delete(line, 1, p1);
        p2 := Pos(' ', line);
        if p2 = 0 then Continue;
        mnt := Copy(line, 1, p2-1);
        Delete(line, 1, p2);
        p3 := Pos(' ', line);
        if p3 = 0 then Continue;
        Delete(line, 1, p3);
        p3 := Pos(' ', line);
        if p3 = 0 then opts := line else opts := Copy(line, 1, p3-1);
        if mnt = '/' then
        begin
          rootOpts := opts;
          Break;
        end;
      end;
    finally
      Close(f);
    end;
  end;

  // soft skip if /proc not available/unexpected
  if rootOpts = '' then
  begin
    AssertTrue('no root mount opts found (soft)', True);
    Exit;
  end;

  // Expected: only ',ro,' token means read-only (avoid false positive on 'remount-ro')
  expectedReadOnly := Pos(',ro,', ',' + rootOpts + ',') > 0;

  AssertTrue(os_storage_info_ex(Info));
  rootIdx := -1;
  for i := 0 to High(Info) do
    if Info[i].Path = '/' then
    begin
      rootIdx := i;
      Break;
    end;
  AssertTrue('root mount should exist', rootIdx >= 0);
  AssertTrue('IsReadOnly should match mount opts ro token', Info[rootIdx].IsReadOnly = expectedReadOnly);
end;

procedure TTestCase_Global.Test_os_storage_mountopts_remount_ro_not_readonly_linux;
var
  Info: TStorageInfoArray;
  i, idx: Integer;
  expectedReadOnly: Boolean;
  f: Text;
  line, mnt, opts: string;
  p1, p2, p3: Integer;
  targetMnt, targetOpts: string;
begin
  // Find a mount whose options include 'remount-ro' but do NOT include the explicit ',ro,' token.
  // A common example is ext4/vfat with 'errors=remount-ro'.
  targetMnt := '';
  targetOpts := '';
  Assign(f, '/proc/self/mounts');
  {$I-} Reset(f); {$I+}
  if IOResult = 0 then
  begin
    try
      while not EOF(f) do
      begin
        ReadLn(f, line);
        // format: dev mnt fs opts ...
        p1 := Pos(' ', line);
        if p1 = 0 then Continue;
        Delete(line, 1, p1);
        p2 := Pos(' ', line);
        if p2 = 0 then Continue;
        mnt := Copy(line, 1, p2-1);
        Delete(line, 1, p2);
        p3 := Pos(' ', line);
        if p3 = 0 then Continue;
        Delete(line, 1, p3);
        p3 := Pos(' ', line);
        if p3 = 0 then opts := line else opts := Copy(line, 1, p3-1);

        if (Pos('remount-ro', opts) > 0) and (Pos(',ro,', ',' + opts + ',') = 0) then
        begin
          targetMnt := mnt;
          targetOpts := opts;
          Break;
        end;
      end;
    finally
      Close(f);
    end;
  end;

  // soft skip if no such mount exists in this environment
  if targetMnt = '' then
  begin
    AssertTrue('no remount-ro mount found (soft)', True);
    Exit;
  end;

  // sanity: this is a case where naive substring search would be a false positive
  AssertTrue('sanity: opts contains substring "ro"', Pos('ro', ',' + targetOpts + ',') > 0);
  AssertTrue('sanity: opts does NOT contain token ",ro,"', Pos(',ro,', ',' + targetOpts + ',') = 0);

  expectedReadOnly := Pos(',ro,', ',' + targetOpts + ',') > 0;

  AssertTrue(os_storage_info_ex(Info));
  idx := -1;
  for i := 0 to High(Info) do
    if Info[i].Path = targetMnt then
    begin
      idx := i;
      Break;
    end;
  AssertTrue('mount should exist in storage info', idx >= 0);
  AssertTrue('remount-ro should not imply read-only without ro token', Info[idx].IsReadOnly = expectedReadOnly);
end;

procedure TTestCase_Global.Test_os_memory_info_ex_linux_details;
var
  Info: TMemoryInfo;
  f: Text;
  s, key, num: string;
  p, p2, code: Integer;
  v: QWord;
  memTotal, memAvail, memFree, memCached, memBuffers: QWord;
  swapTotal, swapFree: QWord;
  delta, diff: QWord;
  expectedPressure: Double;
begin
  memTotal := 0; memAvail := 0; memFree := 0; memCached := 0; memBuffers := 0;
  swapTotal := 0; swapFree := 0;

  // Parse /proc/meminfo (values are in kB)
  Assign(f, '/proc/meminfo');
  {$I-} Reset(f); {$I+}
  if IOResult <> 0 then
  begin
    AssertTrue('no /proc/meminfo (soft)', True);
    Exit;
  end;
  try
    while not EOF(f) do
    begin
      ReadLn(f, s);
      p := Pos(':', s);
      if p <= 0 then Continue;
      key := Copy(s, 1, p-1);
      s := Trim(Copy(s, p+1, MaxInt));
      p2 := Pos(' ', s);
      if p2 > 0 then num := Copy(s, 1, p2-1) else num := s;
      Val(num, v, code);
      if code <> 0 then Continue;
      v := v * 1024;

      if SameText(key, 'MemTotal') then memTotal := v
      else if SameText(key, 'MemAvailable') then memAvail := v
      else if SameText(key, 'MemFree') then memFree := v
      else if SameText(key, 'Cached') then memCached := v
      else if SameText(key, 'Buffers') then memBuffers := v
      else if SameText(key, 'SwapTotal') then swapTotal := v
      else if SameText(key, 'SwapFree') then swapFree := v;
    end;
  finally
    Close(f);
  end;

  // soft skip if /proc/meminfo is unexpected
  if memTotal = 0 then
  begin
    AssertTrue('MemTotal missing (soft)', True);
    Exit;
  end;

  AssertTrue(os_memory_info_ex(Info));
  AssertTrue('total matches MemTotal', Info.Total = memTotal);

  // Available is best-effort; if present, we can validate consistency and pressure.
  if memAvail > 0 then
  begin
    AssertTrue('available should be > 0', Info.Available > 0);
    AssertTrue('available <= total', Info.Available <= Info.Total);
    AssertTrue('used == total - available', Info.Used = Info.Total - Info.Available);

    AssertTrue('pressure should be computed', (Info.Pressure >= 0.0) and (Info.Pressure <= 1.0));
    expectedPressure := Info.Used / Info.Total;
    AssertTrue('pressure matches used/total (soft)', Abs(Info.Pressure - expectedPressure) < 1e-6);
  end;

  // Free/Cached/Buffers should be populated when present in /proc/meminfo.
  if memFree > 0 then
  begin
    // Allow small drift between snapshots.
    delta := memTotal div 100;
    if delta < (16 * 1024 * 1024) then delta := (16 * 1024 * 1024);
    if delta > (256 * 1024 * 1024) then delta := (256 * 1024 * 1024);

    if Info.Free >= memFree then diff := Info.Free - memFree else diff := memFree - Info.Free;
    AssertTrue('free should match MemFree (soft)', diff <= delta);
  end;

  if memCached > 0 then
    AssertTrue('cached should be populated', Info.Cached > 0);

  if memBuffers > 0 then
    AssertTrue('buffers should be populated', Info.Buffers > 0);

  if swapTotal > 0 then
  begin
    AssertTrue('swap total should be populated', Info.Swap.Total > 0);
    AssertTrue('swap available <= total', Info.Swap.Available <= Info.Swap.Total);
    AssertTrue('swap used == total - available', Info.Swap.Used = Info.Swap.Total - Info.Swap.Available);

    // If SwapFree is present, validate Available with a tolerance.
    if swapFree > 0 then
    begin
      // Allow drift between snapshots.
      delta := swapTotal div 100;
      if delta < (16 * 1024 * 1024) then delta := (16 * 1024 * 1024);
      if delta > (1024 * 1024 * 1024) then delta := (1024 * 1024 * 1024);

      if Info.Swap.Available >= swapFree then diff := Info.Swap.Available - swapFree else diff := swapFree - Info.Swap.Available;
      AssertTrue('swap free should match SwapFree (soft)', diff <= delta);
    end;
  end;
end;

procedure TTestCase_Global.Test_os_network_loopback_has_ip_linux;
var
  Info: TNetworkInterfaceArray;
  i, j: Integer;
  hasLo, hasIP: Boolean;
begin
  AssertTrue(os_network_interfaces_ex(Info));
  hasLo := False; hasIP := False;
  for i := 0 to High(Info) do
    if Info[i].Name = 'lo' then
    begin
      hasLo := True;
      for j := 0 to High(Info[i].IPAddresses) do
        if (Pos('127.', Info[i].IPAddresses[j]) = 1) or (Info[i].IPAddresses[j] = '::1') then
          hasIP := True;
    end;
  AssertTrue('loopback exists', hasLo);
  AssertTrue('loopback has ip', hasIP);
end;

procedure TTestCase_Global.Test_os_network_sysfs_non_loopback_enumerated_linux;
var
  Info: TNetworkInterfaceArray;
  sr: TSearchRec;
  i: Integer;
  hasNonLoopSysfs, hasNonLoop: Boolean;
begin
  // If /sys/class/net contains any non-loopback interface, os_network_interfaces_ex
  // should enumerate at least one non-loopback entry.
  hasNonLoopSysfs := False;
  if FindFirst('/sys/class/net/*', faAnyFile, sr) = 0 then
  begin
    try
      repeat
        if (sr.Name = '.') or (sr.Name = '..') then Continue;
        if sr.Name = 'lo' then Continue;
        hasNonLoopSysfs := True;
        Break;
      until FindNext(sr) <> 0;
    finally
      FindClose(sr);
    end;
  end;

  // soft skip for minimal/container environments
  if not hasNonLoopSysfs then
  begin
    AssertTrue('no non-loopback interfaces in /sys/class/net (soft)', True);
    Exit;
  end;

  AssertTrue(os_network_interfaces_ex(Info));
  hasNonLoop := False;
  for i := 0 to High(Info) do
    if Info[i].Name <> 'lo' then
      hasNonLoop := True;

  AssertTrue('non-loopback interface should be enumerated', hasNonLoop);
end;

procedure TTestCase_Global.Test_os_network_non_loopback_ipv4_present_linux;
var
  expectedIPs: TStringList;
  Info: TNetworkInterfaceArray;
  f: Text;
  line, prevLine, ip: string;
  i, j: Integer;
  found, hasExpected: Boolean;
  p: Integer;
begin
  // Parse /proc/net/fib_trie for host-local /32 IPv4 addresses.
  // We expect os_network_interfaces_ex to report at least one non-loopback IPv4 if such
  // addresses exist.
  expectedIPs := TStringList.Create;
  try
    expectedIPs.Sorted := True;
    expectedIPs.Duplicates := dupIgnore;

    prevLine := '';
    Assign(f, '/proc/net/fib_trie');
    {$I-} Reset(f); {$I+}
    if IOResult = 0 then
    begin
      try
        while not EOF(f) do
        begin
          ReadLn(f, line);
          if Pos('/32 host LOCAL', line) > 0 then
          begin
            p := Pos('|--', prevLine);
            if p > 0 then
            begin
              ip := Trim(Copy(prevLine, p + 3, MaxInt));
              if (ip <> '') and (Pos('127.', ip) <> 1) then
                expectedIPs.Add(ip);
            end;
          end;
          prevLine := line;
        end;
      finally
        Close(f);
      end;
    end;

    hasExpected := expectedIPs.Count > 0;
    if not hasExpected then
    begin
      AssertTrue('no non-loopback IPv4 in fib_trie (soft)', True);
      Exit;
    end;

    AssertTrue(os_network_interfaces_ex(Info));
    found := False;
    for i := 0 to High(Info) do
      for j := 0 to High(Info[i].IPAddresses) do
        if expectedIPs.IndexOf(Info[i].IPAddresses[j]) >= 0 then
          found := True;

    AssertTrue('should enumerate at least one non-loopback IPv4 address', found);
  finally
    expectedIPs.Free;
  end;
end;

procedure TTestCase_Global.Test_os_cpu_info_ex_features_frequency_linux;
var
  Info: TCPUInfo;
  f: Text;
  line, key, val: string;
  p: Integer;
  featuresLine, mhzLine: string;
begin
  featuresLine := '';
  mhzLine := '';

  Assign(f, '/proc/cpuinfo');
  {$I-} Reset(f); {$I+}
  if IOResult <> 0 then
  begin
    AssertTrue('no /proc/cpuinfo (soft)', True);
    Exit;
  end;
  try
    while not EOF(f) do
    begin
      ReadLn(f, line);
      p := Pos(':', line);
      if p <= 0 then Continue;
      key := Trim(Copy(line, 1, p-1));
      val := Trim(Copy(line, p+1, MaxInt));

      if (featuresLine = '') and (SameText(key, 'flags') or SameText(key, 'Features')) then
        featuresLine := val;

      if (mhzLine = '') and SameText(key, 'cpu MHz') then
        mhzLine := val;

      if (featuresLine <> '') and (mhzLine <> '') then Break;
    end;
  finally
    Close(f);
  end;

  // soft skip for unexpected cpuinfo formats
  if (featuresLine = '') and (mhzLine = '') then
  begin
    AssertTrue('no cpuinfo flags/features/mhz found (soft)', True);
    Exit;
  end;

  AssertTrue(os_cpu_info_ex(Info));

  if featuresLine <> '' then
    AssertTrue('features should be populated', Length(Info.Features) > 0);

  if mhzLine <> '' then
    AssertTrue('frequency should be populated', Info.Frequency > 0);
end;

procedure TTestCase_Global.Test_os_cpu_info_ex_cache_sizes_linux;
var
  Info: TCPUInfo;
  LExpectedL1: QWord;
  LExpectedL2: QWord;
  LExpectedL3: QWord;

  function ReadFirstLineTrimmed(const aPath: string): string;
  var
    LFile: Text;
    LLine: string;
  begin
    Result := '';
    Assign(LFile, aPath);
    {$I-} Reset(LFile); {$I+}
    if IOResult <> 0 then
      Exit;
    try
      if not EOF(LFile) then
      begin
        ReadLn(LFile, LLine);
        Result := Trim(LLine);
      end;
    finally
      Close(LFile);
    end;
  end;

  function ParseSizeToBytes(const aText: string): QWord;
  var
    LText: string;
    LCode: Integer;
    LValue: QWord;
    LUnit: Char;
    LNum: string;
  begin
    Result := 0;
    LText := Trim(aText);
    if LText = '' then
      Exit;

    LUnit := UpCase(LText[Length(LText)]);
    if (LUnit >= '0') and (LUnit <= '9') then
    begin
      Val(LText, LValue, LCode);
      if LCode = 0 then
        Result := LValue;
      Exit;
    end;

    LNum := Trim(Copy(LText, 1, Length(LText) - 1));
    Val(LNum, LValue, LCode);
    if LCode <> 0 then
      Exit;

    case LUnit of
      'K': Result := LValue * 1024;
      'M': Result := LValue * 1024 * 1024;
      'G': Result := LValue * 1024 * 1024 * 1024;
    else
      Result := LValue;
    end;
  end;

  procedure ComputeExpectedCacheSizes;
  var
    LBase: string;
    LRec: TSearchRec;
    LDir: string;
    LLevel: Integer;
    LLevelText: string;
    LSizeText: string;
    LSize: QWord;
  begin
    LExpectedL1 := 0;
    LExpectedL2 := 0;
    LExpectedL3 := 0;

    LBase := '/sys/devices/system/cpu/cpu0/cache';
    if not DirectoryExists(LBase) then
      Exit;

    if FindFirst(LBase + '/index*', faDirectory, LRec) = 0 then
    try
      repeat
        if (LRec.Name = '.') or (LRec.Name = '..') then
          Continue;
        if (LRec.Attr and faDirectory) = 0 then
          Continue;

        LDir := LBase + '/' + LRec.Name;
        LLevelText := ReadFirstLineTrimmed(LDir + '/level');
        LSizeText := ReadFirstLineTrimmed(LDir + '/size');

        LLevel := StrToIntDef(LLevelText, 0);
        LSize := ParseSizeToBytes(LSizeText);
        if (LLevel <= 0) or (LSize = 0) then
          Continue;

        case LLevel of
          1: Inc(LExpectedL1, LSize);
          2: if LSize > LExpectedL2 then LExpectedL2 := LSize;
          3: if LSize > LExpectedL3 then LExpectedL3 := LSize;
        end;
      until FindNext(LRec) <> 0;
    finally
      FindClose(LRec);
    end;
  end;

begin
  if not DirectoryExists('/sys/devices/system/cpu/cpu0/cache') then
  begin
    AssertTrue('no sysfs cache info (soft)', True);
    Exit;
  end;

  ComputeExpectedCacheSizes;
  if (LExpectedL1 = 0) and (LExpectedL2 = 0) and (LExpectedL3 = 0) then
  begin
    AssertTrue('sysfs cache sizes unreadable (soft)', True);
    Exit;
  end;

  AssertTrue(os_cpu_info_ex(Info));

  if LExpectedL1 > 0 then
    AssertEquals('CacheL1 mismatch', Int64(LExpectedL1), Int64(Info.CacheL1));
  if LExpectedL2 > 0 then
    AssertEquals('CacheL2 mismatch', Int64(LExpectedL2), Int64(Info.CacheL2));
  if LExpectedL3 > 0 then
    AssertEquals('CacheL3 mismatch', Int64(LExpectedL3), Int64(Info.CacheL3));
end;

procedure TTestCase_Global.Test_os_cpu_info_usage_linux;
var
  info1, info2: TCPUInfo;
begin
  // Ensure a clean sampling baseline.
  os_cache_reset;

  // Non-blocking sampling: first call may not have enough data to compute usage.
  AssertTrue(os_cpu_info_ex(info1));
  AssertTrue('first call usage should be unknown', Abs(info1.Usage + 1.0) < 1e-9);

  Sleep(10);
  AssertTrue(os_cpu_info_ex(info2));
  AssertTrue('cpu usage >= -0.01', info2.Usage >= -0.01);
  AssertTrue('cpu usage <= 1.1', info2.Usage <= 1.1);
end;
{$ENDIF}

initialization
  RegisterTest('TTestCase_Global', TTestCase_Global);

end.

