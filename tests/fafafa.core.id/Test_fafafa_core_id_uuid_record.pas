{$CODEPAGE UTF8}
unit Test_fafafa_core_id_uuid_record;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.id, fafafa.core.id.uuid;

type
  TTestCase_UuidRecord = class(TTestCase)
  published
    procedure Test_Parse_Format_Roundtrip;
    procedure Test_Version_Variant;
    procedure Test_Order_Lex;
    procedure Test_Base64Url_Roundtrip;
    procedure Test_NoDash_And_URN_Parse;
    procedure Test_GUID_Roundtrip;
  end;

implementation

procedure TTestCase_UuidRecord.Test_Parse_Format_Roundtrip;
var u1,u2: TUuid; s: string; ok: Boolean;
begin
  u1 := TUuid.NewV7;
  s := u1.ToString;
  ok := TUuid.TryParse(s, u2);
  AssertTrue('try parse', ok);
  AssertEquals('equal string', s, u2.ToString);
end;

procedure TTestCase_UuidRecord.Test_Version_Variant;
var u: TUuid;
begin
  u := TUuid.NewV4;
  AssertTrue('v4', u.IsV4);
  AssertTrue('rfc4122', u.IsRfc4122);
end;

procedure TTestCase_UuidRecord.Test_Order_Lex;
var a,b: TUuid; c: Integer;
begin
  a := TUuid.NewV7;
  b := TUuid.NewV7;
  c := a.CompareLex(b);
  AssertTrue('compare result valid', (c=-1) or (c=0) or (c=1));
end;

procedure TTestCase_UuidRecord.Test_Base64Url_Roundtrip;
var u: TUuid; s: string; u2: TUuid; ok: Boolean;
begin
  u := TUuid.NewV4;
  s := u.ToBase64Url;
  ok := TUuid.TryFromBase64Url(s, u2);
  AssertTrue('TryFromBase64Url', ok);
  AssertEquals('roundtrip string', u.ToString, u2.ToString);
end;

procedure TTestCase_UuidRecord.Test_NoDash_And_URN_Parse;
var u,u2,u3: TUUID; sNo, sUrn: string; ok: Boolean;
begin
  u := TUUID.NewV7;
  sNo := u.ToStringNoDash;
  ok := TUUID.TryParseNoDash(sNo, u2);
  AssertTrue('TryParseNoDash', ok);
  sUrn := 'urn:uuid:' + u.ToString;
  ok := TUUID.TryParseURN(sUrn, u3);
  AssertTrue('TryParseURN', ok);
  AssertEquals('URN==normal', u.ToString, u3.ToString);
end;

procedure TTestCase_UuidRecord.Test_GUID_Roundtrip;
var u: TUUID; g: TGUID; u2: TUUID;
begin
  u := TUUID.NewV4;
  g := u.ToGUID;
  u2 := TUUID.FromGUID(g);
  AssertEquals('guid roundtrip', u.ToString, u2.ToString);
end;


initialization
  RegisterTest('fafafa.core.id.UuidRecord', TTestCase_UuidRecord);
end.

