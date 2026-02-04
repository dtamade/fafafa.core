unit fafafa.core.sync.fairmutex;

{$mode objfpc}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  TFairMutex - 公平互斥锁

  特点：
  - 严格 FIFO 顺序：等待者按请求顺序获得锁
  - 防止线程饥饿：不会出现某个线程一直等不到锁的情况
  - 使用 ticket lock 算法实现公平性

  与普通 Mutex 的区别：
  - 普通 Mutex 可能导致某些线程"饥饿"
  - FairMutex 保证先请求的线程先获得锁
  - 代价是略高的开销

  使用示例：
    var
      M: TFairMutex;
    begin
      M.Init;

      M.Acquire;
      try
        // 临界区
      finally
        M.Release;
      end;

      M.Done;
    end;

  适用场景：
  - 需要公平性的场景
  - 长等待时间的临界区
  - 防止线程饥饿
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
  FAIRMTX_CLOCK_REALTIME = 0;

function fairmtx_clock_gettime(clk_id: cint; tp: PTimeSpec): cint; cdecl; external 'rt' name 'clock_gettime';
{$ENDIF}

type
  IFairMutex = interface
    ['{B1C2D3E4-F5A6-7890-1234-567890ABCDEF}']
    procedure Acquire;
    function TryAcquire: Boolean;
    function TryAcquireTimeout(ATimeoutMs: Cardinal): Boolean;
    procedure Release;
    function IsLocked: Boolean;
  end;

  { TFairMutex - 公平互斥锁实现（基于 ticket lock） }

  TFairMutex = record
  private
    FNextTicket: Int64;    // 下一个发放的 ticket
    FNowServing: Int64;    // 当前服务的 ticket
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
    procedure WaitCond; inline;
    function WaitCondTimeout(ATimeoutMs: Cardinal): Boolean; inline;
    procedure NotifyAll; inline;
  public
    {** 初始化 *}
    procedure Init;

    {** 释放资源 *}
    procedure Done;

    {** 获取锁（阻塞） *}
    procedure Acquire;

    {** 尝试获取锁（非阻塞）
        @return 成功返回 True *}
    function TryAcquire: Boolean;

    {** 尝试获取锁（带超时）
        @return 成功返回 True，超时返回 False *}
    function TryAcquireTimeout(ATimeoutMs: Cardinal): Boolean;

    {** 释放锁 *}
    procedure Release;

    {** 检查是否已锁定 *}
    function IsLocked: Boolean;

    {** 获取等待者数量 *}
    function GetWaiterCount: Integer;

    property WaiterCount: Integer read GetWaiterCount;
  end;

{ 工厂函数 }
function MakeFairMutex: IFairMutex;

implementation

type
  { TFairMutexImpl - 接口实现包装 }
  TFairMutexImpl = class(TInterfacedObject, IFairMutex)
  private
    FMutex: TFairMutex;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Acquire;
    function TryAcquire: Boolean;
    function TryAcquireTimeout(ATimeoutMs: Cardinal): Boolean;
    procedure Release;
    function IsLocked: Boolean;
  end;

{ TFairMutexImpl }

constructor TFairMutexImpl.Create;
begin
  inherited Create;
  FMutex.Init;
end;

destructor TFairMutexImpl.Destroy;
begin
  FMutex.Done;
  inherited;
end;

procedure TFairMutexImpl.Acquire;
begin
  FMutex.Acquire;
end;

function TFairMutexImpl.TryAcquire: Boolean;
begin
  Result := FMutex.TryAcquire;
end;

function TFairMutexImpl.TryAcquireTimeout(ATimeoutMs: Cardinal): Boolean;
begin
  Result := FMutex.TryAcquireTimeout(ATimeoutMs);
end;

procedure TFairMutexImpl.Release;
begin
  FMutex.Release;
end;

function TFairMutexImpl.IsLocked: Boolean;
begin
  Result := FMutex.IsLocked;
end;

function MakeFairMutex: IFairMutex;
begin
  Result := TFairMutexImpl.Create;
end;

{ TFairMutex }

procedure TFairMutex.Lock;
begin
  {$IFDEF UNIX}
  pthread_mutex_lock(@FMutex);
  {$ENDIF}
  {$IFDEF WINDOWS}
  EnterCriticalSection(FCS);
  {$ENDIF}
end;

procedure TFairMutex.Unlock;
begin
  {$IFDEF UNIX}
  pthread_mutex_unlock(@FMutex);
  {$ENDIF}
  {$IFDEF WINDOWS}
  LeaveCriticalSection(FCS);
  {$ENDIF}
end;

procedure TFairMutex.WaitCond;
begin
  {$IFDEF UNIX}
  pthread_cond_wait(@FCond, @FMutex);
  {$ENDIF}
  {$IFDEF WINDOWS}
  SleepConditionVariableCS(FCondVar, FCS, INFINITE);
  {$ENDIF}
end;

function TFairMutex.WaitCondTimeout(ATimeoutMs: Cardinal): Boolean;
{$IFDEF UNIX}
var
  AbsTime: timespec;
  Now: timespec;
  Rc: Integer;
{$ENDIF}
begin
  {$IFDEF UNIX}
  fairmtx_clock_gettime(FAIRMTX_CLOCK_REALTIME, @Now);
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

procedure TFairMutex.NotifyAll;
begin
  {$IFDEF UNIX}
  pthread_cond_broadcast(@FCond);
  {$ENDIF}
  {$IFDEF WINDOWS}
  WakeAllConditionVariable(FCondVar);
  {$ENDIF}
end;

procedure TFairMutex.Init;
begin
  if FInitialized then
    Exit;

  FNextTicket := 0;
  FNowServing := 0;
  FInitialized := True;

  {$IFDEF UNIX}
  if pthread_mutex_init(@FMutex, nil) <> 0 then
    raise Exception.Create('FairMutex: failed to initialize mutex');
  if pthread_cond_init(@FCond, nil) <> 0 then
  begin
    pthread_mutex_destroy(@FMutex);
    raise Exception.Create('FairMutex: failed to initialize condition');
  end;
  {$ENDIF}
  {$IFDEF WINDOWS}
  InitializeCriticalSection(FCS);
  InitializeConditionVariable(FCondVar);
  {$ENDIF}
end;

procedure TFairMutex.Done;
begin
  if not FInitialized then
    Exit;

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

procedure TFairMutex.Acquire;
var
  MyTicket: Int64;
begin
  Lock;
  try
    // 获取我的票号
    MyTicket := FNextTicket;
    Inc(FNextTicket);

    // 等待轮到我
    while FNowServing <> MyTicket do
      WaitCond;
  finally
    Unlock;
  end;
end;

function TFairMutex.TryAcquire: Boolean;
begin
  Result := False;

  Lock;
  try
    // 只有当没有人等待时才能立即获取
    if FNextTicket = FNowServing then
    begin
      Inc(FNextTicket);
      Result := True;
    end;
  finally
    Unlock;
  end;
end;

function TFairMutex.TryAcquireTimeout(ATimeoutMs: Cardinal): Boolean;
var
  MyTicket: Int64;
begin
  Result := False;

  Lock;
  try
    // 获取我的票号
    MyTicket := FNextTicket;
    Inc(FNextTicket);

    // 等待轮到我
    while FNowServing <> MyTicket do
    begin
      if not WaitCondTimeout(ATimeoutMs) then
      begin
        // 超时了，但我们已经拿了票，需要处理
        // 如果刚好轮到我们，就成功获取
        if FNowServing = MyTicket then
        begin
          Result := True;
          Exit;
        end;
        // 否则我们需要"放弃"这张票
        // 注意：这破坏了严格的 FIFO，但超时必须返回
        // 为了保持正确性，我们必须等待直到轮到我们然后立即释放
        while FNowServing <> MyTicket do
          WaitCond;
        // 轮到我们了，立即释放给下一个
        Inc(FNowServing);
        NotifyAll;
        Exit;
      end;
    end;
    Result := True;
  finally
    Unlock;
  end;
end;

procedure TFairMutex.Release;
begin
  Lock;
  try
    Inc(FNowServing);
    NotifyAll;
  finally
    Unlock;
  end;
end;

function TFairMutex.IsLocked: Boolean;
begin
  Lock;
  try
    Result := FNextTicket > FNowServing;
  finally
    Unlock;
  end;
end;

function TFairMutex.GetWaiterCount: Integer;
begin
  Lock;
  try
    // 等待者 = 已发票数 - 当前服务票号 - 1（持有者）
    Result := Integer(FNextTicket - FNowServing);
    if Result > 0 then
      Dec(Result);  // 减去当前持有者
  finally
    Unlock;
  end;
end;

end.
