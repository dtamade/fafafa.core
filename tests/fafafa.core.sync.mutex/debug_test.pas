{$CODEPAGE UTF8}
program debug_test;

{$I fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex;

var
  Mutex: IMutex;
  Result1, Result2, Result3: Boolean;

begin
  WriteLn('调试测试开始...');
  
  Mutex := MakeMutex;
  
  WriteLn('1. 测试 TryAcquire() 无参数版本');
  Result1 := Mutex.TryAcquire();
  WriteLn('   第一次调用: ', Result1);
  
  if Result1 then
  begin
    Result2 := Mutex.TryAcquire();
    WriteLn('   重入调用: ', Result2);
    
    WriteLn('2. 测试 TryAcquire(0) 零超时版本');
    Result3 := Mutex.TryAcquire(0);
    WriteLn('   零超时重入调用: ', Result3);
    
    WriteLn('3. 测试 TryAcquire(100) 有超时版本');
    Result3 := Mutex.TryAcquire(100);
    WriteLn('   有超时重入调用: ', Result3);
    
    Mutex.Release;
  end;
  
  WriteLn('调试测试完成。');
  WriteLn('按回车键退出...');
  ReadLn;
end.
