unit fafafa.core.sync.namedConditionVariable.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses`n  Windows, SysUtils,`n  fafafa.core.atomic,
  fafafa.core.base, fafafa.core.sync.base,
  fafafa.core.sync.namedConditionVariable.base, fafafa.core.sync.mutex.base;

type
  // 鍏变韩鐘舵€佺粨鏋勶紙瀛樺偍鍦ㄥ叡浜唴瀛樹腑锛?
  PSharedCondVarState = ^TSharedCondVarState;
  TSharedCondVarState = record
    WaitingCount: LongInt;            // 褰撳墠绛夊緟鑰呮暟閲?
    SignalCount: LongInt;             // 寰呭鐞嗙殑淇″彿鏁伴噺
    BroadcastGeneration: LongInt;     // 骞挎挱浠ｆ暟锛岄槻姝㈣櫄鍋囧敜閱?
    Stats: TNamedConditionVariableStats; // 缁熻淇℃伅
  end;

  TNamedConditionVariable = class(TSynchronizable, INamedConditionVariable)
  private
    FName: string;
    FOriginalName: string;
    FIsCreator: Boolean;
    FLastError: TWaitError;
    FConfig: TNamedConditionVariableConfig;
    
    // Windows 鍚屾瀵硅薄
    FFileMapping: THandle;            // 鍏变韩鍐呭瓨鏄犲皠
    FSharedState: PSharedCondVarState; // 鍏变韩鐘舵€佹寚閽?
    FWaitSemaphore: THandle;          // 绛夊緟淇″彿閲?
    FSignalEvent: THandle;            // 淇″彿浜嬩欢
    FStateMutex: THandle;             // 鐘舵€佷繚鎶や簰鏂ラ攣
    
    function ValidateName(const AName: string): string;
    function CreateSharedObjects(const AName: string): Boolean;
    function OpenSharedObjects(const AName: string): Boolean;
    procedure CleanupSharedObjects;
    function GetTickCount64: QWord;
    procedure UpdateStats(AOperation: string; AWaitTimeUs: QWord = 0);
  public
    constructor Create(const AName: string); overload;
    constructor Create(const AName: string; const AConfig: TNamedConditionVariableConfig); overload;
    destructor Destroy; override;

    // ILock 鎺ュ彛锛堟潯浠跺彉閲忔湰韬殑閿佸畾锛?
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean; overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;

    // ISynchronizable 鎺ュ彛
    function GetLastError: TWaitError;
    // GetData/SetData 鐢?TSynchronizable 鎻愪緵

    // INamedConditionVariable 鎺ュ彛
    procedure Wait(const ALock: ILock); overload;
    function Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean; overload;
    procedure Signal;
    procedure Broadcast;
    
    // 鏌ヨ鎿嶄綔
    function GetName: string;
    function GetConfig: TNamedConditionVariableConfig;
    procedure UpdateConfig(const AConfig: TNamedConditionVariableConfig);
    
    // 缁熻淇℃伅
    function GetStats: TNamedConditionVariableStats;
    procedure ResetStats;
    
    // 鍏煎鎬ф柟娉?
    function GetHandle: Pointer;
    function IsCreator: Boolean;
  end;

implementation

{ TNamedConditionVariable }

constructor TNamedConditionVariable.Create(const AName: string);
begin
  Create(AName, DefaultNamedConditionVariableConfig);
end;

constructor TNamedConditionVariable.Create(const AName: string; const AConfig: TNamedConditionVariableConfig);
var
  LActualName: string;
begin
  inherited Create;
  
  FOriginalName := AName;
  FConfig := AConfig;
  FLastError := weNone;
  FIsCreator := False;
  
  // 鍒濆鍖栧彞鏌?
  FFileMapping := 0;
  FSharedState := nil;
  FWaitSemaphore := 0;
  FSignalEvent := 0;
  FStateMutex := 0;
  
  // 楠岃瘉骞跺鐞嗗悕绉?
  LActualName := ValidateName(AName);
  
  // 澶勭悊鍏ㄥ眬鍛藉悕绌洪棿
  if AConfig.UseGlobalNamespace and (Pos('Global\', LActualName) <> 1) then
    LActualName := 'Global\' + LActualName;
    
  FName := LActualName;
  
  // 灏濊瘯鍒涘缓鍏变韩瀵硅薄
  if not CreateSharedObjects(LActualName) then
  begin
    // 鍒涘缓澶辫触锛屽皾璇曟墦寮€鐜版湁鐨?
    if not OpenSharedObjects(LActualName) then
      raise ELockError.CreateFmt('Failed to create or open named condition variable "%s": %s', 
        [AName, SysErrorMessage(Windows.GetLastError)]);
  end;
end;

destructor TNamedConditionVariable.Destroy;
begin
  CleanupSharedObjects;
  inherited Destroy;
end;

function TNamedConditionVariable.ValidateName(const AName: string): string;
begin
  if AName = '' then
    raise EInvalidArgument.Create('Named condition variable name cannot be empty');
    
  if Length(AName) > 260 then
    raise EInvalidArgument.Create('Named condition variable name too long (max 260 characters)');
    
  // Windows 涓嶅厑璁稿悕绉颁腑鍖呭惈鍙嶆枩鏉狅紙闄や簡鍛藉悕绌洪棿鍓嶇紑锛?
  if (Pos('\', AName) > 0) and (Pos('Global\', AName) <> 1) and (Pos('Local\', AName) <> 1) then
    raise EInvalidArgument.Create('Invalid character in named condition variable name');
    
  Result := AName;
end;

function TNamedConditionVariable.CreateSharedObjects(const AName: string): Boolean;
var
  LSecurityAttributes: PSecurityAttributes;
  LMappingName, LSemaphoreName, LEventName, LMutexName: string;
begin
  Result := False;
  LSecurityAttributes := nil;
  
  // 鏋勯€犲悇涓璞＄殑鍚嶇О
  LMappingName := AName + '_mapping';
  LSemaphoreName := AName + '_semaphore';
  LEventName := AName + '_event';
  LMutexName := AName + '_mutex';
  
  try
    // 鍒涘缓鍏变韩鍐呭瓨鏄犲皠
    FFileMapping := CreateFileMappingW(INVALID_HANDLE_VALUE, LSecurityAttributes, 
                                      PAGE_READWRITE, 0, SizeOf(TSharedCondVarState), 
                                      PWideChar(UnicodeString(LMappingName)));
    if FFileMapping = 0 then Exit;
    
    FIsCreator := (Windows.GetLastError <> ERROR_ALREADY_EXISTS);
    
    // 鏄犲皠鍏变韩鍐呭瓨
    FSharedState := MapViewOfFile(FFileMapping, FILE_MAP_ALL_ACCESS, 0, 0, 0);
    if FSharedState = nil then Exit;
    
    // 濡傛灉鏄垱寤鸿€咃紝鍒濆鍖栧叡浜姸鎬?
    if FIsCreator then
    begin
      FillChar(FSharedState^, SizeOf(TSharedCondVarState), 0);
      FSharedState^.BroadcastGeneration := 1;
    end;
    
    // 鍒涘缓淇″彿閲忥紙鐢ㄤ簬绛夊緟锛?
    FWaitSemaphore := CreateSemaphoreW(LSecurityAttributes, 0, FConfig.MaxWaiters, 
                                      PWideChar(UnicodeString(LSemaphoreName)));
    if FWaitSemaphore = 0 then Exit;
    
    // 鍒涘缓浜嬩欢锛堢敤浜庝俊鍙烽€氱煡锛?
    FSignalEvent := CreateEventW(LSecurityAttributes, False, False, 
                                PWideChar(UnicodeString(LEventName)));
    if FSignalEvent = 0 then Exit;
    
    // 鍒涘缓浜掓枼閿侊紙淇濇姢鍏变韩鐘舵€侊級
    FStateMutex := CreateMutexW(LSecurityAttributes, False, 
                               PWideChar(UnicodeString(LMutexName)));
    if FStateMutex = 0 then Exit;
    
    Result := True;
    FLastError := weNone;
    
  except
    on E: Exception do
    begin
      CleanupSharedObjects;
      FLastError := weSystemError;
    end;
  end;
end;

function TNamedConditionVariable.OpenSharedObjects(const AName: string): Boolean;
var
  LMappingName, LSemaphoreName, LEventName, LMutexName: string;
begin
  Result := False;

  // 鏋勯€犲悇涓璞＄殑鍚嶇О
  LMappingName := AName + '_mapping';
  LSemaphoreName := AName + '_semaphore';
  LEventName := AName + '_event';
  LMutexName := AName + '_mutex';

  try
    // 鎵撳紑鐜版湁鐨勫叡浜唴瀛樻槧灏?
    FFileMapping := OpenFileMappingW(FILE_MAP_ALL_ACCESS, False,
                                    PWideChar(UnicodeString(LMappingName)));
    if FFileMapping = 0 then Exit;

    // 鏄犲皠鍏变韩鍐呭瓨
    FSharedState := MapViewOfFile(FFileMapping, FILE_MAP_ALL_ACCESS, 0, 0, 0);
    if FSharedState = nil then Exit;

    // 鎵撳紑鐜版湁鐨勫悓姝ュ璞?
    FWaitSemaphore := OpenSemaphoreW(SEMAPHORE_ALL_ACCESS, False,
                                    PWideChar(UnicodeString(LSemaphoreName)));
    if FWaitSemaphore = 0 then Exit;

    FSignalEvent := OpenEventW(EVENT_ALL_ACCESS, False,
                              PWideChar(UnicodeString(LEventName)));
    if FSignalEvent = 0 then Exit;

    FStateMutex := OpenMutexW(MUTEX_ALL_ACCESS, False,
                             PWideChar(UnicodeString(LMutexName)));
    if FStateMutex = 0 then Exit;

    Result := True;
    FLastError := weNone;

  except
    on E: Exception do
    begin
      CleanupSharedObjects;
      FLastError := weSystemError;
    end;
  end;
end;

procedure TNamedConditionVariable.CleanupSharedObjects;
begin
  if FSharedState <> nil then
  begin
    UnmapViewOfFile(FSharedState);
    FSharedState := nil;
  end;

  if FFileMapping <> 0 then
  begin
    CloseHandle(FFileMapping);
    FFileMapping := 0;
  end;

  if FWaitSemaphore <> 0 then
  begin
    CloseHandle(FWaitSemaphore);
    FWaitSemaphore := 0;
  end;

  if FSignalEvent <> 0 then
  begin
    CloseHandle(FSignalEvent);
    FSignalEvent := 0;
  end;

  if FStateMutex <> 0 then
  begin
    CloseHandle(FStateMutex);
    FStateMutex := 0;
  end;
end;

function TNamedConditionVariable.GetTickCount64: QWord;
begin
  Result := Windows.GetTickCount64;
end;

procedure TNamedConditionVariable.UpdateStats(AOperation: string; AWaitTimeUs: QWord);
begin
  if not FConfig.EnableStats then Exit;

  // 鏇存柊缁熻淇℃伅锛堝湪鍏变韩鍐呭瓨涓級
  if AOperation = 'wait' then
  begin
    Inc(FSharedState^.Stats.WaitCount);
    FSharedState^.Stats.TotalWaitTimeUs := FSharedState^.Stats.TotalWaitTimeUs + AWaitTimeUs;
    if AWaitTimeUs > FSharedState^.Stats.MaxWaitTimeUs then
      FSharedState^.Stats.MaxWaitTimeUs := AWaitTimeUs;
  end
  else if AOperation = 'signal' then
    Inc(FSharedState^.Stats.SignalCount)
  else if AOperation = 'broadcast' then
    Inc(FSharedState^.Stats.BroadcastCount)
  else if AOperation = 'timeout' then
    Inc(FSharedState^.Stats.TimeoutCount);
end;

// ILock 鎺ュ彛瀹炵幇锛堟潯浠跺彉閲忔湰韬殑閿佸畾锛?
procedure TNamedConditionVariable.Acquire;
begin
  if WaitForSingleObject(FStateMutex, INFINITE) <> WAIT_OBJECT_0 then
    raise ELockError.Create('Failed to acquire condition variable lock');
end;

procedure TNamedConditionVariable.Release;
begin
  if not ReleaseMutex(FStateMutex) then
    raise ELockError.Create('Failed to release condition variable lock');
end;

function TNamedConditionVariable.TryAcquire: Boolean;
begin
  Result := WaitForSingleObject(FStateMutex, 0) = WAIT_OBJECT_0;
end;

function TNamedConditionVariable.TryAcquire(ATimeoutMs: Cardinal): Boolean;
begin
  Result := WaitForSingleObject(FStateMutex, ATimeoutMs) = WAIT_OBJECT_0;
end;

function TNamedConditionVariable.GetLastError: TWaitError;
begin
  Result := FLastError;
end;

// 鏍稿績鏉′欢鍙橀噺鎿嶄綔
procedure TNamedConditionVariable.Wait(const ALock: ILock);
begin
  if not Wait(ALock, INFINITE) then
    raise ELockError.Create('Infinite wait should not fail');
end;

function TNamedConditionVariable.Wait(const ALock: ILock; ATimeoutMs: Cardinal): Boolean;
var
  LStartTime: QWord;
  LCurrentGeneration: LongInt;
  LWaitResult: DWORD;
begin
  Result := False;

  if ALock = nil then
    raise EInvalidArgument.Create('Mutex cannot be nil');

  LStartTime := GetTickCount64;

  // 鑾峰彇鐘舵€侀攣
  if WaitForSingleObject(FStateMutex, ATimeoutMs) <> WAIT_OBJECT_0 then
  begin
    UpdateStats('timeout');
    Exit;
  end;

  try
    // 澧炲姞绛夊緟鑰呰鏁?
    InterlockedIncrement(FSharedState^.WaitingCount);
    LCurrentGeneration := FSharedState^.BroadcastGeneration;

    // 鏇存柊缁熻
    if FSharedState^.WaitingCount > FSharedState^.Stats.MaxWaiters then
      FSharedState^.Stats.MaxWaiters := FSharedState^.WaitingCount;
    FSharedState^.Stats.CurrentWaiters := FSharedState^.WaitingCount;

  finally
    ReleaseMutex(FStateMutex);
  end;

  // 閲婃斁鐢ㄦ埛浜掓枼閿?
  ALock.Release;

  try
    // 绛夊緟淇″彿閲忔垨瓒呮椂
    LWaitResult := WaitForSingleObject(FWaitSemaphore, ATimeoutMs);

    case LWaitResult of
      WAIT_OBJECT_0: begin
        Result := True;
        UpdateStats('wait', (GetTickCount64 - LStartTime) * 1000);
      end;
      WAIT_TIMEOUT: begin
        UpdateStats('timeout');
      end;
      else begin
        FLastError := weSystemError;
      end;
    end;

  finally
    // 閲嶆柊鑾峰彇鐢ㄦ埛浜掓枼閿?
    ALock.Acquire;

    // 鍑忓皯绛夊緟鑰呰鏁?
    if WaitForSingleObject(FStateMutex, 1000) = WAIT_OBJECT_0 then
    begin
      atomic_decrement(PInt32(@FSharedState^.WaitingCount)^);
      FSharedState^.Stats.CurrentWaiters := FSharedState^.WaitingCount;
      ReleaseMutex(FStateMutex);
    end;
  end;
end;

procedure TNamedConditionVariable.Signal;
begin
  // 鑾峰彇鐘舵€侀攣
  if WaitForSingleObject(FStateMutex, 1000) <> WAIT_OBJECT_0 then
  begin
    FLastError := weSystemError;
    Exit;
  end;

  try
    // 濡傛灉鏈夌瓑寰呰€咃紝閲婃斁涓€涓俊鍙烽噺
    if FSharedState^.WaitingCount > 0 then
    begin
      ReleaseSemaphore(FWaitSemaphore, 1, nil);
      UpdateStats('signal');
    end;
  finally
    ReleaseMutex(FStateMutex);
  end;
end;

procedure TNamedConditionVariable.Broadcast;
var
  LWaitingCount: LongInt;
begin
  // 鑾峰彇鐘舵€侀攣
  if WaitForSingleObject(FStateMutex, 1000) <> WAIT_OBJECT_0 then
  begin
    FLastError := weSystemError;
    Exit;
  end;

  try
    LWaitingCount := FSharedState^.WaitingCount;
    if LWaitingCount > 0 then
    begin
      // 閲婃斁鎵€鏈夌瓑寰呰€?
      ReleaseSemaphore(FWaitSemaphore, LWaitingCount, nil);
      // 澧炲姞骞挎挱浠ｆ暟锛岄槻姝㈣櫄鍋囧敜閱?
      atomic_increment(PInt32(@FSharedState^.BroadcastGeneration)^);
      UpdateStats('broadcast');
    end;
  finally
    ReleaseMutex(FStateMutex);
  end;
end;

// 鏌ヨ鎿嶄綔
function TNamedConditionVariable.GetName: string;
begin
  Result := FOriginalName;
end;

function TNamedConditionVariable.GetConfig: TNamedConditionVariableConfig;
begin
  Result := FConfig;
end;

procedure TNamedConditionVariable.UpdateConfig(const AConfig: TNamedConditionVariableConfig);
begin
  FConfig := AConfig;
  // 娉ㄦ剰锛氫笉鑳芥洿鏀?UseGlobalNamespace锛屽洜涓哄璞″凡缁忓垱寤?
end;

// 缁熻淇℃伅
function TNamedConditionVariable.GetStats: TNamedConditionVariableStats;
begin
  if FSharedState <> nil then
    Result := FSharedState^.Stats
  else
    Result := EmptyNamedConditionVariableStats;
end;

procedure TNamedConditionVariable.ResetStats;
begin
  if FSharedState <> nil then
    FillChar(FSharedState^.Stats, SizeOf(TNamedConditionVariableStats), 0);
end;

// 鍏煎鎬ф柟娉?
function TNamedConditionVariable.GetHandle: Pointer;
begin
  Result := Pointer(FFileMapping);
end;

function TNamedConditionVariable.IsCreator: Boolean;
begin
  Result := FIsCreator;
end;



end.

