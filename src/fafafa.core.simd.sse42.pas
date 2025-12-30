unit fafafa.core.simd.sse42;

{$mode objfpc}
{$I fafafa.core.settings.inc}
{$asmmode intel}

interface

uses
  fafafa.core.simd.base,
  fafafa.core.simd.dispatch;

// === SSE4.2 Backend Implementation ===
// Provides SIMD-accelerated operations using x86-64 SSE4.2 instructions.
// SSE4.2 focuses on string processing and CRC32 hardware acceleration.
//
// Key SSE4.2 instructions:
// - CRC32: Hardware CRC32C (Castagnoli polynomial) computation
// - PCMPESTRI/PCMPESTRM: Explicit-length string compare returning index/mask
// - PCMPISTRI/PCMPISTRM: Implicit-length string compare (null-terminated)
// - PCMPGTQ: 64-bit signed integer greater-than comparison
//
// Note: POPCNT is often associated with SSE4.2 but is actually a separate
// CPUID flag. It may or may not be present on SSE4.2 CPUs.

procedure RegisterSSE42Backend;

// === CRC32 Hardware Functions (Public API) ===
// These use the CRC32C polynomial (iSCSI polynomial: 0x1EDC6F41)

function CRC32C_8(crc: UInt32; value: Byte): UInt32;
function CRC32C_16(crc: UInt32; value: UInt16): UInt32;
function CRC32C_32(crc: UInt32; value: UInt32): UInt32;
function CRC32C_64(crc: UInt64; value: UInt64): UInt64;

// CRC32C for byte buffer
function CRC32C_Buffer(const data: Pointer; len: SizeUInt; initial: UInt32 = $FFFFFFFF): UInt32;

// === String Operations (Public API) ===
// Find first occurrence of any byte from 'needles' in 'haystack'
// Returns index (0-based) or -1 if not found
function FindFirstOf_SSE42(const haystack: PAnsiChar; haystackLen: Integer;
                            const needles: PAnsiChar; needlesLen: Integer): Integer;

// Find first byte NOT in 'chars' set
function FindFirstNotOf_SSE42(const str: PAnsiChar; strLen: Integer;
                               const chars: PAnsiChar; charsLen: Integer): Integer;

implementation

uses
  SysUtils,
  fafafa.core.simd.cpuinfo;

// === CRC32C Hardware Implementation ===
// SSE4.2 provides CRC32 instruction with Castagnoli polynomial

function CRC32C_8(crc: UInt32; value: Byte): UInt32; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  // RDI = crc, RSI = value
  mov    eax, edi
  movzx  esi, sil
  crc32  eax, sil
  {$ELSE}
  // RCX = crc, RDX = value
  mov    eax, ecx
  crc32  eax, dl
  {$ENDIF}
end;

function CRC32C_16(crc: UInt32; value: UInt16): UInt32; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  mov    eax, edi
  crc32  eax, si
  {$ELSE}
  mov    eax, ecx
  crc32  eax, dx
  {$ENDIF}
end;

function CRC32C_32(crc: UInt32; value: UInt32): UInt32; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  mov    eax, edi
  crc32  eax, esi
  {$ELSE}
  mov    eax, ecx
  crc32  eax, edx
  {$ENDIF}
end;

function CRC32C_64(crc: UInt64; value: UInt64): UInt64; assembler; nostackframe;
asm
  {$IFDEF UNIX}
  mov    rax, rdi
  crc32  rax, rsi
  {$ELSE}
  mov    rax, rcx
  crc32  rax, rdx
  {$ENDIF}
end;

// CRC32C for byte buffer - optimized with 64-bit processing
function CRC32C_Buffer(const data: Pointer; len: SizeUInt; initial: UInt32): UInt32;
var
  p: PByte;
  remaining: SizeUInt;
  crc64: UInt64;
begin
  if (data = nil) or (len = 0) then
  begin
    Result := initial;
    Exit;
  end;

  p := PByte(data);
  remaining := len;
  crc64 := initial;

  // Process 8 bytes at a time
  while remaining >= 8 do
  begin
    asm
      mov    rax, crc64
      mov    rdx, p
      mov    rdx, [rdx]      // Load 8 bytes
      crc32  rax, rdx
      mov    crc64, rax
    end;
    Inc(p, 8);
    Dec(remaining, 8);
  end;

  // Process 4 bytes
  if remaining >= 4 then
  begin
    asm
      mov    eax, dword ptr [crc64]
      mov    rdx, p
      mov    edx, [rdx]
      crc32  eax, edx
      mov    dword ptr [crc64], eax
    end;
    Inc(p, 4);
    Dec(remaining, 4);
  end;

  // Process 2 bytes
  if remaining >= 2 then
  begin
    asm
      mov    eax, dword ptr [crc64]
      mov    rdx, p
      movzx  edx, word ptr [rdx]
      crc32  eax, dx
      mov    dword ptr [crc64], eax
    end;
    Inc(p, 2);
    Dec(remaining, 2);
  end;

  // Process remaining byte
  if remaining >= 1 then
  begin
    asm
      mov    eax, dword ptr [crc64]
      mov    rdx, p
      movzx  edx, byte ptr [rdx]
      crc32  eax, dl
      mov    dword ptr [crc64], eax
    end;
  end;

  Result := UInt32(crc64);
end;

// === String Operations using PCMPESTRI/PCMPISTRM ===
// PCMPESTRI: Packed Compare Explicit-length String, Return Index
// Immediate byte encoding:
//   [1:0] = Source data format: 00=unsigned bytes, 01=unsigned words, 10=signed bytes, 11=signed words
//   [3:2] = Aggregation: 00=equal any, 01=ranges, 10=equal each, 11=equal ordered
//   [5:4] = Polarity: 00=positive, 01=negative, 10=masked positive, 11=masked negative
//   [6]   = Output selection: 0=least significant, 1=most significant

// Find first occurrence of any byte from 'needles' in 'haystack'
// Uses "equal any" mode (imm8 = 0x00)
function FindFirstOf_SSE42(const haystack: PAnsiChar; haystackLen: Integer;
                            const needles: PAnsiChar; needlesLen: Integer): Integer;
var
  idx: Integer;
  hLen, nLen: Integer;
  hp, np: PAnsiChar;
  found: Boolean;
begin
  Result := -1;
  if (haystack = nil) or (haystackLen <= 0) or (needles = nil) or (needlesLen <= 0) then
    Exit;

  // Limit needle length to 16 (SSE register size)
  nLen := needlesLen;
  if nLen > 16 then nLen := 16;

  hp := haystack;
  np := needles;
  hLen := haystackLen;
  idx := 0;
  found := False;

  // Process 16 bytes of haystack at a time
  while hLen > 0 do
  begin
    asm
      mov    rax, hp         // haystack pointer
      mov    rdx, np         // needles pointer
      mov    ecx, hLen       // haystack length (remaining)
      mov    r8d, nLen       // needles length

      movdqu xmm0, [rdx]     // Load needles (up to 16 bytes)
      movdqu xmm1, [rax]     // Load haystack chunk

      // PCMPESTRI: eax=needle_len, edx=haystack_len in chunk
      mov    eax, r8d        // needle length in eax
      mov    edx, ecx        // haystack length in edx
      cmp    edx, 16
      jle    @use_edx
      mov    edx, 16         // Cap at 16 for this chunk
    @use_edx:

      // pcmpestri xmm0, xmm1, imm8
      // imm8 = 0x00: unsigned bytes, equal any, positive polarity, least significant index
      // Returns index of first match in ECX, or 16 if no match
      // CF is set if there's a match
      db $66, $0F, $3A, $61, $C1, $00   // pcmpestri xmm0, xmm1, 0x00

      // Check if match found (CF set)
      jnc    @no_match

      // Match found, ECX contains index within this 16-byte chunk
      mov    [idx], ecx
      mov    byte ptr [found], 1
      jmp    @done

    @no_match:
      mov    byte ptr [found], 0

    @done:
    end;

    if found then
    begin
      Result := (hp - haystack) + idx;
      Exit;
    end;

    // Move to next chunk
    if hLen <= 16 then
      Break;
    Inc(hp, 16);
    Dec(hLen, 16);
  end;
end;

// Find first byte NOT in character set
// Uses "equal any" with negative polarity (imm8 = 0x10)
function FindFirstNotOf_SSE42(const str: PAnsiChar; strLen: Integer;
                               const chars: PAnsiChar; charsLen: Integer): Integer;
var
  idx: Integer;
  sLen, cLen: Integer;
  sPtr, cp: PAnsiChar;
  found: Boolean;
begin
  Result := -1;
  if (str = nil) or (strLen <= 0) then
    Exit;
  if (chars = nil) or (charsLen <= 0) then
  begin
    // No chars to match means first char is "not in set"
    Result := 0;
    Exit;
  end;

  cLen := charsLen;
  if cLen > 16 then cLen := 16;

  sPtr := str;
  cp := chars;
  sLen := strLen;
  idx := 0;
  found := False;

  while sLen > 0 do
  begin
    asm
      mov    rax, sPtr
      mov    rdx, cp
      mov    ecx, sLen
      mov    r8d, cLen

      movdqu xmm0, [rdx]     // char set
      movdqu xmm1, [rax]     // string chunk

      mov    eax, r8d        // char set length
      mov    edx, ecx        // string length
      cmp    edx, 16
      jle    @use_edx2
      mov    edx, 16
    @use_edx2:

      // pcmpestri xmm0, xmm1, imm8
      // imm8 = 0x10: unsigned bytes, equal any, negative polarity, least significant
      // Negative polarity inverts the result, finding bytes NOT in set
      db $66, $0F, $3A, $61, $C1, $10

      jnc    @no_match2
      mov    [idx], ecx
      mov    byte ptr [found], 1
      jmp    @done2

    @no_match2:
      mov    byte ptr [found], 0

    @done2:
    end;

    if found then
    begin
      Result := (sPtr - str) + idx;
      Exit;
    end;

    if sLen <= 16 then
      Break;
    Inc(sPtr, 16);
    Dec(sLen, 16);
  end;
end;

// === SSE4.2 64-bit Comparison ===

function SSE42CmpGtI64x2(const a, b: TVecI64x2): TMask2;
var
  maskVal: Integer;
begin
  asm
    lea      rax, a
    lea      rdx, b
    movdqu   xmm0, [rax]
    movdqu   xmm1, [rdx]
    pcmpgtq  xmm0, xmm1
    movmskpd eax, xmm0
    mov      maskVal, eax
  end;
  Result := TMask2(maskVal);
end;

// === Backend Registration ===

procedure RegisterSSE42Backend;
var
  dispatchTable: TSimdDispatchTable;
begin
  // Only register if SSE4.2 is available
  if not HasSSE42 then
    Exit;

  // ✅ 修复 P0-1: 从 SSE4.1 继承实现（SSE4.2 是 SSE4.1 的超集）
  dispatchTable := Default(TSimdDispatchTable);

  // Set backend info BEFORE cloning (will be preserved)
  with dispatchTable.BackendInfo do
  begin
    Backend := sbSSE42;
    Name := 'SSE4.2';
    Description := 'x86-64 SSE4.2 SIMD implementation (CRC32, string ops)';
    Capabilities := [scBasicArithmetic, scComparison, scMathFunctions, scReduction,
                     scShuffle, scIntegerOps, scLoadStore];
    Available := True;
    Priority := 22; // Higher than SSE4.1 (20)
  end;

  // Clone from SSE4.1 → SSSE3 → SSE3 → SSE2 chain
  if not CloneDispatchTable(sbSSE41, dispatchTable) then
    if not CloneDispatchTable(sbSSSE3, dispatchTable) then
      if not CloneDispatchTable(sbSSE3, dispatchTable) then
        if not CloneDispatchTable(sbSSE2, dispatchTable) then
          FillBaseDispatchTable(dispatchTable);

  // Update backend identifier
  dispatchTable.Backend := sbSSE42;

  // SSE4.2 provides string operations and CRC32
  if IsVectorAsmEnabled then
  begin
    // Override 64-bit comparison with PCMPGTQ
    dispatchTable.CmpGtI64x2 := @SSE42CmpGtI64x2;

    // CRC32 functions are exposed directly, not through dispatch table
    // (They're not vector operations, but specialized instructions)
  end;

  // Register the backend
  RegisterBackend(sbSSE42, dispatchTable);
end;

initialization
  RegisterSSE42Backend;
  RegisterBackendRebuilder(sbSSE42, @RegisterSSE42Backend);

end.
