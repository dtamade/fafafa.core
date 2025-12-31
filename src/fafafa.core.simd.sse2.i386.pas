unit fafafa.core.simd.sse2.i386;

{$mode objfpc}
{$I fafafa.core.settings.inc}
{$ASMMODE INTEL}

interface

uses
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch;

// === i386 SSE2 Backend Implementation ===
// Provides SIMD-accelerated operations using 32-bit x86 SSE2 instructions.
// This backend is available on i386 processors with SSE2 support (Pentium 4+).
//
// Key differences from x86_64 SSE2:
//   - 32-bit registers: EAX, EDX, ECX instead of RAX, RDX, RCX
//   - FPC register calling convention: EAX, EDX, ECX for first 3 params
//   - XMM0-XMM7 available (vs XMM0-XMM15 on x86_64)
//   - No 64-bit popcnt; use SWAR popcount

// Register the i386 SSE2 backend
procedure RegisterSSE2i386Backend;

// === i386 SSE2 Facade Functions ===
function MemEqual_SSE2_i386(a, b: Pointer; len: SizeUInt): LongBool;
function MemFindByte_SSE2_i386(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
function SumBytes_SSE2_i386(p: Pointer; len: SizeUInt): UInt64;
function CountByte_SSE2_i386(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;
function BitsetPopCount_SSE2_i386(p: Pointer; len: SizeUInt): SizeUInt;

implementation

uses
  SysUtils,
  fafafa.core.simd.cpuinfo,
  fafafa.core.simd.cpuinfo.base,
  fafafa.core.simd.scalar;

// === i386 SSE2 Memory Functions ===
// FPC i386 register calling convention:
//   - First param: EAX
//   - Second param: EDX
//   - Third param: ECX
//   - Return value: EAX (or EDX:EAX for 64-bit)

function MemEqual_SSE2_i386(a, b: Pointer; len: SizeUInt): LongBool;
var
  pa, pb: PByte;
  i: SizeUInt;
  maskVal: Integer;
begin
  {$PUSH}{$Q-}{$R-}
  if len = 0 then
  begin
    Result := True;
    Exit;
  end;

  if (a = nil) or (b = nil) then
  begin
    Result := (a = b);
    Exit;
  end;

  if a = b then
  begin
    Result := True;
    Exit;
  end;

  pa := PByte(a);
  pb := PByte(b);
  i := 0;

  // Process 16 bytes at a time using SSE2
  while i + 16 <= len do
  begin
    asm
      push ebx
      mov  eax, pa
      mov  edx, pb
      add  eax, i
      add  edx, i
      movdqu xmm0, [eax]
      movdqu xmm1, [edx]
      pcmpeqb xmm0, xmm1
      pmovmskb eax, xmm0
      mov  maskVal, eax
      pop  ebx
    end;

    if maskVal <> $FFFF then
    begin
      Result := False;
      Exit;
    end;

    Inc(i, 16);
  end;

  // Handle remaining bytes
  while i < len do
  begin
    if pa[i] <> pb[i] then
    begin
      Result := False;
      Exit;
    end;
    Inc(i);
  end;

  Result := True;
  {$POP}
end;

function MemFindByte_SSE2_i386(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
var
  pb: PByte;
  i: SizeUInt;
  maskVal: Integer;
  bitPos: Integer;
  broadcastVal: Integer;
begin
  if (len = 0) or (p = nil) then
  begin
    Result := -1;
    Exit;
  end;

  pb := PByte(p);
  i := 0;
  broadcastVal := value;

  // Process 16 bytes at a time using SSE2
  while i + 16 <= len do
  begin
    asm
      push ebx
      // Broadcast value to all 16 bytes
      mov  eax, broadcastVal
      movd xmm1, eax
      punpcklbw xmm1, xmm1
      pshuflw xmm1, xmm1, 0
      punpcklqdq xmm1, xmm1
      
      // Load and compare
      mov  eax, pb
      add  eax, i
      movdqu xmm0, [eax]
      pcmpeqb xmm0, xmm1
      pmovmskb eax, xmm0
      mov  maskVal, eax
      pop  ebx
    end;

    if maskVal <> 0 then
    begin
      // Find first set bit using BSF
      asm
        bsf eax, maskVal
        mov bitPos, eax
      end;
      Result := PtrInt(i) + bitPos;
      Exit;
    end;

    Inc(i, 16);
  end;

  // Handle remaining bytes
  while i < len do
  begin
    if pb[i] = value then
    begin
      Result := PtrInt(i);
      Exit;
    end;
    Inc(i);
  end;

  Result := -1;
end;

function SumBytes_SSE2_i386(p: Pointer; len: SizeUInt): UInt64;
var
  pb: PByte;
  i: SizeUInt;
  sum0, sum1: UInt32;
  tempLo, tempHi: UInt32;
begin
  {$PUSH}{$Q-}{$R-}
  if (len = 0) or (p = nil) then
  begin
    Result := 0;
    Exit;
  end;

  pb := PByte(p);
  i := 0;
  sum0 := 0;
  sum1 := 0;

  // Process 16 bytes at a time using SSE2 psadbw
  while i + 16 <= len do
  begin
    asm
      push ebx
      mov  eax, pb
      add  eax, i
      movdqu xmm0, [eax]
      pxor   xmm1, xmm1      // Zero register
      psadbw xmm0, xmm1      // Sum bytes: result in low 16 bits of each 64-bit lane
      
      // Extract lower 64-bit sum
      movd   eax, xmm0
      add    sum0, eax
      
      // Extract upper 64-bit sum (shift right 8 bytes)
      psrldq xmm0, 8
      movd   eax, xmm0
      add    sum1, eax
      pop    ebx
    end;
    Inc(i, 16);
  end;

  // Handle remaining bytes
  while i < len do
  begin
    Inc(sum0, pb[i]);
    Inc(i);
  end;

  Result := UInt64(sum0) + UInt64(sum1);
  {$POP}
end;

// SWAR popcount for 32-bit mask (no native popcnt on older i386)
function PopCount32_SWAR(x: UInt32): UInt32; inline;
begin
  x := x - ((x shr 1) and $55555555);
  x := (x and $33333333) + ((x shr 2) and $33333333);
  x := (x + (x shr 4)) and $0F0F0F0F;
  x := x + (x shr 8);
  x := x + (x shr 16);
  Result := x and $3F;
end;

function CountByte_SSE2_i386(p: Pointer; len: SizeUInt; value: Byte): SizeUInt;
var
  pb: PByte;
  i: SizeUInt;
  maskVal: UInt32;
  count: SizeUInt;
  broadcastVal: Integer;
begin
  if (len = 0) or (p = nil) then
  begin
    Result := 0;
    Exit;
  end;

  pb := PByte(p);
  i := 0;
  count := 0;
  broadcastVal := value;

  // Process 16 bytes at a time using SSE2
  while i + 16 <= len do
  begin
    asm
      push ebx
      // Broadcast value to all 16 bytes
      mov  eax, broadcastVal
      movd xmm1, eax
      punpcklbw xmm1, xmm1
      pshuflw xmm1, xmm1, 0
      punpcklqdq xmm1, xmm1
      
      // Load and compare
      mov  eax, pb
      add  eax, i
      movdqu xmm0, [eax]
      pcmpeqb xmm0, xmm1
      pmovmskb eax, xmm0
      mov  maskVal, eax
      pop  ebx
    end;

    // Count bits using SWAR (no popcnt on i386)
    Inc(count, PopCount32_SWAR(maskVal));
    Inc(i, 16);
  end;

  // Handle remaining bytes
  while i < len do
  begin
    if pb[i] = value then
      Inc(count);
    Inc(i);
  end;

  Result := count;
end;

// Popcount lookup table for byte values
const
  PopCountTable: array[0..255] of Byte = (
    0,1,1,2,1,2,2,3,1,2,2,3,2,3,3,4,1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,
    1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,
    1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,
    2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,
    1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5,2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,
    2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,
    2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6,3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,
    3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7,4,5,5,6,5,6,6,7,5,6,6,7,6,7,7,8
  );

function BitsetPopCount_SSE2_i386(p: Pointer; len: SizeUInt): SizeUInt;
var
  pb: PByte;
  i: SizeUInt;
  count: SizeUInt;
  dwordCount: SizeUInt;
  dwordVal: UInt32;
  pDword: PUInt32;
begin
  if (len = 0) or (p = nil) then
  begin
    Result := 0;
    Exit;
  end;

  pb := PByte(p);
  i := 0;
  count := 0;

  // Process 4 bytes at a time using SWAR popcount
  pDword := PUInt32(p);
  dwordCount := len div 4;
  
  while dwordCount > 0 do
  begin
    dwordVal := pDword^;
    Inc(count, PopCount32_SWAR(dwordVal));
    Inc(pDword);
    Dec(dwordCount);
  end;
  
  // Handle remaining bytes using lookup table
  i := (len div 4) * 4;
  while i < len do
  begin
    Inc(count, PopCountTable[pb[i]]);
    Inc(i);
  end;

  Result := count;
end;

// === Backend Registration ===

procedure RegisterSSE2i386Backend;
var
  dispatchTable: TSimdDispatchTable;
begin
  // Only register if SSE2 is available
  if not HasSSE2 then
    Exit;

  // Fill with base scalar implementations
  dispatchTable := Default(TSimdDispatchTable);
  FillBaseDispatchTable(dispatchTable);

  // Set backend info
  dispatchTable.Backend := sbSSE2;
  dispatchTable.BackendInfo.Backend := sbSSE2;
  dispatchTable.BackendInfo.Name := 'SSE2-i386';
  dispatchTable.BackendInfo.Description := 'i386 SSE2 SIMD implementation (128-bit)';
  dispatchTable.BackendInfo.Capabilities := [scBasicArithmetic, scComparison, scMathFunctions, scReduction, scLoadStore];
  dispatchTable.BackendInfo.Available := True;
  dispatchTable.BackendInfo.Priority := 10;

  // Override facade functions with SSE2-accelerated versions
  dispatchTable.MemEqual := @MemEqual_SSE2_i386;
  dispatchTable.MemFindByte := @MemFindByte_SSE2_i386;
  dispatchTable.SumBytes := @SumBytes_SSE2_i386;
  dispatchTable.CountByte := @CountByte_SSE2_i386;
  dispatchTable.BitsetPopCount := @BitsetPopCount_SSE2_i386;

  // Register the backend
  RegisterBackend(sbSSE2, dispatchTable);
end;

initialization
  RegisterSSE2i386Backend;

end.
