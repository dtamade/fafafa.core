{$CODEPAGE UTF8}
unit Test_rng_unix;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF UNIX}
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto,
  fafafa.core.crypto.interfaces;
  {$ENDIF}

type
  {$IFDEF UNIX}
  { TTestCase_RNG_Unix }
  TTestCase_RNG_Unix = class(TTestCase)
  published
    procedure Test_Unix_RNG_Smoke_Distribution;
    procedure Test_Unix_RNG_Reset_Burn;
    procedure Test_Unix_RNG_ForceUrandom_And_NonBlocking_Toggles;
    procedure Test_Unix_RNG_ZeroLength;
    {$IFDEF LINUX}
    procedure Test_Linux_RNG_NonBlocking_LargeFill;
    procedure Test_Linux_RNG_Blocking_Mode;
    {$ENDIF}
  end;
  {$ENDIF}

implementation

{$IFDEF UNIX}

procedure SmokeCheck_Distribution(const B: TBytes; out NonZeroRatio: Double);
var I, NonZero: Integer;
begin
  NonZero := 0;
  for I := 0 to High(B) do if B[I] <> 0 then Inc(NonZero);
  if Length(B) = 0 then NonZeroRatio := 0 else NonZeroRatio := NonZero / Length(B);
end;

function CountDistinct(const B: TBytes): Integer;
var I: Integer; Seen: array[0..255] of Boolean;
begin
  FillChar(Seen, SizeOf(Seen), 0);
  for I := 0 to High(B) do Seen[B[I]] := True;
  Result := 0;
  for I := 0 to 255 do if Seen[I] then Inc(Result);
end;

procedure TTestCase_RNG_Unix.Test_Unix_RNG_Smoke_Distribution;
var B: TBytes; R: Double;
begin
  B := GenerateRandomBytes(256);
  AssertEquals(256, Length(B));
  SmokeCheck_Distribution(B, R);
  AssertTrue(Format('non-zero ratio=%.3f', [R]), (R > 0.5) and (R <= 1.0));
  AssertTrue(Format('distinct count=%d', [CountDistinct(B)]), CountDistinct(B) >= 64);
end;

procedure TTestCase_RNG_Unix.Test_Unix_RNG_Reset_Burn;
var R: ISecureRandom; B: TBytes;
begin
  R := GetSecureRandom;
  R.Reset;
  B := R.GetBytes(16);
  AssertEquals(16, Length(B));
  R.Burn;
  B := GenerateRandomBytes(8);
  AssertEquals(8, Length(B));
end;

procedure TTestCase_RNG_Unix.Test_Unix_RNG_ForceUrandom_And_NonBlocking_Toggles;
var
  PrevForce, PrevBlocking: String;
  B: TBytes;
begin
  PrevForce := SysUtils.GetEnvironmentVariable('FAFAFA_CRYPTO_RNG_FORCE_URANDOM');
  PrevBlocking := SysUtils.GetEnvironmentVariable('FAFAFA_CRYPTO_RNG_LINUX_USE_BLOCKING');
  try
    // 强制 urandom 路径
    SysUtils.SetEnvironmentVariable('FAFAFA_CRYPTO_RNG_FORCE_URANDOM', '1');
    B := GenerateRandomBytes(32);
    AssertEquals(32, Length(B));
    // 切换到 getrandom 非阻塞
    SysUtils.SetEnvironmentVariable('FAFAFA_CRYPTO_RNG_FORCE_URANDOM', '0');
    SysUtils.SetEnvironmentVariable('FAFAFA_CRYPTO_RNG_LINUX_USE_BLOCKING', '0');
    B := GenerateRandomBytes(16);
    AssertEquals(16, Length(B));
  finally
    SysUtils.SetEnvironmentVariable('FAFAFA_CRYPTO_RNG_FORCE_URANDOM', PChar(PrevForce));
    SysUtils.SetEnvironmentVariable('FAFAFA_CRYPTO_RNG_LINUX_USE_BLOCKING', PChar(PrevBlocking));
  end;
end;

procedure TTestCase_RNG_Unix.Test_Unix_RNG_ZeroLength;
var B: TBytes;
begin
  B := GenerateRandomBytes(0);
  AssertEquals(0, Length(B));
end;

{$IFDEF LINUX}
procedure TTestCase_RNG_Unix.Test_Linux_RNG_NonBlocking_LargeFill;
var
  PrevForce, PrevBlocking: String;
  B: TBytes;
begin
  PrevForce := SysUtils.GetEnvironmentVariable('FAFAFA_CRYPTO_RNG_FORCE_URANDOM');
  PrevBlocking := SysUtils.GetEnvironmentVariable('FAFAFA_CRYPTO_RNG_LINUX_USE_BLOCKING');
  try
    SysUtils.SetEnvironmentVariable('FAFAFA_CRYPTO_RNG_FORCE_URANDOM', '0');
    SysUtils.SetEnvironmentVariable('FAFAFA_CRYPTO_RNG_LINUX_USE_BLOCKING', '0');
    B := GenerateRandomBytes(4096);
    AssertEquals(4096, Length(B));
  finally
    SysUtils.SetEnvironmentVariable('FAFAFA_CRYPTO_RNG_FORCE_URANDOM', PChar(PrevForce));
    SysUtils.SetEnvironmentVariable('FAFAFA_CRYPTO_RNG_LINUX_USE_BLOCKING', PChar(PrevBlocking));
  end;
end;

procedure TTestCase_RNG_Unix.Test_Linux_RNG_Blocking_Mode;
var
  PrevForce, PrevBlocking: String;
  B: TBytes;
begin
  PrevForce := SysUtils.GetEnvironmentVariable('FAFAFA_CRYPTO_RNG_FORCE_URANDOM');
  PrevBlocking := SysUtils.GetEnvironmentVariable('FAFAFA_CRYPTO_RNG_LINUX_USE_BLOCKING');
  try
    SysUtils.SetEnvironmentVariable('FAFAFA_CRYPTO_RNG_FORCE_URANDOM', '0');
    SysUtils.SetEnvironmentVariable('FAFAFA_CRYPTO_RNG_LINUX_USE_BLOCKING', '1');
    B := GenerateRandomBytes(128);
    AssertEquals(128, Length(B));
  finally
    SysUtils.SetEnvironmentVariable('FAFAFA_CRYPTO_RNG_FORCE_URANDOM', PChar(PrevForce));
    SysUtils.SetEnvironmentVariable('FAFAFA_CRYPTO_RNG_LINUX_USE_BLOCKING', PChar(PrevBlocking));
  end;
end;
{$ENDIF}

initialization
  RegisterTest(TTestCase_RNG_Unix);

{$ENDIF}

end.

