unit fafafa.core.pipeline;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, DateUtils, SyncObjs,
  fafafa.core.base,
  fafafa.core.process;

type
  IPipeline = interface(IInterface)
  ['{E2B8C1D4-7A9F-4E13-8B6F-4F9D6F2A8C31}']
    function Start: IPipeline;
    function WaitForExit(aTimeoutMs: Cardinal = $FFFFFFFF): Boolean;
    function KillAll: IPipeline;
    function TerminateAll: IPipeline;
    function Status: Integer;
    function Success: Boolean;
    function Output: string;     // 末端 stdout（或合流后 stdout+stderr）
    function ErrorText: string;  // 末端 stderr（仅在 CaptureOutput=True 且 MergeStdErr=False 时有效）
    function OutputFilePath: string; // 当捕获介质为文件或 RedirectStdOutToFile 时返回路径，否则空
    function ErrorFilePath: string;  // 当 stderr 落盘（未合并）时返回路径，否则空
  end;

  IPipelineBuilder = interface(IInterface)
  ['{C6D6A5F1-5B8E-4A6A-9F5E-3E1D2C4B6A8F}']
    function Add(const aStage: IProcessBuilder): IPipelineBuilder; overload;
    function Add(const aExe: string; const aArgs: array of string): IPipelineBuilder; overload;
    function CaptureOutput(aEnable: Boolean = True): IPipelineBuilder;
    function FailFast(aEnable: Boolean = True): IPipelineBuilder;
    function MergeStdErr(aEnable: Boolean = True): IPipelineBuilder; // 仅影响末端捕获
    function RedirectStdOutToFile(const aPath: string; aAppend: Boolean = False): IPipelineBuilder;
    function RedirectStdErrToFile(const aPath: string; aAppend: Boolean = False): IPipelineBuilder;
    function CaptureThreshold(const aBytes: SizeInt): IPipelineBuilder; // 捕获阈值（字节）；超阈值自动落盘到临时文件
    function DeleteCapturedOnDestroy(aEnable: Boolean = True): IPipelineBuilder; // 捕获到临时文件时，析构是否删除（默认 True）
    function Build: IPipeline;
    function Start: IPipeline;
  end;

  TPipePump = class(TThread)
  private
    FSrc: TStream;
    FDest: TStream;
    FDestProc: IProcess;
    FSrcProc: IProcess;

    FWriteLock: TCriticalSection;

    FCloseDestOnEof: Boolean;
    FBuf: array[0..8191] of Byte;
  protected
    procedure Execute; override;
  public
    constructor Create(aSrc, aDest: TStream; aSrcProc, aDestProc: IProcess; aCloseDestOnEof: Boolean; aWriteLock: TCriticalSection = nil);
  end;

  TPipeline = class(TInterfacedObject, IPipeline)
  private
    FStages: array of IProcess;
    FPumps: array of TPipePump;
    FCaptureOutput: Boolean;
    FFailFast: Boolean;
    FMergeStdErr: Boolean;
    FCaptureThreshold: Int64;
    FDeleteTempOnDestroy: Boolean;
    FOutput: TStream;
    FErrOutput: TStream;
    FOutputFilePath: string;
    FErrFilePath: string;
    FOutputLock: TCriticalSection;
    FErrOutputLock: TCriticalSection;
    FOutFile: string;
    FOutAppend: Boolean;
    FErrFile: string;
    FErrAppend: Boolean;
    FOwnedStreams: array of TStream;
    procedure FinalizePumps;
  public
    constructor Create(const aStages: array of IProcess; aCaptureOutput, aFailFast, aMergeStdErr: Boolean;
      const aOutFile: string = ''; aOutAppend: Boolean = False;
      const aErrFile: string = ''; aErrAppend: Boolean = False);
    destructor Destroy; override;
    function Start: IPipeline;
    function WaitForExit(aTimeoutMs: Cardinal = $FFFFFFFF): Boolean;
    function KillAll: IPipeline;
    function TerminateAll: IPipeline;
    function Status: Integer;
    function Success: Boolean;
    function Output: string;
    function ErrorText: string;
    function OutputFilePath: string;
    function ErrorFilePath: string;
  end;

  TPipelineBuilder = class(TInterfacedObject, IPipelineBuilder)
  private
    FStages: array of IProcessBuilder;
    FCaptureOutput: Boolean;
    FFailFast: Boolean;
    FMergeStdErr: Boolean;
    FCaptureThreshold: Int64;
    FDeleteTempOnDestroy: Boolean;
    FOutFile: string;
    FOutAppend: Boolean;
    FErrFile: string;
    FErrAppend: Boolean;
  public
    function Add(const aStage: IProcessBuilder): IPipelineBuilder; overload;
    function Add(const aExe: string; const aArgs: array of string): IPipelineBuilder; overload;
    function CaptureOutput(aEnable: Boolean = True): IPipelineBuilder;
    function FailFast(aEnable: Boolean = True): IPipelineBuilder;
    function MergeStdErr(aEnable: Boolean = True): IPipelineBuilder;
    function RedirectStdOutToFile(const aPath: string; aAppend: Boolean = False): IPipelineBuilder;
    function RedirectStdErrToFile(const aPath: string; aAppend: Boolean = False): IPipelineBuilder;
    function CaptureThreshold(const aBytes: SizeInt): IPipelineBuilder;
    function DeleteCapturedOnDestroy(aEnable: Boolean = True): IPipelineBuilder;
    function Build: IPipeline;
    function Start: IPipeline;
  end;

function NewPipeline: IPipelineBuilder;


implementation
{$IFDEF FAFAFA_PROCESS_VERBOSE_LOGGING}
procedure __PipeDbg(const S: string);
var
  ts: string;
begin
  try
    ts := FormatDateTime('hh:nn:ss.zzz', Now);
    WriteLn(StdErr, '[', ts, '] [Pipeline] ', S);
    Flush(StdErr);
  except
  end;
end;
{$ENDIF}

function GetTempFileNameUTF8(const Prefix: string): string;
var
  G: TGUID;
  S: string;
begin
  CreateGUID(G);
  S := GUIDToString(G);
  S := StringReplace(S, '{', '', [rfReplaceAll]);
  S := StringReplace(S, '}', '', [rfReplaceAll]);
  S := StringReplace(S, '-', '', [rfReplaceAll]);
  Result := IncludeTrailingPathDelimiter(GetTempDir) + Prefix + S + '.tmp';
end;

{ TPipePump }

constructor TPipePump.Create(aSrc, aDest: TStream; aSrcProc, aDestProc: IProcess; aCloseDestOnEof: Boolean; aWriteLock: TCriticalSection);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FSrc := aSrc;
  FDest := aDest;
  FSrcProc := aSrcProc;
  FDestProc := aDestProc;
  FCloseDestOnEof := aCloseDestOnEof;
  FWriteLock := aWriteLock;
end;

procedure TPipePump.Execute;
var
  LRead: Integer;
  LZeroAfterExitCount: Integer;
  LZeroSpin: Integer;
begin
  {$IFDEF FAFAFA_PROCESS_VERBOSE_LOGGING}
  __PipeDbg('Pump thread enter');
  {$ENDIF}
  LZeroAfterExitCount := 0;
  LZeroSpin := 0;
  while not Terminated do
  begin
    LRead := 0;
    if FSrc <> nil then
      LRead := FSrc.Read(FBuf[0], SizeOf(FBuf));
    if LRead > 0 then
    begin
      LZeroAfterExitCount := 0;
      if FDest <> nil then
      begin
        if Assigned(FWriteLock) then FWriteLock.Enter;
        try
          FDest.WriteBuffer(FBuf[0], LRead)
        finally
          if Assigned(FWriteLock) then FWriteLock.Leave;
        end;
      end
      else
        Sleep(1);
    end
    else
    begin
      // 0 字节不一定是 EOF，可能是暂时无数据（或源进程已退出但管道仍有残留缓冲未到达 Read）
      if (FSrcProc <> nil) then
        FSrcProc.WaitForExit(0);
      {$IFDEF WINDOWS}
      // Windows: 不再在“已退出且本次读0”时立刻判 EOF，以免丢失尚未到达管道缓冲的数据；
      // 改为依赖“退出后连续两次读0”策略在下方统一关闭。
      {$ENDIF}
      {$IFDEF UNIX}
      // 在 Unix 下，如果源进程已退出且本次读取返回 0，则可视为 EOF，加速关闭下游 stdin 并退出泵
      if (FSrcProc <> nil) and (FSrcProc.HasExited) then
      begin
        if FCloseDestOnEof and (FDestProc <> nil) then
          FDestProc.CloseStandardInput;
        Break;
      end;
      {$ENDIF}
      if (FSrcProc <> nil) and (FSrcProc.HasExited) then
        Inc(LZeroAfterExitCount)
      else
        LZeroAfterExitCount := 0;

      // 防护：连续零读自旋计数，避免 FailFast/Kill 后状态未及时刷新导致泵长期自旋
      Inc(LZeroSpin);
      if LZeroSpin > 500 then
      begin
        {$IFDEF FAFAFA_PROCESS_VERBOSE_LOGGING}
        __PipeDbg('Pump breaking due to prolonged zero-read spin');
        {$ENDIF}
        if FCloseDestOnEof and (FDestProc <> nil) then
          FDestProc.CloseStandardInput;
        Break;
      end;

      if (LZeroAfterExitCount >= 2) then
      begin
        {$IFDEF FAFAFA_PROCESS_VERBOSE_LOGGING}
        __PipeDbg('Pump EOF confirmed (double zero after exit); closing dest stdin');
        {$ENDIF}
        if FCloseDestOnEof and (FDestProc <> nil) then
          FDestProc.CloseStandardInput;
        Break;
      end;
      Sleep(1);
    end;
  end;
  {$IFDEF FAFAFA_PROCESS_VERBOSE_LOGGING}
  __PipeDbg('Pump thread exit');
  {$ENDIF}
end;

{ TPipeline }

constructor TPipeline.Create(const aStages: array of IProcess; aCaptureOutput, aFailFast, aMergeStdErr: Boolean;
  const aOutFile: string; aOutAppend: Boolean; const aErrFile: string; aErrAppend: Boolean);
var
  I: Integer;
begin
  inherited Create;
  SetLength(FStages, Length(aStages));
  for I := 0 to High(aStages) do
    FStages[I] := aStages[I];
  SetLength(FPumps, 0);
  FCaptureOutput := aCaptureOutput;
  FFailFast := aFailFast;
  FMergeStdErr := aMergeStdErr;
  FOutFile := aOutFile;
  FOutAppend := aOutAppend;
  FErrFile := aErrFile;
  FErrAppend := aErrAppend;
  if FCaptureOutput then
  begin
    FOutput := TMemoryStream.Create;
    if not FMergeStdErr then
      FErrOutput := TMemoryStream.Create;
  end;
  FCaptureThreshold := 0; // 默认 0 表示不启用阈值落盘
  FDeleteTempOnDestroy := True; // 最佳实践：默认删除通过阈值创建的临时文件
  FOutputFilePath := '';
  FErrFilePath := '';
  FOutputLock := nil;
  FErrOutputLock := nil;
  SetLength(FOwnedStreams, 0);
end;

destructor TPipeline.Destroy;
var
  I: Integer;
begin
  for I := 0 to High(FPumps) do
    FPumps[I].Free;
  for I := 0 to High(FOwnedStreams) do
    FOwnedStreams[I].Free;
  if Assigned(FOutput) then
    FOutput.Free;
  if Assigned(FErrOutput) then
    FErrOutput.Free;
  if Assigned(FOutputLock) then
  // 删除临时文件（如有）
  try
    if FDeleteTempOnDestroy then
    begin
      if (FOutputFilePath <> '') and (FOutFile = '') then
        try DeleteFile(FOutputFilePath); except end;
      if (FErrFilePath <> '') and (FErrFile = '') and not (FCaptureOutput and FMergeStdErr) then
        try DeleteFile(FErrFilePath); except end;
    end;
  except end;

    FOutputLock.Free;
  if Assigned(FErrOutputLock) then
    FErrOutputLock.Free;
  inherited Destroy;
end;

function TPipeline.Start: IPipeline;
var
  I: Integer;
  LProcPrev, LProcCurr: IProcess;
  LPump: TPipePump;
  TempOut, TempErr: string;
begin
  for I := 0 to High(FStages) do
  begin
    // 标准输出重定向策略：
    // - 中间阶段必须重定向（供泵转发到下游 stdin）
    // - 末端阶段仅在需要捕获/重定向到文件时才重定向；否则继承父进程控制台，避免无人读取导致阻塞
    if I < High(FStages) then
    begin
      if not FStages[I].StartInfo.RedirectStandardOutput then
        FStages[I].StartInfo.RedirectStandardOutput := True;
    end
    else
    begin
      if (FCaptureOutput or (FOutFile <> '') or (FErrFile <> '')) then
      begin
        if not FStages[I].StartInfo.RedirectStandardOutput then
          FStages[I].StartInfo.RedirectStandardOutput := True;
      end;
      // 当需要合并或重定向错误流到文件/内存时，确保末端 stderr 也被重定向
      if (FCaptureOutput and FMergeStdErr) or (FErrFile <> '') then
      begin
        if not FStages[I].StartInfo.RedirectStandardError then
          FStages[I].StartInfo.RedirectStandardError := True;
      end;
    end;

    // 标准输入重定向策略：除第一阶段外，其余阶段需要从上游接收数据
    if (I > 0) and (not FStages[I].StartInfo.RedirectStandardInput) then
      FStages[I].StartInfo.RedirectStandardInput := True;

    {$IFDEF FAFAFA_PROCESS_VERBOSE_LOGGING}
    __PipeDbg(Format('Start stage %d: pid(before)=%d exe=%s args="%s"',[I, FStages[I].ProcessId, FStages[I].StartInfo.FileName, FStages[I].StartInfo.Arguments]));
    {$ENDIF}
    FStages[I].Start;
    {$IFDEF FAFAFA_PROCESS_VERBOSE_LOGGING}
    __PipeDbg(Format('Started stage %d: pid=%d',[I, FStages[I].ProcessId]));
    {$ENDIF}
  end;

  for I := 0 to High(FStages) - 1 do
  begin
    LProcPrev := FStages[I];
    LProcCurr := FStages[I+1];
    LPump := TPipePump.Create(LProcPrev.StandardOutput, LProcCurr.StandardInput, LProcPrev, LProcCurr, True);
    SetLength(FPumps, Length(FPumps) + 1);
    FPumps[High(FPumps)] := LPump;
    {$IFDEF FAFAFA_PROCESS_VERBOSE_LOGGING}
    __PipeDbg(Format('Pump %d->%d created',[I, I+1]));
    {$ENDIF}
    LPump.Start;
    {$IFDEF FAFAFA_PROCESS_VERBOSE_LOGGING}
    __PipeDbg(Format('Pump %d->%d started',[I, I+1]));
    {$ENDIF}
  end;

  // 末端处理：捕获或重定向到文件
  if (Length(FStages) > 0) then
  begin
    if (FOutFile <> '') or (FErrFile <> '') or FCaptureOutput then
    begin
      if (FOutFile <> '') and FCaptureOutput then
        raise Exception.Create('不能同时 CaptureOutput 与 RedirectStdOutToFile');
      if (FErrFile <> '') and (FCaptureOutput and not FMergeStdErr) then
        raise Exception.Create('CaptureOutput 仅支持合并 stderr（MergeStdErr=True）时一起捕获');

      // stdout → 文件或内存
      if FOutFile <> '' then
      begin
        if FOutAppend then
          LPump := TPipePump.Create(FStages[High(FStages)].StandardOutput, TFileStream.Create(FOutFile, fmCreate or fmOpenWrite or fmShareDenyNone), FStages[High(FStages)], nil, False)
        else
          LPump := TPipePump.Create(FStages[High(FStages)].StandardOutput, TFileStream.Create(FOutFile, fmCreate), FStages[High(FStages)], nil, False);
        SetLength(FOwnedStreams, Length(FOwnedStreams)+1);
        FOwnedStreams[High(FOwnedStreams)] := LPump.FDest;
        SetLength(FPumps, Length(FPumps) + 1);
        FPumps[High(FPumps)] := LPump;
        LPump.Start;
      end
      else if FCaptureOutput then
      begin
        // 阈值控制：如设置 FCaptureThreshold>0，则使用临时文件作为捕获介质
        if (FCaptureThreshold > 0) then
        begin
          // 将内存捕获替换为文件捕获（stdout），stderr 依据 FMergeStdErr 决定
          // 生成临时文件
          TempOut := GetTempFileNameUTF8('fafafa_pipeline_out_');
          TempErr := '';
          try
            // 先释放现有内存流以节省内存
            if Assigned(FOutput) then FreeAndNil(FOutput);
            if not FMergeStdErr then
            begin
              if Assigned(FErrOutput) then FreeAndNil(FErrOutput);
            end;

            // 创建文件流
            FOutput := TFileStream.Create(TempOut, fmCreate);
            FOutputFilePath := TempOut;
            if not FMergeStdErr then
            begin
              TempErr := GetTempFileNameUTF8('fafafa_pipeline_err_');
              FErrOutput := TFileStream.Create(TempErr, fmCreate);
              FErrFilePath := TempErr;
            end;

            // 泵到文件
            if FMergeStdErr then
            begin
              if not Assigned(FOutputLock) then FOutputLock := TCriticalSection.Create;
              LPump := TPipePump.Create(FStages[High(FStages)].StandardOutput, FOutput, FStages[High(FStages)], nil, False, FOutputLock);
              SetLength(FPumps, Length(FPumps) + 1);
              FPumps[High(FPumps)] := LPump; LPump.Start;
              LPump := TPipePump.Create(FStages[High(FStages)].StandardError, FOutput, FStages[High(FStages)], nil, False, FOutputLock);
              SetLength(FPumps, Length(FPumps) + 1);
              FPumps[High(FPumps)] := LPump; LPump.Start;
            end
            else
            begin
              LPump := TPipePump.Create(FStages[High(FStages)].StandardOutput, FOutput, FStages[High(FStages)], nil, False);
              SetLength(FPumps, Length(FPumps) + 1);
              FPumps[High(FPumps)] := LPump; LPump.Start;
              if Assigned(FErrOutput) then
              begin
                LPump := TPipePump.Create(FStages[High(FStages)].StandardError, FErrOutput, FStages[High(FStages)], nil, False);
                SetLength(FPumps, Length(FPumps) + 1);
                FPumps[High(FPumps)] := LPump; LPump.Start;
              end;
            end;

            // 无需记录到 FOwnedStreams；FOutput/FErrOutput 由字段本身在析构时释放，避免重复释放
          except
            // 若文件捕获初始化失败，回退内存捕获
            if Assigned(FOutput) then FreeAndNil(FOutput);
            if Assigned(FErrOutput) then FreeAndNil(FErrOutput);
            FOutput := TMemoryStream.Create;
            if not FMergeStdErr then FErrOutput := TMemoryStream.Create;
          end;
        end
        else
        begin
          if FMergeStdErr then
          begin
            if not Assigned(FOutputLock) then FOutputLock := TCriticalSection.Create;
            LPump := TPipePump.Create(FStages[High(FStages)].StandardOutput, FOutput, FStages[High(FStages)], nil, False, FOutputLock);
            SetLength(FPumps, Length(FPumps) + 1);
            FPumps[High(FPumps)] := LPump;
            LPump.Start;
            LPump := TPipePump.Create(FStages[High(FStages)].StandardError, FOutput, FStages[High(FStages)], nil, False, FOutputLock);
            SetLength(FPumps, Length(FPumps) + 1);
            FPumps[High(FPumps)] := LPump;
            LPump.Start;
          end
          else
          begin
            // 分路捕获：stdout → FOutput，stderr → FErrOutput
            LPump := TPipePump.Create(FStages[High(FStages)].StandardOutput, FOutput, FStages[High(FStages)], nil, False);
            SetLength(FPumps, Length(FPumps) + 1);
            FPumps[High(FPumps)] := LPump;
            LPump.Start;
            if Assigned(FErrOutput) then
            begin
              LPump := TPipePump.Create(FStages[High(FStages)].StandardError, FErrOutput, FStages[High(FStages)], nil, False);
              SetLength(FPumps, Length(FPumps) + 1);
              FPumps[High(FPumps)] := LPump;
              LPump.Start;
            end;
          end;
        end;
      end;

      // stderr → 文件（若未合并至内存）
      if (FErrFile <> '') and not (FCaptureOutput and FMergeStdErr) then
      begin
        if FErrAppend then
          LPump := TPipePump.Create(FStages[High(FStages)].StandardError, TFileStream.Create(FErrFile, fmCreate or fmOpenWrite or fmShareDenyNone), FStages[High(FStages)], nil, False)
        else
          LPump := TPipePump.Create(FStages[High(FStages)].StandardError, TFileStream.Create(FErrFile, fmCreate), FStages[High(FStages)], nil, False);
        SetLength(FOwnedStreams, Length(FOwnedStreams)+1);
        FOwnedStreams[High(FOwnedStreams)] := LPump.FDest;
        SetLength(FPumps, Length(FPumps) + 1);
        FPumps[High(FPumps)] := LPump;
        LPump.Start;
      end;
    end;
  end;

  Result := Self;
end;

function TPipeline.WaitForExit(aTimeoutMs: Cardinal): Boolean;
var
  I, J: Integer;
  LDeadline: QWord;
  LAllExited: Boolean;
  LStageExited: Boolean;
  LExitCode: Integer;
begin
  if aTimeoutMs = $FFFFFFFF then
  begin
    // 轮询等待，支持 FailFast；对每个阶段做一次非阻塞 WaitForExit(0) 以刷新状态
    {$IFDEF FAFAFA_PROCESS_VERBOSE_LOGGING}
    __PipeDbg('WaitForExit(INFINITE) enter');
    {$ENDIF}
    repeat
      LAllExited := True;
      for I := 0 to High(FStages) do
      begin
        LStageExited := FStages[I].HasExited;
        if not LStageExited then
        begin
          if not FStages[I].WaitForExit(0) then
            LAllExited := False
          else
            LStageExited := True;
        end;
        {$IFDEF FAFAFA_PROCESS_VERBOSE_LOGGING}
        __PipeDbg(Format('Stage %d state exited=%s code=%d',[I, BoolToStr(FStages[I].HasExited, True), FStages[I].ExitCode]));
        {$ENDIF}
        {$IFDEF FAFAFA_PROCESS_VERBOSE_LOGGING}
        if LStageExited then __PipeDbg(Format('Stage %d exited code=%d',[I, FStages[I].ExitCode]));
        {$ENDIF}
        if LStageExited and FFailFast and (FStages[I].ExitCode <> 0) then
        begin
          {$IFDEF FAFAFA_PROCESS_VERBOSE_LOGGING}
          __PipeDbg(Format('FailFast trigger at stage %d; TerminateAll then KillAll',[I]));
          {$ENDIF}
          // 优先优雅终止，再强制终止
          try TerminateAll; except on E: Exception do ; end;
          try KillAll; except on E: Exception do ; end;
          // 尝试让下游尽快收敛：关闭所有阶段的标准输入，促使对端完成
          for J := 0 to High(FStages) do
            try if (FStages[J] <> nil) then FStages[J].CloseStandardInput; except on E: Exception do ; end;
          // 关闭所有阶段的标准输入，促使对端尽快收敛
          for J := 0 to High(FStages) do
            try if (FStages[J] <> nil) then FStages[J].CloseStandardInput; except on E: Exception do ; end;
          // 有界等待泵收敛
          FinalizePumps;
          Exit(True);
        end;
      end;
      if not LAllExited then Sleep(10);
    until LAllExited;
    {$IFDEF FAFAFA_PROCESS_VERBOSE_LOGGING}
    __PipeDbg('All stages exited, finalizing pumps');
    {$ENDIF}
    FinalizePumps;
    Exit(True);
  end;

  LDeadline := GetTickCount64 + aTimeoutMs;
  {$IFDEF FAFAFA_PROCESS_VERBOSE_LOGGING}
  __PipeDbg(Format('WaitForExit(timeout=%d) enter',[aTimeoutMs]));
  {$ENDIF}
  repeat
    LAllExited := True;
    for I := 0 to High(FStages) do
    begin
      if not FStages[I].HasExited then
      begin
        // 对于限时路径，使用一个小的非零探测时间片，避免 0 导致某些平台 Wait 未能刷新状态
        if not FStages[I].WaitForExit(0) then
          LAllExited := False;
      end;
      if FStages[I].HasExited and FFailFast and (FStages[I].ExitCode <> 0) then
      begin
        {$IFDEF FAFAFA_PROCESS_VERBOSE_LOGGING}
        __PipeDbg(Format('FailFast trigger at stage %d (timeout path), TerminateAll+KillAll, immediate return',[I]));
        {$ENDIF}
        try TerminateAll; except on E: Exception do ; end;
        try KillAll; except on E: Exception do ; end;
        for J := 0 to High(FStages) do
          try if (FStages[J] <> nil) then FStages[J].CloseStandardInput; except on E: Exception do ; end;
        FinalizePumps;
        Exit(True);
      end;
    end;
    if LAllExited then begin
      {$IFDEF FAFAFA_PROCESS_VERBOSE_LOGGING}
      __PipeDbg('All stages exited (timeout path), finalizing pumps');
      {$ENDIF}
      FinalizePumps; Exit(True);
    end;
    // On timeout, do NOT finalize pumps here to honor the timeout contract; caller may poll repeatedly
    if GetTickCount64 >= LDeadline then begin
      {$IFDEF FAFAFA_PROCESS_VERBOSE_LOGGING}
      __PipeDbg('WaitForExit timeout reached, returning False');
      {$ENDIF}
      Exit(False);
    end;
    Sleep(10);
  until False;
end;

function TPipeline.KillAll: IPipeline;
var
  I: Integer;
begin
  for I := 0 to High(FStages) do
  begin
    try
      if (FStages[I] <> nil) and (not FStages[I].HasExited) then
        FStages[I].Kill;
    except
      on E: Exception do
        ; // 忽略已退出或不可杀的阶段，继续收尾
    end;
  end;
  Result := Self;
end;

function TPipeline.TerminateAll: IPipeline;
var
  I: Integer;
begin
  for I := 0 to High(FStages) do
  begin
    try
      if (FStages[I] <> nil) and (not FStages[I].HasExited) then
        FStages[I].Terminate;
    except
      on E: Exception do
        ; // 忽略异常，尽最大努力终止其余阶段
    end;
  end;
  Result := Self;
end;

function TPipeline.Status: Integer;
begin
  if Length(FStages) = 0 then ExitCode := -1;
  Result := FStages[High(FStages)].ExitCode;
end;

function TPipeline.Success: Boolean;
begin
  Result := Status = 0;
end;

function TPipeline.Output: string;
var
  LUtf8: RawByteString;
begin
  if not Assigned(FOutput) then Exit('');
  // 确保泵完成并回绕位置
  FinalizePumps;
  // 若是文件流，回绕从头读
  FOutput.Position := 0;
  SetLength(LUtf8, FOutput.Size);
  if FOutput.Size > 0 then
    FOutput.ReadBuffer(Pointer(LUtf8)^, FOutput.Size);
  {$ifdef FPC_HAS_CPSTRING}
  SetCodePage(LUtf8, CP_UTF8, False);
  {$endif}
  Result := string(LUtf8);
end;

function TPipeline.ErrorText: string;
var
  LUtf8: RawByteString;
begin
  if not Assigned(FErrOutput) then Exit('');
  FinalizePumps;
  FErrOutput.Position := 0;
  SetLength(LUtf8, FErrOutput.Size);
  if FErrOutput.Size > 0 then
    FErrOutput.ReadBuffer(Pointer(LUtf8)^, FErrOutput.Size);
  {$ifdef FPC_HAS_CPSTRING}
  SetCodePage(LUtf8, CP_UTF8, False);
  {$endif}
  Result := string(LUtf8);
end;

{ TPipelineBuilder }

function TPipelineBuilder.Add(const aStage: IProcessBuilder): IPipelineBuilder;
begin
  SetLength(FStages, Length(FStages) + 1);
  FStages[High(FStages)] := aStage;
  Result := Self;
end;

function TPipelineBuilder.Add(const aExe: string; const aArgs: array of string): IPipelineBuilder;
var
  B: IProcessBuilder;
begin
  B := NewProcessBuilder.Command(aExe).Args(aArgs);
  Result := Add(B);
end;

function TPipelineBuilder.DeleteCapturedOnDestroy(aEnable: Boolean): IPipelineBuilder;
begin
  FDeleteTempOnDestroy := aEnable;
  Result := Self;
end;

function TPipelineBuilder.CaptureOutput(aEnable: Boolean): IPipelineBuilder;
begin
  FCaptureOutput := aEnable;
  Result := Self;
end;

function TPipelineBuilder.CaptureThreshold(const aBytes: SizeInt): IPipelineBuilder;
begin
  if aBytes <= 0 then FCaptureThreshold := 0 else FCaptureThreshold := aBytes;
  Result := Self;
end;


function TPipelineBuilder.FailFast(aEnable: Boolean): IPipelineBuilder;
begin
  FFailFast := aEnable;
  Result := Self;
end;

function TPipelineBuilder.MergeStdErr(aEnable: Boolean): IPipelineBuilder;
begin
  FMergeStdErr := aEnable;
  Result := Self;
end;

function TPipelineBuilder.RedirectStdOutToFile(const aPath: string; aAppend: Boolean): IPipelineBuilder;
begin
  FOutFile := aPath;
  FOutAppend := aAppend;
  Result := Self;
end;

function TPipelineBuilder.RedirectStdErrToFile(const aPath: string; aAppend: Boolean): IPipelineBuilder;
begin
  FErrFile := aPath;
  FErrAppend := aAppend;
  Result := Self;
end;

function TPipelineBuilder.Build: IPipeline;
var
  I: Integer;
  P: array of IProcess;
begin
  SetLength(P, Length(FStages));
  for I := 0 to High(FStages) do
  begin
    if I < High(FStages) then
      FStages[I].CaptureStdOut;
    if I > 0 then
      FStages[I].RedirectInput;

    if (I = High(FStages)) and (FCaptureOutput or (FOutFile<>'') or (FErrFile<>'')) then
    begin
      FStages[I].CaptureStdOut;
      if FMergeStdErr or (FErrFile<>'') then
        FStages[I].RedirectStdErr(True);
    end;

    P[I] := FStages[I].Build;
  end;
  Result := TPipeline.Create(P, FCaptureOutput, FFailFast, FMergeStdErr, FOutFile, FOutAppend, FErrFile, FErrAppend);
  // 将阈值传给 Pipeline（当前 Pipeline 内部使用 FCaptureThreshold；必要时可继续向下传递）
  (Result as TPipeline).FCaptureThreshold := Self.FCaptureThreshold;
end;

function TPipelineBuilder.Start: IPipeline;
begin
  Result := Build.Start;
end;


function TPipeline.OutputFilePath: string;
begin
  if FOutFile<>'' then Exit(FOutFile);
  Result := FOutputFilePath;
end;

function TPipeline.ErrorFilePath: string;
begin
  if (FErrFile<>'') and not (FCaptureOutput and FMergeStdErr) then Exit(FErrFile);
  Result := FErrFilePath;
end;

function NewPipeline: IPipelineBuilder;
begin
  Result := TPipelineBuilder.Create;
end;

procedure TPipeline.FinalizePumps;
var
  I: Integer;
begin
  // 等待所有泵线程结束，确保输出完整
  for I := 0 to High(FPumps) do
    if Assigned(FPumps[I]) then
      FPumps[I].WaitFor;
  // 若捕获输出，则回绕位置到开头（文件或内存）
  if Assigned(FOutput) then
    FOutput.Position := 0;
  if Assigned(FErrOutput) then
    FErrOutput.Position := 0;
end;

end.

