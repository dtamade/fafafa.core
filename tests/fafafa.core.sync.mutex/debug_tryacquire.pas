program debug_tryacquire;

{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex;

type
  // 继承 TTryLock 来调试
  TDebugTryLock = class(TTryLock)
  private
    FLocked: Boolean;
    FOwnerThread: TThreadID;
  public
    procedure Acquire; override;
    procedure Release; override;
    function TryAcquire: Boolean; override;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; override;
  end;

procedure TDebugTryLock.Acquire;
begin
  WriteLn('[DEBUG] Acquire called');
  if FLocked and (FOwnerThread = GetCurrentThreadId) then
    raise ELockError.Create('Reentrant acquire');
  FLocked := True;
  FOwnerThread := GetCurrentThreadId;
end;

procedure TDebugTryLock.Release;
begin
  WriteLn('[DEBUG] Release called');
  if not FLocked or (FOwnerThread <> GetCurrentThreadId) then
    raise ELockError.Create('Invalid release');
  FLocked := False;
  FOwnerThread := 0;
end;

function TDebugTryLock.TryAcquire: Boolean;
begin
  WriteLn('[DEBUG] TryAcquire() called');
  if FLocked and (FOwnerThread = GetCurrentThreadId) then
  begin
    WriteLn('[DEBUG]   -> Reentrant detected, returning False');
    Result := False;
  end
  else if FLocked then
  begin
    WriteLn('[DEBUG]   -> Lock owned by other thread, returning False');
    Result := False;
  end
  else
  begin
    WriteLn('[DEBUG]   -> Lock acquired, returning True');
    FLocked := True;
    FOwnerThread := GetCurrentThreadId;
    Result := True;
  end;
end;

function TDebugTryLock.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  StartTime: QWord;
  Count: Integer;
begin
  WriteLn('[DEBUG] TryAcquire(', ATimeoutMs, ') called');
  
  // 使用父类的默认实现
  WriteLn('[DEBUG]   -> Calling inherited implementation...');
  Result := inherited TryAcquire(ATimeoutMs);
  
  WriteLn('[DEBUG]   -> Inherited returned: ', Result);
end;

var
  Lock: TDebugTryLock;
  Result1, Result2, Result3: Boolean;
begin
  WriteLn('调试 TryAcquire 行为');
  WriteLn('====================');
  WriteLn;
  
  Lock := TDebugTryLock.Create;
  try
    WriteLn('Step 1: 第一次 TryAcquire()');
    Result1 := Lock.TryAcquire;
    WriteLn('Result: ', Result1);
    WriteLn;
    
    WriteLn('Step 2: 重入 TryAcquire()');
    Result2 := Lock.TryAcquire;
    WriteLn('Result: ', Result2);
    WriteLn;
    
    WriteLn('Step 3: 重入 TryAcquire(100)');
    Result3 := Lock.TryAcquire(100);
    WriteLn('Result: ', Result3);
    WriteLn;
    
    if Result1 then
    begin
      Lock.Release;
      WriteLn('Lock released');
    end;
    
    WriteLn;
    WriteLn('结论:');
    WriteLn('-----');
    WriteLn('TryAcquire() 返回: ', Result2, ' (期望: False)');
    WriteLn('TryAcquire(100) 返回: ', Result3, ' (期望: False)');
    
  finally
    Lock.Free;
  end;
end.
