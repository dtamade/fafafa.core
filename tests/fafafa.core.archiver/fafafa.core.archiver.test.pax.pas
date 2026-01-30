unit fafafa.core.archiver.test.pax;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.archiver, fafafa.core.archiver.interfaces;

type
  TTestCase_TarPAX = class(TTestCase)
  published
    procedure Test_Tar_PAX_LongPath_WriteRead;
    procedure Test_Tar_PathTraversal_Rejected_OnRead;
  end;

implementation

procedure WriteBytes(const S: string; Dest: TStream);
var a: RawByteString;
begin
  a := UTF8Encode(S);
  if Length(a) > 0 then Dest.WriteBuffer(a[1], Length(a));
end;

function MakeLongPath: string;
var i: Integer;
begin
  Result := '';
  for i := 1 to 10 do begin
    Result := Result + 'seg' + IntToStr(i) + '/';
  end;
  Result := Result + 'file.txt';
end;

procedure TTestCase_TarPAX.Test_Tar_PAX_LongPath_WriteRead;
var ms, msOut: TMemoryStream; W: IArchiveWriter; R: IArchiveReader; E: IArchiveEntry;
    Opt: TArchiveOptions; src: TMemoryStream; dataOut: TBytes; longPath: string;
begin
  longPath := MakeLongPath; // >100 chars
  ms := TMemoryStream.Create;
  msOut := TMemoryStream.Create;
  try
    Opt.Format := afTar; Opt.Compression := caNone; Opt.CompressionLevel := 0;
    Opt.Deterministic := True; Opt.StoreUnixPermissions := False; Opt.StoreTimestampsUtc := True; Opt.FollowSymlinks := False;
    W := CreateArchiveWriter(ms, Opt);

    src := TMemoryStream.Create;
    try
      WriteBytes('pax-long', src); src.Position := 0;
      W.AddStream(longPath, src, Now);
    finally
      src.Free;
    end;
    W.Finish;

    // read back
    ms.Position := 0;
    R := CreateArchiveReader(ms, afTar);
    AssertTrue(R.Next(E));
    AssertFalse(E.IsDirectory);
    AssertEquals(longPath, E.Name);
    msOut.Size := 0; msOut.Position := 0;
    R.ExtractCurrentToStream(msOut);
    SetLength(dataOut, msOut.Size); msOut.Position := 0;
    if Length(dataOut) > 0 then msOut.ReadBuffer(dataOut[0], Length(dataOut));
    AssertEquals('pax-long', TEncoding.UTF8.GetString(dataOut));
    AssertFalse(R.Next(E));
  finally
    msOut.Free; ms.Free;
  end;
end;

procedure TTestCase_TarPAX.Test_Tar_PathTraversal_Rejected_OnRead;
var ms: TMemoryStream; W: IArchiveWriter; R: IArchiveReader; E: IArchiveEntry;
    Opt: TArchiveOptions; src: TMemoryStream; badPath: string;
begin
  badPath := '../evil.txt';
  ms := TMemoryStream.Create;
  try
    Opt.Format := afTar; Opt.Compression := caNone; Opt.CompressionLevel := 0;
    Opt.Deterministic := True; Opt.StoreUnixPermissions := False; Opt.StoreTimestampsUtc := True; Opt.FollowSymlinks := False;
    Opt.EnforcePathSafety := False; // 本用例希望在 Read 阶段拒绝，而非写入阶段
    W := CreateArchiveWriter(ms, Opt);

    src := TMemoryStream.Create;
    try
      src.Size := 1; src.Position := 0;
      W.AddStream(badPath, src, Now);
    finally
      src.Free;
    end;
    W.Finish;

    ms.Position := 0;
    try
      R := CreateArchiveReader(ms, afTar);
      // 读取第一条即应因路径不安全抛错
      AssertTrue(R.Next(E));
      Fail('Expected unsafe path rejection');
    except
      on E: EArchiverError do ;
    end;
  finally
    ms.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_TarPAX);

end.

