unit fafafa.core.archiver.codec.gzip;

{$mode objfpc}{$H+}

{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils,
  fafafa.core.archiver.interfaces,
  fafafa.core.compress.gzip.streams;

type
  // Backward compatible re-exports (implementation moved to fafafa.core.compress.*)
  TGZipCRC32 = fafafa.core.compress.gzip.streams.TGZipCRC32;
  TGZipEncodeStream = fafafa.core.compress.gzip.streams.TGZipEncodeStream;
  TGZipDecodeStream = fafafa.core.compress.gzip.streams.TGZipDecodeStream;

  { TGZipProvider }
  TGZipProvider = class(TInterfacedObject, ICompressionProvider, ICompressionProviderEx)
  public
    function Algorithm: TCompressionAlgorithm;
    function WrapEncode(const Dest: TStream): TStream;
    function WrapDecode(const Source: TStream): TStream;
    function WrapEncodeWithOptions(const Dest: TStream; const Level: Integer): TStream;
  end;

implementation

function TGZipProvider.Algorithm: TCompressionAlgorithm;
begin
  Result := caGZip;
end;

function TGZipProvider.WrapEncode(const Dest: TStream): TStream;
begin
  Result := TGZipEncodeStream.Create(Dest);
end;

function TGZipProvider.WrapDecode(const Source: TStream): TStream;
begin
  Result := TGZipDecodeStream.Create(Source);
end;

function TGZipProvider.WrapEncodeWithOptions(const Dest: TStream; const Level: Integer): TStream;
begin
  // Level 暂不直通到 raw deflate（内部 TRawDeflateStream 目前使用默认级别）
  // 为保持接口一致性，优先保留 Hook；后续可在 TRawDeflateStream 支持级别后接通
  Result := TGZipEncodeStream.Create(Dest);
end;

end.

