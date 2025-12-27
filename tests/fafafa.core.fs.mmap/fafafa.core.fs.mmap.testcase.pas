unit fafafa.core.fs.mmap.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

{**
 * fafafa.core.fs.mmap 模块测试用例
 *
 * 测试内存映射文件功能：
 * - 文件映射/取消映射
 * - 读写操作
 * - 匿名映射
 * - 同步操作
 * - 边界条件
 *
 * @author Claude Code (技术债务修复)
 * @date 2025-12-23
 *}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs,
  fafafa.core.fs.errors,
  fafafa.core.fs.mmap;

type
  { TTestMmapBasic - 基础映射测试 }
  TTestMmapBasic = class(TTestCase)
  private
    FTestDir: string;
    FTestFile: string;
    procedure CreateTestFile(const aContent: string);
    procedure CleanupTestFiles;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_CreateDestroy;
    procedure Test_MapFile_ReadOnly;
    procedure Test_MapFile_ReadWrite;
    procedure Test_MapFile_PartialMapping;
    procedure Test_Unmap;
  end;

  { TTestMmapAnonymous - 匿名映射测试 }
  TTestMmapAnonymous = class(TTestCase)
  published
    procedure Test_AnonymousMapping_Create;
    procedure Test_AnonymousMapping_ReadWrite;
    procedure Test_AnonymousMapping_LargeSize;
  end;

  { TTestMmapReadWrite - 读写操作测试 }
  TTestMmapReadWrite = class(TTestCase)
  private
    FTestDir: string;
    FTestFile: string;
    procedure CreateTestFile(const aContent: string);
    procedure CleanupTestFiles;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_ReadFromMapping;
    procedure Test_WriteToMapping;
    procedure Test_ModifyAndSync;
  end;

  { TTestMmapSync - 同步操作测试 }
  TTestMmapSync = class(TTestCase)
  private
    FTestDir: string;
    FTestFile: string;
    procedure CreateTestFile(aSize: Integer);
    procedure CleanupTestFiles;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Sync;
    procedure Test_SyncRange;
    procedure Test_SyncAsync;
  end;

  { TTestMmapEdgeCases - 边界条件测试 }
  TTestMmapEdgeCases = class(TTestCase)
  private
    FTestDir: string;
    FTestFile: string;
    procedure CleanupTestFiles;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_MapEmptyFile;
    procedure Test_DoubleMap_ShouldFail;
    procedure Test_UnmapWithoutMap;
    procedure Test_SyncWithoutMap_ShouldFail;
    procedure Test_OffsetExceedsFileSize_ShouldFail;
  end;

  { TTestMmapConvenience - 便利函数测试 }
  TTestMmapConvenience = class(TTestCase)
  private
    FTestDir: string;
    FTestFile: string;
    procedure CreateTestFile(const aContent: string);
    procedure CleanupTestFiles;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_MapFileToMemory;
    procedure Test_CreateAnonymousMapping;
  end;

implementation

const
  TEST_CONTENT = 'Hello, Memory Mapped File!';
  TEST_DIR_NAME = 'mmap_test_temp';

{ TTestMmapBasic }

procedure TTestMmapBasic.SetUp;
begin
  FTestDir := GetTempDir(False) + TEST_DIR_NAME + '_' + IntToStr(GetProcessID) + PathDelim;
  ForceDirectories(FTestDir);
  FTestFile := FTestDir + 'test_basic.dat';
end;

procedure TTestMmapBasic.TearDown;
begin
  CleanupTestFiles;
end;

procedure TTestMmapBasic.CreateTestFile(const aContent: string);
var
  F: TFileStream;
begin
  F := TFileStream.Create(FTestFile, fmCreate);
  try
    if Length(aContent) > 0 then
      F.WriteBuffer(aContent[1], Length(aContent));
  finally
    F.Free;
  end;
end;

procedure TTestMmapBasic.CleanupTestFiles;
begin
  if FileExists(FTestFile) then
    DeleteFile(FTestFile);
  if DirectoryExists(FTestDir) then
    RemoveDir(FTestDir);
end;

procedure TTestMmapBasic.Test_CreateDestroy;
var
  Mmap: TMemoryMappedFile;
begin
  Mmap := TMemoryMappedFile.Create;
  try
    AssertFalse('Should not be mapped initially', Mmap.IsMapped);
    AssertNull('Memory should be nil', Mmap.Memory);
    AssertEquals('Size should be 0', 0, Mmap.Size);
  finally
    Mmap.Free;
  end;
end;

procedure TTestMmapBasic.Test_MapFile_ReadOnly;
var
  Mmap: TMemoryMappedFile;
  FileHandle: TfsFile;
begin
  CreateTestFile(TEST_CONTENT);

  FileHandle := fs_open(FTestFile, O_RDONLY, 0);
  AssertTrue('Should open file', IsValidHandle(FileHandle));
  try
    Mmap := TMemoryMappedFile.Create;
    try
      Mmap.MapFile(FileHandle, 0, 0, mpReadOnly, [mmfShared]);

      AssertTrue('Should be mapped', Mmap.IsMapped);
      AssertNotNull('Memory should not be nil', Mmap.Memory);
      AssertEquals('Size should match content', Length(TEST_CONTENT), Mmap.Size);
      AssertEquals('Protection should be ReadOnly', Ord(mpReadOnly), Ord(Mmap.Protection));
    finally
      Mmap.Free;
    end;
  finally
    fs_close(FileHandle);
  end;
end;

procedure TTestMmapBasic.Test_MapFile_ReadWrite;
var
  Mmap: TMemoryMappedFile;
  FileHandle: TfsFile;
begin
  CreateTestFile(TEST_CONTENT);

  FileHandle := fs_open(FTestFile, O_RDWR, 0);
  AssertTrue('Should open file', IsValidHandle(FileHandle));
  try
    Mmap := TMemoryMappedFile.Create;
    try
      Mmap.MapFile(FileHandle, 0, 0, mpReadWrite, [mmfShared]);

      AssertTrue('Should be mapped', Mmap.IsMapped);
      AssertEquals('Protection should be ReadWrite', Ord(mpReadWrite), Ord(Mmap.Protection));
    finally
      Mmap.Free;
    end;
  finally
    fs_close(FileHandle);
  end;
end;

procedure TTestMmapBasic.Test_MapFile_PartialMapping;
var
  Mmap: TMemoryMappedFile;
  FileHandle: TfsFile;
  Offset, MapSize: Int64;
begin
  CreateTestFile(TEST_CONTENT);

  Offset := 5;
  MapSize := 10;

  FileHandle := fs_open(FTestFile, O_RDONLY, 0);
  AssertTrue('Should open file', IsValidHandle(FileHandle));
  try
    Mmap := TMemoryMappedFile.Create;
    try
      Mmap.MapFile(FileHandle, Offset, MapSize, mpReadOnly, [mmfShared]);

      AssertTrue('Should be mapped', Mmap.IsMapped);
      AssertEquals('Size should match requested size', MapSize, Mmap.Size);
    finally
      Mmap.Free;
    end;
  finally
    fs_close(FileHandle);
  end;
end;

procedure TTestMmapBasic.Test_Unmap;
var
  Mmap: TMemoryMappedFile;
  FileHandle: TfsFile;
begin
  CreateTestFile(TEST_CONTENT);

  FileHandle := fs_open(FTestFile, O_RDONLY, 0);
  AssertTrue('Should open file', IsValidHandle(FileHandle));
  try
    Mmap := TMemoryMappedFile.Create;
    try
      Mmap.MapFile(FileHandle, 0, 0, mpReadOnly, [mmfShared]);
      AssertTrue('Should be mapped', Mmap.IsMapped);

      Mmap.Unmap;

      AssertFalse('Should not be mapped after unmap', Mmap.IsMapped);
      AssertNull('Memory should be nil after unmap', Mmap.Memory);
      AssertEquals('Size should be 0 after unmap', 0, Mmap.Size);
    finally
      Mmap.Free;
    end;
  finally
    fs_close(FileHandle);
  end;
end;

{ TTestMmapAnonymous }

procedure TTestMmapAnonymous.Test_AnonymousMapping_Create;
var
  Mmap: TMemoryMappedFile;
begin
  Mmap := TMemoryMappedFile.Create;
  try
    Mmap.MapAnonymous(4096, mpReadWrite);

    AssertTrue('Should be mapped', Mmap.IsMapped);
    AssertNotNull('Memory should not be nil', Mmap.Memory);
    AssertEquals('Size should match requested', 4096, Mmap.Size);
  finally
    Mmap.Free;
  end;
end;

procedure TTestMmapAnonymous.Test_AnonymousMapping_ReadWrite;
var
  Mmap: TMemoryMappedFile;
  Data: PByte;
  I: Integer;
begin
  Mmap := TMemoryMappedFile.Create;
  try
    Mmap.MapAnonymous(256, mpReadWrite);

    // 写入数据
    Data := PByte(Mmap.Memory);
    for I := 0 to 255 do
      Data[I] := Byte(I);

    // 验证数据
    for I := 0 to 255 do
      AssertEquals('Data should match at index ' + IntToStr(I), Byte(I), Data[I]);
  finally
    Mmap.Free;
  end;
end;

procedure TTestMmapAnonymous.Test_AnonymousMapping_LargeSize;
var
  Mmap: TMemoryMappedFile;
  LargeSize: Int64;
begin
  LargeSize := 10 * 1024 * 1024; // 10 MB

  Mmap := TMemoryMappedFile.Create;
  try
    Mmap.MapAnonymous(LargeSize, mpReadWrite);

    AssertTrue('Should be mapped', Mmap.IsMapped);
    AssertEquals('Size should match', LargeSize, Mmap.Size);
  finally
    Mmap.Free;
  end;
end;

{ TTestMmapReadWrite }

procedure TTestMmapReadWrite.SetUp;
begin
  FTestDir := GetTempDir(False) + TEST_DIR_NAME + '_rw_' + IntToStr(GetProcessID) + PathDelim;
  ForceDirectories(FTestDir);
  FTestFile := FTestDir + 'test_rw.dat';
end;

procedure TTestMmapReadWrite.TearDown;
begin
  CleanupTestFiles;
end;

procedure TTestMmapReadWrite.CreateTestFile(const aContent: string);
var
  F: TFileStream;
begin
  F := TFileStream.Create(FTestFile, fmCreate);
  try
    if Length(aContent) > 0 then
      F.WriteBuffer(aContent[1], Length(aContent));
  finally
    F.Free;
  end;
end;

procedure TTestMmapReadWrite.CleanupTestFiles;
begin
  if FileExists(FTestFile) then
    DeleteFile(FTestFile);
  if DirectoryExists(FTestDir) then
    RemoveDir(FTestDir);
end;

procedure TTestMmapReadWrite.Test_ReadFromMapping;
var
  Mmap: TMemoryMappedFile;
  FileHandle: TfsFile;
  ReadContent: string;
begin
  CreateTestFile(TEST_CONTENT);

  FileHandle := fs_open(FTestFile, O_RDONLY, 0);
  AssertTrue('Should open file', IsValidHandle(FileHandle));
  try
    Mmap := TMemoryMappedFile.Create;
    try
      Mmap.MapFile(FileHandle, 0, 0, mpReadOnly, [mmfShared]);

      SetLength(ReadContent, Mmap.Size);
      Move(Mmap.Memory^, ReadContent[1], Mmap.Size);

      AssertEquals('Content should match', TEST_CONTENT, ReadContent);
    finally
      Mmap.Free;
    end;
  finally
    fs_close(FileHandle);
  end;
end;

procedure TTestMmapReadWrite.Test_WriteToMapping;
var
  Mmap: TMemoryMappedFile;
  FileHandle: TfsFile;
  NewContent: string;
begin
  CreateTestFile(TEST_CONTENT);
  NewContent := 'Modified Content Here!!!!';

  FileHandle := fs_open(FTestFile, O_RDWR, 0);
  AssertTrue('Should open file', IsValidHandle(FileHandle));
  try
    Mmap := TMemoryMappedFile.Create;
    try
      Mmap.MapFile(FileHandle, 0, 0, mpReadWrite, [mmfShared]);

      // 写入新内容（不超过原文件大小）
      Move(NewContent[1], Mmap.Memory^, Length(NewContent));
      Mmap.Sync;
    finally
      Mmap.Free;
    end;
  finally
    fs_close(FileHandle);
  end;

  // 验证文件内容已修改
  FileHandle := fs_open(FTestFile, O_RDONLY, 0);
  try
    Mmap := TMemoryMappedFile.Create;
    try
      Mmap.MapFile(FileHandle, 0, 0, mpReadOnly, [mmfShared]);

      AssertTrue('First char should match', PChar(Mmap.Memory)^ = NewContent[1]);
    finally
      Mmap.Free;
    end;
  finally
    fs_close(FileHandle);
  end;
end;

procedure TTestMmapReadWrite.Test_ModifyAndSync;
var
  Mmap: TMemoryMappedFile;
  FileHandle: TfsFile;
  Data: PByte;
begin
  CreateTestFile(TEST_CONTENT);

  FileHandle := fs_open(FTestFile, O_RDWR, 0);
  AssertTrue('Should open file', IsValidHandle(FileHandle));
  try
    Mmap := TMemoryMappedFile.Create;
    try
      Mmap.MapFile(FileHandle, 0, 0, mpReadWrite, [mmfShared]);

      // 修改第一个字节
      Data := PByte(Mmap.Memory);
      Data[0] := Byte('X');

      // 同步到磁盘
      Mmap.Sync(False); // 同步模式

      AssertEquals('First byte should be X', Byte('X'), Data[0]);
    finally
      Mmap.Free;
    end;
  finally
    fs_close(FileHandle);
  end;
end;

{ TTestMmapSync }

procedure TTestMmapSync.SetUp;
begin
  FTestDir := GetTempDir(False) + TEST_DIR_NAME + '_sync_' + IntToStr(GetProcessID) + PathDelim;
  ForceDirectories(FTestDir);
  FTestFile := FTestDir + 'test_sync.dat';
end;

procedure TTestMmapSync.TearDown;
begin
  CleanupTestFiles;
end;

procedure TTestMmapSync.CreateTestFile(aSize: Integer);
var
  F: TFileStream;
  Buffer: array of Byte;
  I: Integer;
begin
  SetLength(Buffer, aSize);
  for I := 0 to aSize - 1 do
    Buffer[I] := Byte(I mod 256);

  F := TFileStream.Create(FTestFile, fmCreate);
  try
    F.WriteBuffer(Buffer[0], aSize);
  finally
    F.Free;
  end;
end;

procedure TTestMmapSync.CleanupTestFiles;
begin
  if FileExists(FTestFile) then
    DeleteFile(FTestFile);
  if DirectoryExists(FTestDir) then
    RemoveDir(FTestDir);
end;

procedure TTestMmapSync.Test_Sync;
var
  Mmap: TMemoryMappedFile;
  FileHandle: TfsFile;
begin
  CreateTestFile(4096);

  FileHandle := fs_open(FTestFile, O_RDWR, 0);
  AssertTrue('Should open file', IsValidHandle(FileHandle));
  try
    Mmap := TMemoryMappedFile.Create;
    try
      Mmap.MapFile(FileHandle, 0, 0, mpReadWrite, [mmfShared]);

      // 修改数据
      PByte(Mmap.Memory)^ := 255;

      // 同步（不应抛出异常）
      Mmap.Sync;
    finally
      Mmap.Free;
    end;
  finally
    fs_close(FileHandle);
  end;
end;

procedure TTestMmapSync.Test_SyncRange;
var
  Mmap: TMemoryMappedFile;
  FileHandle: TfsFile;
begin
  CreateTestFile(4096);

  FileHandle := fs_open(FTestFile, O_RDWR, 0);
  AssertTrue('Should open file', IsValidHandle(FileHandle));
  try
    Mmap := TMemoryMappedFile.Create;
    try
      Mmap.MapFile(FileHandle, 0, 0, mpReadWrite, [mmfShared]);

      // 修改部分数据
      PByte(Mmap.Memory)^ := 255;

      // 同步指定范围（不应抛出异常）
      Mmap.SyncRange(0, 1024);
    finally
      Mmap.Free;
    end;
  finally
    fs_close(FileHandle);
  end;
end;

procedure TTestMmapSync.Test_SyncAsync;
var
  Mmap: TMemoryMappedFile;
  FileHandle: TfsFile;
begin
  CreateTestFile(4096);

  FileHandle := fs_open(FTestFile, O_RDWR, 0);
  AssertTrue('Should open file', IsValidHandle(FileHandle));
  try
    Mmap := TMemoryMappedFile.Create;
    try
      Mmap.MapFile(FileHandle, 0, 0, mpReadWrite, [mmfShared]);

      // 异步同步（不应抛出异常）
      Mmap.Sync(True);
    finally
      Mmap.Free;
    end;
  finally
    fs_close(FileHandle);
  end;
end;

{ TTestMmapEdgeCases }

procedure TTestMmapEdgeCases.SetUp;
begin
  FTestDir := GetTempDir(False) + TEST_DIR_NAME + '_edge_' + IntToStr(GetProcessID) + PathDelim;
  ForceDirectories(FTestDir);
  FTestFile := FTestDir + 'test_edge.dat';
end;

procedure TTestMmapEdgeCases.TearDown;
begin
  CleanupTestFiles;
end;

procedure TTestMmapEdgeCases.CleanupTestFiles;
begin
  if FileExists(FTestFile) then
    DeleteFile(FTestFile);
  if DirectoryExists(FTestDir) then
    RemoveDir(FTestDir);
end;

procedure TTestMmapEdgeCases.Test_MapEmptyFile;
var
  Mmap: TMemoryMappedFile;
  FileHandle: TfsFile;
  F: TFileStream;
begin
  // 创建空文件
  F := TFileStream.Create(FTestFile, fmCreate);
  F.Free;

  FileHandle := fs_open(FTestFile, O_RDONLY, 0);
  AssertTrue('Should open file', IsValidHandle(FileHandle));
  try
    Mmap := TMemoryMappedFile.Create;
    try
      // 映射空文件应该返回 size=0 的映射或失败
      // 行为取决于平台实现
      try
        Mmap.MapFile(FileHandle, 0, 0, mpReadOnly, [mmfShared]);
        // 如果成功，size 应该是 0
        AssertEquals('Size of empty file mapping should be 0', 0, Mmap.Size);
      except
        on E: EFsError do
          // 某些平台可能不允许映射空文件，这也是可接受的
          AssertTrue('Exception for empty file is acceptable', True);
      end;
    finally
      Mmap.Free;
    end;
  finally
    fs_close(FileHandle);
  end;
end;

procedure TTestMmapEdgeCases.Test_DoubleMap_ShouldFail;
var
  Mmap: TMemoryMappedFile;
  FileHandle: TfsFile;
  F: TFileStream;
  ExceptionRaised: Boolean;
begin
  // 创建测试文件
  F := TFileStream.Create(FTestFile, fmCreate);
  try
    F.WriteBuffer(TEST_CONTENT[1], Length(TEST_CONTENT));
  finally
    F.Free;
  end;

  FileHandle := fs_open(FTestFile, O_RDONLY, 0);
  AssertTrue('Should open file', IsValidHandle(FileHandle));
  try
    Mmap := TMemoryMappedFile.Create;
    try
      Mmap.MapFile(FileHandle, 0, 0, mpReadOnly, [mmfShared]);

      // 尝试再次映射应该失败
      ExceptionRaised := False;
      try
        Mmap.MapFile(FileHandle, 0, 0, mpReadOnly, [mmfShared]);
      except
        on E: EFsError do
          ExceptionRaised := True;
      end;

      AssertTrue('Double mapping should raise exception', ExceptionRaised);
    finally
      Mmap.Free;
    end;
  finally
    fs_close(FileHandle);
  end;
end;

procedure TTestMmapEdgeCases.Test_UnmapWithoutMap;
var
  Mmap: TMemoryMappedFile;
begin
  Mmap := TMemoryMappedFile.Create;
  try
    // 未映射时调用 Unmap 不应抛出异常
    Mmap.Unmap;
    AssertFalse('Should still not be mapped', Mmap.IsMapped);
  finally
    Mmap.Free;
  end;
end;

procedure TTestMmapEdgeCases.Test_SyncWithoutMap_ShouldFail;
var
  Mmap: TMemoryMappedFile;
  ExceptionRaised: Boolean;
begin
  Mmap := TMemoryMappedFile.Create;
  try
    ExceptionRaised := False;
    try
      Mmap.Sync;
    except
      on E: EFsError do
        ExceptionRaised := True;
    end;

    AssertTrue('Sync without map should raise exception', ExceptionRaised);
  finally
    Mmap.Free;
  end;
end;

procedure TTestMmapEdgeCases.Test_OffsetExceedsFileSize_ShouldFail;
var
  Mmap: TMemoryMappedFile;
  FileHandle: TfsFile;
  F: TFileStream;
  ExceptionRaised: Boolean;
begin
  // 创建小文件
  F := TFileStream.Create(FTestFile, fmCreate);
  try
    F.WriteBuffer(TEST_CONTENT[1], Length(TEST_CONTENT));
  finally
    F.Free;
  end;

  FileHandle := fs_open(FTestFile, O_RDONLY, 0);
  AssertTrue('Should open file', IsValidHandle(FileHandle));
  try
    Mmap := TMemoryMappedFile.Create;
    try
      ExceptionRaised := False;
      try
        // 偏移量超过文件大小
        Mmap.MapFile(FileHandle, 10000, 100, mpReadOnly, [mmfShared]);
      except
        on E: EFsError do
          ExceptionRaised := True;
      end;

      AssertTrue('Offset exceeding file size should raise exception', ExceptionRaised);
    finally
      Mmap.Free;
    end;
  finally
    fs_close(FileHandle);
  end;
end;

{ TTestMmapConvenience }

procedure TTestMmapConvenience.SetUp;
begin
  FTestDir := GetTempDir(False) + TEST_DIR_NAME + '_conv_' + IntToStr(GetProcessID) + PathDelim;
  ForceDirectories(FTestDir);
  FTestFile := FTestDir + 'test_conv.dat';
end;

procedure TTestMmapConvenience.TearDown;
begin
  CleanupTestFiles;
end;

procedure TTestMmapConvenience.CreateTestFile(const aContent: string);
var
  F: TFileStream;
begin
  F := TFileStream.Create(FTestFile, fmCreate);
  try
    if Length(aContent) > 0 then
      F.WriteBuffer(aContent[1], Length(aContent));
  finally
    F.Free;
  end;
end;

procedure TTestMmapConvenience.CleanupTestFiles;
begin
  if FileExists(FTestFile) then
    DeleteFile(FTestFile);
  if DirectoryExists(FTestDir) then
    RemoveDir(FTestDir);
end;

procedure TTestMmapConvenience.Test_MapFileToMemory;
var
  Mmap: TMemoryMappedFile;
begin
  CreateTestFile(TEST_CONTENT);

  Mmap := MapFileToMemory(FTestFile, mpReadOnly);
  try
    AssertTrue('Should be mapped', Mmap.IsMapped);
    AssertEquals('Size should match', Length(TEST_CONTENT), Mmap.Size);
  finally
    Mmap.Free;
  end;
end;

procedure TTestMmapConvenience.Test_CreateAnonymousMapping;
var
  Mmap: TMemoryMappedFile;
begin
  Mmap := CreateAnonymousMapping(4096, mpReadWrite);
  try
    AssertTrue('Should be mapped', Mmap.IsMapped);
    AssertEquals('Size should match', 4096, Mmap.Size);
    AssertNotNull('Memory should not be nil', Mmap.Memory);
  finally
    Mmap.Free;
  end;
end;

initialization
  RegisterTest('fafafa.core.fs.mmap', TTestMmapBasic);
  RegisterTest('fafafa.core.fs.mmap', TTestMmapAnonymous);
  RegisterTest('fafafa.core.fs.mmap', TTestMmapReadWrite);
  RegisterTest('fafafa.core.fs.mmap', TTestMmapSync);
  RegisterTest('fafafa.core.fs.mmap', TTestMmapEdgeCases);
  RegisterTest('fafafa.core.fs.mmap', TTestMmapConvenience);

end.
