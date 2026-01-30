unit fafafa.core.time.calendar;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.calendar - 日历功能

📖 概述：
  提供日历相关功能，包括日期计算、节假日判断、工作日计算等。
  支持多种日历系统和本地化设置。

🔧 特性：
  • 日期算术运算
  • 工作日/节假日计算
  • 多日历系统支持
  • 本地化日期格式
  • 时区感知的日期处理

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
  DateUtils,
  fafafa.core.time.base,
  fafafa.core.time.date;

type
  // 星期枚举
  TDayOfWeek = (
    dowSunday = 0,
    dowMonday = 1,
    dowTuesday = 2,
    dowWednesday = 3,
    dowThursday = 4,
    dowFriday = 5,
    dowSaturday = 6
  );

  // 月份枚举
  TMonth = (
    moJanuary = 1,
    moFebruary = 2,
    moMarch = 3,
    moApril = 4,
    moMay = 5,
    moJune = 6,
    moJuly = 7,
    moAugust = 8,
    moSeptember = 9,
    moOctober = 10,
    moNovember = 11,
    moDecember = 12
  );

  // 季度枚举
  TQuarter = (
    qFirst = 1,
    qSecond = 2,
    qThird = 3,
    qFourth = 4
  );

  // 日历类型
  TCalendarType = (
    ctGregorian,    // 公历
    ctJulian,       // 儒略历
    ctChinese,      // 农历
    ctIslamic,      // 伊斯兰历
    ctHebrew        // 希伯来历
  );

  // 节假日类型
  THolidayType = (
    htNational,     // 国家法定节假日
    htReligious,    // 宗教节日
    htCultural,     // 文化节日
    htCommercial,   // 商业节日
    htPersonal      // 个人节日
  );

  // 工作日模式
  TWorkdayMode = (
    wmStandard,     // 标准工作日（周一到周五）
    wmSixDay,       // 六天工作制（周一到周六）
    wmCustom        // 自定义工作日
  );

  {**
   * THoliday - 节假日记录
   *
   * @desc
   *   表示一个节假日的信息，包括名称、日期、类型等。
   *}
  THoliday = record
    Name: string;
    Date: TDate;
    HolidayType: THolidayType;
    IsRecurring: Boolean; // 是否每年重复
    Description: string;
    
    class function Create(const AName: string; const ADate: TDate; 
      AType: THolidayType = htNational; ARecurring: Boolean = True): THoliday; static;
  end;

  THolidayArray = array of THoliday;

  {**
   * ICalendar - 日历接口
   *
   * @desc
   *   提供日历相关的计算和查询功能。
   *   支持不同的日历系统和本地化设置。
   *
   * @thread_safety
   *   实现应保证线程安全。
   *}
  ICalendar = interface
    ['{F8E7D6C5-B4A3-2F1E-0D9C-8B7A6F5E4D3C}']
    
    // 基本信息
    function GetCalendarType: TCalendarType;
    function GetName: string;
    function GetLocale: string;
    
    // 日期计算
    function AddDays(const ADate: TDate; ADays: Integer): TDate;
    function AddWeeks(const ADate: TDate; AWeeks: Integer): TDate;
    function AddMonths(const ADate: TDate; AMonths: Integer): TDate;
    function AddYears(const ADate: TDate; AYears: Integer): TDate;
    
    function DaysBetween(const AStartDate, AEndDate: TDate): Integer;
    function WeeksBetween(const AStartDate, AEndDate: TDate): Integer;
    function MonthsBetween(const AStartDate, AEndDate: TDate): Integer;
    function YearsBetween(const AStartDate, AEndDate: TDate): Integer;
    
    // 日期属性
    function GetDayOfWeek(const ADate: TDate): TDayOfWeek;
    function GetDayOfYear(const ADate: TDate): Integer;
    function GetWeekOfYear(const ADate: TDate): Integer;
    function GetMonth(const ADate: TDate): TMonth;
    function GetQuarter(const ADate: TDate): TQuarter;
    function GetYear(const ADate: TDate): Integer;
    
    // 日期范围
    function GetFirstDayOfWeek(const ADate: TDate): TDate;
    function GetLastDayOfWeek(const ADate: TDate): TDate;
    function GetFirstDayOfMonth(const ADate: TDate): TDate;
    function GetLastDayOfMonth(const ADate: TDate): TDate;
    function GetFirstDayOfQuarter(const ADate: TDate): TDate;
    function GetLastDayOfQuarter(const ADate: TDate): TDate;
    function GetFirstDayOfYear(const ADate: TDate): TDate;
    function GetLastDayOfYear(const ADate: TDate): TDate;
    
    // 特殊日期
    function IsLeapYear(AYear: Integer): Boolean;
    function GetDaysInMonth(AYear: Integer; AMonth: TMonth): Integer;
    function GetDaysInYear(AYear: Integer): Integer;
    
    // 工作日计算
    function IsWorkday(const ADate: TDate): Boolean;
    function IsWeekend(const ADate: TDate): Boolean;
    function GetNextWorkday(const ADate: TDate): TDate;
    function GetPreviousWorkday(const ADate: TDate): TDate;
    function GetWorkdaysBetween(const AStartDate, AEndDate: TDate): Integer;
    function AddWorkdays(const ADate: TDate; AWorkdays: Integer): TDate;
    
    // 节假日管理
    function IsHoliday(const ADate: TDate): Boolean;
    function GetHoliday(const ADate: TDate): THoliday;
    function GetHolidays(AYear: Integer): THolidayArray; overload;
    function GetHolidays(const AStartDate, AEndDate: TDate): THolidayArray; overload;
    procedure AddHoliday(const AHoliday: THoliday);
    procedure RemoveHoliday(const ADate: TDate);
    procedure ClearHolidays;
    
    // 工作日模式
    procedure SetWorkdayMode(AMode: TWorkdayMode);
    function GetWorkdayMode: TWorkdayMode;
    procedure SetCustomWorkdays(const AWorkdays: array of TDayOfWeek);
    function GetCustomWorkdays: array of TDayOfWeek;
  end;

  {**
   * ICalendarProvider - 日历提供者接口
   *
   * @desc
   *   管理和创建不同类型的日历实例。
   *   支持多种日历系统和本地化设置。
   *
   * @thread_safety
   *   实现应保证线程安全。
   *}
  ICalendarProvider = interface
    ['{A9B8C7D6-E5F4-3A2B-1C0D-9E8F7A6B5C4D}']
    
    // 日历创建
    function CreateCalendar(AType: TCalendarType; const ALocale: string = ''): ICalendar;
    function CreateGregorianCalendar(const ALocale: string = ''): ICalendar;
    function CreateJulianCalendar(const ALocale: string = ''): ICalendar;
    function CreateChineseCalendar(const ALocale: string = ''): ICalendar;
    function CreateIslamicCalendar(const ALocale: string = ''): ICalendar;
    function CreateHebrewCalendar(const ALocale: string = ''): ICalendar;
    
    // 查询功能
    function GetSupportedTypes: array of TCalendarType;
    function IsTypeSupported(AType: TCalendarType): Boolean;
    function GetDefaultType: TCalendarType;
    function GetSystemLocale: string;
    
    // 信息查询
    function GetTypeName(AType: TCalendarType): string;
    function GetTypeDescription(AType: TCalendarType): string;
  end;

// 工厂函数
function CreateCalendar(AType: TCalendarType = ctGregorian; const ALocale: string = ''): ICalendar;
function CreateCalendarProvider: ICalendarProvider;

// 默认实例
function DefaultCalendar: ICalendar;
function DefaultCalendarProvider: ICalendarProvider;

// 便捷函数
function IsWorkday(const ADate: TDate): Boolean; inline;
function IsWeekend(const ADate: TDate): Boolean; inline;
function IsHoliday(const ADate: TDate): Boolean; inline;
function GetNextWorkday(const ADate: TDate): TDate; inline;
function GetWorkdaysBetween(const AStartDate, AEndDate: TDate): Integer; inline;
function AddWorkdays(const ADate: TDate; AWorkdays: Integer): TDate; inline;

// 常用节假日
function GetCommonHolidays(AYear: Integer; const ACountryCode: string = ''): THolidayArray;
function GetChineseHolidays(AYear: Integer): THolidayArray;
function GetUSHolidays(AYear: Integer): THolidayArray;
function GetEuropeanHolidays(AYear: Integer): THolidayArray;

// 日期格式化（本地化）
function FormatDateLocalized(const ADate: TDate; const AFormat: string; const ALocale: string = ''): string;
function ParseDateLocalized(const ADateStr: string; const AFormat: string; const ALocale: string = ''): TDate;

implementation

type
  // 公历日历实现
  TGregorianCalendar = class(TInterfacedObject, ICalendar)
  private
    FLocale: string;
    FWorkdayMode: TWorkdayMode;
    FCustomWorkdays: array of TDayOfWeek;
    FHolidays: array of THoliday;
    
    function InternalIsWorkday(ADayOfWeek: TDayOfWeek): Boolean;
  public
    constructor Create(const ALocale: string = '');
    
    // ICalendar 实现
    function GetCalendarType: TCalendarType;
    function GetName: string;
    function GetLocale: string;
    
    function AddDays(const ADate: TDate; ADays: Integer): TDate;
    function AddWeeks(const ADate: TDate; AWeeks: Integer): TDate;
    function AddMonths(const ADate: TDate; AMonths: Integer): TDate;
    function AddYears(const ADate: TDate; AYears: Integer): TDate;
    
    function DaysBetween(const AStartDate, AEndDate: TDate): Integer;
    function WeeksBetween(const AStartDate, AEndDate: TDate): Integer;
    function MonthsBetween(const AStartDate, AEndDate: TDate): Integer;
    function YearsBetween(const AStartDate, AEndDate: TDate): Integer;
    
    function GetDayOfWeek(const ADate: TDate): TDayOfWeek;
    function GetDayOfYear(const ADate: TDate): Integer;
    function GetWeekOfYear(const ADate: TDate): Integer;
    function GetMonth(const ADate: TDate): TMonth;
    function GetQuarter(const ADate: TDate): TQuarter;
    function GetYear(const ADate: TDate): Integer;
    
    function GetFirstDayOfWeek(const ADate: TDate): TDate;
    function GetLastDayOfWeek(const ADate: TDate): TDate;
    function GetFirstDayOfMonth(const ADate: TDate): TDate;
    function GetLastDayOfMonth(const ADate: TDate): TDate;
    function GetFirstDayOfQuarter(const ADate: TDate): TDate;
    function GetLastDayOfQuarter(const ADate: TDate): TDate;
    function GetFirstDayOfYear(const ADate: TDate): TDate;
    function GetLastDayOfYear(const ADate: TDate): TDate;
    
    function IsLeapYear(AYear: Integer): Boolean;
    function GetDaysInMonth(AYear: Integer; AMonth: TMonth): Integer;
    function GetDaysInYear(AYear: Integer): Integer;
    
    function IsWorkday(const ADate: TDate): Boolean;
    function IsWeekend(const ADate: TDate): Boolean;
    function GetNextWorkday(const ADate: TDate): TDate;
    function GetPreviousWorkday(const ADate: TDate): TDate;
    function GetWorkdaysBetween(const AStartDate, AEndDate: TDate): Integer;
    function AddWorkdays(const ADate: TDate; AWorkdays: Integer): TDate;
    
    function IsHoliday(const ADate: TDate): Boolean;
    function GetHoliday(const ADate: TDate): THoliday;
    function GetHolidays(AYear: Integer): THolidayArray; overload;
    function GetHolidays(const AStartDate, AEndDate: TDate): THolidayArray; overload;
    procedure AddHoliday(const AHoliday: THoliday);
    procedure RemoveHoliday(const ADate: TDate);
    procedure ClearHolidays;
    
    procedure SetWorkdayMode(AMode: TWorkdayMode);
    function GetWorkdayMode: TWorkdayMode;
    procedure SetCustomWorkdays(const AWorkdays: array of TDayOfWeek);
    function GetCustomWorkdays: TArray<TDayOfWeek>;
  end;

  // 日历提供者实现
  TCalendarProvider = class(TInterfacedObject, ICalendarProvider)
  public
    function CreateCalendar(AType: TCalendarType; const ALocale: string = ''): ICalendar;
    function CreateGregorianCalendar(const ALocale: string = ''): ICalendar;
    function CreateJulianCalendar(const ALocale: string = ''): ICalendar;
    function CreateChineseCalendar(const ALocale: string = ''): ICalendar;
    function CreateIslamicCalendar(const ALocale: string = ''): ICalendar;
    function CreateHebrewCalendar(const ALocale: string = ''): ICalendar;
    
    function GetSupportedTypes: TArray<TCalendarType>;
    function IsTypeSupported(AType: TCalendarType): Boolean;
    function GetDefaultType: TCalendarType;
    function GetSystemLocale: string;
    
    function GetTypeName(AType: TCalendarType): string;
    function GetTypeDescription(AType: TCalendarType): string;
  end;

var
  GDefaultCalendar: ICalendar = nil;
  GDefaultProvider: ICalendarProvider = nil;

{ THoliday }

class function THoliday.Create(const AName: string; const ADate: TDate; 
  AType: THolidayType; ARecurring: Boolean): THoliday;
begin
  Result.Name := AName;
  Result.Date := ADate;
  Result.HolidayType := AType;
  Result.IsRecurring := ARecurring;
  Result.Description := '';
end;

// 工厂函数实现

function CreateCalendar(AType: TCalendarType; const ALocale: string): ICalendar;
begin
  Result := DefaultCalendarProvider.CreateCalendar(AType, ALocale);
end;

function CreateCalendarProvider: ICalendarProvider;
begin
  Result := TCalendarProvider.Create;
end;

function DefaultCalendar: ICalendar;
begin
  if GDefaultCalendar = nil then
    GDefaultCalendar := CreateCalendar;
  Result := GDefaultCalendar;
end;

function DefaultCalendarProvider: ICalendarProvider;
begin
  if GDefaultProvider = nil then
    GDefaultProvider := CreateCalendarProvider;
  Result := GDefaultProvider;
end;

// 便捷函数

function IsWorkday(const ADate: TDate): Boolean;
begin
  Result := DefaultCalendar.IsWorkday(ADate);
end;

function IsWeekend(const ADate: TDate): Boolean;
begin
  Result := DefaultCalendar.IsWeekend(ADate);
end;

function IsHoliday(const ADate: TDate): Boolean;
begin
  Result := DefaultCalendar.IsHoliday(ADate);
end;

function GetNextWorkday(const ADate: TDate): TDate;
begin
  Result := DefaultCalendar.GetNextWorkday(ADate);
end;

function GetWorkdaysBetween(const AStartDate, AEndDate: TDate): Integer;
begin
  Result := DefaultCalendar.GetWorkdaysBetween(AStartDate, AEndDate);
end;

function AddWorkdays(const ADate: TDate; AWorkdays: Integer): TDate;
begin
  Result := DefaultCalendar.AddWorkdays(ADate, AWorkdays);
end;

// 实现细节将在后续添加...

end.
