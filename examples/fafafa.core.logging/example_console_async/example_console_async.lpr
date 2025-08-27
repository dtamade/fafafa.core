program example_console_async;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.logging, fafafa.core.logging.interfaces;

var
  L: ILogger;
begin
  EnableAsyncRoot(1024, 64);
  Logging.SetMinimumLevel(llInfo);
  L := GetLogger('example');
  L.Info('hello %s', ['world']);
  Logging.GetRootSink.Flush;
  Logging.SetRootSink(nil);
end.

