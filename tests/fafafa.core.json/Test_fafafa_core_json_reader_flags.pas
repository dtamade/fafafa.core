{$CODEPAGE UTF8}
unit Test_fafafa_core_json_reader_flags;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core;

type
  TTestCase_ReaderFlags = class(TTestCase)
  published
    procedure Test_BOM_Allowed;
    procedure Test_BOM_Disallowed;
    procedure Test_Comments_Allowed;
    procedure Test_Trailing_Commas_Object_Array;
    procedure Test_StopWhenDone;
    procedure Test_InfNaN_Allow_Disallow;
    procedure Test_InvalidUnicode_Allow;
    procedure Test_NumberAsRaw;
    procedure Test_BignumAsRaw_Integer_Overflow;
  end;

implementation

procedure TTestCase_ReaderFlags.Test_BOM_Allowed;
var S: AnsiString; Doc: TJsonDocument; Err: TJsonError;
begin
  Err := Default(TJsonError);
  S := AnsiChar($EF) + AnsiChar($BB) + AnsiChar($BF) + '123';
  Doc := JsonReadOpts(PChar(S), Length(S), [jrfAllowBOM], GetRtlAllocator(), Err);
  AssertTrue('doc', Assigned(Doc));
  AssertTrue('num', UnsafeIsNum(Doc.Root));
  Doc.Free;
end;

procedure TTestCase_ReaderFlags.Test_BOM_Disallowed;
var S: AnsiString; Doc: TJsonDocument; Err: TJsonError;
begin
  Err := Default(TJsonError);
  S := AnsiChar($EF) + AnsiChar($BB) + AnsiChar($BF) + 'null';
  Doc := JsonReadOpts(PChar(S), Length(S), [], GetRtlAllocator(), Err);
  AssertTrue('should fail', not Assigned(Doc));
  AssertTrue('err set', Err.Code <> jecSuccess);
end;

procedure TTestCase_ReaderFlags.Test_Comments_Allowed;
var S: AnsiString; Doc: TJsonDocument; Err: TJsonError;
begin
  Err := Default(TJsonError);
  S := '/*head*/ {"a":1, //line'#10'  "b":2}';
  Doc := JsonReadOpts(PChar(S), Length(S), [jrfAllowComments], GetRtlAllocator(), Err);
  AssertTrue(Assigned(Doc));
  AssertTrue(UnsafeIsObj(Doc.Root));
  Doc.Free;
end;

procedure TTestCase_ReaderFlags.Test_Trailing_Commas_Object_Array;
var S: AnsiString; Doc: TJsonDocument; Err: TJsonError;
begin
  Err := Default(TJsonError);
  S := '{"a":1,}';
  Doc := JsonReadOpts(PChar(S), Length(S), [jrfAllowTrailingCommas], GetRtlAllocator(), Err);
  AssertTrue(Assigned(Doc)); Doc.Free;
  S := '[1,2,]';
  Doc := JsonReadOpts(PChar(S), Length(S), [jrfAllowTrailingCommas], GetRtlAllocator(), Err);
  AssertTrue(Assigned(Doc)); Doc.Free;
end;

procedure TTestCase_ReaderFlags.Test_StopWhenDone;
var S: AnsiString; Doc: TJsonDocument; Err: TJsonError;
begin
  Err := Default(TJsonError);
  S := '123 456';
  Doc := JsonReadOpts(PChar(S), Length(S), [jrfStopWhenDone], GetRtlAllocator(), Err);
  AssertTrue(Assigned(Doc));
  Doc.Free;
  Doc := JsonReadOpts(PChar(S), Length(S), [], GetRtlAllocator(), Err);
  AssertTrue('should error extra chars', not Assigned(Doc));
end;

procedure TTestCase_ReaderFlags.Test_InfNaN_Allow_Disallow;
var D: TJsonDocument; E: TJsonError; S: AnsiString;
begin
  E := Default(TJsonError);
  S := 'NaN';
  D := JsonReadOpts(PChar(S), Length(S), [jrfAllowInfAndNaN], GetRtlAllocator(), E);
  AssertTrue(Assigned(D)); D.Free;
  D := JsonReadOpts(PChar(S), Length(S), [], GetRtlAllocator(), E);
  AssertTrue('no NaN allowed', not Assigned(D));
end;

procedure TTestCase_ReaderFlags.Test_InvalidUnicode_Allow;
var S: RawByteString; D: TJsonDocument; E: TJsonError;
begin
  E := Default(TJsonError);
  // 非法 UTF-8：单独高位字节 0xC3 后未跟随
  S := '"'#195'"';
  D := JsonReadOpts(PChar(S), Length(S), [jrfAllowInvalidUnicode], GetRtlAllocator(), E);
  AssertTrue(Assigned(D)); D.Free;
end;

procedure TTestCase_ReaderFlags.Test_NumberAsRaw;
var S: AnsiString; D: TJsonDocument; E: TJsonError;
begin
  E := Default(TJsonError);
  S := '12345';
  D := JsonReadOpts(PChar(S), Length(S), [jrfNumberAsRaw], GetRtlAllocator(), E);
  AssertTrue(Assigned(D));
  AssertTrue('raw', UnsafeGetType(D.Root) = YYJSON_TYPE_RAW);
  D.Free;
end;

procedure TTestCase_ReaderFlags.Test_BignumAsRaw_Integer_Overflow;
var S: AnsiString; D: TJsonDocument; E: TJsonError;
begin
  E := Default(TJsonError);
  S := '184467440737095516160'; // 超过 uint64 最大值，整数且无小数/指数
  D := JsonReadOpts(PChar(S), Length(S), [jrfBignumAsRaw], GetRtlAllocator(), E);
  AssertTrue(Assigned(D));
  AssertTrue('raw', UnsafeGetType(D.Root) = YYJSON_TYPE_RAW);
  D.Free;
end;

initialization
  RegisterTest(TTestCase_ReaderFlags);
end.

