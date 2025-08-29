{ Platform-specific implementations for Windows }


{$if not declared(CheckTokenMembership)}
function CheckTokenMembership(TokenHandle: HANDLE; SidToCheck: PSID; var IsMember: BOOL): BOOL; stdcall; external 'advapi32.dll' name 'CheckTokenMembership';
{$endif}

{$IFDEF FAFAFA_OS_CACHE_PROBES}
var
  g_cached_cpu_model_inited: Boolean = False;
  g_cached_cpu_model: string = '';
  g_cached_timezone_inited: Boolean = False;
  g_cached_timezone: string = '';
  g_cached_tz_iana_inited: Boolean = False;
  g_cached_tz_iana: string = '';
  g_cached_is_admin_inited: Boolean = False;
  g_cached_is_admin: Boolean = False;
  g_cached_kernel_ver_inited: Boolean = False;
  g_cached_kernel_ver: string = '';
  g_cached_osver_inited: Boolean = False;
  g_cached_osver: TOSVersionDetailed;
  g_cache_cs_inited: Boolean = False;
  g_cache_cs: TRTLCriticalSection;

procedure _cache_lock;
begin
  // 延迟初始化临界区，确保线程安全
  if not g_cache_cs_inited then
  begin
    InitCriticalSection(g_cache_cs);
    g_cache_cs_inited := True;
  end;
  EnterCriticalSection(g_cache_cs);
end;

procedure _cache_unlock;
begin
  // 安全释放临界区锁
  if g_cache_cs_inited then
    LeaveCriticalSection(g_cache_cs);
end;
{$ENDIF}

function os_getenv(const AName: string): string;
var
  Needed: DWORD;
  W: UnicodeString;
begin
  Result := '';
  Needed := GetEnvironmentVariableW(PWideChar(UnicodeString(AName)), nil, 0);
  if Needed > 0 then
  begin
    SetLength(W, Needed);
    Needed := GetEnvironmentVariableW(PWideChar(UnicodeString(AName)), PWideChar(W), Needed);
    if Needed > 0 then
    begin
      SetLength(W, Needed);
      Result := UTF8Encode(WideString(W));
    end;
  end;
end;

function os_setenv(const AName, AValue: string): Boolean;
begin
  Result := SetEnvironmentVariableW(PWideChar(UnicodeString(AName)), PWideChar(UnicodeString(AValue)));
end;

function os_unsetenv(const AName: string): Boolean;
begin
  Result := SetEnvironmentVariableW(PWideChar(UnicodeString(AName)), nil);
end;

procedure os_environ(const ADest: TStrings);
var
  P, PStart: PWideChar;
  S: UnicodeString;
  U: string;
begin
  if (ADest = nil) then Exit;
  ADest.Clear;
  PStart := GetEnvironmentStringsW();
  P := PStart;
  try
    if P <> nil then
    begin
      while (P^ <> #0) do
      begin
        S := P;
        if (Length(S) > 0) and (S[1] = '=') then
        begin
          Inc(P, Length(S) + 1);
          Continue; // skip pseudo variables like =C:=...
        end;
        U := UTF8Encode(WideString(S));
        ADest.Add(U);
        Inc(P, Length(S) + 1);
      end;
    end;
  finally
    if PStart <> nil then FreeEnvironmentStringsW(PStart);
  end;
end;
function os_lookupenv(const AName: string; out AValue: string): Boolean;
var
  Needed: DWORD;
  W: UnicodeString;
  lastErr: DWORD;
begin
  // Windows: GetEnvironmentVariableW returns 0 if not found; if found and empty, returns 0 but sets last error ERROR_SUCCESS.
  // Distinguish not-found (ERROR_ENVVAR_NOT_FOUND) from empty.
  AValue := '';
  SetLastError(ERROR_SUCCESS);
  Needed := GetEnvironmentVariableW(PWideChar(UnicodeString(AName)), nil, 0);
  if Needed = 0 then
  begin
    lastErr := GetLastError;
    if lastErr = ERROR_ENVVAR_NOT_FOUND then
      Exit(False)
    else
    begin
      // Defined but empty
      AValue := '';
      Exit(True);
    end;
  end;
  // When Needed > 0, retrieve the value
  SetLength(W, Needed);
  Needed := GetEnvironmentVariableW(PWideChar(UnicodeString(AName)), PWideChar(W), Needed);
  if Needed > 0 then
  begin
    SetLength(W, Needed);
    AValue := UTF8Encode(WideString(W));
    Exit(True);
  end;
  // Fallback: consider defined with empty, unless explicit not-found error
  lastErr := GetLastError;
  if lastErr = ERROR_ENVVAR_NOT_FOUND then
    Exit(False)
  else
  begin
    AValue := '';
    Exit(True);
  end;
end;


function os_hostname: string;
var
  Buf: array[0..255] of WideChar;
  L: DWORD;
begin
  L := DWORD(Length(Buf));
  if GetComputerNameW(@Buf[0], L) then
    Result := UTF8Encode(WideString(@Buf[0]))
  else
    Result := '';
end;

function os_username: string;
var
  buf: array[0..255] of WideChar;
  sz: DWORD;
  hSecur32: HMODULE;
  GetUserNameExW: function(NameFormat: ULONG; lpNameBuffer: LPWSTR; var nSize: ULONG): BOOL; stdcall;
  wide: UnicodeString;
  n: ULONG;
begin
  // Try GetUserNameExW(NameSamCompatible=2) dynamically
  Result := '';
  hSecur32 := LoadLibraryW('secur32.dll');
  if hSecur32 <> 0 then
  begin
    try
      Pointer(GetUserNameExW) := GetProcAddress(hSecur32, 'GetUserNameExW');
      if Assigned(GetUserNameExW) then
      begin
        n := 0;
        // NameSamCompatible = 2
        GetUserNameExW(2, nil, n);
        if n > 0 then
        begin
          SetLength(wide, n);
          if GetUserNameExW(2, PWideChar(wide), n) then
            Result := UTF8Encode(WideString(wide));
        end;
      end;
    finally
      FreeLibrary(hSecur32);
    end;
  end;
  if Result = '' then
  begin
    sz := Length(buf);
    if GetUserNameW(@buf[0], sz) then
      Result := UTF8Encode(WideString(@buf[0]))
    else
    begin
      Result := os_getenv('USERNAME');
      if Result = '' then
        Result := os_getenv('USER');
    end;
  end;
end;

function os_home_dir: string;
var
  drv, pth: string;
begin
  // Simplified: prefer env vars to avoid GUID/dynamic API fragility on older toolchains
  Result := os_getenv('USERPROFILE');
  if Result = '' then
  begin
    drv := os_getenv('HOMEDRIVE');
    pth := os_getenv('HOMEPATH');
    if (drv <> '') and (pth <> '') then
      Result := drv + pth;
  end;
  if Result = '' then
    Result := os_temp_dir;
  if Result <> '' then
    Result := ExcludeTrailingPathDelimiter(Result);
end;
function os_kernel_version: string;

var
  reg: HKEY;
  buf: array[0..255] of WideChar;
  datasize, dtype: DWORD;
  major, minor: DWORD;
  buildStr: string;
  buildNum: DWORD;
  ws: WideString;
  verStr: string;
  dotPos: Integer;
  vi: OSVERSIONINFO;
begin
  Result := '';
  if RegOpenKeyExW(HKEY_LOCAL_MACHINE, 'SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion', 0, KEY_READ, reg) = ERROR_SUCCESS then
  begin
    try
      datasize := SizeOf(buf); dtype := 0;
      if RegQueryValueExW(reg, 'CurrentVersion', nil, @dtype, @buf[0], @datasize) = ERROR_SUCCESS then
      begin
        if datasize >= SizeOf(WideChar) then buf[(datasize div SizeOf(WideChar)) - 1] := #0 else buf[0] := #0;
        ws := WideString(@buf[0]);
        major := 0; minor := 0;
        try
          verStr := UTF8Encode(WideString(ws));
          dotPos := Pos('.', verStr);
          if dotPos > 0 then
          begin
            major := StrToIntDef(Copy(verStr, 1, dotPos-1), 0);
            minor := StrToIntDef(Copy(verStr, dotPos+1, MaxInt), 0);
          end
          else
          begin
            major := StrToIntDef(verStr, 0);
            minor := 0;
          end;
        except end;
      end
      else
      begin
        major := 10; minor := 0;
      end;
      datasize := SizeOf(buf); dtype := 0;
      if RegQueryValueExW(reg, 'CurrentBuildNumber', nil, @dtype, @buf[0], @datasize) = ERROR_SUCCESS then
      begin
        if datasize >= SizeOf(WideChar) then buf[(datasize div SizeOf(WideChar)) - 1] := #0 else buf[0] := #0;
        buildStr := UTF8Encode(WideString(@buf[0]));
        buildNum := DWORD(StrToIntDef(buildStr, 0));
      end
      else
        buildNum := 0;
      Result := Format('%d.%d.%d', [major, minor, buildNum]);
    finally
      RegCloseKey(reg);
    end;
  end
  else
  begin
    FillChar(vi, SizeOf(vi), 0);
    vi.dwOSVersionInfoSize := SizeOf(vi);
    if GetVersionEx(vi) then
      Result := Format('%d.%d.%d', [vi.dwMajorVersion, vi.dwMinorVersion, vi.dwBuildNumber])
    else
      Result := '';
  end;
  {$IFDEF FAFAFA_OS_CACHE_PROBES}
  _cache_lock;
  try
    g_cached_kernel_ver := Result;
    g_cached_kernel_ver_inited := True;
  finally
    _cache_unlock;
  end;
  {$ENDIF}
end;

function os_uptime: QWord;
var
  ft: ULONGLONG;
begin
  // GetTickCount64 returns milliseconds since boot
  ft := GetTickCount64;
  Result := ft div 1000;
end;
type
  TMemoryStatusEx = record
    dwLength: DWORD;
    dwMemoryLoad: DWORD;
    ullTotalPhys: ULONGLONG;
    ullAvailPhys: ULONGLONG;
    ullTotalPageFile: ULONGLONG;
    ullAvailPageFile: ULONGLONG;
    ullTotalVirtual: ULONGLONG;
    ullAvailVirtual: ULONGLONG;
    ullAvailExtendedVirtual: ULONGLONG;
  end;

function GlobalMemoryStatusEx(var lpBuffer: TMemoryStatusEx): BOOL; stdcall; external 'kernel32' name 'GlobalMemoryStatusEx';

function os_memory_info(out totalBytes, freeBytes: QWord): Boolean;
var
  st: TMemoryStatusEx;
  st2: TMemoryStatus;
begin
  FillChar(st, SizeOf(st), 0);
  st.dwLength := SizeOf(st);
  if GlobalMemoryStatusEx(st) then
  begin
    totalBytes := st.ullTotalPhys;
    freeBytes := st.ullAvailPhys;
    Exit(totalBytes > 0);
  end;
  // Fallback to legacy API (32-bit totals)
  FillChar(st2, SizeOf(st2), 0);
  GlobalMemoryStatus(st2);
  totalBytes := st2.dwTotalPhys;
  freeBytes := st2.dwAvailPhys;
  Result := (totalBytes > 0);
end;

function os_boot_time: QWord;
var
  nowft: TSystemTime;
  nowdt: TDateTime;
  up: QWord;
begin
  // best-effort: Now(UTC) - Uptime
  GetSystemTime(nowft); // UTC
  nowdt := SystemTimeToDateTime(nowft);
  up := os_uptime;
  if up > 0 then
    Result := DateTimeToUnix(nowdt, True) - up
  else
    Result := 0;
end;

function os_timezone: string;
var
  tzi: TIME_ZONE_INFORMATION;
  r: DWORD;
  w: WideString;
begin
  {$IFDEF FAFAFA_OS_CACHE_PROBES}
  // fast path read without holding lock
  if g_cached_timezone_inited then Exit(g_cached_timezone);
  {$ENDIF}
  r := GetTimeZoneInformation(tzi);
  if (r <> $FFFFFFFF) then
    w := tzi.StandardName
  else
    w := '';
  {$IFDEF FAFAFA_OS_CACHE_PROBES}
  _cache_lock;
  try
    if not g_cached_timezone_inited then
    begin
      if w <> '' then g_cached_timezone := UTF8Encode(w) else g_cached_timezone := '';
      g_cached_timezone_inited := True;
    end;
    Result := g_cached_timezone;
  finally
    _cache_unlock;
  end;
  {$ELSE}
  if w <> '' then Result := UTF8Encode(w) else Result := '';
  {$ENDIF}
end;

type
  TWinTzMap = record std, iana: PChar; end;
const
  C_WIN_TZ_MAP: array[0..98] of TWinTzMap = (
    // Existing mappings
    (std:'China Standard Time'; iana:'Asia/Shanghai'),
    (std:'Tokyo Standard Time'; iana:'Asia/Tokyo'),
    (std:'Korea Standard Time'; iana:'Asia/Seoul'),
    (std:'Taipei Standard Time'; iana:'Asia/Taipei'),
    (std:'Hong Kong Standard Time'; iana:'Asia/Hong_Kong'),
    (std:'Singapore Standard Time'; iana:'Asia/Singapore'),
    (std:'SE Asia Standard Time'; iana:'Asia/Bangkok'),
    (std:'India Standard Time'; iana:'Asia/Kolkata'),
    (std:'Iran Standard Time'; iana:'Asia/Tehran'),
    (std:'Azerbaijan Standard Time'; iana:'Asia/Baku'),
    (std:'Georgian Standard Time'; iana:'Asia/Tbilisi'),
    (std:'Caucasus Standard Time'; iana:'Asia/Yerevan'),
    (std:'West Asia Standard Time'; iana:'Asia/Tashkent'),
    (std:'UTC'; iana:'Etc/UTC'),
    (std:'GMT Standard Time'; iana:'Europe/London'),
    (std:'Greenwich Standard Time'; iana:'Atlantic/Reykjavik'),
    (std:'W. Europe Standard Time'; iana:'Europe/Berlin'),
    (std:'Romance Standard Time'; iana:'Europe/Paris'),
    (std:'Central European Standard Time'; iana:'Europe/Warsaw'),
    (std:'Central Europe Standard Time'; iana:'Europe/Budapest'),
    (std:'GTB Standard Time'; iana:'Europe/Bucharest'),
    (std:'E. Europe Standard Time'; iana:'Europe/Athens'),
    (std:'Turkey Standard Time'; iana:'Europe/Istanbul'),
    (std:'Israel Standard Time'; iana:'Asia/Jerusalem'),
    (std:'Russian Standard Time'; iana:'Europe/Moscow'),
    (std:'FLE Standard Time'; iana:'Europe/Kiev'),
    (std:'Pacific Standard Time'; iana:'America/Los_Angeles'),
    (std:'Central Standard Time'; iana:'America/Chicago'),
    (std:'Eastern Standard Time'; iana:'America/New_York'),
    (std:'Newfoundland Standard Time'; iana:'America/St_Johns'),
    (std:'Mountain Standard Time'; iana:'America/Denver'),
    (std:'Alaskan Standard Time'; iana:'America/Anchorage'),
    (std:'Hawaiian Standard Time'; iana:'Pacific/Honolulu'),
    (std:'US Eastern Standard Time'; iana:'America/Indianapolis'),
    (std:'Venezuela Standard Time'; iana:'America/Caracas'),
    (std:'Argentina Standard Time'; iana:'America/Argentina/Buenos_Aires'),
    (std:'SA Eastern Standard Time'; iana:'America/Sao_Paulo'),
    (std:'SA Pacific Standard Time'; iana:'America/Bogota'),
    (std:'Central Brazilian Standard Time'; iana:'America/Cuiaba'),
    (std:'Morocco Standard Time'; iana:'Africa/Casablanca'),
    (std:'West Pacific Standard Time'; iana:'Pacific/Port_Moresby'),
    (std:'AUS Eastern Standard Time'; iana:'Australia/Sydney'),
    (std:'E. Australia Standard Time'; iana:'Australia/Brisbane'),
    (std:'AUS Central Standard Time'; iana:'Australia/Darwin'),
    (std:'Cen. Australia Standard Time'; iana:'Australia/Adelaide'),
    (std:'New Zealand Standard Time'; iana:'Pacific/Auckland'),
    (std:'W. Central Africa Standard Time'; iana:'Africa/Lagos'),
    (std:'South Africa Standard Time'; iana:'Africa/Johannesburg'),
    (std:'Egypt Standard Time'; iana:'Africa/Cairo'),
    (std:'Arabian Standard Time'; iana:'Asia/Dubai'),
    (std:'Arab Standard Time'; iana:'Asia/Riyadh'),
    (std:'Jordan Standard Time'; iana:'Asia/Amman'),
    // Additional commonly used mappings (KeyName preferred)
    (std:'Dateline Standard Time'; iana:'Etc/GMT+12'),
    (std:'UTC-11'; iana:'Etc/GMT+11'),
    (std:'Aleutian Standard Time'; iana:'America/Adak'),
    (std:'Samoa Standard Time'; iana:'Pacific/Apia'),
    (std:'Marquesas Standard Time'; iana:'Pacific/Marquesas'),
    (std:'UTC+12'; iana:'Etc/GMT-12'),
    (std:'UTC+13'; iana:'Etc/GMT-13'),
    (std:'Chatham Islands Standard Time'; iana:'Pacific/Chatham'),
    (std:'Fiji Standard Time'; iana:'Pacific/Fiji'),
    (std:'Tonga Standard Time'; iana:'Pacific/Tongatapu'),
    (std:'Lord Howe Standard Time'; iana:'Australia/Lord_Howe'),
    (std:'Norfolk Standard Time'; iana:'Pacific/Norfolk'),
    (std:'W. Australia Standard Time'; iana:'Australia/Perth'),
    (std:'Tasmania Standard Time'; iana:'Australia/Hobart'),
    (std:'Sri Lanka Standard Time'; iana:'Asia/Colombo'),
    (std:'Nepal Standard Time'; iana:'Asia/Kathmandu'),
    (std:'Bangladesh Standard Time'; iana:'Asia/Dhaka'),
    (std:'Myanmar Standard Time'; iana:'Asia/Yangon'),
    (std:'Pakistan Standard Time'; iana:'Asia/Karachi'),
    (std:'Afghanistan Standard Time'; iana:'Asia/Kabul'),
    (std:'Central Asia Standard Time'; iana:'Asia/Almaty'),
    (std:'N. Central Asia Standard Time'; iana:'Asia/Novosibirsk'),
    (std:'Omsk Standard Time'; iana:'Asia/Omsk'),
    (std:'North Asia East Standard Time'; iana:'Asia/Irkutsk'),
    (std:'Yakutsk Standard Time'; iana:'Asia/Yakutsk'),
    (std:'Vladivostok Standard Time'; iana:'Asia/Vladivostok'),
    (std:'Sakhalin Standard Time'; iana:'Asia/Sakhalin'),
    (std:'Magadan Standard Time'; iana:'Asia/Magadan'),
    (std:'Kamchatka Standard Time'; iana:'Asia/Kamchatka'),
    (std:'Russia Time Zone 10'; iana:'Asia/Srednekolymsk'),
    (std:'Ekaterinburg Standard Time'; iana:'Asia/Yekaterinburg'),
    (std:'Belarus Standard Time'; iana:'Europe/Minsk'),
    (std:'Kaliningrad Standard Time'; iana:'Europe/Kaliningrad'),
    (std:'Azores Standard Time'; iana:'Atlantic/Azores'),
    (std:'Cape Verde Standard Time'; iana:'Atlantic/Cape_Verde'),
    (std:'Canada Central Standard Time'; iana:'America/Regina'),
    (std:'Central America Standard Time'; iana:'America/Guatemala'),
    (std:'Central Standard Time (Mexico)'; iana:'America/Mexico_City'),
    (std:'Mountain Standard Time (Mexico)'; iana:'America/Chihuahua'),
    (std:'US Mountain Standard Time'; iana:'America/Phoenix'),
    (std:'Eastern Standard Time (Mexico)'; iana:'America/Cancun'),
    (std:'Atlantic Standard Time'; iana:'America/Halifax'),
    (std:'Greenland Standard Time'; iana:'America/Nuuk'),
    (std:'Montevideo Standard Time'; iana:'America/Montevideo'),
    (std:'Paraguay Standard Time'; iana:'America/Asuncion'),
    (std:'Pacific SA Standard Time'; iana:'America/Santiago'),
    (std:'Magallanes Standard Time'; iana:'America/Punta_Arenas')
  );

function _tz_map_lookup(const stdname: string): string;
var i: Integer;
begin
  for i := Low(C_WIN_TZ_MAP) to High(C_WIN_TZ_MAP) do
    if SameText(stdname, C_WIN_TZ_MAP[i].std) then Exit(string(C_WIN_TZ_MAP[i].iana));
  Result := '';
end;

function _win_tz_keyname(out keyName: string): Boolean;
var
  reg: HKEY;
  buf: array[0..255] of WideChar;
  datasize, dtype: DWORD;
begin
  keyName := '';
  Result := False;
  if RegOpenKeyExW(HKEY_LOCAL_MACHINE, 'SYSTEM\CurrentControlSet\Control\TimeZoneInformation', 0, KEY_READ, reg) = ERROR_SUCCESS then
  begin
    try
      datasize := SizeOf(buf); dtype := 0;
      if RegQueryValueExW(reg, 'TimeZoneKeyName', nil, @dtype, @buf[0], @datasize) = ERROR_SUCCESS then
      begin
        if datasize >= SizeOf(WideChar) then buf[(datasize div SizeOf(WideChar)) - 1] := #0 else buf[0] := #0;
        keyName := UTF8Encode(WideString(@buf[0]));
        Result := keyName <> '';
      end;
    finally
      RegCloseKey(reg);
    end;
  end;
end;

function os_timezone_iana: string;
var s, keyName: string;
begin
  {$IFDEF FAFAFA_OS_CACHE_PROBES}
  if g_cached_tz_iana_inited then Exit(g_cached_tz_iana);
  {$ENDIF}
  if _win_tz_keyname(keyName) and (keyName <> '') then
    s := keyName
  else
    s := os_timezone; // fallback to StandardName (may be localized)
  {$IFDEF FAFAFA_OS_CACHE_PROBES}
  _cache_lock;
  try
    if not g_cached_tz_iana_inited then
    begin
      g_cached_tz_iana := _tz_map_lookup(s);
      g_cached_tz_iana_inited := True;
    end;
    Result := g_cached_tz_iana;
  finally
    _cache_unlock;
  end;
  {$ELSE}
  Result := _tz_map_lookup(s);
  {$ENDIF}
end;

function os_is_admin: Boolean;
var
  hToken: HANDLE;
  adminSid: PSID = nil;
  isMember: BOOL;
  NTAuthority: SID_IDENTIFIER_AUTHORITY;
begin
  {$IFDEF FAFAFA_OS_CACHE_PROBES}
  // fast path: avoid lock if already cached
  if g_cached_is_admin_inited then Exit(g_cached_is_admin);
  {$ENDIF}
  // Build Administrators SID: S-1-5-32-544
  NTAuthority.Value[0] := 0; NTAuthority.Value[1] := 0; NTAuthority.Value[2] := 0;
  NTAuthority.Value[3] := 0; NTAuthority.Value[4] := 0; NTAuthority.Value[5] := 5;
  if not AllocateAndInitializeSid(NTAuthority, 2, 32, 544, 0,0,0,0,0,0, adminSid) then
    Exit(False);
  try
    isMember := False;
    if OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, hToken) then
    begin
      try
        if not CheckTokenMembership(hToken, adminSid, isMember) then
          isMember := False;
      finally
        CloseHandle(hToken);
      end;
    end;
  finally
    if adminSid <> nil then FreeSid(adminSid);
  end;
  {$IFDEF FAFAFA_OS_CACHE_PROBES}
  _cache_lock;
  try
    if not g_cached_is_admin_inited then
    begin
      g_cached_is_admin := isMember;
      g_cached_is_admin_inited := True;
    end;
    Result := g_cached_is_admin;
  finally
    _cache_unlock;
  end;
  Result := g_cached_is_admin;
end;

function os_is_wsl: Boolean;
begin
  // Windows host not WSL; return False
  Result := False;
end;

function os_is_container: Boolean;
var
  v: string;
begin
  // Heuristics via well-known env vars
  v := os_getenv('DOTNET_RUNNING_IN_CONTAINER');
  if (v <> '') and ((v = '1') or SameText(v, 'true')) then Exit(True);
  v := os_getenv('CONTAINER_SANDBOX_ID');
  if v <> '' then Exit(True);
  v := os_getenv('RUNNING_IN_CONTAINER');
  if (v <> '') and ((v = '1') or SameText(v, 'true')) then Exit(True);
  Result := False;
end;

function os_is_ci: Boolean;
begin
  Result := (os_getenv('CI') <> '') or (os_getenv('GITHUB_ACTIONS') <> '') or
            (os_getenv('GITLAB_CI') <> '') or (os_getenv('BUILD_BUILDID') <> '') or
            (os_getenv('CIRCLECI') <> '') or (os_getenv('APPVEYOR') <> '') or
            (os_getenv('TRAVIS') <> '') or (os_getenv('TEAMCITY_VERSION') <> '') or
            (os_getenv('JENKINS_URL') <> '');
end;


function os_os_version_detailed: TOSVersionDetailed;
var

  reg: HKEY;
  buf: array[0..255] of WideChar;
  datasize, dtype: DWORD;
  ws: WideString;
  buildStr, productName, displayVersion: string;
  releaseId, installationType, editionId, verLabel: string;
  major, minor, buildNum: Integer;
  vi: OSVERSIONINFO;
begin

  System.Initialize(Result);
  major := 0; minor := 0; buildNum := 0;
  if RegOpenKeyExW(HKEY_LOCAL_MACHINE, 'SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion', 0, KEY_READ, reg) = ERROR_SUCCESS then
  begin
    try
      // ProductName
      datasize := SizeOf(buf); dtype := 0;
      if RegQueryValueExW(reg, 'ProductName', nil, @dtype, @buf[0], @datasize) = ERROR_SUCCESS then
      begin
        if datasize >= SizeOf(WideChar) then buf[(datasize div SizeOf(WideChar)) - 1] := #0 else buf[0] := #0;
        ws := WideString(@buf[0]);
        productName := UTF8Encode(WideString(ws));
      end;
      // DisplayVersion (Windows 10 20H2+ / 11)
      datasize := SizeOf(buf); dtype := 0;
      if RegQueryValueExW(reg, 'DisplayVersion', nil, @dtype, @buf[0], @datasize) = ERROR_SUCCESS then
      begin
        if datasize >= SizeOf(WideChar) then buf[(datasize div SizeOf(WideChar)) - 1] := #0 else buf[0] := #0;
        ws := WideString(@buf[0]);
        displayVersion := UTF8Encode(WideString(ws));
      end;
      // ReleaseId (Windows 10 earlier)
      datasize := SizeOf(buf); dtype := 0;
      if RegQueryValueExW(reg, 'ReleaseId', nil, @dtype, @buf[0], @datasize) = ERROR_SUCCESS then
      begin
        if datasize >= SizeOf(WideChar) then buf[(datasize div SizeOf(WideChar)) - 1] := #0 else buf[0] := #0;
        ws := WideString(@buf[0]);
        releaseId := UTF8Encode(WideString(ws));
      end;
      // InstallationType / EditionID (best-effort, informative)
      datasize := SizeOf(buf); dtype := 0;
      if RegQueryValueExW(reg, 'InstallationType', nil, @dtype, @buf[0], @datasize) = ERROR_SUCCESS then
      begin
        if datasize >= SizeOf(WideChar) then buf[(datasize div SizeOf(WideChar)) - 1] := #0 else buf[0] := #0;
        ws := WideString(@buf[0]);
        installationType := UTF8Encode(WideString(ws));
      end;
      datasize := SizeOf(buf); dtype := 0;
      if RegQueryValueExW(reg, 'EditionID', nil, @dtype, @buf[0], @datasize) = ERROR_SUCCESS then
      begin
        if datasize >= SizeOf(WideChar) then buf[(datasize div SizeOf(WideChar)) - 1] := #0 else buf[0] := #0;
        ws := WideString(@buf[0]);
        editionId := UTF8Encode(WideString(ws));
      end;
      // CurrentVersion (e.g., 10.0)
      datasize := SizeOf(buf); dtype := 0;
      if RegQueryValueExW(reg, 'CurrentVersion', nil, @dtype, @buf[0], @datasize) = ERROR_SUCCESS then
      begin
        ws := WideString(@buf[0]);
        try
          major := StrToIntDef(UTF8Encode(WideString(Copy(ws, 1, Pos('.', ws)-1))), 0);
          minor := StrToIntDef(UTF8Encode(WideString(Copy(ws, Pos('.', ws)+1, MaxInt))), 0);
        except end;
      end;
      // Build number
      datasize := SizeOf(buf); dtype := 0;
      if RegQueryValueExW(reg, 'CurrentBuildNumber', nil, @dtype, @buf[0], @datasize) = ERROR_SUCCESS then
      begin
        buildStr := UTF8Encode(WideString(@buf[0]));
        buildNum := StrToIntDef(buildStr, 0);
      end;
      Result.VersionString := Format('%d.%d', [major, minor]);
      Result.Build := IntToStr(buildNum);

      // Enhanced Name/PrettyName construction
      if productName <> '' then
      begin
        verLabel := displayVersion;
        if verLabel = '' then verLabel := releaseId;
        if verLabel <> '' then
        begin
          Result.Name := productName + ' ' + verLabel;
          Result.PrettyName := Result.Name;
        end
        else
        begin
          Result.Name := productName;
          Result.PrettyName := Result.Name;
        end;

        // Add edition information if available
        if editionId <> '' then
        begin
          Result.Codename := editionId;
          if Pos(editionId, Result.Name) = 0 then
            Result.PrettyName := Result.Name + ' (' + editionId + ')';
        end;
      end
      else
      begin
        Result.Name := 'Windows';
        Result.PrettyName := Result.Name;
      end;

      // Enhanced ID construction
      Result.ID := 'windows';
      if installationType <> '' then
      begin
        if SameText(installationType, 'Server Core') then
          Result.IDLike := 'windows-server-core'
        else if SameText(installationType, 'Server') then
          Result.IDLike := 'windows-server'
        else if SameText(installationType, 'Client') then
          Result.IDLike := 'windows-client';
      end;
    finally
      RegCloseKey(reg);
    end;
  end
  else
  begin
    // fallback to GetVersionEx
    FillChar(vi, SizeOf(vi), 0);
    vi.dwOSVersionInfoSize := SizeOf(vi);
    if GetVersionEx(vi) then
    begin
      buildNum := vi.dwBuildNumber;
      Result.VersionString := Format('%d.%d', [vi.dwMajorVersion, vi.dwMinorVersion]);
      Result.Build := IntToStr(buildNum);

      // Enhanced version detection based on build numbers
      if vi.dwMajorVersion = 10 then
      begin
        // Windows 11 detection (build 22000+)
        if buildNum >= 26100 then begin
          Result.Name := 'Windows 11 24H2';
          Result.Codename := '24H2';
        end
        else if buildNum >= 22631 then begin
          Result.Name := 'Windows 11 23H2';
          Result.Codename := '23H2';
        end
        else if buildNum >= 22621 then begin
          Result.Name := 'Windows 11 22H2';
          Result.Codename := '22H2';
        end
        else if buildNum >= 22000 then begin
          Result.Name := 'Windows 11 21H2';
          Result.Codename := '21H2';
        end
        // Windows 10 versions
        else if buildNum >= 19045 then begin
          Result.Name := 'Windows 10 22H2';
          Result.Codename := '22H2';
        end
        else if buildNum >= 19044 then begin
          Result.Name := 'Windows 10 21H2';
          Result.Codename := '21H2';
        end
        else if buildNum >= 19043 then begin
          Result.Name := 'Windows 10 21H1';
          Result.Codename := '21H1';
        end
        else if buildNum >= 19042 then begin
          Result.Name := 'Windows 10 20H2';
          Result.Codename := '20H2';
        end
        else if buildNum >= 19041 then begin
          Result.Name := 'Windows 10 2004';
          Result.Codename := '2004';
        end
        else if buildNum >= 18363 then begin
          Result.Name := 'Windows 10 1909';
          Result.Codename := '1909';
        end
        else if buildNum >= 18362 then begin
          Result.Name := 'Windows 10 1903';
          Result.Codename := '1903';
        end
        else if buildNum >= 17763 then begin
          Result.Name := 'Windows 10 1809';
          Result.Codename := '1809';
        end
        else if buildNum >= 17134 then begin
          Result.Name := 'Windows 10 1803';
          Result.Codename := '1803';
        end
        else if buildNum >= 16299 then begin
          Result.Name := 'Windows 10 1709';
          Result.Codename := '1709';
        end
        else if buildNum >= 15063 then begin
          Result.Name := 'Windows 10 1703';
          Result.Codename := '1703';
        end
        else if buildNum >= 14393 then begin
          Result.Name := 'Windows 10 1607';
          Result.Codename := '1607';
        end
        else if buildNum >= 10586 then begin
          Result.Name := 'Windows 10 1511';
          Result.Codename := '1511';
        end
        else begin
          Result.Name := 'Windows 10 1507';
          Result.Codename := '1507';
        end;
      end
      else if vi.dwMajorVersion = 6 then
      begin
        if vi.dwMinorVersion = 3 then Result.Name := 'Windows 8.1'
        else if vi.dwMinorVersion = 2 then Result.Name := 'Windows 8'
        else if vi.dwMinorVersion = 1 then Result.Name := 'Windows 7'
        else if vi.dwMinorVersion = 0 then Result.Name := 'Windows Vista'
        else Result.Name := 'Windows NT 6.' + IntToStr(vi.dwMinorVersion);
      end
      else if vi.dwMajorVersion = 5 then
      begin
        if vi.dwMinorVersion = 2 then Result.Name := 'Windows Server 2003'
        else if vi.dwMinorVersion = 1 then Result.Name := 'Windows XP'
        else if vi.dwMinorVersion = 0 then Result.Name := 'Windows 2000'
        else Result.Name := 'Windows NT 5.' + IntToStr(vi.dwMinorVersion);
      end
      else
        Result.Name := 'Windows NT ' + IntToStr(vi.dwMajorVersion) + '.' + IntToStr(vi.dwMinorVersion);

      Result.PrettyName := Result.Name;
      Result.ID := 'windows';
    end;
  end;
  {$IFDEF FAFAFA_OS_CACHE_PROBES}
  _cache_lock;
  try
    g_cached_osver := Result;
    g_cached_osver_inited := True;
  finally
    _cache_unlock;
  end;
  {$ENDIF}
end;

function os_cpu_model: string;
{$IFDEF FAFAFA_OS_CACHE_PROBES}
var
  reg: HKEY;
  dataType: DWORD;
  dataSize: DWORD;
  wideBuf: array[0..255] of WideChar;
  envVal: string;
begin
  // Fast path: check cache without lock
  if g_cached_cpu_model_inited then Exit(g_cached_cpu_model);

  // Slow path: acquire lock and double-check
  _cache_lock;
  try
    if g_cached_cpu_model_inited then Exit(g_cached_cpu_model);
    g_cached_cpu_model := '';

    // Primary method: Registry ProcessorNameString
    if RegOpenKeyExW(HKEY_LOCAL_MACHINE, 'HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0', 0, KEY_READ, reg) = ERROR_SUCCESS then
    begin
      try
        dataType := 0; dataSize := SizeOf(wideBuf);
        if RegQueryValueExW(reg, 'ProcessorNameString', nil, @dataType, @wideBuf[0], @dataSize) = ERROR_SUCCESS then
          g_cached_cpu_model := Trim(UTF8Encode(WideString(@wideBuf[0])));
      finally
        RegCloseKey(reg);
      end;
    end;

    // Fallback 1: PROCESSOR_IDENTIFIER environment variable
    if g_cached_cpu_model = '' then
    begin
      envVal := os_getenv('PROCESSOR_IDENTIFIER');
      if envVal <> '' then g_cached_cpu_model := Trim(envVal);
    end;

    // Fallback 2: Try alternative registry keys
    if g_cached_cpu_model = '' then
    begin
      if RegOpenKeyExW(HKEY_LOCAL_MACHINE, 'HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0', 0, KEY_READ, reg) = ERROR_SUCCESS then
      begin
        try
          // Try Identifier field
          dataType := 0; dataSize := SizeOf(wideBuf);
          if RegQueryValueExW(reg, 'Identifier', nil, @dataType, @wideBuf[0], @dataSize) = ERROR_SUCCESS then
            g_cached_cpu_model := Trim(UTF8Encode(WideString(@wideBuf[0])));
        finally
          RegCloseKey(reg);
        end;
      end;
    end;

    // Fallback 3: PROCESSOR_ARCHITECTURE + PROCESSOR_LEVEL
    if g_cached_cpu_model = '' then
    begin
      envVal := os_getenv('PROCESSOR_ARCHITECTURE');
      if envVal <> '' then
      begin
        g_cached_cpu_model := envVal;
        envVal := os_getenv('PROCESSOR_LEVEL');
        if envVal <> '' then
          g_cached_cpu_model := g_cached_cpu_model + ' Level ' + envVal;
      end;
    end;

    g_cached_cpu_model_inited := True;
  finally
    _cache_unlock;
  end;

  Result := g_cached_cpu_model;
end;
{$ELSE}
var
  reg: HKEY;
  dataType: DWORD;
  dataSize: DWORD;
  wideBuf: array[0..255] of WideChar;
  model, envVal: string;
begin
  model := '';

  // Primary method: Registry ProcessorNameString
  if RegOpenKeyExW(HKEY_LOCAL_MACHINE, 'HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0', 0, KEY_READ, reg) = ERROR_SUCCESS then
  begin
    try
      dataType := 0; dataSize := SizeOf(wideBuf);
      if RegQueryValueExW(reg, 'ProcessorNameString', nil, @dataType, @wideBuf[0], @dataSize) = ERROR_SUCCESS then
        model := Trim(UTF8Encode(WideString(@wideBuf[0])));
    finally
      RegCloseKey(reg);
    end;
  end;

  // Fallback 1: PROCESSOR_IDENTIFIER environment variable
  if model = '' then
  begin
    envVal := os_getenv('PROCESSOR_IDENTIFIER');
    if envVal <> '' then model := Trim(envVal);
  end;

  // Fallback 2: Try alternative registry keys
  if model = '' then
  begin
    if RegOpenKeyExW(HKEY_LOCAL_MACHINE, 'HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0', 0, KEY_READ, reg) = ERROR_SUCCESS then
    begin
      try
        // Try Identifier field
        dataType := 0; dataSize := SizeOf(wideBuf);
        if RegQueryValueExW(reg, 'Identifier', nil, @dataType, @wideBuf[0], @dataSize) = ERROR_SUCCESS then
          model := Trim(UTF8Encode(WideString(@wideBuf[0])));
      finally
        RegCloseKey(reg);
      end;
    end;
  end;

  // Fallback 3: PROCESSOR_ARCHITECTURE + PROCESSOR_LEVEL
  if model = '' then
  begin
    envVal := os_getenv('PROCESSOR_ARCHITECTURE');
    if envVal <> '' then
    begin
      model := envVal;
      envVal := os_getenv('PROCESSOR_LEVEL');
      if envVal <> '' then
        model := model + ' Level ' + envVal;
    end;
  end;

  Result := model;
end;
{$ENDIF}

const
  LOCALE_SNAME = $0000005C; // Windows Vista+

function os_locale_current: string;
var
  wbuf: array[0..85] of WideChar; // LOCALE_NAME_MAX_LENGTH = 85
  len: Integer;
begin
  // Prefer Windows locale SNAME (e.g., "en-US")
  len := GetLocaleInfoW(LOCALE_USER_DEFAULT, LOCALE_SNAME, @wbuf[0], Length(wbuf));
  if len > 0 then
    Result := UTF8Encode(WideString(@wbuf[0]))
  else
    Result := '';
end;


function os_temp_dir: string;
var
  wbuf: array[0..MAX_PATH] of WideChar;
  n: DWORD;
begin
  Result := os_getenv('TEMP');
  if Result = '' then
    Result := os_getenv('TMP');
  if Result <> '' then
  begin
    Result := ExcludeTrailingPathDelimiter(Result);
    Exit;
  end;
  n := GetTempPathW(Length(wbuf), @wbuf[0]);
  if n > 0 then
    Result := UTF8Encode(WideString(@wbuf[0]))
  else
    Result := 'C:\\Windows\\Temp';
  if Result <> '' then
    Result := ExcludeTrailingPathDelimiter(Result);
end;

function os_page_size: Integer;
var
  SI: SYSTEM_INFO;
begin
  GetSystemInfo(SI);
  Result := Integer(SI.dwPageSize);
end;

procedure os_cache_reset;
begin
  {$IFDEF FAFAFA_OS_CACHE_PROBES}
  _cache_lock;
  try
    g_cached_cpu_model_inited := False;
    g_cached_cpu_model := '';
    g_cached_timezone_inited := False;
    g_cached_timezone := '';
    g_cached_tz_iana_inited := False;
    g_cached_tz_iana := '';
    g_cached_is_admin_inited := False;
    g_cached_is_admin := False;
    g_cached_kernel_ver_inited := False;
    g_cached_kernel_ver := '';
    g_cached_osver_inited := False;
    FillChar(g_cached_osver, SizeOf(g_cached_osver), 0);
  finally
    _cache_unlock;
  end;
  {$ENDIF}
end;

procedure os_cache_reset_ex(const flags: TOSCacheFlags);
begin
  {$IFDEF FAFAFA_OS_CACHE_PROBES}
  _cache_lock;
  try
    if oscCpuModel in flags then begin
      g_cached_cpu_model_inited := False;
      g_cached_cpu_model := '';
    end;
    if oscTimezone in flags then begin
      g_cached_timezone_inited := False;
      g_cached_timezone := '';
    end;
    if oscTimezoneIana in flags then begin
      g_cached_tz_iana_inited := False;
      g_cached_tz_iana := '';
    end;
    if oscIsAdmin in flags then begin
      g_cached_is_admin_inited := False;
      g_cached_is_admin := False;
    end;
    if oscKernelVersion in flags then begin
      g_cached_kernel_ver_inited := False;
      g_cached_kernel_ver := '';
    end;
    if oscOSVersionDetailed in flags then begin
      g_cached_osver_inited := False;
      FillChar(g_cached_osver, SizeOf(g_cached_osver), 0);
    end;
  finally
    _cache_unlock;
  end;
  {$ENDIF}
end;

