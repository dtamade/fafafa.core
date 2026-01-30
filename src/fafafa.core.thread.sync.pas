unit fafafa.core.thread.sync;

{**
 * fafafa.core.thread.sync - 线程同步原语模块
 *
 * @desc 提供高级线程同步功能，包括：
 *       - ICountDownLatch 接口：倒计数门闩的标准接口
 *       - TCountDownLatch 类：高性能的倒计数门闩实现
 *       - 线程安全的计数管理
 *       - 高效的等待机制
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
  fafafa.core.sync;

type

  {**
   * 线程同步相关异常类型
   *}

  {**
   * EThreadError
   *
   * @desc 线程操作的基础异常类
   *}
  EThreadError = class(ECore);

  {**
   * ICountDownLatch
   *
   * @desc 倒计数门闩接口
   *       允许一个或多个线程等待其他线程完成操作
   *}
  ICountDownLatch = interface
    ['{E2F3A4B5-C6D7-8E9F-0A1B-C2D3E4F5A6B7}']

    {**
     * CountDown
     *
     * @desc 减少计数器
     *}
    procedure CountDown;

    {**
     * Await
     *
     * @desc 等待计数器归零
     *
     * @params
     *    ATimeoutMs: Cardinal 超时时间（毫秒），INFINITE 表示无限等待
     *
     * @return 在超时前归零返回 True，否则返回 False
     *}
    function Await(ATimeoutMs: Cardinal = INFINITE): Boolean;

    {**
     * GetCount
     *
     * @desc 获取当前计数
     *
     * @return 返回当前计数值
     *}
    function GetCount: Integer;

    // 属性访问器
    property Count: Integer read GetCount;
  end;

  {**
   * TCountDownLatch
   *
   * @desc 倒计数门闩实现类
   *       允许一个或多个线程等待其他线程完成操作
   *}
  TCountDownLatch = class(TInterfacedObject, ICountDownLatch)
  private
    FCount: Integer;
    FLock: ILock;
    FEvent: IEvent;

  public
    constructor Create(ACount: Integer);
    destructor Destroy; override;

    procedure CountDown;
    function Await(ATimeoutMs: Cardinal = INFINITE): Boolean;
    function GetCount: Integer;
  end;

implementation

{ TCountDownLatch }

constructor TCountDownLatch.Create(ACount: Integer);
begin
  inherited Create;

  if ACount < 0 then
    raise EInvalidArgument.Create('CountDownLatch 计数不能为负数');

  FCount := ACount;
  FLock := TMutex.Create;
  FEvent := TEvent.Create(True, ACount = 0); // ManualReset=True, InitialState=(ACount=0)

  // 如果初始计数为0，立即设置事件
  if FCount = 0 then
    FEvent.SetEvent;
end;

destructor TCountDownLatch.Destroy;
begin
  FLock := nil;
  FEvent := nil;
  inherited Destroy;
end;

procedure TCountDownLatch.CountDown;
begin
  FLock.Acquire;
  try
    if FCount > 0 then
    begin
      Dec(FCount);

      // 当计数归零时，唤醒所有等待的线程
      if FCount = 0 then
        FEvent.SetEvent;
    end;
  finally
    FLock.Release;
  end;
end;

function TCountDownLatch.Await(ATimeoutMs: Cardinal): Boolean;
begin
  // 如果计数已经为0，立即返回
  FLock.Acquire;
  try
    if FCount = 0 then
    begin
      Result := True;
      Exit;
    end;
  finally
    FLock.Release;
  end;

  // 等待事件信号
  Result := FEvent.WaitFor(ATimeoutMs) = wrSignaled;
end;

function TCountDownLatch.GetCount: Integer;
begin
  FLock.Acquire;
  try
    Result := FCount;
  finally
    FLock.Release;
  end;
end;

end.
