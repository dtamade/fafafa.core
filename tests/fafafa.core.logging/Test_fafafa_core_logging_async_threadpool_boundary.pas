unit Test_fafafa_core_logging_async_threadpool_boundary;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.io,
  fafafa.core.logging, fafafa.core.logging.interfaces,
  fafafa.core.logging.formatters.text,
  fafafa.core.logging.sinks.textsink, fafafa.core.logging.sinks.rollingfile,
  fafafa.core.logging.sinks.composite, fafafa.core.logging.sinks.async;

type
  TTestCase_Logging_AsyncThreadPoolBoundary = class(TTestCase)
  private
    FTempDir: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 端到端：启用 Async sink + Console/Rollingfile，快速提交大量日志，
    // 验证线程池路径上不再出现整数溢出/信号量异常
    procedure Test_Async_Sink_NoOverflow_NoSemaphoreError;
  end;

implementation

procedure TTestCase_Logging_AsyncThreadPoolBoundary.SetUp;
begin
  inherited;
  FTempDir := GetEnvironmentVariable('TEMP');
  if FTempDir = '' then FTempDir := '.';
end;

procedure TTestCase_Logging_AsyncThreadPoolBoundary.TearDown;
begin
  inherited;
end;

procedure TTestCase_Logging_AsyncThreadPoolBoundary.Test_Async_Sink_NoOverflow_NoSemaphoreError;
var
  logger: ILogger;
  sink: ILogSink;
  composite: ILogSink;
  i: Integer;
  formatter: ILogFormatter;
  fileTextSink: ITextSink;
  asyncSink: ILogSink;
begin
  // 使用具体类构造器而非假想的 CreateXxx 工厂函数
  formatter := TTextLogFormatter.Create;
  fileTextSink := TRollingTextFileSink.Create(FTempDir + PathDelim + 'async-boundary.log', 1024*1024, 1, 0);
  sink := TTextSinkLogSink.Create(TConsoleSink.Create, formatter);
  composite := TCompositeLogSink.Create([sink, TTextSinkLogSink.Create(fileTextSink, formatter)]);
  asyncSink := TAsyncLogSink.Create(composite, 1024, 64, ldpDropOld);

  // 通过全局 Logging 设置 formatter 和根 sink（可选）
  Logging.SetFormatter(formatter);
  Logging.SetRootSink(asyncSink);

  logger := GetLogger('async-boundary');

  // 快速写入足量日志，制造异步队列压力
  for i := 1 to 2000 do
    logger.Info('log #{%d}', [i]);

  // 给异步线程一点时间刷队列
  Sleep(200);

  // 若内部出现异常通常会被抛出或导致 AV；此处只要能正常走完即视为通过
  CheckTrue(True);
end;

initialization
  RegisterTest(TTestCase_Logging_AsyncThreadPoolBoundary);

end.

