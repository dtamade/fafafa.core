unit fafafa.core.archiver.test.noseek;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.archiver, fafafa.core.archiver.interfaces;

// A stream wrapper that disables seeking and size queries to simulate pipes
type
  TNoSeekStream = class(TStream)
  private
    FBase: TStream;
  public
    constructor Create(const ABase: TStream);
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
    function GetSize: Int64; override;
  end;

  TTestCase_NoSeekGzip = class(TTestCase)
  published
    procedure Test_GZip_NoSeek_Decode_Roundtrip;
  end;

implementation

constructor TNoSeekStream.Create(const ABase: TStream);
begin
  inherited Create;
  FBase := ABase;
end;

function TNoSeekStream.Read(var Buffer; Count: Longint): Longint;
begin
  Result := FBase.Read(Buffer, Count);
end;

function TNoSeekStream.Write(const Buffer; Count: Longint): Longint;
begin
  Result := FBase.Write(Buffer, Count);
end;

function TNoSeekStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  // disallow seeking
  Result := -1;
end;

function TNoSeekStream.GetSize: Int64;
begin
  // prevent size queries
  raise Exception.Create('Size not available');
end;

procedure TTestCase_NoSeekGzip.Test_GZip_NoSeek_Decode_Roundtrip;
var raw, gz: TMemoryStream; W: IArchiveWriter; R: IArchiveReader; E: IArchiveEntry; Opt: TArchiveOptions; outMs: TMemoryStream; pipe: TNoSeekStream;
begin
  raw := TMemoryStream.Create; gz := TMemoryStream.Create; outMs := TMemoryStream.Create;
  try
    Opt.Format := afTar; Opt.Compression := caGZip; Opt.CompressionLevel := 6; Opt.Deterministic := True;
    Opt.StoreUnixPermissions := False; Opt.StoreTimestampsUtc := True; Opt.FollowSymlinks := False;
    W := CreateArchiveWriter(gz, Opt);
    W.AddDirectory('d/');
    raw.Size := 11; Move(PAnsiChar(AnsiString('hello world'))^, raw.Memory^, 11);
    W.AddStream('d/a.txt', raw, Now);
    W.Finish;

    gz.Position := 0;
    pipe := TNoSeekStream.Create(gz);
    try
      R := CreateArchiveReader(pipe, afTar, caGZip);
      AssertTrue(R.Next(E)); AssertTrue(E.IsDirectory);
      AssertTrue(R.Next(E)); AssertEquals('d/a.txt', E.Name);
      outMs.Size := 0; outMs.Position := 0;
      R.ExtractCurrentToStream(outMs);
      AssertEquals(11, outMs.Size);
    finally pipe.Free; end;
  finally raw.Free; outMs.Free; gz.Free; end;
end;

initialization
  RegisterTest(TTestCase_NoSeekGzip);

end.
