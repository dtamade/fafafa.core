unit fafafa.core.sync.semaphoreslim;

{$mode objfpc}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  TSemaphoreSlim - 轻量级信号量

  参照 .NET System.Threading.SemaphoreSlim 设计：
  - 进程内轻量级信号量（不使用内核对象）
  - 支持异步等待（通过超时模拟）
  - 比传统信号量更轻量、更快
  - 适合高频短时间等待场景

  使用示例：
    var
      Sem: TSemaphoreSlim;
    begin
      Sem.Init(3, 10);  // 初始 3 个许可，最大 10 个

      if Sem.Wait(1000) then  // 等待 1 秒
      try
        // 使用受保护资源
      finally
        Sem.Release;
      end;

      Sem.Done;
    end;

  适用场景：
  - 资源池限制（数据库连接、线程数）
  - 限流（并发请求数）
  - 生产者-消费者模式
}

interface

uses
  SysUtils, Classes,
  {$IFDEF UNIX}
  BaseUnix, Unix, UnixType, pthreads,
  {$ENDIF}
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  fafafa.core.atomic;

{$IFDEF UNIX}
const
  SEMSLIM_CLOCK_REALTIME = 0;

function semslim_clock_gettime(clk_id: cint; tp: PTimeSpec): cint; cdecl; external 'rt' name 'clock_gettime';
{$ENDIF}

type
  ISemaphoreSlim = interface
    ['{A8B9C0D1-E2F3-4567-8901-ABCDEF012345}']
    function Wait: Boolean;
    function WaitTimeout(ATimeoutMs: Cardinal): Boolean;
    function TryWait: Boolean;
    function Release: Integer;
    function ReleaseMany(AReleaseCount: Integer): Integer;
    function GetCurrentCount: Integer;
    function GetMaxCount: Integer;
    property CurrentCount: Integer read GetCurrentCount;
    property MaxCount: Integer read GetMaxCount;
  end;

  { TSemaphoreSlim - 轻量级信号量实现 }

  TSemaphoreSlim = record
  private
    FCurrentCount: Integer;
    FMaxCount: Integer;
    FWaiterCount: Integer;
    {$IFDEF UNIX}
    FMutex: pthread_mutex_t;
    FCond: pthread_cond_t;
    {$ENDIF}
    {$IFDEF WINDOWS}
    FCS: TRTLCriticalSection;
    FCondVar: TRTLConditionVariable;
    {$ENDIF}
    FInitialized: Boolean;

    procedure Lock; inline;
    procedure Unlock; inline;
    procedure NotifyOne; inline;
    procedure NotifyAll; inline;
    function WaitCondTimeout(ATimeoutMs: Cardinal): Boolean; inline;
  public
    {** 初始化信号量
        @param AInitialCount 初始许可数
        @param AMaxCount 最大许可数（默认等于初始值） *}
    procedure Init(AInitialCount: Integer; AMaxCount: Integer = 0);

    {** 释放资源 *}
    procedure Done;

    {** 等待获取一个许可（无限等待）
        @return 总是返回 True *}
    function Wait: Boolean;

    {** 等待获取一个许可（带超时）
        @return 成功获取返回 True，超时返回 False *}
    function WaitTimeout(ATimeoutMs: Cardinal): Boolean;

    {** 尝试立即获取一个许可（非阻塞）
        @return 成功获取返回 True *}
    function TryWait: Boolean;

    {** 释放一个许可
        @return 释放后的许可数 *}
    function Release: Integer;

    {** 释放多个许可
        @return 释放后的许可数 *}
    function ReleaseMany(AReleaseCount: Integer): Integer;

    {** 获取当前可用许可数 *}
    function GetCurrentCount: Integer;

    {** 获取最大许可数 *}
    function GetMaxCount: Integer;

    {** 获取当前等待者数量 *}
    function GetWaiterCount: Integer;

    property CurrentCount: Integer read GetCurrentCount;
    property MaxCount: Integer read GetMaxCount;
    property WaiterCount: Integer read GetWaiterCount;
  end;

{ 工厂函数 }
function MakeSemaphoreSlim(AInitialCount: Integer; AMaxCount: Integer = 0): ISemaphoreSlim;

implementation

type
  { TSemaphoreSlimImpl - 接口实现包装 }
  TSemaphoreSlimImpl = class(TInterfacedObject, ISemaphoreSlim)
  private
    FSem: TSemaphoreSlim;
  public
    constructor Create(AInitialCount: Integer; AMaxCount: Integer);
    destructor Destroy; override;
    function Wait: Boolean;
    function WaitTimeout(ATimeoutMs: Cardinal): Boolean;
    function TryWait: Boolean;
    function Release: Integer;
    function ReleaseMany(AReleaseCount: Integer): Integer;
    function GetCurrentCount: Integer;
    function GetMaxCount: Integer;
  end;

{ TSemaphoreSlimImpl }

constructor TSemaphoreSlimImpl.Create(AInitialCount: Integer; AMaxCount: Integer);
begin
  inherited Create;
  FSem.Init(AInitialCount, AMaxCount);
end;

destructor TSemaphoreSlimImpl.Destroy;
begin
  FSem.Done;
  inherited;
end;

function TSemaphoreSlimImpl.Wait: Boolean;
begin
  Result := FSem.Wait;
end;

function TSemaphoreSlimImpl.WaitTimeout(ATimeoutMs: Cardinal): Boolean;
begin
  Result := FSem.WaitTimeout(ATimeoutMs);
end;

function TSemaphoreSlimImpl.TryWait: Boolean;
begin
  Result := FSem.TryWait;
end;

function TSemaphoreSlimImpl.Release: Integer;
begin
  Result := FSem.Release;
end;

function TSemaphoreSlimImpl.ReleaseMany(AReleaseCount: Integer): Integer;
begin
  Result := FSem.ReleaseMany(AReleaseCount);
end;

function TSemaphoreSlimImpl.GetCurrentCount: Integer;
begin
  Result := FSem.GetCurrentCount;
end;

function TSemaphoreSlimImpl.GetMaxCount: Integer;
begin
  Result := FSem.GetMaxCount;
end;

function MakeSemaphoreSlim(AInitialCount: Integer; AMaxCount: Integer): ISemaphoreSlim;
begin
  Result := TSemaphoreSlimImpl.Create(AInitialCount, AMaxCount);
end;

{ TSemaphoreSlim }

procedure TSemaphoreSlim.Lock;
begin
  {$IFDEF UNIX}
  pthread_mutex_lock(@FMutex);
  {$ENDIF}
  {$IFDEF WINDOWS}
  EnterCriticalSection(FCS);
  {$ENDIF}
end;

procedure TSemaphoreSlim.Unlock;
begin
  {$IFDEF UNIX}
  pthread_mutex_unlock(@FMutex);
  {$ENDIF}
  {$IFDEF WINDOWS}
  LeaveCriticalSection(FCS);
  {$ENDIF}
end;

procedure TSemaphoreSlim.NotifyOne;
begin
  {$IFDEF UNIX}
  pthread_cond_signal(@FCond);
  {$ENDIF}
  {$IFDEF WINDOWS}
  WakeConditionVariable(FCondVar);
  {$ENDIF}
end;

procedure TSemaphoreSlim.NotifyAll;
begin
  {$IFDEF UNIX}
  pthread_cond_broadcast(@FCond);
  {$ENDIF}
  {$IFDEF WINDOWS}
  WakeAllConditionVariable(FCondVar);
  {$ENDIF}
end;

function TSemaphoreSlim.WaitCondTimeout(ATimeoutMs: Cardinal): Boolean;
{$IFDEF UNIX}
var
  AbsTime: timespec;
  Now: timespec;
  Rc: Integer;
{$ENDIF}
begin
  {$IFDEF UNIX}
  semslim_clock_gettime(SEMSLIM_CLOCK_REALTIME, @Now);
  AbsTime.tv_sec := Now.tv_sec + (ATimeoutMs div 1000);
  AbsTime.tv_nsec := Now.tv_nsec + ((ATimeoutMs mod 1000) * 1000000);
  if AbsTime.tv_nsec >= 1000000000 then
  begin
    Inc(AbsTime.tv_sec);
    Dec(AbsTime.tv_nsec, 1000000000);
  end;
  Rc := pthread_cond_timedwait(@FCond, @FMutex, @AbsTime);
  Result := Rc <> ESysETIMEDOUT;
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := SleepConditionVariableCS(FCondVar, FCS, ATimeoutMs);
  {$ENDIF}
end;

procedure TSemaphoreSlim.Init(AInitialCount: Integer; AMaxCount: Integer);
begin
  if FInitialized then
    Exit;

  if AInitialCount < 0 then
    raise Exception.Create('SemaphoreSlim: initial count must be >= 0');

  if AMaxCount = 0 then
    AMaxCount := AInitialCount;

  if AMaxCount < AInitialCount then
    raise Exception.Create('SemaphoreSlim: max count must be >= initial count');

  FCurrentCount := AInitialCount;
  FMaxCount := AMaxCount;
  FWaiterCount := 0;
  FInitialized := True;

  {$IFDEF UNIX}
  if pthread_mutex_init(@FMutex, nil) <> 0 then
    raise Exception.Create('SemaphoreSlim: failed to initialize mutex');
  if pthread_cond_init(@FCond, nil) <> 0 then
  begin
    pthread_mutex_destroy(@FMutex);
    raise Exception.Create('SemaphoreSlim: failed to initialize condition');
  end;
  {$ENDIF}
  {$IFDEF WINDOWS}
  InitializeCriticalSection(FCS);
  InitializeConditionVariable(FCondVar);
  {$ENDIF}
end;

procedure TSemaphoreSlim.Done;
begin
  if not FInitialized then
    Exit;

  // 唤醒所有等待者
  Lock;
  try
    NotifyAll;
  finally
    Unlock;
  end;

  {$IFDEF UNIX}
  pthread_cond_destroy(@FCond);
  pthread_mutex_destroy(@FMutex);
  {$ENDIF}
  {$IFDEF WINDOWS}
  DeleteCriticalSection(FCS);
  {$ENDIF}

  FInitialized := False;
end;

function TSemaphoreSlim.Wait: Boolean;
begin
  Lock;
  try
    Inc(FWaiterCount);
    try
      while FCurrentCount = 0 do
      begin
        {$IFDEF UNIX}
        pthread_cond_wait(@FCond, @FMutex);
        {$ENDIF}
        {$IFDEF WINDOWS}
        SleepConditionVariableCS(FCondVar, FCS, INFINITE);
        {$ENDIF}
      end;
      Dec(FCurrentCount);
      Result := True;
    finally
      Dec(FWaiterCount);
    end;
  finally
    Unlock;
  end;
end;

function TSemaphoreSlim.WaitTimeout(ATimeoutMs: Cardinal): Boolean;
begin
  Result := False;

  Lock;
  try
    Inc(FWaiterCount);
    try
      while FCurrentCount = 0 do
      begin
        if not WaitCondTimeout(ATimeoutMs) then
          Exit(False);
      end;
      Dec(FCurrentCount);
      Result := True;
    finally
      Dec(FWaiterCount);
    end;
  finally
    Unlock;
  end;
end;

function TSemaphoreSlim.TryWait: Boolean;
begin
  Result := False;

  Lock;
  try
    if FCurrentCount > 0 then
    begin
      Dec(FCurrentCount);
      Result := True;
    end;
  finally
    Unlock;
  end;
end;

function TSemaphoreSlim.Release: Integer;
begin
  Result := ReleaseMany(1);
end;

function TSemaphoreSlim.ReleaseMany(AReleaseCount: Integer): Integer;
begin
  if AReleaseCount < 1 then
    raise Exception.Create('SemaphoreSlim: release count must be >= 1');

  Lock;
  try
    if FCurrentCount + AReleaseCount > FMaxCount then
      raise Exception.Create('SemaphoreSlim: releasing would exceed max count');

    FCurrentCount := FCurrentCount + AReleaseCount;
    Result := FCurrentCount;

    // 唤醒等待者
    if AReleaseCount = 1 then
      NotifyOne
    else
      NotifyAll;
  finally
    Unlock;
  end;
end;

function TSemaphoreSlim.GetCurrentCount: Integer;
begin
  Lock;
  try
    Result := FCurrentCount;
  finally
    Unlock;
  end;
end;

function TSemaphoreSlim.GetMaxCount: Integer;
begin
  Result := FMaxCount;  // 不变，无需锁
end;

function TSemaphoreSlim.GetWaiterCount: Integer;
begin
  Result := atomic_load(FWaiterCount, mo_acquire);
end;

end.
