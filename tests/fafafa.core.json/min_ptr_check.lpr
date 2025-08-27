program min_ptr_check;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.json;

var
  Doc: IJsonDocument;
  R: IJsonValue;
  I64: Int64;
  S: String;
begin
  Doc := NewJsonReader().ReadFromString('{"arr":[1,2],"obj":{"k":"v"}}', []);
  R := Doc.Root;
  I64 := JsonGetIntOrDefaultByPtr(R, '/arr/9', -1);
  Writeln('I64=', I64);
  S := JsonGetStrOrDefaultByPtr(R, '/obj/k', 'default');
  Writeln('S=', S);
end.

