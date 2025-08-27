program example_echo_min_poll_nb;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.socket;

// 最小非阻塞 + 轮询 客户端示例：
// 连接本地 127.0.0.1:8080，发送 "hello"，读取回显后退出。
// 需先运行 echo_server（已在 examples/fafafa.core.socket/bin 提供）。

procedure Main;
var
  S: ISocket;
  Poller: ISocketPoller;
  Sent: Boolean = False;
  Buf: array[0..1023] of byte;
  N, Err: Integer;
  Msg: RawByteString;
  I: Integer;
  E: TSocketPollResult;
  Ready: TSocketPollResults;
begin
  // 1) 建立连接并设为非阻塞
  S := TSocket.ConnectTo('127.0.0.1', 8080);
  S.SetNonBlocking(True);

  // 2) 注册到默认轮询器（跨平台自动选择）
  Poller := CreateDefaultPoller;
  Poller.RegisterSocket(S, [seRead, seWrite]);

  // 3) 事件循环（Try* 非阻塞风格）
  while True do
  begin
    if Poller.Poll(500) <= 0 then
      Continue;

    Ready := Poller.GetReadyEvents;
    for I := 0 to High(Ready) do
    begin
      E := Ready[I];
      // 可写：尝试发送一次
      if (seWrite in E.Events) and (not Sent) then
      begin
        Msg := 'hello' + LineEnding;
        // 注意：RawByteString 首元素索引为 1
        if S.TrySend(@Msg[1], Length(Msg), Err) >= 0 then
          Sent := True
        else if (Err <> SOCKET_EWOULDBLOCK) and (Err <> SOCKET_EAGAIN) and (Err <> SOCKET_EINTR) then
          raise ESocketSendError.Create('send failed', Err, S.Handle);
      end;

      // 可读：读取数据
      if (seRead in E.Events) then
      begin
        N := S.TryReceive(@Buf[0], SizeOf(Buf), Err);
        if N > 0 then
        begin
          // 打印收到的数据，然后退出
          WriteLn('recv: ', Copy(PAnsiChar(@Buf[0])^, 1, N));
          Exit;
        end
        else if N = 0 then
        begin
          // 对端关闭
          Exit;
        end
        else if (Err <> SOCKET_EWOULDBLOCK) and (Err <> SOCKET_EAGAIN) and (Err <> SOCKET_EINTR) then
        begin
          raise ESocketReceiveError.Create('recv failed', Err, S.Handle);
        end;
      end;
    end;
  end;
end;

begin
  try
    Main;
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      Halt(1);
    end;
  end;
end.

