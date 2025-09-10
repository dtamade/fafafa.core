{$CODEPAGE UTF8}
program minimal_test;

{$mode objfpc}{$H+}

uses
  fafafa.core.sync.sem;

var
  Sem: ISem;
begin
  WriteLn('开始最小测试...');
  
  try
    Sem := MakeSem(1, 3);
    WriteLn('✓ 创建信号量成功');
    
    Sem.Acquire;
    WriteLn('✓ 获取许可成功');
    
    Sem.Release;
    WriteLn('✓ 释放许可成功');
    
    WriteLn('✓ 最小测试通过');
  except
    on E: Exception do
      WriteLn('✗ 错误: ', E.Message);
  end;
end.
