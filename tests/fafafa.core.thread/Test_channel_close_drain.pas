unit Test_channel_close_drain;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.thread;

type
  TTestCase_Channel_CloseDrain = class(TTestCase)
  published
    procedure Test_Buffered_Close_Allows_Draining;
  end;

implementation

procedure TTestCase_Channel_CloseDrain.Test_Buffered_Close_Allows_Draining;
var
  C: IChannel;
  V: Pointer;
  ok: Boolean;
begin
  // 建立容量为3的缓冲通道
  C := CreateChannel(3);
  // 发送三条数据
  ok := C.Send(Pointer(PtrUInt(1)));  AssertTrue(ok);
  ok := C.Send(Pointer(PtrUInt(2)));  AssertTrue(ok);
  ok := C.Send(Pointer(PtrUInt(3)));  AssertTrue(ok);

  // 关闭通道
  C.Close;

  // 关闭后发送应失败
  ok := C.Send(Pointer(PtrUInt(4)));
  AssertFalse('close 后发送应失败', ok);

  // 关闭后应允许耗尽缓冲中的数据
  ok := C.Recv(V);  AssertTrue('应能取到第1条', ok);  AssertEquals(1, Integer(PtrUInt(V)));
  ok := C.Recv(V);  AssertTrue('应能取到第2条', ok);  AssertEquals(2, Integer(PtrUInt(V)));
  ok := C.Recv(V);  AssertTrue('应能取到第3条', ok);  AssertEquals(3, Integer(PtrUInt(V)));

  // 缓冲已空，再接收应返回 False
  ok := C.TryRecv(V);
  AssertFalse('缓冲已空且已关闭，应返回 False', ok);
end;

initialization
  RegisterTest(TTestCase_Channel_CloseDrain);

end.

