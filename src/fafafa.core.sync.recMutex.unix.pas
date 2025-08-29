unit fafafa.core.sync.recMutex.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.base, fafafa.core.sync.base,
  fafafa.core.sync.recMutex.base;

type
  TRecMutex = class(TInterfacedObject, IRecMutex)
  private
    FMutex: pthread_mutex_t;
    FLastError: TWaitError;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean; overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
    function GetLastError: TWaitError;
    function GetHandle: Pointer; // 供条件变量等高级组件使用
  end;

implementation

constructor TRecMutex.Create;
var
  Attr: pthread_mutexattr_t;
begin
  inherited Create;
  if pthread_mutexattr_init(@Attr) <> 0 then
    raise ELockError.Create('recMutex: attr_init failed');
  if pthread_mutexattr_settype(@Attr, PTHREAD_MUTEX_RECURSIVE) <> 0 then
  begin
    pthread_mutexattr_destroy(@Attr);
    raise ELockError.Create('recMutex: set recursive failed');
  end;
  if pthread_mutex_init(@FMutex, @Attr) <> 0 then
  begin
    pthread_mutexattr_destroy(@Attr);
    raise ELockError.Create('recMutex: init failed');
  end;
  pthread_mutexattr_destroy(@Attr);
  FLastError := weNone;
end;

destructor TRecMutex.Destroy;
begin
  pthread_mutex_destroy(@FMutex);
  inherited Destroy;
end;

procedure TRecMutex.Acquire;
begin
  if pthread_mutex_lock(@FMutex) <> 0 then
    raise ELockError.Create('recMutex: acquire failed');
  FLastError := weNone;
end;

procedure TRecMutex.Release;
begin
  if pthread_mutex_unlock(@FMutex) <> 0 then
    raise ELockError.Create('recMutex: release failed');
  FLastError := weNone;
end;

function TRecMutex.TryAcquire: Boolean;
begin
  Result := pthread_mutex_trylock(@FMutex) = 0;
  if Result then FLastError := weNone;
end;

function TRecMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  start: QWord;
  ts: TTimeSpec;
  lockResult: Integer;
begin
  if ATimeoutMs = 0 then Exit(TryAcquire);

  // 使用原生的超时机制而不是循环调用 TryAcquire
  start := GetTickCount64;
  ts.tv_sec := ATimeoutMs div 1000;
  ts.tv_nsec := (ATimeoutMs mod 1000) * 1000000;

  lockResult := pthread_mutex_timedlock(@FMutex, @ts);
  Result := lockResult = 0;

  if Result then
    FLastError := weNone
  else if lockResult = ESysETIMEDOUT then
    FLastError := weTimeout
  else
    FLastError := weSystemError;
end;

function TRecMutex.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

function TRecMutex.GetHandle: Pointer;
begin
  Result := @FMutex;
end;

end.

