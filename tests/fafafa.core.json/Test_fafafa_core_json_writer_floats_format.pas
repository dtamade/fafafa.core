{$CODEPAGE UTF8}
unit Test_fafafa_core_json_writer_floats_format;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.json.core;

type
  TTestCase_Json_Writer_Floats_Format = class(TTestCase)
  published
    procedure Test_TrailingZeros_Trimmed;
    procedure Test_DecimalPoint_TrimmedWhenZero;
  end;

implementation

procedure TTestCase_Json_Writer_Floats_Format.Test_TrailingZeros_Trimmed;
var D: TJsonDocument; S: String;
begin
  D := JsonRead(PChar('{"x":1.2300000}'), Length('{"x":1.2300000}'), []);
  try
    S := JsonWriteToString(D, []);
    AssertEquals('{"x":1.23}', S);
  finally
    D.Free;
  end;
end;

procedure TTestCase_Json_Writer_Floats_Format.Test_DecimalPoint_TrimmedWhenZero;
var D: TJsonDocument; S: String;
begin
  D := JsonRead(PChar('{"x":0.000}'), Length('{"x":0.000}'), []);
  try
    S := JsonWriteToString(D, []);
    AssertEquals('{"x":0}', S);
  finally
    D.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_Json_Writer_Floats_Format);
end.

