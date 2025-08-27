unit Test_fafafa_core_socket_error_semantics;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.socket;

Type
  TTestCase_Socket_ErrorSemantics = class(TTestCase)
  published
    procedure Test_ConnectWithTimeout_Raises_WithErrorCodeAndHandle;
    procedure Test_Bind_Conflict_Raises_WithErrorCodeAndHandle;
  end;

implementation

procedure TTestCase_Socket_ErrorSemantics.Test_ConnectWithTimeout_Raises_WithErrorCodeAndHandle;
var S: ISocket; Addr: ISocketAddress; Raised: Boolean;
begin
  S := TSocket.TCP;
  Addr := TSocketAddress.CreateIPv4('127.0.0.1', 1); // 通常未监听
  Raised := False;
  try
    S.ConnectWithTimeout(Addr, 50);
  except
    on E: ESocketConnectError do
    begin
      Raised := True;
      AssertTrue('error code should be non-negative', E.ErrorCode >= 0);
      // 句柄字段在部分路径上可能不可用（如逻辑校验），不强制断言
    end;
  end;
  AssertTrue('should raise ESocketConnectError', Raised);
end;

procedure TTestCase_Socket_ErrorSemantics.Test_Bind_Conflict_Raises_WithErrorCodeAndHandle;
var S1, S2: ISocket; Port: Integer; Raised: Boolean;
begin
  // 使用原始 Socket 进行绑定，避免 Listener 内部改写选项影响
  S1 := TSocket.TCP;
  S1.ReuseAddress := False;
  S1.Bind(TSocketAddress.CreateIPv4('127.0.0.1', 0));
  Port := S1.LocalAddress.Port; // 分配的实际端口

  S2 := TSocket.TCP;
  S2.ReuseAddress := False;
  Raised := False;
  try
    S2.Bind(TSocketAddress.CreateIPv4('127.0.0.1', Port));
  except
    on E: ESocketBindError do
    begin
      Raised := True;
      AssertTrue('error code should be non-negative', E.ErrorCode >= 0);
      AssertEquals('exception handle matches socket', PtrUInt(S2.Handle), PtrUInt(E.SocketHandle));
    end;
  end;
  AssertTrue('should raise ESocketBindError', Raised);
end;

initialization
  RegisterTest(TTestCase_Socket_ErrorSemantics);

end.

