{$CODEPAGE UTF8}
unit fafafa.core.platform.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry,
  fafafa.core.endian,
  fafafa.core.platform;

type
  TTestCorePlatform = class(TTestCase)
  published
    procedure Test_PlatformOS_MatchesBuildTarget;
    procedure Test_PlatformArch_MatchesBuildTarget;
    procedure Test_PlatformPointerWidth_IsStable;
    procedure Test_PlatformEndianness_FollowsEndianUnit;
    procedure Test_PlatformTarget_ComposesStaticFacts;
  end;

implementation

procedure TTestCorePlatform.Test_PlatformOS_MatchesBuildTarget;
begin
  {$IF DEFINED(ANDROID)}
  AssertEquals(Ord(poAndroid), Ord(PlatformOS));
  {$ELSEIF DEFINED(IOS)}
  AssertEquals(Ord(poIOS), Ord(PlatformOS));
  {$ELSEIF DEFINED(WINDOWS)}
  AssertEquals(Ord(poWindows), Ord(PlatformOS));
  {$ELSEIF DEFINED(LINUX)}
  AssertEquals(Ord(poLinux), Ord(PlatformOS));
  {$ELSEIF DEFINED(DARWIN)}
  AssertEquals(Ord(poDarwin), Ord(PlatformOS));
  {$ELSEIF DEFINED(FREEBSD)}
  AssertEquals(Ord(poFreeBSD), Ord(PlatformOS));
  {$ELSE}
  AssertEquals(Ord(poUnknown), Ord(PlatformOS));
  {$ENDIF}
end;

procedure TTestCorePlatform.Test_PlatformArch_MatchesBuildTarget;
begin
  {$IF DEFINED(CPUI386) OR DEFINED(CPUX86)}
  AssertEquals(Ord(paX86), Ord(PlatformArch));
  {$ELSEIF DEFINED(CPUX86_64) OR DEFINED(CPUX64)}
  AssertEquals(Ord(paX64), Ord(PlatformArch));
  {$ELSEIF DEFINED(CPUAARCH64) OR DEFINED(CPUARM64)}
  AssertEquals(Ord(paArm64), Ord(PlatformArch));
  {$ELSEIF DEFINED(CPUARM)}
  AssertEquals(Ord(paArm), Ord(PlatformArch));
  {$ELSEIF DEFINED(CPURISCV64)}
  AssertEquals(Ord(paRiscV64), Ord(PlatformArch));
  {$ELSEIF DEFINED(CPUPPC64)}
  AssertEquals(Ord(paPowerPC64), Ord(PlatformArch));
  {$ELSE}
  AssertEquals(Ord(paUnknown), Ord(PlatformArch));
  {$ENDIF}
end;

procedure TTestCorePlatform.Test_PlatformPointerWidth_IsStable;
begin
  AssertTrue('Pointer width should be 32 or 64', (PlatformPointerBits = 32) or (PlatformPointerBits = 64));
  AssertEquals('PlatformIs64Bit should agree with pointer width', PlatformPointerBits = 64, PlatformIs64Bit);
end;

procedure TTestCorePlatform.Test_PlatformEndianness_FollowsEndianUnit;
begin
  AssertEquals('Platform endianness should match endian unit', Ord(NativeEndianness), Ord(PlatformEndianness));
end;

procedure TTestCorePlatform.Test_PlatformTarget_ComposesStaticFacts;
var
  LTarget: TPlatformTarget;
begin
  LTarget := PlatformTarget;
  AssertEquals('Target.OS should mirror PlatformOS', Ord(PlatformOS), Ord(LTarget.OS));
  AssertEquals('Target.Arch should mirror PlatformArch', Ord(PlatformArch), Ord(LTarget.Arch));
  AssertEquals('Target.PointerBits should mirror PlatformPointerBits', PlatformPointerBits, LTarget.PointerBits);
  AssertEquals('Target.Endianness should mirror PlatformEndianness', Ord(PlatformEndianness), Ord(LTarget.Endianness));
end;

initialization
  RegisterTest(TTestCorePlatform);

end.
