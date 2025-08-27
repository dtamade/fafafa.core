{$CODEPAGE UTF8}
program example_mem_integration_runner;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  consoletestrunner,
  // 集成/跨域示例测试单元（已从 tests 迁移为示例）
  Test_memory_map,
  Test_memory_map_flushrange,
  Test_shared_memory,
  Test_shared_memory_crossproc,
  Test_shared_memory_crossproc_unix,

  // 暂不包含 enhanced_* 单元，待该系列稳定后再纳入
  Test_memory_performance;

var
  Application: TTestRunner;
begin
  DefaultFormat := fPlain;
  Application := TTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'fafafa.core.mem 集成/示例测试 Runner';
    Application.Run;
  finally
    Application.Free;
  end;
end.

