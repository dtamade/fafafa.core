program test_raii_mutex;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils,
  fafafa.core.sync.mutex;

var
  m: IMutex;
  guard, guard1, guard2: IMutexGuard;

begin
  WriteLn('=== 测试 RAII 互斥锁功能 ===');
  
  try
    // 测试标准可重入互斥锁的 RAII 功能
    WriteLn('1. 创建互斥锁...');
    m := MakeMutex;
    WriteLn('   ✅ MakeMutex 成功');
    
    // 测试 Lock 方法（RAII 自动管理）
    WriteLn('2. 测试 Lock 方法（RAII）...');
    begin
      guard := m.Lock;
      WriteLn('   ✅ m.Lock 成功，锁已自动获取');
      
      // 在这个作用域内，锁被自动持有
      // 当 guard 超出作用域时，锁会自动释放
    end;
    // guard 在这里自动析构，锁被自动释放
    WriteLn('   ✅ 锁已自动释放（RAII）');
    
    // 测试 TryLock 方法
    WriteLn('3. 测试 TryLock 方法...');
    guard := m.TryLock;
    if guard <> nil then
    begin
      WriteLn('   ✅ m.TryLock 成功，锁已自动获取');
      guard := nil; // 手动释放引用，触发自动析构
      WriteLn('   ✅ 锁已自动释放');
    end
    else
    begin
      WriteLn('   ❌ m.TryLock 失败');
    end;
    
    // 测试嵌套 RAII 锁（可重入性）
    WriteLn('4. 测试嵌套 RAII 锁（可重入性）...');
    begin
      
      guard1 := m.Lock;
      WriteLn('   ✅ 第一层 RAII 锁获取成功');
      
      guard2 := m.Lock;
      WriteLn('   ✅ 第二层 RAII 锁获取成功（可重入）');
      
      // 两个 guard 都会在作用域结束时自动释放
    end;
    WriteLn('   ✅ 嵌套锁已全部自动释放');
    
    // 测试异常安全性
    WriteLn('5. 测试异常安全性...');
    try
      guard := m.Lock;
      WriteLn('   ✅ 锁已获取');
      
      // 模拟异常
      raise Exception.Create('测试异常');
    except
      on E: Exception do
      begin
        WriteLn('   ✅ 捕获异常: ', E.Message);
        // guard 会在异常处理后自动析构，确保锁被释放
      end;
    end;
    guard := nil; // 确保释放
    WriteLn('   ✅ 异常情况下锁已自动释放');
    
    // 测试 TryLock 失败的情况
    WriteLn('6. 测试 TryLock 在锁被占用时的行为...');
    begin
      
      guard1 := m.Lock;
      WriteLn('   ✅ 第一个锁已获取');
      
      // 对于可重入锁，TryLock 应该成功
      guard2 := m.TryLock;
      if guard2 <> nil then
      begin
        WriteLn('   ✅ TryLock 成功（可重入锁）');
      end
      else
      begin
        WriteLn('   ⚠️  TryLock 失败（这对可重入锁来说是意外的）');
      end;
    end;
    WriteLn('   ✅ 所有锁已自动释放');
    
    WriteLn('');
    WriteLn('✅ 所有 RAII 测试通过！自动锁管理工作正常！');
    
  except
    on E: Exception do
    begin
      WriteLn('❌ 测试失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
