{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_movetree_abort_safe;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs, fafafa.core.fs.tree, fafafa.core.fs.fileio, fafafa.core.fs.directory, fafafa.core.fs.options, fafafa.core.fs.errors;

type
  TTestCase_MoveTree_AbortSafe = class(TTestCase)
  published
    procedure Test_MoveTree_Abort_ShouldNotDeleteSourceOnFailure;
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

procedure MakeConflictSubtree(const Root, Sub: string);
begin
  ForceDirectories(IncludeTrailingPathDelimiter(Root) + Sub + PathDelim + 'file');
end;

procedure TTestCase_MoveTree_AbortSafe.Test_MoveTree_Abort_ShouldNotDeleteSourceOnFailure;
var
  Src, Dst: string;
  Opts: TFsMoveTreeOptions;
  RaisedErr: Boolean;
begin
  Src := 'mt_abort_src_' + IntToStr(GetTickCount64);
  Dst := 'mt_abort_dst_' + IntToStr(GetTickCount64);
  EnsureClean(Src); EnsureClean(Dst);
  CreateDirectory(Src, True);
  CreateDirectory(Dst, True);

  // src 有 okdir/file_ok 与 badsub/file
  CreateText(IncludeTrailingPathDelimiter(Src) + 'okdir' + PathDelim + 'file_ok', 'ok');
  CreateText(IncludeTrailingPathDelimiter(Src) + 'badsub' + PathDelim + 'file', 'bad');
  // 在 dst 构造冲突：badsub/file 变成目录，复制应失败
  MakeConflictSubtree(Dst, 'badsub');

  FillChar(Opts, SizeOf(Opts), 0);
  Opts.Overwrite := True;
  Opts.FollowSymlinks := False;
  Opts.RootBehavior := rbMerge;
  Opts.ErrorPolicy := epAbort;

  RaisedErr := False;
  try
    FsMoveTreeEx(Src, Dst, Opts);
  except
    on E: EFsError do RaisedErr := True;
  end;
  AssertTrue('Abort should raise error', RaisedErr);
  // 关键：源不应被删除
  AssertTrue('source should still exist', DirectoryExists(Src));

  EnsureClean(Src); EnsureClean(Dst);
end;

initialization
  RegisterTest(TTestCase_MoveTree_AbortSafe);
end.

