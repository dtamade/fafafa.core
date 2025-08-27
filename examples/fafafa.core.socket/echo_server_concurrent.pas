program echo_server_concurrent;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  Classes, SysUtils,
  fafafa.core.socket;

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

type
  TEchoThread = class(TThread)
  private
    FCli: ISocket;
  protected
    procedure Execute; override;
  public
    constructor Create(const S: ISocket);
  end;

constructor TEchoThread.Create(const S: ISocket);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FCli := S;
  Start;
end;

procedure TEchoThread.Execute;
var
  Buf: array[0..4095] of Byte;
  N: Integer;
begin
  try
    N := FCli.Receive(@Buf[0], SizeOf(Buf));
    if N > 0 then FCli.Send(@Buf[0], N);
  except
    on E: Exception do ;
  end;
  FCli.Close;
end;

var
  L: ISocketListener;
  C: ISocket;
  Port, TimeoutMs: Integer;
  UseIPv6: Boolean;
begin
  Port := GetIntParamValue('--port', 8081);
  TimeoutMs := GetIntParamValue('--timeout', 200);
  UseIPv6 := HasFlag('--ipv6');
  if UseIPv6 then L := TSocketListener.ListenTCPv6(Port) else L := TSocketListener.ListenTCP(Port);

  L.Active := True;
  if UseIPv6 then
    Writeln('echo_server_concurrent listening on [::]:', Port, ' timeout=', TimeoutMs, 'ms')
  else
    Writeln('echo_server_concurrent listening on 0.0.0.0:', Port, ' timeout=', TimeoutMs, 'ms');
  try
    while True do
    begin
      try
        C := L.AcceptWithTimeout(TimeoutMs);
        if Assigned(C) then
        begin
          Writeln('Client: ', C.RemoteAddress.ToString);
          TEchoThread.Create(C);
        end;
      except
        on E: ESocketTimeoutError do ;
        on E: Exception do Writeln('Accept failed: ', E.Message);
      end;
    end;
  finally
    L.Active := False;
  end;
end.

