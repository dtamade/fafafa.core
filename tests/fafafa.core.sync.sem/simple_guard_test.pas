{$CODEPAGE UTF8}
unit simple_guard_test;

{$mode objfpc}{$H+}

interface

procedure TestGuardMechanism;

implementation

uses
  fafafa.core.sync.sem;

procedure TestGuardMechanism;
var
  Sem: ISem;
  Guard: ISemGuard;
begin
  WriteLn('=== 信号量守卫机制测试 ===');
  
  // 创建信号量
  Sem := MakeSem(1, 3);
  WriteLn('1. 创建信号量: 初始=1, 最大=3');
  WriteLn('   可用许可: ', Sem.GetAvailableCount);
  
  // 获取守卫
  WriteLn('2. 获取守卫...');
  Guard := Sem.AcquireGuard;
  WriteLn('   获取后可用许可: ', Sem.GetAvailableCount);
  WriteLn('   守卫持有许可数: ', Guard.GetCount);
  
  // 手动释放
  WriteLn('3. 手动释放守卫...');
  Guard.Release;
  WriteLn('   释放后可用许可: ', Sem.GetAvailableCount);
  WriteLn('   守卫持有许可数: ', Guard.GetCount);
  
  WriteLn('4. 测试完成！');
end;

end.
