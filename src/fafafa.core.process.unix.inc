{ fafafa.core.process.unix.inc }
{ 平台实现分离骨架（Unix/Linux） }

{ TODO: 后续将以下平台相关实现迁移至此文件，保持行为不变：
  - TProcess.StartUnix
  - TProcess.WaitForExitUnix
  - TProcess.KillUnix
  - TProcess.TerminateUnix
  - TProcess.CreatePipesUnix
  - TProcess.ClosePipesUnix
  - TProcess.BuildArgumentArrayUnix
  - TProcess.BuildEnvironmentArrayUnix
  - TProcess.FreeArgumentArrayUnix
  - TProcess.FreeEnvironmentArrayUnix
  - TProcess.ParseArgumentsUnix
}

{ 设计说明（仅注释，不含实现）：
  - 可执行路径解析（PATH 搜索 + 执行位检查）：
    * 若 FileName 非绝对/相对路径，则遍历 PATH 目录，要求具有可执行位
  - 参数传递：
    * 直接 argv/execve，避免 shell 参与；构建器 Arg/Args 逐项形成 argv
  - 环境变量：
    * 复用当前进程环境（Environment.Count=0）或使用指定键值集合
  - UseShellExecute：
    * v1 不启用；如未来启用，将以 /bin/sh -c path 形式另行设计，并在文档/测试中界定边界
}
{
  实现策略注释：
  - PATH 搜索：若 FileName 无分隔符，遍历 PATH，要求 Stat 可执行；失败则按既有逻辑抛错
  - 参数 argv：构建器 Arg/Args 逐项加入；legacy Arguments 解析保守，按引号与反斜杠最小规则
  - 环境继承：Environment.Count=0 时继承当前进程环境；否则使用提供的键值集合
}

function SearchExecutableInPathUnix(const AFile: string): Boolean;
var
  LPath, LDir, LFull: string;
  I: Integer;
  LDirs: TStringList;
begin
  // 获取 PATH 环境变量
  LPath := SysUtils.GetEnvironmentVariable('PATH');
  if LPath = '' then
  begin
    Result := False;
    Exit;
  end;

  Result := False;
  LDirs := TStringList.Create;
  try
    LDirs.Delimiter := ':';
    LDirs.StrictDelimiter := True;
    LDirs.DelimitedText := LPath;  // Unix 系统 PATH 本来就是用 : 分隔的

    for I := 0 to LDirs.Count - 1 do
    begin
      LDir := Trim(LDirs[I]);
      if LDir = '' then Continue;

      LFull := IncludeTrailingPathDelimiter(LDir) + AFile;

      // 检查文件是否存在且可执行
      if (fpaccess(PAnsiChar(AnsiString(LFull)), F_OK) = 0) and
         (fpaccess(PAnsiChar(AnsiString(LFull)), X_OK) = 0) then
      begin
        Result := True;
        Exit;
      end;
    end;
  finally
    LDirs.Free;
  end;
end;


{$IFDEF FAFAFA_PROCESS_USE_POSIX_SPAWN}
// M2: posix_spawnp + file_actions 重定向（最小实现）
// 注意：仅在 UNIX 且定义 FAFAFA_PROCESS_USE_POSIX_SPAWN 时编译；默认关闭，不影响现有行为。

// C 绑定（最小子集）
function posix_spawnp(var pid: TPid; path: PChar; file_actions: Pointer; attrp: Pointer; argv: PPChar; envp: PPChar): LongInt; cdecl; external 'c' name 'posix_spawnp';
{$IFDEF FAFAFA_POSIX_SPAWN_FILE_ACTIONS}
function posix_spawn_file_actions_init(var actions: Pointer): LongInt; cdecl; external 'c' name 'posix_spawn_file_actions_init';
function posix_spawn_file_actions_destroy(var actions: Pointer): LongInt; cdecl; external 'c' name 'posix_spawn_file_actions_destroy';
function posix_spawn_file_actions_adddup2(var actions: Pointer; fd: LongInt; newfd: LongInt): LongInt; cdecl; external 'c' name 'posix_spawn_file_actions_adddup2';
function posix_spawn_file_actions_addclose(var actions: Pointer; fd: LongInt): LongInt; cdecl; external 'c' name 'posix_spawn_file_actions_addclose';
{$ENDIF}
{$IFDEF FAFAFA_POSIX_SPAWN_ATTR}
function posix_spawnattr_init(var attr: Pointer): LongInt; cdecl; external 'c' name 'posix_spawnattr_init';
function posix_spawnattr_destroy(var attr: Pointer): LongInt; cdecl; external 'c' name 'posix_spawnattr_destroy';
function posix_spawnattr_setflags(var attr: Pointer; flags: LongInt): LongInt; cdecl; external 'c' name 'posix_spawnattr_setflags';
{$IFDEF FAFAFA_POSIX_SPAWN_SETPGROUP}
function posix_spawnattr_setpgroup(var attr: Pointer; pgroup: LongInt): LongInt; cdecl; external 'c' name 'posix_spawnattr_setpgroup';
{$ENDIF}
{$ENDIF}
{$IFDEF FAFAFA_POSIX_SPAWN_FLAGS}
const
  POSIX_SPAWN_SETPGROUP = 1; // 默认占位：如平台不同，请在编译命令中覆写
{$ENDIF}

{$IFDEF FAFAFA_POSIX_SPAWN_CHDIR_NP}
function posix_spawn_file_actions_addchdir_np(var actions: Pointer; path: PChar): LongInt; cdecl; external 'c' name 'posix_spawn_file_actions_addchdir_np';
{$ENDIF}
{$ENDIF}

function TProcess.StartUnixUsingPosixSpawn: Boolean;
var
  LPid: TPid;
  LArgv: PPChar;
  LEnvp: PPChar;
  Rc: LongInt;
  Actions: Pointer;
  {$IFDEF FAFAFA_POSIX_SPAWN_ATTR}
  Attr: Pointer;
  Flags: LongInt;
  {$ENDIF}
  NeedStdIn, NeedStdOut, NeedStdErr, MergeErr: Boolean;
  DoRedirect: Boolean;
begin
  Result := False;

  // 工作目录处理：在后续 file_actions 分支中按能力判断并可能回退
  // 此处不提前退出

  // 构建 argv/envp（遵循现有逻辑）
  LArgv := BuildArgumentArrayUnix;
  if FStartInfo.Environment.Count > 0 then
    LEnvp := BuildEnvironmentArrayUnix
  else
    LEnvp := nil; // 继承环境

  NeedStdIn  := FStartInfo.RedirectStandardInput;
  NeedStdOut := FStartInfo.RedirectStandardOutput;
  MergeErr   := FStartInfo.StdErrToStdOut and FStartInfo.RedirectStandardOutput;
  NeedStdErr := (FStartInfo.RedirectStandardError) and (not MergeErr);
  DoRedirect := NeedStdIn or NeedStdOut or NeedStdErr or MergeErr;

  Actions := nil;
  {$IFDEF FAFAFA_POSIX_SPAWN_ATTR}
  Attr := nil;
  {$ENDIF}

  {$IFDEF FAFAFA_POSIX_SPAWN_ATTR}
  // 提前初始化 attr，并按需设置 PGID/flags（与 file_actions 解耦）
  if (Attr = nil) then
    if posix_spawnattr_init(Attr) <> 0 then Exit;
  Flags := 0;
  {$IFDEF FAFAFA_POSIX_SPAWN_FLAGS}
  Flags := Flags or POSIX_SPAWN_SETPGROUP;
  {$ENDIF}
  {$IFDEF FAFAFA_POSIX_SPAWN_SETPGROUP}
  // 将子进程置入以其 PID 为 PGID 的新进程组（PGID=0）
  if posix_spawnattr_setpgroup(Attr, 0) <> 0 then Exit;
  {$ENDIF}
  if posix_spawnattr_setflags(Attr, Flags) <> 0 then Exit;
  {$ENDIF}

  try
    {$IFDEF FAFAFA_POSIX_SPAWN_FILE_ACTIONS}
    if DoRedirect or (FStartInfo.WorkingDirectory <> '') then
    begin
      // 初始化 file_actions
      if posix_spawn_file_actions_init(Actions) <> 0 then Exit;

      // 重定向（如需）
      if DoRedirect then
      begin
        if NeedStdIn  then if posix_spawn_file_actions_adddup2(Actions, FInputPipe[0], 0) <> 0 then Exit;
        if NeedStdOut then if posix_spawn_file_actions_adddup2(Actions, FOutputPipe[1], 1) <> 0 then Exit;
        if MergeErr   then begin if posix_spawn_file_actions_adddup2(Actions, 1, 2) <> 0 then Exit; end
        else if NeedStdErr then if posix_spawn_file_actions_adddup2(Actions, FErrorPipe[1], 2) <> 0 then Exit;

	      // 加固：关闭不必要的 fd（最小化子进程可见句柄）。父侧应使用 CLOEXEC；此处补防御。
	      // 仅示例关闭与重定向相关的反向端。更多 fd 关闭需结合 fd 列表管理（后续迭代再加）。
	      if NeedStdIn then begin
	        // 子进程不需要输入写端
	        if posix_spawn_file_actions_addclose(Actions, FInputPipe[1]) <> 0 then Exit;
	      end;
	      if NeedStdOut then begin
	        // 子进程不需要输出读端
	        if posix_spawn_file_actions_addclose(Actions, FOutputPipe[0]) <> 0 then Exit;
	      end;
	      if NeedStdErr and (not MergeErr) then begin
	        // 子进程不需要错误读端
	        if posix_spawn_file_actions_addclose(Actions, FErrorPipe[0]) <> 0 then Exit;
	      end;

      end;

      // 工作目录（可选扩展，检测到支持时才添加）
      {$IFDEF FAFAFA_POSIX_SPAWN_CHDIR_NP}
      if (FStartInfo.WorkingDirectory <> '') then
      begin
        if posix_spawn_file_actions_addchdir_np(Actions, PChar(FStartInfo.WorkingDirectory)) <> 0 then Exit;
      end;
      {$ENDIF}

      {$ELSE}
      if (FStartInfo.WorkingDirectory <> '') then Exit; // 不支持 chdir_np 时回退
      {$ENDIF}
    end
    else
    begin
      Actions := nil; // 不需要 file_actions
    end;
    {$ELSE}
    // 未启用 file_actions 绑定时，不支持重定向/工作目录 -> 回退
    if DoRedirect or (FStartInfo.WorkingDirectory <> '') then Exit;
    {$ENDIF}

    // 调用 posix_spawnp（PATH 搜索由其处理）
    Rc := posix_spawnp(LPid, PChar(FStartInfo.FileName), Actions, {$IFDEF FAFAFA_POSIX_SPAWN_ATTR}Attr{$ELSE}nil{$ENDIF}, LArgv, LEnvp);
    if Rc <> 0 then Exit; // 回退
    {$IFDEF FAFAFA_POSIX_SPAWN_ATTR}
    // 销毁 attr（若已初始化）——占位
    if Attr <> nil then posix_spawnattr_destroy(Attr);
    {$ENDIF}


    // 成功：父进程关闭子端句柄，与现实现一致
    FProcessId_Unix := LPid;
    FProcessId := Cardinal(LPid);
    FState := psRunning;

    if NeedStdIn then fpclose(FInputPipe[0]);
    if NeedStdOut then fpclose(FOutputPipe[1]);
    if NeedStdErr then fpclose(FErrorPipe[1]);

    Result := True;
  finally
    {$IFDEF FAFAFA_POSIX_SPAWN_FILE_ACTIONS}
    if Actions <> nil then posix_spawn_file_actions_destroy(Actions);
    {$ENDIF}
    if LArgv <> nil then FreeArgumentArrayUnix(LArgv);
    if (LEnvp <> nil) then FreeEnvironmentArrayUnix(LEnvp);
  end;
end;
{$ENDIF}



procedure TProcess.StartUnix;
var
  LPid: TPid;
  LArgv: PPChar;
  LEnvp: PPChar;
begin
  // 构建参数数组
  LArgv := BuildArgumentArrayUnix;
  LEnvp := BuildEnvironmentArrayUnix;

  try
    // 使用 fork + exec 启动进程
    LPid := fpfork;

    if LPid = -1 then
      raise EProcessError.CreateFmt('无法创建子进程: %s', [StrError(fpgeterrno)])
    else if LPid = 0 then
    begin
      // 子进程
      try
        {$IFDEF FAFAFA_PROCESS_GROUPS}
        // 将子进程置入以自身 PID 为 PGID 的新进程组，便于后续统一 killpg
        // 忽略失败（某些环境可能返回 EPERM/EINVAL）
        fpSetpgid(0, 0);
        {$ENDIF}

        // 设置流重定向
        if FStartInfo.RedirectStandardInput then
        begin
          fpclose(FInputPipe[1]);  // 关闭写入端
          fpdup2(FInputPipe[0], 0); // 重定向 stdin
          fpclose(FInputPipe[0]);
        end;

        if FStartInfo.RedirectStandardOutput then
        begin
          fpclose(FOutputPipe[0]); // 关闭读取端
          fpdup2(FOutputPipe[1], 1); // 重定向 stdout
          fpclose(FOutputPipe[1]);
        end;

        if FStartInfo.StdErrToStdOut and FStartInfo.RedirectStandardOutput then
        begin
          // 合流：stderr 指向 stdout 相同的 fd（1）
          fpdup2(1, 2);
        end
        else if FStartInfo.RedirectStandardError then
        begin
          fpclose(FErrorPipe[0]);  // 关闭读取端
          fpdup2(FErrorPipe[1], 2); // 重定向 stderr
          fpclose(FErrorPipe[1]);
        end;

        // 设置工作目录
        if FStartInfo.WorkingDirectory <> '' then
          fpchdir(FStartInfo.WorkingDirectory);

        // 执行程序
        fpexecve(FStartInfo.FileName, LArgv, LEnvp);

        // 如果到达这里，说明 exec 失败了
        fpwrite(2, 'exec failed'#10, 12);
        fpexit(127);
      except
        fpexit(127);
      end;
    end
    else
    begin
      // 父进程
      FProcessId_Unix := LPid;
      FProcessId := Cardinal(LPid);
      FState := psRunning;

      // 关闭子进程端的管道句柄
      if FStartInfo.RedirectStandardInput then
        fpclose(FInputPipe[0]);
      if FStartInfo.RedirectStandardOutput then
        fpclose(FOutputPipe[1]);
      if FStartInfo.RedirectStandardError and not (FStartInfo.StdErrToStdOut and FStartInfo.RedirectStandardOutput) then
        // 若已合流到 stdout，不重复关闭同一端
        fpclose(FErrorPipe[1]);
    end;

      // 启动后台排水线程（在启用 DrainOutput 且重定向时）
      if FStartInfo.RedirectStandardOutput and (FOutputPipe[0] <> -1) and FStartInfo.GetDrainOutput and (FDrainThreadOut = nil) then
      begin
        FDrainThreadOut := TThread.CreateAnonymousThread(
          procedure
          var
            Buf: array[0..4095] of Byte;
            N: ssize_t;
          begin
            while True do
            begin
              N := fpread(FOutputPipe[0], @Buf[0], SizeOf(Buf));
              if N <= 0 then Break; // EOF 或错误则退出
            end;
          end);
        FDrainThreadOut.FreeOnTerminate := False;
        FDrainThreadOut.Start;
      end;

      if FStartInfo.RedirectStandardError and (not FStartInfo.StdErrToStdOut) and (FErrorPipe[0] <> -1) and FStartInfo.GetDrainOutput and (FDrainThreadErr = nil) then
      begin
        FDrainThreadErr := TThread.CreateAnonymousThread(
          procedure
          var
            Buf: array[0..4095] of Byte;
            N: ssize_t;
          begin
            while True do
            begin
              N := fpread(FErrorPipe[0], @Buf[0], SizeOf(Buf));
              if N <= 0 then Break;
            end;
          end);
        FDrainThreadErr.FreeOnTerminate := False;
        FDrainThreadErr.Start;
      end;


  finally
    // 清理参数和环境变量数组
    if LArgv <> nil then
      FreeArgumentArrayUnix(LArgv);
    if LEnvp <> nil then
      FreeEnvironmentArrayUnix(LEnvp);
  end;
end;

function TProcess.WaitForExitUnix(aTimeoutMs: Cardinal): Boolean;
var
  LStatus: Integer;
  LResult: TPid;
  LStartTime: TDateTime;
  LElapsed: Integer;
begin
  Result := False;

  if FState in [psExited, psTerminated] then
  begin
    Result := True;
    Exit;
  end;

  LStartTime := Now;

  repeat
    // 非阻塞等待子进程
    LResult := fpwaitpid(FProcessId_Unix, @LStatus, WNOHANG);

    if LResult = FProcessId_Unix then
    begin
      // 进程已结束
      if WIFEXITED(LStatus) then
      begin
        FExitCode := WEXITSTATUS(LStatus);
        FState := psExited;
      end
      else if WIFSIGNALED(LStatus) then
      begin
        FExitCode := -WTERMSIG(LStatus);
        FState := psTerminated;
      end;

      FExitTime := Now;
      Result := True;

      // 只清理进程句柄，保留管道用于读取数据
      FProcessId_Unix := 0;
      Exit;
    end
    else if LResult = -1 then
    begin
      // 在某些并发 wait 条件下，可能已无子进程可等待（ECHILD），视为已退出
      if fpgeterrno = ECHILD then
      begin
        Result := True;
        Exit;
      end
      else
        raise EProcessError.CreateFmt('等待进程失败: %s', [StrError(fpgeterrno)]);
    end;

    // 检查超时
    if aTimeoutMs <> $FFFFFFFF then
    begin
      LElapsed := MilliSecondsBetween(Now, LStartTime);
      if LElapsed >= aTimeoutMs then
        Exit; // 超时
    end;

    // 短暂休眠避免忙等待（后续可改为 ppoll/pselect）
    Sleep(10);

  until False;
end;

procedure TProcess.KillUnix;
begin
  if FProcessId_Unix > 0 then
  begin
    // 发送 SIGKILL 信号进行强制终止
    if fpkill(FProcessId_Unix, SIGKILL) = -1 then
      raise EProcessError.CreateFmt('无法强制终止进程: %s', [StrError(fpgeterrno)]);

    FState := psTerminated;
    FExitTime := Now;
    FExitCode := -SIGKILL;
  end;
end;

procedure TProcess.TerminateUnix;
begin
  if FProcessId_Unix > 0 then
  begin
    // 发送 SIGTERM 信号进行优雅终止
    if fpkill(FProcessId_Unix, SIGTERM) = -1 then
      raise EProcessError.CreateFmt('无法优雅终止进程: %s', [StrError(fpgeterrno)]);

    FState := psTerminated;
    FExitTime := Now;
    FExitCode := -SIGTERM;
  end;
end;

procedure TProcess.CreatePipesUnix;
begin
  // 创建输入管道
  if FStartInfo.RedirectStandardInput then
  begin
    if fppipe(FInputPipe) = -1 then
      raise EProcessError.CreateFmt('创建输入管道失败: %s', [StrError(fpgeterrno)]);
  end;

  // 创建输出管道
  if FStartInfo.RedirectStandardOutput then
  begin
    if fppipe(FOutputPipe) = -1 then
    begin
      if FStartInfo.RedirectStandardInput then
      begin
        fpclose(FInputPipe[0]);
        fpclose(FInputPipe[1]);
      end;
      raise EProcessError.CreateFmt('创建输出管道失败: %s', [StrError(fpgeterrno)]);
    end;
  end;

  // 创建错误管道
  if FStartInfo.RedirectStandardError then
  begin
    if fppipe(FErrorPipe) = -1 then
    begin
      if FStartInfo.RedirectStandardInput then
      begin
        fpclose(FInputPipe[0]);
        fpclose(FInputPipe[1]);
      end;
      if FStartInfo.RedirectStandardOutput then
      begin
        fpclose(FOutputPipe[0]);
        fpclose(FOutputPipe[1]);
      end;
      raise EProcessError.CreateFmt('创建错误管道失败: %s', [StrError(fpgeterrno)]);
    end;
  end;
end;

procedure TProcess.CloseDrainThreadsUnix;
begin
  {$IFDEF UNIX}
  // 仅当存在对应后台排水线程时，才主动关闭读取端以促使线程退出。
  // 避免在未启用自动排水时过早关闭读取端，影响调用方后续读取。
  if Assigned(FDrainThreadOut) then
  begin
    if FOutputPipe[0] <> -1 then
    begin
      fpclose(FOutputPipe[0]);
      FOutputPipe[0] := -1;
    end;
  end;
  if Assigned(FDrainThreadErr) then
  begin
    if (not FStartInfo.StdErrToStdOut) and (FErrorPipe[0] <> -1) then
    begin
      fpclose(FErrorPipe[0]);
      FErrorPipe[0] := -1;
    end;
  end;

  if Assigned(FDrainThreadOut) then
  begin
    FDrainThreadOut.WaitFor;
    FreeAndNil(FDrainThreadOut);
  end;
  if Assigned(FDrainThreadErr) then
  begin
    FDrainThreadErr.WaitFor;
    FreeAndNil(FDrainThreadErr);
  end;
  {$ENDIF}
end;


procedure TProcess.ClosePipesUnix;
begin
  if FInputPipe[0] <> -1 then
  begin
    fpclose(FInputPipe[0]);
    FInputPipe[0] := -1;
  end;
  if FInputPipe[1] <> -1 then
  begin
    fpclose(FInputPipe[1]);
    FInputPipe[1] := -1;
  end;
  if FOutputPipe[0] <> -1 then
  begin
    fpclose(FOutputPipe[0]);
    FOutputPipe[0] := -1;
  end;
  if FOutputPipe[1] <> -1 then
  begin
    fpclose(FOutputPipe[1]);
    FOutputPipe[1] := -1;
  end;
  if FErrorPipe[0] <> -1 then
  begin
    fpclose(FErrorPipe[0]);
    FErrorPipe[0] := -1;
  end;
  if FErrorPipe[1] <> -1 then
  begin
    fpclose(FErrorPipe[1]);
    FErrorPipe[1] := -1;
  end;
end;

function TProcess.BuildArgumentArrayUnix: PPChar;
var
  LArgs: TStringList;
  LArgArray: PPChar;
  I: Integer;
begin
  LArgs := TStringList.Create;
  try
    // 添加程序名
    LArgs.Add(FStartInfo.FileName);

    // 解析参数字符串
    if FStartInfo.Arguments <> '' then
    begin
      ParseArgumentsUnix(FStartInfo.Arguments, LArgs);
    end;

    // 分配内存给参数数组
    GetMem(LArgArray, (LArgs.Count + 1) * SizeOf(PChar));

    // 复制参数
    for I := 0 to LArgs.Count - 1 do
    begin
      GetMem(LArgArray[I], Length(LArgs[I]) + 1);
      StrPCopy(LArgArray[I], LArgs[I]);
    end;

    // 最后一个元素必须是 nil
    LArgArray[LArgs.Count] := nil;

    Result := LArgArray;

  finally
    LArgs.Free;
  end;
end;

function TProcess.BuildEnvironmentArrayUnix: PPChar;
var
  LEnvList: TStringList;
  LEnvArray: PPChar;
  I: Integer;
  LEnvVar: string;
begin
  LEnvList := TStringList.Create;
  try
    // 如果有自定义环境变量，使用它们
    if FStartInfo.Environment.Count > 0 then
    begin
      for I := 0 to FStartInfo.Environment.Count - 1 do
      begin
        LEnvVar := FStartInfo.Environment.Names[I] + '=' + FStartInfo.Environment.ValueFromIndex[I];
        LEnvList.Add(LEnvVar);
      end;
    end
    else
    begin
      // 否则继承当前进程的环境变量
      for I := 1 to GetEnvironmentVariableCount do
      begin
        LEnvVar := GetEnvironmentString(I);
        if LEnvVar <> '' then
          LEnvList.Add(LEnvVar);
      end;
    end;

    // 分配内存给环境变量数组
    GetMem(LEnvArray, (LEnvList.Count + 1) * SizeOf(PChar));

    // 复制环境变量
    for I := 0 to LEnvList.Count - 1 do
    begin
      GetMem(LEnvArray[I], Length(LEnvList[I]) + 1);
      StrPCopy(LEnvArray[I], LEnvList[I]);
    end;

    // 最后一个元素必须是 nil
    LEnvArray[LEnvList.Count] := nil;

    Result := LEnvArray;

  finally
    LEnvList.Free;
  end;
end;

procedure TProcess.FreeArgumentArrayUnix(aArgv: PPChar);
var
  I: Integer;
begin
  if aArgv = nil then
    Exit;

  I := 0;
  while aArgv[I] <> nil do
  begin
    FreeMem(aArgv[I]);
    Inc(I);
  end;

  FreeMem(aArgv);
end;

procedure TProcess.FreeEnvironmentArrayUnix(aEnvp: PPChar);
var
  I: Integer;
begin
  if aEnvp = nil then
    Exit;

  I := 0;
  while aEnvp[I] <> nil do
  begin
    FreeMem(aEnvp[I]);
    Inc(I);
  end;

  FreeMem(aEnvp);
end;

procedure TProcess.ParseArgumentsUnix(const aArguments: string; aArgs: TStringList);
var
  I: Integer;
  LCurrentArg: string;
  LInQuotes: Boolean;
  LQuoteChar: Char;
  LChar: Char;
begin
  LCurrentArg := '';
  LInQuotes := False;
  LQuoteChar := #0;

  I := 1;
  while I <= Length(aArguments) do
  begin
    LChar := aArguments[I];

    if not LInQuotes then
    begin
      // 不在引号内
      if (LChar = '"') or (LChar = '''') then
      begin
        // 开始引号
        LInQuotes := True;
        LQuoteChar := LChar;
      end
      else if LChar = ' ' then
      begin
        // 空格分隔参数
        if LCurrentArg <> '' then
        begin
          aArgs.Add(LCurrentArg);
          LCurrentArg := '';
        end;
      end
      else
      begin
        // 普通字符
        LCurrentArg := LCurrentArg + LChar;
      end;
    end
    else
    begin
      // 在引号内
      if LChar = LQuoteChar then
      begin
        // 结束引号
        LInQuotes := False;
        LQuoteChar := #0;
      end
      else if (LChar = '\') and (I < Length(aArguments)) then
      begin
        // 转义字符
        Inc(I);
        if I <= Length(aArguments) then
          LCurrentArg := LCurrentArg + aArguments[I];
      end
      else
      begin
        // 引号内的普通字符
        LCurrentArg := LCurrentArg + LChar;
      end;
    end;

    Inc(I);
  end;

  // 添加最后一个参数
  if LCurrentArg <> '' then
    aArgs.Add(LCurrentArg);
end;



