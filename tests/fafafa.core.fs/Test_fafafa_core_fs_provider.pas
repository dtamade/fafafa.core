unit Test_fafafa_core_fs_provider;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, FPCUnit, TestRegistry,
  fafafa.core.fs.provider,
  fafafa.core.fs.provider.memory;

type
  { TTestFileSystemProvider }
  TTestFileSystemProvider = class(TTestCase)
  private
    FMemFS: TMemoryFileSystem;
    FRealFS: IFileSystemProvider;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 内存文件系统测试
    procedure Test_MemoryFS_WriteAndReadFile;
    procedure Test_MemoryFS_WriteAndReadTextFile;
    procedure Test_MemoryFS_CreateAndListDirectory;
    procedure Test_MemoryFS_DeleteFile;
    procedure Test_MemoryFS_CopyFile;
    procedure Test_MemoryFS_MoveFile;
    procedure Test_MemoryFS_Exists;
    procedure Test_MemoryFS_IsFile;
    procedure Test_MemoryFS_IsDirectory;
    procedure Test_MemoryFS_GetFileSize;

    // 真实文件系统测试
    procedure Test_RealFS_GetCurrentDirectory;
    procedure Test_RealFS_GetTempDirectory;

    // 接口兼容性测试
    procedure Test_Interface_Compatibility;
  end;

implementation

{ TTestFileSystemProvider }

procedure TTestFileSystemProvider.SetUp;
begin
  FMemFS := TMemoryFileSystem.Create;
  FRealFS := GetDefaultFileSystem;
end;

procedure TTestFileSystemProvider.TearDown;
begin
  FreeAndNil(FMemFS);
  FRealFS := nil;
end;

procedure TTestFileSystemProvider.Test_MemoryFS_WriteAndReadFile;
var
  Data, ReadData: TBytes;
begin
  Data := nil;
  SetLength(Data, 5);
  Data[0] := 1; Data[1] := 2; Data[2] := 3; Data[3] := 4; Data[4] := 5;

  FMemFS.WriteFile('/test.bin', Data);
  ReadData := FMemFS.ReadFile('/test.bin');

  AssertEquals('长度应匹配', 5, Length(ReadData));
  AssertEquals('内容应匹配', Data[0], ReadData[0]);
  AssertEquals('内容应匹配', Data[4], ReadData[4]);
end;

procedure TTestFileSystemProvider.Test_MemoryFS_WriteAndReadTextFile;
var
  Text: string;
begin
  FMemFS.WriteTextFile('/hello.txt', 'Hello World');
  Text := FMemFS.ReadTextFile('/hello.txt');

  AssertEquals('文本应匹配', 'Hello World', Text);
end;

procedure TTestFileSystemProvider.Test_MemoryFS_CreateAndListDirectory;
var
  Entries: TFsDirEntries;
begin
  FMemFS.CreateDirectory('/mydir');
  FMemFS.WriteTextFile('/mydir/a.txt', 'file a');
  FMemFS.WriteTextFile('/mydir/b.txt', 'file b');

  Entries := FMemFS.ListDirectory('/mydir');
  AssertEquals('应有 2 个条目', 2, Length(Entries));
end;

procedure TTestFileSystemProvider.Test_MemoryFS_DeleteFile;
begin
  FMemFS.WriteTextFile('/todelete.txt', 'delete me');
  AssertTrue('文件应存在', FMemFS.Exists('/todelete.txt'));

  FMemFS.DeleteFile('/todelete.txt');
  AssertFalse('文件应已删除', FMemFS.Exists('/todelete.txt'));
end;

procedure TTestFileSystemProvider.Test_MemoryFS_CopyFile;
begin
  FMemFS.WriteTextFile('/src.txt', 'source content');
  FMemFS.CopyFile('/src.txt', '/dst.txt');

  AssertTrue('源文件应存在', FMemFS.Exists('/src.txt'));
  AssertTrue('目标文件应存在', FMemFS.Exists('/dst.txt'));
  AssertEquals('内容应相同', FMemFS.ReadTextFile('/src.txt'), FMemFS.ReadTextFile('/dst.txt'));
end;

procedure TTestFileSystemProvider.Test_MemoryFS_MoveFile;
begin
  FMemFS.WriteTextFile('/tomove.txt', 'move me');
  FMemFS.MoveFile('/tomove.txt', '/moved.txt');

  AssertFalse('源文件应不存在', FMemFS.Exists('/tomove.txt'));
  AssertTrue('目标文件应存在', FMemFS.Exists('/moved.txt'));
  AssertEquals('内容应保留', 'move me', FMemFS.ReadTextFile('/moved.txt'));
end;

procedure TTestFileSystemProvider.Test_MemoryFS_Exists;
begin
  AssertFalse('不存在的文件', FMemFS.Exists('/notexist.txt'));
  FMemFS.WriteTextFile('/exist.txt', 'I exist');
  AssertTrue('存在的文件', FMemFS.Exists('/exist.txt'));
end;

procedure TTestFileSystemProvider.Test_MemoryFS_IsFile;
begin
  FMemFS.WriteTextFile('/file.txt', 'I am a file');
  FMemFS.CreateDirectory('/dir');

  AssertTrue('应为文件', FMemFS.IsFile('/file.txt'));
  AssertFalse('目录不是文件', FMemFS.IsFile('/dir'));
end;

procedure TTestFileSystemProvider.Test_MemoryFS_IsDirectory;
begin
  FMemFS.WriteTextFile('/file.txt', 'I am a file');
  FMemFS.CreateDirectory('/dir');

  AssertFalse('文件不是目录', FMemFS.IsDirectory('/file.txt'));
  AssertTrue('应为目录', FMemFS.IsDirectory('/dir'));
end;

procedure TTestFileSystemProvider.Test_MemoryFS_GetFileSize;
var
  Size: Int64;
begin
  FMemFS.WriteTextFile('/sized.txt', '12345');
  Size := FMemFS.GetFileSize('/sized.txt');
  AssertEquals('大小应为 5', 5, Size);
end;

procedure TTestFileSystemProvider.Test_RealFS_GetCurrentDirectory;
var
  CurDir: string;
begin
  CurDir := FRealFS.GetCurrentDirectory;
  AssertTrue('当前目录应非空', Length(CurDir) > 0);
end;

procedure TTestFileSystemProvider.Test_RealFS_GetTempDirectory;
var
  TempDir: string;
begin
  TempDir := FRealFS.GetTempDirectory;
  AssertTrue('临时目录应非空', Length(TempDir) > 0);
end;

procedure TTestFileSystemProvider.Test_Interface_Compatibility;
var
  FS: IFileSystemProvider;
begin
  // 测试内存文件系统可以赋值给接口
  FS := TMemoryFileSystem.Create;
  FS.WriteTextFile('/test.txt', 'interface test');
  AssertEquals('接口调用应正常', 'interface test', FS.ReadTextFile('/test.txt'));

  // 测试真实文件系统
  FS := GetDefaultFileSystem;
  AssertTrue('真实文件系统应返回当前目录', Length(FS.GetCurrentDirectory) > 0);
end;

initialization
  RegisterTest(TTestFileSystemProvider);

end.
