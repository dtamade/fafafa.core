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
  TStreamSink = class(TInterfacedObject, IByteSink)
  private
    FStream: TStream;
  public
    constructor Create(AStream: TStream);
    function Write(const P: Pointer; Count: SizeInt): SizeInt;
    function WriteBytes(const B: TBytes): SizeInt;
    function WriteByte(Value: Byte): SizeInt;
  end;

  TStreamSource = class(TInterfacedObject, IByteSource)
  private
    FStream: TStream;
  public
    constructor Create(AStream: TStream);
    function Read(P: Pointer; Count: SizeInt): SizeInt;
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

function TStreamSink.Write(const P: Pointer; Count: SizeInt): SizeInt;
var w: Longint;
begin
  if (P = nil) and (Count > 0) then Exit(0);
  if Count <= 0 then Exit(0);
  w := FStream.Write(P^, Count);
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

{ TStreamSource }
constructor TStreamSource.Create(AStream: TStream);
begin
  inherited Create;
  if AStream = nil then raise EArgumentNil.Create('stream=nil');
  FStream := AStream;
end;

function TStreamSource.Read(P: Pointer; Count: SizeInt): SizeInt;
var r: Longint;
begin
  if (P = nil) and (Count > 0) then Exit(0);
  if Count <= 0 then Exit(0);
  r := FStream.Read(P^, Count);
  if r < 0 then r := 0;
  Result := r;
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

