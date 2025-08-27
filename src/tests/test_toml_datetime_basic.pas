unit test_toml_datetime_basic;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

procedure RegisterTomlDatetimeTests;

implementation

type
  TTomlDatetimeCase = class(TTestCase)
  private
    function GetValueByPath(const Doc: ITomlDocument; const Path: String): ITomlValue;
  published
    procedure Test_Parse_OffsetDateTime_Z_And_Offset;
    procedure Test_Parse_Local_Types;
    procedure Test_Parse_Invalid_OffsetDateTime_Fails;
  end;

function TTomlDatetimeCase.GetValueByPath(const Doc: ITomlDocument; const Path: String): ITomlValue;
var
  T: ITomlTable; V: ITomlValue; Seg: String; P, PEnd: PChar;
begin
  Result := nil;
  if (Doc = nil) or (Doc.GetRoot = nil) then Exit;
  T := Doc.GetRoot;
  P := PChar(Path); PEnd := P + Length(Path); Seg := '';
  while (P < PEnd) and (P^ <> '.') do begin Seg := Seg + P^; Inc(P); end;
  while (P < PEnd) do
  begin
    V := T.GetValue(Seg);
    if (V = nil) or (V.GetType <> tvtTable) then Exit(nil);
    T := (V as ITomlTable);
    Inc(P); Seg := '';
    while (P < PEnd) and (P^ <> '.') do begin Seg := Seg + P^; Inc(P); end;
  end;
  Result := T.GetValue(Seg);
end;

procedure TTomlDatetimeCase.Test_Parse_OffsetDateTime_Z_And_Offset;
var
  Doc: ITomlDocument; Err: TTomlError; V: ITomlValue; S: String;
  Txt: RawByteString;
begin
  // Zulu
  Txt := 'ts1 = 1979-05-27T07:32:00Z' + LineEnding +
         'ts2 = 1979-05-27T07:32:00+07:00';
  FillChar(Err, SizeOf(Err), 0);
  AssertTrue(Parse(Txt, Doc, Err));
  AssertTrue(Doc <> nil);
  V := GetValueByPath(Doc, 'ts1');
  AssertTrue(V <> nil);
  AssertEquals(Ord(tvtOffsetDateTime), Ord(V.GetType));
  AssertTrue(V.TryGetTemporalText(S));
  AssertEquals('1979-05-27T07:32:00Z', S);
  V := GetValueByPath(Doc, 'ts2');
  AssertTrue(V <> nil);
  AssertEquals(Ord(tvtOffsetDateTime), Ord(V.GetType));
  AssertTrue(V.TryGetTemporalText(S));
  AssertEquals('1979-05-27T07:32:00+07:00', S);
  // roundtrip writer smoke
  Txt := ToToml(Doc, []);
  AssertTrue(Pos('1979-05-27T07:32:00Z', String(Txt)) > 0);
  AssertTrue(Pos('1979-05-27T07:32:00+07:00', String(Txt)) > 0);
end;

procedure TTomlDatetimeCase.Test_Parse_Local_Types;
var
  Doc: ITomlDocument; Err: TTomlError; V: ITomlValue; S: String;
  Txt: RawByteString;
begin
  Txt := 'ldt = 1979-05-27T07:32:00' + LineEnding +
         'ld  = 1979-05-27' + LineEnding +
         'lt  = 07:32:00';
  FillChar(Err, SizeOf(Err), 0);
  AssertTrue(Parse(Txt, Doc, Err));
  V := GetValueByPath(Doc, 'ldt');
  AssertTrue(V <> nil);
  AssertEquals(Ord(tvtLocalDateTime), Ord(V.GetType));
  AssertTrue(V.TryGetTemporalText(S));
  AssertEquals('1979-05-27T07:32:00', S);
  V := GetValueByPath(Doc, 'ld');
  AssertTrue(V <> nil);
  AssertEquals(Ord(tvtLocalDate), Ord(V.GetType));
  AssertTrue(V.TryGetTemporalText(S));
  AssertEquals('1979-05-27', S);
  V := GetValueByPath(Doc, 'lt');
  AssertTrue(V <> nil);
  AssertEquals(Ord(tvtLocalTime), Ord(V.GetType));
  AssertTrue(V.TryGetTemporalText(S));
  AssertEquals('07:32:00', S);
end;

procedure TTomlDatetimeCase.Test_Parse_Invalid_OffsetDateTime_Fails;
var
  Doc: ITomlDocument; Err: TTomlError;
  Txt: RawByteString;
begin
  // invalid offset: missing ':' in +0700 should fail
  Txt := 'ts = 1979-05-27T07:32:00+0700';
  FillChar(Err, SizeOf(Err), 0);
  AssertFalse(Parse(Txt, Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure RegisterTomlDatetimeTests;
begin
  RegisterTest('toml-datetime', TTomlDatetimeCase);
end;

end.

