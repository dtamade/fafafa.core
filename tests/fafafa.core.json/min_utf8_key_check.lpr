program min_utf8_key_check;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.json;

var
  Doc: IJsonDocument;
  R, U, V: IJsonValue;
  Key: UTF8String;
begin
  Doc := NewJsonReader().ReadFromString('{"u":{"你好":1}}', []);
  R := Doc.Root;
  U := R.GetObjectValue('u');
  Key := UTF8String('你好');
  Writeln('HasKeyUtf8? ', JsonHasKeyUtf8(U, Key));
  V := JsonGetValueUtf8(U, Key);
  if V<>nil then Writeln('Value=', V.GetInteger) else Writeln('Value nil');
end.

