program echo_client;

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
  Host: string;
  Port: Integer;
  Msg: string;
  UseIPv6: Boolean;
  S: ISocket;
  A: ISocketAddress;
  Buf: TBytes;
  N: Integer;
begin
  Host := GetParamValue('--host', '127.0.0.1');
  Port := GetIntParamValue('--port', 8080);
  Msg  := GetParamValue('--message', 'hello');
  UseIPv6 := HasFlag('--ipv6');

  if UseIPv6 then begin
    S := TSocket.TCPv6;
    A := TSocketAddress.IPv6(Host, Port);
  end else begin
    S := TSocket.TCP;
    A := TSocketAddress.IPv4(Host, Port);
  end;

  try
    S.Connect(A);
    Buf := TEncoding.UTF8.GetBytes(Msg);
    S.Send(Buf);

    SetLength(Buf, 4096);
    N := S.Receive(@Buf[0], Length(Buf));
    if N > 0 then begin
      SetLength(Buf, N);
      Writeln('echo: ', TEncoding.UTF8.GetString(Buf));
    end else
      Writeln('no data received');

    S.Close;
  except
    on E: Exception do begin
      Writeln('echo_client error: ', E.Message);
      Halt(1);
    end;
  end;
end.

