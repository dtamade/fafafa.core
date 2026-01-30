unit fafafa.core.time.builders;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.builders - 日期时间构建器 (v1.2.0)

📖 概述：
  提供流畅的链式构建器 API 用于创建日期、时间和日期时间对象。
  对齐 Rust chrono 的 builder 模式设计。

🔧 特性：
  • TDateBuilder: 链式构建 TDate
  • TTimeBuilder: 链式构建 TTimeOfDay
  • TDateTimeBuilder: 链式构建 TNaiveDateTime 或 TZonedDateTime
  • 支持任意顺序的链式调用
  • 合理的默认值

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
  fafafa.core.time.base,
  fafafa.core.time.date,
  fafafa.core.time.timeofday,
  fafafa.core.time.naivedatetime,
  fafafa.core.time.zoneddatetime,
  fafafa.core.time.offset;

type
  {**
   * TDateBuilder - 日期构建器
   *
   * @desc
   *   提供链式 API 构建 TDate 对象。
   *   支持任意顺序设置年、月、日。
   *
   * @example
   *   D := DateBuilder.Year(2024).Month(1).Day(15).Build;
   *   D := DateBuilder.Month(12).Day(25).Year(2024).Build;
   *}
  TDateBuilder = record
  private
    FYear: Integer;
    FMonth: Integer;
    FDay: Integer;
  public
    /// <summary>设置年份</summary>
    function Year(AYear: Integer): TDateBuilder;
    /// <summary>设置月份 (1-12)</summary>
    function Month(AMonth: Integer): TDateBuilder;
    /// <summary>设置日期 (1-31)</summary>
    function Day(ADay: Integer): TDateBuilder;
    
    /// <summary>构建 TDate 对象</summary>
    /// <exception cref="ETimeError">日期无效时抛出</exception>
    function Build: TDate;
    
    /// <summary>尝试构建 TDate 对象</summary>
    /// <returns>构建是否成功</returns>
    function TryBuild(out ADate: TDate): Boolean;
  end;

  {**
   * TTimeBuilder - 时间构建器
   *
   * @desc
   *   提供链式 API 构建 TTimeOfDay 对象。
   *   支持纳秒精度。
   *
   * @example
   *   T := TimeBuilder.Hour(14).Minute(30).Second(45).Build;
   *   T := TimeBuilder.Hour(9).Minute(26).Second(53).Nanosecond(589793238).Build;
   *}
  TTimeBuilder = record
  private
    FHour: Integer;
    FMinute: Integer;
    FSecond: Integer;
    FNanosecond: Integer;
  public
    /// <summary>设置小时 (0-23)</summary>
    function Hour(AHour: Integer): TTimeBuilder;
    /// <summary>设置分钟 (0-59)</summary>
    function Minute(AMinute: Integer): TTimeBuilder;
    /// <summary>设置秒 (0-59)</summary>
    function Second(ASecond: Integer): TTimeBuilder;
    /// <summary>设置毫秒 (0-999)</summary>
    function Millisecond(AMillisecond: Integer): TTimeBuilder;
    /// <summary>设置纳秒 (0-999999999)</summary>
    function Nanosecond(ANanosecond: Integer): TTimeBuilder;
    
    /// <summary>构建 TTimeOfDay 对象</summary>
    /// <exception cref="ETimeError">时间无效时抛出</exception>
    function Build: TTimeOfDay;
    
    /// <summary>尝试构建 TTimeOfDay 对象</summary>
    /// <returns>构建是否成功</returns>
    function TryBuild(out ATime: TTimeOfDay): Boolean;
  end;

  {**
   * TDateTimeBuilder - 日期时间构建器
   *
   * @desc
   *   提供链式 API 构建 TNaiveDateTime 或 TZonedDateTime 对象。
   *   支持从组件或从 TDate/TTimeOfDay 对象构建。
   *
   * @example
   *   // 从组件构建
   *   DT := DateTimeBuilder.Year(2024).Month(1).Day(15)
   *           .Hour(14).Minute(30).Second(0).BuildNaive;
   *
   *   // 从对象构建
   *   DT := DateTimeBuilder.Date(D).Time(T).BuildNaive;
   *
   *   // 带时区构建
   *   ZDT := DateTimeBuilder.Year(2024).Month(1).Day(15)
   *            .Hour(14).Minute(30).Second(0)
   *            .AtOffset(TUtcOffset.FromHours(8)).BuildZoned;
   *}
  TDateTimeBuilder = record
  private
    FYear: Integer;
    FMonth: Integer;
    FDay: Integer;
    FHour: Integer;
    FMinute: Integer;
    FSecond: Integer;
    FNanosecond: Integer;
    FOffset: TUtcOffset;
    FHasOffset: Boolean;
    FHasDate: Boolean;
    FHasTime: Boolean;
    FDate: TDate;
    FTime: TTimeOfDay;
  public
    // 日期组件
    /// <summary>设置年份</summary>
    function Year(AYear: Integer): TDateTimeBuilder;
    /// <summary>设置月份 (1-12)</summary>
    function Month(AMonth: Integer): TDateTimeBuilder;
    /// <summary>设置日期 (1-31)</summary>
    function Day(ADay: Integer): TDateTimeBuilder;
    
    // 时间组件
    /// <summary>设置小时 (0-23)</summary>
    function Hour(AHour: Integer): TDateTimeBuilder;
    /// <summary>设置分钟 (0-59)</summary>
    function Minute(AMinute: Integer): TDateTimeBuilder;
    /// <summary>设置秒 (0-59)</summary>
    function Second(ASecond: Integer): TDateTimeBuilder;
    /// <summary>设置毫秒 (0-999)</summary>
    function Millisecond(AMillisecond: Integer): TDateTimeBuilder;
    /// <summary>设置纳秒 (0-999999999)</summary>
    function Nanosecond(ANanosecond: Integer): TDateTimeBuilder;
    
    // 从对象设置
    /// <summary>设置日期部分</summary>
    function Date(const ADate: TDate): TDateTimeBuilder;
    /// <summary>设置时间部分</summary>
    function Time(const ATime: TTimeOfDay): TDateTimeBuilder;
    
    // 时区设置
    /// <summary>设置 UTC 偏移</summary>
    function AtOffset(const AOffset: TUtcOffset): TDateTimeBuilder;
    /// <summary>设置为 UTC</summary>
    function AtUTC: TDateTimeBuilder;
    /// <summary>设置为本地时区</summary>
    function AtLocal: TDateTimeBuilder;
    
    // 构建方法
    /// <summary>构建 TNaiveDateTime (无时区)</summary>
    function BuildNaive: TNaiveDateTime;
    /// <summary>构建 TZonedDateTime (带时区)</summary>
    function BuildZoned: TZonedDateTime;
    
    /// <summary>尝试构建 TNaiveDateTime</summary>
    function TryBuildNaive(out ADateTime: TNaiveDateTime): Boolean;
    /// <summary>尝试构建 TZonedDateTime</summary>
    function TryBuildZoned(out ADateTime: TZonedDateTime): Boolean;
  end;

/// <summary>创建一个新的日期构建器</summary>
/// <returns>初始化的 TDateBuilder，默认值为 1/1/1</returns>
function DateBuilder: TDateBuilder;

/// <summary>创建一个新的时间构建器</summary>
/// <returns>初始化的 TTimeBuilder，默认值为 00:00:00</returns>
function TimeBuilder: TTimeBuilder;

/// <summary>创建一个新的日期时间构建器</summary>
/// <returns>初始化的 TDateTimeBuilder，默认值为 1/1/1 00:00:00</returns>
function DateTimeBuilder: TDateTimeBuilder;

implementation

const
  NS_PER_MS = 1000000;  // 1 毫秒 = 10^6 纳秒

{ 工厂函数 }

function DateBuilder: TDateBuilder;
begin
  Result.FYear := 1;
  Result.FMonth := 1;
  Result.FDay := 1;
end;

function TimeBuilder: TTimeBuilder;
begin
  Result.FHour := 0;
  Result.FMinute := 0;
  Result.FSecond := 0;
  Result.FNanosecond := 0;
end;

function DateTimeBuilder: TDateTimeBuilder;
begin
  Result.FYear := 1;
  Result.FMonth := 1;
  Result.FDay := 1;
  Result.FHour := 0;
  Result.FMinute := 0;
  Result.FSecond := 0;
  Result.FNanosecond := 0;
  Result.FOffset := TUtcOffset.UTC;
  Result.FHasOffset := False;
  Result.FHasDate := False;
  Result.FHasTime := False;
end;

{ TDateBuilder }

function TDateBuilder.Year(AYear: Integer): TDateBuilder;
begin
  Result := Self;
  Result.FYear := AYear;
end;

function TDateBuilder.Month(AMonth: Integer): TDateBuilder;
begin
  Result := Self;
  Result.FMonth := AMonth;
end;

function TDateBuilder.Day(ADay: Integer): TDateBuilder;
begin
  Result := Self;
  Result.FDay := ADay;
end;

function TDateBuilder.Build: TDate;
begin
  if not TDate.TryCreate(FYear, FMonth, FDay, Result) then
    raise ETimeError.CreateFmt('Invalid date: %d-%d-%d', [FYear, FMonth, FDay]);
end;

function TDateBuilder.TryBuild(out ADate: TDate): Boolean;
begin
  Result := TDate.TryCreate(FYear, FMonth, FDay, ADate);
end;

{ TTimeBuilder }

function TTimeBuilder.Hour(AHour: Integer): TTimeBuilder;
begin
  Result := Self;
  Result.FHour := AHour;
end;

function TTimeBuilder.Minute(AMinute: Integer): TTimeBuilder;
begin
  Result := Self;
  Result.FMinute := AMinute;
end;

function TTimeBuilder.Second(ASecond: Integer): TTimeBuilder;
begin
  Result := Self;
  Result.FSecond := ASecond;
end;

function TTimeBuilder.Millisecond(AMillisecond: Integer): TTimeBuilder;
begin
  Result := Self;
  Result.FNanosecond := AMillisecond * NS_PER_MS;
end;

function TTimeBuilder.Nanosecond(ANanosecond: Integer): TTimeBuilder;
begin
  Result := Self;
  Result.FNanosecond := ANanosecond;
end;

function TTimeBuilder.Build: TTimeOfDay;
begin
  // 验证时间有效性
  if (FHour < 0) or (FHour > 23) or
     (FMinute < 0) or (FMinute > 59) or
     (FSecond < 0) or (FSecond > 59) or
     (FNanosecond < 0) or (FNanosecond > 999999999) then
    raise ETimeError.CreateFmt('Invalid time: %d:%d:%d.%d', 
      [FHour, FMinute, FSecond, FNanosecond]);
  
  Result := TTimeOfDay.CreateNs(FHour, FMinute, FSecond, FNanosecond);
end;

function TTimeBuilder.TryBuild(out ATime: TTimeOfDay): Boolean;
begin
  if (FHour < 0) or (FHour > 23) or
     (FMinute < 0) or (FMinute > 59) or
     (FSecond < 0) or (FSecond > 59) or
     (FNanosecond < 0) or (FNanosecond > 999999999) then
  begin
    Result := False;
    Exit;
  end;
  
  ATime := TTimeOfDay.CreateNs(FHour, FMinute, FSecond, FNanosecond);
  Result := True;
end;

{ TDateTimeBuilder }

function TDateTimeBuilder.Year(AYear: Integer): TDateTimeBuilder;
begin
  Result := Self;
  Result.FYear := AYear;
end;

function TDateTimeBuilder.Month(AMonth: Integer): TDateTimeBuilder;
begin
  Result := Self;
  Result.FMonth := AMonth;
end;

function TDateTimeBuilder.Day(ADay: Integer): TDateTimeBuilder;
begin
  Result := Self;
  Result.FDay := ADay;
end;

function TDateTimeBuilder.Hour(AHour: Integer): TDateTimeBuilder;
begin
  Result := Self;
  Result.FHour := AHour;
end;

function TDateTimeBuilder.Minute(AMinute: Integer): TDateTimeBuilder;
begin
  Result := Self;
  Result.FMinute := AMinute;
end;

function TDateTimeBuilder.Second(ASecond: Integer): TDateTimeBuilder;
begin
  Result := Self;
  Result.FSecond := ASecond;
end;

function TDateTimeBuilder.Millisecond(AMillisecond: Integer): TDateTimeBuilder;
begin
  Result := Self;
  Result.FNanosecond := AMillisecond * NS_PER_MS;
end;

function TDateTimeBuilder.Nanosecond(ANanosecond: Integer): TDateTimeBuilder;
begin
  Result := Self;
  Result.FNanosecond := ANanosecond;
end;

function TDateTimeBuilder.Date(const ADate: TDate): TDateTimeBuilder;
begin
  Result := Self;
  Result.FDate := ADate;
  Result.FHasDate := True;
end;

function TDateTimeBuilder.Time(const ATime: TTimeOfDay): TDateTimeBuilder;
begin
  Result := Self;
  Result.FTime := ATime;
  Result.FHasTime := True;
end;

function TDateTimeBuilder.AtOffset(const AOffset: TUtcOffset): TDateTimeBuilder;
begin
  Result := Self;
  Result.FOffset := AOffset;
  Result.FHasOffset := True;
end;

function TDateTimeBuilder.AtUTC: TDateTimeBuilder;
begin
  Result := Self;
  Result.FOffset := TUtcOffset.UTC;
  Result.FHasOffset := True;
end;

function TDateTimeBuilder.AtLocal: TDateTimeBuilder;
begin
  Result := Self;
  Result.FOffset := TUtcOffset.Local;
  Result.FHasOffset := True;
end;

function TDateTimeBuilder.BuildNaive: TNaiveDateTime;
var
  LDate: TDate;
  LTime: TTimeOfDay;
begin
  // 获取日期部分
  if FHasDate then
    LDate := FDate
  else
  begin
    if not TDate.TryCreate(FYear, FMonth, FDay, LDate) then
      raise ETimeError.CreateFmt('Invalid date: %d-%d-%d', [FYear, FMonth, FDay]);
  end;
  
  // 获取时间部分
  if FHasTime then
    LTime := FTime
  else
  begin
    if (FHour < 0) or (FHour > 23) or
       (FMinute < 0) or (FMinute > 59) or
       (FSecond < 0) or (FSecond > 59) or
       (FNanosecond < 0) or (FNanosecond > 999999999) then
      raise ETimeError.CreateFmt('Invalid time: %d:%d:%d.%d',
        [FHour, FMinute, FSecond, FNanosecond]);
    LTime := TTimeOfDay.CreateNs(FHour, FMinute, FSecond, FNanosecond);
  end;
  
  // 使用纳秒精度构建
  Result := TNaiveDateTime.CreateNs(
    LDate.GetYear, LDate.GetMonth, LDate.GetDay,
    LTime.GetHour, LTime.GetMinute, LTime.GetSecond, 
    LTime.GetSubsecondNanos
  );
end;

function TDateTimeBuilder.BuildZoned: TZonedDateTime;
var
  LNaive: TNaiveDateTime;
  LOffset: TUtcOffset;
begin
  LNaive := BuildNaive;
  
  if FHasOffset then
    LOffset := FOffset
  else
    LOffset := TUtcOffset.UTC;  // 默认 UTC
  
  Result := TZonedDateTime.FromDateAndTime(LNaive.Date, LNaive.Time, LOffset);
end;

function TDateTimeBuilder.TryBuildNaive(out ADateTime: TNaiveDateTime): Boolean;
var
  LDate: TDate;
  LTime: TTimeOfDay;
begin
  Result := False;
  
  // 获取日期部分
  if FHasDate then
    LDate := FDate
  else
  begin
    if not TDate.TryCreate(FYear, FMonth, FDay, LDate) then
      Exit;
  end;
  
  // 获取时间部分
  if FHasTime then
    LTime := FTime
  else
  begin
    if (FHour < 0) or (FHour > 23) or
       (FMinute < 0) or (FMinute > 59) or
       (FSecond < 0) or (FSecond > 59) or
       (FNanosecond < 0) or (FNanosecond > 999999999) then
      Exit;
    LTime := TTimeOfDay.CreateNs(FHour, FMinute, FSecond, FNanosecond);
  end;
  
  ADateTime := TNaiveDateTime.CreateNs(
    LDate.GetYear, LDate.GetMonth, LDate.GetDay,
    LTime.GetHour, LTime.GetMinute, LTime.GetSecond,
    LTime.GetSubsecondNanos
  );
  Result := True;
end;

function TDateTimeBuilder.TryBuildZoned(out ADateTime: TZonedDateTime): Boolean;
var
  LNaive: TNaiveDateTime;
  LOffset: TUtcOffset;
begin
  Result := TryBuildNaive(LNaive);
  if not Result then
    Exit;
  
  if FHasOffset then
    LOffset := FOffset
  else
    LOffset := TUtcOffset.UTC;
  
  ADateTime := TZonedDateTime.FromDateAndTime(LNaive.Date, LNaive.Time, LOffset);
end;

end.
