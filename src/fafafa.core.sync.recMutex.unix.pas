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
  public
    constructor Create;
    destructor Destroy; override;
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean;
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
end;

procedure TRecMutex.Release;
begin
  if pthread_mutex_unlock(@FMutex) <> 0 then
    raise ELockError.Create('recMutex: release failed');
end;

function TRecMutex.TryAcquire: Boolean;
begin
  Result := pthread_mutex_trylock(@FMutex) = 0;
end;

function TRecMutex.GetHandle: Pointer;
begin
  Result := @FMutex;
end;

end.

