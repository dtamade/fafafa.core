unit fafafa.core.sync.exchanger;

{$mode objfpc}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  TExchanger<T> - 线程间数据交换器

  参照 Java Exchanger 的语义：
  - 两个线程在交换点交换数据
  - 第一个到达的线程等待
  - 第二个到达的线程与第一个交换数据后双方继续

  使用示例：
    var
      Ex: TExchanger<string>;
    begin
      Ex.Init;
      // Thread 1: 用 "Hello" 交换，得到 "World"
      Result := Ex.Exchange('Hello');
      // Thread 2: 用 "World" 交换，得到 "Hello"
      Result := Ex.Exchange('World');
    end;

  适用场景：
  - 生产者-消费者之间的直接数据传递
  - 管道模式中的缓冲区交换
  - 双缓冲技术
}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.atomic;

const
  CLOCK_REALTIME = 0;

function clock_gettime(clk_id: cint; tp: PTimeSpec): cint; cdecl; external 'rt';

type

  { generic TExchanger<T> }

  generic TExchanger<T> = record
  private
    FMutex: pthread_mutex_t;
    FCond: pthread_cond_t;
    FData: T;
    FHasData: Boolean;
    FInitialized: Boolean;
  public
    {** 初始化交换器 *}
    procedure Init;

    {** 释放资源 *}
    procedure Done;

    {** 交换数据
        @param AItem 要交换的数据
        @return 从对方获得的数据 *}
    function Exchange(const AItem: T): T;

    {** 带超时的交换
        @param AItem 要交换的数据
        @param ATimeoutMs 超时时间（毫秒）
        @param AResult 交换结果
        @return 如果成功交换返回 True *}
    function TryExchange(const AItem: T; ATimeoutMs: Cardinal; out AResult: T): Boolean;
  end;

  { 常用类型特化 }
  TExchangerInt = specialize TExchanger<Integer>;
  TExchangerStr = specialize TExchanger<string>;
  TExchangerPtr = specialize TExchanger<Pointer>;

implementation

{ TExchanger<T> }

procedure TExchanger.Init;
begin
  if FInitialized then
    Exit;

  FHasData := False;
  FInitialized := True;

  if pthread_mutex_init(@FMutex, nil) <> 0 then
    raise Exception.Create('Exchanger: failed to initialize mutex');

  if pthread_cond_init(@FCond, nil) <> 0 then
  begin
    pthread_mutex_destroy(@FMutex);
    raise Exception.Create('Exchanger: failed to initialize condition variable');
  end;
end;

procedure TExchanger.Done;
begin
  if not FInitialized then
    Exit;

  pthread_cond_destroy(@FCond);
  pthread_mutex_destroy(@FMutex);
  FInitialized := False;
end;

function TExchanger.Exchange(const AItem: T): T;
begin
  pthread_mutex_lock(@FMutex);
  try
    if FHasData then
    begin
      // 第二个到达：取走数据，放入自己的数据
      Result := FData;
      FData := AItem;
      FHasData := False;
      pthread_cond_signal(@FCond);
    end
    else
    begin
      // 第一个到达：放入数据，等待
      FData := AItem;
      FHasData := True;
      while FHasData do
        pthread_cond_wait(@FCond, @FMutex);
      Result := FData;
    end;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TExchanger.TryExchange(const AItem: T; ATimeoutMs: Cardinal; out AResult: T): Boolean;
var
  AbsTime: timespec;
  Now: timespec;
  Rc: Integer;
begin
  clock_gettime(CLOCK_REALTIME, @Now);
  AbsTime.tv_sec := Now.tv_sec + (ATimeoutMs div 1000);
  AbsTime.tv_nsec := Now.tv_nsec + ((ATimeoutMs mod 1000) * 1000000);
  if AbsTime.tv_nsec >= 1000000000 then
  begin
    Inc(AbsTime.tv_sec);
    Dec(AbsTime.tv_nsec, 1000000000);
  end;

  pthread_mutex_lock(@FMutex);
  try
    if FHasData then
    begin
      // 第二个到达
      AResult := FData;
      FData := AItem;
      FHasData := False;
      pthread_cond_signal(@FCond);
      Result := True;
    end
    else
    begin
      // 第一个到达
      FData := AItem;
      FHasData := True;

      Rc := 0;
      while FHasData and (Rc = 0) do
        Rc := pthread_cond_timedwait(@FCond, @FMutex, @AbsTime);

      if FHasData then
      begin
        // 超时，撤回数据
        FHasData := False;
        Result := False;
      end
      else
      begin
        AResult := FData;
        Result := True;
      end;
    end;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

end.
