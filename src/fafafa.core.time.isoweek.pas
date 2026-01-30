unit fafafa.core.time.isoweek;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.isoweek - ISO 8601 周

📖 概述：
  提供 ISO 8601 周的表示和操作，对齐 Rust chrono::IsoWeek。
  ISO 周从周一开始，一年的第一周包含该年的第一个周四。

🔧 特性：
  • ISO 8601 周年和周号
  • 日期到 ISO 周的转换
  • ISO 周到日期的转换
  • 周算术（AddWeeks, WeeksUntil）

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
──────────────────────────────────────────────────────────────
}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.time.date;

type
  /// <summary>
  ///   TIsoWeek - ISO 8601 周
  ///   对齐 Rust chrono::IsoWeek 的设计。
  /// </summary>
  TIsoWeek = record
  private
    FYear: Integer;  // ISO 周年（可能与日历年不同）
    FWeek: Integer;  // 周号 1-53
    
    class function GetIsoWeekYear(AJulianDay: Integer): Integer; static;
    class function GetIsoWeekNumber(AJulianDay: Integer): Integer; static;
    class function GetWeek1Monday(AYear: Integer): Integer; static; // 返回 Julian Day
  public
    // ═══════════════════════════════════════════════════════════════
    // 构造函数
    // ═══════════════════════════════════════════════════════════════
    
    class function Create(AYear, AWeek: Integer): TIsoWeek; static;
    class function FromDate(const ADate: TDate): TIsoWeek; static;
    
    // ═══════════════════════════════════════════════════════════════
    // 访问器
    // ═══════════════════════════════════════════════════════════════
    
    function GetYear: Integer; inline;
    function GetWeek: Integer; inline;
    
    property Year: Integer read GetYear;
    property Week: Integer read GetWeek;
    
    // ═══════════════════════════════════════════════════════════════
    // 日期计算
    // ═══════════════════════════════════════════════════════════════
    
    /// <summary>返回本周的周一</summary>
    function Monday: TDate;
    
    /// <summary>返回本周的周日</summary>
    function Sunday: TDate;
    
    /// <summary>返回本周指定的某一天（1=周一, 7=周日）</summary>
    function DayOfWeek(ADayNum: Integer): TDate;
    
    // ═══════════════════════════════════════════════════════════════
    // 周算术
    // ═══════════════════════════════════════════════════════════════
    
    function AddWeeks(AWeeks: Integer): TIsoWeek;
    function WeeksUntil(const AOther: TIsoWeek): Integer;
    
    // ═══════════════════════════════════════════════════════════════
    // 格式化与解析
    // ═══════════════════════════════════════════════════════════════
    
    function ToISO8601: string;
    class function TryParse(const AStr: string; out AWeek: TIsoWeek): Boolean; static;
    function ToString: string;
    
    // ═══════════════════════════════════════════════════════════════
    // 比较运算符
    // ═══════════════════════════════════════════════════════════════
    
    class operator =(const A, B: TIsoWeek): Boolean; inline;
    class operator <>(const A, B: TIsoWeek): Boolean; inline;
    class operator <(const A, B: TIsoWeek): Boolean; inline;
    class operator >(const A, B: TIsoWeek): Boolean; inline;
    class operator <=(const A, B: TIsoWeek): Boolean; inline;
    class operator >=(const A, B: TIsoWeek): Boolean; inline;
  end;

implementation

{ TIsoWeek }

// 计算指定年份 ISO 第一周的周一的 Julian Day
class function TIsoWeek.GetWeek1Monday(AYear: Integer): Integer;
var
  LJan4: Integer;
  LDayOfWeek: Integer;
begin
  // ISO 8601: 第一周包含该年的第一个周四
  // 等价于：第一周包含 1 月 4 日
  // 所以第一周的周一 = 1月4日 - (1月4日的星期几 - 1)
  LJan4 := TDate.Create(AYear, 1, 4).ToJulianDay;
  // TDate.GetDayOfWeek: 1=Sunday, 7=Saturday
  // ISO: 1=Monday, 7=Sunday
  // 需要转换: Sunday(1) -> 7, Monday(2) -> 1, ...
  LDayOfWeek := TDate.FromJulianDay(LJan4).GetDayOfWeek;
  // 转换为 ISO 格式（1=周一，7=周日）
  if LDayOfWeek = 1 then
    LDayOfWeek := 7
  else
    Dec(LDayOfWeek);
  
  // 周一 = Jan4 - (ISO日期 - 1)
  Result := LJan4 - (LDayOfWeek - 1);
end;

class function TIsoWeek.GetIsoWeekYear(AJulianDay: Integer): Integer;
var
  LDate: TDate;
  LYear: Integer;
  LWeek1Monday: Integer;
begin
  LDate := TDate.FromJulianDay(AJulianDay);
  LYear := LDate.GetYear;
  
  // 检查是否属于下一年的第一周
  LWeek1Monday := GetWeek1Monday(LYear + 1);
  if AJulianDay >= LWeek1Monday then
    Exit(LYear + 1);
  
  // 检查是否属于当年
  LWeek1Monday := GetWeek1Monday(LYear);
  if AJulianDay >= LWeek1Monday then
    Exit(LYear);
  
  // 属于上一年
  Exit(LYear - 1);
end;

class function TIsoWeek.GetIsoWeekNumber(AJulianDay: Integer): Integer;
var
  LIsoYear: Integer;
  LWeek1Monday: Integer;
begin
  LIsoYear := GetIsoWeekYear(AJulianDay);
  LWeek1Monday := GetWeek1Monday(LIsoYear);
  Result := (AJulianDay - LWeek1Monday) div 7 + 1;
end;

class function TIsoWeek.Create(AYear, AWeek: Integer): TIsoWeek;
begin
  Result.FYear := AYear;
  Result.FWeek := AWeek;
end;

class function TIsoWeek.FromDate(const ADate: TDate): TIsoWeek;
var
  LJulianDay: Integer;
begin
  LJulianDay := ADate.ToJulianDay;
  Result.FYear := GetIsoWeekYear(LJulianDay);
  Result.FWeek := GetIsoWeekNumber(LJulianDay);
end;

function TIsoWeek.GetYear: Integer;
begin
  Result := FYear;
end;

function TIsoWeek.GetWeek: Integer;
begin
  Result := FWeek;
end;

function TIsoWeek.Monday: TDate;
var
  LWeek1Monday: Integer;
begin
  LWeek1Monday := GetWeek1Monday(FYear);
  Result := TDate.FromJulianDay(LWeek1Monday + (FWeek - 1) * 7);
end;

function TIsoWeek.Sunday: TDate;
begin
  Result := Monday.AddDays(6);
end;

function TIsoWeek.DayOfWeek(ADayNum: Integer): TDate;
begin
  // ADayNum: 1=周一, 7=周日
  Result := Monday.AddDays(ADayNum - 1);
end;

function TIsoWeek.AddWeeks(AWeeks: Integer): TIsoWeek;
var
  LMonday: TDate;
  LNewDate: TDate;
begin
  LMonday := Self.Monday;
  LNewDate := LMonday.AddDays(AWeeks * 7);
  Result := TIsoWeek.FromDate(LNewDate);
end;

function TIsoWeek.WeeksUntil(const AOther: TIsoWeek): Integer;
var
  LThisMonday, LOtherMonday: Integer;
begin
  LThisMonday := Self.Monday.ToJulianDay;
  LOtherMonday := AOther.Monday.ToJulianDay;
  Result := (LOtherMonday - LThisMonday) div 7;
end;

function TIsoWeek.ToISO8601: string;
begin
  Result := Format('%.4d-W%.2d', [FYear, FWeek]);
end;

class function TIsoWeek.TryParse(const AStr: string; out AWeek: TIsoWeek): Boolean;
var
  LYear, LWeekNum: Integer;
begin
  Result := False;
  AWeek.FYear := 0;
  AWeek.FWeek := 0;
  
  // 格式: YYYY-Www
  if Length(AStr) < 8 then
    Exit;
  
  if not TryStrToInt(Copy(AStr, 1, 4), LYear) then
    Exit;
  
  if Copy(AStr, 5, 2) <> '-W' then
    Exit;
  
  if not TryStrToInt(Copy(AStr, 7, 2), LWeekNum) then
    Exit;
  
  if (LWeekNum < 1) or (LWeekNum > 53) then
    Exit;
  
  AWeek.FYear := LYear;
  AWeek.FWeek := LWeekNum;
  Result := True;
end;

function TIsoWeek.ToString: string;
begin
  Result := ToISO8601;
end;

class operator TIsoWeek.=(const A, B: TIsoWeek): Boolean;
begin
  Result := (A.FYear = B.FYear) and (A.FWeek = B.FWeek);
end;

class operator TIsoWeek.<>(const A, B: TIsoWeek): Boolean;
begin
  Result := (A.FYear <> B.FYear) or (A.FWeek <> B.FWeek);
end;

class operator TIsoWeek.<(const A, B: TIsoWeek): Boolean;
begin
  if A.FYear <> B.FYear then
    Result := A.FYear < B.FYear
  else
    Result := A.FWeek < B.FWeek;
end;

class operator TIsoWeek.>(const A, B: TIsoWeek): Boolean;
begin
  if A.FYear <> B.FYear then
    Result := A.FYear > B.FYear
  else
    Result := A.FWeek > B.FWeek;
end;

class operator TIsoWeek.<=(const A, B: TIsoWeek): Boolean;
begin
  Result := not (A > B);
end;

class operator TIsoWeek.>=(const A, B: TIsoWeek): Boolean;
begin
  Result := not (A < B);
end;

end.
