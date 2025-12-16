unit fafafa.core.time.leapsec;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.leapsec - 闰秒处理

📖 概述：
  提供闰秒表、TAI-UTC 偏移计算和 UTC-SLS 涂抹算法支持。
  
🔧 特性：
  • 历史闰秒表（1972-2017）
  • TAI-UTC 偏移查询
  • UTC-SLS (Smoothed Leap Seconds) 涂抹算法
  • 闰秒时刻检测

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

const
  /// <summary>UTC-SLS 涂抹窗口大小（秒）</summary>
  UTCSLS_SMEAR_WINDOW = 1000;

/// <summary>返回闰秒表中的闰秒数量</summary>
function GetLeapSecondCount: Integer;

/// <summary>检查指定 Unix 时间是否为闰秒发生时刻</summary>
/// <param name="AUnixSec">Unix 时间戳（秒）</param>
/// <returns>如果该时刻是闰秒发生时刻返回 True</returns>
function IsLeapSecondMoment(AUnixSec: Int64): Boolean;

/// <summary>获取指定时刻的 TAI-UTC 偏移量（秒）</summary>
/// <param name="AUnixSec">Unix 时间戳（秒）</param>
/// <returns>TAI - UTC 的秒数差值</returns>
/// <remarks>
///   TAI (国际原子时) 是连续的时间标准，不包含闰秒。
///   UTC 通过插入闰秒与地球自转保持同步。
/// </remarks>
function GetTAIMinusUTC(AUnixSec: Int64): Integer;

/// <summary>应用 UTC-SLS (Smoothed Leap Seconds) 涂抹算法</summary>
/// <param name="AUnixSec">UTC Unix 时间戳（秒）</param>
/// <returns>UTC-SLS 时间戳（秒）</returns>
/// <remarks>
///   UTC-SLS 是 Google 提出的闰秒处理策略，在闰秒前 1000 秒内
///   将闰秒"涂抹"到时间中，使时间平滑过渡，避免出现 23:59:60。
/// </remarks>
function ApplyUTCSLS(AUnixSec: Int64): Int64;

/// <summary>获取下一个闰秒发生时刻</summary>
/// <param name="AUnixSec">当前 Unix 时间戳（秒）</param>
/// <param name="ANextLeap">输出：下一个闰秒时刻</param>
/// <returns>如果存在下一个闰秒返回 True</returns>
function GetNextLeapSecond(AUnixSec: Int64; out ANextLeap: Int64): Boolean;

implementation

uses
  fafafa.core.math;

const
  // 历史闰秒表：每个闰秒发生在该 Unix 时间戳所代表的那一秒结束时
  // 即 23:59:59 变为 23:59:60，然后变为 00:00:00
  // 存储的是闰秒前一秒的 Unix 时间戳
  LEAP_SECONDS: array[0..26] of Int64 = (
    78796799,   // 1972-06-30 23:59:59
    94694399,   // 1972-12-31 23:59:59
    126230399,  // 1973-12-31 23:59:59
    157766399,  // 1974-12-31 23:59:59
    189302399,  // 1975-12-31 23:59:59
    220924799,  // 1976-12-31 23:59:59
    252460799,  // 1977-12-31 23:59:59
    283996799,  // 1978-12-31 23:59:59
    315532799,  // 1979-12-31 23:59:59
    362793599,  // 1981-06-30 23:59:59
    394329599,  // 1982-06-30 23:59:59
    425865599,  // 1983-06-30 23:59:59
    489023999,  // 1985-06-30 23:59:59
    567993599,  // 1987-12-31 23:59:59
    631151999,  // 1989-12-31 23:59:59
    662687999,  // 1990-12-31 23:59:59
    709948799,  // 1992-06-30 23:59:59
    741484799,  // 1993-06-30 23:59:59
    773020799,  // 1994-06-30 23:59:59
    820454399,  // 1995-12-31 23:59:59
    867715199,  // 1997-06-30 23:59:59
    915148799,  // 1998-12-31 23:59:59
    1136073599, // 2005-12-31 23:59:59
    1230767999, // 2008-12-31 23:59:59
    1341100799, // 2012-06-30 23:59:59
    1435708799, // 2015-06-30 23:59:59
    1483228799  // 2016-12-31 23:59:59
  );
  
  // 每个闰秒后的 TAI-UTC 偏移量
  // 1972-01-01 开始时 TAI-UTC = 10 秒
  TAI_OFFSETS: array[0..27] of Integer = (
    10,  // 1972-01-01 之前（起始偏移）
    11,  // 1972-06-30 后
    12,  // 1972-12-31 后
    13,  // 1973-12-31 后
    14,  // 1974-12-31 后
    15,  // 1975-12-31 后
    16,  // 1976-12-31 后
    17,  // 1977-12-31 后
    18,  // 1978-12-31 后
    19,  // 1979-12-31 后
    20,  // 1981-06-30 后
    21,  // 1982-06-30 后
    22,  // 1983-06-30 后
    23,  // 1985-06-30 后
    24,  // 1987-12-31 后
    25,  // 1989-12-31 后
    26,  // 1990-12-31 后
    27,  // 1992-06-30 后
    28,  // 1993-06-30 后
    29,  // 1994-06-30 后
    30,  // 1995-12-31 后
    31,  // 1997-06-30 后
    32,  // 1998-12-31 后
    33,  // 2005-12-31 后
    34,  // 2008-12-31 后
    35,  // 2012-06-30 后
    36,  // 2015-06-30 后
    37   // 2016-12-31 后
  );

function GetLeapSecondCount: Integer;
begin
  Result := Length(LEAP_SECONDS);
end;

function IsLeapSecondMoment(AUnixSec: Int64): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to High(LEAP_SECONDS) do
  begin
    if LEAP_SECONDS[I] = AUnixSec then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function GetTAIMinusUTC(AUnixSec: Int64): Integer;
var
  I: Integer;
begin
  // 在 1972-01-01 之前，使用起始偏移
  // 63072000 = 1972-01-01 00:00:00 UTC
  if AUnixSec < 63072000 then
  begin
    Result := 10;
    Exit;
  end;
  
  // 二分查找或线性查找对应的偏移
  Result := TAI_OFFSETS[0];
  for I := 0 to High(LEAP_SECONDS) do
  begin
    if AUnixSec > LEAP_SECONDS[I] then
      Result := TAI_OFFSETS[I + 1]
    else
      Break;
  end;
end;

function ApplyUTCSLS(AUnixSec: Int64): Int64;
var
  I: Integer;
  LeapTime: Int64;
  SmearStart: Int64;
  ElapsedInWindow: Int64;
  SmearOffset: Double;
begin
  Result := AUnixSec;
  
  // 查找最近的闰秒（在当前时间之后或刚好发生）
  for I := 0 to High(LEAP_SECONDS) do
  begin
    LeapTime := LEAP_SECONDS[I];
    SmearStart := LeapTime - UTCSLS_SMEAR_WINDOW + 1;
    
    // 在涂抹窗口内
    if (AUnixSec >= SmearStart) and (AUnixSec <= LeapTime) then
    begin
      // 计算在窗口内经过的时间
      ElapsedInWindow := AUnixSec - SmearStart;
      // 涂抹偏移：线性增加，在窗口结束时达到 1 秒
      SmearOffset := ElapsedInWindow / UTCSLS_SMEAR_WINDOW;
      // UTC-SLS 时间 = UTC 时间 + 涂抹偏移
      Result := AUnixSec + Round(SmearOffset);
      Exit;
    end;
  end;
  
  // 不在任何涂抹窗口内，返回原时间
  Result := AUnixSec;
end;

function GetNextLeapSecond(AUnixSec: Int64; out ANextLeap: Int64): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to High(LEAP_SECONDS) do
  begin
    if LEAP_SECONDS[I] > AUnixSec then
    begin
      ANextLeap := LEAP_SECONDS[I];
      Result := True;
      Exit;
    end;
  end;
end;

end.
