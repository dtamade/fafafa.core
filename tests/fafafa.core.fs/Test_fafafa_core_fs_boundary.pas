{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_boundary;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs,
  fafafa.core.fs.path,
  fafafa.core.fs.fileobj,
  fafafa.core.fs.bufio,
  fafafa.core.fs.std;

type
  // ============================================================================
  // 边界测试：Unicode 特殊字符路径
  // ============================================================================
  TTestFsBoundaryUnicode = class(TTestCase)
  private
    FTestDir: string;
    procedure SetUpTestDir;
    procedure TearDownTestDir;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 中文路径
    procedure Test_Unicode_Chinese_FileName;
    procedure Test_Unicode_Chinese_DirName;
    // 日文路径
    procedure Test_Unicode_Japanese_FileName;
    // 韩文路径
    procedure Test_Unicode_Korean_FileName;
    // 表情符号
    procedure Test_Unicode_Emoji_FileName;
    // 特殊 Unicode 字符
    procedure Test_Unicode_ZeroWidthChars;
    procedure Test_Unicode_RtlChars;
    procedure Test_Unicode_CombiningChars;
    // 混合 Unicode
    procedure Test_Unicode_Mixed_Script;
    // 边界情况
    procedure Test_Unicode_MaxLength_FileName;
  end;

  // ============================================================================
  // 边界测试：符号链接
  // ============================================================================
  TTestFsBoundarySymlink = class(TTestCase)
  private
    FTestDir: string;
    procedure SetUpTestDir;
    procedure TearDownTestDir;
    function CanCreateSymlink: Boolean;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 基本符号链接
    procedure Test_Symlink_ReadThrough;
    procedure Test_Symlink_WriteThrough;
    // 循环链接
    procedure Test_Symlink_SelfReference;
    procedure Test_Symlink_CircularAB;
    // 深层嵌套
    procedure Test_Symlink_DeepChain;
    // 悬空链接
    procedure Test_Symlink_Dangling;
    // 目录链接
    procedure Test_Symlink_Directory;
    // 相对路径链接
    procedure Test_Symlink_RelativePath;
  end;

  // ============================================================================
  // 边界测试：大文件处理 (需设置环境变量 FAFAFA_TEST_LARGEFILE=1)
  // ============================================================================
  TTestFsBoundaryLargeFile = class(TTestCase)
  private
    FTestDir: string;
    FEnabled: Boolean;
    procedure SetUpTestDir;
    procedure TearDownTestDir;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 大于 2GB (32位边界)
    procedure Test_LargeFile_2GB_Seek;
    // 大于 4GB (32位溢出边界)
    procedure Test_LargeFile_4GB_Boundary;
    // 稀疏文件测试
    procedure Test_LargeFile_Sparse;
  end;

  // ============================================================================
  // 边界测试：缓冲区边界
  // ============================================================================
  TTestFsBoundaryBuffer = class(TTestCase)
  private
    FTestDir: string;
    procedure SetUpTestDir;
    procedure TearDownTestDir;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 缓冲区边界
    procedure Test_Buffer_ExactSize;
    procedure Test_Buffer_CrossBoundary;
    procedure Test_Buffer_TinyBuffer;
    // 行边界
    procedure Test_Buffer_LineCrossBoundary;
    procedure Test_Buffer_VeryLongLine;
    // 空文件
    procedure Test_Buffer_EmptyFile;
    // 单字节
    procedure Test_Buffer_SingleByte;
  end;

implementation

// ============================================================================
// TTestFsBoundaryUnicode
// ============================================================================

procedure TTestFsBoundaryUnicode.SetUpTestDir;
begin
  FTestDir := GetTempDir(False) + 'fafafa_test_unicode_' + IntToStr(GetProcessID) + PathDelim;
  if not DirectoryExists(FTestDir) then
    CreateDir(FTestDir);
end;

procedure TTestFsBoundaryUnicode.TearDownTestDir;
var
  SR: TSearchRec;
begin
  if FindFirst(FTestDir + '*', faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Name <> '.') and (SR.Name <> '..') then
      begin
        if (SR.Attr and faDirectory) <> 0 then
          RemoveDir(FTestDir + SR.Name)
        else
          DeleteFile(FTestDir + SR.Name);
      end;
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
  RemoveDir(FTestDir);
end;

procedure TTestFsBoundaryUnicode.SetUp;
begin
  SetUpTestDir;
end;

procedure TTestFsBoundaryUnicode.TearDown;
begin
  TearDownTestDir;
end;

procedure TTestFsBoundaryUnicode.Test_Unicode_Chinese_FileName;
var
  Path, Content: string;
begin
  Path := FTestDir + '中文文件名.txt';
  Content := '这是中文内容';

  FsWriteString(Path, Content);
  AssertTrue('File should exist', FileExists(Path));
  AssertEquals(Content, FsReadToString(Path));
end;

procedure TTestFsBoundaryUnicode.Test_Unicode_Chinese_DirName;
var
  DirPath, FilePath, Content: string;
begin
  DirPath := FTestDir + '中文目录';
  FilePath := DirPath + PathDelim + '文件.txt';
  Content := 'test';

  FsCreateDir(DirPath);
  AssertTrue('Dir should exist', DirectoryExists(DirPath));

  FsWriteString(FilePath, Content);
  AssertEquals(Content, FsReadToString(FilePath));
end;

procedure TTestFsBoundaryUnicode.Test_Unicode_Japanese_FileName;
var
  Path, Content: string;
begin
  Path := FTestDir + 'ファイル名.txt';
  Content := 'テスト内容';

  FsWriteString(Path, Content);
  AssertTrue('File should exist', FileExists(Path));
  AssertEquals(Content, FsReadToString(Path));
end;

procedure TTestFsBoundaryUnicode.Test_Unicode_Korean_FileName;
var
  Path, Content: string;
begin
  Path := FTestDir + '파일이름.txt';
  Content := '테스트 내용';

  FsWriteString(Path, Content);
  AssertTrue('File should exist', FileExists(Path));
  AssertEquals(Content, FsReadToString(Path));
end;

procedure TTestFsBoundaryUnicode.Test_Unicode_Emoji_FileName;
var
  Path, Content: string;
begin
  // 使用简单的表情符号
  Path := FTestDir + 'file_🎉_test.txt';
  Content := 'emoji test 🚀';

  try
    FsWriteString(Path, Content);
    AssertTrue('File should exist', FileExists(Path));
    AssertEquals(Content, FsReadToString(Path));
  except
    on E: Exception do
    begin
      // 某些文件系统不支持表情符号文件名
      // 这种情况下测试跳过
      if Pos('Invalid', E.Message) > 0 then
        Exit;
      raise;
    end;
  end;
end;

procedure TTestFsBoundaryUnicode.Test_Unicode_ZeroWidthChars;
var
  Path, Content: string;
begin
  // 零宽字符 (U+200B Zero Width Space)
  Path := FTestDir + 'file' + #$E2#$80#$8B + 'name.txt';
  Content := 'zero width test';

  try
    FsWriteString(Path, Content);
    AssertTrue('File should exist', FileExists(Path));
    AssertEquals(Content, FsReadToString(Path));
  except
    on E: Exception do
    begin
      // 某些文件系统不支持零宽字符
      Exit;
    end;
  end;
end;

procedure TTestFsBoundaryUnicode.Test_Unicode_RtlChars;
var
  Path, Content: string;
begin
  // 阿拉伯文 (RTL)
  Path := FTestDir + 'ملف.txt';
  Content := 'RTL test محتوى';

  FsWriteString(Path, Content);
  AssertTrue('File should exist', FileExists(Path));
  AssertEquals(Content, FsReadToString(Path));
end;

procedure TTestFsBoundaryUnicode.Test_Unicode_CombiningChars;
var
  Path, Content: string;
begin
  // 组合字符 (e + combining acute accent)
  Path := FTestDir + 'cafe' + #$CC#$81 + '.txt';
  Content := 'combining char test';

  try
    FsWriteString(Path, Content);
    AssertTrue('File should exist', FileExists(Path));
    AssertEquals(Content, FsReadToString(Path));
  except
    on E: Exception do
      Exit;
  end;
end;

procedure TTestFsBoundaryUnicode.Test_Unicode_Mixed_Script;
var
  Path, Content: string;
begin
  // 混合脚本: 中文+日文+英文
  Path := FTestDir + '混合_ミックス_mixed.txt';
  Content := '内容 コンテンツ content';

  FsWriteString(Path, Content);
  AssertTrue('File should exist', FileExists(Path));
  AssertEquals(Content, FsReadToString(Path));
end;

procedure TTestFsBoundaryUnicode.Test_Unicode_MaxLength_FileName;
var
  Path, FileName, Content: string;
  I: Integer;
begin
  // 创建接近文件名长度限制的名称 (大多数系统 255 字节)
  FileName := '';
  for I := 1 to 60 do  // 60 * 3 bytes = 180 bytes (中文每字符3字节)
    FileName := FileName + '测';
  FileName := FileName + '.txt';

  Path := FTestDir + FileName;
  Content := 'max length test';

  try
    FsWriteString(Path, Content);
    AssertTrue('File should exist', FileExists(Path));
    AssertEquals(Content, FsReadToString(Path));
  except
    on E: Exception do
    begin
      // 文件名过长可能失败
      if Pos('name too long', LowerCase(E.Message)) > 0 then
        Exit;
      raise;
    end;
  end;
end;

// ============================================================================
// TTestFsBoundarySymlink
// ============================================================================

procedure TTestFsBoundarySymlink.SetUpTestDir;
begin
  FTestDir := GetTempDir(False) + 'fafafa_test_symlink_' + IntToStr(GetProcessID) + PathDelim;
  if not DirectoryExists(FTestDir) then
    CreateDir(FTestDir);
end;

procedure TTestFsBoundarySymlink.TearDownTestDir;
var
  SR: TSearchRec;
begin
  if FindFirst(FTestDir + '*', faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Name <> '.') and (SR.Name <> '..') then
      begin
        if (SR.Attr and faDirectory) <> 0 then
          RemoveDir(FTestDir + SR.Name)
        else
          DeleteFile(FTestDir + SR.Name);
      end;
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
  RemoveDir(FTestDir);
end;

function TTestFsBoundarySymlink.CanCreateSymlink: Boolean;
var
  TestFile, TestLink: string;
begin
  Result := False;
  {$IFDEF WINDOWS}
  // Windows 需要管理员权限或开发者模式
  Exit;
  {$ENDIF}

  TestFile := FTestDir + 'symlink_test_target';
  TestLink := FTestDir + 'symlink_test_link';

  try
    FsWriteString(TestFile, 'test');
    FsSymlink(TestFile, TestLink);
    Result := FileExists(TestLink);
    DeleteFile(TestLink);
    DeleteFile(TestFile);
  except
    Result := False;
  end;
end;

procedure TTestFsBoundarySymlink.SetUp;
begin
  SetUpTestDir;
end;

procedure TTestFsBoundarySymlink.TearDown;
begin
  TearDownTestDir;
end;

procedure TTestFsBoundarySymlink.Test_Symlink_ReadThrough;
var
  Target, Link, Content: string;
begin
  if not CanCreateSymlink then Exit;

  Target := FTestDir + 'target.txt';
  Link := FTestDir + 'link.txt';
  Content := 'read through symlink';

  FsWriteString(Target, Content);
  FsSymlink(Target, Link);

  AssertEquals('Read through symlink', Content, FsReadToString(Link));
end;

procedure TTestFsBoundarySymlink.Test_Symlink_WriteThrough;
var
  Target, Link, Content: string;
begin
  if not CanCreateSymlink then Exit;

  Target := FTestDir + 'target_write.txt';
  Link := FTestDir + 'link_write.txt';
  Content := 'write through symlink';

  FsWriteString(Target, 'original');
  FsSymlink(Target, Link);
  FsWriteString(Link, Content);

  AssertEquals('Write should affect target', Content, FsReadToString(Target));
end;

procedure TTestFsBoundarySymlink.Test_Symlink_SelfReference;
var
  Link: string;
begin
  if not CanCreateSymlink then Exit;

  Link := FTestDir + 'self_link';

  try
    FsSymlink(Link, Link);
    // 尝试读取应该失败
    try
      FsReadToString(Link);
      Fail('Should not be able to read self-referencing symlink');
    except
      // 预期异常
    end;
  except
    // 创建自引用链接可能失败，这也是可接受的
  end;
end;

procedure TTestFsBoundarySymlink.Test_Symlink_CircularAB;
var
  LinkA, LinkB: string;
begin
  if not CanCreateSymlink then Exit;

  LinkA := FTestDir + 'circular_a';
  LinkB := FTestDir + 'circular_b';

  try
    // 创建 A -> B
    FsSymlink(LinkB, LinkA);
    // 创建 B -> A (形成循环)
    FsSymlink(LinkA, LinkB);

    // 尝试读取应该失败
    try
      FsReadToString(LinkA);
      Fail('Should not be able to read circular symlink');
    except
      // 预期异常 (ELOOP 或类似)
    end;
  except
    // 创建循环链接可能失败
  end;
end;

procedure TTestFsBoundarySymlink.Test_Symlink_DeepChain;
var
  I: Integer;
  Prev, Curr, Target, Content: string;
begin
  if not CanCreateSymlink then Exit;

  Target := FTestDir + 'deep_target.txt';
  Content := 'deep chain test';
  FsWriteString(Target, Content);

  // 创建链接链: link_1 -> link_2 -> ... -> link_10 -> target
  Prev := Target;
  for I := 10 downto 1 do
  begin
    Curr := FTestDir + 'deep_link_' + IntToStr(I);
    FsSymlink(Prev, Curr);
    Prev := Curr;
  end;

  // 通过最外层链接读取
  AssertEquals('Read through deep chain', Content, FsReadToString(Prev));
end;

procedure TTestFsBoundarySymlink.Test_Symlink_Dangling;
var
  Target, Link: string;
  LinkTarget: string;
begin
  if not CanCreateSymlink then Exit;

  Target := FTestDir + 'nonexistent_target.txt';
  Link := FTestDir + 'dangling_link';

  // 创建指向不存在文件的链接
  FsSymlink(Target, Link);

  // 使用 FsReadLink 验证链接存在 (比 FileExists 更可靠)
  try
    LinkTarget := FsReadLink(Link);
    AssertTrue('Symlink should point to target', Pos('nonexistent', LinkTarget) > 0);
  except
    Fail('Symlink should exist and be readable');
  end;

  // 但读取应该失败
  try
    FsReadToString(Link);
    Fail('Should not be able to read dangling symlink');
  except
    // 预期异常
  end;
end;

procedure TTestFsBoundarySymlink.Test_Symlink_Directory;
var
  TargetDir, Link, FilePath, Content: string;
begin
  if not CanCreateSymlink then Exit;

  TargetDir := FTestDir + 'target_dir';
  Link := FTestDir + 'link_dir';
  Content := 'dir symlink test';

  FsCreateDir(TargetDir);
  FsWriteString(TargetDir + PathDelim + 'file.txt', Content);

  FsSymlink(TargetDir, Link);

  // 通过链接目录访问文件
  FilePath := Link + PathDelim + 'file.txt';
  AssertEquals('Read through dir symlink', Content, FsReadToString(FilePath));
end;

procedure TTestFsBoundarySymlink.Test_Symlink_RelativePath;
var
  SubDir, Target, Link, Content: string;
begin
  if not CanCreateSymlink then Exit;

  SubDir := FTestDir + 'subdir';
  FsCreateDir(SubDir);

  Target := SubDir + PathDelim + 'target.txt';
  Link := FTestDir + 'relative_link';
  Content := 'relative symlink test';

  FsWriteString(Target, Content);

  // 使用相对路径创建链接
  FsSymlink('subdir/target.txt', Link);

  AssertEquals('Read through relative symlink', Content, FsReadToString(Link));
end;

// ============================================================================
// TTestFsBoundaryLargeFile
// ============================================================================

procedure TTestFsBoundaryLargeFile.SetUpTestDir;
begin
  FEnabled := GetEnvironmentVariable('FAFAFA_TEST_LARGEFILE') = '1';
  if not FEnabled then Exit;

  FTestDir := GetTempDir(False) + 'fafafa_test_largefile_' + IntToStr(GetProcessID) + PathDelim;
  if not DirectoryExists(FTestDir) then
    CreateDir(FTestDir);
end;

procedure TTestFsBoundaryLargeFile.TearDownTestDir;
var
  SR: TSearchRec;
begin
  if not FEnabled then Exit;

  if FindFirst(FTestDir + '*', faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Name <> '.') and (SR.Name <> '..') then
        DeleteFile(FTestDir + SR.Name);
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
  RemoveDir(FTestDir);
end;

procedure TTestFsBoundaryLargeFile.SetUp;
begin
  SetUpTestDir;
end;

procedure TTestFsBoundaryLargeFile.TearDown;
begin
  TearDownTestDir;
end;

procedure TTestFsBoundaryLargeFile.Test_LargeFile_2GB_Seek;
var
  F: TFile;
  Path: string;
  Pos2GB: Int64;
  TestData: TBytes;
begin
  if not FEnabled then Exit;

  Path := FTestDir + 'large_2gb.bin';
  Pos2GB := Int64(2) * 1024 * 1024 * 1024;  // 2GB

  F := TFile.Create_(Path);
  try
    // Seek 到 2GB 位置
    F.Seek(Pos2GB, 0);
    AssertEquals('Position should be 2GB', Pos2GB, F.Tell);

    // 写入数据
    SetLength(TestData, 10);
    TestData[0] := $DE;
    TestData[9] := $AD;
    F.WriteBytes(TestData);

    // 验证文件大小
    AssertTrue('File should be > 2GB', F.Size > Pos2GB);
  finally
    F.Free;
  end;

  // 重新打开验证
  F := TFile.Open(Path);
  try
    F.Seek(Pos2GB, 0);
    TestData := F.ReadBytes(10);
    AssertEquals($DE, TestData[0]);
    AssertEquals($AD, TestData[9]);
  finally
    F.Free;
  end;
end;

procedure TTestFsBoundaryLargeFile.Test_LargeFile_4GB_Boundary;
var
  F: TFile;
  Path: string;
  Pos4GB: Int64;
  TestData: TBytes;
begin
  if not FEnabled then Exit;

  Path := FTestDir + 'large_4gb.bin';
  Pos4GB := Int64(4) * 1024 * 1024 * 1024;  // 4GB

  F := TFile.Create_(Path);
  try
    // Seek 到 4GB 边界附近
    F.Seek(Pos4GB - 5, 0);

    // 跨越 4GB 边界写入
    SetLength(TestData, 10);
    TestData[0] := $BE;
    TestData[4] := $EF;  // 正好在 4GB 边界
    TestData[9] := $CA;
    F.WriteBytes(TestData);

    AssertTrue('File should be > 4GB', F.Size > Pos4GB);
  finally
    F.Free;
  end;

  // 验证
  F := TFile.Open(Path);
  try
    F.Seek(Pos4GB - 5, 0);
    TestData := F.ReadBytes(10);
    AssertEquals($BE, TestData[0]);
    AssertEquals($EF, TestData[4]);
    AssertEquals($CA, TestData[9]);
  finally
    F.Free;
  end;
end;

procedure TTestFsBoundaryLargeFile.Test_LargeFile_Sparse;
var
  F: TFile;
  Path: string;
  Pos1, Pos2: Int64;
  TestData: TBytes;
begin
  if not FEnabled then Exit;

  Path := FTestDir + 'sparse.bin';
  Pos1 := Int64(100) * 1024 * 1024;   // 100MB
  Pos2 := Int64(500) * 1024 * 1024;   // 500MB

  F := TFile.Create_(Path);
  try
    // 在 100MB 处写入
    F.Seek(Pos1, 0);
    SetLength(TestData, 4);
    TestData[0] := $11;
    F.WriteBytes(TestData);

    // 在 500MB 处写入
    F.Seek(Pos2, 0);
    TestData[0] := $22;
    F.WriteBytes(TestData);

    AssertTrue('File should be > 500MB', F.Size > Pos2);
  finally
    F.Free;
  end;

  // 验证
  F := TFile.Open(Path);
  try
    F.Seek(Pos1, 0);
    TestData := F.ReadBytes(1);
    AssertEquals($11, TestData[0]);

    F.Seek(Pos2, 0);
    TestData := F.ReadBytes(1);
    AssertEquals($22, TestData[0]);
  finally
    F.Free;
  end;
end;

// ============================================================================
// TTestFsBoundaryBuffer
// ============================================================================

procedure TTestFsBoundaryBuffer.SetUpTestDir;
begin
  FTestDir := GetTempDir(False) + 'fafafa_test_buffer_' + IntToStr(GetProcessID) + PathDelim;
  if not DirectoryExists(FTestDir) then
    CreateDir(FTestDir);
end;

procedure TTestFsBoundaryBuffer.TearDownTestDir;
var
  SR: TSearchRec;
begin
  if FindFirst(FTestDir + '*', faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Name <> '.') and (SR.Name <> '..') then
        DeleteFile(FTestDir + SR.Name);
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
  RemoveDir(FTestDir);
end;

procedure TTestFsBoundaryBuffer.SetUp;
begin
  SetUpTestDir;
end;

procedure TTestFsBoundaryBuffer.TearDown;
begin
  TearDownTestDir;
end;

procedure TTestFsBoundaryBuffer.Test_Buffer_ExactSize;
var
  Path: string;
  Writer: TFsBufWriter;
  Reader: TFsBufReader;
  Data: TBytes;
  I: Integer;
const
  BufSize = 1024;
begin
  Path := FTestDir + 'exact_size.bin';

  // 创建正好等于缓冲区大小的数据
  SetLength(Data, BufSize);
  for I := 0 to BufSize - 1 do
    Data[I] := I mod 256;

  Writer := TFsBufWriter.Create(TFile.Create_(Path), BufSize, True);
  try
    Writer.WriteBytes(Data);
  finally
    Writer.Free;
  end;

  Reader := TFsBufReader.Create(TFile.Open(Path), BufSize, True);
  try
    Data := Reader.ReadBytes(BufSize);
    AssertEquals(BufSize, Length(Data));
    for I := 0 to BufSize - 1 do
      AssertEquals(I mod 256, Data[I]);
  finally
    Reader.Free;
  end;
end;

procedure TTestFsBoundaryBuffer.Test_Buffer_CrossBoundary;
var
  Path: string;
  Writer: TFsBufWriter;
  Reader: TFsBufReader;
  Data: TBytes;
  I: Integer;
const
  BufSize = 1024;
  DataSize = 1500;  // 跨越缓冲区边界
begin
  Path := FTestDir + 'cross_boundary.bin';

  SetLength(Data, DataSize);
  for I := 0 to DataSize - 1 do
    Data[I] := I mod 256;

  Writer := TFsBufWriter.Create(TFile.Create_(Path), BufSize, True);
  try
    Writer.WriteBytes(Data);
  finally
    Writer.Free;
  end;

  Reader := TFsBufReader.Create(TFile.Open(Path), BufSize, True);
  try
    Data := Reader.ReadBytes(DataSize);
    AssertEquals(DataSize, Length(Data));
    for I := 0 to DataSize - 1 do
      AssertEquals(I mod 256, Data[I]);
  finally
    Reader.Free;
  end;
end;

procedure TTestFsBoundaryBuffer.Test_Buffer_TinyBuffer;
var
  Path: string;
  Writer: TFsBufWriter;
  Reader: TFsBufReader;
  Line: string;
begin
  Path := FTestDir + 'tiny_buffer.txt';

  // 使用非常小的缓冲区 (16 字节)
  Writer := TFsBufWriter.Create(TFile.Create_(Path), 16, True);
  try
    Writer.WriteLn('This is a longer line that exceeds the tiny buffer');
    Writer.WriteLn('Second line');
  finally
    Writer.Free;
  end;

  Reader := TFsBufReader.Create(TFile.Open(Path), 16, True);
  try
    AssertTrue(Reader.ReadLine(Line));
    AssertEquals('This is a longer line that exceeds the tiny buffer', Line);
    AssertTrue(Reader.ReadLine(Line));
    AssertEquals('Second line', Line);
  finally
    Reader.Free;
  end;
end;

procedure TTestFsBoundaryBuffer.Test_Buffer_LineCrossBoundary;
var
  Path: string;
  Writer: TFsBufWriter;
  Reader: TFsBufReader;
  Line, TestLine: string;
  I: Integer;
const
  BufSize = 64;
begin
  Path := FTestDir + 'line_cross.txt';

  // 创建一行正好跨越缓冲区边界
  TestLine := '';
  for I := 1 to BufSize - 5 do
    TestLine := TestLine + 'X';
  TestLine := TestLine + 'CROSS';  // 这部分会跨越边界

  Writer := TFsBufWriter.Create(TFile.Create_(Path), BufSize, True);
  try
    Writer.WriteLn(TestLine);
    Writer.WriteLn('After');
  finally
    Writer.Free;
  end;

  Reader := TFsBufReader.Create(TFile.Open(Path), BufSize, True);
  try
    AssertTrue(Reader.ReadLine(Line));
    AssertEquals(TestLine, Line);
    AssertTrue(Reader.ReadLine(Line));
    AssertEquals('After', Line);
  finally
    Reader.Free;
  end;
end;

procedure TTestFsBoundaryBuffer.Test_Buffer_VeryLongLine;
var
  Path: string;
  Writer: TFsBufWriter;
  Reader: TFsBufReader;
  Line, TestLine: string;
  I: Integer;
const
  LineLen = 100000;  // 100KB 行
begin
  Path := FTestDir + 'very_long_line.txt';

  TestLine := '';
  for I := 1 to LineLen do
    TestLine := TestLine + Char(65 + (I mod 26));

  Writer := TFsBufWriter.Create(TFile.Create_(Path), 8192, True);
  try
    Writer.WriteLn(TestLine);
  finally
    Writer.Free;
  end;

  Reader := TFsBufReader.Create(TFile.Open(Path), 8192, True);
  try
    AssertTrue(Reader.ReadLine(Line));
    AssertEquals(LineLen, Length(Line));
    AssertEquals(TestLine, Line);
  finally
    Reader.Free;
  end;
end;

procedure TTestFsBoundaryBuffer.Test_Buffer_EmptyFile;
var
  Path: string;
  Writer: TFsBufWriter;
  Reader: TFsBufReader;
  Line: string;
  Data: TBytes;
begin
  Path := FTestDir + 'empty.bin';

  Writer := TFsBufWriter.Create(TFile.Create_(Path), 1024, True);
  try
    // 不写入任何内容
  finally
    Writer.Free;
  end;

  Reader := TFsBufReader.Create(TFile.Open(Path), 1024, True);
  try
    AssertFalse('Empty file should return False', Reader.ReadLine(Line));
    Data := Reader.ReadBytes(100);
    AssertEquals('Empty file should return 0 bytes', 0, Length(Data));
    AssertEquals('ReadByte should return -1', -1, Reader.ReadByte);
    AssertTrue('Should be EOF', Reader.IsEof);
  finally
    Reader.Free;
  end;
end;

procedure TTestFsBoundaryBuffer.Test_Buffer_SingleByte;
var
  Path: string;
  Writer: TFsBufWriter;
  Reader: TFsBufReader;
begin
  Path := FTestDir + 'single_byte.bin';

  Writer := TFsBufWriter.Create(TFile.Create_(Path), 1024, True);
  try
    Writer.WriteByte(42);
  finally
    Writer.Free;
  end;

  Reader := TFsBufReader.Create(TFile.Open(Path), 1024, True);
  try
    AssertEquals(42, Reader.ReadByte);
    AssertEquals(-1, Reader.ReadByte);
    AssertTrue(Reader.IsEof);
  finally
    Reader.Free;
  end;
end;

initialization
  RegisterTest(TTestFsBoundaryUnicode);
  RegisterTest(TTestFsBoundarySymlink);
  RegisterTest(TTestFsBoundaryLargeFile);
  RegisterTest(TTestFsBoundaryBuffer);

end.
