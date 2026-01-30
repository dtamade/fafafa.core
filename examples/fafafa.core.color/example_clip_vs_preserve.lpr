program example_clip_vs_preserve;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, Math,
  fafafa.core.color;

procedure PrintRgb(const tag: string; const c: color_rgba_t);
begin
  Write(tag);
  Write(': #');
  Write(IntToHex(c.r,2));
  Write(IntToHex(c.g,2));
  Write(IntToHex(c.b,2));
  Write('  ('); Write(c.r:3); Write(','); Write(c.g:3); Write(','); Write(c.b:3); Write(')');
  WriteLn;
end;

procedure Demo(const L, C: Single; const H: Single);
var lch: color_oklch_t; clipc, pres: color_rgba_t;
begin
  lch.L := L; lch.C := C; lch.h := H;
  WriteLn('Input  OKLCH = (L=', FormatFloat('0.000', L), ', C=', FormatFloat('0.000',C), ', h=', FormatFloat('0.0',H), '°)');
  clipc := color_from_oklch_gamut(lch, GMT_Clip);
  pres := color_from_oklch_gamut(lch, GMT_PreserveHueDesaturate);
  PrintRgb('Clip     ', clipc);
  PrintRgb('Preserve ', pres);
  WriteLn('');
end;

begin
  WriteLn('=== Clip vs Preserve (OKLCH -> sRGB) ===');
  // 越界高饱和案例
  Demo(0.70, 0.45, 20);
  Demo(0.70, 0.50, 220);
  Demo(0.85, 0.40, 350);
  // 接近边界案例
  Demo(0.50, 0.18, 120);
  Demo(0.30, 0.22, 280);
end.

