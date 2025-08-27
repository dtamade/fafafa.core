{$CODEPAGE UTF8}
program tests_logging;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  Classes, SysUtils, consoletestrunner,
  Test_fafafa_core_logging,
  Test_fafafa_core_logging_bytes_roll,
  Test_fafafa_core_logging_filter_enricher,
  Test_fafafa_core_logging_roll_count,
  Test_fafafa_core_logging_size_buffered,
  Test_fafafa_core_logging_async_threadpool_boundary,
  Test_fafafa_core_logging_async_sink_shutdown_cancel;

type
  TMyTestRunner = class(TTestRunner)
  public
    OutputFile: string;
  protected
    procedure DoRun; override;
  end;


procedure TMyTestRunner.DoRun;
var
  SavedOutput: Text;
  UseFile: Boolean;
begin
  UseFile := (OutputFile <> '');
  if UseFile then
  begin
    SavedOutput := Output;
    AssignFile(Output, OutputFile);
    Rewrite(Output);
    try
      inherited DoRun;
    finally
      CloseFile(Output);
      Output := SavedOutput;
    end;
  end
  else
  begin
    inherited DoRun;
  end;
end;

var
  LApp: TMyTestRunner;

begin
  LApp := TMyTestRunner.Create(nil);
  try
    LApp.Initialize;
    LApp.Title := 'fafafa.core.logging Test Suite';
    // 将输出同时写入文件，便于在控制台拦截场景调试
    LApp.OutputFile := ExtractFilePath(ParamStr(0)) + 'tests_logging_report.txt';
    LApp.Run;
  finally
    LApp.Free;
  end;
  testregistry.GetTestRegistry.Free;
end.

