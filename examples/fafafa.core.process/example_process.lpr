program example_process;

{**
 * fafafa.core.process 示例程序
 *
 * 本示例演示了 fafafa.core.process 模块的典型用法，包括：
 * - 基本进程启动和等待
 * - 参数传递和环境变量设置
 * - 标准流重定向和数据交互
 * - 进程优先级和窗口状态控制
 * - 错误处理和异常管理
 *
 * 编译要求：
 * - FreePascal 3.2.0+
 * - Lazarus IDE (可选)
 *
 * 使用方法：
 * 1. 编译：lazbuild example_process.lpi
 * 2. 运行：./example_process 或 example_process.exe
 *
 * 作者：fafafa.core 开发团队
 * 版本：1.0.0
 * 许可：MIT License
 *}

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils, Classes, DateUtils,
  fafafa.core.process,
  fafafa.core.args;

{**
 * 演示基本的进程启动和等待
 *}
procedure DemoBasicProcessExecution;
var
  LStartInfo: IProcessStartInfo;
  LProcess: IProcess;
  LResult: Boolean;
begin
  WriteLn('=== 演示1: 基本进程启动和等待 ===');

  // 创建进程启动配置
  LStartInfo := TProcessStartInfo.Create;
  {$IFDEF WINDOWS}
  LStartInfo.FileName := 'cmd.exe';
  LStartInfo.Arguments := '/c echo 你好，fafafa.core.process！';
  {$ELSE}
  LStartInfo.FileName := '/bin/echo';
  LStartInfo.Arguments := '你好，fafafa.core.process！';
  {$ENDIF}

  // 创建进程实例
  LProcess := TProcess.Create(LStartInfo);

  try
    WriteLn('✓ 启动进程: ', LStartInfo.FileName, ' ', LStartInfo.Arguments);

    // 启动进程
    LProcess.Start;
    WriteLn('✓ 进程已启动，PID: ', LProcess.ProcessId);

    // 等待进程完成
    LResult := LProcess.WaitForExit(5000); // 最多等待5秒

    if LResult then
    begin
      WriteLn('✓ 进程已完成，退出码: ', LProcess.ExitCode);
      WriteLn('✓ 运行时间: ', MilliSecondsBetween(LProcess.ExitTime, LProcess.StartTime), ' 毫秒');
    end
    else
    begin
      WriteLn('⚠ 进程执行超时');
      LProcess.Kill;
    end;

  except
    on E: Exception do
      WriteLn('❌ 错误: ', E.Message);
  end;

  WriteLn;
end;

{**
 * 演示参数传递和环境变量设置
 *}
procedure DemoArgumentsAndEnvironment;
var
  LStartInfo: IProcessStartInfo;
  LProcess: IProcess;
  LResult: Boolean;
begin
  WriteLn('=== 演示2: 参数传递和环境变量 ===');

  LStartInfo := TProcessStartInfo.Create;
  {$IFDEF WINDOWS}
  LStartInfo.FileName := 'cmd.exe';
  LStartInfo.Arguments := '/c echo 环境变量TEST_VAR的值是: %TEST_VAR%';
  {$ELSE}
  LStartInfo.FileName := '/bin/sh';
  LStartInfo.Arguments := '-c "echo 环境变量TEST_VAR的值是: $TEST_VAR"';
  {$ENDIF}

  // 设置自定义环境变量
  LStartInfo.SetEnvironmentVariable('TEST_VAR', 'Hello from fafafa.core.process!');
  LStartInfo.SetEnvironmentVariable('DEMO_MODE', 'true');

  LProcess := TProcess.Create(LStartInfo);

  try
    WriteLn('✓ 设置环境变量: TEST_VAR=', LStartInfo.GetEnvironmentVariable('TEST_VAR'));
    WriteLn('✓ 启动进程: ', LStartInfo.FileName);

    LProcess.Start;
    LResult := LProcess.WaitForExit(5000);

    if LResult then
      WriteLn('✓ 进程完成，退出码: ', LProcess.ExitCode)
    else
    begin
      WriteLn('⚠ 进程超时');
      LProcess.Kill;
    end;

  except
    on E: Exception do
      WriteLn('❌ 错误: ', E.Message);
  end;

  WriteLn;
end;

{**
 * 演示 UsePathSearch 的开启/关闭差异
 *}
procedure DemoUsePathSearch;
var
  P: IProcess;
begin
  WriteLn('=== 演示: UsePathSearch 开启/关闭 ===');
  {$IFDEF WINDOWS}
  // 开启 PATH 搜索：相对命令名可直接解析
  P := TProcessBuilder.Create
        .Executable('cmd')
        .Args(['/c','echo PATH 搜索开启'])
        .UsePathSearch(True)
        .Build;
  P.Start;
  P.WaitForExit(2000);

  // 关闭 PATH 搜索：相对命令名将失败（需要绝对路径）
  try
    P := TProcessBuilder.Create


          .Executable('cmd')
          .Args(['/c','echo PATH 搜索关闭'])
          .UsePathSearch(False)
          .Build;
    P.Start;
    WriteLn('⚠ 预期失败，但成功启动（请检查环境）');
  except
    on E: EProcessStartError do
      WriteLn('✓ 关闭搜索后，相对命令启动失败（预期）');
  end;
  {$ELSE}
  // Linux: /bin/echo 在 PATH 中；关闭搜索后需绝对路径
  P := TProcessBuilder.Create
        .Executable('echo')
        .Args(['PATH 搜索开启'])
        .UsePathSearch(True)
        .Build;
  P.Start;
  P.WaitForExit(2000);

  try
    P := TProcessBuilder.Create
          .Executable('echo')
          .Args(['PATH 搜索关闭'])
          .UsePathSearch(False)
          .Build;
    P.Start;
    WriteLn('⚠ 预期失败，但成功启动（请检查环境）');
  except
    on E: EProcessStartError do
      WriteLn('✓ 关闭搜索后，相对命令启动失败（预期）');
  end;
  {$ENDIF}
  WriteLn;
end;


{$IFDEF WINDOWS}
procedure DemoGroupPolicy;
var
  Policy: TProcessGroupPolicy;
  G: IProcessGroup;
  P: IProcess;
begin
  WriteLn('=== 演示: 进程组优雅终止策略（Windows） ===');
  Policy.EnableCtrlBreak := True;
  Policy.EnableWmClose := False;
  Policy.GracefulWaitMs := 500; // 演示用较短等待
  G := NewProcessGroup(Policy);

  P := NewProcessBuilder.Command('cmd.exe')
    .Args(['/c','ping','-n','5','127.0.0.1','>NUL'])
    .Build;
  P.Start;
  G.Add(P);
  WriteLn('✓ 进程已加入组，PID=', P.ProcessId);

  G.TerminateGroup(1);
  if P.WaitForExit(3000) then
    WriteLn('✓ 终止后已退出，ExitCode=', P.ExitCode)
  else
  begin
    WriteLn('⚠ 未在预期时间内退出，进行强制 Kill');
    P.Kill;
  end;
end;
{$ENDIF}


{**
 * 演示标准输出重定向和数据读取
 *}
procedure DemoOutputRedirection;
var
  LStartInfo: IProcessStartInfo;
  LProcess: IProcess;
  LResult: Boolean;
  LBuffer: array[0..1023] of Byte;
  LBytesRead: Integer;
  LOutput: string;
begin
  WriteLn('=== 演示3: 标准输出重定向 ===');

  LStartInfo := TProcessStartInfo.Create;
  {$IFDEF WINDOWS}
  LStartInfo.FileName := 'cmd.exe';
  LStartInfo.Arguments := '/c dir /b';  // 列出当前目录文件
  {$ELSE}
  LStartInfo.FileName := '/bin/ls';
  LStartInfo.Arguments := '-la';
  {$ENDIF}

  // 启用标准输出重定向
  LStartInfo.RedirectStandardOutput := True;

  LProcess := TProcess.Create(LStartInfo);

  try
    WriteLn('✓ 启动进程并重定向标准输出');

    LProcess.Start;
    LResult := LProcess.WaitForExit(5000);

    if LResult then
    begin
      WriteLn('✓ 进程完成，开始读取输出数据...');

      // 读取标准输出
      LOutput := '';
      if Assigned(LProcess.StandardOutput) then
      begin
        repeat
          LBytesRead := LProcess.StandardOutput.Read(LBuffer[0], SizeOf(LBuffer));
          if LBytesRead > 0 then
          begin
            SetLength(LOutput, Length(LOutput) + LBytesRead);
            Move(LBuffer[0], LOutput[Length(LOutput) - LBytesRead + 1], LBytesRead);
          end;
        until LBytesRead = 0;

        WriteLn('✓ 读取到 ', Length(LOutput), ' 字节的输出数据:');
        WriteLn('--- 输出开始 ---');
        Write(LOutput);
        WriteLn('--- 输出结束 ---');
      end
      else
        WriteLn('⚠ 标准输出流不可用');

      WriteLn;
  WriteLn('=== 演示3.1: stderr 合流到 stdout ===');
  try
    {$IFDEF WINDOWS}
    WriteLn(NewProcessBuilder.Command('cmd.exe')
      .Args(['/c','(echo OUT & echo ERR 1>&2)'])
      .StdErrToStdOut
      .CaptureStdOut
      .Output);
    {$ELSE}
    WriteLn(NewProcessBuilder.Command('/bin/sh')
      .Args(['-c','(echo OUT; echo ERR 1>&2)'])
      .StdErrToStdOut
      .CaptureStdOut
      .Output);
    {$ENDIF}
  except
    on E: Exception do WriteLn('❌ 合流演示失败: ', E.Message);
  end;

  WriteLn;
  WriteLn('=== 演示4.1: 超时便捷 API ===');
  try
    {$IFDEF WINDOWS}
    NewProcessBuilder.Command('cmd.exe').Args(['/c','timeout','/t','2','/nobreak']).RunWithTimeout(500);
    {$ELSE}
    NewProcessBuilder.Command('/bin/sh').Args(['-c','sleep 2']).RunWithTimeout(500);
    {$ENDIF}
  except
    on E: EProcessTimeoutError do WriteLn('✓ 超时捕获成功: ', E.Message);
    on E: Exception do WriteLn('❌ 非预期异常: ', E.Message);
  end;

    end
    else
    begin
      WriteLn('⚠ 进程超时');
      LProcess.Kill;
    end;

  except
    on E: Exception do
      WriteLn('❌ 错误: ', E.Message);
  end;

  WriteLn;
end;

{**
 * 演示标准输入重定向和数据写入
 *}
procedure DemoInputRedirection;
var
  LStartInfo: IProcessStartInfo;
  LProcess: IProcess;
  LResult: Boolean;
  LInputStream: TStringStream;
  LBuffer: array[0..1023] of Byte;
  LBytesRead: Integer;
  LOutput: string;
begin
  WriteLn('=== 演示4: 标准输入重定向 ===');

  LStartInfo := TProcessStartInfo.Create;
  {$IFDEF WINDOWS}
  LStartInfo.FileName := 'cmd.exe';
  LStartInfo.Arguments := '/c findstr "hello"';  // 查找包含hello的行
  {$ELSE}
  LStartInfo.FileName := '/bin/grep';
  LStartInfo.Arguments := 'hello';
  {$ENDIF}

  // 启用输入和输出重定向
  LStartInfo.RedirectStandardInput := True;
  LStartInfo.RedirectStandardOutput := True;

  LProcess := TProcess.Create(LStartInfo);

  try
    WriteLn('✓ 启动进程并重定向标准输入/输出');

    LProcess.Start;

    // 向标准输入写入测试数据
    if Assigned(LProcess.StandardInput) then
    begin
      LInputStream := TStringStream.Create('hello world' + #13#10 + 'test line' + #13#10 + 'hello fafafa' + #13#10);
      try
        LProcess.StandardInput.CopyFrom(LInputStream, 0);
        WriteLn('✓ 已写入 ', LInputStream.Size, ' 字节到标准输入');

        // 关闭输入流，让子进程知道没有更多输入
        LProcess.CloseStandardInput;
        WriteLn('✓ 输入流已关闭');
      finally
        LInputStream.Free;
      end;
    end;

    LResult := LProcess.WaitForExit(5000);

    if LResult then
    begin
      WriteLn('✓ 进程完成，读取过滤后的输出...');

      // 读取标准输出
      LOutput := '';
      if Assigned(LProcess.StandardOutput) then
      begin
        repeat
          LBytesRead := LProcess.StandardOutput.Read(LBuffer[0], SizeOf(LBuffer));
          if LBytesRead > 0 then
          begin
            SetLength(LOutput, Length(LOutput) + LBytesRead);
            Move(LBuffer[0], LOutput[Length(LOutput) - LBytesRead + 1], LBytesRead);
          end;
        until LBytesRead = 0;

        WriteLn('✓ 过滤结果:');
        WriteLn('--- 输出开始 ---');
        Write(LOutput);
        WriteLn('--- 输出结束 ---');
      end;
    end
    else
    begin
      WriteLn('⚠ 进程超时');
      LProcess.Kill;
    end;

  except
    on E: Exception do
      WriteLn('❌ 错误: ', E.Message);
  end;

  WriteLn;
end;

{**
 * 演示进程优先级和窗口状态控制
 *}
procedure DemoProcessPriorityAndWindow;
var
  LStartInfo: IProcessStartInfo;
  LProcess: IProcess;
  LResult: Boolean;
begin
  WriteLn('=== 演示5: 进程优先级和窗口状态 ===');

  LStartInfo := TProcessStartInfo.Create;
  {$IFDEF WINDOWS}
  LStartInfo.FileName := 'cmd.exe';
  LStartInfo.Arguments := '/c echo 高优先级进程执行中...';
  LStartInfo.WindowShowState := wsHidden;  // 隐藏窗口
  {$ELSE}
  LStartInfo.FileName := '/bin/echo';
  LStartInfo.Arguments := '高优先级进程执行中...';
  {$ENDIF}

  // 设置高优先级
  LStartInfo.Priority := ppHigh;

  LProcess := TProcess.Create(LStartInfo);

  try
    WriteLn('✓ 设置进程优先级为: 高');
    {$IFDEF WINDOWS}
    WriteLn('✓ 设置窗口状态为: 隐藏');
    {$ENDIF}

    LProcess.Start;
    WriteLn('✓ 进程已启动，PID: ', LProcess.ProcessId);

    LResult := LProcess.WaitForExit(5000);

    if LResult then
      WriteLn('✓ 高优先级进程完成，退出码: ', LProcess.ExitCode)
    else
    begin
      WriteLn('⚠ 进程超时');
      LProcess.Kill;
    end;

  except
    on E: Exception do
      WriteLn('❌ 错误: ', E.Message);
  end;

  WriteLn;
end;

{**
 * 演示错误处理和异常管理
 *}
procedure DemoErrorHandling;
var
  LStartInfo: IProcessStartInfo;
  LProcess: IProcess;
begin
  WriteLn('=== 演示6: 错误处理和异常管理 ===');

  // 测试1: 无效的可执行文件
  WriteLn('测试1: 启动不存在的可执行文件');
  LStartInfo := TProcessStartInfo.Create;
  LStartInfo.FileName := 'nonexistent_program_12345.exe';

  try
    LStartInfo.Validate;
    WriteLn('❌ 验证应该失败但没有失败');
  except
    on E: EProcessStartError do
      WriteLn('✓ 正确捕获到启动错误: ', E.Message);
    on E: Exception do
      WriteLn('⚠ 捕获到其他异常: ', E.Message);
  end;

  // 测试2: 无效的工作目录
  WriteLn('测试2: 设置不存在的工作目录');
  LStartInfo := TProcessStartInfo.Create;
  {$IFDEF WINDOWS}
  LStartInfo.FileName := 'cmd.exe';
  {$ELSE}
  LStartInfo.FileName := '/bin/echo';
  {$ENDIF}
  LStartInfo.WorkingDirectory := '/nonexistent/directory/12345';

  try
    LStartInfo.Validate;
    WriteLn('❌ 验证应该失败但没有失败');
  except
    on E: EProcessStartError do
      WriteLn('✓ 正确捕获到工作目录错误: ', E.Message);
    on E: Exception do
      WriteLn('⚠ 捕获到其他异常: ', E.Message);
  end;

  // 测试3: 在已终止进程上执行操作
  WriteLn('测试3: 在已终止进程上执行操作');
  LStartInfo := TProcessStartInfo.Create;
  {$IFDEF WINDOWS}
  LStartInfo.FileName := 'cmd.exe';
  LStartInfo.Arguments := '/c echo test';
  {$ELSE}
  LStartInfo.FileName := '/bin/echo';
  LStartInfo.Arguments := 'test';
  {$ENDIF}

  LProcess := TProcess.Create(LStartInfo);

  try
    LProcess.Start;
    LProcess.WaitForExit(5000);
    WriteLn('✓ 进程已正常完成');

    // 尝试在已终止的进程上执行Kill操作
    try
      LProcess.Kill;
      WriteLn('❌ Kill操作应该失败但没有失败');
    except
      on E: EProcessError do
        WriteLn('✓ 正确捕获到进程状态错误: ', E.Message);
      on E: Exception do
        WriteLn('⚠ 捕获到其他异常: ', E.Message);
    end;

  except
    on E: Exception do
      WriteLn('❌ 进程执行错误: ', E.Message);
  end;

  WriteLn;
end;

{**
 * 主程序入口
 *}
var
  opts: TArgsOptions;
  demo: string;
begin
  // 全局参数默认：支持 --no-xxx 取反
  opts := ArgsOptionsDefault;
  opts.EnableNoPrefixNegation := True;
  ArgsOptionsSetDefault(opts);

  // 读取 --demo=xxx 参数（默认空）
  demo := Args.Get('demo', '');

  WriteLn('fafafa.core.process 示例程序');
  WriteLn('================================');
  WriteLn('命令行：--demo=usepath|group|output|input|all');
  WriteLn;

  try
    if demo = 'usepath' then
    begin
      DemoUsePathSearch;
    end
    {$IFDEF WINDOWS}
    else if demo = 'group' then
    begin
      DemoGroupPolicy;
    end
    {$ENDIF}
    else if demo = 'output' then
    begin
      DemoOutputRedirection;
    end
    else if demo = 'input' then
    begin
      DemoInputRedirection;
    end
    else if demo = 'all' then
    begin
      DemoUsePathSearch;
      {$IFDEF WINDOWS}DemoGroupPolicy;{$ENDIF}
      DemoOutputRedirection;
      DemoInputRedirection;
    end
    else
    begin
      // 默认：执行原有全套演示
      DemoBasicProcessExecution;
      DemoArgumentsAndEnvironment;
      DemoOutputRedirection;
      DemoInputRedirection;
      DemoProcessPriorityAndWindow;
      DemoErrorHandling;
    end;

    WriteLn('=== 演示完成 ===');
  except
    on E: Exception do
    begin
      WriteLn('❌ 程序执行出错: ', E.Message);
      ExitCode := 1;
    end;
  end;

  ExitCode := 0;
end.
