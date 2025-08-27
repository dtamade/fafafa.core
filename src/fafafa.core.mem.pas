{
```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.mem

## Abstract 摘要

Memory management module providing unified memory operations and allocator re-exports.
内存管理模块，提供统一的内存操作和分配器重新导出。

## Declaration 声明

For forwarding or using it for your own project, please retain the copyright notice of this project. Thank you.
转发或者用于自己项目请保留本项目的版权声明,谢谢.

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

{------------------------------------------------------------------------------
  v1.1.0 Release Notes（2025-08-10）
  - 接口优先收束：TryAlloc 系列、ReleasePtr 别名（避免与 TObject.Free 混淆）
  - 统计助手：Mem/Stack/Slab 只读快照（fafafa.core.mem.stats）
  - 使用提示：size=0 返回 nil；Destroy vs ReleasePtr；Free(nil) 跨池差异
  - 示例与构建：新增 interface 与 microbench 示例，批量脚本纳入
  - 行为：不破坏向后兼容；线程安全不在本版本范围
------------------------------------------------------------------------------}


unit fafafa.core.mem;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.mem.utils,
  fafafa.core.mem.allocator,
  fafafa.core.mem.memPool,
  fafafa.core.mem.stackPool,
  fafafa.core.mem.slabPool;

const
  FAFAFA_CORE_MEM_VERSION = '1.1.0';

function MemVersion: string; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{-----------------------------------------------------------------------------
  使用提示 Usage Notes

  - 分配策略：
    * size=0：返回 nil（不抛异常）；Stack/Slab/Mem 保持一致
    * TryAlloc：提供不抛异常的尝试分配（返回 False、指针为 nil）

  - 释放策略：
    * 释放块内存请使用 ReleasePtr(APtr)（别名，避免与 TObject.Free 混淆）
    * 销毁实例请使用 Destroy
  - 异常语义（汇总）：
    * MemPool.Free(nil) => EMemPoolInvalidPointer
    * MemPool.DoubleFree => EMemPoolDoubleFree
    * SlabPool.Free: 双重释放 => ESlabPoolCorruption；nil 安全
  - 统计：
    * 可通过 fafafa.core.mem.stats 获取 Mem/Stack/Slab 的只读统计快照
-----------------------------------------------------------------------------}


{
  重新导出核心内存操作函数 Re-export core memory operation functions
}

// 从 fafafa.core.mem.utils 重新导出内存操作函数
// Overlap 检查
function IsOverlap(aPtr1: Pointer; aSize1: SizeUInt; aPtr2: Pointer; aSize2: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsOverlap(aPtr1, aPtr2: Pointer; aSize: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsOverlapUnChecked(aPtr1: Pointer; aSize1: SizeUInt; aPtr2: Pointer; aSize2: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function IsOverlapUnChecked(aPtr1, aPtr2: Pointer; aSize: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// Copy 系列
procedure Copy(aSrc, aDst: Pointer; aSize: SizeUInt); {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure CopyUnChecked(aSrc, aDst: Pointer; aSize: SizeUInt); {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure CopyNonOverlap(aSrc, aDst: Pointer; aSize: SizeUInt); {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure CopyNonOverlapUnChecked(aSrc, aDst: Pointer; aSize: SizeUInt); {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// Fill/Zero 系列
procedure Fill(aDst: Pointer; aCount: SizeUInt; aValue: UInt8); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure Fill(aDst: Pointer; aCount: SizeInt; aValue: UInt8); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure Fill8(aDst: Pointer; aCount: SizeUInt; aValue: UInt8); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure Fill8(aDst: Pointer; aCount: SizeInt; aValue: UInt8); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure Fill16(aDst: Pointer; aCount: SizeUInt; aValue: UInt16); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure Fill16(aDst: Pointer; aCount: SizeInt; aValue: UInt16); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure Fill32(aDst: Pointer; aCount: SizeUInt; aValue: UInt32); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure Fill32(aDst: Pointer; aCount: SizeInt; aValue: UInt32); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure Fill64(aDst: Pointer; aCount: SizeUInt; const aValue: UInt64); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure Fill64(aDst: Pointer; aCount: SizeInt; const aValue: UInt64); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure Zero(aDst: Pointer; aSize: SizeUInt); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
procedure Zero(aDst: Pointer; aSize: SizeInt); overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// Compare/Equal 系列
function Compare(aPtr1, aPtr2: Pointer; aCount: SizeUInt): Integer; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Compare(aPtr1, aPtr2: Pointer; aCount: SizeInt): Integer; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Compare8(aPtr1, aPtr2: Pointer; aCount: SizeUInt): Integer; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Compare8(aPtr1, aPtr2: Pointer; aCount: SizeInt): Integer; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Compare16(aPtr1, aPtr2: Pointer; aCount: SizeUInt): Integer; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Compare16(aPtr1, aPtr2: Pointer; aCount: SizeInt): Integer; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Compare32(aPtr1, aPtr2: Pointer; aCount: SizeUInt): Integer; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Compare32(aPtr1, aPtr2: Pointer; aCount: SizeInt): Integer; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Equal(aPtr1, aPtr2: Pointer; aSize: SizeUInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function Equal(aPtr1, aPtr2: Pointer; aSize: SizeInt): Boolean; overload; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

// 对齐
function IsAligned(aPtr: Pointer; aAlignment: SizeUInt = SizeOf(Pointer)): Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function AlignUp(aPtr: Pointer; aAlignment: SizeUInt = SIZE_PTR): Pointer; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
function AlignUpUnChecked(aPtr: Pointer; aAlignment: SizeUInt = SIZE_PTR): Pointer; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
  function AlignDown(aPtr: Pointer; aAlignment: SizeUInt = SIZE_PTR): Pointer; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
  function AlignDownUnChecked(aPtr: Pointer; aAlignment: SizeUInt = SIZE_PTR): Pointer; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{
  重新导出分配器类型 Re-export allocator types
}

type
  // 导出接口优先的分配器类型（统一 IAllocator 策略）
  IAllocator = fafafa.core.mem.allocator.IAllocator;
  TAllocator = fafafa.core.mem.allocator.TAllocator;
  TCallbackAllocator = fafafa.core.mem.allocator.TCallbackAllocator;
  TRtlAllocator = fafafa.core.mem.allocator.TRtlAllocator;
  {$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
  TCrtAllocator = fafafa.core.mem.allocator.TCrtAllocator;
  {$ENDIF}

// 重新导出分配器获取函数
function GetRtlAllocator: IAllocator; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
{$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
function GetCrtAllocator: IAllocator; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
{$ENDIF}

{
  高级内存管理功能 Advanced Memory Management Features
}

// 重新导出池类型（门面导出三类核心池）
type
  TMemPool  = fafafa.core.mem.memPool.TMemPool;
  TStackPool = fafafa.core.mem.stackPool.TStackPool;
  TSlabPool = fafafa.core.mem.slabPool.TSlabPool;

// 重新导出增强版栈池类型
// 为保持门面职责收敛，不再重导出增强型/对象池/环形缓冲区/内存映射/映射池类型。
// 用户可按需直接 uses 各自单元：
//   - fafafa.core.mem.enhancedStackPool / enhancedObjectPool / enhancedRingBuffer
//   - fafafa.core.mem.objectPool / ringBuffer
//   - fafafa.core.fs.mmap（建议替代 memoryMap 系列）
//   - fafafa.core.mem.mappedRingBuffer / mappedSlabPool（建议迁移至 fs 子域）


  {--------------------------------------------------------------------------
    注意：内存映射/共享内存等功能不再由 fafafa.core.mem 门面导出；
    请直接使用 fs 子域（例如 fafafa.core.fs.mmap）或各自单元。
  --------------------------------------------------------------------------}

implementation

{ 重新导出函数的实现 Re-export function implementations }

function IsOverlap(aPtr1: Pointer; aSize1: SizeUInt; aPtr2: Pointer; aSize2: SizeUInt): Boolean;
begin
  Result := fafafa.core.mem.utils.IsOverlap(aPtr1, aSize1, aPtr2, aSize2);
end;

function IsOverlap(aPtr1, aPtr2: Pointer; aSize: SizeUInt): Boolean;
begin
  Result := fafafa.core.mem.utils.IsOverlap(aPtr1, aPtr2, aSize);
end;
function IsOverlapUnChecked(aPtr1: Pointer; aSize1: SizeUInt; aPtr2: Pointer; aSize2: SizeUInt): Boolean;
begin
  Result := fafafa.core.mem.utils.IsOverlapUnChecked(aPtr1, aSize1, aPtr2, aSize2);
end;

function IsOverlapUnChecked(aPtr1, aPtr2: Pointer; aSize: SizeUInt): Boolean;
begin
  Result := fafafa.core.mem.utils.IsOverlapUnChecked(aPtr1, aPtr2, aSize);
end;

procedure CopyUnChecked(aSrc, aDst: Pointer; aSize: SizeUInt);
begin
  fafafa.core.mem.utils.CopyUnChecked(aSrc, aDst, aSize);
end;

procedure CopyNonOverlap(aSrc, aDst: Pointer; aSize: SizeUInt);
begin
  fafafa.core.mem.utils.CopyNonOverlap(aSrc, aDst, aSize);
end;

procedure CopyNonOverlapUnChecked(aSrc, aDst: Pointer; aSize: SizeUInt);
begin
  fafafa.core.mem.utils.CopyNonOverlapUnChecked(aSrc, aDst, aSize);
end;

procedure Fill(aDst: Pointer; aCount: SizeInt; aValue: UInt8);
begin
  fafafa.core.mem.utils.Fill(aDst, aCount, aValue);
end;

procedure Fill8(aDst: Pointer; aCount: SizeUInt; aValue: UInt8);
begin
  fafafa.core.mem.utils.Fill8(aDst, aCount, aValue);
end;

procedure Fill8(aDst: Pointer; aCount: SizeInt; aValue: UInt8);
begin
  fafafa.core.mem.utils.Fill8(aDst, aCount, aValue);
end;

procedure Fill16(aDst: Pointer; aCount: SizeUInt; aValue: UInt16);
begin
  fafafa.core.mem.utils.Fill16(aDst, aCount, aValue);
end;

procedure Fill16(aDst: Pointer; aCount: SizeInt; aValue: UInt16);
begin
  fafafa.core.mem.utils.Fill16(aDst, aCount, aValue);
end;

procedure Fill32(aDst: Pointer; aCount: SizeUInt; aValue: UInt32);
begin
  fafafa.core.mem.utils.Fill32(aDst, aCount, aValue);
end;

procedure Fill32(aDst: Pointer; aCount: SizeInt; aValue: UInt32);
begin
  fafafa.core.mem.utils.Fill32(aDst, aCount, aValue);
end;

procedure Fill64(aDst: Pointer; aCount: SizeUInt; const aValue: UInt64);
begin
  fafafa.core.mem.utils.Fill64(aDst, aCount, aValue);
end;

procedure Fill64(aDst: Pointer; aCount: SizeInt; const aValue: UInt64);
begin
  fafafa.core.mem.utils.Fill64(aDst, aCount, aValue);
end;

procedure Zero(aDst: Pointer; aSize: SizeInt);
begin
  fafafa.core.mem.utils.Zero(aDst, aSize);
end;

function Compare(aPtr1, aPtr2: Pointer; aCount: SizeInt): Integer;
begin
  Result := fafafa.core.mem.utils.Compare(aPtr1, aPtr2, aCount);
end;

function Compare8(aPtr1, aPtr2: Pointer; aCount: SizeUInt): Integer;
begin
  Result := fafafa.core.mem.utils.Compare8(aPtr1, aPtr2, aCount);
end;

function Compare8(aPtr1, aPtr2: Pointer; aCount: SizeInt): Integer;
begin
  Result := fafafa.core.mem.utils.Compare8(aPtr1, aPtr2, aCount);
end;

function Compare16(aPtr1, aPtr2: Pointer; aCount: SizeUInt): Integer;
begin
  Result := fafafa.core.mem.utils.Compare16(aPtr1, aPtr2, aCount);
end;

function Compare16(aPtr1, aPtr2: Pointer; aCount: SizeInt): Integer;
begin
  Result := fafafa.core.mem.utils.Compare16(aPtr1, aPtr2, aCount);
end;

function Compare32(aPtr1, aPtr2: Pointer; aCount: SizeUInt): Integer;
begin
  Result := fafafa.core.mem.utils.Compare32(aPtr1, aPtr2, aCount);
end;

function Compare32(aPtr1, aPtr2: Pointer; aCount: SizeInt): Integer;
begin
  Result := fafafa.core.mem.utils.Compare32(aPtr1, aPtr2, aCount);
end;

function Equal(aPtr1, aPtr2: Pointer; aSize: SizeInt): Boolean;
begin
  Result := fafafa.core.mem.utils.Equal(aPtr1, aPtr2, aSize);
end;

function AlignUpUnChecked(aPtr: Pointer; aAlignment: SizeUInt): Pointer;
begin
  Result := fafafa.core.mem.utils.AlignUpUnChecked(aPtr, aAlignment);
end;

function AlignDown(aPtr: Pointer; aAlignment: SizeUInt): Pointer;
begin
  Result := fafafa.core.mem.utils.AlignDown(aPtr, aAlignment);
end;

function AlignDownUnChecked(aPtr: Pointer; aAlignment: SizeUInt): Pointer;
begin
  Result := fafafa.core.mem.utils.AlignDownUnChecked(aPtr, aAlignment);
end;


procedure Copy(aSrc, aDst: Pointer; aSize: SizeUInt);
begin
  fafafa.core.mem.utils.Copy(aSrc, aDst, aSize);
end;

procedure Fill(aDst: Pointer; aCount: SizeUInt; aValue: UInt8);
begin
  fafafa.core.mem.utils.Fill(aDst, aCount, aValue);
end;

procedure Zero(aDst: Pointer; aSize: SizeUInt);
begin
  fafafa.core.mem.utils.Zero(aDst, aSize);
end;

function Compare(aPtr1, aPtr2: Pointer; aCount: SizeUInt): Integer;
begin
  Result := fafafa.core.mem.utils.Compare(aPtr1, aPtr2, aCount);
end;

function Equal(aPtr1, aPtr2: Pointer; aSize: SizeUInt): Boolean;
begin
  Result := fafafa.core.mem.utils.Equal(aPtr1, aPtr2, aSize);
end;

function IsAligned(aPtr: Pointer; aAlignment: SizeUInt): Boolean;
begin
  Result := fafafa.core.mem.utils.IsAligned(aPtr, aAlignment);
end;

function AlignUp(aPtr: Pointer; aAlignment: SizeUInt): Pointer;
begin
  Result := fafafa.core.mem.utils.AlignUp(aPtr, aAlignment);
end;

function GetRtlAllocator: IAllocator;
begin
  Result := fafafa.core.mem.allocator.GetRtlAllocator;
end;

{$IFDEF FAFAFA_CORE_CRT_ALLOCATOR}
function GetCrtAllocator: IAllocator;
begin
  Result := fafafa.core.mem.allocator.GetCrtAllocator;
end;
{$ENDIF}

function MemVersion: string;
begin
  Result := FAFAFA_CORE_MEM_VERSION;
end;



end.

{
  注意: 高级功能模块已创建但未集成到主门面模块中

  可用的高级模块:
  - fafafa.core.mem.advanced - 高级内存池和线程安全池
  - fafafa.core.mem.config - 配置管理
  - fafafa.core.mem.factory - 内存池工厂

  要使用高级功能，请直接引用相应的模块:
  uses fafafa.core.mem.factory;

  LPool := CreateSmallObjectPool('MyPool');
}
