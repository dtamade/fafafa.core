{ Common cross-platform helpers for fafafa.core.os }

{$IFDEF UNIX}
function _unix_getenv(const AName: string): string; forward;
{$ENDIF}

function os_getenv(const AName: string): string;
begin
  {$IFDEF UNIX}
  Result := _unix_getenv(AName);
  {$ELSE}
  Result := SysUtils.GetEnvironmentVariable(AName);
  {$ENDIF}
end;

