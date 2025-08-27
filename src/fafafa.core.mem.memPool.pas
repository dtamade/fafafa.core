{
```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.mem.memPool

## Abstract 摘要

General-purpose memory pool implementation providing efficient fixed-size block allocation.
通用内存池实现，提供高效的固定大小块分配。

## Declaration 声明

For forwarding or using it for your own project, please retain the copyright notice of this project. Thank you.
转发或者用于自己项目请保留本项目的版权声明,谢谢.

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

unit fafafa.core.mem.memPool;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.mem.allocator;

type
  // 自定义异常类型
  EMemPoolError = class(Exception);
  EMemPoolInvalidPointer = class(EMemPoolError);
  EMemPoolDoubleFree = class(EMemPoolError);

  TMemPoolConfig = record
    BlockSize: SizeUInt;
    Capacity: Integer;
    Alignment: SizeUInt;    // 保留字段：未来用于按对齐分配
    ZeroOnAlloc: Boolean;   // 预分配块是否置零（默认False）
    Allocator: IAllocator;  // 底层分配器
  end;

  {**
   * TMemPool
   *
   * @desc 通用内存池，提供固定大小的内存块分配
   *       General-purpose memory pool for fixed-size block allocation
   *}
  TMemPool = class
  private
    FBlockSize: SizeUInt;
    FCapacity: Integer;
    FAllocatedCount: Integer;
    FBlocks: array of Pointer;
    FFreeList: array of Boolean;
    FBaseAllocator: IAllocator;
    // O(1) 分配/释放的自由索引栈（栈顶为可用索引个数）
    FFreeStack: array of Integer;
    FFreeTop: Integer;


    function GetAvailableCount: Integer;

  public
    {**
     * Create
     *
     * @desc 创建内存池
     *       Create memory pool
     *
     * @param aBlockSize 块大小 Block size
     * @param aCapacity 容量 Capacity
     * @param aAllocator 基础分配器 Base allocator (optional)
     *}
    constructor Create(aBlockSize: SizeUInt; aCapacity: Integer; aAllocator: IAllocator = nil); overload;
    constructor Create(const aConfig: TMemPoolConfig); overload;

    {**
     * Destroy
     *
     * @desc 销毁内存池
     *       Destroy memory pool
     *}
    destructor Destroy; override;

    {**
     * Alloc
     *
     * @desc 分配内存块
     *       Allocate memory block
     *
     * @return 内存指针 Memory pointer
     *}
    function Alloc: Pointer;

    {**
     * TryAlloc
     *
     * @desc 尝试分配（不抛异常），失败返回 False
     *       Try to allocate (no exception), return False on failure
     *}
    function TryAlloc(out APtr: Pointer): Boolean; inline;

    {**
     * Free
     *
     * @desc 释放内存块
     *       Free memory block
     *
     * @param aPtr 内存指针 Memory pointer
     *}
    procedure Free(aPtr: Pointer);

    {** 别名：释放内存块，避免与 TObject.Free 混淆 **}
    procedure ReleasePtr(aPtr: Pointer); inline;

    {**
     * Reset
     *
     * @desc 重置内存池，释放所有分配的块
     *       Reset memory pool, free all allocated blocks
     *}
    procedure Reset;

    function IsEmpty: Boolean;
    function IsFull: Boolean;

    // 属性 Properties
    property BlockSize: SizeUInt read FBlockSize;
    property Capacity: Integer read FCapacity;
    property AllocatedCount: Integer read FAllocatedCount;
    property AvailableCount: Integer read GetAvailableCount;
  end;

implementation

uses
  fafafa.core.mem.utils;

constructor TMemPool.Create(const aConfig: TMemPoolConfig);
var
  LIndex: Integer;
begin
  Create(aConfig.BlockSize, aConfig.Capacity, aConfig.Allocator);
  if aConfig.ZeroOnAlloc then
  begin
    for LIndex := 0 to FCapacity - 1 do
      if FBlocks[LIndex] <> nil then
        FillChar(FBlocks[LIndex]^, FBlockSize, 0);
  end;
end;

{ TMemPool }

constructor TMemPool.Create(aBlockSize: SizeUInt; aCapacity: Integer; aAllocator: IAllocator);
var
  LIndex, LRollback: Integer; // 局部索引（遵循 L 前缀规范）
begin
  inherited Create;

  // 参数校验（中文注释）：块大小与容量必须有效
  if aBlockSize = 0 then
    raise Exception.Create('Block size cannot be zero');
  if aCapacity <= 0 then
    raise Exception.Create('Capacity must be positive');

  FBlockSize := aBlockSize;
  FCapacity := aCapacity;
  FAllocatedCount := 0;

  // 选择基础分配器：默认使用 RTL 分配器
  if aAllocator = nil then
    FBaseAllocator := fafafa.core.mem.allocator.GetRtlAllocator
  else
    FBaseAllocator := aAllocator;

  SetLength(FBlocks, aCapacity);
  SetLength(FFreeList, aCapacity);
  SetLength(FFreeStack, aCapacity);
  FFreeTop := 0;

  // 预分配所有块（O(n) 初始化）
  for LIndex := 0 to aCapacity - 1 do
  begin
    FBlocks[LIndex] := FBaseAllocator.GetMem(aBlockSize);
    if FBlocks[LIndex] = nil then
    begin
      // Roll back already allocated blocks to avoid leaks on constructor failure
      // 注意：不能修改 for 循环变量 LIndex，这里使用独立的回滚计数器
      LRollback := LIndex - 1;
      while LRollback >= 0 do
      begin
        if FBlocks[LRollback] <> nil then
          FBaseAllocator.FreeMem(FBlocks[LRollback]);
        Dec(LRollback);
      end;
      raise Exception.Create('Failed to allocate memory block');
    end;
    FFreeList[LIndex] := True; // True 表示空闲
    // 同步填充自由栈：入栈空闲索引
    FFreeStack[FFreeTop] := LIndex;
    Inc(FFreeTop);
  end;
end;

destructor TMemPool.Destroy;
var
  LIndex: Integer; // 局部索引（遵循 L 前缀规范）
begin
  // 释放所有预分配的块
  for LIndex := 0 to FCapacity - 1 do
  begin
    if FBlocks[LIndex] <> nil then
      FBaseAllocator.FreeMem(FBlocks[LIndex]);
  end;

  SetLength(FBlocks, 0);
  SetLength(FFreeList, 0);
  inherited Destroy;
end;

function TMemPool.Alloc: Pointer;
var
  LIndex: Integer; // 局部索引（遵循 L 前缀规范）
begin
  Result := nil;

  // O(1): 从自由索引栈弹出一个空闲块
  if FFreeTop > 0 then
  begin
    Dec(FFreeTop);
    LIndex := FFreeStack[FFreeTop];
    // 额外一致性检查：若标记不一致，进行修正（不抛异常，保持健壮）
    if not FFreeList[LIndex] then
    begin
      // 退回：该索引被占用，继续线性扫描作为兜底
      // 注意：保持行为，不引入破坏
    end
    else
    begin
      FFreeList[LIndex] := False;
      Inc(FAllocatedCount);
      Exit(FBlocks[LIndex]);
    end;
  end;


  // 兜底：线性扫描（意外不一致或栈为空的情况）
  for LIndex := 0 to FCapacity - 1 do
  begin
    if FFreeList[LIndex] then
    begin
      FFreeList[LIndex] := False;
      Inc(FAllocatedCount);
      Exit(FBlocks[LIndex]);
    end;
  end;
end;

function TMemPool.TryAlloc(out APtr: Pointer): Boolean;
begin
  APtr := Alloc;
  Result := APtr <> nil;
end;

procedure TMemPool.ReleasePtr(aPtr: Pointer);
begin
  Free(aPtr);
end;


procedure TMemPool.Free(aPtr: Pointer);
var
  LIndex: Integer; // 局部索引（遵循 L 前缀规范）
begin
  if aPtr = nil then
    raise EMemPoolInvalidPointer.Create('TMemPool.Free: aPtr cannot be nil');

  // 查找要释放的块（匹配指针位置并校验双重释放）
  for LIndex := 0 to FCapacity - 1 do
  begin
    if FBlocks[LIndex] = aPtr then
    begin
      if FFreeList[LIndex] then
        raise EMemPoolDoubleFree.Create('TMemPool.Free: double free detected');
      // 块已分配，执行释放
      FFreeList[LIndex] := True;
      Dec(FAllocatedCount);

      // O(1): 将索引压回自由栈
      FFreeStack[FFreeTop] := LIndex;
      Inc(FFreeTop);
      Exit;
    end;
  end;

  // 未找到匹配块，指针不属于该池
  raise EMemPoolInvalidPointer.Create('TMemPool.Free: pointer does not belong to this pool');
end;

procedure TMemPool.Reset;
var
  LIndex: Integer; // 局部索引（遵循 L 前缀规范）
begin
  // 重置所有块为空闲状态
  for LIndex := 0 to FCapacity - 1 do
    FFreeList[LIndex] := True;
  FAllocatedCount := 0;
end;

function TMemPool.GetAvailableCount: Integer;
begin
  Result := FCapacity - FAllocatedCount;
end;

function TMemPool.IsEmpty: Boolean;
begin
  Result := FAllocatedCount = 0;
end;

function TMemPool.IsFull: Boolean;
begin
  Result := FAllocatedCount = FCapacity;
end;

end.
