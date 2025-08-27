unit fafafa.core.sync.spin.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.spin.base;

type
  TSpinLock = class(TInterfacedObject, ISpinLock)
  private
    FSpinLock: pthread_spinlock_t;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean; overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
  end;

implementation

{ TSpinLock }

constructor TSpinLock.Create;
begin
  inherited Create;
  // 初始化 pthread 自旋锁
  if pthread_spin_init(@FSpinLock, PTHREAD_PROCESS_PRIVATE) <> 0 then
    raise ELockError.Create('Failed to initialize pthread spinlock');
end;

destructor TSpinLock.Destroy;
begin
  // 销毁 pthread 自旋锁
  pthread_spin_destroy(@FSpinLock);
  inherited Destroy;
end;

procedure TSpinLock.Acquire;
begin
  // 使用 pthread 自旋锁（它本身处理所有线程安全问题）
  if pthread_spin_lock(@FSpinLock) <> 0 then
    raise ELockError.Create('Failed to acquire pthread spinlock');
end;

procedure TSpinLock.Release;
begin
  // 释放 pthread 自旋锁
  if pthread_spin_unlock(@FSpinLock) <> 0 then
    raise ELockError.Create('Failed to release pthread spinlock');
end;

function TSpinLock.TryAcquire: Boolean;
begin
  Result := pthread_spin_trylock(@FSpinLock) = 0;
end;

function TSpinLock.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  StartTime, ElapsedMs: QWord;
  TimeSpec: timespec;
  R: cint;
begin
  if ATimeoutMs = 0 then
  begin
    Result := TryAcquire;
    Exit;
  end;

  StartTime := GetTickCount64;
  repeat
    Result := pthread_spin_trylock(@FSpinLock) = 0;
    if Result then
      Exit;

    // 检查超时
    ElapsedMs := GetTickCount64 - StartTime;
    if ElapsedMs >= ATimeoutMs then
      Exit(False);

    // 短暂休眠避免忙等待（处理 EINTR 重试）
    TimeSpec.tv_sec := 0;
    TimeSpec.tv_nsec := 1000000; // 1ms
    repeat
      R := fpnanosleep(@TimeSpec, nil);
      if (R = 0) then Break;
      if fpgeterrno <> ESysEINTR then Break; // 其它错误，跳出由外层循环继续
    until False;
  until False;
end;



end.
