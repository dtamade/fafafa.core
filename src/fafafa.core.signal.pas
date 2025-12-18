unit fafafa.core.signal;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes
  {$IFDEF UNIX}, BaseUnix, Unix{$ENDIF}
  {$IFDEF WINDOWS}, Windows{$ENDIF}
  , fafafa.core.sync, fafafa.core.env
  ;

// Cross-platform signal kinds (normalized)
// Note: Windows 控制台事件映射为 Ctrl* 成员
//       Unix 仅在支持平台可用的信号会被安装

type
  TSignal = (
    sgInt,       // SIGINT / CTRL_C
    sgTerm,      // SIGTERM
    sgHup,       // SIGHUP
    sgUsr1,      // SIGUSR1
    sgUsr2,      // SIGUSR2
    sgWinch,     // SIGWINCH (terminal resize)
    sgCtrlBreak, // Windows: CTRL_BREAK
    sgCtrlClose, // Windows: CTRL_CLOSE_EVENT
    sgCtrlLogoff,// Windows: CTRL_LOGOFF_EVENT
    sgCtrlShutdown // Windows: CTRL_SHUTDOWN_EVENT
  );
  TSignalSet = set of TSignal;

  TSignalProc = procedure (const aSig: TSignal) of object;

  // 队列丢弃策略（达到容量上限时）
  TQueueDropPolicy = (
    qdpDropOldest, // 丢弃最旧（出队端前移一位）
    qdpDropNewest  // 丢弃最新（忽略本次入队）
  );

  TQueueStats = record
    Capacity: Integer;
    Length: Integer;
    Policy: TQueueDropPolicy;
    DropCount: QWord;
  end;

  ISignalCenter = interface
    ['{29F0B9A6-9C9F-49B0-8E67-1BB0FCD57D7E}']
    procedure Start;
    procedure Stop;
    function  IsRunning: Boolean;
    // 非异常风格：返回错误信息
    function  TryStart(out ErrMsg: string): Boolean;
    function  TryStop(out ErrMsg: string): Boolean;
    // Subscribe returns a token (positive). Thread-safe.
    function  Subscribe(const aSignals: TSignalSet; const aCallback: TSignalProc): Int64;
    // Subscribe with an owner; allows UnsubscribeAll(owner) later
    function  SubscribeOwned(aOwner: TObject; const aSignals: TSignalSet; const aCallback: TSignalProc): Int64;
    procedure Unsubscribe(aToken: Int64);
    // Unsubscribe all subscriptions owned by the given owner
    procedure UnsubscribeAll(aOwner: TObject);
    // Pause/Resume a subscription by token
    procedure Pause(aToken: Int64);
    procedure Resume(aToken: Int64);
    // Configure internal queue capacity and drop policy (<=0 means unlimited)
    procedure ConfigureQueue(aMaxCapacity: Integer; aPolicy: TQueueDropPolicy);
    // Configure debounce window (ms) for sgWinch; 0 means disabled
    procedure ConfigureWinchDebounce(aWindowMs: Cardinal);
    // Blocking wait for next signal (from process-wide center), optional timeout (ms). Returns True if got one.
    function  WaitNext(out aSig: TSignal; aTimeoutMs: Cardinal = $FFFFFFFF): Boolean;
    // Non-blocking try wait
    function  TryWaitNext(out aSig: TSignal): Boolean;
    // Subscribe once helper
    function  SubscribeOnce(const aSignals: TSignalSet; const aCallback: TSignalProc): Int64;
    // Test helper: inject a signal into dispatcher queue (safe, thread-aware)
    procedure InjectForTest(const aSig: TSignal);
    // Observability: get current queue stats
    function  GetQueueStats: TQueueStats;
  end;

function SignalCenter: ISignalCenter;

implementation

uses
  fafafa.core.math;

{$IFDEF FAFAFA_SIGNAL_DEBUG}
procedure _sig_dbg(const s: string); inline;
begin
  WriteLn('[SIG]', s);
  System.Flush(Output);
end;
{$ELSE}
procedure _sig_dbg(const s: string); inline; begin end;
{$ENDIF}


Type
  PSub = ^TSub;
  TSub = record
    Token: Int64;
    Signals: TSignalSet;
    Callback: TSignalProc;
    Owner: TObject; // 可选：用于 SubscribeOnce 之类的适配器对象
  end;

  { TSignalCenterImpl }
  TSignalCenterImpl = class(TInterfacedObject, ISignalCenter)
  private
    FLock: ILock;              // 保护订阅表与队列
    FSubs: TList;              // of PSub
    FPaused: TList;            // of Int64 (token set)
    FNextToken: Int64;
    FRunning: Boolean;
    FDispThread: TThread;
    FHasWork: IEvent;          // 队列有新事件
    // 环形缓冲替代 TList+FQStart
    FQBuf: array of TSignal;   // 缓冲区
    FQHead: Integer;           // 出队索引
    FQTail: Integer;           // 入队索引（下一个写入位置）
    FQCount: Integer;          // 当前元素数量
    FQCap: Integer;            // 最大容量（<=0 表示无限/自动扩容）
    FQPolicy: TQueueDropPolicy;
    FWinchDebounceMs: Cardinal; // sgWinch 去抖窗口（毫秒），0 表示禁用
    FLastWinchTs: QWord;        // 上次 sgWinch 入队时间戳
    FDropCount: QWord;          // 丢弃计数（内部统计）
    {$IFDEF UNIX}
    FPipeRd, FPipeWr: cint;
    // 保存旧的 sigaction 以便 Stop 恢复
    FOldAct_INT, FOldAct_TERM: SigActionRec;
    {$IFDEF SIGHUP}  FOldAct_HUP: SigActionRec;   {$ENDIF}
    {$IFDEF SIGUSR1} FOldAct_USR1: SigActionRec;  {$ENDIF}
    {$IFDEF SIGUSR2} FOldAct_USR2: SigActionRec;  {$ENDIF}
    {$IFDEF SIGWINCH}FOldAct_WINCH: SigActionRec; {$ENDIF}
    {$ENDIF}
  {$IFDEF UNIX}
  function  SetNonBlockCloseExec(fd: cint): Boolean;
  {$ENDIF}
  private
    procedure DispatchOne(const aSig: TSignal);
    procedure Enqueue(const aSig: TSignal);
    function  Dequeue(var aSig: TSignal): Boolean;
    procedure SetRunning(aOn: Boolean);
  {$IFDEF UNIX}
  private
    class procedure SigHandler(sig: cint); cdecl; static;
    class var GPipeWr: cint; // static for handler
  {$ENDIF}
  {$IFDEF WINDOWS}
  private
    class function ConsoleCtrlHandler(Code: DWORD): BOOL; stdcall; static;
    class var GInstance: TSignalCenterImpl; // for static callback
    FCtrlHandlerInstalled: Boolean;
  {$ENDIF}
  public
    function  TryWaitNext(out aSig: TSignal): Boolean;
    constructor Create;
    destructor Destroy; override;
    function  SubscribeOnce(const aSignals: TSignalSet; const aCallback: TSignalProc): Int64;
    procedure Start;
    procedure Stop;
    function  IsRunning: Boolean;
    function  TryStart(out ErrMsg: string): Boolean;
    function  TryStop(out ErrMsg: string): Boolean;
    function  Subscribe(const aSignals: TSignalSet; const aCallback: TSignalProc): Int64;
    function  SubscribeOwned(aOwner: TObject; const aSignals: TSignalSet; const aCallback: TSignalProc): Int64;
    procedure Unsubscribe(aToken: Int64);
    procedure UnsubscribeAll(aOwner: TObject);
    procedure Pause(aToken: Int64);
    procedure Resume(aToken: Int64);
    procedure ConfigureQueue(aMaxCapacity: Integer; aPolicy: TQueueDropPolicy);
    procedure ConfigureWinchDebounce(aWindowMs: Cardinal);
    function  WaitNext(out aSig: TSignal; aTimeoutMs: Cardinal): Boolean;
    procedure InjectForTest(const aSig: TSignal);
    function  GetQueueStats: TQueueStats;
  end;

  TDispatcherThread = class(TThread)
  private
    FOwner: TSignalCenterImpl;
  protected
    procedure Execute; override;
  public
    constructor CreateOwner(AOwner: TSignalCenterImpl);
  end;

var
  GCenter: ISignalCenter = nil;

{$IFDEF UNIX}
function MapUnixSigToKind(sig: cint): TSignal;
begin
  case sig of
    SIGINT:   Exit(sgInt);
    SIGTERM:  Exit(sgTerm);
    SIGHUP:   Exit(sgHup);
    {$IFDEF SIGUSR1} SIGUSR1: Exit(sgUsr1); {$ENDIF}
    {$IFDEF SIGUSR2} SIGUSR2: Exit(sgUsr2); {$ENDIF}
    {$IFDEF SIGWINCH} SIGWINCH: Exit(sgWinch); {$ENDIF}
  end;
  // default
  Result := sgTerm;
end;
{$ENDIF}

{$IFDEF WINDOWS}
function MapCtrlToKind(Code: DWORD): TSignal;
begin
  case Code of
    CTRL_C_EVENT:        Exit(sgInt);
    CTRL_BREAK_EVENT:    Exit(sgCtrlBreak);
    CTRL_CLOSE_EVENT:    Exit(sgCtrlClose);
    CTRL_LOGOFF_EVENT:   Exit(sgCtrlLogoff);
    CTRL_SHUTDOWN_EVENT: Exit(sgCtrlShutdown);
  end;
  Result := sgInt;
end;
{$ENDIF}

{ TDispatcherThread }
constructor TDispatcherThread.CreateOwner(AOwner: TSignalCenterImpl);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FOwner := AOwner;
end;

procedure TDispatcherThread.Execute;
var
  LSig: TSignal;
  {$IFDEF UNIX}
  buf: array[0..63] of byte;
  n, i: ssizeint;
  {$ENDIF}
begin
  {$IFDEF UNIX}
  // select + non-blocking read to reduce syscalls
  while not Terminated do
  begin
    var rfds: TFDSet; var tv: TTimeVal;
    fpFD_ZERO(rfds); fpFD_SET(FOwner.FPipeRd, rfds);
    tv.tv_sec := 0; tv.tv_usec := 200000; // 200ms
    if fpSelect(FOwner.FPipeRd+1, @rfds, nil, nil, @tv) > 0 then
    begin
      n := fpRead(FOwner.FPipeRd, buf, SizeOf(buf));
      if n > 0 then
      begin
        for i := 0 to n-1 do
        FOwner.DispatchOne(MapUnixSigToKind(buf[i]));
    end
    end;
    // drain injected queue opportunistically
    if FOwner.Dequeue(LSig) then FOwner.DispatchOne(LSig);
  end;
  {$ELSE}
  while not Terminated do
  begin
    if FOwner.WaitNext(LSig, 200) then
      FOwner.DispatchOne(LSig);
  end;
  {$ENDIF}
end;

{ TSignalCenterImpl }
constructor TSignalCenterImpl.Create;
begin
  inherited Create;
  FLock := TMutex.Create;
  FSubs := TList.Create;
  FPaused := TList.Create;
  // 初始化环形缓冲区为延迟分配（按需增长或配置容量）
  SetLength(FQBuf, 0);
  FQHead := 0;
  FQTail := 0;
  FQCount := 0;
  FQCap := 0; // 无上限（自动扩容）
  FQPolicy := qdpDropNewest;
  FDropCount := 0;
  FHasWork := TEvent.Create(False {manualReset}, False {initialState});
  FNextToken := 1;
  FWinchDebounceMs := 0;
  FLastWinchTs := 0;
  {$IFDEF UNIX}
  FPipeRd := -1; FPipeWr := -1;
  {$ENDIF}
end;

destructor TSignalCenterImpl.Destroy;
var p: PSub;
begin
  Stop;
  while FSubs.Count > 0 do
  begin
    p := PSub(FSubs[0]);
    Dispose(p);
    FSubs.Delete(0);
  end;
  FSubs.Free;
  FPaused.Free;
  // FQBuf 为动态数组，无需显式释放
  inherited Destroy;
end;

procedure TSignalCenterImpl.SetRunning(aOn: Boolean);
begin
  FLock.Acquire;
  try
    FRunning := aOn;
  finally
    FLock.Release;
  end;
end;

procedure TSignalCenterImpl.Start;
{$IFDEF UNIX}
var act: SigActionRec;
{$ENDIF}
begin
  // 全流程互斥，避免 Start/Stop 竞态
  FLock.Acquire;
  try
    if FRunning then Exit;
    // 测试注入：通过环境变量触发 Start 失败（仅用于单元测试）
    if env_get('FAFAFA_SIGNAL_TEST_FAIL_START') = '1' then
      raise Exception.Create('signal: test injected start failure');
    {$IFDEF UNIX}
    // self-pipe initialization (non-blocking + close-on-exec)
    if fpPipe(FPipeRd, FPipeWr) <> 0 then
      raise Exception.Create('signal: pipe creation failed');
    SetNonBlockCloseExec(FPipeRd);
    SetNonBlockCloseExec(FPipeWr);
    GPipeWr := FPipeWr; // static for handler

    FillChar(act, SizeOf(act), 0);
    act.sa_handler := @TSignalCenterImpl.SigHandler;
    sigemptyset(act.sa_mask);
    act.sa_flags := SA_RESTART;
    {$IFDEF FAFAFA_SIGNAL_ENABLE_SIGINT}  fpSigAction(SIGINT, @act, @FOldAct_INT);   {$ENDIF}
    {$IFDEF FAFAFA_SIGNAL_ENABLE_SIGTERM} fpSigAction(SIGTERM, @act, @FOldAct_TERM); {$ENDIF}
    {$IFDEF FAFAFA_SIGNAL_ENABLE_SIGHUP}  {$IFDEF SIGHUP}   fpSigAction(SIGHUP, @act, @FOldAct_HUP);   {$ENDIF} {$ENDIF}
    {$IFDEF FAFAFA_SIGNAL_ENABLE_SIGUSR1} {$IFDEF SIGUSR1}  fpSigAction(SIGUSR1, @act, @FOldAct_USR1);  {$ENDIF} {$ENDIF}
    {$IFDEF FAFAFA_SIGNAL_ENABLE_SIGUSR2} {$IFDEF SIGUSR2}  fpSigAction(SIGUSR2, @act, @FOldAct_USR2);  {$ENDIF} {$ENDIF}
    {$IFDEF FAFAFA_SIGNAL_ENABLE_SIGWINCH}{$IFDEF SIGWINCH} fpSigAction(SIGWINCH, @act, @FOldAct_WINCH); {$ENDIF} {$ENDIF}

    {$ENDIF}

    {$IFDEF WINDOWS}
    {$IFDEF FAFAFA_SIGNAL_ENABLE_WIN_CTRL}
    // Allow tests to disable Win ConsoleCtrlHandler to avoid console interference
    if env_get('FAFAFA_SIGNAL_TEST_DISABLE_WINCTRL') <> '1' then
    begin
      GInstance := Self;
      if not SetConsoleCtrlHandler(@TSignalCenterImpl.ConsoleCtrlHandler, True) then
        raise Exception.Create('signal: SetConsoleCtrlHandler install failed');
      FCtrlHandlerInstalled := True;
    end
    else
      FCtrlHandlerInstalled := False;
    {$ENDIF}
    {$ENDIF}
    FDispThread := TDispatcherThread.CreateOwner(Self);
    FRunning := True;
    FDispThread.Start;
  finally
    FLock.Release;
  end;
end;



// Implementation
function TSignalCenterImpl.TryStart(out ErrMsg: string): Boolean;
begin
  Result := False; ErrMsg := '';
  try
    Start;
    Result := True;
  except
    on E: Exception do begin ErrMsg := E.Message; Result := False; end;
  end;
end;

function TSignalCenterImpl.TryStop(out ErrMsg: string): Boolean;
begin
  Result := False; ErrMsg := '';
  try
    Stop;
    Result := True;
  except
    on E: Exception do begin ErrMsg := E.Message; Result := False; end;
  end;
end;




procedure TSignalCenterImpl.Stop;
var
  disp: TThread;
begin
  // 全流程互斥，避免与 Start 交错
  disp := nil;
  _sig_dbg('Stop: entering');
  FLock.Acquire;
  try
    if not FRunning then begin _sig_dbg('Stop: not running'); Exit; end;

    // 测试注入：通过环境变量触发 Stop 失败（仅用于单元测试）
    if env_get('FAFAFA_SIGNAL_TEST_FAIL_STOP') = '1' then
      raise Exception.Create('signal: test injected stop failure');

    {$IFDEF WINDOWS}
    {$IFDEF FAFAFA_SIGNAL_ENABLE_WIN_CTRL}
    if FCtrlHandlerInstalled then
    begin
      SetConsoleCtrlHandler(@TSignalCenterImpl.ConsoleCtrlHandler, False);
      GInstance := nil;
      FCtrlHandlerInstalled := False;
    end;
    {$ENDIF}
    {$ENDIF}

    // 在线程终止与唤醒后，先把指针取出并清空，锁外等待
    if Assigned(FDispThread) then
    begin
      disp := FDispThread;
      disp.Terminate;
      FHasWork.SetEvent;
      _sig_dbg('Stop: signaled worker');
      FDispThread := nil;
    end;

    // 清空内部队列，确保 Stop 后不再有残留事件
    FQHead := 0; FQTail := 0; FQCount := 0; FLastWinchTs := 0;

    {$IFDEF UNIX}
    // 恢复旧的 handler（按条件编译的信号分别恢复）
    {$IFDEF FAFAFA_SIGNAL_ENABLE_SIGINT}  fpSigAction(SIGINT,  @FOldAct_INT,   nil); {$ENDIF}
    {$IFDEF FAFAFA_SIGNAL_ENABLE_SIGTERM} fpSigAction(SIGTERM, @FOldAct_TERM,  nil); {$ENDIF}
    {$IFDEF FAFAFA_SIGNAL_ENABLE_SIGHUP}  {$IFDEF SIGHUP}   fpSigAction(SIGHUP,  @FOldAct_HUP,   nil);  {$ENDIF} {$ENDIF}
    {$IFDEF FAFAFA_SIGNAL_ENABLE_SIGUSR1} {$IFDEF SIGUSR1}  fpSigAction(SIGUSR1, @FOldAct_USR1,  nil);  {$ENDIF} {$ENDIF}
    {$IFDEF FAFAFA_SIGNAL_ENABLE_SIGUSR2} {$IFDEF SIGUSR2}  fpSigAction(SIGUSR2, @FOldAct_USR2,  nil);  {$ENDIF} {$ENDIF}
    {$IFDEF FAFAFA_SIGNAL_ENABLE_SIGWINCH}{$IFDEF SIGWINCH} fpSigAction(SIGWINCH,@FOldAct_WINCH, nil);  {$ENDIF} {$ENDIF}

    if FPipeRd <> -1 then begin fpClose(FPipeRd); FPipeRd := -1; end;
    if FPipeWr <> -1 then begin fpClose(FPipeWr); FPipeWr := -1; end;
    {$ENDIF}

    FRunning := False;
  finally
    FLock.Release;
  end;

  // 锁外等待线程退出，避免与 Dequeue/DispatchOne 的锁竞争造成死锁
  if Assigned(disp) then
  begin
    _sig_dbg('Stop: waiting worker...');
    disp.WaitFor;
    _sig_dbg('Stop: worker joined');
    FreeAndNil(disp);
  end;
end;

function TSignalCenterImpl.IsRunning: Boolean;
begin
  FLock.Acquire;
  try
    Result := FRunning;
  finally
    FLock.Release;
  end;
end;

procedure TSignalCenterImpl.DispatchOne(const aSig: TSignal);
var i: Integer; p: PSub; LCallbacks: array of TSignalProc; LCount: Integer;
begin
  // 快照订阅者（排除暂停），锁外回调
  FLock.Acquire;
  try
    LCount := 0;
    SetLength(LCallbacks, FSubs.Count);
    for i := 0 to FSubs.Count-1 do
    begin
      p := PSub(FSubs[i]);
      if (p <> nil) and (aSig in p^.Signals) and (FPaused.IndexOf(Pointer(p^.Token)) < 0) then
      begin
        LCallbacks[LCount] := p^.Callback;
        Inc(LCount);
      end;
    end;
  finally
    FLock.Release;
  end;
  for i := 0 to LCount-1 do
    if Assigned(LCallbacks[i]) then
      try LCallbacks[i](aSig); except end;
end;

procedure TSignalCenterImpl.Enqueue(const aSig: TSignal);
var
  willAdd: Boolean;
  dropped: Boolean;
  lastIdx: Integer;
  lastSig: TSignal;
  cap: Integer;
  newCap: Integer;
  i: Integer;
  newBuf: array of TSignal;
begin
  // Stop 后不再处理事件
  if not IsRunning then Exit;
  FLock.Acquire;
  try
    willAdd := True; dropped := False;

    // sgWinch 合并与去抖
    if aSig = sgWinch then
    begin
      if FQCount > 0 then
      begin
        lastIdx := (FQTail - 1 + Max(Length(FQBuf), 1)) mod Max(Length(FQBuf), 1);
        if (Length(FQBuf) > 0) then
        begin
          lastSig := FQBuf[lastIdx];
          if lastSig = sgWinch then
            willAdd := False;
        end;
      end;
      if willAdd and (FWinchDebounceMs > 0) then
      begin
        if (FLastWinchTs <> 0) and ((GetTickCount64 - FLastWinchTs) < FWinchDebounceMs) then
          willAdd := False;
      end;
    end;

    // 确保缓冲容量（当配置为无限时，采用按需扩容策略）
    if willAdd then
    begin
      if (FQCap <= 0) then
      begin
        // 自动扩容：容量翻倍到至少容纳 FQCount+1
        cap := Length(FQBuf);
        if cap = 0 then cap := 16;
        if FQCount >= cap then
        begin
          newCap := cap shl 1;
          if newCap < cap + 1 then newCap := cap + 1;
          // 重新布局到新数组（保持顺序）
          SetLength(newBuf, newCap);
          for i := 0 to FQCount - 1 do
            newBuf[i] := FQBuf[(FQHead + i) mod cap];
          FQBuf := newBuf;
          FQHead := 0;
          FQTail := FQCount;
        end;
      end
      else
      begin
        // 有界：应用丢弃策略
        if FQCount >= FQCap then
        begin
          case FQPolicy of
            qdpDropOldest:
              begin
                // 丢弃最旧：前移 head
                if FQCount > 0 then
                begin
                  FQHead := (FQHead + 1) mod Max(Length(FQBuf), 1);
                  Dec(FQCount);
                  Inc(FDropCount);
                end
                else
                  willAdd := False;
              end;
            qdpDropNewest:
              begin
                willAdd := False; dropped := True; Inc(FDropCount);
              end;
          end;
        end;
        // 确保底层数组大小至少为 FQCap
        if Length(FQBuf) < FQCap then
        begin
          SetLength(FQBuf, FQCap);
          FQHead := 0; FQTail := FQCount mod FQCap;
        end;
      end;
    end;

    if willAdd then
    begin
      if Length(FQBuf) = 0 then begin SetLength(FQBuf, 16); FQHead := 0; FQTail := 0; FQCount := 0; end;
      FQBuf[FQTail] := aSig;
      FQTail := (FQTail + 1) mod Length(FQBuf);
      Inc(FQCount);
      if aSig = sgWinch then FLastWinchTs := GetTickCount64;
    end;

    if willAdd and not dropped then
      FHasWork.SetEvent;
  finally
    FLock.Release;
  end;
end;

function TSignalCenterImpl.GetQueueStats: TQueueStats;
begin
  FLock.Acquire;
  try
    Result.Capacity := Length(FQBuf);
    if FQCap > 0 then Result.Capacity := FQCap; // 对外报告逻辑容量
    Result.Length := FQCount;
    Result.Policy := FQPolicy;
    Result.DropCount := FDropCount;
  finally
    FLock.Release;
  end;
end;

function TSignalCenterImpl.Dequeue(var aSig: TSignal): Boolean;
begin
  Result := False;
  FLock.Acquire;
  try
    if FQCount > 0 then
    begin
      aSig := FQBuf[FQHead];
      FQHead := (FQHead + 1) mod Max(Length(FQBuf), 1);
      Dec(FQCount);
      Result := True;
    end;
  finally
    FLock.Release;
  end;
end;

function TSignalCenterImpl.Subscribe(const aSignals: TSignalSet; const aCallback: TSignalProc): Int64;
var p: PSub;
begin
  New(p);
  FLock.Acquire;
  try
    p^.Token := FNextToken; Inc(FNextToken);
    p^.Signals := aSignals;
    p^.Callback := aCallback;
    p^.Owner := nil;
    FSubs.Add(p);
    Result := p^.Token;
  finally
    FLock.Release;
  end;
end;

function TSignalCenterImpl.SubscribeOwned(aOwner: TObject; const aSignals: TSignalSet; const aCallback: TSignalProc): Int64;
var p: PSub;
begin
  New(p);
  FLock.Acquire;
  try
    p^.Token := FNextToken; Inc(FNextToken);
    p^.Signals := aSignals;
    p^.Callback := aCallback;
    p^.Owner := aOwner;
    FSubs.Add(p);
    Result := p^.Token;
  finally
    FLock.Release;
  end;
end;

procedure TSignalCenterImpl.Unsubscribe(aToken: Int64);
var i, j: Integer; p: PSub;
begin
  FLock.Acquire;
  try
    for i := 0 to FSubs.Count-1 do
    begin
      p := PSub(FSubs[i]);
      if (p <> nil) and (p^.Token = aToken) then
      begin
        Dispose(p);
        FSubs.Delete(i);
        // also remove token from paused set if present
        if FPaused.Count > 0 then
        begin
          for j := FPaused.Count-1 downto 0 do
            if Int64(FPaused[j]) = aToken then begin FPaused.Delete(j); Break; end;
        end;
        Break;
      end;
    end;
  finally
    FLock.Release;
  end;
end;

procedure TSignalCenterImpl.UnsubscribeAll(aOwner: TObject);
var i, j: Integer; p: PSub; tok: Int64;
begin
  if aOwner = nil then Exit;
  FLock.Acquire;
  try
    // 从后往前遍历，便于删除
    for i := FSubs.Count-1 downto 0 do
    begin
      p := PSub(FSubs[i]);
      if (p <> nil) and (p^.Owner = aOwner) then
      begin
        tok := p^.Token;
        Dispose(p);
        FSubs.Delete(i);
        // 清理暂停集
        if FPaused.Count > 0 then
        begin
          for j := FPaused.Count-1 downto 0 do
            if Int64(FPaused[j]) = tok then FPaused.Delete(j);
        end;
      end;
    end;
  finally
    FLock.Release;
  end;
end;

function TSignalCenterImpl.WaitNext(out aSig: TSignal; aTimeoutMs: Cardinal): Boolean;
var wr: TWaitResult;
begin
  // 先尝试非阻塞出队
  if Dequeue(aSig) then Exit(True);
  wr := FHasWork.WaitFor(aTimeoutMs);
  if wr = wrSignaled then
  begin
    // 自动复位事件，无需额外 Reset（IEvent 为 auto-reset）
    Result := Dequeue(aSig);
  end
  else
    Result := False;
end;

procedure TSignalCenterImpl.InjectForTest(const aSig: TSignal);
begin
  Enqueue(aSig);
end;

function TSignalCenterImpl.TryWaitNext(out aSig: TSignal): Boolean;
begin
  Result := WaitNext(aSig, 0);
end;

type
  TOnceWrapper = class
  public
    Center: TSignalCenterImpl;
    Token: Int64;
    UserCallback: TSignalProc;
    Owner: TObject;
    procedure Handle(const S: TSignal);
  end;

procedure TOnceWrapper.Handle(const S: TSignal);
begin
  if Assigned(Center) then Center.Unsubscribe(Token);
  if Assigned(UserCallback) then UserCallback(S);
  // 自销毁，避免泄漏
  Free;
end;

function TSignalCenterImpl.SubscribeOnce(const aSignals: TSignalSet; const aCallback: TSignalProc): Int64;
var W: TOnceWrapper;
begin
  W := TOnceWrapper.Create;
  W.Center := Self;
  W.UserCallback := aCallback;
  W.Token := 0; // will set after Subscribe returns
  Result := Subscribe(aSignals, @W.Handle);
  W.Token := Result;
end;

procedure TSignalCenterImpl.Pause(aToken: Int64);
begin
  FLock.Acquire;
  try
    if FPaused.IndexOf(Pointer(aToken)) < 0 then
      FPaused.Add(Pointer(aToken));
  finally
    FLock.Release;
  end;
end;

procedure TSignalCenterImpl.Resume(aToken: Int64);
var idx: Integer;
begin
  FLock.Acquire;
  try
    idx := FPaused.IndexOf(Pointer(aToken));
    if idx >= 0 then FPaused.Delete(idx);
  finally
    FLock.Release;
  end;
end;



procedure TSignalCenterImpl.ConfigureQueue(aMaxCapacity: Integer; aPolicy: TQueueDropPolicy);
begin
  FLock.Acquire;
  try
    FQCap := aMaxCapacity;
    FQPolicy := aPolicy;
  finally
    FLock.Release;
  end;
end;

procedure TSignalCenterImpl.ConfigureWinchDebounce(aWindowMs: Cardinal);
begin
  FLock.Acquire;
  try
    FWinchDebounceMs := aWindowMs;
  finally
    FLock.Release;
  end;
end;

{$IFDEF UNIX}
function TSignalCenterImpl.SetNonBlockCloseExec(fd: cint): Boolean;
var flags: cint;
begin
  Result := False;
  // O_NONBLOCK
  flags := fpFcntl(fd, F_GETFL);
  if flags <> -1 then
  begin
    if fpFcntl(fd, F_SETFL, flags or O_NONBLOCK) <> -1 then Result := True;
  end;
  // FD_CLOEXEC
  flags := fpFcntl(fd, F_GETFD);
  if flags <> -1 then fpFcntl(fd, F_SETFD, flags or FD_CLOEXEC);
end;
{$ENDIF}


{$IFDEF UNIX}
class procedure TSignalCenterImpl.SigHandler(sig: cint); cdecl;
var b: byte;
begin
  // write a single byte to self-pipe; ignore errors
  b := byte(sig);
  if GPipeWr <> -1 then fpWrite(GPipeWr, @b, 1);
end;
{$ENDIF}

{$IFDEF WINDOWS}
class function TSignalCenterImpl.ConsoleCtrlHandler(Code: DWORD): BOOL; stdcall;
var kind: TSignal; i: Integer; hasSub: Boolean; p: PSub;
begin
  if Assigned(GInstance) then
  begin
    kind := MapCtrlToKind(Code);
    // 仅当存在至少一个该信号的订阅者时，声明“已处理”（返回 True）
    hasSub := False;
    GInstance.FLock.Acquire;
    try
      for i := 0 to GInstance.FSubs.Count-1 do
      begin
        p := PSub(GInstance.FSubs[i]);
        if (p <> nil) and (kind in p^.Signals) and (GInstance.FPaused.IndexOf(Pointer(p^.Token)) < 0) then
        begin
          hasSub := True; Break;
        end;
      end;
    finally
      GInstance.FLock.Release;
    end;
    GInstance.Enqueue(kind);
    Result := hasSub;
    Exit;
  end;
  Result := False;
end;
{$ENDIF}

function SignalCenter: ISignalCenter;
begin
  if GCenter = nil then
    GCenter := TSignalCenterImpl.Create;
  Result := GCenter;
end;

end.

