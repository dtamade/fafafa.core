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
  LTick: ITick;
  LStartTick: UInt64;
  LElapsedNS: Double;
  LI: Integer;
  LSum: Int64; // 使用Int64避免溢出
begin
  WriteLn('=== 基本使用演示 ===');

  // 创建默认时间测量实例
  LTick := CreateDefaultTick;
  WriteLn('时间分辨率: ', LTick.GetResolution, ' ticks/秒');

  // 测量一个简单计算的耗时
  LStartTick := LTick.GetCurrentTick;

  LSum := 0;
  for LI := 1 to 100000 do // 减少循环次数避免溢出
    LSum := LSum + LI;

  LElapsedNS := LTick.MeasureElapsed(LStartTick);

  WriteLn('计算1到100000的和耗时: ', Format('%.2f', [LElapsedNS / 1000]), ' 微秒');
  WriteLn('计算结果: ', LSum);
  WriteLn;
end;

procedure DemoProviderComparison;
var
  LProviders: TTickProviderTypeArray;
  LProvider: ITickProvider;
  LTick: ITick;
  LI, LJ: Integer;
  LStartTick: UInt64;
  LElapsedNS: Double;
  LSum: Int64; // 使用Int64避免溢出
begin
  WriteLn('=== 不同提供者比较 ===');

  // 获取所有可用的提供者
  LProviders := GetAvailableProviders;
  WriteLn('可用的时间提供者数量: ', Length(LProviders));

  for LI := 0 to High(LProviders) do
  begin
    try
      LProvider := CreateTickProvider(LProviders[LI]);
      WriteLn('提供者: ', LProvider.GetProviderName);
      WriteLn('  类型: ', Ord(LProvider.GetProviderType));
      WriteLn('  可用: ', LProvider.IsAvailable);

      if LProvider.IsAvailable then
      begin
        LTick := LProvider.CreateTick;
        WriteLn('  分辨率: ', LTick.GetResolution, ' ticks/秒');

        // 测试性能
        LStartTick := LTick.GetCurrentTick;
        LSum := 0;
        for LJ := 1 to 100000 do
          LSum := LSum + LJ;
        LElapsedNS := LTick.MeasureElapsed(LStartTick);

        WriteLn('  测试耗时: ', Format('%.2f', [LElapsedNS / 1000]), ' 微秒');
      end;

      WriteLn;
    except
      on E: Exception do
        WriteLn('提供者创建失败: ', E.Message);
    end;
  end;
end;

procedure DemoTimeConversion;
var
  LTick: ITick;
  LTicks: UInt64;
begin
  WriteLn('=== 时间转换演示 ===');
  
  LTick := CreateDefaultTick;
  LTicks := LTick.GetResolution; // 1秒的时间戳数
  
  WriteLn('1秒的时间戳数: ', LTicks);
  WriteLn('转换为纳秒: ', Format('%.0f', [LTick.TicksToNanoSeconds(LTicks)]), ' ns');
  WriteLn('转换为微秒: ', Format('%.0f', [LTick.TicksToMicroSeconds(LTicks)]), ' μs');
  WriteLn('转换为毫秒: ', Format('%.0f', [LTick.TicksToMilliSeconds(LTicks)]), ' ms');
  
  // 测试小时间间隔的转换
  LTicks := LTick.GetResolution div 1000; // 1毫秒的时间戳数
  WriteLn;
  WriteLn('1毫秒的时间戳数: ', LTicks);
  WriteLn('转换为纳秒: ', Format('%.0f', [LTick.TicksToNanoSeconds(LTicks)]), ' ns');
  WriteLn('转换为微秒: ', Format('%.2f', [LTick.TicksToMicroSeconds(LTicks)]), ' μs');
  WriteLn;
end;

procedure DemoBenchmarkScenario;
var
  LTick: ITick;
  LStartTick, LPhaseStart: UInt64;
  LTotalTime, LPhase1, LPhase2, LPhase3: Double;
  LData: array[0..9999] of Integer;
  LI, LSum: Integer;
begin
  WriteLn('=== 基准测试场景演示 ===');
  
  LTick := CreateDefaultTick;
  LStartTick := LTick.GetCurrentTick;
  
  // 阶段1：数据初始化
  LPhaseStart := LTick.GetCurrentTick;
  for LI := 0 to 9999 do
    LData[LI] := LI;
  LPhase1 := LTick.MeasureElapsed(LPhaseStart);
  
  // 阶段2：数据处理
  LPhaseStart := LTick.GetCurrentTick;
  LSum := 0;
  for LI := 0 to 9999 do
    LSum := LSum + LData[LI] * 2;
  LPhase2 := LTick.MeasureElapsed(LPhaseStart);
  
  // 阶段3：结果验证
  LPhaseStart := LTick.GetCurrentTick;
  if LSum <> 99990000 then
    WriteLn('错误：计算结果不正确');
  LPhase3 := LTick.MeasureElapsed(LPhaseStart);
  
  LTotalTime := LTick.MeasureElapsed(LStartTick);
  
  WriteLn('基准测试结果:');
  WriteLn('  总耗时: ', Format('%.2f', [LTotalTime / 1000]), ' 微秒');
  WriteLn('  阶段1 (初始化): ', Format('%.2f', [LPhase1 / 1000]), ' 微秒');
  WriteLn('  阶段2 (处理): ', Format('%.2f', [LPhase2 / 1000]), ' 微秒');
  WriteLn('  阶段3 (验证): ', Format('%.2f', [LPhase3 / 1000]), ' 微秒');
  WriteLn('  计算结果: ', LSum);
  WriteLn;
end;

procedure DemoHighFrequencyMeasurement;
var
  LTick: ITick;
  LStartTick: UInt64;
  LMeasurements: array[0..99] of UInt64;
  LI, LMonotonicCount: Integer;
  LTotalTime: Double;
begin
  WriteLn('=== 高频测量演示 ===');
  
  LTick := CreateDefaultTick;
  LStartTick := LTick.GetCurrentTick;
  LMonotonicCount := 0;
  
  // 进行100次连续测量
  for LI := 0 to 99 do
  begin
    LMeasurements[LI] := LTick.GetCurrentTick;
    if (LI > 0) and (LMeasurements[LI] >= LMeasurements[LI-1]) then
      Inc(LMonotonicCount);
  end;
  
  LTotalTime := LTick.MeasureElapsed(LStartTick);
  
  WriteLn('高频测量结果:');
  WriteLn('  测量次数: 100');
  WriteLn('  单调递增次数: ', LMonotonicCount, '/99');
  WriteLn('  单调性: ', Format('%.1f', [LMonotonicCount / 99 * 100]), '%');
  WriteLn('  总耗时: ', Format('%.2f', [LTotalTime / 1000]), ' 微秒');
  WriteLn('  平均每次测量: ', Format('%.2f', [LTotalTime / 100]), ' 纳秒');
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
