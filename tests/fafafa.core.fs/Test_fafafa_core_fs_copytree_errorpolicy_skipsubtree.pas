{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_copytree_errorpolicy_skipsubtree;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs.tree, fafafa.core.fs.fileio, fafafa.core.fs.directory, fafafa.core.fs.options;

type
  TTestCase_CopyTree_ErrorPolicy_SkipSubtree = class(TTestCase)
  published
    procedure Test_ErrorPolicy_SkipSubtree;
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

// 构造：在 dst 下制造某子树冲突，使得该子树中的文件复制失败
procedure MakeConflictSubtree(const Root, Sub: string);
begin
  ForceDirectories(IncludeTrailingPathDelimiter(Root) + Sub + PathDelim + 'file'); // 目录与文件同名冲突
end;

procedure TTestCase_CopyTree_ErrorPolicy_SkipSubtree.Test_ErrorPolicy_SkipSubtree;
var
  Src, Dst: string;
  Opts: TFsCopyTreeOptions;
  Res: TFsTreeResult;
begin
  Src := 'ep_skipsub_src_' + IntToStr(GetTickCount64);
  Dst := 'ep_skipsub_dst_' + IntToStr(GetTickCount64);
  EnsureClean(Src); EnsureClean(Dst);
  CreateDirectory(Src, True);
  CreateDirectory(Dst, True);

  // 构造 src 结构：okdir/file_ok 与 badsub/file 将被复制；在 dst 构造冲突：badsub/file 成为目录
  CreateText(IncludeTrailingPathDelimiter(Src) + 'okdir' + PathDelim + 'file_ok', 'ok');
  CreateText(IncludeTrailingPathDelimiter(Src) + 'badsub' + PathDelim + 'file', 'bad');
  MakeConflictSubtree(Dst, 'badsub');

  Opts := Default(TFsCopyTreeOptions);
  Opts.Overwrite := True;
  Opts.FollowSymlinks := False;
  Opts.ErrorPolicy := epSkipSubtree;

  FsCopyTreeEx(Src, Dst, Opts, Res);

  // 预期：okdir/file_ok 被复制；badsub 子树因冲突被跳过
  AssertTrue('okdir/file_ok copied', FileExists(IncludeTrailingPathDelimiter(Dst) + 'okdir' + PathDelim + 'file_ok'));
  AssertFalse('badsub/file should not be copied', FileExists(IncludeTrailingPathDelimiter(Dst) + 'badsub' + PathDelim + 'file'));
  AssertTrue('errors counted', Res.Errors >= 1);

  EnsureClean(Src); EnsureClean(Dst);
end;

initialization
  RegisterTest(TTestCase_CopyTree_ErrorPolicy_SkipSubtree);
end.

