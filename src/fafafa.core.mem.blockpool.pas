{
```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.mem.pool - 内存池接口
## Abstract 摘要

Memory pool interfaces for specialized allocation patterns.
内存池接口，用于特殊的分配模式。

## Declaration 声明

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

unit fafafa.core.mem.blockpool;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.mem.layout,
  fafafa.core.mem.error;

const
  {** IBlockPool 接口 GUID *}
  GUID_IBLOCKPOOL = '{B8F4E0A2-3C5D-4F9B-AE60-7D8C9B0F1234}';

  {** IArena 接口 GUID *}
  GUID_IARENA = '{C905F1B3-4D6E-5A0C-BF78-8E9D0C102345}';

type
  {**
   * IBlockPool
   *
   * @desc 固定大小块池接口
   *       Fixed-size block pool interface
   *
   * @design
   *   - 所有块大小相同（BlockSize）
   *   - O(1) Acquire/Release
   *   - 无碎片化
   *   - 适用于高频分配相同大小对象的场景
   *
   * @example
   *   var Pool: IBlockPool := TBlockPool.Create(SizeOf(TMyObject), 1000);
   *   var Obj := TMyObject(Pool.Acquire);
   *   // 使用对象
   *   Pool.Release(Obj);
   *}
  IBlockPool = interface
    [GUID_IBLOCKPOOL]

    {**
     * Acquire
     *
     * @desc 获取一个块
     *       Acquire a block from the pool
     *
     * @return Pointer 块指针，失败返回 nil
     *
     * @note 性能关键：应该是 O(1)
     *}
    function Acquire: Pointer;

    {**
     * TryAcquire
     *
     * @desc 尝试获取一个块
     *       Try to acquire a block
     *
     * @params
     *   aPtr: Pointer out 参数，成功时返回块指针
     *
     * @return Boolean True 如果成功
     *}
    function TryAcquire(out aPtr: Pointer): Boolean;

    {**
     * Release
     *
     * @desc 释放一个块
     *       Release a block back to the pool
     *
     * @params
     *   aPtr: Pointer 块指针
     *
     * @note aPtr = nil 时安全
     *}
    procedure Release(aPtr: Pointer);

    {**
     * Reset
     *
     * @desc 重置池，释放所有块
     *       Reset pool, release all blocks
     *
     * @warning 所有已分配的块指针将失效
     *}
    procedure Reset;

    {**
     * BlockSize
     *
     * @desc 获取块大小
     *       Get block size
     *
     * @return SizeUInt 每个块的字节数
     *}
    function BlockSize: SizeUInt;

    {**
     * Capacity
     *
     * @desc 获取池容量
     *       Get pool capacity
     *
     * @return SizeUInt 最大块数量
     *}
    function Capacity: SizeUInt;

    {**
     * Available
     *
     * @desc 获取可用块数量
     *       Get available block count
     *
     * @return SizeUInt 当前可用块数量
     *}
    function Available: SizeUInt;

    {**
     * InUse
     *
     * @desc 获取已使用块数量
     *       Get in-use block count
     *
     * @return SizeUInt 当前已分配块数量
     *}
    function InUse: SizeUInt;
  end;

  {**
   * TArenaMarker
   *
   * @desc Arena 位置标记
   *       Arena position marker for SaveMark/RestoreToMark
   *}
  TArenaMarker = type SizeUInt;

  {**
   * IArena
   *
   * @desc 竞技场/栈式分配器接口
   *       Arena/bump allocator interface
   *
   * @design
   *   - 线性分配（bump pointer）
   *   - O(1) 分配
   *   - 支持批量释放（通过 RestoreToMark）
   *   - 不支持单独释放
   *   - 适用于临时对象、作用域分配
   *
   * @example
   *   var Arena: IArena := TArena.Create(64 * 1024);
   *   var Mark := Arena.SaveMark;
   *   var P1 := Arena.Alloc(TMemLayout.Create(100, 8));
   *   var P2 := Arena.Alloc(TMemLayout.Create(200, 16));
   *   // 批量释放 P1 和 P2
   *   Arena.RestoreToMark(Mark);
   *}
  IArena = interface
    [GUID_IARENA]

    {**
     * Alloc
     *
     * @desc 分配内存
     *       Allocate memory from arena
     *
     * @params
     *   aLayout: TMemLayout 内存布局
     *
     * @return TAllocResult 分配结果
     *
     * @note 极快的 O(1) 分配
     *}
    function Alloc(const aLayout: TMemLayout): TAllocResult;

    {**
     * AllocZeroed
     *
     * @desc 分配并清零内存
     *       Allocate and zero-fill
     *}
    function AllocZeroed(const aLayout: TMemLayout): TAllocResult;

    {**
     * SaveMark
     *
     * @desc 保存当前位置
     *       Save current position marker
     *
     * @return TArenaMarker 位置标记
     *}
    function SaveMark: TArenaMarker;

    {**
     * RestoreToMark
     *
     * @desc 恢复到之前的位置（批量释放）
     *       Restore to previous position (bulk free)
     *
     * @params
     *   aMark: TArenaMarker 之前保存的位置
     *
     * @note 所有在 Mark 之后分配的内存将被释放
     *}
    procedure RestoreToMark(aMark: TArenaMarker);

    {**
     * Reset
     *
     * @desc 重置 Arena
     *       Reset arena to initial state
     *}
    procedure Reset;

    {**
     * TotalSize
     *
     * @desc 获取总大小
     *       Get total arena size
     *
     * @return SizeUInt 总字节数
     *}
    function TotalSize: SizeUInt;

    {**
     * UsedSize
     *
     * @desc 获取已使用大小
     *       Get used size
     *
     * @return SizeUInt 已分配字节数
     *}
    function UsedSize: SizeUInt;

    {**
     * RemainingSize
     *
     * @desc 获取剩余大小
     *       Get remaining size
     *
     * @return SizeUInt 剩余字节数
     *}
    function RemainingSize: SizeUInt;
  end;

  {**
   * TBlockPoolBase
   *
   * @desc IBlockPool 的抽象基类
   *       Abstract base class for block pool implementations
   *}
  TBlockPoolBase = class(TInterfacedObject, IBlockPool)
  protected
    FBlockSize: SizeUInt;
    FCapacity: SizeUInt;

  public
    constructor Create(aBlockSize, aCapacity: SizeUInt); virtual;

    { IBlockPool - 子类必须实现 }
    function Acquire: Pointer; virtual; abstract;
    function TryAcquire(out aPtr: Pointer): Boolean; virtual; abstract;
    procedure Release(aPtr: Pointer); virtual; abstract;
    procedure Reset; virtual; abstract;
    function BlockSize: SizeUInt; virtual;
    function Capacity: SizeUInt; virtual;
    function Available: SizeUInt; virtual; abstract;
    function InUse: SizeUInt; virtual;
  end;

  {**
   * TSimpleBlockPool
   *
   * @desc 简单的固定块池实现
   *       Simple fixed block pool implementation
   *
   * @note 使用空闲链表，O(1) 分配/释放
   *}
  TSimpleBlockPool = class(TBlockPoolBase)
  private
    FMemory: Pointer;      // 内存块
    FFreeHead: Pointer;    // 空闲链表头
    FAllocCount: SizeUInt; // 已分配数量
  public
    constructor Create(aBlockSize, aCapacity: SizeUInt); override;
    destructor Destroy; override;

    function Acquire: Pointer; override;
    function TryAcquire(out aPtr: Pointer): Boolean; override;
    procedure Release(aPtr: Pointer); override;
    procedure Reset; override;
    function Available: SizeUInt; override;
  end;

  {**
   * TArenaBase
   *
   * @desc IArena 的抽象基类
   *       Abstract base class for arena implementations
   *}
  TArenaBase = class(TInterfacedObject, IArena)
  protected
    FTotalSize: SizeUInt;

  public
    constructor Create(aTotalSize: SizeUInt); virtual;

    { IArena - 子类必须实现 }
    function Alloc(const aLayout: TMemLayout): TAllocResult; virtual; abstract;
    function AllocZeroed(const aLayout: TMemLayout): TAllocResult; virtual;
    function SaveMark: TArenaMarker; virtual; abstract;
    procedure RestoreToMark(aMark: TArenaMarker); virtual; abstract;
    procedure Reset; virtual; abstract;
    function TotalSize: SizeUInt; virtual;
    function UsedSize: SizeUInt; virtual; abstract;
    function RemainingSize: SizeUInt; virtual;
  end;

  {**
   * TSimpleArena
   *
   * @desc 简单的 Arena 实现
   *       Simple arena implementation with bump allocation
   *
   * @note 使用单个连续内存块
   *}
  TSimpleArena = class(TArenaBase)
  private
    FMemory: Pointer;    // 内存块起始
    FCurrent: Pointer;   // 当前分配位置
    FEnd: Pointer;       // 内存块结束
  public
    constructor Create(aTotalSize: SizeUInt); override;
    destructor Destroy; override;

    function Alloc(const aLayout: TMemLayout): TAllocResult; override;
    function SaveMark: TArenaMarker; override;
    procedure RestoreToMark(aMark: TArenaMarker); override;
    procedure Reset; override;
    function UsedSize: SizeUInt; override;
  end;

implementation

{ TBlockPoolBase }

constructor TBlockPoolBase.Create(aBlockSize, aCapacity: SizeUInt);
begin
  inherited Create;
  FBlockSize := aBlockSize;
  FCapacity := aCapacity;
end;

function TBlockPoolBase.BlockSize: SizeUInt;
begin
  Result := FBlockSize;
end;

function TBlockPoolBase.Capacity: SizeUInt;
begin
  Result := FCapacity;
end;

function TBlockPoolBase.InUse: SizeUInt;
begin
  Result := FCapacity - Available;
end;

{ TSimpleBlockPool }

constructor TSimpleBlockPool.Create(aBlockSize, aCapacity: SizeUInt);
var
  LActualBlockSize: SizeUInt;
  I: SizeUInt;
  LPtr: PPointer;
begin
  // 确保块大小至少能存储一个指针（用于空闲链表）
  if aBlockSize < SizeOf(Pointer) then
    LActualBlockSize := SizeOf(Pointer)
  else
    LActualBlockSize := aBlockSize;

  inherited Create(LActualBlockSize, aCapacity);

  // 分配内存
  GetMem(FMemory, LActualBlockSize * aCapacity);
  FAllocCount := 0;

  // 初始化空闲链表
  FFreeHead := FMemory;
  for I := 0 to aCapacity - 2 do
  begin
    LPtr := PPointer(PByte(FMemory) + I * LActualBlockSize);
    LPtr^ := PByte(FMemory) + (I + 1) * LActualBlockSize;
  end;
  // 最后一个块指向 nil
  LPtr := PPointer(PByte(FMemory) + (aCapacity - 1) * LActualBlockSize);
  LPtr^ := nil;
end;

destructor TSimpleBlockPool.Destroy;
begin
  if FMemory <> nil then
    FreeMem(FMemory);
  inherited Destroy;
end;

function TSimpleBlockPool.Acquire: Pointer;
begin
  if FFreeHead = nil then
  begin
    Result := nil;
    Exit;
  end;

  Result := FFreeHead;
  FFreeHead := PPointer(FFreeHead)^;
  Inc(FAllocCount);
end;

function TSimpleBlockPool.TryAcquire(out aPtr: Pointer): Boolean;
begin
  aPtr := Acquire;
  Result := aPtr <> nil;
end;

procedure TSimpleBlockPool.Release(aPtr: Pointer);
begin
  if aPtr = nil then
    Exit;

  // 验证指针在池范围内
  if (PByte(aPtr) < PByte(FMemory)) or
     (PByte(aPtr) >= PByte(FMemory) + FBlockSize * FCapacity) then
    Exit;  // 无效指针，静默忽略

  // 加入空闲链表
  PPointer(aPtr)^ := FFreeHead;
  FFreeHead := aPtr;
  Dec(FAllocCount);
end;

procedure TSimpleBlockPool.Reset;
var
  I: SizeUInt;
  LPtr: PPointer;
begin
  FAllocCount := 0;

  // 重建空闲链表
  FFreeHead := FMemory;
  for I := 0 to FCapacity - 2 do
  begin
    LPtr := PPointer(PByte(FMemory) + I * FBlockSize);
    LPtr^ := PByte(FMemory) + (I + 1) * FBlockSize;
  end;
  LPtr := PPointer(PByte(FMemory) + (FCapacity - 1) * FBlockSize);
  LPtr^ := nil;
end;

function TSimpleBlockPool.Available: SizeUInt;
begin
  Result := FCapacity - FAllocCount;
end;

{ TArenaBase }

constructor TArenaBase.Create(aTotalSize: SizeUInt);
begin
  inherited Create;
  FTotalSize := aTotalSize;
end;

function TArenaBase.AllocZeroed(const aLayout: TMemLayout): TAllocResult;
begin
  Result := Alloc(aLayout);
  if Result.IsOk and (Result.Ptr <> nil) then
    FillChar(Result.Ptr^, aLayout.Size, 0);
end;

function TArenaBase.TotalSize: SizeUInt;
begin
  Result := FTotalSize;
end;

function TArenaBase.RemainingSize: SizeUInt;
begin
  Result := FTotalSize - UsedSize;
end;

{ TSimpleArena }

constructor TSimpleArena.Create(aTotalSize: SizeUInt);
begin
  inherited Create(aTotalSize);

  GetMem(FMemory, aTotalSize);
  FCurrent := FMemory;
  FEnd := PByte(FMemory) + aTotalSize;
end;

destructor TSimpleArena.Destroy;
begin
  if FMemory <> nil then
    FreeMem(FMemory);
  inherited Destroy;
end;

function TSimpleArena.Alloc(const aLayout: TMemLayout): TAllocResult;
var
  LAligned: Pointer;
  LNewCurrent: Pointer;
begin
  if not aLayout.IsValid then
  begin
    Result := TAllocResult.Err(aeInvalidLayout);
    Exit;
  end;

  if aLayout.IsZeroSized then
  begin
    Result := TAllocResult.Ok(nil);
    Exit;
  end;

  // 对齐当前指针
  LAligned := Pointer(AlignUp(PtrUInt(FCurrent), aLayout.Align));
  LNewCurrent := PByte(LAligned) + aLayout.Size;

  // 检查是否有足够空间
  if PtrUInt(LNewCurrent) > PtrUInt(FEnd) then
  begin
    Result := TAllocResult.Err(aeOutOfMemory);
    Exit;
  end;

  FCurrent := LNewCurrent;
  Result := TAllocResult.Ok(LAligned);
end;

function TSimpleArena.SaveMark: TArenaMarker;
begin
  Result := TArenaMarker(PtrUInt(FCurrent) - PtrUInt(FMemory));
end;

procedure TSimpleArena.RestoreToMark(aMark: TArenaMarker);
var
  LTarget: Pointer;
begin
  LTarget := PByte(FMemory) + SizeUInt(aMark);

  // 验证标记有效
  if (PtrUInt(LTarget) < PtrUInt(FMemory)) or (PtrUInt(LTarget) > PtrUInt(FEnd)) then
    Exit;

  FCurrent := LTarget;
end;

procedure TSimpleArena.Reset;
begin
  FCurrent := FMemory;
end;

function TSimpleArena.UsedSize: SizeUInt;
begin
  Result := PtrUInt(FCurrent) - PtrUInt(FMemory);
end;

end.
