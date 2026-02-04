{$CODEPAGE UTF8}
unit TestHelpers_Sync;

{**
 * fafafa.core.sync 统一测试辅助模块
 *
 * 提供同步原语边界测试的通用工具：
 * - 并发测试线程管理
 * - 超时边界测试辅助
 * - 压力测试统计
 * - 高并发场景支持
 *
 * @author fafafaStudio
 * @version 1.0
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit;

const
  // 超时边界值常量
  TIMEOUT_ZERO      = 0;        // 0ms - 立即返回
  TIMEOUT_MIN       = 1;        // 1ms - 最小有效超时
  TIMEOUT_SMALL     = 10;       // 10ms - 小超时
  TIMEOUT_MEDIUM    = 100;      // 100ms - 中等超时
  TIMEOUT_LARGE     = 1000;     // 1s - 大超时
  TIMEOUT_STRESS    = 10;       // 压力测试默认超时
  TIMEOUT_MAX       = $FFFFFFFF; // 最大超时（约49天）

  // 并发测试线程数
  THREAD_COUNT_SINGLE  = 1;
  THREAD_COUNT_SMALL   = 4;
  THREAD_COUNT_MEDIUM  = 16;
  THREAD_COUNT_LARGE   = 100;
  THREAD_COUNT_STRESS  = 1000;

  // 压力测试迭代次数
  STRESS_ITERATIONS_SMALL  = 100;
  STRESS_ITERATIONS_MEDIUM = 1000;
  STRESS_ITERATIONS_LARGE  = 10000;

type
  // 测试结果统计
  TTestStats = record
    StartTime: QWord;
    EndTime: QWord;
    SuccessCount: Integer;
    FailureCount: Integer;
    TimeoutCount: Integer;
    ExceptionCount: Integer;
  end;

  // 通用工作线程基类
  TWorkerThread = class(TThread)
  private
    FId: Integer;
    FSuccess: Boolean;
    FErrorMessage: String;
    FStartTime: QWord;
    FEndTime: QWord;
  protected
    procedure DoWork; virtual; abstract;
    procedure Execute; override;
  public
    constructor Create(AId: Integer);
    property Id: Integer read FId;
    property Success: Boolean read FSuccess;
    property ErrorMessage: String read FErrorMessage;
    property StartTime: QWord read FStartTime;
    property EndTime: QWord read FEndTime;
    function ElapsedMs: QWord;
  end;

  // 工作线程数组辅助类型
  TWorkerThreadArray = array of TWorkerThread;

// ===== 时间辅助函数 =====

// 获取当前时间（毫秒）
function GetCurrentTimeMs: QWord;

// ===== 线程管理辅助 =====

// 等待所有线程完成
procedure WaitForAllThreads(const AThreads: TWorkerThreadArray);

// 释放所有线程
procedure FreeAllThreads(var AThreads: TWorkerThreadArray);

// 启动所有线程
procedure StartAllThreads(const AThreads: TWorkerThreadArray);

// 统计线程结果
function CollectThreadStats(const AThreads: TWorkerThreadArray): TTestStats;

// ===== 测试断言辅助 =====

// 断言超时测试：结果应该在预期时间内返回
procedure AssertTimeout(ATestCase: TTestCase; AActualMs, AExpectedMs: QWord;
  ATolerancePercent: Integer = 100; const AMsg: String = '');

// 断言时间在范围内
procedure AssertTimeInRange(ATestCase: TTestCase; AActualMs, AMinMs, AMaxMs: QWord;
  const AMsg: String = '');

// 断言所有线程成功
procedure AssertAllThreadsSuccess(ATestCase: TTestCase;
  const AThreads: TWorkerThreadArray; const AMsg: String = '');

// 断言成功计数
procedure AssertSuccessCount(ATestCase: TTestCase; AExpected, AActual: Integer;
  const AMsg: String = '');

// ===== 压力测试辅助 =====

// 检查是否启用压力测试模式
function IsStressModeEnabled: Boolean;

// 获取压力测试迭代次数（根据环境变量或命令行参数）
function GetStressIterations(ADefault: Integer = STRESS_ITERATIONS_MEDIUM): Integer;

// 获取压力测试线程数
function GetStressThreadCount(ADefault: Integer = THREAD_COUNT_LARGE): Integer;

// ===== 测试输出辅助 =====

// 打印测试统计
procedure PrintTestStats(const AStats: TTestStats; const ATestName: String);

// 打印线程详情（用于调试）
procedure PrintThreadDetails(const AThreads: TWorkerThreadArray);

implementation

{ TWorkerThread }

constructor TWorkerThread.Create(AId: Integer);
begin
  inherited Create(True); // 创建时暂停
  FreeOnTerminate := False;
  FId := AId;
  FSuccess := False;
  FErrorMessage := '';
  FStartTime := 0;
  FEndTime := 0;
end;

procedure TWorkerThread.Execute;
begin
  FStartTime := GetCurrentTimeMs;
  try
    DoWork;
    FSuccess := True;
  except
    on E: Exception do
    begin
      FSuccess := False;
      FErrorMessage := E.Message;
    end;
  end;
  FEndTime := GetCurrentTimeMs;
end;

function TWorkerThread.ElapsedMs: QWord;
begin
  if FEndTime >= FStartTime then
    Result := FEndTime - FStartTime
  else
    Result := 0;
end;

{ 时间辅助函数 }

function GetCurrentTimeMs: QWord;
begin
  Result := GetTickCount64;
end;

{ 线程管理辅助 }

procedure WaitForAllThreads(const AThreads: TWorkerThreadArray);
var
  i: Integer;
begin
  for i := 0 to High(AThreads) do
    if AThreads[i] <> nil then
      AThreads[i].WaitFor;
end;

procedure FreeAllThreads(var AThreads: TWorkerThreadArray);
var
  i: Integer;
begin
  for i := 0 to High(AThreads) do
    FreeAndNil(AThreads[i]);
  SetLength(AThreads, 0);
end;

procedure StartAllThreads(const AThreads: TWorkerThreadArray);
var
  i: Integer;
begin
  for i := 0 to High(AThreads) do
    if AThreads[i] <> nil then
      AThreads[i].Start;
end;

function CollectThreadStats(const AThreads: TWorkerThreadArray): TTestStats;
var
  i: Integer;
  MinStart, MaxEnd: QWord;
begin
  Result.SuccessCount := 0;
  Result.FailureCount := 0;
  Result.TimeoutCount := 0;
  Result.ExceptionCount := 0;
  MinStart := High(QWord);
  MaxEnd := 0;

  for i := 0 to High(AThreads) do
  begin
    if AThreads[i] = nil then Continue;

    if AThreads[i].Success then
      Inc(Result.SuccessCount)
    else
    begin
      Inc(Result.FailureCount);
      if Pos('timeout', LowerCase(AThreads[i].ErrorMessage)) > 0 then
        Inc(Result.TimeoutCount)
      else if AThreads[i].ErrorMessage <> '' then
        Inc(Result.ExceptionCount);
    end;

    if AThreads[i].StartTime < MinStart then
      MinStart := AThreads[i].StartTime;
    if AThreads[i].EndTime > MaxEnd then
      MaxEnd := AThreads[i].EndTime;
  end;

  if MinStart = High(QWord) then
    MinStart := 0;
  Result.StartTime := MinStart;
  Result.EndTime := MaxEnd;
end;

{ 测试断言辅助 }

procedure AssertTimeout(ATestCase: TTestCase; AActualMs, AExpectedMs: QWord;
  ATolerancePercent: Integer; const AMsg: String);
var
  MinMs, MaxMs: QWord;
  Msg: String;
begin
  MinMs := AExpectedMs * (100 - ATolerancePercent) div 100;
  MaxMs := AExpectedMs * (100 + ATolerancePercent) div 100;

  if AMsg <> '' then
    Msg := AMsg
  else
    Msg := Format('Timeout: expected ~%dms (±%d%%), actual %dms',
                  [AExpectedMs, ATolerancePercent, AActualMs]);

  ATestCase.AssertTrue(Msg, (AActualMs >= MinMs) and (AActualMs <= MaxMs));
end;

procedure AssertTimeInRange(ATestCase: TTestCase; AActualMs, AMinMs, AMaxMs: QWord;
  const AMsg: String);
var
  Msg: String;
begin
  if AMsg <> '' then
    Msg := AMsg
  else
    Msg := Format('Time: expected %d-%dms, actual %dms', [AMinMs, AMaxMs, AActualMs]);

  ATestCase.AssertTrue(Msg, (AActualMs >= AMinMs) and (AActualMs <= AMaxMs));
end;

procedure AssertAllThreadsSuccess(ATestCase: TTestCase;
  const AThreads: TWorkerThreadArray; const AMsg: String);
var
  i, FailCount: Integer;
  FirstError: String;
  Msg: String;
begin
  FailCount := 0;
  FirstError := '';

  for i := 0 to High(AThreads) do
  begin
    if (AThreads[i] <> nil) and (not AThreads[i].Success) then
    begin
      Inc(FailCount);
      if FirstError = '' then
        FirstError := Format('Thread %d: %s', [AThreads[i].Id, AThreads[i].ErrorMessage]);
    end;
  end;

  if AMsg <> '' then
    Msg := AMsg
  else if FailCount > 0 then
    Msg := Format('%d threads failed. First error: %s', [FailCount, FirstError])
  else
    Msg := 'All threads should succeed';

  ATestCase.AssertEquals(Msg, 0, FailCount);
end;

procedure AssertSuccessCount(ATestCase: TTestCase; AExpected, AActual: Integer;
  const AMsg: String);
var
  Msg: String;
begin
  if AMsg <> '' then
    Msg := AMsg
  else
    Msg := Format('Success count: expected %d, actual %d', [AExpected, AActual]);

  ATestCase.AssertEquals(Msg, AExpected, AActual);
end;

{ 压力测试辅助 }

function IsStressModeEnabled: Boolean;
var
  i: Integer;
  s: String;
begin
  Result := False;

  // 检查环境变量
  if GetEnvironmentVariable('STRESS_TEST') = '1' then
    Exit(True);

  // 检查命令行参数
  for i := 1 to ParamCount do
  begin
    s := ParamStr(i);
    if (s = '--stress') or (s = '-S') then
      Exit(True);
  end;
end;

function GetStressIterations(ADefault: Integer): Integer;
var
  EnvVal: String;
  Val: Integer;
begin
  Result := ADefault;

  EnvVal := GetEnvironmentVariable('STRESS_ITERATIONS');
  if EnvVal <> '' then
  begin
    if TryStrToInt(EnvVal, Val) and (Val > 0) then
      Result := Val;
  end;
end;

function GetStressThreadCount(ADefault: Integer): Integer;
var
  EnvVal: String;
  Val: Integer;
begin
  Result := ADefault;

  EnvVal := GetEnvironmentVariable('STRESS_THREADS');
  if EnvVal <> '' then
  begin
    if TryStrToInt(EnvVal, Val) and (Val > 0) then
      Result := Val;
  end;
end;

{ 测试输出辅助 }

procedure PrintTestStats(const AStats: TTestStats; const ATestName: String);
var
  ElapsedMs: QWord;
begin
  ElapsedMs := AStats.EndTime - AStats.StartTime;
  WriteLn(Format('=== %s ===', [ATestName]));
  WriteLn(Format('  Duration: %d ms', [ElapsedMs]));
  WriteLn(Format('  Success:  %d', [AStats.SuccessCount]));
  WriteLn(Format('  Failure:  %d', [AStats.FailureCount]));
  WriteLn(Format('  Timeout:  %d', [AStats.TimeoutCount]));
  WriteLn(Format('  Exception: %d', [AStats.ExceptionCount]));
end;

procedure PrintThreadDetails(const AThreads: TWorkerThreadArray);
var
  i: Integer;
begin
  WriteLn('=== Thread Details ===');
  for i := 0 to High(AThreads) do
  begin
    if AThreads[i] = nil then Continue;
    WriteLn(Format('  Thread %d: Success=%s, Time=%dms, Error=%s',
      [AThreads[i].Id,
       BoolToStr(AThreads[i].Success, 'Yes', 'No'),
       AThreads[i].ElapsedMs,
       AThreads[i].ErrorMessage]));
  end;
end;

end.
