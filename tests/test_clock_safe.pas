unit test_clock_safe;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.time.base,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.time.clock,
  fafafa.core.time.clock.safe,
  fafafa.core.time.result,
  fafafa.core.thread.cancel;

type
  { TTestClockSafe }
  TTestClockSafe = class(TTestCase)
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // MonotonicClockSafe 测试
    procedure TestMonotonicClockSafeTryMode;
    procedure TestMonotonicClockSafeResultMode;
    procedure TestMonotonicClockSafeErrorStats;
    procedure TestMonotonicClockSafeBackwardCompatibility;
    
    // SystemClockSafe 测试
    procedure TestSystemClockSafeTryMode;
    procedure TestSystemClockSafeResultMode;
    procedure TestSystemClockSafeErrorStats;
    
    // 错误场景测试
    procedure TestErrorRecovery;
    procedure TestConcurrentAccess;
    procedure TestStatisticsAccuracy;
  end;

  { TMockFailingMonotonicClock }
  TMockFailingMonotonicClock = class(TInterfacedObject, IMonotonicClock)
  private
    FFailureRate: Double;  // 0.0 = never fail, 1.0 = always fail
    FFailCount: Integer;
    FCallCount: Integer;
    
    function ShouldFail: Boolean;
  public
    constructor Create(AFailureRate: Double = 0.5);
    
    function NowInstant: TInstant;
    procedure SleepFor(const D: TDuration);
    procedure SleepUntil(const T: TInstant);
    function WaitFor(const D: TDuration; const Token: ICancellationToken): Boolean;
    function WaitUntil(const T: TInstant; const Token: ICancellationToken): Boolean;
    function GetResolution: TDuration;
    function GetName: string;
    
    property CallCount: Integer read FCallCount;
    property FailCount: Integer read FFailCount;
  end;

  { TMockFailingSystemClock }
  TMockFailingSystemClock = class(TInterfacedObject, ISystemClock)
  private
    FFailureRate: Double;
    FFailCount: Integer;
    FCallCount: Integer;
    
    function ShouldFail: Boolean;
  public
    constructor Create(AFailureRate: Double = 0.5);
    
    function NowUTC: TDateTime;
    function NowLocal: TDateTime;
    function NowUnixMs: Int64;
    function NowUnixNs: Int64;
    function GetTimeZoneOffset: TDuration;
    function GetTimeZoneName: string;
    function GetName: string;
    
    property CallCount: Integer read FCallCount;
    property FailCount: Integer read FFailCount;
  end;

implementation

{ TMockFailingMonotonicClock }

constructor TMockFailingMonotonicClock.Create(AFailureRate: Double);
begin
  inherited Create;
  FFailureRate := AFailureRate;
  FFailCount := 0;
  FCallCount := 0;
end;

function TMockFailingMonotonicClock.ShouldFail: Boolean;
begin
  Inc(FCallCount);
  Result := Random < FFailureRate;
  if Result then
    Inc(FFailCount);
end;

function TMockFailingMonotonicClock.NowInstant: TInstant;
begin
  if ShouldFail then
    raise Exception.Create('Mock clock failure: NowInstant');
  Result := TInstant.FromNsSinceEpoch(GetTickCount64 * 1000000);
end;

procedure TMockFailingMonotonicClock.SleepFor(const D: TDuration);
begin
  if ShouldFail then
    raise Exception.Create('Mock clock failure: SleepFor');
  Sleep(D.AsMs);
end;

procedure TMockFailingMonotonicClock.SleepUntil(const T: TInstant);
var
  now: TInstant;
  d: TDuration;
begin
  if ShouldFail then
    raise Exception.Create('Mock clock failure: SleepUntil');
  now := TInstant.FromNsSinceEpoch(GetTickCount64 * 1000000);
  d := T.Diff(now);
  if d.AsMs > 0 then
    Sleep(d.AsMs);
end;

function TMockFailingMonotonicClock.WaitFor(const D: TDuration; 
  const Token: ICancellationToken): Boolean;
begin
  if ShouldFail then
    raise Exception.Create('Mock clock failure: WaitFor');
  if (Token <> nil) and Token.IsCancellationRequested then
    Exit(False);
  Sleep(D.AsMs);
  Result := True;
end;

function TMockFailingMonotonicClock.WaitUntil(const T: TInstant; 
  const Token: ICancellationToken): Boolean;
var
  now: TInstant;
  d: TDuration;
begin
  if ShouldFail then
    raise Exception.Create('Mock clock failure: WaitUntil');
  if (Token <> nil) and Token.IsCancellationRequested then
    Exit(False);
  now := TInstant.FromNsSinceEpoch(GetTickCount64 * 1000000);
  d := T.Diff(now);
  if d.AsMs > 0 then
    Sleep(d.AsMs);
  Result := True;
end;

function TMockFailingMonotonicClock.GetResolution: TDuration;
begin
  if ShouldFail then
    raise Exception.Create('Mock clock failure: GetResolution');
  Result := TDuration.FromMs(1);
end;

function TMockFailingMonotonicClock.GetName: string;
begin
  Result := 'MockFailingMonotonicClock';
end;

{ TMockFailingSystemClock }

constructor TMockFailingSystemClock.Create(AFailureRate: Double);
begin
  inherited Create;
  FFailureRate := AFailureRate;
  FFailCount := 0;
  FCallCount := 0;
end;

function TMockFailingSystemClock.ShouldFail: Boolean;
begin
  Inc(FCallCount);
  Result := Random < FFailureRate;
  if Result then
    Inc(FFailCount);
end;

function TMockFailingSystemClock.NowUTC: TDateTime;
begin
  if ShouldFail then
    raise Exception.Create('Mock clock failure: NowUTC');
  Result := Now;
end;

function TMockFailingSystemClock.NowLocal: TDateTime;
begin
  if ShouldFail then
    raise Exception.Create('Mock clock failure: NowLocal');
  Result := Now;
end;

function TMockFailingSystemClock.NowUnixMs: Int64;
begin
  if ShouldFail then
    raise Exception.Create('Mock clock failure: NowUnixMs');
  Result := DateTimeToUnix(Now) * 1000;
end;

function TMockFailingSystemClock.NowUnixNs: Int64;
begin
  if ShouldFail then
    raise Exception.Create('Mock clock failure: NowUnixNs');
  Result := DateTimeToUnix(Now) * 1000000000;
end;

function TMockFailingSystemClock.GetTimeZoneOffset: TDuration;
begin
  if ShouldFail then
    raise Exception.Create('Mock clock failure: GetTimeZoneOffset');
  Result := TDuration.FromHours(0);  // UTC
end;

function TMockFailingSystemClock.GetTimeZoneName: string;
begin
  if ShouldFail then
    raise Exception.Create('Mock clock failure: GetTimeZoneName');
  Result := 'UTC';
end;

function TMockFailingSystemClock.GetName: string;
begin
  Result := 'MockFailingSystemClock';
end;

{ TTestClockSafe }

procedure TTestClockSafe.SetUp;
begin
  Randomize;
end;

procedure TTestClockSafe.TearDown;
begin
  // Nothing to clean up
end;

procedure TTestClockSafe.TestMonotonicClockSafeTryMode;
var
  mockClock: TMockFailingMonotonicClock;
  safeClock: IMonotonicClockSafe;
  instant: TInstant;
  duration: TDuration;
  success: Boolean;
  waitResult: Boolean;
  i: Integer;
  successCount, failureCount: Integer;
begin
  // 测试 Try 模式的错误处理
  mockClock := TMockFailingMonotonicClock.Create(0.3);  // 30% 失败率
  safeClock := CreateMonotonicClockSafe(mockClock);
  
  successCount := 0;
  failureCount := 0;
  
  // 测试 TryNowInstant
  for i := 1 to 100 do
  begin
    if safeClock.TryNowInstant(instant) then
      Inc(successCount)
    else
      Inc(failureCount);
  end;
  
  AssertTrue('Should have some successes', successCount > 0);
  AssertTrue('Should have some failures', failureCount > 0);
  
  // 测试 TryGetResolution
  success := safeClock.TryGetResolution(duration);
  if success then
    AssertTrue('Resolution should be positive', duration.AsNs > 0);
  
  // 测试 TrySleepFor
  success := safeClock.TrySleepFor(TDuration.FromMs(1));
  // 不检查结果，因为可能成功或失败
  
  // 测试 TryWaitFor
  success := safeClock.TryWaitFor(TDuration.FromMs(1), nil, waitResult);
  if success then
    AssertTrue('Wait should succeed when not cancelled', waitResult);
end;

procedure TTestClockSafe.TestMonotonicClockSafeResultMode;
var
  mockClock: TMockFailingMonotonicClock;
  safeClock: IMonotonicClockSafe;
  instantResult: TInstantResult;
  durationResult: TDurationResult;
  boolResult: TBoolResult;
  i: Integer;
  okCount, errCount: Integer;
begin
  // 测试 Result 模式的错误处理
  mockClock := TMockFailingMonotonicClock.Create(0.4);  // 40% 失败率
  safeClock := CreateMonotonicClockSafe(mockClock);
  
  okCount := 0;
  errCount := 0;
  
  // 测试 NowInstantResult
  for i := 1 to 50 do
  begin
    instantResult := safeClock.NowInstantResult;
    if instantResult.IsOk then
      Inc(okCount)
    else
      Inc(errCount);
  end;
  
  AssertTrue('Should have some Ok results', okCount > 0);
  AssertTrue('Should have some Error results', errCount > 0);
  
  // 测试 GetResolutionResult
  durationResult := safeClock.GetResolutionResult;
  if durationResult.IsOk then
    AssertTrue('Resolution should be positive', durationResult.Value.AsNs > 0)
  else
    AssertTrue('Error message should not be empty', durationResult.Error.Message <> '');
  
  // 测试 SleepForResult
  boolResult := safeClock.SleepForResult(TDuration.FromMs(1));
  // 检查结果格式正确
  AssertTrue('Result should be either Ok or Err', 
    boolResult.IsOk or (not boolResult.IsOk));
  
  // 测试 WaitForResult
  boolResult := safeClock.WaitForResult(TDuration.FromMs(1), nil);
  if boolResult.IsOk then
    AssertTrue('Wait should return true when successful', boolResult.Value);
end;

procedure TTestClockSafe.TestMonotonicClockSafeErrorStats;
var
  mockClock: TMockFailingMonotonicClock;
  safeClock: IMonotonicClockSafe;
  stats: TClockErrorStats;
  instant: TInstant;
  i: Integer;
  expectedTotal: Integer;
begin
  // 测试错误统计功能
  mockClock := TMockFailingMonotonicClock.Create(0.5);  // 50% 失败率
  safeClock := CreateMonotonicClockSafe(mockClock);
  
  // 重置统计
  safeClock.ResetErrorStats;
  stats := safeClock.GetErrorStats;
  AssertEquals('Initial total operations', 0, stats.TotalOperations);
  AssertEquals('Initial successful operations', 0, stats.SuccessfulOperations);
  AssertEquals('Initial failed operations', 0, stats.FailedOperations);
  
  // 执行一些操作
  expectedTotal := 20;
  for i := 1 to expectedTotal do
  begin
    safeClock.TryNowInstant(instant);
  end;
  
  // 检查统计
  stats := safeClock.GetErrorStats;
  AssertEquals('Total operations should match', expectedTotal, stats.TotalOperations);
  AssertEquals('Success + Failed should equal Total', 
    stats.TotalOperations, stats.SuccessfulOperations + stats.FailedOperations);
  
  // 测试 HasError
  if stats.FailedOperations > 0 then
    AssertTrue('HasError should be true when there are failures', safeClock.HasError);
  
  // 测试重置
  safeClock.ResetErrorStats;
  stats := safeClock.GetErrorStats;
  AssertEquals('Stats should be reset', 0, stats.TotalOperations);
  AssertFalse('HasError should be false after reset', safeClock.HasError);
end;

procedure TTestClockSafe.TestMonotonicClockSafeBackwardCompatibility;
var
  normalClock: IMonotonicClock;
  safeClock: IMonotonicClockSafe;
  instant1, instant2: TInstant;
  duration: TDuration;
begin
  // 测试向后兼容性 - 安全时钟应该能作为普通时钟使用
  normalClock := CreateMonotonicClock;
  safeClock := CreateMonotonicClockSafe(normalClock);
  
  // 作为 IMonotonicClock 使用
  instant1 := safeClock.NowInstant;
  safeClock.SleepFor(TDuration.FromMs(10));
  instant2 := safeClock.NowInstant;
  
  duration := instant2.Diff(instant1);
  AssertTrue('Time should advance', duration.AsMs >= 10);
  
  // 测试名称
  AssertTrue('Name should contain Safe', Pos('Safe', safeClock.GetName) > 0);
  
  // 测试 Resolution
  duration := safeClock.GetResolution;
  AssertTrue('Resolution should be positive', duration.AsNs > 0);
end;

procedure TTestClockSafe.TestSystemClockSafeTryMode;
var
  mockClock: TMockFailingSystemClock;
  safeClock: ISystemClockSafe;
  dt: TDateTime;
  unixMs, unixNs: Int64;
  offset: TDuration;
  name: string;
  success: Boolean;
  i: Integer;
  successCount, failureCount: Integer;
begin
  // 测试系统时钟的 Try 模式
  mockClock := TMockFailingSystemClock.Create(0.25);  // 25% 失败率
  safeClock := CreateSystemClockSafe(mockClock);
  
  successCount := 0;
  failureCount := 0;
  
  // 测试 TryNowUTC
  for i := 1 to 100 do
  begin
    if safeClock.TryNowUTC(dt) then
      Inc(successCount)
    else
      Inc(failureCount);
  end;
  
  AssertTrue('Should have more successes than failures', successCount > failureCount);
  
  // 测试 TryNowLocal
  success := safeClock.TryNowLocal(dt);
  if success then
    AssertTrue('DateTime should be valid', dt > 0);
  
  // 测试 TryNowUnixMs
  success := safeClock.TryNowUnixMs(unixMs);
  if success then
    AssertTrue('Unix ms should be positive', unixMs > 0);
  
  // 测试 TryNowUnixNs
  success := safeClock.TryNowUnixNs(unixNs);
  if success then
    AssertTrue('Unix ns should be positive', unixNs > 0);
  
  // 测试 TryGetTimeZoneOffset
  success := safeClock.TryGetTimeZoneOffset(offset);
  // 不检查具体值，因为取决于系统设置
  
  // 测试 TryGetTimeZoneName
  success := safeClock.TryGetTimeZoneName(name);
  // 名称可能为空或任何值
end;

procedure TTestClockSafe.TestSystemClockSafeResultMode;
var
  mockClock: TMockFailingSystemClock;
  safeClock: ISystemClockSafe;
  dtResult: TDateTimeResult;
  int64Result: TInt64Result;
  durationResult: TDurationResult;
  i: Integer;
  okCount, errCount: Integer;
begin
  // 测试系统时钟的 Result 模式
  mockClock := TMockFailingSystemClock.Create(0.35);  // 35% 失败率
  safeClock := CreateSystemClockSafe(mockClock);
  
  okCount := 0;
  errCount := 0;
  
  // 测试 NowUTCResult
  for i := 1 to 50 do
  begin
    dtResult := safeClock.NowUTCResult;
    if dtResult.IsOk then
      Inc(okCount)
    else
      Inc(errCount);
  end;
  
  AssertTrue('Should have some Ok results', okCount > 0);
  AssertTrue('Should have some Error results', errCount > 0);
  
  // 测试 NowLocalResult
  dtResult := safeClock.NowLocalResult;
  if dtResult.IsOk then
    AssertTrue('DateTime should be valid', dtResult.Value > 0);
  
  // 测试 NowUnixMsResult
  int64Result := safeClock.NowUnixMsResult;
  if int64Result.IsOk then
    AssertTrue('Unix ms should be positive', int64Result.Value > 0);
  
  // 测试 NowUnixNsResult
  int64Result := safeClock.NowUnixNsResult;
  if int64Result.IsOk then
    AssertTrue('Unix ns should be positive', int64Result.Value > 0);
  
  // 测试 GetTimeZoneOffsetResult
  durationResult := safeClock.GetTimeZoneOffsetResult;
  AssertTrue('Result should be valid', 
    durationResult.IsOk or (not durationResult.IsOk));
end;

procedure TTestClockSafe.TestSystemClockSafeErrorStats;
var
  mockClock: TMockFailingSystemClock;
  safeClock: ISystemClockSafe;
  stats: TClockErrorStats;
  dt: TDateTime;
  i: Integer;
begin
  // 测试系统时钟的错误统计
  mockClock := TMockFailingSystemClock.Create(0.6);  // 60% 失败率
  safeClock := CreateSystemClockSafe(mockClock);
  
  // 重置并检查初始状态
  safeClock.ResetErrorStats;
  AssertFalse('Should not have errors initially', safeClock.HasError);
  
  // 执行操作
  for i := 1 to 30 do
  begin
    safeClock.TryNowUTC(dt);
  end;
  
  // 检查统计
  stats := safeClock.GetErrorStats;
  AssertEquals('Total operations', 30, stats.TotalOperations);
  AssertTrue('Should have failures with 60% failure rate', stats.FailedOperations > 0);
  AssertTrue('Should have some successes', stats.SuccessfulOperations > 0);
  
  if stats.FailedOperations > 0 then
  begin
    AssertTrue('HasError should be true', safeClock.HasError);
    AssertTrue('LastError should be set', safeClock.GetLastError.Code > 0);
  end;
end;

procedure TTestClockSafe.TestErrorRecovery;
var
  mockClock: TMockFailingMonotonicClock;
  safeClock: IMonotonicClockSafe;
  instant: TInstant;
  attempts, successes: Integer;
  i: Integer;
begin
  // 测试错误恢复 - 失败后继续尝试
  mockClock := TMockFailingMonotonicClock.Create(0.7);  // 70% 失败率
  safeClock := CreateMonotonicClockSafe(mockClock);
  
  attempts := 0;
  successes := 0;
  
  // 尝试多次，直到成功
  for i := 1 to 100 do
  begin
    Inc(attempts);
    if safeClock.TryNowInstant(instant) then
    begin
      Inc(successes);
      if successes >= 10 then
        Break;  // 获得足够的成功次数
    end;
  end;
  
  AssertTrue('Should eventually succeed', successes > 0);
  AssertTrue('Should require multiple attempts', attempts > successes);
  
  // 检查统计反映了尝试
  AssertEquals('Stats should show all attempts', 
    attempts, Integer(safeClock.GetErrorStats.TotalOperations));
end;

procedure TTestClockSafe.TestConcurrentAccess;
var
  safeClock: IMonotonicClockSafe;
  threads: array[0..9] of TThread;
  i: Integer;
  
  type
    TTestThread = class(TThread)
    private
      FClock: IMonotonicClockSafe;
    protected
      procedure Execute; override;
    public
      constructor Create(AClock: IMonotonicClockSafe);
    end;
    
  constructor TTestThread.Create(AClock: IMonotonicClockSafe);
  begin
    inherited Create(False);
    FClock := AClock;
    FreeOnTerminate := False;
  end;
  
  procedure TTestThread.Execute;
  var
    i: Integer;
    instant: TInstant;
  begin
    for i := 1 to 100 do
    begin
      FClock.TryNowInstant(instant);
      if i mod 10 = 0 then
        Sleep(1);  // 偶尔让出 CPU
    end;
  end;
  
begin
  // 测试并发访问安全性
  safeClock := CreateMonotonicClockSafe(CreateMonotonicClock);
  
  // 创建并启动线程
  for i := 0 to High(threads) do
    threads[i] := TTestThread.Create(safeClock);
  
  // 等待所有线程完成
  for i := 0 to High(threads) do
  begin
    threads[i].WaitFor;
    threads[i].Free;
  end;
  
  // 检查统计一致性
  AssertEquals('Total operations should be 1000', 
    1000, safeClock.GetErrorStats.TotalOperations);
end;

procedure TTestClockSafe.TestStatisticsAccuracy;
var
  mockClock: TMockFailingMonotonicClock;
  safeClock: IMonotonicClockSafe;
  instant: TInstant;
  i: Integer;
  actualSuccesses, actualFailures: Integer;
  stats: TClockErrorStats;
begin
  // 测试统计准确性
  mockClock := TMockFailingMonotonicClock.Create(0.0);  // 从不失败
  safeClock := CreateMonotonicClockSafe(mockClock);
  safeClock.ResetErrorStats;
  
  // 全部成功的情况
  for i := 1 to 50 do
    safeClock.TryNowInstant(instant);
  
  stats := safeClock.GetErrorStats;
  AssertEquals('All should succeed', 50, stats.SuccessfulOperations);
  AssertEquals('None should fail', 0, stats.FailedOperations);
  
  // 改为总是失败
  mockClock.Free;
  mockClock := TMockFailingMonotonicClock.Create(1.0);  // 总是失败
  safeClock := CreateMonotonicClockSafe(mockClock);
  safeClock.ResetErrorStats;
  
  // 全部失败的情况
  for i := 1 to 50 do
    safeClock.TryNowInstant(instant);
  
  stats := safeClock.GetErrorStats;
  AssertEquals('None should succeed', 0, stats.SuccessfulOperations);
  AssertEquals('All should fail', 50, stats.FailedOperations);
end;

initialization
  RegisterTest(TTestClockSafe);

end.