unit clock_improvements_example;

{
  时钟模块保守改进示例
  
  这个文件展示如何在不修改原有代码的情况下，
  通过装饰器模式为时钟添加新功能。
  
  特点：
  - 完全不影响原有代码
  - 新旧接口可以并存
  - 用户可选择性采用
}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils,
  fafafa.core.time.clock,
  fafafa.core.time.base,
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.result;

type
  // 定义错误类型
  TClockError = (
    ceNone,
    ceNotAvailable,
    ceSystemError,
    ceInvalidOperation
  );
  
  // 定义 Result 类型别名
  TInstantResult = specialize TResult<TInstant, TClockError>;
  TDurationResult = specialize TResult<TDuration, TClockError>;
  
  { IMonotonicClockSafe - 带错误处理的单调时钟接口 }
  IMonotonicClockSafe = interface(IMonotonicClock)
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    
    // Try 方法 - 返回 Boolean
    function TryNowInstant(out AInstant: TInstant): Boolean;
    function TrySleepFor(const D: TDuration): Boolean;
    
    // Safe 方法 - 返回 Result
    function SafeNowInstant: TInstantResult;
    function SafeGetResolution: TDurationResult;
    
    // 状态查询
    function IsAvailable: Boolean;
    function GetLastError: string;
    function GetErrorCount: Integer;
  end;
  
  { TMonotonicClockSafe - 安全单调时钟实现 }
  TMonotonicClockSafe = class(TInterfacedObject, IMonotonicClockSafe, IMonotonicClock)
  private
    FInnerClock: IMonotonicClock;
    FLastError: string;
    FErrorCount: Integer;
    
    procedure RecordError(const AMessage: string);
  public
    constructor Create(const AInnerClock: IMonotonicClock = nil);
    
    // IMonotonicClock - 转发到内部时钟
    function NowInstant: TInstant;
    procedure SleepFor(const D: TDuration);
    procedure SleepUntil(const T: TInstant);
    function WaitFor(const D: TDuration; const Token: ICancellationToken): Boolean;
    function WaitUntil(const T: TInstant; const Token: ICancellationToken): Boolean;
    function GetResolution: TDuration;
    function GetName: string;
    
    // IMonotonicClockSafe - 新增安全方法
    function TryNowInstant(out AInstant: TInstant): Boolean;
    function TrySleepFor(const D: TDuration): Boolean;
    function SafeNowInstant: TInstantResult;
    function SafeGetResolution: TDurationResult;
    function IsAvailable: Boolean;
    function GetLastError: string;
    function GetErrorCount: Integer;
  end;
  
  { TTestClockEnhanced - 增强的测试时钟 }
  TTestClockEnhanced = class(TInterfacedObject, IFixedClock)
  private
    FInnerClock: IFixedClock;
    FAutoAdvance: Boolean;
    FAutoAdvanceStep: TDuration;
    FCallCount: Integer;
    FRecordedCalls: array of TInstant;
    
  public
    constructor Create(const AInitialTime: TInstant);
    
    // 测试辅助功能
    procedure EnableAutoAdvance(const AStep: TDuration);
    procedure DisableAutoAdvance;
    function GetCallCount: Integer;
    procedure ResetCallCount;
    function GetRecordedCalls: TArray<TInstant>;
    
    // IFixedClock 实现 - 委托给内部时钟并添加功能
    function NowInstant: TInstant;
    // ... 其他方法委托实现
  end;

// 工厂函数
function CreateSafeMonotonicClock: IMonotonicClockSafe;
function CreateEnhancedTestClock(const AInitialTime: TInstant): TTestClockEnhanced;

// 便捷函数
function TrySleepFor(const D: TDuration): Boolean;
function SafeNowInstant: TInstantResult;

implementation

{ TMonotonicClockSafe }

constructor TMonotonicClockSafe.Create(const AInnerClock: IMonotonicClock);
begin
  inherited Create;
  if AInnerClock = nil then
    FInnerClock := CreateMonotonicClock
  else
    FInnerClock := AInnerClock;
  FLastError := '';
  FErrorCount := 0;
end;

procedure TMonotonicClockSafe.RecordError(const AMessage: string);
begin
  FLastError := AMessage;
  Inc(FErrorCount);
end;

function TMonotonicClockSafe.NowInstant: TInstant;
begin
  // 直接转发到内部时钟（保持原有行为）
  Result := FInnerClock.NowInstant;
end;

procedure TMonotonicClockSafe.SleepFor(const D: TDuration);
begin
  FInnerClock.SleepFor(D);
end;

procedure TMonotonicClockSafe.SleepUntil(const T: TInstant);
begin
  FInnerClock.SleepUntil(T);
end;

function TMonotonicClockSafe.WaitFor(const D: TDuration; const Token: ICancellationToken): Boolean;
begin
  Result := FInnerClock.WaitFor(D, Token);
end;

function TMonotonicClockSafe.WaitUntil(const T: TInstant; const Token: ICancellationToken): Boolean;
begin
  Result := FInnerClock.WaitUntil(T, Token);
end;

function TMonotonicClockSafe.GetResolution: TDuration;
begin
  Result := FInnerClock.GetResolution;
end;

function TMonotonicClockSafe.GetName: string;
begin
  Result := 'Safe(' + FInnerClock.GetName + ')';
end;

function TMonotonicClockSafe.TryNowInstant(out AInstant: TInstant): Boolean;
begin
  try
    AInstant := FInnerClock.NowInstant;
    Result := True;
  except
    on E: Exception do
    begin
      RecordError(E.Message);
      Result := False;
    end;
  end;
end;

function TMonotonicClockSafe.TrySleepFor(const D: TDuration): Boolean;
begin
  try
    FInnerClock.SleepFor(D);
    Result := True;
  except
    on E: Exception do
    begin
      RecordError(E.Message);
      Result := False;
    end;
  end;
end;

function TMonotonicClockSafe.SafeNowInstant: TInstantResult;
begin
  try
    Result := TInstantResult.Ok(FInnerClock.NowInstant);
  except
    on E: Exception do
    begin
      RecordError(E.Message);
      Result := TInstantResult.Err(ceSystemError);
    end;
  end;
end;

function TMonotonicClockSafe.SafeGetResolution: TDurationResult;
begin
  try
    Result := TDurationResult.Ok(FInnerClock.GetResolution);
  except
    on E: Exception do
    begin
      RecordError(E.Message);
      Result := TDurationResult.Err(ceSystemError);
    end;
  end;
end;

function TMonotonicClockSafe.IsAvailable: Boolean;
begin
  // 简单检查：尝试获取一次时间
  try
    FInnerClock.NowInstant;
    Result := True;
  except
    Result := False;
  end;
end;

function TMonotonicClockSafe.GetLastError: string;
begin
  Result := FLastError;
end;

function TMonotonicClockSafe.GetErrorCount: Integer;
begin
  Result := FErrorCount;
end;

{ TTestClockEnhanced }

constructor TTestClockEnhanced.Create(const AInitialTime: TInstant);
begin
  inherited Create;
  FInnerClock := CreateFixedClock(AInitialTime);
  FAutoAdvance := False;
  FAutoAdvanceStep := TDuration.FromMillis(0);
  FCallCount := 0;
  SetLength(FRecordedCalls, 0);
end;

procedure TTestClockEnhanced.EnableAutoAdvance(const AStep: TDuration);
begin
  FAutoAdvance := True;
  FAutoAdvanceStep := AStep;
end;

procedure TTestClockEnhanced.DisableAutoAdvance;
begin
  FAutoAdvance := False;
end;

function TTestClockEnhanced.GetCallCount: Integer;
begin
  Result := FCallCount;
end;

procedure TTestClockEnhanced.ResetCallCount;
begin
  FCallCount := 0;
  SetLength(FRecordedCalls, 0);
end;

function TTestClockEnhanced.GetRecordedCalls: TArray<TInstant>;
begin
  Result := Copy(FRecordedCalls);
end;

function TTestClockEnhanced.NowInstant: TInstant;
begin
  Inc(FCallCount);
  
  // 获取当前时间
  Result := FInnerClock.NowInstant;
  
  // 记录调用
  SetLength(FRecordedCalls, Length(FRecordedCalls) + 1);
  FRecordedCalls[High(FRecordedCalls)] := Result;
  
  // 如果启用自动前进，调整时钟
  if FAutoAdvance then
    FInnerClock.AdvanceBy(FAutoAdvanceStep);
end;

{ 工厂函数 }

function CreateSafeMonotonicClock: IMonotonicClockSafe;
begin
  Result := TMonotonicClockSafe.Create;
end;

function CreateEnhancedTestClock(const AInitialTime: TInstant): TTestClockEnhanced;
begin
  Result := TTestClockEnhanced.Create(AInitialTime);
end;

{ 便捷函数 }

function TrySleepFor(const D: TDuration): Boolean;
var
  Clock: IMonotonicClockSafe;
begin
  Clock := CreateSafeMonotonicClock;
  Result := Clock.TrySleepFor(D);
end;

function SafeNowInstant: TInstantResult;
var
  Clock: IMonotonicClockSafe;
begin
  Clock := CreateSafeMonotonicClock;
  Result := Clock.SafeNowInstant;
end;

end.