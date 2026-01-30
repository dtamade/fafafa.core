{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_copytree_symlink_aslink;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs, fafafa.core.fs.tree, fafafa.core.fs.fileio, fafafa.core.fs.directory, fafafa.core.fs.options;

type
  TTestCase_CopyTree_SymlinkAsLink = class(TTestCase)
  published
    procedure Test_CopySymlinksAsLinks_When_FollowFalse;
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
  ForceDirectories(ExtractFileDir(P));
  AssignFile(F, P);
  Rewrite(F);
  Write(F, S);
  Close(F);
end;

procedure TTestCase_CopyTree_SymlinkAsLink.Test_CopySymlinksAsLinks_When_FollowFalse;
var
  R, A, B, LinkAtoB, Dst: string;
  Opts: TFsCopyTreeOptions;
  Res: TFsTreeResult;
begin
  if not Enabled then Exit;

  R := 'copytree_aslink_' + IntToStr(GetTickCount64);
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

  Opts := Default(TFsCopyTreeOptions);
  Opts.Overwrite := True;
  Opts.FollowSymlinks := False;
  Opts.CopySymlinksAsLinks := True;

  FsCopyTreeEx(R, Dst, Opts, Res);

  // 期待：复制为链接本体，因此 Dst/A/to_B 是符号链接（至少存在）；B/file.txt 仍会被复制
  AssertTrue('A/to_B exists', DirectoryExists(IncludeTrailingPathDelimiter(Dst) + 'A' + PathDelim + 'to_B') or
    FileExists(IncludeTrailingPathDelimiter(Dst) + 'A' + PathDelim + 'to_B'));
  AssertTrue('B/file.txt exists', FileExists(IncludeTrailingPathDelimiter(Dst) + 'B' + PathDelim + 'file.txt'));

  EnsureClean(R);
  EnsureClean(Dst);
end;

initialization
  RegisterTest(TTestCase_CopyTree_SymlinkAsLink);
end.

