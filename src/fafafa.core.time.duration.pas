unit fafafa.core.time.duration;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, DateUtils, fafafa.core.thread.cancel, fafafa.core.time.consts,
  fafafa.core.sync.event, fafafa.core.sync.event.base;


type
  TProc = procedure;
  // 持续时间（只能为正值，符合 Rust Duration 语义）
  TDuration = record
  private
    FNs: UInt64; // 纳秒，只能为正值
  public
    class function FromNs(const A: UInt64): TDuration; static;
    class function FromUs(const A: UInt64): TDuration; static;
    class function FromMs(const A: UInt64): TDuration; static;
    class function FromSec(const A: UInt64): TDuration; static;

    // 浮点数支持（对齐 Rust）
    class function FromSecsF64(const Secs: Double): TDuration; static;
    class function FromSecsF32(const Secs: Single): TDuration; static;

    // 安全构造（对齐 Rust checked_* 方法）
    class function TryFromNs(const A: UInt64; out D: TDuration): Boolean; static;
    class function TryFromUs(const A: UInt64; out D: TDuration): Boolean; static;
    class function TryFromMs(const A: UInt64; out D: TDuration): Boolean; static;
    class function TryFromSec(const A: UInt64; out D: TDuration): Boolean; static;
    class function TryFromSecsF64(const Secs: Double; out D: TDuration): Boolean; static;
    class function TryFromSecsF32(const Secs: Single; out D: TDuration): Boolean; static;

    function AsNs: UInt64; inline;
    function AsUs: UInt64; inline;
    function AsMs: UInt64; inline;
    function AsSec: UInt64; inline;
    function AsSecsF64: Double; inline;
    function AsSecsF32: Single; inline;

    function Add(const B: TDuration): TDuration; inline;
    function Mul(const K: UInt64): TDuration; inline;
    function DivBy(const K: UInt64): TDuration; inline;

    function Modulo(const B: TDuration): TDuration; inline;

    function IsZero: Boolean; inline;
    function ToString: string; inline;

    // 常量（对齐 Rust）
    class function Zero: TDuration; static; inline;
    class function Max: TDuration; static; inline;
    class function Second: TDuration; static; inline;
    class function Millisecond: TDuration; static; inline;
    class function Microsecond: TDuration; static; inline;
    class function Nanosecond: TDuration; static; inline;

    // Clamp 到 [Min, Max]
    function Clamp(const MinV, MaxV: TDuration): TDuration; inline;


    // 标量和取整/夹取工具
    function Between(const MinV, MaxV: TDuration): TDuration; inline;
    function RoundToUnit(const UnitNs: Int64): TDuration; inline;
    function TruncToUnit(const UnitNs: Int64): TDuration; inline;
    function FloorToUnit(const UnitNs: Int64): TDuration; inline;
    function CeilToUnit(const UnitNs: Int64): TDuration; inline;
    // 便捷：按常用单位
    function RoundToUs: TDuration; inline;
    function RoundToMs: TDuration; inline;
    function RoundToSec: TDuration; inline;
    function TruncToUs: TDuration; inline;
    function TruncToMs: TDuration; inline;
    function TruncToSec: TDuration; inline;
    function FloorToUs: TDuration; inline;
    function FloorToMs: TDuration; inline;
    function FloorToSec: TDuration; inline;
    function CeilToUs: TDuration; inline;
    function CeilToMs: TDuration; inline;
    function CeilToSec: TDuration; inline;


    // 运算符重载（算术）- 移除减法，Duration 不能为负
    class operator +(const A, B: TDuration): TDuration; inline;
    class operator *(const A: TDuration; const K: UInt64): TDuration; inline;
    class operator *(const K: UInt64; const A: TDuration): TDuration; inline;
    class operator div(const A: TDuration; const K: UInt64): TDuration; inline;

    // 比较与工具
    function Compare(const B: TDuration): Integer; inline; // -1/0/1
    function LessThan(const B: TDuration): Boolean; inline;
    function GreaterThan(const B: TDuration): Boolean; inline;
    class function Min(const A, B: TDuration): TDuration; static; inline;
    class function Max(const A, B: TDuration): TDuration; static; inline;

    // 安全算术（对齐 Rust checked_* 方法）
    function CheckedAdd(const B: TDuration; out R: TDuration): Boolean; inline;
    function CheckedMul(const K: UInt64; out R: TDuration): Boolean; inline;
    function CheckedDiv(const K: UInt64; out R: TDuration): Boolean; inline;
    function CheckedModulo(const B: TDuration; out R: TDuration): Boolean; inline;

    // 饱和算术（对齐 Rust saturating_* 方法）
    function SaturatingAdd(const B: TDuration): TDuration; inline;
    function SaturatingMul(const K: UInt64): TDuration; inline;
    function SaturatingDiv(const K: UInt64): TDuration; inline;

    // 运算符重载（比较）
    class operator =(const A, B: TDuration): Boolean;
    class operator <>(const A, B: TDuration): Boolean;
    class operator <(const A, B: TDuration): Boolean;
    class operator >(const A, B: TDuration): Boolean;
    class operator <=(const A, B: TDuration): Boolean;
    class operator >=(const A, B: TDuration): Boolean;
  end;

  // 时间点（单调时钟）- 完全不透明，对齐 Rust Instant
  TInstant = record
  private
    FNs: UInt64; // 纳秒，从某个固定起点开始
  public
    // 只允许内部构造，不暴露给外部
    class function Now: TInstant; static; inline;
    class function FromNs(const Ns: UInt64): TInstant; static; inline;
    class function FromSec(const Sec: UInt64): TInstant; static; inline;
    function AsNs: UInt64; inline;
    function AsSec: UInt64; inline;
    function Add(const D: TDuration): TInstant; inline;
    function Diff(const B: TInstant): TDuration; inline;

    // 核心方法（对齐 Rust Instant API）
    function DurationSince(const Earlier: TInstant): TDuration; inline;
    function CheckedDurationSince(const Earlier: TInstant; out D: TDuration): Boolean; inline;
    function SaturatingDurationSince(const Earlier: TInstant): TDuration; inline;
    function Elapsed: TDuration; inline;

    // 算术操作（对齐 Rust）
    function CheckedAdd(const D: TDuration; out R: TInstant): Boolean; inline;
    function CheckedSub(const D: TDuration; out R: TInstant): Boolean; inline;
    function SaturatingAdd(const D: TDuration): TInstant; inline;
    function SaturatingSub(const D: TDuration): TInstant; inline;

    // 比较方法
    function Compare(const B: TInstant): Integer; inline;
    class function Min(const A, B: TInstant): TInstant; static; inline;
    class function Max(const A, B: TInstant): TInstant; static; inline;

    // 运算符重载（对齐 Rust）
    class operator +(const A: TInstant; const D: TDuration): TInstant; inline;
    class operator -(const A: TInstant; const D: TDuration): TInstant; inline;
    class operator -(const A, B: TInstant): TDuration; inline;
    class operator =(const A, B: TInstant): Boolean;
    class operator <>(const A, B: TInstant): Boolean;
    class operator <(const A, B: TInstant): Boolean;
    class operator >(const A, B: TInstant): Boolean;
    class operator <=(const A, B: TInstant): Boolean;
    class operator >=(const A, B: TInstant): Boolean;
  end;

  // 系统时间（对齐 Rust SystemTime）
  TSystemTime = record
  private
    FUnixNanos: Int64; // 可以为负（表示 1970 年之前）
  public
    // 构造函数
    class function Now: TSystemTime; static; inline;
    class function UnixEpoch: TSystemTime; static; inline;
    class function FromUnixNanos(const Nanos: Int64): TSystemTime; static; inline;
    class function FromUnixSecs(const Secs: Int64): TSystemTime; static; inline;

    // 核心方法（对齐 Rust SystemTime API）
    function DurationSince(const Earlier: TSystemTime; out D: TDuration): Boolean; inline;
    function Elapsed(out D: TDuration): Boolean; inline;
    function CheckedAdd(const D: TDuration; out R: TSystemTime): Boolean; inline;
    function CheckedSub(const D: TDuration; out R: TSystemTime): Boolean; inline;

    // 转换方法
    function ToUnixNanos: Int64; inline;
    function ToUnixSecs: Int64; inline;
    function ToDateTime: TDateTime; inline;
    class function FromDateTime(const DT: TDateTime): TSystemTime; static; inline;

    // 比较
    function Compare(const Other: TSystemTime): Integer; inline;

    // 运算符重载
    class operator +(const A: TSystemTime; const D: TDuration): TSystemTime; inline;
    class operator -(const A: TSystemTime; const D: TDuration): TSystemTime; inline;
    class operator -(const A, B: TSystemTime): TDuration; inline;
    class operator =(const A, B: TSystemTime): Boolean;
    class operator <>(const A, B: TSystemTime): Boolean;
    class operator <(const A, B: TSystemTime): Boolean;
    class operator >(const A, B: TSystemTime): Boolean;
    class operator <=(const A, B: TSystemTime): Boolean;
    class operator >=(const A, B: TSystemTime): Boolean;
  end;

  // 截止时间
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

  // 时钟接口
  IMonotonicClock = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function Now: TInstant;
    procedure Sleep(const D: TDuration);
  end;

  ISystemClock = interface
    ['{B2C3D4E5-F6A7-8901-BCDE-F12345678901}']
    function Now: TDateTime;
    function NowUTC: TDateTime;
    function ToInstant(const DT: TDateTime): TInstant;
    function FromInstant(const I: TInstant): TDateTime;
  end;

  // 计时器接口
  ITimer = interface
    ['{C3D4E5F6-A7B8-9012-CDEF-123456789012}']
    function GetInterval: TDuration;
    procedure SetInterval(const AInterval: TDuration);
    function GetEnabled: Boolean;
    procedure SetEnabled(const AEnabled: Boolean);
    function GetOnTimer: TNotifyEvent;
    procedure SetOnTimer(const AOnTimer: TNotifyEvent);
    
    procedure Start;
    procedure Stop;
    procedure Reset;
    
    property Interval: TDuration read GetInterval write SetInterval;
    property Enabled: Boolean read GetEnabled write SetEnabled;
    property OnTimer: TNotifyEvent read GetOnTimer write SetOnTimer;
  end;

  // 秒表
  TStopwatch = record
  private
    FStartTime: TInstant;
    FElapsed: TDuration;
    FIsRunning: Boolean;
    FClock: IMonotonicClock;
  public
    class function Create: TStopwatch; static;
    class function Create(const AClock: IMonotonicClock): TStopwatch; static;
    class function StartNew: TStopwatch; static;
    class function StartNew(const AClock: IMonotonicClock): TStopwatch; static;
    
    procedure Start;
    procedure Stop;
    procedure Reset;
    procedure Restart;
    
    function GetElapsed: TDuration;
    function GetElapsedMs: UInt64;
    function GetElapsedUs: UInt64;
    function GetElapsedNs: UInt64;
    function IsRunning: Boolean;
    
    property Elapsed: TDuration read GetElapsed;
    property ElapsedMs: UInt64 read GetElapsedMs;
    property ElapsedUs: UInt64 read GetElapsedUs;
    property ElapsedNs: UInt64 read GetElapsedNs;
  end;


const
  // 对齐 Rust 的重要常量
  UNIX_EPOCH: TSystemTime = (FUnixNanos: 0);

// 便捷函数
function DefaultMonotonicClock: IMonotonicClock;
function DefaultSystemClock: ISystemClock;
function CreateManualMonotonicClock(const StartAt: TInstant): IMonotonicClock;

// 时间解析
function TryParseDuration(const S: string; out D: TDuration): Boolean;
function ParseDuration(const S: string): TDuration;

// 超时工具
function TimeoutFor(const D: TDuration; P: TProc): Boolean;
function TimeoutFor(const D: TDuration; P: TProc; const Token: ICancellationToken): Boolean;

// 便捷时间创建
function Nanoseconds(const N: Int64): TDuration; inline;
function Microseconds(const N: Int64): TDuration; inline;
function Milliseconds(const N: Int64): TDuration; inline;
function Seconds(const N: Int64): TDuration; inline;
function Minutes(const N: Int64): TDuration; inline;
function Hours(const N: Int64): TDuration; inline;

// 时间测量
function MeasureTime(P: TProc): TDuration;
function MeasureTime(P: TProc; const Clock: IMonotonicClock): TDuration;

// 睡眠函数
procedure SleepFor(const D: TDuration);
procedure SleepUntil(const T: TInstant);

implementation

uses
  {$IFDEF MSWINDOWS}
  Windows
  {$ELSE}
  BaseUnix
    {$IFDEF LINUX}
    , Linux
    {$ENDIF}
    {$IFDEF DARWIN}
    , UnixType
    {$ENDIF}
  {$ENDIF}
  ;

type
  // 固定时钟实现
  TFixedMonotonicClock = class(TInterfacedObject, IMonotonicClock)
  private
    FFixedTime: TInstant;
  public
    constructor Create(const AFixedTime: TInstant);
    function Now: TInstant;
    procedure Sleep(const D: TDuration);
  end;

  // 系统时钟实现
  TSystemClockImpl = class(TInterfacedObject, ISystemClock)
  public
    function Now: TDateTime;
    function NowUTC: TDateTime;
    function ToInstant(const DT: TDateTime): TInstant;
    function FromInstant(const I: TInstant): TDateTime;
  end;

  // 单调时钟实现
  TMonotonicClockImpl = class(TInterfacedObject, IMonotonicClock)
  private
    {$IFDEF MSWINDOWS}
    FFrequency: Int64;
    FStartCounter: Int64;
    {$ELSE}
    FStartTime: timespec;
    {$ENDIF}
  public
    constructor Create;
    function Now: TInstant;
    procedure Sleep(const D: TDuration);
  end;

var
  GMonotonicClock: IMonotonicClock = nil;
  GSystemClock: ISystemClock = nil;

function CreateManualMonotonicClock(const StartAt: TInstant): IMonotonicClock;
begin
  Result := TFixedMonotonicClock.Create(StartAt);
end;

function TryParseDuration(const S: string; out D: TDuration): Boolean;
var
  i, n: Integer;
  numPart, unitPart: string;
  sign: Integer;
  accum: Int64;
  curNum: Int64;
  hadAny: Boolean;
begin
  D := TDuration.Zero;
  if S = '' then Exit(False);
  i := 1; n := Length(S); sign := 1; accum := 0; hadAny := False;
  if (S[i] = '+') or (S[i] = '-') then
  begin
    if S[i] = '-' then sign := -1;
    Inc(i);
    if i > n then Exit(False);
  end;
  while i <= n do
  begin
    // 读取数字
    numPart := '';
    while (i <= n) and (S[i] in ['0'..'9']) do
    begin
      numPart += S[i]; Inc(i);
    end;
    if numPart = '' then Exit(False);
    if not TryStrToInt64(numPart, curNum) then Exit(False);
    // 读取单位（可为空：默认 ns）
    unitPart := '';
    while (i <= n) and (S[i] in ['a'..'z','A'..'Z']) do
    begin
      unitPart += LowerCase(S[i]); Inc(i);
    end;
    if (unitPart = '') then
      accum := accum + curNum // 视为 ns
    else if (unitPart = 'ns') then
      accum := accum + curNum
    else if (unitPart = 'us') or (unitPart = 'µs') then
      accum := accum + curNum * 1000
    else if (unitPart = 'ms') then
      accum := accum + curNum * 1000 * 1000
    else if (unitPart = 's') then
      accum := accum + curNum * 1000 * 1000 * 1000
    else if (unitPart = 'm') then
      accum := accum + curNum * 60 * 1000 * 1000 * 1000
    else if (unitPart = 'h') then
      accum := accum + curNum * 3600 * 1000 * 1000 * 1000
    else
      Exit(False);
    hadAny := True;
  end;
  if not hadAny then Exit(False);
  if sign = -1 then accum := -accum;
  D := TDuration.FromNs(accum);
  Result := True;
end;

function ParseDuration(const S: string): TDuration;
begin
  if not TryParseDuration(S, Result) then
    raise Exception.CreateFmt('Invalid duration: %s', [S]);
end;

function TimeoutFor(const D: TDuration; P: TProc): Boolean;
var
  done: IEvent;
  th: TThread;
  deadline, now: QWord;
begin
  if not Assigned(P) then Exit(True);
  done := TEvent.Create(True, False);
  th := TThread.CreateAnonymousThread(
    procedure
    begin
      try P(); finally done.SetEvent; end;
    end
  );
  th.FreeOnTerminate := True;
  th.Start;

  deadline := GetTickCount64 + D.AsMs;
  repeat
    if done.TryWait then Exit(True);
    now := GetTickCount64;
    if now >= deadline then Exit(False);
    Sleep(1);
  until False;
end;

function TimeoutFor(const D: TDuration; P: TProc; const Token: ICancellationToken): Boolean;
var
  done: IEvent;
  th: TThread;
  deadline, now: QWord;
begin
  if not Assigned(P) then Exit(True);
  done := TEvent.Create(True, False);
  th := TThread.CreateAnonymousThread(
    procedure
    begin
      try P(); finally done.SetEvent; end;
    end
  );
  th.FreeOnTerminate := True;
  th.Start;

  deadline := GetTickCount64 + D.AsMs;
  repeat
    if done.TryWait then Exit(True);
    if Assigned(Token) and Token.IsCancellationRequested then Exit(False);
    now := GetTickCount64;
    if now >= deadline then Exit(False);
    Sleep(1);
  until False;
end;

// 便捷时间创建函数
function Nanoseconds(const N: Int64): TDuration;
begin
  Result := TDuration.FromNs(N);
end;

function Microseconds(const N: Int64): TDuration;
begin
  Result := TDuration.FromUs(N);
end;

function Milliseconds(const N: Int64): TDuration;
begin
  Result := TDuration.FromMs(N);
end;

function Seconds(const N: Int64): TDuration;
begin
  Result := TDuration.FromSec(N);
end;

function Minutes(const N: Int64): TDuration;
begin
  Result := TDuration.FromSec(N * 60);
end;

function Hours(const N: Int64): TDuration;
begin
  Result := TDuration.FromSec(N * 3600);
end;

// 时间测量函数
function MeasureTime(P: TProc): TDuration;
var
  sw: TStopwatch;
begin
  sw := TStopwatch.StartNew;
  try
    P();
  finally
    sw.Stop;
  end;
  Result := sw.Elapsed;
end;

function MeasureTime(P: TProc; const Clock: IMonotonicClock): TDuration;
var
  sw: TStopwatch;
begin
  sw := TStopwatch.StartNew(Clock);
  try
    P();
  finally
    sw.Stop;
  end;
  Result := sw.Elapsed;
end;

// 睡眠函数
procedure SleepFor(const D: TDuration);
begin
  DefaultMonotonicClock.Sleep(D);
end;

procedure SleepUntil(const T: TInstant);
var
  now: TInstant;
  remaining: TDuration;
begin
  now := DefaultMonotonicClock.Now;
  if now.FNs < T.FNs then
  begin
    remaining := T.DurationSince(now);
    SleepFor(remaining);
  end;
end;

{ TDuration }

class function TDuration.FromNs(const A: UInt64): TDuration;
begin
  Result.FNs := A;
end;

class function TDuration.FromUs(const A: UInt64): TDuration;
begin
  Result.FNs := A * 1000;
end;

class function TDuration.FromMs(const A: UInt64): TDuration;
begin
  Result.FNs := A * 1000000;
end;

class function TDuration.FromSec(const A: UInt64): TDuration;
begin
  Result.FNs := A * 1000000000;
end;

class function TDuration.FromSecsF64(const Secs: Double): TDuration;
begin
  Result.FNs := UInt64(Trunc(Secs * 1000000000));
end;

class function TDuration.FromSecsF32(const Secs: Single): TDuration;
begin
  Result.FNs := UInt64(Trunc(Secs * 1000000000));
end;

class function TDuration.TryFromNs(const A: UInt64; out D: TDuration): Boolean;
begin
  D.FNs := A;
  Result := True;
end;

class function TDuration.TryFromUs(const A: UInt64; out D: TDuration): Boolean;
begin
  D.FNs := A * 1000;
  Result := True;
end;

class function TDuration.TryFromMs(const A: UInt64; out D: TDuration): Boolean;
begin
  D.FNs := A * 1000000;
  Result := True;
end;

class function TDuration.TryFromSec(const A: UInt64; out D: TDuration): Boolean;
begin
  D.FNs := A * 1000000000;
  Result := True;
end;

class function TDuration.TryFromSecsF64(const Secs: Double; out D: TDuration): Boolean;
begin
  if (Secs < 0) or (Secs > High(UInt64) / 1000000000) then
    Exit(False);
  D.FNs := UInt64(Trunc(Secs * 1000000000));
  Result := True;
end;

class function TDuration.TryFromSecsF32(const Secs: Single; out D: TDuration): Boolean;
begin
  if (Secs < 0) or (Secs > High(UInt64) / 1000000000) then
    Exit(False);
  D.FNs := UInt64(Trunc(Secs * 1000000000));
  Result := True;
end;

function TDuration.AsNs: UInt64;
begin
  Result := FNs;
end;

function TDuration.AsUs: UInt64;
begin
  Result := FNs div 1000;
end;

function TDuration.AsMs: UInt64;
begin
  Result := FNs div 1000000;
end;

function TDuration.AsSec: UInt64;
begin
  Result := FNs div 1000000000;
end;

function TDuration.AsSecsF64: Double;
begin
  Result := FNs / 1000000000.0;
end;

function TDuration.AsSecsF32: Single;
begin
  Result := FNs / 1000000000.0;
end;

function TDuration.ToString: string;
var
  v: UInt64;
begin
  v := FNs;
  if v >= 1000000000 then
    Result := FormatFloat('0.###s', v / 1000000000.0)
  else if v >= 1000000 then
    Result := FormatFloat('0.###ms', v / 1000000.0)
  else if v >= 1000 then
    Result := FormatFloat('0.###us', v / 1000.0)
  else
    Result := IntToStr(v) + 'ns';
end;

function TDuration.Add(const B: TDuration): TDuration;
begin
  Result.FNs := FNs + B.FNs;
end;

function TDuration.Mul(const K: UInt64): TDuration;
begin
  Result.FNs := FNs * K;
end;

function TDuration.DivBy(const K: UInt64): TDuration;
begin
  Result.FNs := FNs div K;
end;

function TDuration.Modulo(const B: TDuration): TDuration;
begin
  Result.FNs := FNs mod B.FNs;
end;

function TDuration.IsZero: Boolean;
begin
  Result := FNs = 0;
end;

class function TDuration.Zero: TDuration;
begin
  Result.FNs := 0;
end;

class function TDuration.Max: TDuration;
begin
  Result.FNs := High(UInt64);
end;

class function TDuration.Second: TDuration;
begin
  Result.FNs := 1000000000;
end;

class function TDuration.Millisecond: TDuration;
begin
  Result.FNs := 1000000;
end;

class function TDuration.Microsecond: TDuration;
begin
  Result.FNs := 1000;
end;

class function TDuration.Nanosecond: TDuration;
begin
  Result.FNs := 1;
end;

function TDuration.Clamp(const MinV, MaxV: TDuration): TDuration;
begin
  if FNs < MinV.FNs then
    Result.FNs := MinV.FNs
  else if FNs > MaxV.FNs then
    Result.FNs := MaxV.FNs
  else
    Result.FNs := FNs;
end;

function TDuration.Between(const MinV, MaxV: TDuration): TDuration;
begin
  Result := Clamp(MinV, MaxV);
end;

function TDuration.RoundToUnit(const UnitNs: Int64): TDuration;
var
  u, half, q: UInt64;
begin
  if UnitNs <= 1 then Exit(Self);
  u := UInt64(UnitNs);
  if u = 0 then Exit(Self);
  half := u div 2;
  q := (FNs + half) div u;
  Result.FNs := q * u;
end;

function TDuration.TruncToUnit(const UnitNs: Int64): TDuration;
var
  u, q: UInt64;
begin
  if UnitNs <= 1 then Exit(Self);
  u := UInt64(UnitNs);
  if u = 0 then Exit(Self);
  q := FNs div u;
  Result.FNs := q * u;
end;

function TDuration.FloorToUnit(const UnitNs: Int64): TDuration;
var
  u, q: UInt64;
begin
  if UnitNs <= 1 then Exit(Self);
  u := UInt64(UnitNs);
  if u = 0 then Exit(Self);
  q := FNs div u;
  Result.FNs := q * u;
end;

function TDuration.CeilToUnit(const UnitNs: Int64): TDuration;
var
  u, q: UInt64;
begin
  if UnitNs <= 1 then Exit(Self);
  u := UInt64(UnitNs);
  if u = 0 then Exit(Self);
  q := FNs div u;
  if (FNs mod u) <> 0 then Inc(q);
  Result.FNs := q * u;
end;

// 便捷单位转换方法
function TDuration.RoundToUs: TDuration;
begin
  Result := RoundToUnit(1000);
end;

function TDuration.RoundToMs: TDuration;
begin
  Result := RoundToUnit(1000000);
end;

function TDuration.RoundToSec: TDuration;
begin
  Result := RoundToUnit(1000000000);
end;

function TDuration.TruncToUs: TDuration;
begin
  Result := TruncToUnit(1000);
end;

function TDuration.TruncToMs: TDuration;
begin
  Result := TruncToUnit(1000000);
end;

function TDuration.TruncToSec: TDuration;
begin
  Result := TruncToUnit(1000000000);
end;

function TDuration.FloorToUs: TDuration;
begin
  Result := FloorToUnit(1000);
end;

function TDuration.FloorToMs: TDuration;
begin
  Result := FloorToUnit(1000000);
end;

function TDuration.FloorToSec: TDuration;
begin
  Result := FloorToUnit(1000000000);
end;

function TDuration.CeilToUs: TDuration;
begin
  Result := CeilToUnit(1000);
end;

function TDuration.CeilToMs: TDuration;
begin
  Result := CeilToUnit(1000000);
end;

function TDuration.CeilToSec: TDuration;
begin
  Result := CeilToUnit(1000000000);
end;

// 运算符重载（算术）
class operator TDuration.+(const A, B: TDuration): TDuration;
begin
  Result.FNs := A.FNs + B.FNs;
end;

class operator TDuration.*(const A: TDuration; const K: UInt64): TDuration;
begin
  Result.FNs := A.FNs * K;
end;

class operator TDuration.*(const K: UInt64; const A: TDuration): TDuration;
begin
  Result.FNs := K * A.FNs;
end;

class operator TDuration.div(const A: TDuration; const K: UInt64): TDuration;
begin
  Result.FNs := A.FNs div K;
end;

// 比较方法
function TDuration.Compare(const B: TDuration): Integer;
begin
  if FNs < B.FNs then
    Result := -1
  else if FNs > B.FNs then
    Result := 1
  else
    Result := 0;
end;

function TDuration.LessThan(const B: TDuration): Boolean;
begin
  Result := FNs < B.FNs;
end;

function TDuration.GreaterThan(const B: TDuration): Boolean;
begin
  Result := FNs > B.FNs;
end;

class function TDuration.Min(const A, B: TDuration): TDuration;
begin
  if A.FNs < B.FNs then
    Result := A
  else
    Result := B;
end;

class function TDuration.Max(const A, B: TDuration): TDuration;
begin
  if A.FNs > B.FNs then
    Result := A
  else
    Result := B;
end;

// 安全算术（对齐 Rust checked_* 方法）
function TDuration.CheckedAdd(const B: TDuration; out R: TDuration): Boolean;
begin
  if FNs > High(UInt64) - B.FNs then
    Exit(False);
  R.FNs := FNs + B.FNs;
  Result := True;
end;

function TDuration.CheckedMul(const K: UInt64; out R: TDuration): Boolean;
begin
  if (K > 0) and (FNs > High(UInt64) div K) then
    Exit(False);
  R.FNs := FNs * K;
  Result := True;
end;

function TDuration.CheckedDiv(const K: UInt64; out R: TDuration): Boolean;
begin
  if K = 0 then
    Exit(False);
  R.FNs := FNs div K;
  Result := True;
end;

function TDuration.CheckedModulo(const B: TDuration; out R: TDuration): Boolean;
begin
  if B.FNs = 0 then
    Exit(False);
  R.FNs := FNs mod B.FNs;
  Result := True;
end;

// 饱和算术（对齐 Rust saturating_* 方法）
function TDuration.SaturatingAdd(const B: TDuration): TDuration;
begin
  if FNs > High(UInt64) - B.FNs then
    Result.FNs := High(UInt64)
  else
    Result.FNs := FNs + B.FNs;
end;

function TDuration.SaturatingMul(const K: UInt64): TDuration;
begin
  if (K > 0) and (FNs > High(UInt64) div K) then
    Result.FNs := High(UInt64)
  else
    Result.FNs := FNs * K;
end;

function TDuration.SaturatingDiv(const K: UInt64): TDuration;
begin
  if K = 0 then
    Result.FNs := High(UInt64)
  else
    Result.FNs := FNs div K;
end;

// 运算符重载（比较）
class operator TDuration.=(const A, B: TDuration): Boolean;
begin
  Result := A.FNs = B.FNs;
end;

class operator TDuration.<>(const A, B: TDuration): Boolean;
begin
  Result := A.FNs <> B.FNs;
end;

class operator TDuration.<(const A, B: TDuration): Boolean;
begin
  Result := A.FNs < B.FNs;
end;

class operator TDuration.>(const A, B: TDuration): Boolean;
begin
  Result := A.FNs > B.FNs;
end;

class operator TDuration.<=(const A, B: TDuration): Boolean;
begin
  Result := A.FNs <= B.FNs;
end;

class operator TDuration.>=(const A, B: TDuration): Boolean;
begin
  Result := A.FNs >= B.FNs;
end;

{ TInstant }

class function TInstant.Now: TInstant;
begin
  Result := DefaultMonotonicClock.Now;
end;

class function TInstant.FromNs(const Ns: UInt64): TInstant;
begin
  Result.FNs := Ns;
end;

class function TInstant.FromSec(const Sec: UInt64): TInstant;
begin
  Result.FNs := Sec * 1000000000;
end;

function TInstant.AsNs: UInt64;
begin
  Result := FNs;
end;

function TInstant.AsSec: UInt64;
begin
  Result := FNs div 1000000000;
end;

function TInstant.Add(const D: TDuration): TInstant;
begin
  if FNs > High(UInt64) - D.FNs then
    Result.FNs := High(UInt64)
  else
    Result.FNs := FNs + D.FNs;
end;

function TInstant.Diff(const B: TInstant): TDuration;
begin
  Result := DurationSince(B);
end;

function TInstant.DurationSince(const Earlier: TInstant): TDuration;
begin
  if FNs >= Earlier.FNs then
    Result.FNs := FNs - Earlier.FNs
  else
    Result.FNs := 0; // 饱和到 0，对齐 Rust 行为
end;

function TInstant.CheckedDurationSince(const Earlier: TInstant; out D: TDuration): Boolean;
begin
  if FNs >= Earlier.FNs then
  begin
    D.FNs := FNs - Earlier.FNs;
    Result := True;
  end
  else
    Result := False;
end;

function TInstant.SaturatingDurationSince(const Earlier: TInstant): TDuration;
begin
  if FNs >= Earlier.FNs then
    Result.FNs := FNs - Earlier.FNs
  else
    Result.FNs := 0;
end;

function TInstant.Elapsed: TDuration;
begin
  Result := Now.DurationSince(Self);
end;

function TInstant.CheckedAdd(const D: TDuration; out R: TInstant): Boolean;
begin
  if FNs > High(UInt64) - D.FNs then
    Exit(False);
  R.FNs := FNs + D.FNs;
  Result := True;
end;

function TInstant.CheckedSub(const D: TDuration; out R: TInstant): Boolean;
begin
  if FNs < D.FNs then
    Exit(False);
  R.FNs := FNs - D.FNs;
  Result := True;
end;

function TInstant.SaturatingAdd(const D: TDuration): TInstant;
begin
  if FNs > High(UInt64) - D.FNs then
    Result.FNs := High(UInt64)
  else
    Result.FNs := FNs + D.FNs;
end;

function TInstant.SaturatingSub(const D: TDuration): TInstant;
begin
  if FNs < D.FNs then
    Result.FNs := 0
  else
    Result.FNs := FNs - D.FNs;
end;

function TInstant.Compare(const B: TInstant): Integer;
begin
  if FNs < B.FNs then
    Result := -1
  else if FNs > B.FNs then
    Result := 1
  else
    Result := 0;
end;

class function TInstant.Min(const A, B: TInstant): TInstant;
begin
  if A.FNs < B.FNs then
    Result := A
  else
    Result := B;
end;

class function TInstant.Max(const A, B: TInstant): TInstant;
begin
  if A.FNs > B.FNs then
    Result := A
  else
    Result := B;
end;

// 运算符重载
class operator TInstant.+(const A: TInstant; const D: TDuration): TInstant;
begin
  Result := A.SaturatingAdd(D);
end;

class operator TInstant.-(const A: TInstant; const D: TDuration): TInstant;
begin
  Result := A.SaturatingSub(D);
end;

class operator TInstant.-(const A, B: TInstant): TDuration;
begin
  Result := A.DurationSince(B);
end;

class operator TInstant.=(const A, B: TInstant): Boolean;
begin
  Result := A.FNs = B.FNs;
end;

class operator TInstant.<>(const A, B: TInstant): Boolean;
begin
  Result := A.FNs <> B.FNs;
end;

class operator TInstant.<(const A, B: TInstant): Boolean;
begin
  Result := A.FNs < B.FNs;
end;

class operator TInstant.>(const A, B: TInstant): Boolean;
begin
  Result := A.FNs > B.FNs;
end;

class operator TInstant.<=(const A, B: TInstant): Boolean;
begin
  Result := A.FNs <= B.FNs;
end;

class operator TInstant.>=(const A, B: TInstant): Boolean;
begin
  Result := A.FNs >= B.FNs;
end;

{ TSystemTime }

class function TSystemTime.Now: TSystemTime;
begin
  Result.FUnixNanos := DateTimeToUnix(SysUtils.Now) * 1000000000;
end;

class function TSystemTime.UnixEpoch: TSystemTime;
begin
  Result.FUnixNanos := 0;
end;

class function TSystemTime.FromUnixNanos(const Nanos: Int64): TSystemTime;
begin
  Result.FUnixNanos := Nanos;
end;

class function TSystemTime.FromUnixSecs(const Secs: Int64): TSystemTime;
begin
  Result.FUnixNanos := Secs * 1000000000;
end;

function TSystemTime.DurationSince(const Earlier: TSystemTime; out D: TDuration): Boolean;
var
  diff: Int64;
begin
  diff := FUnixNanos - Earlier.FUnixNanos;
  if diff < 0 then
    Exit(False);
  D.FNs := UInt64(diff);
  Result := True;
end;

function TSystemTime.Elapsed(out D: TDuration): Boolean;
begin
  Result := Now.DurationSince(Self, D);
end;

function TSystemTime.CheckedAdd(const D: TDuration; out R: TSystemTime): Boolean;
begin
  if FUnixNanos > High(Int64) - Int64(D.FNs) then
    Exit(False);
  R.FUnixNanos := FUnixNanos + Int64(D.FNs);
  Result := True;
end;

function TSystemTime.CheckedSub(const D: TDuration; out R: TSystemTime): Boolean;
begin
  if FUnixNanos < Int64(D.FNs) then
    Exit(False);
  R.FUnixNanos := FUnixNanos - Int64(D.FNs);
  Result := True;
end;

function TSystemTime.ToUnixNanos: Int64;
begin
  Result := FUnixNanos;
end;

function TSystemTime.ToUnixSecs: Int64;
begin
  Result := FUnixNanos div 1000000000;
end;

function TSystemTime.ToDateTime: TDateTime;
begin
  Result := UnixToDateTime(FUnixNanos div 1000000000);
end;

class function TSystemTime.FromDateTime(const DT: TDateTime): TSystemTime;
begin
  Result.FUnixNanos := DateTimeToUnix(DT) * 1000000000;
end;

function TSystemTime.Compare(const Other: TSystemTime): Integer;
begin
  if FUnixNanos < Other.FUnixNanos then
    Result := -1
  else if FUnixNanos > Other.FUnixNanos then
    Result := 1
  else
    Result := 0;
end;

// TSystemTime 运算符重载
class operator TSystemTime.+(const A: TSystemTime; const D: TDuration): TSystemTime;
begin
  Result.FUnixNanos := A.FUnixNanos + Int64(D.FNs);
end;

class operator TSystemTime.-(const A: TSystemTime; const D: TDuration): TSystemTime;
begin
  Result.FUnixNanos := A.FUnixNanos - Int64(D.FNs);
end;

class operator TSystemTime.-(const A, B: TSystemTime): TDuration;
var
  diff: Int64;
begin
  diff := A.FUnixNanos - B.FUnixNanos;
  if diff < 0 then
    Result.FNs := 0
  else
    Result.FNs := UInt64(diff);
end;

class operator TSystemTime.=(const A, B: TSystemTime): Boolean;
begin
  Result := A.FUnixNanos = B.FUnixNanos;
end;

class operator TSystemTime.<>(const A, B: TSystemTime): Boolean;
begin
  Result := A.FUnixNanos <> B.FUnixNanos;
end;

class operator TSystemTime.<(const A, B: TSystemTime): Boolean;
begin
  Result := A.FUnixNanos < B.FUnixNanos;
end;

class operator TSystemTime.>(const A, B: TSystemTime): Boolean;
begin
  Result := A.FUnixNanos > B.FUnixNanos;
end;

class operator TSystemTime.<=(const A, B: TSystemTime): Boolean;
begin
  Result := A.FUnixNanos <= B.FUnixNanos;
end;

class operator TSystemTime.>=(const A, B: TSystemTime): Boolean;
begin
  Result := A.FUnixNanos >= B.FUnixNanos;
end;

{ TDeadline }

const
  NEVER_INSTANT = High(UInt64);

class function TDeadline.Never: TDeadline;
begin
  Result.FInstant.FNs := NEVER_INSTANT;
end;

class function TDeadline.Now: TDeadline;
begin
  Result.FInstant := DefaultMonotonicClock.Now;
end;

class function TDeadline.After(const D: TDuration): TDeadline;
begin
  Result.FInstant := DefaultMonotonicClock.Now.Add(D);
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
  Result := Remaining(DefaultMonotonicClock.Now);
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
  Result := HasExpired(DefaultMonotonicClock.Now);
end;

function TDeadline.HasExpired(const ANow: TInstant): Boolean;
begin
  if IsNever then
    Result := False
  else
    Result := ANow.FNs >= FInstant.FNs;
end;

function TDeadline.Expired: Boolean;
begin
  Result := HasExpired;
end;

function TDeadline.IsNever: Boolean;
begin
  Result := FInstant.FNs = NEVER_INSTANT;
end;

function TDeadline.TimeUntil(const ANow: TInstant): TDuration;
begin
  Result := Remaining(ANow);
end;

function TDeadline.Overdue(const ANow: TInstant): TDuration;
begin
  Result := ANow.DurationSince(FInstant);
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

class operator TDeadline.<>(const A, B: TDeadline): Boolean;
begin
  Result := not A.Equal(B);
end;

class operator TDeadline.<(const A, B: TDeadline): Boolean;
begin
  Result := A.LessThan(B);
end;

class operator TDeadline.>(const A, B: TDeadline): Boolean;
begin
  Result := A.GreaterThan(B);
end;

class operator TDeadline.<=(const A, B: TDeadline): Boolean;
begin
  Result := A.Compare(B) <= 0;
end;

class operator TDeadline.>=(const A, B: TDeadline): Boolean;
begin
  Result := A.Compare(B) >= 0;
end;

function TDeadline.ToString: string;
begin
  if IsNever then
    Result := 'Never'
  else if HasExpired then
    Result := Format('Expired (%s ago)', [Overdue(DefaultMonotonicClock.Now).ToString])
  else
    Result := Format('In %s', [Remaining.ToString]);
end;

{ TStopwatch }

class function TStopwatch.Create: TStopwatch;
begin
  Result.FStartTime := TInstant.FromNs(0);
  Result.FElapsed := TDuration.Zero;
  Result.FIsRunning := False;
  Result.FClock := DefaultMonotonicClock;
end;

class function TStopwatch.Create(const AClock: IMonotonicClock): TStopwatch;
begin
  Result.FStartTime := TInstant.FromNs(0);
  Result.FElapsed := TDuration.Zero;
  Result.FIsRunning := False;
  Result.FClock := AClock;
end;

class function TStopwatch.StartNew: TStopwatch;
begin
  Result := Create;
  Result.Start;
end;

class function TStopwatch.StartNew(const AClock: IMonotonicClock): TStopwatch;
begin
  Result := Create(AClock);
  Result.Start;
end;

procedure TStopwatch.Start;
begin
  if not FIsRunning then
  begin
    FStartTime := FClock.Now;
    FIsRunning := True;
  end;
end;

procedure TStopwatch.Stop;
begin
  if FIsRunning then
  begin
    FElapsed := FElapsed + FClock.Now.DurationSince(FStartTime);
    FIsRunning := False;
  end;
end;

procedure TStopwatch.Reset;
begin
  FElapsed := TDuration.Zero;
  FIsRunning := False;
end;

procedure TStopwatch.Restart;
begin
  Reset;
  Start;
end;

function TStopwatch.GetElapsed: TDuration;
begin
  Result := FElapsed;
  if FIsRunning then
    Result := Result + FClock.Now.DurationSince(FStartTime);
end;

function TStopwatch.GetElapsedMs: UInt64;
begin
  Result := GetElapsed.AsMs;
end;

function TStopwatch.GetElapsedUs: UInt64;
begin
  Result := GetElapsed.AsUs;
end;

function TStopwatch.GetElapsedNs: UInt64;
begin
  Result := GetElapsed.AsNs;
end;

function TStopwatch.IsRunning: Boolean;
begin
  Result := FIsRunning;
end;

{ TFixedMonotonicClock }

constructor TFixedMonotonicClock.Create(const AFixedTime: TInstant);
begin
  inherited Create;
  FFixedTime := AFixedTime;
end;

function TFixedMonotonicClock.Now: TInstant;
begin
  Result := FFixedTime;
end;

procedure TFixedMonotonicClock.Sleep(const D: TDuration);
begin
  // Fixed clock doesn't actually sleep
end;

{ TSystemClockImpl }

function TSystemClockImpl.Now: TDateTime;
begin
  Result := SysUtils.Now;
end;

function TSystemClockImpl.NowUTC: TDateTime;
begin
  Result := SysUtils.NowUTC;
end;

function TSystemClockImpl.ToInstant(const DT: TDateTime): TInstant;
var
  unixTime: Int64;
begin
  unixTime := DateTimeToUnix(DT);
  Result := TInstant.FromSec(UInt64(unixTime));
end;

function TSystemClockImpl.FromInstant(const I: TInstant): TDateTime;
var
  unixTime: Int64;
begin
  unixTime := Int64(I.AsSec);
  Result := UnixToDateTime(unixTime);
end;

{ TMonotonicClockImpl }

constructor TMonotonicClockImpl.Create;
begin
  inherited Create;
  {$IFDEF MSWINDOWS}
  QueryPerformanceFrequency(FFrequency);
  QueryPerformanceCounter(FStartCounter);
  {$ELSE}
  clock_gettime(CLOCK_MONOTONIC, @FStartTime);
  {$ENDIF}
end;

function TMonotonicClockImpl.Now: TInstant;
{$IFDEF MSWINDOWS}
var
  counter: Int64;
  elapsed: Int64;
{$ELSE}
var
  currentTime: timespec;
  elapsed: Int64;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  QueryPerformanceCounter(counter);
  elapsed := ((counter - FStartCounter) * 1000000000) div FFrequency;
  Result := TInstant.FromNs(UInt64(elapsed));
  {$ELSE}
  clock_gettime(CLOCK_MONOTONIC, @currentTime);
  elapsed := (currentTime.tv_sec - FStartTime.tv_sec) * 1000000000 +
             (currentTime.tv_nsec - FStartTime.tv_nsec);
  Result := TInstant.FromNs(UInt64(elapsed));
  {$ENDIF}
end;

procedure TMonotonicClockImpl.Sleep(const D: TDuration);
{$IFDEF MSWINDOWS}
var
  ms: DWORD;
{$ELSE}
var
  req: timespec;
{$ENDIF}
begin
  if D.IsZero then Exit;

  {$IFDEF MSWINDOWS}
  ms := DWORD(D.AsMs);
  if ms = 0 then ms := 1; // At least sleep 1ms
  Windows.Sleep(ms);
  {$ELSE}
  req.tv_sec := D.AsSec;
  req.tv_nsec := D.AsNs mod 1000000000;
  nanosleep(@req, nil);
  {$ENDIF}
end;

// Default clock functions
function DefaultMonotonicClock: IMonotonicClock;
begin
  if GMonotonicClock = nil then
    GMonotonicClock := TMonotonicClockImpl.Create;
  Result := GMonotonicClock;
end;

function DefaultSystemClock: ISystemClock;
begin
  if GSystemClock = nil then
    GSystemClock := TSystemClockImpl.Create;
  Result := GSystemClock;
end;

end.
