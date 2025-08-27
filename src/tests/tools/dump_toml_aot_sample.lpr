program dump_toml_aot_sample;

{$mode objfpc}{$H+}
{$I ../fafafa.core.settings.inc}

uses
  SysUtils, fafafa.core.toml;

var
  Txt: RawByteString; Doc: ITomlDocument; Err: TTomlError;
  S1, S2: String;
begin
  Txt := '[[fruit]]' + #10 +
         'name = "apple"' + #10 +
         'tags = ["fresh","sweet"]' + #10 +
         '[[fruit]]' + #10 +
         'name = "banana"' + #10 +
         'tags = ["ripe"]' + #10 +
         '' + #10 +
         '[fruit.info]' + #10 +
         'origin = "earth"' + #10 +
         'prices = [1, 2.5]' + #10;
  Err.Clear;
  if not Parse(Txt, Doc, Err) then begin Writeln('Parse failed: ', Err.ToString); Halt(1); end;
  S1 := String(ToToml(Doc, [twfPretty, twfSortKeys, twfSpacesAroundEquals]));
  S2 := String(ToToml(Doc, []));
  Writeln('---PRETTY SORTED SPACED---');
  Writeln(S1);
  Writeln('---COMPACT---');
  Writeln(S2);
end.

