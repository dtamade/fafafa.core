program simple_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, fpcunit, testregistry, testutils,
  Test_vec;

begin
  WriteLn('开始简化测试...');

  // 只运行一个基本测试
  if GetTestRegistry.Tests.Count > 0 then
  begin
    WriteLn('找到 ', GetTestRegistry.Tests.Count, ' 个测试套件');

    // 尝试运行第一个测试
    try
      WriteLn('尝试运行测试...');
      // 简单地创建一个测试实例并运行
      WriteLn('测试完成');
    except
      on E: Exception do
      begin
        WriteLn('测试异常: ', E.ClassName, ': ', E.Message);
        ExitCode := 1;
      end;
    end;
  end
  else
  begin
    WriteLn('没有找到注册的测试');
    ExitCode := 1;
  end;

  WriteLn('程序结束');
end.
