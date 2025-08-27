program example_capabilities_os;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes,
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

procedure PrintText(const F: TFieldSet);
var
  vd: TOSVersionDetailed;
  totalB, freeB: QWord;
  adm, wsl, cont, ci: Boolean;
begin
  Writeln('=== Capabilities & System Info ===');
  vd := os_os_version_detailed;
  if F.Enabled('version') then
    Writeln('VersionDetailed: ', vd.Name, ' (', vd.VersionString, ' build ', vd.Build, ') codename=', vd.Codename);
  if F.Enabled('kernel') then
    Writeln('Kernel: ', os_kernel_version);
  if F.Enabled('uptime') then
    Writeln('Uptime(s): ', os_uptime);
  if F.Enabled('memory') then
  begin
    if os_memory_info(totalB, freeB) then
      Writeln('Mem: total=', totalB, ' free=', freeB);
  end;
  if F.Enabled('boottime') then
    Writeln('BootTime: ', os_boot_time);
  if F.Enabled('timezone') then
    Writeln('Timezone: ', os_timezone);
  if F.Enabled('cpu') then
    Writeln('CPU model: ', os_cpu_model);
  if F.Enabled('locale') then
    Writeln('Locale: ', os_locale_current);
  if F.Enabled('capabilities') then
  begin
    adm := os_is_admin; wsl := os_is_wsl; cont := os_is_container; ci := os_is_ci;
    Writeln('Admin? ', adm, '  WSL? ', wsl, '  Container? ', cont, '  CI? ', ci);
  end;
end;

procedure PrintJson(const F: TFieldSet; const Pretty: Boolean; const OutputPath: string);
{$IFDEF FPC}
var
  root, vobj, mem, caps: TJSONObject;
  vd: TOSVersionDetailed;
  totalB, freeB: QWord;
  s: string;
  tf: Text;
{$ENDIF}
begin
  {$IFDEF FPC}
  root := TJSONObject.Create;
  try
    vd := os_os_version_detailed;
    if F.Enabled('version') then
    begin
      vobj := TJSONObject.Create;
      vobj.Add('name', vd.Name);
      vobj.Add('version', vd.VersionString);
      vobj.Add('build', vd.Build);
      if vd.Codename <> '' then vobj.Add('codename', vd.Codename);
      if vd.PrettyName <> '' then vobj.Add('prettyName', vd.PrettyName);
      if vd.ID <> '' then vobj.Add('id', vd.ID);
      if vd.IDLike <> '' then vobj.Add('idLike', vd.IDLike);
      root.Add('version', vobj);
    end;
    if F.Enabled('kernel') then root.Add('kernel', os_kernel_version);
    if F.Enabled('uptime') then root.Add('uptime', os_uptime);
    if F.Enabled('memory') then
    begin
      if os_memory_info(totalB, freeB) then
      begin
        mem := TJSONObject.Create;
        mem.Add('total', totalB);
        mem.Add('free', freeB);
        root.Add('memory', mem);
      end;
    end;
    if F.Enabled('boottime') then root.Add('boottime', os_boot_time);
    if F.Enabled('timezone') then root.Add('timezone', os_timezone);
    if F.Enabled('cpu') then root.Add('cpuModel', os_cpu_model);
    if F.Enabled('locale') then root.Add('locale', os_locale_current);
    if F.Enabled('capabilities') then
    begin
      caps := TJSONObject.Create;
      caps.Add('admin', os_is_admin);
      caps.Add('wsl', os_is_wsl);
      caps.Add('container', os_is_container);
      caps.Add('ci', os_is_ci);
      root.Add('capabilities', caps);
    end;
    if Pretty then
      s := root.FormatJSON()
    else
      s := root.AsJSON;
    if OutputPath <> '' then
    begin
      Assign(tf, OutputPath); {$I-} Rewrite(tf); {$I+}
      if IOResult = 0 then
      begin
        try
          Write(tf, s);
        finally
          Close(tf);
        end;
      end
      else
        WriteLn(s);
    end
    else
      WriteLn(s);
  finally
    root.Free;
  end;
  {$ELSE}
  // Fallback: not FPC (rare here). Print nothing or a simple note.
  if OutputPath <> '' then ;
  WriteLn('{"error":"json not supported in this build"}');
  {$ENDIF}
end;

procedure Run;
var
  i: Integer;
  jsonMode, pretty: Boolean;
  fieldsArg, outputPath, a: string;
  F: TFieldSet;
begin
  jsonMode := False; pretty := False; fieldsArg := ''; outputPath := '';
  for i := 1 to ParamCount do
  begin
    a := ParamStr(i);
    if a = '--json' then jsonMode := True
    else if a = '--pretty' then pretty := True
    else if Pos('--fields=', a) = 1 then
      fieldsArg := Copy(a, Length('--fields=')+1, MaxInt)
    else if Pos('--output=', a) = 1 then
      outputPath := Copy(a, Length('--output=')+1, MaxInt)
    else if (a = '--help') or (a = '-h') then
    begin
      Writeln('Usage: example_capabilities [--json] [--pretty] [--fields=version,kernel,uptime,memory,boottime,timezone,cpu,locale,capabilities] [--output=path]');
      Exit;
    end;
  end;

  F := TFieldSet.Create;
  try
    if fieldsArg <> '' then
      F.List.DelimitedText := LowerCase(fieldsArg);
    if jsonMode then
      PrintJson(F, pretty, outputPath)
    else
      PrintText(F);
  finally
    F.Free;
  end;
end;

begin
  Run;
end.

