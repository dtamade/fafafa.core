unit fafafa.core.io.compress.streaming;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io.compress.streaming - 流式压缩/解压适配器

  提供 IReader/IWriter 风格的流式压缩门面：
  - TGzipCodec: IO.Gzip.Encode/Decode
  - TDeflateCodec: IO.Deflate.Encode/Decode

  内部复用 TGZip*Stream / TCompression*Stream，统一错误映射为 EIOError。
}

interface

uses
  Classes, SysUtils,
  fafafa.core.io.base;

type
  { TGzipCodec - Gzip 流式编解码器命名空间 }
  TGzipCodec = record
    { 创建 Gzip 编码写入器：写入的数据被压缩后写入 Dest }
    class function Encode(ADest: IWriter): IWriteCloser; static;
    { 创建 Gzip 解码读取器：从 Src 读取压缩数据并返回解压后的数据 }
    class function Decode(ASrc: IReader): IReadCloser; static;
  end;

  { TDeflateCodec - Deflate (zlib) 流式编解码器命名空间 }
  TDeflateCodec = record
    { 创建 Deflate 编码写入器 }
    class function Encode(ADest: IWriter): IWriteCloser; static;
    { 创建 Deflate 解码读取器 }
    class function Decode(ASrc: IReader): IReadCloser; static;
  end;

implementation

uses
  ZStream,
  fafafa.core.io.error,
  fafafa.core.io.streams,
  fafafa.core.compress.gzip.streams;

type
  { TWriterStream - 将 IWriter 包装为 TStream（仅支持写入） }
  TWriterStream = class(TStream)
  private
    FWriter: IWriter;
  public
    constructor Create(AWriter: IWriter);
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;

  { TReaderStream - 将 IReader 包装为 TStream（仅支持读取） }
  TReaderStream = class(TStream)
  private
    FReader: IReader;
  public
    constructor Create(AReader: IReader);
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;

  { TGzipEncodeWriter - Gzip 编码写入器 }
  TGzipEncodeWriter = class(TInterfacedObject, IWriter, ICloser, IWriteCloser)
  private
    FDestStream: TWriterStream;
    FGzipStream: TGZipEncodeStream;
    FClosed: Boolean;
  public
    constructor Create(ADest: IWriter);
    destructor Destroy; override;
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;
    procedure Close;
  end;

  { TGzipDecodeReader - Gzip 解码读取器 }
  TGzipDecodeReader = class(TInterfacedObject, IReader, ICloser, IReadCloser)
  private
    FSrcStream: TReaderStream;
    FGzipStream: TGZipDecodeStream;
    FClosed: Boolean;
  public
    constructor Create(ASrc: IReader);
    destructor Destroy; override;
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;
    procedure Close;
  end;

  { TDeflateEncodeWriter - Deflate 编码写入器 }
  TDeflateEncodeWriter = class(TInterfacedObject, IWriter, ICloser, IWriteCloser)
  private
    FDestStream: TWriterStream;
    FCompStream: TCompressionStream;
    FClosed: Boolean;
  public
    constructor Create(ADest: IWriter);
    destructor Destroy; override;
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;
    procedure Close;
  end;

  { TDeflateDecodeReader - Deflate 解码读取器 }
  TDeflateDecodeReader = class(TInterfacedObject, IReader, ICloser, IReadCloser)
  private
    FSrcStream: TReaderStream;
    FDecompStream: TDecompressionStream;
    FClosed: Boolean;
  public
    constructor Create(ASrc: IReader);
    destructor Destroy; override;
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;
    procedure Close;
  end;

{ TWriterStream }

constructor TWriterStream.Create(AWriter: IWriter);
begin
  inherited Create;
  FWriter := AWriter;
end;

function TWriterStream.Read(var Buffer; Count: Longint): Longint;
begin
  Result := 0; // 不支持读
end;

function TWriterStream.Write(const Buffer; Count: Longint): Longint;
var
  Written: SizeInt;
begin
  if Count <= 0 then
    Exit(0);

  while True do
  begin
    try
      Written := FWriter.Write(@Buffer, Count);
    except
      on E: EIOError do
      begin
        if E.Kind = ekInterrupted then
          Continue;
        raise;
      end;
    end;

    if (Count > 0) and (Written = 0) then
      raise EIOError.Create(ekWriteZero, 'write returned 0');

    Result := Written;
    Exit;
  end;
end;

function TWriterStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  // 仅支持查询当前位置（某些压缩流可能会调用）
  if (Origin = soCurrent) and (Offset = 0) then
    Result := 0
  else
    Result := -1;
end;

{ TReaderStream }

constructor TReaderStream.Create(AReader: IReader);
begin
  inherited Create;
  FReader := AReader;
end;

function TReaderStream.Read(var Buffer; Count: Longint): Longint;
begin
  if Count <= 0 then
    Exit(0);

  while True do
  begin
    try
      Result := FReader.Read(@Buffer, Count);
      Exit;
    except
      on E: EIOError do
      begin
        if E.Kind = ekInterrupted then
          Continue;
        raise;
      end;
    end;
  end;
end;

function TReaderStream.Write(const Buffer; Count: Longint): Longint;
begin
  Result := 0; // 不支持写
end;

function TReaderStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
var
  Seeker: ISeeker;
begin
  // 尝试使用底层 Seeker
  if Supports(FReader, ISeeker, Seeker) then
  begin
    case Origin of
      soBeginning: Result := Seeker.Seek(Offset, SeekStart);
      soCurrent: Result := Seeker.Seek(Offset, SeekCurrent);
      soEnd: Result := Seeker.Seek(Offset, SeekEnd);
    end;
  end
  else if (Origin = soCurrent) and (Offset = 0) then
    Result := 0
  else
    Result := -1;
end;

{ TGzipEncodeWriter }

constructor TGzipEncodeWriter.Create(ADest: IWriter);
begin
  inherited Create;
  FClosed := False;
  FDestStream := TWriterStream.Create(ADest);
  FGzipStream := TGZipEncodeStream.Create(FDestStream);
end;

destructor TGzipEncodeWriter.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TGzipEncodeWriter.Write(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  if FClosed then
    raise EIOError.Create(ekBrokenPipe, 'write to closed gzip encoder');
  if Count <= 0 then
    Exit(0);
  try
    Result := FGzipStream.Write(Buf^, Count);
  except
    on E: Exception do
      raise IOErrorWrap(ekUnknown, 'gzip.encode', '', E);
  end;
end;

procedure TGzipEncodeWriter.Close;
begin
  if FClosed then Exit;
  FClosed := True;
  FreeAndNil(FGzipStream); // 刷新并写入 trailer
  FreeAndNil(FDestStream);
end;

{ TGzipDecodeReader }

constructor TGzipDecodeReader.Create(ASrc: IReader);
begin
  inherited Create;
  FClosed := False;
  FSrcStream := TReaderStream.Create(ASrc);
  try
    FGzipStream := TGZipDecodeStream.Create(FSrcStream);
  except
    on E: Exception do
    begin
      FreeAndNil(FSrcStream);
      raise IOErrorWrap(ekInvalidData, 'gzip.decode', '', E);
    end;
  end;
end;

destructor TGzipDecodeReader.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TGzipDecodeReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  if FClosed then
    Exit(0);
  if Count <= 0 then
    Exit(0);
  try
    Result := FGzipStream.Read(Buf^, Count);
  except
    on E: EIOError do
      raise;
    on E: Exception do
    begin
      if Pos('crc', LowerCase(E.Message)) > 0 then
        raise IOErrorWrap(ekInvalidData, 'gzip.decode', '', E)
      else if Pos('short', LowerCase(E.Message)) > 0 then
        raise IOErrorWrap(ekUnexpectedEOF, 'gzip.decode', '', E)
      else
        raise IOErrorWrap(ekInvalidData, 'gzip.decode', '', E);
    end;
  end;
end;

procedure TGzipDecodeReader.Close;
begin
  if FClosed then Exit;
  FClosed := True;
  FreeAndNil(FGzipStream);
  FreeAndNil(FSrcStream);
end;

{ TDeflateEncodeWriter }

constructor TDeflateEncodeWriter.Create(ADest: IWriter);
begin
  inherited Create;
  FClosed := False;
  FDestStream := TWriterStream.Create(ADest);
  FCompStream := TCompressionStream.Create(clDefault, FDestStream, False);
end;

destructor TDeflateEncodeWriter.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TDeflateEncodeWriter.Write(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  if FClosed then
    raise EIOError.Create(ekBrokenPipe, 'write to closed deflate encoder');
  if Count <= 0 then
    Exit(0);
  try
    Result := FCompStream.Write(Buf^, Count);
  except
    on E: Exception do
      raise IOErrorWrap(ekUnknown, 'deflate.encode', '', E);
  end;
end;

procedure TDeflateEncodeWriter.Close;
begin
  if FClosed then Exit;
  FClosed := True;
  FreeAndNil(FCompStream); // 刷新
  FreeAndNil(FDestStream);
end;

{ TDeflateDecodeReader }

constructor TDeflateDecodeReader.Create(ASrc: IReader);
begin
  inherited Create;
  FClosed := False;
  FSrcStream := TReaderStream.Create(ASrc);
  try
    FDecompStream := TDecompressionStream.Create(FSrcStream, False);
  except
    on E: Exception do
    begin
      FreeAndNil(FSrcStream);
      raise IOErrorWrap(ekInvalidData, 'deflate.decode', '', E);
    end;
  end;
end;

destructor TDeflateDecodeReader.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TDeflateDecodeReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  if FClosed then
    Exit(0);
  if Count <= 0 then
    Exit(0);
  try
    Result := FDecompStream.Read(Buf^, Count);
  except
    on E: EReadError do
      raise IOErrorWrap(ekUnexpectedEOF, 'deflate.decode', '', E);
    on E: EStreamError do
      raise IOErrorWrap(ekInvalidData, 'deflate.decode', '', E);
    on E: Exception do
      raise IOErrorWrap(ekUnknown, 'deflate.decode', '', E);
  end;
end;

procedure TDeflateDecodeReader.Close;
begin
  if FClosed then Exit;
  FClosed := True;
  FreeAndNil(FDecompStream);
  FreeAndNil(FSrcStream);
end;

{ TGzipCodec }

class function TGzipCodec.Encode(ADest: IWriter): IWriteCloser;
begin
  Result := TGzipEncodeWriter.Create(ADest);
end;

class function TGzipCodec.Decode(ASrc: IReader): IReadCloser;
begin
  Result := TGzipDecodeReader.Create(ASrc);
end;

{ TDeflateCodec }

class function TDeflateCodec.Encode(ADest: IWriter): IWriteCloser;
begin
  Result := TDeflateEncodeWriter.Create(ADest);
end;

class function TDeflateCodec.Decode(ASrc: IReader): IReadCloser;
begin
  Result := TDeflateDecodeReader.Create(ASrc);
end;

end.
