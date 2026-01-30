unit fafafa.core.time.yearmonth;

{**
  TYearMonth - 年月组合类型
  
  表示一个特定的年月，不含日期信息。适用于：
  - 月度报表（如 "2024年3月报告"）
  - 账单周期
  - 信用卡有效期
  - 任何按月组织的数据
  
  格式采用 ISO 8601 格式：YYYY-MM
  
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
  { TYearMonth - 年月组合 }
  TYearMonth = record
  private
    FYear: Integer;
    FMonth: Integer;  // 1-12
    
    class function DaysInMonthInternal(AYear, AMonth: Integer): Integer; static; inline;
  public
    {** 创建年月组合
        @param AYear 年份
        @param AMonth 月份 (1-12)
        @raises EArgumentException 如果月份无效 *}
    class function Create(AYear, AMonth: Integer): TYearMonth; static;
    
    {** 从 TDate 提取年月部分 *}
    class function FromDate(const ADate: TDate): TYearMonth; static;
    
    {** 当前年月 *}
    class function Now: TYearMonth; static;
    
    // ========== 属性 ==========
    
    {** 年份 *}
    property Year: Integer read FYear;
    
    {** 月份 (1-12) *}
    property Month: Integer read FMonth;
    
    // ========== 日期映射 ==========
    
    {** 在指定日创建完整日期
        @param ADay 日期 (1-31, 根据月份)
        @returns 完整日期
        @raises EArgumentException 如果日期在该月无效 *}
    function AtDay(ADay: Integer): TDate;
    
    {** 获取月初日期 *}
    function FirstDay: TDate; inline;
    
    {** 获取月末日期 *}
    function AtEndOfMonth: TDate;
    
    {** 获取此年月的天数 *}
    function DaysInMonth: Integer; inline;
    
    {** 检查是否为闰年 *}
    function IsLeapYear: Boolean; inline;
    
    // ========== 算术运算 ==========
    
    {** 添加月份
        @param N 要添加的月数（可为负）
        @returns 新的 TYearMonth *}
    function AddMonths(N: Integer): TYearMonth;
    
    {** 减少月份
        @param N 要减少的月数
        @returns 新的 TYearMonth *}
    function SubMonths(N: Integer): TYearMonth; inline;
    
    {** 添加年份
        @param N 要添加的年数（可为负）
        @returns 新的 TYearMonth *}
    function AddYears(N: Integer): TYearMonth; inline;
    
    {** 减少年份
        @param N 要减少的年数
        @returns 新的 TYearMonth *}
    function SubYears(N: Integer): TYearMonth; inline;
    
    {** 下一个月 *}
    function Next: TYearMonth; inline;
    
    {** 上一个月 *}
    function Prev: TYearMonth; inline;
    
    // ========== 比较运算符 ==========
    
    class operator = (const A, B: TYearMonth): Boolean; inline;
    class operator <> (const A, B: TYearMonth): Boolean; inline;
    class operator < (const A, B: TYearMonth): Boolean; inline;
    class operator <= (const A, B: TYearMonth): Boolean; inline;
    class operator > (const A, B: TYearMonth): Boolean; inline;
    class operator >= (const A, B: TYearMonth): Boolean; inline;
    
    // ========== 格式化 ==========
    
    {** 转换为 ISO 8601 格式字符串 (YYYY-MM) *}
    function ToString: string;
    
    {** 从 ISO 8601 格式字符串解析 (YYYY-MM)
        @param S 格式字符串
        @returns TYearMonth 实例
        @raises EConvertError 如果格式无效 *}
    class function Parse(const S: string): TYearMonth; static;
    
    {** 尝试从字符串解析
        @param S 格式字符串
        @param AResult 输出结果
        @returns True 如果解析成功 *}
    class function TryParse(const S: string; out AResult: TYearMonth): Boolean; static;
  end;

implementation

const
  // 每月天数（非闰年）
  DAYS_PER_MONTH: array[1..12] of Integer = (
    31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
  );

{ TYearMonth }

class function TYearMonth.DaysInMonthInternal(AYear, AMonth: Integer): Integer;
begin
  Result := DAYS_PER_MONTH[AMonth];
  // 闰年二月加一天
  if (AMonth = 2) and ((AYear mod 4 = 0) and ((AYear mod 100 <> 0) or (AYear mod 400 = 0))) then
    Inc(Result);
end;

class function TYearMonth.Create(AYear, AMonth: Integer): TYearMonth;
begin
  if (AMonth < 1) or (AMonth > 12) then
    raise EArgumentException.CreateFmt('Invalid month: %d (must be 1-12)', [AMonth]);
  
  Result.FYear := AYear;
  Result.FMonth := AMonth;
end;

class function TYearMonth.FromDate(const ADate: TDate): TYearMonth;
begin
  Result.FYear := ADate.GetYear;
  Result.FMonth := ADate.GetMonth;
end;

class function TYearMonth.Now: TYearMonth;
var
  today: TDate;
begin
  today := TDate.Today;
  Result.FYear := today.GetYear;
  Result.FMonth := today.GetMonth;
end;

function TYearMonth.AtDay(ADay: Integer): TDate;
var
  maxDay: Integer;
begin
  maxDay := DaysInMonthInternal(FYear, FMonth);
  if (ADay < 1) or (ADay > maxDay) then
    raise EArgumentException.CreateFmt('Invalid day: %d for %d-%0.2d (max %d)', 
      [ADay, FYear, FMonth, maxDay]);
  Result := TDate.Create(FYear, FMonth, ADay);
end;

function TYearMonth.FirstDay: TDate;
begin
  Result := TDate.Create(FYear, FMonth, 1);
end;

function TYearMonth.AtEndOfMonth: TDate;
begin
  Result := TDate.Create(FYear, FMonth, DaysInMonthInternal(FYear, FMonth));
end;

function TYearMonth.DaysInMonth: Integer;
begin
  Result := DaysInMonthInternal(FYear, FMonth);
end;

function TYearMonth.IsLeapYear: Boolean;
begin
  // 闰年判断逻辑
  Result := (FYear mod 4 = 0) and ((FYear mod 100 <> 0) or (FYear mod 400 = 0));
end;

function TYearMonth.AddMonths(N: Integer): TYearMonth;
var
  totalMonths: Integer;
begin
  // 将年月转换为从公元0年开始的总月数
  totalMonths := FYear * 12 + (FMonth - 1) + N;
  
  // 处理负数情况
  if totalMonths < 0 then
  begin
    // 调整为正数，确保正确计算年份
    Result.FYear := (totalMonths div 12) - 1;
    Result.FMonth := totalMonths - (Result.FYear * 12) + 1;
  end
  else
  begin
    Result.FYear := totalMonths div 12;
    Result.FMonth := (totalMonths mod 12) + 1;
  end;
end;

function TYearMonth.SubMonths(N: Integer): TYearMonth;
begin
  Result := AddMonths(-N);
end;

function TYearMonth.AddYears(N: Integer): TYearMonth;
begin
  Result.FYear := FYear + N;
  Result.FMonth := FMonth;
end;

function TYearMonth.SubYears(N: Integer): TYearMonth;
begin
  Result := AddYears(-N);
end;

function TYearMonth.Next: TYearMonth;
begin
  Result := AddMonths(1);
end;

function TYearMonth.Prev: TYearMonth;
begin
  Result := AddMonths(-1);
end;

class operator TYearMonth.= (const A, B: TYearMonth): Boolean;
begin
  Result := (A.FYear = B.FYear) and (A.FMonth = B.FMonth);
end;

class operator TYearMonth.<> (const A, B: TYearMonth): Boolean;
begin
  Result := not (A = B);
end;

class operator TYearMonth.< (const A, B: TYearMonth): Boolean;
begin
  if A.FYear <> B.FYear then
    Result := A.FYear < B.FYear
  else
    Result := A.FMonth < B.FMonth;
end;

class operator TYearMonth.<= (const A, B: TYearMonth): Boolean;
begin
  Result := (A < B) or (A = B);
end;

class operator TYearMonth.> (const A, B: TYearMonth): Boolean;
begin
  Result := B < A;
end;

class operator TYearMonth.>= (const A, B: TYearMonth): Boolean;
begin
  Result := (A > B) or (A = B);
end;

function TYearMonth.ToString: string;
begin
  Result := Format('%d-%0.2d', [FYear, FMonth]);
end;

class function TYearMonth.Parse(const S: string): TYearMonth;
begin
  if not TryParse(S, Result) then
    raise EConvertError.CreateFmt('Invalid YearMonth format: "%s" (expected YYYY-MM)', [S]);
end;

class function TYearMonth.TryParse(const S: string; out AResult: TYearMonth): Boolean;
var
  dashPos: Integer;
  y, m: Integer;
begin
  Result := False;
  
  // 查找分隔符
  dashPos := Pos('-', S);
  if dashPos < 2 then Exit;  // 至少要有一位年份
  
  // 解析年份
  if not TryStrToInt(Copy(S, 1, dashPos - 1), y) then Exit;
  
  // 解析月份
  if not TryStrToInt(Copy(S, dashPos + 1, Length(S) - dashPos), m) then Exit;
  if (m < 1) or (m > 12) then Exit;
  
  AResult.FYear := y;
  AResult.FMonth := m;
  Result := True;
end;

end.
