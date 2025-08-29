unit fafafa.core.sync.event.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base;

type
  { 前向声明 }
  IEvent = interface;
  ICancellationToken = interface;

  { 取消令牌接口 - 现代化的取消机制 }
  ICancellationToken = interface
    ['{A1B2C3D4-E5F6-7890-1234-567890ABCDEF}']
    function IsCancelled: Boolean;       // 检查是否已被取消
    procedure Cancel;                    // 取消操作
    procedure Reset;                     // 重置取消状态
    function WaitForCancellation(ATimeoutMs: Cardinal): Boolean; // 等待取消信号
  end;

  { RAII 守卫接口 - 自动管理事件状态 }
  IEventGuard = interface
    ['{F1E2D3C4-B5A6-9788-CDEF-123456789ABC}']
    function IsValid: Boolean;           // 守卫是否有效（成功获取到事件）
    function GetEvent: IEvent;           // 获取关联的事件对象
    procedure Release;                   // 手动释放守卫（可选）
  end;

  { 事件接口 - 简化设计，专注核心功能 }
  IEvent = interface(ISynchronizable)
    ['{E8B9D5C6-7F6A-4D3E-8B9C-6A5D4E3F2B18}']

    { 基础事件操作 }
    procedure SetEvent;
    procedure ResetEvent;
    function WaitFor: TWaitResult; overload;
    function WaitFor(ATimeoutMs: Cardinal): TWaitResult; overload;
    function IsSignaled: Boolean;

    { 扩展操作 }
    function TryWait: Boolean;           // 非阻塞等待
    procedure Pulse;                     // 脉冲信号

    { RAII 守卫方法 - 现代化的资源管理 }
    function WaitGuard: IEventGuard;                              // 阻塞等待并返回守卫
    function WaitGuard(ATimeoutMs: Cardinal): IEventGuard;        // 带超时的等待守卫
    function TryWaitGuard: IEventGuard;                          // 非阻塞等待守卫

    { 中断支持 - 现代化的取消机制 }
    function WaitForInterruptible(ATimeoutMs: Cardinal): TWaitResult; // 可中断的等待
    procedure Interrupt;                                          // 中断所有等待的线程
    function IsInterrupted: Boolean;                             // 检查是否已被中断

    { 取消令牌支持 - 现代化的取消机制 }
    function WaitForCancellable(ATimeoutMs: Cardinal;
                               ACancellationToken: ICancellationToken): TWaitResult; // 支持取消的等待
    function WaitGuardCancellable(ATimeoutMs: Cardinal;
                                 ACancellationToken: ICancellationToken): IEventGuard; // 支持取消的守卫



    { 状态查询 }
    function IsManualReset: Boolean;     // 是否手动重置
    function GetWaitingThreadCount: Integer; // 等待线程数 (调试用，Windows返回-1表示不支持)

    { 增强的错误处理 }
    function GetLastErrorMessage: string; // 获取最后错误的描述信息
    procedure ClearLastError;            // 清除最后的错误状态

    { 性能监控和指标 }
    function GetMetrics: TEventMetrics;   // 获取性能指标
    procedure ResetMetrics;              // 重置性能指标
    function IsMetricsEnabled: Boolean;   // 检查是否启用指标收集
    procedure SetMetricsEnabled(AEnabled: Boolean); // 启用/禁用指标收集

    { 已移除的兼容性方法 - 事件不是锁，不应提供锁语义
      如需锁语义，请使用专门的锁类型（Mutex、SpinLock等）
      迁移指南：
      - Acquire() -> WaitFor() 或 WaitFor(INFINITE)
      - TryAcquire() -> TryWait() 或 WaitFor(0)
      - Release() -> 根据需要使用 SetEvent() 或 ResetEvent()
    }
  end;

  { 批量等待结果 }
  TWaitMultipleResult = record
    Result: TWaitResult;      // 等待结果
    Index: Integer;           // 触发的事件索引（如果 Result = wrSignaled）
  end;

  { 事件性能指标 }
  TEventMetrics = record
    SetEventCount: Int64;     // SetEvent 调用次数
    ResetEventCount: Int64;   // ResetEvent 调用次数
    WaitCount: Int64;         // WaitFor 调用次数
    TryWaitCount: Int64;      // TryWait 调用次数
    TimeoutCount: Int64;      // 超时次数
    SignaledCount: Int64;     // 成功信号次数
    ErrorCount: Int64;        // 错误次数
    TotalWaitTime: Int64;     // 总等待时间（毫秒）
    AverageWaitTime: Double;  // 平均等待时间（毫秒）
    MaxWaitTime: Int64;       // 最大等待时间（毫秒）
    CurrentWaiters: Integer;  // 当前等待线程数
    PeakWaiters: Integer;     // 峰值等待线程数
    FastPathHits: Int64;      // 快速路径命中次数
    SlowPathHits: Int64;      // 慢速路径命中次数
  end;

// 批量操作函数
function WaitForMultiple(const Events: array of IEvent;
                        WaitAll: Boolean;
                        TimeoutMs: Cardinal): TWaitMultipleResult;

function WaitForAny(const Events: array of IEvent;
                   TimeoutMs: Cardinal = High(Cardinal)): TWaitMultipleResult;

function WaitForAll(const Events: array of IEvent;
                   TimeoutMs: Cardinal = High(Cardinal)): TWaitResult;

// 取消令牌工厂函数
function CreateCancellationToken: ICancellationToken;

implementation

uses
  SysUtils;

function WaitForMultiple(const Events: array of IEvent;
                        WaitAll: Boolean;
                        TimeoutMs: Cardinal): TWaitMultipleResult;
var
  i: Integer;
  StartTime, CurrentTime: QWord;
  RemainingTime: Cardinal;
  WaitResult: TWaitResult;
  SignaledCount: Integer;
begin
  Result.Result := wrError;
  Result.Index := -1;

  if Length(Events) = 0 then
  begin
    Result.Result := wrError;
    Exit;
  end;

  StartTime := GetTickCount64;

  if WaitAll then
  begin
    // 等待所有事件
    SignaledCount := 0;
    for i := 0 to High(Events) do
    begin
      if TimeoutMs = High(Cardinal) then
        RemainingTime := High(Cardinal)
      else
      begin
        CurrentTime := GetTickCount64;
        if CurrentTime - StartTime >= TimeoutMs then
        begin
          Result.Result := wrTimeout;
          Exit;
        end;
        RemainingTime := TimeoutMs - (CurrentTime - StartTime);
      end;

      WaitResult := Events[i].WaitFor(RemainingTime);
      if WaitResult = wrSignaled then
        Inc(SignaledCount)
      else
      begin
        Result.Result := WaitResult;
        Exit;
      end;
    end;

    if SignaledCount = Length(Events) then
    begin
      Result.Result := wrSignaled;
      Result.Index := Length(Events) - 1; // 返回最后一个事件的索引
    end;
  end
  else
  begin
    // 等待任意一个事件（轮询实现）
    repeat
      for i := 0 to High(Events) do
      begin
        if Events[i].TryWait then
        begin
          Result.Result := wrSignaled;
          Result.Index := i;
          Exit;
        end;
      end;

      if TimeoutMs <> High(Cardinal) then
      begin
        CurrentTime := GetTickCount64;
        if CurrentTime - StartTime >= TimeoutMs then
        begin
          Result.Result := wrTimeout;
          Exit;
        end;
      end;

      // 短暂休眠避免忙等待
      Sleep(1);
    until False;
  end;
end;

function WaitForAny(const Events: array of IEvent;
                   TimeoutMs: Cardinal): TWaitMultipleResult;
begin
  Result := WaitForMultiple(Events, False, TimeoutMs);
end;

function WaitForAll(const Events: array of IEvent;
                   TimeoutMs: Cardinal): TWaitResult;
var
  MultiResult: TWaitMultipleResult;
begin
  MultiResult := WaitForMultiple(Events, True, TimeoutMs);
  Result := MultiResult.Result;
end;

function CreateCancellationToken: ICancellationToken;
begin
  Result := TCancellationToken.Create;
end;

type
  { 取消令牌的具体实现 }
  TCancellationToken = class(TInterfacedObject, ICancellationToken)
  private
    FCancelled: Boolean;
    FEvent: IEvent; // 内部使用事件来实现等待机制
  public
    constructor Create;
    destructor Destroy; override;

    // ICancellationToken 实现
    function IsCancelled: Boolean;
    procedure Cancel;
    procedure Reset;
    function WaitForCancellation(ATimeoutMs: Cardinal): Boolean;
  end;
  { 事件守卫的基础实现 }
  TEventGuard = class(TInterfacedObject, IEventGuard)
  private
    FEvent: IEvent;
    FIsValid: Boolean;
    FReleased: Boolean;
  public
    constructor Create(AEvent: IEvent; AIsValid: Boolean);
    destructor Destroy; override;

    // IEventGuard 实现
    function IsValid: Boolean;
    function GetEvent: IEvent;
    procedure Release;
  end;

{ TEventGuard }

constructor TEventGuard.Create(AEvent: IEvent; AIsValid: Boolean);
begin
  inherited Create;
  FEvent := AEvent;
  FIsValid := AIsValid;
  FReleased := False;
end;

destructor TEventGuard.Destroy;
begin
  if not FReleased then
    Release;
  inherited Destroy;
end;

function TEventGuard.IsValid: Boolean;
begin
  Result := FIsValid and not FReleased;
end;

function TEventGuard.GetEvent: IEvent;
begin
  Result := FEvent;
end;

procedure TEventGuard.Release;
begin
  if not FReleased then
  begin
    // 对于手动重置事件，可以选择在守卫释放时重置事件
    // 这里暂时不做任何操作，让用户显式控制
    FReleased := True;
  end;
end;

{ TCancellationToken }

constructor TCancellationToken.Create;
begin
  inherited Create;
  FCancelled := False;
  // 注意：这里会产生循环依赖，需要在具体实现中解决
  // FEvent := CreateEvent(True, False);
end;

destructor TCancellationToken.Destroy;
begin
  FEvent := nil;
  inherited Destroy;
end;

function TCancellationToken.IsCancelled: Boolean;
begin
  Result := FCancelled;
end;

procedure TCancellationToken.Cancel;
begin
  if not FCancelled then
  begin
    FCancelled := True;
    if Assigned(FEvent) then
      FEvent.SetEvent; // 通知所有等待的线程
  end;
end;

procedure TCancellationToken.Reset;
begin
  FCancelled := False;
  if Assigned(FEvent) then
    FEvent.ResetEvent;
end;

function TCancellationToken.WaitForCancellation(ATimeoutMs: Cardinal): Boolean;
begin
  if FCancelled then
  begin
    Result := True;
    Exit;
  end;

  if Assigned(FEvent) then
    Result := FEvent.WaitFor(ATimeoutMs) = wrSignaled
  else
    Result := False;
end;

end.
