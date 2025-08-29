unit fafafa.core.io.adapters;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.bytes;

// Stream <-> IByteSink/IByteSource 适配

type
  TStreamSink = class(TInterfacedObject, IByteWriter)
  private
    FStream: TStream;
  public
    constructor Create(AStream: TStream);
    // IWriter 接口
    function Write(const Buffer: Pointer; Count: SizeInt): SizeInt;
    // IByteWriter 接口
    function WriteByte(Value: Byte): SizeInt;
    function WriteBytes(const B: TBytes): SizeInt;
    function WriteString(const S: RawByteString): SizeInt;
  end;

  TStreamSource = class(TInterfacedObject, IByteReader)
  private
    FStream: TStream;
  public
    constructor Create(AStream: TStream);
    // IReader 接口
    function Read(Buffer: Pointer; Count: SizeInt): SizeInt;
    // IByteReader 接口
    function ReadByte: Byte;
    function ReadBytes(Count: SizeInt): TBytes;
    function ReadAll: TBytes;
    function ReadString(Count: SizeInt): RawByteString;
  end;

function MakeStreamSink(AStream: TStream): IByteSink; inline;
function MakeStreamSource(AStream: TStream): IByteSource; inline;

implementation

{ TStreamSink }
constructor TStreamSink.Create(AStream: TStream);
begin
  inherited Create;
  if AStream = nil then raise EArgumentNil.Create('stream=nil');
  FStream := AStream;
end;

function TStreamSink.Write(const Buffer: Pointer; Count: SizeInt): SizeInt;
var w: Longint;
begin
  if (Buffer = nil) and (Count > 0) then Exit(0);
  if Count <= 0 then Exit(0);
  w := FStream.Write(Buffer^, Count);
  if w < 0 then w := 0;
  Result := w;
end;

function TStreamSink.WriteBytes(const B: TBytes): SizeInt;
var w: Longint;
begin
  if Length(B) = 0 then Exit(0);
  w := FStream.Write(B[0], Length(B));
  if w < 0 then w := 0;
  Result := w;
end;

function TStreamSink.WriteByte(Value: Byte): SizeInt;
var w: Longint;
begin
  w := FStream.Write(Value, 1);
  if w < 0 then w := 0;
  Result := w;
end;

function TStreamSink.WriteString(const S: RawByteString): SizeInt;
var w: Longint;
begin
  if Length(S) = 0 then Exit(0);
  w := FStream.Write(S[1], Length(S));
  if w < 0 then w := 0;
  Result := w;
end;

{ TStreamSource }
constructor TStreamSource.Create(AStream: TStream);
begin
  inherited Create;
  if AStream = nil then raise EArgumentNil.Create('stream=nil');
  FStream := AStream;
end;

function TStreamSource.Read(Buffer: Pointer; Count: SizeInt): SizeInt;
var r: Longint;
begin
  if (Buffer = nil) and (Count > 0) then Exit(0);
  if Count <= 0 then Exit(0);
  r := FStream.Read(Buffer^, Count);
  if r < 0 then r := 0;
  Result := r;
end;

function TStreamSource.ReadByte: Byte;
var r: Longint;
begin
  r := FStream.Read(Result, 1);
  if r <> 1 then
    raise EEOFError.Create('Unexpected end of stream');
end;

function TStreamSource.ReadBytes(Count: SizeInt): TBytes;
var r: Longint;
begin
  if Count <= 0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;
  SetLength(Result, Count);
  r := FStream.Read(Result[0], Count);
  if r < Count then
    SetLength(Result, r);
end;

function TStreamSource.ReadAll: TBytes;
const ChunkSize = 8192;
var
  buffer: array[0..ChunkSize-1] of Byte;
  totalRead, r: Longint;
begin
  SetLength(Result, 0);
  totalRead := 0;
  repeat
    r := FStream.Read(buffer[0], ChunkSize);
    if r > 0 then
    begin
      SetLength(Result, totalRead + r);
      Move(buffer[0], Result[totalRead], r);
      Inc(totalRead, r);
    end;
  until r < ChunkSize;
end;

function TStreamSource.ReadString(Count: SizeInt): RawByteString;
var r: Longint;
begin
  if Count <= 0 then
  begin
    Result := '';
    Exit;
  end;
  SetLength(Result, Count);
  r := FStream.Read(Result[1], Count);
  if r < Count then
    SetLength(Result, r);
end;

function MakeStreamSink(AStream: TStream): IByteSink;
begin
  Result := TStreamSink.Create(AStream);
end;

function MakeStreamSource(AStream: TStream): IByteSource;
begin
  Result := TStreamSource.Create(AStream);
end;

end.

