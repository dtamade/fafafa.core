unit fafafa.core.os;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes;

// Cross-platform OS helpers inspired by Rust std::env/std::process (info-side) and Go os package

type
  TPlatformInfo = record
    OS: string;
    Architecture: string;
    Endianness: string;
    Is64Bit: Boolean;
    CPUCount: Integer;
    PageSize: Integer;
    HostName: string;
    UserName: string;
    HomeDir: string;
    TempDir: string;
    ExePath: string;
  end;

  TOSVersionDetailed = record
    Name: string;
    VersionString: string;
    Build: string;
    Codename: string;
    PrettyName: string; // optional, human friendly
    ID: string;         // distro id (Linux), else empty
    IDLike: string;     // distro family (Linux), else empty
  end;


// Environment variable helpers
function os_getenv(const AName: string): string;
function os_lookupenv(const AName: string; out AValue: string): Boolean; // True if defined (even if empty)

function os_setenv(const AName, AValue: string): Boolean; // returns True if success
function os_unsetenv(const AName: string): Boolean;       // returns True if success
procedure os_environ(const ADest: TStrings);              // fills ADest with NAME=VALUE pairs

// Basic platform/system queries
function os_hostname: string;
function os_username: string;
function os_home_dir: string;
function os_temp_dir: string;
function os_exe_path: string;
function os_cpu_count: Integer;
function os_page_size: Integer;
function os_kernel_version: string;
function os_uptime: QWord;              // seconds since boot (best-effort)
function os_memory_info(out totalBytes, freeBytes: QWord): Boolean; // total/free, best-effort
function os_boot_time: QWord;           // seconds since epoch, 0 if unknown
// Second-batch OS info
function os_os_version_detailed: TOSVersionDetailed;
function os_cpu_model: string;
function os_locale_current: string;

function os_timezone: string;           // best-effort, may be empty
function os_timezone_iana: string;      // best-effort: Windows maps StandardName->IANA; Unix returns os_timezone


// Non-strict convenience
function os_exe_dir: string;

  // Strict variants (Boolean + out) for error-aware callers
  function os_exe_path_ex(out APath: string): Boolean;
  function os_home_dir_ex(out APath: string): Boolean;
  function os_kernel_version_ex(out S: string): Boolean;
  function os_timezone_ex(out S: string): Boolean;
  function os_timezone_iana_ex(out S: string): Boolean;

  function os_os_version_detailed_ex(out V: TOSVersionDetailed): Boolean;

  function os_username_ex(out AName: string): Boolean;
  function os_exe_dir_ex(out ADir: string): Boolean;


  function os_hostname_ex(out S: string): Boolean;
  function os_temp_dir_ex(out S: string): Boolean;

type
  TOSCacheFlags = set of (oscTimezone, oscTimezoneIana, oscCpuModel, oscIsAdmin, oscKernelVersion, oscOSVersionDetailed);

procedure os_cache_reset;               // reset all process-level caches for OS probes
procedure os_cache_reset_ex(const flags: TOSCacheFlags); // reset selected caches

// Capability probes (best-effort)
function os_is_admin: Boolean;
function os_is_wsl: Boolean;
function os_is_container: Boolean;
function os_is_ci: Boolean;

function os_platform_info: TPlatformInfo;

implementation

uses
  {$IFDEF WINDOWS} Windows {$ELSE} BaseUnix, Unix {$ENDIF}, DateUtils;

{$IFDEF WINDOWS}
{$I fafafa.core.os.windows.inc}
{$ELSE}
{$I fafafa.core.os.common.inc}
{$I fafafa.core.os.unix.inc}
{$ENDIF}

function os_exe_path: string;
{$IFDEF DARWIN}
  // macOS: use _NSGetExecutablePath
  function _NSGetExecutablePath(buf: PAnsiChar; var size: Cardinal): Integer; cdecl; external 'c';
{$ENDIF}
var
  {$IFDEF WINDOWS}
  ws: UnicodeString;
  cap, len: DWORD;
  {$ELSE}
    {$IFDEF LINUX}
    linkbuf: array[0..4095] of Char;
    L: ssize_t;
    {$ENDIF}
    sizeDarwin: Cardinal;
  {$ENDIF}
  tmp: string;
begin
  {$IFDEF WINDOWS}
  // Use dynamic buffer to avoid truncation if any
  cap := 1024;
  len := 0;
  repeat
    SetLength(ws, cap);
    len := GetModuleFileNameW(0, PWideChar(ws), cap);
    if (len = 0) then begin Result := ''; Exit; end;
    if (len < cap) then break; // not truncated
    if cap >= 65536 then break; // safety cap
    cap := cap * 2;
  until False;
  SetLength(ws, len);
  Result := UTF8Encode(WideString(ws));
  {$ELSE}
  {$IFDEF DARWIN}
  // Try _NSGetExecutablePath
  sizeDarwin := 0;
  // First call to get required size
  if _NSGetExecutablePath(nil, sizeDarwin) <> 0 then
  begin
    // allocate buffer dynamically
    SetLength(tmp, sizeDarwin);
    if _NSGetExecutablePath(PAnsiChar(@tmp[1]), sizeDarwin) = 0 then
      Result := string(tmp)
    else
      Result := '';
  end
  else
  begin
    // unlikely: size known as 0
    Result := ParamStr(0);
  end;
  {$ELSE}
  {$IFDEF LINUX}
  // Linux: readlink /proc/self/exe
  L := fpReadlink('/proc/self/exe', @linkbuf[0], SizeOf(linkbuf)-1);
  if L > 0 then
  begin
    linkbuf[L] := #0;
    Result := StrPas(@linkbuf[0]);
  end
  else
    Result := ParamStr(0);
  {$ELSE}
  // Other Unix: best-effort fallback
  Result := ParamStr(0);
  {$ENDIF}
  {$ENDIF}
{$ENDIF}

end;

function os_cpu_count: Integer;
begin
  {$IFDEF FPC}
  Result := TThread.ProcessorCount;
  if Result <= 0 then
    Result := 1;
  {$ELSE}
  Result := 1;
  {$ENDIF}
end;

function os_platform_info: TPlatformInfo;
begin
  Result.OS := {$IFDEF WINDOWS}'Windows'{$ELSE}{$IFDEF LINUX}'Linux'{$ELSE}{$IFDEF DARWIN}'macOS'{$ELSE}'Unix'{$ENDIF}{$ENDIF}{$ENDIF};
  {$IF DEFINED(CPUX64)}
    Result.Architecture := 'amd64';
  {$ELSEIF DEFINED(CPUX86)}
    Result.Architecture := '386';
  {$ELSEIF DEFINED(CPUAARCH64)}
    Result.Architecture := 'arm64';
  {$ELSEIF DEFINED(CPUARM)}
    Result.Architecture := 'arm';
  {$ELSEIF DEFINED(CPURISCV64)}
    Result.Architecture := 'riscv64';
  {$ELSE}
    Result.Architecture := 'unknown';
  {$ENDIF}
  Result.Endianness := {$IFDEF ENDIAN_LITTLE}'Little'{$ELSE}'Big'{$ENDIF};
  Result.Is64Bit := {$IFDEF CPU64}True{$ELSE}False{$ENDIF};
  Result.CPUCount := os_cpu_count;
  Result.PageSize := os_page_size;
  Result.HostName := os_hostname;
  Result.UserName := os_username;
  Result.HomeDir := os_home_dir;
  Result.TempDir := os_temp_dir;
  Result.ExePath := os_exe_path;
end;

function os_exe_path_ex(out APath: string): Boolean;
begin
  APath := os_exe_path;
  Result := (APath <> '');
end;

function os_exe_dir: string;
begin
  Result := ExtractFileDir(os_exe_path);
end;

function os_home_dir_ex(out APath: string): Boolean;
begin
  APath := os_home_dir;
  Result := (APath <> '');
end;

function os_username_ex(out AName: string): Boolean;
begin
  AName := os_username;
  Result := (AName <> '');
end;

function os_kernel_version_ex(out S: string): Boolean;
begin
  S := os_kernel_version;
  Result := (S <> '');
end;

function os_timezone_ex(out S: string): Boolean;
begin
  S := os_timezone;
  // Success 表示探测流程成功完成；值可能为空（系统未配置）。
  Result := True;
end;

function os_timezone_iana_ex(out S: string): Boolean;
begin
  S := os_timezone_iana;
  // Success 表示探测流程成功完成；值可能为空（无法映射或未配置）。
  Result := True;
end;

function os_os_version_detailed_ex(out V: TOSVersionDetailed): Boolean;
begin
  V := os_os_version_detailed;
  // Consider success if at least one key field is non-empty
  Result := (V.Name <> '') or (V.VersionString <> '') or (V.PrettyName <> '');
end;
function os_exe_dir_ex(out ADir: string): Boolean;
var p: string;
begin
  ADir := '';
  p := os_exe_path;
  if p <> '' then
  begin
    ADir := ExtractFileDir(p);
    Result := (ADir <> '');
  end
  else
    Result := False;
end;

function os_hostname_ex(out S: string): Boolean;
begin
  S := os_hostname;
  Result := (S <> '');
end;

function os_temp_dir_ex(out S: string): Boolean;
begin
  S := os_temp_dir;
  Result := (S <> '');
end;



end.

