{$CODEPAGE UTF8}
unit Test_fafafa_core_json_incr_reader;

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.incr;

type
  TTestCase_IncrReader = class(TTestCase)
  published
    procedure Test_Incr_FullFeed_Once;
    procedure Test_Incr_Feed_InChunks;
  end;

implementation

procedure TTestCase_IncrReader.Test_Incr_FullFeed_Once;
var Al: TAllocator; Err: TJsonError; Doc: TJsonDocument; S: String;
    St: PJsonIncrState; Buf: String;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  S := '{"a":[1,2,3],"b":{"x":true}}';
  Buf := S; // contiguous buffer
  St := JsonIncrNew(PChar(Buf), Length(Buf), [], Al);
  AssertTrue(Assigned(St));
  Doc := JsonIncrRead(St, Length(Buf), Err);
  AssertTrue(Assigned(Doc));
  AssertTrue(Assigned(JsonDocGetRoot(Doc)));
  AssertEquals(SizeUInt(Length(Buf)), JsonDocGetReadSize(Doc));
  Doc.Free; JsonIncrFree(St);
end;

procedure TTestCase_IncrReader.Test_Incr_Feed_InChunks;
var Al: TAllocator; Err: TJsonError; Doc: TJsonDocument; S: String;
    St: PJsonIncrState; Buf: String; Ch1, Ch2, Ch3: SizeUInt;
begin
  Err := Default(TJsonError);
  Al := GetRtlAllocator();
  S := '{"a":[1,2,3],"b":{"x":true}}';
  Buf := S;
  St := JsonIncrNew(PChar(Buf), Length(Buf), [], Al);
  AssertTrue(Assigned(St));
  // 分三段喂入
  Ch1 := 5; Ch2 := 10; Ch3 := Length(Buf) - (Ch1 + Ch2);
  Doc := JsonIncrRead(St, Ch1, Err); AssertTrue(Doc = nil);
  Doc := JsonIncrRead(St, Ch2, Err); AssertTrue(Doc = nil);
  Doc := JsonIncrRead(St, Ch3, Err); AssertTrue(Assigned(Doc));
  AssertTrue(Assigned(JsonDocGetRoot(Doc)));
  AssertEquals(SizeUInt(Length(Buf)), JsonDocGetReadSize(Doc));
  Doc.Free; JsonIncrFree(St);
end;

initialization
  RegisterTest(TTestCase_IncrReader);
end.

