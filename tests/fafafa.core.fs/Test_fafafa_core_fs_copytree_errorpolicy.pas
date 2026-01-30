{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_copytree_errorpolicy;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs.tree, fafafa.core.fs.directory, fafafa.core.fs.options, fafafa.core.fs.errors;

type
  TTestCase_CopyTree_ErrorPolicy = class(TTestCase)
  published
    procedure Test_ErrorPolicy_Abort;
    procedure Test_ErrorPolicy_Continue;
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

// 制造失败：目标路径被权限锁定/只读。这里用简单方式：先创建同名目录，复制文件到目录路径会失败。
procedure MakeConflictPath(const P: string);
begin
  ForceDirectories(P);
end;

procedure TTestCase_CopyTree_ErrorPolicy.Test_ErrorPolicy_Abort;
var
  Src, Dst: string;
  Opts: TFsCopyTreeOptions;
  Res: TFsTreeResult;
  RaisedErr: Boolean;
begin
  Src := 'ep_abort_src_' + IntToStr(GetTickCount64);
  Dst := 'ep_abort_dst_' + IntToStr(GetTickCount64);
  EnsureClean(Src); EnsureClean(Dst);
  CreateDirectory(Src, True);
  CreateDirectory(Dst, True);
  // 准备：src 下有 sub/file，dst 下制造冲突路径 sub/file（目录名=file 名）
  CreateText(IncludeTrailingPathDelimiter(Src) + 'sub' + PathDelim + 'file', 'x');
  MakeConflictPath(IncludeTrailingPathDelimiter(Dst) + 'sub' + PathDelim + 'file');

  Opts := Default(TFsCopyTreeOptions);
  Opts.Overwrite := True;
  Opts.FollowSymlinks := False;
  Opts.ErrorPolicy := epAbort; // 默认

  RaisedErr := False;
  try
    FsCopyTreeEx(Src, Dst, Opts, Res);
  except
    on E: EFsError do RaisedErr := True;
  end;
  AssertTrue('Abort policy should raise', RaisedErr);

  EnsureClean(Src); EnsureClean(Dst);
end;

procedure TTestCase_CopyTree_ErrorPolicy.Test_ErrorPolicy_Continue;
var
  Src, Dst: string;
  Opts: TFsCopyTreeOptions;
  Res: TFsTreeResult;
begin
  Src := 'ep_continue_src_' + IntToStr(GetTickCount64);
  Dst := 'ep_continue_dst_' + IntToStr(GetTickCount64);
  EnsureClean(Src); EnsureClean(Dst);
  CreateDirectory(Src, True);
  CreateDirectory(Dst, True);
  // 冲突同上
  CreateText(IncludeTrailingPathDelimiter(Src) + 'sub' + PathDelim + 'file', 'x');
  MakeConflictPath(IncludeTrailingPathDelimiter(Dst) + 'sub' + PathDelim + 'file');

  Opts := Default(TFsCopyTreeOptions);
  Opts.Overwrite := True;
  Opts.FollowSymlinks := False;
  Opts.ErrorPolicy := epContinue;

  FsCopyTreeEx(Src, Dst, Opts, Res);

  // 期待：不抛异常，Errors 增加；其他不冲突的文件（若有）应被复制（本例只有冲突一个文件）
  AssertTrue('Errors should be >=1', Res.Errors >= 1);

  EnsureClean(Src); EnsureClean(Dst);
end;

initialization
  RegisterTest(TTestCase_CopyTree_ErrorPolicy);
end.

