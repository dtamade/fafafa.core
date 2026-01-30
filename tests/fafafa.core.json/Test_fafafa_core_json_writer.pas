{$CODEPAGE UTF8}
unit Test_fafafa_core_json_writer;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core;

type
  TTestCase_Writer = class(TTestCase)
  published
    procedure Test_Write_Primitives;
    procedure Test_Write_String_Escapes_And_Unicode;
    procedure Test_Write_Pretty_Array_Object;
    procedure Test_Write_Slashes_Escape_Flag;
    procedure Test_Write_InfNaN_Allow_AsNull_Error;
  end;

implementation

procedure TTestCase_Writer.Test_Write_Primitives;
var Doc: TJsonDocument; Err: TJsonError; Len: SizeUInt; WErr: TJsonWriteError; OutBuf: PChar;
    S: String;
begin
  Err := Default(TJsonError);
  WErr := Default(TJsonWriteError);
  Len := 0;
  S := '';
  OutBuf := nil;
  Doc := JsonReadOpts('123', 3, [], GetRtlAllocator(), Err); AssertTrue(Assigned(Doc));
  OutBuf := JsonWriteOpts(Doc, [], GetRtlAllocator(), Len, WErr); AssertTrue(Assigned(OutBuf));
  SetString(S, OutBuf, Len); AssertEquals('123', S); GetRtlAllocator().FreeMem(OutBuf); Doc.Free;

  Doc := JsonReadOpts('true', 4, [], GetRtlAllocator(), Err); AssertTrue(Assigned(Doc));
  OutBuf := JsonWriteOpts(Doc, [], GetRtlAllocator(), Len, WErr); SetString(S, OutBuf, Len); AssertEquals('true', S); GetRtlAllocator().FreeMem(OutBuf); Doc.Free;

  Doc := JsonReadOpts('"hi"', 4, [], GetRtlAllocator(), Err); AssertTrue(Assigned(Doc));
  OutBuf := JsonWriteOpts(Doc, [], GetRtlAllocator(), Len, WErr); SetString(S, OutBuf, Len); AssertEquals('"hi"', S); GetRtlAllocator().FreeMem(OutBuf); Doc.Free;
end;

procedure TTestCase_Writer.Test_Write_String_Escapes_And_Unicode;
var Doc: TJsonDocument; Err: TJsonError; Len: SizeUInt; WErr: TJsonWriteError; OutBuf: PChar; S, SIn: AnsiString;
begin
  Err := Default(TJsonError);
  WErr := Default(TJsonWriteError);
  Len := 0;
  OutBuf := nil;
  S := '';
  SIn := '"\\\"\/\b\f\n\r\t"';
  Doc := JsonReadOpts(PChar(SIn), Length(SIn), [], GetRtlAllocator(), Err);
  OutBuf := JsonWriteOpts(Doc, [jwfEscapeSlashes], GetRtlAllocator(), Len, WErr);
  SetString(S, OutBuf, Len);
  AssertEquals('"\\\"\/\b\f\n\r\t"', S);
  GetRtlAllocator().FreeMem(OutBuf); Doc.Free;

  // Unicode：中文“汉” U+6C49，默认不强制 \\u 转义；开启 EscapeUnicode 则输出 \uXXXX
  SIn := '"汉"';
  Doc := JsonReadOpts(PChar(SIn), Length(SIn), [], GetRtlAllocator(), Err);
  // 直写路径使用 round-trip 验证，避免平台编码差异
  OutBuf := JsonWriteOpts(Doc, [], GetRtlAllocator(), Len, WErr);
  SetString(S, OutBuf, Len);
  GetRtlAllocator().FreeMem(OutBuf);
  // 再读回验证值一致
  Doc.Free; Doc := JsonReadOpts(PChar(S), Length(S), [], GetRtlAllocator(), Err);
  OutBuf := JsonWriteOpts(Doc, [jwfEscapeUnicode], GetRtlAllocator(), Len, WErr);
  SetString(S, OutBuf, Len);
  AssertEquals('"\u6C49"', S);
  GetRtlAllocator().FreeMem(OutBuf);
  OutBuf := JsonWriteOpts(Doc, [jwfEscapeUnicode], GetRtlAllocator(), Len, WErr); SetString(S, OutBuf, Len);
  AssertEquals('"\u6C49"', S); GetRtlAllocator().FreeMem(OutBuf); Doc.Free;
end;

procedure TTestCase_Writer.Test_Write_Pretty_Array_Object;
var Doc: TJsonDocument; Err: TJsonError; Len: SizeUInt; WErr: TJsonWriteError; OutBuf: PChar; S: String;
begin
  Err := Default(TJsonError);
  WErr := Default(TJsonWriteError);
  Len := 0;
  OutBuf := nil;
  S := '';
  Doc := JsonReadOpts('[1,2]', 5, [], GetRtlAllocator(), Err);
  OutBuf := JsonWriteOpts(Doc, [jwfPretty], GetRtlAllocator(), Len, WErr);
  SetString(S, OutBuf, Len);
  AssertTrue(Pos('[', S) = 1);
  AssertTrue(Pos(#13#10 + '  2' + #13#10 + ']', S) > 0);
  GetRtlAllocator().FreeMem(OutBuf); Doc.Free;

  Doc := JsonReadOpts('{"a":1,"b":2}', 13, [], GetRtlAllocator(), Err);
  OutBuf := JsonWriteOpts(Doc, [jwfPretty], GetRtlAllocator(), Len, WErr);
  SetString(S, OutBuf, Len);
  AssertTrue(Pos('{' + LineEnding + '  "a": 1,' + LineEnding + '  "b": 2' + LineEnding + '}', S) > 0);
  GetRtlAllocator().FreeMem(OutBuf); Doc.Free;
end;

procedure TTestCase_Writer.Test_Write_Slashes_Escape_Flag;
var Doc: TJsonDocument; Err: TJsonError; Len: SizeUInt; WErr: TJsonWriteError; OutBuf: PChar; S: String;
begin
  Err := Default(TJsonError);
  WErr := Default(TJsonWriteError);
  Len := 0;
  OutBuf := nil;
  S := '';
  Doc := JsonReadOpts('"a/b"', 5, [], GetRtlAllocator(), Err);
  OutBuf := JsonWriteOpts(Doc, [], GetRtlAllocator(), Len, WErr); SetString(S, OutBuf, Len);
  AssertEquals('"a/b"', S); GetRtlAllocator().FreeMem(OutBuf);
  OutBuf := JsonWriteOpts(Doc, [jwfEscapeSlashes], GetRtlAllocator(), Len, WErr); SetString(S, OutBuf, Len);
  AssertEquals('"a\/b"', S); GetRtlAllocator().FreeMem(OutBuf); Doc.Free;
end;

procedure TTestCase_Writer.Test_Write_InfNaN_Allow_AsNull_Error;
var Err: TJsonError; Doc: TJsonDocument; OutBuf: PChar; Len: SizeUInt; WErr: TJsonWriteError; S: String;
begin
  Err := Default(TJsonError);
  WErr := Default(TJsonWriteError);
  Len := 0;
  OutBuf := nil;
  S := '';
  // 允许 Inf/NaN：文本形式 Infinity/-Infinity/NaN
  Doc := JsonReadOpts('NaN', 3, [jrfAllowInfAndNan], GetRtlAllocator(), Err); AssertTrue(Assigned(Doc));
  OutBuf := JsonWriteOpts(Doc, [jwfAllowInfAndNan], GetRtlAllocator(), Len, WErr); SetString(S, OutBuf, Len);
  AssertEquals('NaN', S); GetRtlAllocator().FreeMem(OutBuf); Doc.Free;

  Doc := JsonReadOpts('Infinity', 8, [jrfAllowInfAndNan], GetRtlAllocator(), Err); AssertTrue(Assigned(Doc));
  OutBuf := JsonWriteOpts(Doc, [jwfAllowInfAndNan], GetRtlAllocator(), Len, WErr); SetString(S, OutBuf, Len);
  AssertEquals('Infinity', S); GetRtlAllocator().FreeMem(OutBuf); Doc.Free;

  // 作为 null 输出
  Doc := JsonReadOpts('NaN', 3, [jrfAllowInfAndNan], GetRtlAllocator(), Err); AssertTrue(Assigned(Doc));
  OutBuf := JsonWriteOpts(Doc, [jwfInfAndNanAsNull], GetRtlAllocator(), Len, WErr); SetString(S, OutBuf, Len);
  AssertEquals('null', S); GetRtlAllocator().FreeMem(OutBuf); Doc.Free;

  // 非允许且非 as-null：应返回错误（jwecNanOrInf）
  Doc := JsonReadOpts('NaN', 3, [jrfAllowInfAndNan], GetRtlAllocator(), Err); AssertTrue(Assigned(Doc));
  OutBuf := JsonWriteOpts(Doc, [], GetRtlAllocator(), Len, WErr);
  AssertTrue('should fail', not Assigned(OutBuf));
  AssertEquals(Ord(jwecNanOrInf), Ord(WErr.Code));
  Doc.Free;
end;

initialization
  RegisterTest(TTestCase_Writer);
end.

