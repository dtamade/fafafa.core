{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_copytree_movetree_fallback;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs.tree, fafafa.core.fs.fileio, fafafa.core.fs.directory, fafafa.core.fs.options;

type
  TTestCase_MoveTree_Fallback = class(TTestCase)
  published
    procedure Test_MoveTree_RenameFail_FallbackCopyAndDelete;
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

function IsDifferentVolumePathAvailable(out P: string): Boolean;
// 简化：尝试使用系统临时目录作为不同卷（不保证一定跨卷，若未跨卷也应能通过逻辑）
begin
  P := GetTempDir(False);
  Result := P <> '';
end;

procedure TTestCase_MoveTree_Fallback.Test_MoveTree_RenameFail_FallbackCopyAndDelete;
var
  Src, Dst: string;
  Opts: TFsMoveTreeOptions;
  Res: TFsTreeResult;
  TempRoot: string;
begin
  Src := 'mt_src_' + IntToStr(GetTickCount64);
  EnsureClean(Src);
  CreateDirectory(Src, True);
  CreateText(IncludeTrailingPathDelimiter(Src) + 'x.txt', 'x');

  if IsDifferentVolumePathAvailable(TempRoot) then
    Dst := IncludeTrailingPathDelimiter(TempRoot) + 'mt_dst_' + IntToStr(GetTickCount64)
  else
    Dst := 'mt_dst_' + IntToStr(GetTickCount64);
  EnsureClean(Dst);

  Opts := Default(TFsMoveTreeOptions);
  Opts.Overwrite := True;
  Opts.FollowSymlinks := False;
  Opts.RootBehavior := rbMerge;
  // 尝试移动：若跨卷 rename 失败，应回退为复制+删除源
  FsMoveTreeEx(Src, Dst, Opts, Res);

  // 期望：最终 Dst 存在文件，Src 被删除
  AssertTrue('dst has x.txt', FileExists(IncludeTrailingPathDelimiter(Dst) + 'x.txt'));
  AssertFalse('src removed', DirectoryExists(Src));

  EnsureClean(Dst);
end;

initialization
  RegisterTest(TTestCase_MoveTree_Fallback);
end.

