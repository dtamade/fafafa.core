{$CODEPAGE UTF8}
unit Test_memory_performance;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry, fafafa.core.mem.memoryMap;

type
  TTestCase_MemoryPerformance = class(TTestCase)
  private
    function MakeTempFile(const prefix, suffix: string): string;
    function GetTickCount64: QWord;
  published
    procedure Test_FileMapping_Flush_Performance;
    procedure Test_LPBytes_ReadWrite_Performance;
    procedure Test_SharedMemory_Performance;
  end;

implementation

function TTestCase_MemoryPerformance.MakeTempFile(const prefix, suffix: string): string;
begin
  Result := GetTempDir + prefix + IntToHex(Random(MaxInt), 8) + suffix;
end;

function TTestCase_MemoryPerformance.GetTickCount64: QWord;
begin
  Result := GetTickCount;
end;

procedure TTestCase_MemoryPerformance.Test_FileMapping_Flush_Performance;
var
  filePath: string;
  mm: TMemoryMap;
  startTime, endTime: QWord;
  i: Integer;
  flushTime, flushRangeTime: QWord;
const
  ITERATIONS = 100;
  FILE_SIZE = 1024 * 1024; // 1MB
begin
  filePath := MakeTempFile('perf_flush_', '.dat');
  try
    // 创建测试文件
    with TFileStream.Create(filePath, fmCreate) do
    try
      Size := FILE_SIZE;
    finally
      Free;
    end;

    mm := TMemoryMap.Create;
    try
      AssertTrue('OpenFile should succeed', mm.OpenFile(filePath, mmaReadWrite));
      
      // 写入一些数据
      FillChar(mm.BaseAddress^, FILE_SIZE, $42);
      
      // 测试 Flush 性能
      startTime := GetTickCount64;
      for i := 1 to ITERATIONS do
        mm.Flush();
      endTime := GetTickCount64;
      flushTime := endTime - startTime;
      
      // 测试 FlushRange 性能
      startTime := GetTickCount64;
      for i := 1 to ITERATIONS do
        mm.FlushRange(0, 4096); // 刷新前4KB
      endTime := GetTickCount64;
      flushRangeTime := endTime - startTime;
      
      WriteLn(Format('Flush Performance: Full=%dms, Range=%dms (iterations=%d)', 
        [flushTime, flushRangeTime, ITERATIONS]));
      
      // 基本性能检查：FlushRange 应该比 Flush 快（或至少不慢太多）
      AssertTrue('FlushRange should not be significantly slower than Flush', 
        flushRangeTime <= flushTime * 2);
        
    finally
      mm.Free;
    end;
  finally
    if FileExists(filePath) then DeleteFile(filePath);
  end;
end;

procedure TTestCase_MemoryPerformance.Test_LPBytes_ReadWrite_Performance;
var
  mm: TMemoryMap;
  startTime, endTime: QWord;
  i: Integer;
  data, readData: RawByteString;
  writeTime, readTime: QWord;
const
  ITERATIONS = 1000;
  DATA_SIZE = 1024; // 1KB per operation
begin
  // 准备测试数据
  SetLength(data, DATA_SIZE);
  FillChar(data[1], DATA_SIZE, $55);
  
  mm := TMemoryMap.Create;
  try
    AssertTrue('CreateAnonymous should succeed', 
      mm.CreateAnonymous(ITERATIONS * (4 + DATA_SIZE), mmaReadWrite));
    
    // 测试写入性能
    startTime := GetTickCount64;
    for i := 0 to ITERATIONS - 1 do
      mm.WriteLPBytes(i * (4 + DATA_SIZE), data);
    endTime := GetTickCount64;
    writeTime := endTime - startTime;
    
    // 测试读取性能
    startTime := GetTickCount64;
    for i := 0 to ITERATIONS - 1 do
      mm.ReadLPBytes(i * (4 + DATA_SIZE), readData);
    endTime := GetTickCount64;
    readTime := endTime - startTime;
    
    WriteLn(Format('LPBytes Performance: Write=%dms, Read=%dms (iterations=%d, size=%dB)', 
      [writeTime, readTime, ITERATIONS, DATA_SIZE]));
    
    // 基本性能检查：读写都应该在合理时间内完成（放宽限制，主要用于回归检测）
    AssertTrue('Write performance should be reasonable', writeTime < 60000); // 60秒内
    AssertTrue('Read performance should be reasonable', readTime < 60000);   // 60秒内
    
  finally
    mm.Free;
  end;
end;

procedure TTestCase_MemoryPerformance.Test_SharedMemory_Performance;
var
  sm: TSharedMemory;
  startTime, endTime: QWord;
  i: Integer;
  data: RawByteString;
  createTime, writeTime: QWord;
  name: string;
const
  ITERATIONS = 100;
  DATA_SIZE = 512;
begin
  name := 'PerfTest_' + IntToHex(Random(MaxInt), 8);
  SetLength(data, DATA_SIZE);
  FillChar(data[1], DATA_SIZE, $66);
  
  sm := TSharedMemory.Create;
  try
    // 测试创建性能
    startTime := GetTickCount64;
    AssertTrue('CreateShared should succeed', 
      sm.CreateShared(name, ITERATIONS * (4 + DATA_SIZE), mmaReadWrite));
    endTime := GetTickCount64;
    createTime := endTime - startTime;
    
    // 测试写入性能
    startTime := GetTickCount64;
    for i := 0 to ITERATIONS - 1 do
      sm.WriteLPBytes(i * (4 + DATA_SIZE), data);
    endTime := GetTickCount64;
    writeTime := endTime - startTime;
    
    WriteLn(Format('SharedMemory Performance: Create=%dms, Write=%dms (iterations=%d)', 
      [createTime, writeTime, ITERATIONS]));
    
    // 基本性能检查（放宽限制，主要用于回归检测）
    AssertTrue('Create performance should be reasonable', createTime < 30000); // 30秒内
    AssertTrue('Write performance should be reasonable', writeTime < 30000);   // 30秒内
    
  finally
    sm.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_MemoryPerformance);

end.
