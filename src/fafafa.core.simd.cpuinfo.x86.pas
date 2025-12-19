unit fafafa.core.simd.cpuinfo.x86;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.cpuinfo.base;

{$IFDEF SIMD_X86_AVAILABLE}

// x86/x64 CPU feature detection facade
// Provides unified interface for x86 CPUID functionality

function HasCPUID: Boolean; inline;
procedure CPUID(EAX: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord); inline;
procedure CPUIDEX(EAX, ECX_In: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord); inline;
function ReadXCR0: UInt64; inline;

function DetectX86Features: TX86Features; inline;
procedure DetectX86VendorAndModel(var cpuInfo: TCPUInfo); inline;
function GetX86CacheInfo: TX86CacheInfo; inline;
function IsAVXSupportedByOS: Boolean; inline;

// Backward-compat convenience wrappers (used by legacy tests)
function HasSSE: Boolean; inline;
function HasSSE2: Boolean; inline;
function HasAVX: Boolean; inline;
function HasAVX2: Boolean; inline;
function GetVendorString: string; inline;
function GetBrandString: string; inline;

{$ENDIF SIMD_X86_AVAILABLE}

implementation

{$IFDEF SIMD_X86_AVAILABLE}

uses
  {$IFDEF CPUX86_64}
  fafafa.core.simd.cpuinfo.x86.x86_64
  {$ELSEIF DEFINED(CPUI386)}
  fafafa.core.simd.cpuinfo.x86.i386
  {$ENDIF};

// Forward calls to architecture-specific implementation

function HasCPUID: Boolean; inline;
begin
  {$IFDEF CPUX86_64}
  Result := fafafa.core.simd.cpuinfo.x86.x86_64.HasCPUID;
  {$ELSEIF DEFINED(CPUI386)}
  Result := fafafa.core.simd.cpuinfo.x86.i386.HasCPUID;
  {$ENDIF}
end;

procedure CPUID(EAX: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord); inline;
begin
  {$IFDEF CPUX86_64}
  fafafa.core.simd.cpuinfo.x86.x86_64.CPUID(EAX, EAX_Out, EBX_Out, ECX_Out, EDX_Out);
  {$ELSEIF DEFINED(CPUI386)}
  fafafa.core.simd.cpuinfo.x86.i386.CPUID(EAX, EAX_Out, EBX_Out, ECX_Out, EDX_Out);
  {$ENDIF}
end;

procedure CPUIDEX(EAX, ECX_In: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord); inline;
begin
  {$IFDEF CPUX86_64}
  fafafa.core.simd.cpuinfo.x86.x86_64.CPUIDEX(EAX, ECX_In, EAX_Out, EBX_Out, ECX_Out, EDX_Out);
  {$ELSEIF DEFINED(CPUI386)}
  fafafa.core.simd.cpuinfo.x86.i386.CPUIDEX(EAX, ECX_In, EAX_Out, EBX_Out, ECX_Out, EDX_Out);
  {$ENDIF}
end;

function ReadXCR0: UInt64; inline;
begin
  {$IFDEF CPUX86_64}
  Result := fafafa.core.simd.cpuinfo.x86.x86_64.ReadXCR0;
  {$ELSEIF DEFINED(CPUI386)}
  Result := fafafa.core.simd.cpuinfo.x86.i386.ReadXCR0;
  {$ENDIF}
end;

function DetectX86Features: TX86Features; inline;
begin
  {$IFDEF CPUX86_64}
  Result := fafafa.core.simd.cpuinfo.x86.x86_64.DetectX86Features;
  {$ELSEIF DEFINED(CPUI386)}
  Result := fafafa.core.simd.cpuinfo.x86.i386.DetectX86Features;
  {$ENDIF}
end;

procedure DetectX86VendorAndModel(var cpuInfo: TCPUInfo); inline;
begin
  {$IFDEF CPUX86_64}
  fafafa.core.simd.cpuinfo.x86.x86_64.DetectX86VendorAndModel(cpuInfo);
  {$ELSEIF DEFINED(CPUI386)}
  fafafa.core.simd.cpuinfo.x86.i386.DetectX86VendorAndModel(cpuInfo);
  {$ENDIF}
end;

function GetX86CacheInfo: TX86CacheInfo; inline;
begin
  {$IFDEF CPUX86_64}
  Result := fafafa.core.simd.cpuinfo.x86.x86_64.GetX86CacheInfo;
  {$ELSEIF DEFINED(CPUI386)}
  Result := fafafa.core.simd.cpuinfo.x86.i386.GetX86CacheInfo;
  {$ENDIF}
end;

function IsAVXSupportedByOS: Boolean; inline;
begin
  {$IFDEF CPUX86_64}
  Result := fafafa.core.simd.cpuinfo.x86.x86_64.IsAVXSupportedByOS;
  {$ELSEIF DEFINED(CPUI386)}
  Result := fafafa.core.simd.cpuinfo.x86.i386.IsAVXSupportedByOS;
  {$ENDIF}
end;

// Backward-compat wrappers
function HasSSE: Boolean; inline;
var F: TX86Features;
begin
  F := DetectX86Features;
  Result := F.HasSSE;
end;

function HasSSE2: Boolean; inline;
var F: TX86Features;
begin
  F := DetectX86Features;
  Result := F.HasSSE2;
end;

function HasAVX: Boolean; inline;
var F: TX86Features;
begin
  F := DetectX86Features;
  Result := F.HasAVX;
end;

function HasAVX2: Boolean; inline;
var F: TX86Features;
begin
  F := DetectX86Features;
  Result := F.HasAVX2;
end;

function GetVendorString: string; inline;
var
  eax, ebx, ecx, edx: DWord;
  vendor: array[0..12] of AnsiChar;
begin
  eax := 0; ebx := 0; ecx := 0; edx := 0;
  vendor[0] := #0;

  CPUID(0, eax, ebx, ecx, edx);
  Move(ebx, vendor[0], 4);
  Move(edx, vendor[4], 4);
  Move(ecx, vendor[8], 4);
  vendor[12] := #0;
  Result := string(vendor);
end;

function GetBrandString: string; inline;
var
  eax, ebx, ecx, edx: DWord;
  brand: array[0..48] of AnsiChar;
begin
  eax := 0; ebx := 0; ecx := 0; edx := 0;
  brand[0] := #0;
  FillChar(brand, SizeOf(brand), 0);

  CPUID($80000000, eax, ebx, ecx, edx);
  if eax >= $80000004 then
  begin
    eax := 0; ebx := 0; ecx := 0; edx := 0;
    CPUID($80000002, eax, ebx, ecx, edx);
    Move(eax, brand[0], 4);
    Move(ebx, brand[4], 4);
    Move(ecx, brand[8], 4);
    Move(edx, brand[12], 4);

    eax := 0; ebx := 0; ecx := 0; edx := 0;
    CPUID($80000003, eax, ebx, ecx, edx);
    Move(eax, brand[16], 4);
    Move(ebx, brand[20], 4);
    Move(ecx, brand[24], 4);
    Move(edx, brand[28], 4);

    eax := 0; ebx := 0; ecx := 0; edx := 0;
    CPUID($80000004, eax, ebx, ecx, edx);
    Move(eax, brand[32], 4);
    Move(ebx, brand[36], 4);
    Move(ecx, brand[40], 4);
    Move(edx, brand[44], 4);
    Result := string(brand);
  end
  else
    Result := GetVendorString + ' Processor';
end;

{$ENDIF SIMD_X86_AVAILABLE}

end.
