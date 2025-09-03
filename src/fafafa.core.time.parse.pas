unit fafafa.core.time.parse;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.parse - 时间解析

📖 概述：
  提供时间和日期字符串的解析功能，支持多种格式和本地化设置。
  包含智能解析和严格模式解析。

🔧 特性：
  • 多种标准格式支持
  • 智能格式检测
  • 本地化解析
  • 严格模式和宽松模式
  • 自定义格式模式

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
  RegExpr,
  fafafa.core.time.base,
  fafafa.core.time.date,
  fafafa.core.time.timeofday,
  fafafa.core.time.format;

type
  // 解析模式
  TParseMode = (
    pmStrict,     // 严格模式，必须完全匹配格式
    pmLenient,    // 宽松模式，允许一定的格式变化
    pmSmart       // 智能模式，自动检测格式
  );

  // 解析选项
  TParseOptions = record
    Mode: TParseMode;
    Locale: string;
    DefaultTimeZone: string;
    AssumeUTC: Boolean;
    AllowPartialMatch: Boolean;
    CaseSensitive: Boolean;
    
    class function Default: TParseOptions; static;
    class function Strict: TParseOptions; static;
    class function Lenient: TParseOptions; static;
    class function Smart: TParseOptions; static;
  end;

  // 解析结果
  TParseResult = record
    Success: Boolean;
    ErrorMessage: string;
    ParsedLength: Integer;
    DetectedFormat: string;
    
    class function CreateSuccess(ALength: Integer; const AFormat: string = ''): TParseResult; static;
    class function CreateError(const AMessage: string; APosition: Integer = 0): TParseResult; static;
  end;

  {**
   * ITimeParser - 时间解析器接口
   *
   * @desc
   *   提供时间和日期字符串的解析功能。
   *   支持多种格式和解析模式。
   *
   * @thread_safety
   *   实现应保证线程安全。
   *}
  ITimeParser = interface
    ['{A9B8C7D6-E5F4-3A2B-1C0D-9E8F7A6B5C4D}']
    
    // 日期时间解析
    function ParseDateTime(const ADateTimeStr: string; out ADateTime: TDateTime): TParseResult; overload;
    function ParseDateTime(const ADateTimeStr: string; const AFormat: string; out ADateTime: TDateTime): TParseResult; overload;
    function ParseDateTime(const ADateTimeStr: string; const AOptions: TParseOptions; out ADateTime: TDateTime): TParseResult; overload;
    
    // 日期解析
    function ParseDate(const ADateStr: string; out ADate: TDate): TParseResult; overload;
    function ParseDate(const ADateStr: string; const AFormat: string; out ADate: TDate): TParseResult; overload;
    function ParseDate(const ADateStr: string; const AOptions: TParseOptions; out ADate: TDate): TParseResult; overload;
    
    // 时间解析
    function ParseTime(const ATimeStr: string; out ATime: TTimeOfDay): TParseResult; overload;
    function ParseTime(const ATimeStr: string; const AFormat: string; out ATime: TTimeOfDay): TParseResult; overload;
    function ParseTime(const ATimeStr: string; const AOptions: TParseOptions; out ATime: TTimeOfDay): TParseResult; overload;
    
    // 持续时间解析
    function ParseDuration(const ADurationStr: string; out ADuration: TDuration): TParseResult; overload;
    function ParseDuration(const ADurationStr: string; const AFormat: string; out ADuration: TDuration): TParseResult; overload;
    function ParseDuration(const ADurationStr: string; const AOptions: TParseOptions; out ADuration: TDuration): TParseResult; overload;
    
    // 智能解析
    function SmartParse(const ATimeStr: string; out ADateTime: TDateTime): TParseResult; overload;
    function SmartParse(const ATimeStr: string; out ADate: TDate): TParseResult; overload;
    function SmartParse(const ATimeStr: string; out ATime: TTimeOfDay): TParseResult; overload;
    function SmartParse(const ATimeStr: string; out ADuration: TDuration): TParseResult; overload;
    
    // 格式检测
    function DetectFormat(const ATimeStr: string): string;
    function GetSupportedFormats: TArray<string>;
    
    // 配置
    procedure SetDefaultOptions(const AOptions: TParseOptions);
    function GetDefaultOptions: TParseOptions;
    procedure SetLocale(const ALocale: string);
    function GetLocale: string;
  end;

  {**
   * IDurationParser - 持续时间解析器接口
   *
   * @desc
   *   专门用于持续时间解析的接口。
   *   支持多种持续时间表示格式。
   *
   * @thread_safety
   *   实现应保证线程安全。
   *}
  IDurationParser = interface
    ['{F8E7D6C5-B4A3-2F1E-0D9C-8B7A6F5E4D3C}']
    
    // 基本解析
    function Parse(const ADurationStr: string; out ADuration: TDuration): TParseResult; overload;
    function Parse(const ADurationStr: string; const AFormat: string; out ADuration: TDuration): TParseResult; overload;
    function Parse(const ADurationStr: string; const AOptions: TParseOptions; out ADuration: TDuration): TParseResult; overload;
    
    // 特定格式解析
    function ParseISO8601(const ADurationStr: string; out ADuration: TDuration): TParseResult; // PT1H30M45S
    function ParseHuman(const ADurationStr: string; out ADuration: TDuration): TParseResult; // "1 hour 30 minutes"
    function ParseCompact(const ADurationStr: string; out ADuration: TDuration): TParseResult; // "1h30m45s"
    function ParsePrecise(const ADurationStr: string; out ADuration: TDuration): TParseResult; // "1:30:45.123"
    
    // 智能解析
    function SmartParse(const ADurationStr: string; out ADuration: TDuration): TParseResult;
    
    // 配置
    procedure SetOptions(const AOptions: TParseOptions);
    function GetOptions: TParseOptions;
  end;

// 工厂函数
function CreateTimeParser: ITimeParser; overload;
function CreateTimeParser(const ALocale: string): ITimeParser; overload;
function CreateDurationParser: IDurationParser; overload;
function CreateDurationParser(const ALocale: string): IDurationParser; overload;

// 默认解析器
function DefaultTimeParser: ITimeParser;
function DefaultDurationParser: IDurationParser;

// 便捷解析函数
function ParseDateTime(const ADateTimeStr: string; out ADateTime: TDateTime): Boolean; overload;
function ParseDateTime(const ADateTimeStr: string; const AFormat: string; out ADateTime: TDateTime): Boolean; overload;
function ParseDate(const ADateStr: string; out ADate: TDate): Boolean; overload;
function ParseDate(const ADateStr: string; const AFormat: string; out ADate: TDate): Boolean; overload;
function ParseTime(const ATimeStr: string; out ATime: TTimeOfDay): Boolean; overload;
function ParseTime(const ATimeStr: string; const AFormat: string; out ATime: TTimeOfDay): Boolean; overload;
function ParseDuration(const ADurationStr: string; out ADuration: TDuration): Boolean; overload;
function ParseDuration(const ADurationStr: string; const AFormat: string; out ADuration: TDuration): Boolean; overload;

// 智能解析函数
function SmartParseDateTime(const ATimeStr: string; out ADateTime: TDateTime): Boolean;
function SmartParseDate(const ATimeStr: string; out ADate: TDate): Boolean;
function SmartParseTime(const ATimeStr: string; out ATime: TTimeOfDay): Boolean;
function SmartParseDuration(const ATimeStr: string; out ADuration: TDuration): Boolean;

// 异常抛出版本
function ParseDateTimeStrict(const ADateTimeStr: string): TDateTime; overload;
function ParseDateTimeStrict(const ADateTimeStr: string; const AFormat: string): TDateTime; overload;
function ParseDateStrict(const ADateStr: string): TDate; overload;
function ParseDateStrict(const ADateStr: string; const AFormat: string): TDate; overload;
function ParseTimeStrict(const ATimeStr: string): TTimeOfDay; overload;
function ParseTimeStrict(const ATimeStr: string; const AFormat: string): TTimeOfDay; overload;
function ParseDurationStrict(const ADurationStr: string): TDuration; overload;
function ParseDurationStrict(const ADurationStr: string; const AFormat: string): TDuration; overload;

// 格式检测
function DetectTimeFormat(const ATimeStr: string): string;
function GetSupportedTimeFormats: TArray<string>;

// 常用格式常量
const
  // ISO 8601 格式
  FORMAT_ISO8601_DATE = 'yyyy-mm-dd';
  FORMAT_ISO8601_TIME = 'hh:nn:ss';
  FORMAT_ISO8601_DATETIME = 'yyyy-mm-dd"T"hh:nn:ss';
  FORMAT_ISO8601_DATETIME_MS = 'yyyy-mm-dd"T"hh:nn:ss.zzz';
  FORMAT_ISO8601_DATETIME_TZ = 'yyyy-mm-dd"T"hh:nn:sszzz';
  
  // RFC 格式
  FORMAT_RFC3339 = 'yyyy-mm-dd"T"hh:nn:ss.zzzzzz';
  FORMAT_RFC2822 = 'ddd, dd mmm yyyy hh:nn:ss zzz';
  
  // 常用格式
  FORMAT_SHORT_DATE = 'm/d/yyyy';
  FORMAT_MEDIUM_DATE = 'mmm d, yyyy';
  FORMAT_LONG_DATE = 'mmmm d, yyyy';
  FORMAT_SHORT_TIME = 'h:nn AM/PM';
  FORMAT_MEDIUM_TIME = 'h:nn:ss AM/PM';
  FORMAT_LONG_TIME = 'hh:nn:ss.zzz';
  
  // 持续时间格式
  FORMAT_DURATION_ISO8601 = 'PT#H#M#S';
  FORMAT_DURATION_COMPACT = '#h#m#s';
  FORMAT_DURATION_PRECISE = '#:#:##.###';

implementation

type
  // 时间解析器实现
  TTimeParser = class(TInterfacedObject, ITimeParser)
  private
    FLocale: string;
    FDefaultOptions: TParseOptions;
    FRegexCache: TStringList;
    
    function BuildRegexPattern(const AFormat: string): string;
    function MatchPattern(const AInput, APattern: string; out AMatches: TStringArray): Boolean;
    function ExtractComponents(const AMatches: TStringArray; const AFormat: string; 
      out AYear, AMonth, ADay, AHour, AMinute, ASecond, AMillisecond: Integer): Boolean;
  public
    constructor Create(const ALocale: string = '');
    destructor Destroy; override;
    
    // ITimeParser 实现
    function ParseDateTime(const ADateTimeStr: string; out ADateTime: TDateTime): TParseResult; overload;
    function ParseDateTime(const ADateTimeStr: string; const AFormat: string; out ADateTime: TDateTime): TParseResult; overload;
    function ParseDateTime(const ADateTimeStr: string; const AOptions: TParseOptions; out ADateTime: TDateTime): TParseResult; overload;
    
    function ParseDate(const ADateStr: string; out ADate: TDate): TParseResult; overload;
    function ParseDate(const ADateStr: string; const AFormat: string; out ADate: TDate): TParseResult; overload;
    function ParseDate(const ADateStr: string; const AOptions: TParseOptions; out ADate: TDate): TParseResult; overload;
    
    function ParseTime(const ATimeStr: string; out ATime: TTimeOfDay): TParseResult; overload;
    function ParseTime(const ATimeStr: string; const AFormat: string; out ATime: TTimeOfDay): TParseResult; overload;
    function ParseTime(const ATimeStr: string; const AOptions: TParseOptions; out ATime: TTimeOfDay): TParseResult; overload;
    
    function ParseDuration(const ADurationStr: string; out ADuration: TDuration): TParseResult; overload;
    function ParseDuration(const ADurationStr: string; const AFormat: string; out ADuration: TDuration): TParseResult; overload;
    function ParseDuration(const ADurationStr: string; const AOptions: TParseOptions; out ADuration: TDuration): TParseResult; overload;
    
    function SmartParse(const ATimeStr: string; out ADateTime: TDateTime): TParseResult; overload;
    function SmartParse(const ATimeStr: string; out ADate: TDate): TParseResult; overload;
    function SmartParse(const ATimeStr: string; out ATime: TTimeOfDay): TParseResult; overload;
    function SmartParse(const ATimeStr: string; out ADuration: TDuration): TParseResult; overload;
    
    function DetectFormat(const ATimeStr: string): string;
    function GetSupportedFormats: TArray<string>;
    
    procedure SetDefaultOptions(const AOptions: TParseOptions);
    function GetDefaultOptions: TParseOptions;
    procedure SetLocale(const ALocale: string);
    function GetLocale: string;
  end;

  // 持续时间解析器实现
  TDurationParser = class(TInterfacedObject, IDurationParser)
  private
    FOptions: TParseOptions;
    
    function ParseISO8601Internal(const ADurationStr: string; out ADuration: TDuration): Boolean;
    function ParseHumanInternal(const ADurationStr: string; out ADuration: TDuration): Boolean;
    function ParseCompactInternal(const ADurationStr: string; out ADuration: TDuration): Boolean;
    function ParsePreciseInternal(const ADurationStr: string; out ADuration: TDuration): Boolean;
  public
    constructor Create(const ALocale: string = '');
    
    // IDurationParser 实现
    function Parse(const ADurationStr: string; out ADuration: TDuration): TParseResult; overload;
    function Parse(const ADurationStr: string; const AFormat: string; out ADuration: TDuration): TParseResult; overload;
    function Parse(const ADurationStr: string; const AOptions: TParseOptions; out ADuration: TDuration): TParseResult; overload;
    
    function ParseISO8601(const ADurationStr: string; out ADuration: TDuration): TParseResult;
    function ParseHuman(const ADurationStr: string; out ADuration: TDuration): TParseResult;
    function ParseCompact(const ADurationStr: string; out ADuration: TDuration): TParseResult;
    function ParsePrecise(const ADurationStr: string; out ADuration: TDuration): TParseResult;
    
    function SmartParse(const ADurationStr: string; out ADuration: TDuration): TParseResult;
    
    procedure SetOptions(const AOptions: TParseOptions);
    function GetOptions: TParseOptions;
  end;

var
  GTimeParser: ITimeParser = nil;
  GDurationParser: IDurationParser = nil;

{ TParseOptions }

class function TParseOptions.Default: TParseOptions;
begin
  Result.Mode := pmLenient;
  Result.Locale := '';
  Result.DefaultTimeZone := '';
  Result.AssumeUTC := False;
  Result.AllowPartialMatch := False;
  Result.CaseSensitive := False;
end;

class function TParseOptions.Strict: TParseOptions;
begin
  Result := Default;
  Result.Mode := pmStrict;
  Result.CaseSensitive := True;
end;

class function TParseOptions.Lenient: TParseOptions;
begin
  Result := Default;
  Result.Mode := pmLenient;
  Result.AllowPartialMatch := True;
end;

class function TParseOptions.Smart: TParseOptions;
begin
  Result := Default;
  Result.Mode := pmSmart;
  Result.AllowPartialMatch := True;
end;

{ TParseResult }

class function TParseResult.CreateSuccess(ALength: Integer; const AFormat: string): TParseResult;
begin
  Result.Success := True;
  Result.ErrorMessage := '';
  Result.ParsedLength := ALength;
  Result.DetectedFormat := AFormat;
end;

class function TParseResult.CreateError(const AMessage: string; APosition: Integer): TParseResult;
begin
  Result.Success := False;
  Result.ErrorMessage := AMessage;
  Result.ParsedLength := APosition;
  Result.DetectedFormat := '';
end;

// 工厂函数实现

function CreateTimeParser: ITimeParser;
begin
  Result := TTimeParser.Create;
end;

function CreateTimeParser(const ALocale: string): ITimeParser;
begin
  Result := TTimeParser.Create(ALocale);
end;

function CreateDurationParser: IDurationParser;
begin
  Result := TDurationParser.Create;
end;

function CreateDurationParser(const ALocale: string): IDurationParser;
begin
  Result := TDurationParser.Create(ALocale);
end;

function DefaultTimeParser: ITimeParser;
begin
  if GTimeParser = nil then
    GTimeParser := CreateTimeParser;
  Result := GTimeParser;
end;

function DefaultDurationParser: IDurationParser;
begin
  if GDurationParser = nil then
    GDurationParser := CreateDurationParser;
  Result := GDurationParser;
end;

// 便捷函数

function ParseDateTime(const ADateTimeStr: string; out ADateTime: TDateTime): Boolean;
var
  result: TParseResult;
begin
  result := DefaultTimeParser.ParseDateTime(ADateTimeStr, ADateTime);
  Result := result.Success;
end;

function ParseDate(const ADateStr: string; out ADate: TDate): Boolean;
var
  result: TParseResult;
begin
  result := DefaultTimeParser.ParseDate(ADateStr, ADate);
  Result := result.Success;
end;

function ParseTime(const ATimeStr: string; out ATime: TTimeOfDay): Boolean;
var
  result: TParseResult;
begin
  result := DefaultTimeParser.ParseTime(ATimeStr, ATime);
  Result := result.Success;
end;

function ParseDuration(const ADurationStr: string; out ADuration: TDuration): Boolean;
var
  result: TParseResult;
begin
  result := DefaultDurationParser.Parse(ADurationStr, ADuration);
  Result := result.Success;
end;

function SmartParseDateTime(const ATimeStr: string; out ADateTime: TDateTime): Boolean;
var
  result: TParseResult;
begin
  result := DefaultTimeParser.SmartParse(ATimeStr, ADateTime);
  Result := result.Success;
end;

function ParseDateTimeStrict(const ADateTimeStr: string): TDateTime;
begin
  if not ParseDateTime(ADateTimeStr, Result) then
    raise EInvalidTimeFormat.CreateFmt('Invalid date/time format: %s', [ADateTimeStr]);
end;

function DetectTimeFormat(const ATimeStr: string): string;
begin
  Result := DefaultTimeParser.DetectFormat(ATimeStr);
end;

// 实现细节将在后续添加...

end.
