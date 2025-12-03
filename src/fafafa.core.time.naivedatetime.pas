unit fafafa.core.time.naivedatetime;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.naivedatetime - 无时区日期时间

📖 概述：
  提供不带时区信息的日期时间类型，对齐 Rust chrono::NaiveDateTime。
  适用于表示本地时间或不需要时区概念的场景。

🔧 特性：
  • 无时区日期时间表示
  • 日期时间算术（AddDays, AddDuration）
  • ISO 8601 格式化与解析
  • 纳秒精度 (v1.2.0 升级)

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
  DateUtils,
  fafafa.core.time.date,
  fafafa.core.time.timeofday,
  fafafa.core.time.duration;

type
  /// <summary>
  ///   TNaiveDateTime - 无时区信息的日期时间类型
  ///   对齐 Rust chrono::NaiveDateTime 的设计。
  /// </summary>
  TNaiveDateTime = record
  private
    FDate: TDate;
    FNanosOfDay: Int64;  // 0 to 86_399_999_999_999 (纳秒精度)
    
    // 内部：计算总纳秒数用于比较
    function GetTotalNanoseconds: Int64;
  public
    // ═══════════════════════════════════════════════════════════════
    // 构造函数
    // ═══════════════════════════════════════════════════════════════
    
    /// <summary>创建日期时间（毫秒精度，向后兼容）</summary>
    class function Create(AYear, AMonth, ADay, AHour, AMinute, ASecond, AMillisecond: Integer): TNaiveDateTime; static;
    /// <summary>创建日期时间（纳秒精度）</summary>
    class function CreateNs(AYear, AMonth, ADay, AHour, AMinute, ASecond, ANanosecond: Integer): TNaiveDateTime; static;
    class function FromDateAndTime(const ADate: TDate; const ATime: TTimeOfDay): TNaiveDateTime; static;
    class function Now: TNaiveDateTime; static;
    
    // ═══════════════════════════════════════════════════════════════
    // 访问器
    // ═══════════════════════════════════════════════════════════════
    
    function GetDate: TDate; inline;
    function GetTime: TTimeOfDay; inline;
    function GetYear: Integer; inline;
    function GetMonth: Integer; inline;
    function GetDay: Integer; inline;
    function GetHour: Integer; inline;
    function GetMinute: Integer; inline;
    function GetSecond: Integer; inline;
    function GetMillisecond: Integer; inline;
    function GetMicrosecond: Integer; inline;  // v1.2.0: 微秒部分 (0-999)
    function GetNanosecond: Integer; inline;   // v1.2.0: 完整纳秒 (0-999999999)
    
    property Date: TDate read GetDate;
    property Time: TTimeOfDay read GetTime;
    property Year: Integer read GetYear;
    property Month: Integer read GetMonth;
    property Day: Integer read GetDay;
    property Hour: Integer read GetHour;
    property Minute: Integer read GetMinute;
    property Second: Integer read GetSecond;
    property Millisecond: Integer read GetMillisecond;
    property Microsecond: Integer read GetMicrosecond;  // v1.2.0
    property Nanosecond: Integer read GetNanosecond;    // v1.2.0
    
    // ═══════════════════════════════════════════════════════════════
    // 日期时间算术
    // ═══════════════════════════════════════════════════════════════
    
    function AddDays(ADays: Integer): TNaiveDateTime;
    function AddDuration(const ADuration: TDuration): TNaiveDateTime;
    function SubtractDuration(const ADuration: TDuration): TNaiveDateTime;
    
    // ═══════════════════════════════════════════════════════════════
    // 时间差值
    // ═══════════════════════════════════════════════════════════════
    
    function DurationUntil(const AOther: TNaiveDateTime): TDuration;
    function DurationSince(const AOther: TNaiveDateTime): TDuration;
    
    // ═══════════════════════════════════════════════════════════════
    // 替换日期/时间
    // ═══════════════════════════════════════════════════════════════
    
    function WithDate(const ANewDate: TDate): TNaiveDateTime;
    function WithTime(const ANewTime: TTimeOfDay): TNaiveDateTime;
    
    // ═══════════════════════════════════════════════════════════════
    // 格式化与解析
    // ═══════════════════════════════════════════════════════════════
    
    function ToISO8601: string;
    class function TryParse(const AStr: string; out ADateTime: TNaiveDateTime): Boolean; static;
    function ToString: string;
    
    // ═══════════════════════════════════════════════════════════════
    // 比较运算符
    // ═══════════════════════════════════════════════════════════════
    
    class operator =(const A, B: TNaiveDateTime): Boolean; inline;
    class operator <>(const A, B: TNaiveDateTime): Boolean; inline;
    class operator <(const A, B: TNaiveDateTime): Boolean; inline;
    class operator >(const A, B: TNaiveDateTime): Boolean; inline;
    class operator <=(const A, B: TNaiveDateTime): Boolean; inline;
    class operator >=(const A, B: TNaiveDateTime): Boolean; inline;
  end;

implementation

const
  NS_PER_MS     = Int64(1000000);         // 1 毫秒 = 10^6 纳秒
  NS_PER_SEC    = Int64(1000000000);      // 1 秒 = 10^9 纳秒
  NS_PER_MIN    = Int64(60000000000);     // 1 分钟 = 60 * 10^9 纳秒
  NS_PER_HOUR   = Int64(3600000000000);   // 1 小时 = 3600 * 10^9 纳秒
  NS_PER_DAY    = Int64(86400000000000);  // 1 天 = 86400 * 10^9 纳秒
  MS_PER_DAY    = 86400000;               // 24 * 60 * 60 * 1000 (向后兼容)

{ TNaiveDateTime }

function TNaiveDateTime.GetTotalNanoseconds: Int64;
begin
  Result := Int64(FDate.ToJulianDay) * NS_PER_DAY + FNanosOfDay;
end;

class function TNaiveDateTime.Create(AYear, AMonth, ADay, AHour, AMinute, ASecond, AMillisecond: Integer): TNaiveDateTime;
begin
  Result.FDate := TDate.Create(AYear, AMonth, ADay);
  Result.FNanosOfDay := Int64(AHour) * NS_PER_HOUR +
                        Int64(AMinute) * NS_PER_MIN +
                        Int64(ASecond) * NS_PER_SEC +
                        Int64(AMillisecond) * NS_PER_MS;
end;

class function TNaiveDateTime.CreateNs(AYear, AMonth, ADay, AHour, AMinute, ASecond, ANanosecond: Integer): TNaiveDateTime;
begin
  Result.FDate := TDate.Create(AYear, AMonth, ADay);
  Result.FNanosOfDay := Int64(AHour) * NS_PER_HOUR +
                        Int64(AMinute) * NS_PER_MIN +
                        Int64(ASecond) * NS_PER_SEC +
                        Int64(ANanosecond);
end;

class function TNaiveDateTime.FromDateAndTime(const ADate: TDate; const ATime: TTimeOfDay): TNaiveDateTime;
begin
  Result.FDate := ADate;
  // TTimeOfDay 是毫秒精度，转换为纳秒
  Result.FNanosOfDay := Int64(ATime.ToMilliseconds) * NS_PER_MS;
end;

class function TNaiveDateTime.Now: TNaiveDateTime;
var
  LNow: TDateTime;
  LYear, LMonth, LDay, LHour, LMinute, LSecond, LMilli: Word;
begin
  LNow := SysUtils.Now;
  DecodeDateTime(LNow, LYear, LMonth, LDay, LHour, LMinute, LSecond, LMilli);
  Result := TNaiveDateTime.Create(LYear, LMonth, LDay, LHour, LMinute, LSecond, LMilli);
end;

function TNaiveDateTime.GetDate: TDate;
begin
  Result := FDate;
end;

function TNaiveDateTime.GetTime: TTimeOfDay;
var
  LMs: Integer;
begin
  // 从纳秒转换为毫秒（TTimeOfDay 精度）
  LMs := FNanosOfDay div NS_PER_MS;
  Result := TTimeOfDay.FromMilliseconds(LMs);
end;

function TNaiveDateTime.GetYear: Integer;
begin
  Result := FDate.GetYear;
end;

function TNaiveDateTime.GetMonth: Integer;
begin
  Result := FDate.GetMonth;
end;

function TNaiveDateTime.GetDay: Integer;
begin
  Result := FDate.GetDay;
end;

function TNaiveDateTime.GetHour: Integer;
begin
  Result := (FNanosOfDay div NS_PER_HOUR) mod 24;
end;

function TNaiveDateTime.GetMinute: Integer;
begin
  Result := (FNanosOfDay div NS_PER_MIN) mod 60;
end;

function TNaiveDateTime.GetSecond: Integer;
begin
  Result := (FNanosOfDay div NS_PER_SEC) mod 60;
end;

function TNaiveDateTime.GetMillisecond: Integer;
begin
  // 毫秒 = 纳秒 div 10^6 mod 1000
  Result := (FNanosOfDay div NS_PER_MS) mod 1000;
end;

function TNaiveDateTime.GetMicrosecond: Integer;
begin
  // 微秒部分 = (纳秒 div 1000) mod 1000
  Result := (FNanosOfDay div 1000) mod 1000;
end;

function TNaiveDateTime.GetNanosecond: Integer;
begin
  // 完整纳秒 = 纳秒 mod 10^9
  Result := FNanosOfDay mod NS_PER_SEC;
end;

function TNaiveDateTime.AddDays(ADays: Integer): TNaiveDateTime;
begin
  Result.FDate := FDate.AddDays(ADays);
  Result.FNanosOfDay := FNanosOfDay;
end;

function TNaiveDateTime.AddDuration(const ADuration: TDuration): TNaiveDateTime;
var
  LTotalNs: Int64;
  LDays: Int64;
  LRemainingNs: Int64;
begin
  LTotalNs := FNanosOfDay + ADuration.AsNs;
  
  if LTotalNs >= 0 then
  begin
    LDays := LTotalNs div NS_PER_DAY;
    LRemainingNs := LTotalNs mod NS_PER_DAY;
  end
  else
  begin
    // 处理负数情况
    LDays := (LTotalNs - NS_PER_DAY + 1) div NS_PER_DAY;
    LRemainingNs := LTotalNs - LDays * NS_PER_DAY;
  end;
  
  Result.FDate := FDate.AddDays(Integer(LDays));
  Result.FNanosOfDay := LRemainingNs;
end;

function TNaiveDateTime.SubtractDuration(const ADuration: TDuration): TNaiveDateTime;
begin
  Result := AddDuration(TDuration.FromNs(-ADuration.AsNs));
end;

function TNaiveDateTime.DurationUntil(const AOther: TNaiveDateTime): TDuration;
var
  LDiffNs: Int64;
begin
  LDiffNs := AOther.GetTotalNanoseconds - GetTotalNanoseconds;
  Result := TDuration.FromNs(LDiffNs);
end;

function TNaiveDateTime.DurationSince(const AOther: TNaiveDateTime): TDuration;
var
  LDiffNs: Int64;
begin
  LDiffNs := GetTotalNanoseconds - AOther.GetTotalNanoseconds;
  Result := TDuration.FromNs(LDiffNs);
end;

function TNaiveDateTime.WithDate(const ANewDate: TDate): TNaiveDateTime;
begin
  Result.FDate := ANewDate;
  Result.FNanosOfDay := FNanosOfDay;
end;

function TNaiveDateTime.WithTime(const ANewTime: TTimeOfDay): TNaiveDateTime;
begin
  Result.FDate := FDate;
  // TTimeOfDay 是毫秒精度，转换为纳秒
  Result.FNanosOfDay := Int64(ANewTime.ToMilliseconds) * NS_PER_MS;
end;

function TNaiveDateTime.ToISO8601: string;
var
  LNs: Integer;
  LFracStr: string;
  I: Integer;
begin
  LNs := Nanosecond;  // 0-999999999
  
  if LNs = 0 then
    Result := Format('%.4d-%.2d-%.2dT%.2d:%.2d:%.2d',
      [Year, Month, Day, Hour, Minute, Second])
  else
  begin
    // 格式化亚秒部分，去掉末尾的 0
    LFracStr := Format('%.9d', [LNs]);
    // 去掉末尾 0
    I := Length(LFracStr);
    while (I > 1) and (LFracStr[I] = '0') do
      Dec(I);
    LFracStr := Copy(LFracStr, 1, I);
    
    Result := Format('%.4d-%.2d-%.2dT%.2d:%.2d:%.2d.%s',
      [Year, Month, Day, Hour, Minute, Second, LFracStr]);
  end;
end;

class function TNaiveDateTime.TryParse(const AStr: string; out ADateTime: TNaiveDateTime): Boolean;
var
  LDatePart, LTimePart, LFracPart: string;
  LTPos, LDotPos: Integer;
  LYear, LMonth, LDay, LHour, LMinute, LSecond: Integer;
  LNanosecond: Int64;
  LFracLen: Integer;
begin
  Result := False;
  LNanosecond := 0;
  
  // 查找 'T' 分隔符
  LTPos := Pos('T', AStr);
  if LTPos = 0 then
    Exit;
  
  LDatePart := Copy(AStr, 1, LTPos - 1);
  LTimePart := Copy(AStr, LTPos + 1, Length(AStr) - LTPos);
  
  // 解析日期 YYYY-MM-DD
  if Length(LDatePart) < 10 then
    Exit;
  if not TryStrToInt(Copy(LDatePart, 1, 4), LYear) then
    Exit;
  if not TryStrToInt(Copy(LDatePart, 6, 2), LMonth) then
    Exit;
  if not TryStrToInt(Copy(LDatePart, 9, 2), LDay) then
    Exit;
  
  // 检查亚秒部分
  LDotPos := Pos('.', LTimePart);
  if LDotPos > 0 then
  begin
    LFracPart := Copy(LTimePart, LDotPos + 1, Length(LTimePart) - LDotPos);
    LTimePart := Copy(LTimePart, 1, LDotPos - 1);
    
    // 支持 1-9 位小数
    LFracLen := Length(LFracPart);
    if (LFracLen < 1) or (LFracLen > 9) then
      Exit;
    if not TryStrToInt64(LFracPart, LNanosecond) then
      Exit;
    // 补齐到 9 位
    while LFracLen < 9 do
    begin
      LNanosecond := LNanosecond * 10;
      Inc(LFracLen);
    end;
  end;
  
  // 解析时间 HH:MM:SS
  if Length(LTimePart) < 8 then
    Exit;
  if not TryStrToInt(Copy(LTimePart, 1, 2), LHour) then
    Exit;
  if not TryStrToInt(Copy(LTimePart, 4, 2), LMinute) then
    Exit;
  if not TryStrToInt(Copy(LTimePart, 7, 2), LSecond) then
    Exit;
  
  ADateTime := TNaiveDateTime.CreateNs(LYear, LMonth, LDay, LHour, LMinute, LSecond, Integer(LNanosecond));
  Result := True;
end;

function TNaiveDateTime.ToString: string;
begin
  Result := ToISO8601;
end;

class operator TNaiveDateTime.=(const A, B: TNaiveDateTime): Boolean;
begin
  Result := A.GetTotalNanoseconds = B.GetTotalNanoseconds;
end;

class operator TNaiveDateTime.<>(const A, B: TNaiveDateTime): Boolean;
begin
  Result := A.GetTotalNanoseconds <> B.GetTotalNanoseconds;
end;

class operator TNaiveDateTime.<(const A, B: TNaiveDateTime): Boolean;
begin
  Result := A.GetTotalNanoseconds < B.GetTotalNanoseconds;
end;

class operator TNaiveDateTime.>(const A, B: TNaiveDateTime): Boolean;
begin
  Result := A.GetTotalNanoseconds > B.GetTotalNanoseconds;
end;

class operator TNaiveDateTime.<=(const A, B: TNaiveDateTime): Boolean;
begin
  Result := A.GetTotalNanoseconds <= B.GetTotalNanoseconds;
end;

class operator TNaiveDateTime.>=(const A, B: TNaiveDateTime): Boolean;
begin
  Result := A.GetTotalNanoseconds >= B.GetTotalNanoseconds;
end;

end.
