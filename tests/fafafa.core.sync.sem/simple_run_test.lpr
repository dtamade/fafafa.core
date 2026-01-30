{$CODEPAGE UTF8}
program simple_run_test;

{$mode objfpc}{$H+}

uses
  fafafa.core.sync.sem;

var
  Sem: ISem;
begin
  WriteLn('开始简单测试...');
  
  try
    // 测试创建
    Sem := MakeSem(1, 3);
    WriteLn('✓ 创建信号量成功');
    
    // 测试基本操作
    WriteLn('可用许可: ', Sem.GetAvailableCount);
    WriteLn('最大许可: ', Sem.GetMaxCount);
    
    // 测试获取和释放
    Sem.Acquire;
    WriteLn('获取后可用许可: ', Sem.GetAvailableCount);
    
    Sem.Release;
    WriteLn('释放后可用许可: ', Sem.GetAvailableCount);
    
    WriteLn('✓ 简单测试完成');
  except
    on E: Exception do
      WriteLn('✗ 错误: ', E.Message);
  end;
  
  WriteLn('按回车键退出...');
  ReadLn;
end.
