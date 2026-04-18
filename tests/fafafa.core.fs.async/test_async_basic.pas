unit test_async_basic;

{$CODEPAGE UTF8}
{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry;

type
  // 异步文件系统基础功能测试
  TTestCase_AsyncFsBasic = class(TTestCase)
  private
    LAsyncFs: IAsyncFileSystem;
    LTempDir: string;
    LTestFile: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // === 基础异步文件操作测试 ===
    procedure Test_CreateAsyncFileSystem;
    procedure Test_ReadFileAsync_Success;
    procedure Test_ReadFileAsync_FileNotFound;
    procedure Test_WriteFileAsync_Success;
    procedure Test_ReadWriteTextAsync_Success;
    
    // === 路径安全验证测试 ===
    procedure Test_PathValidation_InvalidPath;
    procedure Test_PathValidation_PathTraversal;
    
    // === 异步文件句柄测试 ===
    procedure Test_OpenFileAsync_Success;
    procedure Test_AsyncFile_ReadWrite;
    procedure Test_AsyncFile_Seek;
    procedure Test_AsyncFile_Close;
    
    // === 错误处理测试 ===
    procedure Test_Exception_InvalidPath;
    procedure Test_Exception_FileOperationFailed;
  end;

implementation

procedure TTestCase_AsyncFsBasic.SetUp;
begin
  // 创建临时目录
  LTempDir := GetTempDir + 'fafafa_async_test_' + IntToStr(Random(10000)) + DirectorySeparator;
  ForceDirectories(LTempDir);
  
  LTestFile := LTempDir + 'test_file.txt';
  
  // 创建异步文件系统实例
  LAsyncFs := CreateAsyncFileSystem();
end;

procedure TTestCase_AsyncFsBasic.TearDown;
begin
  // 清理临时文件和目录
  if DirectoryExists(LTempDir) then
  begin
    if FileExists(LTestFile) then
      DeleteFile(LTestFile);
    RemoveDir(LTempDir);
  end;
  
  LAsyncFs := nil;
end;

procedure TTestCase_AsyncFsBasic.Test_CreateAsyncFileSystem;
var
  LFs: IAsyncFileSystem;
begin
  // 测试创建异步文件系统
  LFs := CreateAsyncFileSystem();
  AssertNotNull('异步文件系统应该被成功创建', LFs);
  
  // 测试线程池配置
  AssertNotNull('线程池应该被自动创建', LFs.GetThreadPool);
end;

procedure TTestCase_AsyncFsBasic.Test_ReadFileAsync_Success;
var
  LTestData: string;
  LFuture: IFuture<TBytes>;
  LResult: TBytes;
  LResultText: string;
begin
  LTestData := 'Hello, Async World! 你好，异步世界！';
  
  // 先创建测试文件
  with TStringList.Create do
  try
    Text := LTestData;
    SaveToFile(LTestFile, TEncoding.UTF8);
  finally
    Free;
  end;
  
  // 异步读取文件
  LFuture := LAsyncFs.ReadFileAsync(LTestFile);
  AssertNotNull('Future对象应该被创建', LFuture);
  
  // 等待结果
  AssertTrue('异步操作应该在合理时间内完成', LFuture.Wait(5000));
  
  LResult := LFuture.GetResult;
  LResultText := TEncoding.UTF8.GetString(LResult);
  
  AssertEquals('读取的内容应该与写入的内容一致', LTestData, LResultText);
end;

procedure TTestCase_AsyncFsBasic.Test_ReadFileAsync_FileNotFound;
var
  LFuture: IFuture<TBytes>;
begin
  // 测试读取不存在的文件
  LFuture := LAsyncFs.ReadFileAsync(LTempDir + 'nonexistent_file.txt');
  
  // 等待操作完成
  LFuture.Wait(5000);
  
  // 应该抛出异常
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('读取不存在的文件应该抛出异常', 
    procedure
    begin
      LFuture.GetResult;
    end, 
    ECore);
  {$ENDIF}
end;

procedure TTestCase_AsyncFsBasic.Test_WriteFileAsync_Success;
var
  LTestData: TBytes;
  LFuture: IFuture<Boolean>;
  LResult: Boolean;
  LReadBack: string;
begin
  LTestData := TEncoding.UTF8.GetBytes('Test write data 测试写入数据');
  
  // 异步写入文件
  LFuture := LAsyncFs.WriteFileAsync(LTestFile, LTestData);
  AssertNotNull('Future对象应该被创建', LFuture);
  
  // 等待结果
  AssertTrue('异步操作应该在合理时间内完成', LFuture.Wait(5000));
  
  LResult := LFuture.GetResult;
  AssertTrue('写入操作应该成功', LResult);
  
  // 验证文件内容
  AssertTrue('文件应该被创建', FileExists(LTestFile));
  
  with TStringList.Create do
  try
    LoadFromFile(LTestFile, TEncoding.UTF8);
    LReadBack := Text;
  finally
    Free;
  end;
  
  AssertEquals('文件内容应该正确', 'Test write data 测试写入数据', LReadBack);
end;

procedure TTestCase_AsyncFsBasic.Test_ReadWriteTextAsync_Success;
var
  LTestText: string;
  LWriteFuture: IFuture<Boolean>;
  LReadFuture: IFuture<string>;
  LResult: string;
begin
  LTestText := 'Hello, Async Text! 你好，异步文本！';
  
  // 异步写入文本
  LWriteFuture := LAsyncFs.WriteTextAsync(LTestFile, LTestText);
  AssertTrue('写入操作应该成功', LWriteFuture.Wait(5000));
  AssertTrue('写入结果应该为真', LWriteFuture.GetResult);
  
  // 异步读取文本
  LReadFuture := LAsyncFs.ReadTextAsync(LTestFile);
  AssertTrue('读取操作应该成功', LReadFuture.Wait(5000));
  
  LResult := LReadFuture.GetResult;
  AssertEquals('读取的文本应该与写入的文本一致', LTestText, LResult);
end;

procedure TTestCase_AsyncFsBasic.Test_PathValidation_InvalidPath;
begin
  // 测试无效路径
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('无效路径应该抛出异常',
    procedure
    begin
      LAsyncFs.ReadFileAsync('');
    end,
    ECore);
  {$ENDIF}
end;

procedure TTestCase_AsyncFsBasic.Test_PathValidation_PathTraversal;
begin
  // 测试路径遍历攻击
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('路径遍历攻击应该被阻止',
    procedure
    begin
      LAsyncFs.ReadFileAsync('../../../etc/passwd');
    end,
    ECore);
  {$ENDIF}
end;

procedure TTestCase_AsyncFsBasic.Test_OpenFileAsync_Success;
var
  LFuture: IFuture<IAsyncFile>;
  LFile: IAsyncFile;
begin
  // 创建测试文件
  with TStringList.Create do
  try
    Text := 'Test file content';
    SaveToFile(LTestFile);
  finally
    Free;
  end;
  
  // 异步打开文件
  LFuture := OpenFileAsync(LTestFile, O_RDONLY, 0);
  AssertTrue('文件打开应该成功', LFuture.Wait(5000));
  
  LFile := LFuture.GetResult;
  AssertNotNull('文件对象应该被创建', LFile);
  AssertEquals('文件路径应该正确', LTestFile, LFile.GetPath);
  
  // 关闭文件
  LFile.CloseAsync.Wait(5000);
end;

procedure TTestCase_AsyncFsBasic.Test_AsyncFile_ReadWrite;
var
  LOpenFuture: IFuture<IAsyncFile>;
  LFile: IAsyncFile;
  LTestData: TBytes;
  LWriteFuture: IFuture<SizeUInt>;
  LReadFuture: IFuture<TBytes>;
  LResult: TBytes;
begin
  LTestData := TEncoding.UTF8.GetBytes('Async file test data');
  
  // 打开文件进行写入
  LOpenFuture := OpenFileAsync(LTestFile, O_RDWR or O_CREAT, 644);
  AssertTrue('文件打开应该成功', LOpenFuture.Wait(5000));
  
  LFile := LOpenFuture.GetResult;
  
  // 写入数据
  LWriteFuture := LFile.WriteAsync(LTestData);
  AssertTrue('写入应该成功', LWriteFuture.Wait(5000));
  AssertEquals('写入字节数应该正确', Length(LTestData), LWriteFuture.GetResult);
  
  // 移动到文件开头
  LFile.SeekAsync(0, SEEK_SET).Wait(5000);
  
  // 读取数据
  LReadFuture := LFile.ReadAsync(Length(LTestData));
  AssertTrue('读取应该成功', LReadFuture.Wait(5000));
  
  LResult := LReadFuture.GetResult;
  AssertEquals('读取的数据长度应该正确', Length(LTestData), Length(LResult));
  AssertEquals('读取的数据应该与写入的数据一致', 
    TEncoding.UTF8.GetString(LTestData), 
    TEncoding.UTF8.GetString(LResult));
  
  // 关闭文件
  LFile.CloseAsync.Wait(5000);
end;

procedure TTestCase_AsyncFsBasic.Test_AsyncFile_Seek;
var
  LFile: IAsyncFile;
  LTestData: TBytes;
  LSeekFuture: IFuture<Int64>;
  LPosition: Int64;
begin
  LTestData := TEncoding.UTF8.GetBytes('0123456789');
  
  // 创建并打开文件
  LFile := OpenFileAsync(LTestFile, O_RDWR or O_CREAT, 644).GetResult;
  
  // 写入测试数据
  LFile.WriteAsync(LTestData).Wait(5000);
  
  // 测试seek到文件开头
  LSeekFuture := LFile.SeekAsync(0, SEEK_SET);
  AssertTrue('Seek操作应该成功', LSeekFuture.Wait(5000));
  LPosition := LSeekFuture.GetResult;
  AssertEquals('位置应该在文件开头', Int64(0), LPosition);
  
  // 测试seek到文件中间
  LSeekFuture := LFile.SeekAsync(5, SEEK_SET);
  AssertTrue('Seek操作应该成功', LSeekFuture.Wait(5000));
  LPosition := LSeekFuture.GetResult;
  AssertEquals('位置应该在文件中间', Int64(5), LPosition);
  
  // 关闭文件
  LFile.CloseAsync.Wait(5000);
end;

procedure TTestCase_AsyncFsBasic.Test_AsyncFile_Close;
var
  LFile: IAsyncFile;
  LCloseFuture: IFuture<Boolean>;
begin
  // 创建测试文件
  with TStringList.Create do
  try
    Text := 'Test';
    SaveToFile(LTestFile);
  finally
    Free;
  end;
  
  // 打开文件
  LFile := OpenFileAsync(LTestFile, O_RDONLY, 0).GetResult;
  
  // 关闭文件
  LCloseFuture := LFile.CloseAsync;
  AssertTrue('关闭操作应该成功', LCloseFuture.Wait(5000));
  AssertTrue('关闭结果应该为真', LCloseFuture.GetResult);
  
  // 再次关闭应该仍然成功（幂等性）
  LCloseFuture := LFile.CloseAsync;
  AssertTrue('重复关闭应该成功', LCloseFuture.Wait(5000));
  AssertTrue('重复关闭结果应该为真', LCloseFuture.GetResult);
end;

procedure TTestCase_AsyncFsBasic.Test_Exception_InvalidPath;
begin
  // 测试空路径
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('空路径应该抛出异常',
    procedure
    begin
      LAsyncFs.ReadFileAsync('');
    end,
    ECore);
  {$ENDIF}
end;

procedure TTestCase_AsyncFsBasic.Test_Exception_FileOperationFailed;
var
  LFuture: IFuture<TBytes>;
begin
  // 测试读取不存在的文件
  LFuture := LAsyncFs.ReadFileAsync(LTempDir + 'definitely_nonexistent_file.txt');
  
  // 等待操作完成
  LFuture.Wait(5000);
  
  // 获取结果时应该抛出异常
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  AssertException('文件操作失败应该抛出异常',
    procedure
    begin
      LFuture.GetResult;
    end,
    Exception);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_AsyncFsBasic);

end.
