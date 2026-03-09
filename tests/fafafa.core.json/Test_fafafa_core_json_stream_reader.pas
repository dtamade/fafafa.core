unit Test_fafafa_core_json_stream_reader;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fpcunit,
  testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json,
  fafafa.core.json.core;

type
  TTestCase_JsonStreamReader = class(TTestCase)
  published
    procedure Test_FeedThenTryRead_ShouldReturnDocument;
    procedure Test_TryRead_MultipleDocuments_InSingleFeed;
    procedure Test_Feed_InvalidParameter_ShouldReturnError;
    procedure Test_Feed_Overflow_ShouldReturnInvalidParameter;
    procedure Test_Reset_ShouldClearState;
  end;

implementation

procedure TTestCase_JsonStreamReader.Test_FeedThenTryRead_ShouldReturnDocument;
var
  LReader: IJsonStreamReader;
  LDoc: IJsonDocument;
  LJson: UTF8String;
  LCode: Integer;
  LRoot: IJsonValue;
begin
  LReader := NewJsonStreamReader(256, GetRtlAllocator(), []);
  LJson := UTF8String('{"a":1,"b":true}');

  LCode := LReader.Feed(PChar(LJson), Length(LJson));
  AssertEquals('Feed should succeed', 0, LCode);

  LCode := LReader.TryRead(LDoc);
  AssertEquals('TryRead should succeed', 0, LCode);
  AssertTrue('Doc should be assigned', Assigned(LDoc));

  LRoot := LDoc.GetRoot;
  AssertTrue('Root should be assigned', Assigned(LRoot));
  AssertTrue('Root should be object', LRoot.IsObject);
  AssertTrue('Root should have key a', LRoot.HasObjectKey('a'));
end;

procedure TTestCase_JsonStreamReader.Test_TryRead_MultipleDocuments_InSingleFeed;
var
  LReader: IJsonStreamReader;
  LDoc1: IJsonDocument;
  LDoc2: IJsonDocument;
  LJson: UTF8String;
  LCode: Integer;
begin
  LReader := NewJsonStreamReader(256, GetRtlAllocator(), []);
  LJson := UTF8String('{"a":1}{"b":2}');

  LCode := LReader.Feed(PChar(LJson), Length(LJson));
  AssertEquals('Feed should succeed', 0, LCode);

  LCode := LReader.TryRead(LDoc1);
  AssertEquals('First TryRead should succeed', 0, LCode);
  AssertTrue('First doc should be assigned', Assigned(LDoc1));
  AssertTrue('First doc should contain key a', LDoc1.GetRoot.HasObjectKey('a'));

  LCode := LReader.TryRead(LDoc2);
  AssertEquals('Second TryRead should also succeed', 0, LCode);
  AssertTrue('Second doc should be assigned', Assigned(LDoc2));
  AssertTrue('Second doc should contain key b', LDoc2.GetRoot.HasObjectKey('b'));
end;

procedure TTestCase_JsonStreamReader.Test_Feed_InvalidParameter_ShouldReturnError;
var
  LReader: IJsonStreamReader;
  LJson: UTF8String;
  LCode: Integer;
begin
  LReader := NewJsonStreamReader(32, GetRtlAllocator(), []);
  LJson := UTF8String('{"a":1}');

  LCode := LReader.Feed(nil, 1);
  AssertEquals('nil chunk should be invalid', Ord(jecInvalidParameter), LCode);

  LCode := LReader.Feed(PChar(LJson), 0);
  AssertEquals('zero length should be invalid', Ord(jecInvalidParameter), LCode);
end;

procedure TTestCase_JsonStreamReader.Test_Feed_Overflow_ShouldReturnInvalidParameter;
var
  LReader: IJsonStreamReader;
  LJson: UTF8String;
  LCode: Integer;
begin
  LReader := NewJsonStreamReader(4, GetRtlAllocator(), []);
  LJson := UTF8String('{"a":1}');

  LCode := LReader.Feed(PChar(LJson), Length(LJson));
  AssertEquals('overflow feed should be invalid', Ord(jecInvalidParameter), LCode);
end;

procedure TTestCase_JsonStreamReader.Test_Reset_ShouldClearState;
var
  LReader: IJsonStreamReader;
  LDoc: IJsonDocument;
  LPart: UTF8String;
  LJson: UTF8String;
  LCode: Integer;
begin
  LReader := NewJsonStreamReader(256, GetRtlAllocator(), []);
  LPart := UTF8String('{"a":');

  LCode := LReader.Feed(PChar(LPart), Length(LPart));
  AssertEquals('Feed partial should succeed', 0, LCode);

  LCode := LReader.TryRead(LDoc);
  AssertEquals('Partial data should need more', Ord(jecMore), LCode);

  LReader.Reset;

  LCode := LReader.TryRead(LDoc);
  AssertEquals('After reset without new data should need more', Ord(jecMore), LCode);

  LJson := UTF8String('{"a":1}');
  LCode := LReader.Feed(PChar(LJson), Length(LJson));
  AssertEquals('Feed after reset should succeed', 0, LCode);

  LCode := LReader.TryRead(LDoc);
  AssertEquals('TryRead after reset should succeed', 0, LCode);
  AssertTrue('Doc after reset should be assigned', Assigned(LDoc));
end;

initialization
  RegisterTest(TTestCase_JsonStreamReader);

end.
