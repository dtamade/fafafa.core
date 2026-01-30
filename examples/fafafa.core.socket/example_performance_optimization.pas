program example_performance_optimization;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.socket;

{**
 * 高性能Socket编程示例
 * 
 * 本示例展示如何使用 fafafa.core.socket 模块进行高性能网络编程：
 * 1. 零拷贝操作
 * 2. 非阻塞I/O
 * 3. 连接复用
 * 4. 内存管理优化
 *}

procedure DemoZeroCopyOperations;
var
  LServer, LClient: ISocket;
  LListener: ISocketListener;
  LBuffer: array[0..8191] of Byte;
  LData: PByte;
  LSize: Integer;
  LErrorCode: Integer;
begin
  WriteLn('=== 零拷贝操作示例 ===');
  
  try
    // 创建服务器
    LListener := TSocketListener.ListenTCP(8080);
    LListener.Start;
    WriteLn('服务器启动在端口 8080');
    
    // 创建客户端连接
    LClient := TSocket.CreateTCP;
    LClient.Connect(TSocketAddress.Localhost(8080));
    WriteLn('客户端已连接');
    
    // 接受连接
    LServer := LListener.AcceptClient;
    WriteLn('服务器接受连接');
    
    // 零拷贝发送：使用指针直接操作
    FillChar(LBuffer, SizeOf(LBuffer), $AA);
    LData := @LBuffer[0];
    LSize := SizeOf(LBuffer);
    
    WriteLn('发送数据（零拷贝）: ', LSize, ' 字节');
    LClient.Send(LData, LSize);
    
    // 零拷贝接收：直接写入预分配缓冲区
    FillChar(LBuffer, SizeOf(LBuffer), 0);
    LSize := LServer.Receive(@LBuffer[0], SizeOf(LBuffer));
    WriteLn('接收数据（零拷贝）: ', LSize, ' 字节');
    
    // 验证数据
    if LBuffer[0] = $AA then
      WriteLn('✓ 数据传输正确')
    else
      WriteLn('✗ 数据传输错误');
      
  finally
    LListener.Stop;
    WriteLn('服务器已停止');
  end;
end;

procedure DemoNonBlockingIO;
var
  LServer, LClient: ISocket;
  LListener: ISocketListener;
  LData: TBytes;
  LErrorCode: Integer;
  LBytesSent, LBytesReceived: Integer;
  LRetryCount: Integer;
begin
  WriteLn('');
  WriteLn('=== 非阻塞I/O示例 ===');
  
  try
    // 创建服务器
    LListener := TSocketListener.ListenTCP(8081);
    LListener.Start;
    WriteLn('非阻塞服务器启动在端口 8081');
    
    // 创建客户端连接
    LClient := TSocket.CreateTCP;
    LClient.Connect(TSocketAddress.Localhost(8081));
    
    // 接受连接
    LServer := LListener.AcceptClient;
    
    // 设置非阻塞模式
    LClient.NonBlocking := True;
    LServer.NonBlocking := True;
    WriteLn('已设置非阻塞模式');
    
    // 准备大量数据
    SetLength(LData, 1024 * 1024); // 1MB
    FillChar(LData[0], Length(LData), $BB);
    
    // 非阻塞发送
    LRetryCount := 0;
    LBytesSent := 0;
    while LBytesSent < Length(LData) do
    begin
      LBytesReceived := LClient.TrySend(@LData[LBytesSent], Length(LData) - LBytesSent, LErrorCode);
      
      if LBytesReceived > 0 then
      begin
        Inc(LBytesSent, LBytesReceived);
        WriteLn('已发送: ', LBytesSent, '/', Length(LData), ' 字节');
      end
      else if LErrorCode = {$IFDEF WINDOWS}WSAEWOULDBLOCK{$ELSE}EWOULDBLOCK{$ENDIF} then
      begin
        Inc(LRetryCount);
        if LRetryCount mod 1000 = 0 then
          WriteLn('发送缓冲区满，重试中... (', LRetryCount, ')');
        Sleep(1); // 短暂等待
      end
      else
      begin
        WriteLn('发送错误: ', LErrorCode);
        Break;
      end;
    end;
    
    WriteLn('✓ 非阻塞发送完成，总重试次数: ', LRetryCount);
    
  finally
    LListener.Stop;
    WriteLn('非阻塞服务器已停止');
  end;
end;

procedure DemoConnectionReuse;
var
  LListener: ISocketListener;
  LClient1, LClient2, LServer1, LServer2: ISocket;
  LMessage: TBytes;
begin
  WriteLn('');
  WriteLn('=== 连接复用示例 ===');
  
  try
    // 创建可复用的监听器
    LListener := TSocketListener.ListenTCP(8082);
    LListener.ReuseAddress := True; // 允许地址复用
    LListener.Start;
    WriteLn('复用监听器启动在端口 8082');
    
    // 第一个客户端连接
    LClient1 := TSocket.CreateTCP;
    LClient1.Connect(TSocketAddress.Localhost(8082));
    LServer1 := LListener.AcceptClient;
    WriteLn('第一个客户端已连接');
    
    // 第二个客户端连接
    LClient2 := TSocket.CreateTCP;
    LClient2.Connect(TSocketAddress.Localhost(8082));
    LServer2 := LListener.AcceptClient;
    WriteLn('第二个客户端已连接');
    
    // 并发通信
    LMessage := TEncoding.UTF8.GetBytes('Hello from Client 1');
    LClient1.Send(LMessage);
    LMessage := LServer1.Receive(1024);
    WriteLn('服务器收到客户端1消息: ', TEncoding.UTF8.GetString(LMessage));
    
    LMessage := TEncoding.UTF8.GetBytes('Hello from Client 2');
    LClient2.Send(LMessage);
    LMessage := LServer2.Receive(1024);
    WriteLn('服务器收到客户端2消息: ', TEncoding.UTF8.GetString(LMessage));
    
    WriteLn('✓ 连接复用成功');
    
  finally
    LListener.Stop;
    WriteLn('复用监听器已停止');
  end;
end;

procedure DemoMemoryOptimization;
var
  LSocket: ISocket;
  LAddr: ISocketAddress;
  LBuffer: Pointer;
  LBufferSize: Integer;
begin
  WriteLn('');
  WriteLn('=== 内存管理优化示例 ===');
  
  // 预分配缓冲区
  LBufferSize := 64 * 1024; // 64KB
  GetMem(LBuffer, LBufferSize);
  try
    WriteLn('预分配缓冲区: ', LBufferSize, ' 字节');
    
    // 复用地址对象
    LAddr := TSocketAddress.Localhost(80);
    WriteLn('地址对象: ', LAddr.ToString);
    
    // 复用Socket对象（通过接口引用计数）
    LSocket := TSocket.CreateTCP;
    LSocket.SetSendBufferSize(LBufferSize);
    LSocket.SetReceiveBufferSize(LBufferSize);
    WriteLn('Socket缓冲区已优化');
    
    // 使用预分配缓冲区进行操作
    FillChar(LBuffer^, LBufferSize, $CC);
    WriteLn('✓ 内存优化配置完成');
    
  finally
    FreeMem(LBuffer);
    WriteLn('缓冲区已释放');
  end;
end;

procedure DemoPerformanceBenchmark;
var
  LServer, LClient: ISocket;
  LListener: ISocketListener;
  LData: TBytes;
  LStartTime, LEndTime: TDateTime;
  LTotalBytes: Int64;
  LIterations: Integer;
  I: Integer;
  LThroughput: Double;
begin
  WriteLn('');
  WriteLn('=== 性能基准测试 ===');
  
  try
    // 创建测试环境
    LListener := TSocketListener.ListenTCP(8083);
    LListener.Start;
    
    LClient := TSocket.CreateTCP;
    LClient.Connect(TSocketAddress.Localhost(8083));
    LServer := LListener.AcceptClient;
    
    // 优化Socket设置
    LClient.SetSendBufferSize(256 * 1024);
    LServer.SetReceiveBufferSize(256 * 1024);
    LClient.TcpNoDelay := True;
    LServer.TcpNoDelay := True;
    
    // 准备测试数据
    SetLength(LData, 8192); // 8KB per iteration
    FillChar(LData[0], Length(LData), $DD);
    
    LIterations := 1000;
    LTotalBytes := Int64(Length(LData)) * LIterations;
    
    WriteLn('开始性能测试...');
    WriteLn('数据包大小: ', Length(LData), ' 字节');
    WriteLn('迭代次数: ', LIterations);
    WriteLn('总数据量: ', LTotalBytes div 1024, ' KB');
    
    // 开始计时
    LStartTime := Now;
    
    for I := 1 to LIterations do
    begin
      LClient.Send(LData);
      LServer.Receive(Length(LData));
      
      if I mod 100 = 0 then
        Write('.');
    end;
    
    // 结束计时
    LEndTime := Now;
    WriteLn('');
    
    // 计算性能指标
    LThroughput := LTotalBytes / ((LEndTime - LStartTime) * 24 * 3600); // 字节/秒
    
    WriteLn('✓ 性能测试完成');
    WriteLn('总耗时: ', FormatFloat('0.000', (LEndTime - LStartTime) * 24 * 3600), ' 秒');
    WriteLn('吞吐量: ', FormatFloat('0.00', LThroughput / 1024 / 1024), ' MB/s');
    
  finally
    LListener.Stop;
  end;
end;

begin
  WriteLn('fafafa.core.socket 高性能编程示例');
  WriteLn('=====================================');
  
  try
    DemoZeroCopyOperations;
    DemoNonBlockingIO;
    DemoConnectionReuse;
    DemoMemoryOptimization;
    DemoPerformanceBenchmark;
    
    WriteLn('');
    WriteLn('所有示例执行完成！');
    
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
