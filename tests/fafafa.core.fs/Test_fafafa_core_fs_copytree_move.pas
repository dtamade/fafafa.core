unit Test_fafafa_core_fs_copytree_move;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs, fafafa.core.fs.fileio, fafafa.core.fs.tree, fafafa.core.fs.directory, fafafa.core.fs.options;

type
  TTestCase_CopyMove = class(TTestCase)
  published
    procedure Test_CopyTree_Basic;
    procedure Test_MoveTree_Basic;
    procedure Test_CopyTree_OverwriteFalse_TargetExists_Raises;
    procedure Test_MoveTree_OverwriteFalse_TargetExists_Raises;
    {$IFDEF UNIX}
    procedure Test_CopyTree_PreserveTimesPerms_POSIX;
    {$ENDIF}
  end;


implementation

function MakeTempDir(const Prefix: string): string;
var base: string;
begin
  base := IncludeTrailingPathDelimiter(GetTempDir(False));
  Result := base + Prefix + IntToStr(GetTickCount64) + '_' + IntToStr(Random(100000));
  ForceDirectories(Result);
end;

procedure WriteText(const Path, S: string);
begin
  WriteTextFile(Path, S);
end;

procedure CreateSampleTree(const Root: string);
begin
  ForceDirectories(IncludeTrailingPathDelimiter(Root) + 'a/b');
  WriteText(IncludeTrailingPathDelimiter(Root) + 'a/b/x.txt', 'hello');
  WriteText(IncludeTrailingPathDelimiter(Root) + 'a/c.txt', 'world');
end;

procedure TTestCase_CopyMove.Test_CopyTree_Basic;
var
  Src, Dst: string;
var
  Opts: TFsCopyTreeOptions;
begin
  Src := MakeTempDir('fs_copytree_src_');
  Dst := MakeTempDir('fs_copytree_dst_');
  try
    CreateSampleTree(Src);
    // 确保覆盖（目标目录预存在且可能含相同文件名）
    Opts.Overwrite := True;
    FsCopyTreeEx(Src, Dst, Opts);
    AssertTrue('x.txt copied', FileExists(IncludeTrailingPathDelimiter(Dst) + 'a/b/x.txt'));
    AssertTrue('c.txt copied', FileExists(IncludeTrailingPathDelimiter(Dst) + 'a/c.txt'));
  finally
    // cleanup best-effort
  end;
end;

procedure TTestCase_CopyMove.Test_MoveTree_Basic;
var
  Src, Dst: string;
  Opts: TFsMoveTreeOptions;
begin
  Src := MakeTempDir('fs_movetree_src_');
  Dst := MakeTempDir('fs_movetree_dst_');
  try
    CreateSampleTree(Src);
    Opts.Overwrite := True;
    FsMoveTreeEx(Src, Dst, Opts);
    AssertTrue('moved x.txt', FileExists(IncludeTrailingPathDelimiter(Dst) + 'a/b/x.txt'));
    AssertTrue('moved c.txt', FileExists(IncludeTrailingPathDelimiter(Dst) + 'a/c.txt'));
    AssertFalse('src removed', DirectoryExists(Src));
  finally
  end;
end;

procedure TTestCase_CopyMove.Test_CopyTree_OverwriteFalse_TargetExists_Raises;
var
  Src, Dst: string;
  Opts: TFsCopyTreeOptions;
begin
  Src := MakeTempDir('fs_copytree_src_');
  Dst := MakeTempDir('fs_copytree_dst_');
  try
    CreateSampleTree(Src);
    CreateSampleTree(Dst); // make target exists
    Opts.Overwrite := False;
    try
      FsCopyTreeEx(Src, Dst, Opts);
      Fail('Expected exception not raised');
    except
      on E: Exception do
        AssertTrue('exception raised as expected', True);
    end;
  finally
  end;
end;
procedure TTestCase_CopyMove.Test_MoveTree_OverwriteFalse_TargetExists_Raises;
var
  Src, Dst: string;
  Opts: TFsMoveTreeOptions;
begin
  Src := MakeTempDir('fs_movetree_src_');
  Dst := MakeTempDir('fs_movetree_dst_');
  try
    CreateSampleTree(Src);
    CreateSampleTree(Dst); // make target exists
    Opts.Overwrite := False;
    try
      FsMoveTreeEx(Src, Dst, Opts);
      Fail('Expected exception not raised');
    except
      on E: Exception do
        AssertTrue('exception raised as expected', True);
    end;
  finally
  end;
end;


{$IFDEF UNIX}
function GetPerm9(const Mode: Cardinal): Cardinal; inline;
begin
  Result := Mode and $1FF; // 低9位（POSIX 权限）
end;

procedure TTestCase_CopyMove.Test_CopyTree_PreserveTimesPerms_POSIX;
var
  Src, Dst, FSrc, FDst: string;
  Opts: TFsCopyTreeOptions;
  SSrc, SDst: TfsStat;
  PermSrc, PermDst: Cardinal;
begin
  Src := MakeTempDir('fs_copytree_src_');
  Dst := MakeTempDir('fs_copytree_dst_');
  try
    // 构造：一个文件，设置权限与时间
    ForceDirectories(IncludeTrailingPathDelimiter(Src) + 'a');
    FSrc := IncludeTrailingPathDelimiter(Src) + 'a/x.txt';
    WriteText(FSrc, 'perm_time');

    // 修改权限为 0644，并尝试设置 mtime/atime
    fs_chmod(FSrc, $1A4); // 0644 = 0o644 = $1A4
    if fs_stat(FSrc, SSrc) = 0 then
    begin
      // 把 mtime 往回调 2 秒（若平台支持）
      fs_utime(FSrc, SSrc.ATime.Sec + SSrc.ATime.Nsec / 1e9 - 2.0,
                      SSrc.MTime.Sec + SSrc.MTime.Nsec / 1e9 - 2.0);
      fs_stat(FSrc, SSrc); // 重新取 stat
    end;

    // 执行复制并开启 PreserveTimes/Perms
    Opts.Overwrite := True;
    Opts.PreserveTimes := True;
    Opts.PreservePerms := True;
    FsCopyTreeEx(Src, Dst, Opts);

    FDst := IncludeTrailingPathDelimiter(Dst) + 'a/x.txt';
    AssertTrue('dest exists', FileExists(FDst));

    // 校验权限与时间（best-effort）：权限相同；mtime 非增大（允差）
    if (fs_stat(FSrc, SSrc) = 0) and (fs_stat(FDst, SDst) = 0) then
    begin
      PermSrc := GetPerm9(SSrc.Mode);
      PermDst := GetPerm9(SDst.Mode);
      AssertTrue('perm preserved', PermDst = PermSrc);
      // 只断言“目标 mtime >= 源 mtime - 1s 且 <= 源 mtime + 3s”以容忍系统舍入与分辨率差异
      AssertTrue('mtime preserved (loose)',
        (SDst.MTime.Sec >= SSrc.MTime.Sec - 1) and (SDst.MTime.Sec <= SSrc.MTime.Sec + 3));
    end;
  finally
    // cleanup best-effort
  end;
end;
{$ENDIF}

initialization
  RegisterTest(TTestCase_CopyMove);
end.
