program example_performance_benchmark;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  SysUtils, Classes, DateUtils,
  fafafa.core.base,
  fafafa.core.socket;

{**
 * Socket性能基准测试套件
 * 
 * 本程序测试各种Socket操作的性能：
 * 1. 传统TBytes vs 零拷贝指针操作
 * 2. 单次发送 vs 批量发送
 * 3. 缓冲区池 vs 动态分配
 * 4. 向量化I/O性能
 * 5. 不同缓冲区大小的影响
 *}

type
  TBenchmarkResult = record
    TestName: string;
    TotalBytes: Int64;
    ElapsedMs: Int64;
    ThroughputMBps: Double;
    OperationsPerSec: Double;
  end;

var
  GResults: array of TBenchmarkResult;

procedure AddResult(const ATestName: string; ATotalBytes, AElapsedMs: Int64; AOperations: Integer);
var
  LResult: TBenchmarkResult;
begin
  LResult.TestName := ATestName;
  LResult.TotalBytes := ATotalBytes;
  LResult.ElapsedMs := AElapsedMs;
  LResult.ThroughputMBps := (ATotalBytes / 1024 / 1024) / (AElapsedMs / 1000);
  LResult.OperationsPerSec := AOperations / (AElapsedMs / 1000);
  
  SetLength(GResults, Length(GResults) + 1);
  GResults[High(GResults)] := LResult;
end;

procedure PrintResults;
var
  I: Integer;
begin
  WriteLn('');
  WriteLn('性能基准测试结果');
  WriteLn('=====================================');
  WriteLn('测试名称                    | 吞吐量(MB/s) | 操作/秒    | 耗时(ms)');
  WriteLn('------------------------------------------------------------------');
  
  for I := 0 to High(GResults) do
  begin
    with GResults[I] do
      WriteLn(Format('%-26s | %10.2f | %10.0f | %8d', 
        [TestName, ThroughputMBps, OperationsPerSec, ElapsedMs]));
  end;
  WriteLn('------------------------------------------------------------------');
end;

function CreateTestEnvironment(APort: Word; out AServer, AClient: ISocket; out AListener: ISocketListener): Boolean;
begin
  Result := False;
  try
    // 创建服务器
    AListener := TSocketListener.ListenTCP(APort);
    AListener.Start;
    
    // 创建客户端
    AClient := TSocket.CreateTCP;
    AClient.Connect(TSocketAddress.Localhost(APort));
    
    // 接受连接
    AServer := AListener.AcceptClient;
    
    // 优化设置
    AClient.TcpNoDelay := True;
    AServer.TcpNoDelay := True;
    AClient.SetSendBufferSize(256 * 1024);
    AServer.SetReceiveBufferSize(256 * 1024);
    
    Result := True;
  except
    on E: Exception do
      WriteLn('创建测试环境失败: ', E.Message);
  end;
end;

procedure BenchmarkTraditionalTBytes;
const
  ITERATIONS = 1000;
  PACKET_SIZE = 8192;
var
  LServer, LClient: ISocket;
  LListener: ISocketListener;
  LData: TBytes;
  LStartTime: TDateTime;
  I: Integer;
begin
  WriteLn('测试: 传统TBytes操作...');
  
  if not CreateTestEnvironment(8001, LServer, LClient, LListener) then Exit;
  
  try
    SetLength(LData, PACKET_SIZE);
    FillChar(LData[0], PACKET_SIZE, $AA);
    
    LStartTime := Now;
    
    for I := 1 to ITERATIONS do
    begin
      LClient.Send(LData);
      LServer.Receive(PACKET_SIZE);
    end;
    
    AddResult('传统TBytes操作', 
      Int64(PACKET_SIZE) * ITERATIONS, 
      MilliSecondsBetween(Now, LStartTime),
      ITERATIONS);
      
  finally
    LListener.Stop;
  end;
end;

procedure BenchmarkZeroCopyPointer;
const
  ITERATIONS = 1000;
  PACKET_SIZE = 8192;
var
  LServer, LClient: ISocket;
  LListener: ISocketListener;
  LBuffer: array[0..PACKET_SIZE-1] of Byte;
  LStartTime: TDateTime;
  I: Integer;
begin
  WriteLn('测试: 零拷贝指针操作...');
  
  if not CreateTestEnvironment(8002, LServer, LClient, LListener) then Exit;
  
  try
    FillChar(LBuffer, PACKET_SIZE, $BB);
    
    LStartTime := Now;
    
    for I := 1 to ITERATIONS do
    begin
      LClient.Send(@LBuffer[0], PACKET_SIZE);
      LServer.Receive(@LBuffer[0], PACKET_SIZE);
    end;
    
    AddResult('零拷贝指针操作', 
      Int64(PACKET_SIZE) * ITERATIONS, 
      MilliSecondsBetween(Now, LStartTime),
      ITERATIONS);
      
  finally
    LListener.Stop;
  end;
end;

procedure BenchmarkBufferPool;
const
  ITERATIONS = 1000;
  PACKET_SIZE = 8192;
var
  LServer, LClient: ISocket;
  LListener: ISocketListener;
  LPool: TSocketBufferPool;
  LBuffer: TSocketBuffer;
  LData: array[0..PACKET_SIZE-1] of Byte;
  LStartTime: TDateTime;
  I: Integer;
begin
  WriteLn('测试: 缓冲区池操作...');
  
  if not CreateTestEnvironment(8003, LServer, LClient, LListener) then Exit;
  
  try
    LPool := TSocketBufferPool.Create(PACKET_SIZE, 16);
    try
      FillChar(LData, PACKET_SIZE, $CC);
      
      LStartTime := Now;
      
      for I := 1 to ITERATIONS do
      begin
        LClient.SendWithPool(@LData[0], PACKET_SIZE, LPool);
        LBuffer := LServer.ReceiveWithPool(PACKET_SIZE, LPool);
        LPool.Release(LBuffer);
      end;
      
      AddResult('缓冲区池操作', 
        Int64(PACKET_SIZE) * ITERATIONS, 
        MilliSecondsBetween(Now, LStartTime),
        ITERATIONS);
        
    finally
      LPool.Free;
    end;
  finally
    LListener.Stop;
  end;
end;

procedure BenchmarkVectorizedIO;
const
  ITERATIONS = 500;
  VECTOR_COUNT = 4;
  VECTOR_SIZE = 2048;
var
  LServer, LClient: ISocket;
  LListener: ISocketListener;
  LVectors: TIOVectorArray;
  LBuffers: array[0..VECTOR_COUNT-1] of array[0..VECTOR_SIZE-1] of Byte;
  LStartTime: TDateTime;
  I, J: Integer;
begin
  WriteLn('测试: 向量化I/O操作...');
  
  if not CreateTestEnvironment(8004, LServer, LClient, LListener) then Exit;
  
  try
    // 准备向量
    SetLength(LVectors, VECTOR_COUNT);
    for I := 0 to VECTOR_COUNT - 1 do
    begin
      FillChar(LBuffers[I], VECTOR_SIZE, $DD + I);
      LVectors[I].Data := @LBuffers[I][0];
      LVectors[I].Size := VECTOR_SIZE;
    end;
    
    LStartTime := Now;
    
    for I := 1 to ITERATIONS do
    begin
      LClient.SendVectorized(LVectors);
      LServer.ReceiveVectorized(LVectors);
    end;
    
    AddResult('向量化I/O操作', 
      Int64(VECTOR_COUNT * VECTOR_SIZE) * ITERATIONS, 
      MilliSecondsBetween(Now, LStartTime),
      ITERATIONS);
      
  finally
    LListener.Stop;
  end;
end;

procedure BenchmarkBufferSizes;
const
  ITERATIONS = 200;
  SIZES: array[0..4] of Integer = (1024, 4096, 16384, 65536, 262144);
var
  LServer, LClient: ISocket;
  LListener: ISocketListener;
  LBuffer: Pointer;
  LStartTime: TDateTime;
  I, J, LSize: Integer;
begin
  WriteLn('测试: 不同缓冲区大小...');
  
  for I := 0 to High(SIZES) do
  begin
    LSize := SIZES[I];
    
    if not CreateTestEnvironment(8005 + I, LServer, LClient, LListener) then Continue;
    
    try
      GetMem(LBuffer, LSize);
      try
        FillChar(LBuffer^, LSize, $EE);
        
        LStartTime := Now;
        
        for J := 1 to ITERATIONS do
        begin
          LClient.Send(LBuffer, LSize);
          LServer.Receive(LBuffer, LSize);
        end;
        
        AddResult(Format('缓冲区%dKB', [LSize div 1024]), 
          Int64(LSize) * ITERATIONS, 
          MilliSecondsBetween(Now, LStartTime),
          ITERATIONS);
          
      finally
        FreeMem(LBuffer);
      end;
    finally
      LListener.Stop;
    end;
  end;
end;

begin
  WriteLn('fafafa.core.socket 性能基准测试');
  WriteLn('=====================================');
  WriteLn('');
  
  try
    BenchmarkTraditionalTBytes;
    BenchmarkZeroCopyPointer;
    BenchmarkBufferPool;
    BenchmarkVectorizedIO;
    BenchmarkBufferSizes;
    
    PrintResults;
    
    WriteLn('');
    WriteLn('测试完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
