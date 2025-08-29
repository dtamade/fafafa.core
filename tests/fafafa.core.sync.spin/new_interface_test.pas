program new_interface_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.spin.base,
  fafafa.core.sync.spin;

var
  L: ISpinLock;
  Policy: TSpinLockPolicy;
  NewPolicy: TSpinLockPolicy;

begin
  WriteLn('测试新增的接口方法...');
  
  // 1. 测试 GetPolicy 和 UpdatePolicy
  WriteLn('1. 测试策略获取和更新...');
  Policy := DefaultSpinLockPolicy;
  Policy.MaxSpins := 128;
  Policy.BackoffStrategy := sbsLinear;
  
  L := MakeSpinLock(Policy);
  
  // 获取策略并验证
  NewPolicy := L.GetPolicy;
  WriteLn('   原始 MaxSpins: ', Policy.MaxSpins);
  WriteLn('   获取的 MaxSpins: ', NewPolicy.MaxSpins);
  WriteLn('   原始 BackoffStrategy: ', Ord(Policy.BackoffStrategy));
  WriteLn('   获取的 BackoffStrategy: ', Ord(NewPolicy.BackoffStrategy));
  
  if (NewPolicy.MaxSpins = Policy.MaxSpins) and 
     (NewPolicy.BackoffStrategy = Policy.BackoffStrategy) then
    WriteLn('   ✓ GetPolicy 测试通过')
  else
    WriteLn('   ✗ GetPolicy 测试失败');
  
  // 更新策略
  NewPolicy.MaxSpins := 256;
  NewPolicy.BackoffStrategy := sbsExponential;
  L.UpdatePolicy(NewPolicy);
  
  Policy := L.GetPolicy;
  if (Policy.MaxSpins = 256) and (Policy.BackoffStrategy = sbsExponential) then
    WriteLn('   ✓ UpdatePolicy 测试通过')
  else
    WriteLn('   ✗ UpdatePolicy 测试失败');
  
  // 2. 测试 GetSpinCount 和 SetSpinCount
  WriteLn('2. 测试自旋次数获取和设置...');
  WriteLn('   当前 SpinCount: ', L.GetSpinCount);
  
  L.SetSpinCount(512);
  if L.GetSpinCount = 512 then
    WriteLn('   ✓ SetSpinCount/GetSpinCount 测试通过')
  else
    WriteLn('   ✗ SetSpinCount/GetSpinCount 测试失败');
  
  // 3. 测试 IsHeld
  WriteLn('3. 测试锁状态检测...');
  WriteLn('   获取锁前 IsHeld: ', L.IsHeld);
  
  L.Acquire;
  WriteLn('   获取锁后 IsHeld: ', L.IsHeld);
  
  L.Release;
  WriteLn('   释放锁后 IsHeld: ', L.IsHeld);
  
  // 4. 测试 GetOwnerThread
  WriteLn('4. 测试所有者线程获取...');
  WriteLn('   当前线程ID: ', GetCurrentThreadId);
  WriteLn('   锁的所有者线程ID: ', L.GetOwnerThread);
  
  L.Acquire;
  WriteLn('   获取锁后所有者线程ID: ', L.GetOwnerThread);
  L.Release;
  
  // 5. 测试 GetCurrentSpins
  WriteLn('5. 测试当前自旋次数...');
  WriteLn('   当前自旋次数: ', L.GetCurrentSpins);
  
  WriteLn('');
  WriteLn('新接口测试完成！');
end.
