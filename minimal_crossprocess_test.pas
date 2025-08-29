program minimal_crossprocess_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.namedConditionVariable,
  fafafa.core.sync.namedMutex;

const
  TEST_CONDVAR_NAME = 'test_minimal_condvar';
  TEST_MUTEX_NAME = 'test_minimal_mutex';

var
  LCondVar: INamedConditionVariable;
  LMutex: INamedMutex;
  LRole: string;

procedure TestCreator;
begin
  try
    WriteLn('[Creator] 开始创建共享对象...');
    
    LMutex := CreateNamedMutex(TEST_MUTEX_NAME);
    WriteLn('[Creator] ✓ 互斥锁创建成功');
    
    LCondVar := MakeNamedConditionVariable(TEST_CONDVAR_NAME);
    WriteLn('[Creator] ✓ 条件变量创建成功');
    WriteLn('[Creator] 是否为创建者: ', LCondVar.IsCreator);
    
    WriteLn('[Creator] 等待5秒让其他进程访问...');
    Sleep(5000);
    
    WriteLn('[Creator] 发送信号...');
    LCondVar.Signal;
    WriteLn('[Creator] ✓ 信号发送完成');
    
    WriteLn('[Creator] 创建者完成');
    ExitCode := 0;
    
  except
    on E: Exception do
    begin
      WriteLn('[Creator] ❌ 错误: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end;

procedure TestAccessor;
begin
  try
    WriteLn('[Accessor] 开始访问共享对象...');
    
    // 等待一下确保创建者先创建对象
    Sleep(1000);
    
    LMutex := CreateNamedMutex(TEST_MUTEX_NAME);
    WriteLn('[Accessor] ✓ 互斥锁访问成功');
    
    LCondVar := MakeNamedConditionVariable(TEST_CONDVAR_NAME);
    WriteLn('[Accessor] ✓ 条件变量访问成功');
    WriteLn('[Accessor] 是否为创建者: ', LCondVar.IsCreator);
    
    WriteLn('[Accessor] 访问者完成');
    ExitCode := 0;
    
  except
    on E: Exception do
    begin
      WriteLn('[Accessor] ❌ 错误: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end;

begin
  try
    if ParamCount = 0 then
    begin
      WriteLn('用法: ', ParamStr(0), ' [creator|accessor]');
      ExitCode := 1;
    end
    else
    begin
      LRole := ParamStr(1);
      if LRole = 'creator' then
        TestCreator
      else if LRole = 'accessor' then
        TestAccessor
      else
      begin
        WriteLn('无效参数: ', LRole);
        ExitCode := 1;
      end;
    end;
  except
    on E: Exception do
    begin
      WriteLn('全局错误: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
