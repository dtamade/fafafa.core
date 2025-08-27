{$CODEPAGE UTF8}
unit Test_fafafa_core_json_writer_numbers_equiv;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json.core;

Type
  TTestCase_Json_Writer_Numbers_Equiv = class(TTestCase)
  private
    function WriteToStreamAsString(Doc: TJsonDocument; Flags: TJsonWriteFlags): String;
  published
    procedure Test_Int64_UInt64_Equivalence;
    procedure Test_Float_General_Equivalence;
    procedure Test_NaN_Inf_Flags;
  end;

implementation

function TTestCase_Json_Writer_Numbers_Equiv.WriteToStreamAsString(Doc: TJsonDocument; Flags: TJsonWriteFlags): String;
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

procedure TTestCase_Json_Writer_Numbers_Equiv.Test_Int64_UInt64_Equivalence;
var D: TJsonDocument; S1, S2: String;
begin
  D := JsonRead(PChar('{"i":-9223372036854775808,"u":18446744073709551615}'),
                Length('{"i":-9223372036854775808,"u":18446744073709551615}'), []);
  try
    AssertTrue(Assigned(D));
    S1 := JsonWriteToString(D, []);
    S2 := WriteToStreamAsString(D, []);
    AssertEquals('int/uint stream vs string', S1, S2);
  finally
    D.Free;
  end;
end;

procedure TTestCase_Json_Writer_Numbers_Equiv.Test_Float_General_Equivalence;
var D: TJsonDocument; S1, S2: String;
begin
  D := JsonRead(PChar('{"a":0.0,"b":1.23456789012345,"c":1e10,"d":-2.5e-5}'),
                Length('{"a":0.0,"b":1.23456789012345,"c":1e10,"d":-2.5e-5}'), []);
  try
    AssertTrue(Assigned(D));
    S1 := JsonWriteToString(D, []);
    S2 := WriteToStreamAsString(D, []);
    AssertEquals('float stream vs string', S1, S2);
  finally
    D.Free;
  end;
end;

procedure TTestCase_Json_Writer_Numbers_Equiv.Test_NaN_Inf_Flags;
var D: TJsonDocument; S1, S2: String;
begin
  // 测试 j如何在允许NaN/Inf 和 as-null 情况下等价
  D := JsonRead(PChar('{"n":NaN,"p":Infinity,"m":-Infinity}'),
                Length('{"n":NaN,"p":Infinity,"m":-Infinity}'), [jrfAllowInfAndNan]);
  try
    AssertTrue(Assigned(D));
    S1 := JsonWriteToString(D, [jwfAllowInfAndNan]);
    S2 := WriteToStreamAsString(D, [jwfAllowInfAndNan]);
    AssertEquals('allow inf/nan', S1, S2);

    S1 := JsonWriteToString(D, [jwfInfAndNanAsNull]);
    S2 := WriteToStreamAsString(D, [jwfInfAndNanAsNull]);
    AssertEquals('inf/nan as null', S1, S2);
  finally
    D.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Json_Writer_Numbers_Equiv);
end.

