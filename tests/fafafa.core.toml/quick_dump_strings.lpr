program quick_dump_strings;
{$mode objfpc}{$H+}
uses
  SysUtils, fafafa.core.toml;
var
  D: ITomlDocument;
  E: TTomlError;
  S: RawByteString;
begin
  E.Clear;
  if not Parse(RawByteString('s = "a\"b\\c\n\r\t"'), D, E) then
  begin
    Writeln('parse failed: ', E.Message);
    Halt(1);
  end;
  S := ToToml(D, []);
  Writeln('OUTPUT_START');
  Writeln(String(S));
  Writeln('OUTPUT_END');
end.

