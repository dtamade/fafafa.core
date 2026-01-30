program example_daily_rolling;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.logging, fafafa.core.logging.interfaces;

var
  L: ILogger;
begin
  EnableAsyncDailyRollingFileRoot('example.log', 7, 4096, 128);
  Logging.SetMinimumLevel(llInfo);
  L := GetLogger('example');
  L.Info('line %d', [1]);
  Logging.GetRootSink.Flush;
  Logging.SetRootSink(nil);
end.

