program xxh3_empty_smoke;
{$mode objfpc}{$H+}
{$I ../fafafa.core.settings.inc}
uses
  SysUtils, fafafa.core.crypto;
begin
  WriteLn(BytesToHex(XXH3_64Hash(nil, 0)));
end.

