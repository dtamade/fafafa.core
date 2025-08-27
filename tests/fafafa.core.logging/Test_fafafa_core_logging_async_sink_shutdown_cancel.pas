unit Test_fafafa_core_logging_async_sink_shutdown_cancel;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.logging,
  fafafa.core.logging.formatters.text,
  fafafa.core.logging.sinks.textsink,
  fafafa.core.logging.sinks.async;

type
  TTestCase_Logging_AsyncSink_ShutdownCancel = class(TTestCase)
  published
    // 验证：在析构/停止路径上，不发生信号量最大计数越界（不额外 Release NotFull）
    procedure Test_Destroy_NoExtraNotFullRelease_NoSemaphoreOverflow;
  end;

implementation

procedure TTestCase_Logging_AsyncSink_ShutdownCancel.Test_Destroy_NoExtraNotFullRelease_NoSemaphoreOverflow;
var
  Formatter: ILogFormatter;
  Inner: ILogSink;
  AsyncSink: ILogSink;
  I: Integer;
begin
  Formatter := TTextLogFormatter.Create;
  Inner := TTextSinkLogSink.Create(TConsoleSink.Create, Formatter);
  AsyncSink := TAsyncLogSink.Create(Inner, 32, 8, ldpDropNew);

  // 制造一定的队列压力，但不必过大
  for I := 1 to 256 do
    Logging.Log(TLogLevel.llInfo, 'shutdown-cancel #{%d}', [I], '', AsyncSink);

  // 直接释放 AsyncSink（引用计数归零），触发 Destroy 路径
  AsyncSink := nil;

  // 若 Destroy 中错误地额外释放 NotFull，会引发 ELockError：Semaphore count would exceed maximum
  // 未抛异常视为通过
  CheckTrue(True);
end;

initialization
  RegisterTest(TTestCase_Logging_AsyncSink_ShutdownCancel);

end.

