unit fafafa.core.time.format;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.format - 时间格式化

📖 概述：
  提供时间和日期的格式化功能，支持多种格式模式和本地化设置。
  包含持续时间的人性化格式化和自定义格式支持。

🔧 特性：
  • 多种预定义格式
  • 自定义格式模式
  • 本地化支持
  • 持续时间人性化显示
  • ISO 8601 标准支持

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
──────────────────────────────────────────────────────────────
}

{$modeswitch advancedrecords}

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  DateUtils,
  fafafa.core.time.base,
  fafafa.core.time.duration,
  fafafa.core.time.date,
  fafafa.core.time.timeofday;

type
  // 预定义格式类型
  TDateTimeFormat = (
    dtfISO8601,           // 2023-12-25T14:30:00.000Z
    dtfISO8601Date,       // 2023-12-25
    dtfISO8601Time,       // 14:30:00.000
    dtfRFC3339,           // 2023-12-25T14:30:00.000+08:00
    dtfShort,             // 12/25/23 2:30 PM
    dtfMedium,            // Dec 25, 2023 2:30:00 PM
    dtfLong,              // December 25, 2023 at 2:30:00 PM UTC+8
    dtfFull,              // Monday, December 25, 2023 at 2:30:00 PM China Standard Time
    dtfCustom             // 自定义格式
  );

  // 持续时间格式类型
  TDurationFormat = (
    dfCompact,            // 1h30m45s
    dfVerbose,            // 1 hour 30 minutes 45 seconds
    dfPrecise,            // 1:30:45.123
    dfHuman,              // about 1 hour
    dfISO8601,            // PT1H30M45.123S
    dfCustom              // 自定义格式
  );

  // 格式化选项
  TFormatOptions = record
    UseUTC: Boolean;              // 使用 UTC 时间
    ShowMilliseconds: Boolean;    // 显示毫秒
    Use24Hour: Boolean;           // 使用 24 小时制
    ShowTimeZone: Boolean;        // 显示时区
    Locale: string;               // 本地化设置
    CustomPattern: string;        // 自定义格式模式
    
    class function Default: TFormatOptions; static;
    class function UTC: TFormatOptions; static;
    class function Local: TFormatOptions; static;
    class function Precise: TFormatOptions; static;
  end;

  // 持续时间格式化选项
  TDurationFormatOptions = record
    ShowZeroUnits: Boolean;       // 显示零值单位
    UseAbbreviation: Boolean;     // 使用缩写
    MaxUnits: Integer;            // 最大显示单位数
    Precision: Integer;           // 小数精度
    Locale: string;               // 本地化设置
    
    class function Default: TDurationFormatOptions; static;
    class function Compact: TDurationFormatOptions; static;
    class function Verbose: TDurationFormatOptions; static;
    class function Precise: TDurationFormatOptions; static;
  end;

  {**
   * ITimeFormatter - 时间格式化器接口
   *
   * @desc
   *   提供时间和日期的格式化功能。
   *   支持多种格式和本地化设置。
   *
   * @thread_safety
   *   实现应保证线程安全。
   *}
  ITimeFormatter = interface
    ['{C8D7E6F5-A4B3-2F1E-0D9C-8B7A6F5E4D3C}']
    
    // 日期时间格式化
    function FormatDateTime(const ADateTime: TDateTime; AFormat: TDateTimeFormat = dtfISO8601): string; overload;
    function FormatDateTime(const ADateTime: TDateTime; const AOptions: TFormatOptions): string; overload;
    function FormatDateTime(const ADateTime: TDateTime; const APattern: string): string; overload;
    
    // 日期格式化
    function FormatDate(const ADate: TDate; AFormat: TDateTimeFormat = dtfISO8601Date): string; overload;
    function FormatDate(const ADate: TDate; const AOptions: TFormatOptions): string; overload;
    function FormatDate(const ADate: TDate; const APattern: string): string; overload;
    
    // 时间格式化
    function FormatTime(const ATime: TTimeOfDay; AFormat: TDateTimeFormat = dtfISO8601Time): string; overload;
    function FormatTime(const ATime: TTimeOfDay; const AOptions: TFormatOptions): string; overload;
    function FormatTime(const ATime: TTimeOfDay; const APattern: string): string; overload;
    
    // 持续时间格式化
    function FormatDuration(const ADuration: TDuration; AFormat: TDurationFormat = dfCompact): string; overload;
    function FormatDuration(const ADuration: TDuration; const AOptions: TDurationFormatOptions): string; overload;
    function FormatDuration(const ADuration: TDuration; const APattern: string): string; overload;
    
    // 相对时间格式化
    function FormatRelative(const ADateTime: TDateTime; const ABaseTime: TDateTime): string; overload;
    function FormatRelative(const ADateTime: TDateTime): string; overload; // 相对于当前时间
    
    // 配置
    procedure SetLocale(const ALocale: string);
    function GetLocale: string;
    procedure SetDefaultOptions(const AOptions: TFormatOptions);
    function GetDefaultOptions: TFormatOptions;
  end;

  {**
   * IDurationFormatter - 持续时间格式化器接口
   *
   * @desc
   *   专门用于持续时间格式化的接口。
   *   提供人性化的持续时间显示。
   *
   * @thread_safety
   *   实现应保证线程安全。
   *}
  IDurationFormatter = interface
    ['{B7C6D5E4-F3A2-1E0D-9C8B-7A6F5E4D3C2B}']
    
    // 基本格式化
    function Format(const ADuration: TDuration): string; overload;
    function Format(const ADuration: TDuration; AFormat: TDurationFormat): string; overload;
    function Format(const ADuration: TDuration; const AOptions: TDurationFormatOptions): string; overload;
    function Format(const ADuration: TDuration; const APattern: string): string; overload;
    
    // 人性化格式化
    function FormatHuman(const ADuration: TDuration): string; // "about 2 hours"
    function FormatCompact(const ADuration: TDuration): string; // "2h 30m"
    function FormatVerbose(const ADuration: TDuration): string; // "2 hours 30 minutes"
    function FormatPrecise(const ADuration: TDuration): string; // "2:30:45.123"
    function FormatISO8601(const ADuration: TDuration): string; // "PT2H30M45.123S"
    
    // 配置
    procedure SetOptions(const AOptions: TDurationFormatOptions);
    function GetOptions: TDurationFormatOptions;
    procedure SetLocale(const ALocale: string);
    function GetLocale: string;
  end;

// 工厂函数
function CreateTimeFormatter: ITimeFormatter; overload;
function CreateTimeFormatter(const ALocale: string): ITimeFormatter; overload;
function CreateDurationFormatter: IDurationFormatter; overload;
function CreateDurationFormatter(const ALocale: string): IDurationFormatter; overload;

// 默认格式化器
function DefaultTimeFormatter: ITimeFormatter;
function DefaultDurationFormatter: IDurationFormatter;

// 便捷格式化函数
function FormatDateTime(const ADateTime: TDateTime; AFormat: TDateTimeFormat = dtfISO8601): string; overload;
function FormatDateTime(const ADateTime: TDateTime; const APattern: string): string; overload;
function FormatDate(const ADate: TDate; AFormat: TDateTimeFormat = dtfISO8601Date): string; overload;
function FormatDate(const ADate: TDate; const APattern: string): string; overload;
function FormatTime(const ATime: TTimeOfDay; AFormat: TDateTimeFormat = dtfISO8601Time): string; overload;
function FormatTime(const ATime: TTimeOfDay; const APattern: string): string; overload;

function FormatDuration(const ADuration: TDuration; AFormat: TDurationFormat = dfCompact): string; overload;
function FormatDuration(const ADuration: TDuration; const APattern: string): string; overload;
function FormatDurationHuman(const ADuration: TDuration): string;
function FormatDurationCompact(const ADuration: TDuration): string;
function FormatDurationVerbose(const ADuration: TDuration): string;
function FormatDurationPrecise(const ADuration: TDuration): string;
function FormatDurationISO8601(const ADuration: TDuration): string;

function FormatRelativeTime(const ADateTime: TDateTime; const ABaseTime: TDateTime): string; overload;
function FormatRelativeTime(const ADateTime: TDateTime): string; overload;

// Global toggles used by tests
procedure SetDurationFormatUseAbbr(AUseAbbr: Boolean);
procedure SetDurationFormatSecPrecision(APrecision: Integer);

// 格式模式常量
const
  // 日期格式模式
  PATTERN_ISO8601_DATE = 'yyyy-mm-dd';
  PATTERN_ISO8601_TIME = 'hh:nn:ss.zzz';
  PATTERN_ISO8601_DATETIME = 'yyyy-mm-dd"T"hh:nn:ss.zzz';
  PATTERN_RFC3339 = 'yyyy-mm-dd"T"hh:nn:ss.zzzzzz';
  
  // 常用格式模式
  PATTERN_SHORT_DATE = 'm/d/yy';
  PATTERN_MEDIUM_DATE = 'mmm d, yyyy';
  PATTERN_LONG_DATE = 'mmmm d, yyyy';
  PATTERN_FULL_DATE = 'dddd, mmmm d, yyyy';
  
  PATTERN_SHORT_TIME = 'h:nn AM/PM';
  PATTERN_MEDIUM_TIME = 'h:nn:ss AM/PM';
  PATTERN_LONG_TIME = 'h:nn:ss.zzz AM/PM';
  PATTERN_24HOUR_TIME = 'hh:nn:ss';
  
  // 持续时间格式模式
  PATTERN_DURATION_COMPACT = 'h"h"n"m"s"s"';
  PATTERN_DURATION_PRECISE = 'h:nn:ss.zzz';
  PATTERN_DURATION_ISO8601 = '"PT"h"H"n"M"s.zzz"S"';

implementation

type
  // 时间格式化器实现
  TTimeFormatter = class(TInterfacedObject, ITimeFormatter)
  private
    FLocale: string;
    FDefaultOptions: TFormatOptions;
    
    function GetFormatPattern(AFormat: TDateTimeFormat; const AOptions: TFormatOptions): string;
    function ApplyPattern(const ADateTime: TDateTime; const APattern: string; const AOptions: TFormatOptions): string;
  public
    constructor Create(const ALocale: string = '');
    
    // ITimeFormatter 实现
    function FormatDateTime(const ADateTime: TDateTime; AFormat: TDateTimeFormat = dtfISO8601): string; overload;
    function FormatDateTime(const ADateTime: TDateTime; const AOptions: TFormatOptions): string; overload;
    function FormatDateTime(const ADateTime: TDateTime; const APattern: string): string; overload;
    
    function FormatDate(const ADate: TDate; AFormat: TDateTimeFormat = dtfISO8601Date): string; overload;
    function FormatDate(const ADate: TDate; const AOptions: TFormatOptions): string; overload;
    function FormatDate(const ADate: TDate; const APattern: string): string; overload;
    
    function FormatTime(const ATime: TTimeOfDay; AFormat: TDateTimeFormat = dtfISO8601Time): string; overload;
    function FormatTime(const ATime: TTimeOfDay; const AOptions: TFormatOptions): string; overload;
    function FormatTime(const ATime: TTimeOfDay; const APattern: string): string; overload;
    
    function FormatDuration(const ADuration: TDuration; AFormat: TDurationFormat = dfCompact): string; overload;
    function FormatDuration(const ADuration: TDuration; const AOptions: TDurationFormatOptions): string; overload;
    function FormatDuration(const ADuration: TDuration; const APattern: string): string; overload;
    
    function FormatRelative(const ADateTime: TDateTime; const ABaseTime: TDateTime): string; overload;
    function FormatRelative(const ADateTime: TDateTime): string; overload;
    
    procedure SetLocale(const ALocale: string);
    function GetLocale: string;
    procedure SetDefaultOptions(const AOptions: TFormatOptions);
    function GetDefaultOptions: TFormatOptions;
  end;

  // 持续时间格式化器实现
  TDurationFormatter = class(TInterfacedObject, IDurationFormatter)
  private
    FLocale: string;
    FOptions: TDurationFormatOptions;
    
    function FormatUnits(const ADuration: TDuration; const AOptions: TDurationFormatOptions): string;
    function GetUnitName(const AUnit: string; AValue: Int64; const AOptions: TDurationFormatOptions): string;
  public
    constructor Create(const ALocale: string = '');
    
    // IDurationFormatter 实现
    function Format(const ADuration: TDuration): string; overload;
    function Format(const ADuration: TDuration; AFormat: TDurationFormat): string; overload;
    function Format(const ADuration: TDuration; const AOptions: TDurationFormatOptions): string; overload;
    function Format(const ADuration: TDuration; const APattern: string): string; overload;
    
    function FormatHuman(const ADuration: TDuration): string;
    function FormatCompact(const ADuration: TDuration): string;
    function FormatVerbose(const ADuration: TDuration): string;
    function FormatPrecise(const ADuration: TDuration): string;
    function FormatISO8601(const ADuration: TDuration): string;
    
    procedure SetOptions(const AOptions: TDurationFormatOptions);
    function GetOptions: TDurationFormatOptions;
    procedure SetLocale(const ALocale: string);
    function GetLocale: string;
  end;

var
  GTimeFormatter: ITimeFormatter = nil;
  GDurationFormatter: IDurationFormatter = nil;

{ TFormatOptions }

class function TFormatOptions.Default: TFormatOptions;
begin
  Result.UseUTC := False;
  Result.ShowMilliseconds := False;
  Result.Use24Hour := True;
  Result.ShowTimeZone := False;
  Result.Locale := '';
  Result.CustomPattern := '';
end;

class function TFormatOptions.UTC: TFormatOptions;
begin
  Result := Default;
  Result.UseUTC := True;
  Result.ShowTimeZone := True;
end;

class function TFormatOptions.Local: TFormatOptions;
begin
  Result := Default;
  Result.UseUTC := False;
  Result.ShowTimeZone := True;
end;

class function TFormatOptions.Precise: TFormatOptions;
begin
  Result := Default;
  Result.ShowMilliseconds := True;
end;

{ TDurationFormatOptions }

class function TDurationFormatOptions.Default: TDurationFormatOptions;
begin
  Result.ShowZeroUnits := False;
  Result.UseAbbreviation := True;
  Result.MaxUnits := 3;
  Result.Precision := 0;
  Result.Locale := '';
end;

class function TDurationFormatOptions.Compact: TDurationFormatOptions;
begin
  Result := Default;
  Result.UseAbbreviation := True;
  Result.MaxUnits := 2;
end;

class function TDurationFormatOptions.Verbose: TDurationFormatOptions;
begin
  Result := Default;
  Result.UseAbbreviation := False;
  Result.MaxUnits := 3;
end;

class function TDurationFormatOptions.Precise: TDurationFormatOptions;
begin
  Result := Default;
  Result.ShowZeroUnits := True;
  Result.Precision := 3;
end;

// 工厂函数实现

function CreateTimeFormatter: ITimeFormatter;
begin
  Result := TTimeFormatter.Create;
end;

function CreateTimeFormatter(const ALocale: string): ITimeFormatter;
begin
  Result := TTimeFormatter.Create(ALocale);
end;

function CreateDurationFormatter: IDurationFormatter;
begin
  Result := TDurationFormatter.Create;
end;

function CreateDurationFormatter(const ALocale: string): IDurationFormatter;
begin
  Result := TDurationFormatter.Create(ALocale);
end;

function DefaultTimeFormatter: ITimeFormatter;
begin
  if GTimeFormatter = nil then
    GTimeFormatter := CreateTimeFormatter;
  Result := GTimeFormatter;
end;

function DefaultDurationFormatter: IDurationFormatter;
begin
  if GDurationFormatter = nil then
    GDurationFormatter := CreateDurationFormatter;
  Result := GDurationFormatter;
end;

// Expose toggles (implemented below)

// 便捷函数

var
  GHumanUseAbbr: Boolean = True;
  GHumanSecPrecision: Integer = 0;

procedure SetDurationFormatUseAbbr(AUseAbbr: Boolean);
begin
  GHumanUseAbbr := AUseAbbr;
end;

procedure SetDurationFormatSecPrecision(APrecision: Integer);
begin
  if APrecision < 0 then APrecision := 0;
  if APrecision > 3 then APrecision := 3;
  GHumanSecPrecision := APrecision;
end;

function FormatDateTime(const ADateTime: TDateTime; AFormat: TDateTimeFormat): string;
begin
  Result := DefaultTimeFormatter.FormatDateTime(ADateTime, AFormat);
end;

function FormatDateTime(const ADateTime: TDateTime; const APattern: string): string;
begin
  Result := DefaultTimeFormatter.FormatDateTime(ADateTime, APattern);
end;

function FormatDuration(const ADuration: TDuration; AFormat: TDurationFormat): string;
begin
  Result := DefaultDurationFormatter.Format(ADuration, AFormat);
end;

function FormatDurationHuman(const ADuration: TDuration): string;
var
  ms: Int64;
  absMs: Int64;
  fmt: string;
begin
  // honor toggles for abbr and sec precision
  ms := ADuration.AsMs;
  absMs := Abs(ms);
  if absMs < 1000 then
  begin
    if GHumanUseAbbr then
      Result := SysUtils.Format('%dms', [absMs])
    else
      Result := SysUtils.Format('%d milliseconds', [absMs]);
    Exit;
  end;

  if GHumanSecPrecision > 0 then
  begin
    fmt := SysUtils.Format('%%.%df', [GHumanSecPrecision]);
    if GHumanUseAbbr then
      Result := SysUtils.Format(fmt + 's', [absMs/1000.0])
    else
      Result := SysUtils.Format(fmt + ' seconds', [absMs/1000.0]);
  end
  else
  begin
    if GHumanUseAbbr then
      Result := SysUtils.Format('%ds', [absMs div 1000])
    else
      Result := SysUtils.Format('%d seconds', [absMs div 1000]);
  end;
end;

function FormatDurationCompact(const ADuration: TDuration): string;
begin
  Result := DefaultDurationFormatter.FormatCompact(ADuration);
end;

{ TTimeFormatter }

constructor TTimeFormatter.Create(const ALocale: string);
begin
  FLocale := ALocale;
  FDefaultOptions := TFormatOptions.Default;
end;

function TTimeFormatter.GetFormatPattern(AFormat: TDateTimeFormat; const AOptions: TFormatOptions): string;
begin
  case AFormat of
    dtfISO8601:           Result := PATTERN_ISO8601_DATETIME;
    dtfISO8601Date:       Result := PATTERN_ISO8601_DATE;
    dtfISO8601Time:
      begin
        if AOptions.ShowMilliseconds then
          Result := 'hh:nn:ss.zzz'
        else
          Result := 'hh:nn:ss';
      end;
    dtfRFC3339:           Result := PATTERN_ISO8601_DATETIME; // 简化为 ISO8601；RFC3339 时区留待后续实现
    dtfShort:             Result := 'm/d/yy h:nn AM/PM';
    dtfMedium:            Result := 'mmm d, yyyy h:nn:ss AM/PM';
    dtfLong:              Result := 'mmmm d, yyyy h:nn:ss AM/PM';
    dtfFull:              Result := 'dddd, mmmm d, yyyy h:nn:ss AM/PM';
    dtfCustom:            Result := AOptions.CustomPattern;
  else
    Result := PATTERN_ISO8601_DATETIME;
  end;

  // 24小时制调整
  if AOptions.Use24Hour then
  begin
    Result := StringReplace(Result, 'h:nn:ss', 'hh:nn:ss', [rfReplaceAll, rfIgnoreCase]);
    Result := StringReplace(Result, 'h:nn', 'hh:nn', [rfReplaceAll, rfIgnoreCase]);
    // 移除 AM/PM（若存在）
    Result := StringReplace(Result, ' AM/PM', '', [rfReplaceAll, rfIgnoreCase]);
  end;

  // 毫秒显示调整
  if AOptions.ShowMilliseconds then
  begin
    if Pos('.zzz', Result) = 0 then
      if Pos('ss', Result) > 0 then
        Result := StringReplace(Result, 'ss', 'ss.zzz', [])
      else if Pos('nn', Result) > 0 then
        Result := StringReplace(Result, 'nn', 'nn:00.000', [])
      else if Pos('hh', Result) > 0 then
        Result := StringReplace(Result, 'hh', 'hh:00:00.000', []);
  end;
end;

function TTimeFormatter.ApplyPattern(const ADateTime: TDateTime; const APattern: string; const AOptions: TFormatOptions): string;
var
  dt: TDateTime;
begin
  dt := ADateTime; // 简化：暂不处理时区转换
  Result := SysUtils.FormatDateTime(APattern, dt);
  // 时区后缀等扩展可在此追加
end;

function TTimeFormatter.FormatDateTime(const ADateTime: TDateTime; AFormat: TDateTimeFormat): string;
var
  opts: TFormatOptions;
  patt: string;
begin
  opts := FDefaultOptions;
  patt := GetFormatPattern(AFormat, opts);
  Result := ApplyPattern(ADateTime, patt, opts);
end;

function TTimeFormatter.FormatDateTime(const ADateTime: TDateTime; const AOptions: TFormatOptions): string;
var
  patt: string;
begin
  // 采用 ISO8601 作为默认格式
  patt := GetFormatPattern(dtfISO8601, AOptions);
  Result := ApplyPattern(ADateTime, patt, AOptions);
end;

function TTimeFormatter.FormatDateTime(const ADateTime: TDateTime; const APattern: string): string;
begin
  Result := ApplyPattern(ADateTime, APattern, FDefaultOptions);
end;

function TTimeFormatter.FormatDate(const ADate: TDate; AFormat: TDateTimeFormat): string;
var
  opts: TFormatOptions;
  patt: string;
begin
  opts := FDefaultOptions;
  case AFormat of
    dtfISO8601Date: patt := PATTERN_ISO8601_DATE;
    dtfShort:       patt := PATTERN_SHORT_DATE;
    dtfMedium:      patt := PATTERN_MEDIUM_DATE;
    dtfLong:        patt := PATTERN_LONG_DATE;
    dtfFull:        patt := PATTERN_FULL_DATE;
    dtfCustom:      patt := opts.CustomPattern;
  else
    patt := PATTERN_ISO8601_DATE;
  end;
  Result := SysUtils.FormatDateTime(patt, ADate.ToDateTime);
end;

function TTimeFormatter.FormatDate(const ADate: TDate; const AOptions: TFormatOptions): string;
var
  patt: string;
begin
  // 日期仅显示日期部分
  patt := PATTERN_ISO8601_DATE;
  Result := SysUtils.FormatDateTime(patt, ADate.ToDateTime);
end;

function TTimeFormatter.FormatDate(const ADate: TDate; const APattern: string): string;
begin
  Result := SysUtils.FormatDateTime(APattern, ADate.ToDateTime);
end;

function TTimeFormatter.FormatTime(const ATime: TTimeOfDay; AFormat: TDateTimeFormat): string;
var
  opts: TFormatOptions;
  patt: string;
begin
  opts := FDefaultOptions;
  case AFormat of
    dtfISO8601Time: patt := GetFormatPattern(dtfISO8601Time, opts);
    dtfShort:       patt := PATTERN_SHORT_TIME;
    dtfMedium:      patt := PATTERN_MEDIUM_TIME;
    dtfLong:        patt := PATTERN_LONG_TIME;
    dtfCustom:      patt := opts.CustomPattern;
  else
    patt := GetFormatPattern(dtfISO8601Time, opts);
  end;
  Result := SysUtils.FormatDateTime(patt, ATime.ToTime);
end;

function TTimeFormatter.FormatTime(const ATime: TTimeOfDay; const AOptions: TFormatOptions): string;
var
  patt: string;
begin
  patt := GetFormatPattern(dtfISO8601Time, AOptions);
  Result := SysUtils.FormatDateTime(patt, ATime.ToTime);
end;

function TTimeFormatter.FormatTime(const ATime: TTimeOfDay; const APattern: string): string;
begin
  Result := SysUtils.FormatDateTime(APattern, ATime.ToTime);
end;

function TTimeFormatter.FormatDuration(const ADuration: TDuration; AFormat: TDurationFormat): string;
var
  df: IDurationFormatter;
begin
  df := DefaultDurationFormatter;
  Result := df.Format(ADuration, AFormat);
end;

function TTimeFormatter.FormatDuration(const ADuration: TDuration; const AOptions: TDurationFormatOptions): string;
var
  df: IDurationFormatter;
begin
  df := DefaultDurationFormatter;
  df.SetOptions(AOptions);
  Result := df.Format(ADuration, AOptions);
end;

function TTimeFormatter.FormatDuration(const ADuration: TDuration; const APattern: string): string;
var
  df: IDurationFormatter;
begin
  // 简化：忽略自定义模式，使用紧凑格式
  df := DefaultDurationFormatter;
  Result := df.FormatCompact(ADuration);
end;

function TTimeFormatter.FormatRelative(const ADateTime: TDateTime; const ABaseTime: TDateTime): string;
var
  deltaSec: Int64;
  absSec: Int64;
  sign: string;
begin
  deltaSec := Round((ADateTime - ABaseTime) * 86400.0);
  if deltaSec = 0 then Exit('just now');
  absSec := Abs(deltaSec);
  if deltaSec < 0 then sign := ' ago' else sign := '';

  if absSec < 60 then
    Result := SysUtils.Format('%d seconds%s', [absSec, sign])
  else if absSec < 3600 then
    Result := SysUtils.Format('%d minutes%s', [absSec div 60, sign])
  else if absSec < 86400 then
    Result := SysUtils.Format('%d hours%s', [absSec div 3600, sign])
  else
    Result := SysUtils.Format('%d days%s', [absSec div 86400, sign]);

  if (deltaSec > 0) and (sign = '') then
    Result := 'in ' + Result;
end;

function TTimeFormatter.FormatRelative(const ADateTime: TDateTime): string;
begin
  Result := FormatRelative(ADateTime, Now);
end;

procedure TTimeFormatter.SetLocale(const ALocale: string);
begin
  FLocale := ALocale;
end;

function TTimeFormatter.GetLocale: string;
begin
  Result := FLocale;
end;

procedure TTimeFormatter.SetDefaultOptions(const AOptions: TFormatOptions);
begin
  FDefaultOptions := AOptions;
end;

function TTimeFormatter.GetDefaultOptions: TFormatOptions;
begin
  Result := FDefaultOptions;
end;

{ TDurationFormatter }

constructor TDurationFormatter.Create(const ALocale: string);
begin
  FLocale := ALocale;
  FOptions := TDurationFormatOptions.Default;
end;

function TDurationFormatter.GetUnitName(const AUnit: string; AValue: Int64; const AOptions: TDurationFormatOptions): string;
begin
  if AOptions.UseAbbreviation then
  begin
    if AUnit = 'hour' then Exit('h');
    if AUnit = 'minute' then Exit('m');
    if AUnit = 'second' then Exit('s');
    if AUnit = 'millisecond' then Exit('ms');
  end;
  // 非缩写，处理复数
  if AValue = 1 then
    Result := AUnit
  else
    Result := AUnit + 's';
end;

function TDurationFormatter.FormatUnits(const ADuration: TDuration; const AOptions: TDurationFormatOptions): string;
var
  msTotal: Int64;
  ms, s, m, h: Int64;
  parts: array[0..3] of string;
  count, taken: Integer;
  uName, suffix, sep: string;
begin
  msTotal := ADuration.AsMs;
  if msTotal < 0 then msTotal := -msTotal; // magnitude only for formatting

  h := msTotal div (60*60*1000);
  ms := msTotal mod (60*60*1000);
  m := ms div (60*1000);
  ms := ms mod (60*1000);
  s := ms div 1000;
  ms := ms mod 1000;

  count := 0;
  taken := 0;

  if (h > 0) or AOptions.ShowZeroUnits then
  begin
    uName := GetUnitName('hour', h, AOptions);
    if AOptions.UseAbbreviation then suffix := uName else suffix := ' ' + uName;
    parts[count] := SysUtils.Format('%d%s', [h, suffix]);
    Inc(count);
  end;
  if (m > 0) or (AOptions.ShowZeroUnits and (count > 0)) then
  begin
    uName := GetUnitName('minute', m, AOptions);
    if AOptions.UseAbbreviation then suffix := uName else suffix := ' ' + uName;
    parts[count] := SysUtils.Format('%d%s', [m, suffix]);
    Inc(count);
  end;
  if (s > 0) or (AOptions.ShowZeroUnits and (count > 0)) then
  begin
    uName := GetUnitName('second', s, AOptions);
    if AOptions.UseAbbreviation then suffix := uName else suffix := ' ' + uName;
    parts[count] := SysUtils.Format('%d%s', [s, suffix]);
    Inc(count);
  end;
  if (AOptions.Precision > 0) and ((ms > 0) or (AOptions.ShowZeroUnits and (count > 0))) then
  begin
    uName := GetUnitName('millisecond', ms, AOptions);
    if AOptions.UseAbbreviation then suffix := uName else suffix := ' ' + uName;
    parts[count] := SysUtils.Format('%d%s', [ms, suffix]);
    Inc(count);
  end;

  if AOptions.UseAbbreviation then sep := ' ' else sep := ', ';
  Result := '';
  while (taken < count) and ((AOptions.MaxUnits = 0) or (taken < AOptions.MaxUnits)) do
  begin
    if Result <> '' then Result := Result + sep;
    Result := Result + parts[taken];
    Inc(taken);
  end;
end;

function TDurationFormatter.Format(const ADuration: TDuration): string;
begin
  Result := Format(ADuration, dfCompact);
end;

function TDurationFormatter.Format(const ADuration: TDuration; AFormat: TDurationFormat): string;
begin
  case AFormat of
    dfCompact:  Result := FormatCompact(ADuration);
    dfVerbose:  Result := FormatVerbose(ADuration);
    dfPrecise:  Result := FormatPrecise(ADuration);
    dfHuman:    Result := FormatHuman(ADuration);
    dfISO8601:  Result := FormatISO8601(ADuration);
    dfCustom:   Result := FormatCompact(ADuration);
  else
    Result := FormatCompact(ADuration);
  end;
end;

function TDurationFormatter.Format(const ADuration: TDuration; const AOptions: TDurationFormatOptions): string;
begin
  Result := FormatUnits(ADuration, AOptions);
end;

function TDurationFormatter.Format(const ADuration: TDuration; const APattern: string): string;
begin
  // 简化：忽略自定义模式
  Result := FormatCompact(ADuration);
end;

function TDurationFormatter.FormatHuman(const ADuration: TDuration): string;
var
  ms: Int64;
  absMs: Int64;
begin
  ms := ADuration.AsMs;
  absMs := Abs(ms);
  if absMs < 1000 then
    Result := SysUtils.Format('%d ms', [absMs])
  else if absMs < 60*1000 then
    Result := SysUtils.Format('about %d seconds', [absMs div 1000])
  else if absMs < 60*60*1000 then
    Result := SysUtils.Format('about %d minutes', [absMs div (60*1000)])
  else if absMs < 24*60*60*1000 then
    Result := SysUtils.Format('about %d hours', [absMs div (60*60*1000)])
  else
    Result := SysUtils.Format('about %d days', [absMs div (24*60*60*1000)]);
end;

function TDurationFormatter.FormatCompact(const ADuration: TDuration): string;
var
  msTotal: Int64;
  ms, s, m, h: Int64;
  outStr: string;
begin
  msTotal := ADuration.AsMs;
  if msTotal < 0 then msTotal := -msTotal; // 仅格式化大小

  h := msTotal div (60*60*1000);
  ms := msTotal mod (60*60*1000);
  m := ms div (60*1000);
  ms := ms mod (60*1000);
  s := ms div 1000;
  ms := ms mod 1000;

  outStr := '';
  if h > 0 then outStr := outStr + IntToStr(h) + 'h';
  if m > 0 then outStr := outStr + IntToStr(m) + 'm';
  if s > 0 then outStr := outStr + IntToStr(s) + 's';
  if (outStr = '') and (msTotal = 0) then outStr := '0s';
  if (outStr = '') and (ms > 0) then outStr := IntToStr(ms) + 'ms';

  Result := outStr;
end;

function TDurationFormatter.FormatVerbose(const ADuration: TDuration): string;
var
  opts: TDurationFormatOptions;
begin
  opts := TDurationFormatOptions.Default;
  opts.UseAbbreviation := False;
  opts.MaxUnits := 3;
  Result := FormatUnits(ADuration, opts);
end;

function TDurationFormatter.FormatPrecise(const ADuration: TDuration): string;
var
  msTotal: Int64;
  ms, s, m, h: Int64;
begin
  msTotal := ADuration.AsMs;
  if msTotal < 0 then msTotal := -msTotal; // 仅格式化大小

  h := msTotal div (60*60*1000);
  ms := msTotal mod (60*60*1000);
  m := ms div (60*1000);
  ms := ms mod (60*1000);
  s := ms div 1000;
  ms := ms mod 1000;

  if ms > 0 then
    Result := SysUtils.Format('%d:%0.2d:%0.2d.%0.3d', [h, m, s, ms])
  else
    Result := SysUtils.Format('%d:%0.2d:%0.2d', [h, m, s]);
end;

function TDurationFormatter.FormatISO8601(const ADuration: TDuration): string;
var
  ms: Int64;
  s, m, h: Int64;
  fracMs: Int64;
begin
  ms := ADuration.AsMs;
  if ms < 0 then ms := -ms; // ISO8601 不带负号，若需可扩展为 -PT...

  h := ms div (60*60*1000);
  ms := ms mod (60*60*1000);
  m := ms div (60*1000);
  ms := ms mod (60*1000);
  s := ms div 1000;
  fracMs := ms mod 1000;

  if fracMs > 0 then
    Result := SysUtils.Format('PT%dH%dM%d.%0.3dS', [h, m, s, fracMs])
  else
    Result := SysUtils.Format('PT%dH%dM%dS', [h, m, s]);
end;

procedure TDurationFormatter.SetOptions(const AOptions: TDurationFormatOptions);
begin
  FOptions := AOptions;
end;

function TDurationFormatter.GetOptions: TDurationFormatOptions;
begin
  Result := FOptions;
end;

procedure TDurationFormatter.SetLocale(const ALocale: string);
begin
  FLocale := ALocale;
end;

function TDurationFormatter.GetLocale: string;
begin
  Result := FLocale;
end;

// ===== 便捷函数补全 =====

function FormatDate(const ADate: TDate; AFormat: TDateTimeFormat): string;
begin
  Result := DefaultTimeFormatter.FormatDate(ADate, AFormat);
end;

function FormatDate(const ADate: TDate; const APattern: string): string;
begin
  Result := DefaultTimeFormatter.FormatDate(ADate, APattern);
end;

function FormatTime(const ATime: TTimeOfDay; AFormat: TDateTimeFormat): string;
begin
  Result := DefaultTimeFormatter.FormatTime(ATime, AFormat);
end;

function FormatTime(const ATime: TTimeOfDay; const APattern: string): string;
begin
  Result := DefaultTimeFormatter.FormatTime(ATime, APattern);
end;

function FormatDuration(const ADuration: TDuration; const APattern: string): string;
begin
  Result := DefaultDurationFormatter.Format(ADuration, APattern);
end;

function FormatDurationVerbose(const ADuration: TDuration): string;
begin
  Result := DefaultDurationFormatter.FormatVerbose(ADuration);
end;

function FormatDurationPrecise(const ADuration: TDuration): string;
begin
  Result := DefaultDurationFormatter.FormatPrecise(ADuration);
end;

function FormatDurationISO8601(const ADuration: TDuration): string;
begin
  Result := DefaultDurationFormatter.FormatISO8601(ADuration);
end;

function FormatRelativeTime(const ADateTime: TDateTime; const ABaseTime: TDateTime): string;
begin
  Result := DefaultTimeFormatter.FormatRelative(ADateTime, ABaseTime);
end;

function FormatRelativeTime(const ADateTime: TDateTime): string;
begin
  Result := DefaultTimeFormatter.FormatRelative(ADateTime);
end;

end.
