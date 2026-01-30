{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_copytree_rootbehavior;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs.tree, fafafa.core.fs.fileio, fafafa.core.fs.directory, fafafa.core.fs.options, fafafa.core.fs.errors;

type
  TTestCase_CopyTree_RootBehavior = class(TTestCase)
  published
    procedure Test_RootBehavior_Merge;
    procedure Test_RootBehavior_Error;
    procedure Test_RootBehavior_Replace;
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

procedure TTestCase_CopyTree_RootBehavior.Test_RootBehavior_Merge;
var
  Src, Dst: string;
  Opts: TFsCopyTreeOptions;
begin
  Src := 'rb_merge_src_' + IntToStr(GetTickCount64);
  Dst := 'rb_merge_dst_' + IntToStr(GetTickCount64);
  EnsureClean(Src); EnsureClean(Dst);
  CreateDirectory(Src, True);
  CreateDirectory(Dst, True);
  CreateText(IncludeTrailingPathDelimiter(Src) + 'a.txt', 'src');
  CreateText(IncludeTrailingPathDelimiter(Dst) + 'old.txt', 'old');

  Opts := Default(TFsCopyTreeOptions);
  Opts.Overwrite := True;
  Opts.FollowSymlinks := False;
  Opts.RootBehavior := rbMerge;

  FsCopyTreeEx(Src, Dst, Opts);

  AssertTrue('old remains', FileExists(IncludeTrailingPathDelimiter(Dst) + 'old.txt'));
  AssertTrue('a.txt copied', FileExists(IncludeTrailingPathDelimiter(Dst) + 'a.txt'));

  EnsureClean(Src); EnsureClean(Dst);
end;

procedure TTestCase_CopyTree_RootBehavior.Test_RootBehavior_Error;
var
  Src, Dst: string;
  Opts: TFsCopyTreeOptions;
  RaisedErr: Boolean;
begin
  Src := 'rb_err_src_' + IntToStr(GetTickCount64);
  Dst := 'rb_err_dst_' + IntToStr(GetTickCount64);
  EnsureClean(Src); EnsureClean(Dst);
  CreateDirectory(Src, True);
  CreateDirectory(Dst, True);
  CreateText(IncludeTrailingPathDelimiter(Src) + 'a.txt', 'src');

  Opts := Default(TFsCopyTreeOptions);
  Opts.Overwrite := True;
  Opts.FollowSymlinks := False;
  Opts.RootBehavior := rbError;

  RaisedErr := False;
  try
    FsCopyTreeEx(Src, Dst, Opts);
  except
    on E: EFsError do RaisedErr := True;
  end;
  AssertTrue('should raise when dst root exists', RaisedErr);

  EnsureClean(Src); EnsureClean(Dst);
end;

procedure TTestCase_CopyTree_RootBehavior.Test_RootBehavior_Replace;
var
  Src, Dst: string;
  Opts: TFsCopyTreeOptions;
begin
  Src := 'rb_replace_src_' + IntToStr(GetTickCount64);
  Dst := 'rb_replace_dst_' + IntToStr(GetTickCount64);
  EnsureClean(Src); EnsureClean(Dst);
  CreateDirectory(Src, True);
  CreateDirectory(Dst, True);
  CreateText(IncludeTrailingPathDelimiter(Src) + 'a.txt', 'src');
  CreateText(IncludeTrailingPathDelimiter(Dst) + 'old.txt', 'old');

  Opts := Default(TFsCopyTreeOptions);
  Opts.Overwrite := True;
  Opts.FollowSymlinks := False;
  Opts.RootBehavior := rbReplace;

  FsCopyTreeEx(Src, Dst, Opts);

  AssertFalse('old should be gone', FileExists(IncludeTrailingPathDelimiter(Dst) + 'old.txt'));
  AssertTrue('a.txt copied', FileExists(IncludeTrailingPathDelimiter(Dst) + 'a.txt'));

  EnsureClean(Src); EnsureClean(Dst);
end;

initialization
  RegisterTest(TTestCase_CopyTree_RootBehavior);
end.

