unit fafafa.core.time.date;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.date - 日期类型和操作

📖 概述：
  提供现代化的日期类型和相关操作，支持日期算术、比较、格式化等功能。
  基于公历系统，提供高精度和类型安全的日期处理。

🔧 特性：
  • 类型安全的日期表示
  • 丰富的日期算术运算
  • 日期比较和排序
  • 日期范围和区间
  • 与标准 TDateTime 的互操作

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
──────────────────────────────────────────────────────────────
}

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  DateUtils,
  fafafa.core.time.base;

type
  {**
   * TDate - 日期类型
   *
   * @desc
   *   表示公历日期的记录类型，提供类型安全的日期操作。
   *   内部使用 Julian Day Number 存储，确保计算的准确性。
   *
   * @precision
   *   日级精度，不包含时间信息。
   *
   * @thread_safety
   *   值类型，天然线程安全。
   *
   * @range
   *   支持公元前 4713 年到公元后 3268 年的日期范围。
   *}
  TDate = record
  private
    FJulianDay: Integer; // Julian Day Number
    
    class function IsValidDate(AYear, AMonth, ADay: Integer): Boolean; static;
    class function DateToJulianDay(AYear, AMonth, ADay: Integer): Integer; static;
    class procedure JulianDayToDate(AJulianDay: Integer; out AYear, AMonth, ADay: Integer); static;
  public
    // 构造函数
    class function Create(AYear, AMonth, ADay: Integer): TDate; static;
    class function FromJulianDay(AJulianDay: Integer): TDate; static;
    class function FromDateTime(const ADateTime: TDateTime): TDate; static;
    class function FromUnixDays(AUnixDays: Integer): TDate; static; // 自 1970-01-01 的天数
    class function Today: TDate; static;
    class function Yesterday: TDate; static;
    class function Tomorrow: TDate; static;
    
    // 安全构造函数
    class function TryCreate(AYear, AMonth, ADay: Integer; out ADate: TDate): Boolean; static;
    class function TryFromDateTime(const ADateTime: TDateTime; out ADate: TDate): Boolean; static;
    class function TryParse(const ADateStr: string; out ADate: TDate): Boolean; static;
    class function TryParseISO(const ADateStr: string; out ADate: TDate): Boolean; static;
    
    // 常量
    class function MinValue: TDate; static; // 最小日期
    class function MaxValue: TDate; static; // 最大日期
    class function Epoch: TDate; static; // Unix 纪元 (1970-01-01)
    
    // 转换函数
    function ToJulianDay: Integer; inline;
    function ToDateTime: TDateTime;
    function ToUnixDays: Integer; // 自 1970-01-01 的天数
    function ToISO8601: string; // YYYY-MM-DD 格式
    
    // 日期组件
    function GetYear: Integer;
    function GetMonth: Integer;
    function GetDay: Integer;
    function GetDayOfWeek: Integer; // 1=Sunday, 7=Saturday
    function GetDayOfYear: Integer;
    function GetWeekOfYear: Integer;
    function GetQuarter: Integer;
    
    // 日期算术
    function AddDays(ADays: Integer): TDate; inline;
    function AddWeeks(AWeeks: Integer): TDate; inline;
    function AddMonths(AMonths: Integer): TDate;
    function AddYears(AYears: Integer): TDate;
    function SubtractDays(ADays: Integer): TDate; inline;
    function SubtractWeeks(AWeeks: Integer): TDate; inline;
    function SubtractMonths(AMonths: Integer): TDate;
    function SubtractYears(AYears: Integer): TDate;
    
    // 日期差值
    function DaysBetween(const AOther: TDate): Integer; inline;
    function WeeksBetween(const AOther: TDate): Integer;
    function MonthsBetween(const AOther: TDate): Integer;
    function YearsBetween(const AOther: TDate): Integer;
    function DaysUntil(const AOther: TDate): Integer; inline; // 到另一个日期的天数
    function DaysSince(const AOther: TDate): Integer; inline; // 自另一个日期的天数
    
    // 比较操作
    function Compare(const AOther: TDate): Integer; inline;
    function Equal(const AOther: TDate): Boolean; inline;
    function LessThan(const AOther: TDate): Boolean; inline;
    function LessOrEqual(const AOther: TDate): Boolean; inline;
    function GreaterThan(const AOther: TDate): Boolean; inline;
    function GreaterOrEqual(const AOther: TDate): Boolean; inline;
    function IsBetween(const AStart, AEnd: TDate): Boolean; inline;
    
    // 工具函数
    function IsLeapYear: Boolean;
    function DaysInMonth: Integer;
    function DaysInYear: Integer;
    function IsWeekend: Boolean;
    function IsFirstDayOfMonth: Boolean; inline;
    function IsLastDayOfMonth: Boolean;
    function IsFirstDayOfYear: Boolean; inline;
    function IsLastDayOfYear: Boolean;
    
    // 日期范围
    function StartOfWeek: TDate; // 本周第一天（周日）
    function EndOfWeek: TDate; // 本周最后一天（周六）
    function StartOfMonth: TDate; // 本月第一天
    function EndOfMonth: TDate; // 本月最后一天
    function StartOfQuarter: TDate; // 本季度第一天
    function EndOfQuarter: TDate; // 本季度最后一天
    function StartOfYear: TDate; // 本年第一天
    function EndOfYear: TDate; // 本年最后一天
    
    // 工具方法
    function Clamp(const AMin, AMax: TDate): TDate; inline;
    class function Min(const A, B: TDate): TDate; static; inline;
    class function Max(const A, B: TDate): TDate; static; inline;
    
    // 运算符重载
    class operator +(const ADate: TDate; ADays: Integer): TDate; inline;
    class operator -(const ADate: TDate; ADays: Integer): TDate; inline;
    class operator -(const A, B: TDate): Integer; inline; // 返回天数差
    class operator =(const A, B: TDate): Boolean; inline;
    class operator <>(const A, B: TDate): Boolean; inline;
    class operator <(const A, B: TDate): Boolean; inline;
    class operator >(const A, B: TDate): Boolean; inline;
    class operator <=(const A, B: TDate): Boolean; inline;
    class operator >=(const A, B: TDate): Boolean; inline;
    
    // 字符串表示
    function ToString: string; overload;
    function ToString(const AFormat: string): string; overload;
    function ToShortString: string; // 简短格式
    function ToLongString: string; // 详细格式
  end;

  {**
   * TDateRange - 日期范围
   *
   * @desc
   *   表示一个日期范围，包含开始日期和结束日期。
   *   提供范围相关的操作和查询功能。
   *
   * @thread_safety
   *   值类型，天然线程安全。
   *}
  TDateRange = record
  private
    FStartDate: TDate;
    FEndDate: TDate;
  public
    // 构造函数
    class function Create(const AStart, AEnd: TDate): TDateRange; static;
    class function CreateDays(const AStart: TDate; ADays: Integer): TDateRange; static;
    class function CreateWeeks(const AStart: TDate; AWeeks: Integer): TDateRange; static;
    class function CreateMonths(const AStart: TDate; AMonths: Integer): TDateRange; static;
    class function CreateYears(const AStart: TDate; AYears: Integer): TDateRange; static;
    
    // 属性
    function GetStartDate: TDate; inline;
    function GetEndDate: TDate; inline;
    function GetDuration: Integer; inline; // 天数
    
    // 查询操作
    function Contains(const ADate: TDate): Boolean; inline;
    function Overlaps(const AOther: TDateRange): Boolean;
    function IsEmpty: Boolean; inline;
    function IsValid: Boolean; inline;
    
    // 范围操作
    function Union(const AOther: TDateRange): TDateRange;
    function Intersection(const AOther: TDateRange): TDateRange;
    function Extend(ADays: Integer): TDateRange;
    function Shift(ADays: Integer): TDateRange;
    
    // 迭代支持
    function GetEnumerator: TDateRangeEnumerator;
    
    // 字符串表示
    function ToString: string;
  end;

  // 日期范围枚举器
  TDateRangeEnumerator = record
  private
    FRange: TDateRange;
    FCurrent: TDate;
    FStarted: Boolean;
  public
    constructor Create(const ARange: TDateRange);
    function MoveNext: Boolean;
    function GetCurrent: TDate; inline;
    property Current: TDate read GetCurrent;
  end;

// 便捷函数
function DateOf(AYear, AMonth, ADay: Integer): TDate; inline;
function Today: TDate; inline;
function Yesterday: TDate; inline;
function Tomorrow: TDate; inline;

// 日期解析
function ParseDate(const ADateStr: string): TDate;
function ParseDateISO(const ADateStr: string): TDate; // ISO 8601 格式
function TryParseDate(const ADateStr: string; out ADate: TDate): Boolean;
function TryParseDateISO(const ADateStr: string; out ADate: TDate): Boolean;

// 日期格式化
function FormatDate(const ADate: TDate; const AFormat: string): string;

// 日期常量
const
  JULIAN_DAY_EPOCH = 2440588; // 1970-01-01 的 Julian Day Number
  DAYS_PER_WEEK = 7;
  MONTHS_PER_YEAR = 12;
  QUARTERS_PER_YEAR = 4;

implementation

const
  // 每月天数（非闰年）
  DAYS_IN_MONTH: array[1..12] of Integer = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);

{ TDate }

class function TDate.IsValidDate(AYear, AMonth, ADay: Integer): Boolean;
begin
  Result := (AYear >= 1) and (AYear <= 9999) and
            (AMonth >= 1) and (AMonth <= 12) and
            (ADay >= 1);
  
  if Result then
  begin
    if AMonth = 2 then
    begin
      if IsLeapYear(AYear) then
        Result := ADay <= 29
      else
        Result := ADay <= 28;
    end
    else
      Result := ADay <= DAYS_IN_MONTH[AMonth];
  end;
end;

class function TDate.DateToJulianDay(AYear, AMonth, ADay: Integer): Integer;
var
  a, y, m: Integer;
begin
  // 使用标准的 Julian Day Number 算法
  a := (14 - AMonth) div 12;
  y := AYear + 4800 - a;
  m := AMonth + 12 * a - 3;
  
  Result := ADay + (153 * m + 2) div 5 + 365 * y + y div 4 - y div 100 + y div 400 - 32045;
end;

class procedure TDate.JulianDayToDate(AJulianDay: Integer; out AYear, AMonth, ADay: Integer);
var
  a, b, c, d, e, m: Integer;
begin
  // 使用标准的 Julian Day Number 逆算法
  a := AJulianDay + 32044;
  b := (4 * a + 3) div 146097;
  c := a - (146097 * b) div 4;
  d := (4 * c + 3) div 1461;
  e := c - (1461 * d) div 4;
  m := (5 * e + 2) div 153;
  
  ADay := e - (153 * m + 2) div 5 + 1;
  AMonth := m + 3 - 12 * (m div 10);
  AYear := 100 * b + d - 4800 + m div 10;
end;

class function TDate.Create(AYear, AMonth, ADay: Integer): TDate;
begin
  if not IsValidDate(AYear, AMonth, ADay) then
    raise ETimeError.CreateFmt('Invalid date: %d-%d-%d', [AYear, AMonth, ADay]);
  
  Result.FJulianDay := DateToJulianDay(AYear, AMonth, ADay);
end;

class function TDate.FromJulianDay(AJulianDay: Integer): TDate;
begin
  Result.FJulianDay := AJulianDay;
end;

class function TDate.FromDateTime(const ADateTime: TDateTime): TDate;
var
  year, month, day: Word;
begin
  DecodeDate(ADateTime, year, month, day);
  Result := Create(year, month, day);
end;

class function TDate.FromUnixDays(AUnixDays: Integer): TDate;
begin
  Result.FJulianDay := JULIAN_DAY_EPOCH + AUnixDays;
end;

class function TDate.Today: TDate;
begin
  Result := FromDateTime(Date);
end;

class function TDate.Yesterday: TDate;
begin
  Result := Today.AddDays(-1);
end;

class function TDate.Tomorrow: TDate;
begin
  Result := Today.AddDays(1);
end;

class function TDate.TryCreate(AYear, AMonth, ADay: Integer; out ADate: TDate): Boolean;
begin
  Result := IsValidDate(AYear, AMonth, ADay);
  if Result then
    ADate.FJulianDay := DateToJulianDay(AYear, AMonth, ADay);
end;

class function TDate.TryFromDateTime(const ADateTime: TDateTime; out ADate: TDate): Boolean;
var
  year, month, day: Word;
begin
  try
    DecodeDate(ADateTime, year, month, day);
    Result := TryCreate(year, month, day, ADate);
  except
    Result := False;
  end;
end;

class function TDate.MinValue: TDate;
begin
  Result := Create(1, 1, 1);
end;

class function TDate.MaxValue: TDate;
begin
  Result := Create(9999, 12, 31);
end;

class function TDate.Epoch: TDate;
begin
  Result := Create(1970, 1, 1);
end;

function TDate.ToJulianDay: Integer;
begin
  Result := FJulianDay;
end;

function TDate.ToDateTime: TDateTime;
var
  year, month, day: Integer;
begin
  JulianDayToDate(FJulianDay, year, month, day);
  Result := EncodeDate(year, month, day);
end;

function TDate.ToUnixDays: Integer;
begin
  Result := FJulianDay - JULIAN_DAY_EPOCH;
end;

function TDate.ToISO8601: string;
var
  year, month, day: Integer;
begin
  JulianDayToDate(FJulianDay, year, month, day);
  Result := Format('%04d-%02d-%02d', [year, month, day]);
end;

function TDate.GetYear: Integer;
var
  month, day: Integer;
begin
  JulianDayToDate(FJulianDay, Result, month, day);
end;

function TDate.GetMonth: Integer;
var
  year, day: Integer;
begin
  JulianDayToDate(FJulianDay, year, Result, day);
end;

function TDate.GetDay: Integer;
var
  year, month: Integer;
begin
  JulianDayToDate(FJulianDay, year, month, Result);
end;

function TDate.GetDayOfWeek: Integer;
begin
  // Julian Day Number 0 是周一，我们需要转换为周日=1的格式
  Result := ((FJulianDay + 1) mod 7) + 1;
end;

function TDate.AddDays(ADays: Integer): TDate;
begin
  Result.FJulianDay := FJulianDay + ADays;
end;

function TDate.AddWeeks(AWeeks: Integer): TDate;
begin
  Result := AddDays(AWeeks * 7);
end;

function TDate.DaysBetween(const AOther: TDate): Integer;
begin
  Result := Abs(FJulianDay - AOther.FJulianDay);
end;

function TDate.DaysUntil(const AOther: TDate): Integer;
begin
  Result := AOther.FJulianDay - FJulianDay;
end;

function TDate.DaysSince(const AOther: TDate): Integer;
begin
  Result := FJulianDay - AOther.FJulianDay;
end;

function TDate.Compare(const AOther: TDate): Integer;
begin
  if FJulianDay < AOther.FJulianDay then
    Result := -1
  else if FJulianDay > AOther.FJulianDay then
    Result := 1
  else
    Result := 0;
end;

function TDate.Equal(const AOther: TDate): Boolean;
begin
  Result := FJulianDay = AOther.FJulianDay;
end;

function TDate.LessThan(const AOther: TDate): Boolean;
begin
  Result := FJulianDay < AOther.FJulianDay;
end;

function TDate.GreaterThan(const AOther: TDate): Boolean;
begin
  Result := FJulianDay > AOther.FJulianDay;
end;

function TDate.IsLeapYear: Boolean;
var
  year: Integer;
begin
  year := GetYear;
  Result := (year mod 4 = 0) and ((year mod 100 <> 0) or (year mod 400 = 0));
end;

function TDate.ToString: string;
begin
  Result := ToISO8601;
end;

// 运算符重载

class operator TDate.+(const ADate: TDate; ADays: Integer): TDate;
begin
  Result := ADate.AddDays(ADays);
end;

class operator TDate.-(const ADate: TDate; ADays: Integer): TDate;
begin
  Result := ADate.AddDays(-ADays);
end;

class operator TDate.-(const A, B: TDate): Integer;
begin
  Result := A.DaysUntil(B);
end;

class operator TDate.=(const A, B: TDate): Boolean;
begin
  Result := A.Equal(B);
end;

class operator TDate.<(const A, B: TDate): Boolean;
begin
  Result := A.LessThan(B);
end;

class operator TDate.>(const A, B: TDate): Boolean;
begin
  Result := A.GreaterThan(B);
end;

// 便捷函数

function DateOf(AYear, AMonth, ADay: Integer): TDate;
begin
  Result := TDate.Create(AYear, AMonth, ADay);
end;

function Today: TDate;
begin
  Result := TDate.Today;
end;

function Yesterday: TDate;
begin
  Result := TDate.Yesterday;
end;

function Tomorrow: TDate;
begin
  Result := TDate.Tomorrow;
end;

// 实现细节将在后续添加...

end.
