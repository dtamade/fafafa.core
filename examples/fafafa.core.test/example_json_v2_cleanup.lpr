{$CODEPAGE UTF8}
program example_json_v2_cleanup;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.test.listener.json,
  fafafa.core.test.json.rtl,
  fafafa.core.test.core;

var
  L: ITestListener;
begin
  // 使用 JSON V2 Writer 以输出结构化 cleanup 数组到 report.json
  L := TJsonTestListener.Create(@CreateRtlJsonWriterV2, 'report.json');
  L.OnStart(1);
  // 构造一个失败用例，并包含 cleanup 明细（两条）
  L.OnTestFailure('demo/cleanup', 'boom' + LineEnding + '[cleanup]' + LineEnding + 'E1: c1' + LineEnding + 'E2: c2', 20);
  L.OnEnd(1, 1, 20);
  Writeln('生成 report.json，包含 tests[0].cleanup 结构化数组');
end.

