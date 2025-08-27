program simple_json_string_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core;

var
  GTotal, GPass, GFail: Integer;

procedure AssertTrue(const Msg: string; Cond: Boolean);
begin
  Inc(GTotal);
  if Cond then begin
    Inc(GPass);
    WriteLn('✓ ', Msg);
  end else begin
    Inc(GFail);
    WriteLn('✗ ', Msg);
  end;
end;

procedure AssertEqualsStr(const Msg, Expected, Actual: string);
begin
  Inc(GTotal);
  if Expected = Actual then begin
    Inc(GPass);
    WriteLn('✓ ', Msg);
  end else begin
    Inc(GFail);
    WriteLn('✗ ', Msg, ' - Expected="', Expected, '", Actual="', Actual, '"');
  end;
end;

procedure AssertEqualsInt(const Msg: string; Expected, Actual: SizeUInt);
begin
  Inc(GTotal);
  if Expected = Actual then begin
    Inc(GPass);
    WriteLn('✓ ', Msg);
  end else begin
    Inc(GFail);
    WriteLn('✗ ', Msg, ' - Expected=', Expected, ', Actual=', Actual);
  end;
end;

function ReadOk(const S: string; out OutStr: string): Boolean;
var
  Doc: TJsonDocument;
  Root: PJsonValue;
begin
  Doc := JsonRead(PChar(S), Length(S), [jrfDefault]);
  Result := Assigned(Doc);
  if Result then try
    Root := JsonDocGetRoot(Doc);
    Result := Assigned(Root) and JsonIsStr(Root);
    if Result then begin
      SetString(OutStr, JsonGetStr(Root), JsonGetLen(Root));
    end;
  finally
    JsonDocFree(Doc);
  end;
end;

function ReadErr(const S: string; out ErrCode: TJsonErrorCode; out ErrMsg: string): Boolean;
var
  Doc: TJsonDocument;
  Alc: TAllocator;
  Err: TJsonError;
begin
  Alc := GetRtlAllocator();
  Doc := JsonReadOpts(PChar(S), Length(S), [jrfDefault], Alc, Err);
  Result := not Assigned(Doc);
  if Result then begin
    ErrCode := Err.Code;
    ErrMsg := Err.Message;
  end else
    JsonDocFree(Doc);
end;

procedure Test_SimpleASCII;
var S, OutStr: string;
begin
  S := '"Hello"';
  AssertTrue('Parse simple ASCII string', ReadOk(S, OutStr));
  AssertEqualsStr('ASCII content ok', 'Hello', OutStr);
  AssertTrue('Length ok', Length(OutStr) = 5);
end;

procedure Test_Escapes;
var S, OutStr, Expect: string;
begin
  // JSON text: a\"b\\c\/_\b\f\n\r\t -> decoded: a"b\c/_ + control chars
  S := '"a\\\"b\\c\/_\b\f\n\r\t"';
  Expect := 'a\"b\c/_' + Chr(8) + Chr(12) + Chr(10) + Chr(13) + Chr(9);
  AssertTrue('Parse escapes', ReadOk(S, OutStr));
  AssertEqualsStr('Escapes content ok', Expect, OutStr);
end;

procedure Test_UnicodeBMP;
var S, OutStr: string;
begin
  S := '"\u0041\u00DF"'; // A, ß
  AssertTrue('Parse unicode BMP', ReadOk(S, OutStr));
  // Verify as UTF-8 bytes: 41 C3 9F
  AssertTrue('Unicode BMP length bytes = 3', Length(OutStr) = 3);
  AssertTrue('Unicode BMP byte[1]=0x41', Ord(OutStr[1]) = $41);
  AssertTrue('Unicode BMP byte[2]=0xC3', Ord(OutStr[2]) = $C3);
  AssertTrue('Unicode BMP byte[3]=0x9F', Ord(OutStr[3]) = $9F);
end;

procedure Test_SurrogatePair;
var S, OutStr: string;
begin
  // U+1D11E MUSICAL SYMBOL G CLEF: \uD834\uDD1E
  S := '"\uD834\uDD1E"';
  AssertTrue('Parse surrogate pair', ReadOk(S, OutStr));
  // Length in UTF-8 is 4 bytes; exact character compare may depend on font, check length >= 1
  AssertTrue('Surrogate pair decoded to UTF-8 length 4', Length(OutStr) = 4);
end;

procedure Test_Error_ControlChar;
var S, Msg: string; Code: TJsonErrorCode;
begin
  S := '"abc' + Chr(1) + '"';
  AssertTrue('Detect control char error', ReadErr(S, Code, Msg));
end;

procedure Test_Error_UnterminatedEscape;
var S, Msg: string; Code: TJsonErrorCode;
begin
  S := '"abc\\'; // "abc\
  AssertTrue('Detect unterminated escape', ReadErr(S, Code, Msg));
end;

procedure Test_Error_NoLowSurrogate;
var S, Msg: string; Code: TJsonErrorCode;
begin
  S := '"\uD834X"';
  AssertTrue('Detect missing low surrogate', ReadErr(S, Code, Msg));
end;

procedure Test_Error_InvalidLowSurrogate;
var S, Msg: string; Code: TJsonErrorCode;
begin
  S := '"\uD834\u0041"';
  AssertTrue('Detect invalid low surrogate', ReadErr(S, Code, Msg));
end;

procedure RunAll;
begin
  Test_SimpleASCII;
  Test_Escapes;
  Test_UnicodeBMP;
  Test_SurrogatePair;
  Test_Error_ControlChar;
  Test_Error_UnterminatedEscape;
  Test_Error_NoLowSurrogate;
  Test_Error_InvalidLowSurrogate;
end;

begin
  try
    RunAll;
  except
    on E: Exception do begin
      Inc(GFail);
      WriteLn('Exception: ', E.Message);
    end;
  end;
  WriteLn('Total: ', GTotal, ', Pass: ', GPass, ', Fail: ', GFail);
  if GFail <> 0 then Halt(1);
end.

