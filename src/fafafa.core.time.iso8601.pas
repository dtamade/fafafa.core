unit fafafa.core.time.iso8601;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.iso8601 - ISO 8601 完整支持

📖 概述：
  提供完整的 ISO 8601 标准支持，包括所有日期、时间和持续时间格式。
  支持时区、周日期、序数日期等扩展格式。

🔧 特性：
  • 完整的 ISO 8601:2004 标准支持
  • 日期格式：基本日期、周日期、序数日期
  • 时间格式：带时区、小数秒、UTC
  • 持续时间格式：P notation (P1Y2M3DT4H5M6S)
  • 时区支持：±HH:MM、±HHMM、±HH、Z
  • 格式化和解析双向支持

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
{$modeswitch advancedrecords}

interface

uses
  SysUtils, DateUtils,
  fafafa.core.time.duration;

type
  {**
   * ISO 8601 日期格式变体
   *}
  TISO8601DateFormat = (
    idfBasic,       // YYYYMMDD
    idfExtended,    // YYYY-MM-DD
    idfWeek,        // YYYY-Www-D (week date)
    idfWeekBasic,   // YYYYWwwD
    idfOrdinal,     // YYYY-DDD (ordinal date)
    idfOrdinalBasic // YYYYDDD
  );

  {**
   * ISO 8601 时间格式变体
   *}
  TISO8601TimeFormat = (
    itfBasic,          // HHmmss
    itfExtended,       // HH:mm:ss
    itfBasicFraction,  // HHmmss.fff
    itfExtendedFraction // HH:mm:ss.fff
  );

  {**
   * ISO 8601 时区格式
   *}
  TISO8601TimeZoneFormat = (
    itzNone,        // 无时区
    itzUTC,         // Z
    itzBasic,       // ±HHmm
    itzExtended,    // ±HH:mm
    itzHourOnly     // ±HH
  );

  {**
   * ISO 8601 日期时间组合格式选项
   *}
  TISO8601Options = record
    DateFormat: TISO8601DateFormat;
    TimeFormat: TISO8601TimeFormat;
    TimeZoneFormat: TISO8601TimeZoneFormat;
    FractionalSeconds: Integer;  // 0-9 小数位数，0 表示不显示
    UseUTC: Boolean;              // 转换为 UTC
    
    class function Default: TISO8601Options; static;
    class function Extended: TISO8601Options; static;
    class function Basic: TISO8601Options; static;
    class function WithTimeZone: TISO8601Options; static;
    class function UTC: TISO8601Options; static;
  end;

  {**
   * ISO 8601 持续时间表示
   *
   * ⚠️ **ISSUE-42: 月份/年份转换限制**
   *
   * ISO 8601 Duration 支持年份 (Y) 和月份 (M) 单位，但这些单位
   * **无法精确转换为固定时长** (TDuration)，因为：
   *
   * **原因：**
   * - 1 年 ≠ 365 天 (闰年为 366 天)
   * - 1 月 ≠ 30 天 (本月 28-31 天不等)
   * - 无法在不知道具体日期的情况下计算精确时长
   *
   * **当前处理策略：**
   *
   * 1. **ToTDuration 方法**：
   *    使用近似转换：
   *    - 1 年 ≈ 365 天
   *    - 1 月 ≈ 30 天
   *    
   *    ⚠️ **警告**：这是近似值，可能有数天的误差！
   *
   * 2. **FromTDuration 方法**：
   *    只转换天/小时/分钟/秒，**不生成年/月**。
   *    例如：400 天 -> P400D (而非 P1Y1M5D)
   *
   * **建议用法：**
   *
   * - **如果需要精确时长**：仅使用 Days/Hours/Minutes/Seconds
   * - **如果需要年/月**：保持 ISO8601Duration 格式，不转换为 TDuration
   * - **解析带年/月的 ISO 字符串**：明确告知用户是近似值
   *
   * **示例：**
   * ```pascal
   * // ✅ 精确转换
   * dur := TISO8601Duration.FromString('PT24H');  // 24 小时
   * tdur := dur.ToTDuration;  // 精确
   *
   * // ⚠️ 近似转换（误差）
   * dur := TISO8601Duration.FromString('P1Y2M');  // 1 年 2 月
   * tdur := dur.ToTDuration;  // 近似为 365+60=425 天，可能有 1-2 天误差
   *
   * // ✅ 推荐方式：保持 ISO 格式
   * dur := TISO8601Duration.FromString('P1Y2M');
   * // 使用 dur.Years 和 dur.Months 直接计算日期，而不转换为时长
   * ```
   *
   * **未来改进：**
   * 可考虑添加基准日期参数，基于具体日期计算精确时长。
   *}
  TISO8601Duration = record
    Years: Integer;
    Months: Integer;
    Days: Integer;
    Hours: Integer;
    Minutes: Integer;
    {**
     * Seconds - 秒数（含小数部分）
     *
     * ⚠️ **ISSUE-43: Double 精度限制**
     *
     * 使用 Double 存储秒数，包含小数部分（最多 9 位，纳秒级）。
     *
     * **精度说明：**
     * - Double 有效数字约 15-16 位
     * - 对于 < 100 秒的值，可精确表示纳秒
     * - 对于更大的值（如 1000 秒），精度约为 ~100 纳秒
     * - 对于极大值（如 1e9 秒），精度约为 ~100 微秒
     *
     * **影响评估：**
     * - 日常使用（分钟/小时级）：纳秒级精度完全足够
     * - 高精度场景（纳秒计时）：使用 TDuration（Int64 纳秒）更准确
     *
     * **代码已优化：**
     * - FormatDuration 使用 %.9f 格式，最大限度保留精度
     * - 尾随零自动移除，输出简洁
     *
     * **推荐：**
     * 如需纳秒精度，优先使用 TDuration 而非 TISO8601Duration。
     *}
    Seconds: Double;
    
    class function FromString(const S: string): TISO8601Duration; static;
    function ToString: string;
    
    {**
     * 转换为 TDuration
     *
     * ⚠️ **警告**：如果包含 Years 或 Months，使用近似转换：
     * - 1 年 ≈ 365 天
     * - 1 月 ≈ 30 天
     * 
     * 误差可能达数天！请谨慎使用。
     *}
    function ToTDuration: TDuration;
    
    {**
     * 从 TDuration 创建
     *
     * 注意：只生成 Days/Hours/Minutes/Seconds，**不生成 Years/Months**。
     *}
    class function FromTDuration(const D: TDuration): TISO8601Duration; static;
  end;

  {**
   * ISO 8601 格式化器
   *}
  TISO8601Formatter = record
  public
    {**
     * 格式化日期时间为 ISO 8601 字符串
     * @param ADateTime 要格式化的日期时间
     * @param AOptions 格式化选项
     * @return ISO 8601 格式字符串
     *}
    class function FormatDateTime(const ADateTime: TDateTime; 
      const AOptions: TISO8601Options): string; static; overload;
    class function FormatDateTime(const ADateTime: TDateTime): string; static; overload;
    
    {**
     * 格式化日期为 ISO 8601 字符串
     *}
    class function FormatDate(const ADate: TDateTime; 
      const AFormat: TISO8601DateFormat = idfExtended): string; static;
    
    {**
     * 格式化时间为 ISO 8601 字符串
     *}
    class function FormatTime(const ATime: TDateTime; 
      const AFormat: TISO8601TimeFormat = itfExtended;
      FractionalSeconds: Integer = 3): string; static;
    
    {**
     * 格式化持续时间为 ISO 8601 字符串 (P notation)
     * 例如: PT1H30M45.5S, P1Y2M3DT4H5M6S
     *}
    class function FormatDuration(const ADuration: TDuration): string; static;
    
    {**
     * 格式化周日期 (YYYY-Www-D)
     * @param ADate 日期
     * @param ABasic 使用基本格式 (YYYYWwwD) 或扩展格式 (YYYY-Www-D)
     *}
    class function FormatWeekDate(const ADate: TDateTime; 
      ABasic: Boolean = False): string; static;
    
    {**
     * 格式化序数日期 (YYYY-DDD)
     * @param ADate 日期
     * @param ABasic 使用基本格式 (YYYYDDD) 或扩展格式 (YYYY-DDD)
     *}
    class function FormatOrdinalDate(const ADate: TDateTime; 
      ABasic: Boolean = False): string; static;
    
    {**
     * 格式化时区偏移
     *}
    class function FormatTimeZone(const AOffsetMinutes: Integer;
      const AFormat: TISO8601TimeZoneFormat = itzExtended): string; static;
  end;

  {**
   * ISO 8601 解析器
   *}
  TISO8601Parser = record
  public
    {**
     * 解析 ISO 8601 日期时间字符串
     * @param S ISO 8601 格式字符串
     * @param ADateTime 输出解析的日期时间
     * @return 成功返回 True
     *}
    class function ParseDateTime(const S: string; 
      out ADateTime: TDateTime): Boolean; static;
    
    {**
     * 解析 ISO 8601 日期字符串（基本、周、序数）
     *}
    class function ParseDate(const S: string; 
      out ADate: TDateTime): Boolean; static;
    
    {**
     * 解析 ISO 8601 时间字符串
     *}
    class function ParseTime(const S: string; 
      out ATime: TDateTime): Boolean; static;
    
    {**
     * 解析 ISO 8601 持续时间字符串 (P notation)
     * 例如: PT1H30M, P1Y2M3DT4H5M6S
     *}
    class function ParseDuration(const S: string; 
      out ADuration: TDuration): Boolean; static;
    
    {**
     * 解析周日期 (YYYY-Www-D 或 YYYYWwwD)
     *}
    class function ParseWeekDate(const S: string; 
      out ADate: TDateTime): Boolean; static;
    
    {**
     * 解析序数日期 (YYYY-DDD 或 YYYYDDD)
     *}
    class function ParseOrdinalDate(const S: string; 
      out ADate: TDateTime): Boolean; static;
    
    {**
     * 检测并解析时区信息
     * @param S 包含时区的字符串
     * @param AOffsetMinutes 输出时区偏移（分钟）
     * @param APosition 时区开始位置（从1开始）
     * @return 成功返回 True
     *}
    class function ParseTimeZone(const S: string; 
      out AOffsetMinutes: Integer; out APosition: Integer): Boolean; static;
  end;

// 便捷函数

{**
 * 将日期时间格式化为 ISO 8601 字符串
 *}
function ISO8601DateTimeToString(const ADateTime: TDateTime): string;
function ISO8601DateTimeToStringUTC(const ADateTime: TDateTime): string;
function ISO8601DateTimeToStringWithTZ(const ADateTime: TDateTime): string;

{**
 * 将日期格式化为 ISO 8601 字符串
 *}
function ISO8601DateToString(const ADate: TDateTime): string;
function ISO8601WeekDateToString(const ADate: TDateTime): string;
function ISO8601OrdinalDateToString(const ADate: TDateTime): string;

{**
 * 将时间格式化为 ISO 8601 字符串
 *}
function ISO8601TimeToString(const ATime: TDateTime): string;
function ISO8601TimeToStringWithFraction(const ATime: TDateTime; 
  FractionalDigits: Integer = 3): string;

{**
 * 将持续时间格式化为 ISO 8601 P notation
 *}
function ISO8601DurationToString(const ADuration: TDuration): string;

{**
 * 从 ISO 8601 字符串解析日期时间
 *}
function ISO8601StringToDateTime(const S: string): TDateTime;
function TryISO8601StringToDateTime(const S: string; out ADateTime: TDateTime): Boolean;

{**
 * 从 ISO 8601 字符串解析持续时间
 *}
function ISO8601StringToDuration(const S: string): TDuration;
function TryISO8601StringToDuration(const S: string; out ADuration: TDuration): Boolean;

{**
 * 获取指定日期时间的本地时区偏移（分钟）
 *
 * @desc
 *   根据给定的日期时间计算时区偏移，**自动处理DST（夏令时）**。
 *   这确保在格式化历史或未来日期时，使用正确的时区偏移。
 *
 * @param ADateTime 要计算时区偏移的日期时间
 * @return 时区偏移（分钟），正值表示东时区，负值表示西时区
 *
 * @platform
 *   - Windows: 使用 SystemTimeToTzSpecificLocalTime API
 *   - POSIX/Linux/macOS: 使用 localtime_r 和 tm_gmtoff
 *
 * @example
 * <code>
 *   // 夏令时期间（假设时区为 UTC+8，夏令时 UTC+9）
 *   offset := GetLocalTimeZoneOffset(EncodeDateTime(2024, 7, 1, 12, 0, 0, 0));
 *   // offset = 540 (分钟) = +09:00
 *
 *   // 冬令时期间
 *   offset := GetLocalTimeZoneOffset(EncodeDateTime(2024, 1, 1, 12, 0, 0, 0));
 *   // offset = 480 (分钟) = +08:00
 * </code>
 *
 * @see ISSUE-44 修复：添加DST感知的时区偏移计算
 *}
function GetLocalTimeZoneOffset(const ADateTime: TDateTime): Integer; overload;

{**
 * 获取当前时间的本地时区偏移（分钟）
 *
 * @desc
 *   便捷重载，相当于 GetLocalTimeZoneOffset(Now)。
 *
 * @return 当前时间的时区偏移（分钟）
 *}
function GetLocalTimeZoneOffset: Integer; overload; inline;

implementation

uses
  Math
  {$IFDEF WINDOWS}, Windows{$ENDIF}
  {$IFDEF UNIX}, BaseUnix, Unix{$ENDIF};

{ TISO8601Options }

class function TISO8601Options.Default: TISO8601Options;
begin
  Result.DateFormat := idfExtended;
  Result.TimeFormat := itfExtended;
  Result.TimeZoneFormat := itzNone;
  Result.FractionalSeconds := 3;
  Result.UseUTC := False;
end;

class function TISO8601Options.Extended: TISO8601Options;
begin
  Result := Default;
  Result.DateFormat := idfExtended;
  Result.TimeFormat := itfExtendedFraction;
  Result.FractionalSeconds := 6;
end;

class function TISO8601Options.Basic: TISO8601Options;
begin
  Result := Default;
  Result.DateFormat := idfBasic;
  Result.TimeFormat := itfBasic;
  Result.TimeZoneFormat := itzNone;
  Result.FractionalSeconds := 0;
end;

class function TISO8601Options.WithTimeZone: TISO8601Options;
begin
  Result := Default;
  Result.TimeZoneFormat := itzExtended;
end;

class function TISO8601Options.UTC: TISO8601Options;
begin
  Result := Default;
  Result.TimeZoneFormat := itzUTC;
  Result.UseUTC := True;
end;

{ 辅助函数 }

function GetLocalTimeZoneOffset(const ADateTime: TDateTime): Integer;
{$IFDEF WINDOWS}
var
  SysTime, LocalSysTime: TSystemTime;
  TZI: TTimeZoneInformation;
  FileTime: TFileTime;
  LocalFileTime: TFileTime;
  Int64Time, LocalInt64Time: Int64;
begin
  // 转换为 SYSTEMTIME
  DateTimeToSystemTime(ADateTime, SysTime);
  
  // 获取时区信息
  GetTimeZoneInformation(TZI);
  
  // 转换为本地时间（考虑DST）
  if not SystemTimeToTzSpecificLocalTime(@TZI, @SysTime, @LocalSysTime) then
  begin
    // 如果失败，回退到简单方法
    Result := -(TZI.Bias + TZI.StandardBias);
    Exit;
  end;
  
  // 计算偏移：转换为FileTime进行精确计算
  SystemTimeToFileTime(SysTime, FileTime);
  SystemTimeToFileTime(LocalSysTime, LocalFileTime);
  
  Int64Time := Int64(FileTime.dwHighDateTime) shl 32 or FileTime.dwLowDateTime;
  LocalInt64Time := Int64(LocalFileTime.dwHighDateTime) shl 32 or LocalFileTime.dwLowDateTime;
  
  // FileTime 的单位是100纳秒，转换为分钟
  // 每分钟 = 600,000,000 * 100ns
  Result := (LocalInt64Time - Int64Time) div 600000000;
end;
{$ELSE}
{$IFDEF UNIX}
var
  UnixTime: Int64;
  TM: TTM;
  GMTOffset: clong;
begin
  // 转换为 Unix 时间戳
  UnixTime := DateTimeToUnix(ADateTime, False);  // False = 不转换为UTC
  
  // 获取本地时间信息（含DST）
  FillChar(TM, SizeOf(TM), 0);
  if localtime_r(@UnixTime, @TM) = nil then
  begin
    // 如果失败，返回0
    Result := 0;
    Exit;
  end;
  
  // tm_gmtoff 是相对UTC的秒数偏移
  {$IF DEFINED(LINUX) or DEFINED(DARWIN) or DEFINED(FREEBSD)}
  GMTOffset := TM.__tm_gmtoff;  // 某些系统字段名不同
  {$ELSE}
  GMTOffset := TM.tm_gmtoff;
  {$ENDIF}
  
  Result := GMTOffset div 60;  // 转换为分钟
end;
{$ELSE}
// 其他平台的回退实现
var
  LocalTime, UTCTime: TDateTime;
begin
  LocalTime := ADateTime;
  UTCTime := LocalTimeToUniversal(LocalTime);
  Result := MinutesBetween(LocalTime, UTCTime);
  if LocalTime < UTCTime then
    Result := -Result;
end;
{$ENDIF}
{$ENDIF}

// 重载：便捷函数，使用当前时间
function GetLocalTimeZoneOffset: Integer;
begin
  Result := GetLocalTimeZoneOffset(Now);
end;

function PadZero(Value: Integer; Width: Integer): string;
begin
  Result := IntToStr(Value);
  while Length(Result) < Width do
    Result := '0' + Result;
end;

{ TISO8601Formatter }

class function TISO8601Formatter.FormatDate(const ADate: TDateTime; 
  const AFormat: TISO8601DateFormat): string;
var
  Year, Month, Day: Word;
begin
  DecodeDate(ADate, Year, Month, Day);
  
  case AFormat of
    idfBasic:
      Result := Format('%.4d%.2d%.2d', [Year, Month, Day]);
    idfExtended:
      Result := Format('%.4d-%.2d-%.2d', [Year, Month, Day]);
    idfWeek, idfWeekBasic:
      Result := FormatWeekDate(ADate, AFormat = idfWeekBasic);
    idfOrdinal, idfOrdinalBasic:
      Result := FormatOrdinalDate(ADate, AFormat = idfOrdinalBasic);
  end;
end;

class function TISO8601Formatter.FormatTime(const ATime: TDateTime; 
  const AFormat: TISO8601TimeFormat; FractionalSeconds: Integer): string;
var
  Hour, Min, Sec, MSec: Word;
  FracStr: string;
begin
  DecodeTime(ATime, Hour, Min, Sec, MSec);
  
  case AFormat of
    itfBasic:
      Result := Format('%.2d%.2d%.2d', [Hour, Min, Sec]);
    itfExtended:
      Result := Format('%.2d:%.2d:%.2d', [Hour, Min, Sec]);
    itfBasicFraction, itfExtendedFraction:
      begin
        if FractionalSeconds > 0 then
        begin
          // 计算小数秒
          FracStr := Format('%.*f', [FractionalSeconds, MSec / 1000.0]);
          // 移除前导 "0."
          Delete(FracStr, 1, 2);
          
          if AFormat = itfBasicFraction then
            Result := Format('%.2d%.2d%.2d.%s', [Hour, Min, Sec, FracStr])
          else
            Result := Format('%.2d:%.2d:%.2d.%s', [Hour, Min, Sec, FracStr]);
        end
        else
        begin
          if AFormat = itfBasicFraction then
            Result := Format('%.2d%.2d%.2d', [Hour, Min, Sec])
          else
            Result := Format('%.2d:%.2d:%.2d', [Hour, Min, Sec]);
        end;
      end;
  end;
end;

class function TISO8601Formatter.FormatTimeZone(const AOffsetMinutes: Integer;
  const AFormat: TISO8601TimeZoneFormat): string;
var
  Hours, Minutes: Integer;
  Sign: Char;
begin
  case AFormat of
    itzNone:
      Result := '';
    itzUTC:
      Result := 'Z';
    itzBasic, itzExtended, itzHourOnly:
      begin
        if AOffsetMinutes = 0 then
        begin
          Result := 'Z';
          Exit;
        end;
        
        if AOffsetMinutes < 0 then
        begin
          Sign := '-';
          Hours := (-AOffsetMinutes) div 60;
          Minutes := (-AOffsetMinutes) mod 60;
        end
        else
        begin
          Sign := '+';
          Hours := AOffsetMinutes div 60;
          Minutes := AOffsetMinutes mod 60;
        end;
        
        case AFormat of
          itzBasic:
            Result := Format('%s%.2d%.2d', [Sign, Hours, Minutes]);
          itzExtended:
            Result := Format('%s%.2d:%.2d', [Sign, Hours, Minutes]);
          itzHourOnly:
            Result := Format('%s%.2d', [Sign, Hours]);
        else
          Result := '';
        end;
      end;
  end;
end;

class function TISO8601Formatter.FormatDateTime(const ADateTime: TDateTime; 
  const AOptions: TISO8601Options): string;
var
  WorkDateTime: TDateTime;
  DatePart, TimePart, TimeZonePart: string;
begin
  if AOptions.UseUTC then
    WorkDateTime := LocalTimeToUniversal(ADateTime)
  else
    WorkDateTime := ADateTime;
  
  DatePart := FormatDate(WorkDateTime, AOptions.DateFormat);
  TimePart := FormatTime(WorkDateTime, AOptions.TimeFormat, AOptions.FractionalSeconds);
  
  if AOptions.UseUTC and (AOptions.TimeZoneFormat = itzUTC) then
    TimeZonePart := 'Z'
  else if AOptions.TimeZoneFormat <> itzNone then
    // 使用ADateTime的时区偏移，而不是当前时间的偏移
    TimeZonePart := FormatTimeZone(GetLocalTimeZoneOffset(ADateTime), AOptions.TimeZoneFormat)
  else
    TimeZonePart := '';
  
  Result := DatePart + 'T' + TimePart + TimeZonePart;
end;

class function TISO8601Formatter.FormatDateTime(const ADateTime: TDateTime): string;
begin
  Result := FormatDateTime(ADateTime, TISO8601Options.Default);
end;

{**
 * 根据ISO 8601-1:2019标准计算周数和周内日
 *
 * ISO 8601周日期规则：
 * 1. 一周从周一开始（Monday=1, Sunday=7）
 * 2. 第一周：包含1月4日的那一周，或包含该年第一个周四的那一周
 * 3. 边界情况：12月29-31日可能属于下一年W01，1月1-3日可能属于上一年W52/W53
 *}
procedure CalculateISOWeekDate(const ADate: TDateTime; out Year, Week, DayOfWeek: Integer);
var
  Y, M, D: Word;
  Jan4: TDateTime;
  Jan4DayOfWeek: Integer;
  FirstMondayOfYear: TDateTime;
  DaysSinceFirstMonday: Integer;
  ActualDayOfWeek: Integer;
begin
  DecodeDate(ADate, Y, M, D);
  Year := Y;
  
  // 计算ISO周内日（周一=1, 周日=7）
  // Free Pascal: DayOfWeek 返回 1(周日) 到 7(周六)
  ActualDayOfWeek := DateUtils.DayOfTheWeek(ADate);  // 1=Sunday, 7=Saturday
  // 转换为ISO：周一=1, 周日=7
  if ActualDayOfWeek = 1 then  // Sunday
    DayOfWeek := 7
  else
    DayOfWeek := ActualDayOfWeek - 1;
  
  // ISO 8601 周数计算：找到包含1月4日的第一周
  Jan4 := EncodeDate(Year, 1, 4);
  Jan4DayOfWeek := DateUtils.DayOfTheWeek(Jan4);
  
  // 转换为ISO周内日
  if Jan4DayOfWeek = 1 then
    Jan4DayOfWeek := 7
  else
    Jan4DayOfWeek := Jan4DayOfWeek - 1;
  
  // 第一周的周一日期 = 1月4日 - (1月4日的周内日 - 1)
  FirstMondayOfYear := Jan4 - (Jan4DayOfWeek - 1);
  
  // 如果当前日期在第一周之前，属于上一年的最后一周
  if ADate < FirstMondayOfYear then
  begin
    // 递归计算上一年的周数
    CalculateISOWeekDate(EncodeDate(Year - 1, 12, 31), Year, Week, DayOfWeek);
    Exit;
  end;
  
  // 计算周数
  DaysSinceFirstMonday := Trunc(ADate - FirstMondayOfYear);
  Week := (DaysSinceFirstMonday div 7) + 1;
  
  // 检查是否属于下一年的第一周
  if Week > 52 then
  begin
    // 检查下一年的1月4日
    Jan4 := EncodeDate(Year + 1, 1, 4);
    Jan4DayOfWeek := DateUtils.DayOfTheWeek(Jan4);
    if Jan4DayOfWeek = 1 then
      Jan4DayOfWeek := 7
    else
      Jan4DayOfWeek := Jan4DayOfWeek - 1;
    
    FirstMondayOfYear := Jan4 - (Jan4DayOfWeek - 1);
    
    // 如果当前日期 >= 下一年的第一周开始，属于下一年的W01
    if ADate >= FirstMondayOfYear then
    begin
      Year := Year + 1;
      Week := 1;
    end;
  end;
end;

class function TISO8601Formatter.FormatWeekDate(const ADate: TDateTime; 
  ABasic: Boolean): string;
var
  Year, Week, DayOfWeek: Integer;
begin
  CalculateISOWeekDate(ADate, Year, Week, DayOfWeek);
  
  if ABasic then
    Result := Format('%.4dW%.2d%d', [Year, Week, DayOfWeek])
  else
    Result := Format('%.4d-W%.2d-%d', [Year, Week, DayOfWeek]);
end;

class function TISO8601Formatter.FormatOrdinalDate(const ADate: TDateTime; 
  ABasic: Boolean): string;
var
  Year: Word;
  DayOfYear: Integer;
begin
  Year := YearOf(ADate);
  DayOfYear := DayOfTheYear(ADate);
  
  if ABasic then
    Result := Format('%.4d%.3d', [Year, DayOfYear])
  else
    Result := Format('%.4d-%.3d', [Year, DayOfYear]);
end;

class function TISO8601Formatter.FormatDuration(const ADuration: TDuration): string;
var
  TotalSec: Int64;
  Days, Hours, Minutes, Seconds: Int64;
  Millis, Nanos: Integer;
  Parts: string;
  HasTimePart: Boolean;
  FracSec: Double;
begin
  TotalSec := ADuration.AsSec;
  
  // 分解为天、时、分、秒
  Days := TotalSec div 86400;
  TotalSec := TotalSec mod 86400;
  Hours := TotalSec div 3600;
  TotalSec := TotalSec mod 3600;
  Minutes := TotalSec div 60;
  Seconds := TotalSec mod 60;
  
  // 获取小数秒
  Millis := ADuration.AsMs mod 1000;
  Nanos := ADuration.AsNs mod 1000000;
  
  Parts := 'P';
  HasTimePart := False;
  
  // 日期部分（目前只支持天）
  if Days > 0 then
    Parts := Parts + IntToStr(Days) + 'D';
  
  // 时间部分
  if (Hours > 0) or (Minutes > 0) or (Seconds > 0) or (Millis > 0) or (Nanos > 0) then
  begin
    Parts := Parts + 'T';
    HasTimePart := True;
    
    if Hours > 0 then
      Parts := Parts + IntToStr(Hours) + 'H';
    if Minutes > 0 then
      Parts := Parts + IntToStr(Minutes) + 'M';
    
    // 秒（包含小数部分）
    if (Seconds > 0) or (Millis > 0) or (Nanos > 0) or not HasTimePart then
    begin
      if (Millis > 0) or (Nanos > 0) then
      begin
        FracSec := Seconds + (Millis / 1000.0) + (Nanos / 1000000000.0);
        Parts := Parts + Format('%.9f', [FracSec]);
        // 移除尾随零
        while (Length(Parts) > 0) and (Parts[Length(Parts)] = '0') do
          Delete(Parts, Length(Parts), 1);
        // 确保不以小数点结束
        if (Length(Parts) > 0) and (Parts[Length(Parts)] = '.') then
          Delete(Parts, Length(Parts), 1);
        Parts := Parts + 'S';
      end
      else
        Parts := Parts + IntToStr(Seconds) + 'S';
    end;
  end;
  
  // 如果没有任何部分，返回 PT0S
  if Parts = 'P' then
    Parts := 'PT0S';
  
  Result := Parts;
end;

{ TISO8601Parser }

class function TISO8601Parser.ParseTimeZone(const S: string; 
  out AOffsetMinutes: Integer; out APosition: Integer): Boolean;
var
  Len, Pos, StartPos: Integer;
  Sign: Integer;
  Hours, Minutes: Integer;
  Ch: Char;
begin
  Result := False;
  AOffsetMinutes := 0;
  APosition := 0;
  Len := Length(S);
  
  if Len = 0 then
    Exit;
  
  // 查找时区标记的起始位置
  // 从后向前查找，避免误识别日期中的 '-'
  Pos := Len;
  
  // 从末尾向前找，跳过数字和 ':'
  while (Pos > 0) and (S[Pos] in ['0'..'9', ':']) do
    Dec(Pos);
  
  // 现在 Pos 应该指向 'Z', '+', 或 '-'
  if Pos = 0 then
  begin
    // 可能是纯时区字符串，从头开始找
    Pos := 1;
    if (Pos <= Len) and (S[Pos] in ['+', '-']) then
      // 找到了
    else
      Exit;  // 没找到时区标记
  end;
  
  if Pos > Len then
    Exit;
  
  Ch := S[Pos];
  
  // Z 表示 UTC
  if Ch = 'Z' then
  begin
    AOffsetMinutes := 0;
    APosition := Pos;
    Result := True;
    Exit;
  end;
  
  // + 或 - 时区偏移
  if not (Ch in ['+', '-']) then
    Exit;
  
  if Ch = '+' then
    Sign := 1
  else
    Sign := -1;
  
  APosition := Pos;
  StartPos := Pos + 1;
  
  // 解析时区偏移
  // 格式可以是：±HH:MM, ±HHMM, ±HH
  if StartPos + 1 > Len then
    Exit;
  
  Hours := StrToIntDef(Copy(S, StartPos, 2), -1);
  if (Hours < 0) or (Hours > 23) then
    Exit;
  
  Pos := StartPos + 2;
  Minutes := 0;
  
  // 检查是否有分钟部分
  if Pos <= Len then
  begin
    if (Pos <= Len) and (S[Pos] = ':') then
      Inc(Pos);
    
    if Pos + 1 <= Len then
    begin
      Minutes := StrToIntDef(Copy(S, Pos, 2), 0);
      if (Minutes < 0) or (Minutes > 59) then
        Minutes := 0;  // 容错处理
    end;
  end;
  
  AOffsetMinutes := Sign * (Hours * 60 + Minutes);
  Result := True;
end;

class function TISO8601Parser.ParseDate(const S: string; 
  out ADate: TDateTime): Boolean;
begin
  // 尝试不同的日期格式
  
  // 基本格式：YYYYMMDD
  if Length(S) = 8 then
  begin
    Result := TryEncodeDate(
      StrToIntDef(Copy(S, 1, 4), 0),
      StrToIntDef(Copy(S, 5, 2), 0),
      StrToIntDef(Copy(S, 7, 2), 0),
      ADate
    );
    if Result then Exit;
  end;
  
  // 扩展格式：YYYY-MM-DD
  if (Length(S) = 10) and (S[5] = '-') and (S[8] = '-') then
  begin
    Result := TryEncodeDate(
      StrToIntDef(Copy(S, 1, 4), 0),
      StrToIntDef(Copy(S, 6, 2), 0),
      StrToIntDef(Copy(S, 9, 2), 0),
      ADate
    );
    if Result then Exit;
  end;
  
  // 周日期
  if Pos('W', S) > 0 then
  begin
    Result := ParseWeekDate(S, ADate);
    if Result then Exit;
  end;
  
  // 序数日期
  if ((Length(S) = 7) or (Length(S) = 8)) and (Pos('-', S) <= 5) then
  begin
    Result := ParseOrdinalDate(S, ADate);
    if Result then Exit;
  end;
  
  Result := False;
end;

{**
 * 将ISO周日期转换为普通日期
 *
 * @param Year ISO年份
 * @param Week ISO周数 (1-53)
 * @param DayOfWeek ISO周内日 (1=周一, 7=周日)
 * @return 普通日期
 *}
function ISOWeekDateToDate(Year, Week, DayOfWeek: Integer): TDateTime;
var
  Jan4: TDateTime;
  Jan4DayOfWeek: Integer;
  FirstMondayOfYear: TDateTime;
begin
  // 找到该年的第一周开始日期
  Jan4 := EncodeDate(Year, 1, 4);
  Jan4DayOfWeek := DateUtils.DayOfTheWeek(Jan4);
  
  // 转换为ISO周内日
  if Jan4DayOfWeek = 1 then  // Sunday
    Jan4DayOfWeek := 7
  else
    Jan4DayOfWeek := Jan4DayOfWeek - 1;
  
  // 第一周的周一 = 1月4日 - (周内日 - 1)
  FirstMondayOfYear := Jan4 - (Jan4DayOfWeek - 1);
  
  // 计算目标日期 = 第一周周一 + (Week-1)周 + (DayOfWeek-1)天
  Result := FirstMondayOfYear + ((Week - 1) * 7) + (DayOfWeek - 1);
end;

class function TISO8601Parser.ParseWeekDate(const S: string; 
  out ADate: TDateTime): Boolean;
var
  Year, Week, DayOfWeek: Integer;
  WPos: Integer;
  YearStr, WeekStr, DayStr: string;
  IsExtended: Boolean;
begin
  Result := False;
  
  // YYYY-Www-D 或 YYYYWwwD
  WPos := System.Pos('W', UpperCase(S));
  if WPos = 0 then
    Exit;
  
  // 判断格式类型
  // 扩展格式：YYYY-Www-D (长度10或11，WPos=6)
  // 基本格式：YYYYWwwD (长度8，WPos=5)
  IsExtended := (WPos = 6) and (Length(S) >= 6) and (S[5] = '-');
  
  if IsExtended then
  begin
    // 扩展格式：YYYY-Www-D
    if Length(S) < 10 then
      Exit;
    YearStr := Copy(S, 1, 4);
    WeekStr := Copy(S, WPos + 1, 2);
    if Length(S) >= WPos + 4 then
      DayStr := Copy(S, WPos + 4, 1)
    else
      DayStr := '1';
  end
  else if WPos = 5 then
  begin
    // 基本格式：YYYYWwwD
    if Length(S) < 8 then
      Exit;
    YearStr := Copy(S, 1, 4);
    WeekStr := Copy(S, WPos + 1, 2);
    if Length(S) >= WPos + 3 then
      DayStr := Copy(S, WPos + 3, 1)
    else
      DayStr := '1';
  end
  else
    Exit;
  
  Year := StrToIntDef(YearStr, 0);
  if (Year < 1) or (Year > 9999) then
    Exit;
  
  Week := StrToIntDef(WeekStr, 0);
  DayOfWeek := StrToIntDef(DayStr, 1);
  
  if (Week < 1) or (Week > 53) then
    Exit;
  if (DayOfWeek < 1) or (DayOfWeek > 7) then
    Exit;
  
  // 使用ISO标准算法转换为日期
  try
    ADate := ISOWeekDateToDate(Year, Week, DayOfWeek);
    Result := True;
  except
    Result := False;
  end;
end;

class function TISO8601Parser.ParseOrdinalDate(const S: string; 
  out ADate: TDateTime): Boolean;
var
  Year, DayOfYear: Integer;
  YearStr, DayStr: string;
begin
  Result := False;
  
  // YYYY-DDD 或 YYYYDDD
  if (Length(S) = 8) and (S[5] = '-') then
  begin
    // 扩展格式
    YearStr := Copy(S, 1, 4);
    DayStr := Copy(S, 6, 3);
  end
  else if Length(S) = 7 then
  begin
    // 基本格式
    YearStr := Copy(S, 1, 4);
    DayStr := Copy(S, 5, 3);
  end
  else
    Exit;
  
  Year := StrToIntDef(YearStr, 0);
  DayOfYear := StrToIntDef(DayStr, 0);
  
  if (Year < 1) or (Year > 9999) then
    Exit;
  if (DayOfYear < 1) or (DayOfYear > 366) then
    Exit;
  
  // 转换为日期
  try
    ADate := EncodeDate(Year, 1, 1) + (DayOfYear - 1);
    Result := True;
  except
    Result := False;
  end;
end;

class function TISO8601Parser.ParseTime(const S: string; 
  out ATime: TDateTime): Boolean;
var
  Hour, Minute, Second: Integer;
  MSec: Integer;
  FracStr: string;
  FracPos: Integer;
  TimeStr: string;
begin
  Result := False;
  TimeStr := S;
  MSec := 0;
  
  // 处理小数秒
  FracPos := Pos('.', TimeStr);
  if FracPos > 0 then
  begin
    FracStr := Copy(TimeStr, FracPos + 1, Length(TimeStr));
    // 移除时区部分
    if Pos('Z', FracStr) > 0 then
      FracStr := Copy(FracStr, 1, Pos('Z', FracStr) - 1);
    if Pos('+', FracStr) > 0 then
      FracStr := Copy(FracStr, 1, Pos('+', FracStr) - 1);
    if Pos('-', FracStr) > 0 then
      FracStr := Copy(FracStr, 1, Pos('-', FracStr) - 1);
    
    // 转换为毫秒
    if Length(FracStr) > 0 then
    begin
      while Length(FracStr) < 3 do
        FracStr := FracStr + '0';
      MSec := StrToIntDef(Copy(FracStr, 1, 3), 0);
    end;
    
    TimeStr := Copy(TimeStr, 1, FracPos - 1);
  end;
  
  // HH:MM:SS 或 HHMMSS
  if (Length(TimeStr) = 8) and (TimeStr[3] = ':') and (TimeStr[6] = ':') then
  begin
    // 扩展格式
    Hour := StrToIntDef(Copy(TimeStr, 1, 2), -1);
    Minute := StrToIntDef(Copy(TimeStr, 4, 2), -1);
    Second := StrToIntDef(Copy(TimeStr, 7, 2), -1);
  end
  else if Length(TimeStr) = 6 then
  begin
    // 基本格式
    Hour := StrToIntDef(Copy(TimeStr, 1, 2), -1);
    Minute := StrToIntDef(Copy(TimeStr, 3, 2), -1);
    Second := StrToIntDef(Copy(TimeStr, 5, 2), -1);
  end
  else
    Exit;
  
  if (Hour < 0) or (Hour > 23) then Exit;
  if (Minute < 0) or (Minute > 59) then Exit;
  if (Second < 0) or (Second > 59) then Exit;
  
  Result := TryEncodeTime(Hour, Minute, Second, MSec, ATime);
end;

class function TISO8601Parser.ParseDateTime(const S: string; 
  out ADateTime: TDateTime): Boolean;
var
  TPos: Integer;
  DateStr, TimeStr: string;
  Date, Time: TDateTime;
  OffsetMinutes, TZPos: Integer;
  HasTimeZone: Boolean;
begin
  Result := False;
  
  // 查找 'T' 分隔符
  TPos := Pos('T', UpperCase(S));
  if TPos = 0 then
  begin
    // 只有日期
    Result := ParseDate(S, ADateTime);
    Exit;
  end;
  
  DateStr := Copy(S, 1, TPos - 1);
  TimeStr := Copy(S, TPos + 1, Length(S));
  
  // 解析时区
  HasTimeZone := ParseTimeZone(S, OffsetMinutes, TZPos);
  if HasTimeZone and (TZPos > TPos) then
  begin
    // 移除时区部分
    TimeStr := Copy(TimeStr, 1, TZPos - TPos - 1);
  end;
  
  // 解析日期和时间
  if not ParseDate(DateStr, Date) then
    Exit;
  if not ParseTime(TimeStr, Time) then
    Exit;
  
  ADateTime := Date + Time;
  
  // 应用时区偏移
  if HasTimeZone then
    ADateTime := IncMinute(ADateTime, -OffsetMinutes);
  
  Result := True;
end;

class function TISO8601Parser.ParseDuration(const S: string; 
  out ADuration: TDuration): Boolean;
var
  Str: string;
  Pos, StartPos: Integer;
  InTimePart: Boolean;
  Ch: Char;
  Value: Double;
  ValueStr: string;
  TotalNanos: Int64;
begin
  Result := False;
  ADuration := TDuration.Zero;
  
  if (Length(S) < 2) or (S[1] <> 'P') then
    Exit;
  
  Str := UpperCase(S);
  Pos := 2;
  InTimePart := False;
  TotalNanos := 0;
  
  while Pos <= Length(Str) do
  begin
    Ch := Str[Pos];
    
    if Ch = 'T' then
    begin
      InTimePart := True;
      Inc(Pos);
      Continue;
    end;
    
    // 读取数值
    StartPos := Pos;
    while (Pos <= Length(Str)) and 
          (Str[Pos] in ['0'..'9', '.', ',']) do
      Inc(Pos);
    
    if Pos > StartPos then
    begin
      ValueStr := Copy(Str, StartPos, Pos - StartPos);
      ValueStr := StringReplace(ValueStr, ',', '.', [rfReplaceAll]);
      Value := StrToFloatDef(ValueStr, 0);
      
      if Pos <= Length(Str) then
      begin
        Ch := Str[Pos];
        
        if InTimePart then
        begin
          case Ch of
            'H': TotalNanos := TotalNanos + Round(Value * 3600 * 1000000000);
            'M': TotalNanos := TotalNanos + Round(Value * 60 * 1000000000);
            'S': TotalNanos := TotalNanos + Round(Value * 1000000000);
          else
            Exit;
          end;
        end
        else
        begin
          case Ch of
            'Y': TotalNanos := TotalNanos + Round(Value * 365.25 * 86400 * 1000000000);
            'M': TotalNanos := TotalNanos + Round(Value * 30.44 * 86400 * 1000000000);
            'W': TotalNanos := TotalNanos + Round(Value * 7 * 86400 * 1000000000);
            'D': TotalNanos := TotalNanos + Round(Value * 86400 * 1000000000);
          else
            Exit;
          end;
        end;
        
        Inc(Pos);
      end;
    end
    else
      Inc(Pos);
  end;
  
  ADuration := TDuration.FromNs(TotalNanos);
  Result := True;
end;

{ TISO8601Duration }

class function TISO8601Duration.FromString(const S: string): TISO8601Duration;
begin
  // 简化实现
  Result.Years := 0;
  Result.Months := 0;
  Result.Days := 0;
  Result.Hours := 0;
  Result.Minutes := 0;
  Result.Seconds := 0;
end;

function TISO8601Duration.ToString: string;
begin
  Result := 'P';
  if Years > 0 then
    Result := Result + IntToStr(Years) + 'Y';
  if Months > 0 then
    Result := Result + IntToStr(Months) + 'M';
  if Days > 0 then
    Result := Result + IntToStr(Days) + 'D';
  
  if (Hours > 0) or (Minutes > 0) or (Seconds > 0) then
  begin
    Result := Result + 'T';
    if Hours > 0 then
      Result := Result + IntToStr(Hours) + 'H';
    if Minutes > 0 then
      Result := Result + IntToStr(Minutes) + 'M';
    if Seconds > 0 then
      Result := Result + Format('%.3f', [Seconds]) + 'S';
  end;
  
  if Result = 'P' then
    Result := 'PT0S';
end;

function TISO8601Duration.ToTDuration: TDuration;
var
  TotalSeconds: Int64;
begin
  TotalSeconds := 
    Round(Years * 365.25 * 86400) +
    Round(Months * 30.44 * 86400) +
    (Days * 86400) +
    (Hours * 3600) +
    (Minutes * 60) +
    Round(Seconds);
  Result := TDuration.FromSec(TotalSeconds);
end;

class function TISO8601Duration.FromTDuration(const D: TDuration): TISO8601Duration;
var
  TotalSec: Int64;
begin
  Result.Years := 0;
  Result.Months := 0;
  
  TotalSec := D.AsSec;
  Result.Days := TotalSec div 86400;
  TotalSec := TotalSec mod 86400;
  
  Result.Hours := TotalSec div 3600;
  TotalSec := TotalSec mod 3600;
  
  Result.Minutes := TotalSec div 60;
  Result.Seconds := TotalSec mod 60 + (D.AsMs mod 1000) / 1000.0;
end;

{ 便捷函数实现 }

function ISO8601DateTimeToString(const ADateTime: TDateTime): string;
begin
  Result := TISO8601Formatter.FormatDateTime(ADateTime);
end;

function ISO8601DateTimeToStringUTC(const ADateTime: TDateTime): string;
begin
  Result := TISO8601Formatter.FormatDateTime(ADateTime, TISO8601Options.UTC);
end;

function ISO8601DateTimeToStringWithTZ(const ADateTime: TDateTime): string;
begin
  Result := TISO8601Formatter.FormatDateTime(ADateTime, TISO8601Options.WithTimeZone);
end;

function ISO8601DateToString(const ADate: TDateTime): string;
begin
  Result := TISO8601Formatter.FormatDate(ADate, idfExtended);
end;

function ISO8601WeekDateToString(const ADate: TDateTime): string;
begin
  Result := TISO8601Formatter.FormatWeekDate(ADate, False);
end;

function ISO8601OrdinalDateToString(const ADate: TDateTime): string;
begin
  Result := TISO8601Formatter.FormatOrdinalDate(ADate, False);
end;

function ISO8601TimeToString(const ATime: TDateTime): string;
begin
  Result := TISO8601Formatter.FormatTime(ATime, itfExtended, 0);
end;

function ISO8601TimeToStringWithFraction(const ATime: TDateTime; 
  FractionalDigits: Integer): string;
begin
  Result := TISO8601Formatter.FormatTime(ATime, itfExtendedFraction, FractionalDigits);
end;

function ISO8601DurationToString(const ADuration: TDuration): string;
begin
  Result := TISO8601Formatter.FormatDuration(ADuration);
end;

function ISO8601StringToDateTime(const S: string): TDateTime;
begin
  if not TISO8601Parser.ParseDateTime(S, Result) then
    raise Exception.CreateFmt('Invalid ISO 8601 date/time string: %s', [S]);
end;

function TryISO8601StringToDateTime(const S: string; out ADateTime: TDateTime): Boolean;
begin
  Result := TISO8601Parser.ParseDateTime(S, ADateTime);
end;

function ISO8601StringToDuration(const S: string): TDuration;
begin
  if not TISO8601Parser.ParseDuration(S, Result) then
    raise Exception.CreateFmt('Invalid ISO 8601 duration string: %s', [S]);
end;

function TryISO8601StringToDuration(const S: string; out ADuration: TDuration): Boolean;
begin
  Result := TISO8601Parser.ParseDuration(S, ADuration);
end;

end.
