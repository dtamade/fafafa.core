unit fafafa.core.simd.cpuinfo.x86.i386;

{$mode objfpc}
{$I fafafa.core.settings.inc}
{$ASMMODE INTEL}

interface

uses
  fafafa.core.simd.cpuinfo.base,
  fafafa.core.simd.cpuinfo.x86.base;

// 架构实现（i386）：导出�?x86 门面一致的 API

function HasCPUID: Boolean;
procedure CPUID(EAX: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);
procedure CPUIDEX(EAX, ECX_In: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);
function ReadXCR0: UInt64;

function DetectX86Features: TX86Features;
procedure DetectX86VendorAndModel(var cpuInfo: TCPUInfo);
function GetX86CacheInfo: TX86CacheInfo;
function IsAVXSupportedByOS: Boolean;

implementation

type
  TCPUIDResult = array[0..3] of DWord;

function HasCPUID: Boolean; assembler; nostackframe;
asm
  pushfd
  pop eax
  mov ecx, eax
  xor eax, $200000
  push eax
  popfd
  pushfd
  pop eax
  xor eax, ecx
  shr eax, 21
  and eax, 1
  push ecx
  popfd
end;

function ActualCPUID(leaf: DWord): TCPUIDResult;
var
  result_eax, result_ebx, result_ecx, result_edx: DWord;
begin
  asm
    push ebx
    push edi
    mov eax, leaf
    cpuid
    mov result_eax, eax
    mov result_ebx, ebx
    mov result_ecx, ecx
    mov result_edx, edx
    pop edi
    pop ebx
  end;
  Result[0] := result_eax;
  Result[1] := result_ebx;
  Result[2] := result_ecx;
  Result[3] := result_edx;
end;

procedure CPUID(EAX: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);
var
  r: TCPUIDResult;
begin
  r := ActualCPUID(EAX);
  EAX_Out := r[0];
  EBX_Out := r[1];
  ECX_Out := r[2];
  EDX_Out := r[3];
end;

function ActualCPUIDEX(leaf, ecx_in: DWord): TCPUIDResult;
var
  result_eax, result_ebx, result_ecx, result_edx: DWord;
begin
  asm
    push ebx
    push edi
    mov eax, leaf
    mov ecx, ecx_in
    cpuid
    mov result_eax, eax
    mov result_ebx, ebx
    mov result_ecx, ecx
    mov result_edx, edx
    pop edi
    pop ebx
  end;
  Result[0] := result_eax;
  Result[1] := result_ebx;
  Result[2] := result_ecx;
  Result[3] := result_edx;
end;

procedure CPUIDEX(EAX, ECX_In: DWord; var EAX_Out, EBX_Out, ECX_Out, EDX_Out: DWord);
var
  r: TCPUIDResult;
begin
  r := ActualCPUIDEX(EAX, ECX_In);
  EAX_Out := r[0];
  EBX_Out := r[1];
  ECX_Out := r[2];
  EDX_Out := r[3];
end;

function ReadXCR0: UInt64;
var
  result_eax, result_edx: DWord;
begin
  try
    asm
      mov ecx, 0
      xgetbv
      mov result_eax, eax
      mov result_edx, edx
    end;
    Result := (UInt64(result_edx) shl 32) or result_eax;
  except
    Result := 0;
  end;
end;

function IsAVXSupportedByOS: Boolean;
var
  eax, ebx, ecx, edx: DWord;
  xcr0: UInt64;
begin
  Result := False;
  eax := 0; ebx := 0; ecx := 0; edx := 0;
  CPUID(1, eax, ebx, ecx, edx);
  if (ecx and (1 shl 27)) = 0 then Exit; // OSXSAVE
  xcr0 := ReadXCR0;
  Result := XCR0HasAVX(xcr0);
end;

function DetectX86Features: TX86Features;
var
  eax, ebx, ecx, edx: DWord;
  maxLeaf, maxExtLeaf: DWord;
  xcr0: UInt64;
  osxsave: Boolean;
begin
  Result := Default(TX86Features);
  if not HasCPUID then Exit;

  eax := 0; ebx := 0; ecx := 0; edx := 0;
  maxLeaf := 0;
  maxExtLeaf := 0;

  CPUID(0, maxLeaf, ebx, ecx, edx);
  if maxLeaf < 1 then Exit;

  eax := 0; ebx := 0; ecx := 0; edx := 0;
  CPUID(1, eax, ebx, ecx, edx);
  Result.HasMMX := (edx and (1 shl 23)) <> 0;
  Result.HasSSE := (edx and (1 shl 25)) <> 0;
  Result.HasSSE2 := (edx and (1 shl 26)) <> 0;
  Result.HasSSE3 := (ecx and (1 shl 0)) <> 0;
  Result.HasPCLMULQDQ := (ecx and (1 shl 1)) <> 0;
  Result.HasSSSE3 := (ecx and (1 shl 9)) <> 0;
  Result.HasFMA := (ecx and (1 shl 12)) <> 0;
  Result.HasSSE41 := (ecx and (1 shl 19)) <> 0;
  Result.HasSSE42 := (ecx and (1 shl 20)) <> 0;
  Result.HasPOPCNT := (ecx and (1 shl 23)) <> 0;
  Result.HasAES := (ecx and (1 shl 25)) <> 0;
  Result.HasAVX := (ecx and (1 shl 28)) <> 0;
  Result.HasF16C := (ecx and (1 shl 29)) <> 0;
  Result.HasRDRAND := (ecx and (1 shl 30)) <> 0;
  // OSXSAVE/XCR0 门槛
  osxsave := (ecx and (1 shl 27)) <> 0;
  if osxsave then xcr0 := ReadXCR0 else xcr0 := 0;
  if Result.HasAVX then Result.HasAVX := XCR0HasAVX(xcr0);
  if maxLeaf >= 7 then
  begin
    eax := 0; ebx := 0; ecx := 0; edx := 0;
    CPUIDEX(7, 0, eax, ebx, ecx, edx);
    Result.HasBMI1 := (ebx and (1 shl 3)) <> 0;
    Result.HasAVX2 := (ebx and (1 shl 5)) <> 0;
    Result.HasBMI2 := (ebx and (1 shl 8)) <> 0;
    Result.HasAVX512F := (ebx and (1 shl 16)) <> 0;
    Result.HasAVX512DQ := (ebx and (1 shl 17)) <> 0;
    Result.HasAVX512BW := (ebx and (1 shl 30)) <> 0;
    Result.HasAVX512VL := (ebx and (1 shl 31)) <> 0;
    Result.HasAVX512VBMI := (ecx and (1 shl 1)) <> 0;
    Result.HasSHA := (ebx and (1 shl 29)) <> 0;
    Result.HasRDSEED := (ecx and (1 shl 18)) <> 0;
    // �?OS 门槛屏蔽
    if not Result.HasAVX then
    begin
      Result.HasAVX2 := False;
      Result.HasFMA := False;
    end;
    if not Result.HasAVX2 then
    begin
      Result.HasAVX512F := False;
      Result.HasAVX512DQ := False;
      Result.HasAVX512BW := False;
      Result.HasAVX512VL := False;
      Result.HasAVX512VBMI := False;
    end;
    // AVX-512 还需�?XCR0 �?ZMM 状态保�?    if not XCR0HasAVX512(xcr0) then
    begin
      Result.HasAVX512F := False;
      Result.HasAVX512DQ := False;
      Result.HasAVX512BW := False;
      Result.HasAVX512VL := False;
      Result.HasAVX512VBMI := False;
    end;
  end;
  ebx := 0; ecx := 0; edx := 0;
  CPUID($80000000, maxExtLeaf, ebx, ecx, edx);
  if maxExtLeaf >= $80000001 then
  begin
    eax := 0; ebx := 0; ecx := 0; edx := 0;
    CPUID($80000001, eax, ebx, ecx, edx);
    Result.HasFMA4 := (ecx and (1 shl 16)) <> 0;
  end;
end;

procedure DetectX86VendorAndModel(var cpuInfo: TCPUInfo);
var
  eax, ebx, ecx, edx: DWord;
  vendorString: array[0..12] of AnsiChar;
  brandString: array[0..48] of AnsiChar;
begin
  if not HasCPUID then
  begin
    cpuInfo.Vendor := 'Unknown x86';
    cpuInfo.Model := 'Unknown x86 Processor';
    Exit;
  end;

  eax := 0; ebx := 0; ecx := 0; edx := 0;
  vendorString[0] := #0;
  brandString[0] := #0;
  FillChar(vendorString, SizeOf(vendorString), 0);
  FillChar(brandString, SizeOf(brandString), 0);

  CPUID(0, eax, ebx, ecx, edx);
  Move(ebx, vendorString[0], 4);
  Move(edx, vendorString[4], 4);
  Move(ecx, vendorString[8], 4);
  vendorString[12] := #0;
  cpuInfo.Vendor := string(vendorString);

  eax := 0; ebx := 0; ecx := 0; edx := 0;
  CPUID($80000000, eax, ebx, ecx, edx);
  if eax >= $80000004 then
  begin
    CPUID($80000002, eax, ebx, ecx, edx);
    Move(eax, brandString[0], 4);
    Move(ebx, brandString[4], 4);
    Move(ecx, brandString[8], 4);
    Move(edx, brandString[12], 4);
    CPUID($80000003, eax, ebx, ecx, edx);
    Move(eax, brandString[16], 4);
    Move(ebx, brandString[20], 4);
    Move(ecx, brandString[24], 4);
    Move(edx, brandString[28], 4);
    CPUID($80000004, eax, ebx, ecx, edx);
    Move(eax, brandString[32], 4);
    Move(ebx, brandString[36], 4);
    Move(ecx, brandString[40], 4);
    Move(edx, brandString[44], 4);
    cpuInfo.Model := string(brandString);
  end
  else
  begin
    cpuInfo.Model := cpuInfo.Vendor + ' Processor';
  end;
  if cpuInfo.Model = '' then
    cpuInfo.Model := cpuInfo.Vendor + ' Processor';
end;

function GetX86CacheInfo: TX86CacheInfo;
var
  eax, ebx, ecx, edx: DWord;
begin
  Result := Default(TX86CacheInfo);
  if not HasCPUID then Exit;

  eax := 0; ebx := 0; ecx := 0; edx := 0;
  CPUID(0, eax, ebx, ecx, edx);
  if eax >= 2 then
  begin
    eax := 0; ebx := 0; ecx := 0; edx := 0;
    CPUID(2, eax, ebx, ecx, edx);
    Result.L1DataCache := 32;
    Result.L1InstructionCache := 32;
    Result.L2Cache := 256;
    Result.L3Cache := 0;
  end;
  eax := 0; ebx := 0; ecx := 0; edx := 0;
  CPUID($80000000, eax, ebx, ecx, edx);
  if eax >= $80000006 then
  begin
    eax := 0; ebx := 0; ecx := 0; edx := 0;
    CPUID($80000006, eax, ebx, ecx, edx);
    Result.L2Cache := (ecx shr 16) and $FFFF;
    Result.L3Cache := ((edx shr 18) and $3FFF) * 512;
  end;
end;

end.




