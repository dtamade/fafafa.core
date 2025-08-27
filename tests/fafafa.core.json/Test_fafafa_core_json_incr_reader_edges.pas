{$CODEPAGE UTF8}
unit Test_fafafa_core_json_incr_reader_edges;

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.incr;

type
  TTestCase_IncrReader_Edges = class(TTestCase)
  published
    procedure Test_Incr_StringEscapes_CrossChunk;
    procedure Test_Incr_UTF8_Multibyte_CrossChunk;
    procedure Test_Incr_LargeNumber_CrossChunk;
    procedure Test_Incr_Comments_TrailingCommas_WithFlags;
  end;

implementation

procedure TTestCase_IncrReader_Edges.Test_Incr_StringEscapes_CrossChunk;
var Al: TAllocator; Err: TJsonError; Doc: TJsonDocument; St: PJsonIncrState;
    Buf: AnsiString; Mem: PAnsiChar; Len: SizeUInt; Cut1, Cut2: SizeUInt; Root, V: PJsonValue;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  // String with escapes and \u sequence; we will split inside the escape
  // Note: In Pascal string literal, backslash is not an escape character. A single '\u' yields one backslash + 'u' in JSON.
  Buf := '{"s":"ab\u0041cd"}'; // "ab\u0041cd" -> A
  Len := Length(Buf); GetMem(Mem, Len); Move(PChar(Buf)^, Mem^, Len);
  St := JsonIncrNew(Mem, Len, [], Al);
  AssertTrue(Assigned(St));
  // Choose a cut inside the \u sequence: position at the 'u00' boundary
  // Find index of '\u' (single backslash in Pascal literal)
  Cut1 := Pos('\u', Buf);
  AssertTrue(Cut1 > 0);
  // Feed up to just after "\u00"
  Cut2 := Cut1 + 3; // \u0 -> index is 1-based; feeding partial escape
  Doc := JsonIncrRead(St, Cut2, Err);
  AssertTrue('Should need more data before completing string escapes', Doc = nil);
  AssertEquals(Ord(jecMore), Ord(Err.Code));
  // Feed the rest
  Doc := JsonIncrRead(St, Length(Buf) - Cut2, Err);
  AssertTrue(Assigned(Doc));
  Root := JsonDocGetRoot(Doc);
  AssertTrue(Assigned(Root));
  V := JsonObjGet(Root, 's');
  AssertTrue(Assigned(V));
  AssertTrue(JsonIsStr(V));
  AssertEquals('abAcd', String(JsonGetStr(V)));
  Doc.Free; JsonIncrFree(St); FreeMem(Mem);
end;

procedure TTestCase_IncrReader_Edges.Test_Incr_UTF8_Multibyte_CrossChunk;
var Al: TAllocator; Err: TJsonError; Doc: TJsonDocument; St: PJsonIncrState;
    S, Buf: UTF8String; Mem: PAnsiChar; Len: SizeUInt; Cut: SizeUInt; Root, V: PJsonValue;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  // UTF-8 multibyte characters: 你好 (E4 BD A0 E5 A5 BD)
  // Avoid codepage ambiguities by constructing from explicit UTF-8 bytes
  S := UTF8String(#$E4#$BD#$A0#$E5#$A5#$BD);
  Buf := UTF8String('{"s":"') + S + UTF8String('"}');
  Len := Length(Buf); GetMem(Mem, Len); Move(PAnsiChar(Buf)^, Mem^, Len);
  St := JsonIncrNew(Mem, Len, [], Al);
  AssertTrue(Assigned(St));
  // Cut mid-codepoint: split after first byte of first multibyte char
  Cut := Pos('"s":"', Buf) + Length('"s":"');
  // After opening quote; add 1 to include first byte of multibyte char
  Cut := Cut + 1;
  Doc := JsonIncrRead(St, Cut, Err);
  AssertTrue(Doc = nil);
  AssertEquals(Ord(jecMore), Ord(Err.Code));
  // Feed remainder
  Doc := JsonIncrRead(St, Length(Buf) - Cut, Err);
  AssertTrue(Assigned(Doc));
  Root := JsonDocGetRoot(Doc);
  V := JsonObjGet(Root, 's');
  AssertTrue(Assigned(V));
  AssertTrue(JsonEqualsStrN(V, PChar(S), Length(S)));
  Doc.Free; JsonIncrFree(St); FreeMem(Mem);
end;

procedure TTestCase_IncrReader_Edges.Test_Incr_LargeNumber_CrossChunk;
var Al: TAllocator; Err: TJsonError; Doc: TJsonDocument; St: PJsonIncrState;
    Buf: AnsiString; Mem: PAnsiChar; Len: SizeUInt; Cut: SizeUInt; Root, V: PJsonValue;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  // Large integer within 64-bit range
  Buf := '{"n":1234567890123456789}';
  Len := Length(Buf); GetMem(Mem, Len); Move(PChar(Buf)^, Mem^, Len);
  St := JsonIncrNew(Mem, Len, [], Al);
  AssertTrue(Assigned(St));
  // Split number near the middle
  Cut := Pos('12345678', Buf) + 4; // somewhere mid-number
  Doc := JsonIncrRead(St, Cut, Err);
  AssertTrue(Doc = nil);
  AssertEquals(Ord(jecMore), Ord(Err.Code));
  Doc := JsonIncrRead(St, Length(Buf) - Cut, Err);
  AssertTrue(Assigned(Doc));
  Root := JsonDocGetRoot(Doc);
  V := JsonObjGet(Root, 'n');
  AssertTrue(Assigned(V));
  AssertTrue(JsonIsNum(V));
  AssertEquals(Int64(1234567890123456789), JsonGetSint(V));
  Doc.Free; JsonIncrFree(St); FreeMem(Mem);
end;

procedure TTestCase_IncrReader_Edges.Test_Incr_Comments_TrailingCommas_WithFlags;
var Al: TAllocator; Err: TJsonError; Doc: TJsonDocument; St: PJsonIncrState;
    Buf: AnsiString; Mem: PAnsiChar; Len: SizeUInt; Ch1, Ch2: SizeUInt; Root, Arr, ObjV: PJsonValue;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  // Object+Array with comments and trailing commas (allowed via flags)
  Buf := '{/*c*/"a":[1,2,],"o":{"x":true,},}';
  Len := Length(Buf); GetMem(Mem, Len); Move(PChar(Buf)^, Mem^, Len);
  St := JsonIncrNew(Mem, Len, [jrfAllowComments, jrfAllowTrailingCommas], Al);
  AssertTrue(Assigned(St));
  // Feed in two chunks
  Ch1 := 10; Ch2 := Length(Buf) - Ch1;
  Doc := JsonIncrRead(St, Ch1, Err);
  AssertTrue(Doc = nil);
  AssertEquals(Ord(jecMore), Ord(Err.Code));
  Doc := JsonIncrRead(St, Ch2, Err);
  AssertTrue(Assigned(Doc));
  Root := JsonDocGetRoot(Doc);
  Arr := JsonObjGet(Root, 'a');
  AssertTrue(Assigned(Arr));
  AssertEquals(QWord(2), JsonArrSize(Arr));
  ObjV := JsonObjGet(Root, 'o');
  AssertTrue(Assigned(ObjV));
  AssertEquals(QWord(1), JsonObjSize(ObjV));
  Doc.Free; JsonIncrFree(St); FreeMem(Mem);
end;

initialization
  RegisterTest(TTestCase_IncrReader_Edges);
end.

