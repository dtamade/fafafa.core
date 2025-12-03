unit fafafa.core.time.timeofday;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.timeofday - 一天中的时间

📖 概述：
  提供一天中时间的表示和操作，包括小时、分钟、秒和毫秒。
  支持时间算术、比较、格式化等功能。

🔧 特性：
  • 高精度时间表示（毫秒级）
  • 时间算术运算
  • 12/24小时制支持
  • 时间格式化和解析
  • 与标准 TTime 的互操作

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
──────────────────────────────────────────────────────────────
}

{$modeswitch advancedrecords}

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  DateUtils,
  fafafa.core.time.base,
  fafafa.core.time.duration;

type
  // 时间格式
  TTimeFormat = (
    tf12Hour,  // 12小时制
    tf24Hour   // 24小时制
  );

  // 上午/下午
  TMeridiem = (
    mAM,  // 上午
    mPM   // 下午
  );

  {**
   * TTimeOfDay - 一天中的时间
   *
   * @desc
   *   表示一天中的时间，精确到纳秒。
   *   内部使用自午夜开始的纳秒数存储。
   *
   * @precision
   *   纳秒级精度（9位小数）。
   *
   * @thread_safety
   *   值类型，天然线程安全。
   *
   * @range
   *   00:00:00.000000000 到 23:59:59.999999999
   *}
  TTimeOfDay = record
  public const
    NS_PER_US   = Int64(1000);
    NS_PER_MS   = Int64(1000000);
    NS_PER_SEC  = Int64(1000000000);
    NS_PER_MIN  = Int64(60000000000);
    NS_PER_HOUR = Int64(3600000000000);
    NS_PER_DAY  = Int64(86400000000000);
  private
    FNanoseconds: Int64; // 自午夜开始的纳秒数 (0 .. NS_PER_DAY-1)

    class function IsValidTime(AHour, AMinute, ASecond, AMillisecond: Integer): Boolean; static;
    class function IsValidTimeNs(AHour, AMinute, ASecond, ANanosecond: Integer): Boolean; static;
    class function TimeToMilliseconds(AHour, AMinute, ASecond, AMillisecond: Integer): Integer; static;
    class function TimeToNanoseconds(AHour, AMinute, ASecond, ANanosecond: Integer): Int64; static;
    class procedure MillisecondsToTime(AMilliseconds: Integer; out AHour, AMinute, ASecond, AMillisecond: Integer); static;
    class procedure NanosecondsToTime(ANanoseconds: Int64; out AHour, AMinute, ASecond, ANanosecond: Integer); static;
  public
    // 构造函数
    class function Create(AHour, AMinute: Integer; ASecond: Integer = 0; AMillisecond: Integer = 0): TTimeOfDay; static;
    class function CreateNs(AHour, AMinute, ASecond: Integer; ANanosecond: Integer): TTimeOfDay; static;
    class function FromMilliseconds(AMilliseconds: Integer): TTimeOfDay; static;
    class function FromNanoseconds(ANanoseconds: Int64): TTimeOfDay; static;
    class function FromSeconds(ASeconds: Integer): TTimeOfDay; static;
    class function FromMinutes(AMinutes: Integer): TTimeOfDay; static;
    class function FromHours(AHours: Integer): TTimeOfDay; static;
    class function FromTime(const ATime: TTime): TTimeOfDay; static;
    class function FromDuration(const ADuration: TDuration): TTimeOfDay; static;
    class function Now: TTimeOfDay; static;

    // 安全构造函数
    // 兼容重载（旧顺序，无默认参数）
    class function TryCreate(AHour, AMinute, ASecond, AMillisecond: Integer; out ATime: TTimeOfDay): Boolean; overload; static;
    // 新顺序（默认参数在最后）
    class function TryCreate(AHour, AMinute: Integer; out ATime: TTimeOfDay; ASecond: Integer = 0; AMillisecond: Integer = 0): Boolean; overload; static;
    class function TryFromTime(const ATime: TTime; out ATimeOfDay: TTimeOfDay): Boolean; static;
    class function TryParse(const ATimeStr: string; out ATime: TTimeOfDay): Boolean; static;
    class function TryParseISO(const ATimeStr: string; out ATime: TTimeOfDay): Boolean; static;

    // 常量
    class function Midnight: TTimeOfDay; static; // 00:00:00
    class function Noon: TTimeOfDay; static; // 12:00:00
    class function MinValue: TTimeOfDay; static; // 00:00:00.000
    class function MaxValue: TTimeOfDay; static; // 23:59:59.999

    // 转换函数
    function ToMilliseconds: Integer; inline;
    function ToNanoseconds: Int64; inline;
    function ToSeconds: Integer; inline;
    function ToMinutes: Integer; inline;
    function ToHours: Double; inline;
    function ToTime: TTime;
    function ToDuration: TDuration;
    function ToISO8601: string; // HH:MM:SS.nnnnnnnnn 格式（纳秒）

    // 时间组件
    function GetHour: Integer;
    function GetMinute: Integer;
    function GetSecond: Integer;
    function GetMillisecond: Integer;
    function GetMicrosecond: Integer;   // 微秒部分 (0-999)
    function GetNanosecond: Integer;    // 纳秒部分 (0-999)
    function GetSubsecondNanos: Integer; // 秒以下的全部纳秒 (0-999999999)
    function GetHour12: Integer; // 12小时制的小时 (1-12)
    function GetMeridiem: TMeridiem; // AM/PM

    // 时间算术
    function AddHours(AHours: Integer): TTimeOfDay;
    function AddMinutes(AMinutes: Integer): TTimeOfDay;
    function AddSeconds(ASeconds: Integer): TTimeOfDay;
    function AddMilliseconds(AMilliseconds: Integer): TTimeOfDay;
    function AddDuration(const ADuration: TDuration): TTimeOfDay;
    function SubtractHours(AHours: Integer): TTimeOfDay;
    function SubtractMinutes(AMinutes: Integer): TTimeOfDay;
    function SubtractSeconds(ASeconds: Integer): TTimeOfDay;
    function SubtractMilliseconds(AMilliseconds: Integer): TTimeOfDay;
    function SubtractDuration(const ADuration: TDuration): TTimeOfDay;

    // 时间差值
    function DurationUntil(const AOther: TTimeOfDay): TDuration;
    function DurationSince(const AOther: TTimeOfDay): TDuration;
    function MillisecondsUntil(const AOther: TTimeOfDay): Integer;
    function MillisecondsSince(const AOther: TTimeOfDay): Integer;

    // 比较操作
    function Compare(const AOther: TTimeOfDay): Integer; inline;
    function Equal(const AOther: TTimeOfDay): Boolean; inline;
    function LessThan(const AOther: TTimeOfDay): Boolean; inline;
    function LessOrEqual(const AOther: TTimeOfDay): Boolean; inline;
    function GreaterThan(const AOther: TTimeOfDay): Boolean; inline;
    function GreaterOrEqual(const AOther: TTimeOfDay): Boolean; inline;
    function IsBetween(const AStart, AEnd: TTimeOfDay): Boolean;

    // 状态查询
    function IsAM: Boolean; inline;
    function IsPM: Boolean; inline;
    function IsMidnight: Boolean; inline;
    function IsNoon: Boolean; inline;
    function IsMorning: Boolean; // 06:00-12:00
    function IsAfternoon: Boolean; // 12:00-18:00
    function IsEvening: Boolean; // 18:00-22:00
    function IsNight: Boolean; // 22:00-06:00

    // 舍入操作
    function RoundToHour: TTimeOfDay;
    function RoundToMinute: TTimeOfDay;
    function RoundToSecond: TTimeOfDay;
    function TruncateToHour: TTimeOfDay;
    function TruncateToMinute: TTimeOfDay;
    function TruncateToSecond: TTimeOfDay;

    // 工具函数
    function Clamp(const AMin, AMax: TTimeOfDay): TTimeOfDay;
    class function Min(const A, B: TTimeOfDay): TTimeOfDay; static; inline;
    class function Max(const A, B: TTimeOfDay): TTimeOfDay; static; inline;

    // 运算符重载
    class operator +(const ATime: TTimeOfDay; const ADuration: TDuration): TTimeOfDay;
    class operator -(const ATime: TTimeOfDay; const ADuration: TDuration): TTimeOfDay;
    class operator -(const A, B: TTimeOfDay): TDuration;
    class operator =(const A, B: TTimeOfDay): Boolean; inline;
    class operator <>(const A, B: TTimeOfDay): Boolean; inline;
    class operator <(const A, B: TTimeOfDay): Boolean; inline;
    class operator >(const A, B: TTimeOfDay): Boolean; inline;
    class operator <=(const A, B: TTimeOfDay): Boolean; inline;
    class operator >=(const A, B: TTimeOfDay): Boolean; inline;

    // 字符串表示
    function ToString: string; overload;
    function ToString(const AFormat: string): string; overload;
    function ToString(ATimeFormat: TTimeFormat): string; overload;
    function ToShortString: string; // HH:MM 格式
    function ToLongString: string; // HH:MM:SS.mmm 格式
    function To12HourString: string; // h:MM AM/PM 格式
    function To24HourString: string; // HH:MM:SS 格式
  end;

  {**
   * TTimeRange - 时间范围
   *
   * @desc
   *   表示一天中的时间范围，包含开始时间和结束时间。
   *   支持跨午夜的时间范围。
   *
   * @thread_safety
   *   值类型，天然线程安全。
   *}
  TTimeRange = record
  private
    FStartTime: TTimeOfDay;
    FEndTime: TTimeOfDay;
    FCrossesmidnight: Boolean;
  public
    // 构造函数
    class function Create(const AStart, AEnd: TTimeOfDay): TTimeRange; static;
    class function CreateDuration(const AStart: TTimeOfDay; const ADuration: TDuration): TTimeRange; static;

    // 属性
    function GetStartTime: TTimeOfDay; inline;
    function GetEndTime: TTimeOfDay; inline;
    function GetDuration: TDuration;
    function CrossesMiddnight: Boolean; inline;

    // 查询操作
    function Contains(const ATime: TTimeOfDay): Boolean;
    function Overlaps(const AOther: TTimeRange): Boolean;
    function IsEmpty: Boolean; inline;
    function IsValid: Boolean; inline;

    // 范围操作
    function Union(const AOther: TTimeRange): TTimeRange;
    function Intersection(const AOther: TTimeRange): TTimeRange;
    function Extend(const ADuration: TDuration): TTimeRange;
    function Shift(const ADuration: TDuration): TTimeRange;

    // 字符串表示
    function ToString: string;
  end;

// 便捷函数
function TimeOf(AHour, AMinute: Integer; ASecond: Integer = 0; AMillisecond: Integer = 0): TTimeOfDay; inline;
function TimeNow: TTimeOfDay; inline;

// 时间解析
function ParseTime(const ATimeStr: string): TTimeOfDay;
function ParseTimeISO(const ATimeStr: string): TTimeOfDay; // ISO 8601 格式
function TryParseTime(const ATimeStr: string; out ATime: TTimeOfDay): Boolean;
function TryParseTimeISO(const ATimeStr: string; out ATime: TTimeOfDay): Boolean;

// 时间格式化
function FormatTime(const ATime: TTimeOfDay; const AFormat: string): string;
function FormatTime12Hour(const ATime: TTimeOfDay): string;
function FormatTime24Hour(const ATime: TTimeOfDay): string;

// 时间常量
  const
    MILLISECONDS_PER_SECOND = fafafa.core.time.base.MILLISECONDS_PER_SECOND;
    MILLISECONDS_PER_MINUTE = fafafa.core.time.base.MILLISECONDS_PER_MINUTE;
    MILLISECONDS_PER_HOUR   = fafafa.core.time.base.MILLISECONDS_PER_HOUR;
    MILLISECONDS_PER_DAY    = fafafa.core.time.base.MILLISECONDS_PER_DAY;
  
    SECONDS_PER_MINUTE = fafafa.core.time.base.SECONDS_PER_MINUTE;
    SECONDS_PER_HOUR   = fafafa.core.time.base.SECONDS_PER_HOUR;
    SECONDS_PER_DAY    = fafafa.core.time.base.SECONDS_PER_DAY;
  
    MINUTES_PER_HOUR = fafafa.core.time.base.MINUTES_PER_HOUR;
    MINUTES_PER_DAY  = fafafa.core.time.base.MINUTES_PER_DAY;
  
    HOURS_PER_DAY = fafafa.core.time.base.HOURS_PER_DAY;

implementation

uses Math;


{ TTimeOfDay }

class function TTimeOfDay.IsValidTime(AHour, AMinute, ASecond, AMillisecond: Integer): Boolean;
begin
  Result := (AHour >= 0) and (AHour <= 23) and
            (AMinute >= 0) and (AMinute <= 59) and
            (ASecond >= 0) and (ASecond <= 59) and
            (AMillisecond >= 0) and (AMillisecond <= 999);
end;

class function TTimeOfDay.IsValidTimeNs(AHour, AMinute, ASecond, ANanosecond: Integer): Boolean;
begin
  Result := (AHour >= 0) and (AHour <= 23) and
            (AMinute >= 0) and (AMinute <= 59) and
            (ASecond >= 0) and (ASecond <= 59) and
            (ANanosecond >= 0) and (ANanosecond <= 999999999);
end;

class function TTimeOfDay.TimeToMilliseconds(AHour, AMinute, ASecond, AMillisecond: Integer): Integer;
begin
  Result := AHour * MILLISECONDS_PER_HOUR +
            AMinute * MILLISECONDS_PER_MINUTE +
            ASecond * MILLISECONDS_PER_SECOND +
            AMillisecond;
end;

class function TTimeOfDay.TimeToNanoseconds(AHour, AMinute, ASecond, ANanosecond: Integer): Int64;
begin
  Result := Int64(AHour) * NS_PER_HOUR +
            Int64(AMinute) * NS_PER_MIN +
            Int64(ASecond) * NS_PER_SEC +
            ANanosecond;
end;

class procedure TTimeOfDay.MillisecondsToTime(AMilliseconds: Integer; out AHour, AMinute, ASecond, AMillisecond: Integer);
begin
  // 确保在有效范围内
  AMilliseconds := AMilliseconds mod MILLISECONDS_PER_DAY;
  if AMilliseconds < 0 then
    AMilliseconds := AMilliseconds + MILLISECONDS_PER_DAY;

  AHour := AMilliseconds div MILLISECONDS_PER_HOUR;
  AMilliseconds := AMilliseconds mod MILLISECONDS_PER_HOUR;

  AMinute := AMilliseconds div MILLISECONDS_PER_MINUTE;
  AMilliseconds := AMilliseconds mod MILLISECONDS_PER_MINUTE;

  ASecond := AMilliseconds div MILLISECONDS_PER_SECOND;
  AMillisecond := AMilliseconds mod MILLISECONDS_PER_SECOND;
end;

class procedure TTimeOfDay.NanosecondsToTime(ANanoseconds: Int64; out AHour, AMinute, ASecond, ANanosecond: Integer);
var
  ns: Int64;
begin
  ns := ANanoseconds mod NS_PER_DAY;
  if ns < 0 then
    ns := ns + NS_PER_DAY;

  AHour := Integer(ns div NS_PER_HOUR);
  ns := ns mod NS_PER_HOUR;

  AMinute := Integer(ns div NS_PER_MIN);
  ns := ns mod NS_PER_MIN;

  ASecond := Integer(ns div NS_PER_SEC);
  ANanosecond := Integer(ns mod NS_PER_SEC);
end;

class function TTimeOfDay.Create(AHour, AMinute: Integer; ASecond: Integer; AMillisecond: Integer): TTimeOfDay;
begin
  if not IsValidTime(AHour, AMinute, ASecond, AMillisecond) then
    raise ETimeError.CreateFmt('Invalid time: %d:%d:%d.%d', [AHour, AMinute, ASecond, AMillisecond]);

  Result.FNanoseconds := TimeToNanoseconds(AHour, AMinute, ASecond, AMillisecond * Integer(NS_PER_MS));
end;

class function TTimeOfDay.CreateNs(AHour, AMinute, ASecond: Integer; ANanosecond: Integer): TTimeOfDay;
begin
  if not IsValidTimeNs(AHour, AMinute, ASecond, ANanosecond) then
    raise ETimeError.CreateFmt('Invalid time: %d:%d:%d.%d', [AHour, AMinute, ASecond, ANanosecond]);

  Result.FNanoseconds := TimeToNanoseconds(AHour, AMinute, ASecond, ANanosecond);
end;

class function TTimeOfDay.FromMilliseconds(AMilliseconds: Integer): TTimeOfDay;
var
  ms: Integer;
begin
  ms := AMilliseconds mod MILLISECONDS_PER_DAY;
  if ms < 0 then
    ms := ms + MILLISECONDS_PER_DAY;
  Result.FNanoseconds := Int64(ms) * NS_PER_MS;
end;

class function TTimeOfDay.FromNanoseconds(ANanoseconds: Int64): TTimeOfDay;
begin
  Result.FNanoseconds := ANanoseconds mod NS_PER_DAY;
  if Result.FNanoseconds < 0 then
    Result.FNanoseconds := Result.FNanoseconds + NS_PER_DAY;
end;

class function TTimeOfDay.FromTime(const ATime: TTime): TTimeOfDay;
var
  hour, minute, second, millisecond: Word;
begin
  DecodeTime(ATime, hour, minute, second, millisecond);
  Result := Create(hour, minute, second, millisecond);
end;

class function TTimeOfDay.Now: TTimeOfDay;
begin
  Result := FromTime(Time);
end;

class function TTimeOfDay.Midnight: TTimeOfDay;
begin
  Result.FNanoseconds := 0;
end;

class function TTimeOfDay.Noon: TTimeOfDay;
begin
  Result.FNanoseconds := 12 * NS_PER_HOUR;
end;

class function TTimeOfDay.MinValue: TTimeOfDay;
begin
  Result := Midnight;
end;

class function TTimeOfDay.MaxValue: TTimeOfDay;
begin
  Result.FNanoseconds := NS_PER_DAY - 1;
end;

function TTimeOfDay.ToMilliseconds: Integer;
begin
  Result := Integer(FNanoseconds div NS_PER_MS);
end;

function TTimeOfDay.ToNanoseconds: Int64;
begin
  Result := FNanoseconds;
end;

function TTimeOfDay.ToSeconds: Integer;
begin
  Result := Integer(FNanoseconds div NS_PER_SEC);
end;

function TTimeOfDay.ToTime: TTime;
var
  hour, minute, second, nanosecond: Integer;
begin
  NanosecondsToTime(FNanoseconds, hour, minute, second, nanosecond);
  Result := EncodeTime(hour, minute, second, nanosecond div Integer(NS_PER_MS));
end;

function TTimeOfDay.ToDuration: TDuration;
begin
  Result := TDuration.FromNs(FNanoseconds);
end;

function TTimeOfDay.ToISO8601: string;
var
  hour, minute, second, nanosecond: Integer;
  fracStr: string;
begin
  NanosecondsToTime(FNanoseconds, hour, minute, second, nanosecond);
  if nanosecond = 0 then
    Result := Format('%.2d:%.2d:%.2d', [hour, minute, second])
  else if (nanosecond mod 1000000) = 0 then
    // 毫秒级 (3位)
    Result := Format('%.2d:%.2d:%.2d.%.3d', [hour, minute, second, nanosecond div 1000000])
  else if (nanosecond mod 1000) = 0 then
    // 微秒级 (6位)
    Result := Format('%.2d:%.2d:%.2d.%.6d', [hour, minute, second, nanosecond div 1000])
  else
  begin
    // 纳秒级 (9位)
    fracStr := Format('%.9d', [nanosecond]);
    Result := Format('%.2d:%.2d:%.2d.%s', [hour, minute, second, fracStr]);
  end;
end;

function TTimeOfDay.GetHour: Integer;
var
  minute, second, nanosecond: Integer;
begin
  NanosecondsToTime(FNanoseconds, Result, minute, second, nanosecond);
end;

function TTimeOfDay.GetMinute: Integer;
var
  hour, second, nanosecond: Integer;
begin
  NanosecondsToTime(FNanoseconds, hour, Result, second, nanosecond);
end;

function TTimeOfDay.GetSecond: Integer;
var
  hour, minute, nanosecond: Integer;
begin
  NanosecondsToTime(FNanoseconds, hour, minute, Result, nanosecond);
end;

function TTimeOfDay.GetMillisecond: Integer;
var
  subsecNs: Integer;
begin
  subsecNs := Integer(FNanoseconds mod NS_PER_SEC);
  Result := subsecNs div Integer(NS_PER_MS);
end;

function TTimeOfDay.GetMicrosecond: Integer;
var
  subsecNs: Integer;
begin
  subsecNs := Integer(FNanoseconds mod NS_PER_SEC);
  Result := (subsecNs div Integer(NS_PER_US)) mod 1000;
end;

function TTimeOfDay.GetNanosecond: Integer;
begin
  Result := Integer(FNanoseconds mod NS_PER_SEC) mod 1000;
end;

function TTimeOfDay.GetSubsecondNanos: Integer;
begin
  Result := Integer(FNanoseconds mod NS_PER_SEC);
end;

function TTimeOfDay.GetHour12: Integer;
var
  hour: Integer;
begin
  hour := GetHour;
  if hour = 0 then
    Result := 12
  else if hour > 12 then
    Result := hour - 12
  else
    Result := hour;
end;

function TTimeOfDay.GetMeridiem: TMeridiem;
begin
  if GetHour < 12 then
    Result := mAM
  else
    Result := mPM;
end;

function TTimeOfDay.AddMilliseconds(AMilliseconds: Integer): TTimeOfDay;
begin
  Result := FromNanoseconds(FNanoseconds + Int64(AMilliseconds) * NS_PER_MS);
end;

function TTimeOfDay.AddSeconds(ASeconds: Integer): TTimeOfDay;
begin
  Result := AddMilliseconds(ASeconds * MILLISECONDS_PER_SECOND);
end;

function TTimeOfDay.AddMinutes(AMinutes: Integer): TTimeOfDay;
begin
  Result := AddMilliseconds(AMinutes * MILLISECONDS_PER_MINUTE);
end;

function TTimeOfDay.AddHours(AHours: Integer): TTimeOfDay;
begin
  Result := AddMilliseconds(AHours * MILLISECONDS_PER_HOUR);
end;

function TTimeOfDay.Compare(const AOther: TTimeOfDay): Integer;
begin
  if FNanoseconds < AOther.FNanoseconds then
    Result := -1
  else if FNanoseconds > AOther.FNanoseconds then
    Result := 1
  else
    Result := 0;
end;

function TTimeOfDay.Equal(const AOther: TTimeOfDay): Boolean;
begin
  Result := FNanoseconds = AOther.FNanoseconds;
end;

function TTimeOfDay.LessThan(const AOther: TTimeOfDay): Boolean;
begin
  Result := FNanoseconds < AOther.FNanoseconds;
end;

function TTimeOfDay.GreaterThan(const AOther: TTimeOfDay): Boolean;
begin
  Result := FNanoseconds > AOther.FNanoseconds;
end;

function TTimeOfDay.IsAM: Boolean;
begin
  Result := GetMeridiem = mAM;
end;

function TTimeOfDay.IsPM: Boolean;
begin
  Result := GetMeridiem = mPM;
end;

function TTimeOfDay.IsMidnight: Boolean;
begin
  Result := FNanoseconds = 0;
end;

function TTimeOfDay.IsNoon: Boolean;
begin
  Result := FNanoseconds = 12 * NS_PER_HOUR;
end;

function TTimeOfDay.ToString: string;
begin
  Result := ToISO8601;
end;

// 运算符重载

class operator TTimeOfDay.=(const A, B: TTimeOfDay): Boolean;
begin
  Result := A.Equal(B);
end;


class operator TTimeOfDay.<>(const A, B: TTimeOfDay): Boolean;
begin
  Result := not (A = B);
end;

class operator TTimeOfDay.<(const A, B: TTimeOfDay): Boolean;
begin
  Result := A.LessThan(B);
end;

class operator TTimeOfDay.>(const A, B: TTimeOfDay): Boolean;
begin
  Result := A.GreaterThan(B);
end;


// ===== P0: 核心实现补齐 =====

class function TTimeOfDay.FromSeconds(ASeconds: Integer): TTimeOfDay;
begin
  Result := FromMilliseconds(ASeconds * MILLISECONDS_PER_SECOND);
end;

class function TTimeOfDay.FromMinutes(AMinutes: Integer): TTimeOfDay;
begin
  Result := FromMilliseconds(AMinutes * MILLISECONDS_PER_MINUTE);
end;

class function TTimeOfDay.FromHours(AHours: Integer): TTimeOfDay;
begin
  Result := FromMilliseconds(AHours * MILLISECONDS_PER_HOUR);
end;

class function TTimeOfDay.FromDuration(const ADuration: TDuration): TTimeOfDay;
var
  ns: Int64;
begin
  ns := ADuration.AsNs; // 可能为负，交由 FromNanoseconds 归一化
  Result := FromNanoseconds(ns);
end;

class function TTimeOfDay.TryCreate(AHour, AMinute, ASecond, AMillisecond: Integer; out ATime: TTimeOfDay): Boolean;
begin
  Result := IsValidTime(AHour, AMinute, ASecond, AMillisecond);
  if Result then
    ATime := Create(AHour, AMinute, ASecond, AMillisecond)
  else
    ATime := Midnight;
end;

class function TTimeOfDay.TryCreate(AHour, AMinute: Integer; out ATime: TTimeOfDay; ASecond: Integer; AMillisecond: Integer): Boolean;
begin
  Result := TTimeOfDay.TryCreate(AHour, AMinute, ASecond, AMillisecond, ATime);
end;

class function TTimeOfDay.TryFromTime(const ATime: TTime; out ATimeOfDay: TTimeOfDay): Boolean;
begin
  ATimeOfDay := FromTime(ATime);
  Result := True;
end;

function TTimeOfDay.ToMinutes: Integer;
begin
  Result := Integer(FNanoseconds div NS_PER_MIN);
end;

function TTimeOfDay.ToHours: Double;
begin
  Result := FNanoseconds / NS_PER_HOUR;
end;

function TTimeOfDay.AddDuration(const ADuration: TDuration): TTimeOfDay;
var
  deltaNs: Int64;
begin
  deltaNs := ADuration.AsNs mod NS_PER_DAY; // 归一到 24h 内
  Result := FromNanoseconds(FNanoseconds + deltaNs);
end;

function TTimeOfDay.SubtractHours(AHours: Integer): TTimeOfDay;
begin
  Result := AddHours(-AHours);
end;

function TTimeOfDay.SubtractMinutes(AMinutes: Integer): TTimeOfDay;
begin
  Result := AddMinutes(-AMinutes);
end;

function TTimeOfDay.SubtractSeconds(ASeconds: Integer): TTimeOfDay;
begin
  Result := AddSeconds(-ASeconds);
end;

function TTimeOfDay.SubtractMilliseconds(AMilliseconds: Integer): TTimeOfDay;
begin
  Result := AddMilliseconds(-AMilliseconds);
end;

function TTimeOfDay.SubtractDuration(const ADuration: TDuration): TTimeOfDay;
var
  deltaNs: Int64;
begin
  deltaNs := ADuration.AsNs mod NS_PER_DAY;
  Result := FromNanoseconds(FNanoseconds - deltaNs);
end;

function TTimeOfDay.MillisecondsUntil(const AOther: TTimeOfDay): Integer;
var
  diffNs: Int64;
begin
  diffNs := (AOther.FNanoseconds - FNanoseconds) mod NS_PER_DAY;
  if diffNs < 0 then
    diffNs := diffNs + NS_PER_DAY;
  Result := Integer(diffNs div NS_PER_MS);
end;

function TTimeOfDay.MillisecondsSince(const AOther: TTimeOfDay): Integer;
var
  diffNs: Int64;
begin
  diffNs := (FNanoseconds - AOther.FNanoseconds) mod NS_PER_DAY;
  if diffNs < 0 then
    diffNs := diffNs + NS_PER_DAY;
  Result := Integer(diffNs div NS_PER_MS);
end;

function TTimeOfDay.DurationUntil(const AOther: TTimeOfDay): TDuration;
var
  diffNs: Int64;
begin
  diffNs := (AOther.FNanoseconds - FNanoseconds) mod NS_PER_DAY;
  if diffNs < 0 then
    diffNs := diffNs + NS_PER_DAY;
  Result := TDuration.FromNs(diffNs);
end;

function TTimeOfDay.DurationSince(const AOther: TTimeOfDay): TDuration;
var
  diffNs: Int64;
begin
  diffNs := (FNanoseconds - AOther.FNanoseconds) mod NS_PER_DAY;
  if diffNs < 0 then
    diffNs := diffNs + NS_PER_DAY;
  Result := TDuration.FromNs(diffNs);
end;

function TTimeOfDay.LessOrEqual(const AOther: TTimeOfDay): Boolean;
begin
  Result := FNanoseconds <= AOther.FNanoseconds;
end;

function TTimeOfDay.GreaterOrEqual(const AOther: TTimeOfDay): Boolean;
begin
  Result := FNanoseconds >= AOther.FNanoseconds;
end;

function TTimeOfDay.IsBetween(const AStart, AEnd: TTimeOfDay): Boolean;
var
  s, e, x: Int64;
begin
  s := AStart.FNanoseconds;
  e := AEnd.FNanoseconds;
  x := FNanoseconds;
  if s <= e then
    Result := (x >= s) and (x < e)
  else
    // 跨午夜：如 [22:00, 06:00)
    Result := (x >= s) or (x < e);
end;

function TTimeOfDay.Clamp(const AMin, AMax: TTimeOfDay): TTimeOfDay;
var
  s, e, x: Int64;
  eAdj, xAdj: Int64;
begin
  s := AMin.FNanoseconds;
  e := AMax.FNanoseconds;
  x := FNanoseconds;
  if s <= e then
  begin
    if x < s then Exit(AMin);
    if x >= e then Exit(AMax);
    Exit(Self);
  end
  else
  begin
    // 跨午夜，将区间映射到线性轴 [s, e+day)
    eAdj := e + NS_PER_DAY;
    xAdj := x;
    if xAdj < s then xAdj := xAdj + NS_PER_DAY;

    if xAdj < s then Exit(AMin);
    if xAdj >= eAdj then Exit(AMax);
    Exit(Self);
  end;
end;

class function TTimeOfDay.Min(const A, B: TTimeOfDay): TTimeOfDay;
begin
  if A.FNanoseconds <= B.FNanoseconds then Result := A else Result := B;
end;

class function TTimeOfDay.Max(const A, B: TTimeOfDay): TTimeOfDay;
begin
  if A.FNanoseconds >= B.FNanoseconds then Result := A else Result := B;
end;

class operator TTimeOfDay.+(const ATime: TTimeOfDay; const ADuration: TDuration): TTimeOfDay;
begin
  Result := ATime.AddDuration(ADuration);
end;

class operator TTimeOfDay.-(const ATime: TTimeOfDay; const ADuration: TDuration): TTimeOfDay;
begin
  Result := ATime.SubtractDuration(ADuration);
end;

class operator TTimeOfDay.-(const A, B: TTimeOfDay): TDuration;
begin
  // 采用順時針差值：B → A
  Result := B.DurationUntil(A);
end;

class operator TTimeOfDay.<=(const A, B: TTimeOfDay): Boolean;
begin
  Result := A.LessOrEqual(B);
end;


// ===== P1: 解析实现 =====

class function TTimeOfDay.TryParse(const ATimeStr: string; out ATime: TTimeOfDay): Boolean;
var
  s, hStr, mStr, sStr, fracStr, rest: string;
  p, p2, p3: SizeInt;
  h, m, sec, nanosecond: Integer;
  fracLen: Integer;
begin
  s := Trim(ATimeStr);
  ATime := Midnight;
  Result := False;
  if s = '' then Exit;

  // 允许：HH:MM | HH:MM:SS | HH:MM:SS.nnn (1-9位小数)
  p := Pos(':', s);
  if p = 0 then Exit;
  hStr := Copy(s, 1, p - 1);
  rest := Copy(s, p + 1, MaxInt);
  p2 := Pos(':', rest);
  if p2 > 0 then
  begin
    mStr := Copy(rest, 1, p2 - 1);
    sStr := Copy(rest, p2 + 1, MaxInt);
    p3 := Pos('.', sStr);
    if p3 > 0 then
    begin
      fracStr := Copy(sStr, p3 + 1, MaxInt);
      sStr := Copy(sStr, 1, p3 - 1);
    end
    else
      fracStr := '';
  end
  else
  begin
    mStr := rest;
    sStr := '';
    fracStr := '';
  end;

  if (hStr = '') or (mStr = '') then Exit;

  if not TryStrToInt(hStr, h) then Exit;
  if not TryStrToInt(mStr, m) then Exit;

  if sStr = '' then sec := 0
  else if not TryStrToInt(sStr, sec) then Exit;

  if fracStr = '' then nanosecond := 0
  else
  begin
    fracLen := Length(fracStr);
    if (fracLen < 1) or (fracLen > 9) then Exit;
    if not TryStrToInt(fracStr, nanosecond) then Exit;
    // 补齐到9位
    while fracLen < 9 do
    begin
      nanosecond := nanosecond * 10;
      Inc(fracLen);
    end;
  end;

  Result := IsValidTimeNs(h, m, sec, nanosecond);
  if Result then
    ATime := CreateNs(h, m, sec, nanosecond);
end;

class function TTimeOfDay.TryParseISO(const ATimeStr: string; out ATime: TTimeOfDay): Boolean;
var
  s, hStr, mStr, sStr, msStr, rest: string;
  p, p2, p3: SizeInt;
  h, m, sec, ms: Integer;
begin
  // 严格：HH:MM:SS(.mmm)?，不允许空格
  s := ATimeStr;
  ATime := Midnight;
  Result := False;
  if (s = '') or (Pos(' ', s) > 0) then Exit;

  p := Pos(':', s);
  if p = 0 then Exit;
  hStr := Copy(s, 1, p - 1);
  rest := Copy(s, p + 1, MaxInt);
  p2 := Pos(':', rest);
  if p2 = 0 then Exit;
  mStr := Copy(rest, 1, p2 - 1);
  sStr := Copy(rest, p2 + 1, MaxInt);
  p3 := Pos('.', sStr);
  if p3 > 0 then
  begin
    msStr := Copy(sStr, p3 + 1, MaxInt);
    sStr := Copy(sStr, 1, p3 - 1);
  end
  else
    msStr := '';

  // 必须为两位数（小时/分钟/秒），毫秒若存在必须为三位
  if (Length(hStr) <> 2) or (Length(mStr) <> 2) or (Length(sStr) <> 2) then Exit;
  if (msStr <> '') and (Length(msStr) <> 3) then Exit;

  if not TryStrToInt(hStr, h) then Exit;
  if not TryStrToInt(mStr, m) then Exit;
  if not TryStrToInt(sStr, sec) then Exit;
  if msStr = '' then ms := 0 else if not TryStrToInt(msStr, ms) then Exit;

  if not IsValidTime(h, m, sec, ms) then Exit;

  ATime := Create(h, m, sec, ms);
  Result := True;
end;

// ===== P2: 舍入/截断 =====

function TTimeOfDay.TruncateToSecond: TTimeOfDay;
var
  ns: Int64;
begin
  ns := (FNanoseconds div NS_PER_SEC) * NS_PER_SEC;
  Result := FromNanoseconds(ns);
end;

function TTimeOfDay.TruncateToMinute: TTimeOfDay;
var
  ns: Int64;
begin
  ns := (FNanoseconds div NS_PER_MIN) * NS_PER_MIN;
  Result := FromNanoseconds(ns);
end;

function TTimeOfDay.TruncateToHour: TTimeOfDay;
var
  ns: Int64;
begin
  ns := (FNanoseconds div NS_PER_HOUR) * NS_PER_HOUR;
  Result := FromNanoseconds(ns);
end;

function TTimeOfDay.RoundToSecond: TTimeOfDay;
var
  ns: Int64;
begin
  ns := ((FNanoseconds + (NS_PER_SEC div 2)) div NS_PER_SEC) * NS_PER_SEC;
  Result := FromNanoseconds(ns);
end;

function TTimeOfDay.RoundToMinute: TTimeOfDay;
var
  ns: Int64;
begin
  ns := ((FNanoseconds + (NS_PER_MIN div 2)) div NS_PER_MIN) * NS_PER_MIN;
  Result := FromNanoseconds(ns);
end;

function TTimeOfDay.RoundToHour: TTimeOfDay;
var
  ns: Int64;
begin
  ns := ((FNanoseconds + (NS_PER_HOUR div 2)) div NS_PER_HOUR) * NS_PER_HOUR;
  Result := FromNanoseconds(ns);
end;

// ===== P2: TTimeRange 实现 =====

class function TTimeRange.Create(const AStart, AEnd: TTimeOfDay): TTimeRange;
begin
  Result.FStartTime := AStart;
  Result.FEndTime := AEnd;
  Result.FCrossesmidnight := AStart.FNanoseconds > AEnd.FNanoseconds;
end;

class function TTimeRange.CreateDuration(const AStart: TTimeOfDay; const ADuration: TDuration): TTimeRange;
var
  durNs: Int64;
  endNs: Int64;
begin
  Result.FStartTime := AStart;
  durNs := ADuration.AsNs mod TTimeOfDay.NS_PER_DAY;
  endNs := (AStart.FNanoseconds + durNs) mod TTimeOfDay.NS_PER_DAY;
  if endNs < 0 then endNs := endNs + TTimeOfDay.NS_PER_DAY;
  Result.FEndTime := TTimeOfDay.FromNanoseconds(endNs);
  Result.FCrossesmidnight := AStart.FNanoseconds > endNs;
end;

function TTimeRange.GetStartTime: TTimeOfDay;
begin
  Result := FStartTime;
end;

function TTimeRange.GetEndTime: TTimeOfDay;
begin
  Result := FEndTime;
end;

function TTimeRange.GetDuration: TDuration;
var
  ns: Int64;
begin
  if not CrossesMiddnight then
    ns := (FEndTime.FNanoseconds - FStartTime.FNanoseconds)
  else
    ns := (TTimeOfDay.NS_PER_DAY - FStartTime.FNanoseconds) + FEndTime.FNanoseconds;
  Result := TDuration.FromNs(ns);
end;

function TTimeRange.CrossesMiddnight: Boolean;
begin
  Result := FCrossesmidnight;
end;

function TTimeRange.IsEmpty: Boolean;
begin
  Result := FStartTime.FNanoseconds = FEndTime.FNanoseconds;
end;

function TTimeRange.IsValid: Boolean;
begin
  // 任何 [start,end) 视为合法（允许跨午夜）
  Result := True;
end;

function TTimeRange.Contains(const ATime: TTimeOfDay): Boolean;
var
  s, e, x: Int64;
begin
  s := FStartTime.FNanoseconds;
  e := FEndTime.FNanoseconds;
  x := ATime.FNanoseconds;
  if not CrossesMiddnight then
    Result := (x >= s) and (x < e)
  else
    Result := (x >= s) or (x < e);
end;

function TTimeRange.Overlaps(const AOther: TTimeRange): Boolean;
  // 将两段都转换为最多两段的半开区间，在 0..NS_PER_DAY 线性轴上逐对判断
  function Overlap1(s1,e1,s2,e2: Int64): Boolean;
  begin
    Result := (s1 < e2) and (s2 < e1);
  end;
var
  s1,e1,s2,e2: Int64;
  A1s,A1e,A2s,A2e: array[0..1] of Int64;
  n1,n2,i,j: Integer;
begin
  s1 := FStartTime.FNanoseconds; e1 := FEndTime.FNanoseconds;
  s2 := AOther.FStartTime.FNanoseconds; e2 := AOther.FEndTime.FNanoseconds;

  // 归一化为线性段集合（每段 s<e）
  if s1 <= e1 then begin
    A1s[0] := s1; A1e[0] := e1; n1 := 1;
  end else begin
    A1s[0] := s1; A1e[0] := TTimeOfDay.NS_PER_DAY;
    A1s[1] := 0;  A1e[1] := e1; n1 := 2;
  end;

  if s2 <= e2 then begin
    A2s[0] := s2; A2e[0] := e2; n2 := 1;
  end else begin
    A2s[0] := s2; A2e[0] := TTimeOfDay.NS_PER_DAY;
    A2s[1] := 0;  A2e[1] := e2; n2 := 2;
  end;

  for i := 0 to n1-1 do
    for j := 0 to n2-1 do
      if Overlap1(A1s[i], A1e[i], A2s[j], A2e[j]) then
        Exit(True);
  Result := False;
end;

function TTimeRange.Union(const AOther: TTimeRange): TTimeRange;
// 合并：以本段起点为基准展开到线性轴，取两段线性并集的最小包络，再折回到 [0,day)。
var
  s1,e1,s2,e2: Int64;
  base: Int64;
  s1u,e1u,s2u,e2u: Int64;
  startU,endU: Int64;
begin
  s1 := FStartTime.FNanoseconds; e1 := FEndTime.FNanoseconds;
  s2 := AOther.FStartTime.FNanoseconds; e2 := AOther.FEndTime.FNanoseconds;

  base := s1;

  // 展开 A
  s1u := s1;
  e1u := e1; if e1u < s1u then e1u := e1u + TTimeOfDay.NS_PER_DAY;

  // 展开 B 相对 base
  if s2 >= base then s2u := s2 else s2u := s2 + TTimeOfDay.NS_PER_DAY;
  e2u := e2; if e2u < s2 then e2u := e2u + TTimeOfDay.NS_PER_DAY;
  if s2u > e2u then e2u := e2u + TTimeOfDay.NS_PER_DAY;

  // 线性并集的包络
  if s1u < s2u then begin startU := s1u; endU := Max(e1u, e2u); end
  else begin startU := s2u; endU := Max(e1u, e2u); end;

  Result := TTimeRange.Create(
    TTimeOfDay.FromNanoseconds(startU mod TTimeOfDay.NS_PER_DAY),
    TTimeOfDay.FromNanoseconds(endU mod TTimeOfDay.NS_PER_DAY)
  );
end;

function TTimeRange.Intersection(const AOther: TTimeRange): TTimeRange;
// 计算交集：将两段各自拆为最多两片段，逐对求交；若有多个交段，仅返回覆盖更长的那一段（简化）。
  function Inter1(s1,e1,s2,e2: Int64; out rs,re: Int64): Boolean;
  begin
    rs := Max(s1, s2);
    re := Min(e1, e2);
    Result := rs < re; // 半开区间，相接不算相交
  end;
var
  s1,e1,s2,e2: Int64;
  A1s,A1e,A2s,A2e: array[0..1] of Int64;
  n1,n2,i,j: Integer;
  brs,bre,bestLen,tmpS,tmpE: Int64;
begin
  s1 := FStartTime.FNanoseconds; e1 := FEndTime.FNanoseconds;
  s2 := AOther.FStartTime.FNanoseconds; e2 := AOther.FEndTime.FNanoseconds;

  if s1 <= e1 then begin A1s[0]:=s1; A1e[0]:=e1; n1:=1; end
  else begin A1s[0]:=s1; A1e[0]:=TTimeOfDay.NS_PER_DAY; A1s[1]:=0; A1e[1]:=e1; n1:=2; end;

  if s2 <= e2 then begin A2s[0]:=s2; A2e[0]:=e2; n2:=1; end
  else begin A2s[0]:=s2; A2e[0]:=TTimeOfDay.NS_PER_DAY; A2s[1]:=0; A2e[1]:=e2; n2:=2; end;

  bestLen := -1; brs := 0; bre := 0;
  for i := 0 to n1-1 do
    for j := 0 to n2-1 do
      if Inter1(A1s[i],A1e[i],A2s[j],A2e[j], tmpS,tmpE) then
        if (tmpE - tmpS) > bestLen then
        begin
          bestLen := tmpE - tmpS;
          brs := tmpS; bre := tmpE;
        end;

  if bestLen > 0 then
    Result := TTimeRange.Create(TTimeOfDay.FromNanoseconds(brs), TTimeOfDay.FromNanoseconds(bre mod TTimeOfDay.NS_PER_DAY))
  else
    Result := TTimeRange.Create(FStartTime, FStartTime);
end;

function TTimeRange.Extend(const ADuration: TDuration): TTimeRange;
begin
  Result := TTimeRange.Create(FStartTime, FEndTime.AddDuration(ADuration));
end;

function TTimeRange.Shift(const ADuration: TDuration): TTimeRange;
begin
  Result.FStartTime := FStartTime.AddDuration(ADuration);
  Result.FEndTime := FEndTime.AddDuration(ADuration);
  Result.FCrossesmidnight := Result.FStartTime.FNanoseconds > Result.FEndTime.FNanoseconds;
end;

function TTimeRange.ToString: string;
begin
  Result := Format('%s - %s', [FStartTime.ToShortString, FEndTime.ToShortString]);
end;




class operator TTimeOfDay.>=(const A, B: TTimeOfDay): Boolean;
begin
  Result := A.GreaterOrEqual(B);
end;

// ===== P1: 字符串与时段判定 =====

function TTimeOfDay.ToString(const AFormat: string): string;
var
  t: TTime;
begin
  t := ToTime;
  Result := SysUtils.FormatDateTime(AFormat, t);
end;

{$PUSH}{$WARN 6018 OFF} // Suppress "Unreachable code" warning - false positive in case-else
function TTimeOfDay.ToString(ATimeFormat: TTimeFormat): string;
var
  mm: Integer;
  mer: string;
begin
  case ATimeFormat of
    tf12Hour:
      begin
        mm := GetMinute;
        if IsAM then mer := 'AM' else mer := 'PM';
        Result := Format('%d:%0.2d %s', [GetHour12, mm, mer]);
      end;
    tf24Hour:
      Result := To24HourString;
  else
    Result := ToISO8601;
  end;
end;
{$POP}

function TTimeOfDay.ToShortString: string;
begin
  Result := Format('%0.2d:%0.2d', [GetHour, GetMinute]);
end;

function TTimeOfDay.ToLongString: string;
begin
  Result := Format('%0.2d:%0.2d:%0.2d.%0.3d', [GetHour, GetMinute, GetSecond, GetMillisecond]);
end;

function TTimeOfDay.To12HourString: string;
var
  mm: Integer;
  mer: string;
begin
  mm := GetMinute;
  if IsAM then mer := 'AM' else mer := 'PM';
  Result := Format('%d:%0.2d %s', [GetHour12, mm, mer]);
end;

function TTimeOfDay.To24HourString: string;
begin
  Result := Format('%0.2d:%0.2d:%0.2d', [GetHour, GetMinute, GetSecond]);
end;

function TTimeOfDay.IsMorning: Boolean;
begin
  // [06:00, 12:00)
  Result := IsBetween(TTimeOfDay.Create(6, 0), TTimeOfDay.Create(12, 0));
end;

function TTimeOfDay.IsAfternoon: Boolean;
begin
  // [12:00, 18:00)
  Result := IsBetween(TTimeOfDay.Create(12, 0), TTimeOfDay.Create(18, 0));
end;

function TTimeOfDay.IsEvening: Boolean;
begin
  // [18:00, 22:00)
  Result := IsBetween(TTimeOfDay.Create(18, 0), TTimeOfDay.Create(22, 0));
end;

function TTimeOfDay.IsNight: Boolean;
begin
  // [22:00, 06:00)
  Result := IsBetween(TTimeOfDay.Create(22, 0), TTimeOfDay.Create(6, 0));
end;

// 便捷函数

function TimeOf(AHour, AMinute: Integer; ASecond: Integer; AMillisecond: Integer): TTimeOfDay;
begin
  Result := TTimeOfDay.Create(AHour, AMinute, ASecond, AMillisecond);
end;

function TimeNow: TTimeOfDay;
begin
  Result := TTimeOfDay.Now;
end;

// 实现细节将在后续添加...

// ===== P1: 全局格式化/解析函数（轻量版占位，解析详见 P2） =====

function ParseTime(const ATimeStr: string): TTimeOfDay;
begin
  if not TTimeOfDay.TryParse(ATimeStr, Result) then
    raise EInvalidTimeFormat.CreateFmt('Invalid time string: %s', [ATimeStr]);
end;

function ParseTimeISO(const ATimeStr: string): TTimeOfDay;
begin
  if not TTimeOfDay.TryParseISO(ATimeStr, Result) then
    raise EInvalidTimeFormat.CreateFmt('Invalid ISO time string: %s', [ATimeStr]);
end;

function TryParseTime(const ATimeStr: string; out ATime: TTimeOfDay): Boolean;
begin
  Result := TTimeOfDay.TryParse(ATimeStr, ATime);
end;

function TryParseTimeISO(const ATimeStr: string; out ATime: TTimeOfDay): Boolean;
begin
  Result := TTimeOfDay.TryParseISO(ATimeStr, ATime);
end;

function FormatTime(const ATime: TTimeOfDay; const AFormat: string): string;
begin
  Result := ATime.ToString(AFormat);
end;

function FormatTime12Hour(const ATime: TTimeOfDay): string;
begin
  Result := ATime.To12HourString;
end;

function FormatTime24Hour(const ATime: TTimeOfDay): string;
begin
  Result := ATime.To24HourString;
end;


end.
