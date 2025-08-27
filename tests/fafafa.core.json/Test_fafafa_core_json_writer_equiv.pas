{$CODEPAGE UTF8}
unit Test_fafafa_core_json_writer_equiv;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core;

type
  TTestCase_Json_Writer_Equiv = class(TTestCase)
  private
    function WriteToStreamAsString(Doc: TJsonDocument; Flags: TJsonWriteFlags): String;
  published
    procedure Test_StringVsStream_DefaultFlags;
    procedure Test_StringVsStream_PrettyFlags;
  end;

implementation

function TTestCase_Json_Writer_Equiv.WriteToStreamAsString(Doc: TJsonDocument; Flags: TJsonWriteFlags): String;
var MS: TMemoryStream; S: String;
begin
  Result := '';
  MS := TMemoryStream.Create;
  try
    AssertTrue(JsonWriteToStream(Doc, MS, Flags));
    SetString(S, PChar(MS.Memory), MS.Size);
    Result := S;
  finally
    MS.Free;
  end;
end;

procedure TTestCase_Json_Writer_Equiv.Test_StringVsStream_DefaultFlags;
var D: TJsonDocument; S1, S2: String;
begin
  D := JsonRead(PChar('{"a":1,"b":[true,null,3.14],"s":"x"}'), Length('{"a":1,"b":[true,null,3.14],"s":"x"}'), []);
  try
    AssertTrue(Assigned(D));
    S1 := JsonWriteToString(D, []);
    S2 := WriteToStreamAsString(D, []);
    AssertEquals('string vs stream (compact)', S1, S2);
  finally
    D.Free;
  end;
end;

procedure TTestCase_Json_Writer_Equiv.Test_StringVsStream_PrettyFlags;
var D: TJsonDocument; S1, S2: String;
begin
  D := JsonRead(PChar('{"obj":{"k":"v"},"arr":[1,2,3]}'), Length('{"obj":{"k":"v"},"arr":[1,2,3]}'), []);
  try
    AssertTrue(Assigned(D));
    S1 := JsonWriteToString(D, [jwfPretty]);
    S2 := WriteToStreamAsString(D, [jwfPretty]);
    AssertEquals('string vs stream (pretty)', S1, S2);
  finally
    D.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Json_Writer_Equiv);
end.

