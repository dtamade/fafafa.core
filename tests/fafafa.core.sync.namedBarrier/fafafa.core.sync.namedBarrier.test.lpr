program fafafa.core.sync.namedBarrier.test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.base, fafafa.core.sync.namedBarrier;

procedure TestBasicCreation;
var
  LBarrier: INamedBarrier;
  LInfo: TNamedBarrierInfo;
begin
  WriteLn('测试基本创建功能...');
  try
    LBarrier := MakeNamedBarrier('test_barrier_1');
    if Assigned(LBarrier) then
    begin
      WriteLn('  ✓ 基本创建成功');
      LInfo := LBarrier.GetInfo;
      WriteLn('  - 名称: ', LInfo.Name);
      WriteLn('  - 参与者数量: ', LInfo.ParticipantCount);
      WriteLn('  - 等待者数量: ', LInfo.CurrentWaitingCount);
    end
    else
      WriteLn('  ✗ 基本创建失败');
  except
    on E: Exception do
      WriteLn('  ✗ 基本创建异常: ', E.Message);
  end;
  WriteLn;
end;

procedure TestConfiguredCreation;
var
  LBarrier: INamedBarrier;
  LInfo: TNamedBarrierInfo;
  LConfig: TNamedBarrierConfig;
begin
  WriteLn('测试配置创建功能...');
  try
    LConfig := NamedBarrierConfigWithParticipants(3);
    LBarrier := MakeNamedBarrier('test_barrier_2', LConfig);
    if Assigned(LBarrier) then
    begin
      WriteLn('  ✓ 配置创建成功');
      LInfo := LBarrier.GetInfo;
      WriteLn('  - 名称: ', LInfo.Name);
      WriteLn('  - 参与者数量: ', LInfo.ParticipantCount);
    end
    else
      WriteLn('  ✗ 配置创建失败');
  except
    on E: Exception do
      WriteLn('  ✗ 配置创建异常: ', E.Message);
  end;
  WriteLn;
end;

procedure TestSignalAndReset;
var
  LBarrier: INamedBarrier;
  LInfo: TNamedBarrierInfo;
begin
  WriteLn('测试信号和重置功能...');
  try
    LBarrier := MakeNamedBarrier('test_barrier_3', 2);
    if Assigned(LBarrier) then
    begin
      LInfo := LBarrier.GetInfo;
      WriteLn('  - 初始状态: ', BoolToStr(LInfo.IsSignaled, True));

      LBarrier.Signal;
      LInfo := LBarrier.GetInfo;
      WriteLn('  - 触发后状态: ', BoolToStr(LInfo.IsSignaled, True));

      LBarrier.Reset;
      LInfo := LBarrier.GetInfo;
      WriteLn('  - 重置后状态: ', BoolToStr(LInfo.IsSignaled, True));

      WriteLn('  ✓ 信号和重置功能正常');
    end
    else
      WriteLn('  ✗ 创建屏障失败');
  except
    on E: Exception do
      WriteLn('  ✗ 信号和重置异常: ', E.Message);
  end;
  WriteLn;
end;

procedure TestTryWait;
var
  LBarrier: INamedBarrier;
  LGuard: INamedBarrierGuard;
begin
  WriteLn('测试非阻塞等待功能...');
  try
    LBarrier := MakeNamedBarrier('test_barrier_4', 2);
    if Assigned(LBarrier) then
    begin
      // 测试未触发状态
      LGuard := LBarrier.TryWait;
      if not Assigned(LGuard) then
        WriteLn('  ✓ 未触发状态正确返回 nil')
      else
        WriteLn('  ✗ 未触发状态错误返回守卫');

      // 触发屏障后测试
      LBarrier.Signal;
      LGuard := LBarrier.TryWait;
      if Assigned(LGuard) then
      begin
        WriteLn('  ✓ 触发后正确返回守卫');
        WriteLn('  - 守卫是否为最后参与者: ', BoolToStr(LGuard.IsLastParticipant, True));
        WriteLn('  - 守卫代数: ', LGuard.GetGeneration);
        WriteLn('  - 守卫等待耗时(ms): ', LGuard.GetWaitTime);
      end
      else
        WriteLn('  ✗ 触发后错误返回 nil');
    end
    else
      WriteLn('  ✗ 创建屏障失败');
  except
    on E: Exception do
      WriteLn('  ✗ 非阻塞等待异常: ', E.Message);
  end;
  WriteLn;
end;

procedure TestErrorHandling;
begin
  WriteLn('测试错误处理功能...');

  // 测试无效名称
  try
    MakeNamedBarrier('');
    WriteLn('  ✗ 应该抛出无效名称异常');
  except
    on E: EInvalidArgument do
      WriteLn('  ✓ 正确捕获无效名称异常: ', E.Message);
    on E: Exception do
      WriteLn('  ? 意外异常类型: ', E.ClassName, ' - ', E.Message);
  end;

  // 测试无效参与者数量
  try
    MakeNamedBarrier('test_invalid', 1);
    WriteLn('  ✗ 应该抛出无效参与者数量异常');
  except
    on E: EInvalidArgument do
      WriteLn('  ✓ 正确捕获无效参与者数量异常: ', E.Message);
    on E: Exception do
      WriteLn('  ? 意外异常类型: ', E.ClassName, ' - ', E.Message);
  end;

  WriteLn;
end;

var
  LTestsPassed, LTestsTotal: Integer;

begin
  // 设置随机种子
  Randomize;

  WriteLn('fafafa.core.sync.namedBarrier 基本功能测试');
  WriteLn('==========================================');
  WriteLn;

  LTestsTotal := 5;
  LTestsPassed := 0;

  try
    TestBasicCreation;
    Inc(LTestsPassed);

    TestConfiguredCreation;
    Inc(LTestsPassed);

    TestSignalAndReset;
    Inc(LTestsPassed);

    TestTryWait;
    Inc(LTestsPassed);

    TestErrorHandling;
    Inc(LTestsPassed);

    WriteLn('==========================================');
    WriteLn('测试完成: ', LTestsPassed, '/', LTestsTotal, ' 通过');

    if LTestsPassed = LTestsTotal then
    begin
      WriteLn('✓ 所有基本功能测试通过！');
      ExitCode := 0;
    end
    else
    begin
      WriteLn('✗ 部分测试失败');
      ExitCode := 1;
    end;

  except
    on E: Exception do
    begin
      WriteLn('测试执行出错: ', E.ClassName, ' - ', E.Message);
      ExitCode := 1;
    end;
  end;

  WriteLn;
  WriteLn('注意：这些是基本功能测试，真正的屏障同步需要多个进程。');
  WriteLn('请运行跨进程示例来测试完整的屏障功能。');
end.
