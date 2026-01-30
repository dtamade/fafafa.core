unit Test_fafafa_core_socket_advanced;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

{$IFDEF FAFAFA_SOCKET_ADVANCED}
uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.socket;

type
  TTestCase_Socket_Advanced = class(TTestCase)
  published
    procedure Test_Socket_Timeout_Span_GetSet;
    procedure Test_Socket_SendReceive_Buffer;
    procedure Test_Socket_SendReceive_Vectorized;
    procedure Test_Socket_SendReceive_WithPool;
    // Edge cases
    procedure Test_Vectorized_Empty;
    procedure Test_Vectorized_WithZeroLengthSegment;
    procedure Test_ReceiveWithPool_ExactCapacity;
  end;

implementation

procedure TTestCase_Socket_Advanced.Test_Socket_Timeout_Span_GetSet;
var
  S: ISocket;
begin
  S := TSocket.TCP;
  S.SetSendTimeout(TTimeSpan.FromMilliseconds(200));
  AssertTrue('SendTimeoutSpan应>=200ms', S.GetSendTimeoutSpan.TotalMilliseconds >= 200);
  S.SetReceiveTimeout(TTimeSpan.FromMilliseconds(300));
  AssertTrue('ReceiveTimeoutSpan应>=300ms', S.GetReceiveTimeoutSpan.TotalMilliseconds >= 300);
end;

procedure TTestCase_Socket_Advanced.Test_Socket_SendReceive_Buffer;
var
  LListener: ISocketListener;
  LPort: Word;
  LServer, LClient: ISocket;
  SendBytes: TBytes;
  SendBuf: TSocketBuffer;
  RecvBuf: TSocketBuffer;
  N: Integer;
begin
  // 启动本地回环TCP监听（端口0自动分配）
  LListener := TSocketListener.CreateTCP(TSocketAddress.Any(0));
  LListener.Start;
  try
    LPort := LListener.ListenAddress.Port;
    // 客户端连接
    LClient := TSocket.TCP;
    LClient.Connect(TSocketAddress.Create('127.0.0.1', LPort, afInet));

    // 服务端接受
    LServer := LListener.AcceptWithTimeout(1000);
    AssertNotNull('应成功接受连接', LServer);

    // 发送端：构造发送缓冲区（Wrap 外部内存）
    SendBytes := TEncoding.UTF8.GetBytes('hello-adv-buffer');
    SendBuf := TSocketBuffer.Wrap(@SendBytes[0], Length(SendBytes));
    N := LClient.SendBuffer(SendBuf);
    AssertEquals('发送字节数应等于输入长度', Length(SendBytes), N);

    // 接收端：使用Owned缓冲区（Create）
    RecvBuf := TSocketBuffer.Create(4096);
    try
      N := LServer.ReceiveBuffer(RecvBuf);
      AssertTrue('接收字节数应>0', N > 0);
      AssertEquals('回环应完整收到', Length(SendBytes), N);
      AssertEquals('内容应一致', 0, CompareByte(SendBytes[0], RecvBuf.Data^, N));
    finally
      RecvBuf.Free;
    end;
  finally
    LListener.Stop;
  end;
end;

procedure TTestCase_Socket_Advanced.Test_Socket_SendReceive_Vectorized;
var
  LListener: ISocketListener;
  LPort: Word;
  LServer, LClient: ISocket;
  Hdr, Body, OutBuf: TBytes;
  Vecs: TIOVectorArray;
  Recv1, Recv2: TIOVectorArray;
  N: Integer;
begin
  LListener := TSocketListener.CreateTCP(TSocketAddress.Any(0));
  LListener.Start;
  try
    LPort := LListener.ListenAddress.Port;
    LClient := TSocket.TCP;
    LClient.Connect(TSocketAddress.Create('127.0.0.1', LPort, afInet));
    LServer := LListener.AcceptWithTimeout(1000);
    AssertNotNull('应成功接受连接', LServer);

    Hdr := TEncoding.UTF8.GetBytes('HDR:');
    Body := TEncoding.UTF8.GetBytes('payload-vector');

    SetLength(Vecs, 2);
    Vecs[0].Data := @Hdr[0];  Vecs[0].Size := Length(Hdr);
    Vecs[1].Data := @Body[0]; Vecs[1].Size := Length(Body);
    N := LClient.SendVectorized(Vecs);
    AssertEquals('发送总字节数应为两段之和', Length(Hdr)+Length(Body), N);

    SetLength(OutBuf, Length(Hdr)+Length(Body));
    SetLength(Recv1, 2); SetLength(Recv2, 0);
    Recv1[0].Data := @OutBuf[0];            Recv1[0].Size := Length(Hdr);
    Recv1[1].Data := @OutBuf[Length(Hdr)];  Recv1[1].Size := Length(Body);
    N := LServer.ReceiveVectorized(Recv1);
    AssertEquals('接收总字节数应为两段之和', Length(Hdr)+Length(Body), N);
    AssertEquals('内容应一致', 0, CompareByte(Hdr[0], OutBuf[0], Length(Hdr)));
    AssertEquals('内容应一致', 0, CompareByte(Body[0], OutBuf[Length(Hdr)], Length(Body)));
  finally
    LListener.Stop;
  end;
end;

procedure TTestCase_Socket_Advanced.Test_Socket_SendReceive_WithPool;
var
  LListener: ISocketListener;
  LPort: Word;
  LServer, LClient: ISocket;
  Pool: TSocketBufferPool;
  SendBytes: TBytes;
  RecvBuf: TSocketBuffer;
  N: Integer;
begin
  LListener := TSocketListener.CreateTCP(TSocketAddress.Any(0));
  LListener.Start;
  try
    LPort := LListener.ListenAddress.Port;
    LClient := TSocket.TCP;
    LClient.Connect(TSocketAddress.Create('127.0.0.1', LPort, afInet));
    LServer := LListener.AcceptWithTimeout(1000);
    AssertNotNull('应成功接受连接', LServer);

    Pool := TSocketBufferPool.Create(1024, 8);
    try
      SendBytes := TEncoding.UTF8.GetBytes('hello-pool');
      N := LClient.SendWithPool(@SendBytes[0], Length(SendBytes), Pool);
      AssertEquals('发送字节数应匹配', Length(SendBytes), N);

      // 使用不超过池默认容量的最大读取，避免内部缓冲区被 Resize 导致池内记录失配
      RecvBuf := LServer.ReceiveWithPool(1024, Pool);
      try
        AssertTrue('接收应>0', RecvBuf.Size > 0);
        AssertEquals('应完整收到与发送一致的长度', Length(SendBytes), RecvBuf.Size);
        AssertEquals('内容一致', 0, CompareByte(SendBytes[0], RecvBuf.Data^, RecvBuf.Size));
      finally
        Pool.Release(RecvBuf);
      end;
    finally
      Pool.Free;
    end;
  finally
    LListener.Stop;
  end;



//
// 向量化发送：空向量
//
procedure TTestCase_Socket_Advanced.Test_Vectorized_Empty;
var
  LListener: ISocketListener; LPort: Word; LServer, LClient: ISocket;
  Vecs: TIOVectorArray;
begin
  LListener := TSocketListener.CreateTCP(TSocketAddress.Any(0));
  LListener.Start;
  try
    LPort := LListener.ListenAddress.Port;
    LClient := TSocket.TCP;  LClient.Connect(TSocketAddress.Create('127.0.0.1', LPort, afInet));
    LServer := LListener.AcceptWithTimeout(1000);  AssertNotNull('应成功接受连接', LServer);
    SetLength(Vecs, 0);
    AssertEquals('空向量发送应返回0', 0, LClient.SendVectorized(Vecs));
  finally
    LListener.Stop;
  end;
end;

procedure TTestCase_Socket_Advanced.Test_Vectorized_WithZeroLengthSegment;
var
  LListener: ISocketListener; LPort: Word; LServer, LClient: ISocket;
  Hdr, Body, OutBuf: TBytes; Vecs: TIOVectorArray; Recv: TIOVectorArray; N: Integer;
begin
  LListener := TSocketListener.CreateTCP(TSocketAddress.Any(0));
  LListener.Start;
  try
    LPort := LListener.ListenAddress.Port;
    LClient := TSocket.TCP;  LClient.Connect(TSocketAddress.Create('127.0.0.1', LPort, afInet));
    LServer := LListener.AcceptWithTimeout(1000);  AssertNotNull('应成功接受连接', LServer);

    Hdr := TEncoding.UTF8.GetBytes('X'); SetLength(Body, 0);
    SetLength(Vecs, 2);
    Vecs[0].Data := @Hdr[0];  Vecs[0].Size := Length(Hdr);
    Vecs[1].Data := nil;      Vecs[1].Size := 0;
    N := LClient.SendVectorized(Vecs);
    AssertEquals('含0长度段的发送应只计有效部分', Length(Hdr), N);

    SetLength(OutBuf, Length(Hdr)); SetLength(Recv, 1);
    Recv[0].Data := @OutBuf[0]; Recv[0].Size := Length(Hdr);
    N := LServer.ReceiveVectorized(Recv);
    AssertEquals('应仅收到有效部分', Length(Hdr), N);
    AssertEquals('内容一致', 0, CompareByte(Hdr[0], OutBuf[0], Length(Hdr)));
  finally
    LListener.Stop;
  end;
end;

procedure TTestCase_Socket_Advanced.Test_ReceiveWithPool_ExactCapacity;
var
  LListener: ISocketListener; LPort: Word; LServer, LClient: ISocket;
  Pool: TSocketBufferPool; Msg: TBytes; RecvBuf: TSocketBuffer; N: Integer;
begin
  LListener := TSocketListener.CreateTCP(TSocketAddress.Any(0));
  LListener.Start;
  try
    LPort := LListener.ListenAddress.Port;
    LClient := TSocket.TCP;  LClient.Connect(TSocketAddress.Create('127.0.0.1', LPort, afInet));
    LServer := LListener.AcceptWithTimeout(1000);  AssertNotNull('应成功接受连接', LServer);

    Pool := TSocketBufferPool.Create(1024, 4);
    try
      Msg := TEncoding.UTF8.GetBytes('exact');
      N := LClient.SendWithPool(@Msg[0], Length(Msg), Pool);
      AssertEquals('发送长度匹配', Length(Msg), N);
      RecvBuf := LServer.ReceiveWithPool(1024, Pool);
      try
        AssertEquals('接收长度匹配', Length(Msg), RecvBuf.Size);
      finally
        Pool.Release(RecvBuf);
      end;
    finally
      Pool.Free;
    end;
  finally
    LListener.Stop;
  end;
end;

initialization
  RegisterTest(TTestCase_Socket_Advanced);
{$ENDIF} // FAFAFA_SOCKET_ADVANCED

end.

