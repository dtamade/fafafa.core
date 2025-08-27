unit fafafa.core.mem.pool.fixed.tl;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, {$if defined(Windows)}Windows,{$endif} SyncObjs,
  fafafa.core.mem.pool.base,
  fafafa.core.mem.pool.fixed,
  fafafa.core.mem.allocator;

// 说明（原型）：
// - Thread-Local 变体：每线程一个内部 TFixedPool
// - Acquire：优先访问当前线程池；Release：若指针不属于本线程池，则按指针归属路由到目标线程的 inbox 队列
// - 目标：每线程 inbox 降低全局争用；仍保留全局回退队列以保证稳健性

 type
  TFixedPoolTL = class(TInterfacedObject, IPool)
  private
    type
      TRangeInbox = record
        Pool: TFixedPool;
        InboxBuf: array of Pointer;
        Head, Tail, Count: Integer;
        InboxLock: TRTLCriticalSection;
      end;
  private
    FCapacityPerThread: Integer;
    FBlockSize: SizeUInt;
    FAlignment: SizeUInt;
    FAllocator: IAllocator;
    // 线程本地池（TLS）
    class threadvar ThreadPool: TFixedPool;
    class threadvar ThreadIndex: Integer;
    class threadvar ThreadIndexValid: Boolean;
    // 每线程 inbox 注册表（全局）
    class var Registry: array of TRangeInbox;
    class var RegistryLock: TRTLCriticalSection;
    // 回退全局跨线程队列
    class var CrossQueue: array of Pointer;
    class var CrossLock: TRTLCriticalSection;
    class var LocksInitState: LongInt; // 0=uninit, 1=done
    // 统计（可选）
    // 页→池快速路由（读多写少）
    class var PageMapLock: TRTLCriticalSection;
    class var PageSize: SizeUInt;
    class var PageMask: PtrUInt;
    class var PageMap: array of record PageBase: PtrUInt; Pool: TFixedPool; end;
    class var PageMapCount: Integer;
    class var PageMapCap: Integer;

    class var StatsInboxPush: QWord;
    class var StatsInboxDrain: QWord;
    class var StatsCrossPush: QWord;
  private
    function EnsureThreadPool: TFixedPool;
  public
    constructor Create(ABlockSize: SizeUInt; ACapacityPerThread: Integer; AAlignment: SizeUInt = 0; AAllocator: IAllocator = nil);
    destructor Destroy; override;
    class procedure ThreadCleanup; // 供线程退出前调用：注销/冲刷当前线程
  public
    // IPool
    function Acquire(out AUnit: Pointer): Boolean;
    function TryAcquire(out AUnit: Pointer): Boolean;
    function AcquireN(out AUnits: array of Pointer; aCount: Integer): Integer;
    procedure Release(AUnit: Pointer);
    procedure ReleaseN(const AUnits: array of Pointer; aCount: Integer);
    procedure Reset;
  end;

implementation

// forward decls (unit private helpers)

procedure EnsureGlobalLocks; forward;
procedure RegisterThreadPool(tp: TFixedPool); forward;
function FindInboxByPtr(p: Pointer; out idx: Integer): Boolean; forward;
function GetRegistryIndexForPool(tp: TFixedPool): Integer; forward;
procedure DrainInboxOfIndex(idx: Integer; SelfTP: TFixedPool); forward;
procedure SiphonCrossQueueFor(SelfTP: TFixedPool); forward;

{ TFixedPoolTL }

constructor TFixedPoolTL.Create(ABlockSize: SizeUInt; ACapacityPerThread: Integer; AAlignment: SizeUInt; AAllocator: IAllocator);
begin
  inherited Create;
  if ACapacityPerThread <= 0 then
    raise Exception.Create('CapacityPerThread must be positive');
  FBlockSize := ABlockSize;
  FAlignment := AAlignment;
  FCapacityPerThread := ACapacityPerThread;
  if AAllocator = nil then FAllocator := fafafa.core.mem.allocator.GetRtlAllocator else FAllocator := AAllocator;
  // 初始化全局结构
  EnsureGlobalLocks;
  SetLength(CrossQueue, 0);
end;

destructor TFixedPoolTL.Destroy;
var idx: Integer; SelfTP: TFixedPool;
begin
  // 冲刷：先将属于本线程池的跨线程指针吸回
  SelfTP := ThreadPool;
  if SelfTP <> nil then
  begin
    DrainInboxOfIndex(GetRegistryIndexForPool(SelfTP), SelfTP);
    SiphonCrossQueueFor(SelfTP);
  end;
  // 注销：从 Registry 移除自身条目，并释放 InboxLock
  idx := GetRegistryIndexForPool(SelfTP);
  if idx >= 0 then
  begin
    EnterCriticalSection(TFixedPoolTL.RegistryLock);
    try
      DoneCriticalsection(TFixedPoolTL.Registry[idx].InboxLock);
      // 将最后一个条目移到 idx，收缩长度
      if idx <> High(TFixedPoolTL.Registry) then
        TFixedPoolTL.Registry[idx] := TFixedPoolTL.Registry[High(TFixedPoolTL.Registry)];
      SetLength(TFixedPoolTL.Registry, Length(TFixedPoolTL.Registry)-1);
    finally
      LeaveCriticalSection(TFixedPoolTL.RegistryLock);
    end;
  end;
  // 释放本线程池
  if ThreadPool <> nil then
    FreeAndNil(ThreadPool);
  inherited Destroy;
end;

class procedure TFixedPoolTL.ThreadCleanup;
var idx: Integer; tp: TFixedPool;
begin
  tp := ThreadPool;
  if tp = nil then Exit;
  DrainInboxOfIndex(GetRegistryIndexForPool(tp), tp);
  SiphonCrossQueueFor(tp);
  idx := GetRegistryIndexForPool(tp);
  if idx >= 0 then
  begin
    EnterCriticalSection(TFixedPoolTL.RegistryLock);
    try
      DoneCriticalsection(TFixedPoolTL.Registry[idx].InboxLock);
      if idx <> High(TFixedPoolTL.Registry) then
        TFixedPoolTL.Registry[idx] := TFixedPoolTL.Registry[High(TFixedPoolTL.Registry)];
      SetLength(TFixedPoolTL.Registry, Length(TFixedPoolTL.Registry)-1);
    finally
      LeaveCriticalSection(TFixedPoolTL.RegistryLock);
    end;
  end;
  FreeAndNil(ThreadPool);
  ThreadIndexValid := False;
  ThreadIndex := -1;
end;


function PageBaseOf(p: Pointer): PtrUInt; inline;
begin
  Result := PtrUInt(PtrUInt(p) and not TFixedPoolTL.PageMask);
end;

function FindInboxByPtrFast(p: Pointer; out idx: Integer): Boolean;
var base: PtrUInt; i: Integer;
begin
  Result := False; idx := -1;
  if TFixedPoolTL.PageSize = 0 then Exit(False);
  base := PageBaseOf(p);
  EnterCriticalSection(TFixedPoolTL.PageMapLock);
  try
    for i := 0 to TFixedPoolTL.PageMapCount-1 do
      if TFixedPoolTL.PageMap[i].PageBase = base then begin idx := GetRegistryIndexForPool(TFixedPoolTL.PageMap[i].Pool); Exit(idx >= 0); end;
  finally
    LeaveCriticalSection(TFixedPoolTL.PageMapLock);
  end;
end;

  end;
  // 释放本线程池
  if ThreadPool <> nil then
    FreeAndNil(ThreadPool);
  inherited Destroy;
end;

procedure EnsureGlobalLocks;
begin
  if InterlockedCompareExchange(TFixedPoolTL.LocksInitState, 1, 0) = 0 then
  begin
    InitCriticalSection(TFixedPoolTL.RegistryLock);
    InitCriticalSection(TFixedPoolTL.CrossLock);
    InitCriticalSection(TFixedPoolTL.PageMapLock);
    // 默认按 4KB 页面
    TFixedPoolTL.PageSize := 4096;
    TFixedPoolTL.PageMask := PtrUInt(TFixedPoolTL.PageSize - 1);
    SetLength(TFixedPoolTL.PageMap, 64); // 初始容量
    TFixedPoolTL.PageMapCap := 64;
    TFixedPoolTL.PageMapCount := 0;
  end;
end;
procedure PageMapAddForPool(tp: TFixedPool);
var base: Pointer; sz: SizeUInt; pageBase: PtrUInt;
begin
  if tp = nil then Exit;
  tp.GetArenaRange(base, sz);
  if (base = nil) or (sz = 0) then Exit;
  pageBase := PtrUInt(PtrUInt(base) and not TFixedPoolTL.PageMask);
  EnterCriticalSection(TFixedPoolTL.PageMapLock);
  try
    if TFixedPoolTL.PageMapCount = TFixedPoolTL.PageMapCap then begin
      TFixedPoolTL.PageMapCap := TFixedPoolTL.PageMapCap * 2;
      SetLength(TFixedPoolTL.PageMap, TFixedPoolTL.PageMapCap);
    end;
    TFixedPoolTL.PageMap[TFixedPoolTL.PageMapCount].PageBase := pageBase;
    TFixedPoolTL.PageMap[TFixedPoolTL.PageMapCount].Pool := tp;
    Inc(TFixedPoolTL.PageMapCount);
  finally
    LeaveCriticalSection(TFixedPoolTL.PageMapLock);
  end;
end;


procedure RegisterThreadPool(tp: TFixedPool);
const
  INBOX_CAP = 256; // 2^k
var
  e: Integer;
begin
  EnterCriticalSection(TFixedPoolTL.RegistryLock);
  try
    e := Length(TFixedPoolTL.Registry);
    SetLength(TFixedPoolTL.Registry, e+1);
    with TFixedPoolTL.Registry[e] do
    begin
      Pool := tp;
      SetLength(InboxBuf, INBOX_CAP);
      Head := 0; Tail := 0; Count := 0;
      InitCriticalSection(InboxLock);
    end;
    // 路由映射注册
    PageMapAddForPool(tp);
    // 记录 TLS 索引缓存
    TFixedPoolTL.ThreadIndex := e;
    TFixedPoolTL.ThreadIndexValid := True;
  finally
    LeaveCriticalSection(TFixedPoolTL.RegistryLock);
  end;
end;

function FindInboxByPtr(p: Pointer; out idx: Integer): Boolean;
var i: Integer;
begin
  Result := False; idx := -1;
  // 先尝试 TLS 索引命中
  if TFixedPoolTL.ThreadIndexValid then
  begin
    EnterCriticalSection(TFixedPoolTL.RegistryLock);
    try
      if (TFixedPoolTL.ThreadIndex >= 0) and (TFixedPoolTL.ThreadIndex <= High(TFixedPoolTL.Registry)) then
        if TFixedPoolTL.Registry[TFixedPoolTL.ThreadIndex].Pool.Owns(p) then
          Exit(True);
    finally
      LeaveCriticalSection(TFixedPoolTL.RegistryLock);
    end;
  end;
  // 快速路由
  if FindInboxByPtrFast(p, idx) then Exit(True);
  // 扫描回退
  EnterCriticalSection(TFixedPoolTL.RegistryLock);
  try
    for i := 0 to High(TFixedPoolTL.Registry) do
      if TFixedPoolTL.Registry[i].Pool.Owns(p) then begin idx := i; TFixedPoolTL.ThreadIndex := i; TFixedPoolTL.ThreadIndexValid := True; Exit(True); end;
  finally
    LeaveCriticalSection(TFixedPoolTL.RegistryLock);
  end;
end;


function GetRegistryIndexForPool(tp: TFixedPool): Integer;
var i: Integer;
begin
  Result := -1;
  EnterCriticalSection(TFixedPoolTL.RegistryLock);
  try
    if TFixedPoolTL.ThreadIndexValid and (TFixedPoolTL.ThreadIndex <= High(TFixedPoolTL.Registry)) then
      if TFixedPoolTL.Registry[TFixedPoolTL.ThreadIndex].Pool = tp then Exit(TFixedPoolTL.ThreadIndex);
    for i := 0 to High(TFixedPoolTL.Registry) do
      if TFixedPoolTL.Registry[i].Pool = tp then begin
        TFixedPoolTL.ThreadIndex := i; TFixedPoolTL.ThreadIndexValid := True; Exit(i);
      end;
  finally
    LeaveCriticalSection(TFixedPoolTL.RegistryLock);
  end;
end;

procedure DrainInboxOfIndex(idx: Integer; SelfTP: TFixedPool);
var p: Pointer;
begin
  if (idx < 0) or (idx > High(TFixedPoolTL.Registry)) then Exit;
  EnterCriticalSection(TFixedPoolTL.Registry[idx].InboxLock);
  try
    while TFixedPoolTL.Registry[idx].Count > 0 do
    begin
      p := TFixedPoolTL.Registry[idx].InboxBuf[TFixedPoolTL.Registry[idx].Head];
      TFixedPoolTL.Registry[idx].Head := (TFixedPoolTL.Registry[idx].Head + 1) and (Length(TFixedPoolTL.Registry[idx].InboxBuf)-1);
      Dec(TFixedPoolTL.Registry[idx].Count);
      SelfTP.ReleasePtr(p);
    end;
  finally
    LeaveCriticalSection(TFixedPoolTL.Registry[idx].InboxLock);
  end;
end;

procedure SiphonCrossQueueFor(SelfTP: TFixedPool);
var p: Pointer; len: Integer; i: Integer;
begin
  while True do
  begin
    EnterCriticalSection(TFixedPoolTL.CrossLock);
    len := Length(TFixedPoolTL.CrossQueue);
    if len = 0 then begin LeaveCriticalSection(TFixedPoolTL.CrossLock); Break; end;
    p := TFixedPoolTL.CrossQueue[High(TFixedPoolTL.CrossQueue)];
    SetLength(TFixedPoolTL.CrossQueue, len-1);
    LeaveCriticalSection(TFixedPoolTL.CrossLock);
    if SelfTP.Owns(p) then
      SelfTP.ReleasePtr(p)
    else if FindInboxByPtr(p, i) then
    begin
      // 放回目标 inbox（与 Acquire 路由一致）
      EnterCriticalSection(TFixedPoolTL.Registry[i].InboxLock);
      try
        if TFixedPoolTL.Registry[i].Count < Length(TFixedPoolTL.Registry[i].InboxBuf) then
        begin
          TFixedPoolTL.Registry[i].InboxBuf[TFixedPoolTL.Registry[i].Tail] := p;
          TFixedPoolTL.Registry[i].Tail := (TFixedPoolTL.Registry[i].Tail + 1) and (Length(TFixedPoolTL.Registry[i].InboxBuf)-1);
          Inc(TFixedPoolTL.Registry[i].Count);
        end
        else
        begin
          EnterCriticalSection(TFixedPoolTL.CrossLock);
          try
            SetLength(TFixedPoolTL.CrossQueue, Length(TFixedPoolTL.CrossQueue)+1);
            TFixedPoolTL.CrossQueue[High(TFixedPoolTL.CrossQueue)] := p;
          finally
            LeaveCriticalSection(TFixedPoolTL.CrossLock);
          end;
          Break;
        end;
      finally
        LeaveCriticalSection(TFixedPoolTL.Registry[i].InboxLock);
      end;
    end
    else
    begin
      // 未命中，放回尾部并退出
      EnterCriticalSection(TFixedPoolTL.CrossLock);
      try
        SetLength(TFixedPoolTL.CrossQueue, Length(TFixedPoolTL.CrossQueue)+1);
        TFixedPoolTL.CrossQueue[High(TFixedPoolTL.CrossQueue)] := p;
      finally
        LeaveCriticalSection(TFixedPoolTL.CrossLock);
      end;
      Break;
    end;
  end;
end;

function TFixedPoolTL.EnsureThreadPool: TFixedPool;
begin
  if ThreadPool = nil then
  begin
    ThreadPool := TFixedPool.Create(FBlockSize, FCapacityPerThread, FAlignment, FAllocator);
    RegisterThreadPool(ThreadPool);
  end;
  Result := ThreadPool;
end;

function TFixedPoolTL.Acquire(out AUnit: Pointer): Boolean;
var
  SelfTP: TFixedPool;
  p: Pointer;
  i, len: Integer;
begin
  SelfTP := EnsureThreadPool;
  // 处理回退队列：一次取一个，避免持有 CrossLock 去拿 RegistryLock
  while True do
  begin
    EnterCriticalSection(TFixedPoolTL.CrossLock);
    len := Length(TFixedPoolTL.CrossQueue);
    if len = 0 then begin LeaveCriticalSection(TFixedPoolTL.CrossLock); Break; end;
    p := TFixedPoolTL.CrossQueue[High(TFixedPoolTL.CrossQueue)];
    SetLength(TFixedPoolTL.CrossQueue, len-1);
    LeaveCriticalSection(TFixedPoolTL.CrossLock);

    if SelfTP.Owns(p) then
      SelfTP.ReleasePtr(p)
    else if FindInboxByPtr(p, i) then
    begin
      EnterCriticalSection(TFixedPoolTL.Registry[i].InboxLock);
      try
        if TFixedPoolTL.Registry[i].Count < Length(TFixedPoolTL.Registry[i].InboxBuf) then
        begin
          TFixedPoolTL.Registry[i].InboxBuf[TFixedPoolTL.Registry[i].Tail] := p;
          TFixedPoolTL.Registry[i].Tail := (TFixedPoolTL.Registry[i].Tail + 1) and (Length(TFixedPoolTL.Registry[i].InboxBuf)-1);
          Inc(TFixedPoolTL.Registry[i].Count);
        end
        else
        begin
          // 满：回退到全局队列
          EnterCriticalSection(TFixedPoolTL.CrossLock);
          try
            SetLength(TFixedPoolTL.CrossQueue, Length(TFixedPoolTL.CrossQueue)+1);
            TFixedPoolTL.CrossQueue[High(TFixedPoolTL.CrossQueue)] := p;
          finally
            LeaveCriticalSection(TFixedPoolTL.CrossLock);
          end;
        end;
      finally
        LeaveCriticalSection(TFixedPoolTL.Registry[i].InboxLock);
      end;
    end
    else
    begin
      // 放回回退队列尾
      EnterCriticalSection(TFixedPoolTL.CrossLock);
      try
        SetLength(TFixedPoolTL.CrossQueue, Length(TFixedPoolTL.CrossQueue)+1);
        TFixedPoolTL.CrossQueue[High(TFixedPoolTL.CrossQueue)] := p;
      finally
        LeaveCriticalSection(TFixedPoolTL.CrossLock);
      end;
      Break;
    end;
  end;

  // 拉取当前线程的 inbox（环形队列，批量 drain）
  EnterCriticalSection(TFixedPoolTL.RegistryLock);
  try
    if TFixedPoolTL.ThreadIndexValid and (TFixedPoolTL.ThreadIndex <= High(TFixedPoolTL.Registry)) then i := TFixedPoolTL.ThreadIndex
    else begin
      for i := 0 to High(TFixedPoolTL.Registry) do
        if TFixedPoolTL.Registry[i].Pool = SelfTP then begin TFixedPoolTL.ThreadIndex := i; TFixedPoolTL.ThreadIndexValid := True; Break; end;
    end;
  finally
    LeaveCriticalSection(TFixedPoolTL.RegistryLock);
  end;
  if TFixedPoolTL.ThreadIndexValid then
  begin
    EnterCriticalSection(TFixedPoolTL.Registry[i].InboxLock);
    try
      while TFixedPoolTL.Registry[i].Count > 0 do
      begin
        p := TFixedPoolTL.Registry[i].InboxBuf[TFixedPoolTL.Registry[i].Head];
        TFixedPoolTL.Registry[i].Head := (TFixedPoolTL.Registry[i].Head + 1) and (Length(TFixedPoolTL.Registry[i].InboxBuf)-1);
        Dec(TFixedPoolTL.Registry[i].Count);
        SelfTP.ReleasePtr(p);
      end;
    finally
      LeaveCriticalSection(TFixedPoolTL.Registry[i].InboxLock);
    end;
  end;

  Result := SelfTP.Acquire(AUnit);
end;

procedure TFixedPoolTL.Reset;
begin
  if ThreadPool <> nil then
    ThreadPool.Reset;
end;

procedure TFixedPoolTL.Release(AUnit: Pointer);
var
  SelfTP: TFixedPool;
  i: Integer;
begin
  if AUnit = nil then Exit;
  SelfTP := EnsureThreadPool;
  if SelfTP.Owns(AUnit) then
  begin
    SelfTP.Release(AUnit);
    Exit;
  end;
  // 跨线程回收：尝试直接投递到目标线程 inbox
  if FindInboxByPtr(AUnit, i) then
  begin
    EnterCriticalSection(TFixedPoolTL.Registry[i].InboxLock);

    try
      if TFixedPoolTL.Registry[i].Count < Length(TFixedPoolTL.Registry[i].InboxBuf) then
      begin
        TFixedPoolTL.Registry[i].InboxBuf[TFixedPoolTL.Registry[i].Tail] := AUnit;
        TFixedPoolTL.Registry[i].Tail := (TFixedPoolTL.Registry[i].Tail + 1) and (Length(TFixedPoolTL.Registry[i].InboxBuf)-1);
        Inc(TFixedPoolTL.Registry[i].Count);
      end
      else
      begin
        // 满：回退全局队列
        EnterCriticalSection(TFixedPoolTL.CrossLock);
        try
          SetLength(TFixedPoolTL.CrossQueue, Length(TFixedPoolTL.CrossQueue)+1);
          TFixedPoolTL.CrossQueue[High(TFixedPoolTL.CrossQueue)] := AUnit;
        finally
          LeaveCriticalSection(TFixedPoolTL.CrossLock);
        end;
      end;
    finally
      LeaveCriticalSection(TFixedPoolTL.Registry[i].InboxLock);
    end;
    Exit;
  end;
  // 未命中：回退到全局队列
  EnterCriticalSection(TFixedPoolTL.CrossLock);
  try
    SetLength(TFixedPoolTL.CrossQueue, Length(TFixedPoolTL.CrossQueue)+1);
    TFixedPoolTL.CrossQueue[High(TFixedPoolTL.CrossQueue)] := AUnit;
  finally
    LeaveCriticalSection(TFixedPoolTL.CrossLock);
  end;
end;

function TFixedPoolTL.TryAcquire(out AUnit: Pointer): Boolean;
begin
  Result := Acquire(AUnit);
end;

function TFixedPoolTL.AcquireN(out AUnits: array of Pointer; aCount: Integer): Integer;
var i: Integer; p: Pointer;
begin
  Result := 0;
  for i := 0 to aCount-1 do begin
    if not Acquire(p) then Exit;
    AUnits[i] := p;
    Inc(Result);
  end;
end;

procedure TFixedPoolTL.ReleaseN(const AUnits: array of Pointer; aCount: Integer);
var i: Integer;
begin
  for i := 0 to aCount-1 do
    Release(AUnits[i]);
end;


end.

