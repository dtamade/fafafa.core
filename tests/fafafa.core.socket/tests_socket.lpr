program tests_socket;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils
  {$IFDEF WINDOWS}, Windows{$ENDIF},
  consoletestrunner,
  // 测试单元
  Test_fafafa_core_socket,
  {$IFDEF FAFAFA_SOCKET_ADVANCED} Test_fafafa_core_socket_advanced, {$ENDIF}
  Test_fafafa_core_socket_best_practices,
  Test_fafafa_core_socket_error_semantics,
  Test_fafafa_core_socket_stats_json,
  Test_fafafa_core_socket_stats_json_ext,
  Test_fafafa_core_socket_shards_smoke,
  Perf_fafafa_core_socket;

var
  Application: TTestRunner;

begin
  {$IFDEF WINDOWS} SetConsoleOutputCP(65001); {$ENDIF}
  SetTextCodePage(Output, 65001);
  SetTextCodePage(StdErr, 65001);
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.socket Tests';
  Application.Run;
  Application.Free;
end.
