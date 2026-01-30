unit fafafa.core.signal.extra.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry, sysutils,
  fafafa.core.signal;

Type
  TTestCase_Extra = class(TTestCase)
  private
    FPausedCount: Integer;
    procedure OnPaused(const S: TSignal);
  published
    procedure Test_ConfigureQueue_DropNewest_vs_DropOldest;
    procedure Test_Pause_Resume;
  end;

implementation

procedure TTestCase_Extra.OnPaused(const S: TSignal);
begin
  Inc(FPausedCount);
end;

procedure TTestCase_Extra.Test_ConfigureQueue_DropNewest_vs_DropOldest;
var C: ISignalCenter; s: TSignal; ok: Boolean;
begin
  C := SignalCenter; C.Start;
  try
    // DropNewest: 达容量立即丢弃新事件
    C.ConfigureQueue(1, qdpDropNewest);
    C.InjectForTest(sgInt);
    C.InjectForTest(sgTerm); // 将被丢弃
    ok := C.WaitNext(s, 200);
    CheckTrue(ok and (s = sgInt), 'expect first kept');
    ok := C.WaitNext(s, 50);
    CheckFalse(ok, 'second dropped');

    // DropOldest: 达容量丢弃最旧，保留最新
    C.ConfigureQueue(1, qdpDropOldest);
    C.InjectForTest(sgInt);
    C.InjectForTest(sgTerm); // 触发丢弃最旧 sgInt
    ok := C.WaitNext(s, 200);
    CheckTrue(ok and (s = sgTerm), 'expect newest kept');
  finally
    C.Stop;
  end;
end;

procedure TTestCase_Extra.Test_Pause_Resume;
var C: ISignalCenter; tok: Int64;
begin
  C := SignalCenter; C.Start;
  try
    FPausedCount := 0;
    tok := C.Subscribe([sgInt], @OnPaused);
    C.Pause(tok);
    // 注入后不应触发
    C.InjectForTest(sgInt);
    Sleep(50);
    CheckEquals(0, FPausedCount, 'paused should not receive');

    // 恢复后应可收到
    C.Resume(tok);
    C.InjectForTest(sgInt);
    Sleep(50);
    CheckEquals(1, FPausedCount, 'resumed should receive');

    C.Unsubscribe(tok);
  finally
    C.Stop;
  end;
end;

initialization
  RegisterTest(TTestCase_Extra);

end.

