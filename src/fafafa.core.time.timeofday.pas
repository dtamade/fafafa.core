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

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  DateUtils,
  fafafa.core.time.base;

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
   *   表示一天中的时间，精确到毫秒。
   *   内部使用自午夜开始的毫秒数存储。
   *
   * @precision
   *   毫秒级精度。
   *
   * @thread_safety
   *   值类型，天然线程安全。
   *
   * @range
   *   00:00:00.000 到 23:59:59.999
   *}
  TTimeOfDay = record
  private
    FMilliseconds: Integer; // 自午夜开始的毫秒数 (0-86399999)
    
    class function IsValidTime(AHour, AMinute, ASecond, AMillisecond: Integer): Boolean; static;
    class function TimeToMilliseconds(AHour, AMinute, ASecond, AMillisecond: Integer): Integer; static;
    class procedure MillisecondsToTime(AMilliseconds: Integer; out AHour, AMinute, ASecond, AMillisecond: Integer); static;
  public
    // 构造函数
    class function Create(AHour, AMinute: Integer; ASecond: Integer = 0; AMillisecond: Integer = 0): TTimeOfDay; static;
    class function FromMilliseconds(AMilliseconds: Integer): TTimeOfDay; static;
    class function FromSeconds(ASeconds: Integer): TTimeOfDay; static;
    class function FromMinutes(AMinutes: Integer): TTimeOfDay; static;
    class function FromHours(AHours: Integer): TTimeOfDay; static;
    class function FromTime(const ATime: TTime): TTimeOfDay; static;
    class function FromDuration(const ADuration: TDuration): TTimeOfDay; static;
    class function Now: TTimeOfDay; static;
    
    // 安全构造函数
    class function TryCreate(AHour, AMinute: Integer; ASecond: Integer = 0; AMillisecond: Integer = 0; out ATime: TTimeOfDay): Boolean; static;
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
    function ToSeconds: Integer; inline;
    function ToMinutes: Integer; inline;
    function ToHours: Double; inline;
    function ToTime: TTime;
    function ToDuration: TDuration;
    function ToISO8601: string; // HH:MM:SS.mmm 格式
    
    // 时间组件
    function GetHour: Integer;
    function GetMinute: Integer;
    function GetSecond: Integer;
    function GetMillisecond: Integer;
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
  MILLISECONDS_PER_SECOND = 1000;
  MILLISECONDS_PER_MINUTE = 60000;
  MILLISECONDS_PER_HOUR = 3600000;
  MILLISECONDS_PER_DAY = 86400000;
  
  SECONDS_PER_MINUTE = 60;
  SECONDS_PER_HOUR = 3600;
  SECONDS_PER_DAY = 86400;
  
  MINUTES_PER_HOUR = 60;
  MINUTES_PER_DAY = 1440;
  
  HOURS_PER_DAY = 24;

implementation

{ TTimeOfDay }

class function TTimeOfDay.IsValidTime(AHour, AMinute, ASecond, AMillisecond: Integer): Boolean;
begin
  Result := (AHour >= 0) and (AHour <= 23) and
            (AMinute >= 0) and (AMinute <= 59) and
            (ASecond >= 0) and (ASecond <= 59) and
            (AMillisecond >= 0) and (AMillisecond <= 999);
end;

class function TTimeOfDay.TimeToMilliseconds(AHour, AMinute, ASecond, AMillisecond: Integer): Integer;
begin
  Result := AHour * MILLISECONDS_PER_HOUR +
            AMinute * MILLISECONDS_PER_MINUTE +
            ASecond * MILLISECONDS_PER_SECOND +
            AMillisecond;
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

class function TTimeOfDay.Create(AHour, AMinute: Integer; ASecond: Integer; AMillisecond: Integer): TTimeOfDay;
begin
  if not IsValidTime(AHour, AMinute, ASecond, AMillisecond) then
    raise ETimeError.CreateFmt('Invalid time: %d:%d:%d.%d', [AHour, AMinute, ASecond, AMillisecond]);
  
  Result.FMilliseconds := TimeToMilliseconds(AHour, AMinute, ASecond, AMillisecond);
end;

class function TTimeOfDay.FromMilliseconds(AMilliseconds: Integer): TTimeOfDay;
begin
  Result.FMilliseconds := AMilliseconds mod MILLISECONDS_PER_DAY;
  if Result.FMilliseconds < 0 then
    Result.FMilliseconds := Result.FMilliseconds + MILLISECONDS_PER_DAY;
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
  Result.FMilliseconds := 0;
end;

class function TTimeOfDay.Noon: TTimeOfDay;
begin
  Result.FMilliseconds := 12 * MILLISECONDS_PER_HOUR;
end;

class function TTimeOfDay.MinValue: TTimeOfDay;
begin
  Result := Midnight;
end;

class function TTimeOfDay.MaxValue: TTimeOfDay;
begin
  Result.FMilliseconds := MILLISECONDS_PER_DAY - 1;
end;

function TTimeOfDay.ToMilliseconds: Integer;
begin
  Result := FMilliseconds;
end;

function TTimeOfDay.ToSeconds: Integer;
begin
  Result := FMilliseconds div MILLISECONDS_PER_SECOND;
end;

function TTimeOfDay.ToTime: TTime;
var
  hour, minute, second, millisecond: Integer;
begin
  MillisecondsToTime(FMilliseconds, hour, minute, second, millisecond);
  Result := EncodeTime(hour, minute, second, millisecond);
end;

function TTimeOfDay.ToDuration: TDuration;
begin
  Result := TDuration.FromMs(FMilliseconds);
end;

function TTimeOfDay.ToISO8601: string;
var
  hour, minute, second, millisecond: Integer;
begin
  MillisecondsToTime(FMilliseconds, hour, minute, second, millisecond);
  if millisecond > 0 then
    Result := Format('%02d:%02d:%02d.%03d', [hour, minute, second, millisecond])
  else
    Result := Format('%02d:%02d:%02d', [hour, minute, second]);
end;

function TTimeOfDay.GetHour: Integer;
var
  minute, second, millisecond: Integer;
begin
  MillisecondsToTime(FMilliseconds, Result, minute, second, millisecond);
end;

function TTimeOfDay.GetMinute: Integer;
var
  hour, second, millisecond: Integer;
begin
  MillisecondsToTime(FMilliseconds, hour, Result, second, millisecond);
end;

function TTimeOfDay.GetSecond: Integer;
var
  hour, minute, millisecond: Integer;
begin
  MillisecondsToTime(FMilliseconds, hour, minute, Result, millisecond);
end;

function TTimeOfDay.GetMillisecond: Integer;
var
  hour, minute, second: Integer;
begin
  MillisecondsToTime(FMilliseconds, hour, minute, second, Result);
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
  Result := FromMilliseconds(FMilliseconds + AMilliseconds);
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
  if FMilliseconds < AOther.FMilliseconds then
    Result := -1
  else if FMilliseconds > AOther.FMilliseconds then
    Result := 1
  else
    Result := 0;
end;

function TTimeOfDay.Equal(const AOther: TTimeOfDay): Boolean;
begin
  Result := FMilliseconds = AOther.FMilliseconds;
end;

function TTimeOfDay.LessThan(const AOther: TTimeOfDay): Boolean;
begin
  Result := FMilliseconds < AOther.FMilliseconds;
end;

function TTimeOfDay.GreaterThan(const AOther: TTimeOfDay): Boolean;
begin
  Result := FMilliseconds > AOther.FMilliseconds;
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
  Result := FMilliseconds = 0;
end;

function TTimeOfDay.IsNoon: Boolean;
begin
  Result := FMilliseconds = 12 * MILLISECONDS_PER_HOUR;
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

class operator TTimeOfDay.<(const A, B: TTimeOfDay): Boolean;
begin
  Result := A.LessThan(B);
end;

class operator TTimeOfDay.>(const A, B: TTimeOfDay): Boolean;
begin
  Result := A.GreaterThan(B);
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

end.
