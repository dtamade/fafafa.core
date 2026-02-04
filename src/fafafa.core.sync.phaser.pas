unit fafafa.core.sync.phaser;

{$mode objfpc}
{$I fafafa.core.settings.inc}

{
  IPhaser - 可重用的阶段同步屏障

  参照 Java Phaser 的语义：
  - 类似 Barrier 但可重复使用
  - 支持动态注册/注销参与者
  - 每个阶段完成后自动进入下一阶段

  与 Barrier 的区别：
  - Barrier: 固定参与者数，一次性使用
  - Phaser: 动态参与者数，可重复使用

  使用示例：
    var
      P: IPhaser;
    begin
      P := MakePhaser(4);  // 4 个初始参与者
      // 多线程同步
      P.ArriveAndAwaitAdvance;  // 到达并等待其他人
      // 进入下一阶段
      P.ArriveAndAwaitAdvance;
    end;
}

interface

uses
  SysUtils, BaseUnix, Unix, UnixType, pthreads,
  fafafa.core.sync.base,
  fafafa.core.atomic;

type

  { IPhaser }

  IPhaser = interface(ISynchronizable)
    ['{F8A9B0C1-2D3E-4F5A-6B7C-8D9E0F1A2B3C}']

    {**
     * Register - 注册一个新参与者
     * @return 当前阶段号
     *}
    function Register: Integer;

    {**
     * Arrive - 到达当前阶段（不等待）
     * @return 到达时的阶段号
     *}
    function Arrive: Integer;

    {**
     * ArriveAndAwaitAdvance - 到达并等待进入下一阶段
     * @return 新的阶段号
     *}
    function ArriveAndAwaitAdvance: Integer;

    {**
     * ArriveAndDeregister - 到达并注销
     * @return 到达时的阶段号
     *}
    function ArriveAndDeregister: Integer;

    {**
     * AwaitAdvance - 等待指定阶段完成
     * @param APhase 要等待的阶段号
     * @return 当前阶段号
     *}
    function AwaitAdvance(APhase: Integer): Integer;

    {**
     * GetPhase - 获取当前阶段号
     *}
    function GetPhase: Integer;

    {**
     * GetRegisteredParties - 获取注册的参与者数
     *}
    function GetRegisteredParties: Integer;

    {**
     * GetArrivedParties - 获取已到达的参与者数
     *}
    function GetArrivedParties: Integer;

    {**
     * IsTerminated - 检查是否已终止
     *}
    function IsTerminated: Boolean;
  end;

  { TPhaser }

  TPhaser = class(TInterfacedObject, IPhaser, ISynchronizable)
  private
    FMutex: pthread_mutex_t;
    FCond: pthread_cond_t;
    FPhase: Integer;
    FRegistered: Integer;
    FArrived: Integer;
    FTerminated: Boolean;
    FData: Pointer;

    procedure AdvancePhase;
  public
    constructor Create(AParties: Integer);
    destructor Destroy; override;

    { IPhaser }
    function Register: Integer;
    function Arrive: Integer;
    function ArriveAndAwaitAdvance: Integer;
    function ArriveAndDeregister: Integer;
    function AwaitAdvance(APhase: Integer): Integer;
    function GetPhase: Integer;
    function GetRegisteredParties: Integer;
    function GetArrivedParties: Integer;
    function IsTerminated: Boolean;

    { ISynchronizable }
    function GetData: Pointer;
    procedure SetData(AData: Pointer);
  end;

function MakePhaser(AParties: Integer): IPhaser;

implementation

{ TPhaser }

constructor TPhaser.Create(AParties: Integer);
begin
  inherited Create;
  FPhase := 0;
  FRegistered := AParties;
  FArrived := 0;
  FTerminated := False;
  FData := nil;

  if pthread_mutex_init(@FMutex, nil) <> 0 then
    raise ELockError.Create('Phaser: failed to initialize mutex');

  if pthread_cond_init(@FCond, nil) <> 0 then
  begin
    pthread_mutex_destroy(@FMutex);
    raise ELockError.Create('Phaser: failed to initialize condition variable');
  end;
end;

destructor TPhaser.Destroy;
begin
  pthread_cond_destroy(@FCond);
  pthread_mutex_destroy(@FMutex);
  inherited Destroy;
end;

procedure TPhaser.AdvancePhase;
begin
  FArrived := 0;
  Inc(FPhase);
  pthread_cond_broadcast(@FCond);
end;

function TPhaser.Register: Integer;
begin
  pthread_mutex_lock(@FMutex);
  try
    if FTerminated then
      Exit(-1);
    Inc(FRegistered);
    Result := FPhase;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TPhaser.Arrive: Integer;
begin
  pthread_mutex_lock(@FMutex);
  try
    if FTerminated then
      Exit(-1);

    Result := FPhase;
    Inc(FArrived);

    if FArrived >= FRegistered then
      AdvancePhase;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TPhaser.ArriveAndAwaitAdvance: Integer;
var
  CurrentPhase: Integer;
begin
  pthread_mutex_lock(@FMutex);
  try
    if FTerminated then
      Exit(-1);

    CurrentPhase := FPhase;
    Inc(FArrived);

    if FArrived >= FRegistered then
    begin
      AdvancePhase;
      Result := FPhase;
    end
    else
    begin
      // 等待其他参与者
      while (FPhase = CurrentPhase) and (not FTerminated) do
        pthread_cond_wait(@FCond, @FMutex);
      Result := FPhase;
    end;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TPhaser.ArriveAndDeregister: Integer;
begin
  pthread_mutex_lock(@FMutex);
  try
    if FTerminated then
      Exit(-1);

    Result := FPhase;
    Inc(FArrived);
    Dec(FRegistered);

    if FRegistered <= 0 then
    begin
      FTerminated := True;
      pthread_cond_broadcast(@FCond);
    end
    else if FArrived >= FRegistered then
      AdvancePhase;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TPhaser.AwaitAdvance(APhase: Integer): Integer;
begin
  pthread_mutex_lock(@FMutex);
  try
    while (FPhase = APhase) and (not FTerminated) do
      pthread_cond_wait(@FCond, @FMutex);
    Result := FPhase;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TPhaser.GetPhase: Integer;
begin
  pthread_mutex_lock(@FMutex);
  try
    Result := FPhase;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TPhaser.GetRegisteredParties: Integer;
begin
  pthread_mutex_lock(@FMutex);
  try
    Result := FRegistered;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TPhaser.GetArrivedParties: Integer;
begin
  pthread_mutex_lock(@FMutex);
  try
    Result := FArrived;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TPhaser.IsTerminated: Boolean;
begin
  pthread_mutex_lock(@FMutex);
  try
    Result := FTerminated;
  finally
    pthread_mutex_unlock(@FMutex);
  end;
end;

function TPhaser.GetData: Pointer;
begin
  Result := FData;
end;

procedure TPhaser.SetData(AData: Pointer);
begin
  FData := AData;
end;

function MakePhaser(AParties: Integer): IPhaser;
begin
  Result := TPhaser.Create(AParties);
end;

end.
