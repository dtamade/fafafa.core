unit fafafa.core.thread.future;

{**
 * fafafa.core.thread.future - Future/Promise 异步结果模块
 *
 * @desc 提供现代化的异步编程支持，包括：
 *       - IFuture 接口：异步操作结果的标准接口
 *       - TFuture 类：高性能的 Future 实现
 *       - 链式调用支持：ContinueWith, OnComplete
 *       - 函数式编程：Map, AndThen
 *       - 线程安全的状态管理
 *
 * @author fafafa.core 开发团队
 * @version 1.0.0
 * @since 2025-08-08
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.sync,
  fafafa.core.thread.debuglog;

type

  {**
   * Future 相关异常类型
   *}

  {**
   * EFutureError
   *
   * @desc Future 操作的基础异常类
   *}
  EFutureError = class(ECore);

  {**
   * EFutureTimeoutError
   *
   * @desc Future 操作超时时抛出的异常
   *}
  EFutureTimeoutError = class(EFutureError);

  {**
   * EFutureCancelledError
   *
   * @desc Future 已取消时进行操作抛出的异常
   *}
  EFutureCancelledError = class(EFutureError);

  {**
   * TFutureState
   *
   * @desc Future 状态枚举
   *}
  TFutureState = (
    fsPending,    // 等待中
    fsCompleted,  // 已完成
    fsCancelled,  // 已取消
    fsFailed      // 执行失败
  );

  {**
   * 任务回调函数类型定义
   *}
  TTaskFunc = function(aData: Pointer): Boolean;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  TTaskRefFunc = reference to function(): Boolean;
  {$ENDIF}

  {**
   * IFuture
   *
   * @desc 现代化 Future 接口 - 支持链式调用和函数式编程
   *       提供类似 Rust/JavaScript Promise 的 API
   *}
  IFuture = interface
    ['{B1C2D3E4-F5A6-7B8C-9D0E-F1A2B3C4D5E6}']

    {**
     * IsDone
     *
     * @desc 检查异步操作是否完成
     *
     * @return 操作完成返回 True，否则返回 False
     *}
    function IsDone: Boolean;

    {**
     * IsCancelled
     *
     * @desc 检查异步操作是否被取消
     *
     * @return 操作被取消返回 True，否则返回 False
     *}
    function IsCancelled: Boolean;

    {**
     * Cancel
     *
     * @desc 取消异步操作
     *
     * @return 成功取消返回 True，否则返回 False
     *}
    function Cancel: Boolean;

    {**
     * WaitFor
     *
     * @desc 等待异步操作完成
     *
     * @params
     *    ATimeoutMs: Cardinal 超时时间（毫秒），INFINITE 表示无限等待
     *
     * @return 在超时前完成返回 True，否则返回 False
     *}
    function WaitFor(ATimeoutMs: Cardinal = INFINITE): Boolean;

    {**
     * ContinueWith - 现代化链式调用
     *
     * @desc 在当前 Future 完成后执行回调（类似 JavaScript Promise.then）
     *
     * @params
     *    ACallback: TTaskRefFunc 完成时的回调函数
     *
     * @return 返回新的 Future 用于继续链式调用
     *}
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    function ContinueWith(const ACallback: TTaskRefFunc): IFuture;
    {$ENDIF}

    {**
     * OnComplete - 完成回调
     *
     * @desc 设置 Future 完成时的回调函数
     *
     * @params
     *    ACallback: TTaskRefFunc 完成时的回调函数
     *
     * @return 返回自身，支持链式调用
     *}
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure OnComplete(const ACallback: TTaskRefFunc);
    {$ENDIF}

    {**
     * Map - 函数式映射
     *
     * @desc 对 Future 的结果进行转换（类似 Rust 的 map）
     *
     * @params
     *    AMapper: TTaskFunc 映射函数
     *    AData: Pointer 传递给映射函数的数据
     *
     * @return 返回新的 Future 包含转换后的结果
     *}
    function Map(AMapper: TTaskFunc; AData: Pointer = nil): IFuture;

    {**
     * AndThen - 链式异步操作
     *
     * @desc 在当前 Future 完成后执行另一个异步操作（类似 Rust 的 and_then）
     *
     * @params
     *    ANext: TTaskFunc 下一个异步操作
     *    AData: Pointer 传递给下一个操作的数据
     *
     * @return 返回新的 Future 表示整个链式操作的结果
     *}
    function AndThen(ANext: TTaskFunc; AData: Pointer = nil): IFuture;
  end;

  {**
   * IFutureInternal
   *
   * @desc Future 内部接口，用于线程池内部操作
   *}
  IFutureInternal = interface(IFuture)
    ['{C2D3E4F5-A6B7-8C9D-0E1F-A2B3C4D5E6F7}']

    {**
     * Complete
     *
     * @desc 标记 Future 为完成状态
     *}
    procedure Complete;

    {**
     * Fail
     *
     * @desc 标记 Future 为失败状态
     *
     * @params
     *    AException: Exception 异常对象
     *}
    procedure Fail(AException: Exception);
  end;

  {**
   * TFuture
   *
   * @desc Future 实现类
   *       提供异步操作结果的获取和管理
   *}
  TFuture = class(TInterfacedObject, IFuture, IFutureInternal)
  private
    FState: TFutureState;
    FException: Exception;
    FEvent: IEvent;
    FLock: ILock;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    FOnComplete: TTaskRefFunc;
    {$ENDIF}

    FCallbackInvoked: Boolean; // 确保回调最多执行一次

    procedure SetCompleted;
    procedure SetCancelled;
    procedure SetFailed(AException: Exception);
    procedure NotifyCompletion;

  public
    constructor Create;
    destructor Destroy; override;

    // IFuture 接口实现
    function IsDone: Boolean;
    function IsCancelled: Boolean;
    function Cancel: Boolean;
    function WaitFor(ATimeoutMs: Cardinal = INFINITE): Boolean;

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    function ContinueWith(const ACallback: TTaskRefFunc): IFuture;
    procedure OnComplete(const ACallback: TTaskRefFunc);
    {$ENDIF}

    // Rust 启发的组合方法
    function Map(AMapper: TTaskFunc; AData: Pointer = nil): IFuture;
    function AndThen(ANext: TTaskFunc; AData: Pointer = nil): IFuture;

    // 内部方法
    procedure Complete;
    procedure Fail(AException: Exception);
  end;

implementation

{ TFuture }

constructor TFuture.Create;
begin
  inherited Create;
  FState := fsPending;
  FException := nil;
  FEvent := TEvent.Create(True, False); // ManualReset=True, InitialState=False
  FLock := TMutex.Create;
  {$IFDEF FAFAFA_THREAD_DEBUG}
  DebugLog(Format('future.new %p', [Pointer(Self)]));
  {$ENDIF}
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  FOnComplete := nil;
  {$ENDIF}
  FCallbackInvoked := False;
end;

destructor TFuture.Destroy;
begin
  // 先释放异常对象，避免析构期回调再次触发
  FreeAndNil(FException);
  FEvent := nil;
  FLock := nil;
  {$IFDEF FAFAFA_THREAD_DEBUG}
  DebugLog(Format('future.free %p', [Pointer(Self)]));
  {$ENDIF}
  inherited Destroy;
end;

function TFuture.IsDone: Boolean;
begin
  FLock.Acquire;
  try
    Result := FState in [fsCompleted, fsCancelled, fsFailed];
  finally
    FLock.Release;
  end;
end;

function TFuture.IsCancelled: Boolean;
begin
  FLock.Acquire;
  try
    Result := FState = fsCancelled;
  finally
    FLock.Release;
  end;
end;

function TFuture.Cancel: Boolean;
var
  LDidCancel: Boolean;
begin
  LDidCancel := False;
  FLock.Acquire;
  try
    if FState = fsPending then
    begin
      SetCancelled;
      LDidCancel := True;
      Result := True;
    end
    else if FState = fsCompleted then
      raise EInvalidOperation.Create('Future 已经完成，不能取消')
    else
      Result := False; // 已经取消
  finally
    FLock.Release;
  end;
end;

function TFuture.WaitFor(ATimeoutMs: Cardinal): Boolean;
begin
  // 如果已经完成，直接返回
  if IsDone then
  begin
    DebugLog('future wait early-done');
    Result := True;
    Exit;
  end;

  // 等待事件信号
  case FEvent.WaitFor(ATimeoutMs) of
    wrSignaled:
      begin
        DebugLog('future wait signaled'); Result := True;
      end;
    wrTimeout:
      begin
        // 赛后复核：超时瞬间可能已完成（抗竞态）
        if IsDone then
        begin
          DebugLog('future wait timeout-late-done'); Result := True;
        end
        else
        begin
          DebugLog('future wait timeout'); Result := False;
        end;
      end;
  else
    DebugLog('future wait other'); Result := False;
  end;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function TFuture.ContinueWith(const ACallback: TTaskRefFunc): IFuture;
var
  LNewFuture: TFuture;
begin
  LNewFuture := TFuture.Create;
  Result := LNewFuture;

  // 如果当前 Future 已完成，立即执行回调
  if IsDone then
  begin
    try
      if ACallback() then
        LNewFuture.Complete
      else
        LNewFuture.Fail(Exception.Create('回调函数返回 False'));
    except
      on E: Exception do
        LNewFuture.Fail(E);
    end;
  end
  else
  begin
    // 设置完成回调 - 使用更安全的方式
    FLock.Acquire;
    try
      // 保持一次性回调的语义：只记录最近一次
      FOnComplete := function(): Boolean
      begin
        try
          Result := ACallback();
          if Result then
            LNewFuture.Complete
          else
            LNewFuture.Fail(Exception.Create('回调函数返回 False'));
        except
          on E: Exception do
          begin
            LNewFuture.Fail(E);
            Result := False;
          end;
        end;
      end;
    finally
      FLock.Release;
    end;
  end;
end;

procedure TFuture.OnComplete(const ACallback: TTaskRefFunc);
var
  LCallDirect: Boolean;
  LCallback: TTaskRefFunc;
begin
  LCallDirect := False;
  LCallback := nil;

  // 若未完成：登记一次性回调；若已完成：若尚未回调则立即在锁外调用
  FLock.Acquire;
  try
    {$IFDEF FAFAFA_THREAD_DEBUG}
    DebugLog('future.oncomplete: set/trigger');
    {$ENDIF}
    if FState in [fsPending] then
    begin
      // 保持一次性回调的语义：只记录最近一次
      FOnComplete := ACallback;
    end
    else
    begin
      // 已完成：只有当尚未触发过回调时才在锁外调用一次，并标记已触发
      if not FCallbackInvoked then
      begin
        FCallbackInvoked := True;
        LCallDirect := True;
        LCallback := ACallback;
      end;
    end;
  finally
    FLock.Release;
  end;

  if LCallDirect and Assigned(LCallback) then
  begin
    try
      // 与异步路径保持一致：捕获返回值但不用于改变状态
      if not LCallback() then ;
    except
      on E: Exception do
      begin
        // 回调异常不传播到调用者，保持与异步回调一致的弹性
      end;
    end;
  end;
end;
{$ENDIF}

function TFuture.Map(AMapper: TTaskFunc; AData: Pointer = nil): IFuture;
var
  LNewFuture: TFuture;
begin
  LNewFuture := TFuture.Create;
  Result := LNewFuture;

  // 当当前 Future 完成时，执行映射函数
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  OnComplete(function(): Boolean
  begin
    try
      // 执行映射函数
      AMapper(AData);
      LNewFuture.Complete;
      Result := True;
    except
      on E: Exception do
      begin
        LNewFuture.Fail(E);
        Result := False;
      end;
    end;
  end);
  {$ELSE}
  // 简化版本：直接返回当前 Future
  Result := Self;
  {$ENDIF}
end;

function TFuture.AndThen(ANext: TTaskFunc; AData: Pointer = nil): IFuture;
var
  LNewFuture: TFuture;
begin
  LNewFuture := TFuture.Create;
  Result := LNewFuture;

  // 当当前 Future 完成时，执行下一个任务
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  OnComplete(function(): Boolean
  begin
    try
      // 注意：这里需要引用 TThreads.Spawn，但为了避免循环依赖，
      // 我们暂时使用简化实现
      ANext(AData);
      LNewFuture.Complete;
      Result := True;
    except
      on E: Exception do
      begin
        LNewFuture.Fail(E);
        Result := False;
      end;
    end;
  end);
  {$ELSE}
  // 简化版本：直接返回当前 Future
  Result := Self;
  {$ENDIF}
end;

procedure TFuture.Complete;
begin
  FLock.Acquire;
  try
    if FState = fsPending then
      SetCompleted
    else if FState = fsCompleted then
      raise EInvalidOperation.Create('Future 已经完成，不能重复完成')
    else
      raise EInvalidOperation.Create('Future 已经完成或取消，不能重复完成');
  finally
    FLock.Release;
  end;
  // 在锁外通知回调，避免任何潜在的锁嵌套问题
  NotifyCompletion;
end;

procedure TFuture.Fail(AException: Exception);
begin
  FLock.Acquire;
  try
    if FState = fsPending then
      SetFailed(AException);
  finally
    FLock.Release;
  end;
  // 在锁外通知回调，避免任何潜在的锁嵌套问题
  NotifyCompletion;
end;

procedure TFuture.SetCompleted;
begin
  FState := fsCompleted;
  FEvent.SetEvent;
end;

procedure TFuture.SetCancelled;
begin
  FState := fsCancelled;
  FEvent.SetEvent;
end;

procedure TFuture.SetFailed(AException: Exception);
var
  LMsg: string;
begin
  FState := fsFailed;
  // 拷贝异常信息，避免引用已释放的异常对象；并且接管传入异常的释放，消除外部泄漏
  if Assigned(AException) then
    LMsg := AException.Message
  else
    LMsg := 'Future failed';

  // 释放传入的异常（Fail/SetFailed 对异常拥有所有权）
  FreeAndNil(AException);

  // 用消息构造内部异常对象（供调用方查询）
  FreeAndNil(FException);
  FException := Exception.Create(LMsg);
  FEvent.SetEvent;
end;

procedure TFuture.NotifyCompletion;
var
  LCallback: TTaskRefFunc;
  LRes: Boolean;
  LCallNow: Boolean;
begin
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  LCallback := nil;
  LCallNow := False;

  // 在锁保护下获取并清空回调函数，避免重复调用和竞态；并确保最多一次执行
  FLock.Acquire;
  try
    if not FCallbackInvoked then
    begin
      LCallback := FOnComplete;
      {$IFDEF FAFAFA_THREAD_DEBUG}
      if Assigned(LCallback) then DebugLog('future.notify: take-callback') else DebugLog('future.notify: no-callback');
      {$ENDIF}
      FOnComplete := nil;
      LCallNow := Assigned(LCallback);
      // 仅当确有回调时，才标记为已调用，避免阻断“完成后注册”的立即调用
      if LCallNow then FCallbackInvoked := True;
    end
    else
    begin
      {$IFDEF FAFAFA_THREAD_DEBUG}
      DebugLog('future.notify: already-invoked');
      {$ENDIF}
    end;
  finally
    FLock.Release;
  end;

  // 在锁外执行回调，避免死锁
  if LCallNow then
  begin
    try
      {$IFDEF FAFAFA_THREAD_DEBUG}
      DebugLog(Format('future.notify.invoke %p', [Pointer(Self)]));
      {$ENDIF}
      LRes := LCallback();
      {$IFDEF FAFAFA_THREAD_DEBUG}
      DebugLog('future.notify.invoke-done');
      {$ENDIF}
      // 不使用返回值，仅为确保调用约定稳定
      if False and LRes then ;
    except
      // 忽略回调中的异常，避免影响主流程
    end;
  end;
  {$ENDIF}
end;

end.
