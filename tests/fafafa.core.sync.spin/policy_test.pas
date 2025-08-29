program policy_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.sync.spin.base,
  fafafa.core.sync.spin;

var
  L1, L2, L3: ISpinLock;
  Policy: TSpinLockPolicy;

begin
  WriteLn('Testing SpinLock Policy Configuration...');
  
  // 测试默认策略
  WriteLn('1. Testing default policy...');
  L1 := MakeSpinLock;
  L1.Acquire;
  L1.Release;
  WriteLn('   OK: Default policy works');
  
  // 测试自定义策略 - 线性退避
  WriteLn('2. Testing linear backoff policy...');
  Policy := DefaultSpinLockPolicy;
  Policy.MaxSpins := 32;
  Policy.BackoffStrategy := sbsLinear;
  Policy.MaxBackoffMs := 8;
  Policy.EnableStats := False;
  
  L2 := MakeSpinLock(Policy);
  L2.Acquire;
  L2.Release;
  WriteLn('   OK: Linear backoff policy works');
  
  // 测试自定义策略 - 指数退避
  WriteLn('3. Testing exponential backoff policy...');
  Policy.BackoffStrategy := sbsExponential;
  Policy.MaxBackoffMs := 32;
  
  L3 := MakeSpinLock(Policy);
  L3.Acquire;
  L3.Release;
  WriteLn('   OK: Exponential backoff policy works');
  
  // 测试策略常量
  WriteLn('4. Testing policy constants...');
  WriteLn('   sbsLinear = ', Ord(sbsLinear));
  WriteLn('   sbsExponential = ', Ord(sbsExponential));
  WriteLn('   sbsAdaptive = ', Ord(sbsAdaptive));
  
  // 测试默认策略值
  WriteLn('5. Testing default policy values...');
  Policy := DefaultSpinLockPolicy;
  WriteLn('   MaxSpins = ', Policy.MaxSpins);
  WriteLn('   BackoffStrategy = ', Ord(Policy.BackoffStrategy));
  WriteLn('   MaxBackoffMs = ', Policy.MaxBackoffMs);
  WriteLn('   EnableStats = ', Policy.EnableStats);
  
  WriteLn('Policy configuration test completed successfully!');
end.
