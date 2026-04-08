unit fafafa.core.endian.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.endian;

type
  TTestCoreEndian = class(TTestCase)
  published
    procedure Test_NativeEndianness_IsConcrete;
    procedure Test_ResolveEndianness_ResolvesNative;
    procedure Test_IsLittleEndian_And_IsBigEndian_Agree;
    procedure Test_ByteSwap16_32_64;
    procedure Test_ByteSwap_IsInvolution;
  end;

implementation

procedure TTestCoreEndian.Test_NativeEndianness_IsConcrete;
begin
  AssertTrue((NativeEndianness = enLittleEndian) or (NativeEndianness = enBigEndian));
  AssertTrue(NativeEndianness <> enNative);
end;

procedure TTestCoreEndian.Test_ResolveEndianness_ResolvesNative;
begin
  AssertEquals(Ord(NativeEndianness), Ord(ResolveEndianness(enNative)));
  AssertEquals(Ord(enLittleEndian), Ord(ResolveEndianness(enLittleEndian)));
  AssertEquals(Ord(enBigEndian), Ord(ResolveEndianness(enBigEndian)));
end;

procedure TTestCoreEndian.Test_IsLittleEndian_And_IsBigEndian_Agree;
begin
  AssertTrue(IsLittleEndian <> IsBigEndian);
  AssertTrue(IsLittleEndian(enLittleEndian));
  AssertTrue(IsBigEndian(enBigEndian));
end;

procedure TTestCoreEndian.Test_ByteSwap16_32_64;
begin
  AssertEquals(Word($3412), ByteSwap16($1234));
  AssertEquals(DWord($78563412), ByteSwap32($12345678));
  AssertEquals(QWord($8877665544332211), ByteSwap64($1122334455667788));
end;

procedure TTestCoreEndian.Test_ByteSwap_IsInvolution;
begin
  AssertEquals(Word($1234), ByteSwap16(ByteSwap16($1234)));
  AssertEquals(DWord($12345678), ByteSwap32(ByteSwap32($12345678)));
  AssertEquals(QWord($1122334455667788), ByteSwap64(ByteSwap64($1122334455667788)));
end;

initialization
  RegisterTest(TTestCoreEndian);

end.
