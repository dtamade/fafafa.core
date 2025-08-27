{$CODEPAGE UTF8}
unit test_aligned;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base,

  fafafa.core.mem.allocator;

type
  TTestCase_Aligned = class(TTestCase)
  published
    procedure Test_AllocAligned_Basic;
    procedure Test_AllocAligned_InvalidAlignment;
    procedure Test_AllocAligned_16_Bytes;
    procedure Test_AllocAligned_64_Bytes;
    procedure Test_AllocAligned_128_Bytes;

  end;

implementation

procedure TTestCase_Aligned.Test_AllocAligned_Basic;
var
  P: Pointer;
begin
  P := GetRtlAllocator.AllocAligned(128, 32);
  try
    AssertTrue('AllocAligned should return non-nil', P <> nil);
    AssertEquals('Pointer should be 32-byte aligned', 0, PtrUInt(P) and (32-1));
  finally
    GetRtlAllocator.FreeAligned(P);
  end;
end;

procedure TTestCase_Aligned.Test_AllocAligned_InvalidAlignment;
begin
  AssertException(EInvalidArgument, procedure begin GetRtlAllocator.AllocAligned(64, 3); end);
end;

procedure TTestCase_Aligned.Test_AllocAligned_16_Bytes;
var
  P: Pointer;
begin
  P := GetRtlAllocator.AllocAligned(256, 16);
  try
    AssertTrue('AllocAligned(256,16) should return non-nil', P <> nil);
    AssertEquals('Pointer should be 16-byte aligned', 0, PtrUInt(P) and (16-1));
  finally
    GetRtlAllocator.FreeAligned(P);
  end;
end;

procedure TTestCase_Aligned.Test_AllocAligned_64_Bytes;
var
  P: Pointer;
begin
  P := GetRtlAllocator.AllocAligned(512, 64);
  try
    AssertTrue('AllocAligned(512,64) should return non-nil', P <> nil);
    AssertEquals('Pointer should be 64-byte aligned', 0, PtrUInt(P) and (64-1));
  finally
    GetRtlAllocator.FreeAligned(P);
  end;
end;

procedure TTestCase_Aligned.Test_AllocAligned_128_Bytes;
var
  P: Pointer;
begin
  P := GetRtlAllocator.AllocAligned(1024, 128);
  try
    AssertTrue('AllocAligned(1024,128) should return non-nil', P <> nil);
    AssertEquals('Pointer should be 128-byte aligned', 0, PtrUInt(P) and (128-1));
  finally
    GetRtlAllocator.FreeAligned(P);
  end;
end;



initialization
  RegisterTest(TTestCase_Aligned);

end.

