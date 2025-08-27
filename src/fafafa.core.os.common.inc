{ Common cross-platform helpers for fafafa.core.os }

function os_getenv(const AName: string): string;
begin
  Result := SysUtils.GetEnvironmentVariable(AName);
end;

