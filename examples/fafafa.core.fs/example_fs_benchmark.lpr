program benchmark_fs;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$modeswitch unicodestrings}
{$WARN IMPLICIT_STRING_CAST OFF}
{$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$UNITPATH ..\..\src}

uses
  Classes, SysUtils,
  {$IFDEF WINDOWS}
  Windows,
  {$ELSE}
  Unix, BaseUnix,
  {$ENDIF}
  fafafa.core.fs,
  fafafa.core.fs.path,
  fafafa.core.fs.highlevel;

{$IFDEF WINDOWS}
type
  TProcessMemoryCounters = record
    cb: DWORD;
    PageFaultCount: DWORD;
    PeakWorkingSetSize: SIZE_T;
    WorkingSetSize: SIZE_T;
    QuotaPeakPagedPoolUsage: SIZE_T;
    QuotaPagedPoolUsage: SIZE_T;
    QuotaPeakNonPagedPoolUsage: SIZE_T;
    QuotaNonPagedPoolUsage: SIZE_T;
    PagefileUsage: SIZE_T;
    PeakPagefileUsage: SIZE_T;
  end;

function GetProcessMemoryInfo(Process: THandle; var ppsmemCounters: TProcessMemoryCounters; cb: DWORD): BOOL; stdcall; external 'psapi.dll';
{$ENDIF}

const
  BENCHMARK_DIR = 'benchmark_test';
  ITERATIONS = 10000;
  SMALL_FILE_SIZE = 1024;        // 1KB
  MEDIUM_FILE_SIZE = 1024 * 1024; // 1MB
  LARGE_FILE_SIZE = 10 * 1024 * 1024; // 10MB

type
  TBenchmarkResult = record
    TestName: string;
    Iterations: Integer;
    TotalTimeUs: Int64;           // 改为微秒
    AvgTimeUs: Double;            // 改为微秒
    ThroughputMBps: Double;
    OperationsPerSec: Double;
    MemoryUsedMB: Double;         // 新增：内存使用
    MemoryLeakMB: Double;         // 新增：内存泄漏
  end;

var
  LResults: array of TBenchmarkResult;

// 内存使用监控函数
{$IFDEF WINDOWS}
function GetMemoryUsage: Int64;
var
  LMemInfo: TProcessMemoryCounters;
begin
  LMemInfo.cb := SizeOf(LMemInfo);
  if GetProcessMemoryInfo(GetCurrentProcess, LMemInfo, SizeOf(LMemInfo)) then
    Result := LMemInfo.WorkingSetSize
  else
    Result := 0;
end;
{$ELSE}
function GetMemoryUsage: Int64;
var
  LStatFile: TextFile;
  LLine: string;
  LPos: Integer;
  LValue: string;
begin
  Result := 0;
  try
    AssignFile(LStatFile, '/proc/self/status');
    Reset(LStatFile);
    while not Eof(LStatFile) do
    begin
      ReadLn(LStatFile, LLine);
      if Pos('VmRSS:', LLine) = 1 then
      begin
        LPos := Pos(':', LLine);
        if LPos > 0 then
        begin
          LValue := Trim(Copy(LLine, LPos + 1, Length(LLine)));
          LPos := Pos(' ', LValue);
          if LPos > 0 then
            LValue := Copy(LValue, 1, LPos - 1);
          Result := StrToInt64Def(LValue, 0) * 1024; // 转换为字节
        end;
        Break;
      end;
    end;
    CloseFile(LStatFile);
  except
    Result := 0;
  end;
end;
{$ENDIF}

// 高精度时间测量函数（微秒级精度）
function GetHighResolutionTime: Int64;
{$IFDEF WINDOWS}
var
  LFrequency, LCounter: Int64;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  if QueryPerformanceFrequency(LFrequency) then
  begin
    QueryPerformanceCounter(LCounter);
    Result := (LCounter * 1000000) div LFrequency; // 微秒精度
  end
  else
    Result := GetTickCount64 * 1000; // 降级到毫秒转微秒
  {$ELSE}
  var LTimeSpec: TTimeSpec;
  clock_gettime(CLOCK_MONOTONIC, @LTimeSpec);
  Result := LTimeSpec.tv_sec * 1000000 + LTimeSpec.tv_nsec div 1000; // 微秒精度
  {$ENDIF}
end;

procedure LogResult(const aResult: TBenchmarkResult);
begin
  Writeln(Format('%-30s | %8d | %8d μs | %8.1f μs | %8.2f MB/s | %10.0f ops/s | %6.1f MB | %6.2f MB',
    [aResult.TestName, aResult.Iterations, aResult.TotalTimeUs,
     aResult.AvgTimeUs, aResult.ThroughputMBps, aResult.OperationsPerSec,
     aResult.MemoryUsedMB, aResult.MemoryLeakMB]));
end;

// 优化的测试数据生成函数（块填充算法）
function CreateTestData(aSize: Integer): TBytes;
var
  LPattern: array[0..255] of Byte;
  I, LRemaining: Integer;
  LDest: PByte;
begin
  SetLength(Result, aSize);

  // 创建256字节模式
  for I := 0 to 255 do
    LPattern[I] := Byte(I);

  LDest := @Result[0];
  LRemaining := aSize;

  // 按256字节块快速填充
  while LRemaining >= 256 do
  begin
    Move(LPattern[0], LDest^, 256);
    Inc(LDest, 256);
    Dec(LRemaining, 256);
  end;

  // 填充剩余字节
  if LRemaining > 0 then
    Move(LPattern[0], LDest^, LRemaining);
end;

procedure Cleanup;
begin
  if DirectoryExists(BENCHMARK_DIR) then
  begin
    try
      DeleteDirectory(BENCHMARK_DIR, True);
    except
      // 忽略清理错误
    end;
  end;
end;

// 文件系统预热函数
procedure WarmupFileSystem;
var
  LWarmupFile: string;
  LWarmupData: TBytes;
  I: Integer;
begin
  Writeln('正在预热文件系统...');
  LWarmupFile := BENCHMARK_DIR + DirectorySeparator + 'warmup.dat';
  SetLength(LWarmupData, 1024 * 1024); // 1MB

  // 填充预热数据
  for I := 0 to High(LWarmupData) do
    LWarmupData[I] := Byte(I mod 256);

  // 执行几次读写操作预热
  for I := 1 to 3 do
  begin
    WriteBinaryFile(LWarmupFile, LWarmupData);
    LWarmupData := ReadBinaryFile(LWarmupFile);
    if FileExists(LWarmupFile) then
      DeleteFile(LWarmupFile);
  end;

  Writeln('预热完成。');
  Writeln('');
end;

function BenchmarkFileCreation(aFileSize: Integer; const aTestName: string): TBenchmarkResult;
var
  LStartTime, LEndTime: Int64;
  LStartMem, LEndMem: Int64;
  I: Integer;
  LTestData: TBytes;
  LFileNames: array of string;
begin
  Result.TestName := aTestName;
  Result.Iterations := ITERATIONS div 10; // 文件创建测试减少迭代次数

  // 预生成测试数据和文件名
  LTestData := CreateTestData(aFileSize);
  SetLength(LFileNames, Result.Iterations);
  for I := 0 to Result.Iterations - 1 do
    LFileNames[I] := BENCHMARK_DIR + DirectorySeparator + 'test_' + IntToStr(I) + '.dat';

  // 记录开始内存
  LStartMem := GetMemoryUsage;

  // 开始基准测试
  LStartTime := GetHighResolutionTime;
  for I := 0 to Result.Iterations - 1 do
  begin
    WriteBinaryFile(LFileNames[I], LTestData);
  end;
  LEndTime := GetHighResolutionTime;

  // 记录结束内存
  LEndMem := GetMemoryUsage;

  // 计算结果（微秒）
  Result.TotalTimeUs := LEndTime - LStartTime;
  Result.AvgTimeUs := Result.TotalTimeUs / Result.Iterations;
  Result.ThroughputMBps := (Result.Iterations * aFileSize / 1024.0 / 1024.0) / (Result.TotalTimeUs / 1000000.0);
  Result.OperationsPerSec := Result.Iterations / (Result.TotalTimeUs / 1000000.0);
  Result.MemoryUsedMB := LEndMem / 1024.0 / 1024.0;
  Result.MemoryLeakMB := (LEndMem - LStartMem) / 1024.0 / 1024.0;

  // 清理测试文件（在测试时间之外）
  for I := 0 to Result.Iterations - 1 do
  begin
    if FileExists(LFileNames[I]) then
      DeleteFile(LFileNames[I]);
  end;
end;

function BenchmarkFileReading(aFileSize: Integer; const aTestName: string): TBenchmarkResult;
var
  LStartTime, LEndTime: Int64;
  LStartMem, LEndMem: Int64;
  I: Integer;
  LTestData, LReadData: TBytes;
  LFileName: string;
begin
  Result.TestName := aTestName;
  Result.Iterations := ITERATIONS div 10;

  LTestData := CreateTestData(aFileSize);
  LFileName := BENCHMARK_DIR + DirectorySeparator + 'benchmark_read.dat';

  // 创建测试文件
  WriteBinaryFile(LFileName, LTestData);

  // 记录开始内存
  LStartMem := GetMemoryUsage;

  // 开始基准测试
  LStartTime := GetHighResolutionTime;
  for I := 1 to Result.Iterations do
  begin
    LReadData := ReadBinaryFile(LFileName);
  end;
  LEndTime := GetHighResolutionTime;

  // 记录结束内存
  LEndMem := GetMemoryUsage;

  // 计算结果（微秒）
  Result.TotalTimeUs := LEndTime - LStartTime;
  Result.AvgTimeUs := Result.TotalTimeUs / Result.Iterations;
  Result.ThroughputMBps := (Result.Iterations * aFileSize / 1024.0 / 1024.0) / (Result.TotalTimeUs / 1000000.0);
  Result.OperationsPerSec := Result.Iterations / (Result.TotalTimeUs / 1000000.0);
  Result.MemoryUsedMB := LEndMem / 1024.0 / 1024.0;
  Result.MemoryLeakMB := (LEndMem - LStartMem) / 1024.0 / 1024.0;

  // 清理
  if FileExists(LFileName) then
    DeleteFile(LFileName);
end;

function BenchmarkPathOperations(const aTestName: string): TBenchmarkResult;
var
  LStartTime, LEndTime: Int64;
  I: Integer;
  LPath, LResult: string;
begin
  Result.TestName := aTestName;
  Result.Iterations := ITERATIONS;

  LPath := 'C:\temp\..\users\.\documents\..\projects\.\fafafa\..\..\test\file.txt';

  LStartTime := GetHighResolutionTime;
  for I := 1 to Result.Iterations do
  begin
    LResult := NormalizePath(LPath);
  end;
  LEndTime := GetHighResolutionTime;

  Result.TotalTimeUs := LEndTime - LStartTime;
  Result.AvgTimeUs := Result.TotalTimeUs / Result.Iterations;
  Result.ThroughputMBps := 0; // 不适用
  Result.OperationsPerSec := Result.Iterations / (Result.TotalTimeUs / 1000000.0);
  Result.MemoryUsedMB := 0; // 不适用
  Result.MemoryLeakMB := 0; // 不适用
end;

function BenchmarkDirectoryScanning(const aTestName: string): TBenchmarkResult;
var
  LStartTime, LEndTime: Int64;
  I, J: Integer;
  LDirEntries: TStringList;
  LFileName: string;
  LTestData: TBytes;
begin
  Result.TestName := aTestName;
  Result.Iterations := 100; // 目录扫描测试减少迭代次数

  // 创建100个测试文件
  LTestData := CreateTestData(1024);
  for I := 1 to 100 do
  begin
    LFileName := BENCHMARK_DIR + DirectorySeparator + 'scan_test_' + IntToStr(I) + '.dat';
    WriteBinaryFile(LFileName, LTestData);
  end;

  LDirEntries := TStringList.Create;
  try
    LStartTime := GetHighResolutionTime;
    for I := 1 to Result.Iterations do
    begin
      fs_scandir(BENCHMARK_DIR, LDirEntries);
    end;
    LEndTime := GetHighResolutionTime;
  finally
    LDirEntries.Free;
  end;

  Result.TotalTimeUs := LEndTime - LStartTime;
  Result.AvgTimeUs := Result.TotalTimeUs / Result.Iterations;
  Result.ThroughputMBps := 0; // 不适用
  Result.OperationsPerSec := Result.Iterations / (Result.TotalTimeUs / 1000000.0);
  Result.MemoryUsedMB := 0; // 不适用
  Result.MemoryLeakMB := 0; // 不适用
  
  // 清理测试文件
  for I := 1 to 100 do
  begin
    LFileName := BENCHMARK_DIR + DirectorySeparator + 'scan_test_' + IntToStr(I) + '.dat';
    if FileExists(LFileName) then
      fs_unlink(LFileName);
  end;
end;

function BenchmarkStreamingIO(aFileSize: Integer; const aTestName: string): TBenchmarkResult;
var
  LStartTime, LEndTime: Int64;
  LFile: TFsFile;
  LBuffer: array[0..8191] of Byte; // 8KB buffer
  LBytesRead, LTotalBytes, I: Integer;
  LTestData: TBytes;
  LFileName: string;
begin
  Result.TestName := aTestName;
  Result.Iterations := 10; // 流式IO测试减少迭代次数

  LTestData := CreateTestData(aFileSize);
  LFileName := BENCHMARK_DIR + DirectorySeparator + 'streaming_test.dat';

  // 创建测试文件
  WriteBinaryFile(LFileName, LTestData);

  LStartTime := GetHighResolutionTime;
  for I := 1 to Result.Iterations do
  begin
    LFile := TFsFile.Create;
    try
      LFile.Open(LFileName, fomRead);
      LTotalBytes := 0;
      repeat
        LBytesRead := LFile.Read(LBuffer, SizeOf(LBuffer));
        Inc(LTotalBytes, LBytesRead);
      until LBytesRead = 0;
      LFile.Close;
    finally
      LFile.Free;
    end;
  end;
  LEndTime := GetHighResolutionTime;

  Result.TotalTimeUs := LEndTime - LStartTime;
  Result.AvgTimeUs := Result.TotalTimeUs / Result.Iterations;
  Result.ThroughputMBps := (Result.Iterations * aFileSize / 1024.0 / 1024.0) / (Result.TotalTimeUs / 1000000.0);
  Result.OperationsPerSec := Result.Iterations / (Result.TotalTimeUs / 1000000.0);
  Result.MemoryUsedMB := 0; // 不适用
  Result.MemoryLeakMB := 0; // 不适用

  // 清理
  if FileExists(LFileName) then
    DeleteFile(LFileName);
end;

begin
  Writeln('=== fafafa.core.fs Performance Benchmark (优化版) ===');
  Writeln('');

  Cleanup;
  CreateDirectory(BENCHMARK_DIR, False);

  // 预热文件系统
  WarmupFileSystem;

  Writeln(Format('%-30s | %8s | %8s | %8s | %8s | %10s | %6s | %6s',
    ['Test Name', 'Iters', 'Total μs', 'Avg μs', 'MB/s', 'Ops/sec', 'Mem MB', 'Leak MB']));
  Writeln(StringOfChar('-', 110));
  
  // 文件创建基准测试
  SetLength(LResults, Length(LResults) + 1);
  LResults[High(LResults)] := BenchmarkFileCreation(SMALL_FILE_SIZE, 'File Creation (1KB)');
  LogResult(LResults[High(LResults)]);
  
  SetLength(LResults, Length(LResults) + 1);
  LResults[High(LResults)] := BenchmarkFileCreation(MEDIUM_FILE_SIZE, 'File Creation (1MB)');
  LogResult(LResults[High(LResults)]);
  
  // 文件读取基准测试
  SetLength(LResults, Length(LResults) + 1);
  LResults[High(LResults)] := BenchmarkFileReading(SMALL_FILE_SIZE, 'File Reading (1KB)');
  LogResult(LResults[High(LResults)]);
  
  SetLength(LResults, Length(LResults) + 1);
  LResults[High(LResults)] := BenchmarkFileReading(MEDIUM_FILE_SIZE, 'File Reading (1MB)');
  LogResult(LResults[High(LResults)]);
  
  // 流式IO基准测试
  SetLength(LResults, Length(LResults) + 1);
  LResults[High(LResults)] := BenchmarkStreamingIO(LARGE_FILE_SIZE, 'Streaming IO (10MB)');
  LogResult(LResults[High(LResults)]);
  
  // 路径操作基准测试
  SetLength(LResults, Length(LResults) + 1);
  LResults[High(LResults)] := BenchmarkPathOperations('Path Normalization');
  LogResult(LResults[High(LResults)]);
  
  // 目录扫描基准测试
  SetLength(LResults, Length(LResults) + 1);
  LResults[High(LResults)] := BenchmarkDirectoryScanning('Directory Scanning');
  LogResult(LResults[High(LResults)]);
  
  Writeln('');
  Writeln('Benchmark completed. Results saved for optimization analysis.');
  
  Cleanup;
end.
