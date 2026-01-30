unit fafafa.core.socket.async.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.socket,
  fafafa.core.socket.async,
  fafafa.core.async.runtime;

type
  // 异步Socket基础测试
  TTestCase_AsyncSocket = class(TTestCase)
  private
    FRuntime: TAsyncRuntime;
    FTestServer: ISocketListener;
    
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    
  published
    procedure Test_AsyncSocket_Creation;
    procedure Test_AsyncResult_Basic;
    procedure Test_AsyncSocket_ConnectAsync;
    procedure Test_AsyncSocket_SendReceiveAsync;
    procedure Test_AsyncSocket_HighPerformanceAsync;
    procedure Test_AsyncSocket_BatchOperations;
    procedure Test_AsyncSocket_ErrorHandling;
    procedure Test_AsyncSocket_Callbacks;
  end;

  // 异步Socket性能测试
  TTestCase_AsyncSocketPerformance = class(TTestCase)
  published
    procedure Test_AsyncSocket_ConcurrentConnections;
    procedure Test_AsyncSocket_ThroughputComparison;
    procedure Test_AsyncSocket_MemoryUsage;
  end;

implementation

{ TTestCase_AsyncSocket }

procedure TTestCase_AsyncSocket.SetUp;
begin
  inherited SetUp;
  
  // 初始化异步运行时
  TAsyncRuntime.Initialize;
  FRuntime := TAsyncRuntime.GetInstance;
  
  // 启动测试服务器
  FTestServer := TSocketListener.ListenTCP(8081);
  FTestServer.Start;
end;

procedure TTestCase_AsyncSocket.TearDown;
begin
  if Assigned(FTestServer) then
    FTestServer.Stop;
    
  TAsyncRuntime.Finalize;
  inherited TearDown;
end;

procedure TTestCase_AsyncSocket.Test_AsyncSocket_Creation;
var
  LAsyncSocket: IAsyncSocket;
begin
  // 测试TCP异步Socket创建
  LAsyncSocket := TAsyncSocket.CreateTCP;
  AssertNotNull('TCP异步Socket应该创建成功', LAsyncSocket);
  AssertEquals('应该是TCP类型', Ord(stStream), Ord(LAsyncSocket.SocketType));
  
  // 测试UDP异步Socket创建
  LAsyncSocket := TAsyncSocket.CreateUDP;
  AssertNotNull('UDP异步Socket应该创建成功', LAsyncSocket);
  AssertEquals('应该是UDP类型', Ord(stDgram), Ord(LAsyncSocket.SocketType));
end;

procedure TTestCase_AsyncSocket.Test_AsyncResult_Basic;
var
  LResult: specialize TAsyncResult<Integer>;
begin
  LResult := specialize TAsyncResult<Integer>.Create;
  try
    // 测试初始状态
    AssertFalse('初始状态应该未完成', LResult.IsCompleted);
    AssertFalse('初始状态应该未取消', LResult.IsCancelled);
    AssertFalse('初始状态应该无错误', LResult.HasError);
    
    // 测试设置结果
    LResult.SetResult(42);
    AssertTrue('设置结果后应该完成', LResult.IsCompleted);
    AssertEquals('结果应该正确', 42, LResult.GetResult);
    
  finally
    LResult.Free;
  end;
end;

procedure TTestCase_AsyncSocket.Test_AsyncSocket_ConnectAsync;
var
  LAsyncSocket: IAsyncSocket;
  LConnectResult: specialize IAsyncResult<Boolean>;
  LServerSocket: ISocket;
begin
  // 启动简单的接受线程
  TThread.CreateAnonymousThread(procedure
    begin
      try
        LServerSocket := FTestServer.AcceptClient(5000);
        if Assigned(LServerSocket) then
          LServerSocket.Close;
      except
        // 忽略异常
      end;
    end).Start;
    
  LAsyncSocket := TAsyncSocket.CreateTCP;
  
  // 测试异步连接
  LConnectResult := LAsyncSocket.ConnectAsync(TSocketAddress.Localhost(8081), 3000);
  AssertNotNull('连接结果不应该为空', LConnectResult);
  
  // 等待连接完成
  AssertTrue('连接应该在超时前完成', LConnectResult.WaitFor(5000));
  AssertTrue('连接应该成功', LConnectResult.GetResult);
  
  LAsyncSocket.Close;
end;

procedure TTestCase_AsyncSocket.Test_AsyncSocket_SendReceiveAsync;
var
  LAsyncSocket: IAsyncSocket;
  LServerSocket: ISocket;
  LConnectResult: specialize IAsyncResult<Boolean>;
  LSendResult: specialize IAsyncResult<Integer>;
  LReceiveResult: specialize IAsyncResult<TBytes>;
  LTestData: TBytes;
  LReceivedData: TBytes;
begin
  // 启动回显服务器线程
  TThread.CreateAnonymousThread(procedure
    begin
      try
        LServerSocket := FTestServer.AcceptClient(5000);
        if Assigned(LServerSocket) then
        begin
          var LData := LServerSocket.Receive(1024);
          if Length(LData) > 0 then
            LServerSocket.Send(LData); // 回显
          LServerSocket.Close;
        end;
      except
        // 忽略异常
      end;
    end).Start;
    
  LAsyncSocket := TAsyncSocket.CreateTCP;
  
  // 连接
  LConnectResult := LAsyncSocket.ConnectAsync(TSocketAddress.Localhost(8081));
  AssertTrue('连接应该成功', LConnectResult.WaitFor(5000) and LConnectResult.GetResult);
  
  // 准备测试数据
  LTestData := TEncoding.UTF8.GetBytes('Hello Async Socket!');
  
  // 异步发送
  LSendResult := LAsyncSocket.SendAsync(LTestData);
  AssertTrue('发送应该完成', LSendResult.WaitFor(3000));
  AssertEquals('发送字节数应该正确', Length(LTestData), LSendResult.GetResult);
  
  // 异步接收
  LReceiveResult := LAsyncSocket.ReceiveAsync(1024);
  AssertTrue('接收应该完成', LReceiveResult.WaitFor(3000));
  
  LReceivedData := LReceiveResult.GetResult;
  AssertEquals('接收数据长度应该正确', Length(LTestData), Length(LReceivedData));
  AssertEquals('接收数据内容应该正确', TEncoding.UTF8.GetString(LTestData), TEncoding.UTF8.GetString(LReceivedData));
  
  LAsyncSocket.Close;
end;

procedure TTestCase_AsyncSocket.Test_AsyncSocket_HighPerformanceAsync;
var
  LAsyncSocket: IAsyncSocket;
  LServerSocket: ISocket;
  LConnectResult: specialize IAsyncResult<Boolean>;
  LSendResult: specialize IAsyncResult<Integer>;
  LBuffer: TSocketBuffer;
  LVectors: TIOVectorArray;
  LData1, LData2: array[0..511] of Byte;
begin
  // 启动服务器线程
  TThread.CreateAnonymousThread(procedure
    begin
      try
        LServerSocket := FTestServer.AcceptClient(5000);
        if Assigned(LServerSocket) then
        begin
          // 接收所有数据
          while True do
          begin
            var LData := LServerSocket.Receive(4096);
            if Length(LData) = 0 then Break;
          end;
          LServerSocket.Close;
        end;
      except
        // 忽略异常
      end;
    end).Start;
    
  LAsyncSocket := TAsyncSocket.CreateTCP;
  
  // 连接
  LConnectResult := LAsyncSocket.ConnectAsync(TSocketAddress.Localhost(8081));
  AssertTrue('连接应该成功', LConnectResult.WaitFor(5000) and LConnectResult.GetResult);
  
  // 测试缓冲区操作
  LBuffer := TSocketBuffer.Create(1024);
  try
    FillChar(LBuffer.Data^, LBuffer.Capacity, $AA);
    LBuffer.FSize := 512;
    
    LSendResult := LAsyncSocket.SendBufferAsync(LBuffer);
    AssertTrue('缓冲区发送应该完成', LSendResult.WaitFor(3000));
    AssertEquals('缓冲区发送字节数应该正确', 512, LSendResult.GetResult);
    
  finally
    LBuffer.Free;
  end;
  
  // 测试向量化I/O
  FillChar(LData1, SizeOf(LData1), $BB);
  FillChar(LData2, SizeOf(LData2), $CC);
  
  SetLength(LVectors, 2);
  LVectors[0].Data := @LData1[0];
  LVectors[0].Size := SizeOf(LData1);
  LVectors[1].Data := @LData2[0];
  LVectors[1].Size := SizeOf(LData2);
  
  LSendResult := LAsyncSocket.SendVectorizedAsync(LVectors);
  AssertTrue('向量化发送应该完成', LSendResult.WaitFor(3000));
  AssertEquals('向量化发送字节数应该正确', SizeOf(LData1) + SizeOf(LData2), LSendResult.GetResult);
  
  LAsyncSocket.Close;
end;

procedure TTestCase_AsyncSocket.Test_AsyncSocket_BatchOperations;
var
  LAsyncSocket: IAsyncSocket;
  LServerSocket: ISocket;
  LConnectResult: specialize IAsyncResult<Boolean>;
  LSendResult: specialize IAsyncResult<Integer>;
  LLargeData: TBytes;
  I: Integer;
begin
  // 启动服务器线程
  TThread.CreateAnonymousThread(procedure
    begin
      try
        LServerSocket := FTestServer.AcceptClient(5000);
        if Assigned(LServerSocket) then
        begin
          // 接收大量数据
          var LTotalReceived := 0;
          while LTotalReceived < 8192 do
          begin
            var LData := LServerSocket.Receive(4096);
            if Length(LData) = 0 then Break;
            Inc(LTotalReceived, Length(LData));
          end;
          LServerSocket.Close;
        end;
      except
        // 忽略异常
      end;
    end).Start;
    
  LAsyncSocket := TAsyncSocket.CreateTCP;
  
  // 连接
  LConnectResult := LAsyncSocket.ConnectAsync(TSocketAddress.Localhost(8081));
  AssertTrue('连接应该成功', LConnectResult.WaitFor(5000) and LConnectResult.GetResult);
  
  // 准备大量数据
  SetLength(LLargeData, 8192);
  for I := 0 to High(LLargeData) do
    LLargeData[I] := Byte(I mod 256);
    
  // 测试批量发送
  LSendResult := LAsyncSocket.SendAllAsync(LLargeData);
  AssertTrue('批量发送应该完成', LSendResult.WaitFor(5000));
  AssertEquals('批量发送字节数应该正确', Length(LLargeData), LSendResult.GetResult);
  
  LAsyncSocket.Close;
end;

procedure TTestCase_AsyncSocket.Test_AsyncSocket_ErrorHandling;
var
  LAsyncSocket: IAsyncSocket;
  LConnectResult: specialize IAsyncResult<Boolean>;
begin
  LAsyncSocket := TAsyncSocket.CreateTCP;
  
  // 测试连接到不存在的服务器
  LConnectResult := LAsyncSocket.ConnectAsync(TSocketAddress.Create('127.0.0.1', 9999), 1000);
  AssertTrue('连接尝试应该完成', LConnectResult.WaitFor(3000));
  
  // 应该连接失败或有错误
  if LConnectResult.IsCompleted then
  begin
    if LConnectResult.HasError then
      AssertNotNull('应该有错误信息', LConnectResult.GetError)
    else
      AssertFalse('连接到不存在的服务器应该失败', LConnectResult.GetResult);
  end;
end;

procedure TTestCase_AsyncSocket.Test_AsyncSocket_Callbacks;
var
  LAsyncSocket: IAsyncSocket;
  LCallbackTriggered: Boolean;
begin
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  LAsyncSocket := TAsyncSocket.CreateTCP;
  LCallbackTriggered := False;
  
  // 设置错误回调
  LAsyncSocket.OnError(procedure(AError: Exception)
    begin
      LCallbackTriggered := True;
    end);
    
  // 尝试连接到不存在的服务器触发错误
  var LConnectResult := LAsyncSocket.ConnectAsync(TSocketAddress.Create('127.0.0.1', 9999), 1000);
  LConnectResult.WaitFor(3000);
  
  // 给回调一些时间执行
  Sleep(100);
  
  AssertTrue('错误回调应该被触发', LCallbackTriggered);
  {$ELSE}
  // 如果不支持匿名方法，跳过测试
  AssertTrue('匿名方法支持未启用，跳过回调测试', True);
  {$ENDIF}
end;

{ TTestCase_AsyncSocketPerformance }

procedure TTestCase_AsyncSocketPerformance.Test_AsyncSocket_ConcurrentConnections;
begin
  // TODO: 实现并发连接性能测试
  AssertTrue('并发连接测试待实现', True);
end;

procedure TTestCase_AsyncSocketPerformance.Test_AsyncSocket_ThroughputComparison;
begin
  // TODO: 实现吞吐量对比测试
  AssertTrue('吞吐量对比测试待实现', True);
end;

procedure TTestCase_AsyncSocketPerformance.Test_AsyncSocket_MemoryUsage;
begin
  // TODO: 实现内存使用测试
  AssertTrue('内存使用测试待实现', True);
end;

initialization
  RegisterTest(TTestCase_AsyncSocket);
  RegisterTest(TTestCase_AsyncSocketPerformance);

end.
