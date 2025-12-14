unit fafafa.core.time.rfc2822;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.rfc2822 - RFC 2822 日期格式

📖 概述：
  RFC 2822 定义了互联网邮件消息格式中的日期时间格式。
  广泛用于电子邮件和 HTTP 头。

🔧 格式：
  "Tue, 03 Dec 2024 12:30:45 +0800"
  
  组成：
  - 可选的星期缩写和逗号: "Tue, "
  - 日期: "03 Dec 2024"
  - 时间: "12:30:45"
  - 时区: "+0800" 或 "-0500"

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
──────────────────────────────────────────────────────────────
}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.time.zoneddatetime,
  fafafa.core.time.offset,
  fafafa.core.time.date;

/// <summary>格式化为 RFC 2822 格式</summary>
function FormatRFC2822(const ADateTime: TZonedDateTime): string;

/// <summary>解析 RFC 2822 格式字符串</summary>
function TryParseRFC2822(const AInput: string; out ADateTime: TZonedDateTime): Boolean;

implementation

const
  WEEKDAY_ABBRS: array[1..7] of string = (
    'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
  );
  
  MONTH_ABBRS: array[1..12] of string = (
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  );

function FormatRFC2822(const ADateTime: TZonedDateTime): string;
var
  LDow: Integer;
  LOffsetSec, LOffsetHour, LOffsetMin: Integer;
  LSign: Char;
begin
  LDow := ADateTime.Date.GetDayOfWeek;
  
  // 计算时区偏移
  LOffsetSec := ADateTime.Offset.TotalSeconds;
  if LOffsetSec >= 0 then
    LSign := '+'
  else
  begin
    LSign := '-';
    LOffsetSec := -LOffsetSec;
  end;
  LOffsetHour := LOffsetSec div 3600;
  LOffsetMin := (LOffsetSec mod 3600) div 60;
  
  Result := Format('%s, %.2d %s %.4d %.2d:%.2d:%.2d %s%.2d%.2d', [
    WEEKDAY_ABBRS[LDow],
    ADateTime.Day,
    MONTH_ABBRS[ADateTime.Month],
    ADateTime.Year,
    ADateTime.Hour,
    ADateTime.Minute,
    ADateTime.Second,
    LSign,
    LOffsetHour,
    LOffsetMin
  ]);
end;

function ParseMonthAbbr(const AStr: string): Integer;
var
  i: Integer;
  s: string;
begin
  s := Copy(AStr, 1, 3);
  for i := 1 to 12 do
    if SameText(s, MONTH_ABBRS[i]) then
      Exit(i);
  Result := 0;
end;

function TryParseTimezoneName(const AStr: string; out AOffsetSec: Integer): Boolean;
var
  LUpper: string;
begin
  Result := True;
  LUpper := UpperCase(AStr);
  
  // UTC 等价表示
  if (LUpper = 'Z') or (LUpper = 'UT') or (LUpper = 'UTC') or (LUpper = 'GMT') then
    AOffsetSec := 0
  // 美国东部时区
  else if LUpper = 'EST' then
    AOffsetSec := -5 * 3600
  else if LUpper = 'EDT' then
    AOffsetSec := -4 * 3600
  // 美国中部时区
  else if LUpper = 'CST' then
    AOffsetSec := -6 * 3600
  else if LUpper = 'CDT' then
    AOffsetSec := -5 * 3600
  // 美国山地时区
  else if LUpper = 'MST' then
    AOffsetSec := -7 * 3600
  else if LUpper = 'MDT' then
    AOffsetSec := -6 * 3600
  // 美国太平洋时区
  else if LUpper = 'PST' then
    AOffsetSec := -8 * 3600
  else if LUpper = 'PDT' then
    AOffsetSec := -7 * 3600
  else
    Result := False;
end;

function TryParseRFC2822(const AInput: string; out ADateTime: TZonedDateTime): Boolean;
var
  s: string;
  p, LDay, LMonth, LYear, LHour, LMinute, LSecond: Integer;
  LOffsetHour, LOffsetMin, LOffsetSec: Integer;
  LSign: Integer;
  LOffset: TUtcOffset;
  LTzName: string;
  
  function SkipSpaces: Boolean;
  begin
    while (p <= Length(s)) and (s[p] = ' ') do
      Inc(p);
    Result := p <= Length(s);
  end;
  
  function ParseInt(ADigits: Integer; out AValue: Integer): Boolean;
  var
    i: Integer;
    ss: string;
  begin
    Result := False;
    ss := '';
    for i := 1 to ADigits do
    begin
      if (p > Length(s)) or not (s[p] in ['0'..'9']) then
        Exit;
      ss := ss + s[p];
      Inc(p);
    end;
    Result := TryStrToInt(ss, AValue);
  end;
  
  function ParseFlexInt(AMin, AMax: Integer; out AValue: Integer): Boolean;
  var
    i: Integer;
    ss: string;
  begin
    Result := False;
    ss := '';
    for i := 1 to AMax do
    begin
      if (p > Length(s)) or not (s[p] in ['0'..'9']) then
        Break;
      ss := ss + s[p];
      Inc(p);
    end;
    if Length(ss) < AMin then
      Exit;
    Result := TryStrToInt(ss, AValue);
  end;
  
  function MatchChar(c: Char): Boolean;
  begin
    if (p <= Length(s)) and (s[p] = c) then
    begin
      Inc(p);
      Result := True;
    end
    else
      Result := False;
  end;
  
  function ParseMonthName: Boolean;
  var
    ss: string;
  begin
    Result := False;
    if p + 2 > Length(s) then
      Exit;
    ss := Copy(s, p, 3);
    LMonth := ParseMonthAbbr(ss);
    if LMonth = 0 then
      Exit;
    Inc(p, 3);
    Result := True;
  end;
  
begin
  Result := False;
  s := Trim(AInput);
  p := 1;
  
  // 跳过可选的星期缩写 "Tue, "
  if (Length(s) >= 5) and (s[4] = ',') then
  begin
    p := 5;
    SkipSpaces;
  end;
  
  // 解析日期 "03 Dec 2024" 或 "3 Dec 24"
  if not ParseFlexInt(1, 2, LDay) then Exit;
  if not SkipSpaces then Exit;
  if not ParseMonthName then Exit;
  if not SkipSpaces then Exit;
  if not ParseFlexInt(2, 4, LYear) then Exit;
  
  // 处理 2 位年份
  if LYear < 100 then
  begin
    if LYear >= 70 then
      LYear := 1900 + LYear
    else
      LYear := 2000 + LYear;
  end;
  
  // 解析时间 "12:30:45"
  if not SkipSpaces then Exit;
  if not ParseInt(2, LHour) then Exit;
  if not MatchChar(':') then Exit;
  if not ParseInt(2, LMinute) then Exit;
  if not MatchChar(':') then Exit;
  if not ParseInt(2, LSecond) then Exit;
  
  // 解析时区
  if not SkipSpaces then Exit;
  
  // 尝试数字格式 "+0800" 或 "-0500"
  if (s[p] = '+') or (s[p] = '-') then
  begin
    if s[p] = '+' then
      LSign := 1
    else
      LSign := -1;
    Inc(p);
    
    if not ParseInt(2, LOffsetHour) then Exit;
    if not ParseInt(2, LOffsetMin) then Exit;
    
    LOffsetSec := LSign * (LOffsetHour * 3600 + LOffsetMin * 60);
  end
  else
  begin
    // 尝试时区名称 "GMT", "EST", "PST" 等
    LTzName := '';
    while (p <= Length(s)) and (s[p] in ['A'..'Z', 'a'..'z']) do
    begin
      LTzName := LTzName + s[p];
      Inc(p);
    end;
    
    if not TryParseTimezoneName(LTzName, LOffsetSec) then
      Exit;
  end;
  
  // 构建时区偏移
  LOffset := TUtcOffset.FromSeconds(LOffsetSec);
  
  // 创建 TZonedDateTime
  ADateTime := TZonedDateTime.Create(LYear, LMonth, LDay, LHour, LMinute, LSecond, LOffset);
  Result := True;
end;

end.
