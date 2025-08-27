unit fafafa.core.color.oklch.gamut.props.extra.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}
{$I testutils.color.tolerances.inc}

interface

uses
  Classes, SysUtils, Math, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_OKLCHGamutProps_Extra = class(TTestCase)
  published
    procedure Test_Preserve_Random_OutOfGamut_Samples;
    procedure Test_Preserve_HueWrap_Endpoints;
  end;

implementation

function HueDelta(a, b: Single): Single; inline;
var d: Single;
begin
  d := Abs(a - b);
  if d > 180 then d := 360 - d;
  Result := d;
end;

function InSrgbByteRange(const c: color_rgba_t): Boolean; inline;
begin
  Result := True; // 字节域检查对 UInt8 无意义，此处保持 True 以聚焦 OKLCH 保真属性
end;

procedure TTestCase_OKLCHGamutProps_Extra.Test_Preserve_Random_OutOfGamut_Samples;
var
  i: Integer;
  L, Ch, H: Single;
  lchIn, lchOut: color_oklch_t;
  c: color_rgba_t;
  seed: LongInt;
begin
  // 固定种子，保证可重复
  seed := 12345;
  RandSeed := seed;
  for i := 1 to 100 do
  begin
    // 生成越界概率较高的样本：较高 C
    L := 0.05 + Random * 0.90;  // [0.05, 0.95]
    Ch := 0.20 + Random * 0.50;  // [0.20, 0.70]
    H := Random * 360.0;        // [0, 360)
    lchIn.L := L; lchIn.C := Ch; lchIn.h := H;

    c := color_from_oklch_gamut(lchIn, GMT_PreserveHueDesaturate);
    lchOut := color_to_oklch(c);

    // 性质：L、h 基本保持；C 不大于输入；结果在 sRGB 字节域
    AssertTrue('L preserved within 0.03', Abs(lchOut.L - lchIn.L) <= 0.03);
    // Hue 断言策略：使用共享容差常量
    if lchOut.C < TOL_C_NEAR_GRAY then
    begin
      // skip hue assertion for near-gray outputs
    end
    else if lchIn.L <= TOL_L_VERY_LOW then
      AssertTrue(Format('Hue preserved within %.0f deg (very low L) (L=%.4f C=%.4f h=%.2f -> L''=%.4f C''=%.4f h''=%.2f, Δh=%.3f)',
        [TOL_HUE_VERY_LOW, lchIn.L, lchIn.C, lchIn.h, lchOut.L, lchOut.C, lchOut.h, HueDelta(lchOut.h, lchIn.h)]),
        HueDelta(lchOut.h, lchIn.h) <= TOL_HUE_VERY_LOW)
    else if lchIn.L <= TOL_L_LOW then
      AssertTrue(Format('Hue preserved within %.0f deg (low L) (L=%.4f C=%.4f h=%.2f -> L''=%.4f C''=%.4f h''=%.2f, Δh=%.3f)',
        [TOL_HUE_LOW, lchIn.L, lchIn.C, lchIn.h, lchOut.L, lchOut.C, lchOut.h, HueDelta(lchOut.h, lchIn.h)]),
        HueDelta(lchOut.h, lchIn.h) <= TOL_HUE_LOW)
    else
      AssertTrue(Format('Hue preserved within %.0f deg (L=%.4f C=%.4f h=%.2f -> L''=%.4f C''=%.4f h''=%.2f, Δh=%.3f)',
        [TOL_HUE_NORMAL, lchIn.L, lchIn.C, lchIn.h, lchOut.L, lchOut.C, lchOut.h, HueDelta(lchOut.h, lchIn.h)]),
        HueDelta(lchOut.h, lchIn.h) <= TOL_HUE_NORMAL);
    AssertTrue('C does not increase', lchOut.C <= lchIn.C + 1e-4);
    AssertTrue('RGB in byte range', InSrgbByteRange(c));
  end;
end;

procedure TTestCase_OKLCHGamutProps_Extra.Test_Preserve_HueWrap_Endpoints;
var
  lchIn, lchOut: color_oklch_t;
  c: color_rgba_t;
begin
  // h 接近 360 -> 0 的环绕边界
  lchIn.L := 0.7; lchIn.C := 0.45; lchIn.h := 359.5;
  c := color_from_oklch_gamut(lchIn, GMT_PreserveHueDesaturate);
  lchOut := color_to_oklch(c);
  AssertTrue('L preserved within 0.02', Abs(lchOut.L - lchIn.L) <= 0.02);
  AssertTrue('Hue wrap preserved within 2 deg', HueDelta(lchOut.h, lchIn.h) <= 2.0);
  AssertTrue('C does not increase', lchOut.C <= lchIn.C + 1e-4);
  AssertTrue('RGB in byte range', InSrgbByteRange(c));

  // h 接近 0 -> 360 的环绕另一侧
  lchIn.L := 0.7; lchIn.C := 0.45; lchIn.h := 0.5;
  c := color_from_oklch_gamut(lchIn, GMT_PreserveHueDesaturate);
  lchOut := color_to_oklch(c);
  AssertTrue('L preserved within 0.02 (low-h)', Abs(lchOut.L - lchIn.L) <= 0.02);
  AssertTrue('Hue wrap preserved within 2 deg (low-h)', HueDelta(lchOut.h, lchIn.h) <= 2.0);
  AssertTrue('C does not increase (low-h)', lchOut.C <= lchIn.C + 1e-4);
  AssertTrue('RGB in byte range (low-h)', InSrgbByteRange(c));
end;

initialization
  RegisterTest(TTestCase_OKLCHGamutProps_Extra);

end.

