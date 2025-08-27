{
```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.mem.stackPool

## Abstract 摘要

Stack-based memory pool implementation providing fast sequential allocation and bulk deallocation.
基于栈的内存池实现，提供快速的顺序分配和批量释放。

## Declaration 声明

For forwarding or using it for your own project, please retain the copyright notice of this project. Thank you.
转发或者用于自己项目请保留本项目的版权声明,谢谢.

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

unit fafafa.core.mem.stackPool;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.mem.allocator;

 type
  TStackPoolConfig = record
    TotalSize: SizeUInt;
    Alignment: SizeUInt;    // 默认指针大小
    ZeroOnAlloc: Boolean;   // 分配后是否清零（默认False）
    Allocator: IAllocator;
  end;

type
  {**
   * TStackPool
   *
   * @desc 栈式内存池，提供快速的顺序分配和批量释放
   *       Stack-based memory pool for fast sequential allocation and bulk deallocation
   *}
  TStackPool = class
  protected
    FBuffer: Pointer;
    FSize: SizeUInt;
    FOffset: SizeUInt;
    FBaseAllocator: IAllocator;

    function GetAvailableSize: SizeUInt;
    function AlignOffset(aOffset, aAlignment: SizeUInt): SizeUInt;

  public
    {**
     * Create
     *
     * @desc 创建栈式内存池
     *       Create stack memory pool
     *
     * @param aSize 总大小 Total size
     * @param aAllocator 基础分配器 Base allocator (optional)
     *}
    constructor Create(aSize: SizeUInt; aAllocator: IAllocator = nil); overload;
    constructor Create(const aConfig: TStackPoolConfig); overload;

    {**
     * Destroy
     *
     * @desc 销毁栈式内存池
     *       Destroy stack memory pool
     *}
    destructor Destroy; override;

    {**
     * Alloc
     *
     * @desc 分配内存
     *       Allocate memory
     *
     * @param aSize 请求大小 Requested size
     * @param aAlignment 对齐要求 Alignment requirement (default: pointer size)
     * @return 内存指针 Memory pointer
     *}
    function Alloc(aSize: SizeUInt; aAlignment: SizeUInt = SizeOf(Pointer)): Pointer; inline;
    function AllocAligned(aSize: SizeUInt; aAlignment: SizeUInt): Pointer; inline;

    {**
     * TryAlloc
     *
     * @desc 尝试分配（不抛异常），失败返回 False
     *       Try to allocate (no exception), return False on failure
     *}
    function TryAlloc(aSize: SizeUInt; out APtr: Pointer; aAlignment: SizeUInt = SizeOf(Pointer)): Boolean; inline;
    function TryAllocAligned(aSize: SizeUInt; out APtr: Pointer; aAlignment: SizeUInt): Boolean; inline;

    {**
     * Reset
     *
     * @desc 重置栈，释放所有分配的内存
     *       Reset stack, free all allocated memory
     *}
    procedure Reset; inline;

    {**
     * SaveState
     *
     * @desc 保存当前状态
     *       Save current state
     *
     * @return 状态标记 State marker
     *}
    function SaveState: SizeUInt; inline;

    {**
     * RestoreState
     *
     * @desc 恢复到指定状态
     *       Restore to specified state
     *
     * @param aState 状态标记 State marker
     *}
    procedure RestoreState(aState: SizeUInt); inline;

    // 属性 Properties
    property TotalSize: SizeUInt read FSize;
    property UsedSize: SizeUInt read FOffset;
    property AvailableSize: SizeUInt read GetAvailableSize;

    function IsEmpty: Boolean;
    function IsFull: Boolean;
  end;

implementation

uses
  fafafa.core.mem.utils;

constructor TStackPool.Create(const aConfig: TStackPoolConfig);
begin
  Create(aConfig.TotalSize, aConfig.Allocator);
  if aConfig.ZeroOnAlloc and (FBuffer <> nil) then
    FillChar(FBuffer^, FSize, 0);
end;

{ TStackPool }

constructor TStackPool.Create(aSize: SizeUInt; aAllocator: IAllocator);
begin
  inherited Create;

  if aSize = 0 then
    raise Exception.Create('Stack size cannot be zero');

  FSize := aSize;
  FOffset := 0;

  if aAllocator = nil then
    FBaseAllocator := fafafa.core.mem.allocator.GetRtlAllocator
  else
    FBaseAllocator := aAllocator;

  FBuffer := FBaseAllocator.GetMem(aSize);
  if FBuffer = nil then
    raise Exception.Create('Failed to allocate stack buffer');
end;

destructor TStackPool.Destroy;
begin
  if FBuffer <> nil then
    FBaseAllocator.FreeMem(FBuffer);
  inherited Destroy;
end;

function TStackPool.Alloc(aSize: SizeUInt; aAlignment: SizeUInt): Pointer;
var
  LAlignedOffset: SizeUInt;
begin
  Result := nil;




  if aSize = 0 then
    Exit;

  // 防御性：对齐为 0 则使用指针大小；且对齐必须为 2 的幂（否则回退为指针大小）
  if aAlignment = 0 then
    aAlignment := SizeOf(Pointer);
  if (aAlignment and (aAlignment - 1)) <> 0 then
    aAlignment := SizeOf(Pointer);

  // 计算对齐后的偏移（中文注释）：按对齐要求向上取整
  LAlignedOffset := AlignOffset(FOffset, aAlignment);

  // 溢出与界限检查
  if (LAlignedOffset > FSize) or (aSize > FSize - LAlignedOffset) then
    Exit;

  // 返回指针并更新偏移（使用类型化指针算术以避免 4055）
  Result := Pointer(PByte(FBuffer) + LAlignedOffset);
  FOffset := LAlignedOffset + aSize;
end;

procedure TStackPool.Reset;
begin
  FOffset := 0;
end;

function TStackPool.SaveState: SizeUInt;
begin
  Result := FOffset;
end;

function TStackPool.TryAlloc(aSize: SizeUInt; out APtr: Pointer; aAlignment: SizeUInt): Boolean;
begin
  APtr := Alloc(aSize, aAlignment);
  Result := APtr <> nil;
end;

procedure TStackPool.RestoreState(aState: SizeUInt);
begin
  if aState <= FSize then
    FOffset := aState;
end;

function TStackPool.GetAvailableSize: SizeUInt;
begin
  Result := FSize - FOffset;
end;

function TStackPool.IsEmpty: Boolean;
begin
  Result := FOffset = 0;
end;

function TStackPool.IsFull: Boolean;
begin
  Result := FOffset >= FSize;
end;

function TStackPool.AllocAligned(aSize: SizeUInt; aAlignment: SizeUInt): Pointer;
begin
  if aSize = 0 then Exit(nil);
  if aAlignment = 0 then
    raise EInvalidArgument.Create('TStackPool.AllocAligned: aAlignment is 0');
  if (aAlignment and (aAlignment - 1)) <> 0 then
    raise EInvalidArgument.Create('TStackPool.AllocAligned: aAlignment must be power of two');
  Result := Alloc(aSize, aAlignment);
end;

function TStackPool.TryAllocAligned(aSize: SizeUInt; out APtr: Pointer; aAlignment: SizeUInt): Boolean;
begin
  try
    APtr := AllocAligned(aSize, aAlignment);
    Result := APtr <> nil;
  except
    APtr := nil;
    Result := False;
  end;
end;

function TStackPool.AlignOffset(aOffset, aAlignment: SizeUInt): SizeUInt;
begin
  if aAlignment <= 1 then
    Result := aOffset
  else
    Result := (aOffset + aAlignment - 1) and not (aAlignment - 1);
end;


end.
