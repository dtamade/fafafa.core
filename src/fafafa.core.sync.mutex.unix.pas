unit fafafa.core.sync.mutex.unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.mutex.base;

type
  TMutex = class(TInterfacedObject, IMutex)
  private
    FMutex: pthread_mutex_t;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean;
    function GetHandle: Pointer;
  end;

implementation

{ TMutex }

constructor TMutex.Create;
var
  Attr: pthread_mutexattr_t;
begin
  inherited Create;

  // 初始化互斥锁属性
  if pthread_mutexattr_init(@Attr) <> 0 then
    raise ELockError.Create('Failed to initialize mutex attributes');

  // 设置为不可重入（标准）互斥：Release 使用 NORMAL；Debug 使用 ERRORCHECK 便于发现误用
  {$IFDEF DEBUG}
  if pthread_mutexattr_settype(@Attr, PTHREAD_MUTEX_ERRORCHECK) <> 0 then
  begin
    pthread_mutexattr_destroy(@Attr);
    raise ELockError.Create('Failed to set mutex type to errorcheck');
  end;
  {$ELSE}
  if pthread_mutexattr_settype(@Attr, PTHREAD_MUTEX_NORMAL) <> 0 then
  begin
    pthread_mutexattr_destroy(@Attr);
    raise ELockError.Create('Failed to set mutex type to normal');
  end;
  {$ENDIF}

  // 初始化互斥锁
  if pthread_mutex_init(@FMutex, @Attr) <> 0 then
  begin
    pthread_mutexattr_destroy(@Attr);
    raise ELockError.Create('Failed to initialize mutex');
  end;

  pthread_mutexattr_destroy(@Attr);
end;

destructor TMutex.Destroy;
begin
  pthread_mutex_destroy(@FMutex);
  inherited Destroy;
end;

procedure TMutex.Acquire;
begin
  if pthread_mutex_lock(@FMutex) <> 0 then
    raise ELockError.Create('Failed to acquire mutex');
end;

procedure TMutex.Release;
begin
  if pthread_mutex_unlock(@FMutex) <> 0 then
    raise ELockError.Create('Failed to release mutex');
end;

function TMutex.TryAcquire: Boolean;
begin
  Result := pthread_mutex_trylock(@FMutex) = 0;
end;



function TMutex.GetHandle: Pointer;
begin
  Result := @FMutex;
end;

end.

