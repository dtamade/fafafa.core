program test_reentrant;

{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex;

var
  Mutex: IMutex;
  Result1, Result2, Result3: Boolean;
begin
  WriteLn('测试 Mutex 重入行为');
  WriteLn('==================');
  
  Mutex := MakeMutex;
  
  // 第一次获取锁
  WriteLn('1. 第一次 TryAcquire...');
  Result1 := Mutex.TryAcquire;
  WriteLn('   结果: ', Result1);  // 应该是 True
  
  if Result1 then
  begin
    // 测试无参数版本的重入
    WriteLn('2. 重入测试 - TryAcquire() 无参数...');
    Result2 := Mutex.TryAcquire;
    WriteLn('   结果: ', Result2);  // 应该是 False
    
    // 测试带超时版本的重入
    WriteLn('3. 重入测试 - TryAcquire(100) 带超时...');
    Result3 := Mutex.TryAcquire(100);
    WriteLn('   结果: ', Result3);  // 问题：这里返回什么？
    
    // 释放锁
    Mutex.Release;
    WriteLn('4. 锁已释放');
  end;
  
  WriteLn;
  WriteLn('测试结论:');
  WriteLn('----------');
  if Result1 and (not Result2) then
  begin
    WriteLn('✓ TryAcquire() 无参数版本正确处理了重入（返回 False）');
  end;
  
  if Result1 and Result3 then
  begin
    WriteLn('✗ 问题: TryAcquire(100) 带超时版本在重入时返回了 True！');
    WriteLn('  这可能是因为实现有 bug 或者测试的期望值不正确');
  end
  else if Result1 and (not Result3) then
  begin
    WriteLn('✓ TryAcquire(100) 带超时版本正确处理了重入（返回 False）');
    WriteLn('  测试代码的期望值是正确的，实现也是正确的');
  end;
end.
