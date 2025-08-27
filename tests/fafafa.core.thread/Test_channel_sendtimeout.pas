unit Test_channel_sendtimeout;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.thread;

type
  TTestCase_Channel_SendTimeout = class(TTestCase)
  published
    procedure Test_SendTimeout_Buffered;
    procedure Test_SendTimeout_Unbuffered;
  end;

implementation

procedure TTestCase_Channel_SendTimeout.Test_SendTimeout_Buffered;
var C: IChannel; V: Pointer; ok: Boolean;
begin
  C := CreateChannel(1);
  ok := C.Send(Pointer(1));
  AssertTrue(ok);
  // 缓冲已满；无接收者；短超时应返回 False
  ok := C.SendTimeout(Pointer(2), 50);
  AssertFalse(ok);
  // 取出一个，空间释放
  ok := C.Recv(V);
  AssertTrue(ok);
end;

procedure TTestCase_Channel_SendTimeout.Test_SendTimeout_Unbuffered;
var C: IChannel; ok: Boolean;
begin
  C := CreateChannel(0);
  // 无接收者，短超时
  ok := C.SendTimeout(Pointer(1), 50);
  AssertFalse(ok);
end;

initialization
  RegisterTest(TTestCase_Channel_SendTimeout);

end.

