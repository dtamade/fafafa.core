{$CODEPAGE UTF8}
program palette_demo;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.color;

procedure PrintColor(const aTitle: string; const aColor: color_rgba_t);
begin
  WriteLn(aTitle, ': ', color_to_hex(aColor));
end;

function ReadAllText(const aPath: string): string;
var
  LFile: TextFile;
  LLine: string;
  LText: string;
begin
  LText := '';
  AssignFile(LFile, aPath);
  {$I-} Reset(LFile); {$I+}
  if IOResult <> 0 then
    Exit('');

  try
    while not Eof(LFile) do
    begin
      ReadLn(LFile, LLine);
      if LText <> '' then
        LText := LText + LineEnding;
      LText := LText + LLine;
    end;
  finally
    CloseFile(LFile);
  end;

  Result := LText;
end;

procedure BuildDemoColors(out aStartColor, aEndColor: color_rgba_t);
var
  LOklch: color_oklch_t;
begin
  LOklch.L := 0.7;
  LOklch.C := 0.1;
  LOklch.h := 350;
  aStartColor := color_from_oklch(LOklch);

  LOklch.h := 10;
  aEndColor := color_from_oklch(LOklch);
end;

procedure InitPaletteStops(out aColors: array of color_rgba_t);
begin
  aColors[0] := COLOR_RED;
  aColors[1] := COLOR_GREEN;
  aColors[2] := COLOR_BLUE;
end;

procedure DemoMixComparison;
var
  LStartColor: color_rgba_t;
  LEndColor: color_rgba_t;
  LMixSrgb: color_rgba_t;
  LMixLinear: color_rgba_t;
  LMixOklab: color_rgba_t;
  LMixOklch: color_rgba_t;
begin
  BuildDemoColors(LStartColor, LEndColor);

  LMixSrgb := color_mix_srgb(LStartColor, LEndColor, 0.5);
  LMixLinear := color_mix_linear(LStartColor, LEndColor, 0.5);
  LMixOklab := color_mix_oklab(LStartColor, LEndColor, 0.5);
  LMixOklch := color_mix_oklch(LStartColor, LEndColor, 0.5, True);

  WriteLn('== Mix comparison (t=0.5) ==');
  PrintColor('sRGB  ', LMixSrgb);
  PrintColor('Linear', LMixLinear);
  PrintColor('OKLab ', LMixOklab);
  PrintColor('OKLCH ', LMixOklch);
end;

procedure DemoPaletteSampling;
var
  LColors: array[0..2] of color_rgba_t;
  LPalette: color_palette_t;
  LEqualSample: color_rgba_t;
  LPositionSample: color_rgba_t;
  LStructSample: color_rgba_t;
begin
  InitPaletteStops(LColors);
  LPalette := Default(color_palette_t);

  LEqualSample := palette_sample_multi(LColors, 0.6, PIM_SRGB);
  LPositionSample := palette_sample_multi_with_positions(
    LColors,
    [10.0, 20.0, 70.0],
    15.0,
    PIM_SRGB,
    False,
    True
  );

  WriteLn;
  WriteLn('== Palette sampling ==');
  PrintColor('Equal 3-stop t=0.6 (sRGB)', LEqualSample);
  PrintColor('Positions [10,20,70], t=15 norm', LPositionSample);

  palette_init_even(LPalette, PIM_OKLCH, LColors, True);
  LStructSample := palette_sample_struct(LPalette, 0.5);
  PrintColor('Struct API (OKLCH, t=0.5)', LStructSample);
end;

procedure DemoStrategyIO(const aJsonPath: string);
var
  LColors: array[0..2] of color_rgba_t;
  LLoadedStrategy: IPaletteStrategy;
  LLoadedStrategyEx: IPaletteStrategy;
  LStrategy: IPaletteStrategy;
  LDeserialized: IPaletteStrategy;
  LJsonText: string;
  LErrorMessage: string;
begin
  InitPaletteStops(LColors);

  LJsonText := ReadAllText(aJsonPath);
  if LJsonText = '' then
  begin
    WriteLn('Load strategy error: file not found: ', aJsonPath);
    Exit;
  end;

  LLoadedStrategy := palette_strategy_from_text(LJsonText);
  if LLoadedStrategy <> nil then
  begin
    PrintColor('From JSON t=0.2', LLoadedStrategy.Sample(0.2));
    WriteLn('Loaded strategy: count=', LLoadedStrategy.Count, ', mode=', Ord(LLoadedStrategy.Mode));
  end
  else
    WriteLn('Load strategy error: palette_strategy_from_text returned nil');

  if not palette_strategy_from_text_ex(LJsonText, LLoadedStrategyEx, LErrorMessage) then
    WriteLn('Load strategy error: ', LErrorMessage)
  else
    WriteLn('Load strategy ok: count=', LLoadedStrategyEx.Count);

  LStrategy := TPaletteStrategy.CreateWithPositions(
    PIM_OKLCH,
    LColors,
    [0.0, 0.2, 1.0],
    True,
    False
  );
  PrintColor('Strategy Sample t=0.2', LStrategy.Sample(0.2));

  if palette_strategy_deserialize(LStrategy.Serialize, LDeserialized) then
  begin
    PrintColor('Strategy Deserialize t=0.2', LDeserialized.Sample(0.2));
    LDeserialized.AppendColor(COLOR_ORANGE);
    if not LDeserialized.Validate(LErrorMessage) then
    begin
      WriteLn('Validate failed after append: ', LErrorMessage);
      LDeserialized.FixupPositions(True, False);
    end;

    if not LDeserialized.Validate(LErrorMessage) then
      WriteLn('Validate still failed: ', LErrorMessage)
    else
      WriteLn('Validate OK. Colors=', LDeserialized.Count);
  end
  else
    WriteLn('Deserialize failed');
end;

var
  LJsonPath: string;
begin
  LJsonPath := ExpandFileName(
    ExtractFilePath(ParamStr(0)) + '..' + PathDelim + 'examples' + PathDelim +
    'fafafa.core.color' + PathDelim + 'palette_strategy.json'
  );

  DemoMixComparison;
  DemoPaletteSampling;

  WriteLn;
  WriteLn('== Strategy API ==');
  DemoStrategyIO(LJsonPath);
end.
