{$CODEPAGE UTF8}
unit Test_rng_windows;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, {$IFDEF MSWINDOWS}Windows,{$ELSE}ctypes,{$ENDIF} fpcunit, testregistry,
  fafafa.core.crypto,
  fafafa.core.crypto.interfaces;

type
  { TTestCase_RNG_Windows }
  TTestCase_RNG_Windows = class(TTestCase)
  private
    FPrevEnv: String;
    procedure SetEnvLegacy(const AValue: String);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Windows_RNG_ForceLegacy_Roundtrip;
    procedure Test_Windows_RNG_ForceLegacy_Reset_Burn;
    procedure Test_Windows_RNG_ForceLegacy_SmokeDistribution;
  end;

implementation

{$IFNDEF MSWINDOWS}
function setenv(name: PChar; value: PChar; overwrite: cint): cint; cdecl; external 'c' name 'setenv';
{$ENDIF}

procedure TTestCase_RNG_Windows.SetEnvLegacy(const AValue: String);
begin
  // Note: environment variable is read during each GetBytes call
  {$IFDEF MSWINDOWS}
  Windows.SetEnvironmentVariable('FAFAFA_CRYPTO_RNG_FORCE_LEGACY', PChar(AValue));
  {$ELSE}
  setenv('FAFAFA_CRYPTO_RNG_FORCE_LEGACY', PChar(AValue), 1);
  {$ENDIF}
end;

procedure TTestCase_RNG_Windows.SetUp;
begin
  inherited SetUp;
  FPrevEnv := SysUtils.GetEnvironmentVariable('FAFAFA_CRYPTO_RNG_FORCE_LEGACY');
  SetEnvLegacy('1'); // force legacy CryptGenRandom path
end;

procedure TTestCase_RNG_Windows.TearDown;
begin
  // restore previous env
  SetEnvLegacy(FPrevEnv);
  inherited TearDown;
end;

procedure TTestCase_RNG_Windows.Test_Windows_RNG_ForceLegacy_Roundtrip;
var
  B1, B2: TBytes;
begin
  // Force legacy path, then ensure we can still generate bytes and they differ
  B1 := GenerateRandomBytes(32);
  B2 := GenerateRandomBytes(32);
  AssertEquals('len(B1)=32', 32, Length(B1));
  AssertEquals('len(B2)=32', 32, Length(B2));
  AssertFalse('B1 and B2 should differ', SecureCompare(B1, B2));
end;

procedure TTestCase_RNG_Windows.Test_Windows_RNG_ForceLegacy_Reset_Burn;
var
  R: ISecureRandom;
  B: TBytes;
begin
  R := GetSecureRandom;
  // Reset/Burn should not raise and should keep functionality after re-init
  R.Reset;
  B := R.GetBytes(16);
  AssertEquals(16, Length(B));
  R.Burn;
  // After Burn, using the global instance again should re-init on demand
  B := GenerateRandomBytes(8);
  AssertEquals(8, Length(B));
end;

procedure SmokeCheck_Distribution(const B: TBytes; out NonZeroRatio: Double);
var I, NonZero: Integer;
begin
  NonZero := 0;
  for I := 0 to High(B) do if B[I] <> 0 then Inc(NonZero);
  if Length(B) = 0 then NonZeroRatio := 0 else NonZeroRatio := NonZero / Length(B);
end;

function CountDistinct(const B: TBytes): Integer;
var
  I: Integer;
  Seen: array[0..255] of Boolean;
begin
  FillChar(Seen, SizeOf(Seen), 0);
  for I := 0 to High(B) do Seen[B[I]] := True;
  Result := 0;
  for I := 0 to 255 do if Seen[I] then Inc(Result);
end;

procedure TTestCase_RNG_Windows.Test_Windows_RNG_ForceLegacy_SmokeDistribution;
var B: TBytes; R: Double;
begin
  SetEnvLegacy('1');
  B := GenerateRandomBytes(256);
  SmokeCheck_Distribution(B, R);
  // 仅做极轻量烟囱检查：
  // 1) 非零比例应在 (0.5..1.0] 之间（允许偶发全非零）
  // 2) 至少出现 64 种不同字节值（弱下界）
  AssertTrue(Format('non-zero ratio=%.3f', [R]), (R > 0.5) and (R <= 1.0));
  AssertTrue(Format('distinct count=%d', [CountDistinct(B)]), CountDistinct(B) >= 64);
end;


initialization
  RegisterTest(TTestCase_RNG_Windows);

end.

