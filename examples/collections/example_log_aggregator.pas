program example_log_aggregator;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.hashmap,
  fafafa.core.collections.vec;

type
  TLogEntry = record
    Timestamp: TDateTime;
    Level: string;
    Message: string;
  end;

  { 日志聚合器 }
  TLogAggregator = class
  private
    FLogsByLevel: specialize IHashMap<string, specialize IVec<TLogEntry>>;
    FErrorCount: specialize IHashMap<string, Integer>;
  public
    constructor Create;
    procedure AddLog(const aLevel, aMessage: string);
    procedure PrintSummary;
    procedure PrintErrorPatterns;
  end;

constructor TLogAggregator.Create;
begin
  FLogsByLevel := specialize MakeHashMap<string, specialize IVec<TLogEntry>>();
  FErrorCount := specialize MakeHashMap<string, Integer>();
end;

procedure TLogAggregator.AddLog(const aLevel, aMessage: string);
var
  LLogs: specialize IVec<TLogEntry>;
  LEntry: TLogEntry;
  LCount: Integer;
begin
  // 按级别分组存储
  if not FLogsByLevel.TryGetValue(aLevel, LLogs) then
  begin
    LLogs := specialize MakeVec<TLogEntry>();
    FLogsByLevel.Add(aLevel, LLogs);
  end;
  
  LEntry.Timestamp := Now;
  LEntry.Level := aLevel;
  LEntry.Message := aMessage;
  LLogs.Append(LEntry);
  
  // 错误消息计数
  if aLevel = 'ERROR' then
  begin
    if FErrorCount.TryGetValue(aMessage, LCount) then
      FErrorCount.AddOrAssign(aMessage, LCount + 1)
    else
      FErrorCount.Add(aMessage, 1);
  end;
end;

procedure TLogAggregator.PrintSummary;
var
  LPair: specialize TPair<string, specialize IVec<TLogEntry>>;
begin
  WriteLn('--- 日志统计 ---');
  for LPair in FLogsByLevel do
    WriteLn(Format('  %s: %d 条', [LPair.Key, LPair.Value.GetCount]));
end;

procedure TLogAggregator.PrintErrorPatterns;
var
  LPair: specialize TPair<string, Integer>;
  LTopErrors: specialize IVec<specialize TPair<string, Integer>>;
  i: SizeUInt;
begin
  WriteLn('--- 高频错误（前3名）---');
  
  // 收集所有错误
  LTopErrors := specialize MakeVec<specialize TPair<string, Integer>>();
  for LPair in FErrorCount do
    LTopErrors.Append(LPair);
  
  // 简单排序（冒泡排序，演示用）
  for i := 0 to LTopErrors.GetCount - 1 do
    for var j := i + 1 to LTopErrors.GetCount - 1 do
      if LTopErrors[j].Value > LTopErrors[i].Value then
      begin
        var LTemp := LTopErrors[i];
        LTopErrors[i] := LTopErrors[j];
        LTopErrors[j] := LTemp;
      end;
  
  // 打印前3名
  for i := 0 to Min(2, LTopErrors.GetCount - 1) do
    WriteLn(Format('  %d. %s (出现 %d 次)', [
      i + 1,
      LTopErrors[i].Key,
      LTopErrors[i].Value
    ]));
end;

var
  LAggregator: TLogAggregator;
begin
  WriteLn('=== 日志聚合器示例 ===');
  WriteLn;
  
  LAggregator := TLogAggregator.Create;
  try
    // 模拟日志收集
    WriteLn('--- 收集日志 ---');
    LAggregator.AddLog('INFO', 'Server started');
    LAggregator.AddLog('INFO', 'User logged in');
    LAggregator.AddLog('ERROR', 'Database connection failed');
    LAggregator.AddLog('WARNING', 'High memory usage');
    LAggregator.AddLog('ERROR', 'Database connection failed');
    LAggregator.AddLog('ERROR', 'Timeout connecting to API');
    LAggregator.AddLog('INFO', 'Request processed');
    LAggregator.AddLog('ERROR', 'Database connection failed');
    LAggregator.AddLog('ERROR', 'Timeout connecting to API');
    LAggregator.AddLog('CRITICAL', 'Out of memory');
    WriteLn('已收集 10 条日志');
    WriteLn;
    
    LAggregator.PrintSummary;
    WriteLn;
    
    LAggregator.PrintErrorPatterns;
    WriteLn;
    
    WriteLn('=== 示例完成 ===');
  finally
    LAggregator.Free;
  end;
end.

