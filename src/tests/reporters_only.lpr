program reporters_only;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  test_reporters_extra,
  test_reporters_missing_cases,
  test_reporters_schema_in_col_and_names;

begin
  try
    // 仅运行 Reporter 相关扩展测试（不依赖 fpcunit 注册体系）
    Test_CSVReporter_TabularCounters_SortedAndMissing;
    Test_JSONReporter_SnapshotLoose;
    // 额外本地用例（不进 CI）
    Test_CSVReporter_CustomSeparator; // sep=tab
    Test_CSVReporter_MissingZero;
    Test_CSVReporter_MissingNA;
    Test_CSVReporter_SchemaInColumn_First;
    Test_JSONReporter_ExtremeNames;

    WriteLn('reporters_only: OK');
  except
    on E: Exception do
    begin
      WriteLn('reporters_only: FAIL: ', E.Message);
      Halt(1);
    end;
  end;
end.

