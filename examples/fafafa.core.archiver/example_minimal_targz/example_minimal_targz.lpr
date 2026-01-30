{$CODEPAGE UTF8}
program example_minimal_targz;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  fafafa.core.archiver, fafafa.core.archiver.interfaces;

procedure WriteBytes(const S: string; Dest: TStream);
var b: TBytes;
begin
  b := TEncoding.UTF8.GetBytes(S);
  if Length(b) > 0 then Dest.WriteBuffer(b[0], Length(b));
end;

var
  ms, msOut: TMemoryStream;
  W: IArchiveWriter;
  R: IArchiveReader;
  E: IArchiveEntry;
  Opt: TArchiveOptions;
  src: TMemoryStream;
  dataOut: TBytes;
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
      WriteBytes('hello targz', src);
      src.Position := 0;
      W.AddStream('d/x.txt', src, Now);
    finally
      src.Free;
    end;
    W.Finish;

    ms.Position := 0;
    R := CreateArchiveReader(ms, afTar, caGZip);
    while R.Next(E) do begin
      Writeln('Entry: ', E.Name, ' size=', E.Size, ' dir=', E.IsDirectory);
      if not E.IsDirectory then begin
        msOut.Size := 0; msOut.Position := 0;
        R.ExtractCurrentToStream(msOut);
        SetLength(dataOut, msOut.Size);
        msOut.Position := 0;
        if Length(dataOut) > 0 then msOut.ReadBuffer(dataOut[0], Length(dataOut));
        Writeln('  Content UTF8: ', TEncoding.UTF8.GetString(dataOut));
      end;
    end;
  finally
    msOut.Free; ms.Free;
  end;
end.

