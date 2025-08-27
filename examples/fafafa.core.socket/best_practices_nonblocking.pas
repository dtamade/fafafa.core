{$CODEPAGE UTF8}
program best_practices_nonblocking;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.socket;

// Simple demo: non-blocking connect + frame send/receive (length-prefixed)

function ConnectWithTimeout(const Host: string; Port, TimeoutMs: Integer): ISocket;
var
  S: ISocket;
  Deadline: QWord;
begin
  S := TSocket.TCP;
  S.SetBlocking(False);
  Deadline := GetTickCount64 + QWord(TimeoutMs);
  S.Connect(TSocketAddress.Create(Host, Port));
  while not S.IsConnected do
  begin
    if GetTickCount64 >= Deadline then
      raise Exception.Create('connect timeout');
    Sleep(1);
  end;
  Result := S;
end;

procedure SendAll(S: ISocket; const P: PByte; L: Integer);
var
  Sent, N: Integer;
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
var
  Read, N: Integer;
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
var
  H: array[0..3] of Byte;
  L: LongWord;
begin
  L := Length(B);
  Move(L, H[0], 4);
  SendAll(S, @H[0], 4);
  if L > 0 then SendAll(S, @B[0], L);
end;

function ReceiveFrame(S: ISocket; MaxLen: LongWord): TBytes;
var
  H: array[0..3] of Byte;
  L: LongWord;
begin
  ReceiveExact(S, @H[0], 4);
  Move(H[0], L, 4);
  if L > MaxLen then raise Exception.Create('frame too large');
  SetLength(Result, L);
  if L > 0 then ReceiveExact(S, @Result[0], L);
end;

procedure ClientDemo(const Host: string; Port: Integer; const Msg: string);
var
  C: ISocket;
  Bytes, Echo: TBytes;
begin
  C := ConnectWithTimeout(Host, Port, 2000);
  Bytes := TEncoding.UTF8.GetBytes(Msg);
  SendFrame(C, Bytes);
  Echo := ReceiveFrame(C, 1 shl 20);
  Writeln('Echo: ', TEncoding.UTF8.GetString(Echo));
  C.Close;
end;

procedure ServerOnce(Port: Integer);
var
  L: ISocketListener;
  S, C: ISocket;
  Hdr: array[0..3] of Byte;
  Len: LongWord;
  Payload: TBytes;
begin
  L := TSocketListener.CreateTCP(TSocketAddress.Any(Port));
  L.Start;
  try
    C := TSocket.TCP;
    C.Connect(TSocketAddress.Create('127.0.0.1', Port, afInet));
    S := L.AcceptWithTimeout(1000);
    if S = nil then raise Exception.Create('failed to accept');

    // Read frame from C and echo back
    Payload := TEncoding.UTF8.GetBytes('hello');
    // Client path
    SendFrame(C, Payload);
    // Server path
    ReceiveExact(S, @Hdr[0], 4);
    Move(Hdr[0], Len, 4);
    SetLength(Payload, Len);
    if Len > 0 then ReceiveExact(S, @Payload[0], Len);
    // echo
    SendFrame(S, Payload);

    S.Close; C.Close;
  finally
    L.Stop;
  end;
end;

procedure RunServerOnly(const PortStr: string);
var L: ISocketListener; S: ISocket; Hdr: array[0..3] of Byte; Len: LongWord; Payload: TBytes;
begin
  L := TSocketListener.CreateTCP(TSocketAddress.Any(StrToInt(PortStr)));
  L.Start;
  try
    Writeln('Server listening on ', L.ListenAddress.ToString);
    S := L.AcceptClient;
    // Echo one frame
    ReceiveExact(S, @Hdr[0], 4);
    Move(Hdr[0], Len, 4);
    SetLength(Payload, Len);
    if Len > 0 then ReceiveExact(S, @Payload[0], Len);
    SendFrame(S, Payload);
    S.Close;
  finally
    L.Stop;
  end;
end;

begin
  if (ParamCount >= 1) and (ParamStr(1) = '--demo') then
  begin
    ServerOnce(0);
  end
  else if (ParamCount >= 2) and (ParamStr(1) = '--server-only') then
  begin
    RunServerOnly(ParamStr(2));
  end
  else if (ParamCount >= 4) and (ParamStr(1) = '--client-only') then
  begin
    ClientDemo(ParamStr(2), StrToInt(ParamStr(3)), ParamStr(4));
  end
  else if ParamCount >= 3 then
  begin
    ClientDemo(ParamStr(1), StrToInt(ParamStr(2)), ParamStr(3));
  end
  else
  begin
    Writeln('Usage:');
    Writeln('  best_practices_nonblocking <host> <port> <message>');
    Writeln('  best_practices_nonblocking --demo');
    Writeln('  best_practices_nonblocking --server-only <port>');
    Writeln('  best_practices_nonblocking --client-only <host> <port> <message>');
  end;
end.

