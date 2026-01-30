{$CODEPAGE UTF8}
program example_performance_comparison;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex;

const
  ITERATIONS = 1000000;  // 100万次操作

procedure BenchmarkMutex(const AName: string; AMutex: IMutex);
var
  LStart, LEnd: QWord;
  I: Integer;
  LElapsedMs: Double;
  LOpsPerSec: Double;
begin
  WriteLn('=== ', AName, ' 性能测试 ===');
  
  LStart := GetTickCount64;
  
  for I := 1 to ITERATIONS do
  begin
    AMutex.Acquire;
    // 模拟极短的临界区（空操作）
    AMutex.Release;
  end;
  
  LEnd := GetTickCount64;
  LElapsedMs := LEnd - LStart;
  LOpsPerSec := (ITERATIONS / LElapsedMs) * 1000;
  
  WriteLn('  迭代次数: ', ITERATIONS);
  WriteLn('  总耗时: ', LElapsedMs:0:2, ' ms');
  WriteLn('  平均每次: ', (LElapsedMs / ITERATIONS * 1000000):0:2, ' ns');
  WriteLn('  吞吐量: ', LOpsPerSec:0:0, ' ops/sec');
  WriteLn;
end;

procedure DemoPerformanceComparison;
var
  LPthreadMutex: IMutex;
  LFastMutex: IMutex;
begin
  WriteLn('=== Mutex 性能对比示例 ===');
  WriteLn;
  WriteLn('本示例对比 pthread_mutex 和 Futex 两种实现的性能差异');
  WriteLn('测试场景：极短临界区（空操作），强调锁本身的开销');
  WriteLn;
  
  // 测试 pthread_mutex（默认实现）
  LPthreadMutex := MakeMutex;
  BenchmarkMutex('pthread_mutex（默认，有重入检测）', LPthreadMutex);
  
  // 测试 Futex（高性能实现）
  {$IFDEF UNIX}
  {$IFDEF FAFAFA_CORE_USE_FUTEX}
  LFastMutex := MakeFutexMutex;
  BenchmarkMutex('Futex（高性能，无重入检测）', LFastMutex);
  {$ELSE}
  WriteLn('注意：Futex 实现未启用（FAFAFA_CORE_USE_FUTEX 宏未定义）');
  WriteLn('      当前 MakeFutexMutex 会回退到 pthread_mutex 实现');
  WriteLn;
  LFastMutex := MakeFutexMutex;
  BenchmarkMutex('MakeFutexMutex（回退到 pthread_mutex）', LFastMutex);
  {$ENDIF}
  {$ELSE}
  WriteLn('注意：Futex 仅在 Unix 平台可用');
  WriteLn('      Windows 平台使用 CRITICAL_SECTION 或 SRWLOCK');
  WriteLn;
  {$ENDIF}
  
  WriteLn('=== 性能分析 ===');
  WriteLn;
  WriteLn('预期结果：');
  WriteLn('  - pthread_mutex: 约 25-29 ns per lock/unlock');
  WriteLn('  - Futex: 约 20-25 ns per lock/unlock（快 10-20%）');
  WriteLn;
  WriteLn('选择建议：');
  WriteLn('  - 默认使用 MakeMutex（pthread_mutex）：');
  WriteLn('    ✅ 支持重入检测（安全）');
  WriteLn('    ✅ 符合 POSIX 标准');
  WriteLn('    ✅ 跨平台兼容性好');
  WriteLn('    ⚠️ 性能略低（但对大多数应用影响可忽略）');
  WriteLn;
  WriteLn('  - 性能敏感场景使用 MakeFutexMutex（Futex）：');
  WriteLn('    ✅ 高性能（快 10-20%）');
  WriteLn('    ⚠️ 不支持重入检测（会死锁）');
  WriteLn('    ⚠️ 需要代码保证不会重入');
  WriteLn;
  WriteLn('实际应用建议：');
  WriteLn('  - mutex 操作通常占总时间 < 1%');
  WriteLn('  - 10-20% 的性能差异对整体影响可忽略');
  WriteLn('  - 优先选择安全性（pthread_mutex）');
  WriteLn('  - 只有在明确的性能瓶颈时才考虑 Futex');
end;

procedure DemoReentryDetection;
var
  LPthreadMutex: IMutex;
  LFastMutex: IMutex;
begin
  WriteLn(#13#10'=== 重入检测对比 ===');
  WriteLn;
  
  // pthread_mutex：支持重入检测
  WriteLn('1. pthread_mutex（MakeMutex）：');
  LPthreadMutex := MakeMutex;
  LPthreadMutex.Acquire;
  try
    WriteLn('   第一次 Acquire 成功');
    try
      LPthreadMutex.Acquire;  // 尝试重入
      WriteLn('   ❌ 错误：第二次 Acquire 应该抛出异常');
    except
      on E: EDeadlockError do
        WriteLn('   ✅ 正确：捕获到 EDeadlockError - ', E.Message);
    end;
  finally
    LPthreadMutex.Release;
  end;
  WriteLn;
  
  // Futex：不支持重入检测
  {$IFDEF UNIX}
  {$IFDEF FAFAFA_CORE_USE_FUTEX}
  WriteLn('2. Futex（MakeFutexMutex）：');
  WriteLn('   ⚠️ 警告：Futex 不支持重入检测');
  WriteLn('   ⚠️ 如果尝试重入，程序会死锁（永远等待）');
  WriteLn('   ⚠️ 因此本示例不演示 Futex 的重入行为');
  WriteLn('   ⚠️ 使用 Futex 时必须确保代码不会重入');
  {$ELSE}
  WriteLn('2. MakeFutexMutex（回退到 pthread_mutex）：');
  WriteLn('   当前配置下，MakeFutexMutex 回退到 pthread_mutex');
  WriteLn('   因此行为与 MakeMutex 相同（支持重入检测）');
  {$ENDIF}
  {$ENDIF}
  WriteLn;
end;

begin
  try
    DemoPerformanceComparison;
    DemoReentryDetection;
    
    WriteLn('=== 示例完成 ===');
    WriteLn;
    WriteLn('更多信息请参考：');
    WriteLn('  - docs/fafafa.core.sync.mutex.md - API 文档');
    WriteLn('  - docs/MUTEX_IMPLEMENTATION.md - 实现说明');
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.ClassName, ' - ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
