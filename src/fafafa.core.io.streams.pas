unit fafafa.core.io.streams;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io.streams - TStream 适配器

  提供 TStream 与 IO 接口之间的桥接：
  - TStreamReader: TStream -> IReader
  - TStreamWriter: TStream -> IWriter
  - TStreamIO: TStream -> IReadWriteSeeker

  参考: Rust std::io::Cursor / Go io.Reader
}

interface

uses
  Classes, SysUtils,
  fafafa.core.io.base,
  fafafa.core.io.error;

type
  { TStreamReader - 将 TStream 适配为 IReader

    用法：
      var R: IReader;
      R := TStreamReader.Create(SomeStream, False);
      N := R.Read(@Buf, 100);
  }
  TStreamReader = class(TInterfacedObject, IReader)
  private
    FStream: TStream;
    FOwnsStream: Boolean;
  public
    { 创建适配器
      @param AStream 要包装的流
      @param AOwnsStream 是否拥有流（销毁时是否释放）
    }
    constructor Create(AStream: TStream; AOwnsStream: Boolean = False);
    destructor Destroy; override;

    { IReader }
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;

    property Stream: TStream read FStream;
    property OwnsStream: Boolean read FOwnsStream write FOwnsStream;
  end;

  { TStreamWriter - 将 TStream 适配为 IWriter

    用法：
      var W: IWriter;
      W := TStreamWriter.Create(SomeStream, False);
      N := W.Write(@Data, 100);
  }
  TStreamWriter = class(TInterfacedObject, IWriter, IFlusher)
  private
    FStream: TStream;
    FOwnsStream: Boolean;
  public
    constructor Create(AStream: TStream; AOwnsStream: Boolean = False);
    destructor Destroy; override;

    { IWriter }
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;

    { IFlusher }
    procedure Flush;

    property Stream: TStream read FStream;
    property OwnsStream: Boolean read FOwnsStream write FOwnsStream;
  end;

  { TStreamIO - 将 TStream 适配为完整 IO 接口

    支持 IReader + IWriter + ISeeker + ICloser + IFlusher

    用法：
      var IO: IReadWriteSeeker;
      IO := TStreamIO.Create(SomeStream, True);
  }
  TStreamIO = class(TInterfacedObject,
    IReader, IWriter, ISeeker, ICloser, IFlusher,
    IReadWriter, IReadCloser, IWriteCloser, IReadWriteCloser, IReadWriteSeeker,
    IReadSeeker, IWriteSeeker)
  private
    FStream: TStream;
    FOwnsStream: Boolean;
  public
    constructor Create(AStream: TStream; AOwnsStream: Boolean = False);
    destructor Destroy; override;

    { IReader }
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;

    { IWriter }
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;

    { ISeeker }
    function Seek(Offset: Int64; Whence: Integer): Int64;

    { ICloser }
    procedure Close;

    { IFlusher }
    procedure Flush;

    property Stream: TStream read FStream;
    property OwnsStream: Boolean read FOwnsStream write FOwnsStream;
  end;

{ 工厂函数 }

{ FromStream - 从 TStream 创建 IReader }
function ReaderFromStream(AStream: TStream; AOwnsStream: Boolean = False): IReader;

{ WriterFromStream - 从 TStream 创建 IWriter }
function WriterFromStream(AStream: TStream; AOwnsStream: Boolean = False): IWriter;

{ IOFromStream - 从 TStream 创建完整 IO 接口 }
function IOFromStream(AStream: TStream; AOwnsStream: Boolean = False): IReadWriteSeeker;

implementation

{ TStreamReader }

constructor TStreamReader.Create(AStream: TStream; AOwnsStream: Boolean);
begin
  inherited Create;
  if AStream = nil then
    raise EIOError.Create('TStreamReader: stream is nil');
  FStream := AStream;
  FOwnsStream := AOwnsStream;
end;

destructor TStreamReader.Destroy;
begin
  if FOwnsStream and (FStream <> nil) then
    FStream.Free;
  inherited Destroy;
end;

function TStreamReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
var
  Kind: TIOErrorKind;
begin
  Result := 0;
  if (Buf = nil) or (Count <= 0) then
    Exit;

  try
    Result := FStream.Read(Buf^, Count);
  except
    on E: EIOError do
      raise;
    on E: EInOutError do
    begin
      Kind := ekUnknown;
      {$IFDEF UNIX}
      Kind := IOUnixErrorKind(E.ErrorCode);
      {$ENDIF}
      {$IFDEF WINDOWS}
      Kind := IOWinErrorKind(E.ErrorCode);
      {$ENDIF}
      raise EIOError.Create(Kind, 'read', '', E.ErrorCode, E.Message);
    end;
    on E: Exception do
      raise IOErrorWrap(ekUnknown, 'read', '', E);
  end;
end;

{ TStreamWriter }

constructor TStreamWriter.Create(AStream: TStream; AOwnsStream: Boolean);
begin
  inherited Create;
  if AStream = nil then
    raise EIOError.Create('TStreamWriter: stream is nil');
  FStream := AStream;
  FOwnsStream := AOwnsStream;
end;

destructor TStreamWriter.Destroy;
begin
  if FOwnsStream and (FStream <> nil) then
    FStream.Free;
  inherited Destroy;
end;

function TStreamWriter.Write(Buf: Pointer; Count: SizeInt): SizeInt;
var
  Kind: TIOErrorKind;
begin
  Result := 0;
  if (Buf = nil) or (Count <= 0) then
    Exit;

  try
    Result := FStream.Write(Buf^, Count);
  except
    on E: EIOError do
      raise;
    on E: EInOutError do
    begin
      Kind := ekUnknown;
      {$IFDEF UNIX}
      Kind := IOUnixErrorKind(E.ErrorCode);
      {$ENDIF}
      {$IFDEF WINDOWS}
      Kind := IOWinErrorKind(E.ErrorCode);
      {$ENDIF}
      raise EIOError.Create(Kind, 'write', '', E.ErrorCode, E.Message);
    end;
    on E: Exception do
      raise IOErrorWrap(ekUnknown, 'write', '', E);
  end;
end;

procedure TStreamWriter.Flush;
begin
  // TStream 没有标准 Flush 方法
  // 某些子类（如 TFileStream）可能需要特殊处理
end;

{ TStreamIO }

constructor TStreamIO.Create(AStream: TStream; AOwnsStream: Boolean);
begin
  inherited Create;
  if AStream = nil then
    raise EIOError.Create('TStreamIO: stream is nil');
  FStream := AStream;
  FOwnsStream := AOwnsStream;
end;

destructor TStreamIO.Destroy;
begin
  if FOwnsStream and (FStream <> nil) then
    FStream.Free;
  inherited Destroy;
end;

function TStreamIO.Read(Buf: Pointer; Count: SizeInt): SizeInt;
var
  Kind: TIOErrorKind;
begin
  Result := 0;
  if (Buf = nil) or (Count <= 0) then
    Exit;

  try
    Result := FStream.Read(Buf^, Count);
  except
    on E: EIOError do
      raise;
    on E: EInOutError do
    begin
      Kind := ekUnknown;
      {$IFDEF UNIX}
      Kind := IOUnixErrorKind(E.ErrorCode);
      {$ENDIF}
      {$IFDEF WINDOWS}
      Kind := IOWinErrorKind(E.ErrorCode);
      {$ENDIF}
      raise EIOError.Create(Kind, 'read', '', E.ErrorCode, E.Message);
    end;
    on E: Exception do
      raise IOErrorWrap(ekUnknown, 'read', '', E);
  end;
end;

function TStreamIO.Write(Buf: Pointer; Count: SizeInt): SizeInt;
var
  Kind: TIOErrorKind;
begin
  Result := 0;
  if (Buf = nil) or (Count <= 0) then
    Exit;

  try
    Result := FStream.Write(Buf^, Count);
  except
    on E: EIOError do
      raise;
    on E: EInOutError do
    begin
      Kind := ekUnknown;
      {$IFDEF UNIX}
      Kind := IOUnixErrorKind(E.ErrorCode);
      {$ENDIF}
      {$IFDEF WINDOWS}
      Kind := IOWinErrorKind(E.ErrorCode);
      {$ENDIF}
      raise EIOError.Create(Kind, 'write', '', E.ErrorCode, E.Message);
    end;
    on E: Exception do
      raise IOErrorWrap(ekUnknown, 'write', '', E);
  end;
end;

function TStreamIO.Seek(Offset: Int64; Whence: Integer): Int64;
var
  Origin: Word;
  Kind: TIOErrorKind;
begin
  case Whence of
    SeekStart:   Origin := soFromBeginning;
    SeekCurrent: Origin := soFromCurrent;
    SeekEnd:     Origin := soFromEnd;
  else
    raise EIOError.Create(ekInvalidInput, 'seek', '', 0, 'invalid whence');
  end;

  try
    Result := FStream.Seek(Offset, Origin);
  except
    on E: EIOError do
      raise;
    on E: EInOutError do
    begin
      Kind := ekUnknown;
      {$IFDEF UNIX}
      Kind := IOUnixErrorKind(E.ErrorCode);
      {$ENDIF}
      {$IFDEF WINDOWS}
      Kind := IOWinErrorKind(E.ErrorCode);
      {$ENDIF}
      raise EIOError.Create(Kind, 'seek', '', E.ErrorCode, E.Message);
    end;
    on E: Exception do
      raise IOErrorWrap(ekUnknown, 'seek', '', E);
  end;
end;

procedure TStreamIO.Close;
begin
  if FOwnsStream and (FStream <> nil) then
  begin
    FStream.Free;
    FStream := nil;
  end;
end;

procedure TStreamIO.Flush;
begin
  // TStream 没有标准 Flush 方法
end;

{ 工厂函数 }

function ReaderFromStream(AStream: TStream; AOwnsStream: Boolean): IReader;
begin
  Result := TStreamReader.Create(AStream, AOwnsStream);
end;

function WriterFromStream(AStream: TStream; AOwnsStream: Boolean): IWriter;
begin
  Result := TStreamWriter.Create(AStream, AOwnsStream);
end;

function IOFromStream(AStream: TStream; AOwnsStream: Boolean): IReadWriteSeeker;
begin
  Result := TStreamIO.Create(AStream, AOwnsStream);
end;

end.
