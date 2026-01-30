program example_console_and_rolling;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.logging, fafafa.core.logging.interfaces;

var
  L: ILogger;
begin
  EnableConsoleAndRollingRoot('example.log', 1024*1024, 4096, 128);
  Logging.SetMinimumLevel(llInfo);
  L := GetLogger('example');
  L.Info('to console and file', []);
  Logging.GetRootSink.Flush;
  Logging.SetRootSink(nil);
end.

