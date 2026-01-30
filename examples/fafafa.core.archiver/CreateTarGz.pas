program CreateTarGz;
{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.archiver, fafafa.core.archiver.interfaces;

procedure WriteTextToStream(const S: string; const Dest: TStream);
var bytes: TBytes;
begin
  bytes := TEncoding.UTF8.GetBytes(S);
  if Length(bytes) > 0 then Dest.WriteBuffer(bytes[0], Length(bytes));
end;

var
  OutFile: string;
  FS: TFileStream = nil;
  W: IArchiveWriter;
  Opt: TArchiveOptions;
  Ms: TMemoryStream = nil;
begin
  if ParamCount >= 1 then OutFile := ParamStr(1) else OutFile := 'example.tar.gz';

  // 直接输出到文件（也可用内存流）
  FS := TFileStream.Create(OutFile, fmCreate or fmShareDenyWrite);
  try
    FillChar(Opt, SizeOf(Opt), 0);
    Opt.Format := afTar;
    Opt.Compression := caGZip;
    Opt.CompressionLevel := 6;
    Opt.Deterministic := True;
    Opt.StoreUnixPermissions := False;
    Opt.StoreTimestampsUtc := True;
    Opt.FollowSymlinks := False;

    W := CreateArchiveWriter(FS, Opt);

    // 目录先入档
    W.AddDirectory('d/');

    // 写一个小文本文件
    Ms := TMemoryStream.Create;
    try
      WriteTextToStream('hello from archiver', Ms);
      Ms.Position := 0;
      W.AddStream('d/hello.txt', Ms, Now);
    finally
      Ms.Free;
    end;

    // 完成（Finish 会通过门面适配器刷新并释放压缩流）
    W.Finish;
  finally
    FS.Free;
  end;

  WriteLn('Created: ', OutFile);
end.

