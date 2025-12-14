program fafafa.core.sync.namedSemaphore.test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, fpcunit,
  fafafa.core.sync.namedSemaphore.testcase;

var
  LTestSuite: TTestSuite;
  LTestResult: TTestResult;

begin
  WriteLn('=== fafafa.core.sync.namedSemaphore 单元测试 ===');
  WriteLn('开始执行测试...');
  WriteLn;

  // 创建测试套件
  LTestSuite := TTestSuite.Create('fafafa.core.sync.namedSemaphore 测试套件');
  try
    // 添加测试用例
    LTestSuite.AddTest(TTestCase_Global.Suite);
    LTestSuite.AddTest(TTestCase_INamedSemaphore.Suite);

    // 运行测试
    LTestResult := TTestResult.Create;
    try
      LTestSuite.Run(LTestResult);

      // 显示结果
      WriteLn('测试完成！');
      WriteLn('运行测试数: ', LTestResult.RunTests);
      WriteLn('失败测试数: ', LTestResult.NumberOfFailures);
      WriteLn('错误测试数: ', LTestResult.NumberOfErrors);

      if (LTestResult.NumberOfFailures > 0) or (LTestResult.NumberOfErrors > 0) then
        ExitCode := 1;

    finally
      LTestResult.Free;
    end;
  finally
    LTestSuite.Free;
  end;

end.
