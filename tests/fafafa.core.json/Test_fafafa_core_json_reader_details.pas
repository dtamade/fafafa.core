{$CODEPAGE UTF8}
unit Test_fafafa_core_json_reader_details;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Math, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core;

type
  TTestCase_ReaderDetails = class(TTestCase)
  published
    procedure Test_String_Escapes_Basic;
    procedure Test_String_Unicode_U4;
    procedure Test_String_Surrogate_Pair_Valid;
    procedure Test_String_Control_Char_Invalid_Unless_Allowed;
    procedure Test_Number_Scientific_Positive;
    procedure Test_Number_Scientific_NegativeSmall;
    procedure Test_Number_Scientific_ZeroExp;
    procedure Test_Number_BignumAsRaw_ExpOverflow;
  end;

implementation

procedure TTestCase_ReaderDetails.Test_String_Escapes_Basic;
var S: AnsiString; D: TJsonDocument; E: TJsonError; V: PJsonValue; Got, Exp: UTF8String;
begin
  E := Default(TJsonError);
  S := '"\\\"\/\b\f\n\r\t"'; // " \ \/ 

 	
  D := JsonReadOpts(PChar(S), Length(S), [jrfDefault], GetRtlAllocator(), E);
  AssertTrue(Assigned(D));
  V := D.Root;
  AssertTrue(UnsafeIsStr(V));
  Got := JsonGetStrUtf8(V);
  Exp := AnsiChar(#92) {\} + AnsiChar(#34) {"} + AnsiChar(#47) {/} +
         AnsiChar(#8) {#8} + AnsiChar(#12) {#12} + AnsiChar(#10) {#10} + AnsiChar(#13) {#13} + AnsiChar(#9) {#9};
  AssertEquals(Exp, Got);
  D.Free;
end;

procedure TTestCase_ReaderDetails.Test_String_Unicode_U4;
var S: AnsiString; D: TJsonDocument; E: TJsonError; V: PJsonValue; Got: UTF8String;
begin
  E := Default(TJsonError);
  S := '"\u0041\u0042"'; // "AB"
  D := JsonReadOpts(PChar(S), Length(S), [], GetRtlAllocator(), E);
  AssertTrue(Assigned(D));
  V := D.Root; AssertTrue(UnsafeIsStr(V));
  Got := JsonGetStrUtf8(V);
  AssertEquals('AB', String(Got));
  D.Free;
end;

procedure TTestCase_ReaderDetails.Test_String_Surrogate_Pair_Valid;
var S: AnsiString; D: TJsonDocument; E: TJsonError; V: PJsonValue; Bytes: TBytes; U: UTF8String;
begin
  Bytes := nil;
  E := Default(TJsonError);
  // U+1D11E (MUSICAL SYMBOL G CLEF) = \uD834\uDD1E (valid surrogate pair)
  S := '"\uD834\uDD1E"';
  D := JsonReadOpts(PChar(S), Length(S), [], GetRtlAllocator(), E);
  AssertTrue(Assigned(D));
  V := D.Root; AssertTrue(UnsafeIsStr(V));
  // UTF-8 should be F0 9D 84 9E
  SetLength(Bytes, 4);
  U := JsonGetStrUtf8(V);
  Move(PAnsiChar(U)^, Bytes[0], 4);
  AssertEquals($F0, Bytes[0]);
  AssertEquals($9D, Bytes[1]);
  AssertEquals($84, Bytes[2]);
  AssertEquals($9E, Bytes[3]);
  D.Free;
end;

procedure TTestCase_ReaderDetails.Test_String_Control_Char_Invalid_Unless_Allowed;
var S: RawByteString; D: TJsonDocument; E: TJsonError;
begin
  E := Default(TJsonError);
  S := '"' + AnsiChar(#1) + '"';
  D := JsonReadOpts(PChar(S), Length(S), [], GetRtlAllocator(), E);
  AssertTrue('should fail without allowInvalidUnicode', not Assigned(D));
  D := JsonReadOpts(PChar(S), Length(S), [jrfAllowInvalidUnicode], GetRtlAllocator(), E);
  AssertTrue('should pass with allowInvalidUnicode', Assigned(D));
  D.Free;
end;

procedure TTestCase_ReaderDetails.Test_Number_Scientific_Positive;
var S: AnsiString; D: TJsonDocument; E: TJsonError; V: PJsonValue;
begin
  E := Default(TJsonError);
  S := '1e10';
  D := JsonReadOpts(PChar(S), Length(S), [], GetRtlAllocator(), E);
  AssertTrue(Assigned(D)); V := D.Root; AssertTrue(UnsafeIsNum(V));
  AssertTrue('approx', SameValue(JsonGetNum(V), 1.0e10, 1e-3));
  D.Free;
end;

procedure TTestCase_ReaderDetails.Test_Number_Scientific_NegativeSmall;
var S: AnsiString; D: TJsonDocument; E: TJsonError; V: PJsonValue;
begin
  E := Default(TJsonError);
  S := '-2.5E-3';
  D := JsonReadOpts(PChar(S), Length(S), [], GetRtlAllocator(), E);
  AssertTrue(Assigned(D)); V := D.Root; AssertTrue(UnsafeIsNum(V));
  AssertTrue('approx', SameValue(JsonGetNum(V), -2.5e-3, 1e-9));
  D.Free;
end;

procedure TTestCase_ReaderDetails.Test_Number_Scientific_ZeroExp;
var S: AnsiString; D: TJsonDocument; E: TJsonError; V: PJsonValue;
begin
  E := Default(TJsonError);
  S := '3e0';
  D := JsonReadOpts(PChar(S), Length(S), [], GetRtlAllocator(), E);
  AssertTrue(Assigned(D)); V := D.Root; AssertTrue(UnsafeIsNum(V));
  AssertTrue('approx', SameValue(JsonGetNum(V), 3.0, 1e-12));
  D.Free;
end;

procedure TTestCase_ReaderDetails.Test_Number_BignumAsRaw_ExpOverflow;
var S: AnsiString; D: TJsonDocument; E: TJsonError; V: PJsonValue;
begin
  E := Default(TJsonError);
  S := '1e309';
  D := JsonReadOpts(PChar(S), Length(S), [jrfBignumAsRaw], GetRtlAllocator(), E);
  AssertTrue(Assigned(D)); V := D.Root;
  AssertEquals('raw', Integer(YYJSON_TYPE_RAW), Integer(UnsafeGetType(V)));
  D.Free;
end;

initialization
  RegisterTest(TTestCase_ReaderDetails);
end.

