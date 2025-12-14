unit fafafa.core.compress;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.io.base,
  fafafa.core.io.compress.streaming,
  fafafa.core.io.compress;

type
  { Re-export IO traits used by streaming codecs }
  IReader = fafafa.core.io.base.IReader;
  IWriter = fafafa.core.io.base.IWriter;
  ISeeker = fafafa.core.io.base.ISeeker;
  ICloser = fafafa.core.io.base.ICloser;
  IFlusher = fafafa.core.io.base.IFlusher;

  IReadCloser = fafafa.core.io.base.IReadCloser;
  IWriteCloser = fafafa.core.io.base.IWriteCloser;

  { Streaming codecs }
  TGzipCodec = fafafa.core.io.compress.streaming.TGzipCodec;
  TDeflateCodec = fafafa.core.io.compress.streaming.TDeflateCodec;

  { Compress - facade namespace (similar style to IO) }
  Compress = record
  public
    { Gzip streaming codec namespace }
    class function Gzip: TGzipCodec; static;
    { Deflate streaming codec namespace }
    class function Deflate: TDeflateCodec; static;

    { Byte helpers }
    class function DeflateCompress(const AData: TBytes): TBytes; static;
    class function DeflateDecompress(const AData: TBytes): TBytes; static;
    class function GzipCompress(const AData: TBytes): TBytes; static;
    class function GzipDecompress(const AData: TBytes): TBytes; static;
  end;

implementation

class function Compress.Gzip: TGzipCodec;
begin
  Result := Default(TGzipCodec);
end;

class function Compress.Deflate: TDeflateCodec;
begin
  Result := Default(TDeflateCodec);
end;

class function Compress.DeflateCompress(const AData: TBytes): TBytes;
begin
  Result := fafafa.core.io.compress.DeflateCompress(AData);
end;

class function Compress.DeflateDecompress(const AData: TBytes): TBytes;
begin
  Result := fafafa.core.io.compress.DeflateDecompress(AData);
end;

class function Compress.GzipCompress(const AData: TBytes): TBytes;
begin
  Result := fafafa.core.io.compress.GzipCompress(AData);
end;

class function Compress.GzipDecompress(const AData: TBytes): TBytes;
begin
  Result := fafafa.core.io.compress.GzipDecompress(AData);
end;

end.
