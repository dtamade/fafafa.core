program fafafa.core.sync.namedCondvar.test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, fpcunit, testutils, testregistry,
  fafafa.core.sync.namedCondvar.testcase;

var
  LResult: TTestResult;
  
begin
  WriteLn('fafafa.core.sync.namedCondvar 单元测试');
  WriteLn('================================================');
  
  // 创建测试结果对象
  LResult := TTestResult.Create;
  try
    // 运行所有注册的测试
    GetTestRegistry.Run(LResult);
    
    WriteLn('测试完成:');
    WriteLn('  运行: ', LResult.RunTests);
    WriteLn('  失败: ', LResult.NumberOfFailures);
    WriteLn('  错误: ', LResult.NumberOfErrors);
    
    if (LResult.NumberOfFailures = 0) and (LResult.NumberOfErrors = 0) then
      WriteLn('所有测试通过!')
    else
    begin
      WriteLn('测试失败!');
      ExitCode := 1;
    end;
  finally
    LResult.Free;
  end;
end.
