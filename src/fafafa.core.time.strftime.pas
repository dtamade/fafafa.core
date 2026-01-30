unit fafafa.core.time.strftime;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.strftime - strftime 风格格式化

📖 概述：
  提供类似 C strftime / Python datetime.strftime 的格式化功能。
  支持常用的日期时间格式说明符。

🔧 支持的说明符：
  日期：
    %Y - 4位年份 (2024)
    %y - 2位年份 (24)
    %m - 月份 (01-12)
    %d - 日期 (01-31)
    %j - 年中第几天 (001-366)
    %A - 星期全名 (Monday)
    %a - 星期缩写 (Mon)
    %B - 月份全名 (January)
    %b - 月份缩写 (Jan)
  时间：
    %H - 24小时制小时 (00-23)
    %I - 12小时制小时 (01-12)
    %M - 分钟 (00-59)
    %S - 秒 (00-59)
    %p - AM/PM
    %f - 毫秒 (000-999，扩展)
  其他：
    %% - 字面 %

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
  fafafa.core.time.date,
  fafafa.core.time.timeofday,
  fafafa.core.time.naivedatetime,
  fafafa.core.time.locale;

/// <summary>使用 strftime 格式化日期</summary>
function StrftimeDate(const ADate: TDate; const AFormat: string): string;

/// <summary>使用 strftime 格式化时间</summary>
function StrftimeTime(const ATime: TTimeOfDay; const AFormat: string): string;

/// <summary>使用 strftime 格式化日期时间</summary>
function StrftimeDateTime(const ADateTime: TNaiveDateTime; const AFormat: string): string;

// ============================================================
// strptime - 解析函数（strftime 的逆操作）
// ============================================================

/// <summary>使用 strptime 解析日期字符串</summary>
function StrptimeDate(const AInput: string; const AFormat: string; out ADate: TDate): Boolean;

/// <summary>使用 strptime 解析时间字符串</summary>
function StrptimeTime(const AInput: string; const AFormat: string; out ATime: TTimeOfDay): Boolean;

/// <summary>使用 strptime 解析日期时间字符串</summary>
function StrptimeDateTime(const AInput: string; const AFormat: string; out ADateTime: TNaiveDateTime): Boolean;

// ============================================================
// 带 locale 的格式化/解析函数
// ============================================================

/// <summary>使用 strftime 格式化日期（带本地化）</summary>
function StrftimeDateLocale(const ADate: TDate; const AFormat: string; const ALocale: TLocale): string;

/// <summary>使用 strftime 格式化时间（带本地化）</summary>
function StrftimeTimeLocale(const ATime: TTimeOfDay; const AFormat: string; const ALocale: TLocale): string;

/// <summary>使用 strftime 格式化日期时间（带本地化）</summary>
function StrftimeDateTimeLocale(const ADateTime: TNaiveDateTime; const AFormat: string; const ALocale: TLocale): string;

/// <summary>使用 strptime 解析日期字符串（带本地化）</summary>
function StrptimeDateLocale(const AInput: string; const AFormat: string; out ADate: TDate; const ALocale: TLocale): Boolean;

/// <summary>使用 strptime 解析时间字符串（带本地化）</summary>
function StrptimeTimeLocale(const AInput: string; const AFormat: string; out ATime: TTimeOfDay; const ALocale: TLocale): Boolean;

/// <summary>使用 strptime 解析日期时间字符串（带本地化）</summary>
function StrptimeDateTimeLocale(const AInput: string; const AFormat: string; out ADateTime: TNaiveDateTime; const ALocale: TLocale): Boolean;

implementation

const
  WEEKDAY_NAMES: array[1..7] of string = (
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 
    'Thursday', 'Friday', 'Saturday'
  );
  
  WEEKDAY_ABBRS: array[1..7] of string = (
    'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
  );
  
  MONTH_NAMES: array[1..12] of string = (
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  );
  
  MONTH_ABBRS: array[1..12] of string = (
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  );

function FormatDateSpecifier(const ADate: TDate; ASpecifier: Char): string;
var
  LYear, LMonth, LDay, LDow, LDoy: Integer;
begin
  LYear := ADate.GetYear;
  LMonth := ADate.GetMonth;
  LDay := ADate.GetDay;
  LDow := ADate.GetDayOfWeek;  // 1=Sunday, 7=Saturday
  LDoy := ADate.GetDayOfYear;
  
  case ASpecifier of
    'Y': Result := Format('%.4d', [LYear]);
    'y': Result := Format('%.2d', [LYear mod 100]);
    'm': Result := Format('%.2d', [LMonth]);
    'd': Result := Format('%.2d', [LDay]);
    'j': Result := Format('%d', [LDoy]);
    'A': Result := WEEKDAY_NAMES[LDow];
    'a': Result := WEEKDAY_ABBRS[LDow];
    'B': Result := MONTH_NAMES[LMonth];
    'b': Result := MONTH_ABBRS[LMonth];
  else
    Result := '%' + ASpecifier;  // 未知说明符保持原样
  end;
end;

function FormatTimeSpecifier(const ATime: TTimeOfDay; ASpecifier: Char): string;
var
  LHour, LMinute, LSecond, LMs: Integer;
  LHour12: Integer;
begin
  LHour := ATime.GetHour;
  LMinute := ATime.GetMinute;
  LSecond := ATime.GetSecond;
  LMs := ATime.GetMillisecond;
  
  // 计算12小时制
  if LHour = 0 then
    LHour12 := 12
  else if LHour > 12 then
    LHour12 := LHour - 12
  else
    LHour12 := LHour;
  
  case ASpecifier of
    'H': Result := Format('%.2d', [LHour]);
    'I': Result := Format('%.2d', [LHour12]);
    'M': Result := Format('%.2d', [LMinute]);
    'S': Result := Format('%.2d', [LSecond]);
    'p': if LHour < 12 then Result := 'AM' else Result := 'PM';
    'f': Result := Format('%.3d', [LMs]);
  else
    Result := '%' + ASpecifier;  // 未知说明符保持原样
  end;
end;

function StrftimeDate(const ADate: TDate; const AFormat: string): string;
var
  i: Integer;
  c: Char;
begin
  Result := '';
  i := 1;
  while i <= Length(AFormat) do
  begin
    c := AFormat[i];
    if c = '%' then
    begin
      Inc(i);
      if i <= Length(AFormat) then
      begin
        c := AFormat[i];
        if c = '%' then
          Result := Result + '%'
        else
          Result := Result + FormatDateSpecifier(ADate, c);
      end;
    end
    else
      Result := Result + c;
    Inc(i);
  end;
end;

function StrftimeTime(const ATime: TTimeOfDay; const AFormat: string): string;
var
  i: Integer;
  c: Char;
begin
  Result := '';
  i := 1;
  while i <= Length(AFormat) do
  begin
    c := AFormat[i];
    if c = '%' then
    begin
      Inc(i);
      if i <= Length(AFormat) then
      begin
        c := AFormat[i];
        if c = '%' then
          Result := Result + '%'
        else
          Result := Result + FormatTimeSpecifier(ATime, c);
      end;
    end
    else
      Result := Result + c;
    Inc(i);
  end;
end;

function StrftimeDateTime(const ADateTime: TNaiveDateTime; const AFormat: string): string;
var
  i: Integer;
  c: Char;
  LDate: TDate;
  LTime: TTimeOfDay;
begin
  LDate := ADateTime.GetDate;
  LTime := ADateTime.GetTime;
  
  Result := '';
  i := 1;
  while i <= Length(AFormat) do
  begin
    c := AFormat[i];
    if c = '%' then
    begin
      Inc(i);
      if i <= Length(AFormat) then
      begin
        c := AFormat[i];
        if c = '%' then
          Result := Result + '%'
        else if c in ['Y', 'y', 'm', 'd', 'j', 'A', 'a', 'B', 'b'] then
          Result := Result + FormatDateSpecifier(LDate, c)
        else if c in ['H', 'I', 'M', 'S', 'p', 'f'] then
          Result := Result + FormatTimeSpecifier(LTime, c)
        else
        Result := Result + '%' + c;  // 未知说明符保持原样
      end;
    end
    else
      Result := Result + c;
    Inc(i);
  end;
end;

// ============================================================
// strptime 实现
// ============================================================

type
  TParseState = record
    Year: Integer;
    Month: Integer;
    Day: Integer;
    Hour: Integer;
    Minute: Integer;
    Second: Integer;
    Millisecond: Integer;
    IsPM: Boolean;
    HasYear, HasMonth, HasDay: Boolean;
    HasHour, HasMinute, HasSecond: Boolean;
    Has12Hour: Boolean;
  end;

function ParseNumber(const AInput: string; var APos: Integer; ADigits: Integer; out AValue: Integer): Boolean;
var
  s: string;
  i: Integer;
begin
  Result := False;
  AValue := 0;
  s := '';
  
  // 跳过前导空格
  while (APos <= Length(AInput)) and (AInput[APos] = ' ') do
    Inc(APos);
  
  // 读取数字
  for i := 1 to ADigits do
  begin
    if (APos > Length(AInput)) or not (AInput[APos] in ['0'..'9']) then
      Exit;
    s := s + AInput[APos];
    Inc(APos);
  end;
  
  Result := TryStrToInt(s, AValue);
end;

function ParseFlexNumber(const AInput: string; var APos: Integer; AMinDigits, AMaxDigits: Integer; out AValue: Integer): Boolean;
var
  s: string;
  i: Integer;
begin
  Result := False;
  AValue := 0;
  s := '';
  
  // 跳过前导空格
  while (APos <= Length(AInput)) and (AInput[APos] = ' ') do
    Inc(APos);
  
  // 读取数字（灵活位数）
  for i := 1 to AMaxDigits do
  begin
    if (APos > Length(AInput)) or not (AInput[APos] in ['0'..'9']) then
      Break;
    s := s + AInput[APos];
    Inc(APos);
  end;
  
  if Length(s) < AMinDigits then
    Exit;
    
  Result := TryStrToInt(s, AValue);
end;

function ParseAmPm(const AInput: string; var APos: Integer; out AIsPM: Boolean): Boolean;
var
  s: string;
begin
  Result := False;
  AIsPM := False;
  
  // 跳过前导空格
  while (APos <= Length(AInput)) and (AInput[APos] = ' ') do
    Inc(APos);
  
  if APos + 1 > Length(AInput) then
    Exit;
    
  s := UpperCase(Copy(AInput, APos, 2));
  if s = 'AM' then
  begin
    AIsPM := False;
    Inc(APos, 2);
    Result := True;
  end
  else if s = 'PM' then
  begin
    AIsPM := True;
    Inc(APos, 2);
    Result := True;
  end;
end;

function MatchLiteral(const AInput: string; var APos: Integer; const ALiteral: Char): Boolean;
begin
  if (APos <= Length(AInput)) and (AInput[APos] = ALiteral) then
  begin
    Inc(APos);
    Result := True;
  end
  else
    Result := False;
end;

function ParseWithFormat(const AInput: string; const AFormat: string; var AState: TParseState): Boolean;
var
  iInput, iFormat: Integer;
  c: Char;
  LValue: Integer;
  LIsPM: Boolean;
begin
  Result := False;
  iInput := 1;
  iFormat := 1;
  
  while iFormat <= Length(AFormat) do
  begin
    c := AFormat[iFormat];
    
    if c = '%' then
    begin
      Inc(iFormat);
      if iFormat > Length(AFormat) then
        Exit;
      c := AFormat[iFormat];
      
      case c of
        '%': // 转义 %
          if not MatchLiteral(AInput, iInput, '%') then Exit;
        'Y': // 4位年份
          begin
            if not ParseNumber(AInput, iInput, 4, LValue) then Exit;
            AState.Year := LValue;
            AState.HasYear := True;
          end;
        'y': // 2位年份
          begin
            if not ParseNumber(AInput, iInput, 2, LValue) then Exit;
            if LValue >= 70 then
              AState.Year := 1900 + LValue
            else
              AState.Year := 2000 + LValue;
            AState.HasYear := True;
          end;
        'm': // 月份
          begin
            if not ParseFlexNumber(AInput, iInput, 1, 2, LValue) then Exit;
            if (LValue < 1) or (LValue > 12) then Exit;
            AState.Month := LValue;
            AState.HasMonth := True;
          end;
        'd': // 日期
          begin
            if not ParseFlexNumber(AInput, iInput, 1, 2, LValue) then Exit;
            if (LValue < 1) or (LValue > 31) then Exit;
            AState.Day := LValue;
            AState.HasDay := True;
          end;
        'H': // 24小时制
          begin
            if not ParseFlexNumber(AInput, iInput, 1, 2, LValue) then Exit;
            if (LValue < 0) or (LValue > 23) then Exit;
            AState.Hour := LValue;
            AState.HasHour := True;
          end;
        'I': // 12小时制
          begin
            if not ParseFlexNumber(AInput, iInput, 1, 2, LValue) then Exit;
            if (LValue < 1) or (LValue > 12) then Exit;
            AState.Hour := LValue;
            AState.HasHour := True;
            AState.Has12Hour := True;
          end;
        'M': // 分钟
          begin
            if not ParseFlexNumber(AInput, iInput, 1, 2, LValue) then Exit;
            if (LValue < 0) or (LValue > 59) then Exit;
            AState.Minute := LValue;
            AState.HasMinute := True;
          end;
        'S': // 秒
          begin
            if not ParseFlexNumber(AInput, iInput, 1, 2, LValue) then Exit;
            if (LValue < 0) or (LValue > 59) then Exit;
            AState.Second := LValue;
            AState.HasSecond := True;
          end;
        'p': // AM/PM
          begin
            if not ParseAmPm(AInput, iInput, LIsPM) then Exit;
            AState.IsPM := LIsPM;
          end;
        'f': // 毫秒
          begin
            if not ParseFlexNumber(AInput, iInput, 1, 3, LValue) then Exit;
            AState.Millisecond := LValue;
          end;
      else
        // 未知说明符，尝试匹配字面量
        if not MatchLiteral(AInput, iInput, c) then Exit;
      end;
    end
    else
    begin
      // 匹配字面字符
      if c = ' ' then
      begin
        // 跳过空格（容许多个空格匹配一个）
        while (iInput <= Length(AInput)) and (AInput[iInput] = ' ') do
          Inc(iInput);
      end
      else if not MatchLiteral(AInput, iInput, c) then
        Exit;
    end;
    
    Inc(iFormat);
  end;
  
  // 确保输入已完全消费
  Result := (iInput > Length(AInput));
end;

function StrptimeDate(const AInput: string; const AFormat: string; out ADate: TDate): Boolean;
var
  LState: TParseState;
begin
  Result := False;
  FillChar(LState, SizeOf(LState), 0);
  LState.Day := 1;  // 默认第1天
  
  if not ParseWithFormat(AInput, AFormat, LState) then
    Exit;
  
  // 验证必须有年月
  if not LState.HasYear or not LState.HasMonth then
    Exit;
  
  // 创建日期
  if not TDate.TryCreate(LState.Year, LState.Month, LState.Day, ADate) then
    Exit;
    
  Result := True;
end;

function StrptimeTime(const AInput: string; const AFormat: string; out ATime: TTimeOfDay): Boolean;
var
  LState: TParseState;
  LHour: Integer;
begin
  Result := False;
  FillChar(LState, SizeOf(LState), 0);
  
  if not ParseWithFormat(AInput, AFormat, LState) then
    Exit;
  
  // 验证必须有小时和分钟
  if not LState.HasHour or not LState.HasMinute then
    Exit;
  
  // 处理 12 小时制
  LHour := LState.Hour;
  if LState.Has12Hour then
  begin
    if LState.IsPM then
    begin
      if LHour < 12 then
        LHour := LHour + 12;
    end
    else
    begin
      if LHour = 12 then
        LHour := 0;
    end;
  end;
  
  ATime := TTimeOfDay.Create(LHour, LState.Minute, LState.Second, LState.Millisecond);
  Result := True;
end;

function StrptimeDateTime(const AInput: string; const AFormat: string; out ADateTime: TNaiveDateTime): Boolean;
var
  LState: TParseState;
  LHour: Integer;
begin
  Result := False;
  FillChar(LState, SizeOf(LState), 0);
  LState.Day := 1;  // 默认
  
  if not ParseWithFormat(AInput, AFormat, LState) then
    Exit;
  
  // 验证必须有年月日时分
  if not LState.HasYear or not LState.HasMonth or not LState.HasDay then
    Exit;
  if not LState.HasHour or not LState.HasMinute then
    Exit;
  
  // 处理 12 小时制
  LHour := LState.Hour;
  if LState.Has12Hour then
  begin
    if LState.IsPM then
    begin
      if LHour < 12 then
        LHour := LHour + 12;
    end
    else
    begin
      if LHour = 12 then
        LHour := 0;
    end;
  end;
  
  ADateTime := TNaiveDateTime.Create(LState.Year, LState.Month, LState.Day,
    LHour, LState.Minute, LState.Second, LState.Millisecond);
  Result := True;
end;

// ============================================================
// 带 locale 的实现
// ============================================================

function FormatDateSpecifierLocale(const ADate: TDate; ASpecifier: Char; const ALocale: TLocale): string;
var
  LYear, LMonth, LDay, LDow, LDoy: Integer;
begin
  LYear := ADate.GetYear;
  LMonth := ADate.GetMonth;
  LDay := ADate.GetDay;
  LDow := ADate.GetDayOfWeek;  // 1=Sunday, 7=Saturday
  LDoy := ADate.GetDayOfYear;
  
  case ASpecifier of
    'Y': Result := Format('%.4d', [LYear]);
    'y': Result := Format('%.2d', [LYear mod 100]);
    'm': Result := Format('%.2d', [LMonth]);
    'd': Result := Format('%.2d', [LDay]);
    'j': Result := Format('%d', [LDoy]);
    'A': Result := ALocale.WeekdayNames[LDow];
    'a': Result := ALocale.WeekdayAbbrs[LDow];
    'B': Result := ALocale.MonthNames[LMonth];
    'b': Result := ALocale.MonthAbbrs[LMonth];
  else
    Result := '%' + ASpecifier;
  end;
end;

function FormatTimeSpecifierLocale(const ATime: TTimeOfDay; ASpecifier: Char; const ALocale: TLocale): string;
var
  LHour, LMinute, LSecond, LMs: Integer;
  LHour12: Integer;
begin
  LHour := ATime.GetHour;
  LMinute := ATime.GetMinute;
  LSecond := ATime.GetSecond;
  LMs := ATime.GetMillisecond;
  
  // 计算12小时制
  if LHour = 0 then
    LHour12 := 12
  else if LHour > 12 then
    LHour12 := LHour - 12
  else
    LHour12 := LHour;
  
  case ASpecifier of
    'H': Result := Format('%.2d', [LHour]);
    'I': Result := Format('%.2d', [LHour12]);
    'M': Result := Format('%.2d', [LMinute]);
    'S': Result := Format('%.2d', [LSecond]);
    'p': if LHour < 12 then Result := ALocale.AM else Result := ALocale.PM;
    'f': Result := Format('%.3d', [LMs]);
  else
    Result := '%' + ASpecifier;
  end;
end;

function StrftimeDateLocale(const ADate: TDate; const AFormat: string; const ALocale: TLocale): string;
var
  i: Integer;
  c: Char;
begin
  Result := '';
  i := 1;
  while i <= Length(AFormat) do
  begin
    c := AFormat[i];
    if c = '%' then
    begin
      Inc(i);
      if i <= Length(AFormat) then
      begin
        c := AFormat[i];
        if c = '%' then
          Result := Result + '%'
        else
          Result := Result + FormatDateSpecifierLocale(ADate, c, ALocale);
      end;
    end
    else
      Result := Result + c;
    Inc(i);
  end;
end;

function StrftimeTimeLocale(const ATime: TTimeOfDay; const AFormat: string; const ALocale: TLocale): string;
var
  i: Integer;
  c: Char;
begin
  Result := '';
  i := 1;
  while i <= Length(AFormat) do
  begin
    c := AFormat[i];
    if c = '%' then
    begin
      Inc(i);
      if i <= Length(AFormat) then
      begin
        c := AFormat[i];
        if c = '%' then
          Result := Result + '%'
        else
          Result := Result + FormatTimeSpecifierLocale(ATime, c, ALocale);
      end;
    end
    else
      Result := Result + c;
    Inc(i);
  end;
end;

function StrftimeDateTimeLocale(const ADateTime: TNaiveDateTime; const AFormat: string; const ALocale: TLocale): string;
var
  i: Integer;
  c: Char;
  LDate: TDate;
  LTime: TTimeOfDay;
begin
  LDate := ADateTime.GetDate;
  LTime := ADateTime.GetTime;
  
  Result := '';
  i := 1;
  while i <= Length(AFormat) do
  begin
    c := AFormat[i];
    if c = '%' then
    begin
      Inc(i);
      if i <= Length(AFormat) then
      begin
        c := AFormat[i];
        if c = '%' then
          Result := Result + '%'
        else if c in ['Y', 'y', 'm', 'd', 'j', 'A', 'a', 'B', 'b'] then
          Result := Result + FormatDateSpecifierLocale(LDate, c, ALocale)
        else if c in ['H', 'I', 'M', 'S', 'p', 'f'] then
          Result := Result + FormatTimeSpecifierLocale(LTime, c, ALocale)
        else
          Result := Result + '%' + c;
      end;
    end
    else
      Result := Result + c;
    Inc(i);
  end;
end;

// strptime with locale

function TryMatchString(const AInput: string; var APos: Integer; const AValues: array of string; out AIndex: Integer): Boolean;
var
  i: Integer;
  s: string;
begin
  Result := False;
  AIndex := 0;
  
  // 跳过前导空格
  while (APos <= Length(AInput)) and (AInput[APos] = ' ') do
    Inc(APos);
    
  for i := Low(AValues) to High(AValues) do
  begin
    s := AValues[i];
    if (APos + Length(s) - 1 <= Length(AInput)) and 
       (Copy(AInput, APos, Length(s)) = s) then
    begin
      AIndex := i - Low(AValues) + 1;  // 1-based
      Inc(APos, Length(s));
      Result := True;
      Exit;
    end;
  end;
end;

function ParseWithFormatLocale(const AInput: string; const AFormat: string; var AState: TParseState; const ALocale: TLocale): Boolean;
var
  iInput, iFormat: Integer;
  c: Char;
  LValue: Integer;
  LIsPM: Boolean;
begin
  Result := False;
  iInput := 1;
  iFormat := 1;
  
  while iFormat <= Length(AFormat) do
  begin
    c := AFormat[iFormat];
    
    if c = '%' then
    begin
      Inc(iFormat);
      if iFormat > Length(AFormat) then
        Exit;
      c := AFormat[iFormat];
      
      case c of
        '%': // 转义 %
          if not MatchLiteral(AInput, iInput, '%') then Exit;
        'Y': // 4位年份
          begin
            if not ParseNumber(AInput, iInput, 4, LValue) then Exit;
            AState.Year := LValue;
            AState.HasYear := True;
          end;
        'y': // 2位年份
          begin
            if not ParseNumber(AInput, iInput, 2, LValue) then Exit;
            if LValue >= 70 then
              AState.Year := 1900 + LValue
            else
              AState.Year := 2000 + LValue;
            AState.HasYear := True;
          end;
        'm': // 月份
          begin
            if not ParseFlexNumber(AInput, iInput, 1, 2, LValue) then Exit;
            if (LValue < 1) or (LValue > 12) then Exit;
            AState.Month := LValue;
            AState.HasMonth := True;
          end;
        'd': // 日期
          begin
            if not ParseFlexNumber(AInput, iInput, 1, 2, LValue) then Exit;
            if (LValue < 1) or (LValue > 31) then Exit;
            AState.Day := LValue;
            AState.HasDay := True;
          end;
        'H': // 24小时制
          begin
            if not ParseFlexNumber(AInput, iInput, 1, 2, LValue) then Exit;
            if (LValue < 0) or (LValue > 23) then Exit;
            AState.Hour := LValue;
            AState.HasHour := True;
          end;
        'I': // 12小时制
          begin
            if not ParseFlexNumber(AInput, iInput, 1, 2, LValue) then Exit;
            if (LValue < 1) or (LValue > 12) then Exit;
            AState.Hour := LValue;
            AState.HasHour := True;
            AState.Has12Hour := True;
          end;
        'M': // 分钟
          begin
            if not ParseFlexNumber(AInput, iInput, 1, 2, LValue) then Exit;
            if (LValue < 0) or (LValue > 59) then Exit;
            AState.Minute := LValue;
            AState.HasMinute := True;
          end;
        'S': // 秒
          begin
            if not ParseFlexNumber(AInput, iInput, 1, 2, LValue) then Exit;
            if (LValue < 0) or (LValue > 59) then Exit;
            AState.Second := LValue;
            AState.HasSecond := True;
          end;
        'p': // AM/PM - 使用 locale
          begin
            // 跳过空格
            while (iInput <= Length(AInput)) and (AInput[iInput] = ' ') do
              Inc(iInput);
            // 尝试匹配 locale 的 AM/PM
            if (iInput + Length(ALocale.AM) - 1 <= Length(AInput)) and
               (Copy(AInput, iInput, Length(ALocale.AM)) = ALocale.AM) then
            begin
              LIsPM := False;
              Inc(iInput, Length(ALocale.AM));
            end
            else if (iInput + Length(ALocale.PM) - 1 <= Length(AInput)) and
                    (Copy(AInput, iInput, Length(ALocale.PM)) = ALocale.PM) then
            begin
              LIsPM := True;
              Inc(iInput, Length(ALocale.PM));
            end
            else
              Exit;
            AState.IsPM := LIsPM;
          end;
        'f': // 毫秒
          begin
            if not ParseFlexNumber(AInput, iInput, 1, 3, LValue) then Exit;
            AState.Millisecond := LValue;
          end;
        'A': // 星期全名 - 使用 locale
          begin
            if not TryMatchString(AInput, iInput, ALocale.WeekdayNames, LValue) then Exit;
            // 不设置任何状态，星期名只用于验证
          end;
        'a': // 星期缩写 - 使用 locale
          begin
            if not TryMatchString(AInput, iInput, ALocale.WeekdayAbbrs, LValue) then Exit;
          end;
        'B': // 月份全名 - 使用 locale
          begin
            if not TryMatchString(AInput, iInput, ALocale.MonthNames, LValue) then Exit;
            AState.Month := LValue;
            AState.HasMonth := True;
          end;
        'b': // 月份缩写 - 使用 locale
          begin
            if not TryMatchString(AInput, iInput, ALocale.MonthAbbrs, LValue) then Exit;
            AState.Month := LValue;
            AState.HasMonth := True;
          end;
      else
        // 未知说明符，尝试匹配字面量
        if not MatchLiteral(AInput, iInput, c) then Exit;
      end;
    end
    else
    begin
      // 匹配字面字符
      if c = ' ' then
      begin
        // 跳过空格
        while (iInput <= Length(AInput)) and (AInput[iInput] = ' ') do
          Inc(iInput);
      end
      else if not MatchLiteral(AInput, iInput, c) then
        Exit;
    end;
    
    Inc(iFormat);
  end;
  
  // 确保输入已完全消费
  Result := (iInput > Length(AInput));
end;

function StrptimeDateLocale(const AInput: string; const AFormat: string; out ADate: TDate; const ALocale: TLocale): Boolean;
var
  LState: TParseState;
begin
  Result := False;
  FillChar(LState, SizeOf(LState), 0);
  LState.Day := 1;
  
  if not ParseWithFormatLocale(AInput, AFormat, LState, ALocale) then
    Exit;
  
  if not LState.HasYear or not LState.HasMonth then
    Exit;
  
  if not TDate.TryCreate(LState.Year, LState.Month, LState.Day, ADate) then
    Exit;
    
  Result := True;
end;

function StrptimeTimeLocale(const AInput: string; const AFormat: string; out ATime: TTimeOfDay; const ALocale: TLocale): Boolean;
var
  LState: TParseState;
  LHour: Integer;
begin
  Result := False;
  FillChar(LState, SizeOf(LState), 0);
  
  if not ParseWithFormatLocale(AInput, AFormat, LState, ALocale) then
    Exit;
  
  if not LState.HasHour or not LState.HasMinute then
    Exit;
  
  LHour := LState.Hour;
  if LState.Has12Hour then
  begin
    if LState.IsPM then
    begin
      if LHour < 12 then
        LHour := LHour + 12;
    end
    else
    begin
      if LHour = 12 then
        LHour := 0;
    end;
  end;
  
  ATime := TTimeOfDay.Create(LHour, LState.Minute, LState.Second, LState.Millisecond);
  Result := True;
end;

function StrptimeDateTimeLocale(const AInput: string; const AFormat: string; out ADateTime: TNaiveDateTime; const ALocale: TLocale): Boolean;
var
  LState: TParseState;
  LHour: Integer;
begin
  Result := False;
  FillChar(LState, SizeOf(LState), 0);
  LState.Day := 1;
  
  if not ParseWithFormatLocale(AInput, AFormat, LState, ALocale) then
    Exit;
  
  if not LState.HasYear or not LState.HasMonth or not LState.HasDay then
    Exit;
  if not LState.HasHour or not LState.HasMinute then
    Exit;
  
  LHour := LState.Hour;
  if LState.Has12Hour then
  begin
    if LState.IsPM then
    begin
      if LHour < 12 then
        LHour := LHour + 12;
    end
    else
    begin
      if LHour = 12 then
        LHour := 0;
    end;
  end;
  
  ADateTime := TNaiveDateTime.Create(LState.Year, LState.Month, LState.Day,
    LHour, LState.Minute, LState.Second, LState.Millisecond);
  Result := True;
end;

end.
