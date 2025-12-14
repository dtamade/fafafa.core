unit fafafa.core.archiver.codec.deflate.raw.paszlib;

{$mode objfpc}{$H+}

{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.compress.deflate.raw.paszlib;

type
  // Backward compatible re-exports (implementation moved to fafafa.core.compress.*)
  ERawDeflateError = fafafa.core.compress.deflate.raw.paszlib.ERawDeflateError;
  TRawDeflateStream = fafafa.core.compress.deflate.raw.paszlib.TRawDeflateStream;
  TRawInflateStream = fafafa.core.compress.deflate.raw.paszlib.TRawInflateStream;

implementation

end.
  Result := -1;
end;

end.

