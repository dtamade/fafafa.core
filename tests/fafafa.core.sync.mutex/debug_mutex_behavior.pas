program debug_mutex_behavior;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.mutex;

var
  m: IMutex;
  threadId1, threadId2: TThreadID;

begin
  WriteLn('=== 调试 Mutex 重入行为 ===');
  
  m := MakeMutex;
  
  // 第一次获取
  WriteLn('第一次 Acquire...');
  m.Acquire;
  threadId1 := GetCurrentThreadId;
  WriteLn('第一次 Acquire 成功，线程ID: ', threadId1);
  
  // 尝试重入
  WriteLn('尝试同线程 TryAcquire...');
  threadId2 := GetCurrentThreadId;
  WriteLn('当前线程ID: ', threadId2, ' (应该与第一次相同: ', threadId1 = threadId2, ')');
  
  if m.TryAcquire then
  begin
    WriteLn('❌ TryAcquire 成功 - Mutex 表现为可重入！');
    WriteLn('错误状态: ', Ord(m.GetLastError));
    m.Release; // 释放 TryAcquire
  end
  else
  begin
    WriteLn('✅ TryAcquire 失败 - Mutex 正确表现为不可重入');
    WriteLn('错误状态: ', Ord(m.GetLastError));
  end;
  
  // 释放第一次获取
  WriteLn('释放第一次 Acquire...');
  m.Release;
  WriteLn('释放成功');
  
  WriteLn('=== 测试完成 ===');
end.
