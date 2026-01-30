program example_policy_pipeline;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.logging, fafafa.core.logging.interfaces,
  fafafa.core.io,
  fafafa.core.logging.sinks.textsink,
  fafafa.core.logging.sinks.rollingfile,
  fafafa.core.logging.sinks.async,
  fafafa.core.logging.formatters.text;

var
  pol: TFlushPolicy;
  fmt: ILogFormatter;
  inner: ILogSink;
  async: ILogSink;
  L: ILogger;
begin
  pol.Enabled := True;
  pol.MaxLines := 64;
  pol.MaxIntervalMs := 100;

  fmt := TTextLogFormatter.Create;
  inner := TTextSinkLogSink.Create(
    TRollingTextFileSink.Create('policy.log', 1024*1024, 5, 0),
    fmt,
    pol
  );
  async := TAsyncLogSink.Create(inner, 4096, 128, ldpDropOld);

  Logging.SetFormatter(fmt);
  Logging.SetRootSink(async);
  Logging.SetMinimumLevel(llInfo);

  L := GetLogger('policy');
  L.Info('pipeline started', []);
  L.Info('value=%d ok=%s', [123, 'yes']);

  Logging.GetRootSink.Flush;
  Logging.SetRootSink(nil);
end.

