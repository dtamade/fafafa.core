unit fafafa.core.sync.notify.windows;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  INotify Windows 实现

  使用 CONDITION_VARIABLE + CRITICAL_SECTION 实现：
  - Windows Vista+ 原生条件变量
  - NotifyOne 使用 WakeConditionVariable
  - NotifyAll 使用 WakeAllConditionVariable

  线程安全保证：
  - 所有操作都在临界区保护下进行
  - waiter count 原子更新
}

interface

{$IFDEF WINDOWS}

uses
  fafafa.core.sync.base,
  fafafa.core.sync.notify.base,
  fafafa.core.time.duration,
  fafafa.core.atomic,
  Windows;

type

  { TNotifyWindows }

  TNotifyWindows = class(TInterfacedObject, INotify, ISynchronizable)
  private
    FCS: TRTLCriticalSection;
    FCondVar: TRTLConditionVariable;
    FWaiterCount: Int32;
    FGeneration: Int64;  // 用于区分不同的通知周期
    FData: Pointer;      // 用户数据（ISynchronizable 要求）
  public
    constructor Create;
    destructor Destroy; override;

    { INotify }
    procedure Wait;
    function WaitTimeout(ATimeoutMs: Cardinal): Boolean;
    function WaitDuration(const ADuration: TDuration): TWaitResult;
    procedure NotifyOne;
    procedure NotifyAll;
    function GetWaiterCount: Integer;

    { ISynchronizable }
    function GetData: Pointer;
    procedure SetData(AData: Pointer);
  end;

function MakeNotifyWindows: INotify;

{$ENDIF}

implementation

{$IFDEF WINDOWS}

uses
  SysUtils;

{ TNotifyWindows }

constructor TNotifyWindows.Create;
begin
  inherited Create;
  FWaiterCount := 0;
  FGeneration := 0;
  FData := nil;

  InitializeCriticalSection(FCS);
  InitializeConditionVariable(FCondVar);
end;

destructor TNotifyWindows.Destroy;
begin
  DeleteCriticalSection(FCS);
  // CONDITION_VARIABLE 不需要显式销毁
  inherited Destroy;
end;

procedure TNotifyWindows.Wait;
var
  MyGeneration: Int64;
begin
  EnterCriticalSection(FCS);
  try
    // 记录当前代数，用于检测是否被通知
    MyGeneration := FGeneration;
    atomic_fetch_add(FWaiterCount, 1, mo_relaxed);

    // 等待直到代数变化（即收到通知）
    while MyGeneration = FGeneration do
      SleepConditionVariableCS(FCondVar, FCS, INFINITE);

    atomic_fetch_sub(FWaiterCount, 1, mo_relaxed);
  finally
    LeaveCriticalSection(FCS);
  end;
end;

function TNotifyWindows.WaitTimeout(ATimeoutMs: Cardinal): Boolean;
var
  MyGeneration: Int64;
  WaitResult: BOOL;
begin
  // 0 超时立即返回
  if ATimeoutMs = 0 then
    Exit(False);

  EnterCriticalSection(FCS);
  try
    MyGeneration := FGeneration;
    atomic_fetch_add(FWaiterCount, 1, mo_relaxed);

    Result := True;
    while MyGeneration = FGeneration do
    begin
      WaitResult := SleepConditionVariableCS(FCondVar, FCS, ATimeoutMs);
      if not WaitResult then
      begin
        // 检查是否是超时
        if GetLastError = ERROR_TIMEOUT then
        begin
          Result := False;
          Break;
        end;
      end;
    end;

    atomic_fetch_sub(FWaiterCount, 1, mo_relaxed);
  finally
    LeaveCriticalSection(FCS);
  end;
end;

function TNotifyWindows.WaitDuration(const ADuration: TDuration): TWaitResult;
var
  TimeoutMs: Int64;
begin
  TimeoutMs := ADuration.AsMs;

  // 负数或零立即返回超时
  if TimeoutMs <= 0 then
    Exit(wrTimeout);

  // 防止溢出
  if TimeoutMs > High(Cardinal) then
    TimeoutMs := High(Cardinal);

  if WaitTimeout(Cardinal(TimeoutMs)) then
    Result := wrSignaled
  else
    Result := wrTimeout;
end;

procedure TNotifyWindows.NotifyOne;
begin
  EnterCriticalSection(FCS);
  try
    // 增加代数，让一个等待者检测到变化
    Inc(FGeneration);
    WakeConditionVariable(FCondVar);
  finally
    LeaveCriticalSection(FCS);
  end;
end;

procedure TNotifyWindows.NotifyAll;
begin
  EnterCriticalSection(FCS);
  try
    // 增加代数，让所有等待者检测到变化
    Inc(FGeneration);
    WakeAllConditionVariable(FCondVar);
  finally
    LeaveCriticalSection(FCS);
  end;
end;

function TNotifyWindows.GetWaiterCount: Integer;
begin
  Result := atomic_load(FWaiterCount, mo_relaxed);
end;

function TNotifyWindows.GetData: Pointer;
begin
  Result := FData;
end;

procedure TNotifyWindows.SetData(AData: Pointer);
begin
  FData := AData;
end;

function MakeNotifyWindows: INotify;
begin
  Result := TNotifyWindows.Create;
end;

{$ENDIF}

end.
