program test_acquire;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.namedMutex;

const
  TEST_MUTEX_NAME = 'test_acquire_mutex';

var
  LMutex: INamedMutex;

begin
  try
    WriteLn('=== 测试 Acquire/Release ===');
    
    WriteLn('1. 创建命名互斥锁...');
    LMutex := CreateNamedMutex(TEST_MUTEX_NAME);
    WriteLn('   ✓ 互斥锁创建成功');
    
    WriteLn('2. 测试 Acquire...');
    LMutex.Acquire;
    WriteLn('   ✓ Acquire 成功');
    
    WriteLn('3. 测试 Release...');
    LMutex.Release;
    WriteLn('   ✓ Release 成功');
    
    WriteLn('4. 清理资源...');
    LMutex := nil;
    WriteLn('   ✓ 资源清理完成');
    
    WriteLn('🎉 Acquire/Release 测试通过！');
    ExitCode := 0;
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 错误: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
