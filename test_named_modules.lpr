program test_named_modules;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  fafafa.core.sync.namedMutex,
  fafafa.core.sync.namedEvent,
  fafafa.core.sync.namedSemaphore,
  fafafa.core.sync.namedBarrier,
  fafafa.core.sync.namedConditionVariable,
  fafafa.core.sync.namedRWLock;

var
  NamedMutex: INamedMutex;
  NamedEvent: INamedEvent;
  NamedSem: INamedSemaphore;
  NamedBarrier: INamedBarrier;
  NamedCV: INamedConditionVariable;
  NamedRWLock: INamedRWLock;
  
begin
  WriteLn('测试各个命名模块编译...');
  
  try
    // 测试命名互斥锁
    NamedMutex := MakeNamedMutex('test_mutex');
    WriteLn('✓ namedMutex 模块正常');
    
    // 测试命名事件
    NamedEvent := MakeNamedEvent('test_event');
    WriteLn('✓ namedEvent 模块正常');
    
    // 测试命名信号量
    NamedSem := MakeNamedSemaphore('test_sem');
    WriteLn('✓ namedSemaphore 模块正常');
    
    // 测试命名屏障
    NamedBarrier := MakeNamedBarrier('test_barrier', 2);
    WriteLn('✓ namedBarrier 模块正常');
    
    // 测试命名条件变量
    NamedCV := MakeNamedConditionVariable('test_cv');
    WriteLn('✓ namedConditionVariable 模块正常');
    
    // 测试命名读写锁
    NamedRWLock := MakeNamedRWLock('test_rwlock');
    WriteLn('✓ namedRWLock 模块正常');
    
    WriteLn('');
    WriteLn('🎉 所有命名模块编译和运行正常！');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 测试失败: ', E.Message);
      Halt(1);
    end;
  end;
end.
