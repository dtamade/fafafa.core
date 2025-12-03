unit fafafa.core.time.json;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.json - 时间类型 JSON 序列化

📖 概述：
  提供时间类型的 JSON 序列化和反序列化功能。
  支持 TDate, TTimeOfDay, TZonedDateTime 等类型。

🔧 特性：
  • ISO 8601 格式的 JSON 字符串表示
  • 往返一致性保证
  • 类型安全的序列化/反序列化

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
  SysUtils,
  fafafa.core.time.date,
  fafafa.core.time.timeofday,
  fafafa.core.time.zoneddatetime,
  fafafa.core.time.offset;

// ═══════════════════════════════════════════════════════════════
// TDate JSON 序列化
// ═══════════════════════════════════════════════════════════════

/// <summary>将 TDate 转换为 JSON 字符串</summary>
/// <param name="ADate">日期</param>
/// <returns>JSON 格式字符串，如 "2024-06-15"</returns>
function DateToJSON(const ADate: TDate): string;

/// <summary>从 JSON 字符串解析 TDate</summary>
/// <param name="AJson">JSON 格式字符串</param>
/// <param name="ADate">输出日期</param>
/// <returns>解析是否成功</returns>
function JSONToDate(const AJson: string; out ADate: TDate): Boolean;

// ═══════════════════════════════════════════════════════════════
// TTimeOfDay JSON 序列化
// ═══════════════════════════════════════════════════════════════

/// <summary>将 TTimeOfDay 转换为 JSON 字符串</summary>
/// <param name="ATime">时间</param>
/// <returns>JSON 格式字符串，如 "12:30:45"</returns>
function TimeOfDayToJSON(const ATime: TTimeOfDay): string;

/// <summary>从 JSON 字符串解析 TTimeOfDay</summary>
/// <param name="AJson">JSON 格式字符串</param>
/// <param name="ATime">输出时间</param>
/// <returns>解析是否成功</returns>
function JSONToTimeOfDay(const AJson: string; out ATime: TTimeOfDay): Boolean;

// ═══════════════════════════════════════════════════════════════
// TZonedDateTime JSON 序列化
// ═══════════════════════════════════════════════════════════════

/// <summary>将 TZonedDateTime 转换为 JSON 字符串</summary>
/// <param name="ADateTime">带时区的日期时间</param>
/// <returns>JSON 格式字符串，如 "2024-06-15T12:30:45Z"</returns>
function ZonedDateTimeToJSON(const ADateTime: TZonedDateTime): string;

/// <summary>从 JSON 字符串解析 TZonedDateTime</summary>
/// <param name="AJson">JSON 格式字符串</param>
/// <param name="ADateTime">输出日期时间</param>
/// <returns>解析是否成功</returns>
function JSONToZonedDateTime(const AJson: string; out ADateTime: TZonedDateTime): Boolean;

implementation

// ═══════════════════════════════════════════════════════════════
// 辅助函数
// ═══════════════════════════════════════════════════════════════

function StripQuotes(const S: string): string;
begin
  if (Length(S) >= 2) and (S[1] = '"') and (S[Length(S)] = '"') then
    Result := Copy(S, 2, Length(S) - 2)
  else
    Result := S;
end;

// ═══════════════════════════════════════════════════════════════
// TDate JSON 实现
// ═══════════════════════════════════════════════════════════════

function DateToJSON(const ADate: TDate): string;
begin
  // ISO 8601 日期格式
  Result := '"' + ADate.ToISO8601 + '"';
end;

function JSONToDate(const AJson: string; out ADate: TDate): Boolean;
var
  S: string;
begin
  S := StripQuotes(Trim(AJson));
  Result := TDate.TryParseISO(S, ADate);
end;

// ═══════════════════════════════════════════════════════════════
// TTimeOfDay JSON 实现
// ═══════════════════════════════════════════════════════════════

function TimeOfDayToJSON(const ATime: TTimeOfDay): string;
begin
  // ISO 8601 时间格式
  Result := '"' + ATime.ToISO8601 + '"';
end;

function JSONToTimeOfDay(const AJson: string; out ATime: TTimeOfDay): Boolean;
var
  S: string;
begin
  S := StripQuotes(Trim(AJson));
  Result := TTimeOfDay.TryParse(S, ATime);
end;

// ═══════════════════════════════════════════════════════════════
// TZonedDateTime JSON 实现
// ═══════════════════════════════════════════════════════════════

function ZonedDateTimeToJSON(const ADateTime: TZonedDateTime): string;
begin
  // ISO 8601 日期时间格式
  Result := '"' + ADateTime.ToISO8601 + '"';
end;

function JSONToZonedDateTime(const AJson: string; out ADateTime: TZonedDateTime): Boolean;
var
  S: string;
begin
  S := StripQuotes(Trim(AJson));
  Result := TZonedDateTime.TryParse(S, ADateTime);
end;

end.
