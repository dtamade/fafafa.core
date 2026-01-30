program echo_server;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  SysUtils, fafafa.core.socket;

function GetParamValue(const Key, DefaultVal: string): string;
var i, L: Integer; P: string;
begin
  Result := DefaultVal;
  L := Length(Key);
  for i := 1 to ParamCount do begin
    P := ParamStr(i);
    if (Copy(P,1,L)=Key) and ((Length(P)=L) or (P[L+1]='=')) then begin
      if Length(P)=L then Exit('true');
      Exit(Copy(P, L+2, MaxInt));
    end;
  end;
end;

function GetIntParamValue(const Key: string; DefaultVal: Integer): Integer;
var S: string;
begin
  S := GetParamValue(Key, IntToStr(DefaultVal));
  try Result := StrToInt(S); except Result := DefaultVal; end;
end;

function HasFlag(const Key: string): Boolean;
begin
  Result := SameText(GetParamValue(Key, 'false'), 'true');
end;

var
  Listener: ISocketListener;
  Client: ISocket;
  Port, TimeoutMs: Integer;
  UseIPv6: Boolean;
  Buf: array[0..4095] of Byte;
  N: Integer;
begin
  Port := GetIntParamValue('--port', 8080);
  TimeoutMs := GetIntParamValue('--timeout', 500);
  UseIPv6 := HasFlag('--ipv6');

  if UseIPv6 then
    Listener := TSocketListener.ListenTCPv6(Port)
  else
    Listener := TSocketListener.ListenTCP(Port);

  Listener.Active := True;
  if UseIPv6 then
    Writeln('echo_server listening on [::]:', Port, ' timeout=', TimeoutMs, 'ms')
  else
    Writeln('echo_server listening on 0.0.0.0:', Port, ' timeout=', TimeoutMs, 'ms');

  try
    while True do
    begin
      try
        Client := Listener.AcceptWithTimeout(TimeoutMs);
        if Assigned(Client) then
        begin
          Writeln('Client: ', Client.RemoteAddress.ToString);
          // 简单回显：阻塞读一次，写回
          N := Client.Receive(@Buf[0], SizeOf(Buf));
          if N > 0 then
            Client.Send(@Buf[0], N);
          Client.Close;
        end;
      except
        on E: ESocketTimeoutError do ; // 忽略超时，继续循环
        on E: Exception do Writeln('Accept failed: ', E.Message);
      end;
    end;
  finally
    Listener.Active := False;
  end;
end.

