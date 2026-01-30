unit Test_fafafa_core_socket_best_practices;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}
{$PUSH}
{$HINTS OFF}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.socket;

// Minimal tests to validate Best Practices loops and framing

type
  TTestCase_Socket_BestPractices = class(TTestCase)
  published
    procedure Test_Frame_Roundtrip_Local;
    procedure Test_Receive_ReturnsZero_OnPeerClose;
    procedure Test_ZeroLengthFrame_Roundtrip;
    procedure Test_FrameTooLarge_Raises;
    procedure Test_AcceptWithTimeout_ReturnsNil_OnTimeout;
    procedure Test_RecvAfterClose_MayReturnPositiveThenZero;
    procedure Test_ConnectWithTimeout_Succeeds_Localhost;
    procedure Test_WaitWritable_Readable_Basics;
    procedure Test_AcceptWithTimeout_Zero_ReturnsNil;
    procedure Test_AcceptWithTimeout_VerySmall_ReturnsNil;
    procedure Test_UDP_TryReceive_NoData_WouldBlock;
    procedure Test_WaitReadable_ZeroTimeout_NoData_ReturnsFalse;
    procedure Test_TCP_TryReceive_WouldBlock_ThenData;
    procedure Test_UDP_Loopback_Roundtrip;
    {$IFDEF FAFAFA_SOCKET_ADVANCED}
    procedure Test_Statistics_Counters_Basic;
    {$ENDIF}


    procedure Test_AcceptWithTimeout_MoreThresholds;
    {$IFDEF FAFAFA_SOCKET_ADVANCED}
    procedure Test_Statistics_Time_Basics;

    // 新增：Bind 冲突异常包含 errorCode/handle
    procedure Test_Bind_Conflict_Raises_WithErrorCodeAndHandle;
    {$ENDIF}
  end;

implementation

procedure SendAll(S: ISocket; const P: PByte; L: Integer);
var Sent, N: Integer;
begin
  Sent := 0;
  while Sent < L do
  begin
    N := S.Send(@P[Sent], L - Sent);
    if N <= 0 then raise Exception.Create('send failed');
    Inc(Sent, N);
  end;
end;

procedure ReceiveExact(S: ISocket; const P: PByte; L: Integer);
var Read, N: Integer;
begin
  Read := 0;
  while Read < L do
  begin
    N := S.Receive(@P[Read], L - Read);
    if N = 0 then raise Exception.Create('peer closed');
    if N < 0 then raise Exception.Create('recv failed');
    Inc(Read, N);
  end;
end;

procedure SendFrame(S: ISocket; const B: TBytes);
var H: array[0..3] of Byte; L: LongWord;
begin
  FillChar(H, 0, SizeOf(H));
  L := Length(B);
  Move(L, H[0], 4);
  SendAll(S, @H[0], 4);
  if L > 0 then SendAll(S, @B[0], L);
end;

function ReceiveFrame(S: ISocket; MaxLen: LongWord): TBytes;
var H: array[0..3] of Byte; L: LongWord;
begin
  Result := nil;
  ReceiveExact(S, @H[0], 4);
  Move(H[0], L, 4);
  if (L > MaxLen) then raise Exception.Create('frame too large');
  SetLength(Result, L);
  if L > 0 then ReceiveExact(S, @Result[0], L);
end;

procedure TTestCase_Socket_BestPractices.Test_Frame_Roundtrip_Local;
var
  Listener: ISocketListener;
  Server, Client: ISocket;
  Port: Integer;
  Payload, Echo: TBytes;
  Hdr: array[0..3] of Byte;
  Len: LongWord;
begin
  FillChar(Hdr, 0, SizeOf(Hdr));
  Len := 0;
  Listener := TSocketListener.ListenTCP(0);
  Listener.Start;
  try
    Port := Listener.ListenAddress.Port;
    Client := TSocket.TCP;
    Client.Connect(TSocketAddress.Create('127.0.0.1', Port, afInet));

    Server := Listener.AcceptWithTimeout(1000);
    AssertTrue('Server should accept within 1s', Assigned(Server));

    // Client sends one frame
    Payload := TEncoding.UTF8.GetBytes('bp-demo');
    SendFrame(Client, Payload);

    // Server receives frame
    ReceiveExact(Server, @Hdr[0], 4);
    Move(Hdr[0], Len, 4);
    SetLength(Payload, Len);
    if Len > 0 then ReceiveExact(Server, @Payload[0], Len);

    // Echo back
    SendFrame(Server, Payload);

    // Client reads echo
    Echo := ReceiveFrame(Client, 1 shl 20);
    AssertTrue('bp-demo', CompareMem(@Echo[0], @TEncoding.UTF8.GetBytes('bp-demo')[0], Length(Echo)));

    Server.Close;
    Client.Close;
  finally
    Listener.Stop;
  end;
end;

procedure TTestCase_Socket_BestPractices.Test_Receive_ReturnsZero_OnPeerClose;
var
  A, B: ISocket;
  Buf: array[0..7] of Byte;
  N: Integer;
begin
  FillChar(Buf, 0, SizeOf(Buf));

  // Create local TCP pair via listener
  with TSocketListener.ListenTCP(0) do
  begin
    Start;
    try
      A := TSocket.TCP;
      A.Connect(TSocketAddress.Create('127.0.0.1', ListenAddress.Port, afInet));
      B := AcceptWithTimeout(1000);
      AssertTrue('Accept should succeed', Assigned(B));

      // Close write on A and then fully close
      A.Shutdown(sdSend);
      A.Close;

      // Read from B until 0
      N := B.Receive(@Buf[0], SizeOf(Buf));
      if N > 0 then
      begin
        // drain remaining then next recv should be 0 or error
        while N > 0 do
          N := B.Receive(@Buf[0], SizeOf(Buf));
      end;
      AssertEquals('Expect 0 on peer close after draining', 0, N);

      B.Close;
    finally
      Stop;
    end;
  end;
end;

procedure TTestCase_Socket_BestPractices.Test_ConnectWithTimeout_Succeeds_Localhost;
var L: ISocketListener; C, S: ISocket; Port: Integer;
begin
  L := TSocketListener.ListenTCP(0);
  L.Start;
  try
    Port := L.ListenAddress.Port;
    C := TSocket.TCP;
    C.ConnectWithTimeout(TSocketAddress.Create('127.0.0.1', Port, afInet), 500);
    S := L.AcceptWithTimeout(500);
    AssertTrue('accept', Assigned(S));
    // basic IO to ensure connection is valid
    AssertTrue('client writable quickly', C.WaitWritable(100));
    S.Close; C.Close;
  finally
    L.Stop;
  end;
end;

procedure TTestCase_Socket_BestPractices.Test_WaitWritable_Readable_Basics;
var L: ISocketListener; C, S: ISocket; Port: Integer; Buf: array[0..3] of Byte; N: Integer;

begin
  FillChar(Buf, 0, SizeOf(Buf));
  L := TSocketListener.ListenTCP(0);
  L.Start;
  try
    Port := L.ListenAddress.Port;
    C := TSocket.TCP;
    C.Connect(TSocketAddress.Create('127.0.0.1', Port, afInet));
    S := L.AcceptWithTimeout(500);
    AssertTrue('accept', Assigned(S));
    // client should be writable quickly, server readable only after write
    AssertTrue('client writable', C.WaitWritable(200));
    // write 4 bytes then server becomes readable
    Buf[0] := 1; Buf[1] := 2; Buf[2] := 3; Buf[3] := 4;
    N := C.Send(@Buf[0], 4);
    AssertEquals(4, N);
    AssertTrue('server readable', S.WaitReadable(500));
    N := S.Receive(@Buf[0], 4);
    AssertEquals(4, N);
    S.Close; C.Close;
  finally
    L.Stop;
  end;
end;



procedure TTestCase_Socket_BestPractices.Test_ZeroLengthFrame_Roundtrip;

var L: ISocketListener; S, C: ISocket; Port: Integer; B: TBytes; Echo: TBytes;
begin
  L := TSocketListener.ListenTCP(0);
  L.Start;
  try
    Port := L.ListenAddress.Port;
    C := TSocket.TCP;
    C.Connect(TSocketAddress.Create('127.0.0.1', Port, afInet));
    S := L.AcceptWithTimeout(500);
    AssertTrue('accept', Assigned(S));

    SetLength(B, 0);
    SendFrame(C, B);
    Echo := ReceiveFrame(S, 16);
    AssertEquals(0, Length(Echo));

    // echo back zero
    SendFrame(S, Echo);
    Echo := ReceiveFrame(C, 16);
    AssertEquals(0, Length(Echo));

    S.Close; C.Close;
  finally
    L.Stop;
  end;
end;

procedure TTestCase_Socket_BestPractices.Test_FrameTooLarge_Raises;
var L: ISocketListener; S, C: ISocket; Port: Integer; H: array[0..3] of Byte; Len: LongWord;
begin
  L := TSocketListener.ListenTCP(0);
  L.Start;
  try
    Port := L.ListenAddress.Port;
    C := TSocket.TCP;
    C.Connect(TSocketAddress.Create('127.0.0.1', Port, afInet));
    S := L.AcceptWithTimeout(500);
    AssertTrue('accept', Assigned(S));

    // craft too large header only
    Len := 1 shl 30; // 1GB
    Move(Len, H[0], 4);
    SendAll(C, @H[0], 4);

    try
      // server receive should raise on size check
      ReceiveFrame(S, 1 shl 20);
      Fail('expected exception for frame too large');
    except
      on E: Exception do ;
    end;

    S.Close; C.Close;
  finally
    L.Stop;
  end;
end;

procedure TTestCase_Socket_BestPractices.Test_AcceptWithTimeout_ReturnsNil_OnTimeout;
var L: ISocketListener; S: ISocket;
begin
  L := TSocketListener.ListenTCP(0);
  L.Start;
  try
    S := L.AcceptWithTimeout(100);
    AssertTrue('Expect nil when no client arrives', S = nil);
  finally
    L.Stop;
  end;
end;

procedure TTestCase_Socket_BestPractices.Test_AcceptWithTimeout_MoreThresholds;
var L: ISocketListener; S: ISocket;
begin
  L := TSocketListener.ListenTCP(0);
  L.Start;
  try
    S := L.AcceptWithTimeout(5);
    AssertTrue('Expect nil at 5ms', S = nil);
    S := L.AcceptWithTimeout(10);
    AssertTrue('Expect nil at 10ms', S = nil);
    S := L.AcceptWithTimeout(100);
    AssertTrue('Expect nil at 100ms', S = nil);
    S := L.AcceptWithTimeout(1000);
    AssertTrue('Expect nil at 1000ms', S = nil);
  finally
    L.Stop;
  end;
end;

procedure TTestCase_Socket_BestPractices.Test_AcceptWithTimeout_Zero_ReturnsNil;
var L: ISocketListener; S: ISocket;
begin
  L := TSocketListener.ListenTCP(0);
  L.Start;
  try
    S := L.AcceptWithTimeout(0);
    AssertTrue('AcceptWithTimeout(0) should return nil when no client', S = nil);
  finally
    L.Stop;
  end;
end;




procedure TTestCase_Socket_BestPractices.Test_AcceptWithTimeout_VerySmall_ReturnsNil;
var L: ISocketListener; S: ISocket;
begin
  L := TSocketListener.ListenTCP(0);
  L.Start;
  try
    S := L.AcceptWithTimeout(1);
    AssertTrue('Expect nil when no client arrives with 1ms', S = nil);
  finally
    L.Stop;
  end;
end;

procedure TTestCase_Socket_BestPractices.Test_RecvAfterClose_MayReturnPositiveThenZero;
var L: ISocketListener; A, B: ISocket; Port: Integer; Buf: array[0..63] of Byte; N: Integer; Sent: TBytes;
begin
  L := TSocketListener.ListenTCP(0);
  L.Start;
  try
    Port := L.ListenAddress.Port;
    A := TSocket.TCP;
    A.Connect(TSocketAddress.Create('127.0.0.1', Port, afInet));
    B := L.AcceptWithTimeout(500);
    AssertTrue('accept', Assigned(B));

    // send small payload then close A
    Sent := TEncoding.UTF8.GetBytes('bye');
    SendAll(A, @Sent[0], Length(Sent));
    A.Shutdown(sdSend);
    A.Close;

    N := B.Receive(@Buf[0], SizeOf(Buf));
    AssertTrue('first recv should be >=0', N >= 0);
    while N > 0 do
      N := B.Receive(@Buf[0], SizeOf(Buf));
    AssertEquals('after draining expect 0', 0, N);

    B.Close;
  finally
    L.Stop;
  end;
end;


procedure TTestCase_Socket_BestPractices.Test_TCP_TryReceive_WouldBlock_ThenData;
var L: ISocketListener; C, S: ISocket; Port: Integer; Buf: array[0..7] of Byte; Err, N: Integer;
begin
  L := TSocketListener.ListenTCP(0);
  L.Start;
  try
    Port := L.ListenAddress.Port;
    C := TSocket.TCP;
    C.Connect(TSocketAddress.Create('127.0.0.1', Port, afInet));
    S := L.AcceptWithTimeout(500);
    AssertTrue('accept', Assigned(S));

    S.NonBlocking := True;
    N := S.TryReceive(@Buf[0], SizeOf(Buf), Err);
    AssertEquals('no data yet -> wouldblock', -1, N);
    AssertTrue('err nonzero', Err <> 0);

    // client sends 1 byte
    Buf[0] := 42;
    N := C.Send(@Buf[0], 1);
    AssertEquals('send 1', 1, N);

    // now server should become readable shortly
    AssertTrue('server readable soon', S.WaitReadable(200));
    N := S.TryReceive(@Buf[0], SizeOf(Buf), Err);
    AssertTrue('received >0', N > 0);
  finally
    L.Stop;
  end;
end;

procedure TTestCase_Socket_BestPractices.Test_UDP_Loopback_Roundtrip;
var Srv, Cli: ISocket; Port: Integer; From: ISocketAddress; Msg, Recv: TBytes; N: Integer;
begin
  Srv := TSocket.UDP;
  Srv.ReuseAddress := True;
  // 使用接口工厂，确保引用计数管理，避免临时类实例泄漏
  Srv.Bind(TSocketAddress.CreateIPv4('127.0.0.1', 0));
  Port := Srv.LocalAddress.Port;

  Cli := TSocket.UDP;
  Msg := TEncoding.UTF8.GetBytes('ping');
  // 显式使用接口返回的地址，确保自动释放
  N := Cli.SendTo(@Msg[0], Length(Msg), TSocketAddress.CreateIPv4('127.0.0.1', Port));
  AssertEquals('sendto bytes', Length(Msg), N);

  Recv := Srv.ReceiveFrom(1024, From);
  AssertEquals('payload len eq', Length(Msg), Length(Recv));
  AssertTrue('payload text', (Length(Recv)=4) and (Recv[0]=Ord('p')) and (Recv[1]=Ord('i')) and (Recv[2]=Ord('n')) and (Recv[3]=Ord('g')));
  AssertTrue('from address set', Assigned(From));
  AssertTrue('from port > 0', From.Port > 0);


{$IFDEF FAFAFA_SOCKET_ADVANCED}
procedure TTestCase_Socket_BestPractices.Test_Statistics_Counters_Basic;
var L: ISocketListener; C, S: ISocket; Port: Integer; Stat: TSocketStatistics; B: TBytes; N: Integer;
begin
  L := TSocketListener.ListenTCP(0);
  L.Start;
  try
    Port := L.ListenAddress.Port;
    C := TSocket.TCP;
    C.Connect(TSocketAddress.Create('127.0.0.1', Port, afInet));
    S := L.AcceptWithTimeout(500);
    AssertTrue('accept', Assigned(S));

    S.ResetStatistics; C.ResetStatistics;
    B := TEncoding.UTF8.GetBytes('hello');
    N := C.Send(@B[0], Length(B));
    AssertEquals('send hello', Length(B), N);
    AssertTrue('server readable', S.WaitReadable(200));
    SetLength(B, 5);
    N := S.Receive(@B[0], 5);
    AssertEquals('recv hello', 5, N);

    Stat := C.GetStatistics;
    AssertTrue('client sent bytes >= 5', Stat.BytesSent >= 5);
    AssertTrue('client send ops >= 1', Stat.SendOperations >= 1);

    Stat := S.GetStatistics;
    AssertTrue('server recv bytes >= 5', Stat.BytesReceived >= 5);
    AssertTrue('server recv ops >= 1', Stat.ReceiveOperations >= 1);
  finally
    L.Stop;
  end;
end;
{$ENDIF}

{$IFDEF FAFAFA_SOCKET_ADVANCED}
procedure TTestCase_Socket_BestPractices.Test_Statistics_Time_Basics;
var L: ISocketListener; C, S: ISocket; Port: Integer; Stat: TSocketStatistics;
begin
  L := TSocketListener.ListenTCP(0);
  L.Start;
  try
    Port := L.ListenAddress.Port;
    C := TSocket.TCP;
    C.Connect(TSocketAddress.Create('127.0.0.1', Port, afInet));
    S := L.AcceptWithTimeout(500);
    AssertTrue('accept', Assigned(S));

    S.ResetStatistics; C.ResetStatistics;
    Stat := C.GetStatistics;
    AssertTrue('connection time set', Stat.ConnectionTime > 0);
    AssertTrue('last activity set', Stat.LastActivity > 0);
  finally
    L.Stop;
  end;
end;
{$ENDIF}


  Cli.Close;
  Srv.Close;
end;


procedure TTestCase_Socket_BestPractices.Test_UDP_TryReceive_NoData_WouldBlock;
var U: ISocket; Buf: array[0..15] of Byte; Err, N: Integer;
begin
  U := TSocket.UDP;
  U.NonBlocking := True;
  // not bound, receive should return -1 with EWOULDBLOCK/EAGAIN on most stacks
  N := U.TryReceive(@Buf[0], SizeOf(Buf), Err);
  AssertEquals('no data -> -1', -1, N);
  AssertTrue('wouldblock/again', (Err <> 0));
  U.Close;
end;

procedure TTestCase_Socket_BestPractices.Test_WaitReadable_ZeroTimeout_NoData_ReturnsFalse;
var L: ISocketListener; C, S: ISocket; Port: Integer;
begin
  L := TSocketListener.ListenTCP(0);
  L.Start;
  try
    Port := L.ListenAddress.Port;
    C := TSocket.TCP;
    C.Connect(TSocketAddress.Create('127.0.0.1', Port, afInet));
    S := L.AcceptWithTimeout(500);
    AssertTrue('accept', Assigned(S));
    // without any write, server should not be readable with zero timeout
    AssertFalse('server not readable immediately', S.WaitReadable(0));
    C.Close; S.Close;
  finally
    L.Stop;
  end;
end;

initialization
  RegisterTest(TTestCase_Socket_BestPractices);

{$POP}

end.

