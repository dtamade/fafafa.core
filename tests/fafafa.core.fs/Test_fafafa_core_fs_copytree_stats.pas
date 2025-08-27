{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_copytree_stats;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs, fafafa.core.fs.highlevel;

type
  TTestCase_CopyTree_Stats = class(TTestCase)
  published
    procedure Test_CopyTree_Result_Stats;
  end;

implementation

procedure EnsureClean(const P: string);
begin
  try
    DeleteDirectory(P, True);
  except
  end;
end;

procedure CreateText(const P, S: string);
var F: TextFile;
begin
  ForceDirectories(ExtractFileDir(P));
  AssignFile(F, P);
  Rewrite(F);
  Write(F, S);
  Close(F);
end;

procedure CreateBin(const P: string; Count: Integer);
var FS: TFileStream; Buf: array of byte; i: Integer;
begin
  ForceDirectories(ExtractFileDir(P));
  FS := TFileStream.Create(P, fmCreate);
  try
    SetLength(Buf, Count);
    for i := 0 to Count - 1 do Buf[i] := i and $FF;
    if Count > 0 then FS.WriteBuffer(Buf[0], Count);
  finally
    FS.Free;
  end;
end;

procedure TTestCase_CopyTree_Stats.Test_CopyTree_Result_Stats;
var
  Src, Dst: string;
  Opts: TFsCopyTreeOptions;
  Res: TFsTreeResult;
  sizeSum: QWord;
begin
  Randomize;
  Src := 'copytree_stats_' + IntToStr(GetTickCount64);
  Dst := Src + '_dst';
  EnsureClean(Src); EnsureClean(Dst);
  CreateDirectory(Src, True);
  CreateText(IncludeTrailingPathDelimiter(Src) + 'a.txt', 'hello'); // 5 bytes
  CreateBin(IncludeTrailingPathDelimiter(Src) + 'sub' + PathDelim + 'b.bin', 10); // 10 bytes

  FillChar(Opts, SizeOf(Opts), 0);
  Opts.Overwrite := True;
  Opts.FollowSymlinks := False;

  FsCopyTreeEx(Src, Dst, Opts, Res);

  // 基本存在性验证
  AssertTrue('dest a.txt exists', FileExists(IncludeTrailingPathDelimiter(Dst) + 'a.txt'));
  AssertTrue('dest sub/b.bin exists', FileExists(IncludeTrailingPathDelimiter(Dst) + 'sub' + PathDelim + 'b.bin'));

  // 统计验证：文件数与总字节
  sizeSum := 5 + 10;
  AssertEquals('files copied = 2', 2, Res.FilesCopied);
  AssertTrue('bytes copied = 15', Res.BytesCopied = sizeSum);
  AssertEquals('errors = 0', QWord(0), Res.Errors);

  // 清理
  EnsureClean(Src); EnsureClean(Dst);
end;

initialization
  RegisterTest(TTestCase_CopyTree_Stats);
end.

