unit Test_fafafa_core_fs_rustapi;

{$mode objfpc}{$H+}

{!
  测试 Rust 风格 API
  - TFsFileType, TFsPermissions, TFsMetadata
  - TFile, TFsOpenOptionsBuilder
  - TFsPath, TFsPathBuf
  - TFsReadDir, TFsDirEntry
  - 便捷函数
}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs,
  fafafa.core.fs.std;

type
  TTestRustStyleAPI = class(TTestCase)
  private
    FTempDir: string;
    FTestFile: string;
    procedure SetupTempDir;
    procedure CleanupTempDir;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // TFsPermissions 测试
    procedure Test_Permissions_FromMode;
    procedure Test_Permissions_Default;
    procedure Test_Permissions_ReadOnly;
    procedure Test_Permissions_ToString;
    procedure Test_Permissions_WithReadOnly;

    // TFsMetadata 测试
    procedure Test_Metadata_FromPath;
    procedure Test_Metadata_FileType;
    procedure Test_Metadata_Size;
    procedure Test_Metadata_Permissions;

    // TFile 测试
    procedure Test_File_Open;
    procedure Test_File_Create;
    procedure Test_File_ReadWrite;
    procedure Test_File_ReadString;
    procedure Test_File_Seek;

    // TFsOpenOptionsBuilder 测试
    procedure Test_OpenOptions_ForReading;
    procedure Test_OpenOptions_ForWriting;
    procedure Test_OpenOptions_Chain;

    // TFsPath 测试
    procedure Test_Path_From;
    procedure Test_Path_FileName;
    procedure Test_Path_Extension;
    procedure Test_Path_Parent;
    procedure Test_Path_Join;
    procedure Test_Path_IsAbsolute;
    procedure Test_Path_WithExtension;

    // TFsPathBuf 测试
    procedure Test_PathBuf_Push;
    procedure Test_PathBuf_Pop;
    procedure Test_PathBuf_SetExtension;

    // TFsReadDir 测试
    procedure Test_ReadDir_Basic;
    procedure Test_ReadDir_Count;

    // 便捷函数测试
    procedure Test_FsWriteString_FsReadToString;
    procedure Test_FsAppendString;
    procedure Test_FsCopy;
    procedure Test_FsCreateDir;
  end;

implementation

procedure TTestRustStyleAPI.SetupTempDir;
begin
  FTempDir := IncludeTrailingPathDelimiter(GetTempDir) + 'fafafa_rustapi_test_' + IntToStr(GetTickCount64);
  ForceDirectories(FTempDir);
  FTestFile := FTempDir + PathDelim + 'test.txt';
end;

procedure TTestRustStyleAPI.CleanupTempDir;
begin
  if DirectoryExists(FTempDir) then
  begin
    DeleteFile(FTestFile);
    DeleteFile(FTempDir + PathDelim + 'copy.txt');
    DeleteFile(FTempDir + PathDelim + 'subdir' + PathDelim + 'file.txt');
    RemoveDir(FTempDir + PathDelim + 'subdir');
    RemoveDir(FTempDir);
  end;
end;

procedure TTestRustStyleAPI.SetUp;
begin
  SetupTempDir;
end;

procedure TTestRustStyleAPI.TearDown;
begin
  CleanupTempDir;
end;

// ============================================================================
// TFsPermissions 测试
// ============================================================================

procedure TTestRustStyleAPI.Test_Permissions_FromMode;
var
  P: TFsPermissions;
begin
  P := TFsPermissions.FromMode($1FF); // 0777
  AssertTrue('OwnerRead', P.OwnerRead);
  AssertTrue('OwnerWrite', P.OwnerWrite);
  AssertTrue('OwnerExecute', P.OwnerExecute);
  AssertEquals('Mode', $1FF, P.Mode);
end;

procedure TTestRustStyleAPI.Test_Permissions_Default;
var
  P: TFsPermissions;
begin
  P := TFsPermissions.Default;
  AssertTrue('OwnerRead', P.OwnerRead);
  AssertTrue('OwnerWrite', P.OwnerWrite);
  AssertFalse('Not OwnerExecute', P.OwnerExecute);
end;

procedure TTestRustStyleAPI.Test_Permissions_ReadOnly;
var
  P: TFsPermissions;
begin
  P := TFsPermissions.ReadOnly;
  AssertTrue('IsReadOnly', P.IsReadOnly);
  AssertFalse('Not OwnerWrite', P.OwnerWrite);
end;

procedure TTestRustStyleAPI.Test_Permissions_ToString;
var
  P: TFsPermissions;
begin
  P := TFsPermissions.FromMode($1ED); // 0755 = rwxr-xr-x
  AssertEquals('ToString', 'rwxr-xr-x', P.ToString);
end;

procedure TTestRustStyleAPI.Test_Permissions_WithReadOnly;
var
  P, P2: TFsPermissions;
begin
  P := TFsPermissions.Default;
  P2 := P.WithReadOnly(True);
  AssertTrue('P2 IsReadOnly', P2.IsReadOnly);
  AssertFalse('P still writable', P.IsReadOnly);
end;

// ============================================================================
// TFsMetadata 测试
// ============================================================================

procedure TTestRustStyleAPI.Test_Metadata_FromPath;
var
  M: TFsMetadata;
  F: TFile;
begin
  // Create test file
  F := TFile.Create_(FTestFile);
  try
    F.WriteString('Hello');
  finally
    F.Free;
  end;

  M := FsMetadata(FTestFile);
  try
    AssertTrue('IsValid', M.IsValid);
    AssertTrue('IsFile', M.IsFile);
  finally
    M.Free;
  end;
end;

procedure TTestRustStyleAPI.Test_Metadata_FileType;
var
  M: TFsMetadata;
  F: TFile;
begin
  F := TFile.Create_(FTestFile);
  try
    F.WriteString('Test');
  finally
    F.Free;
  end;

  M := FsMetadata(FTestFile);
  try
    AssertEquals('FileType', Ord(ftRegular), Ord(M.FileType));
  finally
    M.Free;
  end;
end;

procedure TTestRustStyleAPI.Test_Metadata_Size;
var
  M: TFsMetadata;
  F: TFile;
begin
  F := TFile.Create_(FTestFile);
  try
    F.WriteString('12345');
  finally
    F.Free;
  end;

  M := FsMetadata(FTestFile);
  try
    AssertEquals('Size', 5, M.Size);
  finally
    M.Free;
  end;
end;

procedure TTestRustStyleAPI.Test_Metadata_Permissions;
var
  M: TFsMetadata;
  P: TFsPermissions;
  F: TFile;
begin
  F := TFile.Create_(FTestFile);
  try
    F.WriteString('Test');
  finally
    F.Free;
  end;

  M := FsMetadata(FTestFile);
  try
    P := M.Permissions;
    AssertTrue('OwnerRead', P.OwnerRead);
  finally
    M.Free;
  end;
end;

// ============================================================================
// TFile 测试
// ============================================================================

procedure TTestRustStyleAPI.Test_File_Open;
var
  F: TFile;
begin
  // Create file first
  FsWriteString(FTestFile, 'Test content');

  F := TFile.Open(FTestFile);
  try
    AssertTrue('IsOpen', F.IsOpen);
  finally
    F.Free;
  end;
end;

procedure TTestRustStyleAPI.Test_File_Create;
var
  F: TFile;
begin
  F := TFile.Create_(FTestFile);
  try
    AssertTrue('IsOpen', F.IsOpen);
    F.WriteString('Created!');
  finally
    F.Free;
  end;

  AssertTrue('File exists', FileExists(FTestFile));
end;

procedure TTestRustStyleAPI.Test_File_ReadWrite;
var
  F: TFile;
  Data: TBytes;
begin
  SetLength(Data, 5);
  Data[0] := 65; Data[1] := 66; Data[2] := 67; Data[3] := 68; Data[4] := 69;

  F := TFile.Create_(FTestFile);
  try
    F.WriteAll(Data);
  finally
    F.Free;
  end;

  F := TFile.Open(FTestFile);
  try
    Data := F.ReadAll;
    AssertEquals('Length', 5, Length(Data));
    AssertEquals('Data[0]', 65, Data[0]);
  finally
    F.Free;
  end;
end;

procedure TTestRustStyleAPI.Test_File_ReadString;
var
  F: TFile;
  S: string;
begin
  FsWriteString(FTestFile, 'Hello World');

  F := TFile.Open(FTestFile);
  try
    S := F.ReadString;
    AssertEquals('Content', 'Hello World', S);
  finally
    F.Free;
  end;
end;

procedure TTestRustStyleAPI.Test_File_Seek;
var
  F: TFile;
  Pos: Int64;
begin
  FsWriteString(FTestFile, '0123456789');

  F := TFile.Open(FTestFile);
  try
    Pos := F.Seek(5, SEEK_SET);
    AssertEquals('Seek result', 5, Pos);
    AssertEquals('Tell', 5, F.Tell);
  finally
    F.Free;
  end;
end;

// ============================================================================
// TFsOpenOptionsBuilder 测试
// ============================================================================

procedure TTestRustStyleAPI.Test_OpenOptions_ForReading;
var
  H: TfsFile;
begin
  FsWriteString(FTestFile, 'Test');

  H := TFsOpenOptionsBuilder.ForReading.Open(FTestFile);
  try
    AssertTrue('Valid handle', IsValidHandle(H));
  finally
    fs_close(H);
  end;
end;

procedure TTestRustStyleAPI.Test_OpenOptions_ForWriting;
var
  H: TfsFile;
begin
  H := TFsOpenOptionsBuilder.ForWriting.Open(FTestFile);
  try
    AssertTrue('Valid handle', IsValidHandle(H));
  finally
    fs_close(H);
  end;
end;

procedure TTestRustStyleAPI.Test_OpenOptions_Chain;
var
  H: TfsFile;
begin
  H := TFsOpenOptionsBuilder.New
         .Read(True)
         .Write(True)
         .Create_(True)
         .Open(FTestFile);
  try
    AssertTrue('Valid handle', IsValidHandle(H));
  finally
    fs_close(H);
  end;
end;

// ============================================================================
// TFsPath 测试
// ============================================================================

procedure TTestRustStyleAPI.Test_Path_From;
var
  P: TFsPath;
begin
  P := Path('/home/user/file.txt');
  AssertEquals('Value', '/home/user/file.txt', P.Value);
end;

procedure TTestRustStyleAPI.Test_Path_FileName;
var
  P: TFsPath;
begin
  P := Path('/home/user/file.txt');
  AssertEquals('FileName', 'file.txt', P.FileName);
end;

procedure TTestRustStyleAPI.Test_Path_Extension;
var
  P: TFsPath;
begin
  P := Path('/home/user/file.txt');
  AssertEquals('Extension', '.txt', P.Extension);
end;

procedure TTestRustStyleAPI.Test_Path_Parent;
var
  P: TFsPath;
begin
  P := Path('/home/user/file.txt');
  AssertEquals('Parent', '/home/user', P.Parent.Value);
end;

procedure TTestRustStyleAPI.Test_Path_Join;
var
  P: TFsPath;
begin
  P := Path('/home/user').Join('documents').Join('file.txt');
  AssertTrue('Contains documents', Pos('documents', P.Value) > 0);
  AssertTrue('Contains file.txt', Pos('file.txt', P.Value) > 0);
end;

procedure TTestRustStyleAPI.Test_Path_IsAbsolute;
var
  P1, P2: TFsPath;
begin
  P1 := Path('/home/user');
  P2 := Path('relative/path');

  AssertTrue('P1 is absolute', P1.IsAbsolute);
  AssertTrue('P2 is relative', P2.IsRelative);
end;

procedure TTestRustStyleAPI.Test_Path_WithExtension;
var
  P: TFsPath;
begin
  P := Path('/home/user/file.txt').WithExtension('.bak');
  AssertEquals('Extension', '.bak', P.Extension);
end;

// ============================================================================
// TFsPathBuf 测试
// ============================================================================

procedure TTestRustStyleAPI.Test_PathBuf_Push;
var
  Buf: TFsPathBuf;
begin
  Buf := PathBuf('/home');
  Buf.Push('user');
  Buf.Push('file.txt');
  AssertTrue('Contains user', Pos('user', Buf.Value) > 0);
  AssertTrue('Contains file.txt', Pos('file.txt', Buf.Value) > 0);
end;

procedure TTestRustStyleAPI.Test_PathBuf_Pop;
var
  Buf: TFsPathBuf;
begin
  Buf := PathBuf('/home/user/file.txt');
  AssertTrue('Pop returns true', Buf.Pop);
  AssertEquals('FileName after pop', 'user', Buf.FileName);
end;

procedure TTestRustStyleAPI.Test_PathBuf_SetExtension;
var
  Buf: TFsPathBuf;
begin
  Buf := PathBuf('/home/user/file.txt');
  Buf.SetExtension('.md');
  AssertEquals('Extension', '.md', Buf.Extension);
end;

// ============================================================================
// TFsReadDir 测试
// ============================================================================

procedure TTestRustStyleAPI.Test_ReadDir_Basic;
var
  Dir: TFsReadDir;
  Entry: TFsDirEntry;
  Found: Boolean;
begin
  // Create test file
  FsWriteString(FTestFile, 'Test');

  Dir := FsReadDir(FTempDir);
  try
    AssertTrue('IsValid', Dir.IsValid);
    Found := False;
    while Dir.Next(Entry) do
    begin
      if Entry.FileName = 'test.txt' then
        Found := True;
    end;
    AssertTrue('Found test.txt', Found);
  finally
    Dir.Free;
  end;
end;

procedure TTestRustStyleAPI.Test_ReadDir_Count;
var
  Dir: TFsReadDir;
begin
  FsWriteString(FTestFile, 'Test');
  FsWriteString(FTempDir + PathDelim + 'file2.txt', 'Test2');

  Dir := FsReadDir(FTempDir);
  try
    AssertTrue('Count >= 2', Dir.Count >= 2);
  finally
    Dir.Free;
  end;

  DeleteFile(FTempDir + PathDelim + 'file2.txt');
end;

// ============================================================================
// 便捷函数测试
// ============================================================================

procedure TTestRustStyleAPI.Test_FsWriteString_FsReadToString;
var
  Content: string;
begin
  FsWriteString(FTestFile, 'Hello World!');
  Content := FsReadToString(FTestFile);
  AssertEquals('Content', 'Hello World!', Content);
end;

procedure TTestRustStyleAPI.Test_FsAppendString;
var
  Content: string;
begin
  FsWriteString(FTestFile, 'First');
  FsAppendString(FTestFile, 'Second');
  Content := FsReadToString(FTestFile);
  AssertEquals('Content', 'FirstSecond', Content);
end;

procedure TTestRustStyleAPI.Test_FsCopy;
var
  Dest: string;
begin
  FsWriteString(FTestFile, 'Original');
  Dest := FTempDir + PathDelim + 'copy.txt';
  FsCopy(FTestFile, Dest);
  AssertTrue('Copy exists', FileExists(Dest));
  AssertEquals('Copy content', 'Original', FsReadToString(Dest));
end;

procedure TTestRustStyleAPI.Test_FsCreateDir;
var
  SubDir: string;
begin
  SubDir := FTempDir + PathDelim + 'subdir';
  FsCreateDir(SubDir);
  AssertTrue('SubDir exists', DirectoryExists(SubDir));
end;

initialization
  RegisterTest(TTestRustStyleAPI);

end.
