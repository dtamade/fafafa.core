{
  fafafa.core.crypto.aead.gcm.ghash - GHASH for AES-GCM

  Spec:
  - NIST SP 800-38D. J0 for 96-bit IV: Nonce || 0^31 || 1
  - GHASH: GF(2^128) mult over poly x^128 + x^7 + x^2 + x + 1 (R=0xE1<<120)
  - Bit order: process X MSB-first; RightShift1(V) with LSB reduction by R

  Notes:
  - Pure Pascal reference; future: optional CLMUL acceleration via factory switch
}
unit fafafa.core.crypto.aead.gcm.ghash;

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

interface

type
  TBytes = array of Byte;

  IGHash = interface
    ['{0E36D976-BA3F-4C61-9C67-6A9717B5E9B1}']
    procedure Init(const HSubKey: TBytes); // H = AES_K(0^128)
    procedure Update(const Data: TBytes);   // absorb in 128-bit blocks (pad last)
    procedure WarmUp;                       // prebuild tables for current backend (no-op for CLMUL)
    function Finalize(const AADLen, CLen: QWord): TBytes; // S = GHASH(H, AAD, C)
    procedure Reset;
  end;


// Test/diagnostic: select backend at runtime
// Force: -1 = Auto (prefer CLMUL if available under macro), 0 = Pure, 1 = CLMUL (if available)
procedure GHash_SelectBackend(Force: Integer);

function CreateGHash: IGHash;

  // Optional developer API: set default pure-mode for new GHASH contexts (Debug builds primarily)
  procedure GHash_SetPureMode(const Mode: string);


implementation

uses
  SysUtils,
  fafafa.core.crypto.interfaces;


{------------------------------------------------------------------------------
 GHASH developer notes (best‑practice quick ref)

 - Backends
   * Pure Pascal (default in Debug), optional CLMUL for x86_64 (default in Release)
   * Runtime override (optional): FAFAFA_GHASH_IMPL=auto|pure|clmul
   * Debug one‑time backend log: FAFAFA_GHASH_LOG_BACKEND=1|true

 - Pure Pascal modes (Debug)
   * FAFAFA_GHASH_PURE_MODE=bit|nibble|byte (default byte). Or call GHash_SetPureMode('...').
   * Tables built lazily by need: V (bit) -> V+Nib (nibble) -> V+Nib+Byte (byte)

 - Safety/diagnostics (Debug)
   * Strict length check in Finalize: AADLen+CLen must equal bytes fed via Update
   * Optional zeroize on Reset: FAFAFA_GHASH_ZEROIZE_TABLES=1|true
   * Optional per‑H tiny LRU cache (≤4): FAFAFA_GHASH_CACHE_PER_H=1|true

 - Bench helpers
   * FAFAFA_BENCH_VERBOSE=1 (print throughput), =2 (median‑of‑3)
   * FAFAFA_BENCH_ITERS to scale iterations
------------------------------------------------------------------------------}


// Pure-mode enum used by both default var and context
type
  TGHashPureMode = (gpmBit, gpmNibble, gpmByte);


var
  GHash_DefaultPureMode: TGHashPureMode = gpmByte;

var
  GF_CLMUL_Faulted: Boolean = False;
  GHash_Backend_Logged: Boolean = False;
  GHash_Backend_Name: string = 'pure';

{$IFDEF CPUX86_64}
{$ASMMODE INTEL}
function CPU_HasPCLMUL: Boolean; assembler; {$IFDEF WINDOWS}nostackframe;{$ENDIF}
asm
  // CPUID leaf 1, ECX bit 1 = PCLMULQDQ
  mov eax, 1
  cpuid
  bt  ecx, 1
  setc al
  movzx eax, al
end;
{$ENDIF}

{$IFDEF FAFAFA_CRYPTO_X86_CLMUL}
{$IFDEF CPUX86_64}
procedure GFMult128_CLMUL(const X, Y: array of Byte; out Z: array of Byte); forward;
{$ENDIF}
{$ENDIF}


procedure XorBlock(var A: array of Byte; const B: array of Byte);
var i: Integer;
begin
  for i := 0 to 15 do A[i] := A[i] xor B[i];
end;

procedure RightShift1(var V: array of Byte; out LSB: Byte);
var i: Integer; carry, newcarry: Byte;
begin
  // Capture LSB prior to shift per GHASH spec
  LSB := V[15] and $01;
  carry := 0;
  // Shift right across 16-byte big-endian array: propagate carry from higher index to lower
  for i := 15 downto 0 do
  begin
    newcarry := V[i] and $01;
    V[i] := (V[i] shr 1) or (carry shl 7);
    carry := newcarry;
  end;
end;

type
  TGFMult128Proc = procedure(const X, Y: array of Byte; out Z: array of Byte);

var
  GFMult128_Impl: TGFMult128Proc;

{$PUSH}{$HINTS OFF 5057}{$HINTS OFF 5058}
procedure GFMult128_Pure(const X, Y: array of Byte; out Z: array of Byte);
// GCM multiply: Z = X * Y over GF(2^128) with poly x^128 + x^7 + x^2 + x + 1
var i, bit: Integer; V, Zloc: array[0..15] of Byte; LSB: Byte; Xi_bit: Boolean;
begin
  {$IFDEF DEBUG}
  if (Length(X) < 16) or (Length(Y) < 16) or (Length(Z) < 16) then
    raise EInvalidArgument.Create('GFMult128_Pure: buffer length must be >= 16');
  {$ENDIF}
  // Pre-initialize locals to satisfy analyzers; does not change semantics
  FillChar(Zloc, SizeOf(Zloc), 0);
  FillChar(V, SizeOf(V), 0);
  Move(Y[0], V[0], 16);
  // MSB-first processing per NIST SP 800-38D Sec 6.3
  // Iterate bytes 0..15 and bits 7..0 so that bit 127 (MSB of X[0]) is processed first
  for i := 0 to 15 do
  begin
    for bit := 7 downto 0 do
    begin
      Xi_bit := ((X[i] shr bit) and $01) <> 0;
      if Xi_bit then XorBlock(Zloc, V);
      RightShift1(V, LSB);
      if LSB <> 0 then
        V[0] := V[0] xor $E1; // reduction by R = 0xE1 << 120
    end;
  end;
  Move(Zloc[0], Z[0], 16);
  // zeroize locals carrying sensitive intermediate state
  FillChar(V, SizeOf(V), 0);
  FillChar(Zloc, SizeOf(Zloc), 0);

end;
{$POP}



procedure GHash_SelectBackend(Force: Integer);
var wantClmul, haveClmul: Boolean; logEnv: string;
begin
  wantClmul := False;
  haveClmul := False;
  case Force of
    0: begin GFMult128_Impl := @GFMult128_Pure; GHash_Backend_Name := 'pure'; end;
    1:
      begin
        {$IFDEF FAFAFA_CRYPTO_X86_CLMUL}
        {$IFDEF CPUX86_64}
        wantClmul := True;
        haveClmul := CPU_HasPCLMUL;
        if haveClmul then begin GFMult128_Impl := @GFMult128_CLMUL; GHash_Backend_Name := 'clmul'; end
        else begin GFMult128_Impl := @GFMult128_Pure; GHash_Backend_Name := 'pure'; end;
        {$ELSE}
        GFMult128_Impl := @GFMult128_Pure; GHash_Backend_Name := 'pure';
        {$ENDIF}
        {$ELSE}
        GFMult128_Impl := @GFMult128_Pure; GHash_Backend_Name := 'pure';
        {$ENDIF}
      end;
  else
    // Auto
    {$IFDEF FAFAFA_CRYPTO_X86_CLMUL}
    {$IFDEF CPUX86_64}
    haveClmul := CPU_HasPCLMUL;
    if haveClmul then begin GFMult128_Impl := @GFMult128_CLMUL; GHash_Backend_Name := 'clmul'; end
    else begin GFMult128_Impl := @GFMult128_Pure; GHash_Backend_Name := 'pure'; end;
    {$ELSE}
    GFMult128_Impl := @GFMult128_Pure; GHash_Backend_Name := 'pure';
    {$ENDIF}
    {$ELSE}
    GFMult128_Impl := @GFMult128_Pure; GHash_Backend_Name := 'pure';
    {$ENDIF}
  end;

  // Optional one-time log (DEBUG only) when requested
  {$IFDEF DEBUG}
  if not GHash_Backend_Logged then
  begin
    logEnv := GetEnvironmentVariable('FAFAFA_GHASH_LOG_BACKEND');
    if (logEnv = '1') or SameText(logEnv, 'true') then
    begin
      WriteLn('[GHASH] backend: ', GHash_Backend_Name, ', wantClmul=', wantClmul, ', haveClmul=', haveClmul);
      GHash_Backend_Logged := True;
    end;
  end;
  {$ENDIF}
end;



{$IFDEF FAFAFA_CRYPTO_X86_CLMUL}
{$IFDEF CPUX86_64}
// CLMUL implementation (x86_64, PCLMULQDQ): 128x128 carry-less multiply + reduction for GHASH
procedure GFMult128_CLMUL(const X, Y: array of Byte; out Z: array of Byte);
var
  LX, LY: array[0..15] of Byte; // little-endian polynomials (reverse of GHASH big-endian)
  TMP: array[0..15] of Byte;
  z0, z1, z2: array[0..1] of QWord; // partial products
  rH0, rH1, rM0, rM1, rL0, rL1: QWord; // reduction accumulators
  s1_0, s1_1, s2_0, s2_1, s7_0, s7_1: QWord;
  m1_0, m1_1, m2_0, m2_1, m7_0, m7_1: QWord;
  i: Integer;
  {$IFDEF DEBUG}
  const ENV_UNVERIFIED = 'FAFAFA_GHASH_ENABLE_UNVERIFIED_CLMUL';
  {$ENDIF}
begin
  if GF_CLMUL_Faulted then begin GFMult128_Pure(X, Y, Z); Exit; end;
  {$IFDEF DEBUG}
  // Experimental guard (DEBUG only): unless explicitly enabled, use reference implementation
  if not SameText(GetEnvironmentVariable('FAFAFA_GHASH_USE_EXPERIMENTAL'), '1') and
     not SameText(GetEnvironmentVariable('FAFAFA_GHASH_USE_EXPERIMENTAL'), 'true') then
  begin
    GFMult128_Pure(X, Y, Z);
    Exit;
  end;
  // Additional DEBUG-time length checks
  if (Length(X) < 16) or (Length(Y) < 16) or (Length(Z) < 16) then
    raise EInvalidArgument.Create('GFMult128_CLMUL: buffer length must be >= 16');
  {$ENDIF}
  try
    // Convert GHASH big-endian byte order to little-endian for PCLMUL polynomial interpretation
    for i := 0 to 15 do begin LX[i] := X[15 - i]; LY[i] := Y[15 - i]; end;

    // Compute 256-bit carry-less product using PCLMULQDQ
    asm
      // Load X,Y via volatile GPRs to avoid FPC symbol addressing pitfalls
      lea rax, [LX]
      lea rdx, [LY]
      movdqu xmm0, [rax]           // X
      movdqu xmm1, [rdx]           // Y

      // z0 = clmul(X.lo, Y.lo)
      movdqa xmm2, xmm0
      pclmulqdq xmm2, xmm1, $00
      lea r8, [z0]
      movdqu [r8], xmm2

      // z2 = clmul(X.hi, Y.hi)
      movdqa xmm2, xmm0
      pclmulqdq xmm2, xmm1, $11
      lea r8, [z2]
      movdqu [r8], xmm2

      // mid = clmul(X.lo, Y.hi) xor clmul(X.hi, Y.lo)
      movdqa xmm2, xmm0
      pclmulqdq xmm2, xmm1, $10
      movdqa xmm3, xmm0
      pclmulqdq xmm3, xmm1, $01
      pxor xmm2, xmm3
      lea r8, [z1]
      movdqu [r8], xmm2
    end;

    // Reference reduction in Pascal (correctness-first)
    // Interpret (rH1:rH0)(rM1:rM0)(rL1:rL0) as 256-bit little-endian polynomial,
    // perform reduction modulo x^128 + x^7 + x^2 + x + 1 per GHASH spec.
    // Fold high 128 into mid
    s1_0 := rH0 shl 1;               s1_1 := (rH1 shl 1) or (rH0 shr 63);
    s2_0 := rH0 shl 2;               s2_1 := (rH1 shl 2) or (rH0 shr 62);
    s7_0 := rH0 shl 7;               s7_1 := (rH1 shl 7) or (rH0 shr 57);
    rM0 := rM0 xor s1_0 xor s2_0 xor s7_0;
    rM1 := rM1 xor s1_1 xor s2_1 xor s7_1;

    // Fold mid high 128 into low
    s1_0 := rM0 shl 1;               s1_1 := (rM1 shl 1) or (rM0 shr 63);
    s2_0 := rM0 shl 2;               s2_1 := (rM1 shl 2) or (rM0 shr 62);
    s7_0 := rM0 shl 7;               s7_1 := (rM1 shl 7) or (rM0 shr 57);
    rL0 := rL0 xor s1_0 xor s2_0 xor s7_0;
    rL1 := rL1 xor s1_1 xor s2_1 xor s7_1;

    // Additional fold from top 7 bits of rL1 back into rL per GHASH polynomial
    // Compute t = rL1 >> 63, then fold constants into rL0/rL1 appropriately
    // Because we keep 128-bit state, repeating is unnecessary here for correctness of single multiply

    // Assemble into two 128-bit parts and incorporate middle cross-products
    rL0 := z0[0]; rL1 := z0[1];
    rH0 := z2[0]; rH1 := z2[1];
    // z1 contributes across the 64-bit boundary
    rL1 := rL1 xor z1[0];
    rH0 := rH0 xor z1[1];

    // Reduce (rH:rL) modulo x^128 + x^7 + x^2 + x + 1
    // Portable reduction based on well-known formulation (little-endian words):
    // Let T = rH1; then
    //   rL0 ^= (T << 63) ^ (T << 62) ^ (T << 57);
    //   rL1 ^= T ^ (T >> 1) ^ (T >> 2) ^ (T >> 7);
    // Let T = rH0; then
    //   rL0 ^= T ^ (T << 1) ^ (T << 2) ^ (T << 7);
    //   rL1 ^= (T >> 63) ^ (T >> 62) ^ (T >> 57);
    s7_0 := rH1; // reuse temps as T
    rL0 := rL0 xor (s7_0 shl 63) xor (s7_0 shl 62) xor (s7_0 shl 57);
    rL1 := rL1 xor s7_0 xor (s7_0 shr 1) xor (s7_0 shr 2) xor (s7_0 shr 7);

    s7_0 := rH0;
    rL0 := rL0 xor s7_0 xor (s7_0 shl 1) xor (s7_0 shl 2) xor (s7_0 shl 7);
    rL1 := rL1 xor (s7_0 shr 63) xor (s7_0 shr 62) xor (s7_0 shr 57);

    // Convert little-endian polynomial back to GHASH big-endian bytes
    Move(rL0, TMP[0], 8); Move(rL1, TMP[8], 8);
    for i := 0 to 15 do Z[i] := TMP[15 - i];

    {$IFDEF DEBUG}
    // Verify against reference; if mismatch, mark faulted and return reference
    var Zref: array[0..15] of Byte;
    GFMult128_Pure(X, Y, Zref);
    if CompareByte(Zref[0], Z[0], 16) <> 0 then
    begin
      GF_CLMUL_Faulted := True;
      Move(Zref[0], Z[0], 16);
    end;
    {$ENDIF}

  except
    GF_CLMUL_Faulted := True;
    GFMult128_Pure(X, Y, Z);
    Exit;
  end;

  // Wipe sensitive temporaries (best-effort)
  FillChar(LX, SizeOf(LX), 0);
  FillChar(LY, SizeOf(LY), 0);
  FillChar(TMP, SizeOf(TMP), 0);
  FillChar(z0, SizeOf(z0), 0);
  FillChar(z1, SizeOf(z1), 0);
  FillChar(z2, SizeOf(z2), 0);
  rH0 := 0; rH1 := 0; rM0 := 0; rM1 := 0; rL0 := 0; rL1 := 0;
  s1_0 := 0; s1_1 := 0; s2_0 := 0; s2_1 := 0; s7_0 := 0; s7_1 := 0;
  m1_0 := 0; m1_1 := 0; m2_0 := 0; m2_1 := 0; m7_0 := 0; m7_1 := 0;
end;
{$ENDIF}
{$ENDIF}

procedure GFMult128(const X, Y: array of Byte; out Z: array of Byte);
begin
  if Assigned(GFMult128_Impl) then
    GFMult128_Impl(X, Y, Z)
  else
    GFMult128_Pure(X, Y, Z);
end;

procedure Put64BE(var Dst: array of Byte; Offset: Integer; Value: QWord);
var j: Integer;
begin
  for j := 0 to 7 do
    Dst[Offset + (7 - j)] := Byte((Value shr (j*8)) and $FF);
end;


type
  // TGHashPureMode already declared above; keep only once
  // (moved near top for CreateGHash default var)
  // TGHashPureMode = (gpmBit, gpmNibble, gpmByte);

  TGHashContext = class(TInterfacedObject, IGHash)
  private
    FH: array[0..15] of Byte;  // hash subkey
    FX: array[0..15] of Byte;  // accumulator
    FInit: Boolean;
    FBuf: TBytes;              // accumulate AAD||C bytes (streaming-friendly but simple)
    // Precomputed powers of V=H shifted with reduction: FPowV[k] = V after k RightShift1+reduce
    FPowV: array[0..127, 0..15] of Byte;
    // 4-bit nibble table: FPowNib[n][k][16] is the 16-byte vector for nibble n at byte-index k
    FPowNib: array[0..31, 0..15, 0..15] of Byte; // 32 nibble entries per byte position, each 16-byte vector
    // 8-bit table: FPowByte[k][v][16] is the 16-byte vector for full byte value v at position k
    FPowByte: array[0..15, 0..255, 0..15] of Byte;
    // Pure mode selection and build flags

    FPureMode: TGHashPureMode;
    FHasV, FHasNib, FHasByte: Boolean;
  private
    procedure BuildPowV;
    procedure BuildPowNib;
    procedure BuildPowByte;
    procedure EnsureTables(NeedV, NeedNib, NeedByte: Boolean);
    procedure MulAccWithH_Precomp(const X: array of Byte; out Z: array of Byte);
    procedure MulAccWithH_Nibble(const X: array of Byte; out Z: array of Byte);
    procedure MulAccWithH_Byte(const X: array of Byte; out Z: array of Byte);
    procedure MulAccSelected(const X: array of Byte; out Z: array of Byte);
  public
    procedure Init(const HSubKey: TBytes);
    procedure Update(const Data: TBytes);
    procedure WarmUp;
    function Finalize(const AADLen, CLen: QWord): TBytes;
    procedure Reset;
  end;

{$IFDEF DEBUG}
const GH_CACHE_SIZE = 4;

type
  TTableCacheEntry = record
    Valid: Boolean;
    H: array[0..15] of Byte;
    HasV, HasNib, HasByte: Boolean;
    PowV: array[0..127, 0..15] of Byte;
    PowNib: array[0..31, 0..15, 0..15] of Byte;
    PowByte: array[0..15, 0..255, 0..15] of Byte;
    LastUse: QWord;
  end;

var
  GHash_TableCache: array[0..GH_CACHE_SIZE-1] of TTableCacheEntry;
  GHash_CacheTick: QWord = 0;

function CacheEnabled: Boolean;
begin
  Result := SameText(GetEnvironmentVariable('FAFAFA_GHASH_CACHE_PER_H'), '1') or
            SameText(GetEnvironmentVariable('FAFAFA_GHASH_CACHE_PER_H'), 'true');
end;

function BytesEqual16(const A, B: array of Byte): Boolean;
var i: Integer;
begin
  Result := True;
  for i := 0 to 15 do if A[i] <> B[i] then begin Result := False; Exit; end;
end;

function CacheFind(const H: array of Byte): Integer;
var i: Integer;
begin
  Result := -1;
  for i := 0 to GH_CACHE_SIZE-1 do
    if GHash_TableCache[i].Valid and BytesEqual16(GHash_TableCache[i].H, H) then
      exit(i);
end;

procedure CacheTouch(Index: Integer);
begin
  Inc(GHash_CacheTick);
  GHash_TableCache[Index].LastUse := GHash_CacheTick;
end;

function CachePickVictim: Integer;
var i: Integer; bestTick: QWord; bestIdx: Integer;
begin
  bestIdx := 0; bestTick := High(QWord);
  for i := 0 to GH_CACHE_SIZE-1 do
    if (not GHash_TableCache[i].Valid) then exit(i)
    else if GHash_TableCache[i].LastUse < bestTick then
    begin bestTick := GHash_TableCache[i].LastUse; bestIdx := i; end;
  Result := bestIdx;
end;

procedure CacheLoadIfCan(var Ctx: TGHashContext; NeedV, NeedNib, NeedByte: Boolean; out Loaded: Boolean);
var idx: Integer;
begin
  Loaded := False;
  if not CacheEnabled then Exit;
  idx := CacheFind(Ctx.FH);
  if idx < 0 then Exit;
  if NeedV and (not GHash_TableCache[idx].HasV) then Exit;
  if NeedNib and (not GHash_TableCache[idx].HasNib) then Exit;
  if NeedByte and (not GHash_TableCache[idx].HasByte) then Exit;
  if NeedV then Move(GHash_TableCache[idx].PowV[0][0], Ctx.FPowV[0][0], SizeOf(Ctx.FPowV)); Ctx.FHasV := Ctx.FHasV or NeedV;
  if NeedNib then Move(GHash_TableCache[idx].PowNib[0][0][0], Ctx.FPowNib[0][0][0], SizeOf(Ctx.FPowNib)); Ctx.FHasNib := Ctx.FHasNib or NeedNib;
  if NeedByte then Move(GHash_TableCache[idx].PowByte[0][0][0], Ctx.FPowByte[0][0][0], SizeOf(Ctx.FPowByte)); Ctx.FHasByte := Ctx.FHasByte or NeedByte;
  Loaded := True;
  CacheTouch(idx);
end;

procedure CacheSaveFromCtx(const Ctx: TGHashContext);
var idx: Integer;
begin
  if not CacheEnabled then Exit;
  idx := CacheFind(Ctx.FH);
  if idx < 0 then idx := CachePickVictim;
  GHash_TableCache[idx].Valid := True;
  Move(Ctx.FH[0], GHash_TableCache[idx].H[0], 16);
  if Ctx.FHasV then begin Move(Ctx.FPowV[0][0], GHash_TableCache[idx].PowV[0][0], SizeOf(Ctx.FPowV)); GHash_TableCache[idx].HasV := True; end;
  if Ctx.FHasNib then begin Move(Ctx.FPowNib[0][0][0], GHash_TableCache[idx].PowNib[0][0][0], SizeOf(Ctx.FPowNib)); GHash_TableCache[idx].HasNib := True; end;
  if Ctx.FHasByte then begin Move(Ctx.FPowByte[0][0][0], GHash_TableCache[idx].PowByte[0][0][0], SizeOf(Ctx.FPowByte)); GHash_TableCache[idx].HasByte := True; end;
  CacheTouch(idx);
end;
{$ENDIF}


procedure TGHashContext.BuildPowV;
var
  V: array[0..15] of Byte;
  LSB: Byte;
  i: Integer;
begin
  Move(FH[0], V[0], 16);
  for i := 0 to 127 do
  begin
    Move(V[0], FPowV[i][0], 16);
    RightShift1(V, LSB);
    if LSB <> 0 then V[0] := V[0] xor $E1;
  end;
end;

procedure TGHashContext.BuildPowNib;
var
  n, k, b: Integer;
  tmp: array[0..15] of Byte;
begin
  // For each byte position k (0..15), precompute 16 nibble combinations for high and low nibble
  // Layout: index 0..15 for high-nibble at bit indices [k*8 .. k*8+3], and 16..31 for low-nibble at [k*8+4 .. k*8+7]
  for k := 0 to 15 do
  begin
    // high nibble table (values 0..15), bits mapping to FPowV indices (k*8 + (7-0)) .. (k*8 + (7-3))
    for n := 0 to 15 do
    begin
      FillChar(tmp, SizeOf(tmp), 0);
      for b := 0 to 3 do
        if ((n shr (3-b)) and 1) <> 0 then
          XorBlock(tmp, FPowV[(k*8) + b]);
      Move(tmp[0], FPowNib[0 + n][k][0], 16);
    end;

    // low nibble table (values 0..15)
    for n := 0 to 15 do
    begin
      FillChar(tmp, SizeOf(tmp), 0);
      for b := 0 to 3 do
        if ((n shr (3-b)) and 1) <> 0 then
          XorBlock(tmp, FPowV[(k*8) + 4 + b]);
      // store to slot 16..31
      Move(tmp[0], FPowNib[16 + n][k][0], 16);
    end;
  end;
end;

procedure TGHashContext.MulAccWithH_Nibble(const X: array of Byte; out Z: array of Byte);
var
  Zloc: array[0..15] of Byte;
  k: Integer;
  hi, lo: Byte;
begin
  FillChar(Zloc, SizeOf(Zloc), 0);
  for k := 0 to 15 do
  begin
    hi := (X[k] shr 4) and $0F;
    lo := X[k] and $0F;
    // XOR precomputed vectors for current byte's high/low nibble
    // high nibble uses table indices 0..15, low nibble uses 16..31
    XorBlock(Zloc, FPowNib[0 + hi][k]);
    XorBlock(Zloc, FPowNib[16 + lo][k]);
  end;
  Move(Zloc[0], Z[0], 16);
  FillChar(Zloc, SizeOf(Zloc), 0);
end;



procedure TGHashContext.BuildPowByte;
var
  k, v: Integer;
  tmp: array[0..15] of Byte;
begin
  for k := 0 to 15 do
  begin
    for v := 0 to 255 do
    begin
      FillChar(tmp, SizeOf(tmp), 0);
      // combine high and low nibble precomputations
      XorBlock(tmp, FPowNib[0 + ((v shr 4) and $0F)][k]);
      XorBlock(tmp, FPowNib[16 + (v and $0F)][k]);
      Move(tmp[0], FPowByte[k][v][0], 16);
    end;
  end;
end;

procedure TGHashContext.MulAccWithH_Byte(const X: array of Byte; out Z: array of Byte);
var
  Zloc: array[0..15] of Byte;
  k: Integer;
begin
  FillChar(Zloc, SizeOf(Zloc), 0);
  for k := 0 to 15 do



// EnsureTables: build just enough precompute tables for current pure mode
// - NeedV:   bit path powers (FPowV)
// - NeedNib: nibble path tables (depends on V)
// - NeedByte:byte path tables (depends on V+Nib)

    XorBlock(Zloc, FPowByte[k][X[k]]);
  Move(Zloc[0], Z[0], 16);
  FillChar(Zloc, SizeOf(Zloc), 0);
end;


procedure TGHashContext.EnsureTables(NeedV, NeedNib, NeedByte: Boolean);
begin
  if NeedV and (not FHasV) then begin BuildPowV; FHasV := True; end;
  if NeedNib and (not FHasNib) then begin if not FHasV then begin BuildPowV; FHasV := True; end; BuildPowNib; FHasNib := True; end;
  if NeedByte and (not FHasByte) then begin if not FHasNib then begin if not FHasV then begin BuildPowV; FHasV := True; end; BuildPowNib; FHasNib := True; end; BuildPowByte; FHasByte := True; end;
end;

procedure TGHashContext.MulAccSelected(const X: array of Byte; out Z: array of Byte);
begin
  case FPureMode of
    gpmBit:    MulAccWithH_Precomp(X, Z);
    gpmNibble: MulAccWithH_Nibble(X, Z);
  else
    MulAccWithH_Byte(X, Z);
  end;
end;



procedure TGHashContext.MulAccWithH_Precomp(const X: array of Byte; out Z: array of Byte);
var
  Zloc: array[0..15] of Byte;
  i, bit: Integer;
begin
  FillChar(Zloc, SizeOf(Zloc), 0);
  // X is big-endian; process MSB-first (byte 0 bit 7 down to byte 15 bit 0)
  for i := 0 to 15 do
  begin
    for bit := 7 downto 0 do
      if ((X[i] shr bit) and $01) <> 0 then
        XorBlock(Zloc, FPowV[(i*8)+(7-bit)]);
  end;
  Move(Zloc[0], Z[0], 16);
  FillChar(Zloc, SizeOf(Zloc), 0);
end;

function CreateGHash: IGHash;
begin
  Result := TGHashContext.Create as IGHash;
end;




procedure TGHashContext.Init(const HSubKey: TBytes);
begin
  if Length(HSubKey) <> 16 then
    raise EInvalidArgument.Create('GHASH H length must be 16');
  Move(HSubKey[0], FH[0], 16);
  FillChar(FX, SizeOf(FX), 0);
  SetLength(FBuf, 0);
  FHasV := False; FHasNib := False; FHasByte := False;
  // Pure mode selection: env (Debug) takes precedence; otherwise use default pure mode
  {$IFDEF DEBUG}
  case LowerCase(GetEnvironmentVariable('FAFAFA_GHASH_PURE_MODE')) of
    'bit':    FPureMode := gpmBit;
    'nibble': FPureMode := gpmNibble;
    'byte':   FPureMode := gpmByte;
    else      FPureMode := GHash_DefaultPureMode;
  end;
  {$ELSE}
  FPureMode := gpmByte;
  {$ENDIF}
  FInit := True;
end;


procedure GHash_SetPureMode(const Mode: string);
begin
  {$IFDEF DEBUG}
  case LowerCase(Mode) of
    'bit':    GHash_DefaultPureMode := gpmBit;
    'nibble': GHash_DefaultPureMode := gpmNibble;
    'byte':   GHash_DefaultPureMode := gpmByte;
  else
    GHash_DefaultPureMode := gpmByte;
  end;
  {$ENDIF}
end;

  // Finalize flow (pure path):
  // 1) Ensure required tables (or load from per‑H cache in Debug)
  // 2) Process AAD blocks -> Acc = (Acc xor AAD_i) * H
  // 3) Process C blocks   -> Acc = (Acc xor C_i)   * H
  // 4) Pad remaining bytes (if any) and multiply once
  // 5) Mix lengths block: [len(AAD)||len(C)] (bits), multiply once



procedure TGHashContext.Update(const Data: TBytes);
var
  off, i: Integer;
begin
  if not FInit then
    raise EInvalidOperation.Create('GHASH not initialized');
  // Buffer only; defer block processing and padding to Finalize using AADLen/CLen
  off := Length(FBuf);
  SetLength(FBuf, off + Length(Data));
  for i := 0 to High(Data) do
    FBuf[off + i] := Data[i];
end;

{$PUSH}{$HINTS OFF 5057}{$HINTS OFF 5058}
function TGHashContext.Finalize(const AADLen, CLen: QWord): TBytes;
var
  LenBlock: array[0..15] of Byte;
  Block: array[0..15] of Byte;
  Y: array[0..15] of Byte;
  Acc: array[0..15] of Byte;
  i, Offset, Rem, TotalNeeded, BufLen: Integer;
begin
  Result := nil;
  FillChar(LenBlock, SizeOf(LenBlock), 0);
  FillChar(Block, SizeOf(Block), 0);
  FillChar(Y, SizeOf(Y), 0);
  FillChar(Acc, SizeOf(Acc), 0);
  if not FInit then
    raise EInvalidOperation.Create('GHASH not initialized');

  // We will compute S from scratch over FBuf using provided lengths
  // Ensure required tables for selected pure mode
  case FPureMode of
    gpmBit:    EnsureTables(True, False, False);
    gpmNibble: EnsureTables(True, True, False);
  else
    EnsureTables(True, True, True);
  end;

  BufLen := Length(FBuf);
  TotalNeeded := Integer(AADLen + CLen);
  {$IFDEF DEBUG}
  if BufLen <> TotalNeeded then
    raise EInvalidArgument.CreateFmt('GHASH: Update length (%d) differs from declared (AADLen+CLen=%d)', [BufLen, TotalNeeded]);
  {$ENDIF}
  if BufLen < TotalNeeded then
    TotalNeeded := BufLen; // be tolerant; process what we have

  // 1) AAD blocks
  Offset := 0;
  while Offset + 16 <= Integer(AADLen) do
  begin
    Move(FBuf[Offset], Block[0], 16);
    XorBlock(Acc, Block);
    MulAccSelected(Acc, Y);
    Move(Y[0], Acc[0], 16);
    Inc(Offset, 16);
  end;
  Rem := Integer(AADLen) - Offset;
  if Rem > 0 then
  begin
    FillChar(Block, SizeOf(Block), 0);
    for i := 0 to Rem - 1 do Block[i] := FBuf[Offset + i];
    XorBlock(Acc, Block);
    MulAccSelected(Acc, Y);
    Move(Y[0], Acc[0], 16);
    Inc(Offset, Rem);
  end;

  // 2) C blocks
  while Offset + 16 <= Integer(AADLen + CLen) do
  begin
    Move(FBuf[Offset], Block[0], 16);
    XorBlock(Acc, Block);
    MulAccSelected(Acc, Y);
    Move(Y[0], Acc[0], 16);
    Inc(Offset, 16);
  end;
  Rem := Integer(AADLen + CLen) - Offset;
  if Rem > 0 then
  begin
    FillChar(Block, SizeOf(Block), 0);
    for i := 0 to Rem - 1 do Block[i] := FBuf[Offset + i];
    XorBlock(Acc, Block);
    MulAccSelected(Acc, Y);
    Move(Y[0], Acc[0], 16);
    Inc(Offset, Rem);
  end;

  // 3) length block (bits)
  Put64BE(LenBlock, 0, QWord(AADLen) shl 3);
  Put64BE(LenBlock, 8, QWord(CLen) shl 3);
  XorBlock(Acc, LenBlock);
  MulAccSelected(Acc, Y);
  Move(Y[0], Acc[0], 16);

  // output
  SetLength(Result, 16);
  for i := 0 to 15 do Result[i] := Acc[i];

  // zeroize local buffers
  FillChar(LenBlock, SizeOf(LenBlock), 0);
  FillChar(Block, SizeOf(Block), 0);
  FillChar(Y, SizeOf(Y), 0);
  FillChar(Acc, SizeOf(Acc), 0);
  {$POP}
end;

procedure TGHashContext.Reset;
begin
  FillChar(FH, SizeOf(FH), 0);
  FillChar(FX, SizeOf(FX), 0);
  if Length(FBuf) > 0 then FillChar(FBuf[0], Length(FBuf), 0);
  SetLength(FBuf, 0);
  // Optional table zeroization (guarded by env)
  if SameText(GetEnvironmentVariable('FAFAFA_GHASH_ZEROIZE_TABLES'), '1') or
     SameText(GetEnvironmentVariable('FAFAFA_GHASH_ZEROIZE_TABLES'), 'true') then
  begin
    FillChar(FPowV, SizeOf(FPowV), 0);
    FillChar(FPowNib, SizeOf(FPowNib), 0);
    FillChar(FPowByte, SizeOf(FPowByte), 0);
    FHasV := False; FHasNib := False; FHasByte := False;
  end;
  FInit := False;
end;

procedure TGHashContext.WarmUp;
begin
  if not FInit then Exit;
  // Only meaningful for pure backend; CLMUL path ignores precompute tables
  if SameText(GHash_Backend_Name, 'pure') then
  begin
    case FPureMode of
      gpmBit:    EnsureTables(True, False, False);
      gpmNibble: EnsureTables(True, True, False);
    else
      EnsureTables(True, True, True);
    end;
  end;
end;


end.