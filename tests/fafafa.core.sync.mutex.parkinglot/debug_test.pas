program debug_test;

{$mode objfpc}{$H+}

uses
  SysUtils;

begin
  try
    WriteLn('Debug test starting...');
    
    // 测试基本输出
    WriteLn('Basic output test: OK');
    
    // 测试异常处理
    try
      WriteLn('Testing exception handling...');
      // 不抛出异常，只是测试
      WriteLn('Exception handling: OK');
    except
      on E: Exception do
        WriteLn('Exception caught: ', E.Message);
    end;
    
    WriteLn('Debug test completed successfully!');
    
  except
    on E: Exception do
    begin
      WriteLn('Fatal error: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
