unit fafafa.core.time.zoneddatetime;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.zoneddatetime - 带时区的日期时间

📖 概述：
  提供带时区信息的日期时间类型，对齐 Rust chrono::DateTime<Tz>。
  支持时区转换、Unix 时间戳、ISO 8601 格式化。

🔧 特性：
  • 类型安全的带时区日期时间表示
  • 时区转换（ToUtc, WithOffset）
  • Unix 时间戳互转
  • ISO 8601 格式化与解析
  • 跨时区比较

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
──────────────────────────────────────────────────────────────
}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  DateUtils,
  fafafa.core.time.offset,
  fafafa.core.time.date,
  fafafa.core.time.timeofday,
  fafafa.core.time.instant;

type
  /// <summary>
  ///   TZonedDateTime - 带时区的日期时间类型
  ///   存储本地时间 + 时区偏移，能够精确表示时间线上的一个点。
  ///   对齐 Rust chrono::DateTime<Tz> 的设计。
  /// </summary>
  TZonedDateTime = record
  private
    FDate: TDate;
    FTime: TTimeOfDay;
    FOffset: TUtcOffset;
    
    // 内部：计算 Unix 时间戳（UTC 秒数）
    function GetUnixTimestampInternal: Int64;
  public
    // ═══════════════════════════════════════════════════════════════
    // 构造函数
    // ═══════════════════════════════════════════════════════════════
    
    /// <summary>创建指定时区的日期时间</summary>
    class function Create(AYear, AMonth, ADay, AHour, AMinute, ASecond: Integer;
      const AOffset: TUtcOffset): TZonedDateTime; static;
    
    /// <summary>从 TDate 和 TTimeOfDay 创建</summary>
    class function FromDateAndTime(const ADate: TDate; const ATime: TTimeOfDay;
      const AOffset: TUtcOffset): TZonedDateTime; static;
    
    /// <summary>从 Unix 时间戳创建</summary>
    class function FromUnixTimestamp(ATimestamp: Int64; const AOffset: TUtcOffset): TZonedDateTime; static;
    
    /// <summary>获取当前 UTC 时间</summary>
    class function NowUtc: TZonedDateTime; static;
    
    /// <summary>获取当前本地时间</summary>
    class function NowLocal: TZonedDateTime; static;
    
    // ═══════════════════════════════════════════════════════════════
    // 访问器
    // ═══════════════════════════════════════════════════════════════
    
    function GetDate: TDate; inline;
    function GetTime: TTimeOfDay; inline;
    function GetOffset: TUtcOffset; inline;
    function GetYear: Integer; inline;
    function GetMonth: Integer; inline;
    function GetDay: Integer; inline;
    function GetHour: Integer; inline;
    function GetMinute: Integer; inline;
    function GetSecond: Integer; inline;
    
    property Date: TDate read GetDate;
    property Time: TTimeOfDay read GetTime;
    property Offset: TUtcOffset read GetOffset;
    property Year: Integer read GetYear;
    property Month: Integer read GetMonth;
    property Day: Integer read GetDay;
    property Hour: Integer read GetHour;
    property Minute: Integer read GetMinute;
    property Second: Integer read GetSecond;
    
    // ═══════════════════════════════════════════════════════════════
    // 时区转换
    // ═══════════════════════════════════════════════════════════════
    
    /// <summary>转换为 UTC 时间</summary>
    function ToUtc: TZonedDateTime;
    
    /// <summary>转换到指定时区</summary>
    function WithOffset(const ANewOffset: TUtcOffset): TZonedDateTime;
    
    // ═══════════════════════════════════════════════════════════════
    // Unix 时间戳
    // ═══════════════════════════════════════════════════════════════
    
    /// <summary>转换为 Unix 时间戳（UTC 秒数）</summary>
    function ToUnixTimestamp: Int64;
    
    /// <summary>转换为 TInstant（时间线上的精确时刻）</summary>
    function ToInstant: TInstant;
    
    // ═══════════════════════════════════════════════════════════════
    // 格式化与解析
    // ═══════════════════════════════════════════════════════════════
    
    /// <summary>ISO 8601 格式输出</summary>
    function ToISO8601: string;
    
    /// <summary>解析 ISO 8601 格式字符串</summary>
    class function TryParse(const AStr: string; out ADateTime: TZonedDateTime): Boolean; static;
    
    /// <summary>字符串表示</summary>
    function ToString: string;
    
    // ═══════════════════════════════════════════════════════════════
    // 比较运算符（基于 UTC 时间点比较）
    // ═══════════════════════════════════════════════════════════════
    
    class operator =(const A, B: TZonedDateTime): Boolean; inline;
    class operator <>(const A, B: TZonedDateTime): Boolean; inline;
    class operator <(const A, B: TZonedDateTime): Boolean; inline;
    class operator >(const A, B: TZonedDateTime): Boolean; inline;
    class operator <=(const A, B: TZonedDateTime): Boolean; inline;
    class operator >=(const A, B: TZonedDateTime): Boolean; inline;
  end;

  /// <summary>
  ///   TInstantZDTHelper - TInstant 的时区转换扩展
  ///   提供 TInstant -> TZonedDateTime 的便捷转换方法
  /// </summary>
  TInstantZDTHelper = type helper for TInstant
    /// <summary>将此时刻转换为指定时区的 TZonedDateTime</summary>
    /// <param name="AOffset">目标时区偏移</param>
    /// <returns>对应时区的日期时间</returns>
    function AtOffset(const AOffset: TUtcOffset): TZonedDateTime;
    
    /// <summary>将此时刻转换为 UTC 时区的 TZonedDateTime</summary>
    /// <returns>UTC 时区的日期时间</returns>
    function AtUtc: TZonedDateTime;
  end;

implementation

const
  SECONDS_PER_DAY = 86400;
  UNIX_EPOCH_JULIAN_DAY = 2440588; // 1970-01-01 的 Julian Day

{ TZonedDateTime }

function TZonedDateTime.GetUnixTimestampInternal: Int64;
var
  LDays: Integer;
  LSeconds: Integer;
begin
  // 计算自 Unix 纪元的天数
  LDays := FDate.ToJulianDay - UNIX_EPOCH_JULIAN_DAY;
  // 计算当天的秒数
  LSeconds := FTime.ToSeconds;
  // 转换为 UTC：减去时区偏移
  Result := Int64(LDays) * SECONDS_PER_DAY + LSeconds - FOffset.TotalSeconds;
end;

class function TZonedDateTime.Create(AYear, AMonth, ADay, AHour, AMinute, ASecond: Integer;
  const AOffset: TUtcOffset): TZonedDateTime;
begin
  Result.FDate := TDate.Create(AYear, AMonth, ADay);
  Result.FTime := TTimeOfDay.Create(AHour, AMinute, ASecond);
  Result.FOffset := AOffset;
end;

class function TZonedDateTime.FromDateAndTime(const ADate: TDate; const ATime: TTimeOfDay;
  const AOffset: TUtcOffset): TZonedDateTime;
begin
  Result.FDate := ADate;
  Result.FTime := ATime;
  Result.FOffset := AOffset;
end;

class function TZonedDateTime.FromUnixTimestamp(ATimestamp: Int64; const AOffset: TUtcOffset): TZonedDateTime;
var
  LLocalTimestamp: Int64;
  LDays: Integer;
  LDaySeconds: Integer;
begin
  // 将 UTC 时间戳转换为本地时间戳
  LLocalTimestamp := ATimestamp + AOffset.TotalSeconds;
  
  // 处理负数时间戳
  if LLocalTimestamp >= 0 then
  begin
    LDays := LLocalTimestamp div SECONDS_PER_DAY;
    LDaySeconds := LLocalTimestamp mod SECONDS_PER_DAY;
  end
  else
  begin
    // 对于负数，需要特殊处理以确保 LDaySeconds 为正
    LDays := (LLocalTimestamp - SECONDS_PER_DAY + 1) div SECONDS_PER_DAY;
    LDaySeconds := LLocalTimestamp - Int64(LDays) * SECONDS_PER_DAY;
  end;
  
  Result.FDate := TDate.FromJulianDay(UNIX_EPOCH_JULIAN_DAY + LDays);
  Result.FTime := TTimeOfDay.FromSeconds(LDaySeconds);
  Result.FOffset := AOffset;
end;

class function TZonedDateTime.NowUtc: TZonedDateTime;
var
  LNow: TDateTime;
  LYear, LMonth, LDay, LHour, LMinute, LSecond, LMilli: Word;
begin
  LNow := SysUtils.Now - GetLocalTimeOffset / 1440; // 转换为 UTC
  DecodeDateTime(LNow, LYear, LMonth, LDay, LHour, LMinute, LSecond, LMilli);
  Result := TZonedDateTime.Create(LYear, LMonth, LDay, LHour, LMinute, LSecond, TUtcOffset.UTC);
end;

class function TZonedDateTime.NowLocal: TZonedDateTime;
var
  LNow: TDateTime;
  LYear, LMonth, LDay, LHour, LMinute, LSecond, LMilli: Word;
begin
  LNow := SysUtils.Now;
  DecodeDateTime(LNow, LYear, LMonth, LDay, LHour, LMinute, LSecond, LMilli);
  Result := TZonedDateTime.Create(LYear, LMonth, LDay, LHour, LMinute, LSecond, TUtcOffset.Local);
end;

function TZonedDateTime.GetDate: TDate;
begin
  Result := FDate;
end;

function TZonedDateTime.GetTime: TTimeOfDay;
begin
  Result := FTime;
end;

function TZonedDateTime.GetOffset: TUtcOffset;
begin
  Result := FOffset;
end;

function TZonedDateTime.GetYear: Integer;
begin
  Result := FDate.GetYear;
end;

function TZonedDateTime.GetMonth: Integer;
begin
  Result := FDate.GetMonth;
end;

function TZonedDateTime.GetDay: Integer;
begin
  Result := FDate.GetDay;
end;

function TZonedDateTime.GetHour: Integer;
begin
  Result := FTime.GetHour;
end;

function TZonedDateTime.GetMinute: Integer;
begin
  Result := FTime.GetMinute;
end;

function TZonedDateTime.GetSecond: Integer;
begin
  Result := FTime.GetSecond;
end;

function TZonedDateTime.ToUtc: TZonedDateTime;
begin
  if FOffset.IsUTC then
    Exit(Self);
  Result := FromUnixTimestamp(GetUnixTimestampInternal, TUtcOffset.UTC);
end;

function TZonedDateTime.WithOffset(const ANewOffset: TUtcOffset): TZonedDateTime;
begin
  Result := FromUnixTimestamp(GetUnixTimestampInternal, ANewOffset);
end;

function TZonedDateTime.ToUnixTimestamp: Int64;
begin
  Result := GetUnixTimestampInternal;
end;

function TZonedDateTime.ToInstant: TInstant;
var
  LUnixSec: Int64;
begin
  LUnixSec := GetUnixTimestampInternal;
  Result := TInstant.FromUnixSec(LUnixSec);
end;

function TZonedDateTime.ToISO8601: string;
begin
  Result := Format('%.4d-%.2d-%.2dT%.2d:%.2d:%.2d%s',
    [Year, Month, Day, Hour, Minute, Second, FOffset.ToISO8601]);
end;

class function TZonedDateTime.TryParse(const AStr: string; out ADateTime: TZonedDateTime): Boolean;
var
  LDatePart, LTimePart, LOffsetPart: string;
  LTPos, LOffsetPos: Integer;
  LYear, LMonth, LDay, LHour, LMinute, LSecond: Integer;
  LOffset: TUtcOffset;
begin
  Result := False;
  
  // 查找 'T' 分隔符
  LTPos := Pos('T', AStr);
  if LTPos = 0 then
    Exit;
  
  LDatePart := Copy(AStr, 1, LTPos - 1);
  
  // 查找时区偏移开始位置
  LOffsetPos := 0;
  if Pos('Z', AStr) > LTPos then
    LOffsetPos := Pos('Z', AStr)
  else if Pos('+', AStr) > LTPos then
    LOffsetPos := Pos('+', AStr)
  else
  begin
    // 查找最后一个 '-'（排除日期中的 '-'）
    LOffsetPos := Length(AStr);
    while (LOffsetPos > LTPos) and (AStr[LOffsetPos] <> '-') do
      Dec(LOffsetPos);
    if LOffsetPos <= LTPos then
      Exit; // 没有找到时区偏移
  end;
  
  LTimePart := Copy(AStr, LTPos + 1, LOffsetPos - LTPos - 1);
  LOffsetPart := Copy(AStr, LOffsetPos, Length(AStr) - LOffsetPos + 1);
  
  // 解析日期 YYYY-MM-DD
  if Length(LDatePart) < 10 then
    Exit;
  if not TryStrToInt(Copy(LDatePart, 1, 4), LYear) then
    Exit;
  if not TryStrToInt(Copy(LDatePart, 6, 2), LMonth) then
    Exit;
  if not TryStrToInt(Copy(LDatePart, 9, 2), LDay) then
    Exit;
  
  // 解析时间 HH:MM:SS
  if Length(LTimePart) < 8 then
    Exit;
  if not TryStrToInt(Copy(LTimePart, 1, 2), LHour) then
    Exit;
  if not TryStrToInt(Copy(LTimePart, 4, 2), LMinute) then
    Exit;
  if not TryStrToInt(Copy(LTimePart, 7, 2), LSecond) then
    Exit;
  
  // 解析时区偏移
  if not TUtcOffset.TryParse(LOffsetPart, LOffset) then
    Exit;
  
  ADateTime := TZonedDateTime.Create(LYear, LMonth, LDay, LHour, LMinute, LSecond, LOffset);
  Result := True;
end;

function TZonedDateTime.ToString: string;
begin
  Result := ToISO8601;
end;

class operator TZonedDateTime.=(const A, B: TZonedDateTime): Boolean;
begin
  Result := A.GetUnixTimestampInternal = B.GetUnixTimestampInternal;
end;

class operator TZonedDateTime.<>(const A, B: TZonedDateTime): Boolean;
begin
  Result := A.GetUnixTimestampInternal <> B.GetUnixTimestampInternal;
end;

class operator TZonedDateTime.<(const A, B: TZonedDateTime): Boolean;
begin
  Result := A.GetUnixTimestampInternal < B.GetUnixTimestampInternal;
end;

class operator TZonedDateTime.>(const A, B: TZonedDateTime): Boolean;
begin
  Result := A.GetUnixTimestampInternal > B.GetUnixTimestampInternal;
end;

class operator TZonedDateTime.<=(const A, B: TZonedDateTime): Boolean;
begin
  Result := A.GetUnixTimestampInternal <= B.GetUnixTimestampInternal;
end;

class operator TZonedDateTime.>=(const A, B: TZonedDateTime): Boolean;
begin
  Result := A.GetUnixTimestampInternal >= B.GetUnixTimestampInternal;
end;

{ TInstantZDTHelper }

function TInstantZDTHelper.AtOffset(const AOffset: TUtcOffset): TZonedDateTime;
var
  LUnixSec: Int64;
begin
  LUnixSec := Self.AsUnixSec;
  Result := TZonedDateTime.FromUnixTimestamp(LUnixSec, AOffset);
end;

function TInstantZDTHelper.AtUtc: TZonedDateTime;
begin
  Result := AtOffset(TUtcOffset.UTC);
end;

end.
