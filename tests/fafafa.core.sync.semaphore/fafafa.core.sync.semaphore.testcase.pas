unit fafafa.core.sync.semaphore.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.semaphore, fafafa.core.sync.base, fafafa.core.base;

type
  // 辅助线程：阻塞等待 Acquire，直到主线程释放
  TBlockingAcquireThread = class(TThread)
  private
    FSem: ISemaphore;
    FAcquired: Boolean;
  protected
    procedure Execute; override;
  public
    Completed: Boolean;
    constructor Create(const ASem: ISemaphore);
    property Acquired: Boolean read FAcquired;
  end;

  // 辅助线程：延时释放指定数量的资源
  TDelayedReleaseThread = class(TThread)
  private
    FSem: ISemaphore;
    FDelayMs: Cardinal;
    FCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const ASem: ISemaphore; ADelayMs: Cardinal; ACount: Integer = 1);
  end;


  // 测试全局工厂函数
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_MakeSemaphore_Factory;
  end;

  // 测试 ISemaphore 接口
  TTestCase_ISemaphore = class(TTestCase)
  private
    FSem: ISemaphore;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 构造函数参数
    procedure Test_Constructors_Valid;
    procedure Test_Constructors_Invalid_MaxLEZero;
    procedure Test_Constructors_Invalid_InitialNegative;
    procedure Test_Constructors_Invalid_InitialGreaterThanMax;

    // 基础操作 (ILock 基础 + 扩展)
    procedure Test_Basic_AcquireRelease;
    procedure Test_Basic_TryAcquire;

    // 批量操作
    procedure Test_Bulk_AcquireRelease_TryAcquire;

    // 超时操作
    procedure Test_Timeout_TryAcquire_ZeroAndNonZero;
    procedure Test_Timeout_TryAcquireCount_WithTimeout;
    procedure Test_Timeout_TryAcquireCount_PartialReleaseFails;

    // 状态查询
    procedure Test_StateQueries;

    // 错误条件
    procedure Test_Error_ReleaseBeyondMax;

    // 边界条件
    procedure Test_Edge_ZeroCountsAndNoops;

    // 并发基本验证
    procedure Test_Concurrent_BlockingAcquireAndRelease;

    // 多态性（ILock）
    procedure Test_Polymorphism_ILock;
  end;

implementation

{ TBlockingAcquireThread }

constructor TBlockingAcquireThread.Create(const ASem: ISemaphore);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FSem := ASem;
  FAcquired := False;
  Completed := False;
  Start;
end;

constructor TDelayedReleaseThread.Create(const ASem: ISemaphore; ADelayMs: Cardinal; ACount: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FSem := ASem;
  FDelayMs := ADelayMs;
  FCount := ACount;
  Start;
end;

procedure TDelayedReleaseThread.Execute;
begin
  Sleep(FDelayMs);
  FSem.Release(FCount);
end;

procedure TBlockingAcquireThread.Execute;
begin
  try
    FSem.Acquire; // 阻塞直到主线程释放
    FAcquired := True;
    // 立即释放，避免占用
    FSem.Release;
  finally
    Completed := True;
  end;
end;

{ TTestCase_Global }

procedure TTestCase_Global.Test_MakeSemaphore_Factory;
var
  S: ISemaphore;
begin
  S := MakeSemaphore(1, 3);
  AssertNotNull('MakeSemaphore should return non-nil', S);
  AssertEquals('GetMaxCount should reflect input', 3, S.GetMaxCount);
end;

{ TTestCase_ISemaphore }

procedure TTestCase_ISemaphore.SetUp;
begin
  inherited SetUp;
  FSem := MakeSemaphore(1, 3);
end;

procedure TTestCase_ISemaphore.TearDown;
begin
  FSem := nil;
  inherited TearDown;
end;

procedure TTestCase_ISemaphore.Test_Constructors_Valid;
var
  S: ISemaphore;
begin
  S := MakeSemaphore(0, 1);
  AssertEquals('Initial=0 should set available to 0', 0, S.GetAvailableCount);
  AssertEquals('Max=1 should be stored', 1, S.GetMaxCount);

  S := MakeSemaphore(2, 5);
  AssertEquals('Initial=2 should set available to 2', 2, S.GetAvailableCount);
  AssertEquals('Max=5 should be stored', 5, S.GetMaxCount);
end;

procedure TTestCase_ISemaphore.Test_Constructors_Invalid_MaxLEZero;
begin
  try
    MakeSemaphore(0, 0);
    Fail('AMaxCount<=0 should raise EInvalidArgument');
  except
    on E: EInvalidArgument do ;
  end;
end;

procedure TTestCase_ISemaphore.Test_Constructors_Invalid_InitialNegative;
begin
  try
    MakeSemaphore(-1, 1);
    Fail('AInitialCount<0 should raise EInvalidArgument');
  except
    on E: EInvalidArgument do ;
  end;
end;

procedure TTestCase_ISemaphore.Test_Constructors_Invalid_InitialGreaterThanMax;
begin
  try
    MakeSemaphore(2, 1);
    Fail('AInitialCount>AMaxCount should raise EInvalidArgument');
  except
    on E: EInvalidArgument do ;
  end;
end;

procedure TTestCase_ISemaphore.Test_Basic_AcquireRelease;
begin
  AssertEquals('Initial available should be 1', 1, FSem.GetAvailableCount);
  FSem.Acquire;
  AssertEquals('After Acquire, available should be 0', 0, FSem.GetAvailableCount);
  FSem.Release;
  AssertEquals('After Release, available should be 1', 1, FSem.GetAvailableCount);
end;

procedure TTestCase_ISemaphore.Test_Basic_TryAcquire;
var ok: Boolean;
begin
  ok := FSem.TryAcquire;
  AssertTrue('TryAcquire should succeed when available', ok);
  AssertEquals('After TryAcquire success, available=0', 0, FSem.GetAvailableCount);
  ok := FSem.TryAcquire;
  AssertFalse('TryAcquire should fail when none available', ok);
  FSem.Release;
end;

procedure TTestCase_ISemaphore.Test_Bulk_AcquireRelease_TryAcquire;
var ok: Boolean;
begin
  // 先提升到2
  FSem.Release;
  AssertEquals('After Release once, available=2', 2, FSem.GetAvailableCount);

  ok := FSem.TryAcquire(2);
  AssertTrue('TryAcquire(2) should succeed when enough available', ok);
  AssertEquals('After bulk TryAcquire, available=0', 0, FSem.GetAvailableCount);

  FSem.Release(2);
  AssertEquals('After bulk Release(2), available=2', 2, FSem.GetAvailableCount);
end;

procedure TTestCase_ISemaphore.Test_Timeout_TryAcquire_ZeroAndNonZero;
var ok: Boolean; t0, t1: QWord;
begin
  // 清空
  FSem.Acquire; // now 0

  // 0ms 超时，快速失败
  t0 := GetTickCount64;
  ok := FSem.TryAcquire(Cardinal(0));
  t1 := GetTickCount64;
  AssertFalse('TryAcquire(0) should return False when none available', ok);
  AssertTrue('TryAcquire(0) should be fast', (t1 - t0) < 50);

  // 非0超时
  t0 := GetTickCount64;
  ok := FSem.TryAcquire(Cardinal(50));
  t1 := GetTickCount64;
  AssertFalse('TryAcquire(50) should timeout when none available', ok);
  AssertTrue('TryAcquire(50) should wait around timeout', (t1 - t0) >= 40);

  // 清理
  FSem.Release;
end;

procedure TTestCase_ISemaphore.Test_Timeout_TryAcquireCount_WithTimeout;
var ok: Boolean; t0, t1: QWord; RelThread: TDelayedReleaseThread;
begin
  // available=1，提升到 1，尝试获取2个（需要等待）
  // 让一个辅助线程来在稍后释放一个
  FSem.Acquire; // available=0
  RelThread := TDelayedReleaseThread.Create(FSem, 50, 1); // 延时释放一个
  try
    t0 := GetTickCount64;
    ok := FSem.TryAcquire(1, 200);
    t1 := GetTickCount64;
    AssertTrue('TryAcquire(1,200) should succeed after release', ok);
    AssertTrue('Waited at least ~50ms before success', (t1 - t0) >= 40);
  finally
    // 确保线程已完成
    Sleep(10);
  end;
end;

procedure TTestCase_ISemaphore.Test_Timeout_TryAcquireCount_PartialReleaseFails;
var ok: Boolean; t0, t1: QWord; RelThread: TDelayedReleaseThread;
begin
  // 需要2个，但仅延时释放1个，应当超时失败
  // 先清空
  FSem.Acquire; // available=0
  RelThread := TDelayedReleaseThread.Create(FSem, 50, 1);
  try
    t0 := GetTickCount64;
    ok := FSem.TryAcquire(2, 120);
    t1 := GetTickCount64;
    AssertFalse('TryAcquire(2,120) should fail when only 1 released', ok);
    AssertTrue('Should have waited at least ~50ms before failing', (t1 - t0) >= 40);
  finally
    Sleep(10);
  end;
  // 清理：释放到初始状态
  FSem.Release; // 现在应为1
end;

procedure TTestCase_ISemaphore.Test_StateQueries;
begin
  AssertEquals('GetAvailableCount initial=1', 1, FSem.GetAvailableCount);
  AssertEquals('GetMaxCount initial=3', 3, FSem.GetMaxCount);
end;

procedure TTestCase_ISemaphore.Test_Error_ReleaseBeyondMax;
begin
  // 升至最大
  FSem.Release(2); // 1->3
  AssertEquals('Should be at max=3', 3, FSem.GetAvailableCount);
  try
    FSem.Release; // 超过最大
    Fail('Releasing beyond max should raise ELockError');
  except
    on E: ELockError do ;
  end;
end;

procedure TTestCase_ISemaphore.Test_Edge_ZeroCountsAndNoops;
var ok: Boolean; S: ISemaphore;
begin
  S := MakeSemaphore(0, 2);
  AssertEquals('Initial zero available', 0, S.GetAvailableCount);

  // Acquire(0)/Release(0) 为 no-op
  S.Acquire(0);
  S.Release(0);
  AssertEquals('No-op operations should not change count', 0, S.GetAvailableCount);

  ok := S.TryAcquire(0);
  AssertTrue('TryAcquire(0 count) should return True (no-op success)', ok);

  // 释放一个，确保 TryAcquire 能成功
  S.Release;
  ok := S.TryAcquire;
  AssertTrue('TryAcquire should succeed after release', ok);
end;

procedure TTestCase_ISemaphore.Test_Concurrent_BlockingAcquireAndRelease;
var T: TBlockingAcquireThread;
begin
  // 将可用清零，启动阻塞线程
  FSem.Acquire; // available=0
  T := TBlockingAcquireThread.Create(FSem);
  try
    Sleep(20);
    AssertFalse('Thread should not have acquired yet', T.Acquired);
    // 释放一个，线程应当获得并释放
    FSem.Release;
    // 给线程一点时间完成
    Sleep(50);
    AssertTrue('Thread should have acquired and completed', T.Completed);
  finally
    // 线程 FreeOnTerminate
    Sleep(10);
  end;
end;

procedure TTestCase_ISemaphore.Test_Polymorphism_ILock;
var L: ILock;
begin
  L := FSem; // ISemaphore 应可赋值给 ILock
  L.Acquire;
  try
    // 临界区 - 这里不需要额外检查，只需不抛异常
  finally
    L.Release;
  end;
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_ISemaphore);

end.

