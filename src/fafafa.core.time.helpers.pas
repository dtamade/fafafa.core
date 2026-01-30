unit fafafa.core.time.helpers;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.helpers - 时间类型扩展方法

📖 概述：
  提供 TDate、TTimeOfDay、TNaiveDateTime 的扩展方法，
  解决循环依赖问题，同时保持 API 的流畅性。

🔧 特性：
  • TDate.AndTime/AndHms - 组合日期和时间
  • TTimeOfDay.WithHour/WithMinute/WithSecond/WithMillisecond - 时间修改器
  • TNaiveDateTime.WithYear/WithMonth/WithDay/WithHour/... - 日期时间修改器
  • TNaiveDateTime.AndOffset/AndUtc/AndLocal - 时区转换

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
  fafafa.core.time.offset,
  fafafa.core.time.zoneddatetime;

type
  {**
   * TDateHelper - TDate 的扩展方法
   *
   * @desc
   *   为 TDate 添加 And* 组合方法，用于创建 TNaiveDateTime。
   *}
  TDateHelper = record helper for TDate
    // And* 组合方法
    function AndTime(const ATime: TTimeOfDay): TNaiveDateTime;
    function AndHms(AHour, AMinute, ASecond: Integer): TNaiveDateTime;
    function AndHmsMs(AHour, AMinute, ASecond, AMillisecond: Integer): TNaiveDateTime;
    function TryAndHms(AHour, AMinute, ASecond: Integer; out AResult: TNaiveDateTime): Boolean;
    function TryAndHmsMs(AHour, AMinute, ASecond, AMillisecond: Integer; out AResult: TNaiveDateTime): Boolean;
  end;

  {**
   * TTimeOfDayHelper - TTimeOfDay 的扩展方法
   *
   * @desc
   *   为 TTimeOfDay 添加 With* 修改器方法。
   *}
  TTimeOfDayHelper = record helper for TTimeOfDay
    // On* 组合方法 (v1.2.0)
    function OnDate(const ADate: TDate): TNaiveDateTime;
    
    // With* 修改器方法
    function WithHour(AHour: Integer): TTimeOfDay;
    function WithMinute(AMinute: Integer): TTimeOfDay;
    function WithSecond(ASecond: Integer): TTimeOfDay;
    function WithMillisecond(AMillisecond: Integer): TTimeOfDay;
    
    // TryWith* 安全版本
    function TryWithHour(AHour: Integer; out AResult: TTimeOfDay): Boolean;
    function TryWithMinute(AMinute: Integer; out AResult: TTimeOfDay): Boolean;
    function TryWithSecond(ASecond: Integer; out AResult: TTimeOfDay): Boolean;
    function TryWithMillisecond(AMillisecond: Integer; out AResult: TTimeOfDay): Boolean;
  end;

  {**
   * TNaiveDateTimeHelper - TNaiveDateTime 的扩展方法
   *
   * @desc
   *   为 TNaiveDateTime 添加 With* 修改器方法和 And* 时区转换方法。
   *}
  TNaiveDateTimeHelper = record helper for TNaiveDateTime
    // With* 修改器方法
    function WithYear(AYear: Integer): TNaiveDateTime;
    function WithMonth(AMonth: Integer): TNaiveDateTime;
    function WithDay(ADay: Integer): TNaiveDateTime;
    function WithHour(AHour: Integer): TNaiveDateTime;
    function WithMinute(AMinute: Integer): TNaiveDateTime;
    function WithSecond(ASecond: Integer): TNaiveDateTime;
    function WithMillisecond(AMillisecond: Integer): TNaiveDateTime;
    
    // And* 时区转换方法
    function AndOffset(const AOffset: TUtcOffset): TZonedDateTime;
    function AndUtc: TZonedDateTime;
    function AndLocal: TZonedDateTime;
  end;

implementation

{ TDateHelper }

function TDateHelper.AndTime(const ATime: TTimeOfDay): TNaiveDateTime;
begin
  Result := TNaiveDateTime.FromDateAndTime(Self, ATime);
end;

function TDateHelper.AndHms(AHour, AMinute, ASecond: Integer): TNaiveDateTime;
begin
  Result := TNaiveDateTime.FromDateAndTime(Self, TTimeOfDay.Create(AHour, AMinute, ASecond, 0));
end;

function TDateHelper.AndHmsMs(AHour, AMinute, ASecond, AMillisecond: Integer): TNaiveDateTime;
begin
  Result := TNaiveDateTime.FromDateAndTime(Self, TTimeOfDay.Create(AHour, AMinute, ASecond, AMillisecond));
end;

function TDateHelper.TryAndHms(AHour, AMinute, ASecond: Integer; out AResult: TNaiveDateTime): Boolean;
var
  t: TTimeOfDay;
begin
  Result := TTimeOfDay.TryCreate(AHour, AMinute, ASecond, 0, t);
  if Result then
    AResult := TNaiveDateTime.FromDateAndTime(Self, t);
end;

function TDateHelper.TryAndHmsMs(AHour, AMinute, ASecond, AMillisecond: Integer; out AResult: TNaiveDateTime): Boolean;
var
  t: TTimeOfDay;
begin
  Result := TTimeOfDay.TryCreate(AHour, AMinute, ASecond, AMillisecond, t);
  if Result then
    AResult := TNaiveDateTime.FromDateAndTime(Self, t);
end;

{ TTimeOfDayHelper }

function TTimeOfDayHelper.OnDate(const ADate: TDate): TNaiveDateTime;
begin
  Result := TNaiveDateTime.FromDateAndTime(ADate, Self);
end;

function TTimeOfDayHelper.WithHour(AHour: Integer): TTimeOfDay;
begin
  Result := TTimeOfDay.Create(AHour, Self.GetMinute, Self.GetSecond, Self.GetMillisecond);
end;

function TTimeOfDayHelper.WithMinute(AMinute: Integer): TTimeOfDay;
begin
  Result := TTimeOfDay.Create(Self.GetHour, AMinute, Self.GetSecond, Self.GetMillisecond);
end;

function TTimeOfDayHelper.WithSecond(ASecond: Integer): TTimeOfDay;
begin
  Result := TTimeOfDay.Create(Self.GetHour, Self.GetMinute, ASecond, Self.GetMillisecond);
end;

function TTimeOfDayHelper.WithMillisecond(AMillisecond: Integer): TTimeOfDay;
begin
  Result := TTimeOfDay.Create(Self.GetHour, Self.GetMinute, Self.GetSecond, AMillisecond);
end;

function TTimeOfDayHelper.TryWithHour(AHour: Integer; out AResult: TTimeOfDay): Boolean;
begin
  Result := TTimeOfDay.TryCreate(AHour, Self.GetMinute, Self.GetSecond, Self.GetMillisecond, AResult);
end;

function TTimeOfDayHelper.TryWithMinute(AMinute: Integer; out AResult: TTimeOfDay): Boolean;
begin
  Result := TTimeOfDay.TryCreate(Self.GetHour, AMinute, Self.GetSecond, Self.GetMillisecond, AResult);
end;

function TTimeOfDayHelper.TryWithSecond(ASecond: Integer; out AResult: TTimeOfDay): Boolean;
begin
  Result := TTimeOfDay.TryCreate(Self.GetHour, Self.GetMinute, ASecond, Self.GetMillisecond, AResult);
end;

function TTimeOfDayHelper.TryWithMillisecond(AMillisecond: Integer; out AResult: TTimeOfDay): Boolean;
begin
  Result := TTimeOfDay.TryCreate(Self.GetHour, Self.GetMinute, Self.GetSecond, AMillisecond, AResult);
end;

{ TNaiveDateTimeHelper }

function TNaiveDateTimeHelper.WithYear(AYear: Integer): TNaiveDateTime;
begin
  Result := TNaiveDateTime.FromDateAndTime(Self.Date.WithYear(AYear), Self.Time);
end;

function TNaiveDateTimeHelper.WithMonth(AMonth: Integer): TNaiveDateTime;
begin
  Result := TNaiveDateTime.FromDateAndTime(Self.Date.WithMonth(AMonth), Self.Time);
end;

function TNaiveDateTimeHelper.WithDay(ADay: Integer): TNaiveDateTime;
begin
  Result := TNaiveDateTime.FromDateAndTime(Self.Date.WithDay(ADay), Self.Time);
end;

function TNaiveDateTimeHelper.WithHour(AHour: Integer): TNaiveDateTime;
begin
  Result := TNaiveDateTime.FromDateAndTime(Self.Date, Self.Time.WithHour(AHour));
end;

function TNaiveDateTimeHelper.WithMinute(AMinute: Integer): TNaiveDateTime;
begin
  Result := TNaiveDateTime.FromDateAndTime(Self.Date, Self.Time.WithMinute(AMinute));
end;

function TNaiveDateTimeHelper.WithSecond(ASecond: Integer): TNaiveDateTime;
begin
  Result := TNaiveDateTime.FromDateAndTime(Self.Date, Self.Time.WithSecond(ASecond));
end;

function TNaiveDateTimeHelper.WithMillisecond(AMillisecond: Integer): TNaiveDateTime;
begin
  Result := TNaiveDateTime.FromDateAndTime(Self.Date, Self.Time.WithMillisecond(AMillisecond));
end;

function TNaiveDateTimeHelper.AndOffset(const AOffset: TUtcOffset): TZonedDateTime;
begin
  Result := TZonedDateTime.FromDateAndTime(Self.Date, Self.Time, AOffset);
end;

function TNaiveDateTimeHelper.AndUtc: TZonedDateTime;
begin
  Result := TZonedDateTime.FromDateAndTime(Self.Date, Self.Time, TUtcOffset.UTC);
end;

function TNaiveDateTimeHelper.AndLocal: TZonedDateTime;
begin
  Result := TZonedDateTime.FromDateAndTime(Self.Date, Self.Time, TUtcOffset.Local);
end;

end.
