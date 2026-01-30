unit fafafa.core.compress.deflate.raw.paszlib;

{$mode objfpc}{$H+}

{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils,
  fafafa.core.base;  // ✅ DEFLATE-001: 引入 ECore 基类

// 原始 deflate/inflate 流封装：使用 zlib 的 *Init2(windowBits=-MAX_WBITS)* 原始模式
// - 不写入/解析 zlib 头与 Adler32 尾（供 gzip 编解码内部使用）

type
  ERawDeflateError = class(ECore);  // ✅ DEFLATE-001: 继承自 ECore

  TRawDeflateStream = class(TStream)
  private
    FDest: TStream;
    FOwnsDest: Boolean;
    FInit: Boolean;
    FLevel: Integer;
    FZ: Pointer; // holds Pz_stream
  protected
    procedure DoInit; inline;
    procedure DoFinish; inline;
  public
    constructor Create(const ADest: TStream; const AOwnsDest: Boolean; const ALevel: Integer = -1);
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;

  TRawInflateStream = class(TStream)
  private
    FSource: TStream;
    FOwnsSource: Boolean;
    FInit: Boolean;
    FEOF: Boolean;
    FZ: Pointer; // holds Pz_stream
    FInBuf: array[0..8191] of Byte;
    FInAvail: SizeInt;
    // leftover bytes not consumed by zlib (e.g., gzip trailer read-ahead)
    FUnconsumed: array of Byte;
    FUnconsumedOff: SizeInt;
    FUnconsumedLen: SizeInt;
  protected
    procedure DoInit; inline;
  public
    constructor Create(const ASource: TStream; const AOwnsSource: Boolean);
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    // Expose unconsumed input bytes (copied when Z_STREAM_END is reached)
    function ReadUnconsumed(var Buffer; Count: Longint): Longint;
  end;

implementation

uses zlib;

type
  Pz_stream = ^z_stream;

{ TRawDeflateStream }

constructor TRawDeflateStream.Create(const ADest: TStream; const AOwnsDest: Boolean; const ALevel: Integer);
begin
  inherited Create;
  FDest := ADest;
  FOwnsDest := AOwnsDest;
  FInit := False;
  if ALevel < 0 then FLevel := Z_DEFAULT_COMPRESSION else FLevel := ALevel;
  DoInit;
end;

procedure TRawDeflateStream.DoInit;
var pz: Pz_stream;
begin
  New(pz);
  FillChar(pz^, SizeOf(z_stream), 0);
  FZ := pz;
  // windowBits = -15 => raw deflate
  if deflateInit2(pz^, FLevel, Z_DEFLATED, -15, 8, Z_DEFAULT_STRATEGY) <> Z_OK then
    raise ERawDeflateError.Create('deflateInit2 failed');
  FInit := True;
end;

procedure TRawDeflateStream.DoFinish;
var pz: Pz_stream; outBuf: array[0..8191] of Byte; rc: Integer;
begin
  if not FInit then Exit;
  pz := Pz_stream(FZ);
  repeat
    pz^.next_out := @outBuf[0];
    pz^.avail_out := SizeOf(outBuf);
    rc := deflate(pz^, Z_FINISH);
    if (SizeOf(outBuf) - pz^.avail_out) > 0 then
      FDest.WriteBuffer(outBuf[0], SizeOf(outBuf) - pz^.avail_out);
  until rc = Z_STREAM_END;
  deflateEnd(pz^);
  Dispose(pz);
  FZ := nil;
  FInit := False;
end;

destructor TRawDeflateStream.Destroy;
begin
  try
    DoFinish;
  finally
    if FOwnsDest then FreeAndNil(FDest);
    inherited Destroy;
  end;
end;

function TRawDeflateStream.Read(var Buffer; Count: Longint): Longint;
begin
  Result := 0; // 写流，不支持读
end;

function TRawDeflateStream.Write(const Buffer; Count: Longint): Longint;
var pz: Pz_stream; inPtr: PByte; remaining: SizeInt; outBuf: array[0..8191] of Byte; rc: Integer;
begin
  if Count <= 0 then Exit(0);
  if not FInit then DoInit;
  pz := Pz_stream(FZ);
  inPtr := @Buffer;
  remaining := Count;
  Result := Count;
  while remaining > 0 do begin
    pz^.next_in := pBytef(inPtr);
    if remaining > High(Word) then pz^.avail_in := High(Word) else pz^.avail_in := remaining;
    remaining := remaining - pz^.avail_in;
    Inc(inPtr, pz^.avail_in);
    repeat
      pz^.next_out := @outBuf[0];
      pz^.avail_out := SizeOf(outBuf);
      rc := deflate(pz^, Z_NO_FLUSH);
      if (rc < 0) then raise ERawDeflateError.CreateFmt('deflate error: %d', [rc]);
      if (SizeOf(outBuf) - pz^.avail_out) > 0 then
        FDest.WriteBuffer(outBuf[0], SizeOf(outBuf) - pz^.avail_out);
    until (pz^.avail_in = 0) and (pz^.avail_out > 0);
  end;
end;

function TRawDeflateStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  Result := -1;
end;

{ TRawInflateStream }

constructor TRawInflateStream.Create(const ASource: TStream; const AOwnsSource: Boolean);
begin
  inherited Create;
  FSource := ASource;
  FOwnsSource := AOwnsSource;
  FInit := False;
  FEOF := False;
  FInAvail := 0;
  DoInit;
end;

procedure TRawInflateStream.DoInit;
var pz: Pz_stream;
begin
  New(pz);
  FillChar(pz^, SizeOf(z_stream), 0);
  FZ := pz;
  // windowBits = -15 => raw inflate
  if inflateInit2(pz^, -15) <> Z_OK then
    raise ERawDeflateError.Create('inflateInit2 failed');
  FInit := True;
end;

destructor TRawInflateStream.Destroy;
var pz: Pz_stream;
begin
  try
    if FInit then begin
      pz := Pz_stream(FZ);
      inflateEnd(pz^);
      Dispose(pz);
      FZ := nil;
      FInit := False;
    end;
  finally
    if FOwnsSource then FreeAndNil(FSource);
    inherited Destroy;
  end;
end;

function TRawInflateStream.ReadUnconsumed(var Buffer; Count: Longint): Longint;
begin
  Result := 0;
end;

function TRawInflateStream.Read(var Buffer; Count: Longint): Longint;
var pz: Pz_stream; outPtr: PByte; want: SizeInt; rc: Integer; produced, usedIn: SizeInt;
begin
  if Count <= 0 then Exit(0);
  if not FInit then DoInit;
  pz := Pz_stream(FZ);
  outPtr := @Buffer;
  want := Count;
  Result := 0;
  while want > 0 do begin
    if (pz^.avail_in = 0) and (not FEOF) then begin
      FInAvail := FSource.Read(FInBuf[0], SizeOf(FInBuf));
      if FInAvail <= 0 then begin
        FEOF := True;
        break;
      end;
      pz^.next_in := @FInBuf[0];
      pz^.avail_in := FInAvail;
    end;
    pz^.next_out := pBytef(outPtr);
    pz^.avail_out := want;
    rc := inflate(pz^, Z_NO_FLUSH);
    if (rc < 0) then raise ERawDeflateError.CreateFmt('inflate error: %d', [rc]);
    // produced bytes = requested - remaining
    produced := want - pz^.avail_out;
    if produced > 0 then begin
      Inc(Result, produced);
      Inc(outPtr, produced);
      want := pz^.avail_out;
    end;
    if rc = Z_STREAM_END then begin
      // capture unconsumed input (e.g., gzip trailer already read into inbuf)
      usedIn := FInAvail - pz^.avail_in;
      if (FInAvail > usedIn) then begin
        FUnconsumedLen := FInAvail - usedIn;
        FUnconsumedOff := usedIn;
        SetLength(FUnconsumed, FUnconsumedLen);
        if FUnconsumedLen > 0 then
          Move(FInBuf[FUnconsumedOff], FUnconsumed[0], FUnconsumedLen);
      end else begin
        FUnconsumedLen := 0;
        SetLength(FUnconsumed, 0);
      end;
      FEOF := True;
      break;
    end; // rc = Z_STREAM_END
  end; // while want > 0
end;

function TRawInflateStream.Write(const Buffer; Count: Longint): Longint;
begin
  Result := 0; // 读流，不支持写
end;

function TRawInflateStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  // 支持 Position 查询为已输出的总字节数较复杂，这里返回 -1 表示不支持
  Result := -1;
end;

end.
