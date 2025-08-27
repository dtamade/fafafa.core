unit fafafa.core.mem.pool;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base,
  fafafa.core.mem.allocator.base,
  fafafa.core.mem.pool.base,
  fafafa.core.mem.pool.memoryPool,
  fafafa.core.mem.pool.fixedSlab;

type

  IPool       = fafafa.core.mem.pool.base.IPool;
  IMemoryPool = fafafa.core.mem.pool.memoryPool.IMemoryPool;

  // 对外门面导出，统一从本单元获取接口和实现
  IFixedSlabPool = fafafa.core.mem.pool.fixedSlab.IFixedSlabPool;
  TFixedSlabPool = fafafa.core.mem.pool.fixedSlab.TFixedSlabPool;

function MakeFixedSlabPool(ACapacity: SizeUInt; AAllocator: IAllocator; AMinShift: SizeUInt = 3): IFixedSlabPool; overload;
function MakeFixedSlabPool(ACapacity: SizeUInt; AAllocator: IAllocator): IFixedSlabPool; overload;
function MakeFixedSlabPool(ACapacity: SizeUInt): IFixedSlabPool; overload;


implementation

function MakeFixedSlabPool(ACapacity: SizeUInt; AAllocator: IAllocator; AMinShift: SizeUInt): IFixedSlabPool;
begin
  Result := TFixedSlabPool.Create(ACapacity, AAllocator, AMinShift);
end;

function MakeFixedSlabPool(ACapacity: SizeUInt; AAllocator: IAllocator): IFixedSlabPool;
begin
  Result := TFixedSlabPool.Create(ACapacity, AAllocator);
end;

function MakeFixedSlabPool(ACapacity: SizeUInt): IFixedSlabPool;
begin
  Result := TFixedSlabPool.Create(ACapacity);
end;





end.