unit fafafa.core.archiver.test.gzip.flags;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.archiver, fafafa.core.archiver.interfaces;

type
  TTestCase_GZipHeaderFlags = class(TTestCase)
  published
    procedure Test_GZip_HeaderFlags_All_Supported;
    procedure Test_GZip_Header_FHCRC_Mismatch_Rejected;
  end;

implementation

// Minimal CRC32 for tests (same poly/seed/finalize as prod):
// seed starts at $FFFFFFFF, update per byte, final value uses NOT
var
  g_crc_table: array[0..255] of DWord;
  g_crc_inited: Boolean = False;

procedure crc32_ensure_init;
var i, j: Integer; c: DWord;
begin
  if g_crc_inited then Exit;
  for i := 0 to 255 do begin
    c := i;
    for j := 0 to 7 do begin
      if (c and 1) <> 0 then c := (c shr 1) xor $EDB88320 else c := (c shr 1);
    end;
    g_crc_table[i] := c;
  end;
  g_crc_inited := True;
end;

function crc32_update(ASeed: DWord; const Buffer; Count: SizeInt): DWord;
var p: PByte; i: SizeInt; crc: DWord;
begin
  crc32_ensure_init;
  p := @Buffer; crc := ASeed;
  for i := 0 to Count - 1 do
    crc := (crc shr 8) xor g_crc_table[(crc xor p[i]) and $FF];
  Result := crc;
end;

procedure BuildGZipHeaderWithFlags(const Orig: TStream; const OutStream: TStream; SetFHCRC, SetFEXTRA, SetFNAME, SetFCOMMENT: Boolean);
var hdr: array[0..9] of Byte; r: Longint; flg: Byte; hdr_crc: DWord;
    // buffers
    extra: array[0..3] of Byte;
    xlen: array[0..1] of Byte;
    name: RawByteString;
    cmt: RawByteString;
    b: Byte;
    crc16_le: array[0..1] of Byte;
begin
  // read original 10-byte header
  r := Orig.Read(hdr, SizeOf(hdr));
  if r <> SizeOf(hdr) then raise Exception.Create('short header');
  if (hdr[0] <> $1F) or (hdr[1] <> $8B) or (hdr[2] <> 8) then
    raise Exception.Create('invalid header');
  // set flags
  flg := 0;
  if SetFHCRC then flg := flg or $02;
  if SetFEXTRA then flg := flg or $04;
  if SetFNAME then flg := flg or $08;
  if SetFCOMMENT then flg := flg or $10;
  hdr[3] := flg;

  // start writing new header
  OutStream.WriteBuffer(hdr, SizeOf(hdr));
  // compute header crc32 seed
  hdr_crc := DWord($FFFFFFFF);
  hdr_crc := crc32_update(hdr_crc, hdr, SizeOf(hdr));

  // FEXTRA: write XLEN + subfield 'Ap' with LEN=0 (total 4 bytes)
  if (flg and $04) <> 0 then begin
    xlen[0] := 4; xlen[1] := 0; // 0x0004 LE
    OutStream.WriteBuffer(xlen, 2);
    hdr_crc := crc32_update(hdr_crc, xlen, 2);
    // SI1, SI2, LEN(2)=0
    extra[0] := Ord('A'); extra[1] := Ord('p'); extra[2] := 0; extra[3] := 0;
    OutStream.WriteBuffer(extra, 4);
    hdr_crc := crc32_update(hdr_crc, extra, 4);
  end;

  // FNAME: zero-terminated
  if (flg and $08) <> 0 then begin
    name := 'abc.txt';
    if Length(name) > 0 then OutStream.WriteBuffer(name[1], Length(name));
    hdr_crc := crc32_update(hdr_crc, name[1], Length(name));
    b := 0; OutStream.WriteBuffer(b, 1); hdr_crc := crc32_update(hdr_crc, b, 1);
  end;

  // FCOMMENT: zero-terminated
  if (flg and $10) <> 0 then begin
    cmt := 'cmt';
    if Length(cmt) > 0 then OutStream.WriteBuffer(cmt[1], Length(cmt));
    hdr_crc := crc32_update(hdr_crc, cmt[1], Length(cmt));
    b := 0; OutStream.WriteBuffer(b, 1); hdr_crc := crc32_update(hdr_crc, b, 1);
  end;

  // FHCRC: write CRC16 of header (NOT of crc32 value, per implementation)
  if (flg and $02) <> 0 then begin
    b := 0; // placeholder type
    // Compute 16-bit value = low 16 bits of NOT(hdr_crc)
    crc16_le[0] := Byte((not hdr_crc) and $FF);
    crc16_le[1] := Byte(((not hdr_crc) shr 8) and $FF);
    OutStream.WriteBuffer(crc16_le, 2);
  end;

  // append original body+trailer (starting at offset 10 from original)
  // assumption: Orig is TMemoryStream compatible
  if Orig is TMemoryStream then begin
    OutStream.CopyFrom(Orig, (Orig as TMemoryStream).Size - 10);
  end else begin
    // fallback: read rest
    OutStream.CopyFrom(Orig, MaxInt);
  end;
end;

procedure TTestCase_GZipHeaderFlags.Test_GZip_HeaderFlags_All_Supported;
var raw, gz, gz2: TMemoryStream; W: IArchiveWriter; R: IArchiveReader; E: IArchiveEntry; Opt: TArchiveOptions; outMs: TMemoryStream;
begin
  raw := TMemoryStream.Create; gz := TMemoryStream.Create; gz2 := TMemoryStream.Create; outMs := TMemoryStream.Create;
  try
    // build a simple tar.gz via writer
    Opt.Format := afTar; Opt.Compression := caGZip; Opt.CompressionLevel := 6; Opt.Deterministic := True;
    Opt.StoreUnixPermissions := False; Opt.StoreTimestampsUtc := True; Opt.FollowSymlinks := False;
    W := CreateArchiveWriter(gz, Opt);
    W.AddDirectory('d/');
    raw.Size := 3; Move(PAnsiChar(AnsiString('hey'))^, raw.Memory^, 3);
    W.AddStream('d/a.txt', raw, Now);
    W.Finish;

    gz.Position := 0;
    // build a new gzip with flags set and header CRC present
    BuildGZipHeaderWithFlags(gz, gz2, True, True, True, True);

    // decode and verify
    gz2.Position := 0;
    R := CreateArchiveReader(gz2, afTar, caGZip);
    AssertTrue(R.Next(E)); AssertTrue(E.IsDirectory);
    AssertTrue(R.Next(E)); AssertEquals('d/a.txt', E.Name);
    outMs.Size := 0; outMs.Position := 0; R.ExtractCurrentToStream(outMs);
    AssertEquals(3, outMs.Size);
    AssertFalse(R.Next(E));
  finally raw.Free; gz.Free; gz2.Free; outMs.Free; end;
end;

procedure TTestCase_GZipHeaderFlags.Test_GZip_Header_FHCRC_Mismatch_Rejected;
var raw, gz, gz2: TMemoryStream; W: IArchiveWriter; R: IArchiveReader; E: IArchiveEntry; Opt: TArchiveOptions; b: Byte;
begin
  raw := TMemoryStream.Create; gz := TMemoryStream.Create; gz2 := TMemoryStream.Create;
  try
    Opt.Format := afTar; Opt.Compression := caGZip; Opt.CompressionLevel := 6; Opt.Deterministic := True;
    Opt.StoreUnixPermissions := False; Opt.StoreTimestampsUtc := True; Opt.FollowSymlinks := False;
    W := CreateArchiveWriter(gz, Opt);
    W.AddDirectory('d/');
    raw.Size := 2; Move(PAnsiChar(AnsiString('ok'))^, raw.Memory^, 2);
    W.AddStream('d/b.txt', raw, Now);
    W.Finish;

    gz.Position := 0;
    // build header with FHCRC
    BuildGZipHeaderWithFlags(gz, gz2, True, False, False, False);
    // flip one bit in FHCRC
    gz2.Position := 10; // start after fixed header
    // Depending on flags added, FHCRC is immediately here (no extra/name/comment)
    b := PByte(gz2.Memory + gz2.Position)^;
    PByte(gz2.Memory + gz2.Position)^ := b xor $01;

    // decoding should fail at header parsing
    gz2.Position := 0;
    try
      R := CreateArchiveReader(gz2, afTar, caGZip);
      Fail('expected header crc mismatch');
    except on Ex: Exception do AssertTrue(Pos('header crc mismatch', LowerCase(Ex.Message)) > 0); end;
  finally raw.Free; gz.Free; gz2.Free; end;
end;

initialization
  RegisterTest(TTestCase_GZipHeaderFlags);

end.
