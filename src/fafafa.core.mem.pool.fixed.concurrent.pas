unit fafafa.core.mem.pool.fixed.concurrent;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, SyncObjs,
  fafafa.core.mem.pool.base,      // IPool
  fafafa.core.mem.pool.fixed,     // TFixedPool
  fafafa.core.mem.allocator;      // IAllocator + GetRtlAllocator

// 说明（原型）：
// - 并发包装器：以临界区保护内部固定块池，提供线程安全的 Acquire/Release
// - 目标：最小可用原型，便于上层并发场景落地；性能优化与无锁/线程本地策略在后续迭代
// - 注意：Reset/Destroy 等操作也受保护；调用端应避免与其它线程并发重置/销毁

 type
  TFixedPoolConcurrent = class(TInterfacedObject, IPool)
  private
    FInner: TFixedPool;
    FLock: TCriticalSection;
  private
    function GetBlockSize: SizeUInt; inline;
    function GetCapacity: Integer; inline;
    function GetAllocatedCount: Integer; inline;
  public
    constructor Create(ABlockSize: SizeUInt; ACapacity: Integer; AAlignment: SizeUInt = 0; AAllocator: IAllocator = nil); overload;
    constructor Create(const AConfig: TFixedPoolConfig); overload;
    destructor Destroy; override;
  public
    // IPool
    function Acquire(out AUnit: Pointer): Boolean; inline;
    function TryAcquire(out AUnit: Pointer): Boolean; inline;
    function AcquireN(out AUnits: array of Pointer; aCount: Integer): Integer; inline;
    procedure Release(AUnit: Pointer); inline;
    procedure ReleaseN(const AUnits: array of Pointer; aCount: Integer); inline;

    // 便捷转发（非接口）
    function Alloc: Pointer; inline;
    function TryAlloc(out APtr: Pointer): Boolean; inline;
    procedure ReleasePtr(APtr: Pointer); inline;
    procedure Reset; inline;

    // 只读属性
    property BlockSize: SizeUInt read GetBlockSize;
    property Capacity: Integer read GetCapacity;
    property AllocatedCount: Integer read GetAllocatedCount;
  end;

implementation

{ TFixedPoolConcurrent }

constructor TFixedPoolConcurrent.Create(ABlockSize: SizeUInt; ACapacity: Integer; AAlignment: SizeUInt; AAllocator: IAllocator);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  if AAlignment = 0 then
    FInner := TFixedPool.Create(ABlockSize, ACapacity, 0{default align}, AAllocator)
  else
    FInner := TFixedPool.Create(ABlockSize, ACapacity, AAlignment, AAllocator);
end;

constructor TFixedPoolConcurrent.Create(const AConfig: TFixedPoolConfig);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FInner := TFixedPool.Create(AConfig);
end;

destructor TFixedPoolConcurrent.Destroy;
begin
  FLock.Acquire;
  try
    FreeAndNil(FInner);
  finally
    FLock.Release;
  end;
  FLock.Free;
  inherited Destroy;
end;

function TFixedPoolConcurrent.Acquire(out AUnit: Pointer): Boolean;
begin
  FLock.Acquire;
  try
    Result := FInner.Acquire(AUnit);
  finally
    FLock.Release;
  end;
end;

function TFixedPoolConcurrent.TryAcquire(out AUnit: Pointer): Boolean;
begin
  FLock.Acquire;
  try
    Result := FInner.TryAcquire(AUnit);
  finally
    FLock.Release;
  end;
end;

function TFixedPoolConcurrent.AcquireN(out AUnits: array of Pointer; aCount: Integer): Integer;
begin
  FLock.Acquire;
  try
    Result := FInner.AcquireN(AUnits, aCount);
  finally
    FLock.Release;
  end;
end;

procedure TFixedPoolConcurrent.Release(AUnit: Pointer);
begin
  FLock.Acquire;
  try
    FInner.Release(AUnit);
  finally
    FLock.Release;
  end;
end;

procedure TFixedPoolConcurrent.ReleaseN(const AUnits: array of Pointer; aCount: Integer);
begin
  FLock.Acquire;
  try
    FInner.ReleaseN(AUnits, aCount);
  finally
    FLock.Release;
  end;
end;

function TFixedPoolConcurrent.Alloc: Pointer;
begin
  FLock.Acquire;
  try
    Result := FInner.Alloc;
  finally
    FLock.Release;
  end;
end;

function TFixedPoolConcurrent.TryAlloc(out APtr: Pointer): Boolean;
begin
  FLock.Acquire;
  try
    Result := FInner.TryAlloc(APtr);
  finally
    FLock.Release;
  end;
end;

procedure TFixedPoolConcurrent.ReleasePtr(APtr: Pointer);
begin
  FLock.Acquire;
  try
    FInner.ReleasePtr(APtr);
  finally
    FLock.Release;
  end;
end;

procedure TFixedPoolConcurrent.Reset;
begin
  FLock.Acquire;
  try
    FInner.Reset;
  finally
    FLock.Release;
  end;
end;

function TFixedPoolConcurrent.GetBlockSize: SizeUInt;
begin
  Result := FInner.BlockSize;
end;

function TFixedPoolConcurrent.GetCapacity: Integer;
begin
  Result := FInner.Capacity;
end;

function TFixedPoolConcurrent.GetAllocatedCount: Integer;
begin
  Result := FInner.AllocatedCount;
end;

end.

