unit fafafa.core.bytes.buf;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.bytes; // for TBytesBuilder

type
  EInvalidArgument = fafafa.core.base.EInvalidArgument;
  EOutOfRange      = fafafa.core.base.EOutOfRange;

  IByteBuf = interface
    ['{B2D1B23E-6AC0-41C0-8F24-7D9E7E9B4D55}']
    // 索引与容量
    function GetReaderIndex: SizeInt;
    procedure SetReaderIndex(AValue: SizeInt);
    function GetWriterIndex: SizeInt;
    procedure SetWriterIndex(AValue: SizeInt);
    function Capacity: SizeInt;
    function ReadableBytes: SizeInt;
    function WritableBytes: SizeInt;

    // 写入/读取（扩展：U8/U16/U32/U64，顺序推进索引）
    procedure EnsureWritable(N: SizeInt);
    procedure WriteU8(Value: Byte);
    function ReadU8: Byte;
    procedure WriteU16LE(Value: UInt16);
    procedure WriteU16BE(Value: UInt16);
    procedure WriteU32LE(Value: UInt32);
    procedure WriteU32BE(Value: UInt32);
    procedure WriteU64LE(Value: UInt64);
    procedure WriteU64BE(Value: UInt64);
    function ReadU16LE: UInt16;
    function ReadU16BE: UInt16;
    function ReadU32LE: UInt32;
    function ReadU32BE: UInt32;
    function ReadU64LE: UInt64;
    function ReadU64BE: UInt64;

    // 视图
    function Duplicate: IByteBuf; // 零拷贝共享存储，索引独立
    function Slice(Offset, Len: SizeInt): IByteBuf; // 零拷贝片段视图

    // 字节批量读写
    procedure WriteBytes(const B: TBytes);
    function ReadBytes(Count: SizeInt): TBytes;

    // 维护
    procedure Compact; // owner-only：移动未读数据到起始，FR:=0, FW:=Readable
    procedure DiscardReadBytes; // alias to Compact

    // 导出
    function ToBytes: TBytes; // 拷贝当前 writerIndex 的内容

    property ReaderIndex: SizeInt read GetReaderIndex write SetReaderIndex;
    property WriterIndex: SizeInt read GetWriterIndex write SetWriterIndex;
  end;

  // 互操作：从 ByteBuf 生成 TBytesBuilder（复制）
  function ByteBufToBuilder(const Buf: IByteBuf): TBytesBuilder;

  type
  { TByteBufImpl }
  TByteBufImpl = class(TInterfacedObject, IByteBuf)
  private
    FBuf: TBytes;
    FOffset: SizeInt;   // 视图起始
    FLen: SizeInt;      // 视图长度（容量上限）
    FR: SizeInt;        // readerIndex（相对视图）
    FW: SizeInt;        // writerIndex（相对视图）
    FCanGrow: Boolean;  // 仅 owner 允许扩容（Offset=0 && Len=Length(FBuf)）
  protected
    function GetReaderIndex: SizeInt;
    procedure SetReaderIndex(AValue: SizeInt);
    function GetWriterIndex: SizeInt;
    procedure SetWriterIndex(AValue: SizeInt);
  public
    // 工厂
    class function New(ACapacity: SizeInt = 0): IByteBuf; static;
    class function FromBytes(const B: TBytes): IByteBuf; static;
    class function FromBuilder(const BB: TBytesBuilder): IByteBuf; static;

    // IByteBuf 实现
    function Capacity: SizeInt;
    function ReadableBytes: SizeInt;
    function WritableBytes: SizeInt;

    procedure EnsureWritable(N: SizeInt);
    procedure WriteU8(Value: Byte);
    function ReadU8: Byte;
    procedure WriteU16LE(Value: UInt16);
    procedure WriteU16BE(Value: UInt16);
    procedure WriteU32LE(Value: UInt32);
    procedure WriteU32BE(Value: UInt32);
    procedure WriteU64LE(Value: UInt64);
    procedure WriteU64BE(Value: UInt64);
    function ReadU16LE: UInt16;
    function ReadU16BE: UInt16;
    function ReadU32LE: UInt32;
    function ReadU32BE: UInt32;
    function ReadU64LE: UInt64;
    function ReadU64BE: UInt64;

    function Duplicate: IByteBuf;
    function Slice(Offset, Len: SizeInt): IByteBuf;

    procedure WriteBytes(const B: TBytes);
    function ReadBytes(Count: SizeInt): TBytes;

    procedure Compact;
    procedure DiscardReadBytes;

    function ToBytes: TBytes;
  end;

implementation

function TByteBufImpl.GetReaderIndex: SizeInt;
begin
  Result := FR;
end;

procedure TByteBufImpl.SetReaderIndex(AValue: SizeInt);
begin
  if (AValue < 0) or (AValue > FW) then
    raise EOutOfRange.Create('ReaderIndex out of range');
  FR := AValue;
end;

function TByteBufImpl.GetWriterIndex: SizeInt;
begin
  Result := FW;
end;

procedure TByteBufImpl.SetWriterIndex(AValue: SizeInt);
begin
  if (AValue < FR) or (AValue > FLen) then
    raise EOutOfRange.Create('WriterIndex out of range');
  FW := AValue;
end;

class function TByteBufImpl.New(ACapacity: SizeInt): IByteBuf;
var o: TByteBufImpl;
begin
  o := TByteBufImpl.Create;
  SetLength(o.FBuf, ACapacity);
  o.FOffset := 0;
  o.FLen := ACapacity;
  o.FR := 0;
  o.FW := 0;
  o.FCanGrow := True;
  Result := o;
end;

class function TByteBufImpl.FromBytes(const B: TBytes): IByteBuf;
var o: TByteBufImpl;
begin
  o := TByteBufImpl.Create;
  o.FBuf := B; // 直接接管/共享底层
  o.FOffset := 0;
  o.FLen := Length(B);
  o.FR := 0;
  o.FW := Length(B);
  o.FCanGrow := True;
  Result := o;
end;

class function TByteBufImpl.FromBuilder(const BB: TBytesBuilder): IByteBuf;
var o: TByteBufImpl; tmp: TBytes;
begin
  o := TByteBufImpl.Create;
  // 拷贝 BB 到独立缓冲，避免与 builder 后续写入相互影响
  tmp := BB.ToBytes;
  o.FBuf := tmp;
  o.FOffset := 0;
  o.FLen := Length(tmp);
  o.FR := 0;
  o.FW := Length(tmp);
  o.FCanGrow := True;
  Result := o;
end;

function TByteBufImpl.Capacity: SizeInt;
begin
  Result := FLen;
end;

function TByteBufImpl.ReadableBytes: SizeInt;
begin
  Result := FW - FR;
end;

function TByteBufImpl.WritableBytes: SizeInt;
begin
  Result := FLen - FW;
end;

procedure TByteBufImpl.EnsureWritable(N: SizeInt);
var need: SizeInt;
begin
  if N <= 0 then Exit;
  need := FW + N;
  if need <= FLen then Exit;
  if not FCanGrow then
    raise EOutOfRange.Create('EnsureWritable requires growth but buffer is a view');
  // 仅 owner 且视图对齐时允许扩容
  if (FOffset <> 0) or (FLen <> Length(FBuf)) then
    raise EOutOfRange.Create('Cannot grow non-root view');
  // 优化增长策略：与 TBytesBuilder 保持一致
  if Length(FBuf) < 64 then
    need := Length(FBuf) * 2  // 小容量时翻倍
  else if Length(FBuf) < 1024 then
    need := Length(FBuf) + (Length(FBuf) shr 1)  // 中等容量时 1.5x
  else
    need := Length(FBuf) + (Length(FBuf) shr 2);  // 大容量时 1.25x

  // 确保满足最小需求
  if need < FW + N then
    need := FW + N;
  SetLength(FBuf, need);
  FLen := Length(FBuf);
end;

procedure TByteBufImpl.WriteU8(Value: Byte);
begin
  EnsureWritable(1);
  FBuf[FOffset + FW] := Value;
  Inc(FW);
end;

function TByteBufImpl.ReadU8: Byte;
begin
  if FR >= FW then
    raise EOutOfRange.Create('Read beyond writer index');
  Result := FBuf[FOffset + FR];
  Inc(FR);
end;

procedure TByteBufImpl.WriteU16LE(Value: UInt16);
begin
  EnsureWritable(2);
  FBuf[FOffset + FW] := Byte(Value and $FF);
  FBuf[FOffset + FW + 1] := Byte((Value shr 8) and $FF);
  Inc(FW, 2);
end;

procedure TByteBufImpl.WriteU16BE(Value: UInt16);
begin
  EnsureWritable(2);
  FBuf[FOffset + FW] := Byte((Value shr 8) and $FF);
  FBuf[FOffset + FW + 1] := Byte(Value and $FF);
  Inc(FW, 2);
end;

procedure TByteBufImpl.WriteU32LE(Value: UInt32);
begin
  EnsureWritable(4);
  FBuf[FOffset + FW] := Byte(Value and $FF);
  FBuf[FOffset + FW + 1] := Byte((Value shr 8) and $FF);
  FBuf[FOffset + FW + 2] := Byte((Value shr 16) and $FF);
  FBuf[FOffset + FW + 3] := Byte((Value shr 24) and $FF);
  Inc(FW, 4);
end;

procedure TByteBufImpl.WriteU32BE(Value: UInt32);
begin
  EnsureWritable(4);
  FBuf[FOffset + FW] := Byte((Value shr 24) and $FF);
  FBuf[FOffset + FW + 1] := Byte((Value shr 16) and $FF);
  FBuf[FOffset + FW + 2] := Byte((Value shr 8) and $FF);
  FBuf[FOffset + FW + 3] := Byte(Value and $FF);
  Inc(FW, 4);
end;

function TByteBufImpl.ReadU16LE: UInt16;
begin
  if (FR + 2) > FW then
    raise EOutOfRange.Create('Read beyond writer index');
  Result := UInt16(FBuf[FOffset + FR]) or (UInt16(FBuf[FOffset + FR + 1]) shl 8);
  Inc(FR, 2);
end;

function TByteBufImpl.ReadU16BE: UInt16;
begin
  if (FR + 2) > FW then
    raise EOutOfRange.Create('Read beyond writer index');
  Result := (UInt16(FBuf[FOffset + FR]) shl 8) or UInt16(FBuf[FOffset + FR + 1]);
  Inc(FR, 2);
end;

function TByteBufImpl.ReadU32LE: UInt32;
begin
  if (FR + 4) > FW then
    raise EOutOfRange.Create('Read beyond writer index');
  Result := UInt32(FBuf[FOffset + FR]) or (UInt32(FBuf[FOffset + FR + 1]) shl 8) or
            (UInt32(FBuf[FOffset + FR + 2]) shl 16) or (UInt32(FBuf[FOffset + FR + 3]) shl 24);
  Inc(FR, 4);
end;

procedure TByteBufImpl.WriteBytes(const B: TBytes);
var n: SizeInt;
begin
  n := Length(B);
  if n <= 0 then Exit;
  EnsureWritable(n);
  Move(B[0], FBuf[FOffset + FW], n);
  Inc(FW, n);
end;

function TByteBufImpl.ReadBytes(Count: SizeInt): TBytes;
begin
  if (Count < 0) or ((FR + Count) > FW) then
    raise EOutOfRange.Create('Read beyond writer index');
  SetLength(Result, Count);
  if Count > 0 then
  begin
    Move(FBuf[FOffset + FR], Result[0], Count);
    Inc(FR, Count);
  end;
end;

function TByteBufImpl.ReadU32BE: UInt32;
begin
  if (FR + 4) > FW then
    raise EOutOfRange.Create('Read beyond writer index');
  Result := (UInt32(FBuf[FOffset + FR]) shl 24) or (UInt32(FBuf[FOffset + FR + 1]) shl 16) or
            (UInt32(FBuf[FOffset + FR + 2]) shl 8) or UInt32(FBuf[FOffset + FR + 3]);
  Inc(FR, 4);
end;

// ---- U64 支持 ----
procedure TByteBufImpl.WriteU64LE(Value: UInt64);
begin
  EnsureWritable(8);
  FBuf[FOffset + FW] := Byte(Value and $FF);
  FBuf[FOffset + FW + 1] := Byte((Value shr 8) and $FF);
  FBuf[FOffset + FW + 2] := Byte((Value shr 16) and $FF);
  FBuf[FOffset + FW + 3] := Byte((Value shr 24) and $FF);
  FBuf[FOffset + FW + 4] := Byte((Value shr 32) and $FF);
  FBuf[FOffset + FW + 5] := Byte((Value shr 40) and $FF);
  FBuf[FOffset + FW + 6] := Byte((Value shr 48) and $FF);
  FBuf[FOffset + FW + 7] := Byte((Value shr 56) and $FF);
  Inc(FW, 8);
end;

procedure TByteBufImpl.WriteU64BE(Value: UInt64);
begin
  EnsureWritable(8);
  FBuf[FOffset + FW] := Byte((Value shr 56) and $FF);
  FBuf[FOffset + FW + 1] := Byte((Value shr 48) and $FF);
  FBuf[FOffset + FW + 2] := Byte((Value shr 40) and $FF);
  FBuf[FOffset + FW + 3] := Byte((Value shr 32) and $FF);
  FBuf[FOffset + FW + 4] := Byte((Value shr 24) and $FF);
  FBuf[FOffset + FW + 5] := Byte((Value shr 16) and $FF);
  FBuf[FOffset + FW + 6] := Byte((Value shr 8) and $FF);
  FBuf[FOffset + FW + 7] := Byte(Value and $FF);
  Inc(FW, 8);
end;

function TByteBufImpl.ReadU64LE: UInt64;
begin
  if (FR + 8) > FW then
    raise EOutOfRange.Create('Read beyond writer index');
  Result := UInt64(FBuf[FOffset + FR]) or (UInt64(FBuf[FOffset + FR + 1]) shl 8) or
            (UInt64(FBuf[FOffset + FR + 2]) shl 16) or (UInt64(FBuf[FOffset + FR + 3]) shl 24) or
            (UInt64(FBuf[FOffset + FR + 4]) shl 32) or (UInt64(FBuf[FOffset + FR + 5]) shl 40) or
            (UInt64(FBuf[FOffset + FR + 6]) shl 48) or (UInt64(FBuf[FOffset + FR + 7]) shl 56);
  Inc(FR, 8);
end;

function TByteBufImpl.ReadU64BE: UInt64;
begin
  if (FR + 8) > FW then
    raise EOutOfRange.Create('Read beyond writer index');
  Result := (UInt64(FBuf[FOffset + FR]) shl 56) or (UInt64(FBuf[FOffset + FR + 1]) shl 48) or
            (UInt64(FBuf[FOffset + FR + 2]) shl 40) or (UInt64(FBuf[FOffset + FR + 3]) shl 32) or
            (UInt64(FBuf[FOffset + FR + 4]) shl 24) or (UInt64(FBuf[FOffset + FR + 5]) shl 16) or
            (UInt64(FBuf[FOffset + FR + 6]) shl 8) or UInt64(FBuf[FOffset + FR + 7]);
  Inc(FR, 8);
end;

function TByteBufImpl.Duplicate: IByteBuf;
var o: TByteBufImpl;
begin
  o := TByteBufImpl.Create;
  o.FBuf := FBuf;
  o.FOffset := FOffset;
  o.FLen := FLen;
  o.FR := FR;
  o.FW := FW;
  o.FCanGrow := False; // 视图不允许扩容
  Result := o;
end;

function TByteBufImpl.Slice(Offset, Len: SizeInt): IByteBuf;
var o: TByteBufImpl; maxWritable: SizeInt; valid: SizeInt;
begin
  if (Offset < 0) or (Len < 0) or (Offset + Len > FLen) then
    raise EOutOfRange.Create('Slice out of range');
  o := TByteBufImpl.Create;
  o.FBuf := FBuf;
  o.FOffset := FOffset + Offset;
  o.FLen := Len;
  // slice 的 writerIndex 不能超过父 writerIndex 投影
  maxWritable := FW - Offset;
  if maxWritable < 0 then maxWritable := 0;
  if maxWritable > Len then maxWritable := Len;
  valid := maxWritable;
  o.FW := valid;
  o.FR := 0;
  o.FCanGrow := False;
  Result := o;
end;

procedure TByteBufImpl.Compact;
var remaining: SizeInt;
begin
  // 仅 root owner 可 Compact
  if (FOffset <> 0) or (FLen <> Length(FBuf)) then
    raise EOutOfRange.Create('Compact not allowed on view');
  remaining := FW - FR;
  if remaining > 0 then
    Move(FBuf[FOffset + FR], FBuf[0], remaining);
  FR := 0;
  FW := remaining;
end;

procedure TByteBufImpl.DiscardReadBytes;
begin
  Compact;
end;

function TByteBufImpl.ToBytes: TBytes;
begin
  SetLength(Result, 0);
  SetLength(Result, FW);
  if FW > 0 then
    Move(FBuf[FOffset], Result[0], FW);
end;

function ByteBufToBuilder(const Buf: IByteBuf): TBytesBuilder;
var tmp: TBytes; bb: TBytesBuilder;
begin
  tmp := nil;
  tmp := Buf.ToBytes;
  bb.Init(Length(tmp));
  if Length(tmp) > 0 then bb.Append(tmp);
  Result := bb;
end;

end.

