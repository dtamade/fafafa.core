unit fafafa.core.color.palette.strategy.mode_string.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_PaletteStrategy_ModeString = class(TTestCase)
  published
    procedure Test_Mode_String_OKLCH_OK;
    procedure Test_Mode_String_LINEAR_OK;
    procedure Test_Mode_String_Default_SRGB;
  end;

implementation

procedure TTestCase_PaletteStrategy_ModeString.Test_Mode_String_OKLCH_OK;
var json: string; S: IPaletteStrategy;
begin
  json := '{"mode":"OKLCH","shortest":1,"usePos":0,"norm":0,"colors":["#FF0000","#0000FF"],"positions":[]}';
  AssertTrue(palette_strategy_deserialize(json, S));
  AssertTrue(S<>nil);
end;

procedure TTestCase_PaletteStrategy_ModeString.Test_Mode_String_LINEAR_OK;
var json: string; S: IPaletteStrategy;
begin
  json := '{"mode":"LINEAR","shortest":1,"usePos":0,"norm":0,"colors":["#FF0000","#0000FF"],"positions":[]}';
  AssertTrue(palette_strategy_deserialize(json, S));
  AssertTrue(S<>nil);
end;

procedure TTestCase_PaletteStrategy_ModeString.Test_Mode_String_Default_SRGB;
var json: string; S: IPaletteStrategy;
begin
  json := '{"mode":"UNKNOWN","shortest":1,"usePos":0,"norm":0,"colors":["#FF0000","#0000FF"],"positions":[]}';
  AssertTrue(palette_strategy_deserialize(json, S));
  AssertTrue(S<>nil);
end;

initialization
  RegisterTest(TTestCase_PaletteStrategy_ModeString);

end.

