program example_toml;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.toml;

procedure Demo;
var
  Doc: ITomlDocument;
  Err: TTomlError;
  S: RawByteString;
  OutText: RawByteString;
begin
  Err.Clear;
  S := RawByteString('foo = 1' + LineEnding + 'a.b.c = "x"');
  if not Parse(S, Doc, Err) then
  begin
    Writeln('Parse failed: ', Err.Message);
    Exit;
  end;
  Writeln('Parsed. Root keys: ', Doc.Root.KeyCount);
  OutText := ToToml(Doc, [twfSortKeys, twfSpacesAroundEquals, twfPretty]);
  Writeln('Serialized:');
  Writeln(String(OutText));
end;

begin
  Demo;
end.

