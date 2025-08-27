{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_remove_tree_atomic_write;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.fs.highlevel, fafafa.core.fs.path, fafafa.core.fs.errors, fafafa.core.fs;

type
  TTestCase_RemoveAndAtomic = class(TTestCase)
  published
    // Atomic write
    procedure Test_WriteFileAtomic_Basic;

    // RemoveTreeEx basics
    procedure Test_RemoveTreeEx_Basic;

    // RemoveTreeEx ErrorPolicy: Abort should raise on locked file
    procedure Test_RemoveTreeEx_ErrorPolicy_Abort_FileLocked;
    // RemoveTreeEx ErrorPolicy: Continue should not raise, errors>0, root still exists
    procedure Test_RemoveTreeEx_ErrorPolicy_Continue_FileLocked;

    // FollowSymlinks behavior
    procedure Test_RemoveTreeEx_FollowSymlinks_False_DoesNotTouchExternalTarget;
    procedure Test_RemoveTreeEx_FollowSymlinks_True_RemovesExternalTarget;
  end;

implementation

procedure TTestCase_RemoveAndAtomic.Test_WriteFileAtomic_Basic;
var
  Dir, P: string;
  Data: TBytes;
begin
  Dir := GetTempDirectory;
  P := JoinPath(Dir, 'atomic.txt');
  if FileExists(P) then DeleteFile(P);
  SetLength(Data, 3);
  Data[0] := Ord('A'); Data[1] := Ord('B'); Data[2] := Ord('C');
  WriteFileAtomic(P, Data);
  AssertTrue('file exists', FileExists(P));
  AssertEquals('size', 3, GetFileSize(P));
end;

procedure TTestCase_RemoveAndAtomic.Test_RemoveTreeEx_Basic;
var
  Root, D1, D2, F1, F2: string;
  Opts: TFsRemoveTreeOptions;
  R: TFsRemoveTreeResult;
begin
  Root := JoinPath(GetTempDirectory, 'rt_' + IntToStr(Random(100000)));
  CreateDirectory(Root, True);
  D1 := JoinPath(Root, 'd1');
  D2 := JoinPath(Root, 'd2');
  CreateDirectory(D1, True);
  CreateDirectory(D2, True);
  F1 := JoinPath(D1, 'a.txt');
  F2 := JoinPath(D2, 'b.txt');
  WriteTextFile(F1, 'a');
  WriteTextFile(F2, 'b');

  Opts := FsDefaultRemoveTreeOptions;
  RemoveTreeEx(Root, Opts, R);
  AssertTrue('root removed', not PathExists(Root));
  AssertTrue('files removed count >=2', R.FilesRemoved >= 2);
  AssertTrue('dirs removed count >=2', R.DirsRemoved >= 2);
end;

procedure TTestCase_RemoveAndAtomic.Test_RemoveTreeEx_ErrorPolicy_Abort_FileLocked;
var
  Root, F: string;
  Opts: TFsRemoveTreeOptions;
  FileHandle: TfsFile;
begin
  Root := JoinPath(GetTempDirectory, 'rt_lock_abort_' + IntToStr(Random(100000)));
  CreateDirectory(Root, True);
  F := JoinPath(Root, 'locked.txt');
  WriteTextFile(F, 'x');

  // 打开并尽量独占（Windows 上使用最小共享）
  // Windows: 不授予删除共享，确保删除受阻以验证错误策略
  FileHandle := fs_open(F, O_RDWR or O_SHARE_READ, S_IRWXU);
  try
    Opts := FsDefaultRemoveTreeOptions;
    Opts.ErrorPolicy := epAbort;
    try
      // 期望抛出异常（无法删除被占用文件）
      RemoveTreeEx(Root, Opts);
      Fail('expected EFsError not raised');
    except
      on E: EFsError do ; // OK
    end;
  finally
    if IsValidHandle(FileHandle) then fs_close(FileHandle);
    RemoveTreeEx(Root, FsDefaultRemoveTreeOptions);
  end;
end;

procedure TTestCase_RemoveAndAtomic.Test_RemoveTreeEx_ErrorPolicy_Continue_FileLocked;
var
  Root, F: string;
  Opts: TFsRemoveTreeOptions;
  R: TFsRemoveTreeResult;
  FileHandle: TfsFile;
begin
  Root := JoinPath(GetTempDirectory, 'rt_lock_continue_' + IntToStr(Random(100000)));
  CreateDirectory(Root, True);
  F := JoinPath(Root, 'locked.txt');
  WriteTextFile(F, 'x');

  // Windows: 不授予删除共享，确保删除受阻以验证错误策略
  FileHandle := fs_open(F, O_RDWR or O_SHARE_READ, S_IRWXU);
  try
    Opts := FsDefaultRemoveTreeOptions;
    Opts.ErrorPolicy := epContinue;
    RemoveTreeEx(Root, Opts, R);
    // 不抛异常，错误计数 >= 1，且根目录仍可能存在（文件锁导致无法删除根）
    AssertTrue('errors >= 1', R.Errors >= 1);
  finally
    if IsValidHandle(FileHandle) then fs_close(FileHandle);
    RemoveTreeEx(Root, FsDefaultRemoveTreeOptions);
  end;
end;

procedure TTestCase_RemoveAndAtomic.Test_RemoveTreeEx_FollowSymlinks_False_DoesNotTouchExternalTarget;
var
  Root, LinkP, ExternalDir, ExternalFile: string;
  Opts: TFsRemoveTreeOptions;
  R: TFsRemoveTreeResult;
begin
  Root := JoinPath(GetTempDirectory, 'rt_symlink_false_' + IntToStr(Random(100000)));
  CreateDirectory(Root, True);
  ExternalDir := JoinPath(GetTempDirectory, 'rt_external_' + IntToStr(Random(100000)));
  CreateDirectory(ExternalDir, True);
  ExternalFile := JoinPath(ExternalDir, 'keep.txt');
  WriteTextFile(ExternalFile, 'k');

  LinkP := JoinPath(Root, 'link_to_external');
  // 创建指向外部目录的符号链接；若不支持则跳过用例
  if fs_symlink(ExternalDir, LinkP) < 0 then Exit;

  Opts := FsDefaultRemoveTreeOptions; // FollowSymlinks=False
  RemoveTreeEx(Root, Opts, R);
  AssertTrue('root removed', not PathExists(Root));
  AssertTrue('external target remains', PathExists(ExternalFile));
  // 清理
  RemoveTreeEx(ExternalDir, FsDefaultRemoveTreeOptions);
end;

procedure TTestCase_RemoveAndAtomic.Test_RemoveTreeEx_FollowSymlinks_True_RemovesExternalTarget;
var
  Root, LinkP, ExternalDir, ExternalFile: string;
  Opts: TFsRemoveTreeOptions;
  R: TFsRemoveTreeResult;
begin
  Root := JoinPath(GetTempDirectory, 'rt_symlink_true_' + IntToStr(Random(100000)));
  CreateDirectory(Root, True);
  ExternalDir := JoinPath(GetTempDirectory, 'rt_external_' + IntToStr(Random(100000)));
  CreateDirectory(ExternalDir, True);
  ExternalFile := JoinPath(ExternalDir, 'gone.txt');
  WriteTextFile(ExternalFile, 'g');

  LinkP := JoinPath(Root, 'link_to_external');
  if fs_symlink(ExternalDir, LinkP) < 0 then Exit;

  Opts := FsDefaultRemoveTreeOptions;
  Opts.FollowSymlinks := True;
  RemoveTreeEx(Root, Opts, R);
  AssertTrue('root removed', not PathExists(Root));
  AssertTrue('external target removed', not PathExists(ExternalDir));
end;


initialization
  RegisterTest(TTestCase_RemoveAndAtomic);
end.

