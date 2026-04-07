unit fafafa.core.platform;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.endian;

type
  TPlatformOS = (
    poUnknown,
    poWindows,
    poLinux,
    poDarwin,
    poFreeBSD,
    poAndroid,
    poIOS
  );

  TPlatformArch = (
    paUnknown,
    paX86,
    paX64,
    paArm,
    paArm64,
    paRiscV64,
    paPowerPC64
  );

  TPlatformTarget = record
    OS: TPlatformOS;
    Arch: TPlatformArch;
    PointerBits: Byte;
    Endianness: TEndianness;
  end;

function PlatformOS: TPlatformOS; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function PlatformArch: TPlatformArch; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function PlatformPointerBits: Byte; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function PlatformEndianness: TEndianness; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function PlatformIs64Bit: Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function PlatformTarget: TPlatformTarget; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function PlatformOSName(aOS: TPlatformOS): string; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function PlatformArchName(aArch: TPlatformArch): string; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

implementation

function PlatformOS: TPlatformOS;
begin
  {$IF DEFINED(ANDROID)}
  Result := poAndroid;
  {$ELSEIF DEFINED(IOS)}
  Result := poIOS;
  {$ELSEIF DEFINED(WINDOWS)}
  Result := poWindows;
  {$ELSEIF DEFINED(LINUX)}
  Result := poLinux;
  {$ELSEIF DEFINED(DARWIN)}
  Result := poDarwin;
  {$ELSEIF DEFINED(FREEBSD)}
  Result := poFreeBSD;
  {$ELSE}
  Result := poUnknown;
  {$ENDIF}
end;

function PlatformArch: TPlatformArch;
begin
  {$IF DEFINED(CPUI386) OR DEFINED(CPUX86)}
  Result := paX86;
  {$ELSEIF DEFINED(CPUX86_64) OR DEFINED(CPUX64)}
  Result := paX64;
  {$ELSEIF DEFINED(CPUAARCH64) OR DEFINED(CPUARM64)}
  Result := paArm64;
  {$ELSEIF DEFINED(CPUARM)}
  Result := paArm;
  {$ELSEIF DEFINED(CPURISCV64)}
  Result := paRiscV64;
  {$ELSEIF DEFINED(CPUPPC64)}
  Result := paPowerPC64;
  {$ELSE}
  Result := paUnknown;
  {$ENDIF}
end;

function PlatformPointerBits: Byte;
begin
  {$IFDEF CPU64}
  Result := 64;
  {$ELSE}
  Result := 32;
  {$ENDIF}
end;

function PlatformEndianness: TEndianness;
begin
  Result := NativeEndianness;
end;

function PlatformIs64Bit: Boolean;
begin
  Result := PlatformPointerBits = 64;
end;

function PlatformTarget: TPlatformTarget;
begin
  Result.OS := PlatformOS;
  Result.Arch := PlatformArch;
  Result.PointerBits := PlatformPointerBits;
  Result.Endianness := PlatformEndianness;
end;

function PlatformOSName(aOS: TPlatformOS): string;
begin
  case aOS of
    poWindows: Result := 'windows';
    poLinux: Result := 'linux';
    poDarwin: Result := 'darwin';
    poFreeBSD: Result := 'freebsd';
    poAndroid: Result := 'android';
    poIOS: Result := 'ios';
  else
    Result := 'unknown';
  end;
end;

function PlatformArchName(aArch: TPlatformArch): string;
begin
  case aArch of
    paX86: Result := 'x86';
    paX64: Result := 'x86_64';
    paArm: Result := 'arm';
    paArm64: Result := 'aarch64';
    paRiscV64: Result := 'riscv64';
    paPowerPC64: Result := 'ppc64';
  else
    Result := 'unknown';
  end;
end;

end.
