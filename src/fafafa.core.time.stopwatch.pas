unit fafafa.core.time.stopwatch;


{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.stopwatch - 秒表计时器

📖 概述：
  提供便捷的秒表功能，用于测量代码执行时间和性能分析。
  基于高精度时间测量，支持启动、停止、重置等操作。

🔧 特性：
  • 高精度时间测量
  • 简单易用的 API
  • 支持累计计时
  • 与 TDuration 无缝集成
  • 线程安全设计

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
──────────────────────────────────────────────────────────────
}

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.time.base,
  fafafa.core.time.duration,
  fafafa.core.time.tick;

type
  // 类型别名
  TDurationArray = array of TDuration;
  
  // 过程类型别名
  TSimpleProc = procedure;
  TObjProc = procedure of object;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  TAnonProc = reference to procedure;
  {$ENDIF}

  {**
   * TStopwatch - 秒表计时器
   *
   * @desc
   *   提供高精度的时间测量功能，类似于 .NET 的 Stopwatch 类。
   *   支持启动、停止、重置和累计计时等操作。
   *
   * @precision
   *   基于记录式 TTick 的实现，通常为纳秒级。
   *
   * @thread_safety
   *   非线程安全，需要外部同步。
   *
   * @usage
   *   var sw: TStopwatch;
   *   begin
   *     sw := TStopwatch.StartNew;
   *     DoWork();
   *     sw.Stop;
   *     Writeln('Elapsed: ', sw.ElapsedMs, ' ms');
   *   end;
   *}
  TStopwatch = record
  private
    FClock: ITick;
    FHasClock: Boolean;
    FStartTick: UInt64;
    FElapsedTicks: UInt64;
    FIsRunning: Boolean;
    FLastLapTick: UInt64;      // 上次 Lap 的时刻
    FLaps: array of UInt64;     // 存储每次 Lap 的间隔 ticks

    procedure EnsureClock;
    function TicksToNs(ATicks: UInt64): UInt64;
  public
    // 构造和工厂方法
    class function Create: TStopwatch; static;
    class function CreateWithClock(const AClock: ITick): TStopwatch; static;
    class function StartNew: TStopwatch; static;
    class function StartNewWithClock(const AClock: ITick): TStopwatch; static;

    // 控制方法
    procedure Start;
    procedure Stop;
    procedure Reset;
    procedure Restart;

    // 状态查询
    function IsRunning: Boolean; inline;

    // 时间获取（原始 ticks）
    function ElapsedTicks: UInt64;

    // 时间获取（纳秒）
    function ElapsedNs: UInt64;

    // 时间获取（常用单位）
    function ElapsedUs: UInt64; inline;
    function ElapsedMs: UInt64; inline;
    function ElapsedSec: Double; inline;

    // TDuration 集成
    function ElapsedDuration: TDuration;

    // Lap 功能（分段计时）
    function Lap: TDuration;           // 记录一个 Lap 并返回距上次 Lap 的时间
    function LapDuration: TDuration;   // 同 Lap，为兼容测试代码
    function GetLaps: TDurationArray; // 获取所有 Lap 记录
    function GetLapCount: Integer;     // 获取 Lap 数量
    procedure ClearLaps;               // 清除所有 Lap 记录

    // 便捷方法（字符串化）
    function ToString: string;
    function ToStringPrecise: string; // 包含纳秒精度
  end;

// 辅助 RAII 秒表
type
  TStopwatchScope = record
  private
    FStopwatch: TStopwatch;
    FName: string;
    FAutoOutput: Boolean;
    FStarted: Boolean;
  public
    class function Create(const AName: string = ''; AAutoOutput: Boolean = True): TStopwatchScope; static;
    class function CreateWithClock(const AName: string; const AClock: ITick; AAutoOutput: Boolean = True): TStopwatchScope; static;

    procedure Finish;
    procedure Cancel;

    function GetElapsed: TDuration;
    function GetElapsedMs: UInt64;
    function GetName: string; inline;

    procedure SetAutoOutput(AValue: Boolean); inline;
    procedure OutputResult;
  end;

// 便捷函数
// 自由过程（全局/局部非方法过程）
function MeasureTime(const AProc: TSimpleProc): TDuration; overload;
function MeasureTimeMs(const AProc: TSimpleProc): UInt64; overload;
function MeasureTimeNs(const AProc: TSimpleProc): UInt64; overload;

// 对象方法（procedure of object）
function MeasureTime(const AProc: TObjProc): TDuration; overload;
function MeasureTimeMs(const AProc: TObjProc): UInt64; overload;
function MeasureTimeNs(const AProc: TObjProc): UInt64; overload;

// 匹名过程（reference to procedure）
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function MeasureTime(const AProc: TAnonProc): TDuration; overload;
function MeasureTimeMs(const AProc: TAnonProc): UInt64; overload;
function MeasureTimeNs(const AProc: TAnonProc): UInt64; overload;
{$ENDIF}

implementation

{ TStopwatch }

class function TStopwatch.Create: TStopwatch;
begin
  Result.FHasClock := False;
  Result.FStartTick := 0;
  Result.FElapsedTicks := 0;
  Result.FIsRunning := False;
  Result.FLastLapTick := 0;
  SetLength(Result.FLaps, 0);
end;

class function TStopwatch.CreateWithClock(const AClock: ITick): TStopwatch;
begin
  Result := Create;
  Result.FClock := AClock;
  Result.FHasClock := True;
end;

class function TStopwatch.StartNew: TStopwatch;
begin
  Result := Create;
  Result.Start;
end;

class function TStopwatch.StartNewWithClock(const AClock: ITick): TStopwatch;
begin
  Result := CreateWithClock(AClock);
  Result.Start;
end;

procedure TStopwatch.EnsureClock;
begin
  if (not FHasClock) or (FClock = nil) then
  begin
    FClock := MakeBestTick;
    FHasClock := True;
  end;
end;

function TStopwatch.TicksToNs(ATicks: UInt64): UInt64;
var
  res, q, r: UInt64;
begin
  EnsureClock;
  res := FClock.GetResolution;
  if res = 0 then Exit(0);
  // ns = (ticks * 1e9) / res，避免溢出：先做整除与取余
  q := ATicks div res;
  r := ATicks - q * res;
  Result := q * 1000000000 + (r * 1000000000) div res;
end;

procedure TStopwatch.Start;
begin
  if not FIsRunning then
  begin
    EnsureClock;
    FStartTick := FClock.Tick;
    FLastLapTick := 0;  // 重置 Lap 起始点
    FIsRunning := True;
  end;
end;

procedure TStopwatch.Stop;
var dt: UInt64;
begin
  if FIsRunning then
  begin
    EnsureClock;
    dt := FClock.Tick - FStartTick;
    FElapsedTicks := FElapsedTicks + dt;
    FIsRunning := False;
  end;
end;

procedure TStopwatch.Reset;
begin
  FElapsedTicks := 0;
  FIsRunning := False;
  FLastLapTick := 0;
  SetLength(FLaps, 0);
end;

procedure TStopwatch.Restart;
begin
  Reset;
  Start;
end;

function TStopwatch.IsRunning: Boolean;
begin
  Result := FIsRunning;
end;

function TStopwatch.ElapsedTicks: UInt64;
begin
  Result := FElapsedTicks;
  if FIsRunning then
  begin
    EnsureClock;
    Result := Result + (FClock.Tick - FStartTick);
  end;
end;

function TStopwatch.ElapsedNs: UInt64;
begin
  Result := TicksToNs(ElapsedTicks);
end;

function TStopwatch.ElapsedUs: UInt64;
begin
  Result := ElapsedNs div 1000;
end;

function TStopwatch.ElapsedMs: UInt64;
begin
  Result := ElapsedNs div 1000000;
end;

function TStopwatch.ElapsedSec: Double;
begin
  Result := ElapsedNs / 1000000000.0;
end;

function TStopwatch.ElapsedDuration: TDuration;
begin
  Result := TDuration.FromNs(Int64(ElapsedNs));
end;

function TStopwatch.ToString: string;
var
  ms: UInt64;
begin
  ms := ElapsedMs;
  if ms < 1000 then
    Result := Format('%d ms', [ms])
  else if ms < 60000 then
    Result := Format('%.2f s', [ms / 1000.0])
  else
    Result := Format('%.2f min', [ms / 60000.0]);
end;

function TStopwatch.ToStringPrecise: string;
begin
  Result := Format('%d ns (%.3f ms)', [ElapsedNs, ElapsedNs / 1000000.0]);
end;

function TStopwatch.Lap: TDuration;
var
  currentTick: UInt64;
  lapTicks: UInt64;
begin
  // 如果未运行，返回零
  if not FIsRunning then
    Exit(TDuration.Zero);
  
  EnsureClock;
  currentTick := FClock.Tick;
  
  // 如果是第一次 Lap，从开始时间计算
  if FLastLapTick = 0 then
    FLastLapTick := FStartTick;
  
  // 计算距上次 Lap 的时间间隔
  lapTicks := currentTick - FLastLapTick;
  FLastLapTick := currentTick;
  
  // 保存 Lap 记录
  SetLength(FLaps, Length(FLaps) + 1);
  FLaps[High(FLaps)] := lapTicks;
  
  // 返回时间间隔
  Result := TDuration.FromNs(Int64(TicksToNs(lapTicks)));
end;

function TStopwatch.LapDuration: TDuration;
begin
  // 兼容测试代码，与 Lap 功能相同
  Result := Lap;
end;

function TStopwatch.GetLaps: TDurationArray;
var
  i: Integer;
begin
  Result := nil;  // 显式初始化以消除编译器警告
  SetLength(Result, Length(FLaps));
  for i := 0 to High(FLaps) do
    Result[i] := TDuration.FromNs(Int64(TicksToNs(FLaps[i])));
end;

function TStopwatch.GetLapCount: Integer;
begin
  Result := Length(FLaps);
end;

procedure TStopwatch.ClearLaps;
begin
  SetLength(FLaps, 0);
  FLastLapTick := 0;
end;

{ TStopwatchScope }

class function TStopwatchScope.Create(const AName: string; AAutoOutput: Boolean): TStopwatchScope;
begin
  Result.FStopwatch := TStopwatch.StartNew;
  Result.FName := AName;
  Result.FAutoOutput := AAutoOutput;
  Result.FStarted := True;
end;

class function TStopwatchScope.CreateWithClock(const AName: string; const AClock: ITick; AAutoOutput: Boolean): TStopwatchScope;
begin
  Result.FStopwatch := TStopwatch.StartNewWithClock(AClock);
  Result.FName := AName;
  Result.FAutoOutput := AAutoOutput;
  Result.FStarted := True;
end;

procedure TStopwatchScope.Finish;
begin
  if FStarted then
  begin
    FStopwatch.Stop;
    if FAutoOutput then
      OutputResult;
    FStarted := False;
  end;
end;

procedure TStopwatchScope.Cancel;
begin
  FStarted := False;
end;

function TStopwatchScope.GetElapsed: TDuration;
begin
  Result := FStopwatch.ElapsedDuration;
end;

function TStopwatchScope.GetElapsedMs: UInt64;
begin
  Result := FStopwatch.ElapsedMs;
end;

function TStopwatchScope.GetName: string;
begin
  Result := FName;
end;

procedure TStopwatchScope.SetAutoOutput(AValue: Boolean);
begin
  FAutoOutput := AValue;
end;

procedure TStopwatchScope.OutputResult;
var
  name: string;
begin
  name := FName;
  if name = '' then
    name := 'Operation';
  Writeln(Format('%s completed in %s', [name, FStopwatch.ToString]));
end;

// 便捷函数实现
function MeasureTime(const AProc: TSimpleProc): TDuration;
var
  sw: TStopwatch;
begin
  sw := TStopwatch.StartNew;
  try
    AProc();
  finally
    sw.Stop;
  end;
  Result := sw.ElapsedDuration;
end;

function MeasureTimeMs(const AProc: TSimpleProc): UInt64;
var
  sw: TStopwatch;
begin
  sw := TStopwatch.StartNew;
  try
    AProc();
  finally
    sw.Stop;
  end;
  Result := sw.ElapsedMs;
end;

function MeasureTimeNs(const AProc: TSimpleProc): UInt64;
var
  sw: TStopwatch;
begin
  sw := TStopwatch.StartNew;
  try
    AProc();
  finally
    sw.Stop;
  end;
  Result := sw.ElapsedNs;
end;

function MeasureTime(const AProc: TObjProc): TDuration;
var
  sw: TStopwatch;
begin
  sw := TStopwatch.StartNew;
  try
    AProc();
  finally
    sw.Stop;
  end;
  Result := sw.ElapsedDuration;
end;

function MeasureTimeMs(const AProc: TObjProc): UInt64;
var
  sw: TStopwatch;
begin
  sw := TStopwatch.StartNew;
  try
    AProc();
  finally
    sw.Stop;
  end;
  Result := sw.ElapsedMs;
end;

function MeasureTimeNs(const AProc: TObjProc): UInt64;
var
  sw: TStopwatch;
begin
  sw := TStopwatch.StartNew;
  try
    AProc();
  finally
    sw.Stop;
  end;
  Result := sw.ElapsedNs;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function MeasureTime(const AProc: TAnonProc): TDuration;
var
  sw: TStopwatch;
begin
  sw := TStopwatch.StartNew;
  try
    AProc();
  finally
    sw.Stop;
  end;
  Result := sw.ElapsedDuration;
end;

function MeasureTimeMs(const AProc: TAnonProc): UInt64;
var
  sw: TStopwatch;
begin
  sw := TStopwatch.StartNew;
  try
    AProc();
  finally
    sw.Stop;
  end;
  Result := sw.ElapsedMs;
end;

function MeasureTimeNs(const AProc: TAnonProc): UInt64;
var
  sw: TStopwatch;
begin
  sw := TStopwatch.StartNew;
  try
    AProc();
  finally
    sw.Stop;
  end;
  Result := sw.ElapsedNs;
end;
{$ENDIF}

end.
