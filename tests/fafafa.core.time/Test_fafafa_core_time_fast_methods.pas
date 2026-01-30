unit Test_fafafa_core_time_fast_methods;

{$mode objfpc}{$H+}

{
  Test: Phase 3 - 快速方法测试
  
  目标：
  - TDuration 分解方法：WholeHours, WholeMinutes, WholeSeconds, SubsecNanos 等
  - TInstant.Elapsed 方法
  
  遵循 TDD 规范：此测试先于实现编写
}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.time;

type
  TTestCase_FastMethods = class(TTestCase)
  published
    // ═══════════════════════════════════════════════════════════════
    // TDuration 分解方法测试 - Whole* 系列
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_Duration_WholeHours_Basic;
    procedure Test_Duration_WholeHours_LessThanOne;
    procedure Test_Duration_WholeHours_Negative;
    procedure Test_Duration_WholeMinutes_Basic;
    procedure Test_Duration_WholeMinutes_LessThanOne;
    procedure Test_Duration_WholeMinutes_Negative;
    procedure Test_Duration_WholeSeconds_Basic;
    procedure Test_Duration_WholeDays_Basic;
    
    // ═══════════════════════════════════════════════════════════════
    // TDuration 分解方法测试 - Subsec* 系列
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_Duration_SubsecNanos_Basic;
    procedure Test_Duration_SubsecNanos_Zero;
    procedure Test_Duration_SubsecNanos_Negative;
    procedure Test_Duration_SubsecMicros_Basic;
    procedure Test_Duration_SubsecMillis_Basic;
    
    // ═══════════════════════════════════════════════════════════════
    // TDuration 分解方法测试 - 组合场景
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_Duration_Decompose_Complex;
    procedure Test_Duration_Decompose_Reassemble;
    
    // ═══════════════════════════════════════════════════════════════
    // TInstant.Elapsed 测试
    // ═══════════════════════════════════════════════════════════════
    
    procedure Test_Instant_Elapsed_Immediate;
    procedure Test_Instant_Elapsed_AfterSleep;
    procedure Test_Instant_DurationSince_Alias;
  end;

implementation

uses
  fafafa.core.time.duration,
  fafafa.core.time.instant,
  fafafa.core.time.clock;

{ TTestCase_FastMethods }

// ═══════════════════════════════════════════════════════════════
// TDuration - Whole* 系列测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_FastMethods.Test_Duration_WholeHours_Basic;
var
  D: TDuration;
begin
  // 3小时30分钟 = 3.5小时 → WholeHours = 3
  D := TDuration.FromHours(3) + TDuration.FromMinutes(30);
  
  AssertEquals('3h30m should have 3 whole hours', 3, D.WholeHours);
end;

procedure TTestCase_FastMethods.Test_Duration_WholeHours_LessThanOne;
var
  D: TDuration;
begin
  // 45分钟 → WholeHours = 0
  D := TDuration.FromMinutes(45);
  
  AssertEquals('45 minutes should have 0 whole hours', 0, D.WholeHours);
end;

procedure TTestCase_FastMethods.Test_Duration_WholeHours_Negative;
var
  D: TDuration;
begin
  // -2小时30分钟 → WholeHours = -2 (截断向零)
  D := -TDuration.FromHours(2) - TDuration.FromMinutes(30);
  
  AssertEquals('-2h30m should have -2 whole hours', -2, D.WholeHours);
end;

procedure TTestCase_FastMethods.Test_Duration_WholeMinutes_Basic;
var
  D: TDuration;
begin
  // 90秒 = 1分30秒 → WholeMinutes = 1
  D := TDuration.FromSec(90);
  
  AssertEquals('90 seconds should have 1 whole minute', 1, D.WholeMinutes);
end;

procedure TTestCase_FastMethods.Test_Duration_WholeMinutes_LessThanOne;
var
  D: TDuration;
begin
  // 45秒 → WholeMinutes = 0
  D := TDuration.FromSec(45);
  
  AssertEquals('45 seconds should have 0 whole minutes', 0, D.WholeMinutes);
end;

procedure TTestCase_FastMethods.Test_Duration_WholeMinutes_Negative;
var
  D: TDuration;
begin
  // -2分30秒 → WholeMinutes = -2
  D := -TDuration.FromMinutes(2) - TDuration.FromSec(30);
  
  AssertEquals('-2m30s should have -2 whole minutes', -2, D.WholeMinutes);
end;

procedure TTestCase_FastMethods.Test_Duration_WholeSeconds_Basic;
var
  D: TDuration;
begin
  // 2500毫秒 = 2.5秒 → WholeSeconds = 2
  D := TDuration.FromMs(2500);
  
  AssertEquals('2500ms should have 2 whole seconds', 2, D.WholeSeconds);
end;

procedure TTestCase_FastMethods.Test_Duration_WholeDays_Basic;
var
  D: TDuration;
begin
  // 36小时 = 1.5天 → WholeDays = 1
  D := TDuration.FromHours(36);
  
  AssertEquals('36 hours should have 1 whole day', 1, D.WholeDays);
end;

// ═══════════════════════════════════════════════════════════════
// TDuration - Subsec* 系列测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_FastMethods.Test_Duration_SubsecNanos_Basic;
var
  D: TDuration;
begin
  // 1.234567890秒 → SubsecNanos = 234567890
  D := TDuration.FromNs(1234567890);
  
  AssertEquals('Subsec nanos should be 234567890', 234567890, D.SubsecNanos);
end;

procedure TTestCase_FastMethods.Test_Duration_SubsecNanos_Zero;
var
  D: TDuration;
begin
  // 整秒 → SubsecNanos = 0
  D := TDuration.FromSec(5);
  
  AssertEquals('Whole seconds should have 0 subsec nanos', 0, D.SubsecNanos);
end;

procedure TTestCase_FastMethods.Test_Duration_SubsecNanos_Negative;
var
  D: TDuration;
begin
  // -1.5秒 → SubsecNanos = 500000000 (亚秒部分始终是正的模值)
  D := TDuration.FromMs(-1500);
  
  // 负数时间的亚秒部分：取模后的绝对值
  AssertTrue('Negative duration subsec nanos should be >= 0', D.SubsecNanos >= 0);
  AssertEquals('Subsec nanos of -1.5s', 500000000, D.SubsecNanos);
end;

procedure TTestCase_FastMethods.Test_Duration_SubsecMicros_Basic;
var
  D: TDuration;
begin
  // 1.234567秒 → SubsecMicros = 234567
  D := TDuration.FromNs(1234567890);
  
  AssertEquals('Subsec micros should be 234567', 234567, D.SubsecMicros);
end;

procedure TTestCase_FastMethods.Test_Duration_SubsecMillis_Basic;
var
  D: TDuration;
begin
  // 1.234秒 → SubsecMillis = 234
  D := TDuration.FromMs(1234);
  
  AssertEquals('Subsec millis should be 234', 234, D.SubsecMillis);
end;

// ═══════════════════════════════════════════════════════════════
// TDuration - 组合场景测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_FastMethods.Test_Duration_Decompose_Complex;
var
  D: TDuration;
begin
  // 1天2小时3分4秒567毫秒
  D := TDuration.FromDays(1) + TDuration.FromHours(2) + 
       TDuration.FromMinutes(3) + TDuration.FromSec(4) + TDuration.FromMs(567);
  
  // 总共 26 小时 3 分 4.567 秒
  AssertEquals('WholeDays should be 1', 1, D.WholeDays);
  AssertEquals('WholeHours should be 26', 26, D.WholeHours);  // 总小时数
  AssertEquals('WholeMinutes should be 1563', 1563, D.WholeMinutes);  // 总分钟数
  AssertEquals('SubsecMillis should be 567', 567, D.SubsecMillis);
end;

procedure TTestCase_FastMethods.Test_Duration_Decompose_Reassemble;
var
  Original, Reassembled: TDuration;
  Days, Hours, Minutes, Seconds: Int64;
  Nanos: Integer;
begin
  // 创建一个复杂时长
  Original := TDuration.FromNs(123456789012345);
  
  // 分解
  Days := Original.WholeDays;
  Hours := Original.WholeHours mod 24;  // 天内小时
  Minutes := Original.WholeMinutes mod 60;  // 小时内分钟
  Seconds := Original.WholeSeconds mod 60;  // 分钟内秒
  Nanos := Original.SubsecNanos;
  
  // 重组
  Reassembled := TDuration.FromDays(Days) + 
                 TDuration.FromHours(Hours) + 
                 TDuration.FromMinutes(Minutes) + 
                 TDuration.FromSec(Seconds) + 
                 TDuration.FromNs(Nanos);
  
  AssertTrue('Reassembled should equal original', Original = Reassembled);
end;

// ═══════════════════════════════════════════════════════════════
// TInstant.Elapsed 测试
// ═══════════════════════════════════════════════════════════════

procedure TTestCase_FastMethods.Test_Instant_Elapsed_Immediate;
var
  Start: TInstant;
  Elapsed: TDuration;
begin
  Start := NowInstant;
  Elapsed := Start.Elapsed;
  
  // 立即调用，经过时间应该很小（< 10ms）
  AssertTrue('Elapsed time should be >= 0', Elapsed.AsNs >= 0);
  AssertTrue('Immediate elapsed should be < 10ms', Elapsed.AsMs < 10);
end;

procedure TTestCase_FastMethods.Test_Instant_Elapsed_AfterSleep;
var
  Start: TInstant;
  Elapsed: TDuration;
begin
  Start := NowInstant;
  
  // 睡眠约 50ms
  SleepFor(TDuration.FromMs(50));
  
  Elapsed := Start.Elapsed;
  
  // 经过时间应该 >= 50ms（允许一些误差）
  AssertTrue('Elapsed should be >= 40ms', Elapsed.AsMs >= 40);
  AssertTrue('Elapsed should be < 200ms', Elapsed.AsMs < 200);
end;

procedure TTestCase_FastMethods.Test_Instant_DurationSince_Alias;
var
  Start, Now: TInstant;
  ElapsedVia1, ElapsedVia2: TDuration;
begin
  Start := NowInstant;
  SleepFor(TDuration.FromMs(10));
  Now := NowInstant;
  
  // 两种方式应该得到相同结果
  ElapsedVia1 := Now.DurationSince(Start);
  ElapsedVia2 := Now.Since(Start);
  
  AssertTrue('DurationSince should equal Since', ElapsedVia1 = ElapsedVia2);
end;

initialization
  RegisterTest(TTestCase_FastMethods);

end.
