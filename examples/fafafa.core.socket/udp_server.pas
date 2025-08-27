program udp_server;

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
  S: ISocket;
  BindAddr, FromAddr: ISocketAddress;
  UseIPv6, Verbose: Boolean;
  Port: Integer;
  Buf: TBytes;
  Msg, BindHost: string;
begin
  Port := GetIntParamValue('--port', 9090);
  UseIPv6 := HasFlag('--ipv6');
  Verbose := HasFlag('--verbose');
  BindHost := GetParamValue('--bind-host', '');

  if UseIPv6 then begin
    S := TSocket.UDPv6;
    if BindHost = '' then BindHost := '::';
    BindAddr := TSocketAddress.IPv6(BindHost, Port);
  end else begin
    S := TSocket.UDP;
    if BindHost = '' then BindHost := '0.0.0.0';
    BindAddr := TSocketAddress.IPv4(BindHost, Port);
  end;

  try
    S.Bind(BindAddr);
    S.ReceiveTimeout := 1000; // 1s 轮询，便于 Ctrl+C 退出
    if UseIPv6 then
      Writeln('udp_server listening on [', BindHost, ']:', Port)
    else
      Writeln('udp_server listening on ', BindHost, ':', Port);
    if Verbose then
    begin
      if UseIPv6 then
        Writeln('family=IPv6 bind-host=', BindHost, ' port=', Port)
      else
        Writeln('family=IPv4 bind-host=', BindHost, ' port=', Port);
    end;

    SetLength(Buf, 65535);
    while True do
    begin
      try
        Buf := S.ReceiveFrom(4096, FromAddr);
        Msg := TEncoding.UTF8.GetString(Buf);
        if Verbose then
          Writeln('received ', Length(Buf), ' bytes from ', FromAddr.ToString);
        Writeln('recv from ', FromAddr.ToString, ': ', Msg);
        // echo back
        S.SendTo(Buf, FromAddr);
        if Verbose then
          Writeln('echoed ', Length(Buf), ' bytes to ', FromAddr.ToString);
      except
        on E: ESocketTimeoutError do ; // ignore and continue
        on E: Exception do Writeln('recv error: ', E.Message);
      end;
    end;
  except
    on E: Exception do begin
      Writeln('udp_server error: ', E.Message);
      Halt(1);
    end;
  end;
end.

