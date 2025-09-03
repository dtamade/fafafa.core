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

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  DateUtils,
  fafafa.core.time.base,
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

// 便捷函数

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
begin
  Result := DefaultDurationFormatter.FormatHuman(ADuration);
end;

function FormatDurationCompact(const ADuration: TDuration): string;
begin
  Result := DefaultDurationFormatter.FormatCompact(ADuration);
end;

// 实现细节将在后续添加...

end.
