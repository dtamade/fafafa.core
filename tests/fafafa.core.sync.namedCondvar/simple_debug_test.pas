program simple_debug_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.namedCondvar,
  fafafa.core.sync.namedMutex;

const
  TEST_CONDVAR_NAME = 'test_debug_condvar';
  TEST_MUTEX_NAME = 'test_debug_mutex';

var
  LCondVar: INamedConditionVariable;
  LMutex: INamedMutex;

begin
  try
    WriteLn('=== 简单调试测试 ===');
    
    WriteLn('1. 创建命名互斥锁...');
    LMutex := Sync.MakeNamedMutex(TEST_MUTEX_NAME);
    WriteLn('   ✓ 互斥锁创建成功');
    WriteLn('   句柄: ', IntToHex(PtrUInt(LMutex.GetHandle), 16));
    
    WriteLn('2. 创建命名条件变量...');
    LCondVar := MakeNamedConditionVariable(TEST_CONDVAR_NAME);
    WriteLn('   ✓ 条件变量创建成功');
    WriteLn('   名称: ', LCondVar.GetName);
    WriteLn('   句柄: ', IntToHex(PtrUInt(LCondVar.GetHandle), 16));
    WriteLn('   是否为创建者: ', LCondVar.IsCreator);
    
    WriteLn('3. 测试基本操作...');
    WriteLn('   发送信号...');
    LCondVar.Signal;
    WriteLn('   ✓ 信号发送成功');
    
    WriteLn('   广播信号...');
    LCondVar.Broadcast;
    WriteLn('   ✓ 广播成功');
    
    WriteLn('4. 清理资源...');
    LCondVar := nil;
    LMutex := nil;
    WriteLn('   ✓ 资源清理完成');
    
    WriteLn('🎉 所有测试通过！');
    ExitCode := 0;
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 错误: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
