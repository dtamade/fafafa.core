unit fafafa.core.sync.timespec;

{**
 * fafafa.core.sync.timespec - Unix 时间规范工具
 *
 * @desc
 *   提供 TTimeSpec 相关的工具函数，用于 Unix 平台的超时处理。
 *   消除各命名同步原语中的代码重复。
 *
 * @author fafafaStudio
 * @version 1.0.0
 * @since 2025-12
 *}

{$mode objfpc}{$H+}

{$IFDEF UNIX}
{$LINKLIB rt}

interface

uses
  BaseUnix, Unix;

const
  { POSIX 时钟常量 }
  CLOCK_REALTIME  = 0;
  CLOCK_MONOTONIC = 1;

type
  { TTimeSpec 指针类型 }
  PTimeSpec = ^TTimeSpec;

{ clock_gettime 函数声明 }
function clock_gettime(clk_id: cint; tp: PTimeSpec): cint; cdecl; external 'rt';

{**
 * 将毫秒超时转换为绝对 TTimeSpec
 *
 * @param ATimeoutMs 超时时间（毫秒）
 * @return 绝对超时时间的 TTimeSpec 结构
 * @raises ELockError 如果获取当前时间失败
 *
 * @note
 *   使用 CLOCK_REALTIME (fpgettimeofday)
 *   对于需要 CLOCK_MONOTONIC 的场景，请使用 TimeoutToMonotonicTimespec
 *}
function TimeoutToTimespec(ATimeoutMs: Cardinal): TTimeSpec;

{**
 * 将毫秒超时转换为绝对单调时钟 TTimeSpec
 *
 * @param ATimeoutMs 超时时间（毫秒）
 * @return 基于 CLOCK_MONOTONIC 的绝对超时时间
 * @raises ELockError 如果获取当前时间失败
 *
 * @note
 *   使用 CLOCK_MONOTONIC，不受系统时间调整影响
 *   推荐用于条件变量等待
 *}
function TimeoutToMonotonicTimespec(ATimeoutMs: Cardinal): TTimeSpec;

{**
 * 将毫秒转换为相对 TTimeSpec（不获取当前时间）
 *
 * @param ATimeoutMs 超时时间（毫秒）
 * @return 相对超时时间的 TTimeSpec 结构
 *}
function MillisecondsToTimespec(ATimeoutMs: Cardinal): TTimeSpec; inline;

{**
 * 规范化 TTimeSpec（处理纳秒溢出）
 *
 * @param ATimespec 要规范化的 TTimeSpec
 *}
procedure NormalizeTimespec(var ATimespec: TTimeSpec); inline;

implementation

uses
  fafafa.core.sync.base;

const
  NSEC_PER_SEC  = 1000000000;  // 每秒纳秒数
  NSEC_PER_MSEC = 1000000;     // 每毫秒纳秒数
  USEC_PER_MSEC = 1000;        // 每毫秒微秒数
  MSEC_PER_SEC  = 1000;        // 每秒毫秒数

procedure NormalizeTimespec(var ATimespec: TTimeSpec);
begin
  if ATimespec.tv_nsec >= NSEC_PER_SEC then
  begin
    Inc(ATimespec.tv_sec, ATimespec.tv_nsec div NSEC_PER_SEC);
    ATimespec.tv_nsec := ATimespec.tv_nsec mod NSEC_PER_SEC;
  end;
end;

function MillisecondsToTimespec(ATimeoutMs: Cardinal): TTimeSpec;
begin
  Result.tv_sec := ATimeoutMs div MSEC_PER_SEC;
  Result.tv_nsec := (ATimeoutMs mod MSEC_PER_SEC) * NSEC_PER_MSEC;
end;

function TimeoutToTimespec(ATimeoutMs: Cardinal): TTimeSpec;
var
  tv: TTimeVal;
begin
  if fpgettimeofday(@tv, nil) <> 0 then
    raise ELockError.Create('Failed to get current time');

  Result.tv_sec := tv.tv_sec + (ATimeoutMs div MSEC_PER_SEC);
  Result.tv_nsec := (tv.tv_usec * USEC_PER_MSEC) +
                    ((ATimeoutMs mod MSEC_PER_SEC) * NSEC_PER_MSEC);

  NormalizeTimespec(Result);
end;

function TimeoutToMonotonicTimespec(ATimeoutMs: Cardinal): TTimeSpec;
var
  CurrentTime: TTimeSpec;
begin
  if clock_gettime(CLOCK_MONOTONIC, @CurrentTime) <> 0 then
    raise ELockError.Create('Failed to get monotonic time');

  Result.tv_sec := CurrentTime.tv_sec + (ATimeoutMs div MSEC_PER_SEC);
  Result.tv_nsec := CurrentTime.tv_nsec +
                    ((ATimeoutMs mod MSEC_PER_SEC) * NSEC_PER_MSEC);

  NormalizeTimespec(Result);
end;

{$ENDIF UNIX}

end.
