{$CODEPAGE UTF8}
program example_socket;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.socket;

{**
 * Socket 使用示例程序
 *
 * 本程序演示 fafafa.core.socket 模块的典型用法：
 * 1. TCP 客户端/服务器通信
 * 2. UDP 数据报通信
 * 3. Socket 选项设置
 * 4. 地址解析和验证
 *}

procedure ShowUsage;
begin
  WriteLn('fafafa.core.socket 使用示例');
  WriteLn('');
  WriteLn('用法:');
  WriteLn('  example_socket tcp-server <port>         - 启动TCP服务器');
  WriteLn('  example_socket tcp-client <host> <port>  - 连接TCP服务器');
  WriteLn('  example_socket udp-server <port>         - 启动UDP服务器');
  WriteLn('  example_socket udp-client <host> <port>  - 发送UDP消息');
  WriteLn('  example_socket tcp-server-nb <port>      - 启动TCP非阻塞服务器');
  WriteLn('  example_socket tcp-client-nb <host> <port> [message] - 连接TCP非阻塞服务器，发送可选消息');
  WriteLn('  example_socket address-demo              - 地址解析演示');
  WriteLn('  example_socket udp-server-nb <port>                     - 启动UDP非阻塞服务器');
  WriteLn('  example_socket udp-client-nb <host> <port> [message]     - UDP 非阻塞客户端，发送可选消息');
  WriteLn('');
  WriteLn('示例:');
  WriteLn('  example_socket tcp-server 8080');
  WriteLn('  example_socket tcp-client localhost 8080');
  WriteLn('  example_socket udp-server 9090');
  WriteLn('  example_socket udp-client 127.0.0.1 9090');
  WriteLn('  example_socket address-demo');
end;

procedure RunTCPServer(const aPort: string);
var
  LListener: ISocketListener;
  LClientSocket: ISocket;
  LData: TBytes;
  LMessage: string;
begin
  WriteLn('启动 TCP 服务器，端口: ', aPort);

  try
    // 使用便捷方法创建监听器 - 在所有接口上监听
    LListener := TSocketListener.ListenTCP(StrToInt(aPort));
    WriteLn('监听地址: ', LListener.ListenAddress.ToString);
    LListener.Backlog := 10;

    // 启动监听
    LListener.Start;
    WriteLn('服务器已启动，等待客户端连接...');
    WriteLn('按 Ctrl+C 退出');

    // 接受客户端连接
    while True do
    begin
      try
        LClientSocket := LListener.AcceptClient;
        if Assigned(LClientSocket.RemoteAddress) then
          WriteLn('客户端已连接: ', LClientSocket.RemoteAddress.ToString)
        else
          WriteLn('客户端已连接');

        // 接收数据 - 使用正确的 Receive 方法
        LData := LClientSocket.Receive(1024);

        LMessage := TEncoding.UTF8.GetString(LData);
        WriteLn('收到消息: ', LMessage);

        // 回复消息
        LMessage := '服务器收到: ' + LMessage;
        LData := TEncoding.UTF8.GetBytes(LMessage);
        LClientSocket.Send(LData);

        // 关闭客户端连接
        LClientSocket.Close;
        WriteLn('客户端连接已关闭');

      except
        on E: Exception do
          WriteLn('处理客户端时出错: ', E.Message);
      end;
    end;

  except
    on E: Exception do
    begin
      WriteLn('TCP服务器错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end;

procedure RunTCPClient(const aHost, aPort: string);
var
  LSocket: ISocket;
  LAddress: ISocketAddress;
  LData: TBytes;
  LMessage: string;
  LBytesReceived: Integer;
begin
  WriteLn('连接 TCP 服务器: ', aHost, ':', aPort);

  try
    // 使用便捷方法创建TCP客户端Socket
    LSocket := TSocket.TCP;

    // 设置Socket选项
    LSocket.ReuseAddress := True;
    LSocket.TcpNoDelay := True;
    LSocket.SendTimeout := 5000;
    LSocket.ReceiveTimeout := 5000;

    // 使用便捷方法创建服务器地址
    LAddress := TSocketAddress.IPv4(aHost, StrToInt(aPort));
    WriteLn('服务器地址: ', LAddress.ToString);

    // 连接服务器
    LSocket.Connect(LAddress);
    WriteLn('已连接到服务器');

    // 发送消息
    LMessage := '你好，这是来自客户端的消息！';
    LData := TEncoding.UTF8.GetBytes(LMessage);
    LSocket.Send(LData);
    WriteLn('已发送消息: ', LMessage);

    // 接收回复
    SetLength(LData, 1024);
    LBytesReceived := LSocket.Receive(@LData[0], Length(LData));
    SetLength(LData, LBytesReceived);

    LMessage := TEncoding.UTF8.GetString(LData);
    WriteLn('收到回复: ', LMessage);

    // 关闭连接
    LSocket.Close;
    WriteLn('连接已关闭');

  except
    on E: Exception do
    begin
      WriteLn('TCP客户端错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end;

procedure RunTCPServerNB(const aPort: string);
var
  Listener: ISocketListener;
  Srv: ISocket;
  Header: array[0..3] of Byte;
  Len: LongWord;
  Payload: TBytes;
  Got, ReadTotal, Sent, TmpInt: Integer;
begin
  WriteLn('启动 TCP 非阻塞服务器，端口: ', aPort);
  Listener := TSocketListener.ListenTCP(StrToInt(aPort));
  Listener.Start;
  try
    Srv := Listener.AcceptWithTimeout(5000);
    if Srv = nil then begin WriteLn('等待客户端超时'); Exit; end;
    Srv.NonBlocking := True;

    // 读取4字节小端长度
    // Fallback precise receive loop
while true do begin
  var got := Srv.Receive(@Header[0], 4);
  if got = 4 then break;
  if got <= 0 then raise Exception.Create('Receive header failed');
end;
    Len := LongWord(Header[0]) or (LongWord(Header[1]) shl 8) or (LongWord(Header[2]) shl 16) or (LongWord(Header[3]) shl 24);
    SetLength(Payload, Len);
    // 精确接收 Payload
    // Fallback precise receive loop for payload
var readTotal := 0;
while readTotal < Integer(Len) do begin
  var r := Srv.Receive(@Payload[readTotal], Integer(Len) - readTotal);
  if r <= 0 then raise Exception.Create('Receive payload failed');
  Inc(readTotal, r);
end;
    WriteLn('收到长度: ', Len, ' 文本: ', TEncoding.UTF8.GetString(Payload));

    // 回显：先发长度头，再发正文
    // Fallback send-all loop for header
var sent := 0;
while sent < 4 do begin
  var s := Srv.Send(@Header[sent], 4 - sent);
  if s <= 0 then raise Exception.Create('Send header failed');
  Inc(sent, s);
end;
    // Fallback send-all loop for payload
sent := 0;
while sent < Integer(Len) do begin
  var s := Srv.Send(@Payload[sent], Integer(Len) - sent);
  if s <= 0 then raise Exception.Create('Send payload failed');
  Inc(sent, s);
end;
    Srv.Close;
  finally
    Listener.Stop;
  end;
end;

procedure RunTCPClientNB(const aHost, aPort: string; const aMessage: string);
var
  Cli: ISocket;
  Header: array[0..3] of Byte;
  Len: LongWord;
  Payload, Echo: TBytes;
begin
  Cli := TSocket.TCP;
  Cli.Connect(TSocketAddress.IPv4(aHost, StrToInt(aPort)));
  Cli.NonBlocking := True;

  if aMessage <> '' then
    Payload := TEncoding.UTF8.GetBytes(aMessage)
  else
    Payload := TEncoding.UTF8.GetBytes('NonBlocking + SendAll/ReceiveExact demo');
  Len := Length(Payload);
  Header[0] := Byte(Len and $FF);
  Header[1] := Byte((Len shr 8) and $FF);
  Header[2] := Byte((Len shr 16) and $FF);
  Header[3] := Byte((Len shr 24) and $FF);

  // 发送：长度 + 正文
  // Fallback send-all loop for header
var sent2 := 0;
while sent2 < 4 do begin
  var s2 := Cli.Send(@Header[sent2], 4 - sent2);
  if s2 <= 0 then raise Exception.Create('Send header failed');
  Inc(sent2, s2);
end;
  // Fallback send-all loop for payload
sent2 := 0;
while sent2 < Integer(Len) do begin
  var s2 := Cli.Send(@Payload[sent2], Integer(Len) - sent2);
  if s2 <= 0 then raise Exception.Create('Send payload failed');
  Inc(sent2, s2);
end;
  WriteLn('已发送长度: ', Len);

  // 接收回显：长度 + 正文
  // Fallback precise receive loop for header
var got2 := 0;
while got2 < 4 do begin
  var r2 := Cli.Receive(@Header[got2], 4 - got2);
  if r2 <= 0 then raise Exception.Create('Receive header failed');
  Inc(got2, r2);
end;
  Len := LongWord(Header[0]) or (LongWord(Header[1]) shl 8) or (LongWord(Header[2]) shl 16) or (LongWord(Header[3]) shl 24);
  // Fallback to manual exact receive for echo
SetLength(Echo, Len);
var read2 := 0;
while read2 < Integer(Len) do begin
  var r3 := Cli.Receive(@Echo[read2], Integer(Len) - read2);
  if r3 <= 0 then raise Exception.Create('Receive echo failed');
  Inc(read2, r3);
end;
  WriteLn('收到回显长度: ', Len, ' 文本: ', TEncoding.UTF8.GetString(Echo));
  Cli.Close;
end;

// 前向声明，避免顺序依赖
procedure RunUDPServerNB(const aPort: string); forward;
procedure RunUDPClientNB(const aHost, aPort, aMessage: string); forward;





procedure RunUDPServerNB(const aPort: string);
var
  S: ISocket;
  FromAddr: ISocketAddress;
  Data: TBytes;
  Tries: Integer;
begin
  S := TSocket.UDP;
  S.Bind(TSocketAddress.Any(StrToInt(aPort)));
  S.NonBlocking := True;
  Tries := 0;
  while Tries < 200 do
  begin
    try
      Data := S.ReceiveFrom(2048, FromAddr);
      if Length(Data) > 0 then
      begin
        S.SendTo(Data, FromAddr);
        WriteLn('UDP server nb echoed length: ', Length(Data));
        Break;
      end;
    except
      on E: Exception do
      begin
        Inc(Tries);
        Sleep(10);
      end;
    end;
  end;
end;

procedure RunUDPClientNB(const aHost, aPort, aMessage: string);
var
  C: ISocket;
  ServerAddr: ISocketAddress;
  Payload, Resp: TBytes;
  FromAddr: ISocketAddress;
  Tries: Integer;
begin
  C := TSocket.UDP;
  ServerAddr := TSocketAddress.IPv4(aHost, StrToInt(aPort));
  C.NonBlocking := True;
  if aMessage <> '' then
    Payload := TEncoding.UTF8.GetBytes(aMessage)
  else
    Payload := TEncoding.UTF8.GetBytes('Hello UDP NB');

  C.SendTo(Payload, ServerAddr);
  Tries := 0;
  while Tries < 200 do
  begin
    try
      Resp := C.ReceiveFrom(2048, FromAddr);
      if Length(Resp) > 0 then
      begin
        WriteLn('UDP client nb received length: ', Length(Resp), ' text: ', TEncoding.UTF8.GetString(Resp));
        Break;
      end;
    except
      on E: Exception do
      begin
        Inc(Tries);
        Sleep(10);
      end;
    end;
  end;
end;

procedure RunUDPServer(const aPort: string);


var
  LSocket: ISocket;
  LAddress: ISocketAddress;
  LFromAddress: ISocketAddress;
  LData: TBytes;
  LMessage: string;
begin
  WriteLn('启动 UDP 服务器，端口: ', aPort);

  try
    // 使用便捷方法创建UDP Socket
    LSocket := TSocket.UDP;

    // 使用便捷方法创建绑定地址
    LAddress := TSocketAddress.Any(StrToInt(aPort));
    WriteLn('绑定地址: ', LAddress.ToString);

    // 绑定地址
    LSocket.Bind(LAddress);
    WriteLn('UDP服务器已启动，等待数据...');
    WriteLn('按 Ctrl+C 退出');

    // 接收数据
    while True do
    begin
      try
        // 使用正确的 ReceiveFrom 方法
        LData := LSocket.ReceiveFrom(1024, LFromAddress);

        LMessage := TEncoding.UTF8.GetString(LData);
        WriteLn('收到来自 ', LFromAddress.ToString, ' 的消息: ', LMessage);

        // 回复消息
        LMessage := 'UDP服务器收到: ' + LMessage;
        LData := TEncoding.UTF8.GetBytes(LMessage);
        LSocket.SendTo(LData, LFromAddress);

      except
        on E: Exception do
          WriteLn('处理UDP数据时出错: ', E.Message);
      end;
    end;

  except
    on E: Exception do
    begin
      WriteLn('UDP服务器错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end;

procedure RunUDPClient(const aHost, aPort: string);
var
  LSocket: ISocket;
  LAddress: ISocketAddress;
  LFromAddress: ISocketAddress;
  LData: TBytes;
  LMessage: string;
begin
  WriteLn('发送 UDP 消息到: ', aHost, ':', aPort);

  try
    // 使用便捷方法创建UDP Socket
    LSocket := TSocket.UDP;

    // 使用便捷方法创建目标地址
    LAddress := TSocketAddress.IPv4(aHost, StrToInt(aPort));
    WriteLn('目标地址: ', LAddress.ToString);

    // 发送消息
    LMessage := '你好，这是UDP消息！';
    LData := TEncoding.UTF8.GetBytes(LMessage);
    LSocket.SendTo(LData, LAddress);
    WriteLn('已发送消息: ', LMessage);

    // 接收回复 - 使用正确的 ReceiveFrom 方法
    LData := LSocket.ReceiveFrom(1024, LFromAddress);

    LMessage := TEncoding.UTF8.GetString(LData);
    WriteLn('收到来自 ', LFromAddress.ToString, ' 的回复: ', LMessage);

    // 关闭Socket
    LSocket.Close;
    WriteLn('UDP通信完成');

  except
    on E: Exception do
    begin
      WriteLn('UDP客户端错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end;

procedure RunAddressDemo;
var
  LAddress: ISocketAddress;
begin
  WriteLn('Socket 地址解析演示');
  WriteLn('==================');

  try
    // 传统方法
    WriteLn('传统创建方法:');
    LAddress := TSocketAddress.CreateIPv4('192.168.1.100', 8080);
    WriteLn('  CreateIPv4: ', LAddress.ToString);

    // 便捷方法演示
    WriteLn('');
    WriteLn('便捷创建方法:');
    LAddress := TSocketAddress.IPv4('192.168.1.100', 8080);
    WriteLn('  IPv4: ', LAddress.ToString);

    LAddress := TSocketAddress.IPv6('::1', 9090);
    WriteLn('  IPv6: ', LAddress.ToString);

    LAddress := TSocketAddress.Localhost(3000);
    WriteLn('  Localhost: ', LAddress.ToString);

    LAddress := TSocketAddress.LocalhostIPv6(3001);
    WriteLn('  LocalhostIPv6: ', LAddress.ToString);

    LAddress := TSocketAddress.Any(8080);
    WriteLn('  Any (服务器绑定): ', LAddress.ToString);

    LAddress := TSocketAddress.AnyIPv6(8081);
    WriteLn('  AnyIPv6 (服务器绑定): ', LAddress.ToString);

    WriteLn('');
    WriteLn('地址属性:');
    LAddress := TSocketAddress.IPv4('192.168.1.100', 8080);
    WriteLn('  主机: ', LAddress.Host);
    WriteLn('  端口: ', LAddress.Port);
    WriteLn('  地址族: ', Ord(LAddress.Family));
    WriteLn('  有效性: ', LAddress.IsValid);
    WriteLn('');

    // 无效地址测试
    WriteLn('无效地址测试:');
    try
      LAddress := TSocketAddress.IPv4('999.999.999.999', 8080);
      WriteLn('  意外：无效地址被接受了');
    except
      on E: Exception do
        WriteLn('  正确：无效地址被拒绝 - ', E.Message);
    end;

  except
    on E: Exception do
    begin
      WriteLn('地址演示错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
end;

var
  LCommand: string;
  LMsg: string;
  I: Integer;
begin
  WriteLn('fafafa.core.socket 示例程序');
  WriteLn('============================');
  WriteLn('');

  if ParamCount = 0 then
  begin
    ShowUsage;
    Exit;
  end;

  LCommand := LowerCase(ParamStr(1));

  case LCommand of
    'tcp-server':
      if ParamCount >= 2 then
        RunTCPServer(ParamStr(2))
      else
        WriteLn('错误: 缺少端口参数');

    'tcp-client':
      if ParamCount >= 3 then
        RunTCPClient(ParamStr(2), ParamStr(3))
      else
        WriteLn('错误: 缺少主机或端口参数');

    'udp-server':
      if ParamCount >= 2 then
        RunUDPServer(ParamStr(2))
      else
        WriteLn('错误: 缺少端口参数');

    'udp-client':
      if ParamCount >= 3 then
        RunUDPClient(ParamStr(2), ParamStr(3))
      else
        WriteLn('错误: 缺少主机或端口参数');

    'udp-server-nb':
      if ParamCount >= 2 then RunUDPServerNB(ParamStr(2)) else WriteLn('错误: 缺少端口参数');

    'udp-client-nb':
      if ParamCount >= 3 then
      begin
        LMsg := '';
        if ParamCount >= 4 then
        begin
          LMsg := ParamStr(4);
          if ParamCount > 4 then
            for I := 5 to ParamCount do
              LMsg := LMsg + ' ' + ParamStr(I);
        end;
        RunUDPClientNB(ParamStr(2), ParamStr(3), LMsg);
      end
      else
        WriteLn('错误: 缺少主机或端口参数');

    'address-demo':
      RunAddressDemo;

    'tcp-server-nb':
      if ParamCount >= 2 then RunTCPServerNB(ParamStr(2)) else WriteLn('错误: 缺少端口参数');

    'tcp-client-nb':
      if ParamCount >= 3 then
      begin
        // 将第4到最后的参数合并为一条消息，支持包含空格
        LMsg := '';
        if ParamCount >= 4 then
        begin
          LMsg := ParamStr(4);
          if ParamCount > 4 then
            for I := 5 to ParamCount do
              LMsg := LMsg + ' ' + ParamStr(I);
        end;
        RunTCPClientNB(ParamStr(2), ParamStr(3), LMsg);
      end
      else
        WriteLn('错误: 缺少主机或端口参数');
  else
  begin
    WriteLn('错误: 未知命令 "', LCommand, '"');
    WriteLn('');
    ShowUsage;
    ExitCode := 1;
  end;
end;
end.
