unit fafafa.core.archiver.test.writer.safety;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.archiver, fafafa.core.archiver.interfaces;

type
  TTestCase_TarWriterSafety = class(TTestCase)
  published
    procedure Test_TarWriter_AddDirectory_UnsafePath_Rejected;
    procedure Test_TarWriter_AddStream_UnsafePath_Rejected;
  end;

implementation

procedure TTestCase_TarWriterSafety.Test_TarWriter_AddDirectory_UnsafePath_Rejected;
var ms: TMemoryStream; W: IArchiveWriter; Opt: TArchiveOptions;
begin
  ms := TMemoryStream.Create;
  try
    Opt.Format := afTar; Opt.Compression := caNone; Opt.CompressionLevel := 0;
    Opt.Deterministic := True; Opt.StoreUnixPermissions := False; Opt.StoreTimestampsUtc := True; Opt.FollowSymlinks := False;
    Opt.EnforcePathSafety := True;
    W := CreateArchiveWriter(ms, Opt);
    try
      W.AddDirectory('/abs/');
      Fail('Expected writer unsafe path rejection');
    except on E: EArchiverError do ; end;
  finally ms.Free; end;
end;

procedure TTestCase_TarWriterSafety.Test_TarWriter_AddStream_UnsafePath_Rejected;
var ms, src: TMemoryStream; W: IArchiveWriter; Opt: TArchiveOptions;
begin
  ms := TMemoryStream.Create; src := TMemoryStream.Create;
  try
    Opt.Format := afTar; Opt.Compression := caNone; Opt.CompressionLevel := 0;
    Opt.Deterministic := True; Opt.StoreUnixPermissions := False; Opt.StoreTimestampsUtc := True; Opt.FollowSymlinks := False;
    Opt.EnforcePathSafety := True;
    W := CreateArchiveWriter(ms, Opt);
    src.Size := 1; src.Position := 0;
    try
      W.AddStream('../up.txt', src, Now);
      Fail('Expected writer unsafe path rejection');
    except on E: EArchiverError do ; end;
  finally src.Free; ms.Free; end;
end;

initialization
  RegisterTest(TTestCase_TarWriterSafety);

end.
