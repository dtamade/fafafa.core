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

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.time.consts,
  fafafa.core.time.duration,
  fafafa.core.time.instant;

type

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
  // 统一对外常量名，值来源于 consts 或其派生
  NANOSECONDS_PER_MICROSECOND = NANOSECONDS_PER_MICRO;
  NANOSECONDS_PER_MILLISECOND = NANOSECONDS_PER_MILLI;
  NANOSECONDS_PER_SECOND      = fafafa.core.time.consts.NANOSECONDS_PER_SECOND;
  NANOSECONDS_PER_MINUTE      = NANOSECONDS_PER_SECOND * 60;
  NANOSECONDS_PER_HOUR        = NANOSECONDS_PER_MINUTE * 60;
  NANOSECONDS_PER_DAY         = NANOSECONDS_PER_HOUR * 24;

  MICROSECONDS_PER_MILLISECOND = 1000;
  MICROSECONDS_PER_SECOND      = fafafa.core.time.consts.MICROSECONDS_PER_SECOND;
  MICROSECONDS_PER_MINUTE      = MICROSECONDS_PER_SECOND * 60;
  MICROSECONDS_PER_HOUR        = MICROSECONDS_PER_MINUTE * 60;
  MICROSECONDS_PER_DAY         = MICROSECONDS_PER_HOUR * 24;

  MILLISECONDS_PER_SECOND = fafafa.core.time.consts.MILLISECONDS_PER_SECOND;
  MILLISECONDS_PER_MINUTE = MILLISECONDS_PER_SECOND * 60;
  MILLISECONDS_PER_HOUR   = MILLISECONDS_PER_MINUTE * 60;
  MILLISECONDS_PER_DAY    = MILLISECONDS_PER_HOUR * 24;

  SECONDS_PER_MINUTE = 60;
  SECONDS_PER_HOUR   = 3600;
  SECONDS_PER_DAY    = 86400;

  MINUTES_PER_HOUR = 60;
  MINUTES_PER_DAY  = 1440;

  HOURS_PER_DAY = 24;
implementation

// TDuration 实现将在后续添加
// TInstant 实现将在后续添加

end.


