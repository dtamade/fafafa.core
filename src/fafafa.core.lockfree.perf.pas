unit fafafa.core.lockfree.perf;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

{**
 * fafafa.core.lockfree.perf - 无锁模块性能监控器
 * 提供 TPerformanceMonitor，集中管理性能统计逻辑。
 *}

interface

uses
  SysUtils, fafafa.core.atomic;

type
  TPerformanceMonitor = class
  private
    FTotalOperations: Int64;
    FSuccessfulOperations: Int64;
    FFailedOperations: Int64;
    FStartTime: QWord;
    FEnabled: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Enable;
    procedure Disable;
    function IsEnabled: Boolean;
    procedure Reset;
    procedure RecordOperation(ASuccess: Boolean);
    function GetTotalOperations: Int64;
    function GetSuccessfulOperations: Int64;
    function GetFailedOperations: Int64;
    function GetThroughput: Double;
    function GetErrorRate: Double;
    function GenerateReport: string;
  end;

implementation

constructor TPerformanceMonitor.Create;
begin
  inherited Create;
  FEnabled := False;
  Reset;
end;

destructor TPerformanceMonitor.Destroy;
begin
  inherited Destroy;
end;

procedure TPerformanceMonitor.Enable;
begin
  FEnabled := True;
  if FStartTime = 0 then
    FStartTime := GetTickCount64;
end;

procedure TPerformanceMonitor.Disable;
begin
  FEnabled := False;
end;

function TPerformanceMonitor.IsEnabled: Boolean;
begin
  Result := FEnabled;
end;

procedure TPerformanceMonitor.Reset;
begin
  atomic_store_64(FTotalOperations, 0);
  atomic_store_64(FSuccessfulOperations, 0);
  atomic_store_64(FFailedOperations, 0);
  FStartTime := GetTickCount64;
end;

procedure TPerformanceMonitor.RecordOperation(ASuccess: Boolean);
begin
  if not FEnabled then Exit;
  atomic_fetch_add_64(FTotalOperations, 1);
  if ASuccess then
    atomic_fetch_add_64(FSuccessfulOperations, 1)
  else
    atomic_fetch_add_64(FFailedOperations, 1);
end;

function TPerformanceMonitor.GetTotalOperations: Int64;
begin
  Result := atomic_load_64(FTotalOperations);
end;

function TPerformanceMonitor.GetSuccessfulOperations: Int64;
begin
  Result := atomic_load_64(FSuccessfulOperations);
end;

function TPerformanceMonitor.GetFailedOperations: Int64;
begin
  Result := atomic_load_64(FFailedOperations);
end;

function TPerformanceMonitor.GetThroughput: Double;
var
  LCurrentTime: QWord;
  LTotalOps: Int64;
begin
  LCurrentTime := GetTickCount64;
  LTotalOps := GetTotalOperations;
  if (LCurrentTime > FStartTime) and (LTotalOps > 0) then
    Result := LTotalOps * 1000.0 / (LCurrentTime - FStartTime)
  else
    Result := 0.0;
end;

function TPerformanceMonitor.GetErrorRate: Double;
var
  LTotalOps, LFailedOps: Int64;
begin
  LTotalOps := GetTotalOperations;
  LFailedOps := GetFailedOperations;
  if LTotalOps > 0 then
    Result := LFailedOps / LTotalOps * 100.0
  else
    Result := 0.0;
end;

function TPerformanceMonitor.GenerateReport: string;
var
  LTotalOps, LSuccessOps, LFailedOps: Int64;
  LThroughput, LErrorRate: Double;
  LElapsedTime: QWord;
begin
  LTotalOps := GetTotalOperations;
  LSuccessOps := GetSuccessfulOperations;
  LFailedOps := GetFailedOperations;
  LThroughput := GetThroughput;
  LErrorRate := GetErrorRate;
  LElapsedTime := GetTickCount64 - FStartTime;
  Result := Format(
    '=== 性能监控报告 ===' + sLineBreak +
    '总操作数: %d' + sLineBreak +
    '成功操作: %d' + sLineBreak +
    '失败操作: %d' + sLineBreak +
    '错误率: %.2f%%' + sLineBreak +
    '吞吐量: %.0f ops/sec' + sLineBreak +
    '监控时长: %d ms' + sLineBreak,
    [LTotalOps, LSuccessOps, LFailedOps, LErrorRate, LThroughput, LElapsedTime]
  );
end;

end.

