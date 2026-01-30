{$CODEPAGE UTF8}
unit Test_rng_contracts;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.crypto,
  fafafa.core.crypto.interfaces,
  TestAssertHelpers;

type
  TTestCase_RNG_Contracts = class(TTestCase)
  private
    procedure Do_InvalidRange; // helper for exception path
  published
    procedure Test_GetBytes_SizeZero_ReturnsEmpty;
    procedure Test_GetBytes_SizePositive_ReturnsExact;
    procedure Test_GetInteger_Range_Equal;
    procedure Test_GetInteger_Range_Invalid_ShouldRaise;
    procedure Test_GetBase64UrlString_LengthAndAlphabet;
    procedure Test_GetHexString_LengthAndAlphabet;
    procedure Test_GetDouble_Range;
    procedure Test_Repeated_GenerateRandomBytes_Different;
  end;

implementation

function IsHex(const S: string): Boolean;
var i: Integer; c: Char;
begin
  Result := True;
  for i := 1 to Length(S) do
  begin
    c := S[i];
    if not (c in ['0'..'9','a'..'f','A'..'F']) then
      Exit(False);
  end;
end;

function IsBase64Url(const S: string): Boolean;
var i: Integer; c: Char;
begin
  Result := True;
  for i := 1 to Length(S) do
  begin
    c := S[i];
    if not (c in ['A'..'Z','a'..'z','0'..'9','-','_']) then
      Exit(False);
  end;
end;

procedure TTestCase_RNG_Contracts.Test_GetBytes_SizeZero_ReturnsEmpty;
var B: TBytes;
begin
  B := GenerateRandomBytes(0);
  AssertEquals(0, Length(B));
end;

procedure TTestCase_RNG_Contracts.Test_GetBytes_SizePositive_ReturnsExact;
var B: TBytes;
begin
  B := GenerateRandomBytes(33);
  AssertEquals(33, Length(B));
end;

procedure TTestCase_RNG_Contracts.Test_GetInteger_Range_Equal;
var X: Integer;
begin
  X := GetSecureRandom.GetInteger(5,5);
  AssertEquals(5, X);
end;

procedure TTestCase_RNG_Contracts.Test_GetInteger_Range_Invalid_ShouldRaise;
begin
  // 使用方法指针断言，兼容不支持匿名函数的编译器分支
  ExpectRaises('invalid range', EInvalidArgument, @Self.Do_InvalidRange);
end;

procedure TTestCase_RNG_Contracts.Test_GetBase64UrlString_LengthAndAlphabet;
var S: string;
begin
  S := GetSecureRandom.GetBase64UrlString(40);
  AssertEquals(40, Length(S));
  AssertTrue('alphabet', IsBase64Url(S));
end;

procedure TTestCase_RNG_Contracts.Test_GetHexString_LengthAndAlphabet;
var S: string;
begin
  S := GetSecureRandom.GetHexString(31);
  AssertEquals(31, Length(S));
  AssertTrue('hex alphabet', IsHex(S));
end;

procedure TTestCase_RNG_Contracts.Test_GetDouble_Range;
var D: Double; i: Integer;
begin
  for i := 1 to 10 do
  begin
    D := GetSecureRandom.GetDouble;
    AssertTrue('0<=D', D >= 0.0);
    AssertTrue('D<1', D < 1.0);
  end;
end;

procedure TTestCase_RNG_Contracts.Test_Repeated_GenerateRandomBytes_Different;
var A,B: TBytes;
begin
  A := GenerateRandomBytes(32);
  B := GenerateRandomBytes(32);
  AssertFalse('A != B likely', ConstantTimeCompare(A, B));
end;

procedure TTestCase_RNG_Contracts.Do_InvalidRange;
begin
  GetSecureRandom.GetInteger(10, 3);
end;

initialization
  RegisterTest(TTestCase_RNG_Contracts);
end.

