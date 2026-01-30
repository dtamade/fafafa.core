{
  fafafa.core.time.workday - 工作日计算
  
  提供工作日判断、计算等功能。
  支持标准五天工作制，可扩展支持节假日。
}
unit fafafa.core.time.workday;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, fafafa.core.time.date;

{ 判断指定日期是否为工作日（默认周一到周五） }
function IsWorkday(const ADate: TDate): Boolean;

{ 判断指定日期是否为周末（周六或周日） }
function IsWeekend(const ADate: TDate): Boolean;

{ 获取下一个工作日（不含当天） }
function GetNextWorkday(const ADate: TDate): TDate;

{ 获取上一个工作日（不含当天） }
function GetPreviousWorkday(const ADate: TDate): TDate;

{ 计算两个日期之间的工作日数量（包含起止日期） }
function GetWorkdaysBetween(const AStartDate, AEndDate: TDate): Integer;

{ 添加指定数量的工作日 }
function AddWorkdays(const ADate: TDate; AWorkdays: Integer): TDate;

implementation

function IsWeekend(const ADate: TDate): Boolean;
var
  DayOfWeek: Integer;
begin
  // TDate.GetDayOfWeek: 1=Sunday, 7=Saturday
  DayOfWeek := ADate.GetDayOfWeek;
  Result := (DayOfWeek = 1) or (DayOfWeek = 7); // Sunday or Saturday
end;

function IsWorkday(const ADate: TDate): Boolean;
begin
  // 工作日 = 非周末
  Result := not IsWeekend(ADate);
end;

function GetNextWorkday(const ADate: TDate): TDate;
begin
  Result := ADate.AddDays(1);
  while IsWeekend(Result) do
    Result := Result.AddDays(1);
end;

function GetPreviousWorkday(const ADate: TDate): TDate;
begin
  Result := ADate.AddDays(-1);
  while IsWeekend(Result) do
    Result := Result.AddDays(-1);
end;

function GetWorkdaysBetween(const AStartDate, AEndDate: TDate): Integer;
var
  Current: TDate;
begin
  Result := 0;
  
  if AStartDate > AEndDate then
    Exit;
  
  Current := AStartDate;
  while Current <= AEndDate do
  begin
    if IsWorkday(Current) then
      Inc(Result);
    Current := Current.AddDays(1);
  end;
end;

function AddWorkdays(const ADate: TDate; AWorkdays: Integer): TDate;
var
  DaysToAdd: Integer;
begin
  Result := ADate;
  
  if AWorkdays = 0 then
    Exit;
  
  if AWorkdays > 0 then
  begin
    DaysToAdd := AWorkdays;
    while DaysToAdd > 0 do
    begin
      Result := Result.AddDays(1);
      if IsWorkday(Result) then
        Dec(DaysToAdd);
    end;
  end
  else
  begin
    DaysToAdd := -AWorkdays;
    while DaysToAdd > 0 do
    begin
      Result := Result.AddDays(-1);
      if IsWorkday(Result) then
        Dec(DaysToAdd);
    end;
  end;
end;

end.
