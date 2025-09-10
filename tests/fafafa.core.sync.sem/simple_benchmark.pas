{$CODEPAGE UTF8}
program simple_benchmark;

{$include fafafa.core.settings.inc}

uses
  SysUtils,
  {$IFNDEF WINDOWS}
  BaseUnix, Unix,
  {$ENDIF}
  fafafa.core.sync.sem;

function GetCurrentTimeMs: QWord;
begin
  {$IFDEF WINDOWS}
  Result := GetTickCount64;
  {$ELSE}
  var tv: TTimeVal;
  fpgettimeofday(@tv, nil);
  Result := QWord(tv.tv_sec) * 1000 + QWord(tv.tv_usec) div 1000;
  {$ENDIF}
end;

procedure RunBasicTest;
var
  Sem: ISem;
  StartTime, EndTime: QWord;
  i: Integer;
  Iterations: Integer;
begin
  Iterations := 10000;
  WriteLn('=== 基本操作性能测试 ===');
  WriteLn(Format('迭代次数: %d', [Iterations]));
  
  Sem := MakeSemaphore(1, 1);
  
  StartTime := GetCurrentTimeMs;
  for i := 1 to Iterations do
  begin
    Sem.Acquire;
    Sem.Release;
  end;
  EndTime := GetCurrentTimeMs;
  
  WriteLn(Format('总时间: %d ms', [EndTime - StartTime]));
  WriteLn(Format('平均每次操作: %.4f ms', [(EndTime - StartTime) / Iterations]));
  if EndTime > StartTime then
    WriteLn(Format('每秒操作数: %.0f ops/sec', [Iterations * 1000.0 / (EndTime - StartTime)]));
  WriteLn;
end;

procedure RunTimeoutTest;
var
  Sem: ISem;
  StartTime, EndTime: QWord;
  i: Integer;
  Success: Boolean;
begin
  WriteLn('=== 超时行为性能测试 ===');
  WriteLn('测试次数: 1000');
  
  Sem := MakeSemaphore(0, 1); // 初始为0，确保超时
  
  StartTime := GetCurrentTimeMs;
  for i := 1 to 1000 do
  begin
    Success := Sem.TryAcquire(1); // 1ms 超时
    if Success then
      Sem.Release; // 不应该发生
  end;
  EndTime := GetCurrentTimeMs;
  
  WriteLn(Format('总时间: %d ms', [EndTime - StartTime]));
  WriteLn(Format('平均超时检测时间: %.4f ms', [(EndTime - StartTime) / 1000]));
  WriteLn;
end;

procedure RunBatchTest;
var
  Sem: ISem;
  StartTime, EndTime: QWord;
  i: Integer;
  BatchSize: Integer;
begin
  WriteLn('=== 批量操作性能测试 ===');
  BatchSize := 5;
  WriteLn(Format('批量大小: %d, 测试次数: 1000', [BatchSize]));
  
  Sem := MakeSemaphore(BatchSize, BatchSize);
  
  StartTime := GetCurrentTimeMs;
  for i := 1 to 1000 do
  begin
    Sem.Acquire(BatchSize);
    Sem.Release(BatchSize);
  end;
  EndTime := GetCurrentTimeMs;
  
  WriteLn(Format('总时间: %d ms', [EndTime - StartTime]));
  WriteLn(Format('平均每次批量操作: %.4f ms', [(EndTime - StartTime) / 1000]));
  if EndTime > StartTime then
    WriteLn(Format('批量操作吞吐量: %.0f batches/sec', [1000 * 1000.0 / (EndTime - StartTime)]));
  WriteLn;
end;

begin
  WriteLn('fafafa.core.sync.sem 简单性能基准测试');
  WriteLn('=====================================');
  WriteLn;
  
  try
    RunBasicTest;
    RunTimeoutTest;
    RunBatchTest;
    
    WriteLn('所有基准测试完成！');
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
