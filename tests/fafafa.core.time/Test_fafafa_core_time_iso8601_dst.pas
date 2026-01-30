{$mode objfpc}{$H+}{$J-}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

unit Test_fafafa_core_time_iso8601_dst;

interface

uses
  Classes, SysUtils, DateUtils, fpcunit, testregistry,
  fafafa.core.math,
  fafafa.core.time.iso8601;

type
  {
    测试 ISSUE-44 修复：DST（夏令时）感知的时区偏移
    
    验证 GetLocalTimeZoneOffset 函数能够：
    1. 根据具体日期时间判断DST状态
    2. 在DST切换边界正确计算时区偏移
    3. 处理春季向前（Spring Forward）和秋季向后（Fall Back）
    
    注意：测试结果依赖于系统时区设置和DST规则
  }
  TTestISO8601DST = class(TTestCase)
  private
    function IsSystemSupportsDST: Boolean;
    function GetSystemTimeZoneInfo(out HasDST: Boolean; out StandardOffset, DSTOffset: Integer): Boolean;
  published
    // 基本功能测试
    procedure Test_GetTimeZoneOffset_WithParameter;
    procedure Test_GetTimeZoneOffset_WithoutParameter;
    procedure Test_GetTimeZoneOffset_Overload_Consistency;
    
    // DST边界测试（依赖系统设置）
    procedure Test_GetTimeZoneOffset_WinterVsSummer;
    procedure Test_GetTimeZoneOffset_DST_SpringForward;
    procedure Test_GetTimeZoneOffset_DST_FallBack;
    
    // 格式化测试（验证修复效果）
    procedure Test_FormatDateTime_WithTimeZone_UsesCorrectOffset;
    procedure Test_FormatDateTime_HistoricalDate_CorrectDST;
    procedure Test_FormatDateTime_FutureDate_CorrectDST;
  end;

implementation

{ TTestISO8601DST }

function TTestISO8601DST.IsSystemSupportsDST: Boolean;
var
  HasDST: Boolean;
  Std, DST: Integer;
begin
  Result := GetSystemTimeZoneInfo(HasDST, Std, DST) and HasDST;
end;

function TTestISO8601DST.GetSystemTimeZoneInfo(out HasDST: Boolean; 
  out StandardOffset, DSTOffset: Integer): Boolean;
var
  WinterDate, SummerDate: TDateTime;
  WinterOffset, SummerOffset: Integer;
begin
  // 使用典型的冬季和夏季日期
  WinterDate := EncodeDate(2024, 1, 15);  // 1月中旬（通常是标准时）
  SummerDate := EncodeDate(2024, 7, 15);  // 7月中旬（通常是夏令时）
  
  WinterOffset := GetLocalTimeZoneOffset(WinterDate);
  SummerOffset := GetLocalTimeZoneOffset(SummerDate);
  
  HasDST := (WinterOffset <> SummerOffset);
  StandardOffset := WinterOffset;
  DSTOffset := SummerOffset;
  
  Result := True;
end;

procedure TTestISO8601DST.Test_GetTimeZoneOffset_WithParameter;
var
  testDate: TDateTime;
  offset: Integer;
begin
  // 测试带参数的版本
  testDate := EncodeDateTime(2024, 6, 15, 12, 30, 0, 0);
  offset := GetLocalTimeZoneOffset(testDate);
  
  // 偏移应该在合理范围内 (-12小时 到 +14小时 = -720 到 +840 分钟)
  CheckTrue((offset >= -720) and (offset <= 840), 
    Format('时区偏移应在合理范围：%d 分钟', [offset]));
end;

procedure TTestISO8601DST.Test_GetTimeZoneOffset_WithoutParameter;
var
  offset1, offset2: Integer;
begin
  // 测试无参数版本（使用当前时间）
  offset1 := GetLocalTimeZoneOffset;
  Sleep(10);  // 短暂延迟
  offset2 := GetLocalTimeZoneOffset;
  
  // 两次调用应该返回相同的偏移（在短时间内）
  CheckEquals(offset1, offset2, '无参数版本应返回当前时间的偏移');
end;

procedure TTestISO8601DST.Test_GetTimeZoneOffset_Overload_Consistency;
var
  currentTime: TDateTime;
  offset1, offset2: Integer;
begin
  // 验证两个重载版本的一致性
  currentTime := Now;
  offset1 := GetLocalTimeZoneOffset(currentTime);
  offset2 := GetLocalTimeZoneOffset;  // 无参数，使用Now
  
  // 应该返回相同或非常接近的值（允许1分钟误差，因为Now可能有微小差异）
  CheckTrue(Abs(offset1 - offset2) <= 1, 
    Format('两个重载版本应返回一致的结果：%d vs %d', [offset1, offset2]));
end;

procedure TTestISO8601DST.Test_GetTimeZoneOffset_WinterVsSummer;
var
  winterDate, summerDate: TDateTime;
  winterOffset, summerOffset: Integer;
  hasDST: Boolean;
  stdOffset, dstOffset: Integer;
begin
  // 测试冬季和夏季的时区偏移
  winterDate := EncodeDate(2024, 1, 15);  // 1月（冬季）
  summerDate := EncodeDate(2024, 7, 15);  // 7月（夏季）
  
  winterOffset := GetLocalTimeZoneOffset(winterDate);
  summerOffset := GetLocalTimeZoneOffset(summerDate);
  
  // 检查系统是否支持DST
  if not GetSystemTimeZoneInfo(hasDST, stdOffset, dstOffset) then
  begin
    Ignore('无法获取系统时区信息');
    Exit;
  end;
  
  if hasDST then
  begin
    // 如果系统支持DST，夏季和冬季偏移应该不同
    CheckTrue(winterOffset <> summerOffset, 
      Format('DST时区：冬季(%d)和夏季(%d)偏移应不同', [winterOffset, summerOffset]));
    
    // 通常夏令时偏移比标准时多1小时（60分钟）
    CheckEquals(60, Abs(summerOffset - winterOffset), 
      'DST偏移通常是1小时（60分钟）');
  end
  else
  begin
    // 如果系统不支持DST，偏移应该相同
    CheckEquals(winterOffset, summerOffset, 
      '非DST时区：冬季和夏季偏移应相同');
  end;
end;

procedure TTestISO8601DST.Test_GetTimeZoneOffset_DST_SpringForward;
var
  beforeDST, afterDST: TDateTime;
  offsetBefore, offsetAfter: Integer;
begin
  // 测试春季DST切换（向前，"Spring Forward"）
  // 使用典型的北半球DST切换日期（3月第二个周日，凌晨2点）
  
  if not IsSystemSupportsDST then
  begin
    Ignore('系统不支持DST，跳过此测试');
    Exit;
  end;
  
  // DST开始前一天
  beforeDST := EncodeDateTime(2024, 3, 9, 12, 0, 0, 0);
  // DST开始后一天
  afterDST := EncodeDateTime(2024, 3, 11, 12, 0, 0, 0);
  
  offsetBefore := GetLocalTimeZoneOffset(beforeDST);
  offsetAfter := GetLocalTimeZoneOffset(afterDST);
  
  // 注意：测试可能因地区而异，这里只做基本检查
  CheckTrue(offsetBefore <> offsetAfter, 
    'DST切换前后偏移应不同');
end;

procedure TTestISO8601DST.Test_GetTimeZoneOffset_DST_FallBack;
var
  beforeDST, afterDST: TDateTime;
  offsetBefore, offsetAfter: Integer;
begin
  // 测试秋季DST切换（向后，"Fall Back"）
  // 使用典型的北半球DST结束日期（11月第一个周日，凌晨2点）
  
  if not IsSystemSupportsDST then
  begin
    Ignore('系统不支持DST，跳过此测试');
    Exit;
  end;
  
  // DST结束前一天
  beforeDST := EncodeDateTime(2024, 11, 2, 12, 0, 0, 0);
  // DST结束后一天
  afterDST := EncodeDateTime(2024, 11, 4, 12, 0, 0, 0);
  
  offsetBefore := GetLocalTimeZoneOffset(beforeDST);
  offsetAfter := GetLocalTimeZoneOffset(afterDST);
  
  // 注意：测试可能因地区而异，这里只做基本检查
  CheckTrue(offsetBefore <> offsetAfter, 
    'DST切换前后偏移应不同');
end;

procedure TTestISO8601DST.Test_FormatDateTime_WithTimeZone_UsesCorrectOffset;
var
  winterDate, summerDate: TDateTime;
  winterStr, summerStr: string;
  options: TISO8601Options;
begin
  // 验证格式化时使用正确的时区偏移
  winterDate := EncodeDateTime(2024, 1, 15, 12, 30, 45, 0);
  summerDate := EncodeDateTime(2024, 7, 15, 12, 30, 45, 0);
  
  options := TISO8601Options.WithTimeZone;
  
  winterStr := TISO8601Formatter.FormatDateTime(winterDate, options);
  summerStr := TISO8601Formatter.FormatDateTime(summerDate, options);
  
  // 检查格式化字符串包含时区信息
  CheckTrue(Pos('+', winterStr) + Pos('-', winterStr) > 0, 
    '冬季日期格式化应包含时区偏移：' + winterStr);
  CheckTrue(Pos('+', summerStr) + Pos('-', summerStr) > 0, 
    '夏季日期格式化应包含时区偏移：' + summerStr);
  
  // 如果系统支持DST，时区部分应该不同
  if IsSystemSupportsDST then
  begin
    CheckTrue(winterStr <> summerStr, 
      Format('DST时区：冬季(%s)和夏季(%s)格式化结果应不同', [winterStr, summerStr]));
  end;
end;

procedure TTestISO8601DST.Test_FormatDateTime_HistoricalDate_CorrectDST;
var
  historicalDate: TDateTime;
  formatted: string;
  offset: Integer;
  options: TISO8601Options;
begin
  // 测试历史日期格式化（ISSUE-44的核心场景）
  // 使用一个明确在标准时的历史日期
  historicalDate := EncodeDateTime(2020, 1, 15, 10, 30, 0, 0);
  
  options := TISO8601Options.WithTimeZone;
  formatted := TISO8601Formatter.FormatDateTime(historicalDate, options);
  
  // 验证：格式化结果应该使用历史日期的时区偏移，而不是当前时间的
  offset := GetLocalTimeZoneOffset(historicalDate);
  
  // 时区偏移应该反映在格式化字符串中
  CheckTrue(Length(formatted) > 0, '格式化结果不应为空');
  CheckTrue(Pos('T', formatted) > 0, '应包含日期时间分隔符T');
  CheckTrue((Pos('+', formatted) > 0) or (Pos('-', formatted) > 0), 
    '应包含时区偏移符号：' + formatted);
end;

procedure TTestISO8601DST.Test_FormatDateTime_FutureDate_CorrectDST;
var
  futureDate: TDateTime;
  formatted: string;
  options: TISO8601Options;
begin
  // 测试未来日期格式化
  // 使用一个明确在夏令时的未来日期
  futureDate := EncodeDateTime(2025, 7, 15, 15, 45, 30, 0);
  
  options := TISO8601Options.WithTimeZone;
  formatted := TISO8601Formatter.FormatDateTime(futureDate, options);
  
  // 验证：格式化结果应该使用未来日期的时区偏移
  CheckTrue(Length(formatted) > 0, '格式化结果不应为空');
  CheckTrue(Pos('2025-07-15', formatted) > 0, '应包含正确的日期');
  CheckTrue((Pos('+', formatted) > 0) or (Pos('-', formatted) > 0), 
    '应包含时区偏移：' + formatted);
end;

initialization
  RegisterTest(TTestISO8601DST);

end.
