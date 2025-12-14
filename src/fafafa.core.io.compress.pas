unit fafafa.core.io.compress;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io.compress - 压缩/解压便捷函数

  提供：
  - DeflateCompress/DeflateDecompress: zlib deflate 压缩
  - GzipCompress/GzipDecompress: gzip 格式压缩

  基于 FPC 内置 ZStream 和项目现有 gzip 实现。
}

interface

uses
  SysUtils;

{ Deflate (zlib) 压缩 }
function DeflateCompress(const AData: TBytes): TBytes;
function DeflateDecompress(const AData: TBytes): TBytes;

{ Gzip 压缩 }
function GzipCompress(const AData: TBytes): TBytes;
function GzipDecompress(const AData: TBytes): TBytes;

implementation

uses
  Classes, ZStream,
  fafafa.core.io.base,
  fafafa.core.io.error,
  fafafa.core.compress.gzip.streams;

{ Deflate }

function DeflateCompress(const AData: TBytes): TBytes;
var
  DstStream: TMemoryStream;
  CompStream: TCompressionStream;
begin
  Result := nil;
  if Length(AData) = 0 then
    Exit;

  DstStream := TMemoryStream.Create;
  try
    CompStream := TCompressionStream.Create(clDefault, DstStream, False);
    try
      if Length(AData) > 0 then
        CompStream.WriteBuffer(AData[0], Length(AData));
    finally
      CompStream.Free;  // Flush and finalize
    end;

    // 复制结果
    SetLength(Result, DstStream.Size);
    if DstStream.Size > 0 then
    begin
      DstStream.Position := 0;
      DstStream.ReadBuffer(Result[0], DstStream.Size);
    end;
  finally
    DstStream.Free;
  end;
end;

function DeflateDecompress(const AData: TBytes): TBytes;
var
  SrcStream, DstStream: TMemoryStream;
  DecompStream: TDecompressionStream;
  Buf: array[0..8191] of Byte;
  N: Integer;
begin
  Result := nil;
  if Length(AData) = 0 then
    Exit;

  SrcStream := TMemoryStream.Create;
  DstStream := TMemoryStream.Create;
  try
    SrcStream.WriteBuffer(AData[0], Length(AData));
    SrcStream.Position := 0;

    try
      DecompStream := TDecompressionStream.Create(SrcStream, False);
      try
        repeat
          N := DecompStream.Read(Buf, SizeOf(Buf));
          if N > 0 then
            DstStream.WriteBuffer(Buf, N);
        until N <= 0;
      finally
        DecompStream.Free;
      end;
    except
      on E: EReadError do
        raise IOErrorWrap(ekUnexpectedEOF, 'decompress', 'deflate', E);
      on E: EStreamError do
        raise IOErrorWrap(ekInvalidData, 'decompress', 'deflate', E);
      on E: Exception do
        raise IOErrorWrap(ekUnknown, 'decompress', 'deflate', E);
    end;

    // 复制结果
    SetLength(Result, DstStream.Size);
    if DstStream.Size > 0 then
    begin
      DstStream.Position := 0;
      DstStream.ReadBuffer(Result[0], DstStream.Size);
    end;
  finally
    SrcStream.Free;
    DstStream.Free;
  end;
end;

{ Gzip }

function GzipCompress(const AData: TBytes): TBytes;
var
  DstStream: TMemoryStream;
  GzStream: TGZipEncodeStream;
begin
  Result := nil;
  if Length(AData) = 0 then
    Exit;

  DstStream := TMemoryStream.Create;
  try
    GzStream := TGZipEncodeStream.Create(DstStream);
    try
      if Length(AData) > 0 then
        GzStream.WriteBuffer(AData[0], Length(AData));
    finally
      GzStream.Free;  // Flush, write trailer
    end;

    // 复制结果
    SetLength(Result, DstStream.Size);
    if DstStream.Size > 0 then
    begin
      DstStream.Position := 0;
      DstStream.ReadBuffer(Result[0], DstStream.Size);
    end;
  finally
    DstStream.Free;
  end;
end;

function GzipDecompress(const AData: TBytes): TBytes;
var
  SrcStream, DstStream: TMemoryStream;
  GzStream: TGZipDecodeStream;
  Buf: array[0..8191] of Byte;
  N: Integer;
  Msg: string;
begin
  Result := nil;
  if Length(AData) = 0 then
    Exit;

  SrcStream := TMemoryStream.Create;
  DstStream := TMemoryStream.Create;
  try
    SrcStream.WriteBuffer(AData[0], Length(AData));
    SrcStream.Position := 0;

    try
      GzStream := TGZipDecodeStream.Create(SrcStream);
      try
        repeat
          N := GzStream.Read(Buf, SizeOf(Buf));
          if N > 0 then
            DstStream.WriteBuffer(Buf, N);
        until N <= 0;
      finally
        GzStream.Free;
      end;
    except
      on E: EReadError do
        raise IOErrorWrap(ekUnexpectedEOF, 'decompress', 'gzip', E);
      on E: EStreamError do
        raise IOErrorWrap(ekInvalidData, 'decompress', 'gzip', E);
      on E: Exception do
      begin
        // 兼容 gzip stream 抛出的错误信息（避免依赖 archiver 异常类型）
        // - short*: 截断/短读
        // - crc/size/header/flags: 数据损坏或格式非法
        Msg := LowerCase(E.Message);
        if Pos('short', Msg) > 0 then
          raise IOErrorWrap(ekUnexpectedEOF, 'decompress', 'gzip', E)
        else if (Pos('crc', Msg) > 0) or (Pos('size mismatch', Msg) > 0) or (Pos('invalid header', Msg) > 0) or (Pos('invalid flags', Msg) > 0) then
          raise IOErrorWrap(ekInvalidData, 'decompress', 'gzip', E)
        else if (Pos('inflate error', Msg) > 0) or (Pos('deflate error', Msg) > 0) then
          raise IOErrorWrap(ekInvalidData, 'decompress', 'gzip', E)
        else
          raise IOErrorWrap(ekUnknown, 'decompress', 'gzip', E);
      end;
    end;

    // 复制结果
    SetLength(Result, DstStream.Size);
    if DstStream.Size > 0 then
    begin
      DstStream.Position := 0;
      DstStream.ReadBuffer(Result[0], DstStream.Size);
    end;
  finally
    SrcStream.Free;
    DstStream.Free;
  end;
end;

end.
