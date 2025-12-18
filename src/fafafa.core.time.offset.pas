unit fafafa.core.time.offset;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.offset - UTC 时区偏移类型

📖 概述：
  提供类型安全的时区偏移表示，对齐 Rust chrono::FixedOffset。
  时区偏移以秒为单位存储，支持 UTC-12 到 UTC+14 的完整范围。

🔧 特性：
  • 类型安全的时区偏移表示
  • 支持小时、分钟、秒级别的偏移构造
  • ISO 8601 格式化（"+08:00", "Z"）
  • 解析 ISO 8601 时区字符串
  • 获取系统本地时区

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

interface

uses
  SysUtils;

type
  /// <summary>
  ///   TUtcOffset - UTC 时区偏移类型
  ///   表示相对于 UTC 的时区偏移，以秒为单位存储。
  ///   支持范围：UTC-12:00 (-43200秒) 到 UTC+14:00 (+50400秒)
  /// </summary>
  /// <remarks>
  ///   这是一个值类型（record），天然线程安全。
  ///   对齐 Rust chrono::FixedOffset 的设计。
  /// </remarks>
  TUtcOffset = record
  private
    FSeconds: Int32;  // 相对于 UTC 的秒数偏移
  public
    // ═══════════════════════════════════════════════════════════════
    // 构造函数
    // ═══════════════════════════════════════════════════════════════
    
    /// <summary>
    ///   返回 UTC（零偏移）时区。
    /// </summary>
    class function UTC: TUtcOffset; static; inline;
    
    /// <summary>
    ///   返回系统本地时区偏移。
    /// </summary>
    /// <remarks>
    ///   此函数会查询操作系统获取当前时区设置。
    ///   注意：返回的是当前时刻的时区偏移，在 DST 切换边界可能变化。
    /// </remarks>
    class function Local: TUtcOffset; static;
    
    /// <summary>
    ///   从小时数创建时区偏移。
    /// </summary>
    /// <param name="AHours">小时数，可以是正数（东）或负数（西）</param>
    /// <returns>对应的时区偏移</returns>
    /// <example>
    ///   TUtcOffset.FromHours(8)   // UTC+8 (北京时间)
    ///   TUtcOffset.FromHours(-5)  // UTC-5 (纽约时间)
    /// </example>
    class function FromHours(AHours: Integer): TUtcOffset; static; inline;
    
    /// <summary>
    ///   从小时和分钟创建时区偏移。
    /// </summary>
    /// <param name="AHours">小时数，可以是正数（东）或负数（西）</param>
    /// <param name="AMinutes">分钟数，始终为正数</param>
    /// <returns>对应的时区偏移</returns>
    /// <example>
    ///   TUtcOffset.FromHoursMinutes(5, 30)   // UTC+5:30 (印度时间)
    ///   TUtcOffset.FromHoursMinutes(-3, 30)  // UTC-3:30 (纽芬兰时间)
    /// </example>
    class function FromHoursMinutes(AHours, AMinutes: Integer): TUtcOffset; static;
    
    /// <summary>
    ///   从秒数创建时区偏移。
    /// </summary>
    /// <param name="ASeconds">相对于 UTC 的秒数偏移</param>
    /// <returns>对应的时区偏移</returns>
    class function FromSeconds(ASeconds: Int32): TUtcOffset; static; inline;
    
    // ═══════════════════════════════════════════════════════════════
    // 访问器
    // ═══════════════════════════════════════════════════════════════
    
    /// <summary>
    ///   返回时区偏移的总秒数。
    /// </summary>
    function TotalSeconds: Int32; inline;
    
    /// <summary>
    ///   返回时区偏移的总分钟数。
    /// </summary>
    function TotalMinutes: Int32; inline;
    
    /// <summary>
    ///   返回时区偏移的小时部分（不含分钟）。
    /// </summary>
    function Hours: Integer; inline;
    
    /// <summary>
    ///   返回时区偏移的分钟部分（0-59）。
    /// </summary>
    function Minutes: Integer; inline;
    
    // ═══════════════════════════════════════════════════════════════
    // 格式化与解析
    // ═══════════════════════════════════════════════════════════════
    
    /// <summary>
    ///   返回 ISO 8601 格式的时区字符串。
    /// </summary>
    /// <returns>
    ///   UTC 返回 "Z"，其他返回 "+HH:MM" 或 "-HH:MM" 格式
    /// </returns>
    /// <example>
    ///   TUtcOffset.UTC.ToISO8601           // "Z"
    ///   TUtcOffset.FromHours(8).ToISO8601  // "+08:00"
    ///   TUtcOffset.FromHours(-5).ToISO8601 // "-05:00"
    /// </example>
    function ToISO8601: string;
    
    /// <summary>
    ///   尝试解析 ISO 8601 格式的时区字符串。
    /// </summary>
    /// <param name="AStr">待解析的字符串，支持 "Z"、"+HH:MM"、"-HH:MM" 格式</param>
    /// <param name="AOffset">解析成功时输出的时区偏移</param>
    /// <returns>解析是否成功</returns>
    class function TryParse(const AStr: string; out AOffset: TUtcOffset): Boolean; static;
    
    // ═══════════════════════════════════════════════════════════════
    // 运算符
    // ═══════════════════════════════════════════════════════════════
    
    /// <summary>
    ///   判断两个时区偏移是否相等。
    /// </summary>
    class operator =(const A, B: TUtcOffset): Boolean; inline;
    
    /// <summary>
    ///   判断两个时区偏移是否不相等。
    /// </summary>
    class operator <>(const A, B: TUtcOffset): Boolean; inline;
    
    /// <summary>
    ///   判断时区偏移 A 是否小于 B（更西）。
    /// </summary>
    class operator <(const A, B: TUtcOffset): Boolean; inline;
    
    /// <summary>
    ///   判断时区偏移 A 是否大于 B（更东）。
    /// </summary>
    class operator >(const A, B: TUtcOffset): Boolean; inline;
    
    /// <summary>
    ///   判断时区偏移 A 是否小于等于 B。
    /// </summary>
    class operator <=(const A, B: TUtcOffset): Boolean; inline;
    
    /// <summary>
    ///   判断时区偏移 A 是否大于等于 B。
    /// </summary>
    class operator >=(const A, B: TUtcOffset): Boolean; inline;
    
    // ═══════════════════════════════════════════════════════════════
    // 工具函数
    // ═══════════════════════════════════════════════════════════════
    
    /// <summary>
    ///   返回时区偏移的字符串表示（用于调试）。
    /// </summary>
    function ToString: string;
    
    /// <summary>
    ///   判断是否为 UTC（零偏移）。
    /// </summary>
    function IsUTC: Boolean; inline;
  end;

implementation

uses
  fafafa.core.math;

{ TUtcOffset }

class function TUtcOffset.UTC: TUtcOffset;
begin
  Result.FSeconds := 0;
end;

class function TUtcOffset.Local: TUtcOffset;
var
  LBias: Integer;
begin
  // SysUtils.GetLocalTimeOffset returns minutes west of UTC
  // We need seconds east of UTC
  LBias := GetLocalTimeOffset;
  Result.FSeconds := -LBias * 60;
end;

class function TUtcOffset.FromHours(AHours: Integer): TUtcOffset;
begin
  Result.FSeconds := AHours * 3600;
end;

class function TUtcOffset.FromHoursMinutes(AHours, AMinutes: Integer): TUtcOffset;
begin
  if AHours >= 0 then
    Result.FSeconds := AHours * 3600 + AMinutes * 60
  else
    Result.FSeconds := AHours * 3600 - AMinutes * 60;
end;

class function TUtcOffset.FromSeconds(ASeconds: Int32): TUtcOffset;
begin
  Result.FSeconds := ASeconds;
end;

function TUtcOffset.TotalSeconds: Int32;
begin
  Result := FSeconds;
end;

function TUtcOffset.TotalMinutes: Int32;
begin
  Result := FSeconds div 60;
end;

function TUtcOffset.Hours: Integer;
begin
  Result := FSeconds div 3600;
end;

function TUtcOffset.Minutes: Integer;
begin
  Result := Abs((FSeconds mod 3600) div 60);
end;

function TUtcOffset.ToISO8601: string;
var
  LAbsSeconds: Integer;
  LHours, LMinutes: Integer;
  LSign: Char;
begin
  if FSeconds = 0 then
    Exit('Z');
    
  if FSeconds > 0 then
    LSign := '+'
  else
    LSign := '-';
    
  LAbsSeconds := Abs(FSeconds);
  LHours := LAbsSeconds div 3600;
  LMinutes := (LAbsSeconds mod 3600) div 60;
  
  Result := Format('%s%.2d:%.2d', [LSign, LHours, LMinutes]);
end;

class function TUtcOffset.TryParse(const AStr: string; out AOffset: TUtcOffset): Boolean;
var
  LSign: Integer;
  LHours, LMinutes: Integer;
  LStr: string;
begin
  Result := False;
  AOffset.FSeconds := 0;
  
  // 空字符串默认为 UTC（支持无时区的日期时间格式）
  if AStr = '' then
    Exit(True);
    
  // Handle 'Z' for UTC
  if (AStr = 'Z') or (AStr = 'z') then
  begin
    AOffset.FSeconds := 0;
    Exit(True);
  end;
  
  // Must start with + or -
  if Length(AStr) < 6 then
    Exit;
    
  case AStr[1] of
    '+': LSign := 1;
    '-': LSign := -1;
  else
    Exit;
  end;
  
  // Expected format: +HH:MM or -HH:MM
  LStr := Copy(AStr, 2, Length(AStr) - 1);
  
  // Check for colon separator
  if (Length(LStr) < 5) or (LStr[3] <> ':') then
    Exit;
    
  // Parse hours
  if not TryStrToInt(Copy(LStr, 1, 2), LHours) then
    Exit;
    
  // Parse minutes
  if not TryStrToInt(Copy(LStr, 4, 2), LMinutes) then
    Exit;
    
  // Validate ranges
  if (LHours < 0) or (LHours > 14) then
    Exit;
  if (LMinutes < 0) or (LMinutes > 59) then
    Exit;
    
  AOffset.FSeconds := LSign * (LHours * 3600 + LMinutes * 60);
  Result := True;
end;

class operator TUtcOffset.=(const A, B: TUtcOffset): Boolean;
begin
  Result := A.FSeconds = B.FSeconds;
end;

class operator TUtcOffset.<>(const A, B: TUtcOffset): Boolean;
begin
  Result := A.FSeconds <> B.FSeconds;
end;

class operator TUtcOffset.<(const A, B: TUtcOffset): Boolean;
begin
  Result := A.FSeconds < B.FSeconds;
end;

class operator TUtcOffset.>(const A, B: TUtcOffset): Boolean;
begin
  Result := A.FSeconds > B.FSeconds;
end;

class operator TUtcOffset.<=(const A, B: TUtcOffset): Boolean;
begin
  Result := A.FSeconds <= B.FSeconds;
end;

class operator TUtcOffset.>=(const A, B: TUtcOffset): Boolean;
begin
  Result := A.FSeconds >= B.FSeconds;
end;

function TUtcOffset.ToString: string;
begin
  if FSeconds = 0 then
    Result := 'UTC'
  else
    Result := 'UTC' + ToISO8601;
end;

function TUtcOffset.IsUTC: Boolean;
begin
  Result := FSeconds = 0;
end;

end.
