{
  # fafafa.core.mem.stats

  统计助手：为现有内存池类提供只读统计快照（不修改原类，不引入行为变化）。
}

unit fafafa.core.mem.stats;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.mem.memPool,
  fafafa.core.mem.stackPool,
  fafafa.core.mem.slabPool;

// 通用统计记录

type
  TMemPoolStats = record
    BlockSize: SizeUInt;
    Capacity: Integer;
    AllocatedCount: Integer;
    AvailableCount: Integer;
    Utilization: Double; // 0.0 .. 1.0
  end;

  TStackPoolStats = record
    TotalSize: SizeUInt;
    UsedSize: SizeUInt;
    AvailableSize: SizeUInt;
    Utilization: Double; // 0.0 .. 1.0
  end;

  TSlabPoolStats = record
    TotalPages: SizeUInt;
    FreePages: SizeUInt;
    PartialPages: SizeUInt;
    FullPages: SizeUInt;
  end;

// 快照函数（零副作用）
function GetMemPoolStats(const APool: TMemPool): TMemPoolStats; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
function GetStackPoolStats(const APool: TStackPool): TStackPoolStats; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
function GetSlabPoolStats(const APool: TSlabPool): TSlabPoolStats; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}

implementation

function GetMemPoolStats(const APool: TMemPool): TMemPoolStats;
var
  LCapacity: Integer;
  LAllocated: Integer;
begin
  // 中文注释：从现有公开属性采集只读统计
  LCapacity := APool.Capacity;
  LAllocated := APool.AllocatedCount;

  Result.BlockSize := APool.BlockSize;
  Result.Capacity := LCapacity;
  Result.AllocatedCount := LAllocated;
  Result.AvailableCount := LCapacity - LAllocated;
  if LCapacity > 0 then
    Result.Utilization := LAllocated / LCapacity
  else
    Result.Utilization := 0.0;
end;

function GetStackPoolStats(const APool: TStackPool): TStackPoolStats;
var
  LTotal, LUsed: SizeUInt;
begin
  // 中文注释：读取总大小与已用大小，计算可用与利用率
  LTotal := APool.TotalSize;
  LUsed := APool.UsedSize;

  Result.TotalSize := LTotal;
  Result.UsedSize := LUsed;
  if LUsed <= LTotal then
    Result.AvailableSize := LTotal - LUsed
  else
    Result.AvailableSize := 0; // 防御性

  if LTotal > 0 then
    Result.Utilization := LUsed / LTotal
  else
    Result.Utilization := 0.0;
end;

function GetSlabPoolStats(const APool: TSlabPool): TSlabPoolStats;
begin
  // 仅提供最小只读统计（从公开方法或现有统计接口聚合）
  FillChar(Result, SizeOf(Result), 0);
  try
    with APool.GetStats do
    begin
      Result.TotalPages := TotalPages;
      Result.FreePages := FreePages;
      Result.PartialPages := PartialPages;
      Result.FullPages := FullPages;
    end;
  except
    // 若获取失败（不同构建配置/接口变动），保持零入侵，不抛异常
  end;
end;

end.

