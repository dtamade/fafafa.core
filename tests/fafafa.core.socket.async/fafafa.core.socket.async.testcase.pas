unit fafafa.core.socket.async.testcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  SysUtils,
  Classes,
  fpcunit,
  testregistry,
  fafafa.core.base,
  fafafa.core.socket,
  fafafa.core.socket.async,
  fafafa.core.async.runtime;

type
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
    procedure Test_AsyncListener_AcceptMultipleAsync_EmptyWithoutError;
    procedure Test_AsyncSocket_SendReceiveAsync;
    procedure Test_AsyncSocket_HighPerformanceAsync;
    procedure Test_AsyncSocket_BatchOperations;
    procedure Test_AsyncSocket_ErrorHandling;
    procedure Test_AsyncSocket_Callbacks;
  end;

  TTestCase_AsyncSocketPerformance = class(TTestCase)
  published
    procedure Test_AsyncSocket_ConcurrentConnections;
    procedure Test_AsyncSocket_ThroughputComparison;
    procedure Test_AsyncSocket_MemoryUsage;
  end;

implementation

procedure TTestCase_AsyncSocket.SetUp;
begin
  inherited SetUp;

  TAsyncRuntime.Initialize;
  FRuntime := TAsyncRuntime.GetInstance;

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
  LAsyncSocket := TAsyncSocket.CreateTCP;
  AssertNotNull('TCP异步Socket应该创建成功', LAsyncSocket);
  AssertEquals('应该是TCP类型', Ord(stStream), Ord(LAsyncSocket.SocketType));

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
    AssertFalse('初始状态应该未完成', LResult.IsCompleted);
    AssertFalse('初始状态应该未取消', LResult.IsCancelled);
    AssertFalse('初始状态应该无错误', LResult.HasError);

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
  TThread.CreateAnonymousThread(procedure
    begin
      try
        LServerSocket := FTestServer.AcceptWithTimeout(5000);
        if Assigned(LServerSocket) then
          LServerSocket.Close;
      except
        // ignore
      end;
    end).Start;

  LAsyncSocket := TAsyncSocket.CreateTCP;
  LConnectResult := LAsyncSocket.ConnectAsync(TSocketAddress.Localhost(8081), 3000);

  AssertNotNull('连接结果不应该为空', LConnectResult);
  AssertTrue('连接应该在超时前完成', LConnectResult.WaitFor(5000));
  AssertTrue('连接应该成功', LConnectResult.GetResult);

  LAsyncSocket.Close;
end;

procedure TTestCase_AsyncSocket.Test_AsyncListener_AcceptMultipleAsync_EmptyWithoutError;
var
  LAsyncListener: IAsyncSocketListener;
  LAcceptResult: specialize IAsyncResult<TAsyncSocketArray>;
  LSockets: TAsyncSocketArray;
begin
  LAsyncListener := TAsyncSocketListener.ListenTCP(8081);
  AssertNotNull('异步监听器应该创建成功', LAsyncListener);

  LAcceptResult := LAsyncListener.AcceptMultipleAsync(3);
  AssertNotNull('AcceptMultipleAsync 结果不应为空', LAcceptResult);
  AssertTrue('AcceptMultipleAsync 应在超时前完成', LAcceptResult.WaitFor(3000));
  AssertFalse('空场景不应返回错误', LAcceptResult.HasError);

  LSockets := LAcceptResult.GetResult;
  AssertEquals('空场景应返回空数组', 0, Length(LSockets));
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
  LServerData: TBytes;
begin
  TThread.CreateAnonymousThread(procedure
    begin
      try
        LServerSocket := FTestServer.AcceptWithTimeout(5000);
        if Assigned(LServerSocket) then
        begin
          LServerData := LServerSocket.Receive(1024);
          if Length(LServerData) > 0 then
            LServerSocket.Send(LServerData);
          LServerSocket.Close;
        end;
      except
        // ignore
      end;
    end).Start;

  LAsyncSocket := TAsyncSocket.CreateTCP;
  LConnectResult := LAsyncSocket.ConnectAsync(TSocketAddress.Localhost(8081));
  AssertTrue('连接应该成功', LConnectResult.WaitFor(5000) and LConnectResult.GetResult);

  LTestData := TEncoding.UTF8.GetBytes('Hello Async Socket!');

  LSendResult := LAsyncSocket.SendAsync(LTestData);
  AssertTrue('发送应该完成', LSendResult.WaitFor(3000));
  AssertEquals('发送字节数应该正确', Length(LTestData), LSendResult.GetResult);

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
  LData1: array[0..511] of Byte;
  LData2: array[0..511] of Byte;
  LServerData: TBytes;
begin
  TThread.CreateAnonymousThread(procedure
    begin
      try
        LServerSocket := FTestServer.AcceptWithTimeout(5000);
        if Assigned(LServerSocket) then
        begin
          while True do
          begin
            LServerData := LServerSocket.Receive(4096);
            if Length(LServerData) = 0 then
              Break;
          end;
          LServerSocket.Close;
        end;
      except
        // ignore
      end;
    end).Start;

  LAsyncSocket := TAsyncSocket.CreateTCP;
  LConnectResult := LAsyncSocket.ConnectAsync(TSocketAddress.Localhost(8081));
  AssertTrue('连接应该成功', LConnectResult.WaitFor(5000) and LConnectResult.GetResult);

  LBuffer := TSocketBuffer.Create(1024);
  try
    FillChar(LBuffer.Data^, LBuffer.Capacity, $AA);
    LBuffer.Resize(512);

    LSendResult := LAsyncSocket.SendBufferAsync(LBuffer);
    AssertTrue('缓冲区发送应该完成', LSendResult.WaitFor(3000));
    AssertEquals('缓冲区发送字节数应该正确', 512, LSendResult.GetResult);
  finally
    LBuffer.Free;
  end;

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
  LIndex: Integer;
  LTotalReceived: Integer;
  LServerData: TBytes;
begin
  TThread.CreateAnonymousThread(procedure
    begin
      try
        LServerSocket := FTestServer.AcceptWithTimeout(5000);
        if Assigned(LServerSocket) then
        begin
          LTotalReceived := 0;
          while LTotalReceived < 8192 do
          begin
            LServerData := LServerSocket.Receive(4096);
            if Length(LServerData) = 0 then
              Break;
            Inc(LTotalReceived, Length(LServerData));
          end;
          LServerSocket.Close;
        end;
      except
        // ignore
      end;
    end).Start;

  LAsyncSocket := TAsyncSocket.CreateTCP;
  LConnectResult := LAsyncSocket.ConnectAsync(TSocketAddress.Localhost(8081));
  AssertTrue('连接应该成功', LConnectResult.WaitFor(5000) and LConnectResult.GetResult);

  SetLength(LLargeData, 8192);
  for LIndex := 0 to High(LLargeData) do
    LLargeData[LIndex] := Byte(LIndex mod 256);

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

  LConnectResult := LAsyncSocket.ConnectAsync(TSocketAddress.Localhost(9999), 1000);
  AssertTrue('连接尝试应该完成', LConnectResult.WaitFor(3000));

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
  LConnectResult: specialize IAsyncResult<Boolean>;
begin
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  LAsyncSocket := TAsyncSocket.CreateTCP;
  LCallbackTriggered := False;

  LAsyncSocket.OnError(procedure(const AError: Exception)
    begin
      LCallbackTriggered := True;
    end);

  LConnectResult := LAsyncSocket.ConnectAsync(TSocketAddress.Localhost(9999), 1000);
  LConnectResult.WaitFor(3000);
  Sleep(100);

  AssertTrue('错误回调应该被触发', LCallbackTriggered);
  {$ELSE}
  AssertTrue('匿名方法支持未启用，跳过回调测试', True);
  {$ENDIF}
end;

procedure TTestCase_AsyncSocketPerformance.Test_AsyncSocket_ConcurrentConnections;
var
  LListener: ISocketListener;
  LServerSocket: ISocket;
  LSockets: array[1..4] of IAsyncSocket;
  LConnectResults: array[1..4] of specialize IAsyncResult<Boolean>;
  LSuccessCount: Integer;
  LIndex: Integer;
const
  TEST_PORT = 18082;
begin
  LSuccessCount := 0;
  LListener := TSocketListener.ListenTCP(TEST_PORT);
  LListener.Start;

  TThread.CreateAnonymousThread(procedure
    var
      LInnerIndex: Integer;
    begin
      try
        for LInnerIndex := 1 to 4 do
        begin
          LServerSocket := LListener.AcceptWithTimeout(5000);
          if Assigned(LServerSocket) then
            LServerSocket.Close;
        end;
      except
        // ignore
      end;
    end).Start;

  for LIndex := 1 to 4 do
  begin
    LSockets[LIndex] := TAsyncSocket.CreateTCP;
    LConnectResults[LIndex] := LSockets[LIndex].ConnectAsync(TSocketAddress.Localhost(TEST_PORT), 3000);
  end;

  for LIndex := 1 to 4 do
  begin
    AssertTrue('并发连接结果应在超时前完成', LConnectResults[LIndex].WaitFor(5000));
    if LConnectResults[LIndex].GetResult then
      Inc(LSuccessCount);
  end;

  AssertEquals('并发连接成功数应匹配', 4, LSuccessCount);

  for LIndex := 1 to 4 do
    LSockets[LIndex].Close;

  LListener.Stop;
end;

procedure TTestCase_AsyncSocketPerformance.Test_AsyncSocket_ThroughputComparison;
var
  LListener: ISocketListener;
  LClientSocket: IAsyncSocket;
  LConnectResult: specialize IAsyncResult<Boolean>;
  LSendResult: specialize IAsyncResult<Integer>;
  LServerThread: TThread;
  LPayload: TBytes;
  LLargeData: TBytes;
  LReceivedData: TBytes;
  LExpectedBytes: array[0..1] of Integer;
  LReceivedBytes: array[0..1] of Integer;
  LSendAsyncElapsedMs: QWord;
  LSendAllElapsedMs: QWord;
  LStartedAt: QWord;
  LSendAsyncThroughput: Int64;
  LSendAllThroughput: Int64;
  LServerCompleted: Boolean;
  LIndex: Integer;
const
  TEST_PORT = 18083;
  PAYLOAD_SIZE = 1024;
  SEND_COUNT = 64;
begin
  LExpectedBytes[0] := PAYLOAD_SIZE * SEND_COUNT;
  LExpectedBytes[1] := PAYLOAD_SIZE * SEND_COUNT;
  LReceivedBytes[0] := 0;
  LReceivedBytes[1] := 0;
  LServerCompleted := False;

  SetLength(LPayload, PAYLOAD_SIZE);
  for LIndex := 0 to High(LPayload) do
    LPayload[LIndex] := Byte(LIndex mod 251);

  SetLength(LLargeData, LExpectedBytes[1]);
  for LIndex := 0 to High(LLargeData) do
    LLargeData[LIndex] := Byte(LIndex mod 251);

  LListener := TSocketListener.ListenTCP(TEST_PORT);
  LListener.Start;

  LServerThread := TThread.CreateAnonymousThread(procedure
    var
      LServerSocket: ISocket;
      LInnerPhase: Integer;
    begin
      try
        for LInnerPhase := 0 to 1 do
        begin
          LServerSocket := LListener.AcceptWithTimeout(5000);
          if not Assigned(LServerSocket) then
            Exit;

          while LReceivedBytes[LInnerPhase] < LExpectedBytes[LInnerPhase] do
          begin
            LReceivedData := LServerSocket.Receive(4096);
            if Length(LReceivedData) = 0 then
              Break;
            Inc(LReceivedBytes[LInnerPhase], Length(LReceivedData));
          end;

          LServerSocket.Close;
        end;
        LServerCompleted := True;
      except
        LServerCompleted := False;
      end;
    end);
  LServerThread.FreeOnTerminate := False;
  LServerThread.Start;

  LClientSocket := TAsyncSocket.CreateTCP;
  LConnectResult := LClientSocket.ConnectAsync(TSocketAddress.Localhost(TEST_PORT), 3000);
  AssertTrue('SendAsync吞吐阶段应连接成功', LConnectResult.WaitFor(5000) and LConnectResult.GetResult);

  LStartedAt := GetTickCount64;
  for LIndex := 1 to SEND_COUNT do
  begin
    LSendResult := LClientSocket.SendAsync(LPayload);
    AssertTrue('SendAsync发送应完成', LSendResult.WaitFor(3000));
    AssertEquals('SendAsync每次发送字节数应正确', PAYLOAD_SIZE, LSendResult.GetResult);
  end;
  LSendAsyncElapsedMs := GetTickCount64 - LStartedAt;
  LClientSocket.Close;

  LClientSocket := TAsyncSocket.CreateTCP;
  LConnectResult := LClientSocket.ConnectAsync(TSocketAddress.Localhost(TEST_PORT), 3000);
  AssertTrue('SendAll吞吐阶段应连接成功', LConnectResult.WaitFor(5000) and LConnectResult.GetResult);

  LStartedAt := GetTickCount64;
  LSendResult := LClientSocket.SendAllAsync(LLargeData);
  AssertTrue('SendAll发送应完成', LSendResult.WaitFor(5000));
  AssertEquals('SendAll总发送字节数应正确', Length(LLargeData), LSendResult.GetResult);
  LSendAllElapsedMs := GetTickCount64 - LStartedAt;
  LClientSocket.Close;

  LServerThread.WaitFor;
  LServerThread.Free;
  LListener.Stop;

  AssertTrue('吞吐测试服务端应完成双阶段接收', LServerCompleted);
  AssertEquals('SendAsync阶段服务端接收字节应完整', LExpectedBytes[0], LReceivedBytes[0]);
  AssertEquals('SendAll阶段服务端接收字节应完整', LExpectedBytes[1], LReceivedBytes[1]);

  if LSendAsyncElapsedMs = 0 then
    LSendAsyncThroughput := LExpectedBytes[0] * 1000
  else
    LSendAsyncThroughput := (Int64(LExpectedBytes[0]) * 1000) div Int64(LSendAsyncElapsedMs);

  if LSendAllElapsedMs = 0 then
    LSendAllThroughput := LExpectedBytes[1] * 1000
  else
    LSendAllThroughput := (Int64(LExpectedBytes[1]) * 1000) div Int64(LSendAllElapsedMs);

  AssertTrue('SendAsync吞吐量应大于0', LSendAsyncThroughput > 0);
  AssertTrue('SendAll吞吐量应大于0', LSendAllThroughput > 0);
end;

procedure TTestCase_AsyncSocketPerformance.Test_AsyncSocket_MemoryUsage;
var
  LListener: ISocketListener;
  LServerThread: TThread;
  LClientSocket: IAsyncSocket;
  LConnectResult: specialize IAsyncResult<Boolean>;
  LMemBefore: QWord;
  LMemAfter: QWord;
  LMemIncrease: QWord;
  LSuccessCount: Integer;
  LIndex: Integer;
const
  TEST_PORT = 18084;
  CONNECTION_COUNT = 50;
  MAX_MEMORY_INCREASE = 16 * 1024 * 1024;
begin
  LSuccessCount := 0;

  LListener := TSocketListener.ListenTCP(TEST_PORT);
  LListener.Start;

  LServerThread := TThread.CreateAnonymousThread(procedure
    var
      LServerSocket: ISocket;
      LInnerIndex: Integer;
    begin
      for LInnerIndex := 1 to CONNECTION_COUNT do
      begin
        LServerSocket := LListener.AcceptWithTimeout(5000);
        if not Assigned(LServerSocket) then
          Exit;
        LServerSocket.Close;
      end;
    end);
  LServerThread.FreeOnTerminate := False;
  LServerThread.Start;

  LMemBefore := GetHeapStatus.TotalAllocated;

  for LIndex := 1 to CONNECTION_COUNT do
  begin
    LClientSocket := TAsyncSocket.CreateTCP;
    LConnectResult := LClientSocket.ConnectAsync(TSocketAddress.Localhost(TEST_PORT), 3000);
    AssertTrue('内存测试连接应在超时前完成', LConnectResult.WaitFor(5000));
    AssertTrue('内存测试连接应成功', LConnectResult.GetResult);
    Inc(LSuccessCount);
    LClientSocket.Close;
    LClientSocket := nil;
  end;

  LServerThread.WaitFor;
  LServerThread.Free;
  LListener.Stop;

  LMemAfter := GetHeapStatus.TotalAllocated;
  if LMemAfter > LMemBefore then
    LMemIncrease := LMemAfter - LMemBefore
  else
    LMemIncrease := 0;

  AssertEquals('内存测试连接成功数应匹配', CONNECTION_COUNT, LSuccessCount);
  AssertTrue('连接循环后的内存增长应在阈值内', LMemIncrease <= MAX_MEMORY_INCREASE);
end;

initialization
  RegisterTest(TTestCase_AsyncSocket);
  RegisterTest(TTestCase_AsyncSocketPerformance);

end.
