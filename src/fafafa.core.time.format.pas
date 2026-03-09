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

{$mode objfpc}
{$I fafafa.core.settings.inc}
{$modeswitch advancedrecords}

interface

uses
  SysUtils,
  DateUtils,
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

  /// <summary>
  ///   持续时间格式类型。定义时长的不同输出格式。
  /// </summary>
  /// <remarks>
  ///   <para><b>dfCompact</b>: 紧凑格式，例如 "1h30m45s"</para>
  ///   <para><b>dfVerbose</b>: 详细格式，例如 "1 hour 30 minutes 45 seconds"</para>
  ///   <para><b>dfPrecise</b>: 精确格式，例如 "1:30:45.123"</para>
  ///   <para><b>dfHuman</b>: 人类可读的近似格式，例如 "about 1 hour"</para>
  ///   <para><b>⚠️ dfHuman 重要说明</b>:</para>
  ///   <list type="bullet">
  ///     <item>返回近似值，会丢失精度（例如 "1h 30m 45s" 变成 "about 2 hours"）</item>
  ///     <item>此格式<b>不可逆</b>：无法从 "about 2 hours" 精确还原原始时长</item>
  ///     <item>仅用于显示目的，不适合数据存储或序列化</item>
  ///     <item>适用场景：UI 展示、日志摘要、用户友好输出</item>
  ///   </list>
  ///   <para><b>dfISO8601</b>: ISO 8601 标准格式，例如 "PT1H30M45.123S"</para>
  ///   <para><b>dfCustom</b>: 自定义格式（当前未完全实现）</para>
  /// </remarks>
  /// <example>
  ///   <code>
  ///   var
  ///     d: TDuration;
  ///     s: string;
  ///   begin
  ///     d := TDuration.FromSec(5432);  // 1小时30分32秒
  ///     
  ///     // ✅ 精确格式（可逆）
  ///     s := FormatDuration(d, dfPrecise);  // "1:30:32.000"
  ///     s := FormatDuration(d, dfISO8601);  // "PT1H30M32S"
  ///     
  ///     // ⚠️ 近似格式（不可逆，精度损失）
  ///     s := FormatDuration(d, dfHuman);    // "about 2 hours"
  ///     // 无法从 "about 2 hours" 还原 5432 秒！
  ///     
  ///     // ✅ 推荐：存储使用精确格式
  ///     s := FormatDuration(d, dfISO8601);  // 存储到数据库
  ///     WriteLn(FormatDuration(d, dfHuman));  // 仅用于显示
  ///   end;
  ///   </code>
  /// </example>
  {**
   * TDurationFormat - 持续时间格式化类型
   *
   * ⚠️ **ISSUE-32: dfHuman 格式不可逆性警告**
   *
   * @value dfCompact
   *   紧凑格式：`1h30m45s`
   *   - 可逆：✅ 可以通过 ParseDuration 解析回 TDuration
   *   - 用途：日志、命令行输出、配置文件
   *
   * @value dfVerbose
   *   详细格式：`1 hour 30 minutes 45 seconds`
   *   - 可逆：✅ 可以通过 ParseDuration 解析回 TDuration
   *   - 用途：用户界面、报告生成
   *
   * @value dfPrecise
   *   精确格式：`1:30:45.123`
   *   - 可逆：✅ 可以通过 ParseDuration 解析回 TDuration
   *   - 用途：高精度计时、性能分析
   *
   * @value dfHuman
   *   人性化格式：`about 1 hour`、`约 2 天`
   *   - 可逆：❌ **不可逆！无法准确解析回原始值**
   *   - 近似行为：
   *     - 自动选择最大单位（秒 → 分钟 → 小时 → 天）
   *     - 舍入到整数（90秒 → "about 2 minutes"）
   *     - 忽略小单位（1小时30分 → "about 1 hour"）
   *   - 用途：**仅用于展示**，如社交媒体时间戳、通知消息
   *
   *   **警告：**
   *   - 不要存储 dfHuman 格式的字符串
   *   - 不要尝试解析 dfHuman 格式的字符串
   *   - 往返转换会丢失精度：`TDuration.FromHours(1) -> "about 1 hour" -> ???`
   *
   *   **示例：**
   *   ```pascal
   *   var
   *     d1: TDuration;
   *     s1: string;
   *   begin
   *     d1 := TDuration.FromSec(90);
   *     s1 := FormatDuration(d1, dfHuman); // "about 2 minutes"
   *     // ❌ 错误：无法准确解析回 90 秒
   *     
   *     // ✅ 正确：对于需要往返的场景，使用 dfISO8601 或 dfCompact
   *     s1 := FormatDuration(d1, dfISO8601); // "PT1M30S"
   *     ParseDurationStrict(s1); // 准确恢复为 90 秒
   *   end;
   *   ```
   *
   * @value dfISO8601
   *   ISO 8601 标准格式：`PT1H30M45.123S`
   *   - 可逆：✅ 完全可逆，精确到毫秒
   *   - 用途：API 接口、数据交换、国际标准
   *
   * @value dfCustom
   *   自定义格式：根据 CustomPattern 参数
   *   - 可逆性：取决于自定义模式
   *   - 用途：特殊需求、自定义报表
   *}
  TDurationFormat = (
    dfCompact,            // 1h30m45s
    dfVerbose,            // 1 hour 30 minutes 45 seconds
    dfPrecise,            // 1:30:45.123
    dfHuman,              // about 1 hour (近似，不可逆)
    dfISO8601,            // PT1H30M45.123S
    dfCustom              // 自定义格式
  );

  {**
   * TFormatOptions - 时间格式化选项
   *
   * @field UseUTC
   *   使用 UTC 时间而非本地时间
   *
   * @field ShowMilliseconds
   *   显示毫秒部分
   *
   *   ⚠️ **ISSUE-29: TDateTime 精度限制**
   *   TDateTime 基于 Double 类型，精度约为 **~1 毫秒**。
   *   ShowMilliseconds 选项可能无法显示精确的毫秒值。
   *   
   *   对于高精度时间戳，建议使用：
   *   - TInstant (纳秒精度)
   *   - Unix 时间戳 (NowUnixMs, NowUnixNs)
   *
   * @field Use24Hour
   *   使用 24 小时制，False 时使用 12 小时制并显示 AM/PM
   *
   * @field ShowTimeZone
   *   显示时区信息 (UTC+08:00 或 CST)
   *
   * @field Locale
   *   本地化设置，用于月份名称、星期名称等本地化内容。
   *
   *   ⚠️ **ISSUE-30: Locale 格式标准化**
   *   Locale 字符串应遵循 **BCP 47** 标准：
   *   - 英语（美国）: 'en-US'
   *   - 中文（简体）: 'zh-CN'
   *   - 中文（繁体）: 'zh-TW'
   *   - 日语：'ja-JP'
   *   - 空字符串或 'default' 使用系统默认 locale
   *
   *   不建议使用：'English', 'Chinese', 'cn', 'us' 等不规范格式。
   *
   * @field CustomPattern
   *   自定义格式模式字符串。
   *
   *   ⚠️ **ISSUE-31: CustomPattern 模式说明**
   *   支持的模式标记：
   *   
   *   **日期部分：**
   *   - 'yyyy' : 4 位年份 (2024)
   *   - 'yy'   : 2 位年份 (24)
   *   - 'MM'   : 2 位月份 (01-12)
   *   - 'M'    : 1-2 位月份 (1-12)
   *   - 'dd'   : 2 位日期 (01-31)
   *   - 'd'    : 1-2 位日期 (1-31)
   *   - 'MMM'  : 月份缩写 (Jan, Feb)
   *   - 'MMMM' : 月份全名 (January, February)
   *   
   *   **时间部分：**
   *   - 'HH'   : 24小时 2 位 (00-23)
   *   - 'H'    : 24小时 1-2 位 (0-23)
   *   - 'hh'   : 12小时 2 位 (01-12)
   *   - 'h'    : 12小时 1-2 位 (1-12)
   *   - 'mm'   : 分钟 2 位 (00-59)
   *   - 'm'    : 分钟 1-2 位 (0-59)
   *   - 'ss'   : 秒 2 位 (00-59)
   *   - 's'    : 秒 1-2 位 (0-59)
   *   - 'fff'  : 毫秒 3 位 (000-999)
   *   - 'tt'   : AM/PM 标记
   *   
   *   **示例：**
   *   - 'yyyy-MM-dd HH:mm:ss'     -> '2024-10-04 14:30:45'
   *   - 'dd/MM/yyyy hh:mm:ss tt'  -> '04/10/2024 02:30:45 PM'
   *   - 'MMMM d, yyyy'            -> 'October 4, 2024'
   *   
   *   注意：未匹配的字符直接输出（例如 '-', '/', ':' 等分隔符）。
   *}
  TFormatOptions = record
    UseUTC: Boolean;
    ShowMilliseconds: Boolean;
    Use24Hour: Boolean;
    ShowTimeZone: Boolean;
    Locale: string;
    CustomPattern: string;
    
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

    /// <summary>
    ///   格式化相对时间（基于当前时间）。
    ///   ⚠️ 基准时间：使用 Now 函数获取当前系统时间作为基准。
    /// </summary>
    /// <param name="ADateTime">要格式化的目标时间</param>
    /// <returns>
    ///   人性化的相对时间字符串，例如：
    ///   - "just now" (当前时刻)
    ///   - "30 seconds ago" (过去)
    ///   - "in 5 minutes" (未来)
    ///   - "2 hours ago"
    ///   - "in 3 days"
    /// </returns>
    /// <remarks>
    ///   <para><b>基准时间说明：</b></para>
    ///   <para>此重载方法内部调用 Now 函数获取当前系统时间作为基准时间。</para>
    ///   <para>等价于调用：FormatRelative(ADateTime, Now)</para>
    ///   <para></para>
    ///   <para><b>时间精度：</b></para>
    ///   <para>由于使用 TDateTime 类型，时间差的精度约为 ~1 毫秒。</para>
    ///   <para>对于更精确的时间测量，建议使用 TInstant 和 TDuration。</para>
    ///   <para></para>
    ///   <para><b>使用建议：</b></para>
    ///   <para>✅ 适用于用户界面显示（"2 hours ago"）</para>
    ///   <para>✅ 适用于日志和消息提示</para>
    ///   <para>⚠️ 不适合多次调用且要求一致基准的场景（应使用显式 ABaseTime 参数）</para>
    /// </remarks>
    /// <example>
    ///   <code>
    ///   var
    ///     dt: TDateTime;
    ///     relStr: string;
    ///   begin
    ///     // 使用当前时间作为基准（自动调用 Now）
    ///     dt := Now - 0.5/24;  // 30 分钟前
    ///     relStr := DefaultTimeFormatter.FormatRelative(dt);
    ///     WriteLn(relStr);  // 输出: "30 minutes ago"
    ///
    ///     // 多次调用时基准时间不同（每次都调用 Now）
    ///     Sleep(1000);
    ///     relStr := DefaultTimeFormatter.FormatRelative(dt);
    ///     WriteLn(relStr);  // 输出: "30 minutes ago" (可能略有不同)
    ///
    ///     // 如需一致的基准，使用显式参数版本
    ///     baseTime := Now;
    ///     relStr1 := DefaultTimeFormatter.FormatRelative(dt1, baseTime);
    ///     relStr2 := DefaultTimeFormatter.FormatRelative(dt2, baseTime);
    ///   end;
    ///   </code>
    /// </example>
    function FormatRelative(const ADateTime: TDateTime): string; overload;
    
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

/// <summary>
///   格式化日期时间为字符串。
/// </summary>
/// <param name="ADateTime">要格式化的日期时间</param>
/// <param name="AFormat">格式类型，默认为 dtfISO8601</param>
/// <returns>格式化后的字符串</returns>
/// <remarks>
///   <para><b>默认值说明</b>：此函数默认使用 <c>dtfISO8601</c> 格式，原因如下：</para>
///   <list type="number">
///     <item>ISO 8601 是国际标准，适合数据交换和存储</item>
///     <item>可排序、可解析、无歧义</item>
///     <item>跨平台、跨语言兼容性好</item>
///   </list>
///   <para>⚠️ 注意：<c>FormatDuration</c> 默认使用 <c>dfCompact</c> 而非 ISO 8601。
///   这是有意的设计差异，因为时长的紧凑格式（如 "2h 30m"）更符合日常使用习惯。</para>
/// </remarks>
/// <example>
///   <code>
///   var dt: TDateTime;
///   begin
///     dt := EncodeDateTime(2024, 1, 15, 14, 30, 0, 0);
///     WriteLn(FormatDateTime(dt));           // "2024-01-15T14:30:00"
///     WriteLn(FormatDateTime(dt, dtfShort)); // "1/15/2024 2:30 PM"
///   end;
///   </code>
/// </example>
function FormatDateTime(const ADateTime: TDateTime; AFormat: TDateTimeFormat = dtfISO8601): string; overload;
function FormatDateTime(const ADateTime: TDateTime; const APattern: string): string; overload;

/// <summary>
///   格式化日期为字符串。
/// </summary>
/// <param name="ADate">要格式化的日期</param>
/// <param name="AFormat">格式类型，默认为 dtfISO8601Date</param>
/// <returns>格式化后的日期字符串</returns>
/// <remarks>
///   <para>⚠️ **ISSUE-33: 默认值说明**</para>
///   <para>此函数默认使用 <c>dtfISO8601Date</c>，与 <c>FormatDateTime</c> 保持一致。</para>
///   <para>原因：ISO 8601 日期格式（YYYY-MM-DD）是国际标准，无歧义，适合存储和交换。</para>
/// </remarks>
/// <example>
///   <code>
///   var d: TDate;
///   begin
///     d := TDate.Create(2024, 10, 25);
///     WriteLn(FormatDate(d));           // "2024-10-25"
///     WriteLn(FormatDate(d, dtfShort)); // "10/25/2024" (locale-dependent)
///   end;
///   </code>
/// </example>
function FormatDate(const ADate: TDate; AFormat: TDateTimeFormat = dtfISO8601Date): string; overload;
function FormatDate(const ADate: TDate; const APattern: string): string; overload;

/// <summary>
///   格式化时间为字符串。
/// </summary>
/// <param name="ATime">要格式化的时间</param>
/// <param name="AFormat">格式类型，默认为 dtfISO8601Time</param>
/// <returns>格式化后的时间字符串</returns>
/// <remarks>
///   <para>⚠️ **ISSUE-33: 默认值说明**</para>
///   <para>此函数默认使用 <c>dtfISO8601Time</c>，与 <c>FormatDateTime</c> 保持一致。</para>
///   <para>原因：ISO 8601 时间格式（HH:MM:SS）是国际标准，24小时制，无 AM/PM 歧义。</para>
/// </remarks>
/// <example>
///   <code>
///   var t: TTimeOfDay;
///   begin
///     t := TTimeOfDay.Create(14, 30, 45);
///     WriteLn(FormatTime(t));           // "14:30:45"
///     WriteLn(FormatTime(t, dtfShort)); // "2:30 PM" (12-hour format)
///   end;
///   </code>
/// </example>
function FormatTime(const ATime: TTimeOfDay; AFormat: TDateTimeFormat = dtfISO8601Time): string; overload;
function FormatTime(const ATime: TTimeOfDay; const APattern: string): string; overload;

/// <summary>
///   格式化时长为字符串。
/// </summary>
/// <param name="ADuration">要格式化的时长</param>
/// <param name="AFormat">格式类型，默认为 dfCompact</param>
/// <returns>格式化后的字符串</returns>
/// <remarks>
///   <para><b>默认值说明</b>：此函数默认使用 <c>dfCompact</c> 格式，原因如下：</para>
///   <list type="number">
///     <item>紧凑格式（如 "2h 30m 15s"）更直观、易读</item>
///     <item>符合日常表达时长的习惯</item>
///     <item>节省显示空间，适合 UI 和日志输出</item>
///   </list>
///   <para>⚠️ 注意：<c>FormatDateTime</c> 默认使用 <c>dtfISO8601</c> 而非紧凑格式。
///   这是有意的设计差异，因为日期时间更需要标准化和可交换性。</para>
///   <para>如需用于数据存储或交换，推荐显式使用 <c>dfISO8601</c>：</para>
///   <code>s := FormatDuration(d, dfISO8601);  // "PT2H30M15S"</code>
///   
///   <para>⚠️ **ISSUE-32: dfHuman 格式警告**</para>
///   <para><c>dfHuman</c> 格式（"about 2 hours"）是**近似的、不可逆的**：</para>
///   <list type="bullet">
///     <item>❌ 不可解析：无法用 ParseDuration 还原为精确值</item>
///     <item>❌ 不可存储：存储后丢失精度信息</item>
///     <item>✅ 仅用于显示：适合用户界面、通知消息、社交媒体时间戳</item>
///   </list>
///   <para>详见 <see cref="TDurationFormat">TDurationFormat.dfHuman</see> 文档。</para>
/// </remarks>
/// <example>
///   <code>
///   var d: TDuration;
///   begin
///     d := TDuration.FromSec(9015);  // 2h 30m 15s
///     WriteLn(FormatDuration(d));              // "2h 30m 15s" (默认紧凑)
///     WriteLn(FormatDuration(d, dfISO8601));   // "PT2H30M15S" (推荐存储)
///     WriteLn(FormatDuration(d, dfHuman));     // "about 2 hours" (仅显示)
///   end;
///   </code>
/// </example>
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

uses
  fafafa.core.math;

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

const
  // ✅ ISSUE-35: 本地化资源缓存
  // 月份名称（英文）- 默认缓存
  MONTH_NAMES_EN_FULL: array[1..12] of string = (
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  );
  MONTH_NAMES_EN_ABBR: array[1..12] of string = (
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  );
  
  // 星期名称（英文）- 默认缓存
  WEEKDAY_NAMES_EN_FULL: array[1..7] of string = (
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
  );
  WEEKDAY_NAMES_EN_ABBR: array[1..7] of string = (
    'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
  );
  
  // 中文月份名称
  MONTH_NAMES_ZH_FULL: array[1..12] of string = (
    '一月', '二月', '三月', '四月', '五月', '六月',
    '七月', '八月', '九月', '十月', '十一月', '十二月'
  );
  
  // 中文星期名称
  WEEKDAY_NAMES_ZH_FULL: array[1..7] of string = (
    '星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'
  );
  WEEKDAY_NAMES_ZH_ABBR: array[1..7] of string = (
    '日', '一', '二', '三', '四', '五', '六'
  );
  
  // 日文月份名称
  MONTH_NAMES_JA_FULL: array[1..12] of string = (
    '1月', '2月', '3月', '4月', '5月', '6月',
    '7月', '8月', '9月', '10月', '11月', '12月'
  );
  
  // 日文星期名称
  WEEKDAY_NAMES_JA_FULL: array[1..7] of string = (
    '日曜日', '月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日'
  );
  WEEKDAY_NAMES_JA_ABBR: array[1..7] of string = (
    '日', '月', '火', '水', '木', '金', '土'
  );

{**
 * GetCachedMonthName - 获取缓存的月份名称
 *
 * ✅ ISSUE-35: 本地化查找性能优化
 * 使用预缓存的常量数组代替每次查找系统 locale
 *
 * @param AMonth - 月份 (1-12)
 * @param ALocale - 语言环境 (en, zh, ja)
 * @param AFull - True 返回完整名称，False 返回缩写
 * @return 月份名称
 *}
function GetCachedMonthName(AMonth: Integer; const ALocale: string; AFull: Boolean): string;
var
  locale: string;
begin
  if (AMonth < 1) or (AMonth > 12) then
    Exit('');
    
  locale := LowerCase(Copy(ALocale, 1, 2));
  
  if locale = 'zh' then
    Result := MONTH_NAMES_ZH_FULL[AMonth]
  else if locale = 'ja' then
    Result := MONTH_NAMES_JA_FULL[AMonth]
  else // 默认英文
  begin
    if AFull then
      Result := MONTH_NAMES_EN_FULL[AMonth]
    else
      Result := MONTH_NAMES_EN_ABBR[AMonth];
  end;
end;

{**
 * GetCachedWeekdayName - 获取缓存的星期名称
 *
 * ✅ ISSUE-35: 本地化查找性能优化
 *
 * @param AWeekday - 星期 (1=Sunday, 7=Saturday)
 * @param ALocale - 语言环境 (en, zh, ja)
 * @param AFull - True 返回完整名称，False 返回缩写
 * @return 星期名称
 *}
function GetCachedWeekdayName(AWeekday: Integer; const ALocale: string; AFull: Boolean): string;
var
  locale: string;
begin
  if (AWeekday < 1) or (AWeekday > 7) then
    Exit('');
    
  locale := LowerCase(Copy(ALocale, 1, 2));
  
  if locale = 'zh' then
  begin
    if AFull then
      Result := WEEKDAY_NAMES_ZH_FULL[AWeekday]
    else
      Result := WEEKDAY_NAMES_ZH_ABBR[AWeekday];
  end
  else if locale = 'ja' then
  begin
    if AFull then
      Result := WEEKDAY_NAMES_JA_FULL[AWeekday]
    else
      Result := WEEKDAY_NAMES_JA_ABBR[AWeekday];
  end
  else // 默认英文
  begin
    if AFull then
      Result := WEEKDAY_NAMES_EN_FULL[AWeekday]
    else
      Result := WEEKDAY_NAMES_EN_ABBR[AWeekday];
  end;
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
  ns: Int64;
  us: Int64;
  ms: Int64;
  absNs: Int64;
  absUs: Int64;
  absMs: Int64;
  fmt: string;
begin
  // honor toggles for abbr and sec precision
  ns := ADuration.AsNs;
  absNs := Abs(ns);
  
  // Handle nanoseconds (< 1000ns)
  if absNs < 1000 then
  begin
    if GHumanUseAbbr then
      Result := SysUtils.Format('%dns', [absNs])
    else
      Result := SysUtils.Format('%d nanoseconds', [absNs]);
    Exit;
  end;
  
  // Handle microseconds (< 1000us)
  us := ADuration.AsUs;
  absUs := Abs(us);
  if absUs < 1000 then
  begin
    if GHumanUseAbbr then
      Result := SysUtils.Format('%dus', [absUs])
    else
      Result := SysUtils.Format('%d microseconds', [absUs]);
    Exit;
  end;
  
  // Handle milliseconds (< 1000ms)
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

  // Handle seconds
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

{$PUSH}{$WARN 6018 OFF} // Suppress "Unreachable code" warning - false positive in case-else
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
{$POP}

function TTimeFormatter.ApplyPattern(const ADateTime: TDateTime; const APattern: string; const AOptions: TFormatOptions): string;
var
  dt: TDateTime;
begin
  // TODO: 使用 AOptions 处理时区转换等
  if AOptions.CustomPattern <> '' then; // suppress unused parameter hint
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
  if AOptions.CustomPattern <> '' then
    patt := AOptions.CustomPattern
  else
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
  LPattern: string;
begin
  df := DefaultDurationFormatter;
  LPattern := LowerCase(Trim(APattern));

  if (Pos('precise', LPattern) > 0) or (Pos('time', LPattern) > 0) then
    Result := df.Format(ADuration, dfPrecise)
  else if (Pos('verbose', LPattern) > 0) or (Pos('long', LPattern) > 0) then
    Result := df.Format(ADuration, dfVerbose)
  else if Pos('human', LPattern) > 0 then
    Result := df.Format(ADuration, dfHuman)
  else if (Pos('iso', LPattern) > 0) or (Pos('8601', LPattern) > 0) then
    Result := df.Format(ADuration, dfISO8601)
  else
    Result := df.Format(ADuration, dfCompact);
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

{$PUSH}{$WARN 6018 OFF} // Suppress "Unreachable code" warning - false positive in case-else
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
{$POP}

function TDurationFormatter.Format(const ADuration: TDuration; const AOptions: TDurationFormatOptions): string;
begin
  Result := FormatUnits(ADuration, AOptions);
end;

function TDurationFormatter.Format(const ADuration: TDuration; const APattern: string): string;
var
  LPattern: string;
begin
  LPattern := LowerCase(Trim(APattern));

  if (Pos('precise', LPattern) > 0) or (Pos('time', LPattern) > 0) then
    Result := FormatPrecise(ADuration)
  else if (Pos('verbose', LPattern) > 0) or (Pos('long', LPattern) > 0) then
    Result := FormatVerbose(ADuration)
  else if Pos('human', LPattern) > 0 then
    Result := FormatHuman(ADuration)
  else if (Pos('iso', LPattern) > 0) or (Pos('8601', LPattern) > 0) then
    Result := FormatISO8601(ADuration)
  else
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
