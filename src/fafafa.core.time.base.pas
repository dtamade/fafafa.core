unit fafafa.core.time.base;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.base - 时间模块基础定义

📖 概述：
  时间模块的基础定义，包含核心类型、接口、异常和常量。
  提供统一的时间语义层，支持现代化的时间处理。

🔧 特性：
  • 核心时间类型：TDuration、TInstant、TDeadline
  • 统一的异常处理体系
  • 跨平台时间常量定义
  • 高精度纳秒级时间表示

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
──────────────────────────────────────────────────────────────
}

{$MODE OBJFPC}{$H+}
{$modeswitch advancedrecords}

{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base;

type
  // 简单过程别名，供计时/回调等使用
  TProc = procedure;
  {**
   * ETimeError - 时间操作基础异常类
   *
   * @desc
   *   所有时间相关异常的基类。提供统一的异常处理接口，
   *   便于捕获和处理各种时间操作错误。
   *
   * @inheritance
   *   继承自标准的 Exception 类，具备完整的异常处理能力。
   *
   * @usage
   *   try
   *     // 时间操作
   *   except
   *     on E: ETimeError do
   *       // 处理所有时间相关异常
   *   end;
   *}
  ETimeError = class(Exception);

  {**
   * ETimeoutError - 超时异常类
   *
   * @desc
   *   当时间操作超过指定的超时时间时抛出的异常。
   *   用于区分超时和其他类型的失败。
   *
   * @scenarios
   *   - 带超时的等待操作超时
   *   - 定时器操作超时
   *   - 调度器任务超时
   *}
  ETimeoutError = class(ETimeError);

  {**
   * EInvalidTimeFormat - 无效时间格式异常类
   *
   * @desc
   *   当时间格式化或解析操作遇到无效格式时抛出的异常。
   *   用于时间字符串的格式验证和错误处理。
   *
   * @scenarios
   *   - 解析无效的时间字符串
   *   - 使用不支持的时间格式
   *   - 时间格式化参数错误
   *}
  EInvalidTimeFormat = class(ETimeError);

  {**
   * ETimeOverflow - 时间溢出异常类
   *
   * @desc
   *   当时间计算结果超出表示范围时抛出的异常。
   *   用于防止时间计算中的溢出错误。
   *
   * @scenarios
   *   - 时间加法导致溢出
   *   - 时间乘法导致溢出
   *   - 时间转换超出范围
   *}
  ETimeOverflow = class(ETimeError);

const
  // 时间单位常量（纳秒为基准）
  NANOSECONDS_PER_MICROSECOND = 1000;
  NANOSECONDS_PER_MILLISECOND = 1000000;
  NANOSECONDS_PER_SECOND = 1000000000;
  NANOSECONDS_PER_MINUTE = 60000000000;
  NANOSECONDS_PER_HOUR = 3600000000000;
  NANOSECONDS_PER_DAY = 86400000000000;

  MICROSECONDS_PER_MILLISECOND = 1000;
  MICROSECONDS_PER_SECOND = 1000000;
  MICROSECONDS_PER_MINUTE = 60000000;
  MICROSECONDS_PER_HOUR = 3600000000;
  MICROSECONDS_PER_DAY = 86400000000;

  MILLISECONDS_PER_SECOND = 1000;
  MILLISECONDS_PER_MINUTE = 60000;
  MILLISECONDS_PER_HOUR = 3600000;
  MILLISECONDS_PER_DAY = 86400000;

  SECONDS_PER_MINUTE = 60;
  SECONDS_PER_HOUR = 3600;
  SECONDS_PER_DAY = 86400;

  MINUTES_PER_HOUR = 60;
  MINUTES_PER_DAY = 1440;

  HOURS_PER_DAY = 24;

type
  // 前向声明
  TDuration = record;
  TInstant = record;
  TDeadline = record;

  {**
   * TDuration - 时间间隔类型
   *
   * @desc
   *   表示时间间隔的记录类型，基于纳秒精度。
   *   支持负值以表达"已过期/剩余为负"的概念。
   *   提供丰富的算术和比较操作。
   *
   * @precision
   *   纳秒级精度，适用于高精度时间测量和计算。
   *
   * @thread_safety
   *   值类型，天然线程安全。
   *}
  TDuration = record
  private
    FNs: Int64; // 纳秒
  public
    // 构造函数
    class function FromNs(const A: Int64): TDuration; static;
    class function FromUs(const A: Int64): TDuration; static;
    class function FromMs(const A: Int64): TDuration; static;
    class function FromSec(const A: Int64): TDuration; static;
    class function Zero: TDuration; static; inline;

    // 安全构造函数
    class function TryFromNs(const A: Int64; out D: TDuration): Boolean; static;
    class function TryFromUs(const A: Int64; out D: TDuration): Boolean; static;
    class function TryFromMs(const A: Int64; out D: TDuration): Boolean; static;
    class function TryFromSec(const A: Int64; out D: TDuration): Boolean; static;

    // 转换函数
    function AsNs: Int64; inline;
    function AsUs: Int64; inline;
    function AsMs: Int64; inline;
    function AsSec: Int64; inline;

    // 算术操作
    function Add(const B: TDuration): TDuration; inline;
    function Sub(const B: TDuration): TDuration; inline;
    function Mul(const K: Int64): TDuration; inline;
    function DivBy(const K: Int64): TDuration; inline;
    function Modulo(const B: TDuration): TDuration; inline;
    function Abs: TDuration; inline;
    function Neg: TDuration; inline;

    // 状态检查
    function IsZero: Boolean; inline;
    function IsNegative: Boolean; inline;
    function IsPositive: Boolean; inline;

    // 比较操作
    function Compare(const B: TDuration): Integer; inline;
    function LessThan(const B: TDuration): Boolean; inline;
    function GreaterThan(const B: TDuration): Boolean; inline;
    function Equal(const B: TDuration): Boolean; inline;

    // 工具函数
    function Clamp(const MinV, MaxV: TDuration): TDuration; inline;
    class function Min(const A, B: TDuration): TDuration; static; inline;
    class function Max(const A, B: TDuration): TDuration; static; inline;

    // 饱和算术
    function SaturatingAdd(const B: TDuration): TDuration; inline;
    function SaturatingSub(const B: TDuration): TDuration; inline;
    function SaturatingMul(const K: Int64): TDuration;

    // 安全算术
    function CheckedAdd(const B: TDuration; out R: TDuration): Boolean; inline;
    function CheckedSub(const B: TDuration; out R: TDuration): Boolean; inline;
    function CheckedMul(const K: Int64; out R: TDuration): Boolean; inline;

    // 运算符重载
    class operator +(const A, B: TDuration): TDuration; inline;
    class operator -(const A, B: TDuration): TDuration; inline;
    class operator *(const A: TDuration; const K: Int64): TDuration; inline;
    class operator *(const K: Int64; const A: TDuration): TDuration; inline;
    class operator =(const A, B: TDuration): Boolean;
    class operator <>(const A, B: TDuration): Boolean;
    class operator <(const A, B: TDuration): Boolean;
    class operator >(const A, B: TDuration): Boolean;
    class operator <=(const A, B: TDuration): Boolean;
    class operator >=(const A, B: TDuration): Boolean;

    // 字符串表示
    function ToString: string;
  end;

  {**
   * TInstant - 单调时钟时间点
   *
   * @desc
   *   表示单调时钟上的时间点，基于纳秒精度。
   *   单调时钟不受系统时间调整影响，适用于测量和超时。
   *
   * @precision
   *   纳秒级精度，自某个不变基准起点计算。
   *
   * @thread_safety
   *   值类型，天然线程安全。
   *}
  TInstant = record
  private
    FNsSinceEpoch: UInt64; // 单调时钟的纳秒
  public
    // 构造函数
    class function FromNsSinceEpoch(const A: UInt64): TInstant; static;
    class function Zero: TInstant; static; inline;

    // 转换函数
    function AsNsSinceEpoch: UInt64; inline;

    // 算术操作
    function Add(const D: TDuration): TInstant; inline;
    function Sub(const D: TDuration): TInstant; inline;
    function Diff(const Older: TInstant): TDuration; inline;
    function Since(const Older: TInstant): TDuration; inline;

    // 状态检查
    function HasPassed(const NowI: TInstant): Boolean; inline;
    function IsBefore(const Other: TInstant): Boolean; inline;
    function IsAfter(const Other: TInstant): Boolean; inline;

    // 比较操作
    function Compare(const B: TInstant): Integer; inline;
    function LessThan(const B: TInstant): Boolean; inline;
    function GreaterThan(const B: TInstant): Boolean; inline;
    function Equal(const B: TInstant): Boolean; inline;

    // 工具函数
    function Clamp(const MinV, MaxV: TInstant): TInstant; inline;
    class function Min(const A, B: TInstant): TInstant; static; inline;
    class function Max(const A, B: TInstant): TInstant; static; inline;

    // 安全算术
    function CheckedAdd(const D: TDuration; out R: TInstant): Boolean; inline;
    function CheckedSub(const D: TDuration; out R: TInstant): Boolean; inline;

    // 运算符重载
    class operator =(const A, B: TInstant): Boolean;
    class operator <>(const A, B: TInstant): Boolean;
    class operator <(const A, B: TInstant): Boolean;
    class operator >(const A, B: TInstant): Boolean;
    class operator <=(const A, B: TInstant): Boolean;
    class operator >=(const A, B: TInstant): Boolean;

    // 字符串表示
    function ToString: string;
  end;

implementation

// TDuration 实现将在后续添加
// TInstant 实现将在后续添加

end.
