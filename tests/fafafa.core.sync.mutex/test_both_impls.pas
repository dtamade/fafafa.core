program test_both_impls;

{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex.base,
  fafafa.core.sync.mutex.windows;

procedure TestImpl(const ImplName: string; Mutex: IMutex);
var
  Result1, Result2, Result3, Result4: Boolean;
begin
  WriteLn('测试实现: ', ImplName);
  WriteLn('=======================');
  
  // 第一次获取锁
  WriteLn('1. 第一次 TryAcquire()...');
  Result1 := Mutex.TryAcquire;
  WriteLn('   结果: ', Result1);  
  
  if Result1 then
  begin
    // 测试无参数版本的重入
    WriteLn('2. 重入测试 - TryAcquire() 无参数...');
    Result2 := Mutex.TryAcquire;
    WriteLn('   结果: ', Result2, ' (期望: False)');
    
    // 测试带零超时版本的重入
    WriteLn('3. 重入测试 - TryAcquire(0) 零超时...');
    Result3 := Mutex.TryAcquire(0);
    WriteLn('   结果: ', Result3, ' (期望: False)');
    
    // 测试带实际超时版本的重入
    WriteLn('4. 重入测试 - TryAcquire(100) 带超时...');
    Result4 := Mutex.TryAcquire(100);
    WriteLn('   结果: ', Result4, ' (期望: False)');
    
    // 释放锁
    Mutex.Release;
    WriteLn('5. 锁已释放');
  end;
  WriteLn;
end;

var
  CriticalSectionMutex: IMutex;
  {$IFDEF FAFAFA_CORE_USE_SRWLOCK}
  SRWMutex: IMutex;
  {$ENDIF}
begin
  WriteLn('Mutex 重入行为详细测试');
  WriteLn('======================');
  WriteLn;
  
  // 测试 CRITICAL_SECTION 实现
  WriteLn('--- CRITICAL_SECTION 实现 ---');
  CriticalSectionMutex := TMutex.Create;
  TestImpl('TMutex (CRITICAL_SECTION)', CriticalSectionMutex);
  
  {$IFDEF FAFAFA_CORE_USE_SRWLOCK}
  // 测试 SRWLOCK 实现
  WriteLn('--- SRWLOCK 实现 ---');
  SRWMutex := TSRWMutex.Create;
  TestImpl('TSRWMutex (SRWLOCK)', SRWMutex);
  {$ENDIF}
  
  WriteLn('测试完成');
end.
