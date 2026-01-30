program udp_client;

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
  Target: ISocketAddress;
  UseIPv6, Verbose: Boolean;
  Host, SrcHost, Msg: string;
  Port, TimeoutMs: Integer;
  Buf: TBytes;
  From: ISocketAddress;
begin
  Host := GetParamValue('--host', '127.0.0.1');
  SrcHost := GetParamValue('--source-host', '');
  Port := GetIntParamValue('--port', 9090);
  Msg  := GetParamValue('--message', 'hello-udp');
  TimeoutMs := GetIntParamValue('--timeout', 5000);
  UseIPv6 := HasFlag('--ipv6');
  Verbose := HasFlag('--verbose');

  if UseIPv6 then begin
    S := TSocket.UDPv6;
    Target := TSocketAddress.IPv6(Host, Port);
  end else begin
    S := TSocket.UDP;
    Target := TSocketAddress.IPv4(Host, Port);
  end;

  try
    // 可选：绑定源地址，便于 IPv6 回环/指定接口测试
    if SrcHost <> '' then begin
      if UseIPv6 then
        S.Bind(TSocketAddress.IPv6(SrcHost, 0))
      else
        S.Bind(TSocketAddress.IPv4(SrcHost, 0));
      if Verbose then Writeln('bound source=', SrcHost);
    end;

    Buf := TEncoding.UTF8.GetBytes(Msg);
    S.SendTo(Buf, Target);
    if Verbose then Writeln('sent ', Length(Buf), ' bytes to ', Target.ToString);
    Writeln('sent: ', Msg);

    S.ReceiveTimeout := TimeoutMs;
    Buf := S.ReceiveFrom(4096, From);
    if Verbose then Writeln('received ', Length(Buf), ' bytes from ', From.ToString);
    Writeln('recv from ', From.ToString, ': ', TEncoding.UTF8.GetString(Buf));

    S.Close;
  except
    on E: ESocketTimeoutError do begin
      Writeln('timeout waiting for reply (', TimeoutMs, ' ms)');
      Halt(2);
    end;
    on E: Exception do begin
      Writeln('udp_client error: ', E.Message);
      Halt(1);
    end;
  end;
end.

