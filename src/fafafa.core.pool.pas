unit fafafa.core.pool;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.mem.pool.base,                   // IPool
  fafafa.core.mem.allocator,                    // IAllocator
  fafafa.core.mem.pool.fixed,                   // TFixedPool
  fafafa.core.mem.pool.fixed.growable;          // TGrowingFixedPool & config

type
  TGrowingFixedPoolConfig = fafafa.core.mem.pool.fixed.growable.TGrowingFixedPoolConfig;
  TGrowthKind = fafafa.core.mem.pool.fixed.growable.TGrowthKind;

// 工厂：固定容量固定块池
function CreateFixedPool(ABlockSize: SizeUInt; ACapacity: Integer; AAllocator: IAllocator = nil): IPool;

// 工厂：自动增长固定块池
function CreateGrowingFixedPool(const C: TGrowingFixedPoolConfig): IPool;

implementation

function CreateFixedPool(ABlockSize: SizeUInt; ACapacity: Integer; AAllocator: IAllocator): IPool;
begin
  Result := TFixedPool.Create(ABlockSize, ACapacity, AAllocator);
end;

function CreateGrowingFixedPool(const C: TGrowingFixedPoolConfig): IPool;
begin
  Result := TGrowingFixedPool.Create(C) as IPool;
end;

end.

