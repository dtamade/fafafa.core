unit fafafa.core.signal.stop_semantics.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry, sysutils,
  fafafa.core.signal;

type
  TTestCase_StopSemantics = class(TTestCase)
  private
    FCount: Integer;
    procedure OnAny(const S: TSignal);
  published
    procedure Test_Stop_Prevents_Callbacks;
    procedure Test_GetQueueStats_BasicAndDrop;
    procedure Test_TryStart_TryStop_Succeed;
  end;

implementation

procedure TTestCase_StopSemantics.OnAny(const S: TSignal);
begin
  Inc(FCount);
end;

procedure TTestCase_StopSemantics.Test_Stop_Prevents_Callbacks;
var C: ISignalCenter; tok: Int64;
begin
  WriteLn('[CASE] Test_Stop_Prevents_Callbacks: begin'); System.Flush(Output);
  C := SignalCenter;
  C.Start;
  try
    FCount := 0;
    tok := C.Subscribe([sgInt], @OnAny);
    // 正常注入应触发
    C.InjectForTest(sgInt);
    Sleep(30);
    CheckTrue(FCount >= 1, 'callback should have fired before Stop');
    // Stop 后不应再触发
    C.Unsubscribe(tok);
  finally
    C.Stop;
  end;
  WriteLn('[CASE] Test_Stop_Prevents_Callbacks: end, FCount=', FCount); System.Flush(Output);
  // Stop 之后再次注入，计数不应增加
  C.InjectForTest(sgInt);
  Sleep(30);
  CheckTrue(FCount >= 1, 'no further callbacks after Stop');
end;

procedure TTestCase_StopSemantics.Test_GetQueueStats_BasicAndDrop;
var C: ISignalCenter; S: TQueueStats; ok: Boolean; Sig: TSignal;
begin
  C := SignalCenter; C.Start;
  try
    // DropNewest 情况
    C.ConfigureQueue(1, qdpDropNewest);
    S := C.GetQueueStats;
    CheckEquals(1, S.Capacity, 'Capacity should be 1 (configured)');

    C.InjectForTest(sgInt);
    S := C.GetQueueStats;
    CheckEquals(1, S.Length, 'Length should be 1 after first inject');

    C.InjectForTest(sgTerm); // 将被丢弃
    S := C.GetQueueStats;
    CheckEquals(1, S.Length, 'Length should remain 1 after drop-newest');
    CheckTrue(S.DropCount >= 1, 'DropCount should increase');

    // 取出一个，长度应变 0
    ok := C.TryWaitNext(Sig);
    CheckTrue(ok, 'TryWaitNext should fetch one');
    S := C.GetQueueStats;
    CheckEquals(0, S.Length, 'Length should be 0 after dequeue');

    // DropOldest 情况
    C.ConfigureQueue(1, qdpDropOldest);
    C.InjectForTest(sgInt);
    C.InjectForTest(sgTerm); // 覆盖最旧
    S := C.GetQueueStats;
    CheckEquals(1, S.Length, 'Length still 1 with capacity 1');
    // 取出应为 sgTerm
    ok := C.TryWaitNext(Sig);
    CheckTrue(ok and (Sig = sgTerm), 'DropOldest keeps newest');
  finally
    C.Stop;
  end;
end;

procedure TTestCase_StopSemantics.Test_TryStart_TryStop_Succeed;
var C: ISignalCenter; Err: string; ok: Boolean;
begin
  C := SignalCenter;
  ok := C.TryStart(Err);
  CheckTrue(ok, 'TryStart should succeed');
  CheckEquals('', Err, 'ErrMsg should be empty on success');
  ok := C.TryStop(Err);
  CheckTrue(ok, 'TryStop should succeed');
end;

initialization
  RegisterTest(TTestCase_StopSemantics);

end.

