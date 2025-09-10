{$CODEPAGE UTF8}
program fafafa.core.sync.sem.benchmark;

{$include fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.sync.sem.benchmark;

var
  Benchmark: TSemaphoreBenchmark;
begin
  WriteLn('fafafa.core.sync.sem 性能基准测试');
  WriteLn('=====================================');
  WriteLn;
  
  try
    // 创建基准测试实例
    Benchmark := TSemaphoreBenchmark.Create(1, 10, 10000, 4);
    try
      // 运行各种测试
      Benchmark.RunBasicOperations;
      Benchmark.RunConcurrentAccess;
      Benchmark.RunTimeoutBehavior;
      Benchmark.RunBatchOperations;
      
      WriteLn('所有基准测试完成！');
    finally
      Benchmark.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
