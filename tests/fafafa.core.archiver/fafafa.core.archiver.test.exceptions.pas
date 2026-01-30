unit fafafa.core.archiver.test.exceptions;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.archiver, fafafa.core.archiver.interfaces;

type
  TTestCase_TarExceptions = class(TTestCase)
  published
    procedure Test_Tar_Reader_TruncatedHeader;
    procedure Test_Tar_Reader_TruncatedPayload;
  end;

implementation

procedure TTestCase_TarExceptions.Test_Tar_Reader_TruncatedHeader;
var ms: TMemoryStream; R: IArchiveReader; E: IArchiveEntry;
begin
  ms := TMemoryStream.Create;
  try
    // 少于 512 字节的内容 → 读取头时即报错
    ms.Size := 100;
    ms.Position := 0;
    try
      R := CreateArchiveReader(ms, afTar);
      // 惰性读取：在 Next 时触发异常
      try
        AssertTrue(R.Next(E));
        Fail('Expected exception not raised');
      except on E: EArchiverError do ; end;
    except
      on E: EArchiverError do ;
    end;
  finally
    ms.Free;
  end;
end;

procedure TTestCase_TarExceptions.Test_Tar_Reader_TruncatedPayload;
var
  ms: TMemoryStream;
  W: IArchiveWriter;
  R: IArchiveReader;
  E: IArchiveEntry;
  tmp: TMemoryStream;
  Opt: TArchiveOptions;
  src: TMemoryStream;
  out: TMemoryStream;
  fileSize, pad, cut: Int64;
begin
  ms := TMemoryStream.Create;
  tmp := TMemoryStream.Create;
  try
    // 写入一个完整 tar，再截断其中内容
    Opt.Format := afTar; Opt.Compression := caNone; Opt.CompressionLevel := 0; Opt.Deterministic := True;
    Opt.StoreUnixPermissions := False; Opt.StoreTimestampsUtc := True; Opt.FollowSymlinks := False;

    W := CreateArchiveWriter(tmp, Opt);
    W.AddDirectory('d/');
    src := TMemoryStream.Create;
    try
      src.Size := 1000; // 1KB 不整除 512，尾部 padding 更短
      W.AddStream('d/x.bin', src, Now);
    finally
      src.Free;
    end;
    W.Finish;

    // 截断 payload：仅保留“目录头+文件头+文件数据前100字节”，确保 Extract 时短读
    // 布局简化：dir(512) + fileHdr(512) + payload(1000) + pad(24) + EOF(1024)
    fileSize := 1000; // 上文写入的 src.Size
    pad := (512 - (fileSize mod 512)) mod 512; // =24（仅用于说明）
    cut := 0; // 不从末尾计算，直接按需复制前缀
    tmp.Position := 0;
    ms.CopyFrom(tmp, 512 + 512 + 1); // 仅复制到 payload 第1字节，确保短读
    AssertEquals(1025, ms.Size);
    ms.Position := 0;

    // 从第二条目开始或其后续 Extract 均可能在任何一步短读
    try
      R := CreateArchiveReader(ms, afTar);
      AssertTrue(R.Next(E)); // 目录（若此处短读亦应被捕获）

      AssertTrue(R.Next(E)); // 文件（可能在此短读：header）
      AssertEquals(1000, E.Size);

      out := TMemoryStream.Create;
      try
        R.ExtractCurrentToStream(out); // 也可能在此短读：payload
        Fail('Expected short read error');
      finally
        out.Free;
      end;
    except
      on Ex: Exception do begin
        AssertTrue(Pos('short read', Ex.Message) > 0);
      end;
    end;
  finally
    tmp.Free; ms.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_TarExceptions);

end.

