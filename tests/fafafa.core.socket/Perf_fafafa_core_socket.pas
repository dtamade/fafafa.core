unit Perf_fafafa_core_socket;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fafafa.core.math, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.socket;

type
  TTestCase_Perf = class(TTestCase)
  private
    function NowMs: QWord;
    function GetEnvInt(const Name: string; Default: Integer): Integer;
  published
    procedure Test_Perf_TCP_ShortConnections_100;
    procedure Test_Perf_TCP_LongConnections_RTT_Throughput;
    procedure Test_Perf_UDP_Throughput_Loss;
  end;

implementation

function TTestCase_Perf.GetEnvInt(const Name: string; Default: Integer): Integer;
var S: String; V: Integer;
begin
  S := GetEnvironmentVariable(Name);
  if (S <> '') and TryStrToInt(S, V) then Result := V else Result := Default;
end;

// 复用简单连接线程（本文件内定义一个最小版，避免耦合）
type
  TConnectThread = class(TThread)
  private
    FPort: Word;
  protected
    procedure Execute; override;
  public
    constructor Create(const APort: Word);
  end;

constructor TConnectThread.Create(const APort: Word);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FPort := APort;
  Start;
end;

procedure TConnectThread.Execute;
var
  LClient: ISocket;
  LAddr: ISocketAddress;
begin
  Sleep(20);
  LClient := TSocket.TCP;
  LAddr := TSocketAddress.Localhost(FPort);
  LClient.Connect(LAddr);
  LClient.Close;
end;

function TTestCase_Perf.NowMs: QWord;
begin
  Result := GetTickCount64;
end;

procedure TTestCase_Perf.Test_Perf_TCP_ShortConnections_100;
var
  C: Integer;
  LListener: ISocketListener;
  LPort: Word;
  i: Integer;
  T0, T1: QWord;
  ConnThreads: array of TConnectThread;
begin
  C := GetEnvInt('PERF_TCP_SHORT_CONN_C', 100);
  SetLength(ConnThreads, C);
  LListener := TSocketListener.CreateTCP(TSocketAddress.Any(0));
  LListener.Start;
  try
    // 获取系统分配端口应从 Socket.LocalAddress 取值
    LPort := LListener.Socket.LocalAddress.Port;
    T0 := NowMs;
    for i := 0 to C-1 do ConnThreads[i] := TConnectThread.Create(LPort);
    for i := 0 to C-1 do begin ConnThreads[i].WaitFor; ConnThreads[i].Free; end;
    T1 := NowMs;
    WriteLn(Format('TCP短连接 %d 并发，总耗时=%d ms', [C, T1-T0]));
  finally
    LListener.Stop;
  end;
end;

procedure TTestCase_Perf.Test_Perf_TCP_LongConnections_RTT_Throughput;
var
  Clients, Iter, PayloadSize, AcceptTimeoutMs: Integer;
  LListener: ISocketListener;
  LPort: Word;
  ServerSock, ClientSock: ISocket;
  i, k: Integer;
  T0, T1: QWord;
  Payload, Buffer: TBytes;
begin
  Clients := GetEnvInt('PERF_TCP_LONG_CLIENTS', 10);
  Iter := GetEnvInt('PERF_TCP_LONG_ITER', 200);
  PayloadSize := GetEnvInt('PERF_PAYLOAD_SIZE', 512);
  AcceptTimeoutMs := GetEnvInt('PERF_ACCEPT_TIMEOUT_MS', 5000);

  SetLength(Payload, PayloadSize);
  for i := 0 to High(Payload) do Payload[i] := Byte(i and $FF);
  SetLength(Buffer, PayloadSize);

  LListener := TSocketListener.CreateTCP(TSocketAddress.Any(0));
  LListener.Start;
  try
    // 获取系统分配端口应从 Socket.LocalAddress 取值
    LPort := LListener.Socket.LocalAddress.Port;
    T0 := NowMs;
    for i := 1 to Clients do
    begin
      Sleep(10);
      ClientSock := TSocket.TCP;
      ClientSock.Connect(TSocketAddress.Localhost(LPort));
      ServerSock := LListener.AcceptWithTimeout(AcceptTimeoutMs);
      AssertNotNull('应成功接受连接', ServerSock);
      for k := 1 to Iter do
      begin
        AssertEquals(PayloadSize, ClientSock.Send(@Payload[0], PayloadSize));
        AssertEquals(PayloadSize, ServerSock.Receive(@Buffer[0], PayloadSize));
        AssertEquals(PayloadSize, ServerSock.Send(@Buffer[0], PayloadSize));
        AssertEquals(PayloadSize, ClientSock.Receive(@Buffer[0], PayloadSize));
      end;
      ClientSock.Close; ServerSock.Close;
    end;
    T1 := NowMs;
    WriteLn(Format('TCP长连接 %d * %d 次往返 Payload=%d bytes，总耗时=%d ms',[Clients, Iter, PayloadSize, T1-T0]));
  finally
    LListener.Stop;
  end;
end;

procedure TTestCase_Perf.Test_Perf_UDP_Throughput_Loss;
var
  Packets, PayloadSize, RecvTimeoutMs: Integer;
  Server, Client: ISocket;
  Addr: ISocketAddress;
  Port: Word;
  Payload, Buffer: TBytes;
  i: Integer;
  Sent, Recv: Integer;
  T0, T1: QWord;
  Ratio: Double;
begin
  Packets := GetEnvInt('PERF_UDP_PACKETS', 2000);
  PayloadSize := GetEnvInt('PERF_PAYLOAD_SIZE', 256);
  RecvTimeoutMs := GetEnvInt('PERF_UDP_RECV_TIMEOUT_MS', 10);

  SetLength(Payload, PayloadSize);
  for i := 0 to High(Payload) do Payload[i] := 123;
  SetLength(Buffer, PayloadSize);

  Server := TSocket.UDP;
  Server.Bind(TSocketAddress.Any(0));
  Port := Server.LocalAddress.Port;

  Client := TSocket.UDP;
  Addr := TSocketAddress.Localhost(Port);
  Server.ReceiveTimeout := RecvTimeoutMs;

  Sent := 0; Recv := 0;
  T0 := NowMs;
  for i := 1 to Packets do
    Inc(Sent, Client.SendTo(@Payload[0], PayloadSize, Addr));

  for i := 1 to Packets do
  begin
    if Server.ReceiveFrom(@Buffer[0], PayloadSize, Addr) = PayloadSize then
      Inc(Recv, PayloadSize);
  end;
  T1 := NowMs;

  if Sent > 0 then Ratio := Recv / Sent else Ratio := 0.0;
  WriteLn(Format('UDP 吞吐：SentBytes=%d, RecvBytes=%d, Loss=%d%%, 耗时=%d ms',
    [Sent, Recv, Round((1.0 - Ratio) * 100.0), T1-T0]));

  Server.Close; Client.Close;
end;

initialization
  if GetEnvironmentVariable('ENABLE_PERF') = '1' then
    RegisterTest(TTestCase_Perf);

end.

