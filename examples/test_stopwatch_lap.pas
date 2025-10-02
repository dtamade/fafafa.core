program test_stopwatch_lap;

{$MODE OBJFPC}{$H+}

uses
  SysUtils,
  fafafa.core.time.duration,
  fafafa.core.time.stopwatch;

procedure TestBasicLap;
var
  sw: TStopwatch;
  lap1, lap2, lap3: TDuration;
  laps: TArray<TDuration>;
  i: Integer;
begin
  WriteLn('=== 测试基本 Lap 功能 ===');
  
  sw := TStopwatch.StartNew;
  
  // 第一段工作
  Sleep(100);
  lap1 := sw.Lap;
  WriteLn('Lap 1: ', lap1.AsMs, ' ms (应该约 100ms)');
  
  // 第二段工作
  Sleep(150);
  lap2 := sw.Lap;
  WriteLn('Lap 2: ', lap2.AsMs, ' ms (应该约 150ms)');
  
  // 第三段工作
  Sleep(50);
  lap3 := sw.Lap;
  WriteLn('Lap 3: ', lap3.AsMs, ' ms (应该约 50ms)');
  
  sw.Stop;
  
  // 获取所有 Lap 记录
  laps := sw.GetLaps;
  WriteLn;
  WriteLn('所有 Lap 记录:');
  for i := 0 to High(laps) do
    WriteLn('  Lap ', i + 1, ': ', laps[i].AsMs, ' ms');
  
  WriteLn('Lap 总数: ', sw.GetLapCount);
  WriteLn('总耗时: ', sw.ElapsedMs, ' ms');
  WriteLn;
end;

procedure TestLapWhenStopped;
var
  sw: TStopwatch;
  lap: TDuration;
begin
  WriteLn('=== 测试停止时的 Lap ===');
  
  sw := TStopwatch.Create;
  
  // 未启动时 Lap 应返回零
  lap := sw.Lap;
  WriteLn('未启动时 Lap: ', lap.AsMs, ' ms (应该是 0)');
  
  // 启动后停止
  sw.Start;
  Sleep(100);
  sw.Stop;
  
  // 停止后 Lap 应返回零
  lap := sw.Lap;
  WriteLn('停止后 Lap: ', lap.AsMs, ' ms (应该是 0)');
  WriteLn;
end;

procedure TestClearLaps;
var
  sw: TStopwatch;
  i: Integer;
begin
  WriteLn('=== 测试清除 Lap 记录 ===');
  
  sw := TStopwatch.StartNew;
  
  // 记录几个 Lap
  for i := 1 to 3 do
  begin
    Sleep(50);
    sw.Lap;
  end;
  
  WriteLn('清除前 Lap 数量: ', sw.GetLapCount);
  
  // 清除 Lap 记录
  sw.ClearLaps;
  WriteLn('清除后 Lap 数量: ', sw.GetLapCount);
  
  // 继续记录
  Sleep(100);
  sw.Lap;
  WriteLn('新增 Lap 后数量: ', sw.GetLapCount);
  
  sw.Stop;
  WriteLn;
end;

procedure TestLapDurationCompat;
var
  sw: TStopwatch;
  lap1, lap2: TDuration;
begin
  WriteLn('=== 测试 LapDuration 兼容性 ===');
  
  sw := TStopwatch.StartNew;
  
  Sleep(75);
  lap1 := sw.Lap;
  
  Sleep(75);
  lap2 := sw.LapDuration;  // 使用兼容方法
  
  WriteLn('使用 Lap: ', lap1.AsMs, ' ms');
  WriteLn('使用 LapDuration: ', lap2.AsMs, ' ms');
  WriteLn('两个方法应该功能相同');
  
  sw.Stop;
  WriteLn;
end;

procedure TestRestartWithLaps;
var
  sw: TStopwatch;
  lapCount1, lapCount2: Integer;
begin
  WriteLn('=== 测试 Restart 对 Lap 的影响 ===');
  
  sw := TStopwatch.StartNew;
  
  // 记录一些 Lap
  Sleep(50);
  sw.Lap;
  Sleep(50);
  sw.Lap;
  
  lapCount1 := sw.GetLapCount;
  WriteLn('Restart 前 Lap 数量: ', lapCount1);
  
  // Restart 应该清除 Lap
  sw.Restart;
  lapCount2 := sw.GetLapCount;
  WriteLn('Restart 后 Lap 数量: ', lapCount2, ' (应该是 0)');
  
  // 新的 Lap
  Sleep(100);
  sw.Lap;
  WriteLn('新 Lap 后数量: ', sw.GetLapCount);
  
  sw.Stop;
  WriteLn;
end;

procedure TestAccumulativeLaps;
var
  sw: TStopwatch;
  laps: TArray<TDuration>;
  total: TDuration;
  i: Integer;
begin
  WriteLn('=== 测试 Lap 累积时间 ===');
  
  sw := TStopwatch.StartNew;
  
  // 多个连续 Lap
  for i := 1 to 5 do
  begin
    Sleep(20 * i);  // 20, 40, 60, 80, 100 ms
    sw.Lap;
  end;
  
  sw.Stop;
  
  // 计算 Lap 总和
  laps := sw.GetLaps;
  total := TDuration.Zero;
  WriteLn('各段 Lap 时间:');
  for i := 0 to High(laps) do
  begin
    WriteLn('  Lap ', i + 1, ': ', laps[i].AsMs, ' ms');
    total := total.Add(laps[i]);
  end;
  
  WriteLn('Lap 总和: ', total.AsMs, ' ms');
  WriteLn('秒表总时间: ', sw.ElapsedMs, ' ms');
  WriteLn('两者应该基本相等（可能有微小误差）');
  WriteLn;
end;

begin
  WriteLn('===================================');
  WriteLn('   TStopwatch Lap 功能测试');
  WriteLn('===================================');
  WriteLn;
  
  try
    TestBasicLap;
    TestLapWhenStopped;
    TestClearLaps;
    TestLapDurationCompat;
    TestRestartWithLaps;
    TestAccumulativeLaps;
    
    WriteLn('所有测试完成！');
  except
    on E: Exception do
      WriteLn('错误: ', E.Message);
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.