unit fafafa.core.time.tick;

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.time.consts,
  fafafa.core.base,
  // 为 TimeItTick/ElapsedDuration 提供 TDuration 与 TProc
  fafafa.core.time;

// 说明：
// 本单元作为“时间测量”子命名空间（time.tick）。当前实现通过旧单元
// fafafa.core.tick 转发，确保平滑迁移；后续将把实现下沉到此处，并将旧
// 单元标记为 deprecated。

type
  // Provider 类型
  TTickProviderType = (
    tptStandard,
    tptHighPrecision,
    tptTSC
  );
  TTickProviderTypeArray = array of TTickProviderType;

  // 高精度时间测量接口
  ITick = interface
    ['{B8F5A2E1-4C3D-4F2A-9B1E-8D7C6A5F4E3D}']
    function GetCurrentTick: UInt64;
    function GetResolution: UInt64; // 每秒 ticks 数
    function GetElapsedTicks(const AStartTick: UInt64): UInt64;
    function TicksToNanoSeconds(const ATicks: UInt64): Double;
    function TicksToMicroSeconds(const ATicks: UInt64): Double;
    function TicksToMilliSeconds(const ATicks: UInt64): Double;
    function MeasureElapsed(const AStartTick: UInt64): Double;
  end;

  // 提供者接口
  ITickProvider = interface
    ['{C9A6B3F2-5D4E-4A1B-8E2F-7C8B9A6D5E4F}']
    function CreateTick: ITick;
    function GetProviderType: TTickProviderType;
    function GetProviderName: string;
    function IsAvailable: Boolean;
  end;

  ETickError = class(ECore) end;
  ETickProviderNotAvailable = class(ETickError) end;
  ETickInvalidArgument = class(ETickError) end;

// 工厂方法（暂转发到旧实现）
function CreateTickProvider(const AProviderType: TTickProviderType): ITickProvider; inline;
function CreateDefaultTick: ITick; inline;
function GetAvailableProviders: TTickProviderTypeArray;

// 工具：计时（基于 ITick），适合微基准；返回 TDuration 便于与 time 语义配合
Type
  TStopwatch = record
  private
    FTick: ITick;
    FStart: UInt64;
    FRunning: Boolean;
    FElapsedTicks: UInt64; // 累积
  public
    class function StartNew(const ATick: ITick = nil): TStopwatch; static;
    procedure Start(const ATick: ITick = nil);
    procedure Stop;
    procedure Reset;
    procedure Restart; // 清零并重新开始
    function LapDuration: TDuration; // 返回自上次 Start/Lap 的间隔并推进起点
    function IsRunning: Boolean; inline;
    function ElapsedTicks: UInt64; inline;
    function ElapsedNs: UInt64;
    function ElapsedDuration: TDuration; // 依赖 fafafa.core.time
  end;

function TimeItTick(const P: TProc): TDuration;



const
  // 提供者名称常量
  TICK_PROVIDER_STANDARD_NAME = 'Standard Precision Timer';
  TICK_PROVIDER_HIGHPRECISION_NAME = 'High Precision Timer';
  TICK_PROVIDER_TSC_NAME       = 'TSC Hardware Timer';


implementation

uses
  {$IFDEF MSWINDOWS}Windows{$ELSE}BaseUnix{$IFDEF LINUX}, Linux{$ENDIF}{$ENDIF};

{$IFDEF DARWIN}
Type
  mach_timebase_info_data_t = record
    numer: UInt32;
    denom: UInt32;
  end;
function mach_timebase_info(var info: mach_timebase_info_data_t): LongInt; cdecl; external name 'mach_timebase_info';
function mach_absolute_time: QWord; cdecl; external name 'mach_absolute_time';
var
  GTimebaseNumer: UInt32 = 0;
  GTimebaseDenom: UInt32 = 0;
{$ENDIF}

type
  // 基类
  TTick = class(TInterfacedObject, ITick)
  private
    FResolution: UInt64;
  protected
    function DoGetTick: UInt64; virtual; abstract;
    function DoGetResolution: UInt64; virtual; abstract;
  public
    constructor Create; virtual;
    function GetCurrentTick: UInt64; inline;
    function GetResolution: UInt64; inline;
    function GetElapsedTicks(const AStartTick: UInt64): UInt64; inline;
    function TicksToNanoSeconds(const ATicks: UInt64): Double; inline;
    function TicksToMicroSeconds(const ATicks: UInt64): Double; inline;
    function TicksToMilliSeconds(const ATicks: UInt64): Double; inline;
    function MeasureElapsed(const AStartTick: UInt64): Double; inline;
  end;

  TStandardTick = class(TTick)
  protected
    function DoGetTick: UInt64; override;
    function DoGetResolution: UInt64; override;
  public
    class function IsAvailable: Boolean;
  end;

  THighPrecisionTick = class(TTick)
  protected
    function DoGetTick: UInt64; override;
    function DoGetResolution: UInt64; override;
  public
    class function IsAvailable: Boolean;
  end;

  TTSCTick = class(TTick)
  private
    class var FTSCFrequency: Double;
    class var FTSCCalibrated: Boolean;
    class procedure CalibrateTSC;
    class function ReadTSC: UInt64;
  protected
    function DoGetTick: UInt64; override;
    function DoGetResolution: UInt64; override;
  public
    constructor Create; override;
    class function IsAvailable: Boolean;
  end;

  TTickProvider = class(TInterfacedObject, ITickProvider)
  private
    FProviderType: TTickProviderType;
    FProviderName: string;
  public
    constructor Create(const AProviderType: TTickProviderType; const AProviderName: string);
    function CreateTick: ITick; virtual; abstract;
    function GetProviderType: TTickProviderType; inline;
    function GetProviderName: string; inline;
    function IsAvailable: Boolean; virtual; abstract;
  end;

  TStandardTickProvider = class(TTickProvider)
  public
    constructor Create;
    function CreateTick: ITick; override;
    function IsAvailable: Boolean; override;
  end;

  THighPrecisionTickProvider = class(TTickProvider)
  public
    constructor Create;
    function CreateTick: ITick; override;
    function IsAvailable: Boolean; override;
  end;

  TTSCTickProvider = class(TTickProvider)
  public
    constructor Create;
    function CreateTick: ITick; override;
    function IsAvailable: Boolean; override;
  end;

// 平台相关的时间获取函数
{$IFDEF MSWINDOWS}
function GetStandardTick: UInt64;
begin
  Result := GetTickCount64;
end;

function GetHighPrecisionTick: UInt64;
begin
  if not QueryPerformanceCounter(Int64(Result)) then
    Result := GetTickCount64;
end;

function GetHighPrecisionResolution: UInt64;
begin
  if not QueryPerformanceFrequency(Int64(Result)) then
    Result := MILLISECONDS_PER_SECOND;
end;
{$ELSE}
function GetStandardTick: UInt64;
begin
  Result := GetTickCount64;
end;

function GetHighPrecisionTick: UInt64;
{$IFDEF DARWIN}
var
  t: QWord;
{$ELSE}
var
  LTimeSpec: timespec;
{$ENDIF}
begin
  {$IFDEF DARWIN}
  t := mach_absolute_time;
  if (GTimebaseNumer = 0) or (GTimebaseDenom = 0) then
  begin
    var info: mach_timebase_info_data_t;
    if mach_timebase_info(info) = 0 then
    begin
      GTimebaseNumer := info.numer;
      GTimebaseDenom := info.denom;
    end
    else
    begin
      GTimebaseNumer := 1;
      GTimebaseDenom := 1;
    end;
  end;
  // 转纳秒
  Result := (t * GTimebaseNumer) div GTimebaseDenom;
  {$ELSE}
  clock_gettime(CLOCK_MONOTONIC, @LTimeSpec);
  Result := (LTimeSpec.tv_sec * NANOSECONDS_PER_SECOND) + LTimeSpec.tv_nsec;
  {$ENDIF}
end;

function GetHighPrecisionResolution: UInt64;
begin
  {$IFDEF DARWIN}
  // mach_absolute_time 在换算后视作 ns 分辨率
  Result := NANOSECONDS_PER_SECOND;
  {$ELSE}
  Result := NANOSECONDS_PER_SECOND;
  {$ENDIF}
end;
{$ENDIF}

{ TTick 实现 }
constructor TTick.Create;
begin
  inherited Create;
  FResolution := DoGetResolution;
end;

function TTick.GetCurrentTick: UInt64;
begin
  Result := DoGetTick;
end;

function TTick.GetResolution: UInt64;
begin
  Result := FResolution;
end;

function TTick.GetElapsedTicks(const AStartTick: UInt64): UInt64;
var
  LCurrentTick: UInt64;
begin
  LCurrentTick := GetCurrentTick;
  if LCurrentTick >= AStartTick then
    Result := LCurrentTick - AStartTick
  else
    Result := (High(UInt64) - AStartTick) + LCurrentTick + 1;
  if Result = 0 then
    Result := 1;
end;

function TTick.TicksToNanoSeconds(const ATicks: UInt64): Double;
begin
  Result := (ATicks * NANOSECONDS_PER_SECOND) / FResolution;
end;

function TTick.TicksToMicroSeconds(const ATicks: UInt64): Double;
begin
  Result := (ATicks * MICROSECONDS_PER_SECOND) / FResolution;
end;

function TTick.TicksToMilliSeconds(const ATicks: UInt64): Double;
begin
  Result := (ATicks * MILLISECONDS_PER_SECOND) / FResolution;
end;

function TTick.MeasureElapsed(const AStartTick: UInt64): Double;
var
  LElapsedTicks: UInt64;
begin
  LElapsedTicks := GetElapsedTicks(AStartTick);
  Result := TicksToNanoSeconds(LElapsedTicks);
end;

{ TStandardTick }
function TStandardTick.DoGetTick: UInt64;
begin
  Result := GetStandardTick;
end;

function TStandardTick.DoGetResolution: UInt64;
begin
  Result := MILLISECONDS_PER_SECOND;
end;

class function TStandardTick.IsAvailable: Boolean;
begin
  Result := True;
end;

{ THighPrecisionTick }
function THighPrecisionTick.DoGetTick: UInt64;
begin
  Result := GetHighPrecisionTick;
end;

function THighPrecisionTick.DoGetResolution: UInt64;
begin
  Result := GetHighPrecisionResolution;
end;

class function THighPrecisionTick.IsAvailable: Boolean;
{$IFDEF MSWINDOWS}
var
  LFreq: Int64;
{$ELSE}
var
  LRes: timespec;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  Result := QueryPerformanceFrequency(LFreq);
  {$ELSE}
  Result := clock_getres(CLOCK_MONOTONIC, @LRes) = 0;
  {$ENDIF}
end;

{ TTSCTick }
{$ASMMODE INTEL}
class function TTSCTick.ReadTSC: UInt64; assembler;
asm
  {$IFDEF CPU64}
  XOR   RAX, RAX
  RDTSC
  SHL   RDX, 32
  OR    RAX, RDX
  {$ELSE}
  XOR   EDX, EDX
  XOR   EAX, EAX
  RDTSC
  {$ENDIF}
end;

class procedure TTSCTick.CalibrateTSC;
var
  LStartTick, LEndTick, LStartTSC, LEndTSC: UInt64;
  LDurationNS, LDurationTSC: UInt64;
begin
  if FTSCCalibrated then Exit;
  LStartTick := GetHighPrecisionTick;
  LStartTSC := ReadTSC;
  Sleep(10);
  LEndTSC := ReadTSC;
  LEndTick := GetHighPrecisionTick;
  LDurationNS := ((LEndTick - LStartTick) * NANOSECONDS_PER_SECOND) div GetHighPrecisionResolution;
  LDurationTSC := LEndTSC - LStartTSC;
  if LDurationNS > 0 then
  begin
    FTSCFrequency := LDurationTSC / LDurationNS;
    FTSCCalibrated := True;
  end
  else
    raise ETickError.Create('TSC校准失败：无法获取有效的时间间隔');
end;

constructor TTSCTick.Create;
begin
  if not IsAvailable then
    raise ETickProviderNotAvailable.Create('TSC计时器不可用');
  CalibrateTSC;
  inherited Create;
end;

function TTSCTick.DoGetTick: UInt64;
begin
  if not FTSCCalibrated then
    CalibrateTSC;
  Result := Round(ReadTSC / FTSCFrequency);
end;

function TTSCTick.DoGetResolution: UInt64;
begin
  Result := NANOSECONDS_PER_SECOND;
end;

class function TTSCTick.IsAvailable: Boolean;
begin
  try
    ReadTSC;
    Result := True;
  except
    Result := False;
  end;
end;

{ TTickProvider }
constructor TTickProvider.Create(const AProviderType: TTickProviderType; const AProviderName: string);
begin
  inherited Create;
  FProviderType := AProviderType;
  FProviderName := AProviderName;
end;

function TTickProvider.GetProviderType: TTickProviderType;
begin
  Result := FProviderType;
end;

function TTickProvider.GetProviderName: string;
begin
  Result := FProviderName;
end;

{ TStandardTickProvider }
constructor TStandardTickProvider.Create;
begin
  inherited Create(tptStandard, TICK_PROVIDER_STANDARD_NAME);
end;

function TStandardTickProvider.CreateTick: ITick;
begin
  Result := TStandardTick.Create;
end;

function TStandardTickProvider.IsAvailable: Boolean;
begin
  Result := TStandardTick.IsAvailable;
end;

{ THighPrecisionTickProvider }
constructor THighPrecisionTickProvider.Create;
begin
  inherited Create(tptHighPrecision, TICK_PROVIDER_HIGHPRECISION_NAME);
end;

function THighPrecisionTickProvider.CreateTick: ITick;
begin
  Result := THighPrecisionTick.Create;
end;

function THighPrecisionTickProvider.IsAvailable: Boolean;
begin
  Result := THighPrecisionTick.IsAvailable;
end;

{ TTSCTickProvider }
constructor TTSCTickProvider.Create;
begin
  inherited Create(tptTSC, TICK_PROVIDER_TSC_NAME);
end;

function TTSCTickProvider.CreateTick: ITick;
begin
  Result := TTSCTick.Create;
end;

function TTSCTickProvider.IsAvailable: Boolean;
begin
  Result := TTSCTick.IsAvailable;
end;

function CreateTickProvider(const AProviderType: TTickProviderType): ITickProvider;
begin
  case AProviderType of
    tptStandard:
      begin
        Result := TStandardTickProvider.Create;
        if not Result.IsAvailable then
          raise ETickProviderNotAvailable.CreateFmt('标准时间提供者不可用: %s', [Result.GetProviderName]);
      end;
    tptHighPrecision:
      begin
        Result := THighPrecisionTickProvider.Create;
        if not Result.IsAvailable then
          raise ETickProviderNotAvailable.CreateFmt('高精度时间提供者不可用: %s', [Result.GetProviderName]);
      end;
    tptTSC:
      begin
        Result := TTSCTickProvider.Create;
        if not Result.IsAvailable then
          raise ETickProviderNotAvailable.CreateFmt('TSC时间提供者不可用: %s', [Result.GetProviderName]);
      end;
  else
    raise ETickInvalidArgument.CreateFmt('无效的时间提供者类型: %d', [Ord(AProviderType)]);
  end;
end;

function CreateDefaultTick: ITick;
var
  LProvider: ITickProvider;
begin
  Result := nil;
  try
    LProvider := CreateTickProvider(tptHighPrecision);
    Result := LProvider.CreateTick;
  except
    on ETickProviderNotAvailable do
    begin
      try
        LProvider := CreateTickProvider(tptStandard);
        Result := LProvider.CreateTick;
      except
        on ETickProviderNotAvailable do
          raise ETickError.Create('没有可用的时间提供者');
      end;
    end;
  end;
  if Result = nil then
    raise ETickError.Create('没有可用的时间提供者');
end;

function GetAvailableProviders: TTickProviderTypeArray;
var
  LProviders: TTickProviderTypeArray;
  LCount: Integer;
begin
  {$PUSH}
  {$WARN 5091 OFF}
  SetLength(LProviders, 3);
  LCount := 0;
  {$POP}
  if TStandardTick.IsAvailable then
  begin
    LProviders[LCount] := tptStandard;
    Inc(LCount);
  end;
  if THighPrecisionTick.IsAvailable then
  begin
    LProviders[LCount] := tptHighPrecision;
    Inc(LCount);
  end;
  if TTSCTick.IsAvailable then
  begin
    LProviders[LCount] := tptTSC;
    Inc(LCount);
  end;
  {$PUSH}
  {$WARN 5091 OFF}
  SetLength(LProviders, LCount);
  {$POP}
  Result := LProviders;
end;



class function TStopwatch.StartNew(const ATick: ITick): TStopwatch;
begin
  Result.Reset;
  Result.Start(ATick);
end;

procedure TStopwatch.Start(const ATick: ITick);
begin
  if FRunning then Exit;
  if ATick <> nil then FTick := ATick;
  if FTick = nil then FTick := CreateDefaultTick;
  FStart := FTick.GetCurrentTick;
  FRunning := True;
end;

procedure TStopwatch.Stop;
var
  LNow: UInt64;
begin
  if not FRunning then Exit;
  LNow := FTick.GetCurrentTick;
  // 使用接口的 elapsed 语义，避免外部分辨率差异
  FElapsedTicks := FElapsedTicks + FTick.GetElapsedTicks(FStart);
  FRunning := False;
end;

procedure TStopwatch.Reset;
begin
  FStart := 0;
  FElapsedTicks := 0;
  FRunning := False;
  FTick := nil;
end;

procedure TStopwatch.Restart;
begin
  Reset;
  Start(nil);
end;

function TStopwatch.LapDuration: TDuration;
var
  nowTicks: UInt64;
  deltaTicks: UInt64;
begin
  if (not FRunning) or (FTick = nil) then
    Exit(TDuration.Zero);
  nowTicks := FTick.GetCurrentTick;
  deltaTicks := FTick.GetElapsedTicks(FStart);
  FElapsedTicks := FElapsedTicks + deltaTicks;
  FStart := nowTicks;
  Result := TDuration.FromNs(Trunc(FTick.TicksToNanoSeconds(deltaTicks)));
end;

function TStopwatch.IsRunning: Boolean;
begin
  Result := FRunning;
end;

function TStopwatch.ElapsedTicks: UInt64;
begin
  if FRunning and (FTick <> nil) then
    Result := FElapsedTicks + FTick.GetElapsedTicks(FStart)
  else
    Result := FElapsedTicks;
end;

function TStopwatch.ElapsedNs: UInt64;
var
  LNs: Double;
begin
  if FTick = nil then Exit(0);
  LNs := FTick.TicksToNanoSeconds(ElapsedTicks);
  if LNs < 0 then LNs := 0;
  Result := Trunc(LNs);
end;

function TStopwatch.ElapsedDuration: TDuration;
begin
  Result := TDuration.FromNs(ElapsedNs);
end;

function TimeItTick(const P: TProc): TDuration;
var
  SW: TStopwatch;
begin
  SW := TStopwatch.StartNew;
  if Assigned(P) then P();
  SW.Stop;
  Result := SW.ElapsedDuration;
end;

end.

