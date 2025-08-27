{ fafafa.core.process.windows.inc }
{ 平台实现分离骨架（Windows） }

{ TODO: 后续将以下平台相关实现迁移至此文件，保持行为不变：
  - TProcess.StartWindows
  - TProcess.WaitForExitWindows
  - TProcess.KillWindows
  - TProcess.CreatePipesWindows
  - TProcess.ClosePipesWindows
  - TProcess.BuildCommandLineWindows
  - TProcess.BuildEnvironmentBlockWindows
}

{ 设计说明（仅注释，不含实现）：
  - 可执行路径解析（PATH + PATHEXT）：
    * 若 FileName 无路径分隔符，则按 PATH 搜索，并结合 PATHEXT(.EXE;.BAT;.CMD;...)
    * 若找到，返回绝对路径；否则按当前逻辑报错（保持兼容）
  - 命令行参数引号/转义（QuoteArgWindows）：
    * 与 CreateProcessW/CRT 兼容的反斜杠与双引号处理策略
    * 构建器 Arg/Args 将逐项处理；legacy 字符串 Arguments 暂保留原行为
  - 环境块构造（Unicode，双零终止）：
    * 名称排序、重复名称后写覆盖、允许空值
    * 仍支持“继承当前环境”当 Environment.Count=0
  - UseShellExecute：
    * v1 保留字段，不启用 ShellExecuteEx 分支
    * 如未来启用，需在文档与测试中明确其能力边界（工作目录/环境/控制台继承等）
}
{
  警告/提示净化说明：
  - 初始化 Hint：通过 FillChar 将 LStartupInfo/LProcessInfo 清零
  - 字符串转换 Warning：优先使用 UnicodeString，避免 WideString 隐式转换往返
  - 后续可引入 UTF8String 与 system codepage 转换策略，配合 SysUtils.UTF8Decode/Encode
}


{$IFDEF FAFAFA_PROCESS_SHELLEXECUTE_MINIMAL}
// 手动声明 Kernel32.GetProcessId，某些 FPC 版本未在 Windows 单元中暴露声明
function KernelGetProcessId(hProcess: THandle): DWORD; stdcall; external 'kernel32' name 'GetProcessId';
{$ENDIF}




function WinErrMsg(Err: DWORD): UnicodeString;
var
  buf: PWideChar = nil;
begin
  if FormatMessageW(FORMAT_MESSAGE_ALLOCATE_BUFFER or FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_IGNORE_INSERTS,
                    nil, Err, 0, @buf, 0, nil) <> 0 then
  begin
    try
      Result := buf;
    finally
      LocalFree(HLOCAL(buf));
    end;
  end
  else
    Result := UnicodeString('Unknown error');
end;

procedure TProcess.StartWindows;
var
  LStartupInfo: TStartupInfoW;
  LProcessInfo: TProcessInformation;
  LCommandLine: string;
  LWorkingDir: PWideChar;
  LEnvironment: Pointer;
  LCreationFlags: DWORD;
  LInheritHandles: LongBool; // 按需继承句柄（仅在重定向/合流时为 True）
  LMsgU: UnicodeString;
  {$IFDEF FAFAFA_PROCESS_SHELLEXECUTE_MINIMAL}
  Sei: TShellExecuteInfoW;
  {$ENDIF}
begin
  // 构建命令行
  LCommandLine := BuildCommandLineWindows;

  // 设置工作目录
  if FStartInfo.WorkingDirectory <> '' then
    LWorkingDir := PWideChar(UnicodeString(FStartInfo.WorkingDirectory))
  else
    LWorkingDir := nil;

  // 构建环境变量块
  LEnvironment := BuildEnvironmentBlockWindows;

  try
    // 设置创建标志
    LCreationFlags := CREATE_UNICODE_ENVIRONMENT;
    case FStartInfo.Priority of
      ppIdle: LCreationFlags := LCreationFlags or IDLE_PRIORITY_CLASS;
      ppBelowNormal: LCreationFlags := LCreationFlags or BELOW_NORMAL_PRIORITY_CLASS;
      ppNormal: LCreationFlags := LCreationFlags or NORMAL_PRIORITY_CLASS;
      ppAboveNormal: LCreationFlags := LCreationFlags or ABOVE_NORMAL_PRIORITY_CLASS;
      ppHigh: LCreationFlags := LCreationFlags or HIGH_PRIORITY_CLASS;
      ppRealTime: LCreationFlags := LCreationFlags or REALTIME_PRIORITY_CLASS;
    end;

    // 初始化启动信息（显式清零）
    FillChar(LStartupInfo, SizeOf(LStartupInfo), 0);
    LStartupInfo.cb := SizeOf(LStartupInfo);

    // 初始化进程信息（显式清零）
    FillChar(LProcessInfo, SizeOf(LProcessInfo), 0);

    // 设置窗口显示状态
    case FStartInfo.WindowShowState of
      wsHidden: LStartupInfo.wShowWindow := SW_HIDE;
      wsNormal: LStartupInfo.wShowWindow := SW_SHOWNORMAL;
      wsMinimized: LStartupInfo.wShowWindow := SW_SHOWMINIMIZED;
      wsMaximized: LStartupInfo.wShowWindow := SW_SHOWMAXIMIZED;
    end;
    LStartupInfo.dwFlags := STARTF_USESHOWWINDOW;

    // 设置流重定向
    if FStartInfo.RedirectStandardInput or FStartInfo.RedirectStandardOutput or FStartInfo.RedirectStandardError then
    begin
      LStartupInfo.dwFlags := LStartupInfo.dwFlags or STARTF_USESTDHANDLES;

      if FStartInfo.RedirectStandardInput then
        LStartupInfo.hStdInput := FInputPipeRead
      else
        LStartupInfo.hStdInput := GetStdHandle(STD_INPUT_HANDLE);

      if FStartInfo.RedirectStandardOutput then
        LStartupInfo.hStdOutput := FOutputPipeWrite
      else
        LStartupInfo.hStdOutput := GetStdHandle(STD_OUTPUT_HANDLE);

      if FStartInfo.StdErrToStdOut and FStartInfo.RedirectStandardOutput then
        // 合流：stderr 指向与 stdout 相同的句柄
        LStartupInfo.hStdError := FOutputPipeWrite
      else if FStartInfo.RedirectStandardError then
        LStartupInfo.hStdError := FErrorPipeWrite
      else
        LStartupInfo.hStdError := GetStdHandle(STD_ERROR_HANDLE);
    end;

    {$IFDEF FAFAFA_PROCESS_SHELLEXECUTE_MINIMAL}
    // 当启用最小 ShellExecuteEx 支持，且用户请求 UseShellExecute=True 且无任何重定向/自定义环境时
    if FStartInfo.UseShellExecute
       and not FStartInfo.RedirectStandardInput
       and not FStartInfo.RedirectStandardOutput
       and not FStartInfo.RedirectStandardError
       and not FStartInfo.StdErrToStdOut
       and (FStartInfo.Environment.Count = 0) then
    begin
      // 使用 ShellExecuteExW 启动（仅最小子集：不支持重定向/自定义环境）
      // 注意：需在 uses 中按条件引入 ShellApi
      // Pascal 在本模式下不允许在 begin..end 中声明变量，提前在过程顶部声明 Sei
      FillChar(Sei, SizeOf(Sei), 0);
      Sei.cbSize := SizeOf(Sei);
      Sei.fMask := SEE_MASK_NOCLOSEPROCESS;
      Sei.lpFile := PWideChar(UnicodeString(FStartInfo.FileName));
      if FStartInfo.Arguments <> '' then
        Sei.lpParameters := PWideChar(UnicodeString(FStartInfo.Arguments))
      else
        Sei.lpParameters := nil;
      if FStartInfo.WorkingDirectory <> '' then
        Sei.lpDirectory := PWideChar(UnicodeString(FStartInfo.WorkingDirectory))
      else
        Sei.lpDirectory := nil;
      case FStartInfo.WindowShowState of
        wsHidden:    Sei.nShow := SW_HIDE;
        wsNormal:    Sei.nShow := SW_SHOWNORMAL;
        wsMinimized: Sei.nShow := SW_SHOWMINNOACTIVE;
        wsMaximized: Sei.nShow := SW_SHOWMAXIMIZED;
      end;
      Sei.Wnd := 0;
      Sei.lpVerb := nil; // 默认 'open'

      if not ShellExecuteExW(@Sei) then
      begin
        LMsgU := UnicodeString('无法通过 ShellExecuteEx 启动进程: ') + UnicodeString(FStartInfo.FileName) +
          UnicodeString(' (错误 ') + UnicodeString(IntToStr(GetLastError)) + UnicodeString(': ') + WinErrMsg(GetLastError) + UnicodeString(')');
        raise EProcessStartError.Create(UTF8Encode(LMsgU));
      end;

      // 保存进程信息（ShellExecuteEx 只提供进程句柄；个别情况下可能返回 0）
      FProcessHandle := Sei.hProcess;
      FThreadHandle := 0;

      // 若 Shell 执行未返回进程句柄（极少数情况，如某些关联/动词），回退到 CreateProcessW 以确保可获取 PID
      if FProcessHandle = 0 then
      begin
        LInheritHandles := False;
        if not CreateProcessW(nil, PWideChar(UnicodeString(LCommandLine)), nil, nil, LInheritHandles,
                              LCreationFlags, LEnvironment, LWorkingDir, LStartupInfo, LProcessInfo) then
        begin
          LMsgU := UnicodeString('无法通过回退 CreateProcess 启动进程: ') + UnicodeString(FStartInfo.FileName) +
            UnicodeString(' (错误 ') + UnicodeString(IntToStr(GetLastError)) + UnicodeString(': ') + WinErrMsg(GetLastError) + UnicodeString(')');
          raise EProcessStartError.Create(UTF8Encode(LMsgU));
        end;
        FProcessHandle := LProcessInfo.hProcess;
        FThreadHandle := LProcessInfo.hThread;
        FProcessId := LProcessInfo.dwProcessId;
      end
      else
      begin
        {$IFDEF WINDOWS}
        try
          {$IFDEF FAFAFA_PROCESS_SHELLEXECUTE_MINIMAL}
          FProcessId := KernelGetProcessId(FProcessHandle);
          {$ELSE}
          FProcessId := 0; // 保守回退
          {$ENDIF}
        except
          FProcessId := 0;
        end;
        {$ENDIF}
      end;
    end
    else
    {$ENDIF}
    begin
      // 回退到 CreateProcessW 路径（支持重定向/环境块）
      // 仅在需要重定向（或 stderr 合流）时允许继承句柄，降低句柄泄漏风险
      LInheritHandles := (FStartInfo.RedirectStandardInput)
        or (FStartInfo.RedirectStandardOutput)
        or (FStartInfo.RedirectStandardError)
        or (FStartInfo.StdErrToStdOut and FStartInfo.RedirectStandardOutput);
      if not CreateProcessW(nil, PWideChar(UnicodeString(LCommandLine)), nil, nil, LInheritHandles,
                           LCreationFlags, LEnvironment, LWorkingDir, LStartupInfo, LProcessInfo) then
      begin
        LMsgU := UnicodeString('无法启动进程: ') + UnicodeString(FStartInfo.FileName) +
          UnicodeString(' (错误 ') + UnicodeString(IntToStr(GetLastError)) + UnicodeString(': ') + WinErrMsg(GetLastError) + UnicodeString(')');
        raise EProcessStartError.Create(UTF8Encode(LMsgU));
      end;

      // 保存进程信息
      FProcessHandle := LProcessInfo.hProcess;
      FThreadHandle := LProcessInfo.hThread;
      FProcessId := LProcessInfo.dwProcessId;
    end;

    // 设置进程状态为运行中
    FState := psRunning;

    // 关闭子进程端的管道句柄
    if FStartInfo.RedirectStandardInput then
      CloseHandle(FInputPipeRead);
    if FStartInfo.RedirectStandardOutput then
      CloseHandle(FOutputPipeWrite);
    if FStartInfo.RedirectStandardError and not (FStartInfo.StdErrToStdOut and FStartInfo.RedirectStandardOutput) then
      // 若已合流到 stdout，同一个句柄不重复关闭
      CloseHandle(FErrorPipeWrite);


    // 后台排水线程统一由 EnsureAutoDrainOnWait 在 WaitForExit 前创建（带内存缓冲），
    // 以避免数据丢失与竞态。此处不再直接创建平台层读线程。
  finally
    if LEnvironment <> nil then
      FreeMem(LEnvironment);
  end;
end;

function SearchExecutableInPathWindows(const AFile: string): Boolean;
var
  LFoundLen: DWORD;
  LBuf: array[0..MAX_PATH] of WideChar;
  LPath, LPathExt, LExt: string;
  LExtList: TStringList;
  I: Integer;
begin
  Result := False;

  // 使用 PATH 显式搜索，避免 SearchPath 默认包含当前目录带来的安全风险
  LPath := SysUtils.GetEnvironmentVariable('PATH');

  // 首先尝试原始文件名（可能已经包含扩展名）
  LFoundLen := SearchPathW(PWideChar(UnicodeString(LPath)), PWideChar(UnicodeString(AFile)), nil,
    SizeOf(LBuf) div SizeOf(WideChar), @LBuf[0], nil);
  if LFoundLen <> 0 then
  begin
    Result := True;
    Exit;
  end;

  // 如果文件名已经有扩展名，不再尝试其他扩展名
  if ExtractFileExt(AFile) <> '' then
    Exit;

  // 获取 PATHEXT 环境变量
  LPathExt := SysUtils.GetEnvironmentVariable('PATHEXT');
  if LPathExt = '' then
    LPathExt := '.COM;.EXE;.BAT;.CMD';  // Windows 默认值

  LExtList := TStringList.Create;
  try
    LExtList.Delimiter := ';';
    LExtList.StrictDelimiter := True;
    LExtList.DelimitedText := LPathExt;

    for I := 0 to LExtList.Count - 1 do
    begin
      LExt := Trim(LExtList[I]);
      if LExt = '' then Continue;

      // 尝试带扩展名的文件
      LFoundLen := SearchPathW(PWideChar(UnicodeString(LPath)), PWideChar(UnicodeString(AFile + LExt)), nil,
        SizeOf(LBuf) div SizeOf(WideChar), @LBuf[0], nil);
      if LFoundLen <> 0 then
      begin
        Result := True;
        Exit;
      end;
    end;
  finally
    LExtList.Free;
  end;
end;

function QuoteArgWindows(const S: string): string;
var
  I, Backslashes: Integer;
  NeedsQuotes: Boolean;
  Ch: Char;
begin
  NeedsQuotes := (Pos(' ', S) > 0) or (Pos(#9, S) > 0) or (S = '');
  if not NeedsQuotes then
  begin
    Result := S;
    Exit;
  end;
  Result := '"';
  Backslashes := 0;
  for I := 1 to Length(S) do

  begin
    Ch := S[I];
    if Ch = '\\' then
      Inc(Backslashes)
    else if Ch = '"' then
    begin
      Result := Result + string(StringOfChar(WideChar('\\'), Backslashes * 2 + 1)) + '"';
      Backslashes := 0;
    end
    else
    begin
      if Backslashes > 0 then
      begin
        Result := Result + string(StringOfChar(WideChar('\\'), Backslashes));
        Backslashes := 0;
      end;
      Result := Result + Ch;
    end;
  end;
  if Backslashes > 0 then
    Result := Result + string(StringOfChar(WideChar('\\'), Backslashes * 2));
  Result := Result + '"';
end;

function ParseArgumentsWindows(const aArguments: string; aArgs: TStrings): Boolean;
var
  I, J: Integer;
  S, Token: string;
begin
  aArgs.Clear;
  Result := False;
  S := Trim(aArguments);
  if S = '' then Exit;
  I := 1;
  while I <= Length(S) do
  begin
    while (I <= Length(S)) and (S[I] = ' ') do Inc(I);
    if I > Length(S) then Break;
    if S[I] = '"' then
    begin
      J := I + 1;
      while (J <= Length(S)) and (S[J] <> '"') do Inc(J);
      Token := Copy(S, I + 1, J - I - 1);
      aArgs.Add(Token);
      I := J + 1;
    end
    else begin
      J := I;
      while (J <= Length(S)) and (S[J] <> ' ') do Inc(J);
      Token := Copy(S, I, J - I);
      aArgs.Add(Token);
      I := J;
    end;
  end;
  Result := aArgs.Count > 0;
end;

function TProcess.BuildCommandLineWindows: string;
var
  LArgs: TStrings;
  I: Integer;
  LCmd: string;
  PSI: TProcessStartInfo;
begin
  // 文件名需要按需加引号
  LCmd := QuoteArgWindows(FStartInfo.FileName);

  // 优先使用强类型参数列表（避免对 Arguments 文本进行脆弱解析）
  PSI := nil;
  try
    PSI := FStartInfo as TProcessStartInfo;
  except
    PSI := nil;
  end;

  if (PSI <> nil) and (PSI.GetArgListRaw <> nil) and (PSI.GetArgListRaw.Count > 0) then
  begin
    LArgs := PSI.GetArgListRaw;
    for I := 0 to LArgs.Count - 1 do
      LCmd := LCmd + ' ' + QuoteArgWindows(LArgs[I]);
  end
  else if FStartInfo.Arguments <> '' then
  begin
    // 兼容旧的 Arguments 字符串：临时解析并构建
    LArgs := TStringList.Create;
    try
      if ParseArgumentsWindows(FStartInfo.Arguments, LArgs) then
        for I := 0 to LArgs.Count - 1 do
          LCmd := LCmd + ' ' + QuoteArgWindows(LArgs[I]);
    finally
      LArgs.Free;
    end;
  end;
  Result := LCmd;
end;


function TProcess.BuildEnvironmentBlockWindows: Pointer;
var
  LEnvSize: Integer;
  LEnvBlock: PWideChar;
  LIndex: Integer;
  LCurrentPos: PWideChar;
  LVarName, LVarValue, LEnvString: UnicodeString;
  LSortedVars: TStringList;
  LProcessedVars: TStringList;
begin
  Result := nil;

  if FStartInfo.Environment.Count = 0 then
    Exit; // 使用继承的环境变量

  // 创建排序和去重的环境变量列表（名称大小写不敏感；最后一次出现的值生效）
  LSortedVars := TStringList.Create;
  LProcessedVars := TStringList.Create;
  try
    // 不区分大小写排序
    LSortedVars.CaseSensitive := False;
    LProcessedVars.CaseSensitive := False;
    LSortedVars.Sorted := False;

    // 复制所有环境变量到临时列表
    for LIndex := 0 to FStartInfo.Environment.Count - 1 do
    begin
      LVarName := UnicodeString(FStartInfo.Environment.Names[LIndex]);
      LVarValue := UnicodeString(FStartInfo.Environment.ValueFromIndex[LIndex]);

      // 跳过空名称（已在 SetEnvironmentVariable 中验证）
      if (LVarName = '') then
        continue;

      LEnvString := LVarName + '=' + LVarValue;
      LSortedVars.Add(string(LEnvString));
    end;

    // 按环境变量名称排序（大小写不敏感）
    LSortedVars.CustomSort(
      function(List: TStringList; Index1, Index2: Integer): Integer
      var
        S1, S2: string;
        N1, N2: string;
        P: Integer;
      begin
        S1 := List[Index1];
        S2 := List[Index2];
        P := Pos('=', S1);
        if P > 0 then N1 := Copy(S1, 1, P - 1) else N1 := S1;
        P := Pos('=', S2);
        if P > 0 then N2 := Copy(S2, 1, P - 1) else N2 := S2;
        Result := AnsiCompareText(N1, N2);
      end
    );

    // 去重处理（最后一次出现的值生效），大小写不敏感匹配
    for LIndex := 0 to LSortedVars.Count - 1 do
    begin
      LEnvString := UnicodeString(LSortedVars[LIndex]);
      LVarName := Copy(LEnvString, 1, Pos('=', LEnvString) - 1);
      if LProcessedVars.IndexOfName(string(LVarName)) = -1 then
        LProcessedVars.Add(LSortedVars[LIndex])
      else
        LProcessedVars.Values[string(LVarName)] := Copy(string(LEnvString), Length(string(LVarName)) + 2, MaxInt);
    end;

    // 计算所需的内存大小
    LEnvSize := 0;
    for LIndex := 0 to LProcessedVars.Count - 1 do
    begin
      LEnvString := UnicodeString(LProcessedVars[LIndex]);
      LEnvSize := LEnvSize + Length(LEnvString) + 1; // +1 for null terminator
    end;
    LEnvSize := (LEnvSize + 1) * SizeOf(WideChar); // +1 for final null terminator

    // 分配内存
    GetMem(LEnvBlock, LEnvSize);
    try
      LCurrentPos := LEnvBlock;

      // 复制环境变量到内存块
      for LIndex := 0 to LProcessedVars.Count - 1 do
      begin
        LEnvString := UnicodeString(LProcessedVars[LIndex]);

        // 复制字符串内容
        Move(PWideChar(LEnvString)^, LCurrentPos^, Length(LEnvString) * SizeOf(WideChar));
        Inc(LCurrentPos, Length(LEnvString));

        // 添加字符串终止符
        LCurrentPos^ := #0;
        Inc(LCurrentPos);
      end;

      // 添加最终的双零终止符
      LCurrentPos^ := #0;

      Result := LEnvBlock;
    except
      FreeMem(LEnvBlock);
      raise;
    end;
  finally
    LSortedVars.Free;
    LProcessedVars.Free;
  end;
end;

procedure TProcess.CreatePipesWindows;
var
  LSecurityAttributes: TSecurityAttributes;
  LMsgU: UnicodeString;
begin
  // 设置安全属性，允许句柄继承
  LSecurityAttributes.nLength := SizeOf(TSecurityAttributes);
  LSecurityAttributes.lpSecurityDescriptor := nil;
  LSecurityAttributes.bInheritHandle := True;

  // 创建标准输入管道
  if FStartInfo.RedirectStandardInput then
  begin
    if not CreatePipe(FInputPipeRead, FInputPipeWrite, @LSecurityAttributes, 0) then
    begin
      LMsgU := '无法创建标准输入管道 (错误 ' + UnicodeString(IntToStr(GetLastError)) + ': ' + WinErrMsg(GetLastError) + ')';
      raise EProcessRedirectionError.Create(UTF8Encode(LMsgU));
    end;

    // 确保写入端不被子进程继承
    if not SetHandleInformation(FInputPipeWrite, HANDLE_FLAG_INHERIT, 0) then
      raise EProcessRedirectionError.Create(UTF8Encode(UnicodeString('无法设置输入管道属性')));
  end;

  // 创建标准输出管道
  if FStartInfo.RedirectStandardOutput then
  begin
    if not CreatePipe(FOutputPipeRead, FOutputPipeWrite, @LSecurityAttributes, 0) then
    begin
      LMsgU := '无法创建标准输出管道 (错误 ' + UnicodeString(IntToStr(GetLastError)) + ': ' + WinErrMsg(GetLastError) + ')';
      raise EProcessRedirectionError.Create(UTF8Encode(LMsgU));
    end;

    // 确保读取端不被子进程继承
    if not SetHandleInformation(FOutputPipeRead, HANDLE_FLAG_INHERIT, 0) then
      raise EProcessRedirectionError.Create(UTF8Encode(UnicodeString('无法设置输出管道属性')));
  end;

  // 创建标准错误管道
  if FStartInfo.RedirectStandardError then
  begin
    if not CreatePipe(FErrorPipeRead, FErrorPipeWrite, @LSecurityAttributes, 0) then
    begin
      LMsgU := '无法创建标准错误管道 (错误 ' + UnicodeString(IntToStr(GetLastError)) + ': ' + WinErrMsg(GetLastError) + ')';
      raise EProcessRedirectionError.Create(UTF8Encode(LMsgU));
    end;

    // 确保读取端不被子进程继承
    if not SetHandleInformation(FErrorPipeRead, HANDLE_FLAG_INHERIT, 0) then
      raise EProcessRedirectionError.Create(UTF8Encode(UnicodeString('无法设置错误管道属性')));
  end;
end;

function TProcess.WaitForExitWindows(aTimeoutMs: Cardinal): Boolean;
var
  LWaitResult: DWORD;
  LExitCode: DWORD;
  LDeadline: QWord;
  LRemaining: DWORD;
  LSlice: DWORD;
begin
  if FProcessHandle = 0 then
  begin
    Result := True; // 进程已经结束
    Exit;
  end;

  // 快速退出检测：若已能获取到非 STILL_ACTIVE 的退出码，则直接判定为已退出
  if GetExitCodeProcess(FProcessHandle, LExitCode) then
  begin
    if LExitCode <> STILL_ACTIVE then
    begin
      FExitCode := Integer(LExitCode);
      FExitTime := Now;
      FState := psExited;
      // 关闭句柄
      if FProcessHandle <> 0 then begin CloseHandle(FProcessHandle); FProcessHandle := 0; end;
      if FThreadHandle <> 0 then begin CloseHandle(FThreadHandle); FThreadHandle := 0; end;
      Result := True;
      Exit;
    end;
  end;

  {$IFDEF FAFAFA_PROCESS_VERBOSE_LOGGING}
  try
    WriteLn(StdErr, '[', FormatDateTime('hh:nn:ss.zzz', Now), '] [Process] Wait pid=', FProcessId,
      ' handle=', FProcessHandle, ' timeout=', aTimeoutMs);
    Flush(StdErr);
  except end;
  {$ENDIF}

  // 有限超时：切片等待 + 快速重试，增强 SEE_MASK_NOCLOSEPROCESS 句柄的稳定性
  if aTimeoutMs <> $FFFFFFFF then
  begin
    LDeadline := GetTickCount64 + QWord(aTimeoutMs);
    repeat
      // 再次快速检测退出
      if GetExitCodeProcess(FProcessHandle, LExitCode) and (LExitCode <> STILL_ACTIVE) then
      begin
        FExitCode := Integer(LExitCode);
        FExitTime := Now;
        FState := psExited;
        if FProcessHandle <> 0 then begin CloseHandle(FProcessHandle); FProcessHandle := 0; end;
        if FThreadHandle <> 0 then begin CloseHandle(FThreadHandle); FThreadHandle := 0; end;
        Result := True;
        Exit;
      end;

      if GetTickCount64 >= LDeadline then
      begin
        Result := False;
        Exit;
      end;

      // 计算剩余时间与等待切片（最大 10ms）
      LRemaining := DWORD(LDeadline - GetTickCount64);
      if LRemaining > 10 then LSlice := 10 else LSlice := LRemaining;

      LWaitResult := WaitForSingleObject(FProcessHandle, LSlice);
      if LWaitResult = WAIT_OBJECT_0 then
      begin
        // 成功：读取退出码并收尾
        if GetExitCodeProcess(FProcessHandle, LExitCode) then
          FExitCode := Integer(LExitCode)
        else
          FExitCode := -1;
        FExitTime := Now;
        FState := psExited;
        if FProcessHandle <> 0 then begin CloseHandle(FProcessHandle); FProcessHandle := 0; end;
        if FThreadHandle <> 0 then begin CloseHandle(FThreadHandle); FThreadHandle := 0; end;
        Result := True;
        Exit;
      end
      else if LWaitResult = WAIT_FAILED then
      begin
        // 等待失败：保守返回 False（不抛异常），交由上层重试或诊断
        Result := False;
        Exit;
      end;
      // WAIT_TIMEOUT：继续循环
    until False;
  end
  else
  begin
    // 无限等待路径：保持一次性等待
    LWaitResult := WaitForSingleObject(FProcessHandle, aTimeoutMs);
    Result := LWaitResult = WAIT_OBJECT_0;

    if Result then
    begin
      // 获取退出码
      if GetExitCodeProcess(FProcessHandle, LExitCode) then
        FExitCode := Integer(LExitCode)
      else
        FExitCode := -1;

      FExitTime := Now;
      FState := psExited;

      // 注意：不要在这里清理管道资源，因为用户可能还需要读取输出数据
      // 只清理进程句柄
      if FProcessHandle <> 0 then
      begin
        CloseHandle(FProcessHandle);
        FProcessHandle := 0;
      end;
      if FThreadHandle <> 0 then
      begin
        CloseHandle(FThreadHandle);
        FThreadHandle := 0;
      end;
    end;
  end;
end;

procedure TProcess.KillWindows;
var
  LMsgU: UnicodeString;
begin
  if FProcessHandle = 0 then
    Exit;

  if not TerminateProcess(FProcessHandle, 1) then
  begin
    LMsgU := UnicodeString('无法终止进程 (错误 ') + UnicodeString(IntToStr(GetLastError)) + UnicodeString(': ') + WinErrMsg(GetLastError) + UnicodeString(')');
    raise EProcessError.Create(UTF8Encode(LMsgU));
  end;

  FExitTime := Now;
  FState := psTerminated;
  FExitCode := 1;

  CleanupResources;
end;

procedure TProcess.CloseDrainThreadsWindows;
begin
  {$IFDEF WINDOWS}
  // 仅当存在对应后台排水线程时，才主动关闭读取端以触发线程退出。
  // 避免在未启用自动排水时过早关闭读取端，影响调用方后续读取。
  if Assigned(FDrainThreadOut) then
  begin
    if FOutputPipeRead <> 0 then
    begin
      CloseHandle(FOutputPipeRead);
      FOutputPipeRead := 0;
    end;
  end;
  if Assigned(FDrainThreadErr) then
  begin
    if FErrorPipeRead <> 0 then
    begin
      CloseHandle(FErrorPipeRead);
      FErrorPipeRead := 0;
    end;
  end;
  // 等待线程结束
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

procedure TProcess.ClosePipesWindows;
begin
  if FInputPipeRead <> 0 then
  begin
    CloseHandle(FInputPipeRead);
    FInputPipeRead := 0;
  end;
  if FInputPipeWrite <> 0 then
  begin
    CloseHandle(FInputPipeWrite);
    FInputPipeWrite := 0;
  end;
  if FOutputPipeRead <> 0 then
  begin
    CloseHandle(FOutputPipeRead);
    FOutputPipeRead := 0;
  end;
  if FOutputPipeWrite <> 0 then
  begin
    CloseHandle(FOutputPipeWrite);
    FOutputPipeWrite := 0;
  end;
  if FErrorPipeRead <> 0 then
  begin
    CloseHandle(FErrorPipeRead);
    FErrorPipeRead := 0;
  end;
  if FErrorPipeWrite <> 0 then
  begin
    CloseHandle(FErrorPipeWrite);
    FErrorPipeWrite := 0;
  end;
end;


