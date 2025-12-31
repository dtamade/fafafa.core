unit test_channel_basic;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.lockfree.ifaces,
  fafafa.core.lockfree.factories,
  fafafa.core.lockfree.channel.wait,
  fafafa.core.lockfree.channel.select;

type
  TTestLockFreeChannel = class(TTestCase)
  private
    type
      TIntChannel = specialize ILockFreeChannel<Integer>;
    procedure AssertSend(const aChannel: TIntChannel; const aValue: Integer; const aExpected: TLockFreeSendResult = srOk);
    procedure AssertReceive(const aChannel: TIntChannel; aExpectedValue: Integer);
  published
    procedure SendReceive_SingleThread;
    procedure Complete_DisallowsFurtherSend;
    procedure Cancel_SignalsReceivers;
    procedure WaitReceiveReady_SignalsAfterProducer;
    procedure SPSC_Channel_Backpressure;
    procedure MPSC_Channel_Unbounded;
    procedure WaitAnyReceiveReady_ReturnsIndex;
    procedure ChannelSelectReceive_Works;
    procedure ChannelSelectSend_Works;
  end;

implementation

type
  TDelayedSender = class(TThread)
  private
    FChan: specialize ILockFreeChannel<Integer>;
    FValue: Integer;
    FDelayMs: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const aChan: specialize ILockFreeChannel<Integer>; aValue, aDelayMs: Integer);
  end;

constructor TDelayedSender.Create(const aChan: specialize ILockFreeChannel<Integer>; aValue,
  aDelayMs: Integer);
begin
  inherited Create(True);
  FChan := aChan;
  FValue := aValue;
  FDelayMs := aDelayMs;
  FreeOnTerminate := False;
  Start;
end;

procedure TTestLockFreeChannel.WaitAnyReceiveReady_ReturnsIndex;
var
  ChanA, ChanB: specialize ILockFreeChannelMPMC<Integer>;
  ChannelList: specialize TChannelArray<Integer>;
  V: Integer;
  Index: SizeInt;
begin
  ChanA := specialize NewChannelMPMC<Integer>(4);
  ChanB := specialize NewChannelMPMC<Integer>(4);
  SetLength(ChannelList, 2);
  ChannelList[0] := ChanA;
  ChannelList[1] := ChanB;

  AssertEquals(Ord(srOk), Ord(ChanB.Send(99)));
  Index := specialize WaitAnyReceiveReady<Integer>(ChannelList, 1000);
  AssertEquals(1, Index);
  AssertEquals(Ord(rrOk), Ord(ChanB.Receive(V)));
  AssertEquals(99, V);
end;

procedure TTestLockFreeChannel.ChannelSelectReceive_Works;
var
  ChanA, ChanB: specialize ILockFreeChannelMPMC<Integer>;
  Channels: specialize TChannelArray<Integer>;
  V: Integer;
  Index: SizeInt;
begin
  ChanA := specialize NewChannelMPMC<Integer>(4);
  ChanB := specialize NewChannelMPMC<Integer>(4);
  SetLength(Channels, 2);
  Channels[0] := ChanA;
  Channels[1] := ChanB;

  AssertEquals(Ord(srOk), Ord(ChanA.Send(123)));
  Index := specialize ChannelSelectReceive<Integer>(Channels, V, 1000);
  AssertEquals(0, Index);
  AssertEquals(123, V);
end;

procedure TTestLockFreeChannel.ChannelSelectSend_Works;
var
  ChanA, ChanB: specialize ILockFreeChannelMPMC<Integer>;
  Channels: specialize TChannelArray<Integer>;
  Values: array[0..1] of Integer;
  V: Integer;
  Index: SizeInt;
begin
  ChanA := specialize NewChannelMPMC<Integer>(1);
  ChanB := specialize NewChannelMPMC<Integer>(1);
  SetLength(Channels, 2);
  Channels[0] := ChanA;
  Channels[1] := ChanB;
  Values[0] := 1;
  Values[1] := 2;

  // fill second channel to block send, leaving first available
  AssertEquals(Ord(srOk), Ord(ChanB.Send(42)));

  Index := specialize ChannelSelectSend<Integer>(Channels, Values, 1000);
  AssertEquals(0, Index);
  AssertEquals(Ord(rrOk), Ord(ChanA.Receive(V)));
  AssertEquals(1, V);
  AssertEquals(Ord(rrOk), Ord(ChanB.Receive(V)));
  AssertEquals(42, V);
end;

procedure TDelayedSender.Execute;
begin
  Sleep(FDelayMs);
  if FChan <> nil then
    FChan.Send(FValue);
end;

procedure TTestLockFreeChannel.AssertSend(const aChannel: TIntChannel; const aValue: Integer;
  const aExpected: TLockFreeSendResult);
begin
  AssertEquals(Ord(aExpected), Ord(aChannel.Send(aValue)));
end;

procedure TTestLockFreeChannel.AssertReceive(const aChannel: TIntChannel; aExpectedValue: Integer);
var
  LVal: Integer;
begin
  AssertEquals(Ord(rrOk), Ord(aChannel.Receive(LVal)));
  AssertEquals(aExpectedValue, LVal);
end;

procedure TTestLockFreeChannel.SendReceive_SingleThread;
var
  Chan: specialize ILockFreeChannelMPMC<Integer>;
begin
  Chan := specialize NewChannelMPMC<Integer>(16);
  AssertSend(Chan, 42);
  AssertReceive(Chan, 42);
  AssertEquals(0, Chan.Count);
end;

procedure TTestLockFreeChannel.Complete_DisallowsFurtherSend;
var
  Chan: specialize ILockFreeChannelMPMC<Integer>;
  LVal: Integer;
begin
  Chan := specialize NewChannelMPMC<Integer>(4);
  AssertSend(Chan, 1);
  AssertReceive(Chan, 1);

  Chan.Complete;
  AssertEquals(Ord(srClosed), Ord(Chan.Send(99)));

  AssertEquals(Ord(rrClosed), Ord(Chan.Receive(LVal, 0)));
end;

procedure TTestLockFreeChannel.Cancel_SignalsReceivers;
var
  Chan: specialize ILockFreeChannelMPMC<Integer>;
  LVal: Integer;
begin
  Chan := specialize NewChannelMPMC<Integer>(4);
  Chan.Cancel;
  AssertEquals(Ord(rrCanceled), Ord(Chan.Receive(LVal, 0)));
  AssertFalse('TrySend must fail after Cancel', Chan.TrySend(10));
end;

procedure TTestLockFreeChannel.WaitReceiveReady_SignalsAfterProducer;
var
  Chan: specialize ILockFreeChannelMPMC<Integer>;
  Sender: TDelayedSender;
  LVal: Integer;
begin
  Chan := specialize NewChannelMPMC<Integer>(8);
  Sender := TDelayedSender.Create(Chan, 777, 50);
  try
    AssertTrue('WaitReceiveReady should signal within timeout', Chan.WaitReceiveReady(200 * 1000));
    AssertEquals(Ord(rrOk), Ord(Chan.Receive(LVal)));
    AssertEquals(777, LVal);
  finally
    Sender.WaitFor;
    Sender.Free;
  end;
end;

procedure TTestLockFreeChannel.SPSC_Channel_Backpressure;
var
  Chan: specialize ILockFreeChannelSPSC<Integer>;
  R: Integer;
begin
  Chan := specialize NewChannelSPSC<Integer>(2);
  try
    AssertEquals(Ord(srOk), Ord(Chan.Send(1)));
    AssertEquals(Ord(srOk), Ord(Chan.Send(2)));
    AssertEquals(Ord(srTimedOut), Ord(Chan.Send(3, 1000))); // queue full within timeout
    AssertEquals(Ord(rrOk), Ord(Chan.Receive(R)));
    AssertEquals(1, R);
    AssertEquals(Ord(srOk), Ord(Chan.Send(4)));
    AssertEquals(Ord(rrOk), Ord(Chan.Receive(R)));
    AssertEquals(2, R);
    AssertEquals(Ord(rrOk), Ord(Chan.Receive(R)));
    AssertEquals(4, R);
  finally
    Chan := nil;
  end;
end;

procedure TTestLockFreeChannel.MPSC_Channel_Unbounded;
var
  Chan: specialize ILockFreeChannelMPSC<Integer>;
  i, V: Integer;
begin
  Chan := specialize NewChannelMPSC<Integer>;
  try
    for i := 1 to 100 do
      AssertEquals(Ord(srOk), Ord(Chan.Send(i)));
    for i := 1 to 100 do
    begin
      AssertEquals(Ord(rrOk), Ord(Chan.Receive(V)));
      AssertEquals(i, V);
    end;
  finally
    Chan := nil;
  end;
end;

initialization
  RegisterTest(TTestLockFreeChannel);

end.
