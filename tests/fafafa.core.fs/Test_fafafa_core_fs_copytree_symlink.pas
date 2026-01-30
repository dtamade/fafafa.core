{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_copytree_symlink;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs, fafafa.core.fs.tree, fafafa.core.fs.directory, fafafa.core.fs.options;

type
  TTestCase_CopyTree_Symlink = class(TTestCase)
  published
    procedure Test_CopyTree_Symlink_FollowTrue_CopiesTarget;
    procedure Test_CopyTree_Symlink_FollowFalse_SkipsLink;
  end;

implementation

function Enabled: Boolean;
begin
  {$IFDEF WINDOWS}
  Result := GetEnvironmentVariable('FAFAFA_TEST_SYMLINK') = '1';
  {$ELSE}
  Result := GetEnvironmentVariable('FAFAFA_TEST_SYMLINK') <> '0';
  {$ENDIF}
end;

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
  AssignFile(F, P);
  ForceDirectories(ExtractFileDir(P));
  Rewrite(F);
  Write(F, S);
  Close(F);
end;

procedure TTestCase_CopyTree_Symlink.Test_CopyTree_Symlink_FollowTrue_CopiesTarget;
var
  R, A, B, LinkAtoB, Dst: string;
  Opts: TFsCopyTreeOptions;
begin
  if not Enabled then Exit;
  R := 'copytree_symlink_' + IntToStr(GetTickCount64);
  A := IncludeTrailingPathDelimiter(R) + 'A';
  B := IncludeTrailingPathDelimiter(R) + 'B';
  Dst := R + '_dst';
  EnsureClean(R); EnsureClean(Dst);
  CreateDirectory(R, True);
  CreateDirectory(A, True);
  CreateDirectory(B, True);
  CreateText(IncludeTrailingPathDelimiter(B) + 'file.txt', 'hello');

  LinkAtoB := IncludeTrailingPathDelimiter(A) + 'to_B';
  if fs_symlink('../B', LinkAtoB) <> 0 then begin EnsureClean(R); Exit; end;

  Opts := FsDefaultCopyTreeOptions;
  Opts.Overwrite := True;
  Opts.PreserveTimes := False;
  Opts.PreservePerms := False;
  Opts.FollowSymlinks := True;
  Opts.CopySymlinksAsLinks := False;
  FsCopyTreeEx(R, Dst, Opts);

  // 期待：跟随符号链接，复制到 A/to_B 下的目标内容存在
  AssertTrue(FileExists(IncludeTrailingPathDelimiter(Dst) + 'A/to_B/file.txt'));

  EnsureClean(R);
  EnsureClean(Dst);
end;


procedure TTestCase_CopyTree_Symlink.Test_CopyTree_Symlink_FollowFalse_SkipsLink;
var
  R, A, B, LinkAtoB, Dst: string;
  Opts: TFsCopyTreeOptions;
begin
  if not Enabled then Exit;
  R := 'copytree_symlink_' + IntToStr(GetTickCount64);
  A := IncludeTrailingPathDelimiter(R) + 'A';
  B := IncludeTrailingPathDelimiter(R) + 'B';
  Dst := R + '_dst';
  EnsureClean(R); EnsureClean(Dst);
  CreateDirectory(R, True);
  CreateDirectory(A, True);
  CreateDirectory(B, True);
  CreateText(IncludeTrailingPathDelimiter(B) + 'file.txt', 'hello');

  LinkAtoB := IncludeTrailingPathDelimiter(A) + 'to_B';
  if fs_symlink('../B', LinkAtoB) <> 0 then begin EnsureClean(R); Exit; end;

  Opts := FsDefaultCopyTreeOptions;
  Opts.Overwrite := True;
  Opts.PreserveTimes := False;
  Opts.PreservePerms := False;
  Opts.FollowSymlinks := False; // 关键：不跟随链接时应跳过链接本身
  Opts.CopySymlinksAsLinks := False;
  FsCopyTreeEx(R, Dst, Opts);

  // 期待：不跟随时跳过链接，不应复制到 A/to_B 下的任何内容或链接本身
  AssertFalse(DirectoryExists(IncludeTrailingPathDelimiter(Dst) + 'A' + PathDelim + 'to_B'));
  AssertFalse(FileExists(IncludeTrailingPathDelimiter(Dst) + 'A' + PathDelim + 'to_B'));
  // 但 B/file.txt 仍应被复制
  AssertTrue(FileExists(IncludeTrailingPathDelimiter(Dst) + 'B/file.txt'));

  EnsureClean(R);
  EnsureClean(Dst);
end;

initialization
  RegisterTest(TTestCase_CopyTree_Symlink);
end.

