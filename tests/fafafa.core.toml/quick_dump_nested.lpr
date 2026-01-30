program quick_dump_nested;
{$mode objfpc}{$H+}
uses
  SysUtils, fafafa.core.toml;
var
  D: ITomlDocument;
  E: TTomlError;
  S: RawByteString;
begin
  E.Clear;
  if not Parse(RawByteString('m = [[1, 2], [3, 4]]'), D, E) then
  begin
    Writeln('parse failed: ', E.Message);
    Halt(1);
  end;
  S := ToToml(D, [twfSpacesAroundEquals]);
  Writeln('OUTPUT_START');
  WriteLn(String(S));
  Writeln('OUTPUT_END');
end.

