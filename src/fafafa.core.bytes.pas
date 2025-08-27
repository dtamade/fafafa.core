unit fafafa.core.bytes;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{*
  fafafa.core.bytes — 通用字节序列工具

  目标（v0）
  - Hex 编解码（严格/宽松）
  - 基础切片/拼接/清零
  - 端序读写（LE/BE，u16/u32/u64）
  - TBytesBuilder（累加器，近似 Go bytes.Buffer / Netty ByteBuf 简化）

  设计要点
  - 接口优先，异常统一到 fafafa.core.base（EInvalidArgument/EOutOfRange）
  - 不依赖 crypto 子系统；与平台无关
  - 零分配偏好：读操作不分配；写操作尽量原位，超界抛出
*}

interface

uses
  SysUtils, Classes,
  fafafa.core.base;

type
  // 重新导出常用异常，便于调用方只 uses 本单元
  EInvalidArgument  = fafafa.core.base.EInvalidArgument;
  EOutOfRange       = fafafa.core.base.EOutOfRange;
  EOverflow         = fafafa.core.base.EOverflow;
  EInvalidOperation = fafafa.core.base.EInvalidOperation;
  EArgumentNil      = fafafa.core.base.EArgumentNil;

  // ---- 统一 IO 抽象（最小接口） ----------------------------------------------
  IByteSink = interface
    ['{6E7D4C82-7B1F-49C6-8B0E-7E0C8A9CF6E2}']
    function Write(const P: Pointer; Count: SizeInt): SizeInt;
    function WriteBytes(const B: TBytes): SizeInt;
    function WriteByte(Value: Byte): SizeInt;
  end;

  IByteSource = interface
    ['{2F7B8F0A-3B08-4E37-9E42-3D7F5C8D2C11}']
    function Read(P: Pointer; Count: SizeInt): SizeInt;
  end;

// ---- Hex 编解码 ------------------------------------------------------------
function BytesToHex(const A: TBytes): string;
function BytesToHexUpper(const A: TBytes): string;
function HexFromBytes(const A: TBytes): string; inline; // 别名：更直观
// 严格：仅接受偶数长度 [0-9a-fA-F]，其它报错
function HexToBytes(const S: string): TBytes;
function BytesFromHex(const S: string): TBytes; inline; // 别名：更直观
// 非异常的严格解码：偶数长度且仅 [0-9a-fA-F]，否则返回 False
function TryHexToBytesStrict(const S: string; out B: TBytes): Boolean;
// 宽松：忽略空白与常见前缀（0x/#），非法返回 False（语义同 TryHexToBytesLoose）
function TryParseHexLoose(const S: string; out B: TBytes): Boolean;
// 兼容旧名（建议新代码使用 TryParseHexLoose）
function TryHexToBytesLoose(const S: string; out B: TBytes): Boolean; inline;

// ---- 基础操作 --------------------------------------------------------------
function BytesSlice(const A: TBytes; AIndex, ACount: SizeInt): TBytes;
function BytesConcat(const A, B: TBytes): TBytes; overload;
function BytesConcat(const Parts: array of TBytes): TBytes; overload;
procedure BytesZero(var A: TBytes);
procedure SecureBytesZero(var A: TBytes);

// ---- 端序读写（越界抛出 EOutOfRange）--------------------------------------
function ReadU16LE(const A: TBytes; AOffset: SizeInt): UInt16; overload;
function ReadU16BE(const A: TBytes; AOffset: SizeInt): UInt16; overload;
function ReadU32LE(const A: TBytes; AOffset: SizeInt): UInt32; overload;
function ReadU32BE(const A: TBytes; AOffset: SizeInt): UInt32; overload;
function ReadU64LE(const A: TBytes; AOffset: SizeInt): UInt64; overload;
function ReadU64BE(const A: TBytes; AOffset: SizeInt): UInt64; overload;
// 带游标的读取（成功则推进 Off，越界抛 EOutOfRange）
function ReadU16LEAdv(const A: TBytes; var Off: SizeInt): UInt16;
function ReadU16BEAdv(const A: TBytes; var Off: SizeInt): UInt16;
function ReadU32LEAdv(const A: TBytes; var Off: SizeInt): UInt32;
function ReadU32BEAdv(const A: TBytes; var Off: SizeInt): UInt32;
function ReadU64LEAdv(const A: TBytes; var Off: SizeInt): UInt64;
function ReadU64BEAdv(const A: TBytes; var Off: SizeInt): UInt64;

procedure WriteU16LE(var A: TBytes; AOffset: SizeInt; AValue: UInt16);
procedure WriteU16BE(var A: TBytes; AOffset: SizeInt; AValue: UInt16);
procedure WriteU32LE(var A: TBytes; AOffset: SizeInt; AValue: UInt32);
procedure WriteU32BE(var A: TBytes; AOffset: SizeInt; AValue: UInt32);
procedure WriteU64LE(var A: TBytes; AOffset: SizeInt; AValue: UInt64);
procedure WriteU64BE(var A: TBytes; AOffset: SizeInt; AValue: UInt64);

// ---- BytesBuilder ----------------------------------------------------------
// 说明：
// - Append* 自动扩容（按 1.5~2 倍）
// - ToBytes 返回拷贝（避免外部修改内部缓冲）
// - Clear 仅重置长度，不收缩容量
// - 不做线程安全保证

type
  TBytesBuilder = record
  private
    FBuf: TBytes;
    FLen: SizeInt;
    FWriteAvail: SizeInt;
    FHasPendingWrite: Boolean;
  public
    // capacity management
    procedure Init(ACapacity: SizeInt = 0);
    procedure Clear; inline; // alias of Reset
    procedure Reset; inline; // synonym of Clear
    function Length: SizeInt; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
    function Capacity: SizeInt; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
    procedure EnsureCapacity(ACapacity: SizeInt);
    procedure Reserve(ACapacity: SizeInt); inline; // alias to EnsureCapacity
    procedure ReserveExact(ACapacity: SizeInt);
    procedure Grow(AMinAdd: SizeInt);
    procedure Truncate(ANewLen: SizeInt);
    procedure ShrinkToFit;

    // in-place write
    procedure BeginWrite(ARequest: SizeInt; out P: Pointer; out Granted: SizeInt);
    function TryBeginWrite(ARequest: SizeInt; out P: Pointer; out Granted: SizeInt): Boolean;
    procedure Commit(AWritten: SizeInt);
    procedure EnsureWritable(AMinAdd: SizeInt);

    // appends
    procedure Append(const B: TBytes); overload;
    procedure Append(const P: Pointer; Count: SizeInt); overload;
    procedure AppendByte(Value: Byte);
    procedure AppendU16LE(Value: UInt16);
    procedure AppendU16BE(Value: UInt16);
    procedure AppendU32LE(Value: UInt32);
    procedure AppendU32BE(Value: UInt32);
    procedure AppendU64LE(Value: UInt64);
    procedure AppendU64BE(Value: UInt64);
    procedure AppendString(const S: RawByteString);
    // 严格：S 必须是偶数且只包含 [0-9a-fA-F]
    procedure AppendHex(const S: string);
    // 高性能批量填充
    procedure AppendFill(Value: Byte; Count: SizeInt);
    // 高性能批量复制（重复模式）
    procedure AppendRepeat(const Pattern: TBytes; Times: SizeInt);

    // extraction / borrowing
    function ToBytes: TBytes;                 // copy
    function DetachRaw(out UsedLen: SizeInt): TBytes; deprecated 'Use DetachTrim (may shrink/copy) or DetachNoTrim for strict zero-copy';
    function DetachTrim(out UsedLen: SizeInt): TBytes;   // shrink to used length (may copy); transfers buffer
    function DetachNoTrim(out UsedLen: SizeInt): TBytes; // strict zero-copy (no shrink), transfers buffer
    function IntoBytes: TBytes;               // try zero-copy if perfectly sized; else copy

    // borrow
    procedure Peek(out P: Pointer; out UsedLen: SizeInt); // borrow read-only pointer valid until next mutating call

    // stream interop (deprecated; use WriteToSink/ReadFromSource with IByteSink/IByteSource)
    function WriteToStream(const AStream: TStream): Int64; deprecated 'Use WriteToSink with TStreamSink';

    function ReadFromStream(const AStream: TStream; Count: Int64 = -1): Int64; deprecated 'Use ReadFromSource with TStreamSource';
  end;

function WriteToSink(var BB: TBytesBuilder; const Sink: IByteSink; AChunkSize: SizeInt = 64*1024): Int64;
function ReadFromSource(var BB: TBytesBuilder; const Src: IByteSource; Count: Int64 = -1; AChunkSize: SizeInt = 64*1024): Int64;

// ---- IByteSink/IByteSource 基础适配 -----------------------------------------

// 在 implementation 部分提供适配实现

implementation

// ---- helpers ----
function IsHexChar(ch: Char): Boolean; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
begin
  Result := ((ch >= '0') and (ch <= '9')) or
            ((ch >= 'a') and (ch <= 'f')) or
            ((ch >= 'A') and (ch <= 'F'));
end;

function HexNibble(ch: Char): Byte; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
begin
  case ch of
    '0'..'9': Result := Byte(Ord(ch) - Ord('0'));
    'a'..'f': Result := Byte(Ord(ch) - Ord('a') + 10);
    'A'..'F': Result := Byte(Ord(ch) - Ord('A') + 10);
  else
    raise EInvalidArgument.Create('Invalid hex char');
  end;
end;

// ---- Hex 编解码 ----
function BytesToHex(const A: TBytes): string;
const HEX: PChar = '0123456789abcdef';
var i, n: SizeInt;
begin
  Result := '';
  n := Length(A);
  SetLength(Result, n * 2);
  if n = 0 then Exit;
  for i := 0 to n - 1 do
  begin
    Result[i*2+1] := HEX[(A[i] shr 4) and $F];
    Result[i*2+2] := HEX[A[i] and $F];
  end;
end;

function BytesToHexUpper(const A: TBytes): string;
const HEXU: PChar = '0123456789ABCDEF';
var i, n: SizeInt;
begin
  Result := '';
  n := Length(A);
  SetLength(Result, n * 2);
  if n = 0 then Exit;
  for i := 0 to n - 1 do
  begin
    Result[i*2+1] := HEXU[(A[i] shr 4) and $F];
    Result[i*2+2] := HEXU[A[i] and $F];
  end;
end;

function HexFromBytes(const A: TBytes): string; inline;
begin
  Result := BytesToHex(A);
end;

function HexToBytes(const S: string): TBytes;
var ok: Boolean; tmp: TBytes;
begin
  ok := TryHexToBytesStrict(S, tmp);
  if not ok then
  begin
    // 区分两类错误：奇数长度 -> EInvalidArgument；非法字符 -> EInvalidArgument（统一异常类型）
    if (Length(S) and 1) <> 0 then
      raise EInvalidArgument.Create('Hex string must have even length')
    else
      raise EInvalidArgument.Create('Invalid hex digit');
  end;
  Result := tmp;
end;

// ---- IByteSink/IByteSource 基础适配（实现） ---------------------------------
function WriteToSink(var BB: TBytesBuilder; const Sink: IByteSink; AChunkSize: SizeInt = 64*1024): Int64;
var P: Pointer; N: SizeInt; wrote: SizeInt;
begin
  if Sink = nil then raise EArgumentNil.Create('sink=nil');
  BB.Peek(P, N);
  if (P = nil) or (N = 0) then Exit(0);
  Result := 0;
  while N > 0 do
  begin
    wrote := Sink.Write(P, N);
    if wrote <= 0 then Exit;
    Inc(Result, wrote);
    Inc(PByte(P), wrote);
    Dec(N, wrote);
  end;
end;

function ReadFromSource(var BB: TBytesBuilder; const Src: IByteSource; Count: Int64 = -1; AChunkSize: SizeInt = 64*1024): Int64;
var toRead, want: Int64; p: Pointer; granted: SizeInt; r: SizeInt;
begin
  if Src = nil then raise EArgumentNil.Create('src=nil');
  Result := 0;
  if Count < 0 then
  begin
    repeat
      want := AChunkSize;
      if want <= 0 then want := 1;
      BB.BeginWrite(SizeInt(want), p, granted);
      if granted = 0 then Break;
      r := Src.Read(p, granted);
      if r <= 0 then begin BB.Commit(0); Break; end;
      BB.Commit(r);
      Inc(Result, r);
    until False;
  end
  else
  begin
    toRead := Count;
    while toRead > 0 do
    begin
      want := AChunkSize; if want <= 0 then want := 1; if want > toRead then want := toRead;

      BB.BeginWrite(SizeInt(want), p, granted);
      if granted = 0 then Break;
      if granted > want then granted := SizeInt(want);
      r := Src.Read(p, granted);
      if r <= 0 then begin BB.Commit(0); Break; end;
      BB.Commit(r);
      Inc(Result, r);
      Dec(toRead, r);
    end;
  end;
end;



function TryHexToBytesStrict(const S: string; out B: TBytes): Boolean;
var i, n, L: SizeInt; ch1, ch2: Char;
begin
  SetLength(B, 0);
  L := Length(S);
  if (L = 0) then begin Result := True; Exit; end;
  if (L and 1) <> 0 then begin Result := False; Exit; end;
  SetLength(B, L div 2);
  n := Length(B);
  for i := 0 to n - 1 do
  begin
    ch1 := S[i*2+1]; ch2 := S[i*2+2];
    if (not IsHexChar(ch1)) or (not IsHexChar(ch2)) then
    begin
      SetLength(B, 0);
      Exit(False);
    end;
    B[i] := (HexNibble(ch1) shl 4) or HexNibble(ch2);
  end;
  Result := True;
end;

function BytesFromHex(const S: string): TBytes; inline;
begin
  Result := HexToBytes(S);
end;

function TryParseHexLoose(const S: string; out B: TBytes): Boolean;
var
  i, L: SizeInt;
  ch: Char;
  started: Boolean;
  haveHigh: Boolean;
  highNibble: Byte;
  outLen, cap: SizeInt;
  nib: Byte;
begin
  Result := False;
  SetLength(B, 0);
  L := Length(S);
  if L = 0 then begin Result := True; Exit; end;

  // Pre-allocate an upper bound capacity; will shrink at the end
  cap := L div 2;
  if cap > 0 then SetLength(B, cap);
  outLen := 0;
  started := False;
  haveHigh := False;
  highNibble := 0;

  i := 1;
  while i <= L do
  begin
    ch := S[i];

    // skip whitespace anywhere
    if ch <= ' ' then begin Inc(i); Continue; end;

    // handle prefixes only before any hex digit is consumed
    if (not started) and (not haveHigh) and (outLen = 0) then
    begin
      if ch = '#' then begin Inc(i); Continue; end;
      if (ch = '0') and (i < L) and ((S[i+1] = 'x') or (S[i+1] = 'X')) then
      begin Inc(i, 2); Continue; end;
    end;

    // hex digit?
    if IsHexChar(ch) then
    begin
      started := True;
      case ch of
        '0'..'9': nib := Byte(Ord(ch) - Ord('0'));
        'a'..'f': nib := Byte(Ord(ch) - Ord('a') + 10);
        'A'..'F': nib := Byte(Ord(ch) - Ord('A') + 10);
      else
        nib := 0; // guarded by IsHexChar
      end;

      if not haveHigh then
      begin
        highNibble := nib;
        haveHigh := True;
      end
      else
      begin
        // ensure capacity
        if outLen >= cap then
        begin
          if cap = 0 then cap := 1 else cap := cap + (cap shr 1);
          SetLength(B, cap);
        end;
        B[outLen] := (highNibble shl 4) or nib;
        Inc(outLen);
        haveHigh := False;
      end;

      Inc(i);
      Continue;
    end;

    // invalid non-hex, non-space, non-prefix char
    SetLength(B, 0);
    Exit(False);
  end;

  // odd number of hex digits => invalid
  if haveHigh then
  begin
    SetLength(B, 0);
    Exit(False);
  end;

  if outLen = 0 then
  begin
    SetLength(B, 0);
    Result := True;
  end
  else
  begin
    SetLength(B, outLen);
    Result := True;
  end;
end;

function TryHexToBytesLoose(const S: string; out B: TBytes): Boolean; inline;
begin
  Result := TryParseHexLoose(S, B);
end;

// ---- 基础操作 ----
function BytesSlice(const A: TBytes; AIndex, ACount: SizeInt): TBytes;
begin
  SetLength(Result, 0);
  // use subtraction-form bounds checks to avoid overflow
  if (AIndex < 0) or (ACount < 0) or (AIndex > Length(A)) or (ACount > Length(A) - AIndex) then
    raise EOutOfRange.Create('slice out of range');
  SetLength(Result, ACount);
  if ACount > 0 then
    Move(A[AIndex], Result[0], ACount);
end;

function BytesConcat(const A, B: TBytes): TBytes;
var LA, LB: SizeInt;
begin
  SetLength(Result, 0);
  LA := Length(A); LB := Length(B);
  SetLength(Result, LA + LB);
  if LA > 0 then Move(A[0], Result[0], LA);
  if LB > 0 then Move(B[0], Result[LA], LB);
end;

function BytesConcat(const Parts: array of TBytes): TBytes;
var i: SizeInt; total, off, n: SizeInt;
begin
  SetLength(Result, 0);
  total := 0;
  for i := 0 to High(Parts) do Inc(total, Length(Parts[i]));
  SetLength(Result, total);
  off := 0;
  for i := 0 to High(Parts) do
  begin
    n := Length(Parts[i]);
    if n > 0 then begin Move(Parts[i][0], Result[off], n); Inc(off, n); end;
  end;
end;

procedure BytesZero(var A: TBytes);
begin
  if Length(A) > 0 then FillChar(A[0], Length(A), 0);
end;


procedure SecureBytesZero(var A: TBytes);
begin
  if Length(A) = 0 then Exit;
  // Best-effort zeroization; use a pattern that compilers typically won't elide
  {$PUSH}
  {$OPTIMIZATION OFF}
  FillChar(A[0], Length(A), 0);
  {$POP}
end;

// ---- 边界检查 ----
procedure RequireWithin(const A: TBytes; AOffset, Need: SizeInt);
begin
  // subtraction-form to avoid potential overflow in AOffset + Need
  if (AOffset < 0) or (Need < 0) or (AOffset > Length(A)) or (Need > Length(A) - AOffset) then
    raise EOutOfRange.Create('offset out of range');
end;

// ---- 端序读 ----
function ReadU16LE(const A: TBytes; AOffset: SizeInt): UInt16;
begin
  RequireWithin(A, AOffset, 2);
  Result := UInt16(A[AOffset]) or (UInt16(A[AOffset+1]) shl 8);
end;

function ReadU16BE(const A: TBytes; AOffset: SizeInt): UInt16;
begin
  RequireWithin(A, AOffset, 2);
  Result := (UInt16(A[AOffset]) shl 8) or UInt16(A[AOffset+1]);
end;

function ReadU32LE(const A: TBytes; AOffset: SizeInt): UInt32;
begin
  RequireWithin(A, AOffset, 4);
  Result := UInt32(A[AOffset]) or (UInt32(A[AOffset+1]) shl 8) or
            (UInt32(A[AOffset+2]) shl 16) or (UInt32(A[AOffset+3]) shl 24);
end;

function ReadU32BE(const A: TBytes; AOffset: SizeInt): UInt32;
begin
  RequireWithin(A, AOffset, 4);
  Result := (UInt32(A[AOffset]) shl 24) or (UInt32(A[AOffset+1]) shl 16) or
            (UInt32(A[AOffset+2]) shl 8) or UInt32(A[AOffset+3]);
end;

function ReadU64LE(const A: TBytes; AOffset: SizeInt): UInt64;
begin
  RequireWithin(A, AOffset, 8);
  Result := UInt64(A[AOffset]) or (UInt64(A[AOffset+1]) shl 8) or
            (UInt64(A[AOffset+2]) shl 16) or (UInt64(A[AOffset+3]) shl 24) or
            (UInt64(A[AOffset+4]) shl 32) or (UInt64(A[AOffset+5]) shl 40) or
            (UInt64(A[AOffset+6]) shl 48) or (UInt64(A[AOffset+7]) shl 56);
end;


function ReadU16LEAdv(const A: TBytes; var Off: SizeInt): UInt16;
begin
  Result := ReadU16LE(A, Off);
  Inc(Off, 2);
end;

function ReadU16BEAdv(const A: TBytes; var Off: SizeInt): UInt16;
begin
  Result := ReadU16BE(A, Off);
  Inc(Off, 2);
end;

function ReadU32LEAdv(const A: TBytes; var Off: SizeInt): UInt32;
begin
  Result := ReadU32LE(A, Off);
  Inc(Off, 4);
end;

function ReadU32BEAdv(const A: TBytes; var Off: SizeInt): UInt32;
begin
  Result := ReadU32BE(A, Off);
  Inc(Off, 4);
end;

function ReadU64LEAdv(const A: TBytes; var Off: SizeInt): UInt64;
begin
  Result := ReadU64LE(A, Off);
  Inc(Off, 8);
end;

function ReadU64BEAdv(const A: TBytes; var Off: SizeInt): UInt64;
begin
  Result := ReadU64BE(A, Off);
  Inc(Off, 8);
end;

function ReadU64BE(const A: TBytes; AOffset: SizeInt): UInt64;
begin
  RequireWithin(A, AOffset, 8);
  Result := (UInt64(A[AOffset]) shl 56) or (UInt64(A[AOffset+1]) shl 48) or
            (UInt64(A[AOffset+2]) shl 40) or (UInt64(A[AOffset+3]) shl 32) or
            (UInt64(A[AOffset+4]) shl 24) or (UInt64(A[AOffset+5]) shl 16) or
            (UInt64(A[AOffset+6]) shl 8) or UInt64(A[AOffset+7]);
end;

// ---- 端序写 ----
procedure WriteU16LE(var A: TBytes; AOffset: SizeInt; AValue: UInt16);
begin
  RequireWithin(A, AOffset, 2);
  A[AOffset] := Byte(AValue and $FF);
  A[AOffset+1] := Byte((AValue shr 8) and $FF);
end;

procedure WriteU16BE(var A: TBytes; AOffset: SizeInt; AValue: UInt16);
begin
  RequireWithin(A, AOffset, 2);
  A[AOffset] := Byte((AValue shr 8) and $FF);
  A[AOffset+1] := Byte(AValue and $FF);
end;

procedure WriteU32LE(var A: TBytes; AOffset: SizeInt; AValue: UInt32);
begin
  RequireWithin(A, AOffset, 4);
  A[AOffset] := Byte(AValue and $FF);
  A[AOffset+1] := Byte((AValue shr 8) and $FF);
  A[AOffset+2] := Byte((AValue shr 16) and $FF);
  A[AOffset+3] := Byte((AValue shr 24) and $FF);
end;

procedure WriteU32BE(var A: TBytes; AOffset: SizeInt; AValue: UInt32);
begin
  RequireWithin(A, AOffset, 4);
  A[AOffset] := Byte((AValue shr 24) and $FF);
  A[AOffset+1] := Byte((AValue shr 16) and $FF);
  A[AOffset+2] := Byte((AValue shr 8) and $FF);
  A[AOffset+3] := Byte(AValue and $FF);
end;

procedure WriteU64LE(var A: TBytes; AOffset: SizeInt; AValue: UInt64);
begin
  RequireWithin(A, AOffset, 8);
  A[AOffset] := Byte(AValue and $FF);
  A[AOffset+1] := Byte((AValue shr 8) and $FF);
  A[AOffset+2] := Byte((AValue shr 16) and $FF);
  A[AOffset+3] := Byte((AValue shr 24) and $FF);
  A[AOffset+4] := Byte((AValue shr 32) and $FF);
  A[AOffset+5] := Byte((AValue shr 40) and $FF);
  A[AOffset+6] := Byte((AValue shr 48) and $FF);
  A[AOffset+7] := Byte((AValue shr 56) and $FF);
end;

procedure WriteU64BE(var A: TBytes; AOffset: SizeInt; AValue: UInt64);
begin
  RequireWithin(A, AOffset, 8);
  A[AOffset] := Byte((AValue shr 56) and $FF);
  A[AOffset+1] := Byte((AValue shr 48) and $FF);
  A[AOffset+2] := Byte((AValue shr 40) and $FF);
  A[AOffset+3] := Byte((AValue shr 32) and $FF);
  A[AOffset+4] := Byte((AValue shr 24) and $FF);
  A[AOffset+5] := Byte((AValue shr 16) and $FF);
  A[AOffset+6] := Byte((AValue shr 8) and $FF);
  A[AOffset+7] := Byte(AValue and $FF);
end;

procedure TBytesBuilder.Reserve(ACapacity: SizeInt);
begin
  EnsureCapacity(ACapacity);
end;


// ---- TBytesBuilder ----
procedure TBytesBuilder.Grow(AMinAdd: SizeInt);
var need, cap, newcap: SizeInt;
begin
  cap := System.Length(FBuf);
  if AMinAdd <= 0 then Exit;
  if (FLen < 0) then raise EOutOfRange.Create('negative length');
  // check overflow for need = FLen + AMinAdd
  need := FLen + AMinAdd;
  if (need < FLen) or (need < 0) then raise EOverflow.Create('length overflow');
  if AMinAdd <= cap - FLen then Exit;

  // 优化增长策略：小容量时快速增长，大容量时保守增长
  if cap < 64 then
    newcap := cap * 2  // 小容量时翻倍
  else if cap < 1024 then
    newcap := cap + (cap shr 1)  // 中等容量时 1.5x
  else
    newcap := cap + (cap shr 2);  // 大容量时 1.25x，减少内存浪费

  // 确保满足最小需求
  if newcap < need then newcap := need;
  // 溢出检查
  if (newcap < cap) or (newcap < need) then raise EOverflow.Create('capacity overflow');

  SetLength(FBuf, newcap);
end;

procedure TBytesBuilder.Init(ACapacity: SizeInt);
begin
  SetLength(FBuf, ACapacity);
  FLen := 0;
  FWriteAvail := 0;
  FHasPendingWrite := False;
end;

procedure TBytesBuilder.Clear;
begin
  FLen := 0;
  FWriteAvail := 0;
  FHasPendingWrite := False;
end;

procedure TBytesBuilder.Reset;
begin
  FLen := 0;
  FWriteAvail := 0;
  FHasPendingWrite := False;
end;

function TBytesBuilder.Length: SizeInt;
begin
  Result := FLen;
end;

function TBytesBuilder.Capacity: SizeInt;
begin
  Result := System.Length(FBuf);
end;

procedure TBytesBuilder.EnsureCapacity(ACapacity: SizeInt);
begin
  if ACapacity < 0 then raise EInvalidArgument.Create('negative capacity');
  if ACapacity = 0 then Exit;
  if ACapacity > System.Length(FBuf) then SetLength(FBuf, ACapacity);



end;

procedure TBytesBuilder.ReserveExact(ACapacity: SizeInt);
begin
  if ACapacity < 0 then raise EInvalidArgument.Create('negative capacity');
  if ACapacity = System.Length(FBuf) then Exit;
  SetLength(FBuf, ACapacity);
  if FLen > ACapacity then FLen := ACapacity;
  FWriteAvail := 0;
  FHasPendingWrite := False;
end;


procedure TBytesBuilder.BeginWrite(ARequest: SizeInt; out P: Pointer; out Granted: SizeInt);
begin
  P := nil;
  Granted := 0;
  if ARequest < 0 then raise EInvalidArgument.Create('negative request');
  if FHasPendingWrite then raise EInvalidOperation.Create('pending write not committed');
  if ARequest = 0 then Exit;
  Grow(ARequest);

  P := @FBuf[FLen];
  // 可写区域以请求为准（按语义授予请求的空间）
  FWriteAvail := ARequest;
  Granted := FWriteAvail;
  FHasPendingWrite := True;
end;

function TBytesBuilder.TryBeginWrite(ARequest: SizeInt; out P: Pointer; out Granted: SizeInt): Boolean;
begin
  P := nil; Granted := 0;
  if ARequest <= 0 then begin Result := True; Exit; end;
  if FHasPendingWrite then Exit(False);
  // attempt to ensure enough writable space; grow may reallocate but is allowed
  Grow(ARequest);
  P := @FBuf[FLen];
  FWriteAvail := ARequest;
  Granted := FWriteAvail;
  FHasPendingWrite := True;
  Result := True;
end;

procedure TBytesBuilder.EnsureWritable(AMinAdd: SizeInt);
begin
  if AMinAdd < 0 then raise EInvalidArgument.Create('negative min add');
  if AMinAdd = 0 then Exit;
  Grow(AMinAdd);
end;

procedure TBytesBuilder.Commit(AWritten: SizeInt);
begin
  if not FHasPendingWrite then raise EInvalidOperation.Create('no pending write');
  if (AWritten < 0) or (AWritten > FWriteAvail) then
    raise EInvalidArgument.Create('commit written out of range');
  Inc(FLen, AWritten);
  FWriteAvail := 0;
  FHasPendingWrite := False;
end;

procedure TBytesBuilder.Truncate(ANewLen: SizeInt);
begin
  if (ANewLen < 0) or (ANewLen > FLen) then
    raise EOutOfRange.Create('truncate out of range');
  FLen := ANewLen;
end;

procedure TBytesBuilder.ShrinkToFit;
begin
  if FLen < System.Length(FBuf) then
    SetLength(FBuf, FLen);
end;

procedure TBytesBuilder.Append(const B: TBytes);
begin
  if System.Length(B) = 0 then Exit;
  Grow(System.Length(B));
  Move(B[0], FBuf[FLen], System.Length(B));
  Inc(FLen, System.Length(B));
end;

procedure TBytesBuilder.Append(const P: Pointer; Count: SizeInt);
begin
  if Count < 0 then raise EInvalidArgument.Create('negative count');
  if Count = 0 then Exit;
  if P = nil then raise EInvalidArgument.Create('nil pointer with positive count');
  Grow(Count);
  Move(P^, FBuf[FLen], Count);
  Inc(FLen, Count);
end;

procedure TBytesBuilder.AppendString(const S: RawByteString);
var n: SizeInt;
begin
  n := System.Length(S);
  if n <= 0 then Exit;
  Grow(n);
  Move(Pointer(S)^, FBuf[FLen], n);
  Inc(FLen, n);
end;

procedure TBytesBuilder.AppendByte(Value: Byte); {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
begin
  Grow(1);
  FBuf[FLen] := Value;
  Inc(FLen);
end;

procedure TBytesBuilder.AppendU16LE(Value: UInt16);
begin
  Grow(2);
  FBuf[FLen] := Byte(Value and $FF);
  FBuf[FLen+1] := Byte((Value shr 8) and $FF);
  Inc(FLen, 2);
end;

procedure TBytesBuilder.AppendU16BE(Value: UInt16);
begin
  Grow(2);
  FBuf[FLen] := Byte((Value shr 8) and $FF);
  FBuf[FLen+1] := Byte(Value and $FF);
  Inc(FLen, 2);
end;

procedure TBytesBuilder.AppendU32LE(Value: UInt32);
begin
  Grow(4);
  FBuf[FLen] := Byte(Value and $FF);
  FBuf[FLen+1] := Byte((Value shr 8) and $FF);
  FBuf[FLen+2] := Byte((Value shr 16) and $FF);
  FBuf[FLen+3] := Byte((Value shr 24) and $FF);
  Inc(FLen, 4);
end;

procedure TBytesBuilder.AppendU32BE(Value: UInt32);
begin
  Grow(4);
  FBuf[FLen] := Byte((Value shr 24) and $FF);
  FBuf[FLen+1] := Byte((Value shr 16) and $FF);
  FBuf[FLen+2] := Byte((Value shr 8) and $FF);
  FBuf[FLen+3] := Byte(Value and $FF);
  Inc(FLen, 4);
end;

procedure TBytesBuilder.AppendU64LE(Value: UInt64);
begin
  Grow(8);
  FBuf[FLen] := Byte(Value and $FF);
  FBuf[FLen+1] := Byte((Value shr 8) and $FF);
  FBuf[FLen+2] := Byte((Value shr 16) and $FF);
  FBuf[FLen+3] := Byte((Value shr 24) and $FF);
  FBuf[FLen+4] := Byte((Value shr 32) and $FF);
  FBuf[FLen+5] := Byte((Value shr 40) and $FF);
  FBuf[FLen+6] := Byte((Value shr 48) and $FF);
  FBuf[FLen+7] := Byte((Value shr 56) and $FF);
  Inc(FLen, 8);

end;

function TBytesBuilder.DetachRaw(out UsedLen: SizeInt): TBytes;
begin
  // Deprecated: use DetachTrim (may shrink/copy) or DetachNoTrim for strict zero-copy
  UsedLen := FLen;
  if FLen <> System.Length(FBuf) then
    SetLength(FBuf, FLen);
  Result := FBuf;
  SetLength(FBuf, 0);
  FLen := 0;
  FWriteAvail := 0;
  FHasPendingWrite := False;
end;

function TBytesBuilder.DetachTrim(out UsedLen: SizeInt): TBytes;
begin
  // shrink to used length (may copy depending on runtime)
  UsedLen := FLen;
  if FLen <> System.Length(FBuf) then
    SetLength(FBuf, FLen);
  Result := FBuf;
  SetLength(FBuf, 0);
  FLen := 0;
  FWriteAvail := 0;
  FHasPendingWrite := False;
end;

function TBytesBuilder.DetachNoTrim(out UsedLen: SizeInt): TBytes;
begin
  // Strict ownership transfer without shrinking (no potential copy)
  UsedLen := FLen;
  Result := FBuf;
  SetLength(FBuf, 0);
  FLen := 0;
  FWriteAvail := 0;
  FHasPendingWrite := False;
end;

procedure TBytesBuilder.Peek(out P: Pointer; out UsedLen: SizeInt);
begin
  // Borrow read-only pointer to current used buffer; valid until next mutation
  if FLen = 0 then
  begin
    P := nil;
    UsedLen := 0;
    Exit;
  end;
  P := @FBuf[0];
  UsedLen := FLen;
end;

function TBytesBuilder.IntoBytes: TBytes;
var cap: SizeInt;
begin
  cap := Capacity;
  if cap = FLen then
  begin
    // perfect fit: zero-copy detach
    Result := FBuf;
    SetLength(FBuf, 0);
    FLen := 0;
    FWriteAvail := 0;
    FHasPendingWrite := False;
  end
  else
  begin
    // fallback to copy
    Result := ToBytes;
  end;
end;

procedure TBytesBuilder.AppendU64BE(Value: UInt64);
begin
  Grow(8);
  FBuf[FLen] := Byte((Value shr 56) and $FF);
  FBuf[FLen+1] := Byte((Value shr 48) and $FF);
  FBuf[FLen+2] := Byte((Value shr 40) and $FF);
  FBuf[FLen+3] := Byte((Value shr 32) and $FF);
  FBuf[FLen+4] := Byte((Value shr 24) and $FF);
  FBuf[FLen+5] := Byte((Value shr 16) and $FF);
  FBuf[FLen+6] := Byte((Value shr 8) and $FF);
  FBuf[FLen+7] := Byte(Value and $FF);
  Inc(FLen, 8);
end;

procedure TBytesBuilder.AppendHex(const S: string);
var
  i, L: SizeInt;
  ch1, ch2: Char;
  nib1, nib2: Byte;
  count: SizeInt;
begin
  L := System.Length(S);
  if L = 0 then Exit;
  if (L and 1) <> 0 then raise EInvalidArgument.Create('Hex string must have even length');
  count := L div 2;
  Grow(count);
  i := 0;
  while i < count do
  begin
    ch1 := S[i*2+1]; ch2 := S[i*2+2];
    if (not IsHexChar(ch1)) or (not IsHexChar(ch2)) then
      raise EInvalidArgument.Create('Invalid hex string');
    nib1 := HexNibble(ch1);
    nib2 := HexNibble(ch2);
    FBuf[FLen+i] := (nib1 shl 4) or nib2;
    Inc(i);
  end;
  Inc(FLen, count);
end;

procedure TBytesBuilder.AppendFill(Value: Byte; Count: SizeInt);
begin
  if Count < 0 then raise EInvalidArgument.Create('negative count');
  if Count = 0 then Exit;
  Grow(Count);
  FillChar(FBuf[FLen], Count, Value);
  Inc(FLen, Count);
end;

procedure TBytesBuilder.AppendRepeat(const Pattern: TBytes; Times: SizeInt);
var i, patLen, totalLen: SizeInt;
begin
  if Times < 0 then raise EInvalidArgument.Create('negative times');
  patLen := Length(Pattern);
  if (Times = 0) or (patLen = 0) then Exit;

  totalLen := patLen * Times;
  // 检查溢出
  if (Times > 0) and (totalLen div Times <> patLen) then
    raise EOverflow.Create('repeat size overflow');

  Grow(totalLen);
  for i := 0 to Times - 1 do
  begin
    Move(Pattern[0], FBuf[FLen + i * patLen], patLen);
  end;
  Inc(FLen, totalLen);
end;

function TBytesBuilder.ToBytes: TBytes;
var R: TBytes;
begin
  SetLength(R, FLen);
  if FLen > 0 then Move(FBuf[0], R[0], FLen);
  Result := R;
end;

function TBytesBuilder.WriteToStream(const AStream: TStream): Int64;
var P: Pointer; N: SizeInt; wrote: Longint;
begin
  if AStream = nil then raise EArgumentNil.Create('stream=nil');
  Peek(P, N);
  if (P = nil) or (N = 0) then Exit(0);
  wrote := AStream.Write(P^, N);
  if wrote < 0 then wrote := 0;
  Result := wrote;
end;

function TBytesBuilder.ReadFromStream(const AStream: TStream; Count: Int64): Int64;
const BUF_CHUNK = 64*1024;
var toRead, want: Int64; p: Pointer; granted: SizeInt; r: Longint;
begin
  if AStream = nil then raise EArgumentNil.Create('stream=nil');
  Result := 0;
  if Count < 0 then
  begin
    // read to EOF
    repeat
      want := BUF_CHUNK;
      BeginWrite(SizeInt(want), p, granted);
      if granted = 0 then Break;
      r := AStream.Read(p^, granted);
      if r <= 0 then begin Commit(0); Break; end;
      Commit(r);
      Inc(Result, r);
    until False;
  end
  else
  begin
    toRead := Count;
    while toRead > 0 do
    begin
      want := BUF_CHUNK; if want > toRead then want := toRead;
      BeginWrite(SizeInt(want), p, granted);
      if granted = 0 then Break;
      if granted > want then granted := SizeInt(want);
      r := AStream.Read(p^, granted);
      if r <= 0 then begin Commit(0); Break; end;
      Commit(r);
      Inc(Result, r);
      Dec(toRead, r);
    end;
  end;
end;

end.

