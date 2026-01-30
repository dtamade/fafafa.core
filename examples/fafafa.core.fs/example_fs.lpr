{$CODEPAGE UTF8}
program example_fs;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  fafafa.core.fs;

procedure DemoBasicFileOperations;
var
  LFile: TfsFile;
  LTestData: string;
  LBuffer: array[0..255] of Char;
  LBytesRead: Integer;
  LResult: Integer;
const
  TEST_FILE = 'test_example.txt';
begin
  WriteLn('=== Basic File Operations Demo ===');
  WriteLn;
  
  // 创建并写入文件
  LTestData := 'Hello from fafafa.core.fs!';
  LFile := fs_open(TEST_FILE, O_WRONLY or O_CREAT or O_TRUNC, S_IRWXU);
  
  if IsValidHandle(LFile) then
  begin
    LResult := fs_write(LFile, PChar(LTestData), Length(LTestData), -1);
    WriteLn('✓ File created and written: ', LResult, ' bytes');
    fs_close(LFile);
  end
  else
    WriteLn('✗ Failed to create file');
  
  // 读取文件
  LFile := fs_open(TEST_FILE, O_RDONLY, 0);
  if IsValidHandle(LFile) then
  begin
    FillChar(LBuffer, SizeOf(LBuffer), 0);
    LBytesRead := fs_read(LFile, @LBuffer[0], SizeOf(LBuffer) - 1, -1);
    WriteLn('✓ File read: ', LBytesRead, ' bytes');
    WriteLn('✓ Content: "', string(LBuffer), '"');
    fs_close(LFile);
  end
  else
    WriteLn('✗ Failed to read file');
  
  // 清理
  fs_unlink(TEST_FILE);
  WriteLn('✓ File cleaned up');
  WriteLn;
end;

procedure DemoAdvancedFeatures;
var
  LFile: TfsFile;
  LResult: Integer;
  LBuffer: array[0..255] of Char;
const
  TEST_FILE = 'test_advanced.txt';
begin
  WriteLn('=== Advanced Features Demo ===');
  WriteLn;
  
  // 创建测试文件
  LFile := fs_open(TEST_FILE, O_WRONLY or O_CREAT, S_IRWXU);
  if IsValidHandle(LFile) then
  begin
    fs_write(LFile, PChar('Advanced test'), 13, -1);
    
    // 测试文件同步
    LResult := fs_fsync(LFile);
    WriteLn('✓ File sync (fsync): ', LResult = 0);
    
    fs_close(LFile);
  end;
  
  // 测试文件访问权限检查
  LResult := fs_access(TEST_FILE, F_OK);
  WriteLn('✓ File exists check: ', LResult = 0);
  
  LResult := fs_access(TEST_FILE, R_OK);
  WriteLn('✓ Read permission check: ', LResult = 0);
  
  LResult := fs_access(TEST_FILE, W_OK);
  WriteLn('✓ Write permission check: ', LResult = 0);
  
  // 测试获取绝对路径
  FillChar(LBuffer, SizeOf(LBuffer), 0);
  LResult := fs_realpath(TEST_FILE, @LBuffer[0], SizeOf(LBuffer));
  if LResult > 0 then
    WriteLn('✓ Absolute path: ', string(LBuffer))
  else
    WriteLn('✗ Failed to get absolute path');
  
  // 清理
  fs_unlink(TEST_FILE);
  WriteLn('✓ Advanced test completed');
  WriteLn;
end;

procedure DemoErrorHandling;
var
  LResult: Integer;
begin
  WriteLn('=== Error Handling Demo ===');
  WriteLn;
  
  // 测试访问不存在的文件
  LResult := fs_access('nonexistent_file.txt', F_OK);
  WriteLn('✓ Access non-existent file (should fail): ', LResult < 0);
  
  // 测试删除不存在的文件
  LResult := fs_unlink('nonexistent_file.txt');
  WriteLn('✓ Delete non-existent file (should fail): ', LResult < 0);
  
  WriteLn('✓ Error handling test completed');
  WriteLn;
end;

begin
  WriteLn('========================================');
  WriteLn('  fafafa.core.fs Module Example');
  WriteLn('========================================');
  WriteLn;
  
  try
    DemoBasicFileOperations;
    DemoAdvancedFeatures;
    DemoErrorHandling;
    
    WriteLn('========================================');
    WriteLn('  All Examples Completed Successfully!');
    WriteLn('========================================');
    WriteLn;
    WriteLn('This example demonstrates:');
    WriteLn('  • Basic file operations (create, read, write, delete)');
    WriteLn('  • Advanced features (sync, permissions, absolute paths)');
    WriteLn('  • Proper error handling');
    WriteLn('  • Cross-platform file system operations');
    WriteLn;
    
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('Press Enter to exit...');
  ReadLn;
end.
