{$CODEPAGE UTF8}
program tick_demo;

{
# fafafa.core.tick 模块演示程序

演示如何使用 fafafa.core.tick 模块进行高精度时间测量和基准测试。

## 功能演示：
1. 基本时间测量
2. 不同精度提供者的比较
3. 简单基准测试示例
4. 时间转换功能

## 使用方法：
编译并运行此程序，观察输出结果。

fafafaStudio
Email:dtamade@gmail.com
QQ群:685403987  QQ:179033731
}

{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}

uses
  Classes,
  SysUtils,
  fafafa.core.tick;

procedure DemoBasicUsage;
var
  C: TTick;
  T0, Elapsed: UInt64;
  D: TDuration;
  LI: Integer;
  LSum: Int64; // 使用Int64避免溢出
begin
  WriteLn('=== 基本使用演示 ===');

  C := BestTick;
  WriteLn('时间分辨率: ', C.FrequencyHz, ' ticks/秒');

  T0 := C.Now;

  LSum := 0;
  for LI := 1 to 100000 do // 减少循环次数避免溢出
    LSum := LSum + LI;

  Elapsed := C.Elapsed(T0);
  D := C.TicksToDuration(Elapsed);

  WriteLn('计算1到100000的和耗时: ', Format('%.2f', [D.AsUs]), ' 微秒');
  WriteLn('计算结果: ', LSum);
  WriteLn;
end;

procedure DemoProviderComparison;
var
  types: TTickTypeArray;
  tt: TTickType;
  C: TTick;
  LI, LJ: Integer;
  T0, Elapsed: UInt64;
  D: TDuration;
  LSum: Int64;
begin
  WriteLn('=== 不同计时源比较 ===');

  types := GetAvailableTickTypes;
  WriteLn('可用的计时源数量: ', Length(types));

  for LI := 0 to High(types) do
  begin
    tt := types[LI];
    C := TTick.From(tt);
    WriteLn('计时源: ', GetTickTypeName(tt));
    WriteLn('  频率: ', C.FrequencyHz, ' Hz');
    WriteLn('  单调性: ', C.IsMonotonic);

    // 简单性能测试
    T0 := C.Now;
    LSum := 0;
    for LJ := 1 to 100000 do
      LSum := LSum + LJ;
    Elapsed := C.Elapsed(T0);
    D := C.TicksToDuration(Elapsed);
    WriteLn('  测试耗时: ', Format('%.2f', [D.AsUs]), ' 微秒');
    WriteLn;
  end;
end;

procedure DemoTimeConversion;
var
  C: TTick;
  OneSecTicks: UInt64;
  D: TDuration;
begin
  WriteLn('=== 时间转换演示 ===');

  C := BestTick;
  OneSecTicks := C.FrequencyHz;
  D := C.TicksToDuration(OneSecTicks);

  WriteLn('1秒的时间戳数: ', OneSecTicks);
  WriteLn('转换为纳秒: ', Format('%.0f', [D.AsNs:0:0]), ' ns');
  WriteLn('转换为微秒: ', Format('%.0f', [D.AsUs:0:0]), ' μs');
  WriteLn('转换为毫秒: ', Format('%.0f', [D.AsMs:0:0]), ' ms');

  // 测试小时间间隔的转换（1毫秒）
  D := TDuration.FromMs(1);
  WriteLn;
  WriteLn('1毫秒的时间戳数: ', C.DurationToTicks(D));
  WriteLn('转换为纳秒: ', Format('%.0f', [D.AsNs:0:0]), ' ns');
  WriteLn('转换为微秒: ', Format('%.2f', [D.AsUs]), ' μs');
  WriteLn;
end;

procedure DemoBenchmarkScenario;
var
  C: TTick;
  TStart, TPhase: UInt64;
  DTotal, D1, D2, D3: TDuration;
  LData: array[0..9999] of Integer;
  LI, LSum: Integer;
begin
  WriteLn('=== 基准测试场景演示 ===');

  C := BestTick;
  TStart := C.Now;

  // 阶段1：数据初始化
  TPhase := C.Now;
  for LI := 0 to 9999 do
    LData[LI] := LI;
  D1 := C.TicksToDuration(C.Elapsed(TPhase));

  // 阶段2：数据处理
  TPhase := C.Now;
  LSum := 0;
  for LI := 0 to 9999 do
    LSum := LSum + LData[LI] * 2;
  D2 := C.TicksToDuration(C.Elapsed(TPhase));

  // 阶段3：结果验证
  TPhase := C.Now;
  if LSum <> 99990000 then
    WriteLn('错误：计算结果不正确');
  D3 := C.TicksToDuration(C.Elapsed(TPhase));

  DTotal := C.TicksToDuration(C.Elapsed(TStart));

  WriteLn('基准测试结果:');
  WriteLn('  总耗时: ', Format('%.2f', [DTotal.AsUs]), ' 微秒');
  WriteLn('  阶段1 (初始化): ', Format('%.2f', [D1.AsUs]), ' 微秒');
  WriteLn('  阶段2 (处理): ', Format('%.2f', [D2.AsUs]), ' 微秒');
  WriteLn('  阶段3 (验证): ', Format('%.2f', [D3.AsUs]), ' 微秒');
  WriteLn('  计算结果: ', LSum);
  WriteLn;
end;

procedure DemoHighFrequencyMeasurement;
var
  C: TTick;
  TStart: UInt64;
  Measurements: array[0..99] of UInt64;
  LI, MonotonicCount: Integer;
  DTotal, DAvg: TDuration;
begin
  WriteLn('=== 高频测量演示 ===');

  C := BestTick;
  TStart := C.Now;
  MonotonicCount := 0;

  // 进行100次连续测量
  for LI := 0 to 99 do
  begin
    Measurements[LI] := C.Now;
    if (LI > 0) and (Measurements[LI] >= Measurements[LI-1]) then
      Inc(MonotonicCount);
  end;

  DTotal := C.TicksToDuration(C.Elapsed(TStart));
  DAvg := TDuration.FromNs(DTotal.AsNs div 100);

  WriteLn('高频测量结果:');
  WriteLn('  测量次数: 100');
  WriteLn('  单调递增次数: ', MonotonicCount, '/99');
  WriteLn('  单调性: ', Format('%.1f', [MonotonicCount / 99 * 100]), '%');
  WriteLn('  总耗时: ', Format('%.2f', [DTotal.AsUs]), ' 微秒');
  WriteLn('  平均每次测量: ', Format('%.2f', [DAvg.AsNs]), ' 纳秒');
  WriteLn;
end;

begin
  WriteLn('fafafa.core.tick 模块演示程序');
  WriteLn('=====================================');
  WriteLn;
  
  try
    DemoBasicUsage;
    DemoProviderComparison;
    DemoTimeConversion;
    DemoBenchmarkScenario;
    DemoHighFrequencyMeasurement;
    
    WriteLn('演示完成！');
  except
    on E: Exception do
    begin
      WriteLn('演示过程中发生错误: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
