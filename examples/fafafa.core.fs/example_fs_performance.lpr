program example_fs_performance;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$modeswitch unicodestrings}
{$WARN IMPLICIT_STRING_CAST OFF}
{$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$UNITPATH ..\..\src}

uses
  Classes, SysUtils, DateUtils, Math,
  fafafa.core.fs,
  fafafa.core.fs.errors,
  fafafa.core.fs.highlevel;

const
  TEMP_DIR = 'perf_test';
  SMALL_FILE = TEMP_DIR + DirectorySeparator + 'small.dat';
  MEDIUM_FILE = TEMP_DIR + DirectorySeparator + 'medium.dat';
  LARGE_FILE = TEMP_DIR + DirectorySeparator + 'large.dat';
  
  SMALL_SIZE = 1024;           // 1KB
  MEDIUM_SIZE = 1024 * 1024;   // 1MB
  LARGE_SIZE = 10 * 1024 * 1024; // 10MB

var
  LTestCount: Integer = 0;
  LPassedCount: Integer = 0;

procedure Log(const aMsg: string; aSuccess: Boolean);
begin
  Inc(LTestCount);
  Write('[');
  if aSuccess then
  begin
    Write(' OK ');
    Inc(LPassedCount);
  end
  else
    Write('FAIL');
  Writeln('] ', aMsg);
end;

procedure LogInfo(const aMsg: string);
begin
  Writeln('[ INFO ] ', aMsg);
end;

procedure LogPerf(const aOperation: string; aSize: Int64; aTimeMs: Int64);
var
  LThroughput: Double;
begin
  LThroughput := (aSize / 1024.0 / 1024.0) / (aTimeMs / 1000.0); // MB/s
  Writeln(Format('[ PERF ] %s: %d bytes in %d ms (%.2f MB/s)', 
    [aOperation, aSize, aTimeMs, LThroughput]));
end;

procedure Cleanup;
begin
  LogInfo('清理测试文件...');
  if SysUtils.FileExists(LARGE_FILE) then
    fs_unlink(LARGE_FILE);
  if SysUtils.FileExists(MEDIUM_FILE) then
    fs_unlink(MEDIUM_FILE);
  if SysUtils.FileExists(SMALL_FILE) then
    fs_unlink(SMALL_FILE);
  if SysUtils.DirectoryExists(TEMP_DIR) then
    fs_rmdir(TEMP_DIR);
  LogInfo('清理完成。');
end;

function CreateTestData(aSize: Integer): TBytes;
var
  I: Integer;
begin
  SetLength(Result, aSize);
  // 创建可压缩的测试数据
  for I := 0 to aSize - 1 do
    Result[I] := Byte(I mod 256);
end;

procedure TestFileCreation;
var
  LStartTime: TDateTime;
  LEndTime: TDateTime;
  LElapsed: Int64;
  LTestData: TBytes;
begin
  LogInfo('=== 测试文件创建性能 ===');
  
  // 创建测试目录
  Log('创建测试目录', fs_mkdir(TEMP_DIR, S_IRWXU) = 0);
  
  // 小文件测试
  LTestData := CreateTestData(SMALL_SIZE);
  LStartTime := Now;
  try
    WriteBinaryFile(SMALL_FILE, LTestData);
    LEndTime := Now;
    LElapsed := MilliSecondsBetween(LEndTime, LStartTime);
    LogPerf('小文件创建', SMALL_SIZE, LElapsed);
    Log('小文件创建成功', True);
  except
    on E: Exception do
    begin
      Log('小文件创建失败: ' + E.Message, False);
      Exit;
    end;
  end;
  
  // 中等文件测试
  LTestData := CreateTestData(MEDIUM_SIZE);
  LStartTime := Now;
  try
    WriteBinaryFile(MEDIUM_FILE, LTestData);
    LEndTime := Now;
    LElapsed := MilliSecondsBetween(LEndTime, LStartTime);
    LogPerf('中等文件创建', MEDIUM_SIZE, LElapsed);
    Log('中等文件创建成功', True);
  except
    on E: Exception do
    begin
      Log('中等文件创建失败: ' + E.Message, False);
      Exit;
    end;
  end;
  
  // 大文件测试
  LTestData := CreateTestData(LARGE_SIZE);
  LStartTime := Now;
  try
    WriteBinaryFile(LARGE_FILE, LTestData);
    LEndTime := Now;
    LElapsed := MilliSecondsBetween(LEndTime, LStartTime);
    LogPerf('大文件创建', LARGE_SIZE, LElapsed);
    Log('大文件创建成功', True);
  except
    on E: Exception do
    begin
      Log('大文件创建失败: ' + E.Message, False);
      Exit;
    end;
  end;
end;

procedure TestFileReading;
var
  LStartTime: TDateTime;
  LEndTime: TDateTime;
  LElapsed: Int64;
  LData: TBytes;
begin
  LogInfo('=== 测试文件读取性能 ===');
  
  // 小文件读取
  LStartTime := Now;
  try
    LData := ReadBinaryFile(SMALL_FILE);
    LEndTime := Now;
    LElapsed := MilliSecondsBetween(LEndTime, LStartTime);
    LogPerf('小文件读取', Length(LData), LElapsed);
    Log('小文件读取成功 (' + IntToStr(Length(LData)) + ' 字节)', Length(LData) = SMALL_SIZE);
  except
    on E: Exception do
    begin
      Log('小文件读取失败: ' + E.Message, False);
      Exit;
    end;
  end;
  
  // 中等文件读取
  LStartTime := Now;
  try
    LData := ReadBinaryFile(MEDIUM_FILE);
    LEndTime := Now;
    LElapsed := MilliSecondsBetween(LEndTime, LStartTime);
    LogPerf('中等文件读取', Length(LData), LElapsed);
    Log('中等文件读取成功 (' + IntToStr(Length(LData)) + ' 字节)', Length(LData) = MEDIUM_SIZE);
  except
    on E: Exception do
    begin
      Log('中等文件读取失败: ' + E.Message, False);
      Exit;
    end;
  end;
  
  // 大文件读取
  LStartTime := Now;
  try
    LData := ReadBinaryFile(LARGE_FILE);
    LEndTime := Now;
    LElapsed := MilliSecondsBetween(LEndTime, LStartTime);
    LogPerf('大文件读取', Length(LData), LElapsed);
    Log('大文件读取成功 (' + IntToStr(Length(LData)) + ' 字节)', Length(LData) = LARGE_SIZE);
  except
    on E: Exception do
    begin
      Log('大文件读取失败: ' + E.Message, False);
      Exit;
    end;
  end;
end;

procedure TestStreamingIO;
var
  LFile: TFsFile;
  LBuffer: array[0..8191] of Byte; // 8KB buffer
  LStartTime: TDateTime;
  LEndTime: TDateTime;
  LElapsed: Int64;
  LBytesRead, LTotalBytes: Integer;
  I: Integer;
begin
  LogInfo('=== 测试流式I/O性能 ===');
  
  LFile := TFsFile.Create;
  try
    // 流式读取大文件
    LStartTime := Now;
    LFile.Open(LARGE_FILE, fomRead);
    LTotalBytes := 0;
    repeat
      LBytesRead := LFile.Read(LBuffer, SizeOf(LBuffer));
      Inc(LTotalBytes, LBytesRead);
    until LBytesRead = 0;
    LFile.Close;
    LEndTime := Now;
    
    LElapsed := MilliSecondsBetween(LEndTime, LStartTime);
    LogPerf('流式读取', LTotalBytes, LElapsed);
    Log('流式读取成功 (' + IntToStr(LTotalBytes) + ' 字节)', LTotalBytes = LARGE_SIZE);
    
  except
    on E: Exception do
    begin
      Log('流式读取失败: ' + E.Message, False);
    end;
  end;
  
  try
    // 流式写入测试
    LStartTime := Now;
    LFile.Open(LARGE_FILE + '.stream', fomWrite);
    
    // 填充缓冲区
    for I := 0 to High(LBuffer) do
      LBuffer[I] := Byte(I mod 256);
    
    LTotalBytes := 0;
    while LTotalBytes < LARGE_SIZE do
    begin
      LBytesRead := Min(SizeOf(LBuffer), LARGE_SIZE - LTotalBytes);
      LFile.Write(LBuffer, LBytesRead);
      Inc(LTotalBytes, LBytesRead);
    end;
    LFile.Close;
    LEndTime := Now;
    
    LElapsed := MilliSecondsBetween(LEndTime, LStartTime);
    LogPerf('流式写入', LTotalBytes, LElapsed);
    Log('流式写入成功 (' + IntToStr(LTotalBytes) + ' 字节)', LTotalBytes = LARGE_SIZE);
    
    // 清理
    fs_unlink(LARGE_FILE + '.stream');
    
  except
    on E: Exception do
    begin
      Log('流式写入失败: ' + E.Message, False);
    end;
  end;
  
  LFile.Free;
end;

procedure TestHighLevelAPI;
var
  LStartTime: TDateTime;
  LEndTime: TDateTime;
  LElapsed: Int64;
  LText: string;
begin
  LogInfo('=== 测试高级API性能 ===');
  
  // 创建测试文本
  LText := StringOfChar('A', 1024 * 1024); // 1MB of 'A'
  
  // 文本文件写入
  LStartTime := Now;
  try
    WriteTextFile(TEMP_DIR + DirectorySeparator + 'text.txt', LText);
    LEndTime := Now;
    LElapsed := MilliSecondsBetween(LEndTime, LStartTime);
    LogPerf('文本文件写入', Length(LText), LElapsed);
    Log('文本文件写入成功', True);
  except
    on E: Exception do
    begin
      Log('文本文件写入失败: ' + E.Message, False);
      Exit;
    end;
  end;
  
  // 文本文件读取
  LStartTime := Now;
  try
    LText := ReadTextFile(TEMP_DIR + DirectorySeparator + 'text.txt');
    LEndTime := Now;
    LElapsed := MilliSecondsBetween(LEndTime, LStartTime);
    LogPerf('文本文件读取', Length(LText), LElapsed);
    Log('文本文件读取成功', Length(LText) = 1024 * 1024);
  except
    on E: Exception do
    begin
      Log('文本文件读取失败: ' + E.Message, False);
    end;
  end;
  
  // 清理
  fs_unlink(TEMP_DIR + DirectorySeparator + 'text.txt');
end;

begin
  Writeln('=== fafafa.core.fs 性能测试套件 ===');
  Writeln('');

  Cleanup;
  Writeln('');

  try
    TestFileCreation;
    Writeln('');
    
    TestFileReading;
    Writeln('');
    
    TestStreamingIO;
    Writeln('');
    
    TestHighLevelAPI;
    Writeln('');
    
  except
    on E: Exception do
    begin
      Writeln('测试过程中发生异常: ', E.Message);
    end;
  end;

  Cleanup;

  Writeln('');
  Writeln('=== 性能测试完成 ===');
  Writeln('总测试数: ', LTestCount);
  Writeln('通过测试: ', LPassedCount);
  Writeln('成功率: ', Format('%.1f%%', [LPassedCount * 100.0 / LTestCount]));
  
  if LPassedCount = LTestCount then
    Writeln('🎉 所有性能测试通过！')
  else
    Writeln('❌ 有性能测试失败！');
end.
