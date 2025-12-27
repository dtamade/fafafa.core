unit fafafa.core.time.tz;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.tz - 时区类型

📖 概述：
  提供 IANA 时区支持，类似 Rust chrono-tz。
  支持时区 ID（如 "Asia/Shanghai"）和偏移量查询。

🔧 特性：
  • IANA 时区 ID 支持
  • 获取指定时刻的 UTC 偏移
  • 系统时区检测
  • 固定偏移时区支持

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
  Classes,
  DateUtils,
  {$IFDEF UNIX}
  BaseUnix,
  {$ENDIF}
  fafafa.core.time.offset,
  fafafa.core.time.instant;

type
  /// <summary>
  ///   时区类型枚举
  /// </summary>
  TTimeZoneKind = (
    tzkFixed,    // 固定偏移（如 UTC+8）
    tzkIana      // IANA 时区（如 Asia/Shanghai）
  );
  
  /// <summary>
  ///   DST 转换规则类型
  /// </summary>
  TDSTRuleKind = (
    drkNone,     // 无 DST
    drkUSA,      // 美国规则：3月2周日 -> 11月1周日
    drkEU,       // 欧盟规则：3月最后周日 -> 10月最后周日
    drkAustralia,// 澳大利亚规则：10月1周日 -> 4月1周日（南半球）
    drkIran,     // 伊朗规则：约3月21日 -> 9月21日
    drkEgypt     // 埃及规则：4月最后周五 -> 10月最后周四
  );
  
  /// <summary>
  ///   时区 DST 配置
  /// </summary>
  TDSTConfig = record
    RuleKind: TDSTRuleKind;
    StdOffset: Integer;    // 标准时间偏移（秒）
    DSTOffset: Integer;    // 夏令时偏移（秒）
    SouthernHemisphere: Boolean;  // 南半球（DST 反向）
  end;

  /// <summary>
  ///   TTimeZone - 时区类型
  ///   支持 IANA 时区 ID 和固定偏移时区。
  ///   注意：当前版本的 IANA 时区使用固定偏移近似，
  ///   完整的 DST 支持将在后续版本实现。
  /// </summary>
  TTimeZone = record
  private
    FKind: TTimeZoneKind;
    FId: string;           // 时区 ID (如 "UTC", "Asia/Shanghai")
    FFixedOffset: TUtcOffset;  // 固定偏移（用于 tzkFixed）
    FDSTConfig: TDSTConfig;    // DST 配置
    
    class function DetectSystemTimeZoneId: string; static;
    class function GetOffsetForId(const AId: string): TUtcOffset; static;
    class function GetDSTConfigForId(const AId: string): TDSTConfig; static;
    class function IsDSTActiveAt(const AConfig: TDSTConfig; AUnixSec: Int64): Boolean; static;
  public
    // ═══════════════════════════════════════════════════════════════
    // 工厂方法
    // ═══════════════════════════════════════════════════════════════
    
    /// <summary>返回 UTC 时区</summary>
    class function UTC: TTimeZone; static;
    
    /// <summary>返回系统本地时区</summary>
    class function Local: TTimeZone; static;
    
    /// <summary>从固定偏移创建时区</summary>
    class function FromOffset(const AOffset: TUtcOffset): TTimeZone; static;
    
    /// <summary>尝试从 IANA 时区 ID 创建时区</summary>
    /// <param name="AId">时区 ID（如 "UTC", "Asia/Shanghai"）</param>
    /// <param name="ATimeZone">输出时区</param>
    /// <returns>是否成功</returns>
    class function TryFromId(const AId: string; out ATimeZone: TTimeZone): Boolean; static;
    
    // ═══════════════════════════════════════════════════════════════
    // 访问器
    // ═══════════════════════════════════════════════════════════════
    
    /// <summary>返回时区 ID</summary>
    function GetId: string;
    
    /// <summary>返回时区类型</summary>
    function GetKind: TTimeZoneKind;
    
    /// <summary>是否为固定偏移时区</summary>
    function IsFixedOffset: Boolean;
    
    /// <summary>获取指定时刻的 UTC 偏移</summary>
    /// <param name="AInstant">时间点</param>
    /// <returns>该时刻的 UTC 偏移</returns>
    /// <remarks>
    ///   当前版本对 IANA 时区返回固定偏移近似值。
    ///   完整 DST 支持将在后续版本实现。
    /// </remarks>
    function GetOffsetAt(const AInstant: TInstant): TUtcOffset;
    
    // ═══════════════════════════════════════════════════════════════
    // 运算符
    // ═══════════════════════════════════════════════════════════════
    
    class operator =(const A, B: TTimeZone): Boolean;
    class operator <>(const A, B: TTimeZone): Boolean;
    
    // ═══════════════════════════════════════════════════════════════
    // 字符串表示
    // ═══════════════════════════════════════════════════════════════
    
    function ToString: string;
  end;

implementation

uses
  fafafa.core.math;

// ✅ ISSUE-REVIEW-P2-2: 验证时区 ID，防止路径遍历攻击
// 时区 ID 只能包含：字母、数字、下划线、连字符、正斜杠
// 禁止：双点(..)、反斜杠、以斜杠开头、连续斜杠
function IsValidTimeZoneId(const AId: string): Boolean;
var
  i, Len: Integer;
  c: Char;
  LastWasSlash: Boolean;
begin
  Result := False;
  Len := Length(AId);

  // 空字符串无效
  if Len = 0 then Exit;

  // 长度限制（防止 DoS）
  if Len > 64 then Exit;

  // 不能以斜杠开头（相对路径）
  if AId[1] = '/' then Exit;

  // 不能以斜杠结尾
  if AId[Len] = '/' then Exit;

  // 检查 ".." 路径遍历序列
  if Pos('..', AId) > 0 then Exit;

  // 检查每个字符
  LastWasSlash := False;
  for i := 1 to Len do
  begin
    c := AId[i];

    // 检查连续斜杠
    if c = '/' then
    begin
      if LastWasSlash then Exit;
      LastWasSlash := True;
    end
    else
    begin
      LastWasSlash := False;

      // 只允许：A-Z, a-z, 0-9, _, -, +
      if not (c in ['A'..'Z', 'a'..'z', '0'..'9', '_', '-', '+']) then
        Exit;
    end;
  end;

  Result := True;
end;

{ TTimeZone }

class function TTimeZone.DetectSystemTimeZoneId: string;
{$IFDEF UNIX}
var
  Link: string;
  p: SizeInt;
begin
  // Linux: 读取 /etc/localtime 符号链接
  Result := '';
  try
    Link := FpReadLink('/etc/localtime');
    if Link <> '' then
    begin
      // 链接通常指向 /usr/share/zoneinfo/Asia/Shanghai 等
      p := Pos('/zoneinfo/', Link);
      if p > 0 then
      begin
        Result := Copy(Link, p + 10, MaxInt);
        // ✅ ISSUE-REVIEW-P2-2: 验证提取的时区 ID
        if not IsValidTimeZoneId(Result) then
          Result := '';
      end
      else
      begin
        // 可能是相对路径
        p := Pos('zoneinfo/', Link);
        if p > 0 then
        begin
          Result := Copy(Link, p + 9, MaxInt);
          // ✅ ISSUE-REVIEW-P2-2: 验证提取的时区 ID
          if not IsValidTimeZoneId(Result) then
            Result := '';
        end;
      end;
    end;
  except
    // 忽略错误
  end;
  
  // 备选：读取 /etc/timezone
  if Result = '' then
  begin
    try
      if FileExists('/etc/timezone') then
      begin
        with TStringList.Create do
        try
          LoadFromFile('/etc/timezone');
          if Count > 0 then
          begin
            Result := Trim(Strings[0]);
            // ✅ ISSUE-REVIEW-P2-2: 验证从文件读取的时区 ID
            if not IsValidTimeZoneId(Result) then
              Result := '';
          end;
        finally
          Free;
        end;
      end;
    except
      // 忽略错误
    end;
  end;
  
  // 如果仍然失败，返回 Local
  if Result = '' then
    Result := 'Local';
end;
{$ELSE}
begin
  // Windows: 暂时使用 Local
  Result := 'Local';
end;
{$ENDIF}

class function TTimeZone.GetOffsetForId(const AId: string): TUtcOffset;
begin
  // 返回标准时间偏移（非 DST）
  if (AId = 'UTC') or (AId = 'Etc/UTC') or (AId = 'Etc/GMT') then
    Result := TUtcOffset.UTC
  // === 亜洲 ===
  else if (AId = 'Asia/Shanghai') or (AId = 'Asia/Chongqing') or 
          (AId = 'Asia/Hong_Kong') or (AId = 'Asia/Taipei') then
    Result := TUtcOffset.FromHours(8)
  else if AId = 'Asia/Tokyo' then
    Result := TUtcOffset.FromHours(9)
  else if AId = 'Asia/Seoul' then
    Result := TUtcOffset.FromHours(9)
  else if AId = 'Asia/Singapore' then
    Result := TUtcOffset.FromHours(8)
  else if AId = 'Asia/Kolkata' then
    Result := TUtcOffset.FromSeconds(5 * 3600 + 30 * 60)  // UTC+5:30
  else if AId = 'Asia/Kathmandu' then
    Result := TUtcOffset.FromSeconds(5 * 3600 + 45 * 60)  // UTC+5:45
  else if AId = 'Asia/Dubai' then
    Result := TUtcOffset.FromHours(4)
  else if AId = 'Asia/Tehran' then
    Result := TUtcOffset.FromSeconds(3 * 3600 + 30 * 60)  // UTC+3:30
  // === 欧洲 ===
  else if (AId = 'Europe/London') or (AId = 'Etc/GMT') then
    Result := TUtcOffset.UTC
  else if (AId = 'Europe/Paris') or (AId = 'Europe/Rome') or
          (AId = 'Europe/Madrid') then
    Result := TUtcOffset.FromHours(1)
  else if AId = 'Europe/Berlin' then
    Result := TUtcOffset.FromHours(1)
  else if AId = 'Europe/Moscow' then
    Result := TUtcOffset.FromHours(3)
  // === 美洲 ===
  else if (AId = 'America/New_York') or (AId = 'America/Toronto') then
    Result := TUtcOffset.FromHours(-5)
  else if (AId = 'America/Los_Angeles') or (AId = 'America/Vancouver') then
    Result := TUtcOffset.FromHours(-8)
  else if AId = 'America/Chicago' then
    Result := TUtcOffset.FromHours(-6)
  else if AId = 'America/Denver' then
    Result := TUtcOffset.FromHours(-7)
  else if (AId = 'America/Sao_Paulo') or (AId = 'America/Buenos_Aires') then
    Result := TUtcOffset.FromHours(-3)
  // === 澳洲/太平洋 ===
  else if AId = 'Australia/Sydney' then
    Result := TUtcOffset.FromHours(10)
  else if AId = 'Pacific/Auckland' then
    Result := TUtcOffset.FromHours(12)
  // === 非洲 ===
  else if (AId = 'Africa/Cairo') or (AId = 'Africa/Johannesburg') then
    Result := TUtcOffset.FromHours(2)
  else if AId = 'Local' then
    Result := TUtcOffset.Local
  else
    Result := TUtcOffset.Local;
end;

class function TTimeZone.GetDSTConfigForId(const AId: string): TDSTConfig;
begin
  Result.RuleKind := drkNone;
  Result.StdOffset := 0;
  Result.DSTOffset := 0;
  Result.SouthernHemisphere := False;
  
  // 美国时区 (DST: +1 小时)
  if AId = 'America/New_York' then
  begin
    Result.RuleKind := drkUSA;
    Result.StdOffset := -5 * 3600;
    Result.DSTOffset := -4 * 3600;
  end
  else if AId = 'America/Los_Angeles' then
  begin
    Result.RuleKind := drkUSA;
    Result.StdOffset := -8 * 3600;
    Result.DSTOffset := -7 * 3600;
  end
  else if AId = 'America/Chicago' then
  begin
    Result.RuleKind := drkUSA;
    Result.StdOffset := -6 * 3600;
    Result.DSTOffset := -5 * 3600;
  end
  else if AId = 'America/Denver' then
  begin
    Result.RuleKind := drkUSA;
    Result.StdOffset := -7 * 3600;
    Result.DSTOffset := -6 * 3600;
  end
  // 欧洲时区 (DST: +1 小时)
  else if AId = 'Europe/London' then
  begin
    Result.RuleKind := drkEU;
    Result.StdOffset := 0;
    Result.DSTOffset := 1 * 3600;
  end
  else if AId = 'Europe/Paris' then
  begin
    Result.RuleKind := drkEU;
    Result.StdOffset := 1 * 3600;
    Result.DSTOffset := 2 * 3600;
  end
  else if AId = 'Europe/Berlin' then
  begin
    Result.RuleKind := drkEU;
    Result.StdOffset := 1 * 3600;
    Result.DSTOffset := 2 * 3600;
  end
  // 澳大利亚（南半球）
  else if AId = 'Australia/Sydney' then
  begin
    Result.RuleKind := drkAustralia;
    Result.StdOffset := 10 * 3600;
    Result.DSTOffset := 11 * 3600;
    Result.SouthernHemisphere := True;
  end
  // 加拿大时区（美国规则）
  else if AId = 'America/Toronto' then
  begin
    Result.RuleKind := drkUSA;
    Result.StdOffset := -5 * 3600;
    Result.DSTOffset := -4 * 3600;
  end
  else if AId = 'America/Vancouver' then
  begin
    Result.RuleKind := drkUSA;
    Result.StdOffset := -8 * 3600;
    Result.DSTOffset := -7 * 3600;
  end
  // 更多欧洲时区（欧盟规则）
  else if (AId = 'Europe/Rome') or (AId = 'Europe/Madrid') then
  begin
    Result.RuleKind := drkEU;
    Result.StdOffset := 1 * 3600;
    Result.DSTOffset := 2 * 3600;
  end
  // 伊朗（特殊 DST）
  else if AId = 'Asia/Tehran' then
  begin
    Result.RuleKind := drkIran;
    Result.StdOffset := 3 * 3600 + 30 * 60;  // UTC+3:30
    Result.DSTOffset := 4 * 3600 + 30 * 60;  // UTC+4:30
  end
  // 埃及（特殊 DST）
  else if AId = 'Africa/Cairo' then
  begin
    Result.RuleKind := drkEgypt;
    Result.StdOffset := 2 * 3600;  // EET UTC+2
    Result.DSTOffset := 3 * 3600;  // EEST UTC+3
  end
  // 无 DST 时区
  else if (AId = 'Asia/Shanghai') or (AId = 'Asia/Tokyo') or
          (AId = 'Asia/Seoul') or (AId = 'Asia/Singapore') or
          (AId = 'Asia/Kolkata') or (AId = 'Asia/Kathmandu') or
          (AId = 'Asia/Dubai') or
          (AId = 'America/Sao_Paulo') or (AId = 'America/Buenos_Aires') or
          (AId = 'Africa/Johannesburg') or
          (AId = 'Europe/Moscow') then
  begin
    Result.RuleKind := drkNone;
  end;
end;

// 辅助函数：计算指定年月中第 N 个周日的日期（1-based）
function GetNthSundayOfMonth(AYear, AMonth, ANth: Integer): Integer;
var
  FirstDay, FirstSunday, Day: Integer;
begin
  // 计算该月1日是星期几 (0=周日, 1=周一, ...)
  // 使用 Zeller 公式的变体
  FirstDay := DayOfWeek(EncodeDate(AYear, AMonth, 1)) - 1; // 0=周日
  
  // 第一个周日
  if FirstDay = 0 then
    FirstSunday := 1
  else
    FirstSunday := 8 - FirstDay;
  
  // 第 N 个周日
  Day := FirstSunday + (ANth - 1) * 7;
  Result := Day;
end;

// 辅助函数：计算指定年月中最后一个周日的日期
function GetLastSundayOfMonth(AYear, AMonth: Integer): Integer;
var
  LastDay, LastDayOfWeek: Integer;
begin
  // 获取该月最后一天
  if AMonth = 12 then
    LastDay := 31
  else
    LastDay := DayOf(EncodeDate(AYear, AMonth + 1, 1) - 1);
  
  // 该天是星期几
  LastDayOfWeek := DayOfWeek(EncodeDate(AYear, AMonth, LastDay)) - 1; // 0=周日
  
  // 回退到周日
  Result := LastDay - LastDayOfWeek;
end;

// 辅助函数：将日期时间转换为 Unix 秒
function DateTimeToUnixSec(AYear, AMonth, ADay, AHour: Integer): Int64;
var
  D: TDateTime;
begin
  D := EncodeDate(AYear, AMonth, ADay) + EncodeTime(AHour, 0, 0, 0);
  Result := Round((D - 25569.0) * 86400.0);  // 25569 = 1970-01-01 in TDateTime
end;

// 辅助函数：从 Unix 秒获取年份
function UnixSecToYear(AUnixSec: Int64): Integer;
var
  D: TDateTime;
  Y, M, Day: Word;
begin
  D := 25569.0 + AUnixSec / 86400.0;
  DecodeDate(D, Y, M, Day);
  Result := Y;
end;

class function TTimeZone.IsDSTActiveAt(const AConfig: TDSTConfig; AUnixSec: Int64): Boolean;
var
  Year: Integer;
  DSTStart, DSTEnd: Int64;
  Day: Integer;
begin
  Result := False;
  
  if AConfig.RuleKind = drkNone then
    Exit;
  
  Year := UnixSecToYear(AUnixSec);
  
  case AConfig.RuleKind of
    drkNone:
      Result := False;  // 已在上面检查，这里仅为完整性
    drkUSA:
    begin
      // 美国：3月第2周日 02:00 本地 -> 11月第1周日 02:00 本地
      // 转换时使用标准时间偏移计算 UTC 时间点
      Day := GetNthSundayOfMonth(Year, 3, 2);  // 3月第2周日
      DSTStart := DateTimeToUnixSec(Year, 3, Day, 2) - AConfig.StdOffset;
      
      Day := GetNthSundayOfMonth(Year, 11, 1); // 11月第1周日
      DSTEnd := DateTimeToUnixSec(Year, 11, Day, 2) - AConfig.DSTOffset;
      
      Result := (AUnixSec >= DSTStart) and (AUnixSec < DSTEnd);
    end;
    
    drkEU:
    begin
      // 欧盟：3月最后周日 01:00 UTC -> 10月最后周日 01:00 UTC
      Day := GetLastSundayOfMonth(Year, 3);  // 3月最后周日
      DSTStart := DateTimeToUnixSec(Year, 3, Day, 1);  // 已经是 UTC
      
      Day := GetLastSundayOfMonth(Year, 10); // 10月最后周日
      DSTEnd := DateTimeToUnixSec(Year, 10, Day, 1);   // 已经是 UTC
      
      Result := (AUnixSec >= DSTStart) and (AUnixSec < DSTEnd);
    end;
    
    drkAustralia:
    begin
      // 澳大利亚（南半球）：10月第1周日 02:00 本地 -> 4月第1周日 03:00 本地
      // DST 跨年：10月开始，次年4月结束
      Day := GetNthSundayOfMonth(Year, 10, 1);  // 10月第1周日
      DSTStart := DateTimeToUnixSec(Year, 10, Day, 2) - AConfig.StdOffset;
      
      Day := GetNthSundayOfMonth(Year, 4, 1);   // 4月第1周日
      DSTEnd := DateTimeToUnixSec(Year, 4, Day, 3) - AConfig.DSTOffset;
      
    // 南半球 DST 跨年：在 [1月, 4月) 或 [10月, 12月] 期间激活
      if AUnixSec < DSTEnd then
        Result := True  // 年初到 4 月结束前
      else if AUnixSec >= DSTStart then
        Result := True  // 10 月开始后到年末
      else
        Result := False;
    end;
    
    drkIran:
    begin
      // 伊朗：约 3月21日 00:00 本地 -> 9月21日 00:00 本地
      DSTStart := DateTimeToUnixSec(Year, 3, 21, 0) - AConfig.StdOffset;
      DSTEnd := DateTimeToUnixSec(Year, 9, 21, 0) - AConfig.DSTOffset;
      Result := (AUnixSec >= DSTStart) and (AUnixSec < DSTEnd);
    end;
    
    drkEgypt:
    begin
      // 埃及：约 4月最后周五 00:00 本地 -> 10月最后周四 00:00 本地
      // 简化：使用 4月最后周日前一天 和 10月最后周日前三天
      Day := GetLastSundayOfMonth(Year, 4) - 2;  // 约最后周五
      DSTStart := DateTimeToUnixSec(Year, 4, Day, 0) - AConfig.StdOffset;
      Day := GetLastSundayOfMonth(Year, 10) - 3; // 约最后周四
      DSTEnd := DateTimeToUnixSec(Year, 10, Day, 0) - AConfig.DSTOffset;
      Result := (AUnixSec >= DSTStart) and (AUnixSec < DSTEnd);
    end;
  end;
end;

class function TTimeZone.UTC: TTimeZone;
begin
  Result.FKind := tzkFixed;
  Result.FId := 'UTC';
  Result.FFixedOffset := TUtcOffset.UTC;
end;

class function TTimeZone.Local: TTimeZone;
begin
  Result.FId := DetectSystemTimeZoneId;
  if Result.FId = 'Local' then
  begin
    Result.FKind := tzkFixed;
    Result.FFixedOffset := TUtcOffset.Local;
  end
  else
  begin
    Result.FKind := tzkIana;
    Result.FFixedOffset := GetOffsetForId(Result.FId);
  end;
end;

class function TTimeZone.FromOffset(const AOffset: TUtcOffset): TTimeZone;
begin
  Result.FKind := tzkFixed;
  if AOffset.IsUTC then
    Result.FId := 'UTC'
  else
    Result.FId := 'UTC' + AOffset.ToISO8601;
  Result.FFixedOffset := AOffset;
end;

class function TTimeZone.TryFromId(const AId: string; out ATimeZone: TTimeZone): Boolean;
var
  LId: string;
begin
  LId := Trim(AId);
  Result := False;
  
  if LId = '' then
    Exit;
  
  // UTC 变体
  if (LId = 'UTC') or (LId = 'Etc/UTC') or (LId = 'Etc/GMT') or (LId = 'Z') then
  begin
    ATimeZone := UTC;
    Exit(True);
  end;
  
  // 已知的 IANA 时区
  if (Pos('/', LId) > 0) or (LId = 'Local') then
  begin
    // 验证是否为已知时区
    if (LId = 'Asia/Shanghai') or (LId = 'Asia/Tokyo') or 
       (LId = 'Asia/Seoul') or (LId = 'Asia/Singapore') or
       (LId = 'Asia/Hong_Kong') or (LId = 'Asia/Taipei') or
       (LId = 'Asia/Chongqing') or
       (LId = 'Asia/Kolkata') or (LId = 'Asia/Kathmandu') or
       (LId = 'Asia/Dubai') or (LId = 'Asia/Tehran') or
       (LId = 'Europe/London') or (LId = 'Europe/Paris') or
       (LId = 'Europe/Berlin') or (LId = 'Europe/Moscow') or
       (LId = 'Europe/Rome') or (LId = 'Europe/Madrid') or
       (LId = 'America/New_York') or (LId = 'America/Los_Angeles') or
       (LId = 'America/Chicago') or (LId = 'America/Denver') or
       (LId = 'America/Toronto') or (LId = 'America/Vancouver') or
       (LId = 'America/Sao_Paulo') or (LId = 'America/Buenos_Aires') or
       (LId = 'Australia/Sydney') or (LId = 'Pacific/Auckland') or
       (LId = 'Africa/Cairo') or (LId = 'Africa/Johannesburg') or
       (LId = 'Local') then
    begin
      ATimeZone.FKind := tzkIana;
      ATimeZone.FId := LId;
      ATimeZone.FFixedOffset := GetOffsetForId(LId);
      ATimeZone.FDSTConfig := GetDSTConfigForId(LId);
      Exit(True);
    end;
    
    // 未知的 IANA 格式时区
    Exit(False);
  end;
  
  // 不是有效的时区 ID
  Result := False;
end;

function TTimeZone.GetId: string;
begin
  Result := FId;
end;

function TTimeZone.GetKind: TTimeZoneKind;
begin
  Result := FKind;
end;

function TTimeZone.IsFixedOffset: Boolean;
begin
  Result := FKind = tzkFixed;
end;

function TTimeZone.GetOffsetAt(const AInstant: TInstant): TUtcOffset;
var
  UnixSec: Int64;
begin
  // 固定偏移时区直接返回
  if FKind = tzkFixed then
  begin
    Result := FFixedOffset;
    Exit;
  end;
  
  // IANA 时区：检查 DST
  if FDSTConfig.RuleKind = drkNone then
  begin
    Result := FFixedOffset;
    Exit;
  end;
  
  // 计算 DST 是否激活
  UnixSec := AInstant.AsUnixSec;
  if IsDSTActiveAt(FDSTConfig, UnixSec) then
    Result := TUtcOffset.FromSeconds(FDSTConfig.DSTOffset)
  else
    Result := TUtcOffset.FromSeconds(FDSTConfig.StdOffset);
end;

class operator TTimeZone.=(const A, B: TTimeZone): Boolean;
begin
  Result := A.FId = B.FId;
end;

class operator TTimeZone.<>(const A, B: TTimeZone): Boolean;
begin
  Result := A.FId <> B.FId;
end;

function TTimeZone.ToString: string;
begin
  if FKind = tzkFixed then
    Result := Format('TimeZone(%s, %s)', [FId, FFixedOffset.ToISO8601])
  else
    Result := Format('TimeZone(%s)', [FId]);
end;

end.
