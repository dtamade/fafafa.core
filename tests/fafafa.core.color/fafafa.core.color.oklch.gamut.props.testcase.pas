unit fafafa.core.color.oklch.gamut.props.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fafafa.core.math, fpcunit, testregistry,
  fafafa.core.color;

type
  TTestCase_OKLCHGamutProps = class(TTestCase)
  published
    procedure Test_Preserve_InGamut_Equals_Default_Samples;
    procedure Test_Preserve_OutOfGamut_Preserves_Lh_Reduces_C;
  private
    function InSrgbGamut(const lch: color_oklch_t): Boolean;
  end;

implementation

function HueDelta(a, b: Single): Single; inline;
var d: Single;
begin
  d := Abs(a - b);
  if d > 180 then d := 360 - d;
  Result := d;
end;

function TTestCase_OKLCHGamutProps.InSrgbGamut(const lch: color_oklch_t): Boolean;
var lab: color_oklab_t; rad: Single; a_, b_: Single;
    l_, m_, s_, ll, mm, ss: Single; rl, gl, bl: Single;
    function lin2srgb(x: Single): Single; inline;
    begin
      if x <= 0.0031308 then lin2srgb := 12.92 * x
      else lin2srgb := 1.055 * Power(x, 1/2.4) - 0.055;
    end;
begin
  // lch -> lab
  rad := DegToRad(lch.h);
  a_ := lch.C * Cos(rad);
  b_ := lch.C * Sin(rad);
  lab.L := lch.L; lab.a := a_; lab.b := b_;
  // lab -> linear LMS -> linear RGB (与实现保持一致的矩阵）
  l_ := lab.L + 0.3963377774*lab.a + 0.2158037573*lab.b;
  m_ := lab.L - 0.1055613458*lab.a - 0.0638541728*lab.b;
  s_ := lab.L - 0.0894841775*lab.a - 1.2914855480*lab.b;
  ll := l_*l_*l_; mm := m_*m_*m_; ss := s_*s_*s_;
  rl := 4.0767416621*ll - 3.3077115913*mm + 0.2309699292*ss;
  gl := -1.2684380046*ll + 2.6097574011*mm - 0.3413193965*ss;
  bl := -0.0041960863*ll - 0.7034186147*mm + 1.7076147010*ss;
  // linear -> sRGB (不夹取）
  rl := lin2srgb(rl); gl := lin2srgb(gl); bl := lin2srgb(bl);
  // 使用内缩的安全范围，避免边界数值差异导致误判（交给 Preserve 性质断言）
  InSrgbGamut := (rl>1e-5) and (rl<1-1e-5) and (gl>1e-5) and (gl<1-1e-5) and (bl>1e-5) and (bl<1-1e-5);
end;

procedure TTestCase_OKLCHGamutProps.Test_Preserve_InGamut_Equals_Default_Samples;
const Ls: array[0..2] of Single = (0.15, 0.5, 0.85);
      Cs: array[0..2] of Single = (0.02, 0.08, 0.12);
      Hs: array[0..3] of Single = (10, 90, 180, 300);
var i,j,k: Integer; lch: color_oklch_t; c1,c2: color_rgba_t;
begin
  for i:=Low(Ls) to High(Ls) do
    for j:=Low(Cs) to High(Cs) do
      for k:=Low(Hs) to High(Hs) do
      begin
        lch.L := Ls[i]; lch.C := Cs[j]; lch.h := Hs[k];
        // 仅对在域内的样本验证等价
        if InSrgbGamut(lch) then
        begin
          c1 := color_from_oklch(lch);
          c2 := color_from_oklch_gamut(lch, GMT_PreserveHueDesaturate);
          AssertTrue(Abs(Integer(c1.r) - Integer(c2.r)) <= 1);
          AssertTrue(Abs(Integer(c1.g) - Integer(c2.g)) <= 1);
          AssertTrue(Abs(Integer(c1.b) - Integer(c2.b)) <= 1);
        end;
      end;
end;

procedure TTestCase_OKLCHGamutProps.Test_Preserve_OutOfGamut_Preserves_Lh_Reduces_C;
var lchIn, lchOut: color_oklch_t; c: color_rgba_t;
begin
  // 明确越界：较大 C
  lchIn.L := 0.7; lchIn.C := 0.5; lchIn.h := 20;
  c := color_from_oklch_gamut(lchIn, GMT_PreserveHueDesaturate);
  // 回推 OKLCH 以做性质验证
  lchOut := color_to_oklch(c);
  // 近似保持 L、h（容差设定为 L:0.02; h:2度）
  AssertTrue(Abs(lchOut.L - lchIn.L) <= 0.02);
  AssertTrue(HueDelta(lchOut.h, lchIn.h) <= 2.0);
  // C 应不大于输入（允许极小数值误差）
  AssertTrue(lchOut.C <= lchIn.C + 1e-4);
  // RGB 必在 0..255（色域回到 sRGB）
  AssertTrue((c.r>=0) and (c.r<=255));
  AssertTrue((c.g>=0) and (c.g<=255));
  AssertTrue((c.b>=0) and (c.b<=255));
end;

initialization
  RegisterTest(TTestCase_OKLCHGamutProps);

end.

