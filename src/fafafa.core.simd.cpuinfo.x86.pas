unit fafafa.core.simd.cpuinfo.x86;

{$I fafafa.core.settings.inc}
{$ASMMODE INTEL}

interface

{$IFDEF SIMD_X86_AVAILABLE}

uses
  SysUtils,
  fafafa.core.simd.types,
  fafafa.core.simd.cpuinfo.x86.base
  {$IFDEF CPUX86_64}
  , fafafa.core.simd.cpuinfo.x86.x86_64
  {$ELSE}
  , fafafa.core.simd.cpuinfo.x86.i386
  {$ENDIF}
  ;

// === x86/x64 CPU Detection Interface ===

// Check if CPUID instruction is available
function HasCPUID: Boolean;

// Execute CPUID instruction
procedure CPUID(EAX: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);

// Execute CPUID with ECX input (for extended leaves)
procedure CPUIDEX(EAX, ECX_In: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);

// Detect all x86 features
function DetectX86Features: TX86Features;

// Detect x86 vendor and model information
procedure DetectX86VendorAndModel(var cpuInfo: TCPUInfo);

// Check if OS supports AVX (requires XGETBV)
function IsAVXSupportedByOS: Boolean;

// Get x86 cache information
function GetX86CacheInfo: TX86CacheInfo;

// Convenience: vendor/brand strings
function GetVendorString: string;
function GetBrandString: string;

// === Simple feature query helpers (exposed for other units) ===
function HasSSE: Boolean;
function HasSSE2: Boolean;
function HasAVX: Boolean;
function HasAVX2: Boolean;
function HasFMA: Boolean;


implementation

// 门面转发：核心 API 到具体架构实现
function HasCPUID: Boolean;
begin
  {$IFDEF CPUX86_64}
  Result := fafafa.core.simd.cpuinfo.x86.x86_64.HasCPUID;
  {$ELSE}
  Result := fafafa.core.simd.cpuinfo.x86.i386.HasCPUID;
  {$ENDIF}
end;

procedure CPUID(EAX: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);
begin
  {$IFDEF CPUX86_64}
  fafafa.core.simd.cpuinfo.x86.x86_64.CPUID(EAX, EAX_Out, EBX_Out, ECX_Out, EDX_Out);
  {$ELSE}
  fafafa.core.simd.cpuinfo.x86.i386.CPUID(EAX, EAX_Out, EBX_Out, ECX_Out, EDX_Out);
  {$ENDIF}
end;

procedure CPUIDEX(EAX, ECX_In: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);
begin
  {$IFDEF CPUX86_64}
  fafafa.core.simd.cpuinfo.x86.x86_64.CPUIDEX(EAX, ECX_In, EAX_Out, EBX_Out, ECX_Out, EDX_Out);
  {$ELSE}
  fafafa.core.simd.cpuinfo.x86.i386.CPUIDEX(EAX, ECX_In, EAX_Out, EBX_Out, ECX_Out, EDX_Out);
  {$ENDIF}
end;

function DetectX86Features: TX86Features;
begin
  {$IFDEF CPUX86_64}
  Result := fafafa.core.simd.cpuinfo.x86.x86_64.DetectX86Features;
  {$ELSE}
  Result := fafafa.core.simd.cpuinfo.x86.i386.DetectX86Features;
  {$ENDIF}
end;

procedure DetectX86VendorAndModel(var cpuInfo: TCPUInfo);
begin
  {$IFDEF CPUX86_64}
  fafafa.core.simd.cpuinfo.x86.x86_64.DetectX86VendorAndModel(cpuInfo);
  {$ELSE}
  fafafa.core.simd.cpuinfo.x86.i386.DetectX86VendorAndModel(cpuInfo);
  {$ENDIF}
end;

function IsAVXSupportedByOS: Boolean;
begin
  {$IFDEF CPUX86_64}
  Result := fafafa.core.simd.cpuinfo.x86.x86_64.IsAVXSupportedByOS;
  {$ELSE}
  Result := fafafa.core.simd.cpuinfo.x86.i386.IsAVXSupportedByOS;
  {$ENDIF}
end;

function GetX86CacheInfo: TX86CacheInfo;
begin
  {$IFDEF CPUX86_64}
  Result := fafafa.core.simd.cpuinfo.x86.x86_64.GetX86CacheInfo;
  {$ELSE}
  Result := fafafa.core.simd.cpuinfo.x86.i386.GetX86CacheInfo;
  {$ENDIF}
end;

// 简单特性查询
function HasSSE: Boolean; var f: TX86Features; begin f := DetectX86Features; Result := f.HasSSE; end;
function HasSSE2: Boolean; var f: TX86Features; begin f := DetectX86Features; Result := f.HasSSE2; end;
function HasAVX: Boolean; var f: TX86Features; begin f := DetectX86Features; Result := f.HasAVX; end;
function HasAVX2: Boolean; var f: TX86Features; begin f := DetectX86Features; Result := f.HasAVX2; end;
function HasFMA: Boolean; var f: TX86Features; begin f := DetectX86Features; Result := f.HasFMA; end;

function GetVendorString: string;
var
  eax, ebx, ecx, edx: DWord;
  buf: array[0..12] of AnsiChar;
begin
  CPUID(0, eax, ebx, ecx, edx);
  Move(ebx, buf[0], 4);
  Move(edx, buf[4], 4);
  Move(ecx, buf[8], 4);
  buf[12] := #0;
  Result := string(buf);
end;

function GetBrandString: string;
var
  maxExtLeaf, ebx, ecx, edx: DWord;
  part: array[0..15] of DWord;
  i: Integer;
  p: PAnsiChar;
begin
  Result := '';
  CPUID($80000000, maxExtLeaf, ebx, ecx, edx);
  if maxExtLeaf >= $80000004 then
  begin
    FillChar(part, SizeOf(part), 0);
    CPUID($80000002, part[0], part[1], part[2], part[3]);
    CPUID($80000003, part[4], part[5], part[6], part[7]);
    CPUID($80000004, part[8], part[9], part[10], part[11]);
    // Convert to string (48 bytes)
    SetLength(Result, 48);
    p := PAnsiChar(AnsiString(Result));
    for i := 0 to 11 do
      Move(part[i], p[i * 4], 4);
    // Trim spaces
    Result := Trim(string(AnsiString(Result)));
  end
  else
    Result := GetVendorString + ' Processor';
end;

{$ELSE}

// === Stub implementations for non-x86 platforms ===

implementation

function HasCPUID: Boolean;
begin
  Result := False;
end;

procedure CPUID(EAX: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);
begin
  EAX_Out := 0;
  EBX_Out := 0;
  ECX_Out := 0;
  EDX_Out := 0;
end;

procedure CPUIDEX(EAX, ECX_In: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);
begin
  EAX_Out := 0;
  EBX_Out := 0;
  ECX_Out := 0;
  EDX_Out := 0;
end;

function DetectX86Features: TX86Features;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

procedure DetectX86VendorAndModel(var cpuInfo: TCPUInfo);
begin
  cpuInfo.Vendor := 'Non-x86';
  cpuInfo.Model := 'Non-x86 Processor';
end;

function IsAVXSupportedByOS: Boolean;
begin
  Result := False;
end;

function GetX86CacheInfo: TX86CacheInfo;
begin
  FillChar(Result, SizeOf(Result), 0);
end;

{$ENDIF} // SIMD_X86_AVAILABLE

end.
