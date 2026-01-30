unit Test_future_oncomplete;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  { TTestCase_TFuture_OnComplete }
  TTestCase_TFuture_OnComplete = class(TTestCase)
  published
    procedure Test_OnComplete_Before_Complete;
    procedure Test_OnComplete_After_Complete;
    procedure Test_OnComplete_On_Fail;
  end;

implementation

procedure TTestCase_TFuture_OnComplete.Test_OnComplete_Before_Complete;
var
  F: IFuture;
  Called: Integer;
  t0: QWord;
begin
  Called := 0;
  F := TThreads.Spawn(function(Data: Pointer): Boolean
  begin
    // 加入微小延迟，确保 OnComplete 有充足时间注册
    SysUtils.Sleep(60);
    Result := True;
  end);

  // 注册回调（在完成前），并采用短轮询代替极短 Sleep，提升稳健性
  F.OnComplete(function(): Boolean
  begin
    InterlockedIncrement(Called);
    Result := True;
  end);

  // 等待回调触发或 Future 完成，以先到者为准；最多等待 ~50ms
  t0 := GetTickCount64;
  repeat
    if Called > 0 then Break;
    if F.IsDone then Break;
    SysUtils.Sleep(2);
  until (GetTickCount64 - t0) > 50;

  // 主等待：确保 Future 完成
  F.WaitFor(2000);
  AssertTrue('Future should be done', F.IsDone);

  // 最终保障：若尚未触发回调，再给一个极短让步窗口
  if Called = 0 then SysUtils.Sleep(3);
  AssertTrue('OnComplete should be called once', Called = 1);
end;

procedure TTestCase_TFuture_OnComplete.Test_OnComplete_After_Complete;
var
  F: IFuture;
  Called: Integer;
begin
  Called := 0;
  F := TThreads.Spawn(function(Data: Pointer): Boolean
  begin
    Result := True;
  end);

  // 等待完成后再注册 OnComplete，应立即触发一次
  F.WaitFor(1000);
  F.OnComplete(function(): Boolean
  begin
    InterlockedIncrement(Called);
    Result := True;
  end);

  // 回调应已触发
  AssertTrue('OnComplete should be called once after completion', Called = 1);
end;

procedure TTestCase_TFuture_OnComplete.Test_OnComplete_On_Fail;
var
  F: IFuture;
  Called: Integer;
begin
  Called := 0;
  F := TThreads.Spawn(function(Data: Pointer): Boolean
  begin
    raise Exception.Create('boom');
    Result := False;
  end);

  F.OnComplete(function(): Boolean
  begin
    InterlockedIncrement(Called);
    Result := True;
  end);

  F.WaitFor(1000);
  AssertTrue('Future should be done (failed)', F.IsDone);
  AssertTrue('OnComplete should be called once on fail', Called = 1);
end;

initialization
  RegisterTest(TTestCase_TFuture_OnComplete);

end.

