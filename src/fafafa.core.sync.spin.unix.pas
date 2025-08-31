unit fafafa.core.sync.spin.unix;

{$I fafafa.core.settings.inc}

interface

uses
  BaseUnix, Unix, pthreads,
  fafafa.core.sync.base,
  fafafa.core.sync.spin.base;

type
  // 基于 pthread_spinlock 的高性能自旋锁 - Unix 实现
  TSpin = class(TTryLock, ISpin)
  private
    FSpinLock: pthread_spinlock_t;

  public
    constructor Create;
    destructor Destroy; override;

    // ILock 接口实现
    procedure Acquire; override;
    procedure Release; override;

    // ITryLock 接口实现
    function TryAcquire: Boolean; override;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; override;
  end;

// 工厂函数
function MakeSpin: ISpin;

implementation

uses
  fafafa.core.time.cpu;

const
  BACKOFF_INITIAL = 4;
  BACKOFF_MAX     = 4096;
  TIME_CHECK_SPIN = 1024-1;   // 每 1024 次循环检查超时
  YIELD_SPIN      = 8192-1;   // 每 8192 次循环调用 SchedYield



{ TSpin }

constructor TSpin.Create;
begin
  inherited Create;
  // 初始化 pthread 自旋锁
  if pthread_spin_init(@FSpinLock, PTHREAD_PROCESS_PRIVATE) <> 0 then
    raise Exception.Create('Failed to initialize pthread spinlock');
end;

destructor TSpin.Destroy;
begin
  // 销毁 pthread 自旋锁
  pthread_spin_destroy(@FSpinLock);
  inherited Destroy;
end;

procedure TSpin.Acquire;
begin
  // 使用 pthread 自旋锁获取
  if pthread_spin_lock(@FSpinLock) <> 0 then
    raise Exception.Create('Failed to acquire pthread spinlock');
end;

procedure TSpin.Release;
begin
  // 使用 pthread 自旋锁释放
  if pthread_spin_unlock(@FSpinLock) <> 0 then
    raise Exception.Create('Failed to release pthread spinlock');
end;

function TSpin.TryAcquire: Boolean;
begin
  // 使用 pthread 非阻塞尝试获取
  Result := pthread_spin_trylock(@FSpinLock) = 0;
end;

function TSpin.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  EndTime   : QWord;
  SpinCount : Cardinal;
  Backoff   : Cardinal;
  i         : Cardinal;
begin
  // 快速路径
  if TryAcquire then
    Exit(True);

  if ATimeoutMs = 0 then
    Exit(False);

  EndTime   := GetTickCount64 + ATimeoutMs;
  SpinCount := 0;
  Backoff   := BACKOFF_INITIAL;  // 初始退避次数，例如 4

  repeat
    // === 指数退避自旋 ===
    for i := 1 to Backoff do
    begin
      CpuRelax;           // 跨平台 CPU pause / yield
      if TryAcquire then
        Exit(True);
    end;

    // === 退避加倍，限制上界 ===
    if Backoff < BACKOFF_MAX then
      Backoff := Backoff * 2
    else
      Backoff := BACKOFF_MAX;

    Inc(SpinCount);

    // === 定期检查超时 ===
    if (SpinCount and TIME_CHECK_SPIN) = 0 then
    begin
      if GetTickCount64 >= EndTime then
        Exit(False);

      // 偶尔让出 CPU，避免长时间占用
      if (SpinCount and YIELD_SPIN) = 0 then
        SchedYield;
    end;
  until False;
end;

// 工厂函数
function MakeSpin: ISpin;
begin
  Result := TSpin.Create;
end;

end.
