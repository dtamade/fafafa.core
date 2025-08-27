unit test_json_reader_basic;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.incr;

procedure RegisterTests;

implementation

procedure AssertReadFail(const S: RawByteString; Flags: TJsonReadFlags; 
  const ExpCode: TJsonErrorCode; const ExpMsgSub: AnsiString);
var
  Err: TJsonError;
  Alc: TAllocator;
  Doc: TJsonDocument;
begin
  FillChar(Err, SizeOf(Err), 0);
  FillChar(Alc, SizeOf(Alc), 0);
  Doc := JsonReadOpts(PChar(S), Length(S), Flags, Alc, Err);
  AssertTrue(Doc = nil);
  AssertEquals(Ord(ExpCode), Ord(Err.Code));
  if ExpMsgSub <> '' then
    AssertTrue(Pos(ExpMsgSub, Err.Message) > 0);
end;

procedure Test_Unclosed_Multiline_Comment;
begin
  AssertReadFail('/* abc', [jrfDefault, jrfAllowComments], jecInvalidComment, 'unclosed multiline comment');
end;

procedure Test_Trailing_Comma_Object_Disallow;
begin
  AssertReadFail('{"a":1,}', [jrfDefault], jecJsonStructure, 'trailing comma is not allowed');
end;

procedure Test_Trailing_Comma_Array_Disallow;
begin
  AssertReadFail('[1,]', [jrfDefault], jecJsonStructure, 'trailing comma is not allowed');
end;

procedure Test_UTF16_BOM;
var S: RawByteString;
begin
  // UTF-16BE BOM: FE FF
  S := AnsiChar(#$FE) + AnsiChar(#$FF) + 'x';
  AssertReadFail(S, [jrfDefault], jecUnexpectedCharacter, 'UTF-16 encoding is not supported');
end;

procedure Test_UTF32_BOM;
var S: RawByteString;
begin
  // UTF-32BE BOM: 00 00 FE FF
  S := AnsiChar(#$00) + AnsiChar(#$00) + AnsiChar(#$FE) + AnsiChar(#$FF) + 'x';
  AssertReadFail(S, [jrfDefault], jecUnexpectedCharacter, 'UTF-32 encoding is not supported');
end;

procedure Test_Incr_More_Then_Success;
var
  Buf: array[0..63] of AnsiChar;
  St: PJsonIncrState;
  Err: TJsonError;
  Alc: TAllocator;
  Doc: TJsonDocument;
begin
  FillChar(Buf, SizeOf(Buf), 0);
  FillChar(Err, SizeOf(Err), 0);
  FillChar(Alc, SizeOf(Alc), 0);
  Move('{"a":', Buf, 4);
  St := JsonIncrNew(@Buf[0], SizeOf(Buf), [jrfDefault], Alc);
  Doc := JsonIncrRead(St, 4, Err);
  AssertTrue(Doc = nil);
  AssertEquals(Ord(jecMore), Ord(Err.Code));
  AssertTrue(Pos('need more data', Err.Message) > 0);
  Move('1}', Buf[4], 2);
  Doc := JsonIncrRead(St, 2, Err);
  AssertTrue(Doc <> nil);
  JsonDocFree(Doc);
  JsonIncrFree(St);
end;

procedure RegisterTests;
begin
  RegisterTest('json-reader-basic', @Test_Unclosed_Multiline_Comment);
  RegisterTest('json-reader-basic', @Test_Trailing_Comma_Object_Disallow);
  RegisterTest('json-reader-basic', @Test_Trailing_Comma_Array_Disallow);
  RegisterTest('json-reader-basic', @Test_UTF16_BOM);
  RegisterTest('json-reader-basic', @Test_UTF32_BOM);
  RegisterTest('json-reader-basic', @Test_Incr_More_Then_Success);
end;

end.

