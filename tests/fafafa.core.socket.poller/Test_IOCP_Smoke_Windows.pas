unit Test_IOCP_Smoke_Windows;

{$mode objfpc}{$H+}

interface

implementation

{$IFDEF WINDOWS}
{$IFDEF FAFAFA_SOCKET_POLLER_EXPERIMENTAL}

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.socket,
  fafafa.core.socket.poller;

type
  TTestCase_IOCP_Smoke = class(TTestCase)
  published
    procedure Test_IOCP_Smoke_ReadReady_AllowsNonNegative;
  end;

procedure TTestCase_IOCP_Smoke.Test_IOCP_Smoke_ReadReady_AllowsNonNegative;
var
  LPoller: IAdvancedSocketPoller;
  LServer: ISocketListener;
  LClient: ISocket;
  N: Integer;
begin
  LPoller := TSocketPollerFactory.CreateIOCP(128);
  AssertNotNull('IOCP 轮询器应创建成功', LPoller);
  AssertTrue('GetPollerType 应包含 IOCP', Pos('IOCP', LPoller.GetPollerType) = 1);

  LServer := TSocketListener.ListenTCP(8111);
  LServer.Start;
  LPoller.RegisterSocket(LServer.Socket, [seRead]);

  LClient := TSocket.CreateTCP;
  LClient.Connect(TSocketAddress.Localhost(8111));

  N := LPoller.Poll(500);
  AssertTrue('IOCP Poll 调用成功（允许0）', N >= 0);

  LClient.Close;
  LServer.Stop;
end;

initialization
  RegisterTest(TTestCase_IOCP_Smoke);

{$ENDIF}
{$ENDIF}

end.


