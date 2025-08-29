unit fafafa.core.sync.event.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base;

type
  { 前向声明 }
  IEvent = interface;

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



    { 状态查询 }
    function IsManualReset: Boolean;     // 是否手动重置
    function GetWaitingThreadCount: Integer; // 等待线程数 (调试用，Windows返回-1表示不支持)

    { 增强的错误处理 }
    function GetLastErrorMessage: string; // 获取最后错误的描述信息
    procedure ClearLastError;            // 清除最后的错误状态

    { 已移除的兼容性方法 - 事件不是锁，不应提供锁语义
      如需锁语义，请使用专门的锁类型（Mutex、SpinLock等）
      迁移指南：
      - Acquire() -> WaitFor() 或 WaitFor(INFINITE)
      - TryAcquire() -> TryWait() 或 WaitFor(0)
      - Release() -> 根据需要使用 SetEvent() 或 ResetEvent()
    }
  end;

implementation

type
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

end.
