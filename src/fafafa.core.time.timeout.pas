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

{$modeswitch advancedrecords}

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  Classes,
  fafafa.core.time.base,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.time.clock,
  fafafa.core.thread.cancel;

type
  {$IFDEF FAFAFA_TIMEOUT_EXPERIMENTAL}
  // === 实验性功能：超时管理器 ===
  // 以下接口尚未实现，请勿在生产环境使用。
  // 要启用这些接口，请在项目中定义 FAFAFA_TIMEOUT_EXPERIMENTAL 宏。
  
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
  
  // 简单数组别名，避免外部依赖泛型，供管理器返回列表使用
  TTimeoutArray = array of ITimeout;
  {$ENDIF FAFAFA_TIMEOUT_EXPERIMENTAL}

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
    class function FromInstant(const T: TInstant): TDeadline; static; inline;
    class function FromNow(const D: TDuration): TDeadline; static; inline;
    
    // 查询操作
    function GetInstant: TInstant; inline;
    function Remaining: TDuration; overload; inline;
    function Remaining(const ANow: TInstant): TDuration; overload; inline;
    function RemainingClampedZero(const ANow: TInstant): TDuration; inline;
    function HasExpired: Boolean; overload; inline;
    function HasExpired(const ANow: TInstant): Boolean; overload; inline;
    function IsNever: Boolean; inline;
    
    // 时间计算
    function Overdue(const ANow: TInstant): TDuration; inline; // max(-Remaining, 0)
    
    // 操作
    function Extend(const D: TDuration): TDeadline; inline;
    function ExtendTo(const T: TInstant): TDeadline; inline;
    
    // 比较
    function Compare(const AOther: TDeadline): Integer; inline;
    function Equal(const AOther: TDeadline): Boolean; inline; deprecated 'Use operator = instead';
    function LessThan(const AOther: TDeadline): Boolean; inline; deprecated 'Use operator < instead';
    function GreaterThan(const AOther: TDeadline): Boolean; inline; deprecated 'Use operator > instead';
    
    // 运算符
    class operator =(const A, B: TDeadline): Boolean;
    class operator <(const A, B: TDeadline): Boolean;
    class operator >(const A, B: TDeadline): Boolean;
    
    // 字符串表示
    function ToString: string;
  end;

  {$IFDEF FAFAFA_TIMEOUT_EXPERIMENTAL}
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
  {$ENDIF FAFAFA_TIMEOUT_EXPERIMENTAL}

  {$IFDEF FAFAFA_TIMEOUT_EXPERIMENTAL}
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
    function GetTimeouts: TTimeoutArray; overload;
    function GetTimeouts(AState: TTimeoutState): TTimeoutArray; overload;
    
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
  {$ENDIF FAFAFA_TIMEOUT_EXPERIMENTAL}

  {$IFDEF FAFAFA_TIMEOUT_EXPERIMENTAL}
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
    class function AutoStartOptions: TTimeoutOptions; static;
    class function ManualOptions: TTimeoutOptions; static;
  end;
  {$ENDIF FAFAFA_TIMEOUT_EXPERIMENTAL}

{$IFDEF FAFAFA_TIMEOUT_EXPERIMENTAL}
// === 实验性工厂函数（未实现） ===
// 工厂函数（声明保留，具体实现另行提供）
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
// 使用非泛型回调以提升兼容性（FPC/OBJFPC 模式下避免 specialize 语法）
 type
   TBoolFunc = reference to function: Boolean;

function WaitWithTimeout(const ADuration: TDuration; const ACondition: TBoolFunc): Boolean; overload;
function WaitWithTimeout(const ADuration: TDuration; const ACondition: TBoolFunc; const AToken: ICancellationToken): Boolean; overload;
function WaitWithTimeout(const ADeadline: TDeadline; const ACondition: TBoolFunc): Boolean; overload;
{$ENDIF FAFAFA_TIMEOUT_EXPERIMENTAL}

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

class function TDeadline.FromInstant(const T: TInstant): TDeadline;
begin
  Result := At(T);
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

function TDeadline.RemainingClampedZero(const ANow: TInstant): TDuration;
var
  r: TDuration;
begin
  r := Remaining(ANow);
  if r.IsNegative then
    Result := TDuration.Zero
  else
    Result := r;
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
    Result := ANow >= FInstant;
end;

function TDeadline.IsNever: Boolean;
begin
  Result := FInstant.AsNsSinceEpoch = NEVER_INSTANT;
end;

function TDeadline.Overdue(const ANow: TInstant): TDuration;
var
  remDur: TDuration;
begin
  remDur := Self.Remaining(ANow);
  if remDur.IsNegative then
    Result := -remDur
  else
    Result := TDuration.Zero;
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
  // 直接使用 Compare，避免依赖已弃用的 Equal 方法
  Result := A.Compare(B) = 0;
end;

class operator TDeadline.<(const A, B: TDeadline): Boolean;
begin
  // 使用 Compare 结果进行判定，避免依赖已弃用的 LessThan 方法
  Result := A.Compare(B) < 0;
end;

class operator TDeadline.>(const A, B: TDeadline): Boolean;
begin
  Result := A.Compare(B) > 0;
end;

function TDeadline.ToString: string;
begin
  if IsNever then
    Result := 'Never'
  else if HasExpired then
    Result := Format('Expired (%d ms ago)', [Overdue(fafafa.core.time.clock.NowInstant).AsMs])
  else
    Result := Format('In %d ms', [Remaining.AsMs]);
end;

{$IFDEF FAFAFA_TIMEOUT_EXPERIMENTAL}
{ TTimeoutOptions }

class function TTimeoutOptions.Default: TTimeoutOptions;
begin
  Result.Strategy := tsFixed;
  Result.AutoStart := True;
  Result.AutoRemove := True;
  Result.Name := '';
end;

class function TTimeoutOptions.AutoStartOptions: TTimeoutOptions;
begin
  Result := Default;
  Result.AutoStart := True;
end;

class function TTimeoutOptions.ManualOptions: TTimeoutOptions;
begin
  Result := Default;
  Result.AutoStart := False;
end;

// === 未实现的工厂函数 ===
// 以下函数仅为占位符，实际调用会抛出异常。

function CreateTimeout(const ADuration: TDuration; const AName: string): ITimeout;
begin
  raise ETimeError.Create('CreateTimeout not implemented - enable FAFAFA_TIMEOUT_EXPERIMENTAL');
end;

function CreateTimeout(const ADeadline: TDeadline; const AName: string): ITimeout;
begin
  raise ETimeError.Create('CreateTimeout not implemented - enable FAFAFA_TIMEOUT_EXPERIMENTAL');
end;

function SetTimeout(const ADuration: TDuration; const ACallback: TTimeoutCallback): ITimeout;
begin
  raise ETimeError.Create('SetTimeout not implemented - enable FAFAFA_TIMEOUT_EXPERIMENTAL');
end;

function SetTimeout(const AMilliseconds: Integer; const ACallback: TTimeoutCallback): ITimeout;
begin
  raise ETimeError.Create('SetTimeout not implemented - enable FAFAFA_TIMEOUT_EXPERIMENTAL');
end;

procedure ClearTimeout(const ATimeout: ITimeout);
begin
  if ATimeout <> nil then
    raise ETimeError.Create('ClearTimeout not implemented - enable FAFAFA_TIMEOUT_EXPERIMENTAL');
end;

procedure ClearAllTimeouts;
begin
  // 无操作
  raise ETimeError.Create('ClearAllTimeouts not implemented - enable FAFAFA_TIMEOUT_EXPERIMENTAL');
end;

function CreateTimeout(const ADuration: TDuration; const AOptions: TTimeoutOptions): ITimeout;
begin
  raise ETimeError.Create('CreateTimeout not implemented - enable FAFAFA_TIMEOUT_EXPERIMENTAL');
end;

function CreateTimeout(const ADuration: TDuration; const ACallback: TTimeoutCallback; const AName: string): ITimeout;
begin
  raise ETimeError.Create('CreateTimeout not implemented - enable FAFAFA_TIMEOUT_EXPERIMENTAL');
end;

function CreateTimeout(const ADuration: TDuration; const ACallback: TTimeoutCallbackProc; const AName: string): ITimeout;
begin
  raise ETimeError.Create('CreateTimeout not implemented - enable FAFAFA_TIMEOUT_EXPERIMENTAL');
end;

function CreateTimeoutManager: ITimeoutManager;
begin
  raise ETimeError.Create('CreateTimeoutManager not implemented - enable FAFAFA_TIMEOUT_EXPERIMENTAL');
end;

function CreateTimeoutManager(const AClock: IMonotonicClock): ITimeoutManager;
begin
  raise ETimeError.Create('CreateTimeoutManager not implemented - enable FAFAFA_TIMEOUT_EXPERIMENTAL');
end;

function DefaultTimeoutManager: ITimeoutManager;
begin
  raise ETimeError.Create('DefaultTimeoutManager not implemented - enable FAFAFA_TIMEOUT_EXPERIMENTAL');
end;

function SetTimeout(const ADuration: TDuration; const ACallback: TTimeoutCallbackProc): ITimeout;
begin
  raise ETimeError.Create('SetTimeout not implemented - enable FAFAFA_TIMEOUT_EXPERIMENTAL');
end;

function SetTimeout(const AMilliseconds: Integer; const ACallback: TTimeoutCallbackProc): ITimeout;
begin
  raise ETimeError.Create('SetTimeout not implemented - enable FAFAFA_TIMEOUT_EXPERIMENTAL');
end;

function WaitWithTimeout(const ADuration: TDuration; const ACondition: TBoolFunc): Boolean;
var
  dl: TDeadline;
begin
  dl := TDeadline.After(ADuration);
  Result := WaitWithTimeout(dl, ACondition);
end;

function WaitWithTimeout(const ADuration: TDuration; const ACondition: TBoolFunc; const AToken: ICancellationToken): Boolean;
var
  deadline: TDeadline;
  slice: TDuration;
begin
  deadline := TDeadline.After(ADuration);
  slice := TDuration.FromMs(1);
  Result := False;
  while not deadline.HasExpired(fafafa.core.time.clock.NowInstant) do
  begin
    if Assigned(ACondition) and ACondition() then Exit(True);
    if (AToken <> nil) and AToken.IsCancellationRequested then Exit(False);
    fafafa.core.time.clock.DefaultMonotonicClock.WaitFor(slice, AToken);
  end;
end;

function WaitWithTimeout(const ADeadline: TDeadline; const ACondition: TBoolFunc): Boolean;
var
  slice: TDuration;
begin
  slice := TDuration.FromMs(1);
  Result := False;
  while not ADeadline.HasExpired(fafafa.core.time.clock.NowInstant) do
  begin
    if Assigned(ACondition) and ACondition() then Exit(True);
    fafafa.core.time.clock.DefaultMonotonicClock.WaitFor(slice, nil);
  end;
end;
{$ENDIF FAFAFA_TIMEOUT_EXPERIMENTAL}

end.
