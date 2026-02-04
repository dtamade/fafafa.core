unit fafafa.core.sync.ticketlock;

{$mode objfpc}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  TTicketLock - 票号自旋锁

  特点：
  - 纯自旋实现的公平锁（无内核调用）
  - 严格 FIFO 顺序
  - 极低的获取延迟（无竞争时）
  - 适合短临界区

  算法：
  1. 获取锁时取一个递增的票号
  2. 自旋等待直到当前服务号等于自己的票号
  3. 释放锁时递增服务号

  与 FairMutex 的区别：
  - TicketLock 纯自旋，不进入内核
  - FairMutex 在高竞争时会阻塞

  使用示例：
    var
      L: TTicketLock;
    begin
      L.Init;

      L.Acquire;
      try
        // 短临界区
      finally
        L.Release;
      end;

      L.Done;
    end;

  适用场景：
  - 极短临界区（几十纳秒级）
  - 需要公平性的自旋场景
  - CPU 核心数少的系统
}

interface

uses
  SysUtils, Classes,
  fafafa.core.atomic;

type
  ITicketLock = interface
    ['{D3E4F5A6-B7C8-9012-3456-789ABCDEF012}']
    procedure Acquire;
    function TryAcquire: Boolean;
    procedure Release;
    function IsLocked: Boolean;
  end;

  { TTicketLock - 票号自旋锁实现 }

  TTicketLock = record
  private const
    MAX_SPIN_BEFORE_YIELD = 1000;  // 让步前的最大自旋次数
  private
    FNextTicket: Int64;    // 下一个发放的票号
    FNowServing: Int64;    // 当前服务的票号
    FInitialized: Boolean;

    procedure SpinWait; inline;
    procedure YieldCPU; inline;
  public
    {** 初始化 *}
    procedure Init;

    {** 释放资源 *}
    procedure Done;

    {** 获取锁（自旋等待） *}
    procedure Acquire;

    {** 尝试获取锁（非阻塞）
        @return 成功返回 True *}
    function TryAcquire: Boolean;

    {** 释放锁 *}
    procedure Release;

    {** 检查是否已锁定 *}
    function IsLocked: Boolean;

    {** 获取等待者数量 *}
    function GetWaiterCount: Integer;

    property WaiterCount: Integer read GetWaiterCount;
  end;

{ 工厂函数 }
function MakeTicketLock: ITicketLock;

implementation

{$IFDEF UNIX}
uses
  BaseUnix;
{$ENDIF}
{$IFDEF WINDOWS}
uses
  Windows;
{$ENDIF}

type
  { TTicketLockImpl - 接口实现包装 }
  TTicketLockImpl = class(TInterfacedObject, ITicketLock)
  private
    FLock: TTicketLock;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Acquire;
    function TryAcquire: Boolean;
    procedure Release;
    function IsLocked: Boolean;
  end;

{ TTicketLockImpl }

constructor TTicketLockImpl.Create;
begin
  inherited Create;
  FLock.Init;
end;

destructor TTicketLockImpl.Destroy;
begin
  FLock.Done;
  inherited;
end;

procedure TTicketLockImpl.Acquire;
begin
  FLock.Acquire;
end;

function TTicketLockImpl.TryAcquire: Boolean;
begin
  Result := FLock.TryAcquire;
end;

procedure TTicketLockImpl.Release;
begin
  FLock.Release;
end;

function TTicketLockImpl.IsLocked: Boolean;
begin
  Result := FLock.IsLocked;
end;

function MakeTicketLock: ITicketLock;
begin
  Result := TTicketLockImpl.Create;
end;

{ TTicketLock }

procedure TTicketLock.SpinWait;
begin
  {$IFDEF CPUX86_64}
  asm
    pause
  end;
  {$ELSE}
  // 其他架构使用内存屏障
  ReadWriteBarrier;
  {$ENDIF}
end;

procedure TTicketLock.YieldCPU;
begin
  {$IFDEF UNIX}
  fpNanoSleep(@pTimespec(nil)^, nil);
  {$ENDIF}
  {$IFDEF WINDOWS}
  SwitchToThread;
  {$ENDIF}
end;

procedure TTicketLock.Init;
begin
  if FInitialized then
    Exit;

  FNextTicket := 0;
  FNowServing := 0;
  FInitialized := True;
end;

procedure TTicketLock.Done;
begin
  if not FInitialized then
    Exit;
  FInitialized := False;
end;

procedure TTicketLock.Acquire;
var
  MyTicket: Int64;
  SpinCount: Integer;
begin
  // 原子获取票号
  MyTicket := atomic_fetch_add(FNextTicket, 1, mo_relaxed);

  SpinCount := 0;

  // 自旋等待轮到我
  while atomic_load(FNowServing, mo_acquire) <> MyTicket do
  begin
    Inc(SpinCount);
    if SpinCount < MAX_SPIN_BEFORE_YIELD then
      SpinWait
    else
    begin
      YieldCPU;
      SpinCount := 0;
    end;
  end;
end;

function TTicketLock.TryAcquire: Boolean;
var
  Current, Next: Int64;
begin
  Result := False;

  // 只有当没有等待者时才能立即获取
  Current := atomic_load(FNowServing, mo_acquire);
  Next := atomic_load(FNextTicket, mo_acquire);

  if Current = Next then
  begin
    // 尝试 CAS 获取票号
    if atomic_compare_exchange_strong(FNextTicket, Next, Next + 1, mo_acq_rel, mo_relaxed) then
      Result := True;
  end;
end;

procedure TTicketLock.Release;
begin
  // 递增服务号，下一个等待者将获得锁
  atomic_fetch_add(FNowServing, 1, mo_release);
end;

function TTicketLock.IsLocked: Boolean;
var
  Next, Serving: Int64;
begin
  Serving := atomic_load(FNowServing, mo_acquire);
  Next := atomic_load(FNextTicket, mo_acquire);
  Result := Next > Serving;
end;

function TTicketLock.GetWaiterCount: Integer;
var
  Next, Serving: Int64;
begin
  Serving := atomic_load(FNowServing, mo_acquire);
  Next := atomic_load(FNextTicket, mo_acquire);
  Result := Integer(Next - Serving);
  if Result > 0 then
    Dec(Result);  // 减去当前持有者
end;

end.
