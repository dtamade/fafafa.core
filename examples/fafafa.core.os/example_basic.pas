program example_basic_os;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes, Math,
  {$IFDEF FPC} fpjson {$ENDIF},
  fafafa.core.os;

type
  TFieldSet = class
  public
    List: TStringList;
    constructor Create;
    destructor Destroy; override;
    function Enabled(const Key: string): Boolean; // empty means all enabled
  end;

constructor TFieldSet.Create;
begin
  List := TStringList.Create;
  List.CaseSensitive := False;
  List.Delimiter := ',';
  List.StrictDelimiter := True;
end;

destructor TFieldSet.Destroy;
begin
  List.Free;
  inherited Destroy;
end;

function TFieldSet.Enabled(const Key: string): Boolean;
begin
  if (List.Count = 0) then Exit(True);
  Result := List.IndexOf(LowerCase(Key)) >= 0;
end;


procedure PrintInfo(const F: TFieldSet);
var
  I: Integer;
  L: TStringList;
  Info: TPlatformInfo;
  totalB, freeB: QWord;
  vd: TOSVersionDetailed;
begin
  Info := os_platform_info;
  if F.Enabled('platform') then
  begin
    Writeln('OS: ', Info.OS);
    Writeln('Arch: ', Info.Architecture, ' 64bit:', Info.Is64Bit);
    Writeln('Endian: ', Info.Endianness);
    Writeln('CPU: ', Info.CPUCount, '  PageSize:', Info.PageSize);
    Writeln('Host: ', Info.HostName);
    Writeln('User: ', Info.UserName);
    Writeln('Home: ', Info.HomeDir);
    Writeln('Temp: ', Info.TempDir);
    Writeln('Exe: ', Info.ExePath);
  end;
  Writeln('--- System ---');

  if F.Enabled('kernel') then
    Writeln('Kernel: ', os_kernel_version);
  if F.Enabled('uptime') then
    Writeln('Uptime(s): ', os_uptime);
  if F.Enabled('memory') then
    if os_memory_info(totalB, freeB) then
      Writeln('Mem total: ', totalB, ' free: ', freeB);
  if F.Enabled('boottime') then
    Writeln('Boot time: ', os_boot_time);
  if F.Enabled('timezone') then
    Writeln('Timezone: ', os_timezone);

  if F.Enabled('version') or F.Enabled('cpu') or F.Enabled('locale') then
  begin
    vd := os_os_version_detailed;
    if F.Enabled('version') then
      Writeln('VersionDetailed: ', vd.Name, ' (', vd.VersionString, ' build ', vd.Build, ')');
    if F.Enabled('cpu') then
      Writeln('CPU model: ', os_cpu_model);
    if F.Enabled('locale') then
      Writeln('Locale: ', os_locale_current);
  end;

  if F.Enabled('capabilities') then
  begin
    Writeln('--- Capabilities ---');
    Writeln('Admin? ', os_is_admin, '  WSL? ', os_is_wsl, '  Container? ', os_is_container, '  CI? ', os_is_ci);
  end;

  if F.Enabled('env') then
  begin
    L := TStringList.Create;
    try
      os_environ(L);
      Writeln('Env count: ', L.Count);
      for I := 0 to Min(5, L.Count-1) do
        Writeln('  ', L[I]);
    finally
      L.Free;
    end;
  end;
end;

procedure PrintJson;
{$IFDEF FPC}
var
  root, pinfo, ver, mem, caps: TJSONObject;
  arr: TJSONArray;
  Info: TPlatformInfo;
  vd: TOSVersionDetailed;
  totalB, freeB: QWord;
  L: TStringList;
  i: Integer;
  s: string;
{$ENDIF}
begin
  {$IFDEF FPC}
  root := TJSONObject.Create;
  try
    // platform info
    Info := os_platform_info;
    pinfo := TJSONObject.Create;
    pinfo.Add('os', Info.OS);
    pinfo.Add('arch', Info.Architecture);
    pinfo.Add('is64', Info.Is64Bit);
    pinfo.Add('endian', Info.Endianness);
    pinfo.Add('cpuCount', Info.CPUCount);
    pinfo.Add('pageSize', Info.PageSize);
    pinfo.Add('host', Info.HostName);
    pinfo.Add('user', Info.UserName);
    pinfo.Add('home', Info.HomeDir);
    pinfo.Add('temp', Info.TempDir);
    pinfo.Add('exe', Info.ExePath);
    root.Add('platform', pinfo);

    // version
    vd := os_os_version_detailed;
    ver := TJSONObject.Create;
    ver.Add('name', vd.Name);
    ver.Add('version', vd.VersionString);
    ver.Add('build', vd.Build);
    if vd.Codename <> '' then ver.Add('codename', vd.Codename);
    root.Add('version', ver);

    // system
    root.Add('kernel', os_kernel_version);
    root.Add('uptime', os_uptime);
    if os_memory_info(totalB, freeB) then
    begin
      mem := TJSONObject.Create;
      mem.Add('total', totalB);
      mem.Add('free', freeB);
      root.Add('memory', mem);
    end;
    root.Add('boottime', os_boot_time);
    root.Add('timezone', os_timezone);
    root.Add('cpuModel', os_cpu_model);
    root.Add('locale', os_locale_current);

    // caps
    caps := TJSONObject.Create;
    caps.Add('admin', os_is_admin);
    caps.Add('wsl', os_is_wsl);
    caps.Add('container', os_is_container);
    caps.Add('ci', os_is_ci);
    root.Add('capabilities', caps);

    // env sample
    L := TStringList.Create;
    try
      os_environ(L);
      root.Add('envCount', L.Count);
      arr := TJSONArray.Create;
      for i := 0 to Min(5, L.Count-1) do
        arr.Add(L[i]);
      root.Add('envSample', arr);
    finally
      L.Free;
    end;

    // print
    if (ParamCount >= 2) and ((ParamStr(2) = '--pretty') or (ParamStr(1) = '--pretty')) then
      s := root.FormatJSON()
    else
      s := root.AsJSON;
    WriteLn(s);
  finally
    root.Free;
  end;
  {$ELSE}
  WriteLn('{"error":"json not supported in this build"}');
  {$ENDIF}
end;

procedure Run;
var
  a: string; F: TFieldSet; fieldsArg: string;
begin
  if ParamCount >= 1 then a := ParamStr(1) else a := '';
  if (a = '--help') or (a = '-h') then
  begin
    Writeln('Usage: example_basic [--json] [--pretty] [--fields=platform,version,kernel,uptime,memory,boottime,timezone,cpu,locale,capabilities,env]');
    Writeln('提示：另见 example_strict，演示严格语义变体（os_exe_path_ex/os_home_dir_ex/os_username_ex）。');
    Exit;
  end;
  if (a = '--json') then
    PrintJson
  else
  begin
    // parse optional fields
    if (ParamCount >= 1) and (Pos('--fields=', a) = 1) then
      fieldsArg := Copy(a, Length('--fields=')+1, MaxInt)
    else
      fieldsArg := '';
    F := TFieldSet.Create;
    try
      if fieldsArg <> '' then
        F.List.DelimitedText := LowerCase(fieldsArg);
      PrintInfo(F);
      // demo env set/unset (text mode only)
      if F.Enabled('env') then
      begin
        Writeln('--- Env demo ---');
        if os_setenv('FAFAFA_OS_DEMO', '你好,世界') then
          Writeln('Get env: ', os_getenv('FAFAFA_OS_DEMO'));
        os_unsetenv('FAFAFA_OS_DEMO');
      end;
    finally
      F.Free;
    end;
  end;
end;

begin
  Run;
end.
