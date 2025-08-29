program example_namedSemaphore_basic;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, Classes,
  fafafa.core.sync.namedSemaphore;

procedure DemoBasicUsage;
var
  LSemaphore: INamedSemaphore;
  LGuard: INamedSemaphoreGuard;
begin
  WriteLn('=== Basic Usage Demo ===');

  // Create named semaphore (default config: initial count 1, max count 1)
  LSemaphore := MakeNamedSemaphore('BasicSemaphoreDemo');
  WriteLn('Created semaphore: ', LSemaphore.GetName);
  WriteLn('Max count: ', LSemaphore.GetMaxCount);

  // Use RAII pattern to acquire semaphore
  WriteLn('Acquiring semaphore...');
  LGuard := LSemaphore.Wait;
  WriteLn('Successfully acquired semaphore, guard name: ', LGuard.GetName);

  // Simulate some work
  WriteLn('Executing critical section code...');
  Sleep(1000);

  // Guard will automatically release semaphore when it goes out of scope
  LGuard := nil;
  WriteLn('Semaphore automatically released');
  WriteLn;
end;

procedure DemoCountingSemaphore;
var
  LSemaphore: INamedSemaphore;
  LGuards: array[1..3] of INamedSemaphoreGuard;
  LGuard4: INamedSemaphoreGuard;
  LCurrentCount: Integer;
  I: Integer;
begin
  WriteLn('=== 计数信号量演示 ===');

  // 创建计数信号量：初始计数3，最大计数5
  LSemaphore := MakeCountingSemaphore('CountingSemaphoreDemo', 3, 5);
  WriteLn('创建计数信号量: ', LSemaphore.GetName);
  WriteLn('最大计数: ', LSemaphore.GetMaxCount);

  // 获取当前计数（如果平台支持）
  LCurrentCount := LSemaphore.GetCurrentCount;
  if LCurrentCount >= 0 then
    WriteLn('当前可用计数: ', LCurrentCount);

  // 获取多个信号量
  WriteLn('正在获取多个信号量...');
  for I := 1 to 3 do
  begin
    LGuards[I] := LSemaphore.TryWait;
    if Assigned(LGuards[I]) then
      WriteLn('成功获取第', I, '个信号量')
    else
      WriteLn('无法获取第', I, '个信号量');
  end;

  // 尝试获取第4个（应该失败）
  LGuard4 := LSemaphore.TryWait;
  if Assigned(LGuard4) then
    WriteLn('意外：获取了第4个信号量')
  else
    WriteLn('预期：无法获取第4个信号量（资源已耗尽）');

  // 释放一个信号量
  WriteLn('释放第1个信号量...');
  LGuards[1] := nil;

  // 现在应该能获取一个信号量
  LGuard4 := LSemaphore.TryWait;
  if Assigned(LGuard4) then
    WriteLn('成功：释放后获取了信号量')
  else
    WriteLn('错误：释放后仍无法获取信号量');

  // 清理
  for I := 2 to 3 do
    LGuards[I] := nil;
  LGuard4 := nil;

  WriteLn('所有信号量已释放');
  WriteLn;
end;

procedure DemoBinarySemaphore;
var
  LSemaphore: INamedSemaphore;
  LGuard1, LGuard2: INamedSemaphoreGuard;
begin
  WriteLn('=== 二进制信号量演示 ===');
  
  // 创建二进制信号量（类似互斥锁，但允许多次释放）
  LSemaphore := MakeBinarySemaphore('BinarySemaphoreDemo', True);
  WriteLn('创建二进制信号量: ', LSemaphore.GetName);
  WriteLn('最大计数: ', LSemaphore.GetMaxCount);
  
  // 第一次获取应该成功
  LGuard1 := LSemaphore.TryWait;
  if Assigned(LGuard1) then
    WriteLn('成功获取二进制信号量')
  else
    WriteLn('错误：无法获取二进制信号量');
  
  // 第二次获取应该失败
  LGuard2 := LSemaphore.TryWait;
  if Assigned(LGuard2) then
    WriteLn('错误：意外获取了第二个信号量')
  else
    WriteLn('预期：无法获取第二个信号量（二进制信号量特性）');
  
  // 释放信号量
  WriteLn('释放二进制信号量...');
  LGuard1 := nil;
  
  // 现在应该能获取
  LGuard2 := LSemaphore.TryWait;
  if Assigned(LGuard2) then
    WriteLn('成功：释放后获取了信号量')
  else
    WriteLn('错误：释放后仍无法获取信号量');
  
  LGuard2 := nil;
  WriteLn('二进制信号量已释放');
  WriteLn;
end;

procedure DemoTimeoutOperations;
var
  LSemaphore: INamedSemaphore;
  LGuard1, LGuard2: INamedSemaphoreGuard;
  LStartTime: TDateTime;
  LElapsed: Double;
begin
  WriteLn('=== 超时操作演示 ===');

  // 创建二进制信号量
  LSemaphore := MakeBinarySemaphore('TimeoutDemo', True);
  WriteLn('创建信号量用于超时测试');

  // 先获取信号量
  LGuard1 := LSemaphore.TryWait;
  WriteLn('第一个守卫已获取信号量');

  // 尝试带超时的获取（应该超时）
  WriteLn('尝试带超时获取（1秒超时）...');
  LStartTime := Now;
  LGuard2 := LSemaphore.TryWaitFor(1000); // 1秒超时

  if Assigned(LGuard2) then
    WriteLn('错误：意外获取了信号量')
  else
  begin
    LElapsed := (Now - LStartTime) * 24 * 60 * 60 * 1000; // 转换为毫秒
    WriteLn('预期：超时，耗时约 ', Round(LElapsed), ' 毫秒');
  end;

  // 释放第一个守卫
  WriteLn('释放第一个守卫...');
  LGuard1 := nil;

  // 现在带超时的获取应该立即成功
  WriteLn('再次尝试带超时获取...');
  LStartTime := Now;
  LGuard2 := LSemaphore.TryWaitFor(1000);

  if Assigned(LGuard2) then
  begin
    LElapsed := (Now - LStartTime) * 24 * 60 * 60 * 1000; // 转换为毫秒
    WriteLn('成功：立即获取了信号量，耗时 ', Round(LElapsed), ' 毫秒');
  end
  else
    WriteLn('错误：释放后仍无法获取信号量');

  LGuard2 := nil;
  WriteLn;
end;

procedure DemoErrorHandling;
var
  LSemaphore: INamedSemaphore;
begin
  WriteLn('=== 错误处理演示 ===');

  // 测试无效名称
  try
    MakeNamedSemaphore('');
    WriteLn('错误：应该抛出异常');
  except
    on E: Exception do
      WriteLn('预期异常：', E.ClassName, ' - ', E.Message);
  end;

  // 测试无效计数
  try
    MakeNamedSemaphore('InvalidCount', -1, 5);
    WriteLn('错误：应该抛出异常');
  except
    on E: Exception do
      WriteLn('预期异常：', E.ClassName, ' - ', E.Message);
  end;

  // 测试无效释放计数
  try
    LSemaphore := MakeNamedSemaphore('ValidSemaphore');
    LSemaphore.Release(0);
    WriteLn('错误：应该抛出异常');
  except
    on E: Exception do
      WriteLn('预期异常：', E.ClassName, ' - ', E.Message);
  end;

  WriteLn;
end;

procedure DemoMultipleRelease;
var
  LSemaphore: INamedSemaphore;
  LGuards: array[1..3] of INamedSemaphoreGuard;
  LGuard, LGuard4: INamedSemaphoreGuard;
  I: Integer;
begin
  WriteLn('=== 多重释放演示 ===');

  // 创建计数信号量，初始计数为0
  LSemaphore := MakeCountingSemaphore('MultiReleaseDemo', 0, 5);
  WriteLn('创建计数信号量（初始计数0，最大计数5）');

  // 尝试获取（应该失败）
  LGuard := LSemaphore.TryWait;
  if Assigned(LGuard) then
    WriteLn('错误：意外获取了信号量')
  else
    WriteLn('预期：无法获取信号量（计数为0）');

  // 释放3个计数
  WriteLn('释放3个计数...');
  LSemaphore.Release(3);

  // 现在应该能获取3个信号量
  WriteLn('尝试获取3个信号量...');
  for I := 1 to 3 do
  begin
    LGuards[I] := LSemaphore.TryWait;
    if Assigned(LGuards[I]) then
      WriteLn('成功获取第', I, '个信号量')
    else
      WriteLn('无法获取第', I, '个信号量');
  end;

  // 第4个应该失败
  LGuard4 := LSemaphore.TryWait;
  if Assigned(LGuard4) then
    WriteLn('错误：意外获取了第4个信号量')
  else
    WriteLn('预期：无法获取第4个信号量');

  // 清理
  for I := 1 to 3 do
    LGuards[I] := nil;

  WriteLn('所有信号量已释放');
  WriteLn;
end;

begin
  WriteLn('fafafa.core.sync.namedSemaphore Basic Usage Examples');
  WriteLn('====================================================');
  WriteLn;
  
  try
    DemoBasicUsage;
    DemoCountingSemaphore;
    DemoBinarySemaphore;
    DemoTimeoutOperations;
    DemoErrorHandling;
    DemoMultipleRelease;
    
    WriteLn('=== 所有演示完成 ===');
    WriteLn('命名信号量功能正常工作！');
    
  except
    on E: Exception do
    begin
      WriteLn('发生异常：', E.ClassName, ' - ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
