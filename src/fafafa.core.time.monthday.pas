unit fafafa.core.time.monthday;

{**
  TMonthDay - 月日组合类型
  
  表示一年中的某一天，不含年份信息。适用于表示：
  - 纪念日（如圣诞节 12-25）
  - 生日（如 3-15）
  - 其他年度周期性事件
  
  格式采用 ISO 8601 扩展格式：--MM-DD
  
  @version 1.2.0
  @since 2024-12
*}

{$MODE OBJFPC}{$H+}
{$MODESWITCH ADVANCEDRECORDS}

interface

uses
  SysUtils,
  fafafa.core.time.date;

type
  { TMonthDay - 月日组合 }
  TMonthDay = record
  private
    FMonth: Integer;  // 1-12
    FDay: Integer;    // 1-31 (根据月份)
  public
    {** 创建月日组合
        @param AMonth 月份 (1-12)
        @param ADay 日期 (1-31, 根据月份最大值)
        @raises EArgumentException 如果月份或日期无效 *}
    class function Create(AMonth, ADay: Integer): TMonthDay; static;
    
    {** 从 TDate 提取月日部分 *}
    class function FromDate(const ADate: TDate): TMonthDay; static;
    
    // ========== 预定义常量 ==========
    
    {** 元旦 (1-1) *}
    class function NewYear: TMonthDay; static; inline;
    
    {** 圣诞节 (12-25) *}
    class function Christmas: TMonthDay; static; inline;
    
    {** 闰日 (2-29) *}
    class function LeapDay: TMonthDay; static; inline;
    
    {** 情人节 (2-14) *}
    class function Valentine: TMonthDay; static; inline;
    
    {** 万圣节 (10-31) *}
    class function Halloween: TMonthDay; static; inline;
    
    // ========== 属性 ==========
    
    {** 月份 (1-12) *}
    property Month: Integer read FMonth;
    
    {** 日期 (1-31) *}
    property Day: Integer read FDay;
    
    // ========== 年份映射 ==========
    
    {** 在指定年份创建完整日期
        @param AYear 年份
        @returns 完整日期
        @raises EArgumentException 如果日期在该年份无效（如非闰年的2-29）*}
    function AtYear(AYear: Integer): TDate;
    
    {** 检查此月日在指定年份是否有效
        @param AYear 年份
        @returns True 如果有效，False 如果无效（如非闰年的2-29）*}
    function IsValidInYear(AYear: Integer): Boolean;
    
    // ========== 比较运算符 ==========
    
    class operator = (const A, B: TMonthDay): Boolean; inline;
    class operator <> (const A, B: TMonthDay): Boolean; inline;
    class operator < (const A, B: TMonthDay): Boolean; inline;
    class operator <= (const A, B: TMonthDay): Boolean; inline;
    class operator > (const A, B: TMonthDay): Boolean; inline;
    class operator >= (const A, B: TMonthDay): Boolean; inline;
    
    // ========== 格式化 ==========
    
    {** 转换为 ISO 8601 格式字符串 (--MM-DD) *}
    function ToString: string;
    
    {** 从 ISO 8601 格式字符串解析 (--MM-DD)
        @param S 格式字符串
        @returns TMonthDay 实例
        @raises EConvertError 如果格式无效 *}
    class function Parse(const S: string): TMonthDay; static;
    
    {** 尝试从字符串解析
        @param S 格式字符串
        @param AResult 输出结果
        @returns True 如果解析成功 *}
    class function TryParse(const S: string; out AResult: TMonthDay): Boolean; static;
  end;

implementation

const
  // 每月最大天数（不考虑闰年）
  DAYS_IN_MONTH: array[1..12] of Integer = (
    31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
  );

{ TMonthDay }

class function TMonthDay.Create(AMonth, ADay: Integer): TMonthDay;
begin
  // 验证月份
  if (AMonth < 1) or (AMonth > 12) then
    raise EArgumentException.CreateFmt('Invalid month: %d (must be 1-12)', [AMonth]);
  
  // 验证日期（使用最大可能值，包括闰年二月）
  if (ADay < 1) or (ADay > DAYS_IN_MONTH[AMonth]) then
    raise EArgumentException.CreateFmt('Invalid day: %d for month %d (max %d)', 
      [ADay, AMonth, DAYS_IN_MONTH[AMonth]]);
  
  Result.FMonth := AMonth;
  Result.FDay := ADay;
end;

class function TMonthDay.FromDate(const ADate: TDate): TMonthDay;
begin
  Result.FMonth := ADate.GetMonth;
  Result.FDay := ADate.GetDay;
end;

class function TMonthDay.NewYear: TMonthDay;
begin
  Result.FMonth := 1;
  Result.FDay := 1;
end;

class function TMonthDay.Christmas: TMonthDay;
begin
  Result.FMonth := 12;
  Result.FDay := 25;
end;

class function TMonthDay.LeapDay: TMonthDay;
begin
  Result.FMonth := 2;
  Result.FDay := 29;
end;

class function TMonthDay.Valentine: TMonthDay;
begin
  Result.FMonth := 2;
  Result.FDay := 14;
end;

class function TMonthDay.Halloween: TMonthDay;
begin
  Result.FMonth := 10;
  Result.FDay := 31;
end;

function TMonthDay.AtYear(AYear: Integer): TDate;
begin
  if not IsValidInYear(AYear) then
    raise EArgumentException.CreateFmt('MonthDay --%0.2d-%0.2d is invalid in year %d', 
      [FMonth, FDay, AYear]);
  Result := TDate.Create(AYear, FMonth, FDay);
end;

function TMonthDay.IsValidInYear(AYear: Integer): Boolean;
var
  year: Integer;
begin
  // 特殊处理 2 月 29 日
  if (FMonth = 2) and (FDay = 29) then
  begin
    // 闰年判断逻辑
    year := AYear;
    Result := (year mod 4 = 0) and ((year mod 100 <> 0) or (year mod 400 = 0));
  end
  else
    Result := True;  // 其他所有日期在任何年份都有效
end;

class operator TMonthDay.= (const A, B: TMonthDay): Boolean;
begin
  Result := (A.FMonth = B.FMonth) and (A.FDay = B.FDay);
end;

class operator TMonthDay.<> (const A, B: TMonthDay): Boolean;
begin
  Result := not (A = B);
end;

class operator TMonthDay.< (const A, B: TMonthDay): Boolean;
begin
  if A.FMonth <> B.FMonth then
    Result := A.FMonth < B.FMonth
  else
    Result := A.FDay < B.FDay;
end;

class operator TMonthDay.<= (const A, B: TMonthDay): Boolean;
begin
  Result := (A < B) or (A = B);
end;

class operator TMonthDay.> (const A, B: TMonthDay): Boolean;
begin
  Result := B < A;
end;

class operator TMonthDay.>= (const A, B: TMonthDay): Boolean;
begin
  Result := (A > B) or (A = B);
end;

function TMonthDay.ToString: string;
begin
  // ISO 8601 格式: --MM-DD
  Result := Format('--%0.2d-%0.2d', [FMonth, FDay]);
end;

class function TMonthDay.Parse(const S: string): TMonthDay;
begin
  if not TryParse(S, Result) then
    raise EConvertError.CreateFmt('Invalid MonthDay format: "%s" (expected --MM-DD)', [S]);
end;

class function TMonthDay.TryParse(const S: string; out AResult: TMonthDay): Boolean;
var
  m, d: Integer;
begin
  Result := False;
  
  // 格式: --MM-DD (长度 7)
  if Length(S) <> 7 then Exit;
  if (S[1] <> '-') or (S[2] <> '-') or (S[5] <> '-') then Exit;
  
  // 解析月份
  if not TryStrToInt(Copy(S, 3, 2), m) then Exit;
  if (m < 1) or (m > 12) then Exit;
  
  // 解析日期
  if not TryStrToInt(Copy(S, 6, 2), d) then Exit;
  if (d < 1) or (d > DAYS_IN_MONTH[m]) then Exit;
  
  AResult.FMonth := m;
  AResult.FDay := d;
  Result := True;
end;

end.
