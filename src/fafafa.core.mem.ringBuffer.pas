{
```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.mem.ringBuffer

## Abstract 摘要

High-performance ring buffer implementation for efficient circular data management.
高性能环形缓冲区实现，用于高效的循环数据管理。

## Declaration 声明

For forwarding or using it for your own project, please retain the copyright notice of this project. Thank you.
转发或者用于自己项目请保留本项目的版权声明,谢谢.

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

unit fafafa.core.mem.ringBuffer;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.mem.allocator;

type
  {** 操作结果枚举 Operation result **}
  TRingOpResult = (
    rrOk,
    rrEmpty,
    rrFull,
    rrBadArg,
    rrAllocFailed,
    rrOverflow,
    rrUnsupported
  );

  {**
   * TRingBuffer
   *
   * @desc 高性能环形缓冲区
   *       High-performance ring buffer
   *}
  TRingBuffer = class
  private
    FBuffer: Pointer;
    FCapacity: SizeUInt;
    FElementSize: SizeUInt;
    FHead: SizeUInt;      // 读取位置 Read position
    FTail: SizeUInt;      // 写入位置 Write position
    FCount: SizeUInt;     // 当前元素数量 Current element count
    FBaseAllocator: TAllocator;
    FIsPow2Capacity: Boolean;

    function GetElementPtr(aIndex: SizeUInt): Pointer; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    function GetNextIndex(aIndex: SizeUInt): SizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

  public
    {**
     * Create
     *
     * @desc 创建环形缓冲区
     *       Create ring buffer
     *
     * @param aCapacity 容量（元素数量）Capacity (number of elements)
     * @param aElementSize 元素大小 Element size
     * @param aAllocator 基础分配器 Base allocator (optional)
     *}
    constructor Create(aCapacity: SizeUInt; aElementSize: SizeUInt; aAllocator: TAllocator = nil);

    {**
     * Destroy
     *
     * @desc 销毁环形缓冲区
     *       Destroy ring buffer
     *}
    destructor Destroy; override;

    {**
     * Push
     *
     * @desc 向缓冲区写入数据
     *       Write data to buffer
     *
     * @param aData 数据指针 Data pointer
     * @return 是否成功 Success flag
     *}
    function Push(aData: Pointer): Boolean;
    function TryPush(aData: Pointer): TRingOpResult;

    {**
     * Pop
     *
     * @desc 从缓冲区读取数据
     *       Read data from buffer
     *
     * @param aData 数据指针 Data pointer
     * @return 是否成功 Success flag
     *}
    function Pop(aData: Pointer): Boolean;
    function TryPop(aData: Pointer): TRingOpResult;

    {**
     * Peek
     *
     * @desc 查看数据但不移除
     *       Peek data without removing
     *
     * @param aData 数据指针 Data pointer
     * @param aOffset 偏移量 Offset (default: 0)
     * @return 是否成功 Success flag
     *}
    function Peek(aData: Pointer; aOffset: SizeUInt = 0): Boolean;

    {**
     * Clear
     *
     * @desc 清空缓冲区
     *       Clear buffer
     *}
    procedure Clear;

    {**
     * Resize
     *
     * @desc 调整缓冲区大小
     *       Resize buffer
     *
     * @param aNewCapacity 新容量 New capacity
     * @return 是否成功 Success flag
     *}
    function Resize(aNewCapacity: SizeUInt): Boolean;

    { 批量操作 Batch operations }
    function Push(aData: Pointer; aCount: SizeUInt; out aPushed: SizeUInt): Boolean; overload; // prefer overload naming
    function Pop(aData: Pointer; aCount: SizeUInt; out aPopped: SizeUInt): Boolean; overload; // prefer overload naming
    // deprecated aliases (kept for compatibility)
    function PushN(aData: Pointer; aCount: SizeUInt; out aPushed: SizeUInt): Boolean; deprecated 'Use overloaded Push(aData, aCount, out aPushed)';
    function PopN(aData: Pointer; aCount: SizeUInt; out aPopped: SizeUInt): Boolean; deprecated 'Use overloaded Pop(aData, aCount, out aPopped)';

    { 连续片段 Contiguous spans }
    procedure GetContiguousWriteSpan(out aPtr: Pointer; out aLenInElems: SizeUInt);
    procedure GetContiguousReadSpan(out aPtr: Pointer; out aLenInElems: SizeUInt);

    // 属性 Properties
    property Capacity: SizeUInt read FCapacity;
    property ElementSize: SizeUInt read FElementSize;
    property Count: SizeUInt read FCount;

    // 状态查询 Status queries
    function IsEmpty: Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    function IsFull: Boolean; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    function GetAvailableSpace: SizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    function GetUsageRatio: Single; // 使用率 (0.0..1.0)
    function GetUsagePercent: Single; // 使用率百分比 (0..100)
  end;

  {**
   * TTypedRingBuffer<T>
   *
   * @desc 类型安全的泛型环形缓冲区
   *       Type-safe generic ring buffer
   *}
  generic TTypedRingBuffer<T> = class(TRingBuffer)
  public
    constructor Create(aCapacity: SizeUInt; aAllocator: TAllocator = nil);
    function Push(const aItem: T): Boolean; reintroduce;
    function Pop(out aItem: T): Boolean; reintroduce;
    function Peek(out aItem: T; aOffset: SizeUInt = 0): Boolean; reintroduce;
    function TryPush(const aItem: T): TRingOpResult; reintroduce;
    function TryPop(out aItem: T): TRingOpResult; reintroduce;
  end;

implementation

uses
  fafafa.core.mem.utils;

{ TRingBuffer }

constructor TRingBuffer.Create(aCapacity: SizeUInt; aElementSize: SizeUInt; aAllocator: TAllocator);
begin
  inherited Create;

  if aCapacity = 0 then
    raise Exception.Create('Capacity cannot be zero');
  if aElementSize = 0 then
    raise Exception.Create('Element size cannot be zero');

  FCapacity := aCapacity;
  FElementSize := aElementSize;
  FHead := 0;
  FTail := 0;
  FCount := 0;
  FIsPow2Capacity := fafafa.core.mem.utils.IsPowerOfTwo(FCapacity);

  if aAllocator = nil then
    FBaseAllocator := fafafa.core.mem.allocator.GetRtlAllocator
  else
    FBaseAllocator := aAllocator;

  // 防止乘法溢出并分配内存
  if (FElementSize <> 0) and (FCapacity > MAX_SIZE_UINT div FElementSize) then
    raise Exception.Create('Requested size exceeds addressable memory range');

  FBuffer := FBaseAllocator.GetMem(FCapacity * FElementSize);
  if FBuffer = nil then
    raise Exception.Create('Failed to allocate ring buffer memory');
end;

destructor TRingBuffer.Destroy;
begin
  if FBuffer <> nil then
    FBaseAllocator.FreeMem(FBuffer);
  inherited Destroy;
end;

function TRingBuffer.GetElementPtr(aIndex: SizeUInt): Pointer;
begin
  Result := Pointer(PtrUInt(FBuffer) + (aIndex * FElementSize));
end;

function TRingBuffer.GetNextIndex(aIndex: SizeUInt): SizeUInt;
var
  LNext: SizeUInt;
begin
  // 优化环增：容量为2的幂时用位与；否则用边界分支避免取模
  if FIsPow2Capacity then
  begin
    Result := (aIndex + 1) and (FCapacity - 1);
  end
  else
  begin
    LNext := aIndex + 1;
    if LNext >= FCapacity then
      Result := 0
    else
      Result := LNext;
  end;
end;

function TRingBuffer.Push(aData: Pointer): Boolean;
begin
  Result := TryPush(aData) = rrOk;
end;

function TRingBuffer.TryPush(aData: Pointer): TRingOpResult;
begin
  if aData = nil then Exit(rrBadArg);
  if IsFull then Exit(rrFull);

  // 复制数据到缓冲区
  fafafa.core.mem.utils.Copy(aData, GetElementPtr(FTail), FElementSize);

  // 更新尾指针和计数
  FTail := GetNextIndex(FTail);
  Inc(FCount);

  Result := rrOk;
end;

function TRingBuffer.Push(aData: Pointer; aCount: SizeUInt; out aPushed: SizeUInt): Boolean; overload;
var
  LSpace, LToWrite, LFirst, LSecond: SizeUInt;
begin
  aPushed := 0;
  if aData = nil then Exit(False);
  if aCount = 0 then Exit(True);

  LSpace := GetAvailableSpace;
  if LSpace = 0 then Exit(False);

  if LSpace < aCount then
    LToWrite := LSpace
  else
    LToWrite := aCount;

  // 第一段：尾到末尾
  LFirst := LToWrite;
  if LFirst > (FCapacity - FTail) then
    LFirst := (FCapacity - FTail);
  if LFirst > 0 then
    fafafa.core.mem.utils.CopyNonOverlap(aData, GetElementPtr(FTail), LFirst * FElementSize);

  // 第二段：从0开始
  LSecond := LToWrite - LFirst;
  if LSecond > 0 then
    fafafa.core.mem.utils.CopyNonOverlap(Pointer(PtrUInt(aData) + (LFirst * FElementSize)), FBuffer, LSecond * FElementSize);

  FTail := (FTail + LToWrite) mod FCapacity;
  Inc(FCount, LToWrite);

  aPushed := LToWrite;
  Result := aPushed > 0;
end;

function TRingBuffer.PushN(aData: Pointer; aCount: SizeUInt; out aPushed: SizeUInt): Boolean;
begin
  Result := Push(aData, aCount, aPushed);
end;

function TRingBuffer.Pop(aData: Pointer): Boolean;
begin
  Result := TryPop(aData) = rrOk;
end;

function TRingBuffer.TryPop(aData: Pointer): TRingOpResult;
begin
  if aData = nil then Exit(rrBadArg);
  if IsEmpty then Exit(rrEmpty);

  // 复制数据从缓冲区
  fafafa.core.mem.utils.Copy(GetElementPtr(FHead), aData, FElementSize);

  // 更新头指针和计数
  FHead := GetNextIndex(FHead);
  Dec(FCount);

  Result := rrOk;
end;

function TRingBuffer.Pop(aData: Pointer; aCount: SizeUInt; out aPopped: SizeUInt): Boolean; overload;
var
  LAvail, LToRead, LFirst, LSecond: SizeUInt;
begin
  aPopped := 0;
  if aData = nil then Exit(False);
  if aCount = 0 then Exit(True);

  if IsEmpty then Exit(False);

  LAvail := FCount;
  if LAvail < aCount then
    LToRead := LAvail
  else
    LToRead := aCount;

  // 第一段：头到末尾
  LFirst := LToRead;
  if LFirst > (FCapacity - FHead) then
    LFirst := (FCapacity - FHead);
  if LFirst > 0 then
    fafafa.core.mem.utils.CopyNonOverlap(GetElementPtr(FHead), aData, LFirst * FElementSize);

  // 第二段：从0开始
  LSecond := LToRead - LFirst;
  if LSecond > 0 then
    fafafa.core.mem.utils.CopyNonOverlap(FBuffer, Pointer(PtrUInt(aData) + (LFirst * FElementSize)), LSecond * FElementSize);

  FHead := (FHead + LToRead) mod FCapacity;
  Dec(FCount, LToRead);

  aPopped := LToRead;
  Result := aPopped > 0;
end;

function TRingBuffer.PopN(aData: Pointer; aCount: SizeUInt; out aPopped: SizeUInt): Boolean;
begin
  Result := Pop(aData, aCount, aPopped);
end;

function TRingBuffer.Peek(aData: Pointer; aOffset: SizeUInt): Boolean;
var
  LIndex: SizeUInt;
begin
  Result := False;
  if aData = nil then Exit;
  if aOffset >= FCount then Exit;

  LIndex := (FHead + aOffset) mod FCapacity;
  fafafa.core.mem.utils.Copy(GetElementPtr(LIndex), aData, FElementSize);

  Result := True;
end;

procedure TRingBuffer.Clear;
begin
  FHead := 0;
  FTail := 0;
  FCount := 0;
  // 出于性能考虑，不默认清零缓冲区内容；数据将被后续写入覆盖
end;

function TRingBuffer.Resize(aNewCapacity: SizeUInt): Boolean;
var
  LNewBuffer: Pointer;
  LNewSize: SizeUInt;
  LToCopy: SizeUInt;
  LFirstChunk, LSecondChunk: SizeUInt;
  LSrcPtr, LDstPtr: Pointer;
begin
  Result := False;
  if aNewCapacity = 0 then Exit;
  if aNewCapacity = FCapacity then
  begin
    Result := True;
    Exit;
  end;

  // 检查乘法溢出
  if (FElementSize <> 0) and (aNewCapacity > MAX_SIZE_UINT div FElementSize) then
    Exit(False);

  LNewSize := aNewCapacity * FElementSize;
  LNewBuffer := FBaseAllocator.GetMem(LNewSize);
  if LNewBuffer = nil then Exit(False);

  // 如果有数据，需要迁移（保留最旧的前 aNewCapacity 个元素）
  if FCount > 0 then
  begin
    // 需要迁移的元素数量
    if FCount > aNewCapacity then
      LToCopy := aNewCapacity
    else
      LToCopy := FCount;

    // 第一段：从 FHead 到 末尾
    if LToCopy <= (FCapacity - FHead) then
      LFirstChunk := LToCopy
    else
      LFirstChunk := (FCapacity - FHead);

    // 复制第一段
    {$PUSH}{$WARN 4055 OFF}
    LSrcPtr := Pointer(PtrUInt(FBuffer) + (FHead * FElementSize));
    LDstPtr := LNewBuffer;
    {$POP}
    if LFirstChunk > 0 then
      fafafa.core.mem.utils.CopyNonOverlap(LSrcPtr, LDstPtr, LFirstChunk * FElementSize);

    // 复制第二段（从 0 到 FTail-1）
    LSecondChunk := LToCopy - LFirstChunk;
    if LSecondChunk > 0 then
    begin
      {$PUSH}{$WARN 4055 OFF}
      LSrcPtr := FBuffer;
      LDstPtr := Pointer(PtrUInt(LNewBuffer) + (LFirstChunk * FElementSize));
      {$POP}
      fafafa.core.mem.utils.CopyNonOverlap(LSrcPtr, LDstPtr, LSecondChunk * FElementSize);
    end;

    // 更新为迁移后的数量
    FCount := LToCopy;
  end;

  // 释放旧缓冲区
  FBaseAllocator.FreeMem(FBuffer);

  // 更新状态
  FBuffer := LNewBuffer;
  FCapacity := aNewCapacity;
  FIsPow2Capacity := fafafa.core.mem.utils.IsPowerOfTwo(FCapacity);
  FHead := 0;
  if FCapacity > 0 then
    FTail := FCount mod FCapacity
  else
    FTail := 0;

  Result := True;
end;

procedure TRingBuffer.GetContiguousWriteSpan(out aPtr: Pointer; out aLenInElems: SizeUInt);
begin
  if IsFull then
  begin
    aPtr := nil;
    aLenInElems := 0;
    Exit;
  end;
  aPtr := GetElementPtr(FTail);
  aLenInElems := GetAvailableSpace;
  if aLenInElems > (FCapacity - FTail) then
    aLenInElems := (FCapacity - FTail);
end;

procedure TRingBuffer.GetContiguousReadSpan(out aPtr: Pointer; out aLenInElems: SizeUInt);
begin
  if IsEmpty then
  begin
    aPtr := nil;
    aLenInElems := 0;
    Exit;
  end;
  aPtr := GetElementPtr(FHead);
  aLenInElems := FCount;
  if aLenInElems > (FCapacity - FHead) then
    aLenInElems := (FCapacity - FHead);
end;

function TRingBuffer.IsEmpty: Boolean;
begin
  Result := FCount = 0;
end;

function TRingBuffer.IsFull: Boolean;
begin
  Result := FCount = FCapacity;
end;

function TRingBuffer.GetAvailableSpace: SizeUInt;
begin
  Result := FCapacity - FCount;
end;

function TRingBuffer.GetUsageRatio: Single;
begin
  if FCapacity = 0 then
    Result := 0.0
  else
    Result := FCount / FCapacity;
end;

function TRingBuffer.GetUsagePercent: Single;
begin
  Result := GetUsageRatio * 100.0;
end;

{ TTypedRingBuffer<T> }

constructor TTypedRingBuffer.Create(aCapacity: SizeUInt; aAllocator: TAllocator);
begin
  inherited Create(aCapacity, SizeOf(T), aAllocator);
end;

function TTypedRingBuffer.Push(const aItem: T): Boolean;
begin
  Result := inherited Push(@aItem);
end;

function TTypedRingBuffer.TryPush(const aItem: T): TRingOpResult;
begin
  Result := inherited TryPush(@aItem);
end;

function TTypedRingBuffer.Pop(out aItem: T): Boolean;
begin
  Result := inherited Pop(@aItem);
end;

function TTypedRingBuffer.TryPop(out aItem: T): TRingOpResult;
begin
  Result := inherited TryPop(@aItem);
end;

function TTypedRingBuffer.Peek(out aItem: T; aOffset: SizeUInt): Boolean;
begin
  Result := inherited Peek(@aItem, aOffset);
end;

end.
