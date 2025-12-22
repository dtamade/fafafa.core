unit fafafa.core.os;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fafafa.core.result;
  // TODO: Re-enable fafafa.core.result when FreePascal compatibility issues are fixed
  // fafafa.core.result;

// Cross-platform OS helpers inspired by Rust std::env/std::process (info-side) and Go os package

type
  // OS operation error types (inspired by Rust std::io::ErrorKind)
  TOSError = (
    oseSuccess,           // Operation succeeded
    oseNotFound,          // File, directory, or resource not found
    osePermissionDenied,  // Permission denied
    oseInvalidInput,      // Invalid input parameter
    oseSystemError,       // General system error
    oseTimeout,           // Operation timed out
    oseOutOfMemory,       // Out of memory
    oseNotSupported,      // Operation not supported on this platform
    oseAlreadyExists,     // Resource already exists
    oseInterrupted,       // Operation was interrupted
    oseInvalidData,       // Invalid or corrupted data
    oseUnexpectedEof,     // Unexpected end of file/stream
    oseResourceBusy,      // Resource is busy
    oseNetworkError,      // Network-related error
    oseOther              // Other unspecified error
  );

  // Result type aliases for common OS operations
  TOSStringResult = specialize TResult<string, TOSError>;
  TOSBoolResult = specialize TResult<Boolean, TOSError>;

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

  // Enhanced system information structures (inspired by Rust/Go/Java)

  // Array type definitions for FreePascal compatibility
  TStringArray = array of string;

  // Forward declarations for complex types
  TStorageInfo = record
    Path: string;            // Mount point or drive letter
    FileSystem: string;      // File system type (NTFS, ext4, etc.)
    Total: QWord;            // Total space in bytes
    Available: QWord;        // Available space in bytes
    Used: QWord;             // Used space in bytes
    IsRemovable: Boolean;    // Is removable media
    IsReadOnly: Boolean;     // Is read-only
  end;

  TNetworkInterface = record
    Name: string;            // Interface name (eth0, wlan0, etc.)
    DisplayName: string;     // Human-readable name
    HardwareAddress: string; // MAC address
    IPAddresses: TStringArray; // IP addresses (IPv4 and IPv6)
    IsUp: Boolean;           // Interface is up
    IsLoopback: Boolean;     // Is loopback interface
    IsWireless: Boolean;     // Is wireless interface
    MTU: Integer;            // Maximum transmission unit
    Speed: QWord;            // Interface speed in bits per second (0 if unknown)
    BytesSent: QWord;        // Bytes sent (0 if unknown)
    BytesReceived: QWord;    // Bytes received (0 if unknown)
  end;

  TStorageInfoArray = array of TStorageInfo;
  TNetworkInterfaceArray = array of TNetworkInterface;

  // CPU information structure
  TCPUInfo = record
    Model: string;           // CPU model name
    Vendor: string;          // CPU vendor (Intel, AMD, Apple, etc.)
    Cores: Integer;          // Physical cores
    Threads: Integer;        // Logical threads (with hyperthreading)
    Architecture: string;    // x86_64, arm64, etc.
    Frequency: QWord;        // Base frequency in Hz (0 if unknown)
    CacheL1: QWord;          // L1 cache size in bytes (0 if unknown)
    CacheL2: QWord;          // L2 cache size in bytes (0 if unknown)
    CacheL3: QWord;          // L3 cache size in bytes (0 if unknown)
    Features: TStringArray;   // CPU features (SSE, AVX, etc.)
    Usage: Double;           // Current CPU usage 0.0-1.0 (-1 if unknown)
  end;

  // Memory information structure
  TSwapInfo = record
    Total: QWord;            // Total swap space in bytes
    Used: QWord;             // Used swap space in bytes
    Available: QWord;        // Available swap space in bytes
  end;

  TMemoryInfo = record
    Total: QWord;            // Total physical memory in bytes
    Available: QWord;        // Available memory in bytes
    Used: QWord;             // Used memory in bytes
    Free: QWord;             // Free memory in bytes
    Cached: QWord;           // Cached memory in bytes (0 if unknown)
    Buffers: QWord;          // Buffer memory in bytes (0 if unknown)
    Swap: TSwapInfo;         // Swap information
    Pressure: Double;        // Memory pressure 0.0-1.0 (-1 if unknown)
  end;



  // System load information (Unix-style)
  TSystemLoad = record
    Load1Min: Double;        // 1-minute load average (-1 if unknown)
    Load5Min: Double;        // 5-minute load average (-1 if unknown)
    Load15Min: Double;       // 15-minute load average (-1 if unknown)
    RunningProcesses: Integer; // Number of running processes (-1 if unknown)
    TotalProcesses: Integer;   // Total number of processes (-1 if unknown)
  end;

  // Comprehensive system information
  TSystemInfo = record
    Platform: TPlatformInfo;     // Basic platform information
    CPU: TCPUInfo;               // CPU information
    Memory: TMemoryInfo;         // Memory information
    Storage: TStorageInfoArray;    // Storage devices
    Network: TNetworkInterfaceArray; // Network interfaces
    Load: TSystemLoad;           // System load
    OSVersion: TOSVersionDetailed; // Detailed OS version
    BootTime: QWord;             // System boot time (epoch seconds; 0 if unknown)
    Uptime: QWord;               // System uptime in seconds (0 if unknown)
  end;

  // Result type aliases for new structures
  TCPUInfoResult = specialize TResult<TCPUInfo, TOSError>;
  TMemoryInfoResult = specialize TResult<TMemoryInfo, TOSError>;
  TStorageInfoArrayResult = specialize TResult<TStorageInfoArray, TOSError>;
  TNetworkInterfaceArrayResult = specialize TResult<TNetworkInterfaceArray, TOSError>;
  TSystemLoadResult = specialize TResult<TSystemLoad, TOSError>;
  TSystemInfoResult = specialize TResult<TSystemInfo, TOSError>;

// Error handling utilities
function OSErrorToString(Error: TOSError): string;
function SystemErrorToOSError(SystemCode: Integer): TOSError;

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

  // Result-based env APIs (partial re-enable)
  function os_getenv_result(const AName: string): TOSStringResult;
  function os_lookupenv_result(const AName: string): TOSStringResult;
  function os_setenv_result(const AName, AValue: string): TOSBoolResult;
  function os_unsetenv_result(const AName: string): TOSBoolResult;
  function os_hostname_result: TOSStringResult;
  function os_username_result: TOSStringResult;
  function os_home_dir_result: TOSStringResult;
  function os_temp_dir_result: TOSStringResult;
  function os_exe_path_result: TOSStringResult;
  function os_exe_dir_result: TOSStringResult;
  function os_kernel_version_result: TOSStringResult;
  function os_timezone_result: TOSStringResult;
  function os_timezone_iana_result: TOSStringResult;
  function os_cpu_model_result: TOSStringResult;
  function os_locale_current_result: TOSStringResult;
// Result-based system information APIs
function os_cpu_info: TCPUInfoResult;
function os_memory_info_detailed: TMemoryInfoResult;
function os_storage_info: TStorageInfoArrayResult;
function os_network_interfaces: TNetworkInterfaceArrayResult;
function os_system_load: TSystemLoadResult;
function os_system_info: TSystemInfoResult;


// Capability probes (best-effort)
function os_is_admin: Boolean;
function os_is_wsl: Boolean;
function os_is_container: Boolean;
function os_is_ci: Boolean;

function os_platform_info: TPlatformInfo;

// TODO: Re-enable Result-based APIs when fafafa.core.result compatibility is fixed
(*
// Error handling utilities
function OSErrorToString(Error: TOSError): string;
function SystemErrorToOSError(SystemCode: Integer): TOSError;

// New Result-based APIs (统一错误处理版本)
function os_getenv_result(const AName: string): TOSStringResult;
function os_lookupenv_result(const AName: string): TOSStringResult;
function os_setenv_result(const AName, AValue: string): TOSBoolResult;
function os_unsetenv_result(const AName: string): TOSBoolResult;

function os_hostname_result: TOSStringResult;
function os_username_result: TOSStringResult;
function os_home_dir_result: TOSStringResult;
function os_temp_dir_result: TOSStringResult;
function os_exe_path_result: TOSStringResult;
function os_exe_dir_result: TOSStringResult;

function os_kernel_version_result: TOSStringResult;
function os_timezone_result: TOSStringResult;
function os_timezone_iana_result: TOSStringResult;
function os_cpu_model_result: TOSStringResult;
function os_locale_current_result: TOSStringResult;

// New enhanced system information APIs
function os_cpu_info: TCPUInfoResult;
function os_memory_info_detailed: TMemoryInfoResult;
function os_storage_info: TStorageInfoArrayResult;
function os_network_interfaces: TNetworkInterfaceArrayResult;
function os_system_load: TSystemLoadResult;
function os_system_info: TSystemInfoResult;
*)

// Enhanced system information APIs (basic versions without Result)
function os_cpu_info_ex(out Info: TCPUInfo): Boolean;
function os_memory_info_ex(out Info: TMemoryInfo): Boolean;
function os_storage_info_ex(out Info: TStorageInfoArray): Boolean;
function os_network_interfaces_ex(out Info: TNetworkInterfaceArray): Boolean;
function os_system_load_ex(out Info: TSystemLoad): Boolean;
function os_system_info_ex(out Info: TSystemInfo): Boolean;

implementation

uses
  {$IFDEF WINDOWS} Windows {$ELSE} BaseUnix, Unix {$ENDIF}, DateUtils, fafafa.core.math, StrUtils, ctypes, Sockets;

{$IFDEF UNIX}
type
  PStatVFS = ^TStatVFS;
  TStatVFS = record
    f_bsize: culong;
    f_frsize: culong;
    f_blocks: culong;
    f_bfree: culong;
    f_bavail: culong;
    f_files: culong;
    f_ffree: culong;
    f_favail: culong;
    f_fsid: culong;
    f_flag: culong;
    f_namemax: culong;
  end;

function statvfs(path: PChar; buf: PStatVFS): cint; cdecl; external 'c' name 'statvfs';
{$ENDIF}

{$IFDEF UNIX}
type
  PIfAddrs = ^TIfAddrs;
  TIfAddrs = record
    ifa_next: PIfAddrs;
    ifa_name: PChar;
    ifa_flags: cuint;
    ifa_addr: psockaddr;
    ifa_netmask: psockaddr;
    ifa_ifu: psockaddr;
    ifa_data: Pointer;
  end;

function getifaddrs(out ifap: PIfAddrs): cint; cdecl; external 'c' name 'getifaddrs';
procedure freeifaddrs(ifap: PIfAddrs); cdecl; external 'c' name 'freeifaddrs';
{$ENDIF}

{$IFDEF LINUX}
var
  g_cpu_usage_inited: Boolean = False;
  g_cpu_usage_last_idle: QWord = 0;
  g_cpu_usage_last_total: QWord = 0;
{$ENDIF}

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
    {$IFDEF DARWIN}
    sizeDarwin: Cardinal;
    tmp: string;
    {$ENDIF}
  {$ENDIF}
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

// Error handling utilities implementation
function OSErrorToString(Error: TOSError): string;
begin
  // Default first to avoid "unreachable code" warnings when the enum is fully covered.
  Result := 'Unknown error';
  case Error of
    oseSuccess: Result := 'Success';
    oseNotFound: Result := 'Not found';
    osePermissionDenied: Result := 'Permission denied';
    oseInvalidInput: Result := 'Invalid input';
    oseSystemError: Result := 'System error';
    oseTimeout: Result := 'Timeout';
    oseOutOfMemory: Result := 'Out of memory';
    oseNotSupported: Result := 'Not supported';
    oseAlreadyExists: Result := 'Already exists';
    oseInterrupted: Result := 'Interrupted';
    oseInvalidData: Result := 'Invalid data';
    oseUnexpectedEof: Result := 'Unexpected end of file';
    oseResourceBusy: Result := 'Resource busy';
    oseNetworkError: Result := 'Network error';
    oseOther: Result := 'Other error';
  end;
end;

function SystemErrorToOSError(SystemCode: Integer): TOSError;
begin
  {$IFDEF WINDOWS}
  case SystemCode of
    0: Result := oseSuccess;
    2, 3: Result := oseNotFound;           // ERROR_FILE_NOT_FOUND, ERROR_PATH_NOT_FOUND
    5: Result := osePermissionDenied;      // ERROR_ACCESS_DENIED
    8: Result := oseOutOfMemory;           // ERROR_NOT_ENOUGH_MEMORY
    87: Result := oseInvalidInput;         // ERROR_INVALID_PARAMETER
    183: Result := oseAlreadyExists;       // ERROR_ALREADY_EXISTS
    1223: Result := osePermissionDenied;   // ERROR_CANCELLED (user cancelled UAC)
  else
    Result := oseSystemError;
  end;
  {$ELSE}
  case SystemCode of
    0: Result := oseSuccess;
    ESysEPERM: Result := osePermissionDenied;
    ESysENOENT: Result := oseNotFound;
    ESysEINTR: Result := oseInterrupted;
    ESysENOMEM: Result := oseOutOfMemory;
    ESysEACCES: Result := osePermissionDenied;
    ESysEEXIST: Result := oseAlreadyExists;
    ESysEINVAL: Result := oseInvalidInput;
    ESysEBUSY: Result := oseResourceBusy;
    ESysETIMEDOUT: Result := oseTimeout;
  else
    Result := oseSystemError;
  end;
  {$ENDIF}
end;

// Result-based env APIs implementation (partial)
function os_getenv_result(const AName: string): TOSStringResult;
var
  Value: string;
begin
  try
    Value := os_getenv(AName);
    // 注意：os_getenv 返回空字符串可能表示变量不存在或值为空
    // 我们需要用 os_lookupenv 来区分
    if os_lookupenv(AName, Value) then
      Result := TOSStringResult.Ok(Value)
    else
      Result := TOSStringResult.Err(oseNotFound);
  except
    on E: Exception do
      Result := TOSStringResult.Err(oseSystemError);
  end;
end;

function os_lookupenv_result(const AName: string): TOSStringResult;
var
  Value: string;
begin
  try
    if os_lookupenv(AName, Value) then
      Result := TOSStringResult.Ok(Value)
    else
      Result := TOSStringResult.Err(oseNotFound);
  except
    on E: Exception do
      Result := TOSStringResult.Err(oseSystemError);
  end;
end;

function os_setenv_result(const AName, AValue: string): TOSBoolResult;
begin
  try
    if os_setenv(AName, AValue) then
      Result := TOSBoolResult.Ok(True)
    else
      Result := TOSBoolResult.Err(oseSystemError);
  except
    on E: Exception do
      Result := TOSBoolResult.Err(oseSystemError);
  end;
end;

function os_unsetenv_result(const AName: string): TOSBoolResult;
begin
  try
    if os_unsetenv(AName) then
      Result := TOSBoolResult.Ok(True)
    else
      Result := TOSBoolResult.Err(oseSystemError);
  except
    on E: Exception do
      Result := TOSBoolResult.Err(oseSystemError);
  end;
end;
function os_hostname_result: TOSStringResult;
begin
  Result := TOSStringResult.Ok(os_hostname);
  if Result.Unwrap = '' then
    Result := TOSStringResult.Err(oseNotFound);
end;

function os_username_result: TOSStringResult;
begin
  Result := TOSStringResult.Ok(os_username);
  if Result.Unwrap = '' then
    Result := TOSStringResult.Err(oseNotFound);
end;

function os_home_dir_result: TOSStringResult;
begin
  Result := TOSStringResult.Ok(os_home_dir);
  if Result.Unwrap = '' then
    Result := TOSStringResult.Err(oseNotFound);
end;

function os_temp_dir_result: TOSStringResult;
begin
  Result := TOSStringResult.Ok(os_temp_dir);
  if Result.Unwrap = '' then
    Result := TOSStringResult.Err(oseNotFound);
end;

function os_exe_path_result: TOSStringResult;
begin
  Result := TOSStringResult.Ok(os_exe_path);
  if Result.Unwrap = '' then
    Result := TOSStringResult.Err(oseNotFound);
end;

function os_exe_dir_result: TOSStringResult;
begin
  Result := TOSStringResult.Ok(os_exe_dir);
  if Result.Unwrap = '' then
    Result := TOSStringResult.Err(oseNotFound);
end;

function os_kernel_version_result: TOSStringResult;
begin
  Result := TOSStringResult.Ok(os_kernel_version);
  if Result.Unwrap = '' then
    Result := TOSStringResult.Err(oseNotFound);
end;

function os_timezone_result: TOSStringResult;
begin
  Result := TOSStringResult.Ok(os_timezone);
  // timezone may be empty; treat empty as success
end;

function os_timezone_iana_result: TOSStringResult;
begin
  Result := TOSStringResult.Ok(os_timezone_iana);
end;

function os_cpu_model_result: TOSStringResult;
begin
  Result := TOSStringResult.Ok(os_cpu_model);
  if Result.Unwrap = '' then
    Result := TOSStringResult.Err(oseNotFound);
end;

function os_locale_current_result: TOSStringResult;
begin
  Result := TOSStringResult.Ok(os_locale_current);
  // locale may be empty depending on environment; keep success
end;
function os_cpu_info: TCPUInfoResult;
var info: TCPUInfo;
begin
  if os_cpu_info_ex(info) then
    Result := TCPUInfoResult.Ok(info)
  else
    Result := TCPUInfoResult.Err(oseSystemError);
end;

function os_memory_info_detailed: TMemoryInfoResult;
var info: TMemoryInfo;
begin
  if os_memory_info_ex(info) then
    Result := TMemoryInfoResult.Ok(info)
  else
    {$IFDEF LINUX}
    Result := TMemoryInfoResult.Err(oseSystemError);
    {$ELSE}
    Result := TMemoryInfoResult.Err(oseNotSupported);
    {$ENDIF}
end;

function os_storage_info: TStorageInfoArrayResult;
var info: TStorageInfoArray;
begin
  if os_storage_info_ex(info) then
    Result := TStorageInfoArrayResult.Ok(info)
  else
    {$IFDEF LINUX}
    Result := TStorageInfoArrayResult.Err(oseSystemError);
    {$ELSE}
    Result := TStorageInfoArrayResult.Err(oseNotSupported);
    {$ENDIF}
end;

function os_network_interfaces: TNetworkInterfaceArrayResult;
var info: TNetworkInterfaceArray;
begin
  if os_network_interfaces_ex(info) then
    Result := TNetworkInterfaceArrayResult.Ok(info)
  else
    {$IFDEF LINUX}
    Result := TNetworkInterfaceArrayResult.Err(oseSystemError);
    {$ELSE}
    Result := TNetworkInterfaceArrayResult.Err(oseNotSupported);
    {$ENDIF}
end;

function os_system_load: TSystemLoadResult;
var info: TSystemLoad;
begin
  if os_system_load_ex(info) then
    Result := TSystemLoadResult.Ok(info)
  else
    {$IFDEF LINUX}
    Result := TSystemLoadResult.Err(oseSystemError);
    {$ELSE}
    Result := TSystemLoadResult.Err(oseNotSupported);
    {$ENDIF}
end;

function os_system_info: TSystemInfoResult;
var info: TSystemInfo;
begin
  if os_system_info_ex(info) then
    Result := TSystemInfoResult.Ok(info)
  else
    Result := TSystemInfoResult.Err(oseSystemError);
end;

// TODO: Re-enable Result-based implementations when fafafa.core.result compatibility is fixed
(*
function SystemErrorToOSError(SystemCode: Integer): TOSError;
begin
  case SystemCode of
    0: Result := oseSuccess;
    2, 3: Result := oseNotFound;        // File not found, Path not found
    5: Result := osePermissionDenied;   // Access denied
    8: Result := oseOutOfMemory;        // Not enough memory
    32: Result := oseResourceBusy;      // Sharing violation
    else Result := oseSystemError;
  end;
end;

// New Result-based APIs implementation
function os_getenv_result(const AName: string): TOSStringResult;
var
  Value: string;
begin
  try
    Value := os_getenv(AName);
    // 注意：os_getenv 返回空字符串可能表示变量不存在或值为空
    // 我们需要用 os_lookupenv 来区分
    if os_lookupenv(AName, Value) then
      Result := TOSStringResult.Ok(Value)
    else
      Result := TOSStringResult.Err(oseNotFound);
  except
    on E: Exception do
      Result := TOSStringResult.Err(oseSystemError);
  end;
end;

function os_lookupenv_result(const AName: string): TOSStringResult;
var
  Value: string;
begin
  try
    if os_lookupenv(AName, Value) then
      Result := TOSStringResult.Ok(Value)
    else
      Result := TOSStringResult.Err(oseNotFound);
  except
    on E: Exception do
      Result := TOSStringResult.Err(oseSystemError);
  end;
end;

function os_setenv_result(const AName, AValue: string): TOSBoolResult;
begin
  try
    if os_setenv(AName, AValue) then
      Result := TOSBoolResult.Ok(True)
    else
      Result := TOSBoolResult.Err(oseSystemError);
  except
    on E: Exception do
      Result := TOSBoolResult.Err(oseSystemError);
  end;
end;

function os_unsetenv_result(const AName: string): TOSBoolResult;
begin
  try
    if os_unsetenv(AName) then
      Result := TOSBoolResult.Ok(True)
    else
      Result := TOSBoolResult.Err(oseSystemError);
  except
    on E: Exception do
      Result := TOSBoolResult.Err(oseSystemError);
  end;
end;
*)

// Enhanced system information APIs implementation (basic versions without Result)

function os_cpu_info_ex(out Info: TCPUInfo): Boolean;
var
  idle2, total2: QWord;
  function ReadCpuTimes(out idle, total: QWord): Boolean;
  var
    f: Text;
    line, tok: string;
    i: Integer;
    val: Int64;
  begin
    idle := 0; total := 0; Result := False;
    Assign(f, '/proc/stat'); {$I-} Reset(f); {$I+}
    if IOResult <> 0 then Exit;
    try
      ReadLn(f, line);
    finally
      Close(f);
    end;
    if Pos('cpu ', line) <> 1 then Exit;
    Delete(line, 1, 3);
    line := Trim(line);
    for i := 1 to 10 do
    begin
      tok := ExtractWord(i, line, [' ']);
      if tok = '' then break;
      val := StrToInt64Def(tok, 0);
      total := total + QWord(val);
      if (i = 4) or (i = 5) then // idle + iowait
        idle := idle + QWord(val);
    end;
    Result := total > 0;
  end;

  procedure ReadProcCpuInfo;
  var
    f: Text;
    line, key, valueStr: string;
    p: Integer;
    vendorId, featuresStr, mhzStr: string;
    mhz: Double;
    code: Integer;
    i: Integer;
    tok: string;
  begin
    vendorId := '';
    featuresStr := '';
    mhzStr := '';

    Assign(f, '/proc/cpuinfo');
    {$I-} Reset(f); {$I+}
    if IOResult <> 0 then Exit;
    try
      while not EOF(f) do
      begin
        ReadLn(f, line);
        p := Pos(':', line);
        if p <= 0 then Continue;
        key := Trim(Copy(line, 1, p-1));
        valueStr := Trim(Copy(line, p+1, MaxInt));

        if (vendorId = '') and SameText(key, 'vendor_id') then
          vendorId := valueStr
        else if (featuresStr = '') and (SameText(key, 'flags') or SameText(key, 'Features')) then
          featuresStr := valueStr
        else if (mhzStr = '') and SameText(key, 'cpu MHz') then
          mhzStr := valueStr;

        if (vendorId <> '') and (featuresStr <> '') and (mhzStr <> '') then Break;
      end;
    finally
      Close(f);
    end;

    // Vendor mapping (best-effort)
    if vendorId <> '' then
    begin
      if SameText(vendorId, 'GenuineIntel') then
        Info.Vendor := 'Intel'
      else if SameText(vendorId, 'AuthenticAMD') then
        Info.Vendor := 'AMD'
      else
        Info.Vendor := vendorId;
    end;

    // Frequency (Hz) from "cpu MHz" (best-effort)
    if mhzStr <> '' then
    begin
      mhz := 0;
      Val(mhzStr, mhz, code);
      if (code = 0) and (mhz > 0) then
        Info.Frequency := QWord(Trunc(mhz * 1000000.0));
    end;

    // Feature flags
    if featuresStr <> '' then
    begin
      SetLength(Info.Features, 0);
      i := 1;
      while True do
      begin
        tok := ExtractWord(i, featuresStr, [' ', #9]);
        if tok = '' then Break;
        SetLength(Info.Features, Length(Info.Features) + 1);
        Info.Features[High(Info.Features)] := tok;
        Inc(i);
      end;
    end;
  end;
begin
  try
    // Initialize with default values
    Info := Default(TCPUInfo);
    Info.Usage := -1; // Unknown

    // Get basic CPU information from existing APIs
    Info.Model := os_cpu_model;
    Info.Cores := os_cpu_count;
    Info.Threads := os_cpu_count; // Assume no hyperthreading for now
    Info.Architecture := os_platform_info.Architecture;

    // Extract vendor from model string (basic heuristic)
    if Pos('Intel', Info.Model) > 0 then
      Info.Vendor := 'Intel'
    else if Pos('AMD', Info.Model) > 0 then
      Info.Vendor := 'AMD'
    else if Pos('Apple', Info.Model) > 0 then
      Info.Vendor := 'Apple'
    else if Pos('ARM', Info.Model) > 0 then
      Info.Vendor := 'ARM'
    else
      Info.Vendor := 'Unknown';

    // Best-effort: enrich vendor/features/frequency via /proc/cpuinfo (Linux)
    {$IFDEF LINUX}
    ReadProcCpuInfo;
    {$ENDIF}

    // TODO: Implement cache size detection

    // CPU usage monitoring
    // - Linux: non-blocking cached delta via /proc/stat.
    // - Other platforms: keep Usage = -1 (unknown) unless a native implementation exists.
    if ReadCpuTimes(idle2, total2) then
    begin
      {$IFDEF LINUX}
      if g_cpu_usage_inited and (total2 > g_cpu_usage_last_total) then
      begin
        Info.Usage := 1.0 - (idle2 - g_cpu_usage_last_idle) / (total2 - g_cpu_usage_last_total);
        if Info.Usage < 0 then Info.Usage := 0;
        if Info.Usage > 1 then Info.Usage := 1;
      end;
      g_cpu_usage_last_idle := idle2;
      g_cpu_usage_last_total := total2;
      g_cpu_usage_inited := True;
      {$ENDIF}
    end;

    Result := True;
  except
    Info := Default(TCPUInfo);
    Result := False;
  end;
end;

function os_memory_info_ex(out Info: TMemoryInfo): Boolean;
{$IFDEF LINUX}
var
  f: Text;
  s, key, num: string;
  p, p2, code: Integer;
  v: QWord;
  memTotal, memAvail, memFree, memCached, memBuffers: QWord;
  swapTotal, swapFree: QWord;
  totalBytes, freeBytes, availBytes: QWord;
begin
  Info := Default(TMemoryInfo);
  Info.Pressure := -1; // Unknown

  memTotal := 0; memAvail := 0; memFree := 0; memCached := 0; memBuffers := 0;
  swapTotal := 0; swapFree := 0;
  totalBytes := 0; freeBytes := 0; availBytes := 0;

  try
    // Preferred: parse /proc/meminfo for detailed fields.
    Assign(f, '/proc/meminfo');
    {$I-} Reset(f); {$I+}
    if IOResult = 0 then
    begin
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
          // Values are reported in kB.
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
    end;

    if memTotal > 0 then
    begin
      Info.Total := memTotal;

      if memAvail > 0 then
        availBytes := memAvail
      else
      begin
        // Fallback approximation: free + buffers + cached.
        availBytes := memFree;
        if memBuffers > 0 then availBytes := availBytes + memBuffers;
        if memCached > 0 then availBytes := availBytes + memCached;
        if availBytes > memTotal then availBytes := memTotal;
      end;

      Info.Available := availBytes;
      Info.Free := memFree;
      Info.Cached := memCached;
      Info.Buffers := memBuffers;

      if Info.Available <= Info.Total then
        Info.Used := Info.Total - Info.Available
      else
        Info.Used := 0;

      Info.Swap.Total := swapTotal;
      if swapFree <= swapTotal then
        Info.Swap.Available := swapFree
      else
        Info.Swap.Available := swapTotal;
      Info.Swap.Used := Info.Swap.Total - Info.Swap.Available;

      if (Info.Total > 0) and (Info.Available <= Info.Total) then
        Info.Pressure := Info.Used / Info.Total;

      Exit(True);
    end;

    // Fallback: use existing best-effort API.
    if os_memory_info(totalBytes, freeBytes) then
    begin
      Info.Total := totalBytes;
      Info.Available := freeBytes;
      Info.Used := totalBytes - freeBytes;
      Info.Free := freeBytes;
      if (Info.Total > 0) and (Info.Available <= Info.Total) then
        Info.Pressure := Info.Used / Info.Total;
      Result := True;
    end
    else
    begin
      Info := Default(TMemoryInfo);
      Result := False;
    end;
  except
    Info := Default(TMemoryInfo);
    Result := False;
  end;
end;
{$ELSE}
var
  totalBytes, freeBytes: QWord;
begin
  Info := Default(TMemoryInfo);
  Result := False; // advanced memory probe unsupported on non-Linux platforms
end;
{$ENDIF}

function os_storage_info_ex(out Info: TStorageInfoArray): Boolean;
{$IFDEF LINUX}
var
  total, free: Int64;
  f: Text;
  line, mnt, fs, opts: string;
  p1, p2, p3: Integer;
  statv: TStatVFS;
  idx: Integer;
  procedure AddEntry;
  var
    tmpInfo: TStorageInfo;
  begin
    if statvfs(PChar(mnt), @statv) = 0 then
    begin
      total := Int64(statv.f_blocks) * statv.f_frsize;
      free := Int64(statv.f_bavail) * statv.f_frsize;
    end
    else
    begin
      total := -1; free := -1;
    end;
    if (total <= 0) then Exit; // skip pseudo/zero mounts
    SetLength(Info, Length(Info)+1);
    idx := High(Info);
    Info[idx] := Default(TStorageInfo);
    Info[idx].Path := mnt;
    Info[idx].FileSystem := fs;
    if total >= 0 then Info[idx].Total := QWord(total);
    if free >= 0 then Info[idx].Available := QWord(free);
    if (total >= 0) and (free >= 0) and (total >= free) then
      Info[idx].Used := QWord(total - free);
    Info[idx].IsRemovable := (Pos('/media/', mnt) = 1) or (Pos('/run/media/', mnt) = 1);
    // NOTE: only explicit ",ro," token indicates read-only; avoid false positives like "errors=remount-ro".
    Info[idx].IsReadOnly := (Pos(',ro,', ','+opts+',') > 0);
    if (mnt = '/') and (idx > 0) then
    begin
      tmpInfo := Info[0];
      Info[0] := Info[idx];
      Info[idx] := tmpInfo;
    end;
  end;
begin
  Info := nil;
  try
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
          fs := Copy(line, 1, p3-1);
          Delete(line, 1, p3);
          p3 := Pos(' ', line);
          if p3 = 0 then opts := line else opts := Copy(line, 1, p3-1);
          AddEntry;
        end;
      finally
        Close(f);
      end;
    end;
    if Length(Info)=0 then
    begin
      // fallback single root using DiskSize/DiskFree
      total := DiskSize(0); free := DiskFree(0);
      SetLength(Info,1);
      Info[0].Path := '/';
      Info[0].FileSystem := '';
      if total >= 0 then Info[0].Total := QWord(total);
      if free >= 0 then Info[0].Available := QWord(free);
      if (total >= 0) and (free >= 0) and (total>=free) then
        Info[0].Used := QWord(total-free);
    end;
    Result := Length(Info) > 0;
  except
    SetLength(Info, 1);
    Info[0] := Default(TStorageInfo);
    Info[0].Path := '/';
    Info[0].FileSystem := '';
    Info[0].Total := 0;
    Info[0].Available := 0;
    Info[0].Used := 0;
    Info[0].IsRemovable := False;
    Info[0].IsReadOnly := False;
    Result := False;
  end;
end;
{$ELSE}
begin
  Info := nil;
  Result := False; // storage enumeration not implemented on this platform
end;
{$ENDIF}

function os_network_interfaces_ex(out Info: TNetworkInterfaceArray): Boolean;
{$IFDEF LINUX}
var
  sr: TSearchRec;
  basePath, p: string;
  idx: Integer;
  tmp64: Int64;
  {$IFDEF UNIX}
  ifap, ifa: PIfAddrs;
  ifName: string;
  ipStr: AnsiString;
  {$ENDIF}
  function ReadFirstLine(const filePath: string; out val: string): Boolean;
  var
    f: Text;
  begin
    Result := False;
    val := '';
    if not FileExists(filePath) then Exit;

    Assign(f, filePath);
    {$I-} Reset(f); {$I+}
    if IOResult <> 0 then Exit;

    try
      // Some sysfs files may raise EInOutError on read (e.g. /sys/class/net/lo/speed).
      {$I-} ReadLn(f, val); {$I+}
      if IOResult <> 0 then
      begin
        val := '';
        Exit(False);
      end;
      Result := True;
    finally
      Close(f);
    end;
  end;
  function ReadInt64File(const filePath: string; out v: Int64): Boolean;
  var s: string;
  begin
    if ReadFirstLine(filePath, s) then
    begin
      v := StrToInt64Def(Trim(s), 0);
      Exit(True);
    end;
    v := 0;
    Result := False;
  end;
  procedure AddIPForName(const aName, aIP: string);
  var
    i, j: Integer;
  begin
    if (aName = '') or (aIP = '') then Exit;
    for i := 0 to High(Info) do
      if Info[i].Name = aName then
      begin
        for j := 0 to High(Info[i].IPAddresses) do
          if Info[i].IPAddresses[j] = aIP then
            Exit; // dedupe
        SetLength(Info[i].IPAddresses, Length(Info[i].IPAddresses) + 1);
        Info[i].IPAddresses[High(Info[i].IPAddresses)] := aIP;
        Exit;
      end;
  end;
begin
  Info := nil;
  try
    basePath := '/sys/class/net';
    if FindFirst(basePath + '/*', faAnyFile, sr) = 0 then
    begin
      repeat
        if (sr.Name = '.') or (sr.Name = '..') then Continue;
        SetLength(Info, Length(Info) + 1);
        idx := High(Info);
        Info[idx] := Default(TNetworkInterface);
        Info[idx].Name := sr.Name;
        Info[idx].DisplayName := sr.Name;
        // MAC address
        ReadFirstLine(basePath + '/' + sr.Name + '/address', Info[idx].HardwareAddress);
        // MTU
        if ReadInt64File(basePath + '/' + sr.Name + '/mtu', tmp64) then
          Info[idx].MTU := tmp64
        else
          Info[idx].MTU := 0;
        // Speed (Mbps) -> bps
        if ReadInt64File(basePath + '/' + sr.Name + '/speed', tmp64) then
          Info[idx].Speed := QWord(tmp64 * 1000000)
        else
          Info[idx].Speed := 0;
        // Flags
        ReadFirstLine(basePath + '/' + sr.Name + '/operstate', p);
        Info[idx].IsUp := SameText(Trim(p), 'up');
        Info[idx].IsLoopback := (sr.Name = 'lo');
        Info[idx].IsWireless := DirectoryExists(basePath + '/' + sr.Name + '/wireless');
        // Counters
        if ReadInt64File(basePath + '/' + sr.Name + '/statistics/tx_bytes', tmp64) then
          Info[idx].BytesSent := QWord(tmp64)
        else
          Info[idx].BytesSent := 0;
        if ReadInt64File(basePath + '/' + sr.Name + '/statistics/rx_bytes', tmp64) then
          Info[idx].BytesReceived := QWord(tmp64)
        else
          Info[idx].BytesReceived := 0;
      until FindNext(sr) <> 0;
      FindClose(sr);
    end;

    {$IFDEF UNIX}
    // Fill IP addresses using getifaddrs (supports IPv4/IPv6).
    ifap := nil;
    if getifaddrs(ifap) = 0 then
    begin
      try
        ifa := ifap;
        while Assigned(ifa) do
        begin
          if (ifa^.ifa_name <> nil) and (ifa^.ifa_addr <> nil) then
          begin
            ifName := StrPas(ifa^.ifa_name);
            case ifa^.ifa_addr^.sa_family of
              AF_INET:
                ipStr := NetAddrToStr(psockaddr_in(ifa^.ifa_addr)^.sin_addr);
              AF_INET6:
                ipStr := NetAddrToStr6(psockaddr_in6(ifa^.ifa_addr)^.sin6_addr);
            else
              ipStr := '';
            end;
            if ipStr <> '' then
              AddIPForName(ifName, string(ipStr));
          end;
          ifa := ifa^.ifa_next;
        end;
      finally
        freeifaddrs(ifap);
      end;
    end;
    {$ENDIF}

    // Ensure loopback always has the canonical addresses (best-effort).
    AddIPForName('lo', '127.0.0.1');
    AddIPForName('lo', '::1');

    if Length(Info) = 0 then
    begin
      SetLength(Info, 1);
      Info[0] := Default(TNetworkInterface);
      Info[0].Name := 'lo';
      Info[0].DisplayName := 'lo';
      Info[0].HardwareAddress := '00:00:00:00:00:00';
      Info[0].IsLoopback := True;
      Info[0].IsUp := True;
      SetLength(Info[0].IPAddresses, 2);
      Info[0].IPAddresses[0] := '127.0.0.1';
      Info[0].IPAddresses[1] := '::1';
    end;
    Result := Length(Info) > 0;
  except
    SetLength(Info, 1);
    Info[0] := Default(TNetworkInterface);
    Info[0].Name := 'lo';
    Info[0].DisplayName := 'lo';
    Info[0].HardwareAddress := '00:00:00:00:00:00';
    Info[0].IsLoopback := True;
    Info[0].IsUp := True;
    SetLength(Info[0].IPAddresses, 2);
    Info[0].IPAddresses[0] := '127.0.0.1';
    Info[0].IPAddresses[1] := '::1';
    Result := True;
  end;
end;
{$ELSE}
begin
  Info := nil;
  Result := False; // network interface enumeration not implemented on this platform
end;
{$ENDIF}

function os_system_load_ex(out Info: TSystemLoad): Boolean;
{$IFDEF LINUX}
var
  f: Text;
  s, tok: string;
  load1, load5, load15: Double;
  slashPos: Integer;
begin
  try
    Info := Default(TSystemLoad);
    Info.Load1Min := -1;
    Info.Load5Min := -1;
    Info.Load15Min := -1;
    Info.RunningProcesses := -1;
    Info.TotalProcesses := -1;

    Assign(f, '/proc/loadavg');
    {$I-} Reset(f); {$I+}
    if IOResult = 0 then
    begin
      try
        ReadLn(f, s);
      finally
        Close(f);
      end;
      // Parse first three floats
      tok := Trim(s);
      load1 := StrToFloatDef(ExtractWord(1, tok, [' ']), -1);
      load5 := StrToFloatDef(ExtractWord(2, tok, [' ']), -1);
      load15 := StrToFloatDef(ExtractWord(3, tok, [' ']), -1);
      Info.Load1Min := load1;
      Info.Load5Min := load5;
      Info.Load15Min := load15;
      // Fourth field running/total
      tok := ExtractWord(4, tok, [' ']);
      slashPos := Pos('/', tok);
      if slashPos > 0 then
      begin
        Info.RunningProcesses := StrToIntDef(Copy(tok, 1, slashPos-1), -1);
        Info.TotalProcesses := StrToIntDef(Copy(tok, slashPos+1, MaxInt), -1);
      end;
      Result := Info.Load1Min >= 0;
    end
    else
      Result := False;
  except
    Info := Default(TSystemLoad);
    Result := False;
  end;
end;
{$ELSE}
begin
  Info := Default(TSystemLoad);
  Result := False; // load averages not implemented on this platform
end;
{$ENDIF}

function os_system_info_ex(out Info: TSystemInfo): Boolean;
begin
  try
    // Initialize with default values
    Info := Default(TSystemInfo);

    // Get platform information
    Info.Platform := os_platform_info;

    // Get detailed OS version
    Info.OSVersion := os_os_version_detailed;

    // Get boot time and uptime
    Info.BootTime := os_boot_time;
    Info.Uptime := os_uptime;

    // Get enhanced information
    os_cpu_info_ex(Info.CPU);
    os_memory_info_ex(Info.Memory);
    os_storage_info_ex(Info.Storage);
    os_network_interfaces_ex(Info.Network);
    os_system_load_ex(Info.Load);

    Result := True;
  except
    Info := Default(TSystemInfo);
    Result := False;
  end;
end;

{$IFDEF FAFAFA_OS_CACHE_PROBES}
initialization
  {$IFDEF WINDOWS}
  if not g_cache_cs_inited then
  begin
    InitCriticalSection(g_cache_cs);
    g_cache_cs_inited := True;
  end;
  {$ELSE}
  if not g_unix_cache_cs_inited then
  begin
    InitCriticalSection(g_unix_cache_cs);
    g_unix_cache_cs_inited := True;
  end;
  {$ENDIF}

finalization
  {$IFDEF WINDOWS}
  if g_cache_cs_inited then
  begin
    DoneCriticalSection(g_cache_cs);
    g_cache_cs_inited := False;
  end;
  {$ELSE}
  if g_unix_cache_cs_inited then
  begin
    DoneCriticalSection(g_unix_cache_cs);
    g_unix_cache_cs_inited := False;
  end;
  {$ENDIF}
{$ENDIF}

end.
