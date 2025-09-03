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

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.time.base,
  fafafa.core.time.tick;

type
  {**
   * TStopwatch - 秒表计时器
   *
   * @desc
   *   提供高精度的时间测量功能，类似于 .NET 的 Stopwatch 类。
   *   支持启动、停止、重置和累计计时等操作。
   *
   * @precision
   *   基于底层 ITick 实现的精度，通常为纳秒级。
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
    FTick: ITick;
    FStartTick: UInt64;
    FElapsedTicks: UInt64;
    FIsRunning: Boolean;
    
    procedure EnsureTick;
  public
    // 构造和工厂方法
    class function Create: TStopwatch; static;
    class function Create(const ATick: ITick): TStopwatch; static;
    class function StartNew: TStopwatch; static;
    class function StartNew(const ATick: ITick): TStopwatch; static;
    
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
    
    // 便捷方法
    function ToString: string;
    function ToStringPrecise: string; // 包含纳秒精度
    
    // 静态工具方法
    class function Measure(const AProc: TProc): TDuration; static;
    class function Measure(const AProc: TProc; const ATick: ITick): TDuration; static;
    class function MeasureMs(const AProc: TProc): UInt64; static;
    class function MeasureNs(const AProc: TProc): UInt64; static;
  end;

  {**
   * TStopwatchScope - RAII 风格的秒表
   *
   * @desc
   *   提供 RAII 风格的自动计时功能。
   *   在作用域开始时自动启动计时，结束时自动停止并可选择性输出结果。
   *
   * @thread_safety
   *   非线程安全，需要外部同步。
   *
   * @usage
   *   var scope: TStopwatchScope;
   *   begin
   *     scope := TStopwatchScope.Create('Operation');
   *     DoWork();
   *     // 自动析构时输出计时结果
   *   end;
   *}
  TStopwatchScope = record
  private
    FStopwatch: TStopwatch;
    FName: string;
    FAutoOutput: Boolean;
    FStarted: Boolean;
  public
    // 构造方法
    class function Create(const AName: string = ''; AAutoOutput: Boolean = True): TStopwatchScope; static;
    class function Create(const AName: string; const ATick: ITick; AAutoOutput: Boolean = True): TStopwatchScope; static;
    
    // 控制方法
    procedure Finish;
    procedure Cancel;
    
    // 结果获取
    function GetElapsed: TDuration;
    function GetElapsedMs: UInt64;
    function GetName: string; inline;
    
    // 输出控制
    procedure SetAutoOutput(AValue: Boolean); inline;
    procedure OutputResult;
  end;

// 便捷函数
function MeasureTime(const AProc: TProc): TDuration; inline;
function MeasureTimeMs(const AProc: TProc): UInt64; inline;
function MeasureTimeNs(const AProc: TProc): UInt64; inline;

// 全局默认实例相关
procedure SetDefaultStopwatchTick(const ATick: ITick);
function GetDefaultStopwatchTick: ITick;

implementation

var
  GDefaultTick: ITick = nil;

{ TStopwatch }

class function TStopwatch.Create: TStopwatch;
begin
  Result.FTick := nil;
  Result.FStartTick := 0;
  Result.FElapsedTicks := 0;
  Result.FIsRunning := False;
end;

class function TStopwatch.Create(const ATick: ITick): TStopwatch;
begin
  Result := Create;
  Result.FTick := ATick;
end;

class function TStopwatch.StartNew: TStopwatch;
begin
  Result := Create;
  Result.Start;
end;

class function TStopwatch.StartNew(const ATick: ITick): TStopwatch;
begin
  Result := Create(ATick);
  Result.Start;
end;

procedure TStopwatch.EnsureTick;
begin
  if FTick = nil then
    FTick := GetDefaultStopwatchTick;
end;

procedure TStopwatch.Start;
begin
  if not FIsRunning then
  begin
    EnsureTick;
    FStartTick := FTick.GetCurrentTick;
    FIsRunning := True;
  end;
end;

procedure TStopwatch.Stop;
begin
  if FIsRunning then
  begin
    EnsureTick;
    FElapsedTicks := FElapsedTicks + FTick.GetElapsedTicks(FStartTick);
    FIsRunning := False;
  end;
end;

procedure TStopwatch.Reset;
begin
  FElapsedTicks := 0;
  FIsRunning := False;
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
    EnsureTick;
    Result := Result + FTick.GetElapsedTicks(FStartTick);
  end;
end;

function TStopwatch.ElapsedNs: UInt64;
begin
  EnsureTick;
  Result := FTick.MeasureElapsedNs(0) * ElapsedTicks div FTick.GetResolution;
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
  EnsureTick;
  Result := FTick.TicksToDuration(ElapsedTicks);
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

class function TStopwatch.Measure(const AProc: TProc): TDuration;
var
  sw: TStopwatch;
begin
  sw := StartNew;
  try
    AProc();
  finally
    sw.Stop;
  end;
  Result := sw.ElapsedDuration;
end;

class function TStopwatch.Measure(const AProc: TProc; const ATick: ITick): TDuration;
var
  sw: TStopwatch;
begin
  sw := StartNew(ATick);
  try
    AProc();
  finally
    sw.Stop;
  end;
  Result := sw.ElapsedDuration;
end;

class function TStopwatch.MeasureMs(const AProc: TProc): UInt64;
var
  sw: TStopwatch;
begin
  sw := StartNew;
  try
    AProc();
  finally
    sw.Stop;
  end;
  Result := sw.ElapsedMs;
end;

class function TStopwatch.MeasureNs(const AProc: TProc): UInt64;
var
  sw: TStopwatch;
begin
  sw := StartNew;
  try
    AProc();
  finally
    sw.Stop;
  end;
  Result := sw.ElapsedNs;
end;

{ TStopwatchScope }

class function TStopwatchScope.Create(const AName: string; AAutoOutput: Boolean): TStopwatchScope;
begin
  Result.FStopwatch := TStopwatch.StartNew;
  Result.FName := AName;
  Result.FAutoOutput := AAutoOutput;
  Result.FStarted := True;
end;

class function TStopwatchScope.Create(const AName: string; const ATick: ITick; AAutoOutput: Boolean): TStopwatchScope;
begin
  Result.FStopwatch := TStopwatch.StartNew(ATick);
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

function MeasureTime(const AProc: TProc): TDuration;
begin
  Result := TStopwatch.Measure(AProc);
end;

function MeasureTimeMs(const AProc: TProc): UInt64;
begin
  Result := TStopwatch.MeasureMs(AProc);
end;

function MeasureTimeNs(const AProc: TProc): UInt64;
begin
  Result := TStopwatch.MeasureNs(AProc);
end;

procedure SetDefaultStopwatchTick(const ATick: ITick);
begin
  GDefaultTick := ATick;
end;

function GetDefaultStopwatchTick: ITick;
begin
  if GDefaultTick = nil then
    GDefaultTick := fafafa.core.time.tick.DefaultTick;
  Result := GDefaultTick;
end;

end.
