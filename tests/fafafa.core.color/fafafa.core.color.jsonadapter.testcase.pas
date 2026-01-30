unit fafafa.core.color.jsonadapter.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.color, fafafa.core.color.jsonadapter;

type
  TTestCase_JSONAdapter = class(TTestCase)
  published
    procedure Test_Deserialize_JSON_Standard_OK;
  end;

implementation

procedure TTestCase_JSONAdapter.Test_Deserialize_JSON_Standard_OK;
var s: string; o: IPaletteStrategy; msg: string;
begin
  s := '{"mode":"OKLCH","shortest":true,"usePos":true,"norm":false,'+
       '"colors":["#FF0000","#00FF00","#0000FF"],"positions":[0,0.2,1]}';
  AssertTrue(palette_strategy_try_deserialize_json(s, o));
  AssertTrue(o<>nil);
  AssertTrue(o.Validate(msg));
end;

initialization
  RegisterTest(TTestCase_JSONAdapter);

end.

