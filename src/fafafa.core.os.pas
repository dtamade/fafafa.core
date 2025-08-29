unit fafafa.core.os;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes;
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

  // TODO: Re-enable Result types when fafafa.core.result compatibility is fixed
  (*
  // Result type aliases for common OS operations
  TOSStringResult = specialize TResult<string, TOSError>;
  TOSBoolResult = specialize TResult<Boolean, TOSError>;
  TOSIntResult = specialize TResult<Integer, TOSError>;
  TOSQWordResult = specialize TResult<QWord, TOSError>;
  *)

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
    BootTime: TDateTime;         // System boot time (0 if unknown)
    Uptime: QWord;               // System uptime in seconds (0 if unknown)
  end;

  // TODO: Re-enable Result types when fafafa.core.result compatibility is fixed
  (*
  // Result type aliases for new structures
  TCPUInfoResult = specialize TResult<TCPUInfo, TOSError>;
  TMemoryInfoResult = specialize TResult<TMemoryInfo, TOSError>;
  TStorageInfoArrayResult = specialize TResult<TStorageInfoArray, TOSError>;
  TNetworkInterfaceArrayResult = specialize TResult<TNetworkInterfaceArray, TOSError>;
  TSystemLoadResult = specialize TResult<TSystemLoad, TOSError>;
  TSystemInfoResult = specialize TResult<TSystemInfo, TOSError>;
  *)

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

// Error handling utilities implementation
function OSErrorToString(Error: TOSError): string;
begin
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
  else
    Result := 'Unknown error';
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
    1: Result := osePermissionDenied;      // EPERM
    2: Result := oseNotFound;              // ENOENT
    4: Result := oseInterrupted;           // EINTR
    12: Result := oseOutOfMemory;          // ENOMEM
    13: Result := osePermissionDenied;     // EACCES
    17: Result := oseAlreadyExists;        // EEXIST
    22: Result := oseInvalidInput;         // EINVAL
    16: Result := oseResourceBusy;         // EBUSY
    110: Result := oseTimeout;             // ETIMEDOUT
  else
    Result := oseSystemError;
  end;
  {$ENDIF}
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
begin
  try
    // Initialize with default values
    FillChar(Info, SizeOf(Info), 0);
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

    // TODO: Implement platform-specific CPU feature detection
    // TODO: Implement CPU frequency detection
    // TODO: Implement cache size detection
    // TODO: Implement CPU usage monitoring

    Result := True;
  except
    FillChar(Info, SizeOf(Info), 0);
    Result := False;
  end;
end;

function os_memory_info_ex(out Info: TMemoryInfo): Boolean;
var
  totalBytes, freeBytes: QWord;
begin
  try
    // Initialize with default values
    FillChar(Info, SizeOf(Info), 0);
    Info.Pressure := -1; // Unknown

    // Get basic memory information from existing API
    if os_memory_info(totalBytes, freeBytes) then
    begin
      Info.Total := totalBytes;
      Info.Available := freeBytes;
      Info.Used := totalBytes - freeBytes;
      Info.Free := freeBytes;

      // TODO: Implement platform-specific detailed memory information
      // TODO: Get cached, buffers, swap information
      // TODO: Calculate memory pressure

      Result := True;
    end
    else
    begin
      FillChar(Info, SizeOf(Info), 0);
      Result := False;
    end;
  except
    FillChar(Info, SizeOf(Info), 0);
    Result := False;
  end;
end;

function os_storage_info_ex(out Info: TStorageInfoArray): Boolean;
begin
  try
    // TODO: Implement platform-specific storage enumeration
    // For now, return empty array as placeholder
    SetLength(Info, 0);
    Result := True;
  except
    SetLength(Info, 0);
    Result := False;
  end;
end;

function os_network_interfaces_ex(out Info: TNetworkInterfaceArray): Boolean;
begin
  try
    // TODO: Implement platform-specific network interface enumeration
    // For now, return empty array as placeholder
    SetLength(Info, 0);
    Result := True;
  except
    SetLength(Info, 0);
    Result := False;
  end;
end;

function os_system_load_ex(out Info: TSystemLoad): Boolean;
begin
  try
    // Initialize with unknown values
    FillChar(Info, SizeOf(Info), 0);
    Info.Load1Min := -1;
    Info.Load5Min := -1;
    Info.Load15Min := -1;
    Info.RunningProcesses := -1;
    Info.TotalProcesses := -1;

    // TODO: Implement platform-specific system load information
    // Unix: read /proc/loadavg
    // Windows: use performance counters

    Result := True;
  except
    FillChar(Info, SizeOf(Info), 0);
    Result := False;
  end;
end;

function os_system_info_ex(out Info: TSystemInfo): Boolean;
begin
  try
    // Initialize with default values
    FillChar(Info, SizeOf(Info), 0);

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
    FillChar(Info, SizeOf(Info), 0);
    Result := False;
  end;
end;

end.
