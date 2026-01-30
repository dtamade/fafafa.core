unit fafafa.core.socket.poller;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, SyncObjs,
  fafafa.core.base,
  fafafa.core.socket;

type
  // 高性能轮询器性能指标
  TPollerMetrics = record
    TotalEvents: Int64;
    EventsPerSecond: Double;
    AverageLatencyMs: Double;
    RegisteredSockets: Integer;
    MaxConcurrentSockets: Integer;
    PollerType: string;
    LastResetTime: TDateTime;
  end;

  // 高级轮询器接口
  IAdvancedSocketPoller = interface(ISocketPoller)
    ['{F2C9D6E5-8A7B-5C6D-9E4F-2A1B0C9D8E7F}']

    // 批量操作
    function RegisterMultiple(const ASockets: array of ISocket; AEvents: TSocketEvents): Integer;
    function PollBatch(ATimeoutMs: Integer; AMaxEvents: Integer): TSocketPollResults;

    // 性能优化选项
    procedure SetEdgeTriggered(AEnabled: Boolean);  // epoll ET模式
    procedure SetOneShot(AEnabled: Boolean);        // epoll ONESHOT模式
    procedure SetMaxEvents(AMaxEvents: Integer);    // 最大事件数

    // 统计和监控
    function GetPerformanceMetrics: TPollerMetrics;
    procedure ResetMetrics;

    // 轮询器信息
    function GetPollerType: string;
    function GetMaxSockets: Integer;
    function IsHighPerformance: Boolean;
  end;

  // 轮询器工厂
  TSocketPollerFactory = class
  public
    // 创建最佳轮询器（根据平台自动选择）
    class function CreateBest(AMaxSockets: Integer = 10000): IAdvancedSocketPoller;

    // 创建特定类型的轮询器
    class function CreateSelect(AMaxSockets: Integer = 1024): IAdvancedSocketPoller;
    {$IFDEF WINDOWS}
    class function CreateIOCP(AMaxSockets: Integer = 10000): IAdvancedSocketPoller;
    {$ENDIF}
    {$IFDEF LINUX}
    class function CreateEpoll(AMaxSockets: Integer = 10000): IAdvancedSocketPoller;
    {$ENDIF}
    {$IFDEF DARWIN}
    class function CreateKqueue(AMaxSockets: Integer = 10000): IAdvancedSocketPoller;
    {$ENDIF}

    // 获取可用的轮询器类型
    class function GetAvailablePollers: TStringArray;
    class function GetRecommendedPoller: string;
  end;

  // 基础高级轮询器抽象类
  TAdvancedSocketPollerBase = class(TInterfacedObject, IAdvancedSocketPoller)
  protected
    type TSocketEntry = record
      Socket: ISocket;
      Events: TSocketEvents;
      Callback: TSocketEventCallback;
      RegisterTime: TDateTime;
    end;

  protected
    FSockets: array of TSocketEntry;
    FReadyResults: TSocketPollResults;
    FStopped: Boolean;
    FMaxSockets: Integer;
    FMaxEvents: Integer;
    FEdgeTriggered: Boolean;
    FOneShot: Boolean;

    // 性能指标
    FMetrics: TPollerMetrics;
    FLock: TRTLCriticalSection;

    // 抽象方法
    function DoRegisterSocket(const ASocket: ISocket; AEvents: TSocketEvents): Boolean; virtual; abstract;
    function DoUnregisterSocket(const ASocket: ISocket): Boolean; virtual; abstract;
    function DoPoll(ATimeoutMs: Integer; AMaxEvents: Integer): Integer; virtual; abstract;
    function DoModifyEvents(const ASocket: ISocket; AEvents: TSocketEvents): Boolean; virtual; abstract;

    // 辅助方法
    function FindSocketIndex(const ASocket: ISocket): Integer;
    procedure RemoveSocketAt(AIndex: Integer);
    procedure UpdateMetrics(AEventCount: Integer; ALatencyMs: Double);

  public
    constructor Create(AMaxSockets: Integer = 10000);
    destructor Destroy; override;

    // ISocketPoller implementation
    procedure RegisterSocket(const ASocket: ISocket; AEvents: TSocketEvents; ACallback: TSocketEventCallback = nil);
    procedure UnregisterSocket(const ASocket: ISocket);
    procedure ModifyEvents(const ASocket: ISocket; AEvents: TSocketEvents);
    function Poll(ATimeoutMs: Integer): Integer;
    function GetReadyEvents: TSocketPollResults;
    function PollAsync: Integer;
    procedure Stop;
    function GetRegisteredCount: Integer;
    function GetStatistics: string;

    // IAdvancedSocketPoller implementation
    function RegisterMultiple(const ASockets: array of ISocket; AEvents: TSocketEvents): Integer;
    function PollBatch(ATimeoutMs: Integer; AMaxEvents: Integer): TSocketPollResults;
    procedure SetEdgeTriggered(AEnabled: Boolean);
    procedure SetOneShot(AEnabled: Boolean);
    procedure SetMaxEvents(AMaxEvents: Integer);
    function GetPerformanceMetrics: TPollerMetrics;
    procedure ResetMetrics;
    function GetPollerType: string; virtual; abstract;
    function GetMaxSockets: Integer;
    function IsHighPerformance: Boolean; virtual;
  end;

{$IFDEF FAFAFA_SOCKET_POLLER_EXPERIMENTAL}
{$IFDEF WINDOWS}
  // Windows IOCP 轮询器
  TIOCPSocketPoller = class(TAdvancedSocketPollerBase)
  private
    FCompletionPort: THandle;
    FWorkerThreads: array of TThread;
    FWorkerCount: Integer;
    // 写阈值（运行时调节，默认 MaxPending=1，BackoffMs=0）
    FWriteMaxPending: Integer;
    FWriteBackoffMs: Integer;
    FWriteWarnP95Ms: Integer;
    // 跟踪已投递的0字节接收操作（最小实现，仅用于释放资源）
    FRecvOps: array of record
      Ov: Pointer; // placeholder for LPWSAOVERLAPPED
      Dummy: PAnsiChar;
      Handle: THandle;
    end;
    // 跟踪已投递的0字节发送操作（最小实现：用于触发seWrite完成）
    FSendOps: array of record
      Ov: Pointer;
      Handle: THandle;
      StartTick: QWord;
    end;
    // 极简写队列（仅 0 字节发送用于触发 seWrite）
    FWriteQ: array of record
      Handle: THandle;
      Pending: Integer;
      InFlight: Boolean;
    end;
    {$IFDEF DEBUG}
    type
      TDbgHandleStats = record
        Handle: THandle;
        Posted: Integer;
        Canceled: Integer;
        CompletedRead: Integer;
        CompletedClose: Integer;
        CompletedWrite: Integer;
        PostFail: Integer;
        PostFailWrite: Integer;
        // 写延迟统计（ms）：平均值基于 sum/count；p95 基于小型样本环
        WriteLatSum: QWord;
        WriteLatCount: Integer;
        WriteLatSamples: array[0..63] of Word;
        WriteLatSampleCount: Integer;
        WriteLatSamplePos: Integer;
      end;
    {$ENDIF}

    {$IFDEF DEBUG}
    private
      FDbgStats: array of TDbgHandleStats;
      FDbgVerbose: Boolean;
      function DbgFindIndex(AHandle: THandle): Integer;
      function DbgEnsureIndex(AHandle: THandle): Integer;
      procedure DbgIncPosted(AHandle: THandle);
      procedure DbgIncCanceled(AHandle: THandle);
      procedure DbgIncRead(AHandle: THandle);
      procedure DbgIncClose(AHandle: THandle);
      procedure DbgIncPostFail(AHandle: THandle);
      procedure DbgIncWrite(AHandle: THandle);
      procedure DbgIncPostFailWrite(AHandle: THandle);
      procedure DbgAddWriteLatency(AHandle: THandle; ALatencyMs: Word);
      procedure DbgDumpSummary;
      procedure DbgLogPendingOps(const ATag: string);
    {$ENDIF}


    procedure CreateWorkerThreads;
    procedure DestroyWorkerThreads;
    function PostZeroRecv(const ASocket: ISocket): Boolean;
    function PostZeroSend(const ASocket: ISocket): Boolean;
    procedure CleanupRecvOpByOv(AOv: Pointer);
    procedure CleanupSendOpByOv(AOv: Pointer);
    function WriteQFindIndex(AHandle: THandle): Integer;
    function WriteQEnsureIndex(AHandle: THandle): Integer;
    {$IFDEF DEBUG}
    procedure DbgQueueZeroSends(const ASocket: ISocket; ACount: Integer);
    {$ENDIF}

  protected
    function DoRegisterSocket(const ASocket: ISocket; AEvents: TSocketEvents): Boolean; override;
    function DoUnregisterSocket(const ASocket: ISocket): Boolean; override;
    function DoPoll(ATimeoutMs: Integer; AMaxEvents: Integer): Integer; override;
    function DoModifyEvents(const ASocket: ISocket; AEvents: TSocketEvents): Boolean; override;

  public
    constructor Create(AMaxSockets: Integer = 10000);
    destructor Destroy; override;

    function GetPollerType: string; override;
    function IsHighPerformance: Boolean; override;
  {$IFDEF DEBUG}
  public
    function DbgGetSummaryText: string;
    procedure DbgResetStats;
    procedure DbgSetVerbose(AEnabled: Boolean);
    function DbgGetVerbose: Boolean;
    function DbgGetConfigText: string;
    procedure DbgSetWriteThresholds(AMaxPendingZeroSends: Integer; ABackoffMs: Integer);
    procedure DbgSetWriteWarnP95Ms(AThresholdMs: Integer);
    procedure DbgResetWriteLatency;
  {$ENDIF}
  end;

{$IFDEF DEBUG}
  TIOCPSocketPoller = class;
{$ENDIF}

{$ENDIF}

{$IFDEF LINUX}
  // Linux epoll 轮询器
  TEpollSocketPoller = class(TAdvancedSocketPollerBase)
  private
    FEpollFd: Integer;
    FEvents: array of TEpollEvent;

  protected
    function DoRegisterSocket(const ASocket: ISocket; AEvents: TSocketEvents): Boolean; override;
    function DoUnregisterSocket(const ASocket: ISocket): Boolean; override;
    function DoPoll(ATimeoutMs: Integer; AMaxEvents: Integer): Integer; override;
    function DoModifyEvents(const ASocket: ISocket; AEvents: TSocketEvents): Boolean; override;

  public
    constructor Create(AMaxSockets: Integer = 10000);
    destructor Destroy; override;

    function GetPollerType: string; override;
    function IsHighPerformance: Boolean; override;
  end;
{$ENDIF}

{$IFDEF DARWIN}
  // macOS/BSD kqueue 轮询器
  TKqueueSocketPoller = class(TAdvancedSocketPollerBase)
  private
    FKqueueFd: Integer;
    FEvents: array of TKEvent;

  protected
    function DoRegisterSocket(const ASocket: ISocket; AEvents: TSocketEvents): Boolean; override;
    function DoUnregisterSocket(const ASocket: ISocket): Boolean; override;
    function DoPoll(ATimeoutMs: Integer; AMaxEvents: Integer): Integer; override;
{$ENDIF}

{$IFDEF FAFAFA_SOCKET_POLLER_EXPERIMENTAL}
{$IFDEF WINDOWS}
{$IFDEF DEBUG}
procedure TIOCPSocketPoller.DbgSetVerbose(AEnabled: Boolean);
begin
  FDbgVerbose := AEnabled;
end;

function TIOCPSocketPoller.DbgGetVerbose: Boolean;
begin
  Result := FDbgVerbose;
end;

procedure TIOCPSocketPoller.DbgSetWriteThresholds(AMaxPendingZeroSends: Integer; ABackoffMs: Integer);
begin
  if AMaxPendingZeroSends < 0 then AMaxPendingZeroSends := 0;
  if ABackoffMs < 0 then ABackoffMs := 0;
  FWriteMaxPending := AMaxPendingZeroSends;
  FWriteBackoffMs := ABackoffMs;
end;

procedure TIOCPSocketPoller.DbgSetWriteWarnP95Ms(AThresholdMs: Integer);
begin
  if AThresholdMs < 0 then AThresholdMs := 0;
  FWriteWarnP95Ms := AThresholdMs;
end;

procedure TIOCPSocketPoller.DbgResetWriteLatency;
var I: Integer;
begin
  for I := 0 to High(FDbgStats) do
  begin
    FDbgStats[I].WriteLatSum := 0;
    FDbgStats[I].WriteLatCount := 0;
    FDbgStats[I].WriteLatSampleCount := 0;
    FDbgStats[I].WriteLatSamplePos := 0;
  end;
end;

function TIOCPSocketPoller.DbgFindIndex(AHandle: THandle): Integer;
var
  I: Integer;
begin
  for I := 0 to High(FDbgStats) do
    if FDbgStats[I].Handle = AHandle then exit(I);
  Result := -1;
end;

function TIOCPSocketPoller.DbgEnsureIndex(AHandle: THandle): Integer;
var
  I: Integer;
begin
  I := DbgFindIndex(AHandle);
  if I >= 0 then exit(I);
  SetLength(FDbgStats, Length(FDbgStats) + 1);
  I := High(FDbgStats);
  FillChar(FDbgStats[I], SizeOf(FDbgStats[I]), 0);
  FDbgStats[I].Handle := AHandle;
  Result := I;
end;

procedure TIOCPSocketPoller.DbgIncPosted(AHandle: THandle);
var I: Integer; begin I := DbgEnsureIndex(AHandle); Inc(FDbgStats[I].Posted); end;
procedure TIOCPSocketPoller.DbgIncCanceled(AHandle: THandle);
var I: Integer; begin I := DbgEnsureIndex(AHandle); Inc(FDbgStats[I].Canceled); end;
procedure TIOCPSocketPoller.DbgIncRead(AHandle: THandle);
var I: Integer; begin I := DbgEnsureIndex(AHandle); Inc(FDbgStats[I].CompletedRead); end;
procedure TIOCPSocketPoller.DbgIncClose(AHandle: THandle);
var I: Integer; begin I := DbgEnsureIndex(AHandle); Inc(FDbgStats[I].CompletedClose); end;
procedure TIOCPSocketPoller.DbgIncPostFail(AHandle: THandle);
var I: Integer; begin I := DbgEnsureIndex(AHandle); Inc(FDbgStats[I].PostFail); end;
procedure TIOCPSocketPoller.DbgIncWrite(AHandle: THandle);
var I: Integer; begin I := DbgEnsureIndex(AHandle); Inc(FDbgStats[I].CompletedWrite); end;
procedure TIOCPSocketPoller.DbgIncPostFailWrite(AHandle: THandle);
var I: Integer; begin I := DbgEnsureIndex(AHandle); Inc(FDbgStats[I].PostFailWrite); end;
procedure TIOCPSocketPoller.DbgAddWriteLatency(AHandle: THandle; ALatencyMs: Word);
var I, P: Integer; begin
  I := DbgEnsureIndex(AHandle);
  Inc(FDbgStats[I].WriteLatSum, ALatencyMs);
  Inc(FDbgStats[I].WriteLatCount);
  P := FDbgStats[I].WriteLatSamplePos and High(FDbgStats[I].WriteLatSamples);
  FDbgStats[I].WriteLatSamples[P] := ALatencyMs;
  Inc(FDbgStats[I].WriteLatSamplePos);
  if FDbgStats[I].WriteLatSampleCount < Length(FDbgStats[I].WriteLatSamples) then
    Inc(FDbgStats[I].WriteLatSampleCount);
end;

procedure TIOCPSocketPoller.DbgDumpSummary;
var
  I: Integer;
  S: string;
begin
  for I := 0 to High(FDbgStats) do
  begin
    // 简单阈值报警：失败或取消比例过高时给出警示
    var TotalCompleted := FDbgStats[I].CompletedRead + FDbgStats[I].CompletedClose;
    var TotalPosted := FDbgStats[I].Posted;
    var FailRatePct: Integer := 0;
    var CancelRatePct: Integer := 0;
    if TotalPosted > 0 then
    begin
      FailRatePct := (FDbgStats[I].PostFail * 100) div TotalPosted;
      CancelRatePct := (FDbgStats[I].Canceled * 100) div TotalPosted;
    end;

    S := Format('[IOCP] Summary handle=%d posted=%d read=%d close=%d canceled=%d postFail=%d fail%%=%d cancel%%=%d',
      [Integer(FDbgStats[I].Handle), FDbgStats[I].Posted, FDbgStats[I].CompletedRead,
       FDbgStats[I].CompletedClose, FDbgStats[I].Canceled, FDbgStats[I].PostFail,
       FailRatePct, CancelRatePct]);
    if FDbgVerbose then
      OutputDebugString(PChar(S))
    else if (FailRatePct >= 30) or ((CancelRatePct >= 50) and (TotalCompleted = 0)) then
      OutputDebugString(PChar(S));
    if FailRatePct >= 30 then
      OutputDebugString(PChar(Format('[IOCP][WARN] High post failure rate on handle=%d (%d%%)', [Integer(FDbgStats[I].Handle), FailRatePct])));
    if (CancelRatePct >= 50) and (TotalCompleted = 0) then
      OutputDebugString(PChar(Format('[IOCP][WARN] High cancel rate without completions handle=%d (%d%%)', [Integer(FDbgStats[I].Handle), CancelRatePct])));
  end;
  SetLength(FDbgStats, 0);
end;

function TIOCPSocketPoller.DbgGetConfigText: string;
var
  L: TStringList;
  I: Integer;
  Q: string;
begin
  L := TStringList.Create;
  try
    L.Add(Format('dbg_verbose=%s', [BoolToStr(FDbgVerbose, True)]));
    L.Add(Format('pending_recv_ops=%d', [Length(FRecvOps)]));
    L.Add(Format('pending_send_ops=%d', [Length(FSendOps)]));
    L.Add(Format('writeq_entries=%d', [Length(FWriteQ)]));
    Q := '';
    for I := 0 to High(FWriteQ) do
      Q := Q + Format('{h=%d, pend=%d, inflight=%s} ', [Integer(FWriteQ[I].Handle), FWriteQ[I].Pending, BoolToStr(FWriteQ[I].InFlight, True)]);
    if Q <> '' then L.Add('writeq='+Q);
    L.Add(Format('write_max_pending=%d', [FWriteMaxPending]));
    L.Add(Format('write_backoff_ms=%d', [FWriteBackoffMs]));
    L.Add(Format('worker_threads=%d', [Length(FWorkerThreads)]));
    L.Add(Format('dbg_stats_handles=%d', [Length(FDbgStats)]));
    L.Add(Format('write_warn_p95_ms=%d', [FWriteWarnP95Ms]));
    Result := L.Text;
  finally
    L.Free;
  end;
end;

function TIOCPSocketPoller.DbgGetSummaryText: string;
var
  I: Integer;
  L: TStringList;
  TotalCompleted, FailRatePct, CancelRatePct: Integer;
begin
  L := TStringList.Create;
  try
    for I := 0 to High(FDbgStats) do
    begin
      TotalCompleted := FDbgStats[I].CompletedRead + FDbgStats[I].CompletedClose;
      FailRatePct := 0; CancelRatePct := 0;
      if FDbgStats[I].Posted > 0 then
      begin
        FailRatePct := (FDbgStats[I].PostFail * 100) div FDbgStats[I].Posted;
        CancelRatePct := (FDbgStats[I].Canceled * 100) div FDbgStats[I].Posted;
      end;
      // 计算写延迟指标（平均、p95 简易估算）
      var AvgMs: Integer := 0;
      var P95Ms: Integer := 0;
      if FDbgStats[I].WriteLatCount > 0 then
        AvgMs := Integer(FDbgStats[I].WriteLatSum div QWord(FDbgStats[I].WriteLatCount));
      if FDbgStats[I].WriteLatSampleCount > 0 then
      begin
        // 简易 p95：对已采样样本排序后取 95% 位置
        var N := FDbgStats[I].WriteLatSampleCount;
        var Tmp: array of Word;
        SetLength(Tmp, N);
        var K: Integer;
        // 环形样本展开并复制最近 N 个样本（WriteLatSamplePos-1 往回数 N 个）
        var Pos := FDbgStats[I].WriteLatSamplePos;
        for K := 0 to N-1 do
          Tmp[K] := FDbgStats[I].WriteLatSamples[(Pos - 1 - K) and High(FDbgStats[I].WriteLatSamples)];
        // 插入排序：N<=64
        var A, B: Integer;
        for A := 1 to N-1 do
        begin
          var Key := Tmp[A];
          B := A - 1;
          while (B >= 0) and (Tmp[B] > Key) do
          begin
            Tmp[B+1] := Tmp[B];
            Dec(B);
          end;
          Tmp[B+1] := Key;
        end;
        var Idx := (N*95) div 100; if Idx >= N then Idx := N-1;
        if Idx < 0 then Idx := 0;
        P95Ms := Tmp[Idx];
      end;

      L.Add(Format('handle=%d posted=%d read=%d close=%d canceled=%d postFail=%d fail%%=%d cancel%%=%d write=%d writeFail=%d wlat_avg=%dms wlat_p95=%dms',
        [Integer(FDbgStats[I].Handle), FDbgStats[I].Posted, FDbgStats[I].CompletedRead,
         FDbgStats[I].CompletedClose, FDbgStats[I].Canceled, FDbgStats[I].PostFail,
         FailRatePct, CancelRatePct, FDbgStats[I].CompletedWrite, FDbgStats[I].PostFailWrite, AvgMs, P95Ms]));

      if (FWriteWarnP95Ms > 0) and (P95Ms > FWriteWarnP95Ms) then
        OutputDebugString(PChar(Format('[IOCP][WARN] High write latency p95=%dms (> %dms) handle=%d', [P95Ms, FWriteWarnP95Ms, Integer(FDbgStats[I].Handle)])));

    end;
    Result := L.Text;
  finally
    L.Free;
  end;
end;

procedure TIOCPSocketPoller.DbgResetStats;
begin
  SetLength(FDbgStats, 0);
end;

procedure TIOCPSocketPoller.DbgLogPendingOps(const ATag: string);
var
  I: Integer;
  S: string;
begin
    if FDbgVerbose then
  begin
    for I := 0 to High(FRecvOps) do
    begin
      S := Format('[IOCP] %s pending: handle=%d ov=%p dummy=%p',
        [ATag, Integer(FRecvOps[I].Handle), Pointer(FRecvOps[I].Ov), Pointer(FRecvOps[I].Dummy)]);
      OutputDebugString(PChar(S));
    end;
  end
  else
  begin
    if Length(FRecvOps) > 0 then
      OutputDebugString(PChar(Format('[IOCP] %s pending: count=%d (enable VERBOSE to dump all)', [ATag, Length(FRecvOps)])));
  end;
end;
{$ENDIF}
{$ENDIF}

    function DoModifyEvents(const ASocket: ISocket; AEvents: TSocketEvents): Boolean; override;

  public
    constructor Create(AMaxSockets: Integer = 10000);
    destructor Destroy; override;

    function GetPollerType: string; override;
    function IsHighPerformance: Boolean; override;
  end;
{$ENDIF}
{$ENDIF}

  // 增强的 Select 轮询器（跨平台兼容）
  TEnhancedSelectPoller = class(TAdvancedSocketPollerBase)
  protected
    function DoRegisterSocket(const ASocket: ISocket; AEvents: TSocketEvents): Boolean; override;
    function DoUnregisterSocket(const ASocket: ISocket): Boolean; override;
    function DoPoll(ATimeoutMs: Integer; AMaxEvents: Integer): Integer; override;
    function DoModifyEvents(const ASocket: ISocket; AEvents: TSocketEvents): Boolean; override;

  public
    function GetPollerType: string; override;
    function IsHighPerformance: Boolean; override;
  end;

implementation

{$IFDEF WINDOWS}
uses
  Windows, WinSock2;
{$ENDIF}


{$IFDEF FAFAFA_SOCKET_POLLER_EXPERIMENTAL}
{$IFDEF WINDOWS}
// uses Windows, WinSock2; // duplicated; already included above

// IOCP 相关常量和结构
const
  INVALID_HANDLE_VALUE = THandle(-1);

type
  POVERLAPPED = ^OVERLAPPED;
  OVERLAPPED = record
    Internal: ULONG_PTR;
    InternalHigh: ULONG_PTR;
    case Integer of
      0: (
        Offset: DWORD;
        OffsetHigh: DWORD;
      );
      1: (
        Pointer: Pointer;
        hEvent: THandle;
      );
  end;

// IOCP API 声明
function CreateIoCompletionPort(FileHandle: THandle; ExistingCompletionPort: THandle;
  CompletionKey: ULONG_PTR; NumberOfConcurrentThreads: DWORD): THandle; stdcall; external 'kernel32.dll';

function GetQueuedCompletionStatus(CompletionPort: THandle; var lpNumberOfBytes: DWORD;
  var lpCompletionKey: ULONG_PTR; var lpOverlapped: POVERLAPPED; dwMilliseconds: DWORD): BOOL; stdcall; external 'kernel32.dll';

function PostQueuedCompletionStatus(CompletionPort: THandle; dwNumberOfBytesTransferred: DWORD;
  dwCompletionKey: ULONG_PTR; lpOverlapped: POVERLAPPED): BOOL; stdcall; external 'kernel32.dll';

{$ENDIF}
{$ENDIF}

{$IFDEF FAFAFA_SOCKET_POLLER_EXPERIMENTAL}
{$IFDEF LINUX}
uses
  BaseUnix, Linux;

// epoll 相关常量
const
  EPOLL_CTL_ADD = 1;
  EPOLL_CTL_DEL = 2;
  EPOLL_CTL_MOD = 3;

  EPOLLIN = $001;
  EPOLLOUT = $004;
  EPOLLERR = $008;
  EPOLLHUP = $010;
  EPOLLET = $80000000;  // Edge Triggered
  EPOLLONESHOT = $40000000;

type
  TEpollEvent = record
    events: LongWord;
    data: record
      case Integer of
        0: (ptr: Pointer);
        1: (fd: Integer);
        2: (u32: LongWord);
        3: (u64: QWord);
    end;
  end;
  PEpollEvent = ^TEpollEvent;

// epoll API 声明
function epoll_create(size: Integer): Integer; cdecl; external 'c';
function epoll_create1(flags: Integer): Integer; cdecl; external 'c';
function epoll_ctl(epfd: Integer; op: Integer; fd: Integer; event: PEpollEvent): Integer; cdecl; external 'c';
function epoll_wait(epfd: Integer; events: PEpollEvent; maxevents: Integer; timeout: Integer): Integer; cdecl; external 'c';

{$ENDIF}
{$ENDIF}

{$IFDEF DARWIN}
uses
  BaseUnix, BSD;
{$ENDIF}

// ============================================================================
// TSocketPollerFactory 实现
// ============================================================================

{ TSocketPollerFactory }

class function TSocketPollerFactory.CreateBest(AMaxSockets: Integer): IAdvancedSocketPoller;
begin
  {$IFDEF FAFAFA_SOCKET_POLLER_EXPERIMENTAL}
    {$IFDEF WINDOWS}
    Result := CreateIOCP(AMaxSockets);
    {$ELSEIF LINUX}
    Result := CreateEpoll(AMaxSockets);
    {$ELSEIF DARWIN}
    Result := CreateKqueue(AMaxSockets);
    {$ELSE}
    Result := CreateSelect(AMaxSockets);
    {$ENDIF}
  {$ELSE}
    // 默认保守：使用跨平台的增强Select轮询器
    Result := CreateSelect(AMaxSockets);
  {$ENDIF}
end;

class function TSocketPollerFactory.CreateSelect(AMaxSockets: Integer): IAdvancedSocketPoller;
begin
  Result := TEnhancedSelectPoller.Create(AMaxSockets);
end;

{$IFDEF WINDOWS}
class function TSocketPollerFactory.CreateIOCP(AMaxSockets: Integer): IAdvancedSocketPoller;
begin
  {$IFDEF FAFAFA_SOCKET_POLLER_EXPERIMENTAL}
  Result := TIOCPSocketPoller.Create(AMaxSockets);
  {$ELSE}
  // 未启用实验后端：回退到 Select 增强版
  Result := TEnhancedSelectPoller.Create(AMaxSockets);
  {$ENDIF}
end;
{$ENDIF}

{$IFDEF LINUX}
class function TSocketPollerFactory.CreateEpoll(AMaxSockets: Integer): IAdvancedSocketPoller;
begin
  Result := TEpollSocketPoller.Create(AMaxSockets);
end;
{$ENDIF}

{$IFDEF DARWIN}
class function TSocketPollerFactory.CreateKqueue(AMaxSockets: Integer): IAdvancedSocketPoller;
begin
  Result := TKqueueSocketPoller.Create(AMaxSockets);
end;
{$ENDIF}

class function TSocketPollerFactory.GetAvailablePollers: TStringArray;
begin
  SetLength(Result, 0);

  {$IFDEF FAFAFA_SOCKET_POLLER_EXPERIMENTAL}
    {$IFDEF WINDOWS}
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := 'IOCP';
    {$ENDIF}

    {$IFDEF LINUX}
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := 'epoll';
    {$ENDIF}

    {$IFDEF DARWIN}
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)] := 'kqueue';
    {$ENDIF}
  {$ENDIF}

  // select 永远可用
  SetLength(Result, Length(Result) + 1);
  Result[High(Result)] := 'select';
end;

class function TSocketPollerFactory.GetRecommendedPoller: string;
begin
  {$IFDEF FAFAFA_SOCKET_POLLER_EXPERIMENTAL}
    {$IFDEF WINDOWS}
    Result := 'IOCP';
    {$ELSEIF LINUX}
    Result := 'epoll';
    {$ELSEIF DARWIN}
    Result := 'kqueue';
    {$ELSE}
    Result := 'select';
    {$ENDIF}
  {$ELSE}
    Result := 'select';
  {$ENDIF}
end;

// ============================================================================
// TAdvancedSocketPollerBase 实现
// ============================================================================

{ TAdvancedSocketPollerBase }

constructor TAdvancedSocketPollerBase.Create(AMaxSockets: Integer);
begin
  inherited Create;
  FMaxSockets := AMaxSockets;
  FMaxEvents := 1024;
  FEdgeTriggered := False;
  FOneShot := False;
  FStopped := False;

  SetLength(FSockets, 0);
  SetLength(FReadyResults, 0);

  InitCriticalSection(FLock);

  // 初始化性能指标
  FillChar(FMetrics, SizeOf(FMetrics), 0);
  FMetrics.PollerType := GetPollerType;
  FMetrics.LastResetTime := Now;
end;

destructor TAdvancedSocketPollerBase.Destroy;
begin
  Stop;
  DoneCriticalSection(FLock);
  inherited Destroy;
end;

function TAdvancedSocketPollerBase.FindSocketIndex(const ASocket: ISocket): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FSockets) do
  begin
    if FSockets[I].Socket = ASocket then
    begin
      Result := I;
      Break;
    end;
  end;
end;

procedure TAdvancedSocketPollerBase.RemoveSocketAt(AIndex: Integer);
var
  I: Integer;
begin
  if (AIndex >= 0) and (AIndex < Length(FSockets)) then
  begin
    for I := AIndex to High(FSockets) - 1 do
      FSockets[I] := FSockets[I + 1];
    SetLength(FSockets, Length(FSockets) - 1);
  end;
end;

procedure TAdvancedSocketPollerBase.UpdateMetrics(AEventCount: Integer; ALatencyMs: Double);
var
  LElapsedSec: Double;
begin
  EnterCriticalSection(FLock);
  try
    Inc(FMetrics.TotalEvents, AEventCount);

    LElapsedSec := (Now - FMetrics.LastResetTime) * 24 * 3600;
    if LElapsedSec > 0 then
      FMetrics.EventsPerSecond := FMetrics.TotalEvents / LElapsedSec;

    // 计算平均延迟（简单移动平均）
    if FMetrics.AverageLatencyMs = 0 then
      FMetrics.AverageLatencyMs := ALatencyMs
    else
      FMetrics.AverageLatencyMs := (FMetrics.AverageLatencyMs * 0.9) + (ALatencyMs * 0.1);

    FMetrics.RegisteredSockets := Length(FSockets);
    if FMetrics.RegisteredSockets > FMetrics.MaxConcurrentSockets then
      FMetrics.MaxConcurrentSockets := FMetrics.RegisteredSockets;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TAdvancedSocketPollerBase.RegisterSocket(const ASocket: ISocket; AEvents: TSocketEvents; ACallback: TSocketEventCallback);
var
  LIndex: Integer;
begin
  if FStopped then
    raise EInvalidOperation.Create('轮询器已停止');

  if not Assigned(ASocket) then
    raise EArgumentNil.Create('Socket不能为空');

  if Length(FSockets) >= FMaxSockets then
    raise EInvalidOperation.Create('已达到最大Socket数量限制');

  EnterCriticalSection(FLock);
  try
    // 检查是否已注册
    LIndex := FindSocketIndex(ASocket);
    if LIndex >= 0 then
      raise EInvalidOperation.Create('Socket已经注册');

    // 调用平台特定的注册方法
    if DoRegisterSocket(ASocket, AEvents) then
    begin
      // 添加到内部列表
      SetLength(FSockets, Length(FSockets) + 1);
      with FSockets[High(FSockets)] do
      begin
        Socket := ASocket;
        Events := AEvents;
        Callback := ACallback;
        RegisterTime := Now;
      end;
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TAdvancedSocketPollerBase.UnregisterSocket(const ASocket: ISocket);
var
  LIndex: Integer;
begin
  EnterCriticalSection(FLock);
  try
    LIndex := FindSocketIndex(ASocket);
    if LIndex >= 0 then
    begin
      DoUnregisterSocket(ASocket);
      RemoveSocketAt(LIndex);
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TAdvancedSocketPollerBase.ModifyEvents(const ASocket: ISocket; AEvents: TSocketEvents);
var
  LIndex: Integer;
begin
  EnterCriticalSection(FLock);
  try
    LIndex := FindSocketIndex(ASocket);
    if LIndex >= 0 then
    begin
      if DoModifyEvents(ASocket, AEvents) then
        FSockets[LIndex].Events := AEvents;
    end
    else
      raise EArgumentException.Create('Socket未注册');
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAdvancedSocketPollerBase.Poll(ATimeoutMs: Integer): Integer;
var
  LStartTime: TDateTime;
  LLatency: Double;
begin
  if FStopped then
  begin
    Result := 0;
    Exit;
  end;

  LStartTime := Now;
  Result := DoPoll(ATimeoutMs, FMaxEvents);
  LLatency := (Now - LStartTime) * 24 * 3600 * 1000; // 转换为毫秒

  UpdateMetrics(Result, LLatency);
end;

function TAdvancedSocketPollerBase.GetReadyEvents: TSocketPollResults;
begin
  EnterCriticalSection(FLock);
  try
    Result := Copy(FReadyResults);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAdvancedSocketPollerBase.PollAsync: Integer;
begin
  Result := Poll(0); // 非阻塞轮询
end;

procedure TAdvancedSocketPollerBase.Stop;
begin
  FStopped := True;
end;

function TAdvancedSocketPollerBase.GetRegisteredCount: Integer;
begin
  EnterCriticalSection(FLock);
  try
    Result := Length(FSockets);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAdvancedSocketPollerBase.GetStatistics: string;
var
  LMetrics: TPollerMetrics;
begin
  LMetrics := GetPerformanceMetrics;
  Result := Format('%s轮询器: %d/%d Socket已注册, 总事件: %d, 事件/秒: %.2f, 平均延迟: %.2fms',
    [LMetrics.PollerType, LMetrics.RegisteredSockets, FMaxSockets,
     LMetrics.TotalEvents, LMetrics.EventsPerSecond, LMetrics.AverageLatencyMs]);
end;

function TAdvancedSocketPollerBase.RegisterMultiple(const ASockets: array of ISocket; AEvents: TSocketEvents): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(ASockets) do
  begin
    try
      RegisterSocket(ASockets[I], AEvents);
      Inc(Result);
    except
      // 忽略单个注册失败，继续注册其他Socket
    end;
  end;
end;

function TAdvancedSocketPollerBase.PollBatch(ATimeoutMs: Integer; AMaxEvents: Integer): TSocketPollResults;
var
  LEventCount: Integer;
begin
  LEventCount := DoPoll(ATimeoutMs, AMaxEvents);
  Result := GetReadyEvents;
end;

procedure TAdvancedSocketPollerBase.SetEdgeTriggered(AEnabled: Boolean);
begin
  FEdgeTriggered := AEnabled;
end;

procedure TAdvancedSocketPollerBase.SetOneShot(AEnabled: Boolean);
begin
  FOneShot := AEnabled;
end;

procedure TAdvancedSocketPollerBase.SetMaxEvents(AMaxEvents: Integer);
begin
  FMaxEvents := AMaxEvents;
end;

function TAdvancedSocketPollerBase.GetPerformanceMetrics: TPollerMetrics;
begin
  EnterCriticalSection(FLock);
  try
    Result := FMetrics;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TAdvancedSocketPollerBase.ResetMetrics;
begin
  EnterCriticalSection(FLock);
  try
    FillChar(FMetrics, SizeOf(FMetrics), 0);
    FMetrics.PollerType := GetPollerType;
    FMetrics.LastResetTime := Now;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAdvancedSocketPollerBase.GetMaxSockets: Integer;
begin
  Result := FMaxSockets;
end;

function TAdvancedSocketPollerBase.IsHighPerformance: Boolean;
begin

  Result := False; // 基类默认为低性能，子类重写
end;

{$IFDEF FAFAFA_SOCKET_POLLER_EXPERIMENTAL}
{$IFDEF WINDOWS}
// ============================================================================
// TIOCPSocketPoller 实现
// ============================================================================

{ TIOCPSocketPoller }

constructor TIOCPSocketPoller.Create(AMaxSockets: Integer);
begin
  inherited Create(AMaxSockets);

  {$IFDEF DEBUG}
  {$IFDEF FAFAFA_IOCP_DEBUG_VERBOSE}
  FDbgVerbose := True;
  {$ELSE}
  FDbgVerbose := False;
  {$ENDIF}
  {$ENDIF}

  SetLength(FWriteQ, 0);
  FWriteMaxPending := 1;
  FWriteBackoffMs := 0;

  // 创建完成端口
  FCompletionPort := CreateIoCompletionPort(INVALID_HANDLE_VALUE, 0, 0, 0);
  if FCompletionPort = 0 then
    raise ESocketError.Create('无法创建I/O完成端口: ' + SysErrorMessage(GetLastError));

  // 创建工作线程（通常为CPU核心数的2倍）
  FWorkerCount := GetCPUCount * 2;
  if FWorkerCount < 2 then FWorkerCount := 2;
  if FWorkerCount > 64 then FWorkerCount := 64;

  CreateWorkerThreads;
end;


destructor TIOCPSocketPoller.Destroy;
var
  I: Integer;
  {$IFDEF DEBUG}
  LPendingCount: Integer;
  {$ENDIF}
begin
  // 先停止，确保工作线程主循环可以退出
  Stop;
  DestroyWorkerThreads;

  // 在清理前记录并输出挂起信息与摘要，确保发生严格断言时日志完整
  {$IFDEF DEBUG}
  LPendingCount := Length(FRecvOps);
  if LPendingCount > 0 then
  begin
    DbgLogPendingOps('BeforeCleanup');
    DbgDumpSummary;
  end;
  {$ENDIF}

  // 清理任何剩余的占位接收资源（防泄漏）
  EnterCriticalSection(FLock);
  try
    for I := High(FRecvOps) downto 0 do
    begin
      if Assigned(FRecvOps[I].Ov) then FreeMem(FRecvOps[I].Ov);
      if Assigned(FRecvOps[I].Dummy) then FreeMem(FRecvOps[I].Dummy);
    end;
    SetLength(FRecvOps, 0);
  finally
    LeaveCriticalSection(FLock);
  end;

  {$IFDEF DEBUG}
  if LPendingCount > 0 then
  begin
    OutputDebugString(PChar(Format('[IOCP][ASSERT] Pending ops not empty at destroy: count=%d', [LPendingCount])));
    {$IFDEF FAFAFA_IOCP_DEBUG_STRICT_ASSERT}
    raise Exception.CreateFmt('IOCP pending ops not empty at destroy: count=%d', [LPendingCount]);
    {$ENDIF}
  end;
  {$ENDIF}



  if FCompletionPort <> 0 then
    CloseHandle(FCompletionPort);

  inherited Destroy;
end;

function TIOCPSocketPoller.WriteQFindIndex(AHandle: THandle): Integer;
var I: Integer;
begin
  for I := 0 to High(FWriteQ) do
    if FWriteQ[I].Handle = AHandle then Exit(I);
  Result := -1;
end;

function TIOCPSocketPoller.WriteQEnsureIndex(AHandle: THandle): Integer;
var I: Integer;
begin
  I := WriteQFindIndex(AHandle);
  if I >= 0 then Exit(I);
  SetLength(FWriteQ, Length(FWriteQ)+1);
  FWriteQ[High(FWriteQ)].Handle := AHandle;
  FWriteQ[High(FWriteQ)].Pending := 0;
  FWriteQ[High(FWriteQ)].InFlight := False;
  Result := High(FWriteQ);
end;

{$IFDEF DEBUG}
procedure TIOCPSocketPoller.DbgQueueZeroSends(const ASocket: ISocket; ACount: Integer);
var
  I, Qi: Integer;
  H: THandle;
begin
  H := THandle(ASocket.Handle);
  EnterCriticalSection(FLock);
  try
    Qi := WriteQEnsureIndex(H);
    Inc(FWriteQ[Qi].Pending, ACount);
  finally
    LeaveCriticalSection(FLock);
  end;
end;
{$ENDIF}

function TIOCPSocketPoller.PostZeroRecv(const ASocket: ISocket): Boolean;
var
  LHandle: THandle;
  LBuf: WinSock2.WSABUF;
  LBytes: DWORD;
  LFlags: DWORD;
  LOv: POVERLAPPED;
  LDummy: PAnsiChar;
  LRes: Integer;
  I: Integer;
begin
  Result := False;
  LHandle := THandle(ASocket.Handle);
  if LHandle = INVALID_HANDLE_VALUE then Exit;

  // 若该句柄已存在挂起的0字节接收，则不重复投递
  EnterCriticalSection(FLock);
  try
    for I := 0 to High(FRecvOps) do
      if FRecvOps[I].Handle = LHandle then
      begin
        Result := True;
        Exit;
      end;
  finally
    LeaveCriticalSection(FLock);
  end;

  // 分配1字节Dummy缓冲并使用 MSG_PEEK 检测可读就绪（不消耗数据）
  GetMem(LDummy, 1);
  LBuf.len := 1;
  LBuf.buf := LDummy;

  // 分配并清零OVERLAPPED
  GetMem(LOv, SizeOf(OVERLAPPED));
  FillChar(LOv^, SizeOf(OVERLAPPED), 0);

  // 先插入到跟踪表，避免极端时序下完成先于记录导致找不到条目
  EnterCriticalSection(FLock);
  try
    SetLength(FRecvOps, Length(FRecvOps) + 1);
    FRecvOps[High(FRecvOps)].Ov := LOv;
    FRecvOps[High(FRecvOps)].Dummy := LDummy;
    FRecvOps[High(FRecvOps)].Handle := LHandle;
  finally
    LeaveCriticalSection(FLock);
  end;
  {$IFDEF DEBUG}
  DbgIncPosted(LHandle);
  {$ENDIF}


  LBytes := 0;
  LFlags := WinSock2.MSG_PEEK;

  LRes := WinSock2.WSARecv(QWord(LHandle), @LBuf, 1, LBytes, LFlags, WinSock2.LPWSAOVERLAPPED(LOv), nil);
  if (LRes <> 0) and (WinSock2.WSAGetLastError <> WinSock2.WSA_IO_PENDING) then
  begin
    // 从跟踪表移除并释放资源
    EnterCriticalSection(FLock);
    try
      CleanupRecvOpByOv(LOv);
    finally
      LeaveCriticalSection(FLock);
    end;
    {$IFDEF DEBUG}
    DbgIncPostFail(LHandle);
    {$ENDIF}
    Exit;
  end;

  Result := True;
end;

function TIOCPSocketPoller.PostZeroSend(const ASocket: ISocket): Boolean;
var
  LOv: POverlapped;
  LWSABuf: TWSABuf;
  LRes: Integer;
  LHandle: THandle;
  Qi: Integer;
begin
  Result := False;
  LHandle := THandle(ASocket.Handle);
  if LHandle = INVALID_HANDLE_VALUE then Exit;

  GetMem(LOv, SizeOf(TOverlapped));
  FillChar(LOv^, SizeOf(TOverlapped), 0);

  // 使用0长度缓冲触发一次发送完成
  LWSABuf.buf := nil;
  LWSABuf.len := 0;

  EnterCriticalSection(FLock);
  try
    SetLength(FSendOps, Length(FSendOps) + 1);
    FSendOps[High(FSendOps)].Ov := LOv;
    FSendOps[High(FSendOps)].Handle := LHandle;
    FSendOps[High(FSendOps)].StartTick := GetTickCount64;
    // 入队计数+占位 in-flight 标记
    Qi := WriteQEnsureIndex(LHandle);
    Inc(FWriteQ[Qi].Pending);
    FWriteQ[Qi].InFlight := True;
  finally
    LeaveCriticalSection(FLock);
  end;

  LRes := WinSock2.WSASend(QWord(LHandle), @LWSABuf, 1, nil, 0, LPOVERLAPPED(LOv), nil);

  if (LRes <> 0) and (WinSock2.WSAGetLastError <> WinSock2.WSA_IO_PENDING) then
  begin
    EnterCriticalSection(FLock);
    try
      CleanupSendOpByOv(LOv);
      Qi := WriteQFindIndex(LHandle);
      if Qi >= 0 then
      begin
        if FWriteQ[Qi].Pending > 0 then Dec(FWriteQ[Qi].Pending);
        FWriteQ[Qi].InFlight := False;
      end;
    finally
      LeaveCriticalSection(FLock);
    end;
    {$IFDEF DEBUG}
    DbgIncPostFailWrite(LHandle);
    {$ENDIF}
    Exit;
  end;

  Result := True;
end;

procedure TIOCPSocketPoller.CleanupRecvOpByOv(AOv: Pointer);
var
  I, J: Integer;
begin
  if AOv = nil then Exit;
  // 在线性表中查找并释放
  for I := 0 to High(FRecvOps) do
  begin
    if FRecvOps[I].Ov = AOv then
    begin
      if Assigned(FRecvOps[I].Ov) then FreeMem(FRecvOps[I].Ov);
      if Assigned(FRecvOps[I].Dummy) then FreeMem(FRecvOps[I].Dummy);
      // 紧缩数组
      for J := I to High(FRecvOps)-1 do FRecvOps[J] := FRecvOps[J+1];
      SetLength(FRecvOps, Length(FRecvOps)-1);
      Break;
    end;
  end;
end;

procedure TIOCPSocketPoller.CleanupSendOpByOv(AOv: Pointer);
var
  I, J: Integer;
begin
  if AOv = nil then Exit;
  for I := 0 to High(FSendOps) do
  begin
    if FSendOps[I].Ov = AOv then
    begin
      if Assigned(FSendOps[I].Ov) then FreeMem(FSendOps[I].Ov);
      for J := I to High(FSendOps)-1 do FSendOps[J] := FSendOps[J+1];
      SetLength(FSendOps, Length(FSendOps)-1);
      Break;
    end;
  end;
end;


procedure TIOCPSocketPoller.CreateWorkerThreads;
var
  I: Integer;
begin
  SetLength(FWorkerThreads, FWorkerCount);

  for I := 0 to FWorkerCount - 1 do
  begin
    FWorkerThreads[I] := TThread.CreateAnonymousThread(procedure
      var

        LBytesTransferred: DWORD;
        LCompletionKey: ULONG_PTR;
        LOverlapped: POVERLAPPED;
        LSocket: ISocket;
        LEvents: TSocketEvents;
        LNeedRepost: Boolean;

        LIndex: Integer;
      begin
        while not FStopped do
        begin
          try
            if GetQueuedCompletionStatus(FCompletionPort, LBytesTransferred,
               LCompletionKey, LOverlapped, 100) then
            begin
              // 处理完成的I/O操作
              LSocket := ISocket(Pointer(LCompletionKey));
              if Assigned(LSocket) then
              begin
                // 先获取完成状态（区分取消与真正关闭），避免清理后失去上下文
                var LErr: Integer := 0;
                var LFlags: DWORD := 0;
                var LBytes: DWORD := LBytesTransferred;
                var LHandle: THandle := THandle(LSocket.Handle);
                var LIsSend: Boolean := False;
                var I: Integer;
                if (LHandle <> INVALID_HANDLE_VALUE) then
                begin
                  if not WinSock2.WSAGetOverlappedResult(QWord(LHandle), WinSock2.LPWSAOVERLAPPED(LOverlapped), @LBytes, False, @LFlags) then
                    LErr := WinSock2.WSAGetLastError;
                end;

                // 判断该完成是否来自发送投递
                EnterCriticalSection(FLock);
                try
                  for I := 0 to High(FSendOps) do
                    if FSendOps[I].Ov = LOverlapped then
                    begin
                      LIsSend := True;
                      Break;
                    end;
                finally
                  LeaveCriticalSection(FLock);
                end;

                // 记录是否需要重投递（避免长时间持锁后再进行 WinSock 调用）
                LNeedRepost := False;

                // 根据结果构造事件（取消不视为关闭）
                LEvents := [];
                if LErr = WinSock2.WSA_OPERATION_ABORTED then
                begin
                  // 取消：不派发 seClose，不重投递
                  {$IFDEF DEBUG}
                  if FDbgVerbose then
                    OutputDebugString(PChar(Format('[IOCP] Canceled: handle=%d ov=%p',[Integer(LHandle), Pointer(LOverlapped)])));
                  DbgIncCanceled(LHandle);
                  {$ENDIF}
                end
                else
                begin
                  if LIsSend then
                  begin
                    Include(LEvents, seWrite);
                    {$IFDEF DEBUG}
                    if FDbgVerbose then
                      OutputDebugString(PChar(Format('[IOCP] Completed WRITE: handle=%d ov=%p',[Integer(LHandle), Pointer(LOverlapped)])));
                    DbgIncWrite(LHandle);
                    {$ENDIF}
                  end
                  else if LBytes > 0 then
                  begin
                    Include(LEvents, seRead);
                    {$IFDEF DEBUG}
                    if FDbgVerbose then
                      OutputDebugString(PChar(Format('[IOCP] Completed READ: bytes=%d handle=%d ov=%p',[Integer(LBytes), Integer(LHandle), Pointer(LOverlapped)])));
                    DbgIncRead(LHandle);
                    {$ENDIF}
                  end
                  else
                  begin
                    Include(LEvents, seClose);
                    {$IFDEF DEBUG}
                    if FDbgVerbose then
                      OutputDebugString(PChar(Format('[IOCP] Completed CLOSE: handle=%d ov=%p',[Integer(LHandle), Pointer(LOverlapped)])));
                    DbgIncClose(LHandle);
                    {$ENDIF}
                  end;
                end;

                // 添加到就绪结果并回调
                EnterCriticalSection(FLock);
                try
                  LIndex := FindSocketIndex(LSocket);
                  if LIndex >= 0 then
                  begin
                    if LEvents <> [] then
                    begin
                      SetLength(FReadyResults, Length(FReadyResults) + 1);
                      with FReadyResults[High(FReadyResults)] do
                      begin
                        Socket := LSocket;
                        Events := LEvents;
                      end;

                      if Assigned(FSockets[LIndex].Callback) then
                        FSockets[LIndex].Callback(LSocket, LEvents);
                    end;

                    // 非一次性且仍对可读感兴趣，且未检测到关闭或取消时，重投递 0 字节接收
                    if (not LIsSend) and (LErr = 0) and (not FOneShot) and (seRead in FSockets[LIndex].Events) and not (seClose in LEvents) then
                    begin
                      // 仅当句柄仍有效且未停止时考虑重投递
                      if (THandle(LSocket.Handle) <> INVALID_HANDLE_VALUE) and (not FStopped) then
                        LNeedRepost := True;
                    end;
                  end;
                finally
                  LeaveCriticalSection(FLock);
                end;

                // 最后清理与该完成关联的占位缓冲与结构
                EnterCriticalSection(FLock);
                try
                  if LIsSend then
                  begin
                    // 计算写延迟（ms）
                    var StartTick: QWord := 0;
                    EnterCriticalSection(FLock);
                    try
                      for I := 0 to High(FSendOps) do
                        if FSendOps[I].Ov = LOverlapped then
                        begin
                          StartTick := FSendOps[I].StartTick;
                          Break;
                        end;
                    finally
                      LeaveCriticalSection(FLock);
                    end;
                    if StartTick <> 0 then
                      {$IFDEF DEBUG}DbgAddWriteLatency(LHandle, Word(GetTickCount64 - StartTick));{$ENDIF}

                    CleanupSendOpByOv(LOverlapped);
                    // 回退写队列计数
                    I := WriteQFindIndex(LHandle);
                    if I >= 0 then
                    begin
                      if FWriteQ[I].Pending > 0 then Dec(FWriteQ[I].Pending);
                      // 若没有 Pending 了则清 InFlight
                      if FWriteQ[I].Pending = 0 then FWriteQ[I].InFlight := False;
                    end;
                  end
                  else
                    CleanupRecvOpByOv(LOverlapped);
                finally
                  LeaveCriticalSection(FLock);
                end;

                if LNeedRepost and (not FStopped) then
                  PostZeroRecv(LSocket);
              end;
            end;
          except
            // 忽略工作线程中的异常
          end;
        end;
      end);

    FWorkerThreads[I].Start;
  end;
end;

procedure TIOCPSocketPoller.DestroyWorkerThreads;
var
  I, J: Integer;
  LLastHandle: THandle;
begin
  // 优先尝试取消所有挂起的I/O，加速完成回调并减少等待
  EnterCriticalSection(FLock);
  try
    LLastHandle := INVALID_HANDLE_VALUE;
    // Cancel pending recvs
    for I := 0 to High(FRecvOps) do
    begin
      if (FRecvOps[I].Handle <> INVALID_HANDLE_VALUE) and (FRecvOps[I].Handle <> LLastHandle) then
      begin
        {$IFDEF WINDOWS}
        CancelIoEx(FRecvOps[I].Handle, nil);
        {$ENDIF}
        LLastHandle := FRecvOps[I].Handle;
      end;
    end;
    // Best-effort cleanup send ops (all)
    for I := High(FSendOps) downto 0 do
      CleanupSendOpByOv(FSendOps[I].Ov);
    // 清空写队列
    SetLength(FWriteQ, 0);
  finally
    LeaveCriticalSection(FLock);
  end;

  {$IFDEF DEBUG}
  DbgLogPendingOps('BeforeStop');
  {$ENDIF}

  // 通知所有工作线程停止
  for J := 0 to FWorkerCount - 1 do
    PostQueuedCompletionStatus(FCompletionPort, 0, 0, nil);

  // 等待工作线程结束
  for J := 0 to High(FWorkerThreads) do
  begin
    if Assigned(FWorkerThreads[J]) then
    begin
      FWorkerThreads[J].WaitFor;
      FWorkerThreads[J].Free;
    end;
  end;

  {$IFDEF DEBUG}
  DbgLogPendingOps('AfterJoin');
  {$ENDIF}

  SetLength(FWorkerThreads, 0);
end;

function TIOCPSocketPoller.DoRegisterSocket(const ASocket: ISocket; AEvents: TSocketEvents): Boolean;
var
  LHandle: THandle;
begin
  Result := False;

  LHandle := THandle(ASocket.Handle);
  if LHandle = INVALID_HANDLE_VALUE then
    Exit;

  // 将Socket句柄关联到完成端口
  if CreateIoCompletionPort(LHandle, FCompletionPort, ULONG_PTR(Pointer(ASocket)), 0) = 0 then
    Exit;

  // 最小实现：对可读感兴趣时投递一次0字节接收
  if seRead in AEvents then
    PostZeroRecv(ASocket);

  Result := True;
end;

function TIOCPSocketPoller.DoUnregisterSocket(const ASocket: ISocket): Boolean;
var
  LHandle: THandle;
begin
  // 仅取消未完成I/O；内存释放由完成回调路径统一处理，避免重复释放
  LHandle := THandle(ASocket.Handle);
  if LHandle <> INVALID_HANDLE_VALUE then
  begin
    {$IFDEF WINDOWS}
    CancelIoEx(LHandle, nil);
    {$ENDIF}
  end;
  Result := True;
end;

function TIOCPSocketPoller.DoPoll(ATimeoutMs: Integer; AMaxEvents: Integer): Integer;
begin
  // IOCP是异步的，轮询操作由工作线程处理
  // 这里只是返回当前就绪事件的数量
  EnterCriticalSection(FLock);
  try
    Result := Length(FReadyResults);
    // 清空就绪结果，为下次轮询做准备
    SetLength(FReadyResults, 0);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TIOCPSocketPoller.DoModifyEvents(const ASocket: ISocket; AEvents: TSocketEvents): Boolean;
var
  LHandle: THandle;
  LIndex: Integer;
begin
  // 读兴趣：确保至少一个0字节接收在排队；取消兴趣时仅发起取消，由完成路径统一释放
  Result := True;
  if seRead in AEvents then
  begin
    // 轻量：尝试补一次（若已经有挂起的不影响，由于会返回 PENDING）
    PostZeroRecv(ASocket);
  end
  else
  begin
    LHandle := THandle(ASocket.Handle);
    if LHandle <> INVALID_HANDLE_VALUE then
    begin
      {$IFDEF WINDOWS}
      CancelIoEx(LHandle, nil);
      {$ENDIF}
    end;
  end;

  if seWrite in AEvents then
  begin
    // 简单阈值与退避控制（仅针对 0 字节发送的演示投递）
    LHandle := THandle(ASocket.Handle);
    EnterCriticalSection(FLock);
    try
      LIndex := WriteQEnsureIndex(LHandle);
      if (FWriteMaxPending > 0) and (FWriteQ[LIndex].Pending >= FWriteMaxPending) then
      begin
        {$IFDEF DEBUG}
        if FDbgVerbose then
          OutputDebugString(PChar(Format('[IOCP][WRITE] Skip post due to pending threshold: h=%d pend=%d max=%d',
            [Integer(LHandle), FWriteQ[LIndex].Pending, FWriteMaxPending])));
        {$ENDIF}
        if FWriteBackoffMs > 0 then Sleep(FWriteBackoffMs);
        LeaveCriticalSection(FLock);
        Exit(True);
      end;
    finally
      // 注意：后续 PostZeroSend 内部也会加锁修改队列
      LeaveCriticalSection(FLock);
    end;

    // 最小写投递：投递一次 0 字节发送以触发 seWrite 完成
    PostZeroSend(ASocket);
  end;
end;

function TIOCPSocketPoller.GetPollerType: string;
begin
  Result := 'IOCP';
end;

function TIOCPSocketPoller.IsHighPerformance: Boolean;
begin
  Result := True;
end;

{$ENDIF} // WINDOWS
{$ENDIF} // FAFAFA_SOCKET_POLLER_EXPERIMENTAL

{$IFDEF FAFAFA_SOCKET_POLLER_EXPERIMENTAL}
{$IFDEF LINUX}
// ============================================================================
// TEpollSocketPoller 实现
// ============================================================================

{ TEpollSocketPoller }

constructor TEpollSocketPoller.Create(AMaxSockets: Integer);
begin
  inherited Create(AMaxSockets);

  // 创建epoll实例
  FEpollFd := epoll_create1(0);
  if FEpollFd = -1 then
    raise ESocketError.Create('无法创建epoll实例: ' + SysErrorMessage(fpGetErrno));

  // 预分配事件数组
  SetLength(FEvents, FMaxEvents);
end;

destructor TEpollSocketPoller.Destroy;
begin
  if FEpollFd <> -1 then
    fpClose(FEpollFd);

  inherited Destroy;
end;

function TEpollSocketPoller.DoRegisterSocket(const ASocket: ISocket; AEvents: TSocketEvents): Boolean;
var
  LEvent: TEpollEvent;
  LFd: Integer;
begin
  Result := False;

  LFd := ASocket.Handle;
  if LFd = -1 then
    Exit;

  // 设置事件
  FillChar(LEvent, SizeOf(LEvent), 0);
  LEvent.data.ptr := Pointer(ASocket);

  if seRead in AEvents then
    LEvent.events := LEvent.events or EPOLLIN;
  if seWrite in AEvents then
    LEvent.events := LEvent.events or EPOLLOUT;
  if (seError in AEvents) or (seClose in AEvents) then
    LEvent.events := LEvent.events or EPOLLERR or EPOLLHUP;

  // 设置边缘触发模式
  if FEdgeTriggered then
    LEvent.events := LEvent.events or EPOLLET;

  // 设置一次性模式
  if FOneShot then
    LEvent.events := LEvent.events or EPOLLONESHOT;

  // 添加到epoll
  Result := epoll_ctl(FEpollFd, EPOLL_CTL_ADD, LFd, @LEvent) = 0;
end;

function TEpollSocketPoller.DoUnregisterSocket(const ASocket: ISocket): Boolean;
var
  LFd: Integer;
begin
  LFd := ASocket.Handle;
  if LFd = -1 then
  begin
    Result := True;
    Exit;
  end;

  Result := epoll_ctl(FEpollFd, EPOLL_CTL_DEL, LFd, nil) = 0;
end;

function TEpollSocketPoller.DoPoll(ATimeoutMs: Integer; AMaxEvents: Integer): Integer;
var
  I: Integer;
  LSocket: ISocket;
  LEvents: TSocketEvents;
  LIndex: Integer;
begin
  Result := 0;

  if AMaxEvents > Length(FEvents) then
    SetLength(FEvents, AMaxEvents);

  // 清空之前的结果
  SetLength(FReadyResults, 0);

  // 等待事件
  Result := epoll_wait(FEpollFd, @FEvents[0], AMaxEvents, ATimeoutMs);

  if Result > 0 then
  begin
    FLock.Enter;
    try
      SetLength(FReadyResults, Result);

      for I := 0 to Result - 1 do
      begin
        LSocket := ISocket(FEvents[I].data.ptr);
        if Assigned(LSocket) then
        begin
          // 转换epoll事件到Socket事件
          LEvents := [];
          if (FEvents[I].events and EPOLLIN) <> 0 then
            Include(LEvents, seRead);
          if (FEvents[I].events and EPOLLOUT) <> 0 then
            Include(LEvents, seWrite);
          if (FEvents[I].events and EPOLLERR) <> 0 then
            Include(LEvents, seError);
          if (FEvents[I].events and EPOLLHUP) <> 0 then
            Include(LEvents, seClose);

          FReadyResults[I].Socket := LSocket;
          FReadyResults[I].Events := LEvents;

          // 查找并调用回调
          LIndex := FindSocketIndex(LSocket);
          if (LIndex >= 0) and Assigned(FSockets[LIndex].Callback) then
            FSockets[LIndex].Callback(LSocket, LEvents);
        end;
      end;
    finally
      FLock.Leave;
    end;
  end;
end;

function TEpollSocketPoller.DoModifyEvents(const ASocket: ISocket; AEvents: TSocketEvents): Boolean;
var
  LEvent: TEpollEvent;
  LFd: Integer;
begin
  Result := False;

  LFd := ASocket.Handle;
  if LFd = -1 then
    Exit;

  // 设置新的事件
  FillChar(LEvent, SizeOf(LEvent), 0);
  LEvent.data.ptr := Pointer(ASocket);

  if seRead in AEvents then
    LEvent.events := LEvent.events or EPOLLIN;
  if seWrite in AEvents then
    LEvent.events := LEvent.events or EPOLLOUT;
  if (seError in AEvents) or (seClose in AEvents) then
    LEvent.events := LEvent.events or EPOLLERR or EPOLLHUP;

  if FEdgeTriggered then
    LEvent.events := LEvent.events or EPOLLET;
  if FOneShot then
    LEvent.events := LEvent.events or EPOLLONESHOT;

  Result := epoll_ctl(FEpollFd, EPOLL_CTL_MOD, LFd, @LEvent) = 0;
end;

function TEpollSocketPoller.GetPollerType: string;
begin
  Result := 'epoll';
  if FEdgeTriggered then
    Result := Result + ' (ET)';
  if FOneShot then
    Result := Result + ' (ONESHOT)';
end;

function TEpollSocketPoller.IsHighPerformance: Boolean;
begin
  Result := True;
end;

{$ENDIF} // LINUX
{$ENDIF} // FAFAFA_SOCKET_POLLER_EXPERIMENTAL

// ============================================================================
// TEnhancedSelectPoller 实现（跨平台兼容）
// ============================================================================

{ TEnhancedSelectPoller }

function TEnhancedSelectPoller.DoRegisterSocket(const ASocket: ISocket; AEvents: TSocketEvents): Boolean;
begin
  // Select轮询器的注册只是添加到内部列表，实际的fd_set在Poll时构建
  Result := True;
end;

function TEnhancedSelectPoller.DoUnregisterSocket(const ASocket: ISocket): Boolean;
begin
  // Select轮询器的注销只是从内部列表移除
  Result := True;
end;

function TEnhancedSelectPoller.DoPoll(ATimeoutMs: Integer; AMaxEvents: Integer): Integer;
{$IFDEF WINDOWS}
var
  LReadSet, LWriteSet, LErrorSet: TFDSet;
  {$IFDEF WINDOWS}LTimeout: timeval;{$ELSE}LTimeout: TTimeVal;{$ENDIF}
  LResult: Integer;
  I: Integer;
  LHandle: TSocketHandle;
  LMaxHandle: TSocketHandle;
  LSocket: ISocket;
  LEvents: TSocketEvents;
  LIndex: Integer;
{$ENDIF}
begin
  Result := 0;
  SetLength(FReadyResults, 0);

  if FStopped or (Length(FSockets) = 0) then
    Exit;

{$IFDEF WINDOWS}
  // Windows实现使用select
  FD_ZERO(LReadSet);
  FD_ZERO(LWriteSet);
  FD_ZERO(LErrorSet);
  LMaxHandle := 0;

  EnterCriticalSection(FLock);
  try
    // 添加Socket到相应的集合
    for I := 0 to High(FSockets) do
    begin
      LHandle := FSockets[I].Socket.Handle;
      if LHandle <> INVALID_SOCKET then
      begin
        if seRead in FSockets[I].Events then
          FD_SET(LHandle, LReadSet);
        if seWrite in FSockets[I].Events then
          FD_SET(LHandle, LWriteSet);
        if (seError in FSockets[I].Events) or (seClose in FSockets[I].Events) then
          FD_SET(LHandle, LErrorSet);
        if LHandle > LMaxHandle then
          LMaxHandle := LHandle;
      end;
    end;
  finally
    LeaveCriticalSection(FLock);
  end;

  // 设置超时
  if ATimeoutMs >= 0 then
  begin
    LTimeout.tv_sec := ATimeoutMs div 1000;
    LTimeout.tv_usec := (ATimeoutMs mod 1000) * 1000;
    LResult := select(LMaxHandle + 1, @LReadSet, @LWriteSet, @LErrorSet, @LTimeout);
  end
  else
    LResult := select(LMaxHandle + 1, @LReadSet, @LWriteSet, @LErrorSet, nil);

  if LResult > 0 then
  begin
    EnterCriticalSection(FLock);
    try
      // 检查就绪的Socket
      for I := 0 to High(FSockets) do
      begin
        LHandle := FSockets[I].Socket.Handle;
        if LHandle <> INVALID_SOCKET then
        begin
          LEvents := [];

          if FD_ISSET(LHandle, LReadSet) then
            Include(LEvents, seRead);
          if FD_ISSET(LHandle, LWriteSet) then
            Include(LEvents, seWrite);
          if FD_ISSET(LHandle, LErrorSet) then
          begin
            Include(LEvents, seError);
            Include(LEvents, seClose);
          end;

          if LEvents <> [] then
          begin
            SetLength(FReadyResults, Length(FReadyResults) + 1);
            with FReadyResults[High(FReadyResults)] do
            begin
              Socket := FSockets[I].Socket;
              Events := LEvents;
            end;

            // 调用回调
            if Assigned(FSockets[I].Callback) then
              FSockets[I].Callback(FSockets[I].Socket, LEvents);

            Inc(Result);
          end;
        end;
      end;
    finally
      LeaveCriticalSection(FLock);
    end;
  end;
{$ELSE}
  // Linux/Unix实现使用fpSelect（简化版）
  // 这里可以扩展为更完整的Unix select实现
  Result := 0; // 暂时返回0，表示没有事件
{$ENDIF}
end;

function TEnhancedSelectPoller.DoModifyEvents(const ASocket: ISocket; AEvents: TSocketEvents): Boolean;
begin
  // Select轮询器的事件修改只需要更新内部列表
  Result := True;
end;

function TEnhancedSelectPoller.GetPollerType: string;
begin
  Result := 'select (增强版)';
end;

function TEnhancedSelectPoller.IsHighPerformance: Boolean;
begin
  Result := False; // Select是兼容性方案，不是高性能方案
end;

end.
