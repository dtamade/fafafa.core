unit fafafa.core.time.timeout;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.timeout - 超时处理

📖 概述：
  提供超时相关功能和工具，包括超时检测、超时管理、超时策略等。
  支持可取消的超时操作和灵活的超时配置。

🔧 特性：
  • 超时检测和管理
  • 可取消的超时操作
  • 多种超时策略
  • 超时回调和事件
  • 与取消令牌集成

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
──────────────────────────────────────────────────────────────
}

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  Classes,
  fafafa.core.time.base,
  fafafa.core.time.clock,
  fafafa.core.thread.cancel;

type
  // 超时状态
  TTimeoutState = (
    tsActive,     // 活动中
    tsExpired,    // 已超时
    tsCancelled,  // 已取消
    tsCompleted   // 已完成
  );

  // 超时策略
  TTimeoutStrategy = (
    tsFixed,      // 固定超时
    tsAdaptive,   // 自适应超时
    tsExponential // 指数退避超时
  );

  // 前向声明
  ITimeout = interface;
  ITimeoutManager = interface;

  // 超时回调类型
  TTimeoutCallback = procedure(const ATimeout: ITimeout) of object;
  TTimeoutCallbackProc = procedure(const ATimeout: ITimeout);

  {**
   * TDeadline - 截止时间（从 base 模块移动到这里）
   *
   * @desc
   *   表示一个截止时间点，用于超时检测和管理。
   *
   * @thread_safety
   *   值类型，天然线程安全。
   *}
  TDeadline = record
  private
    FInstant: TInstant;
  public
    // 构造函数
    class function Never: TDeadline; static; inline;
    class function Now: TDeadline; static; inline;
    class function After(const D: TDuration): TDeadline; static; inline;
    class function At(const T: TInstant): TDeadline; static; inline;
    class function FromNow(const D: TDuration): TDeadline; static; inline;
    
    // 查询操作
    function GetInstant: TInstant; inline;
    function Remaining: TDuration; inline;
    function Remaining(const ANow: TInstant): TDuration; inline;
    function HasExpired: Boolean; inline;
    function HasExpired(const ANow: TInstant): Boolean; inline;
    function Expired: Boolean; inline; // alias for HasExpired
    function IsNever: Boolean; inline;
    
    // 时间计算
    function TimeUntil(const ANow: TInstant): TDuration; inline; // = Remaining
    function Overdue(const ANow: TInstant): TDuration; inline; // max(-Remaining, 0)
    function IsExpired(const ANow: TInstant): Boolean; inline; // = Expired
    
    // 操作
    function Extend(const D: TDuration): TDeadline; inline;
    function ExtendTo(const T: TInstant): TDeadline; inline;
    
    // 比较
    function Compare(const AOther: TDeadline): Integer; inline;
    function Equal(const AOther: TDeadline): Boolean; inline;
    function LessThan(const AOther: TDeadline): Boolean; inline;
    function GreaterThan(const AOther: TDeadline): Boolean; inline;
    
    // 运算符重载
    class operator =(const A, B: TDeadline): Boolean; inline;
    class operator <>(const A, B: TDeadline): Boolean; inline;
    class operator <(const A, B: TDeadline): Boolean; inline;
    class operator >(const A, B: TDeadline): Boolean; inline;
    class operator <=(const A, B: TDeadline): Boolean; inline;
    class operator >=(const A, B: TDeadline): Boolean; inline;
    
    // 字符串表示
    function ToString: string;
  end;

  {**
   * ITimeout - 超时接口
   *
   * @desc
   *   表示一个超时实例，提供超时检测和管理功能。
   *
   * @thread_safety
   *   实现应保证线程安全。
   *}
  ITimeout = interface
    ['{F7E6D5C4-B3A2-1F0E-9D8C-7B6A5F4E3D2C}']
    
    // 基本信息
    function GetId: string;
    function GetName: string;
    function GetState: TTimeoutState;
    function GetStrategy: TTimeoutStrategy;
    function GetDeadline: TDeadline;
    function GetDuration: TDuration;
    function GetCreatedTime: TInstant;
    
    // 状态查询
    function IsActive: Boolean;
    function IsExpired: Boolean;
    function IsCancelled: Boolean;
    function IsCompleted: Boolean;
    function Remaining: TDuration;
    function Elapsed: TDuration;
    
    // 控制操作
    procedure Start;
    procedure Stop;
    procedure Cancel;
    procedure Reset; overload;
    procedure Reset(const ANewDuration: TDuration); overload;
    procedure Extend(const AAdditionalTime: TDuration);
    procedure ExtendTo(const ANewDeadline: TDeadline);
    
    // 回调设置
    procedure SetCallback(const ACallback: TTimeoutCallback); overload;
    procedure SetCallback(const ACallback: TTimeoutCallbackProc); overload;
    
    // 等待操作
    function Wait: Boolean; // 等待直到超时或取消
    function Wait(const AToken: ICancellationToken): Boolean; // 可取消等待
    
    // 事件触发
    procedure TriggerTimeout; // 手动触发超时
  end;

  {**
   * ITimeoutManager - 超时管理器接口
   *
   * @desc
   *   管理多个超时实例，提供统一的超时处理。
   *
   * @thread_safety
   *   实现应保证线程安全。
   *}
  ITimeoutManager = interface
    ['{E6F5D4C3-B2A1-0F9E-8D7C-6B5A4F3E2D1C}']
    
    // 超时创建
    function CreateTimeout(const ADuration: TDuration; const AName: string = ''): ITimeout; overload;
    function CreateTimeout(const ADeadline: TDeadline; const AName: string = ''): ITimeout; overload;
    function CreateTimeout(const ADuration: TDuration; const ACallback: TTimeoutCallback; const AName: string = ''): ITimeout; overload;
    function CreateTimeout(const ADuration: TDuration; const ACallback: TTimeoutCallbackProc; const AName: string = ''): ITimeout; overload;
    
    // 超时管理
    procedure AddTimeout(const ATimeout: ITimeout);
    procedure RemoveTimeout(const ATimeout: ITimeout); overload;
    procedure RemoveTimeout(const ATimeoutId: string); overload;
    function GetTimeout(const ATimeoutId: string): ITimeout;
    function GetTimeouts: TArray<ITimeout>; overload;
    function GetTimeouts(AState: TTimeoutState): TArray<ITimeout>; overload;
    
    // 批量操作
    procedure CancelAll;
    procedure CancelExpired;
    procedure CleanupCompleted;
    
    // 状态查询
    function GetActiveCount: Integer;
    function GetExpiredCount: Integer;
    function GetTotalCount: Integer;
    function GetNextExpiration: TDeadline;
    
    // 管理器控制
    procedure Start;
    procedure Stop;
    procedure Pause;
    procedure Resume;
    function IsRunning: Boolean;
    function IsPaused: Boolean;
    
    // 配置
    procedure SetClock(const AClock: IMonotonicClock);
    function GetClock: IMonotonicClock;
    procedure SetCheckInterval(const AInterval: TDuration);
    function GetCheckInterval: TDuration;
  end;

  {**
   * TTimeoutOptions - 超时选项
   *
   * @desc
   *   超时创建和配置的选项。
   *}
  TTimeoutOptions = record
    Strategy: TTimeoutStrategy;
    AutoStart: Boolean;
    AutoRemove: Boolean; // 超时后自动移除
    Name: string;
    
    class function Default: TTimeoutOptions; static;
    class function AutoStart: TTimeoutOptions; static;
    class function Manual: TTimeoutOptions; static;
  end;

// 工厂函数
function CreateTimeout(const ADuration: TDuration; const AName: string = ''): ITimeout; overload;
function CreateTimeout(const ADeadline: TDeadline; const AName: string = ''): ITimeout; overload;
function CreateTimeout(const ADuration: TDuration; const AOptions: TTimeoutOptions): ITimeout; overload;
function CreateTimeout(const ADuration: TDuration; const ACallback: TTimeoutCallback; const AName: string = ''): ITimeout; overload;
function CreateTimeout(const ADuration: TDuration; const ACallback: TTimeoutCallbackProc; const AName: string = ''): ITimeout; overload;

function CreateTimeoutManager: ITimeoutManager; overload;
function CreateTimeoutManager(const AClock: IMonotonicClock): ITimeoutManager; overload;

// 默认管理器
function DefaultTimeoutManager: ITimeoutManager;

// 便捷超时函数
function SetTimeout(const ADuration: TDuration; const ACallback: TTimeoutCallback): ITimeout; overload;
function SetTimeout(const ADuration: TDuration; const ACallback: TTimeoutCallbackProc): ITimeout; overload;
function SetTimeout(const AMilliseconds: Integer; const ACallback: TTimeoutCallback): ITimeout; overload;
function SetTimeout(const AMilliseconds: Integer; const ACallback: TTimeoutCallbackProc): ITimeout; overload;

procedure ClearTimeout(const ATimeout: ITimeout);
procedure ClearAllTimeouts;

// 等待函数（带超时）
function WaitWithTimeout(const ADuration: TDuration; const ACondition: TFunc<Boolean>): Boolean; overload;
function WaitWithTimeout(const ADuration: TDuration; const ACondition: TFunc<Boolean>; const AToken: ICancellationToken): Boolean; overload;
function WaitWithTimeout(const ADeadline: TDeadline; const ACondition: TFunc<Boolean>): Boolean; overload;

// 超时装饰器
function WithTimeout<T>(const ADuration: TDuration; const AFunc: TFunc<T>): T; overload;
function WithTimeout<T>(const ADuration: TDuration; const AFunc: TFunc<T>; const AToken: ICancellationToken): T; overload;
function TryWithTimeout<T>(const ADuration: TDuration; const AFunc: TFunc<T>; out AResult: T): Boolean; overload;
function TryWithTimeout<T>(const ADuration: TDuration; const AFunc: TFunc<T>; out AResult: T; const AToken: ICancellationToken): Boolean; overload;

implementation

const
  NEVER_INSTANT = High(UInt64);

{ TDeadline }

class function TDeadline.Never: TDeadline;
begin
  Result.FInstant := TInstant.FromNsSinceEpoch(NEVER_INSTANT);
end;

class function TDeadline.Now: TDeadline;
begin
  Result.FInstant := fafafa.core.time.clock.NowInstant;
end;

class function TDeadline.After(const D: TDuration): TDeadline;
begin
  Result.FInstant := fafafa.core.time.clock.NowInstant.Add(D);
end;

class function TDeadline.At(const T: TInstant): TDeadline;
begin
  Result.FInstant := T;
end;

class function TDeadline.FromNow(const D: TDuration): TDeadline;
begin
  Result := After(D);
end;

function TDeadline.GetInstant: TInstant;
begin
  Result := FInstant;
end;

function TDeadline.Remaining: TDuration;
begin
  Result := Remaining(fafafa.core.time.clock.NowInstant);
end;

function TDeadline.Remaining(const ANow: TInstant): TDuration;
begin
  if IsNever then
    Result := TDuration.FromNs(High(Int64))
  else
    Result := FInstant.Diff(ANow);
end;

function TDeadline.HasExpired: Boolean;
begin
  Result := HasExpired(fafafa.core.time.clock.NowInstant);
end;

function TDeadline.HasExpired(const ANow: TInstant): Boolean;
begin
  if IsNever then
    Result := False
  else
    Result := ANow.GreaterOrEqual(FInstant);
end;

function TDeadline.Expired: Boolean;
begin
  Result := HasExpired;
end;

function TDeadline.IsNever: Boolean;
begin
  Result := FInstant.AsNsSinceEpoch = NEVER_INSTANT;
end;

function TDeadline.TimeUntil(const ANow: TInstant): TDuration;
begin
  Result := Remaining(ANow);
end;

function TDeadline.Overdue(const ANow: TInstant): TDuration;
var
  remaining: TDuration;
begin
  remaining := Remaining(ANow);
  if remaining.IsNegative then
    Result := remaining.Neg
  else
    Result := TDuration.Zero;
end;

function TDeadline.IsExpired(const ANow: TInstant): Boolean;
begin
  Result := HasExpired(ANow);
end;

function TDeadline.Extend(const D: TDuration): TDeadline;
begin
  if IsNever then
    Result := Self
  else
    Result.FInstant := FInstant.Add(D);
end;

function TDeadline.ExtendTo(const T: TInstant): TDeadline;
begin
  Result.FInstant := T;
end;

function TDeadline.Compare(const AOther: TDeadline): Integer;
begin
  if IsNever and AOther.IsNever then
    Result := 0
  else if IsNever then
    Result := 1
  else if AOther.IsNever then
    Result := -1
  else
    Result := FInstant.Compare(AOther.FInstant);
end;

function TDeadline.Equal(const AOther: TDeadline): Boolean;
begin
  Result := Compare(AOther) = 0;
end;

function TDeadline.LessThan(const AOther: TDeadline): Boolean;
begin
  Result := Compare(AOther) < 0;
end;

function TDeadline.GreaterThan(const AOther: TDeadline): Boolean;
begin
  Result := Compare(AOther) > 0;
end;

// 运算符重载

class operator TDeadline.=(const A, B: TDeadline): Boolean;
begin
  Result := A.Equal(B);
end;

class operator TDeadline.<(const A, B: TDeadline): Boolean;
begin
  Result := A.LessThan(B);
end;

class operator TDeadline.>(const A, B: TDeadline): Boolean;
begin
  Result := A.GreaterThan(B);
end;

function TDeadline.ToString: string;
begin
  if IsNever then
    Result := 'Never'
  else if HasExpired then
    Result := Format('Expired (%s ago)', [Overdue(fafafa.core.time.clock.NowInstant).ToString])
  else
    Result := Format('In %s', [Remaining.ToString]);
end;

{ TTimeoutOptions }

class function TTimeoutOptions.Default: TTimeoutOptions;
begin
  Result.Strategy := tsFixed;
  Result.AutoStart := True;
  Result.AutoRemove := True;
  Result.Name := '';
end;

class function TTimeoutOptions.AutoStart: TTimeoutOptions;
begin
  Result := Default;
  Result.AutoStart := True;
end;

class function TTimeoutOptions.Manual: TTimeoutOptions;
begin
  Result := Default;
  Result.AutoStart := False;
end;

// 工厂函数实现

function CreateTimeout(const ADuration: TDuration; const AName: string): ITimeout;
begin
  Result := DefaultTimeoutManager.CreateTimeout(ADuration, AName);
end;

function CreateTimeout(const ADeadline: TDeadline; const AName: string): ITimeout;
begin
  Result := DefaultTimeoutManager.CreateTimeout(ADeadline, AName);
end;

function SetTimeout(const ADuration: TDuration; const ACallback: TTimeoutCallback): ITimeout;
begin
  Result := DefaultTimeoutManager.CreateTimeout(ADuration, ACallback);
end;

function SetTimeout(const AMilliseconds: Integer; const ACallback: TTimeoutCallback): ITimeout;
begin
  Result := SetTimeout(TDuration.FromMs(AMilliseconds), ACallback);
end;

procedure ClearTimeout(const ATimeout: ITimeout);
begin
  if ATimeout <> nil then
    DefaultTimeoutManager.RemoveTimeout(ATimeout);
end;

procedure ClearAllTimeouts;
begin
  DefaultTimeoutManager.CancelAll;
end;

// 实现细节将在后续添加...

end.
