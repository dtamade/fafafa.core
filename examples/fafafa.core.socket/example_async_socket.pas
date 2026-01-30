program example_async_socket;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.socket,
  fafafa.core.socket.async,
  fafafa.core.async.runtime;

{**
 * 异步Socket示例
 * 
 * 本示例展示如何使用异步Socket进行网络编程：
 * 1. 异步客户端连接和数据传输
 * 2. 异步服务器接受连接和处理数据
 * 3. 高性能异步操作（缓冲区池、向量化I/O）
 * 4. 事件驱动的异步编程模式
 *}

procedure AsyncClientExample;
var
  LClient: IAsyncSocket;
  LConnectResult: specialize IAsyncResult<Boolean>;
  LSendResult: specialize IAsyncResult<Integer>;
  LReceiveResult: specialize IAsyncResult<TBytes>;
  LData: TBytes;
  LResponse: TBytes;
begin
  WriteLn('=== 异步客户端示例 ===');
  
  try
    // 创建异步TCP客户端
    LClient := TAsyncSocket.CreateTCP;
    WriteLn('异步客户端已创建');
    
    // 设置事件回调
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    LClient.OnConnected(procedure(AConnected: Boolean)
      begin
        if AConnected then
          WriteLn('✓ 连接成功回调触发')
        else
          WriteLn('✗ 连接失败回调触发');
      end);
      
    LClient.OnDataReceived(procedure(const AData: TBytes)
      begin
        WriteLn('✓ 数据接收回调触发，收到 ', Length(AData), ' 字节');
      end);
      
    LClient.OnError(procedure(AError: Exception)
      begin
        WriteLn('✗ 错误回调触发: ', AError.Message);
      end);
    {$ENDIF}
    
    // 异步连接到本地服务器
    WriteLn('开始异步连接...');
    LConnectResult := LClient.ConnectAsync(TSocketAddress.Localhost(8080), 5000);
    
    // 等待连接完成
    if LConnectResult.WaitFor(10000) then
    begin
      if LConnectResult.IsCompleted and not LConnectResult.HasError then
      begin
        WriteLn('✓ 异步连接成功');
        
        // 准备发送数据
        LData := TEncoding.UTF8.GetBytes('Hello from async client!' + #13#10);
        
        // 异步发送数据
        WriteLn('开始异步发送数据...');
        LSendResult := LClient.SendAsync(LData);
        
        if LSendResult.WaitFor(5000) then
        begin
          WriteLn('✓ 异步发送完成，发送了 ', LSendResult.GetResult, ' 字节');
          
          // 异步接收响应
          WriteLn('开始异步接收响应...');
          LReceiveResult := LClient.ReceiveAsync(1024);
          
          if LReceiveResult.WaitFor(5000) then
          begin
            LResponse := LReceiveResult.GetResult;
            WriteLn('✓ 异步接收完成，收到: ', TEncoding.UTF8.GetString(LResponse));
          end
          else
            WriteLn('✗ 接收超时');
        end
        else
          WriteLn('✗ 发送超时');
      end
      else
        WriteLn('✗ 连接失败: ', LConnectResult.GetError.Message);
    end
    else
      WriteLn('✗ 连接超时');
      
  except
    on E: Exception do
      WriteLn('客户端异常: ', E.Message);
  end;
  
  WriteLn('');
end;

procedure AsyncHighPerformanceExample;
var
  LClient: IAsyncSocket;
  LBuffer: TSocketBuffer;
  LVectors: TIOVectorArray;
  LData1, LData2: array[0..1023] of Byte;
  LConnectResult: specialize IAsyncResult<Boolean>;
  LSendResult: specialize IAsyncResult<Integer>;
  LReceiveResult: specialize IAsyncResult<Integer>;
begin
  WriteLn('=== 异步高性能操作示例 ===');
  
  try
    LClient := TAsyncSocket.CreateTCP;
    
    // 连接到服务器
    LConnectResult := LClient.ConnectAsync(TSocketAddress.Localhost(8080));
    if not (LConnectResult.WaitFor(5000) and LConnectResult.GetResult) then
    begin
      WriteLn('✗ 无法连接到服务器');
      Exit;
    end;
    
    WriteLn('✓ 连接成功，开始高性能操作测试');
    
    // 1. 缓冲区操作
    WriteLn('测试异步缓冲区操作...');
    LBuffer := TSocketBuffer.Create(2048);
    try
      FillChar(LBuffer.Data^, LBuffer.Capacity, $AA);
      LBuffer.FSize := 1024;
      
      LSendResult := LClient.SendBufferAsync(LBuffer);
      if LSendResult.WaitFor(3000) then
        WriteLn('✓ 异步缓冲区发送完成: ', LSendResult.GetResult, ' 字节')
      else
        WriteLn('✗ 异步缓冲区发送超时');
        
    finally
      LBuffer.Free;
    end;
    
    // 2. 向量化I/O操作
    WriteLn('测试异步向量化I/O...');
    FillChar(LData1, SizeOf(LData1), $BB);
    FillChar(LData2, SizeOf(LData2), $CC);
    
    SetLength(LVectors, 2);
    LVectors[0].Data := @LData1[0];
    LVectors[0].Size := SizeOf(LData1);
    LVectors[1].Data := @LData2[0];
    LVectors[1].Size := SizeOf(LData2);
    
    LSendResult := LClient.SendVectorizedAsync(LVectors);
    if LSendResult.WaitFor(3000) then
      WriteLn('✓ 异步向量化发送完成: ', LSendResult.GetResult, ' 字节')
    else
      WriteLn('✗ 异步向量化发送超时');
      
  except
    on E: Exception do
      WriteLn('高性能操作异常: ', E.Message);
  end;
  
  WriteLn('');
end;

procedure AsyncBatchOperationsExample;
var
  LClient: IAsyncSocket;
  LConnectResult: specialize IAsyncResult<Boolean>;
  LSendResult: specialize IAsyncResult<Integer>;
  LReceiveResult: specialize IAsyncResult<TBytes>;
  LLargeData: TBytes;
  I: Integer;
begin
  WriteLn('=== 异步批量操作示例 ===');
  
  try
    LClient := TAsyncSocket.CreateTCP;
    
    // 连接
    LConnectResult := LClient.ConnectAsync(TSocketAddress.Localhost(8080));
    if not (LConnectResult.WaitFor(5000) and LConnectResult.GetResult) then
    begin
      WriteLn('✗ 无法连接到服务器');
      Exit;
    end;
    
    // 准备大量数据
    SetLength(LLargeData, 64 * 1024); // 64KB
    for I := 0 to High(LLargeData) do
      LLargeData[I] := Byte(I mod 256);
      
    WriteLn('准备发送 ', Length(LLargeData), ' 字节数据...');
    
    // 异步发送所有数据
    LSendResult := LClient.SendAllAsync(LLargeData);
    if LSendResult.WaitFor(10000) then
      WriteLn('✓ 异步批量发送完成: ', LSendResult.GetResult, ' 字节')
    else
      WriteLn('✗ 异步批量发送超时');
      
    // 异步接收精确数量的数据
    WriteLn('开始接收精确数量的数据...');
    LReceiveResult := LClient.ReceiveExactAsync(1024);
    if LReceiveResult.WaitFor(5000) then
    begin
      var LReceivedData := LReceiveResult.GetResult;
      WriteLn('✓ 异步精确接收完成: ', Length(LReceivedData), ' 字节');
    end
    else
      WriteLn('✗ 异步精确接收超时');
      
  except
    on E: Exception do
      WriteLn('批量操作异常: ', E.Message);
  end;
  
  WriteLn('');
end;

procedure StartTestServer;
var
  LListener: ISocketListener;
  LClient: ISocket;
  LData: TBytes;
begin
  WriteLn('启动测试服务器...');
  
  try
    LListener := TSocketListener.ListenTCP(8080);
    LListener.Start;
    WriteLn('✓ 测试服务器启动在端口 8080');
    
    // 简单的回显服务器
    while True do
    begin
      try
        LClient := LListener.AcceptClient(1000);
        if Assigned(LClient) then
        begin
          WriteLn('接受客户端连接: ', LClient.RemoteAddress.ToString);
          
          // 接收数据并回显
          LData := LClient.Receive(65536);
          if Length(LData) > 0 then
          begin
            WriteLn('收到数据: ', Length(LData), ' 字节');
            LClient.Send(LData); // 回显
          end;
          
          LClient.Close;
        end;
      except
        on E: Exception do
          if not (E is ESocketTimeout) then
            WriteLn('服务器错误: ', E.Message);
      end;
    end;
    
  except
    on E: Exception do
      WriteLn('服务器启动失败: ', E.Message);
  end;
end;

begin
  WriteLn('fafafa.core.socket 异步Socket示例');
  WriteLn('=====================================');
  WriteLn('');
  
  try
    // 初始化异步运行时
    TAsyncRuntime.Initialize;
    
    WriteLn('请先在另一个终端运行测试服务器，然后按回车继续...');
    ReadLn;
    
    AsyncClientExample;
    AsyncHighPerformanceExample;
    AsyncBatchOperationsExample;
    
    WriteLn('所有异步操作示例完成！');
    
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
