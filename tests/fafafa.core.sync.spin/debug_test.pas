program debug_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.spin;

var
  L: ISpinLock;

begin
  WriteLn('Testing Debug checks...');
  
  L := MakeSpinLock;
  
  // 正常使用
  WriteLn('1. Normal usage...');
  L.Acquire;
  L.Release;
  WriteLn('   OK');
  
  // 测试重入检测（应该在 Debug 模式下抛异常）
  WriteLn('2. Testing reentrancy detection...');
  L.Acquire;
  try
    try
      L.Acquire; // 这应该在 Debug 模式下抛异常
      WriteLn('   ERROR: Reentrancy not detected!');
    except
      on E: Exception do
        WriteLn('   OK: Caught reentrancy: ', E.Message);
    end;
  finally
    L.Release;
  end;
  
  // 测试错误释放检测（应该在 Debug 模式下抛异常）
  WriteLn('3. Testing wrong release detection...');
  try
    L.Release; // 这应该在 Debug 模式下抛异常
    WriteLn('   ERROR: Wrong release not detected!');
  except
    on E: Exception do
      WriteLn('   OK: Caught wrong release: ', E.Message);
  end;
  
  WriteLn('Debug test completed.');
end.
