program test_tick;

{
──────────────────────────────────────────────────────────────
📦 项目：test_tick - Tick 模块测试程序

📖 概述：
  测试 fafafa.core.time.tick 模块的功能和性能。
  验证各种时钟源的可用性和精度。

🔧 测试内容：
  • 各种 tick 类型的可用性检测
  • 时间测量精度验证
  • TSC 硬件计时器测试
  • 跨平台兼容性验证

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

uses
  SysUtils, Classes,
  fafafa.core.time.tick,
  fafafa.core.time.duration;

procedure TestTickTypeAvailability;
var
  tickType: TTickType;
  availableTypes: TTickTypeArray;
begin
  WriteLn('=== Tick 类型可用性测试 ===');
  
  for tickType := Low(TTickType) to High(TTickType) do
  begin
    Write(GetTickTypeName(tickType), ': ');
    if IsTickTypeAvailable(tickType) then
      WriteLn('✓ 可用')
    else
      WriteLn('✗ 不可用');
  end;
  
  WriteLn;
  availableTypes := GetAvailableTickTypes;
  Write('可用的 Tick 类型: ');
  for tickType in availableTypes do
    Write(GetTickTypeName(tickType), ' ');
  WriteLn;
  WriteLn;
end;

procedure TestTickPrecision(const ATickType: TTickType);
var
  tick: ITick;
  start: UInt64;
  duration: TDuration;
  i: Integer;
begin
  if not IsTickTypeAvailable(ATickType) then
  begin
    WriteLn(GetTickTypeName(ATickType), ': 不可用，跳过测试');
    Exit;
  end;
  
  WriteLn('=== ', GetTickTypeName(ATickType), ' 精度测试 ===');
  
  tick := CreateTick(ATickType);
  
  WriteLn('分辨率: ', tick.Resolution, ' ticks/秒');
  WriteLn('单调性: ', BoolToStr(tick.IsMonotonic, True));
  WriteLn('高精度: ', BoolToStr(tick.IsHighResolution, True));
  WriteLn('最小间隔: ', tick.MinimumInterval.AsNs, ' 纳秒');
  
  // 测试短时间测量
  start := tick.GetCurrentTick;
  Sleep(1); // 睡眠 1 毫秒
  duration := tick.TicksToDuration(tick.GetElapsedTicks(start));
  WriteLn('Sleep(1) 测量结果: ', duration.AsMs:0:3, ' 毫秒');
  
  // 测试循环计时
  start := tick.GetCurrentTick;
  for i := 1 to 1000000 do
    ; // 空循环
  duration := tick.TicksToDuration(tick.GetElapsedTicks(start));
  WriteLn('1,000,000 次空循环: ', duration.AsUs:0:1, ' 微秒');
  
  WriteLn;
end;

procedure TestQuickMeasure;
var
  duration: TDuration;
  i: Integer;
begin
  WriteLn('=== QuickMeasure 便捷函数测试 ===');
  
  duration := QuickMeasure(
    procedure
    var
      j: Integer;
    begin
      for j := 1 to 100000 do
        ; // 空循环
    end
  );
  
  WriteLn('100,000 次空循环 (QuickMeasure): ', duration.AsUs:0:1, ' 微秒');
  WriteLn;
end;

procedure TestGlobalTicks;
begin
  WriteLn('=== 全局 Tick 函数测试 ===');
  
  var defaultTick := DefaultTick;
  WriteLn('DefaultTick 类型: ', GetTickTypeName(ttBest));
  
  var highPrecisionTick := HighPrecisionTick;
  WriteLn('HighPrecisionTick 类型: ', GetTickTypeName(ttHighPrecision));
  
  var systemTick := SystemTick;
  WriteLn('SystemTick 类型: ', GetTickTypeName(ttSystem));
  
  WriteLn;
end;

procedure TestTSCSpecific;
begin
  WriteLn('=== TSC 特定测试 ===');
  
  if IsTickTypeAvailable(ttTSC) then
  begin
    WriteLn('TSC 硬件计时器可用');
    
    var tscTick := CreateTick(ttTSC);
    WriteLn('TSC 频率: ', tscTick.Resolution, ' Hz');
    WriteLn('TSC 最小间隔: ', tscTick.MinimumInterval.AsNs, ' 纳秒');
    
    // 测试 TSC 精度
    var start := tscTick.GetCurrentTick;
    var dummy := 0;
    for var i := 1 to 1000 do
      Inc(dummy);
    var duration := tscTick.TicksToDuration(tscTick.GetElapsedTicks(start));
    WriteLn('1,000 次递增操作 (TSC): ', duration.AsNs, ' 纳秒');
  end
  else
  begin
    WriteLn('TSC 硬件计时器不可用');
  end;
  
  WriteLn;
end;

begin
  WriteLn('fafafa.core.time.tick 模块测试程序');
  WriteLn('=====================================');
  WriteLn;
  
  try
    TestTickTypeAvailability;
    TestGlobalTicks;
    TestQuickMeasure;
    
    // 测试各种 tick 类型
    TestTickPrecision(ttBest);
    TestTickPrecision(ttHighPrecision);
    TestTickPrecision(ttStandard);
    TestTickPrecision(ttSystem);
    TestTickPrecision(ttTSC);
    
    TestTSCSpecific;
    
    WriteLn('所有测试完成！');
    
  except
    on E: Exception do
    begin
      WriteLn('测试过程中发生错误: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
