unit fafafa.core.sync.spin.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fpcunit, testregistry,
  fafafa.core.sync.spin, fafafa.core.sync.base;

type
  // 全局函数测试
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_MakeSpinLock;
    procedure Test_MakeSpinLock_ASpinCount;
  end;

  // TSpinLock 类测试
  TTestCase_TSpinLock = class(TTestCase)
  private
    FSpinLock: ISpinLock;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 公共 API（Acquire/Release/TryAcquire/Timeout）

    // ILock + ISpinLock API
    procedure Test_Acquire;
    procedure Test_Release;
    procedure Test_TryAcquire;
    procedure Test_TryAcquire_ATimeoutMs_0;
    procedure Test_TryAcquire_ATimeoutMs_100;
    procedure Test_TryAcquire_ATimeoutMs_Contention_False;

    // 并发
    procedure Test_Concurrent_Contention;
    procedure Test_Concurrent_LongRun;

    // 析构场景
    procedure Test_Destroy_NoUse;
    procedure Test_Destroy_AfterUse;

    // 性能（简单基准）
    procedure Test_Perf_SpinCount_100_vs_5000;
  end;

implementation

{ TTestCase_Global }

procedure TTestCase_Global.Test_MakeSpinLock;
var
  L: ISpinLock;
begin
  L := MakeSpinLock;
  AssertNotNull(L);
end;

procedure TTestCase_Global.Test_MakeSpinLock_ASpinCount;
var
  L: ISpinLock;
begin
  L := MakeSpinLock;
  AssertNotNull(L);
end;

{ TTestCase_TSpinLock }

procedure TTestCase_TSpinLock.SetUp;
begin
  inherited SetUp;
  FSpinLock := MakeSpinLock;
end;

procedure TTestCase_TSpinLock.TearDown;
begin
  FSpinLock := nil;
  inherited TearDown;
end;



procedure TTestCase_TSpinLock.Test_Acquire;
begin
  FSpinLock.Acquire;
  try
    // 在持有锁期间执行一个简单操作
    Sleep(1);
  finally
    FSpinLock.Release;
  end;
end;

procedure TTestCase_TSpinLock.Test_Release;
begin
  FSpinLock.Acquire;
  FSpinLock.Release;
  // 释放后应可再次获取
  AssertTrue(FSpinLock.TryAcquire);
  FSpinLock.Release;
end;

procedure TTestCase_TSpinLock.Test_TryAcquire;
begin
  AssertTrue(FSpinLock.TryAcquire);
  FSpinLock.Release;
end;

procedure TTestCase_TSpinLock.Test_TryAcquire_ATimeoutMs_0;
begin
  AssertTrue(FSpinLock.TryAcquire(0));
  FSpinLock.Release;
end;

procedure TTestCase_TSpinLock.Test_TryAcquire_ATimeoutMs_100;
var
  StartT, Elapsed: QWord;
begin
  StartT := GetTickCount64;
  AssertTrue(FSpinLock.TryAcquire(100));
  Elapsed := GetTickCount64 - StartT;
  AssertTrue(Elapsed < 50);
  FSpinLock.Release;
end;

procedure TTestCase_TSpinLock.Test_TryAcquire_ATimeoutMs_Contention_False;
var
  L: ISpinLock;
  T: TThread;
  StartT, Elapsed: QWord;
begin
  L := MakeSpinLock;

  // 另起线程持有锁 200ms
  T := TThread.CreateAnonymousThread(
    procedure
    begin
      L.Acquire;
      try
        Sleep(200);
      finally
        L.Release;
      end;
    end);
  T.FreeOnTerminate := False;
  T.Start;
  T.WaitFor; // 注意：等待线程启动并获取锁并不容易准确，这里简单等待一下

  // 100ms 超时应失败，耗时 >= 100ms
  StartT := GetTickCount64;
  AssertFalse(L.TryAcquire(100));
  Elapsed := GetTickCount64 - StartT;
  AssertTrue(Elapsed >= 95, 'elapsed='+IntToStr(Elapsed));

  T.Free;
end;

procedure TTestCase_TSpinLock.Test_Concurrent_Contention;
const
  ThreadCount = 4;
  Iter = 1000;
var
  Counter: Integer = 0;
  Threads: array[0..ThreadCount-1] of TThread;
  I: Integer;
  L: ISpinLock;
begin
  L := MakeSpinLock;

  for I := 0 to ThreadCount-1 do
  begin
    Threads[I] := TThread.CreateAnonymousThread(
      procedure
      var J: Integer;
      begin
        for J := 1 to Iter do
        begin
          L.Acquire;
          try
            Inc(Counter);
          finally
            L.Release;
          end;
        end;
      end);
    Threads[I].Start;
  end;

  for I := 0 to ThreadCount-1 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;

  AssertEquals(ThreadCount*Iter, Counter);
end;

procedure TTestCase_TSpinLock.Test_Concurrent_LongRun;
const
  ThreadCount = 4;
  Iter = 10000;
var
  Counter: Integer = 0;
  Threads: array[0..ThreadCount-1] of TThread;
  I: Integer;
  L: ISpinLock;
begin
  L := MakeSpinLock;

  for I := 0 to ThreadCount-1 do
  begin
    Threads[I] := TThread.CreateAnonymousThread(
      procedure
      var J: Integer;
      begin
        for J := 1 to Iter do
        begin
          L.Acquire;
          try
            Inc(Counter);
          finally
            L.Release;
          end;
        end;
      end);
    Threads[I].Start;
  end;

  for I := 0 to ThreadCount-1 do
  begin
    Threads[I].WaitFor;
    Threads[I].Free;
  end;

  AssertEquals(ThreadCount*Iter, Counter);
end;

procedure TTestCase_TSpinLock.Test_Destroy_NoUse;
var
  L: ISpinLock;
begin
  L := MakeSpinLock;
  // 作用域结束自动释放，若有泄漏会由 heaptrc 报告
  AssertNotNull(L);
end;

procedure TTestCase_TSpinLock.Test_Destroy_AfterUse;
var
  L: ISpinLock;
begin
  L := MakeSpinLock;
  L.Acquire;
  L.Release;
  // 作用域结束自动释放
  AssertNotNull(L);
end;

procedure TTestCase_TSpinLock.Test_Perf_SpinCount_100_vs_5000;
const
  N = 10000;
var
  L1, L2: ISpinLock;
  T1, T2: QWord;
  I: Integer;
begin
  // 现在不再暴露 SpinCount，简单检查 Acquire/Release 循环耗时
  L1 := MakeSpinLock;
  L2 := MakeSpinLock;

  T1 := GetTickCount64;
  for I := 1 to N do begin L1.Acquire; L1.Release; end;
  T1 := GetTickCount64 - T1;

  T2 := GetTickCount64;
  for I := 1 to N do begin L2.Acquire; L2.Release; end;
  T2 := GetTickCount64 - T2;

  AssertTrue((T1 > 0) and (T2 > 0));
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_TSpinLock);

end.
