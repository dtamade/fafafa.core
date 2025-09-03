unit fafafa.core.sync.sem.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.sync.sem, fafafa.core.sync.base, fafafa.core.base;

type
  // 辅助线程：阻塞等�?Acquire，直到主线程释放
  TBlockingAcquireThread = class(TThread)
  private
    FSem: ISem;
    FAcquired: Boolean;
  protected
    procedure Execute; override;
  public
    Completed: Boolean;
    constructor Create(const ASem: ISem);
    property Acquired: Boolean read FAcquired;
  end;

  // 辅助线程：延时释放指定数量的资源
  TDelayedReleaseThread = class(TThread)
  private
    FSem: ISem;
    FDelayMs: Cardinal;
    FCount: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const ASem: ISem; ADelayMs: Cardinal; ACount: Integer = 1);
  end;


  // 测试全局工厂函数
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_CreateSemaphore_Factory;
  end;

  // 测试 ISem 接口
  TTestCase_ISem = class(TTestCase)
  private
    FSem: ISem;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 构造函数参�?
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

    // 回滚一致性（跨平台期望：失败不改变可用计数）
    procedure Test_Rollback_TryAcquireCount_Timeout_NoRelease;
    procedure Test_Rollback_TryAcquireCount_Timeout_WithSingleDelayedRelease;

    // 状态查�?
    procedure Test_StateQueries;

    // 错误条件
    procedure Test_Error_ReleaseBeyondMax;
    procedure Test_ParamValidation_AcquireRelease_Invalid;
    procedure Test_ParamValidation_TryAcquire_Invalid;
    procedure Test_TryAcquire_GreaterThanMax_ReturnsFalse;
    procedure Test_LastError_SuccessAndTimeout;

    // 边界条件
    procedure Test_Edge_ZeroCountsAndNoops;

    // 并发基本验证
    procedure Test_Concurrent_BlockingAcquireAndRelease;

    // 多态性（ILock�?
    // 压力测试
    procedure Test_Stress_Interleaved_MultiThread;

    procedure Test_Polymorphism_ILock;
  end;

  // 压力测试线程：循环获�?释放
  TWorkerThread = class(TThread)
  private
    FSem: ISem;
    FLoops: Integer;
    FBulkCount: Integer;
    FUseTimeout: Boolean;
    FTimeoutMs: Cardinal;
  protected
    procedure Execute; override;
  public
    constructor Create(const ASem: ISem; ALoops, ABulkCount: Integer; AUseTimeout: Boolean = False; ATimeoutMs: Cardinal = 0);
  end;

  // 取样线程：在并发过程中持续检查计数边界是否被破坏
  TSamplerThread = class(TThread)
  private
    FSem: ISem;
    FStop: Boolean;
    FViolations: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(const ASem: ISem);
    procedure Stop;
    property Violations: Integer read FViolations;
  end;


implementation

{ TBlockingAcquireThread }

constructor TBlockingAcquireThread.Create(const ASem: ISem);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FSem := ASem;
  FAcquired := False;
  Completed := False;
  Start;
end;

constructor TDelayedReleaseThread.Create(const ASem: ISem; ADelayMs: Cardinal; ACount: Integer);
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

constructor TWorkerThread.Create(const ASem: ISem; ALoops, ABulkCount: Integer; AUseTimeout: Boolean; ATimeoutMs: Cardinal);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FSem := ASem;
  FLoops := ALoops;
  FBulkCount := ABulkCount;
  FUseTimeout := AUseTimeout;
  FTimeoutMs := ATimeoutMs;
  Start;
end;

procedure TWorkerThread.Execute;
var i, k: Integer; ok: Boolean;
begin
  for i := 1 to FLoops do
  begin
    // 可选：批量获取
    if FBulkCount <= 1 then
    begin
      if FUseTimeout then
      begin
        ok := FSem.TryAcquire(1, FTimeoutMs);
        if ok then FSem.Release;
      end
      else
      begin
        FSem.Acquire;
        FSem.Release;
      end;
    end
    else
    begin
      // 尝试批量；失败则降级为逐个（避免长时间等待�?
      ok := False;
      if FUseTimeout then
        ok := FSem.TryAcquire(FBulkCount, FTimeoutMs)
      else
        ok := FSem.TryAcquire(FBulkCount);
      if ok then
        FSem.Release(FBulkCount)
      else
      begin
        for k := 1 to FBulkCount do
        begin
          if FUseTimeout then
          begin
            if FSem.TryAcquire(1, FTimeoutMs) then FSem.Release;
          end
          else
          begin
            if FSem.TryAcquire then FSem.Release;
          end;
        end;
      end;
    end;
  end;
end;

constructor TSamplerThread.Create(const ASem: ISem);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FSem := ASem;
  FStop := False;
  FViolations := 0;
  Start;
end;

procedure TSamplerThread.Stop;
begin
  FStop := True;
end;

procedure TSamplerThread.Execute;
begin
  while not FStop do
  begin
    if (FSem.GetAvailableCount < 0) or (FSem.GetAvailableCount > FSem.GetMaxCount) then
      Inc(FViolations);
    Sleep(1);
  end;
end;


procedure TBlockingAcquireThread.Execute;
begin
  try
    FSem.Acquire; // 阻塞直到主线程释�?
    FAcquired := True;
    // 立即释放，避免占�?
    FSem.Release;
  finally
    Completed := True;
  end;
end;

{ TTestCase_Global }

procedure TTestCase_Global.Test_CreateSemaphore_Factory;
var
  S: ISem;
begin
  S := fafafa.core.sync.sem.MakeSem(1, 3);
  AssertNotNull('MakeSem should return non-nil', S);
  AssertEquals('GetMaxCount should reflect input', 3, S.GetMaxCount);
end;

{ TTestCase_ISem }

procedure TTestCase_ISem.SetUp;
begin
  inherited SetUp;
  FSem := fafafa.core.sync.sem.MakeSem(1, 3);
end;

procedure TTestCase_ISem.TearDown;
begin
  FSem := nil;
  inherited TearDown;
end;

procedure TTestCase_ISem.Test_Constructors_Valid;
var
  S: ISem;
begin
  S := fafafa.core.sync.sem.MakeSem(0, 1);
  AssertEquals('Initial=0 should set available to 0', 0, S.GetAvailableCount);
  AssertEquals('Max=1 should be stored', 1, S.GetMaxCount);

  S := fafafa.core.sync.sem.MakeSem(2, 5);
  AssertEquals('Initial=2 should set available to 2', 2, S.GetAvailableCount);
  AssertEquals('Max=5 should be stored', 5, S.GetMaxCount);
end;

procedure TTestCase_ISem.Test_Constructors_Invalid_MaxLEZero;
begin
  try
    fafafa.core.sync.sem.MakeSem(0, 0);
    Fail('AMaxCount<=0 should raise EInvalidArgument');
  except
    on E: EInvalidArgument do ;
  end;
end;

procedure TTestCase_ISem.Test_Constructors_Invalid_InitialNegative;
begin
  try
    fafafa.core.sync.sem.MakeSem(-1, 1);
    Fail('AInitialCount<0 should raise EInvalidArgument');
  except
    on E: EInvalidArgument do ;
  end;
end;

procedure TTestCase_ISem.Test_Constructors_Invalid_InitialGreaterThanMax;
begin
  try
    fafafa.core.sync.sem.MakeSem(2, 1);
    Fail('AInitialCount>AMaxCount should raise EInvalidArgument');
  except
    on E: EInvalidArgument do ;
  end;
end;

procedure TTestCase_ISem.Test_Basic_AcquireRelease;
begin
  AssertEquals('Initial available should be 1', 1, FSem.GetAvailableCount);
  FSem.Acquire;
  AssertEquals('After Acquire, available should be 0', 0, FSem.GetAvailableCount);
  FSem.Release;
  AssertEquals('After Release, available should be 1', 1, FSem.GetAvailableCount);
end;

procedure TTestCase_ISem.Test_Basic_TryAcquire;
var ok: Boolean;
begin
  ok := FSem.TryAcquire;
  AssertTrue('TryAcquire should succeed when available', ok);
  AssertEquals('After TryAcquire success, available=0', 0, FSem.GetAvailableCount);
  ok := FSem.TryAcquire;
  AssertFalse('TryAcquire should fail when none available', ok);
  FSem.Release;
end;

procedure TTestCase_ISem.Test_Bulk_AcquireRelease_TryAcquire;
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

procedure TTestCase_ISem.Test_Timeout_TryAcquire_ZeroAndNonZero;
var ok: Boolean; t0, t1: QWord;
begin
  // 清空
  FSem.Acquire; // now 0

  // 0ms 超时，快速失�?
  t0 := GetTickCount64;
  ok := FSem.TryAcquire(Cardinal(0));
  t1 := GetTickCount64;
  AssertFalse('TryAcquire(0) should return False when none available', ok);
  AssertTrue('TryAcquire(0) should be fast', (t1 - t0) < 50);

  // �?超时
  t0 := GetTickCount64;
  ok := FSem.TryAcquire(Cardinal(50));
  t1 := GetTickCount64;
  AssertFalse('TryAcquire(50) should timeout when none available', ok);
  AssertTrue('TryAcquire(50) should wait around timeout', (t1 - t0) >= 40);

  // 清理
  FSem.Release;
end;

procedure TTestCase_ISem.Test_ParamValidation_AcquireRelease_Invalid;
begin
  // Acquire with negative
  try
    FSem.Acquire(-1);
    Fail('Acquire(-1) should raise EInvalidArgument');
  except on E: EInvalidArgument do ; end;

  // Acquire with > Max
  try
    FSem.Acquire(FSem.GetMaxCount + 1);
    Fail('Acquire(>Max) should raise EInvalidArgument');
  except on E: EInvalidArgument do ; end;

  // Release with negative
  try
    FSem.Release(-1);
    Fail('Release(-1) should raise EInvalidArgument');
  except on E: EInvalidArgument do ; end;
end;

procedure TTestCase_ISem.Test_ParamValidation_TryAcquire_Invalid;
var ok: Boolean;
begin
  // TryAcquire with negative
  try
    ok := FSem.TryAcquire(-1);
    Fail('TryAcquire(-1) should raise EInvalidArgument');
  except on E: EInvalidArgument do ; end;

  try
    ok := FSem.TryAcquire(-1, 10);
    Fail('TryAcquire(-1,10) should raise EInvalidArgument');
  except on E: EInvalidArgument do ; end;
end;

procedure TTestCase_ISem.Test_TryAcquire_GreaterThanMax_ReturnsFalse;
var ok: Boolean; nmax: Integer;
begin
  nmax := FSem.GetMaxCount;
  ok := FSem.TryAcquire(nmax+1, 0);
  AssertFalse('TryAcquire(>Max) should return False', ok);
  ok := FSem.TryAcquire(nmax+1, 20);
  AssertFalse('TryAcquire(>Max,timeout) should return False', ok);
end;

procedure TTestCase_ISem.Test_LastError_SuccessAndTimeout;
var ok: Boolean; err: TWaitError;
begin
  // Success should clear LastError
  ok := FSem.TryAcquire; AssertTrue('TryAcquire should succeed initially', ok);
  err := FSem.GetLastError; AssertEquals('LastError after success should be weNone', Ord(weNone), Ord(err));
  FSem.Release;

  // Force timeout: empty then try with short timeout
  FSem.Acquire;
  ok := FSem.TryAcquire(Cardinal(10));
  AssertFalse('TryAcquire(10) should timeout', ok);
  err := FSem.GetLastError;
  AssertEquals('LastError after timeout should be weTimeout', Ord(weTimeout), Ord(err));
  FSem.Release;
end;

procedure TTestCase_ISem.Test_Timeout_TryAcquireCount_WithTimeout;
var ok: Boolean; t0, t1: QWord; RelThread: TDelayedReleaseThread;
begin
  // available=1，提升到 1，尝试获�?个（需要等待）
  // 让一个辅助线程来在稍后释放一�?
  FSem.Acquire; // available=0
  RelThread := TDelayedReleaseThread.Create(FSem, 50, 1); // 延时释放一�?
  try
    t0 := GetTickCount64;
    ok := FSem.TryAcquire(1, 200);
    t1 := GetTickCount64;
    AssertTrue('TryAcquire(1,200) should succeed after release', ok);
    AssertTrue('Waited at least ~50ms before success', (t1 - t0) >= 40);
  finally
    // 确保线程已完�?
    Sleep(10);
  end;
end;

procedure TTestCase_ISem.Test_Timeout_TryAcquireCount_PartialReleaseFails;
var ok: Boolean; t0, t1: QWord; RelThread: TDelayedReleaseThread;
begin
  // 需�?个，但仅延时释放1个，应当超时失败
  // 先清�?
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
  // 清理：释放到初始状�?
  FSem.Release; // 现在应为1
end;

procedure TTestCase_ISem.Test_Rollback_TryAcquireCount_Timeout_NoRelease;
begin
  // 初始 available=1, max=3（SetUp 中创建了 1/3�?
  // 申请 2 个许可，超时失败后，应保持计数不�?
  FSem.Acquire; // available=0
  try
    AssertEquals('available should be 0 before try', 0, FSem.GetAvailableCount);
    AssertFalse('TryAcquire(2, 50) should timeout', FSem.TryAcquire(2, 50));
    AssertEquals('after timeout, available unchanged (rollback)', 0, FSem.GetAvailableCount);
  finally
    FSem.Release; // 恢复�?
  end;
end;

procedure TTestCase_ISem.Test_Rollback_TryAcquireCount_Timeout_WithSingleDelayedRelease;
var RelThread: TDelayedReleaseThread; t0,t1: QWord; ok: Boolean;
begin
  // 申请 2 个，期间仅释�?1 个，最终仍应超时失败，计数保持不变
  FSem.Acquire; // available=0
  RelThread := TDelayedReleaseThread.Create(FSem, 40, 1);
  try
    t0 := GetTickCount64;
    ok := FSem.TryAcquire(2, 100);
    t1 := GetTickCount64;
    AssertFalse('TryAcquire(2,100) should still timeout (only 1 released)', ok);
    AssertTrue('should have waited at least ~40ms', (t1 - t0) >= 30);
    // 外部释放�?个许可应当保留，尝试获取的“已获取部分”会被回�?
    AssertEquals('after timeout, available should reflect external release (rollback preserves state)', 1, FSem.GetAvailableCount);
  finally
    Sleep(10);
    FSem.Release; // 恢复�?
  end;
end;


procedure TTestCase_ISem.Test_StateQueries;
begin
  AssertEquals('GetAvailableCount initial=1', 1, FSem.GetAvailableCount);
  AssertEquals('GetMaxCount initial=3', 3, FSem.GetMaxCount);
end;

procedure TTestCase_ISem.Test_Error_ReleaseBeyondMax;
begin
  // 升至最�?
  FSem.Release(2); // 1->3
  AssertEquals('Should be at max=3', 3, FSem.GetAvailableCount);
  try
    FSem.Release; // 超过最�?
    Fail('Releasing beyond max should raise ELockError');
  except
    on E: ELockError do ;

    else
      raise;
  end;

end;



procedure TTestCase_ISem.Test_Edge_ZeroCountsAndNoops;
var ok: Boolean; S: ISem;
begin
  S := fafafa.core.sync.sem.MakeSem(0, 2);
  AssertEquals('Initial zero available', 0, S.GetAvailableCount);

  // Acquire(0)/Release(0) �?no-op
  S.Acquire(0);
  S.Release(0);
  AssertEquals('No-op operations should not change count', 0, S.GetAvailableCount);

  ok := S.TryAcquire(0);
  AssertTrue('TryAcquire(0 count) should return True (no-op success)', ok);

  // 释放一个，确保 TryAcquire 能成�?
  S.Release;
  ok := S.TryAcquire;
  AssertTrue('TryAcquire should succeed after release', ok);
end;

procedure TTestCase_ISem.Test_Concurrent_BlockingAcquireAndRelease;
var T: TBlockingAcquireThread;
begin
  // 将可用清零，启动阻塞线程
  FSem.Acquire; // available=0
  T := TBlockingAcquireThread.Create(FSem);
  try
    Sleep(20);
    AssertFalse('Thread should not have acquired yet', T.Acquired);
    // 释放一个，线程应当获得并释�?
    FSem.Release;
    // 给线程一点时间完�?
    Sleep(50);
    AssertTrue('Thread should have acquired and completed', T.Completed);
  finally
    // 线程 FreeOnTerminate
    Sleep(10);
  end;
end;

procedure TTestCase_ISem.Test_Polymorphism_ILock;
var L: ILock;
begin
  L := FSem; // ISem 应可赋值给 ILock
  L.Acquire;
  try
    // 临界�?- 这里不需要额外检查，只需不抛异常
  finally
    L.Release;
  end;
end;

procedure TTestCase_ISem.Test_Stress_Interleaved_MultiThread;
var
  Sampler: TSamplerThread;


  Threads: array of TWorkerThread;
  i, N, Loops: Integer;
  ViolCount: Integer;
begin
  // 基线：初始化 2 个可用，最�?3
  FSem := fafafa.core.sync.sem.MakeSem(2, 3);

  N := 8;      // 线程�?
  Sampler := TSamplerThread.Create(FSem);

  Loops := 200; // 每线程循环次数（保持较短，稳定）
  SetLength(Threads, N);

  for i := 0 to N-1 do
  begin
    if (i mod 3) = 0 then
      Threads[i] := TWorkerThread.Create(FSem, Loops, 2, True, 5) // 带超时的批量
    else if (i mod 3) = 1 then
      Threads[i] := TWorkerThread.Create(FSem, Loops, 1, True, 5) // 带超时的单个
    else
      Threads[i] := TWorkerThread.Create(FSem, Loops, 1, False, 0); // 非超时单�?
  end;

  // 先等待工作线程结�?
  for i := 0 to N-1 do
    Threads[i].WaitFor;
  // 回收工作线程
  for i := 0 to N-1 do
  begin
    Threads[i].Free;
    Threads[i] := nil;
  end;

  // 再停止采样线程并读取采样结果




  Sampler.Stop;
  Sampler.WaitFor;
  // 先取值再释放对象，避免释放后访问内存
  ViolCount := Sampler.Violations;
  Sampler.Free;

  // 断言：计数范围与无违�?
  AssertTrue('Available count within [0..Max] after stress',
    (FSem.GetAvailableCount >= 0) and (FSem.GetAvailableCount <= FSem.GetMaxCount));
  AssertEquals('Sampler should not detect boundary violations', 0, ViolCount);
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_ISem);

end.

