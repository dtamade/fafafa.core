{ Platform-specific implementations for Unix-like systems }

{$IFDEF FAFAFA_OS_CACHE_PROBES}
var
  g_unix_cached_cpu_model_inited: Boolean = False;
  g_unix_cached_cpu_model: string = '';
  g_unix_cached_timezone_inited: Boolean = False;
  g_unix_cached_timezone: string = '';
  g_unix_cached_kernel_ver_inited: Boolean = False;
  g_unix_cached_kernel_ver: string = '';
  g_unix_cached_osver_inited: Boolean = False;
  g_unix_cached_osver: TOSVersionDetailed;
  g_unix_cache_cs_inited: Boolean = False;
  g_unix_cache_cs: TRTLCriticalSection;

procedure _cache_lock_unix;
begin
  if not g_unix_cache_cs_inited then
  begin
    InitCriticalSection(g_unix_cache_cs);
    g_unix_cache_cs_inited := True;
  end;
  EnterCriticalSection(g_unix_cache_cs);
end;

procedure _cache_unlock_unix;
begin
  if g_unix_cache_cs_inited then
    LeaveCriticalSection(g_unix_cache_cs);
end;
{$ENDIF}

function os_setenv(const AName, AValue: string): Boolean;
begin
  if AValue = '' then
    Result := (fpunsetenv(PChar(AName)) = 0)
  else
    Result := (fpsetenv(PChar(AnsiString(AName + '=' + AValue))) = 0);
end;

function os_unsetenv(const AName: string): Boolean;
begin
  Result := (fpunsetenv(PChar(AName)) = 0);
end;

procedure os_environ(const ADest: TStrings);
var
  I, Cnt: Integer;
  PEnv: PChar;
begin
  if ADest = nil then Exit;
  ADest.Clear;
  Cnt := SysUtils.GetEnvironmentVariableCount;
  for I := 0 to Cnt - 1 do
  begin
    PEnv := SysUtils.GetEnvironmentString(I);
    if PEnv <> nil then
      ADest.Add(string(PEnv));
  end;
end;
function os_lookupenv(const AName: string; out AValue: string): Boolean;
begin
  // 优先使用 fpgetenv（常量时间），否则回退扫描环境块
  AValue := '';
  {$IFDEF UNIX}
  var p := fpgetenv(PChar(AName));
  if p <> nil then begin
    AValue := StrPas(p);
    Exit(True);
  end;
  {$ENDIF}
  Result := False;
  var cnt := SysUtils.GetEnvironmentVariableCount;
  for var i := 0 to cnt - 1 do
  begin
    var q := SysUtils.GetEnvironmentString(i);
    if q = nil then Continue;
    var s := string(q);
    var posEq := System.Pos('=', s);
    if posEq <= 0 then Continue;
    var name := Copy(s, 1, posEq - 1);
    if name = AName then
    begin
      AValue := Copy(s, posEq + 1, MaxInt);
      Exit(True);
    end;
  end;
end;


function os_hostname: string;
var
  Buf: array[0..255] of Char;
begin
  if fpgethostname(@Buf[0], SizeOf(Buf)) = 0 then
    Result := StrPas(@Buf[0])
  else
    Result := '';
end;

function os_username: string;
{$IFDEF UNIX}
var
  pw: PPasswd;
begin
  pw := fpgetpwuid(fpgeteuid);
  if (pw <> nil) and (pw^.pw_name <> nil) then
    Result := StrPas(pw^.pw_name)
  else
  begin
    Result := os_getenv('USER');
    if Result = '' then
      Result := os_getenv('USERNAME');
  end;
end;
{$ELSE}
begin
  Result := os_getenv('USER');
  if Result = '' then
    Result := os_getenv('USERNAME');
end;
{$ENDIF}

function os_home_dir: string;
{$IFDEF UNIX}
var
  pw: PPasswd;
begin
  Result := os_getenv('HOME');
  if Result = '' then
  begin
    pw := fpgetpwuid(fpgeteuid);
    if (pw <> nil) and (pw^.pw_dir <> nil) then
      Result := StrPas(pw^.pw_dir)
    else
      Result := '';
  end;
  if Result <> '' then
    Result := ExcludeTrailingPathDelimiter(Result);
end;
{$ELSE}
begin
  Result := os_getenv('HOME');
  if Result <> '' then
    Result := ExcludeTrailingPathDelimiter(Result);
end;
{$ENDIF}

function os_temp_dir: string;
begin
  Result := os_getenv('TMPDIR');
  if Result = '' then
    Result := '/tmp';
  if Result <> '' then
    Result := ExcludeTrailingPathDelimiter(Result);
end;

function os_page_size: Integer;
begin
  {$IFDEF DARWIN}
  // macOS: sysctl hw.pagesize
  var ps: cint;
  var sz: size_t = SizeOf(ps);
  if fpSysCtlByName('hw.pagesize', @ps, @sz, nil, 0) = 0 then
    Result := ps
  else
    Result := 4096;
  {$ELSEIF DEFINED(HASFPSYSCONF)}
  Result := fpSysConf(_SC_PAGESIZE);
  if Result <= 0 then Result := 4096;
  {$ELSE}
  Result := 4096;
  {$ENDIF}
end;

procedure os_cache_reset;
begin
  {$IFDEF FAFAFA_OS_CACHE_PROBES}
  g_unix_cached_cpu_model_inited := False; g_unix_cached_cpu_model := '';
  g_unix_cached_timezone_inited := False; g_unix_cached_timezone := '';
  g_unix_cached_kernel_ver_inited := False; g_unix_cached_kernel_ver := '';
  g_unix_cached_osver_inited := False; FillChar(g_unix_cached_osver, SizeOf(g_unix_cached_osver), 0);
  {$ENDIF}
end;

procedure os_cache_reset_ex(const flags: TOSCacheFlags);
begin
  {$IFDEF FAFAFA_OS_CACHE_PROBES}
  if oscCpuModel in flags then begin g_unix_cached_cpu_model_inited := False; g_unix_cached_cpu_model := ''; end;
  if oscTimezone in flags then begin g_unix_cached_timezone_inited := False; g_unix_cached_timezone := ''; end;
  if oscKernelVersion in flags then begin g_unix_cached_kernel_ver_inited := False; g_unix_cached_kernel_ver := ''; end;
  if oscOSVersionDetailed in flags then begin g_unix_cached_osver_inited := False; FillChar(g_unix_cached_osver, SizeOf(g_unix_cached_osver), 0); end;
  // Unix: timezone_iana 等于 timezone，无需单独分组
  {$ENDIF}
end;

function os_kernel_version: string;
{$IFDEF FAFAFA_OS_CACHE_PROBES}
begin
  _cache_lock_unix;
  try
    if g_unix_cached_kernel_ver_inited then Exit(g_unix_cached_kernel_ver);
  finally
    _cache_unlock_unix;
  end;
{$ENDIF}
var
  uts: UtsName;
begin
  if fpUname(uts) = 0 then
    Result := StrPas(@uts.release[0])
  else
    Result := '';
  {$IFDEF FAFAFA_OS_CACHE_PROBES}
  _cache_lock_unix;
  try
    g_unix_cached_kernel_ver := Result;
    g_unix_cached_kernel_ver_inited := True;
  finally
    _cache_unlock_unix;
  end;
  {$ENDIF}
end;

function os_uptime: QWord;
{$IFDEF DARWIN}
var
  tvBoot, tvNow: TimeVal;
  sz: size_t;
begin
  Result := 0;
  sz := SizeOf(tvBoot);
  if fpSysCtlByName('kern.boottime', @tvBoot, @sz, nil, 0) = 0 then
  begin
    if fpGetTimeOfDay(@tvNow, nil) = 0 then
    begin
      if tvNow.tv_sec > tvBoot.tv_sec then
        Result := QWord(tvNow.tv_sec - tvBoot.tv_sec)
      else
        Result := 0;
    end;
  end;
end;
{$ELSEIF DEFINED(FREEBSD) or DEFINED(OPENBSD) or DEFINED(NETBSD) or DEFINED(DRAGONFLY)}
var
  tvBoot, tvNow: TimeVal;
  sz: size_t;
begin
  Result := 0;
  sz := SizeOf(tvBoot);
  if fpSysCtlByName('kern.boottime', @tvBoot, @sz, nil, 0) = 0 then
  begin
    if fpGetTimeOfDay(@tvNow, nil) = 0 then
    begin
      if tvNow.tv_sec > tvBoot.tv_sec then
        Result := QWord(tvNow.tv_sec - tvBoot.tv_sec)
      else
        Result := 0;
    end;
  end;
end;
{$ELSE}
var
  f: Text;
  s: string;
  p: Integer;
  v: Extended;
begin
  // Try /proc/uptime (Linux). If not available, return 0.
  Result := 0;
  Assign(f, '/proc/uptime');
  {$I-}
  Reset(f);
  {$I+}
  if IOResult = 0 then
  begin
    ReadLn(f, s);
    Close(f);
    p := Pos(' ', s);
    if p > 0 then s := Copy(s, 1, p-1);
    Val(s, v, p);
    if p = 0 then
      if v > 0 then Result := Trunc(v);
  end;
end;
{$ENDIF}


function os_memory_info(out totalBytes, freeBytes: QWord): Boolean;
{$IFDEF DARWIN}
var
  memsize: QWord;
  memsizeLen: size_t;
  host: mach_port_t;
  count: mach_msg_type_number_t;
  vmstat: vm_statistics64_data_t;
  pagesize: vm_size_t;
  ret: kern_return_t;
begin
  totalBytes := 0; freeBytes := 0;
  memsizeLen := SizeOf(memsize);
  if fpSysCtlByName('hw.memsize', @memsize, @memsizeLen, nil, 0) = 0 then
    totalBytes := memsize;
  host := mach_host_self();
  count := SizeOf(vmstat) div SizeOf(integer);
  ret := host_page_size(host, pagesize);
  if ret = 0 then
  begin
    ret := host_statistics64(host, HOST_VM_INFO64, vmstat, count);
    if ret = 0 then
    begin
      freeBytes := (QWord(vmstat.free_count) + QWord(vmstat.inactive_count)) * QWord(pagesize);
    end;
  end;
  Result := (totalBytes > 0);
end;
{$ELSE}
var
  f: Text;
  k, v: QWord;
  s, key: string;
  p: Integer;
begin
  totalBytes := 0; freeBytes := 0; Result := False;
  Assign(f, '/proc/meminfo');
  {$I-}
  Reset(f);
  {$I+}
  if IOResult <> 0 then Exit;
  try
    while not Eof(f) do
    begin
      ReadLn(f, s);
      p := Pos(':', s);
      if p > 0 then
      begin
        key := Copy(s, 1, p-1);
        s := Trim(Copy(s, p+1, MaxInt));
        Val(Copy(s, 1, Pos(' ', s)-1), v, p);
        if p = 0 then
        begin
          // values are in kB
          k := v * 1024;
          if SameText(key, 'MemTotal') then totalBytes := k;
          if SameText(key, 'MemAvailable') then freeBytes := k;
        end;
      end;
    end;
  finally
    Close(f);
  end;
  Result := (totalBytes > 0);
end;
{$ENDIF}

function os_boot_time: QWord;
{$IFDEF DARWIN}
var
  tvBoot: TimeVal;
  sz: size_t;
begin
  Result := 0;
  sz := SizeOf(tvBoot);
  if fpSysCtlByName('kern.boottime', @tvBoot, @sz, nil, 0) = 0 then
    Result := QWord(tvBoot.tv_sec)
  else
    Result := 0;
end;
{$ELSEIF DEFINED(FREEBSD) or DEFINED(OPENBSD) or DEFINED(NETBSD) or DEFINED(DRAGONFLY)}
var
  tvBoot: TimeVal;
  sz: size_t;
begin
  Result := 0;
  sz := SizeOf(tvBoot);
  if fpSysCtlByName('kern.boottime', @tvBoot, @sz, nil, 0) = 0 then
    Result := QWord(tvBoot.tv_sec)
  else
    Result := 0;
end;
{$ELSE}
var
  f: Text;
  s: string;
  p, code: Integer;
  v: QWord;
begin
  Result := 0;
  Assign(f, '/proc/stat');
  {$I-}
  Reset(f);
  {$I+}
  if IOResult <> 0 then Exit;
  try
    while not Eof(f) do
    begin
      ReadLn(f, s);
      if Pos('btime', s) = 1 then
      begin
        p := Pos(' ', s);
        Delete(s, 1, p);
        Val(Trim(s), v, code);
        if code = 0 then Result := v;
        Break;
      end;
    end;
  finally
    Close(f);
  end;
end;
{$ENDIF}



function os_is_admin: Boolean;
begin
  Result := (fpGetUID = 0);
end;

function os_is_wsl: Boolean;
var
  f: Text; s: string;
begin
  Result := False;
  Assign(f, '/proc/sys/kernel/osrelease');
  {$I-} Reset(f); {$I+}
  if IOResult <> 0 then Exit;
  try
    ReadLn(f, s);
    if Pos('Microsoft', s) > 0 then Result := True;
  finally
    Close(f);
  end;
end;

function os_is_container: Boolean;
var
  f: Text; s: string;
begin
  if FileExists('/.dockerenv') or FileExists('/run/.containerenv') then Exit(True);
  Result := False;
  Assign(f, '/proc/1/cgroup');
  {$I-} Reset(f); {$I+}
  if IOResult <> 0 then Exit;
  try
    while not Eof(f) do begin
      ReadLn(f, s);
      if (Pos('docker', s) > 0) or (Pos('containerd', s) > 0) or (Pos('/kubepods/', s) > 0)
         or (Pos('crio', s) > 0) or (Pos('podman', s) > 0) then begin
        Result := True; Exit;
      end;
    end;
  finally
    Close(f);
  end;
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
{$IFDEF FAFAFA_OS_CACHE_PROBES}
begin
  _cache_lock_unix;
  try
    if g_unix_cached_osver_inited then Exit(g_unix_cached_osver);
  finally
    _cache_unlock_unix;
  end;
{$ENDIF}
var
  f: Text; s, k, v: string; p: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  {$IFDEF DARWIN}
  // macOS: map Darwin kernel major to macOS version (best-effort)
  // uname -r returns like: 23.4.0 for macOS 14.x (Sonoma), 24.x for macOS 15 (Sequoia)
  var un: utsname;
  var rel: AnsiString;
  var dot, major: Integer;
  if fpUname(un) = 0 then
  begin
    rel := StrPas(@un.release[0]);
    dot := Pos('.', rel);
    major := StrToIntDef(Copy(rel, 1, dot-1), 0);
    // Mapping (simplified): 22→13 Ventura, 23→14 Sonoma, 24→15 Sequoia; plus older versions
    if major >= 24 then begin Result.VersionString := '15'; Result.Name := 'macOS Sequoia'; end
    else if major = 23 then begin Result.VersionString := '14'; Result.Name := 'macOS Sonoma'; end
    else if major = 22 then begin Result.VersionString := '13'; Result.Name := 'macOS Ventura'; end
    else if major = 21 then begin Result.VersionString := '12'; Result.Name := 'macOS Monterey'; end
    else if major = 20 then begin Result.VersionString := '11'; Result.Name := 'macOS Big Sur'; end
    else if major = 19 then begin Result.VersionString := '10.15'; Result.Name := 'macOS Catalina'; end
    else if major = 18 then begin Result.VersionString := '10.14'; Result.Name := 'macOS Mojave'; end
    else if major = 17 then begin Result.VersionString := '10.13'; Result.Name := 'macOS High Sierra'; end
    else if major = 16 then begin Result.VersionString := '10.12'; Result.Name := 'macOS Sierra'; end
    else begin Result.VersionString := IntToStr(major); Result.Name := 'macOS'; end;
    Result.PrettyName := Result.Name;
    Result.Build := rel; // keep Darwin release as build hint
    Result.ID := 'macos';
    {$IFDEF FAFAFA_OS_CACHE_PROBES}
    _cache_lock_unix; try g_unix_cached_osver := Result; g_unix_cached_osver_inited := True; finally _cache_unlock_unix; end;
    {$ENDIF}
    Exit;
  end;
  {$ENDIF}
  if FileExists('/etc/os-release') then
  begin
    Assign(f, '/etc/os-release'); {$I-} Reset(f); {$I+}
    if IOResult = 0 then
    begin
      try
        while not EOF(f) do
        begin
          ReadLn(f, s);
          p := Pos('=', s);
          if p > 0 then
          begin
            k := Copy(s, 1, p-1);
            v := Copy(s, p+1, MaxInt);
            v := StringReplace(v, '"', '', [rfReplaceAll]);
            if SameText(k, 'NAME') then begin Result.Name := v; if Result.PrettyName='' then Result.PrettyName := v; end;
            if SameText(k, 'VERSION_ID') then Result.VersionString := v;
            if SameText(k, 'VERSION') then Result.Codename := v;
            if SameText(k, 'ID') then Result.ID := LowerCase(v);
            if SameText(k, 'ID_LIKE') then Result.IDLike := LowerCase(v);
            if SameText(k, 'PRETTY_NAME') then Result.PrettyName := v;
          end;
        end;
      finally
        Close(f);
      end;
    end;
  end;
  // Fallback: if still mostly empty, try uname sysname/release to fill basics
  if (Result.Name = '') and (Result.VersionString = '') and (Result.PrettyName = '') then
  begin
    var un: utsname;
    if fpUname(un) = 0 then
    begin
      Result.Name := StrPas(@un.sysname[0]);
      Result.VersionString := StrPas(@un.release[0]);
      Result.PrettyName := Result.Name;
      Result.Build := Result.VersionString;
    end;
  end;

  // If uname fallback used and we have Name, set ID as lowercase(Name) for BSD-like systems
  if (Result.ID = '') and (Result.Name <> '') then
    Result.ID := LowerCase(Result.Name);

  {$IFDEF FAFAFA_OS_CACHE_PROBES}
  _cache_lock_unix; try g_unix_cached_osver := Result; g_unix_cached_osver_inited := True; finally _cache_unlock_unix; end;
  {$ENDIF}
end;

function os_cpu_model: string;
{$IFDEF FAFAFA_OS_CACHE_PROBES}
var f: Text; s: string; p: Integer;
begin
  if g_unix_cached_cpu_model_inited then Exit(g_unix_cached_cpu_model);
  g_unix_cached_cpu_model := '';
  {$IFDEF DARWIN}
  // macOS: sysctl machdep.cpu.brand_string
  var fpcmd: cint; // avoid name clash
  var name: PChar = 'machdep.cpu.brand_string';
  var buf: array[0..255] of Char;
  var size: size_t = SizeOf(buf);
  if fpSysCtlByName(name, @buf[0], @size, nil, 0) = 0 then
    g_unix_cached_cpu_model := Trim(StrPas(@buf[0]));
  {$ELSE}
  if FileExists('/proc/cpuinfo') then
  begin
    Assign(f, '/proc/cpuinfo'); {$I-} Reset(f); {$I+}
    if IOResult = 0 then
    begin
      try
        while not EOF(f) do begin
          ReadLn(f, s);
          p := Pos(':', s);
          if (p > 0) and (Pos('model name', s) = 1) then
          begin
            g_unix_cached_cpu_model := Trim(Copy(s, p+1, MaxInt));
            Break;
          end;
        end;
      finally
        Close(f);
      end;
    end;
  end;
  {$ENDIF}
  g_unix_cached_cpu_model_inited := True;
  Result := g_unix_cached_cpu_model;
end;
{$ELSE}
var f: Text; s: string; p: Integer; model: string;
begin
  model := '';
  {$IFDEF DARWIN}
  // macOS: sysctl machdep.cpu.brand_string
  var fpcmd: cint; // avoid name clash
  var name: PChar = 'machdep.cpu.brand_string';
  var buf: array[0..255] of Char;
  var size: size_t = SizeOf(buf);
  if fpSysCtlByName(name, @buf[0], @size, nil, 0) = 0 then
    model := Trim(StrPas(@buf[0]));
  {$ELSE}
  if FileExists('/proc/cpuinfo') then
  begin
    Assign(f, '/proc/cpuinfo'); {$I-} Reset(f); {$I+}
    if IOResult = 0 then
    begin
      try
        while not EOF(f) do begin
          ReadLn(f, s);
          p := Pos(':', s);
          if (p > 0) and (Pos('model name', s) = 1) then
          begin
            model := Trim(Copy(s, p+1, MaxInt));
            Break;
          end;
        end;
      finally
        Close(f);
      end;
    end;
  end;
  {$ENDIF}
  Result := model;
end;
{$ENDIF}

function os_locale_current: string;
var
  lang: string; p, atPos, colonPos: Integer;
begin
  // Prefer LANG; fallback LC_ALL/LC_MESSAGES/LC_CTYPE; normalize: zh_CN.UTF-8@modifier:other -> zh-CN
  lang := os_getenv('LANG');
  if lang = '' then lang := os_getenv('LC_ALL');
  if lang = '' then lang := os_getenv('LC_MESSAGES');
  if lang = '' then lang := os_getenv('LC_CTYPE');
  // take first segment before ':'
  colonPos := Pos(':', lang);
  if colonPos > 0 then
    Delete(lang, colonPos, MaxInt);
  // strip modifier after '@'
  atPos := Pos('@', lang);
  if atPos > 0 then
    Delete(lang, atPos, MaxInt);
  // strip encoding after '.'
  p := Pos('.', lang);
  if p > 0 then
    Delete(lang, p, MaxInt);
  // normalize underscore to hyphen
  lang := StringReplace(lang, '_', '-', [rfReplaceAll]);
  Result := lang;
end;

function os_timezone: string;
{$IFDEF FAFAFA_OS_CACHE_PROBES}
var s: string;
    f: Text;
    linkbuf: array[0..1023] of Char;
    L, p: Integer;
begin
  // Fast path without lock
  if g_unix_cached_timezone_inited then
    Exit(g_unix_cached_timezone);

  // Slow path with lock + double-check
  _cache_lock_unix;
  try
    if g_unix_cached_timezone_inited then
      Exit(g_unix_cached_timezone);

    s := os_getenv('TZ');
    if s <> '' then
    begin
      g_unix_cached_timezone := s;
      g_unix_cached_timezone_inited := True;
      Exit(g_unix_cached_timezone);
    end;

    if FileExists('/etc/timezone') then
    begin
      Assign(f, '/etc/timezone'); {$I-} Reset(f); {$I+}
      if IOResult = 0 then
      begin
        try
          ReadLn(f, s);
          s := Trim(s);
        finally
          Close(f);
        end;
        if s <> '' then
        begin
          g_unix_cached_timezone := s;
          g_unix_cached_timezone_inited := True;
          Exit(g_unix_cached_timezone);
        end;
      end;
    end
    else if FileExists('/etc/TZ') then
    begin
      Assign(f, '/etc/TZ'); {$I-} Reset(f); {$I+}
      if IOResult = 0 then
      begin
        try ReadLn(f, s); finally Close(f); end;
        s := Trim(s);
        if s <> '' then
        begin
          g_unix_cached_timezone := s;
          g_unix_cached_timezone_inited := True;
          Exit(g_unix_cached_timezone);
        end;
      end;
    end
    else if FileExists('/etc/sysconfig/clock') then
    begin
      Assign(f, '/etc/sysconfig/clock'); {$I-} Reset(f); {$I+}
      if IOResult = 0 then
      begin
        try
          while not EOF(f) do begin
            ReadLn(f, s);
            p := Pos('ZONE=', s);
            if p = 1 then begin
              s := Trim(StringReplace(Copy(s, 6, MaxInt), '"', '', [rfReplaceAll]));
              if s <> '' then
              begin
                g_unix_cached_timezone := s;
                g_unix_cached_timezone_inited := True;
                Close(f);
                Exit(g_unix_cached_timezone);
              end;
            end;
          end;
        finally
          Close(f);
        end;
      end;
    end;

    // Try /etc/localtime symlink like .../zoneinfo/Region/City
    {$IFDEF UNIX}
    L := fpReadlink('/etc/localtime', @linkbuf[0], SizeOf(linkbuf)-1);
    if L > 0 then
    begin
      linkbuf[L] := #0;
      s := StrPas(@linkbuf[0]);
      // find 'zoneinfo/' and take the tail
      p := Pos('zoneinfo/', s);
      if p > 0 then
        s := Copy(s, p + Length('zoneinfo/'), MaxInt);
    end;
    {$ENDIF}

    g_unix_cached_timezone := s;
    g_unix_cached_timezone_inited := True;
    Result := g_unix_cached_timezone;
  finally
    _cache_unlock_unix;
  end;
end;
{$ELSE}
var
  f: Text; s: string; linkbuf: array[0..1023] of Char; L, p: Integer;
begin
  s := os_getenv('TZ');
  if s <> '' then Exit(s);
  if FileExists('/etc/timezone') then
  begin
    Assign(f, '/etc/timezone'); {$I-} Reset(f); {$I+}
    if IOResult = 0 then
    begin
      try ReadLn(f, s); finally Close(f); end;
      s := Trim(s);
      if s <> '' then Exit(s);
    end;
  end
  else if FileExists('/etc/TZ') then
  begin
    Assign(f, '/etc/TZ'); {$I-} Reset(f); {$I+}
    if IOResult = 0 then
    begin
      try ReadLn(f, s); finally Close(f); end;
      s := Trim(s);
      if s <> '' then Exit(s);
    end;
  end
  else if FileExists('/etc/sysconfig/clock') then
  begin
    Assign(f, '/etc/sysconfig/clock'); {$I-} Reset(f); {$I+}
    if IOResult = 0 then
    begin
      try
        while not EOF(f) do begin
          ReadLn(f, s);
          p := Pos('ZONE=', s);
          if p = 1 then begin
            s := Trim(StringReplace(Copy(s, 6, MaxInt), '"', '', [rfReplaceAll]));
            if s <> '' then begin Result := s; Exit; end;
          end;
        end;
      finally
        Close(f);
      end;
    end;
  end;
  {$IFDEF UNIX}
  L := fpReadlink('/etc/localtime', @linkbuf[0], SizeOf(linkbuf)-1);
  if L > 0 then
  begin
    linkbuf[L] := #0;
    s := StrPas(@linkbuf[0]);
    p := Pos('zoneinfo/', s);
    if p > 0 then s := Copy(s, p + Length('zoneinfo/'), MaxInt);
  end;
  {$ENDIF}
  Result := s;
end;
{$ENDIF}

function os_timezone_iana: string;
begin
  // Unix: timezone already IANA or empty; return as-is
  Result := os_timezone;
end;


