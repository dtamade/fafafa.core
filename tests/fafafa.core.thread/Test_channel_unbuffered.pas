unit Test_channel_unbuffered;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  { TTestCase_TChannel_Unbuffered }
  TTestCase_TChannel_Unbuffered = class(TTestCase)
  published
    procedure Test_Unbuffered_Send_Then_Recv_Handshake;
    procedure Test_Unbuffered_Recv_Then_Send_Handshake;
  end;

implementation

procedure TTestCase_TChannel_Unbuffered.Test_Unbuffered_Send_Then_Recv_Handshake;
var
  LChan: IChannel;
  LPool: IThreadPool;
  LFuture: IFuture;
  LGot: Pointer;
  LStart, LEnd: QWord;
  LSendDuration: QWord;
  LData: Pointer;
begin
  // 容量=0：发送必须等待接收方握手
  LChan := CreateChannel(0);
  LPool := CreateSingleThreadPool;
  LData := Pointer(PtrUInt(123));

  // 在后台线程延迟后进行接收
  LFuture := LPool.Submit(
    function: Boolean
    begin
      SysUtils.Sleep(150);
      Result := LChan.Recv(LGot);
    end
  );

  LStart := GetTickCount64;
  AssertTrue('Send should succeed after receiver ready', LChan.Send(LData));
  LEnd := GetTickCount64;
  LSendDuration := LEnd - LStart;

  // 发送应被阻塞~150ms左右（允许一定误差）
  AssertTrue('Send should be blocked until receiver (>=120ms)', LSendDuration >= 120);

  // 等待后台接收完成，并检查数据一致
  AssertTrue('Receiver future should complete', LFuture.WaitFor(2000));
  AssertTrue('Recv should succeed', LGot <> nil);
  AssertEquals('Data value should match', PtrUInt(LData), PtrUInt(LGot));

  LPool.Shutdown;
  LPool.AwaitTermination(2000);
end;

procedure TTestCase_TChannel_Unbuffered.Test_Unbuffered_Recv_Then_Send_Handshake;
var
  LChan: IChannel;
  LPool: IThreadPool;
  LFuture: IFuture;
  LGot: Pointer;
  LData: Pointer;
  LRecvDone: Boolean;
begin
  // 容量=0：先接收会阻塞，直到发送到达
  LChan := CreateChannel(0);
  LPool := CreateSingleThreadPool;
  LData := Pointer(PtrUInt(456));
  LRecvDone := False;

  // 后台线程先进行接收（应阻塞），等待发送
  LFuture := LPool.Submit(
    function: Boolean
    begin
      Result := LChan.Recv(LGot);
      LRecvDone := Result;
    end
  );

  // 小延迟以确保接收先进入阻塞
  SysUtils.Sleep(100);

  // 发送应立即完成，并解除接收阻塞
  AssertTrue('Send should succeed and wake receiver', LChan.Send(LData));
  AssertTrue('Receiver should complete', LFuture.WaitFor(2000));
  AssertTrue('Receiver should report success', LRecvDone);
  AssertEquals('Data value should match', PtrUInt(LData), PtrUInt(LGot));

  LPool.Shutdown;
  LPool.AwaitTermination(2000);
end;

initialization
  RegisterTest(TTestCase_TChannel_Unbuffered);

end.

