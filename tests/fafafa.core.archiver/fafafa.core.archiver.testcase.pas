unit fafafa.core.archiver.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.archiver, fafafa.core.archiver.interfaces;

type
  TTestCase_TarRoundtrip = class(TTestCase)
  published
    procedure Test_Tar_WriteRead_Roundtrip;
    procedure Test_Tar_DirectoryAndFile_Layout;
    procedure Test_Tar_ZeroByteFile;
    procedure Test_Tar_EmptyArchive_EOF;
  end;

  TTestCase_TarGZipRoundtrip = class(TTestCase)
  published
    procedure Test_TarGZip_WriteRead_Roundtrip;
    procedure Test_GZip_Trailer_CRC_Mismatch;
    procedure Test_GZip_Trailer_Size_Mismatch;
  end;

implementation

procedure WriteBytes(const S: string; Dest: TStream);
var a: RawByteString;
begin
  a := UTF8Encode(S);
  if Length(a) > 0 then Dest.WriteBuffer(a[1], Length(a));
end;

procedure TTestCase_TarRoundtrip.Test_Tar_WriteRead_Roundtrip;
var
  ms, msOut: TMemoryStream;
  W: IArchiveWriter;
  R: IArchiveReader;
  E: IArchiveEntry;
  dataOut: TBytes;
  Opt: TArchiveOptions;
  src: TMemoryStream;
begin
  ms := TMemoryStream.Create;
  msOut := TMemoryStream.Create;
  try
    // Write TAR (no compression)
    // 注意：避免内联 var，事先声明
    Opt.Format := afTar;
    Opt.Compression := caNone;
    Opt.CompressionLevel := 0;
    Opt.Deterministic := True;
    Opt.StoreUnixPermissions := False;
    Opt.StoreTimestampsUtc := True;
    Opt.FollowSymlinks := False;

    W := CreateArchiveWriter(ms, Opt);
    // add directory and file
    W.AddDirectory('dir/');
    src := TMemoryStream.Create;
    try
      WriteBytes('hello tar', src);
      src.Position := 0;
      W.AddStream('dir/a.txt', src, Now);
    finally
      src.Free;
    end;
    W.Finish;

    // Read back
    ms.Position := 0;
    R := CreateArchiveReader(ms, afTar);
    // dir/
    AssertTrue(R.Next(E));
    AssertEquals('dir/', E.Name);
    AssertTrue(E.IsDirectory);
    // dir/a.txt
    AssertTrue(R.Next(E));
    AssertEquals('dir/a.txt', E.Name);
    AssertEquals(9, E.Size);
    msOut.Size := 0; msOut.Position := 0;
    R.ExtractCurrentToStream(msOut);
    SetLength(dataOut, msOut.Size);
    msOut.Position := 0;
    if Length(dataOut) > 0 then msOut.ReadBuffer(dataOut[0], Length(dataOut));
    AssertEquals('hello tar', TEncoding.UTF8.GetString(dataOut));
    // EOF
    AssertFalse(R.Next(E));
  finally
    msOut.Free;
    ms.Free;
  end;
end;

procedure TTestCase_TarRoundtrip.Test_Tar_DirectoryAndFile_Layout;
var
  ms: TMemoryStream;
  W: IArchiveWriter;
  R: IArchiveReader;
  E: IArchiveEntry;
  Opt: TArchiveOptions;
begin
  ms := TMemoryStream.Create;
  try
    Opt.Format := afTar;
    Opt.Compression := caNone;
    Opt.CompressionLevel := 0;
    Opt.Deterministic := True;
    Opt.StoreUnixPermissions := False;
    Opt.StoreTimestampsUtc := True;
    Opt.FollowSymlinks := False;

    W := CreateArchiveWriter(ms, Opt);
    W.AddDirectory('empty/');
    W.Finish;

    ms.Position := 0;
    R := CreateArchiveReader(ms, afTar);
    AssertTrue(R.Next(E));
    AssertTrue(E.IsDirectory);
    AssertEquals('empty/', E.Name);
    AssertEquals(0, E.Size);
    AssertFalse(R.Next(E));
  finally
    ms.Free;
  end;
end;

procedure TTestCase_TarGZipRoundtrip.Test_TarGZip_WriteRead_Roundtrip;
var
  ms, msOut: TMemoryStream;
  W: IArchiveWriter; R: IArchiveReader; E: IArchiveEntry;
  src: TMemoryStream; dataOut: TBytes;
  Opt: TArchiveOptions;
begin
  ms := TMemoryStream.Create;
  msOut := TMemoryStream.Create;
  try
    Opt.Format := afTar;
    Opt.Compression := caGZip;
    Opt.CompressionLevel := 6;
    Opt.Deterministic := True;
    Opt.StoreUnixPermissions := False;
    Opt.StoreTimestampsUtc := True;
    Opt.FollowSymlinks := False;

    W := CreateArchiveWriter(ms, Opt);
    W.AddDirectory('d/');
    src := TMemoryStream.Create;
    try
      WriteBytes('gzip ok', src);
      src.Position := 0;
      W.AddStream('d/x.txt', src, Now);
    finally
      src.Free;
    end;
    W.Finish;

    ms.Position := 0;
    R := CreateArchiveReader(ms, afTar, caGZip);
    AssertTrue(R.Next(E));
    AssertEquals('d/', E.Name);
    AssertTrue(E.IsDirectory);

    AssertTrue(R.Next(E));
    AssertEquals('d/x.txt', E.Name);
    msOut.Size := 0; msOut.Position := 0;
    R.ExtractCurrentToStream(msOut);
    SetLength(dataOut, msOut.Size);
    msOut.Position := 0; if Length(dataOut) > 0 then msOut.ReadBuffer(dataOut[0], Length(dataOut));
    AssertEquals('gzip ok', TEncoding.UTF8.GetString(dataOut));

    AssertFalse(R.Next(E));
  finally
    msOut.Free; ms.Free;
  end;
end;


procedure TTestCase_TarRoundtrip.Test_Tar_ZeroByteFile;
var ms, msOut: TMemoryStream; W: IArchiveWriter; R: IArchiveReader; E: IArchiveEntry; Opt: TArchiveOptions; src: TMemoryStream;
begin
  ms := TMemoryStream.Create; msOut := TMemoryStream.Create;
  try
    Opt.Format := afTar; Opt.Compression := caNone; Opt.CompressionLevel := 0; Opt.Deterministic := True;
    Opt.StoreUnixPermissions := False; Opt.StoreTimestampsUtc := True; Opt.FollowSymlinks := False;
    W := CreateArchiveWriter(ms, Opt);
    W.AddDirectory('d/');
    src := TMemoryStream.Create;
    try
      src.Size := 0;
      W.AddStream('d/zero.bin', src, Now);
    finally src.Free; end;
    W.Finish;

    ms.Position := 0; R := CreateArchiveReader(ms, afTar);
    AssertTrue(R.Next(E)); AssertTrue(E.IsDirectory);
    AssertTrue(R.Next(E));
    AssertEquals('d/zero.bin', E.Name);
    AssertEquals(0, E.Size);
    msOut.Size := 0; msOut.Position := 0;
    R.ExtractCurrentToStream(msOut);
    AssertEquals(0, msOut.Size);
    AssertFalse(R.Next(E));
  finally msOut.Free; ms.Free; end;
end;

procedure TTestCase_TarRoundtrip.Test_Tar_EmptyArchive_EOF;
var ms: TMemoryStream; R: IArchiveReader; E: IArchiveEntry;
begin
  ms := TMemoryStream.Create;
  try
    // 手工构造一个空归档：两个 512 字节全零块
    ms.Size := 1024; FillChar(ms.Memory^, ms.Size, 0); ms.Position := 0;
    R := CreateArchiveReader(ms, afTar);
    AssertFalse(R.Next(E));
  finally ms.Free; end;
end;

procedure TTestCase_TarGZipRoundtrip.Test_GZip_Trailer_CRC_Mismatch;
var raw, gz: TMemoryStream; W: IArchiveWriter; R: IArchiveReader; E: IArchiveEntry; Opt: TArchiveOptions; outMs: TMemoryStream; b: byte;
begin
  // 先构造一个 tar.gz
  raw := TMemoryStream.Create; gz := TMemoryStream.Create; outMs := TMemoryStream.Create;
  try
    Opt.Format := afTar; Opt.Compression := caGZip; Opt.CompressionLevel := 6; Opt.Deterministic := True;
    Opt.StoreUnixPermissions := False; Opt.StoreTimestampsUtc := True; Opt.FollowSymlinks := False;
    W := CreateArchiveWriter(gz, Opt);
    W.AddDirectory('d/');
    raw.Size := 5; // 任意内容
    W.AddStream('d/a.bin', raw, Now);
    W.Finish;

    // 篡改 CRC：最后 8 字节 trailer 的前 4 字节是 CRC（LE），翻转一个字节
    gz.Position := 0; AssertTrue(gz.Size >= 8);
    gz.Position := gz.Size - 8;
    b := PByte(gz.Memory + gz.Position)^; // 直接操作内存（内存流）
    PByte(gz.Memory + gz.Position)^ := b xor $FF;

    // 读取时应在 trailer 校验阶段抛错
    gz.Position := 0; R := CreateArchiveReader(gz, afTar, caGZip);
    AssertTrue(R.Next(E)); AssertTrue(R.Next(E));
    try
      R.ExtractCurrentToStream(outMs);
      Fail('Expected gzip trailer CRC mismatch');
    except on Ex: Exception do AssertTrue(Pos('crc mismatch', LowerCase(Ex.Message)) > 0); end;
  finally raw.Free; outMs.Free; gz.Free; end;
end;

procedure TTestCase_TarGZipRoundtrip.Test_GZip_Trailer_Size_Mismatch;
var raw, gz: TMemoryStream; W: IArchiveWriter; R: IArchiveReader; E: IArchiveEntry; Opt: TArchiveOptions; outMs: TMemoryStream; b: byte;
begin
  raw := TMemoryStream.Create; gz := TMemoryStream.Create; outMs := TMemoryStream.Create;
  try
    Opt.Format := afTar; Opt.Compression := caGZip; Opt.CompressionLevel := 6; Opt.Deterministic := True;
    Opt.StoreUnixPermissions := False; Opt.StoreTimestampsUtc := True; Opt.FollowSymlinks := False;
    W := CreateArchiveWriter(gz, Opt);
    W.AddDirectory('d/'); raw.Size := 7; W.AddStream('d/b.bin', raw, Now); W.Finish;

    // 篡改 ISIZE：trailer 的后 4 字节；翻转最低有效字节
    gz.Position := gz.Size - 4;
    b := PByte(gz.Memory + gz.Position)^;
    PByte(gz.Memory + gz.Position)^ := b xor $FF;

    gz.Position := 0; R := CreateArchiveReader(gz, afTar, caGZip);
    AssertTrue(R.Next(E)); AssertTrue(R.Next(E));
    try
      R.ExtractCurrentToStream(outMs);
      Fail('Expected gzip trailer size mismatch');
    except on Ex: Exception do AssertTrue(Pos('size mismatch', LowerCase(Ex.Message)) > 0); end;
  finally raw.Free; outMs.Free; gz.Free; end;
end;

initialization
  RegisterTest(TTestCase_TarRoundtrip);
  RegisterTest(TTestCase_TarGZipRoundtrip);

end.

