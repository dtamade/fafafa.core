unit fafafa.core.archiver.codec.deflate.paszlib;

{$mode objfpc}{$H+}

{$I src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fafafa.core.archiver.interfaces;

type
  { TPaszlibDeflateProvider }
  TPaszlibDeflateProvider = class(TInterfacedObject, ICompressionProvider, ICompressionProviderEx)
  public
    function Algorithm: TCompressionAlgorithm;
    function WrapEncode(const Dest: TStream): TStream;
    function WrapDecode(const Source: TStream): TStream;
    function WrapEncodeWithOptions(const Dest: TStream; const Level: Integer): TStream;
  end;

implementation

uses ZStream;

function TPaszlibDeflateProvider.Algorithm: TCompressionAlgorithm;
begin
  // paszlib 的 TCompressionStream/TDecompressionStream 是 zlib 封装（非 gzip）
  Result := caDeflate;
end;

function TPaszlibDeflateProvider.WrapEncode(const Dest: TStream): TStream;
begin
  // 默认压缩级别：clDefault；不接管底层 Dest 的生命周期
  Result := TCompressionStream.Create(clDefault, Dest, False);
end;

function TPaszlibDeflateProvider.WrapDecode(const Source: TStream): TStream;
begin
  // 不接管底层 Source 的生命周期
  Result := TDecompressionStream.Create(Source, False);
end;

function TPaszlibDeflateProvider.WrapEncodeWithOptions(const Dest: TStream; const Level: Integer): TStream;
var cl: TCompressionLevel;
begin
  // Map integer 0..9 to paszlib levels; fallback to clDefault
  if Level <= 0 then cl := clNone
  else if Level >= 9 then cl := clMax
  else if Level <= 3 then cl := clFastest
  else cl := clDefault;
  Result := TCompressionStream.Create(cl, Dest, False);
end;

end.

