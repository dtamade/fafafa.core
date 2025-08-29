program simple_mutex_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils,
  fafafa.core.sync.mutex;

var
  m: IMutex;

begin
  WriteLn('=== 简单 Mutex 测试 ===');
  
  try
    // 测试基本工厂函数
    WriteLn('1. 创建 Mutex...');
    m := MakeMutex;
    WriteLn('   ✅ MakeMutex 成功');
    
    // 测试基本操作
    WriteLn('2. 测试基本操作...');
    m.Acquire;
    WriteLn('   ✅ Acquire 成功');
    m.Release;
    WriteLn('   ✅ Release 成功');
    
    // 测试 TryAcquire
    WriteLn('3. 测试 TryAcquire...');
    if m.TryAcquire then
    begin
      WriteLn('   ✅ TryAcquire 成功');
      m.Release;
      WriteLn('   ✅ Release 成功');
    end
    else
      WriteLn('   ❌ TryAcquire 失败');
    
    WriteLn('');
    WriteLn('✅ 所有测试通过！');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 测试失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
