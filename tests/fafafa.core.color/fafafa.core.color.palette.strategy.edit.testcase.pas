unit fafafa.core.color.palette.strategy.edit.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_PaletteStrategyEdit = class(TTestCase)
  published
    procedure Test_Edit_Append_Insert_Remove_Clear_Validate;
  end;

implementation

procedure TTestCase_PaletteStrategyEdit.Test_Edit_Append_Insert_Remove_Clear_Validate;
var S: IPaletteStrategy; arr: array[0..1] of color_rgba_t; msg: string; c: color_rgba_t;
begin
  arr[0] := COLOR_RED; arr[1] := COLOR_BLUE;
  S := TPaletteStrategy.CreateEven(PIM_SRGB, arr, True);
  AssertTrue(S.Validate(msg));
  c := COLOR_GREEN;
  S.AppendColor(c);
  S.InsertColor(1, COLOR_WHITE);
  S.RemoveAt(0);
  S.Clear;
  AssertFalse(S.Validate(msg));
end;

initialization
  RegisterTest(TTestCase_PaletteStrategyEdit);

end.

