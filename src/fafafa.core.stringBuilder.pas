unit fafafa.core.stringBuilder;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{*
  fafafa.core.stringBuilder — 高性能字节序列字符串构建器（编码无关）

  设计要点
  - 接口优先：IStringBuilder，便于替换实现
  - 基于 TBytesBuilder 聚合实现，避免多次分配
  - 不涉及任何编码/校验语义：按原样拷贝追加；长度为字节数
  - ToString/AsBytes 返回新副本，不暴露内部缓冲
*}

interface

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.bytes,
  fafafa.core.io.base;

type
  EInvalidArgument = fafafa.core.base.EInvalidArgument;
  EOutOfRange      = fafafa.core.base.EOutOfRange;
  EArgumentNil     = fafafa.core.base.EArgumentNil;

  IStringBuilder = interface
    ['{C5B54F5B-2A4F-4C9B-A2A2-0D2B6D8A1E77}']
    // 容量与长度（Length 为字节数）
    function Capacity: SizeInt;
    function Length: SizeInt;
    procedure EnsureCapacity(ACapacity: SizeInt);
    procedure Reserve(ACapacity: SizeInt);
    procedure ReserveExact(ACapacity: SizeInt);
    procedure Truncate(ANewLen: SizeInt);
    procedure ShrinkToFit;

    // 追加（链式返回自身）
    function Append(const S: string): IStringBuilder; overload;
    function AppendLine: IStringBuilder; overload;
    function AppendLine(const S: string): IStringBuilder; overload;
    function AppendChar(const C: Char): IStringBuilder; // 编码无关：按 SizeOf(Char) 原样写入（平台相关）
    function AppendByte(const B: Byte): IStringBuilder; // 明确 1 字节
    function AppendLF: IStringBuilder;              // 明确 LF (0x0A)
    function AppendCRLF: IStringBuilder;            // 明确 CRLF (0x0D,0x0A)
    function AppendBytes(const B: TBytes): IStringBuilder; overload;
    function AppendBytes(const P: Pointer; Count: SizeInt): IStringBuilder; overload;

    // 数值快速路径（避免临时字符串）
    function AppendInt64(const V: Int64): IStringBuilder;
    function AppendUInt64(const V: QWord): IStringBuilder;
    function AppendFloat64(const V: Double): IStringBuilder;

    function Clear: IStringBuilder;

    // 导出（编码无关）：ToString 原样拼接；ToRaw/AsBytes 拷贝；IntoBytes/DetachBytes 暴露零拷贝
    function ToString: string;
    function ToRaw: RawByteString;
    function AsBytes: TBytes;
    function IntoBytes: TBytes;     // try zero-copy; else copy
    function DetachBytes(out UsedLen: SizeInt): TBytes; // zero-copy + reset

    // IO 互操作（编码无关）：按字节读写
    function WriteToStream(const AStream: TStream): Int64;
    function AppendFromStream(const AStream: TStream; Count: Int64 = -1): Int64;
    function WriteToByteSink(const Sink: IWriter; AChunkSize: SizeInt = 64*1024): Int64;
    function AppendFromByteSource(const Src: IReader; Count: Int64 = -1; AChunkSize: SizeInt = 64*1024): Int64;

    // UTF-8 友好 API（编码无关的字节追加，但命名明确语义）
    function AppendUTF8String(const S: RawByteString): IStringBuilder;
    function AppendCodePoint(const U: Cardinal): IStringBuilder;
  end;

  { TStringBuilderRaw }
  TStringBuilderRaw = class(TInterfacedObject, IStringBuilder)
  private
    FBB: TBytesBuilder;
  private
    procedure AppendRaw(const P: Pointer; const Len: SizeInt);
  public
    constructor Create(ACapacity: SizeInt = 0);
    class function New(ACapacity: SizeInt = 0): IStringBuilder; static;

    // IStringBuilder
    function Capacity: SizeInt;
    function Length: SizeInt;
    procedure EnsureCapacity(ACapacity: SizeInt);

    procedure Reserve(ACapacity: SizeInt);
    procedure ReserveExact(ACapacity: SizeInt);
    procedure Truncate(ANewLen: SizeInt);
    procedure ShrinkToFit;

    function Append(const S: string): IStringBuilder; overload;
    function AppendLine: IStringBuilder; overload;
    function AppendLine(const S: string): IStringBuilder; overload;
    function AppendChar(const C: Char): IStringBuilder; // 编码无关：按 SizeOf(Char) 原样写入（平台相关）
    function AppendByte(const B: Byte): IStringBuilder; // 明确 1 字节
    function AppendLF: IStringBuilder;              // 明确 LF (0x0A)
    function AppendCRLF: IStringBuilder;            // 明确 CRLF (0x0D,0x0A)
    function AppendBytes(const B: TBytes): IStringBuilder; overload;
    function AppendBytes(const P: Pointer; Count: SizeInt): IStringBuilder; overload;

    // 数值快速路径（避免临时字符串）
    function AppendInt64(const V: Int64): IStringBuilder;
    function AppendUInt64(const V: QWord): IStringBuilder;
    function AppendFloat64(const V: Double): IStringBuilder;

    // 文本便捷：十六进制与转义/引号（按字节处理，不涉及编码）
    function AppendHexLower(const B: TBytes): IStringBuilder;
    function AppendHexUpper(const B: TBytes): IStringBuilder;
    function AppendQuoted(const S: RawByteString; Quote: AnsiChar = '"'): IStringBuilder;
    function AppendEscaped(const S: RawByteString): IStringBuilder;

    function Clear: IStringBuilder;

    function ToString: string; override;
    function ToRaw: RawByteString;
    function AsBytes: TBytes;
    function WriteToByteSink(const Sink: IWriter; AChunkSize: SizeInt = 64*1024): Int64;
    function AppendFromByteSource(const Src: IReader; Count: Int64 = -1; AChunkSize: SizeInt = 64*1024): Int64;

    function IntoBytes: TBytes;
    function DetachBytes(out UsedLen: SizeInt): TBytes;

    function WriteToStream(const AStream: TStream): Int64;
    function AppendFromStream(const AStream: TStream; Count: Int64 = -1): Int64;

    function AppendUTF8String(const S: RawByteString): IStringBuilder;
    function AppendCodePoint(const U: Cardinal): IStringBuilder;
  end;

// 工厂函数（便捷）
function MakeStringBuilder(ACapacity: SizeInt = 0): IStringBuilder; inline;


implementation

procedure EncodeCodePointToUTF8(const U: Cardinal; out Buf: array of Byte; out L: Integer);
begin
  // 最多 4 字节编码
  if U <= $7F then begin
    if Length(Buf) < 1 then raise EOutOfRange.Create('buffer too small');
    Buf[0] := Byte(U);
    L := 1;
  end
  else if U <= $7FF then begin
    if Length(Buf) < 2 then raise EOutOfRange.Create('buffer too small');
    Buf[0] := Byte($C0 or ((U shr 6) and $1F));
    Buf[1] := Byte($80 or (U and $3F));
    L := 2;
  end
  else if U <= $FFFF then begin
    if (U >= $D800) and (U <= $DFFF) then
      raise EInvalidArgument.Create('invalid Unicode surrogate');
    if Length(Buf) < 3 then raise EOutOfRange.Create('buffer too small');
    Buf[0] := Byte($E0 or ((U shr 12) and $0F));
    Buf[1] := Byte($80 or ((U shr 6) and $3F));
    Buf[2] := Byte($80 or (U and $3F));
    L := 3;
  end
  else if U <= $10FFFF then begin
    if Length(Buf) < 4 then raise EOutOfRange.Create('buffer too small');
    Buf[0] := Byte($F0 or ((U shr 18) and $07));
    Buf[1] := Byte($80 or ((U shr 12) and $3F));
    Buf[2] := Byte($80 or ((U shr 6) and $3F));
    Buf[3] := Byte($80 or (U and $3F));
    L := 4;
  end
  else
    raise EInvalidArgument.Create('codepoint out of range');
end;


// Minimal helper: format Int64 into a Char buffer; returns char count
function FormatInt64ToBuf(const V: Int64; var Buf: array of Char): Integer;
var
  S: string;
  I, Cap: SizeInt;
begin
  S := IntToStr(V);
  Cap := High(Buf) - Low(Buf) + 1;
  if Cap < Length(S) then
    raise EOutOfRange.Create('buffer too small');
  for I := 1 to Length(S) do
    Buf[I - 1] := S[I];
  Result := Length(S);
end;

{ TStringBuilderRaw }
constructor TStringBuilderRaw.Create(ACapacity: SizeInt);
begin
  inherited Create;
  FBB.Init(ACapacity);
end;

class function TStringBuilderRaw.New(ACapacity: SizeInt): IStringBuilder;
begin
  Result := TStringBuilderRaw.Create(ACapacity);
end;

function TStringBuilderRaw.Capacity: SizeInt;
begin
  Result := FBB.Capacity;
end;

procedure TStringBuilderRaw.ReserveExact(ACapacity: SizeInt);
begin
  FBB.ReserveExact(ACapacity);
end;

function TStringBuilderRaw.Length: SizeInt;
begin
  Result := FBB.Length;
end;

procedure TStringBuilderRaw.EnsureCapacity(ACapacity: SizeInt);
begin
  FBB.EnsureCapacity(ACapacity);
end;

procedure TStringBuilderRaw.Reserve(ACapacity: SizeInt);
begin
  FBB.Reserve(ACapacity);
end;

procedure TStringBuilderRaw.Truncate(ANewLen: SizeInt);
begin
  FBB.Truncate(ANewLen);
end;

procedure TStringBuilderRaw.ShrinkToFit;
begin
  FBB.ShrinkToFit;
end;

procedure TStringBuilderRaw.AppendRaw(const P: Pointer; const Len: SizeInt);
begin
  // 直接委托 TBytesBuilder，以对齐异常语义（nil+>0/Count<0 抛异常）
  if Len = 0 then Exit;
  FBB.Append(P, Len);
end;

function TStringBuilderRaw.Append(const S: string): IStringBuilder;
var
  L: SizeInt;
begin
  // 编码无关：直接按底层字符单元大小写入（Length(S) * SizeOf(Char) 字节）
  L := System.Length(S);
  if L > 0 then
    AppendRaw(Pointer(S), L * SizeOf(Char));
  Result := Self;
end;

function TStringBuilderRaw.AppendLine: IStringBuilder;
begin
  Result := Append(LineEnding);
end;

function TStringBuilderRaw.AppendLF: IStringBuilder;
begin
  FBB.AppendByte($0A);
  Result := Self;
end;

function TStringBuilderRaw.AppendCRLF: IStringBuilder;
begin
  FBB.AppendByte($0D);
  FBB.AppendByte($0A);
  Result := Self;
end;

function TStringBuilderRaw.AppendLine(const S: string): IStringBuilder;
begin
  Result := Append(S).Append(LineEnding);
end;

function TStringBuilderRaw.AppendChar(const C: Char): IStringBuilder;
begin
  AppendRaw(@C, SizeOf(Char));
  Result := Self;
end;

function TStringBuilderRaw.AppendBytes(const B: TBytes): IStringBuilder;
begin
  if System.Length(B) > 0 then AppendRaw(@B[0], System.Length(B));
  Result := Self;
end;

function TStringBuilderRaw.AppendByte(const B: Byte): IStringBuilder;
begin
  FBB.AppendByte(B);
  Result := Self;
end;

function TStringBuilderRaw.AppendBytes(const P: Pointer; Count: SizeInt): IStringBuilder;
begin
  AppendRaw(P, Count);
  Result := Self;
end;

function TStringBuilderRaw.Clear: IStringBuilder;
begin
  FBB.Clear;
  Result := Self;
end;

function TStringBuilderRaw.ToString: string;
var
  B: TBytes;
  n: SizeInt;
  rb: RawByteString absolute Result;
begin
  // 原样转为 string（由调用方确保期望的编码）
  B := FBB.ToBytes;
  n := System.Length(B);
  if n = 0 then Exit('');

  SetLength(Result, n);
  Move(B[0], Result[1], n);
  SetCodePage(rb, CP_UTF8, False);
end;

function TStringBuilderRaw.ToRaw: RawByteString;
var B: TBytes;
begin
  Result := '';
  B := FBB.ToBytes;
  SetLength(Result, System.Length(B));
  if System.Length(B) > 0 then Move(B[0], Pointer(Result)^, System.Length(B));
end;
function TStringBuilderRaw.IntoBytes: TBytes;
begin
  Result := FBB.IntoBytes;
end;

function TStringBuilderRaw.DetachBytes(out UsedLen: SizeInt): TBytes;
begin
  Result := FBB.DetachTrim(UsedLen);
end;

function TStringBuilderRaw.WriteToByteSink(const Sink: IWriter; AChunkSize: SizeInt): Int64;
begin
  Result := WriteToSink(FBB, Sink, AChunkSize);
end;

function TStringBuilderRaw.AppendFromByteSource(const Src: IReader; Count: Int64; AChunkSize: SizeInt): Int64;
begin
  Result := ReadFromSource(FBB, Src, Count, AChunkSize);
end;


function TStringBuilderRaw.AsBytes: TBytes;
begin
  Result := FBB.ToBytes;
end;

function TStringBuilderRaw.WriteToStream(const AStream: TStream): Int64;
var P: Pointer; N: SizeInt; wrote: Longint;
begin
  if AStream = nil then raise EArgumentNil.Create('stream=nil');
  FBB.Peek(P, N);
  if (P = nil) or (N = 0) then Exit(0);
  wrote := AStream.Write(P^, N);
  if wrote < 0 then wrote := 0;
  Result := wrote;
end;
function TStringBuilderRaw.AppendUTF8String(const S: RawByteString): IStringBuilder;
begin
  // 按字节原样追加（调用方保证 UTF-8）
  FBB.AppendString(S);
  Result := Self;
end;

function TStringBuilderRaw.AppendInt64(const V: Int64): IStringBuilder;
var
  s: string;
  L: SizeInt;
begin
  s := IntToStr(V);
  L := System.Length(s);
  if L > 0 then
    AppendRaw(Pointer(s), L * SizeOf(Char));
  Result := Self;
end;

function TStringBuilderRaw.AppendUInt64(const V: QWord): IStringBuilder;
var v64: Int64;
begin
  if V <= High(Int64) then v64 := Int64(V) else v64 := Int64(V); // fallback; same path
  Result := AppendInt64(v64);
end;

function TStringBuilderRaw.AppendFloat64(const V: Double): IStringBuilder;
var s: string;
begin
  // keep simple first: use FloatToStr into temp string, later optimize
  s := FloatToStr(V);
  Result := Append(s);
end;

function TStringBuilderRaw.AppendCodePoint(const U: Cardinal): IStringBuilder;
var buf: array[0..3] of Byte; L: Integer;
begin
  EncodeCodePointToUTF8(U, buf, L);
  FBB.Append(@buf[0], L);
  Result := Self;
end;


function TStringBuilderRaw.AppendFromStream(const AStream: TStream; Count: Int64): Int64;
const
  BUF_CHUNK: SizeInt = 64*1024;
var
  toRead: Int64;
  want: SizeInt;
  p: Pointer;
  granted: SizeInt;
  r: Longint;
begin
  if AStream = nil then raise EArgumentNil.Create('stream=nil');
  Result := 0;

  if Count < 0 then
  begin
    repeat
      want := BUF_CHUNK;
      FBB.BeginWrite(want, p, granted);
      if granted = 0 then Break;
      r := AStream.Read(p^, granted);
      if r <= 0 then begin FBB.Commit(0); Break; end;
      FBB.Commit(r);
      Inc(Result, r);
    until False;
  end
  else
  begin
    toRead := Count;
    while toRead > 0 do
    begin
      want := BUF_CHUNK;
      if toRead < want then
        want := SizeInt(toRead);

      FBB.BeginWrite(want, p, granted);
      if granted = 0 then Break;
      if granted > want then granted := want;
      r := AStream.Read(p^, granted);
      if r <= 0 then begin FBB.Commit(0); Break; end;
      FBB.Commit(r);
      Inc(Result, r);
      Dec(toRead, r);
    end;
  end;
end;

function TStringBuilderRaw.AppendHexLower(const B: TBytes): IStringBuilder;
const HEX: PAnsiChar = '0123456789abcdef';
var i: SizeInt; L: SizeInt; p: Pointer; g: SizeInt; pb: PByte; pc: PAnsiChar;
begin
  L := System.Length(B);
  if L = 0 then Exit(Self);
  FBB.BeginWrite(L*2, p, g);
  pb := @B[0]; pc := PAnsiChar(p);
  for i := 0 to L-1 do
  begin
    pc[i*2]   := HEX[(pb[i] shr 4) and $F];
    pc[i*2+1] := HEX[pb[i] and $F];
  end;
  FBB.Commit(L*2);
  Result := Self;
end;

function TStringBuilderRaw.AppendHexUpper(const B: TBytes): IStringBuilder;
const HEXU: PAnsiChar = '0123456789ABCDEF';
var i: SizeInt; L: SizeInt; p: Pointer; g: SizeInt; pb: PByte; pc: PAnsiChar;
begin
  L := System.Length(B);
  if L = 0 then Exit(Self);
  FBB.BeginWrite(L*2, p, g);
  pb := @B[0]; pc := PAnsiChar(p);
  for i := 0 to L-1 do
  begin
    pc[i*2]   := HEXU[(pb[i] shr 4) and $F];
    pc[i*2+1] := HEXU[pb[i] and $F];
  end;
  FBB.Commit(L*2);
  Result := Self;
end;

function TStringBuilderRaw.AppendQuoted(const S: RawByteString; Quote: AnsiChar): IStringBuilder;
var L: SizeInt; p: Pointer; g: SizeInt; ps: PAnsiChar; pc: PAnsiChar;
begin
  L := System.Length(S);
  FBB.BeginWrite(L+2, p, g);
  pc := PAnsiChar(p);
  pc[0] := Quote;
  if L > 0 then begin ps := PAnsiChar(Pointer(S)); System.Move(ps^, pc[1], L); end;
  pc[L+1] := Quote;
  FBB.Commit(L+2);
  Result := Self;
end;

function TStringBuilderRaw.AppendEscaped(const S: RawByteString): IStringBuilder;
var i: SizeInt; L: SizeInt; pc: PAnsiChar; ps: PAnsiChar; need: SizeInt; ch: AnsiChar; p: Pointer; g: SizeInt;
begin
  L := System.Length(S);
  if L = 0 then Exit(Self);
  need := L*2;
  FBB.BeginWrite(need, p, g);
  pc := PAnsiChar(p);
  ps := PAnsiChar(Pointer(S));
  g := 0;
  for i := 0 to L-1 do
  begin
    ch := ps[i];
    case ch of
      '\': begin pc[g] := '\'; Inc(g); pc[g] := '\'; Inc(g); end;
      #34:  begin pc[g] := '\'; Inc(g); pc[g] := #34;  Inc(g); end;
      #10:  begin pc[g] := '\'; Inc(g); pc[g] := 'n';   Inc(g); end;
      #13:  begin pc[g] := '\'; Inc(g); pc[g] := 'r';   Inc(g); end;
      #9:   begin pc[g] := '\'; Inc(g); pc[g] := 't';   Inc(g); end;
    else
      pc[g] := ch; Inc(g);
    end;
  end;
  FBB.Commit(g);
  Result := Self;
end;

function MakeStringBuilder(ACapacity: SizeInt): IStringBuilder; inline;
begin
  Result := TStringBuilderRaw.New(ACapacity);
end;

end.

