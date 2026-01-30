program simple_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.sync.recMutex;

var
  RecMutex: IRecMutex;
  Result1, Result2: Boolean;

begin
  WriteLn('=== 简单的 RecMutex 测试 ===');
  
  // 创建锁
  WriteLn('1. 创建 RecMutex...');
  RecMutex := MakeRecMutex;
  WriteLn('   创建成功');
  
  // 测试基本的 TryAcquire
  WriteLn('2. 测试 TryAcquire()...');
  Result1 := RecMutex.TryAcquire;
  WriteLn('   TryAcquire() = ', Result1);
  if Result1 then
  begin
    WriteLn('   释放锁...');
    try
      RecMutex.Release;
      WriteLn('   释放成功');
    except
      on E: Exception do
        WriteLn('   释放失败: ', E.Message);
    end;
  end;
  
  WriteLn;
  
  // 测试 TryAcquire(0)
  WriteLn('3. 测试 TryAcquire(0)...');
  try
    Result2 := RecMutex.TryAcquire(0);
    WriteLn('   TryAcquire(0) = ', Result2);
    if Result2 then
    begin
      WriteLn('   释放锁...');
      try
        RecMutex.Release;
        WriteLn('   释放成功');
      except
        on E: Exception do
          WriteLn('   释放失败: ', E.Message);
      end;
    end;
  except
    on E: Exception do
      WriteLn('   TryAcquire(0) 异常: ', E.Message);
  end;
  
  WriteLn;
  
  // 测试 TryAcquire(100)
  WriteLn('4. 测试 TryAcquire(100)...');
  Result2 := RecMutex.TryAcquire(100);
  WriteLn('   TryAcquire(100) = ', Result2);
  if Result2 then
  begin
    WriteLn('   释放锁...');
    try
      RecMutex.Release;
      WriteLn('   释放成功');
    except
      on E: Exception do
        WriteLn('   释放失败: ', E.Message);
    end;
  end;
  
  WriteLn;
  WriteLn('=== 测试完成 ===');
end.
