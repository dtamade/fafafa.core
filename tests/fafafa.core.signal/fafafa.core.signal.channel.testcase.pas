unit fafafa.core.signal.channel.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry, sysutils,
  fafafa.core.signal, fafafa.core.signal.channel;

Type
  TTestCase_Channel = class(TTestCase)
  published
    procedure Test_Unbuffered_Channel_RecvTimeout;
    procedure Test_Buffered_Channel_Recv;
    procedure Test_Unbuffered_Drop;
    procedure Test_Buffered_Capacity1_Drop;
  end;

implementation

procedure TTestCase_Channel.Test_Unbuffered_Channel_RecvTimeout;
var Ch: TSignalChannel; Sig: TSignal; C: ISignalCenter;
begin
  C := SignalCenter; C.Start;
  Ch := TSignalChannel.Create([sgInt], 0);
  try
    C.InjectForTest(sgInt);
    CheckTrue(Ch.RecvTimeout(Sig, 200));
    CheckTrue(Sig = sgInt);
  finally
    Ch.Free; C.Stop;
  end;
end;

procedure TTestCase_Channel.Test_Buffered_Channel_Recv;
var Ch: TSignalChannel; Sig: TSignal; C: ISignalCenter;
begin
  C := SignalCenter; C.Start;
  Ch := TSignalChannel.Create([sgTerm], 8);
  try
    C.InjectForTest(sgTerm);
    CheckTrue(Ch.Recv(Sig));
    CheckTrue(Sig = sgTerm);
  finally
    Ch.Free; C.Stop;
  end;

procedure TTestCase_Channel.Test_Unbuffered_Drop;
var Ch: TSignalChannel; Sig: TSignal; C: ISignalCenter; ok: Boolean;
begin
  C := SignalCenter; C.Start;
  Ch := TSignalChannel.Create([sgInt], 0);
  try
    // 注入两次：第一下配对成功，第二下因无等待者将被丢弃
    C.InjectForTest(sgInt);
    ok := Ch.RecvTimeout(Sig, 200);
    CheckTrue(ok and (Sig = sgInt));
    // 立刻再注入一次，但不立即接收，给回调一个调度窗
    C.InjectForTest(sgInt);
    Sleep(10);
    // 再尝试接收，通常会超时（被丢弃）
    ok := Ch.RecvTimeout(Sig, 50);
    CheckFalse(ok);
  finally
    Ch.Free; C.Stop;
  end;
end;

procedure TTestCase_Channel.Test_Buffered_Capacity1_Drop;
var Ch: TSignalChannel; Sig: TSignal; C: ISignalCenter; ok: Boolean;
begin
  C := SignalCenter; C.Start;
  Ch := TSignalChannel.Create([sgInt], 1);
  try
    // capacity=1：第一次进入缓冲，第二次因满被丢弃
    C.InjectForTest(sgInt);
    C.InjectForTest(sgInt);
    Sleep(10);
    ok := Ch.RecvTimeout(Sig, 100);
    CheckTrue(ok and (Sig = sgInt));
    // 缓冲仅一条，第二条被丢弃，此处应无更多可取
    ok := Ch.RecvTimeout(Sig, 50);
    CheckFalse(ok);
  finally
    Ch.Free; C.Stop;
  end;
end;

  end;
end;

initialization
  RegisterTest(TTestCase_Channel);

end.

