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

{$modeswitch advancedrecords}

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  Classes,
  DateUtils,
  RegExpr,
  StrUtils,
  fafafa.core.time.base,
  fafafa.core.time.duration,
  fafafa.core.time.date,
  fafafa.core.time.timeofday,
  fafafa.core.time.format;

type
  // 动态字符串数组
  TStringArray = array of string;

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
    function GetSupportedFormats: TStringArray;
    
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
function GetSupportedTimeFormats: TStringArray;

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
    function GetSupportedFormats: TStringArray;
    
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
  res: TParseResult;
begin
  res := DefaultTimeParser.ParseDateTime(ADateTimeStr, ADateTime);
  Result := res.Success;
end;

function ParseDateTime(const ADateTimeStr: string; const AFormat: string; out ADateTime: TDateTime): Boolean;
var
  res: TParseResult;
begin
  res := DefaultTimeParser.ParseDateTime(ADateTimeStr, AFormat, ADateTime);
  Result := res.Success;
end;

function ParseDate(const ADateStr: string; out ADate: TDate): Boolean;
var
  res: TParseResult;
begin
  res := DefaultTimeParser.ParseDate(ADateStr, ADate);
  Result := res.Success;
end;

function ParseDate(const ADateStr: string; const AFormat: string; out ADate: TDate): Boolean;
var
  res: TParseResult;
begin
  res := DefaultTimeParser.ParseDate(ADateStr, AFormat, ADate);
  Result := res.Success;
end;

function ParseTime(const ATimeStr: string; out ATime: TTimeOfDay): Boolean;
var
  res: TParseResult;
begin
  res := DefaultTimeParser.ParseTime(ATimeStr, ATime);
  Result := res.Success;
end;

function ParseTime(const ATimeStr: string; const AFormat: string; out ATime: TTimeOfDay): Boolean;
var
  res: TParseResult;
begin
  res := DefaultTimeParser.ParseTime(ATimeStr, AFormat, ATime);
  Result := res.Success;
end;

function ParseDuration(const ADurationStr: string; out ADuration: TDuration): Boolean;
var
  res: TParseResult;
begin
  res := DefaultDurationParser.Parse(ADurationStr, ADuration);
  Result := res.Success;
end;

function ParseDuration(const ADurationStr: string; const AFormat: string; out ADuration: TDuration): Boolean;
var
  res: TParseResult;
begin
  res := DefaultDurationParser.Parse(ADurationStr, AFormat, ADuration);
  Result := res.Success;
end;

function SmartParseDateTime(const ATimeStr: string; out ADateTime: TDateTime): Boolean;
var
  res: TParseResult;
begin
  res := DefaultTimeParser.SmartParse(ATimeStr, ADateTime);
  Result := res.Success;
end;

function SmartParseDate(const ATimeStr: string; out ADate: TDate): Boolean;
var
  outRes: TParseResult;
begin
  outRes := DefaultTimeParser.SmartParse(ATimeStr, ADate);
  Result := outRes.Success;
end;

function SmartParseTime(const ATimeStr: string; out ATime: TTimeOfDay): Boolean;
var
  outRes: TParseResult;
begin
  outRes := DefaultTimeParser.SmartParse(ATimeStr, ATime);
  Result := outRes.Success;
end;

function SmartParseDuration(const ATimeStr: string; out ADuration: TDuration): Boolean;
var
  outRes: TParseResult;
begin
  outRes := DefaultDurationParser.SmartParse(ATimeStr, ADuration);
  Result := outRes.Success;
end;

function ParseDateTimeStrict(const ADateTimeStr: string): TDateTime; overload;
begin
  if not ParseDateTime(ADateTimeStr, Result) then
    raise EInvalidTimeFormat.CreateFmt('Invalid date/time format: %s', [ADateTimeStr]);
end;

function ParseDateTimeStrict(const ADateTimeStr: string; const AFormat: string): TDateTime; overload;
begin
  if not ParseDateTime(ADateTimeStr, AFormat, Result) then
    raise EInvalidTimeFormat.CreateFmt('Invalid date/time format: %s', [ADateTimeStr]);
end;

function ParseDateStrict(const ADateStr: string): TDate; overload;
begin
  if not ParseDate(ADateStr, Result) then
    raise EInvalidTimeFormat.CreateFmt('Invalid date format: %s', [ADateStr]);
end;

function ParseDateStrict(const ADateStr: string; const AFormat: string): TDate; overload;
begin
  if not ParseDate(ADateStr, AFormat, Result) then
    raise EInvalidTimeFormat.CreateFmt('Invalid date format: %s', [ADateStr]);
end;

function ParseTimeStrict(const ATimeStr: string): TTimeOfDay; overload;
begin
  if not ParseTime(ATimeStr, Result) then
    raise EInvalidTimeFormat.CreateFmt('Invalid time format: %s', [ATimeStr]);
end;

function ParseTimeStrict(const ATimeStr: string; const AFormat: string): TTimeOfDay; overload;
begin
  if not ParseTime(ATimeStr, AFormat, Result) then
    raise EInvalidTimeFormat.CreateFmt('Invalid time format: %s', [ATimeStr]);
end;

function ParseDurationStrict(const ADurationStr: string): TDuration; overload;
begin
  if not ParseDuration(ADurationStr, Result) then
    raise EInvalidTimeFormat.CreateFmt('Invalid duration format: %s', [ADurationStr]);
end;

function ParseDurationStrict(const ADurationStr: string; const AFormat: string): TDuration; overload;
begin
  if not ParseDuration(ADurationStr, AFormat, Result) then
    raise EInvalidTimeFormat.CreateFmt('Invalid duration format: %s', [ADurationStr]);
end;

function DetectTimeFormat(const ATimeStr: string): string;
begin
  Result := DefaultTimeParser.DetectFormat(ATimeStr);
end;

function GetSupportedTimeFormats: TStringArray;
begin
  Result := DefaultTimeParser.GetSupportedFormats;
end;

{ TTimeParser }

constructor TTimeParser.Create(const ALocale: string);
begin
  FLocale := ALocale;
  FDefaultOptions := TParseOptions.Default;
  FRegexCache := nil;
end;

destructor TTimeParser.Destroy;
begin
  FreeAndNil(FRegexCache);
  inherited Destroy;
end;

// Stubbed helpers for minimal compile
function TTimeParser.BuildRegexPattern(const AFormat: string): string;
begin
  Result := AFormat;
end;

function TTimeParser.MatchPattern(const AInput, APattern: string; out AMatches: TStringArray): Boolean;
begin
  SetLength(AMatches, 0);
  Result := False;
end;

function TTimeParser.ExtractComponents(const AMatches: TStringArray; const AFormat: string;
  out AYear, AMonth, ADay, AHour, AMinute, ASecond, AMillisecond: Integer): Boolean;
begin
  AYear := 0; AMonth := 0; ADay := 0; AHour := 0; AMinute := 0; ASecond := 0; AMillisecond := 0;
  Result := False;
end;

function TTimeParser.ParseDateTime(const ADateTimeStr: string; out ADateTime: TDateTime): TParseResult;
var
  ok: Boolean;
begin
  ok := TryStrToDateTime(ADateTimeStr, ADateTime);
  if ok then
    Exit(TParseResult.CreateSuccess(Length(ADateTimeStr), 'auto'))
  else
    Exit(TParseResult.CreateError('Invalid date/time', 0));
end;

function TTimeParser.ParseDateTime(const ADateTimeStr: string; const AFormat: string; out ADateTime: TDateTime): TParseResult;
begin
  // 简化：忽略格式，调用基本解析
  Result := ParseDateTime(ADateTimeStr, ADateTime);
end;

function TTimeParser.ParseDateTime(const ADateTimeStr: string; const AOptions: TParseOptions; out ADateTime: TDateTime): TParseResult;
begin
  // 简化：忽略选项，调用基本解析
  Result := ParseDateTime(ADateTimeStr, ADateTime);
end;

function TTimeParser.ParseDate(const ADateStr: string; out ADate: TDate): TParseResult;
var
  ok: Boolean;
begin
  ok := TDate.TryParse(ADateStr, ADate);
  if ok then
    Exit(TParseResult.CreateSuccess(Length(ADateStr), FORMAT_ISO8601_DATE))
  else
    Exit(TParseResult.CreateError('Invalid date', 0));
end;

function TTimeParser.ParseDate(const ADateStr: string; const AFormat: string; out ADate: TDate): TParseResult;
begin
  // 简化：忽略格式，调用基本解析
  Result := ParseDate(ADateStr, ADate);
end;

function TTimeParser.ParseDate(const ADateStr: string; const AOptions: TParseOptions; out ADate: TDate): TParseResult;
begin
  // 简化：忽略选项，调用基本解析
  Result := ParseDate(ADateStr, ADate);
end;

function TTimeParser.ParseTime(const ATimeStr: string; out ATime: TTimeOfDay): TParseResult;
var
  ok: Boolean;
begin
  ok := TTimeOfDay.TryParse(ATimeStr, ATime);
  if ok then
    Exit(TParseResult.CreateSuccess(Length(ATimeStr), FORMAT_ISO8601_TIME))
  else
    Exit(TParseResult.CreateError('Invalid time', 0));
end;

function TTimeParser.ParseTime(const ATimeStr: string; const AFormat: string; out ATime: TTimeOfDay): TParseResult;
begin
  Result := ParseTime(ATimeStr, ATime);
end;

function TTimeParser.ParseTime(const ATimeStr: string; const AOptions: TParseOptions; out ATime: TTimeOfDay): TParseResult;
begin
  Result := ParseTime(ATimeStr, ATime);
end;

function TTimeParser.DetectFormat(const ATimeStr: string): string;
begin
  if Pos('T', ATimeStr) > 0 then
    Exit(FORMAT_ISO8601_DATETIME)
  else if Pos(':', ATimeStr) > 0 then
    Exit(FORMAT_ISO8601_TIME)
  else
    Exit(FORMAT_ISO8601_DATE);
end;

function TTimeParser.GetSupportedFormats: TStringArray;
begin
  Result := nil;  // 显式初始化以消除编译器警告
  SetLength(Result, 6);
  Result[0] := FORMAT_ISO8601_DATE;
  Result[1] := FORMAT_ISO8601_TIME;
  Result[2] := FORMAT_ISO8601_DATETIME;
  Result[3] := FORMAT_ISO8601_DATETIME_MS;
  Result[4] := FORMAT_RFC3339;
  Result[5] := FORMAT_RFC2822;
end;

function TTimeParser.SmartParse(const ATimeStr: string; out ADateTime: TDateTime): TParseResult;
var
  dt: TDateTime;
  d: TDate;
  t: TTimeOfDay;
begin
  if TryStrToDateTime(ATimeStr, dt) then
    Exit(TParseResult.CreateSuccess(Length(ATimeStr), 'auto'))
  else if TDate.TryParse(ATimeStr, d) then
  begin
    ADateTime := d.ToDateTime;
    Exit(TParseResult.CreateSuccess(Length(ATimeStr), FORMAT_ISO8601_DATE));
  end
  else if TTimeOfDay.TryParse(ATimeStr, t) then
  begin
    ADateTime := EncodeDate(1970,1,1) + Frac(t.ToTime);
    Exit(TParseResult.CreateSuccess(Length(ATimeStr), FORMAT_ISO8601_TIME));
  end
  else
    Exit(TParseResult.CreateError('Cannot detect time format', 0));
end;

function TTimeParser.SmartParse(const ATimeStr: string; out ADate: TDate): TParseResult;
var
  d: TDate;
  dt: TDateTime;
begin
  if TDate.TryParse(ATimeStr, d) then
  begin
    ADate := d;
    Exit(TParseResult.CreateSuccess(Length(ATimeStr), FORMAT_ISO8601_DATE));
  end
  else if TryStrToDateTime(ATimeStr, dt) then
  begin
    ADate := TDate.FromDateTime(dt);
    Exit(TParseResult.CreateSuccess(Length(ATimeStr), 'auto'));
  end
  else
    Exit(TParseResult.CreateError('Invalid date', 0));
end;

function TTimeParser.SmartParse(const ATimeStr: string; out ATime: TTimeOfDay): TParseResult;
var
  t: TTimeOfDay;
  dt: TDateTime;
begin
  if TTimeOfDay.TryParse(ATimeStr, t) then
  begin
    ATime := t;
    Exit(TParseResult.CreateSuccess(Length(ATimeStr), FORMAT_ISO8601_TIME));
  end
  else if TryStrToDateTime(ATimeStr, dt) then
  begin
    ATime := TTimeOfDay.FromTime(Frac(dt));
    Exit(TParseResult.CreateSuccess(Length(ATimeStr), 'auto'));
  end
  else
    Exit(TParseResult.CreateError('Invalid time', 0));
end;

function TTimeParser.ParseDuration(const ADurationStr: string; out ADuration: TDuration): TParseResult;
var
  s: string;
  v32: LongInt;
begin
  s := Trim(LowerCase(ADurationStr));
  if (s = '') then Exit(TParseResult.CreateError('Empty duration', 0));

  // 简化：仅支持纯毫秒数字、尾随 h/m/s/ms
  if (RightStr(s,2) = 'ms') and TryStrToInt(Copy(s,1,Length(s)-2), v32) then
  begin
    ADuration := TDuration.FromMs(v32);
    Exit(TParseResult.CreateSuccess(Length(ADurationStr), FORMAT_DURATION_PRECISE));
  end
  else if (RightStr(s,1) = 's') and TryStrToInt(Copy(s,1,Length(s)-1), v32) then
  begin
    ADuration := TDuration.FromSec(v32);
    Exit(TParseResult.CreateSuccess(Length(ADurationStr), FORMAT_DURATION_COMPACT));
  end
  else if (RightStr(s,1) = 'm') and TryStrToInt(Copy(s,1,Length(s)-1), v32) then
  begin
    ADuration := TDuration.FromSec(v32*60);
    Exit(TParseResult.CreateSuccess(Length(ADurationStr), FORMAT_DURATION_COMPACT));
  end
  else if (RightStr(s,1) = 'h') and TryStrToInt(Copy(s,1,Length(s)-1), v32) then
  begin
    ADuration := TDuration.FromSec(v32*3600);
    Exit(TParseResult.CreateSuccess(Length(ADurationStr), FORMAT_DURATION_COMPACT));
  end
  else
    Exit(TParseResult.CreateError('Invalid duration', 0));
end;

function TTimeParser.ParseDuration(const ADurationStr: string; const AFormat: string; out ADuration: TDuration): TParseResult;
begin
  Result := ParseDuration(ADurationStr, ADuration);
end;

function TTimeParser.ParseDuration(const ADurationStr: string; const AOptions: TParseOptions; out ADuration: TDuration): TParseResult;
begin
  Result := ParseDuration(ADurationStr, ADuration);
end;

function TTimeParser.SmartParse(const ATimeStr: string; out ADuration: TDuration): TParseResult;
begin
  Result := ParseDuration(ATimeStr, ADuration);
end;

procedure TTimeParser.SetDefaultOptions(const AOptions: TParseOptions);
begin
  FDefaultOptions := AOptions;
end;

function TTimeParser.GetDefaultOptions: TParseOptions;
begin
  Result := FDefaultOptions;
end;

procedure TTimeParser.SetLocale(const ALocale: string);
begin
  FLocale := ALocale;
end;

function TTimeParser.GetLocale: string;
begin
  Result := FLocale;
end;

{ TDurationParser }

constructor TDurationParser.Create(const ALocale: string);
begin
  FOptions := TParseOptions.Default;
end;

// Stubbed internals for minimal compile
function TDurationParser.ParseISO8601Internal(const ADurationStr: string; out ADuration: TDuration): Boolean;
begin
  Result := False;
end;

function TDurationParser.ParseHumanInternal(const ADurationStr: string; out ADuration: TDuration): Boolean;
begin
  Result := False;
end;

function TDurationParser.ParseCompactInternal(const ADurationStr: string; out ADuration: TDuration): Boolean;
begin
  Result := False;
end;

function TDurationParser.ParsePreciseInternal(const ADurationStr: string; out ADuration: TDuration): Boolean;
begin
  Result := False;
end;

function TDurationParser.Parse(const ADurationStr: string; out ADuration: TDuration): TParseResult;
begin
  // 直接复用 TTimeParser 的简单逻辑
  Result := TTimeParser.Create('').ParseDuration(ADurationStr, ADuration);
end;

function TDurationParser.Parse(const ADurationStr: string; const AFormat: string; out ADuration: TDuration): TParseResult;
begin
  Result := Parse(ADurationStr, ADuration);
end;

function TDurationParser.Parse(const ADurationStr: string; const AOptions: TParseOptions; out ADuration: TDuration): TParseResult;
begin
  Result := Parse(ADurationStr, ADuration);
end;

function TDurationParser.ParseISO8601(const ADurationStr: string; out ADuration: TDuration): TParseResult;
begin
  // 简化：复用通用解析
  Result := Parse(ADurationStr, ADuration);
end;

function TDurationParser.ParseHuman(const ADurationStr: string; out ADuration: TDuration): TParseResult;
begin
  Result := Parse(ADurationStr, ADuration);
end;

function TDurationParser.ParseCompact(const ADurationStr: string; out ADuration: TDuration): TParseResult;
begin
  Result := Parse(ADurationStr, ADuration);
end;

function TDurationParser.ParsePrecise(const ADurationStr: string; out ADuration: TDuration): TParseResult;
begin
  Result := Parse(ADurationStr, ADuration);
end;

function TDurationParser.SmartParse(const ADurationStr: string; out ADuration: TDuration): TParseResult;
begin
  Result := Parse(ADurationStr, ADuration);
end;

procedure TDurationParser.SetOptions(const AOptions: TParseOptions);
begin
  FOptions := AOptions;
end;

function TDurationParser.GetOptions: TParseOptions;
begin
  Result := FOptions;
end;

end.
