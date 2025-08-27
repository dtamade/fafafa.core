program test_minimal_suite;

{$mode objfpc}{$H+}

uses
  SysUtils;

function ExeDir: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFileDir(ParamStr(0)));
end;

procedure RunOrFail(const NameOnly: string);
var fullExe: string; rc: Integer;
begin
  fullExe := ExeDir + NameOnly;
  if not FileExists(fullExe) then
  begin
    WriteLn('[skip] ', fullExe, ' not found');
    Exit;
  end;
  rc := SysUtils.ExecuteProcess(fullExe, '', []);
  if rc <> 0 then
  begin
    WriteLn('[fail] ', NameOnly, ' rc=', rc);
    Halt(rc);
  end
  else
    WriteLn('[ok]   ', NameOnly);
end;

begin
  try
    WriteLn('== Minimal Suite Runner ==');
    RunOrFail('test_api_aliases.exe');
    RunOrFail('test_oa_tombstone_stress.exe');
    RunOrFail('test_resource_safety_basic.exe');
    WriteLn('.. OK');
  except
    on E: Exception do begin
      WriteLn('FAILED: ', E.Message);
      Halt(1);
    end;
  end;
end.

