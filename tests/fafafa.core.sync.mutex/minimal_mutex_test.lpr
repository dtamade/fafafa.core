program minimal_mutex_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads, pthreads, BaseUnix, Unix, UnixType,{$ENDIF}
  SysUtils;

// 最小化的同步基础定义，避免依赖复杂的 fafafa.core.base
type
  TWaitError = (
    weNone,
    weTimeout,
    weSystemError,
    weDeadlock
  );

  ISynchronizable = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function GetLastError: TWaitError;
  end;

  ILock = interface(ISynchronizable)
    ['{B8F5A2E1-4C3D-4F2A-9B1E-8D7C6A5F4E3D}']
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
  end;

  IMutex = interface(ILock)
    ['{B8F5A2E1-4C3D-4F2A-9B1E-8D7C6A5F4E3D}']
    function GetHandle: Pointer;
  end;

  ELockError = class(Exception);

  // 简化的 Unix Mutex 实现
  {$IFDEF UNIX}
  TMutex = class(TInterfacedObject, IMutex)
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
    function GetHandle: Pointer;
  end;
  {$ENDIF}

{$IFDEF UNIX}
constructor TMutex.Create;
var
  Attr: pthread_mutexattr_t;
begin
  inherited Create;
  
  if pthread_mutexattr_init(@Attr) <> 0 then
    raise ELockError.Create('Failed to initialize mutex attributes');
  
  if pthread_mutexattr_settype(@Attr, PTHREAD_MUTEX_RECURSIVE) <> 0 then
    raise ELockError.Create('Failed to set mutex type to recursive');
  
  if pthread_mutex_init(@FMutex, @Attr) <> 0 then
    raise ELockError.Create('Failed to initialize mutex');
  
  pthread_mutexattr_destroy(@Attr);
  FLastError := weNone;
end;

destructor TMutex.Destroy;
begin
  pthread_mutex_destroy(@FMutex);
  inherited Destroy;
end;

procedure TMutex.Acquire;
begin
  if pthread_mutex_lock(@FMutex) <> 0 then
  begin
    FLastError := weSystemError;
    raise ELockError.Create('Failed to acquire mutex');
  end
  else
    FLastError := weNone;
end;

procedure TMutex.Release;
begin
  if pthread_mutex_unlock(@FMutex) <> 0 then
  begin
    FLastError := weSystemError;
    raise ELockError.Create('Failed to release mutex');
  end
  else
    FLastError := weNone;
end;

function TMutex.TryAcquire: Boolean;
begin
  Result := pthread_mutex_trylock(@FMutex) = 0;
  if Result then
    FLastError := weNone
  else
    FLastError := weTimeout;
end;

function TMutex.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  start: QWord;
begin
  if ATimeoutMs = 0 then Exit(TryAcquire);
  start := GetTickCount64;
  while GetTickCount64 - start < ATimeoutMs do
  begin
    if TryAcquire then Exit(True);
    Sleep(1);
  end;
  Result := False;
  FLastError := weTimeout;
end;

function TMutex.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

function TMutex.GetHandle: Pointer;
begin
  Result := @FMutex;
end;
{$ENDIF}

function MakeMutex: IMutex;
begin
  {$IFDEF UNIX}
  Result := TMutex.Create;
  {$ELSE}
  raise Exception.Create('Platform not supported in minimal test');
  {$ENDIF}
end;

// 测试程序
var
  m: IMutex;

begin
  WriteLn('=== 最小化 Mutex 测试 ===');
  
  try
    WriteLn('1. 创建 Mutex...');
    m := MakeMutex;
    WriteLn('   ✅ MakeMutex 成功');
    
    WriteLn('2. 测试基本操作...');
    m.Acquire;
    WriteLn('   ✅ Acquire 成功');
    m.Release;
    WriteLn('   ✅ Release 成功');
    
    WriteLn('3. 测试 TryAcquire...');
    if m.TryAcquire then
    begin
      WriteLn('   ✅ TryAcquire 成功');
      m.Release;
      WriteLn('   ✅ Release 成功');
    end
    else
      WriteLn('   ❌ TryAcquire 失败');
    
    WriteLn('4. 测试可重入性...');
    m.Acquire;
    WriteLn('   ✅ 第一次 Acquire 成功');
    m.Acquire;
    WriteLn('   ✅ 第二次 Acquire 成功（可重入）');
    m.Release;
    WriteLn('   ✅ 第一次 Release 成功');
    m.Release;
    WriteLn('   ✅ 第二次 Release 成功');
    
    WriteLn('');
    WriteLn('✅ 所有测试通过！');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 测试失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
