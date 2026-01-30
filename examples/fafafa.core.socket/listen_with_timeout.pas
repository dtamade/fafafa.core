program listen_with_timeout;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.socket;

function GetParamValue(const Key, DefaultVal: string): string;
var
  i, L: Integer;
  P: string;
begin
  Result := DefaultVal;
  L := Length(Key);
  for i := 1 to ParamCount do
  begin
    P := ParamStr(i);
    if (Copy(P, 1, L) = Key) and ((Length(P) = L) or (P[L+1] = '=')) then
    begin
      if Length(P) = L then Exit('true');
      Exit(Copy(P, L+2, MaxInt));
    end;
  end;
end;

function GetIntParamValue(const Key: string; DefaultVal: Integer): Integer;
var
  S: string;
begin
  S := GetParamValue(Key, IntToStr(DefaultVal));
  try
    Result := StrToInt(S);
  except
    Result := DefaultVal;
  end;
end;

function HasFlag(const Key: string): Boolean;
begin
  Result := SameText(GetParamValue(Key, 'false'), 'true');
end;

procedure PrintUsage;
begin
  Writeln('Usage: listen_with_timeout [--ipv6] [--port=N] [--timeout=MS]');
  Writeln('  --ipv6        Listen on IPv6 (default: IPv4)');
  Writeln('  --port=N      Port to listen (default: 8080)');
  Writeln('  --timeout=MS  Accept timeout in milliseconds (default: 250)');
end;

var
  UseIPv6: Boolean;
  Port, TimeoutMs: Integer;
  Listener: ISocketListener;
  Client: ISocket;
begin
  if HasFlag('--help') or HasFlag('-h') then
  begin
    PrintUsage;
    Halt(0);
  end;

  UseIPv6 := HasFlag('--ipv6');
  Port := GetIntParamValue('--port', 8080);
  TimeoutMs := GetIntParamValue('--timeout', 250);

  if UseIPv6 then
    Writeln('Listening on [::]:', Port)
  else
    Writeln('Listening on 0.0.0.0:', Port);

  if UseIPv6 then
    Listener := TSocketListener.ListenTCPv6(Port)
  else
    Listener := TSocketListener.ListenTCP(Port);

  // 使用 Start/Stop 而非 Active 属性，避免接口属性编译器差异
  Listener.Start;
  try
    Writeln('Waiting for a client up to ', TimeoutMs, ' ms ...');
    try
      Client := Listener.AcceptWithTimeout(TimeoutMs);
      // 若实现抛异常，本行可能不会执行；若实现返回 nil，可兼容打印
      if Assigned(Client) then
      begin
        Writeln('Client connected: ', Client.RemoteAddress.ToString);
        // 演示常用选项（使用属性读写）
        Client.KeepAlive := True;
        Client.TcpNoDelay := True;
        Writeln('KeepAlive=', Client.KeepAlive, ', TcpNoDelay=', Client.TcpNoDelay);
        Client.Close;
      end
      else
        Writeln('No client within timeout (nil).');
    except
      on E: ESocketTimeoutError do
      begin
        Writeln('Accept timed out (expected for demo): ', E.Message);
      end;
      on E: Exception do
      begin
        Writeln('Accept failed: ', E.Message);
      end;
    end;
  finally
    Listener.Stop;
  end;
end.

