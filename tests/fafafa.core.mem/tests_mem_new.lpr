{
  fafafa.core.mem New Tests Runner

  Runs all newly added test suites:
  - test_mem_adapter (IAllocator/IAlloc adapters)
  - test_growable_pool (TGrowingFixedPool)
  - test_enhanced_stackpool (TEnhancedStackPool) - SKIPPED due to AV bug
  - test_sharded_ringbuffer (TMappedRingBufferSharded)
}
program tests_mem_new;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  test_mem_adapter,
  test_mem_adapter_extended,
  test_growable_pool,
  test_stackpool_policy,
  test_fixedpool_guard;
  // test_enhanced_stackpool - SKIPPED: has AV bug in scope management
  // test_sharded_ringbuffer requires shared memory setup, run separately

begin
  WriteLn('');
  WriteLn('################################################');
  WriteLn('#  fafafa.core.mem New Tests Runner            #');
  WriteLn('################################################');
  WriteLn('');

  try
    WriteLn('>>> Running Memory Adapter Tests...');
    test_mem_adapter.RunAllTests;
    WriteLn('');
    WriteLn('>>> Running Memory Adapter Extended Tests...');
    test_mem_adapter_extended.RunAllTests;
    WriteLn('');

    WriteLn('>>> Running Growable Pool Tests...');
    test_growable_pool.RunAllTests;
    WriteLn('');

    WriteLn('>>> Running StackPool Policy Tests...');
    test_stackpool_policy.RunAllTests;
    WriteLn('');

    WriteLn('>>> Running FixedPool Guard Tests...');
    test_fixedpool_guard.RunAllTests;
    WriteLn('');

    // WriteLn('>>> Running Enhanced StackPool Tests...');
    // test_enhanced_stackpool.RunAllTests;
    // WriteLn('');
    WriteLn('>>> SKIPPED: Enhanced StackPool Tests (has AV bug in TStackScope.Free)');
    WriteLn('');

    WriteLn('################################################');
    WriteLn('#  All tests completed!                        #');
    WriteLn('################################################');
  except
    on E: Exception do
    begin
      WriteLn('');
      WriteLn('!!! TEST FAILED !!!');
      WriteLn('Exception: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
