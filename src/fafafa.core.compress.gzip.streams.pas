unit fafafa.core.compress.gzip.streams;

{$mode objfpc}{$H+}

{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils,
  fafafa.core.compress.deflate.raw.paszlib;

type
  { EGZipError }
  EGZipError = class(Exception);

  { CRC32 工具（基于全局表，避免在 record 中使用 class var 以兼容性） }
  TGZipCRC32 = record end;

  { TGZipEncodeStream }
  TGZipEncodeStream = class(TStream)
  private
    FDest: TStream;
    FDeflate: TRawDeflateStream;
    FCRC: DWord;
    FSize: DWord;
    FClosed: Boolean;
  protected
    procedure DoWriteHeader;
    procedure DoWriteTrailer;
  public
    constructor Create(const ADest: TStream);
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;

  { TBoundedStream: 仅从底层流读取指定上限字节数，不拥有底层流 }
  TBoundedStream = class(TStream)
  private
    FBase: TStream;
    FRemain: Int64;
  public
    constructor Create(const Base: TStream; const MaxBytes: Int64);
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;

  { TGZipDecodeStream }
  TGZipDecodeStream = class(TStream)
  private
    FSource: TStream;
    FInflate: TRawInflateStream;
    FCRC: DWord;
    FSize: DWord;
    FVerified: Boolean;
    FTrailerPrefix: array[0..7] of Byte;
    FTrailerPrefixLen: Integer;
  protected
    procedure ReadHeader;
    procedure VerifyTrailer;
  public
    constructor Create(const ASource: TStream);
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;

implementation

function _try_get_pos_size(S: TStream; out CurPos, TotalSize: Int64): Boolean;
begin
  try
    CurPos := S.Position;
    TotalSize := S.Size;
    Exit(True);
  except
    Exit(False);
  end;
end;

{ TGZipCRC32 }

var
  _crc32_inited: Boolean = False;
  _crc32_table: array[0..255] of DWord;

procedure _crc32_ensure_init;
var i, j: Integer; c: DWord;
begin
  if _crc32_inited then Exit;
  for i := 0 to 255 do begin
    c := i;
    for j := 0 to 7 do begin
      if (c and 1) <> 0 then c := (c shr 1) xor $EDB88320 else c := (c shr 1);
    end;
    _crc32_table[i] := c;
  end;
  _crc32_inited := True;
end;

function _crc32_update(ASeed: DWord; const Buffer; Count: SizeInt): DWord;
var p: PByte; i: SizeInt; crc: DWord;
begin
  _crc32_ensure_init;
  p := @Buffer;
  crc := ASeed;
  for i := 0 to Count - 1 do begin
    crc := (crc shr 8) xor _crc32_table[(crc xor p[i]) and $FF];
  end;
  Result := crc;
end;

{ TBoundedStream }

constructor TBoundedStream.Create(const Base: TStream; const MaxBytes: Int64);
begin
  inherited Create;
  FBase := Base;
  FRemain := MaxBytes;
end;

function TBoundedStream.Read(var Buffer; Count: Longint): Longint;
begin
  if FRemain <= 0 then exit(0);
  if Count > FRemain then Count := FRemain;
  if Count <= 0 then exit(0);
  Result := FBase.Read(Buffer, Count);
  if Result > 0 then Dec(FRemain, Result);
end;

function TBoundedStream.Write(const Buffer; Count: Longint): Longint;
begin
  Result := 0; // 只读
end;

function TBoundedStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  Result := -1; // 不支持寻址
end;

{ TGZipEncodeStream }

procedure TGZipEncodeStream.DoWriteHeader;
const
  Hdr: array[0..9] of Byte = (
    $1F, $8B, 8, 0,  // ID1 ID2 CM=8(deflate), FLG=0
    0, 0, 0, 0,      // MTIME=0 for deterministic
    0,               // XFL=0 (unknown/auto)
    255              // OS=255 unknown
  );
begin
  FDest.WriteBuffer(Hdr, SizeOf(Hdr));
end;

procedure TGZipEncodeStream.DoWriteTrailer;
var
  Trailer: array[0..7] of Byte;
  Crc, ISize: DWord;
begin
  // gzip CRC32 是标准 IEEE-802.3 CRC，初始种子为 $FFFFFFFF，最终需按位取反
  Crc := not FCRC;
  ISize := FSize;
  // little-endian
  Trailer[0] := Byte(Crc and $FF);
  Trailer[1] := Byte((Crc shr 8) and $FF);
  Trailer[2] := Byte((Crc shr 16) and $FF);
  Trailer[3] := Byte((Crc shr 24) and $FF);
  Trailer[4] := Byte(ISize and $FF);
  Trailer[5] := Byte((ISize shr 8) and $FF);
  Trailer[6] := Byte((ISize shr 16) and $FF);
  Trailer[7] := Byte((ISize shr 24) and $FF);
  FDest.WriteBuffer(Trailer, SizeOf(Trailer));
end;

constructor TGZipEncodeStream.Create(const ADest: TStream);
begin
  inherited Create;
  FDest := ADest;
  FCRC := DWord($FFFFFFFF); FSize := 0; FClosed := False;
  DoWriteHeader;
  // 不接管 Dest 生命周期；使用 raw deflate 以匹配 gzip body 要求
  FDeflate := TRawDeflateStream.Create(FDest, False, -1);
end;

destructor TGZipEncodeStream.Destroy;
begin
  if not FClosed then begin
    FDeflate.Free; // 刷新压缩数据
    DoWriteTrailer;
    FClosed := True;
  end;
  inherited Destroy;
end;

function TGZipEncodeStream.Read(var Buffer; Count: Longint): Longint;
begin
  Result := 0; // 写流，不支持读
end;

function TGZipEncodeStream.Write(const Buffer; Count: Longint): Longint;
begin
  if Count > 0 then begin
    FCRC := _crc32_update(FCRC, Buffer, Count);
    Inc(FSize, DWord(Count));
    Result := FDeflate.Write(Buffer, Count);
  end else
    Result := 0;
end;

function TGZipEncodeStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  // 允许查询当前位置；编码侧返回已写入的未压缩字节数
  if (Origin = soCurrent) and (Offset = 0) then begin
    Result := FSize;
    Exit;
  end;
  if (Origin = soBeginning) and (Offset = 0) then begin
    Result := 0;
    Exit;
  end;
  Result := -1; // 其他寻址不支持，返回 -1，不抛异常
end;

{ TGZipDecodeStream }

procedure TGZipDecodeStream.ReadHeader;
var hdr: array[0..9] of Byte; r: Longint; flg: Byte; b: Byte; extLen: Word;
    buf: array[0..1023] of Byte; toSkip, got: Longint; hdr_crc: DWord;
    len2: array[0..1] of Byte; crc16_le: array[0..1] of Byte; got16, expect16: Word;
begin
  r := FSource.Read(hdr, SizeOf(hdr));
  if r <> SizeOf(hdr) then raise EGZipError.Create('gzip: short header');
  if (hdr[0] <> $1F) or (hdr[1] <> $8B) or (hdr[2] <> 8) then
    raise EGZipError.Create('gzip: invalid header');
  flg := hdr[3];
  // 保守校验：保留位必须为 0
  if (flg and $E0) <> 0 then
    raise EGZipError.Create('gzip: invalid flags');

  // 开始计算 header CRC32（标准 CRC，最终取 NOT 的低 16 位与 FHCRC 比较）
  hdr_crc := DWord($FFFFFFFF);
  hdr_crc := _crc32_update(hdr_crc, hdr, SizeOf(hdr));

  // 处理 FEXTRA (0x04)
  if (flg and $04) <> 0 then begin
    // 读取 2 字节小端长度，并纳入 header CRC
    r := FSource.Read(len2, SizeOf(len2));
    if r <> SizeOf(len2) then raise EGZipError.Create('gzip: short extra length');
    hdr_crc := _crc32_update(hdr_crc, len2, SizeOf(len2));
    extLen := len2[0] or (len2[1] shl 8);
    toSkip := extLen;
    while toSkip > 0 do begin
      if toSkip > SizeOf(buf) then got := SizeOf(buf) else got := toSkip;
      r := FSource.Read(buf, got);
      if r <> got then raise EGZipError.Create('gzip: short extra');
      hdr_crc := _crc32_update(hdr_crc, buf, r);
      Dec(toSkip, r);
    end;
  end;

  // 处理 FNAME (0x08)：读取到零终止（含 0）并纳入 header CRC
  if (flg and $08) <> 0 then begin
    repeat
      r := FSource.Read(b, 1);
      if r <> 1 then raise EGZipError.Create('gzip: short fname');
      hdr_crc := _crc32_update(hdr_crc, b, 1);
    until b = 0;
  end;

  // 处理 FCOMMENT (0x10)：读取到零终止并纳入 header CRC
  if (flg and $10) <> 0 then begin
    repeat
      r := FSource.Read(b, 1);
      if r <> 1 then raise EGZipError.Create('gzip: short fcomment');
      hdr_crc := _crc32_update(hdr_crc, b, 1);
    until b = 0;
  end;

  // 处理 FHCRC (0x02)：读取并校验（按 RFC：CRC32 的低 16 位，LE 存储）
  if (flg and $02) <> 0 then begin
    r := FSource.Read(crc16_le, 2);
    if r <> 2 then raise EGZipError.Create('gzip: short fhcrc');
    got16 := crc16_le[0] or (crc16_le[1] shl 8);
    expect16 := Word((not hdr_crc) and $FFFF);
    if got16 <> expect16 then raise EGZipError.Create('gzip: header crc mismatch');
  end;

  // 忽略 MTIME/XFL/OS（已在固定头中读取）
end;

procedure TGZipDecodeStream.VerifyTrailer;
var tr: array[0..7] of Byte; crc, isize: DWord; got, r: Longint; cur, total: Int64; need: Integer;
begin
  if FVerified then Exit;
  // 优先使用 inflate 未消费的前缀字节（针对非可寻址源已读入 trailer 的情况）
  got := 0;
  if FTrailerPrefixLen > 0 then begin
    need := SizeOf(tr);
    if FTrailerPrefixLen < need then need := FTrailerPrefixLen;
    Move(FTrailerPrefix[0], tr[0], need);
    got := need;
  end;
  // 可寻址源：若当前位置不在 trailer 起点，先 Seek 到末尾-8
  if _try_get_pos_size(FSource, cur, total) then begin
    if total < 8 then raise EGZipError.Create('gzip: short trailer');
    if cur <> (total - 8) then
      FSource.Seek(total - 8, soBeginning);
  end;
  // 读取剩余 trailer 字节
  while got < SizeOf(tr) do begin
    r := FSource.Read(tr[got], SizeOf(tr) - got);
    if r <= 0 then raise EGZipError.Create('gzip: short trailer');
    Inc(got, r);
  end;
  // 如果此前用了前缀，清空以避免复用
  FTrailerPrefixLen := 0;

  crc := tr[0] or (tr[1] shl 8) or (tr[2] shl 16) or (tr[3] shl 24);
  isize := tr[4] or (tr[5] shl 8) or (tr[6] shl 16) or (tr[7] shl 24);
  if crc <> DWord(not FCRC) then raise EGZipError.Create('gzip: crc mismatch');
  if isize <> FSize then raise EGZipError.Create('gzip: size mismatch');
  FVerified := True;
end;

constructor TGZipDecodeStream.Create(const ASource: TStream);
var cur, total, bodyLen: Int64; bounded: TStream;
begin
  inherited Create;
  FSource := ASource;
  FCRC := DWord($FFFFFFFF); FSize := 0; FVerified := False;
  ReadHeader;
  // 构造解压流：对可寻址源，仅允许解压“body”字节，不触达 trailer
  if _try_get_pos_size(FSource, cur, total) and (total >= cur + 8) then begin
    bodyLen := total - cur - 8;
    if bodyLen < 0 then bodyLen := 0;
    bounded := TBoundedStream.Create(FSource, bodyLen);
    FInflate := TRawInflateStream.Create(bounded, True); // 拥有 bounded
  end else begin
    // 非可寻址源：退化为直接包裹
    FInflate := TRawInflateStream.Create(FSource, False);
  end;
end;

destructor TGZipDecodeStream.Destroy;
begin
  // 析构期不做额外读取/校验，只释放解压流，避免二次读取导致的位置错乱或异常
  FreeAndNil(FInflate);
  inherited Destroy;
end;

function TGZipDecodeStream.Read(var Buffer; Count: Longint): Longint;
var cur, total: Int64; needVerify: Boolean; got: Integer;
begin
  // 如果解压流已被释放（前次 EOF 后），后续读一律返回 0；必要时补做一次校验
  if FInflate = nil then begin
    if not FVerified then VerifyTrailer;
    Exit(0);
  end;

  Result := FInflate.Read(Buffer, Count);
  if Result > 0 then begin
    FCRC := _crc32_update(FCRC, Buffer, Result);
    Inc(FSize, DWord(Result));
  end else begin
    // 捕获 inflate 未消费的 trailer 前缀（针对非可寻址源提前读入的情况）
    FTrailerPrefixLen := 0;
    got := FInflate.ReadUnconsumed(FTrailerPrefix, SizeOf(FTrailerPrefix));
    if got > 0 then FTrailerPrefixLen := got;

    // 仅当底层源确实已到 trailer 处才做校验（可寻址源更稳健）
    needVerify := True;
    if _try_get_pos_size(FSource, cur, total) then begin
      // 可寻址源：只有当当前位置已到达末尾减 8（即 trailer 起始）才校验
      needVerify := (cur >= total - 8);
    end;

    FInflate.Free;
    FInflate := nil;
    if (not FVerified) and needVerify then VerifyTrailer;
    Result := 0;
  end;
end;

function TGZipDecodeStream.Write(const Buffer; Count: Longint): Longint;
begin
  Result := 0; // 读流，不支持写
end;

function TGZipDecodeStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  // 允许查询当前位置（Position getter 会调用 Seek(0, soFromCurrent)）
  if (Origin = soCurrent) and (Offset = 0) then begin
    Result := FSize; // 已解压输出的总字节数作为“当前位置”
    Exit;
  end;
  // 兼容读取 Position:=0 的场景（某些调用方可能用以探测可寻址性）
  if (Origin = soBeginning) and (Offset = 0) then begin
    Result := 0;
    Exit;
  end;
  // 其他寻址一律返回 -1（表示不支持），不抛异常以兼容探测式调用
  Result := -1;
end;

end.
