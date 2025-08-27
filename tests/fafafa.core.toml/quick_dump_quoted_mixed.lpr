program quick_dump_quoted_mixed;
{$mode objfpc}{$H+}
uses
  SysUtils, fafafa.core.toml;
var
  D: ITomlDocument; E: TTomlError; S: RawByteString;
begin
  E.Clear;
  if not Parse(RawByteString(
    'title = "Q"' + LineEnding +
    '["root table"]' + LineEnding +
    '"a b" = 1' + LineEnding +
    '"q\"t" = "v"' + LineEnding +
    '[[items]]' + LineEnding +
    'name = "i1"' + LineEnding +
    '[[items]]' + LineEnding +
    'name = "i2"' + LineEnding +
    '["root table"."sub table"]' + LineEnding +
    'x = true'
  ), D, E) then
  begin
    Writeln('parse failed: ', E.Message);
    Halt(1);
  end;
  S := ToToml(D, [twfSortKeys, twfSpacesAroundEquals, twfPretty]);
  Writeln('OUTPUT_START');
  Writeln(String(S));
  Writeln('OUTPUT_END');
end.

