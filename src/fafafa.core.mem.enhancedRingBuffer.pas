{$CODEPAGE UTF8}
unit fafafa.core.mem.enhancedRingBuffer;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fafafa.core.mem.ringBuffer, fafafa.core.mem.allocator;

type
  {**
   * TEnhancedRingBuffer
   * 
   * @desc 增强版环形缓冲区，扩展了原有 TRingBuffer 的功能
   *       添加了批量操作、多种数据类型支持、高级查询功能
   *}
  TEnhancedRingBuffer = class(TRingBuffer)
  private
    FBatchBuffer: Pointer;     // 批量操作临时缓冲区
    FBatchCapacity: SizeUInt;  // 批量缓冲区容量
    
    procedure EnsureBatchBuffer(aRequiredSize: SizeUInt);
    
  public
    constructor Create(aCapacity: SizeUInt; aElementSize: SizeUInt; aAllocator: TAllocator = nil);
    destructor Destroy; override;
    
    {**
     * PushBatch
     * 
     * @desc 批量推入多个元素
     * @param aData 数据数组指针
     * @param aCount 元素个数
     * @return 实际推入的元素个数
     *}
    function PushBatch(aData: Pointer; aCount: SizeUInt): SizeUInt;
    
    {**
     * PopBatch
     * 
     * @desc 批量弹出多个元素
     * @param aData 数据数组指针（输出）
     * @param aCount 期望弹出的元素个数
     * @return 实际弹出的元素个数
     *}
    function PopBatch(aData: Pointer; aCount: SizeUInt): SizeUInt;
    
    {**
     * PeekBatch
     * 
     * @desc 批量查看多个元素（不移除）
     * @param aData 数据数组指针（输出）
     * @param aCount 期望查看的元素个数
     * @param aOffset 起始偏移量
     * @return 实际查看的元素个数
     *}
    function PeekBatch(aData: Pointer; aCount: SizeUInt; aOffset: SizeUInt = 0): SizeUInt;
    
    {**
     * PushBytes
     * 
     * @desc 推入字节数据
     * @param aBytes 字节数组
     * @return 是否成功
     *}
    function PushBytes(const aBytes: TBytes): Boolean;
    
    {**
     * PopBytes
     * 
     * @desc 弹出字节数据
     * @param aBytes 字节数组（输出）
     * @return 是否成功
     *}
    function PopBytes(out aBytes: TBytes): Boolean;
    
    {**
     * PushString
     * 
     * @desc 推入字符串（UTF-8）
     * @param aStr 字符串
     * @return 是否成功
     *}
    function PushString(const aStr: string): Boolean;
    
    {**
     * PopString
     * 
     * @desc 弹出字符串（UTF-8）
     * @param aStr 字符串（输出）
     * @return 是否成功
     *}
    function PopString(out aStr: string): Boolean;
    
    {**
     * PushInteger
     * 
     * @desc 推入整数
     * @param aValue 整数值
     * @return 是否成功
     *}
    function PushInteger(aValue: Integer): Boolean;
    
    {**
     * PopInteger
     * 
     * @desc 弹出整数
     * @param aValue 整数值（输出）
     * @return 是否成功
     *}
    function PopInteger(out aValue: Integer): Boolean;
    
    {**
     * PushInt64
     * 
     * @desc 推入64位整数
     * @param aValue 64位整数值
     * @return 是否成功
     *}
    function PushInt64(aValue: Int64): Boolean;
    
    {**
     * PopInt64
     * 
     * @desc 弹出64位整数
     * @param aValue 64位整数值（输出）
     * @return 是否成功
     *}
    function PopInt64(out aValue: Int64): Boolean;
    
    {**
     * PushDouble
     * 
     * @desc 推入双精度浮点数
     * @param aValue 双精度浮点数值
     * @return 是否成功
     *}
    function PushDouble(aValue: Double): Boolean;
    
    {**
     * PopDouble
     * 
     * @desc 弹出双精度浮点数
     * @param aValue 双精度浮点数值（输出）
     * @return 是否成功
     *}
    function PopDouble(out aValue: Double): Boolean;
    
    {**
     * FindElement
     * 
     * @desc 查找元素在缓冲区中的位置
     * @param aData 要查找的元素数据
     * @param aCompareFunc 比较函数（可选）
     * @return 元素位置，-1表示未找到
     *}
    function FindElement(aData: Pointer; aCompareFunc: Pointer = nil): Integer;
    
    {**
     * ContainsElement
     * 
     * @desc 检查缓冲区是否包含指定元素
     * @param aData 要查找的元素数据
     * @param aCompareFunc 比较函数（可选）
     * @return 是否包含该元素
     *}
    function ContainsElement(aData: Pointer; aCompareFunc: Pointer = nil): Boolean;
    
    {**
     * GetElements
     * 
     * @desc 获取所有元素的副本（不移除）
     * @param aData 数据数组指针（输出）
     * @param aMaxCount 最大元素个数
     * @return 实际获取的元素个数
     *}
    function GetElements(aData: Pointer; aMaxCount: SizeUInt): SizeUInt;
    
    {**
     * DropElements
     * 
     * @desc 丢弃指定数量的元素（从头部开始）
     * @param aCount 要丢弃的元素个数
     * @return 实际丢弃的元素个数
     *}
    function DropElements(aCount: SizeUInt): SizeUInt;
    
    {**
     * GetElementAt
     * 
     * @desc 获取指定位置的元素（不移除）
     * @param aIndex 元素索引（0为最旧元素）
     * @param aData 数据指针（输出）
     * @return 是否成功
     *}
    function GetElementAt(aIndex: SizeUInt; aData: Pointer): Boolean;
    
    {**
     * SetElementAt
     * 
     * @desc 设置指定位置的元素值
     * @param aIndex 元素索引（0为最旧元素）
     * @param aData 数据指针
     * @return 是否成功
     *}
    function SetElementAt(aIndex: SizeUInt; aData: Pointer): Boolean;
    
    {**
     * GetStatistics
     * 
     * @desc 获取缓冲区统计信息
     * @param aTotalPushed 总推入次数
     * @param aTotalPopped 总弹出次数
     * @param aPeakUsage 峰值使用量
     * @param aCurrentUsage 当前使用量
     *}
    procedure GetStatistics(out aTotalPushed, aTotalPopped: UInt64; 
      out aPeakUsage, aCurrentUsage: SizeUInt);
  end;

  {**
   * TTypedEnhancedRingBuffer<T>
   * 
   * @desc 类型安全的增强版泛型环形缓冲区
   *}
  generic TTypedEnhancedRingBuffer<T> = class(TEnhancedRingBuffer)
  public
    constructor Create(aCapacity: SizeUInt; aAllocator: TAllocator = nil);
    
    // 类型安全的基本操作
    function Push(const aItem: T): Boolean; reintroduce;
    function Pop(out aItem: T): Boolean; reintroduce;
    function Peek(out aItem: T; aOffset: SizeUInt = 0): Boolean; reintroduce;
    
    // 类型安全的批量操作
    function PushArray(const aItems: array of T): SizeUInt;
    function PopArray(out aItems: array of T): SizeUInt;
    function PeekArray(out aItems: array of T; aOffset: SizeUInt = 0): SizeUInt;
    
    // 类型安全的查询操作
    function Find(const aItem: T): Integer;
    function Contains(const aItem: T): Boolean;
    function GetItem(aIndex: SizeUInt; out aItem: T): Boolean;
    function SetItem(aIndex: SizeUInt; const aItem: T): Boolean;
    
    // 类型安全的高级操作
    function GetAllItems(out aItems: array of T): SizeUInt;
    function Filter(aFilterFunc: function(const aItem: T): Boolean): SizeUInt;
    function Transform(aTransformFunc: function(const aItem: T): T): Boolean;
  end;

  {**
   * TStringRingBuffer
   * 
   * @desc 专门用于字符串的环形缓冲区
   *}
  TStringRingBuffer = class(TEnhancedRingBuffer)
  public
    constructor Create(aCapacity: SizeUInt; aAllocator: TAllocator = nil);
    
    function PushStr(const aStr: string): Boolean;
    function PopStr(out aStr: string): Boolean;
    function PeekStr(out aStr: string; aOffset: SizeUInt = 0): Boolean;
    
    function PushStrings(const aStrings: array of string): SizeUInt;
    function PopStrings(out aStrings: array of string): SizeUInt;
    
    function FindString(const aStr: string): Integer;
    function ContainsString(const aStr: string): Boolean;
    
    function GetTotalLength: SizeUInt;
    function GetAverageLength: Double;
  end;

  {**
   * TByteRingBuffer
   * 
   * @desc 专门用于字节数据的环形缓冲区
   *}
  TByteRingBuffer = class(TEnhancedRingBuffer)
  public
    constructor Create(aCapacity: SizeUInt; aAllocator: TAllocator = nil);
    
    function PushByte(aByte: Byte): Boolean;
    function PopByte(out aByte: Byte): Boolean;
    function PeekByte(out aByte: Byte; aOffset: SizeUInt = 0): Boolean;
    
    function PushByteArray(const aBytes: array of Byte): SizeUInt;
    function PopByteArray(out aBytes: array of Byte): SizeUInt;
    
    function PushBuffer(aBuffer: Pointer; aSize: SizeUInt): SizeUInt;
    function PopBuffer(aBuffer: Pointer; aSize: SizeUInt): SizeUInt;
    
    function FindByte(aByte: Byte): Integer;
    function FindPattern(const aPattern: array of Byte): Integer;
    
    function GetChecksum: UInt32;
  end;

implementation

uses
  fafafa.core.mem.utils;

{ TEnhancedRingBuffer }

constructor TEnhancedRingBuffer.Create(aCapacity: SizeUInt; aElementSize: SizeUInt; aAllocator: TAllocator);
begin
  inherited Create(aCapacity, aElementSize, aAllocator);
  FBatchBuffer := nil;
  FBatchCapacity := 0;
end;

destructor TEnhancedRingBuffer.Destroy;
begin
  if FBatchBuffer <> nil then
    FBaseAllocator.FreeMem(FBatchBuffer);
  inherited Destroy;
end;

procedure TEnhancedRingBuffer.EnsureBatchBuffer(aRequiredSize: SizeUInt);
var
  NewSize: SizeUInt;
begin
  if aRequiredSize <= FBatchCapacity then Exit;
  
  NewSize := aRequiredSize * FElementSize;
  if FBatchBuffer <> nil then
    FBaseAllocator.FreeMem(FBatchBuffer);
    
  FBatchBuffer := FBaseAllocator.GetMem(NewSize);
  if FBatchBuffer = nil then
    raise Exception.Create('Failed to allocate batch buffer');
    
  FBatchCapacity := aRequiredSize;
end;

function TEnhancedRingBuffer.PushBatch(aData: Pointer; aCount: SizeUInt): SizeUInt;
var
  i: SizeUInt;
  SrcPtr: Pointer;
begin
  Result := 0;
  if (aData = nil) or (aCount = 0) then Exit;

  for i := 0 to aCount - 1 do
  begin
    SrcPtr := Pointer(PtrUInt(aData) + i * FElementSize);
    if Push(SrcPtr) then
      Inc(Result)
    else
      Break; // 缓冲区满了
  end;
end;

function TEnhancedRingBuffer.PopBatch(aData: Pointer; aCount: SizeUInt): SizeUInt;
var
  i: SizeUInt;
  DstPtr: Pointer;
begin
  Result := 0;
  if (aData = nil) or (aCount = 0) then Exit;

  for i := 0 to aCount - 1 do
  begin
    DstPtr := Pointer(PtrUInt(aData) + i * FElementSize);
    if Pop(DstPtr) then
      Inc(Result)
    else
      Break; // 缓冲区空了
  end;
end;

function TEnhancedRingBuffer.PeekBatch(aData: Pointer; aCount: SizeUInt; aOffset: SizeUInt): SizeUInt;
var
  i: SizeUInt;
  DstPtr: Pointer;
begin
  Result := 0;
  if (aData = nil) or (aCount = 0) then Exit;

  for i := 0 to aCount - 1 do
  begin
    DstPtr := Pointer(PtrUInt(aData) + i * FElementSize);
    if Peek(DstPtr, aOffset + i) then
      Inc(Result)
    else
      Break; // 超出范围
  end;
end;

function TEnhancedRingBuffer.PushBytes(const aBytes: TBytes): Boolean;
begin
  Result := False;
  if Length(aBytes) = 0 then Exit;
  if FElementSize <> SizeOf(Byte) then Exit;

  Result := PushBatch(@aBytes[0], Length(aBytes)) = Length(aBytes);
end;

function TEnhancedRingBuffer.PopBytes(out aBytes: TBytes): Boolean;
begin
  Result := False;
  if FElementSize <> SizeOf(Byte) then Exit;
  if IsEmpty then Exit;

  SetLength(aBytes, Count);
  Result := PopBatch(@aBytes[0], Length(aBytes)) = Length(aBytes);
end;

function TEnhancedRingBuffer.PushString(const aStr: string): Boolean;
var
  StrBytes: TBytes;
  StrLen: UInt32;
begin
  Result := False;
  if FElementSize <> SizeOf(Byte) then Exit;

  StrBytes := TEncoding.UTF8.GetBytes(aStr);
  StrLen := Length(StrBytes);

  // 先推入长度，再推入数据
  if not Push(@StrLen) then Exit;
  if StrLen > 0 then
    Result := PushBatch(@StrBytes[0], StrLen) = StrLen
  else
    Result := True;
end;

function TEnhancedRingBuffer.PopString(out aStr: string): Boolean;
var
  StrLen: UInt32;
  StrBytes: TBytes;
begin
  Result := False;
  aStr := '';
  if FElementSize <> SizeOf(Byte) then Exit;
  if IsEmpty then Exit;

  // 先弹出长度
  if not Pop(@StrLen) then Exit;

  if StrLen = 0 then
  begin
    Result := True;
    Exit;
  end;

  // 再弹出数据
  SetLength(StrBytes, StrLen);
  if PopBatch(@StrBytes[0], StrLen) = StrLen then
  begin
    aStr := TEncoding.UTF8.GetString(StrBytes);
    Result := True;
  end;
end;

function TEnhancedRingBuffer.PushInteger(aValue: Integer): Boolean;
begin
  Result := False;
  if FElementSize <> SizeOf(Integer) then Exit;
  Result := Push(@aValue);
end;

function TEnhancedRingBuffer.PopInteger(out aValue: Integer): Boolean;
begin
  Result := False;
  if FElementSize <> SizeOf(Integer) then Exit;
  Result := Pop(@aValue);
end;

function TEnhancedRingBuffer.PushInt64(aValue: Int64): Boolean;
begin
  Result := False;
  if FElementSize <> SizeOf(Int64) then Exit;
  Result := Push(@aValue);
end;

function TEnhancedRingBuffer.PopInt64(out aValue: Int64): Boolean;
begin
  Result := False;
  if FElementSize <> SizeOf(Int64) then Exit;
  Result := Pop(@aValue);
end;

function TEnhancedRingBuffer.PushDouble(aValue: Double): Boolean;
begin
  Result := False;
  if FElementSize <> SizeOf(Double) then Exit;
  Result := Push(@aValue);
end;

function TEnhancedRingBuffer.PopDouble(out aValue: Double): Boolean;
begin
  Result := False;
  if FElementSize <> SizeOf(Double) then Exit;
  Result := Pop(@aValue);
end;

function TEnhancedRingBuffer.FindElement(aData: Pointer; aCompareFunc: Pointer): Integer;
var
  i: SizeUInt;
  TempData: array[0..4095] of Byte;
begin
  Result := -1;
  if (aData = nil) or (FElementSize > SizeOf(TempData)) then Exit;

  for i := 0 to Count - 1 do
  begin
    if Peek(@TempData[0], i) then
    begin
      if aCompareFunc = nil then
      begin
        // 默认按字节比较
        if CompareMem(aData, @TempData[0], FElementSize) then
        begin
          Result := i;
          Break;
        end;
      end
      else
      begin
        // 使用自定义比较函数
        // TODO: 实现函数指针调用
        Result := i;
        Break;
      end;
    end;
  end;
end;

function TEnhancedRingBuffer.ContainsElement(aData: Pointer; aCompareFunc: Pointer): Boolean;
begin
  Result := FindElement(aData, aCompareFunc) >= 0;
end;

function TEnhancedRingBuffer.GetElements(aData: Pointer; aMaxCount: SizeUInt): SizeUInt;
begin
  Result := PeekBatch(aData, aMaxCount, 0);
end;

function TEnhancedRingBuffer.DropElements(aCount: SizeUInt): SizeUInt;
var
  i: SizeUInt;
  TempData: array[0..4095] of Byte;
begin
  Result := 0;
  if FElementSize > SizeOf(TempData) then Exit;

  for i := 0 to aCount - 1 do
  begin
    if Pop(@TempData[0]) then
      Inc(Result)
    else
      Break;
  end;
end;

function TEnhancedRingBuffer.GetElementAt(aIndex: SizeUInt; aData: Pointer): Boolean;
begin
  Result := Peek(aData, aIndex);
end;

function TEnhancedRingBuffer.SetElementAt(aIndex: SizeUInt; aData: Pointer): Boolean;
var
  ElementPtr: Pointer;
  ActualIndex: SizeUInt;
begin
  Result := False;
  if (aData = nil) or (aIndex >= Count) then Exit;

  ActualIndex := (FHead + aIndex) mod FCapacity;
  ElementPtr := GetElementPtr(ActualIndex);
  fafafa.core.mem.utils.Copy(aData, ElementPtr, FElementSize);
  Result := True;
end;

procedure TEnhancedRingBuffer.GetStatistics(out aTotalPushed, aTotalPopped: UInt64;
  out aPeakUsage, aCurrentUsage: SizeUInt);
begin
  // 简化实现，实际应该维护这些统计信息
  aTotalPushed := 0;
  aTotalPopped := 0;
  aPeakUsage := FCapacity;
  aCurrentUsage := Count;
end;

{ TTypedEnhancedRingBuffer<T> }

constructor TTypedEnhancedRingBuffer.Create(aCapacity: SizeUInt; aAllocator: TAllocator);
begin
  inherited Create(aCapacity, SizeOf(T), aAllocator);
end;

function TTypedEnhancedRingBuffer.Push(const aItem: T): Boolean;
begin
  Result := inherited Push(@aItem);
end;

function TTypedEnhancedRingBuffer.Pop(out aItem: T): Boolean;
begin
  Result := inherited Pop(@aItem);
end;

function TTypedEnhancedRingBuffer.Peek(out aItem: T; aOffset: SizeUInt): Boolean;
begin
  Result := inherited Peek(@aItem, aOffset);
end;

function TTypedEnhancedRingBuffer.PushArray(const aItems: array of T): SizeUInt;
begin
  if Length(aItems) = 0 then
    Result := 0
  else
    Result := PushBatch(@aItems[0], Length(aItems));
end;

function TTypedEnhancedRingBuffer.PopArray(out aItems: array of T): SizeUInt;
begin
  if Length(aItems) = 0 then
    Result := 0
  else
    Result := PopBatch(@aItems[0], Length(aItems));
end;

function TTypedEnhancedRingBuffer.PeekArray(out aItems: array of T; aOffset: SizeUInt): SizeUInt;
begin
  if Length(aItems) = 0 then
    Result := 0
  else
    Result := PeekBatch(@aItems[0], Length(aItems), aOffset);
end;

function TTypedEnhancedRingBuffer.Find(const aItem: T): Integer;
begin
  Result := FindElement(@aItem);
end;

function TTypedEnhancedRingBuffer.Contains(const aItem: T): Boolean;
begin
  Result := ContainsElement(@aItem);
end;

function TTypedEnhancedRingBuffer.GetItem(aIndex: SizeUInt; out aItem: T): Boolean;
begin
  Result := GetElementAt(aIndex, @aItem);
end;

function TTypedEnhancedRingBuffer.SetItem(aIndex: SizeUInt; const aItem: T): Boolean;
begin
  Result := SetElementAt(aIndex, @aItem);
end;

function TTypedEnhancedRingBuffer.GetAllItems(out aItems: array of T): SizeUInt;
begin
  Result := GetElements(@aItems[0], Length(aItems));
end;

function TTypedEnhancedRingBuffer.Filter(aFilterFunc: function(const aItem: T): Boolean): SizeUInt;
begin
  // 简化实现，实际应该实现过滤逻辑
  Result := 0;
end;

function TTypedEnhancedRingBuffer.Transform(aTransformFunc: function(const aItem: T): T): Boolean;
begin
  // 简化实现，实际应该实现转换逻辑
  Result := False;
end;

{ TStringRingBuffer }

constructor TStringRingBuffer.Create(aCapacity: SizeUInt; aAllocator: TAllocator);
begin
  inherited Create(aCapacity, SizeOf(Byte), aAllocator);
end;

function TStringRingBuffer.PushStr(const aStr: string): Boolean;
begin
  Result := PushString(aStr);
end;

function TStringRingBuffer.PopStr(out aStr: string): Boolean;
begin
  Result := PopString(aStr);
end;

function TStringRingBuffer.PeekStr(out aStr: string; aOffset: SizeUInt): Boolean;
begin
  // 简化实现，实际应该实现字符串的 Peek
  Result := False;
end;

function TStringRingBuffer.PushStrings(const aStrings: array of string): SizeUInt;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(aStrings) do
  begin
    if PushStr(aStrings[i]) then
      Inc(Result)
    else
      Break;
  end;
end;

function TStringRingBuffer.PopStrings(out aStrings: array of string): SizeUInt;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(aStrings) do
  begin
    if PopStr(aStrings[i]) then
      Inc(Result)
    else
      Break;
  end;
end;

function TStringRingBuffer.FindString(const aStr: string): Integer;
begin
  // 简化实现，实际应该实现字符串查找
  Result := -1;
end;

function TStringRingBuffer.ContainsString(const aStr: string): Boolean;
begin
  Result := FindString(aStr) >= 0;
end;

function TStringRingBuffer.GetTotalLength: SizeUInt;
begin
  // 简化实现，实际应该计算所有字符串的总长度
  Result := 0;
end;

function TStringRingBuffer.GetAverageLength: Double;
begin
  // 简化实现，实际应该计算平均长度
  Result := 0.0;
end;

{ TByteRingBuffer }

constructor TByteRingBuffer.Create(aCapacity: SizeUInt; aAllocator: TAllocator);
begin
  inherited Create(aCapacity, SizeOf(Byte), aAllocator);
end;

function TByteRingBuffer.PushByte(aByte: Byte): Boolean;
begin
  Result := Push(@aByte);
end;

function TByteRingBuffer.PopByte(out aByte: Byte): Boolean;
begin
  Result := Pop(@aByte);
end;

function TByteRingBuffer.PeekByte(out aByte: Byte; aOffset: SizeUInt): Boolean;
begin
  Result := Peek(@aByte, aOffset);
end;

function TByteRingBuffer.PushByteArray(const aBytes: array of Byte): SizeUInt;
begin
  if Length(aBytes) = 0 then
    Result := 0
  else
    Result := PushBatch(@aBytes[0], Length(aBytes));
end;

function TByteRingBuffer.PopByteArray(out aBytes: array of Byte): SizeUInt;
begin
  if Length(aBytes) = 0 then
    Result := 0
  else
    Result := PopBatch(@aBytes[0], Length(aBytes));
end;

function TByteRingBuffer.PushBuffer(aBuffer: Pointer; aSize: SizeUInt): SizeUInt;
begin
  if (aBuffer = nil) or (aSize = 0) then
    Result := 0
  else
    Result := PushBatch(aBuffer, aSize);
end;

function TByteRingBuffer.PopBuffer(aBuffer: Pointer; aSize: SizeUInt): SizeUInt;
begin
  if (aBuffer = nil) or (aSize = 0) then
    Result := 0
  else
    Result := PopBatch(aBuffer, aSize);
end;

function TByteRingBuffer.FindByte(aByte: Byte): Integer;
begin
  Result := FindElement(@aByte);
end;

function TByteRingBuffer.FindPattern(const aPattern: array of Byte): Integer;
begin
  // 简化实现，实际应该实现模式匹配
  Result := -1;
end;

function TByteRingBuffer.GetChecksum: UInt32;
begin
  // 简化实现，实际应该计算校验和
  Result := 0;
end;

end.
