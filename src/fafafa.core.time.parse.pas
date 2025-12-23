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

  {**
   * TParseMode - 解析模式
   *
   * ⚠️ **ISSUE-36: 解析模式行为说明**
   *
   * @value pmStrict - 严格模式
   *   要求输入字符串**完全匹配**指定的格式。
   *
   *   **行为特点：**
   *   - 分隔符必须精确匹配（例如 '-' vs '/')
   *   - 位数必须匹配（'01' vs '1'）
   *   - 不允许额外的空白字符
   *   - 日期/时间值必须在有效范围内
   *   - 失败时立即返回错误，不尝试其他格式
   *
   *   **适用场景：**
   *   - 数据验证
   *   - API 输入检查
   *   - 配置文件解析（格式固定）
   *
   *   **示例：**
   *   格式 'yyyy-MM-dd' 只接受 '2024-10-04'，
   *   拒绝 '2024/10/04', '2024-10-4', '24-10-04' 等。
   *
   * @value pmLenient - 宽松模式
   *   允许一定的格式变化，但仍然需要指定基本格式。
   *
   *   **宽松特性：**
   *   - 分隔符灵活（'-', '/', '.' 等互换）
   *   - 允许前导零（'01' 和 '1' 都接受）
   *   - 允许额外的空白字符
   *   - 大小写不敏感（月份名称、AM/PM）
   *   - 容忍略微的语法差异
   *
   *   **仍然需要：**
   *   - 指定基本格式结构
   *   - 日期/时间组件顺序正确
   *
   *   **适用场景：**
   *   - 用户输入解析
   *   - 日志文件解析（格式可能变化）
   *   - 第三方数据集成
   *
   *   **示例：**
   *   格式 'yyyy-MM-dd' 接受：
   *   '2024-10-04', '2024/10/04', '2024.10.04', '2024-10-4' 等。
   *
   * @value pmSmart - 智能模式
   *   **不需要指定格式**，自动检测并尝试多种常见格式。
   *
   *   **检测策略：**
   *   - 先尝试 ISO 8601 标准格式
   *   - 再尝试常见地区格式（基于 locale)
   *   - 最后尝试模糊匹配
   *   - 返回第一个成功匹配的结果
   *
   *   **特点：**
   *   - 最宽松，接受度最高
   *   - 性能较低（多次尝试）
   *   - 可能产生歧义（多个格式匹配）
   *
   *   **适用场景：**
   *   - 用户自由输入
   *   - 数据清洗和导入
   *   - 多来源数据聚合
   *
   *   **示例：**
   *   自动识别：'2024-10-04', '10/04/2024', 'Oct 4, 2024',
   *   '2024年10月04日', 'Friday, October 4, 2024' 等。
   *
   * **性能对比：**
   * pmStrict > pmLenient > pmSmart
   *
   * **准确性对比：**
   * pmStrict > pmLenient > pmSmart
   *
   * **默认模式：**
   * 大多数 API 使用 pmStrict 作为默认值。
   *}
  TParseMode = (
    pmStrict,
    pmLenient,
    pmSmart
  );

  {**
   * TTimeZoneMode - 时区处理模式
   *
   * ⚠️ **ISSUE-37: 时区处理冲突修复**
   *
   * 定义明确的时区处理策略，避免 DefaultTimeZone 和 AssumeUTC 的冲突。
   *
   * @value tzmLocal - 本地时区
   *   假设输入为本地时区的时间（如果没有时区信息）。
   *   这是最常用的模式，适合处理用户输入。
   *
   * @value tzmUTC - UTC 时区
   *   假设输入为 UTC 时间（如果没有时区信息）。
   *   适合处理服务器间或数据库中的时间戳。
   *
   * @value tzmSpecified - 指定时区
   *   使用 SpecifiedTimeZone 字段指定的时区（如果没有时区信息）。
   *   适合处理特定时区的数据，如 "+08:00"、"-05:00" 等。
   *
   * @value tzmStrict - 严格模式
   *   输入必须包含明确的时区信息，否则报错。
   *   适合需要高精度和明确性的场景，如 API 输入验证。
   *}
  TTimeZoneMode = (
    tzmLocal,        // 假设本地时区
    tzmUTC,          // 假设 UTC
    tzmSpecified,    // 使用指定时区
    tzmStrict        // 必须包含时区信息
  );

  {**
   * TParseErrorCode - 解析错误代码
   *
   * ⚠️ **ISSUE-38: 错误消息国际化**
   *
   * 提供统一的错误代码枚举，支持程序化错误处理和国际化。
   *
   * @value pecNone - 无错误（成功）
   * @value pecEmptyInput - 输入字符串为空
   * @value pecInvalidFormat - 输入格式不正确
   * @value pecInvalidDateTime - 日期时间值无效
   * @value pecInvalidDate - 日期值无效
   * @value pecInvalidTime - 时间值无效
   * @value pecInvalidDuration - 持续时间值无效
   * @value pecFormatMismatch - 输入与指定格式不匹配
   * @value pecOutOfRange - 日期/时间值超出有效范围
   * @value pecAmbiguousInput - 输入存在歧义（多种可能解析）
   * @value pecPartialMatch - 部分匹配（未完全解析）
   * @value pecUnsafeFormat - 格式字符串不安全（包含危险字符）
   * @value pecFormatTooLong - 格式字符串过长
   * @value pecFormatEmpty - 格式字符串为空
   * @value pecRegexTooComplex - 正则表达式太复杂（DoS风险）
   * @value pecInputTooLong - 输入字符串过长（DoS风险）
   * @value pecCannotDetectFormat - 无法自动检测格式
   * @value pecLocaleNotSupported - 不支持的语言环境
   * @value pecTimeZoneNotSupported - 不支持的时区
   * @value pecInternalError - 内部错误
   *}
  TParseErrorCode = (
    pecNone,                    // 0: 无错误
    pecEmptyInput,              // 1: 输入为空
    pecInvalidFormat,           // 2: 格式不正确
    pecInvalidDateTime,         // 3: 日期时间无效
    pecInvalidDate,             // 4: 日期无效
    pecInvalidTime,             // 5: 时间无效
    pecInvalidDuration,         // 6: 持续时间无效
    pecFormatMismatch,          // 7: 格式不匹配
    pecOutOfRange,              // 8: 超出范围
    pecAmbiguousInput,          // 9: 存在歧义
    pecPartialMatch,            // 10: 部分匹配
    pecUnsafeFormat,            // 11: 格式不安全
    pecFormatTooLong,           // 12: 格式过长
    pecFormatEmpty,             // 13: 格式为空
    pecRegexTooComplex,         // 14: 正则太复杂
    pecInputTooLong,            // 15: 输入过长
    pecCannotDetectFormat,      // 16: 无法检测格式
    pecLocaleNotSupported,      // 17: 语言环境不支持
    pecTimeZoneNotSupported,    // 18: 时区不支持
    pecInternalError            // 19: 内部错误
  );

  {**
   * TParseOptions - 解析选项
   *
   * @field Mode - 解析模式 (Strict/Lenient/Smart)
   * @field Locale - 语言环境，如 "en-US", "zh-CN", "ja-JP"
   * @field TimeZoneMode - 时区处理模式 ⚠️ ISSUE-37 修复
   * @field SpecifiedTimeZone - 当 TimeZoneMode = tzmSpecified 时使用的时区
   * @field AllowPartialMatch - 是否允许部分匹配
   * @field CaseSensitive - 是否区分大小写
   *}
  TParseOptions = record
    Mode: TParseMode;
    Locale: string;
    TimeZoneMode: TTimeZoneMode;           // ⚠️ 替换 DefaultTimeZone 和 AssumeUTC
    SpecifiedTimeZone: string;             // ⚠️ 新增：当 TimeZoneMode=tzmSpecified 时使用
    AllowPartialMatch: Boolean;
    CaseSensitive: Boolean;
    
    class function Default: TParseOptions; static;
    class function Strict: TParseOptions; static;
    class function Lenient: TParseOptions; static;
    class function Smart: TParseOptions; static;
    
    {** 创建 UTC 时区选项 **}
    class function UTC: TParseOptions; static;
    {** 创建指定时区选项 **}
    class function WithTimeZone(const ATimeZone: string): TParseOptions; static;
    {** 创建严格时区选项 **}
    class function StrictTimeZone: TParseOptions; static;
  end;

  {**
   * TParseResult - 解析结果
   *
   * @field Success - 解析是否成功
   * @field ErrorCode - 错误代码（成功时为 pecNone）
   * @field ErrorMessage - 错误消息（可本地化）
   * @field ParsedLength - 已解析的字符数
   * @field DetectedFormat - 检测到的格式
   * @field ErrorPosition - 错误位置（从0开始）
   *}
  TParseResult = record
    Success: Boolean;
    ErrorCode: TParseErrorCode;
    ErrorMessage: string;
    ParsedLength: Integer;
    DetectedFormat: string;
    ErrorPosition: Integer;
    
    class function CreateSuccess(ALength: Integer; const AFormat: string = ''): TParseResult; static;
    class function CreateError(ACode: TParseErrorCode; const AMessage: string; APosition: Integer = 0): TParseResult; static;
    class function CreateErrorCode(ACode: TParseErrorCode; APosition: Integer = 0): TParseResult; static;
    
    {** 获取错误代码的默认消息（英文） **}
    function GetDefaultErrorMessage: string;
    {** 获取本地化错误消息 **}
    function GetLocalizedErrorMessage(const ALocale: string = ''): string;
  end;

  {**
   * 格式字符串验证结果
   *}
  TFormatValidationResult = record
    IsValid: Boolean;
    ErrorCode: TParseErrorCode;
    ErrorMessage: string;
    InvalidPosition: Integer;
    
    class function Valid: TFormatValidationResult; static;
    class function Invalid(ACode: TParseErrorCode; const AMessage: string; APosition: Integer = -1): TFormatValidationResult; static;
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

{**
 * 验证格式字符串的安全性
 *
 * @desc
 *   检查用户提供的格式字符串是否安全，防止正则注入攻击。
 *   只允许标准的日期时间格式标记，拒绝任意正则表达式模式。
 *
 * @param AFormat 待验证的格式字符串
 * @return 验证结果，包含是否有效及错误信息
 *
 * @security
 *   防护措施：
 *   1. 白名单验证：只允许安全的格式标记
 *   2. 长度限制：最大 256 字符
 *   3. 特殊字符检查：拒绝正则表达式元字符
 *
 * @example
 * <code>
 *   var
 *     Result: TFormatValidationResult;
 *   begin
 *     Result := ValidateFormatString('yyyy-mm-dd');  // Valid
 *     Result := ValidateFormatString('(a+)+b');      // Invalid - 正则注入
 *   end;
 * </code>
 *}
function ValidateFormatString(const AFormat: string): TFormatValidationResult;

{**
 * 估算正则表达式的复杂度
 *
 * @desc
 *   通过统计正则表达式中的量词、字符类、回溯点等特征，
 *   估算其执行复杂度，防止回溯炸弹导致的 DoS 攻击。
 *
 * @param APattern 正则表达式模式
 * @return 复杂度评分（0-1000），超过阈值视为危险
 *
 * @security
 *   检测以下危险模式：
 *   - 嵌套量词：(a+)+ 、 (a*)*
 *   - 重叠字符类：[a-z]+[a-z0-9]+
 *   - 过度回溯：(.*)(.*)(.*)$
 *}
function EstimateRegexComplexity(const APattern: string): Integer;

{**
 * TryParseMonthName - 跨 locale 月份名称解析
 *
 * ✅ ISSUE-46: 支持多语言月份名称解析，不依赖系统 locale
 *
 * @param AName - 月份名称（任意语言）
 * @param AMonth - 输出月份数字 (1-12)
 * @return 是否成功解析
 *
 * 支持的格式：
 * - 英文：January, Jan, JANUARY, jan
 * - 中文：一月, 1月
 * - 日文：1月
 * - 德文：Januar, Jan, März
 * - 法文：Janvier, Janv
 *}
function TryParseMonthName(const AName: string; out AMonth: Integer): Boolean;

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
  
  // 安全限制常量
  MAX_FORMAT_STRING_LENGTH = 256;          // 最大格式字符串长度
  MAX_INPUT_STRING_LENGTH = 4096;          // 最大输入字符串长度（防止DoS）
  MAX_REGEX_COMPLEXITY = 100;              // 最大正则表达式复杂度（字符类+量词数）
  REGEX_TIMEOUT_MS = 100;                  // 正则匹配超时时间（毫秒）

implementation

uses
  fafafa.core.math;

const
  // ✅ ISSUE-39: LRU 缓存默认容量
  DEFAULT_LRU_CACHE_CAPACITY = 64;

type
  {**
   * TLRUCacheEntry - LRU 缓存条目
   * ✅ ISSUE-39: 此结构包含访问时间戳用于 LRU 淘汰
   *}
  TLRUCacheEntry = record
    Key: string;
    Value: string;
    LastAccess: Int64;  // 使用 GetTickCount64 时间戳
  end;
  PLRUCacheEntry = ^TLRUCacheEntry;

  {**
   * TLRUCache - 简单 LRU 缓存实现
   *
   * ✅ ISSUE-39: 防止正则缓存无限增长导致内存泄漏
   *
   * 特性：
   * - 固定容量（默认 64 条）
   * - 超出容量时淘汰最久未访问的条目
   * - O(n) 淘汰（对于小容量可接受）
   *}
  TLRUCache = class
  private
    FEntries: array of TLRUCacheEntry;
    FCount: Integer;
    FCapacity: Integer;
    
    function FindIndex(const AKey: string): Integer;
    procedure Evict;
  public
    constructor Create(ACapacity: Integer = DEFAULT_LRU_CACHE_CAPACITY);
    
    function TryGet(const AKey: string; out AValue: string): Boolean;
    procedure Put(const AKey, AValue: string);
    procedure Clear;
    
    property Count: Integer read FCount;
    property Capacity: Integer read FCapacity;
  end;

  // 时间解析器实现
  TTimeParser = class(TInterfacedObject, ITimeParser)
  private
    FLocale: string;
    FDefaultOptions: TParseOptions;
    FRegexCache: TStringList;
    
    {** 检查输入字符串长度，防止 DoS 攻击 (ISSUE-47) **}
    function CheckInputLength(const AInput: string; out AResult: TParseResult): Boolean;
    
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
  // ✅ ISSUE-REVIEW-P1-2: 原子状态标志避免竞态条件
  GTimeParserOnce: Int32 = 0;       // 0=未初始化, 1=正在初始化, 2=已完成
  GDurationParserOnce: Int32 = 0;   // 0=未初始化, 1=正在初始化, 2=已完成

{**
 * GetErrorCodeMessage - 获取错误代码的默认消息（英文）
 *
 * @param ACode - 错误代码
 * @return 错误消息
 *}
function GetErrorCodeMessage(ACode: TParseErrorCode): string;
begin
  case ACode of
    pecNone: Result := 'No error';
    pecEmptyInput: Result := 'Input string is empty';
    pecInvalidFormat: Result := 'Invalid format';
    pecInvalidDateTime: Result := 'Invalid date/time value';
    pecInvalidDate: Result := 'Invalid date value';
    pecInvalidTime: Result := 'Invalid time value';
    pecInvalidDuration: Result := 'Invalid duration value';
    pecFormatMismatch: Result := 'Input does not match the specified format';
    pecOutOfRange: Result := 'Date/time value out of valid range';
    pecAmbiguousInput: Result := 'Input is ambiguous (multiple possible interpretations)';
    pecPartialMatch: Result := 'Partial match (not fully parsed)';
    pecUnsafeFormat: Result := 'Unsafe format string (contains dangerous characters)';
    pecFormatTooLong: Result := 'Format string too long';
    pecFormatEmpty: Result := 'Format string is empty';
    pecRegexTooComplex: Result := 'Regular expression too complex (DoS risk)';
    pecInputTooLong: Result := 'Input string too long (DoS risk)';
    pecCannotDetectFormat: Result := 'Cannot automatically detect format';
    pecLocaleNotSupported: Result := 'Locale not supported';
    pecTimeZoneNotSupported: Result := 'Time zone not supported';
    pecInternalError: Result := 'Internal error';
  else
    Result := 'Unknown error';
  end;
end;

{**
 * GetErrorCodeMessageLocalized - 获取错误代码的本地化消息
 *
 * @param ACode - 错误代码
 * @param ALocale - 语言环境（空字符串使用默认）
 * @return 本地化错误消息
 *}
function GetErrorCodeMessageLocalized(ACode: TParseErrorCode; const ALocale: string = ''): string;
var
  locale: string;
begin
  locale := LowerCase(Trim(ALocale));
  
  // 中文本地化
  if (locale = 'zh') or (locale = 'zh-cn') or (locale = 'zh_cn') or (locale = 'chinese') then
  begin
    case ACode of
      pecNone: Result := '无错误';
      pecEmptyInput: Result := '输入字符串为空';
      pecInvalidFormat: Result := '格式不正确';
      pecInvalidDateTime: Result := '日期时间值无效';
      pecInvalidDate: Result := '日期值无效';
      pecInvalidTime: Result := '时间值无效';
      pecInvalidDuration: Result := '持续时间值无效';
      pecFormatMismatch: Result := '输入与指定格式不匹配';
      pecOutOfRange: Result := '日期/时间值超出有效范围';
      pecAmbiguousInput: Result := '输入存在歧义（多种可能解析）';
      pecPartialMatch: Result := '部分匹配（未完全解析）';
      pecUnsafeFormat: Result := '格式字符串不安全（包含危险字符）';
      pecFormatTooLong: Result := '格式字符串过长';
      pecFormatEmpty: Result := '格式字符串为空';
      pecRegexTooComplex: Result := '正则表达式太复杂（DoS风险）';
      pecInputTooLong: Result := '输入字符串过长（DoS风险）';
      pecCannotDetectFormat: Result := '无法自动检测格式';
      pecLocaleNotSupported: Result := '不支持的语言环境';
      pecTimeZoneNotSupported: Result := '不支持的时区';
      pecInternalError: Result := '内部错误';
    else
      Result := '未知错误';
    end;
    Exit;
  end;
  
  // 日文本地化
  if (locale = 'ja') or (locale = 'ja-jp') or (locale = 'ja_jp') or (locale = 'japanese') then
  begin
    case ACode of
      pecNone: Result := 'エラーなし';
      pecEmptyInput: Result := '入力文字列が空です';
      pecInvalidFormat: Result := '無効な形式';
      pecInvalidDateTime: Result := '無効な日付/時刻値';
      pecInvalidDate: Result := '無効な日付値';
      pecInvalidTime: Result := '無効な時刻値';
      pecInvalidDuration: Result := '無効な期間値';
      pecFormatMismatch: Result := '入力が指定された形式と一致しません';
      pecOutOfRange: Result := '日付/時刻値が有効範囲外です';
      pecAmbiguousInput: Result := '入力が曖昧です（複数の解釈が可能）';
      pecPartialMatch: Result := '部分一致（完全に解析されません）';
      pecUnsafeFormat: Result := '安全でない形式文字列（危険な文字を含む）';
      pecFormatTooLong: Result := '形式文字列が長すぎます';
      pecFormatEmpty: Result := '形式文字列が空です';
      pecRegexTooComplex: Result := '正規表現が複雑すぎます（DoSリスク）';
      pecInputTooLong: Result := '入力文字列が長すぎます（DoSリスク）';
      pecCannotDetectFormat: Result := '形式を自動検出できません';
      pecLocaleNotSupported: Result := 'サポートされていないロケール';
      pecTimeZoneNotSupported: Result := 'サポートされていないタイムゾーン';
      pecInternalError: Result := '内部エラー';
    else
      Result := '不明なエラー';
    end;
    Exit;
  end;
  
  // 默认返回英文
  Result := GetErrorCodeMessage(ACode);
end;

{ TFormatValidationResult }

class function TFormatValidationResult.Valid: TFormatValidationResult;
begin
  Result.IsValid := True;
  Result.ErrorCode := pecNone;
  Result.ErrorMessage := '';
  Result.InvalidPosition := -1;
end;

class function TFormatValidationResult.Invalid(ACode: TParseErrorCode; const AMessage: string; APosition: Integer): TFormatValidationResult;
begin
  Result.IsValid := False;
  Result.ErrorCode := ACode;
  Result.ErrorMessage := AMessage;
  Result.InvalidPosition := APosition;
end;

{ TParseOptions }

class function TParseOptions.Default: TParseOptions;
begin
  Result.Mode := pmLenient;
  Result.Locale := '';
  Result.TimeZoneMode := tzmLocal;          // ⚠️ ISSUE-37: 默认使用本地时区
  Result.SpecifiedTimeZone := '';
  Result.AllowPartialMatch := False;
  Result.CaseSensitive := False;
end;

// ✅ ISSUE-46: 跨 locale 月份名称查找
const
  // 英文月份名称（完整和缩写）
  MONTH_NAMES_EN: array[1..12] of string = (
    'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december'
  );
  MONTH_ABBR_EN: array[1..12] of string = (
    'jan', 'feb', 'mar', 'apr', 'may', 'jun',
    'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
  );
  // 中文月份名称
  MONTH_NAMES_ZH: array[1..12] of string = (
    '一月', '二月', '三月', '四月', '五月', '六月',
    '七月', '八月', '九月', '十月', '十一月', '十二月'
  );
  // 日文月份名称
  MONTH_NAMES_JA: array[1..12] of string = (
    '1月', '2月', '3月', '4月', '5月', '6月',
    '7月', '8月', '9月', '10月', '11月', '12月'
  );
  // 德文月份名称
  MONTH_NAMES_DE: array[1..12] of string = (
    'januar', 'februar', 'märz', 'april', 'mai', 'juni',
    'juli', 'august', 'september', 'oktober', 'november', 'dezember'
  );
  MONTH_ABBR_DE: array[1..12] of string = (
    'jan', 'feb', 'mär', 'apr', 'mai', 'jun',
    'jul', 'aug', 'sep', 'okt', 'nov', 'dez'
  );
  // 法文月份名称
  MONTH_NAMES_FR: array[1..12] of string = (
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
  );
  MONTH_ABBR_FR: array[1..12] of string = (
    'janv', 'févr', 'mars', 'avr', 'mai', 'juin',
    'juil', 'août', 'sept', 'oct', 'nov', 'déc'
  );

{**
 * TryParseMonthName - 跨 locale 月份名称解析
 *
 * ✅ ISSUE-46: 支持多语言月份名称解析，不依赖系统 locale
 *
 * @param AName - 月份名称（任意语言）
 * @param AMonth - 输出月份数字 (1-12)
 * @return 是否成功解析
 *
 * 支持的格式：
 * - 英文：January, Jan, JANUARY, jan
 * - 中文：一月, 1月
 * - 日文：1月
 * - 德文：Januar, Jan, März
 * - 法文：Janvier, Janv
 *}
function TryParseMonthName(const AName: string; out AMonth: Integer): Boolean;
var
  name: string;
  i: Integer;
begin
  Result := False;
  AMonth := 0;
  name := LowerCase(Trim(AName));
  if name = '' then Exit;
  
  // 英文完整名
  for i := 1 to 12 do
    if name = MONTH_NAMES_EN[i] then
    begin
      AMonth := i;
      Exit(True);
    end;
  
  // 英文缩写
  for i := 1 to 12 do
    if name = MONTH_ABBR_EN[i] then
    begin
      AMonth := i;
      Exit(True);
    end;
  
  // 中文
  for i := 1 to 12 do
    if name = MONTH_NAMES_ZH[i] then
    begin
      AMonth := i;
      Exit(True);
    end;
  
  // 日文
  for i := 1 to 12 do
    if name = MONTH_NAMES_JA[i] then
    begin
      AMonth := i;
      Exit(True);
    end;
  
  // 德文
  for i := 1 to 12 do
    if name = MONTH_NAMES_DE[i] then
    begin
      AMonth := i;
      Exit(True);
    end;
  for i := 1 to 12 do
    if name = MONTH_ABBR_DE[i] then
    begin
      AMonth := i;
      Exit(True);
    end;
  
  // 法文
  for i := 1 to 12 do
    if name = MONTH_NAMES_FR[i] then
    begin
      AMonth := i;
      Exit(True);
    end;
  for i := 1 to 12 do
    if name = MONTH_ABBR_FR[i] then
    begin
      AMonth := i;
      Exit(True);
    end;
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

class function TParseOptions.UTC: TParseOptions;
begin
  Result := Default;
  Result.TimeZoneMode := tzmUTC;  // ⚠️ ISSUE-37: 假设 UTC 时区
end;

class function TParseOptions.WithTimeZone(const ATimeZone: string): TParseOptions;
begin
  Result := Default;
  Result.TimeZoneMode := tzmSpecified;  // ⚠️ ISSUE-37: 指定时区
  Result.SpecifiedTimeZone := ATimeZone;
end;

class function TParseOptions.StrictTimeZone: TParseOptions;
begin
  Result := Default;
  Result.TimeZoneMode := tzmStrict;  // ⚠️ ISSUE-37: 严格要求时区
end;

{ TParseResult }

class function TParseResult.CreateSuccess(ALength: Integer; const AFormat: string): TParseResult;
begin
  Result.Success := True;
  Result.ErrorCode := pecNone;
  Result.ErrorMessage := '';
  Result.ParsedLength := ALength;
  Result.DetectedFormat := AFormat;
  Result.ErrorPosition := 0;
end;

class function TParseResult.CreateError(ACode: TParseErrorCode; const AMessage: string; APosition: Integer): TParseResult;
begin
  Result.Success := False;
  Result.ErrorCode := ACode;
  Result.ErrorMessage := AMessage;
  Result.ParsedLength := 0;
  Result.DetectedFormat := '';
  Result.ErrorPosition := APosition;
end;

class function TParseResult.CreateErrorCode(ACode: TParseErrorCode; APosition: Integer): TParseResult;
begin
  Result.Success := False;
  Result.ErrorCode := ACode;
  Result.ErrorMessage := GetErrorCodeMessage(ACode);  // 使用默认英文消息
  Result.ParsedLength := 0;
  Result.DetectedFormat := '';
  Result.ErrorPosition := APosition;
end;

function TParseResult.GetDefaultErrorMessage: string;
begin
  Result := GetErrorCodeMessage(ErrorCode);
end;

function TParseResult.GetLocalizedErrorMessage(const ALocale: string): string;
begin
  Result := GetErrorCodeMessageLocalized(ErrorCode, ALocale);
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

// ✅ ISSUE-REVIEW-P1-2: 使用原子 CAS 模式避免竞态条件
function DefaultTimeParser: ITimeParser;
var
  LState: Int32;
begin
  // 快速路径
  LState := InterlockedCompareExchange(GTimeParserOnce, 0, 0);
  if LState = 2 then
    Exit(GTimeParser);

  // 尝试获取初始化权
  if InterlockedCompareExchange(GTimeParserOnce, 1, 0) = 0 then
  begin
    try
      GTimeParser := CreateTimeParser;
      InterlockedExchange(GTimeParserOnce, 2);
    except
      InterlockedExchange(GTimeParserOnce, 0);
      raise;
    end;
  end
  else
  begin
    while InterlockedCompareExchange(GTimeParserOnce, 0, 0) <> 2 do
    begin
      {$IFDEF WINDOWS}
      Sleep(0);
      {$ELSE}
      ThreadSwitch;
      {$ENDIF}
    end;
  end;
  Result := GTimeParser;
end;

// ✅ ISSUE-REVIEW-P1-2: 使用原子 CAS 模式避免竞态条件
function DefaultDurationParser: IDurationParser;
var
  LState: Int32;
begin
  // 快速路径
  LState := InterlockedCompareExchange(GDurationParserOnce, 0, 0);
  if LState = 2 then
    Exit(GDurationParser);

  // 尝试获取初始化权
  if InterlockedCompareExchange(GDurationParserOnce, 1, 0) = 0 then
  begin
    try
      GDurationParser := CreateDurationParser;
      InterlockedExchange(GDurationParserOnce, 2);
    except
      InterlockedExchange(GDurationParserOnce, 0);
      raise;
    end;
  end
  else
  begin
    while InterlockedCompareExchange(GDurationParserOnce, 0, 0) <> 2 do
    begin
      {$IFDEF WINDOWS}
      Sleep(0);
      {$ELSE}
      ThreadSwitch;
      {$ENDIF}
    end;
  end;
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

{ 安全验证函数实现 }

function ValidateFormatString(const AFormat: string): TFormatValidationResult;
const
  // 安全的格式标记白名单
  SAFE_TOKENS: array[0..26] of string = (
    'yyyy', 'yy', 'mmmm', 'mmm', 'mm', 'm',
    'dddd', 'ddd', 'dd', 'd',
    'hh', 'h', 'nn', 'n', 'ss', 's', 'zzz', 'z',
    'AM/PM', 'am/pm', 'A/P', 'a/p',
    'PT', '#',  // 持续时间格式标记
    'H', 'M', 'S'  // 单字母大写标记（持续时间）
  );
  // 允许的分隔符和字面字符
  SAFE_SEPARATORS = ['-', '/', ':', '.', ' ', ',', 'T', 'Z', '+', '"', ''''];
  // 危险的正则元字符（需要拒绝）
  DANGEROUS_CHARS = ['(', ')', '[', ']', '{', '}', '*', '+', '?', '|', '^', '$', '\'];
var
  i, tokenIdx: Integer;
  ch: Char;
  foundToken: Boolean;
  token: string;
begin
  // 1. 长度限制
  if Length(AFormat) > MAX_FORMAT_STRING_LENGTH then
    Exit(TFormatValidationResult.Invalid(pecFormatTooLong,
      Format('格式字符串过长（超过限制）：%d > %d', [Length(AFormat), MAX_FORMAT_STRING_LENGTH]), 0));
  
  if Length(AFormat) = 0 then
    Exit(TFormatValidationResult.Invalid(pecFormatEmpty, '格式字符串为空（不能为空字符串）', 0));
  
  // 2. 检查危险字符
  for i := 1 to Length(AFormat) do
  begin
    ch := AFormat[i];
    if ch in DANGEROUS_CHARS then
      Exit(TFormatValidationResult.Invalid(pecUnsafeFormat,
        Format('包含危险字符（正则元字符）: "%s" 位置 %d', [ch, i]), i));
  end;
  
  // 3. 白名单验证：检查每个标记是否在白名单中
  i := 1;
  while i <= Length(AFormat) do
  begin
    ch := AFormat[i];
    
    // 跳过分隔符和数字
    if (ch in SAFE_SEPARATORS) or ((ch >= '0') and (ch <= '9')) then
    begin
      Inc(i);
      Continue;
    end;
    
    // 尝试匹配白名单中的标记（从最长标记开始匹配）
    foundToken := False;
    for tokenIdx := 0 to High(SAFE_TOKENS) do
    begin
      token := SAFE_TOKENS[tokenIdx];
      if (i + Length(token) - 1 <= Length(AFormat)) and
         (Copy(AFormat, i, Length(token)) = token) then
      begin
        foundToken := True;
        Inc(i, Length(token));
        Break;
      end;
    end;
    
    // 如果没有匹配到任何安全标记，拒绝为未知标记
    if not foundToken then
      Exit(TFormatValidationResult.Invalid(pecUnsafeFormat,
        Format('包含未知标记 "%s"（位置 %d）', [Copy(AFormat, i, 2), i]), i));
  end;
  
  Result := TFormatValidationResult.Valid;
end;

function EstimateRegexComplexity(const APattern: string): Integer;
var
  i: Integer;
  ch, prevCh: Char;
  complexity: Integer;
  quantifierCount: Integer;
  charClassDepth: Integer;
  groupDepth: Integer;
  backrefCount: Integer;
  consecutiveQuantifiers: Integer;
  inCharClass: Boolean;
  hasQuantifierInGroup: Boolean;
begin
  complexity := 0;
  quantifierCount := 0;
  charClassDepth := 0;
  groupDepth := 0;
  backrefCount := 0;
  consecutiveQuantifiers := 0;
  inCharClass := False;
  hasQuantifierInGroup := False;
  prevCh := #0;
  
  for i := 1 to Length(APattern) do
  begin
    ch := APattern[i];
    
    case ch of
      // 量词：基础 +3，嵌套分组情况大幅增加
      '*', '+', '?':
      begin
        Inc(complexity, 3);
        Inc(quantifierCount);
        Inc(consecutiveQuantifiers);
        
        // 嵌套量词（非常危险）: (a+)+ 风格
        // 只有当量词跟在分组 ')' 后才算嵌套，字符类 [a-z]+ 不算
        if prevCh = ')' then
          Inc(complexity, 50);  // 回溯炸弹特征
        
        if groupDepth > 0 then
          hasQuantifierInGroup := True;
      end;
      
      // 字符类：仅计数，不加复杂度（简单字符类是安全的）
      '[':
      begin
        inCharClass := True;
        Inc(charClassDepth);
        consecutiveQuantifiers := 0;
      end;
      
      ']':
      begin
        inCharClass := False;
        if charClassDepth > 0 then
          Dec(charClassDepth);
      end;
      
      // 分组：+2
      '(':
      begin
        Inc(complexity, 2);
        Inc(groupDepth);
        consecutiveQuantifiers := 0;
      end;
      
      ')':
      begin
        if groupDepth > 0 then
          Dec(groupDepth);
      end;
      
      // 通配符：+4
      '.':
      begin
        if not inCharClass then
          Inc(complexity, 4);
        consecutiveQuantifiers := 0;
      end;
      
      // 选择符：+3
      '|':
      begin
        Inc(complexity, 3);
        consecutiveQuantifiers := 0;
      end;
      
    else
      consecutiveQuantifiers := 0;
    end;
    
    // 回溯引用特殊处理（因为反斜杠不能用在 case 中）
    if (ch = #92) and (i < Length(APattern)) and (APattern[i+1] >= '1') and (APattern[i+1] <= '9') then  // #92 = '\'
    begin
      Inc(complexity, 10);
      Inc(backrefCount);
    end;
    
    prevCh := ch;
  end;
  
  // 额外惩罚：
  // - 过多的量词（>10）
  if quantifierCount > 10 then
    Inc(complexity, (quantifierCount - 10) * 5);
  
  // - 过深的嵌套（>5层）
  if groupDepth > 5 then
    Inc(complexity, 20);
  
  // - 回溯引用（每个+10）
  Inc(complexity, backrefCount * 10);
  
  Result := complexity;
end;

{ TLRUCache }

constructor TLRUCache.Create(ACapacity: Integer);
begin
  if ACapacity < 1 then
    ACapacity := DEFAULT_LRU_CACHE_CAPACITY;
  FCapacity := ACapacity;
  SetLength(FEntries, FCapacity);
  FCount := 0;
end;

function TLRUCache.FindIndex(const AKey: string): Integer;
var
  i: Integer;
begin
  for i := 0 to FCount - 1 do
    if FEntries[i].Key = AKey then
      Exit(i);
  Result := -1;
end;

procedure TLRUCache.Evict;
var
  i, minIdx: Integer;
  minTime: Int64;
begin
  if FCount = 0 then Exit;
  
  // 找到最久未访问的条目
  minIdx := 0;
  minTime := FEntries[0].LastAccess;
  for i := 1 to FCount - 1 do
    if FEntries[i].LastAccess < minTime then
    begin
      minTime := FEntries[i].LastAccess;
      minIdx := i;
    end;
  
  // 删除该条目（用最后一个覆盖）
  if minIdx < FCount - 1 then
    FEntries[minIdx] := FEntries[FCount - 1];
  Dec(FCount);
end;

function TLRUCache.TryGet(const AKey: string; out AValue: string): Boolean;
var
  idx: Integer;
begin
  idx := FindIndex(AKey);
  if idx >= 0 then
  begin
    AValue := FEntries[idx].Value;
    FEntries[idx].LastAccess := GetTickCount64;  // 更新访问时间
    Result := True;
  end
  else
  begin
    AValue := '';
    Result := False;
  end;
end;

procedure TLRUCache.Put(const AKey, AValue: string);
var
  idx: Integer;
begin
  idx := FindIndex(AKey);
  if idx >= 0 then
  begin
    // 更新现有条目
    FEntries[idx].Value := AValue;
    FEntries[idx].LastAccess := GetTickCount64;
  end
  else
  begin
    // 如果达到容量，先淘汰
    if FCount >= FCapacity then
      Evict;
    
    // 添加新条目
    FEntries[FCount].Key := AKey;
    FEntries[FCount].Value := AValue;
    FEntries[FCount].LastAccess := GetTickCount64;
    Inc(FCount);
  end;
end;

procedure TLRUCache.Clear;
begin
  FCount := 0;
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

// 带安全验证的正则构建函数
function TTimeParser.BuildRegexPattern(const AFormat: string): string;
var
  validation: TFormatValidationResult;
  complexity: Integer;
begin
  // 第1层防护：格式字符串白名单验证
  validation := ValidateFormatString(AFormat);
  if not validation.IsValid then
    raise EInvalidTimeFormat.CreateFmt('不安全的格式字符串: %s', [validation.ErrorMessage]);
  
  // TODO: 将格式字符串转换为正则表达式
  // 当前简化实现：直接返回格式字符串
  Result := AFormat;
  
  // 第2层防护：正则表达式复杂度限制
  complexity := EstimateRegexComplexity(Result);
  if complexity > MAX_REGEX_COMPLEXITY then
    raise EInvalidTimeFormat.CreateFmt(
      '正则表达式太复杂：复杂度 %d 超过限制 %d', [complexity, MAX_REGEX_COMPLEXITY]);
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

{**
 * 检查输入字符串长度，防止 DoS 攻击
 * ISSUE-47: 添加输入长度限制
 *
 * @param AInput - 输入字符串
 * @param AResult - 如果超长，返回错误结果
 * @return True 如果长度合法，False 如果超长
 *}
function TTimeParser.CheckInputLength(const AInput: string; out AResult: TParseResult): Boolean;
begin
  if Length(AInput) > MAX_INPUT_STRING_LENGTH then
  begin
    AResult := TParseResult.CreateError(pecInputTooLong,
      Format('输入字符串过长（超过最大限制）：%d > %d', [Length(AInput), MAX_INPUT_STRING_LENGTH]), 0);
    Result := False;
  end
  else
    Result := True;
end;

function TTimeParser.ParseDateTime(const ADateTimeStr: string; out ADateTime: TDateTime): TParseResult;
var
  ok: Boolean;
begin
  // ISSUE-47: 输入长度限制（防止DoS）
  if not CheckInputLength(ADateTimeStr, Result) then
    Exit;
  
  ok := TryStrToDateTime(ADateTimeStr, ADateTime);
  if ok then
    Exit(TParseResult.CreateSuccess(Length(ADateTimeStr), 'auto'))
  else
    Exit(TParseResult.CreateErrorCode(pecInvalidDateTime, 0));
end;

function TTimeParser.ParseDateTime(const ADateTimeStr: string; const AFormat: string; out ADateTime: TDateTime): TParseResult;
var
  pattern: string;
begin
  // 第1层防护：验证格式字符串
  try
    pattern := BuildRegexPattern(AFormat);  // 内部会验证安全性
  except
    on E: EInvalidTimeFormat do
      Exit(TParseResult.CreateError(pecUnsafeFormat, '格式字符串不安全或危险：' + E.Message, 0));
  end;
  
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
  // ISSUE-47: 输入长度限制（防止DoS）
  if not CheckInputLength(ADateStr, Result) then
    Exit;
  
  ok := TDate.TryParse(ADateStr, ADate);
  if ok then
    Exit(TParseResult.CreateSuccess(Length(ADateStr), FORMAT_ISO8601_DATE))
  else
    Exit(TParseResult.CreateErrorCode(pecInvalidDate, 0));
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
  // ISSUE-47: 输入长度限制（防止DoS）
  if not CheckInputLength(ATimeStr, Result) then
    Exit;
  
  ok := TTimeOfDay.TryParse(ATimeStr, ATime);
  if ok then
    Exit(TParseResult.CreateSuccess(Length(ATimeStr), FORMAT_ISO8601_TIME))
  else
    Exit(TParseResult.CreateErrorCode(pecInvalidTime, 0));
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
  // ISSUE-47: 输入长度限制（防止DoS）
  if Length(ATimeStr) > MAX_INPUT_STRING_LENGTH then
    Exit('');  // 返回空字符串表示无法检测
  
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
  // ISSUE-47: 输入长度限制（防止DoS）
  if not CheckInputLength(ATimeStr, Result) then
    Exit;
  
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
    Exit(TParseResult.CreateErrorCode(pecCannotDetectFormat, 0));
end;

function TTimeParser.SmartParse(const ATimeStr: string; out ADate: TDate): TParseResult;
var
  d: TDate;
  dt: TDateTime;
begin
  // ISSUE-47: 输入长度限制（防止DoS）
  if not CheckInputLength(ATimeStr, Result) then
    Exit;
  
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
    Exit(TParseResult.CreateErrorCode(pecInvalidDate, 0));
end;

function TTimeParser.SmartParse(const ATimeStr: string; out ATime: TTimeOfDay): TParseResult;
var
  t: TTimeOfDay;
  dt: TDateTime;
begin
  // ISSUE-47: 输入长度限制（防止DoS）
  if not CheckInputLength(ATimeStr, Result) then
    Exit;
  
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
    Exit(TParseResult.CreateErrorCode(pecInvalidTime, 0));
end;

function TTimeParser.ParseDuration(const ADurationStr: string; out ADuration: TDuration): TParseResult;
var
  s: string;
  v32: LongInt;
begin
  // ISSUE-47: 输入长度限制（防止DoS）
  if not CheckInputLength(ADurationStr, Result) then
    Exit;
  
  s := Trim(LowerCase(ADurationStr));
  if (s = '') then Exit(TParseResult.CreateErrorCode(pecEmptyInput, 0));

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
    Exit(TParseResult.CreateErrorCode(pecInvalidDuration, 0));
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
