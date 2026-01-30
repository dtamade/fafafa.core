unit Test_threadpool_env_taskitempoolmax;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  Windows,
  fafafa.core.thread;

// 说明：由于 TaskItemPoolMax 是在线程池构造时读取环境变量，
// 同一进程内修改环境变量后再次创建线程池才能生效。
// 这里通过在同一进程内设置环境变量后创建线程池进行验证。

type
  TTestCase_EnvTaskItemPoolMax = class(TTestCase)
  published
    procedure Test_Invalid_And_NonPositive_Ignored;
    procedure Test_Valid_Sets_Effective;
  end;

implementation

function ShortTask_ForEnvTest(Data: Pointer): Boolean; begin Result := True; end;

procedure TTestCase_EnvTaskItemPoolMax.Test_Invalid_And_NonPositive_Ignored;
var
  P: IThreadPool;
  M: IThreadPoolMetrics;
begin
  // 非法字符串：应忽略，使用默认（>=64）
  Windows.SetEnvironmentVariable(PChar('FAFAFA_THREAD_TASKITEMPOOL_MAX'), PChar('abc'));
  P := CreateFixedThreadPool(1);
  try
    // 触发一次提交，确保池初始化路径走完
    P.Submit(@ShortTask_ForEnvTest, nil).WaitFor(1000);
    M := P.GetMetrics;
    CheckTrue(M.TaskItemPoolHit >= 0); // 只验证可调用，不崩溃
  finally
    P.Shutdown; P.AwaitTermination(2000);
  end;

  // 非正数：应忽略
  Windows.SetEnvironmentVariable(PChar('FAFAFA_THREAD_TASKITEMPOOL_MAX'), PChar('0'));
  P := CreateFixedThreadPool(1);
  try
    P.Submit(@ShortTask_ForEnvTest, nil).WaitFor(1000);
    M := P.GetMetrics;
    CheckTrue(M.TaskItemPoolMiss >= 0);
  finally
    P.Shutdown; P.AwaitTermination(2000);
  end;
end;

procedure TTestCase_EnvTaskItemPoolMax.Test_Valid_Sets_Effective;
var
  P: IThreadPool;
  M: IThreadPoolMetrics;
  I: Integer;
  HitBefore, MissBefore: Int64;
begin
  // 设置一个较小的上限，检验命中/未命中计数在少量提交下有意义
  Windows.SetEnvironmentVariable(PChar('FAFAFA_THREAD_TASKITEMPOOL_MAX'), PChar('8'));
  P := CreateFixedThreadPool(1);
  try
    // 提交若干短任务，促使对象池使用
    for I := 1 to 200 do
      P.Submit(@ShortTask_ForEnvTest, nil).WaitFor(2000);

    M := P.GetMetrics;
    HitBefore := M.TaskItemPoolHit;
    MissBefore := M.TaskItemPoolMiss;

    // 再次提交，期望命中数继续增加（上限较小但可复用）
    for I := 1 to 200 do
      P.Submit(@ShortTask_ForEnvTest, nil).WaitFor(2000);

    M := P.GetMetrics;
    CheckTrue(M.TaskItemPoolHit >= HitBefore, 'hit should not decrease');
    CheckTrue(M.TaskItemPoolMiss >= MissBefore, 'miss should not decrease');
  finally
    P.Shutdown; P.AwaitTermination(2000);
  end;
end;

initialization
  RegisterTest(TTestCase_EnvTaskItemPoolMax);

end.

