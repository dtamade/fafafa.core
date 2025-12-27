{$CODEPAGE UTF8}
unit fafafa.core.mem.mappedRingBuffer;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fafafa.core.mem.memoryMap;

type
  {**
   * TMappedRingBufferMode
   *
   * @desc 映射环形缓冲区的访问模式
   *}
  TMappedRingBufferMode = (
    mrbProducer,    // 生产者模式（只写）
    mrbConsumer,    // 消费者模式（只读）
    mrbBidirectional // 双向模式（读写）
  );

  {**
   * TMappedRingBuffer
   *
   * @desc 基于内存映射的高性能跨进程环形缓冲区
   *       支持无锁的生产者/消费者模式
   *}
  TMappedRingBuffer = class
  private
    FMemoryMap: TMemoryMap;
    FSharedMemory: TSharedMemory;
    FIsShared: Boolean;
    FMode: TMappedRingBufferMode;
    FCapacity: UInt64;
    FElementSize: UInt32;
    FIsCreator: Boolean;

    // 内存布局指针
    FHeader: Pointer;
    // 双向布局：不再保留单一 SeqArray 指针
    FDataBuffer: Pointer;     // 本端“发送”方向数据区基址（Creator=AB，Opener=BA）
    FDataBufferIn: Pointer;   // 本端“接收”方向数据区基址（Creator=BA，Opener=AB）

    function GetWriteIndex: UInt64; inline;
    function GetReadIndex: UInt64; inline;
    procedure SetWriteIndex(const Value: UInt64); inline;
    procedure SetReadIndex(const Value: UInt64); inline;
    function GetAvailableSpace: UInt64;
    function GetUsedSpace: UInt64;
    function CalculateRequiredSize(aCapacity: UInt64; aElementSize: UInt32): UInt64;
    procedure InitializeHeader(aCapacity: UInt64; aElementSize: UInt32);
    function ValidateHeader: Boolean;

  public
    constructor Create;
    destructor Destroy; override;

    {**
     * CreateFile
     *
     * @desc 创建基于文件的环形缓冲区
     * @param aFileName 文件路径
     * @param aCapacity 容量（元素个数）
     * @param aElementSize 单个元素大小（字节）
     * @param aMode 访问模式
     * @return 是否成功
     *}
    function CreateFile(const aFileName: string; aCapacity: UInt64;
      aElementSize: UInt32; aMode: TMappedRingBufferMode = mrbBidirectional): Boolean;

    {**
     * OpenFile
     *
     * @desc 打开已存在的文件环形缓冲区
     * @param aFileName 文件路径
     * @param aMode 访问模式
     * @return 是否成功
     *}
    function OpenFile(const aFileName: string;
      aMode: TMappedRingBufferMode = mrbBidirectional): Boolean;

    {**
     * CreateShared
     *
     * @desc 创建跨进程共享环形缓冲区
     * @param aName 共享内存名称
     * @param aCapacity 容量（元素个数）
     * @param aElementSize 单个元素大小（字节）
     * @param aMode 访问模式
     * @return 是否成功
     *}
    function CreateShared(const aName: string; aCapacity: UInt64;
      aElementSize: UInt32; aMode: TMappedRingBufferMode = mrbBidirectional): Boolean;

    {**
     * OpenShared
     *
     * @desc 打开已存在的共享环形缓冲区
     * @param aName 共享内存名称
     * @param aMode 访问模式
     * @return 是否成功
     *}
    function OpenShared(const aName: string;
      aMode: TMappedRingBufferMode = mrbBidirectional): Boolean;

    {**
     * Close
     *
     * @desc 关闭环形缓冲区
     *}
    procedure Close;

    {**
     * Push
     *
     * @desc 向缓冲区写入一个元素（生产者操作）
     * @param aData 数据指针
     * @return 是否成功（缓冲区满时返回 False）
     *}
    function Push(const aData: Pointer): Boolean;

    {**
     * Pop
     *
     * @desc 从缓冲区读取一个元素（消费者操作）
     * @param aData 数据指针（输出）
     * @return 是否成功（缓冲区空时返回 False）
     *}
    function Pop(aData: Pointer): Boolean;

    {**
     * Peek
     *
     * @desc 查看下一个元素但不移除
     * @param aData 数据指针（输出）
     * @return 是否成功
     *}
    function Peek(aData: Pointer): Boolean;

    {**
     * PushBatch
     *
     * @desc 批量写入元素
     * @param aData 数据数组指针
     * @param aCount 元素个数
     * @return 实际写入的元素个数
     *}
    function PushBatch(const aData: Pointer; aCount: UInt64): UInt64;

    {**
     * PopBatch
     *
     * @desc 批量读取元素
     * @param aData 数据数组指针（输出）
     * @param aCount 期望读取的元素个数
     * @return 实际读取的元素个数
     *}
    function PopBatch(aData: Pointer; aCount: UInt64): UInt64;

    {**
     * Clear
     *
     * @desc 清空缓冲区（重置读写指针）
     *}
    procedure Clear;

    {**
     * IsEmpty
     *
     * @desc 检查缓冲区是否为空
     *}
    function IsEmpty: Boolean; inline;

    {**
     * IsFull
     *
     * @desc 检查缓冲区是否已满
     *}
    function IsFull: Boolean; inline;

    {**
     * IsValid
     *
     * @desc 检查缓冲区是否有效
     *}
    function IsValid: Boolean; inline;

    // 属性
    property Capacity: UInt64 read FCapacity;
    property ElementSize: UInt32 read FElementSize;
    property AvailableSpace: UInt64 read GetAvailableSpace;
    property UsedSpace: UInt64 read GetUsedSpace;
    property Mode: TMappedRingBufferMode read FMode;
    property IsCreator: Boolean read FIsCreator;
  end;

implementation

uses
  Classes, fafafa.core.atomic;

// Helper: next power of two for UInt64
function NextPow2U64(x: UInt64): UInt64; inline;
begin
  if x <= 1 then Exit(1);
  Dec(x);
  x := x or (x shr 1);
  x := x or (x shr 2);
  x := x or (x shr 4);
  x := x or (x shr 8);
  x := x or (x shr 16);
  x := x or (x shr 32);
  Inc(x);
  Result := x;
end;


const
  // 缓存行大小，避免伪共享
  CACHE_LINE_SIZE = 64;

type
  // 环形缓冲区头部结构（v2：支持双向两套ring）
  PMappedRingBufferHeader = ^TMappedRingBufferHeader;
  TMappedRingBufferHeader = packed record
    Magic: UInt32;           // 魔数，用于验证
    Version: UInt32;         // 版本号
    Capacity: UInt64;        // 容量（元素个数），强制为2的幂（两套ring共用此容量）
    Mask: UInt64;            // 快速取模掩码 = Capacity - 1
    ElementSize: UInt32;     // 单个元素大小
    Reserved1: UInt32;       // 保留字段
    // Ring AB（A->B）计数器（独立cacheline）
    ProducerSeq_AB: Int64;
    ConsumerSeq_AB: Int64;
    CachedConsumerSeq_AB: Int64;
    CachedProducerSeq_AB: Int64;
    AB_Padding: array[0..(CACHE_LINE_SIZE div SizeOf(Int64))*2-5] of Int64; // pad到两行，减少伪共享
    // Ring BA（B->A）计数器（独立cacheline）
    ProducerSeq_BA: Int64;
    ConsumerSeq_BA: Int64;
    CachedConsumerSeq_BA: Int64;
    CachedProducerSeq_BA: Int64;
    BA_Padding: array[0..(CACHE_LINE_SIZE div SizeOf(Int64))*2-5] of Int64;
    // 各区域偏移（相对基址）
    OffSeq_AB: UInt64;
    OffData_AB: UInt64;
    OffSeq_BA: UInt64;
    OffData_BA: UInt64;
  end;

const
  MAPPED_RINGBUFFER_MAGIC = $4D524246; // 'MRBF'
  MAPPED_RINGBUFFER_VERSION = 2;
  // 头部大小由头结构大小决定
  HEADER_SIZE = SizeOf(TMappedRingBufferHeader);

{ TMappedRingBuffer }

constructor TMappedRingBuffer.Create;
begin
  inherited Create;
  FMemoryMap := nil;
  FSharedMemory := nil;
  FIsShared := False;
  FMode := mrbBidirectional;
  FCapacity := 0;
  FElementSize := 0;
  FIsCreator := False;
  FHeader := nil;
  FDataBuffer := nil;
end;

destructor TMappedRingBuffer.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TMappedRingBuffer.CalculateRequiredSize(aCapacity: UInt64; aElementSize: UInt32): UInt64;
begin
  // 头部 + 数据缓冲区（对齐到缓存行）
  // 强制容量为2的幂
  if (aCapacity and (aCapacity - 1)) <> 0 then
    aCapacity := NextPow2U64(aCapacity);
  // 头 + 两套序号数组 + 两套数据区（双向）
  Result := HEADER_SIZE
          + (aCapacity * SizeOf(Int64)) + (aCapacity * aElementSize) // AB
          + (aCapacity * SizeOf(Int64)) + (aCapacity * aElementSize); // BA
  // 对齐到缓存行
  Result := ((Result + CACHE_LINE_SIZE - 1) div CACHE_LINE_SIZE) * CACHE_LINE_SIZE;
end;

procedure TMappedRingBuffer.InitializeHeader(aCapacity: UInt64; aElementSize: UInt32);
var
  Header: PMappedRingBufferHeader;
  i: UInt64;
  SeqPtr: PInt64;
begin
  Header := PMappedRingBufferHeader(FHeader);
  // 规范化容量为2的幂
  if (aCapacity and (aCapacity - 1)) <> 0 then
    aCapacity := NextPow2U64(aCapacity);
  Header^.Magic := MAPPED_RINGBUFFER_MAGIC;
  Header^.Version := MAPPED_RINGBUFFER_VERSION;
  Header^.Capacity := aCapacity;
  Header^.Mask := aCapacity - 1;
  Header^.ElementSize := aElementSize;
  // 同步设置对象字段
  FCapacity := aCapacity;
  FElementSize := aElementSize;
  // 初始化序号计数器（双向）
  atomic_store_64(Header^.ProducerSeq_AB, 0, mo_relaxed);
  atomic_store_64(Header^.ConsumerSeq_AB, 0, mo_relaxed);
  atomic_store_64(Header^.CachedConsumerSeq_AB, 0, mo_relaxed);
  atomic_store_64(Header^.CachedProducerSeq_AB, 0, mo_relaxed);
  atomic_store_64(Header^.ProducerSeq_BA, 0, mo_relaxed);
  atomic_store_64(Header^.ConsumerSeq_BA, 0, mo_relaxed);
  atomic_store_64(Header^.CachedConsumerSeq_BA, 0, mo_relaxed);
  atomic_store_64(Header^.CachedProducerSeq_BA, 0, mo_relaxed);
  // 计算并写入双向偏移（基于规范化后的容量）
  Header^.OffSeq_AB := HEADER_SIZE;
  Header^.OffData_AB := Header^.OffSeq_AB + aCapacity * SizeOf(Int64);
  Header^.OffSeq_BA := Header^.OffData_AB + aCapacity * aElementSize;
  Header^.OffData_BA := Header^.OffSeq_BA + aCapacity * SizeOf(Int64);
  // 初始化两套序列数组：空槽期望值 = 索引值
  for i := 0 to aCapacity - 1 do
  begin
    SeqPtr := PInt64(PByte(FHeader) + Header^.OffSeq_AB + i * SizeOf(Int64));
    atomic_store_64(SeqPtr^, i, mo_relaxed);
    SeqPtr := PInt64(PByte(FHeader) + Header^.OffSeq_BA + i * SizeOf(Int64));
    atomic_store_64(SeqPtr^, i, mo_relaxed);
  end;
end;

function TMappedRingBuffer.ValidateHeader: Boolean;
var
  Header: PMappedRingBufferHeader;
begin
  Result := False;
  if FHeader = nil then Exit;

  Header := PMappedRingBufferHeader(FHeader);
  if (Header^.Magic <> MAPPED_RINGBUFFER_MAGIC) or
     (Header^.Version <> MAPPED_RINGBUFFER_VERSION) then
    Exit;

  FCapacity := Header^.Capacity;
  FElementSize := Header^.ElementSize;
  Result := True;
end;

function TMappedRingBuffer.GetWriteIndex: UInt64;
begin
  if FHeader = nil then Exit(0);
  // 仅用于旧语义的估算：返回当前方向的序号
  if FIsCreator then
    Result := atomic_load_64(PMappedRingBufferHeader(FHeader)^.ProducerSeq_AB, mo_relaxed)
  else
    Result := atomic_load_64(PMappedRingBufferHeader(FHeader)^.ProducerSeq_BA, mo_relaxed);
end;

function TMappedRingBuffer.GetReadIndex: UInt64;
begin
  if FHeader = nil then Exit(0);
  if FIsCreator then
    Result := atomic_load_64(PMappedRingBufferHeader(FHeader)^.ConsumerSeq_AB, mo_relaxed)
  else
    Result := atomic_load_64(PMappedRingBufferHeader(FHeader)^.ConsumerSeq_BA, mo_relaxed);
end;

procedure TMappedRingBuffer.SetWriteIndex(const Value: UInt64);
begin
  if FIsCreator then
    atomic_store_64(PMappedRingBufferHeader(FHeader)^.ProducerSeq_AB, Value, mo_relaxed)
  else
    atomic_store_64(PMappedRingBufferHeader(FHeader)^.ProducerSeq_BA, Value, mo_relaxed);
end;

procedure TMappedRingBuffer.SetReadIndex(const Value: UInt64);
begin
  if FIsCreator then
    atomic_store_64(PMappedRingBufferHeader(FHeader)^.ConsumerSeq_AB, Value, mo_relaxed)
  else
    atomic_store_64(PMappedRingBufferHeader(FHeader)^.ConsumerSeq_BA, Value, mo_relaxed);
end;

function TMappedRingBuffer.GetAvailableSpace: UInt64;
var
  WriteIdx, ReadIdx: UInt64;
begin
  WriteIdx := GetWriteIndex;
  ReadIdx := GetReadIndex;
  if WriteIdx >= ReadIdx then
    Result := FCapacity - (WriteIdx - ReadIdx)
  else
    Result := ReadIdx - WriteIdx;
  if Result > 0 then Dec(Result); // 留一个空槽以区分满/空
end;

function TMappedRingBuffer.GetUsedSpace: UInt64;
begin
  Result := FCapacity - GetAvailableSpace;
end;

{$PUSH}
{$WARN 6018 OFF} // 局部屏蔽：不可达代码（多处 Exit 快路径）
function TMappedRingBuffer.CreateFile(const aFileName: string; aCapacity: UInt64;
  aElementSize: UInt32; aMode: TMappedRingBufferMode): Boolean;
var
  RequiredSize: UInt64;
  Access: TMemoryMapAccess;
begin
  Result := False;
  Close;

  if (aCapacity = 0) or (aElementSize = 0) then Exit;

  RequiredSize := CalculateRequiredSize(aCapacity, aElementSize);

  // 根据模式确定访问权限
  case aMode of
    mrbProducer: Access := mmaWrite;
    mrbConsumer: Access := mmaRead;
    mrbBidirectional: Access := mmaReadWrite;
  else
    Access := mmaReadWrite;
  end;

  FMemoryMap := TMemoryMap.Create;
  try
    // 尝试打开现有文件
    if FileExists(aFileName) then
    begin
      if not FMemoryMap.OpenFile(aFileName, Access) then Exit;
      FIsCreator := False;
    end
    else
    begin
      // 创建新文件
      with TFileStream.Create(aFileName, fmCreate) do
      try
        Size := RequiredSize;
      finally
        Free;
      end;

      if not FMemoryMap.OpenFile(aFileName, Access) then Exit;
      FIsCreator := True;
    end;

    FIsShared := False;
    FMode := aMode;
    FHeader := FMemoryMap.BaseAddress;
    // 单向默认绑定 AB 方向数据区
    FDataBuffer := Pointer(PByte(FHeader) + PMappedRingBufferHeader(FHeader)^.OffData_AB);
    FDataBufferIn := Pointer(PByte(FHeader) + PMappedRingBufferHeader(FHeader)^.OffData_BA);

    if FIsCreator then
    begin
      InitializeHeader(aCapacity, aElementSize);
    end
    else
    begin
      if not ValidateHeader then Exit;
    end;

    Result := True;
  except
    FreeAndNil(FMemoryMap);
  end;
end;
{$POP}

{$PUSH}
{$WARN 6018 OFF}
function TMappedRingBuffer.OpenFile(const aFileName: string;
  aMode: TMappedRingBufferMode): Boolean;
var
  Access: TMemoryMapAccess;
begin
  Result := False;
  Close;

  if not FileExists(aFileName) then Exit;

  case aMode of
    mrbProducer: Access := mmaWrite;
    mrbConsumer: Access := mmaRead;
    mrbBidirectional: Access := mmaReadWrite;
  else
    Access := mmaReadWrite;
  end;

  FMemoryMap := TMemoryMap.Create;
  try
    if not FMemoryMap.OpenFile(aFileName, Access) then Exit;

    FIsShared := False;
    FMode := aMode;
    FIsCreator := False;
    FHeader := FMemoryMap.BaseAddress;
    // 先校验头，再计算偏移
    if not ValidateHeader then Exit;
    FDataBuffer := Pointer(PByte(FHeader) + PMappedRingBufferHeader(FHeader)^.OffData_AB);
    FDataBufferIn := Pointer(PByte(FHeader) + PMappedRingBufferHeader(FHeader)^.OffData_BA);

    Result := True;
  except
    FreeAndNil(FMemoryMap);
  end;
end;
{$POP}

{$PUSH}
{$WARN 6018 OFF}
function TMappedRingBuffer.CreateShared(const aName: string; aCapacity: UInt64;
  aElementSize: UInt32; aMode: TMappedRingBufferMode): Boolean;
var
  RequiredSize: UInt64;
  Access: TMemoryMapAccess;
begin
  Result := False;
  Close;

  if (aCapacity = 0) or (aElementSize = 0) then Exit;

  RequiredSize := CalculateRequiredSize(aCapacity, aElementSize);

  case aMode of
    mrbProducer: Access := mmaWrite;
    mrbConsumer: Access := mmaRead;
    mrbBidirectional: Access := mmaReadWrite;
  else
    Access := mmaReadWrite;
  end;

  FSharedMemory := TSharedMemory.Create;
  try
    if FSharedMemory.CreateShared(aName, RequiredSize, Access) then
    begin
      FIsCreator := FSharedMemory.IsCreator;
    end
    else
    begin
      // 尝试打开已存在的
      if not FSharedMemory.OpenShared(aName, Access) then Exit;
      FIsCreator := False;
    end;

    FIsShared := True;
    FMode := aMode;
    FHeader := FSharedMemory.BaseAddress;

    if FIsCreator then
    begin
      InitializeHeader(aCapacity, aElementSize);
    end
    else
    begin
      if not ValidateHeader then Exit;
    end;

    // 必须在 InitializeHeader/ValidateHeader 之后设置，因为 offset 字段需要先初始化
    FDataBuffer := Pointer(PByte(FHeader) + PMappedRingBufferHeader(FHeader)^.OffData_AB);
    FDataBufferIn := Pointer(PByte(FHeader) + PMappedRingBufferHeader(FHeader)^.OffData_BA);

    Result := True;
  except
    FreeAndNil(FSharedMemory);
  end;
end;
{$POP}

{$PUSH}
{$WARN 6018 OFF}
function TMappedRingBuffer.OpenShared(const aName: string;
  aMode: TMappedRingBufferMode): Boolean;
var
  Access: TMemoryMapAccess;
begin
  Result := False;
  Close;

  case aMode of
    mrbProducer: Access := mmaWrite;
    mrbConsumer: Access := mmaRead;
    mrbBidirectional: Access := mmaReadWrite;
  else
    Access := mmaReadWrite;
  end;

  FSharedMemory := TSharedMemory.Create;
  try
    if not FSharedMemory.OpenShared(aName, Access) then Exit;

    FIsShared := True;
    FMode := aMode;
    FIsCreator := False;
    FHeader := FSharedMemory.BaseAddress;
    // 先校验头，再计算偏移
    if not ValidateHeader then Exit;
    FDataBuffer := Pointer(PByte(FHeader) + PMappedRingBufferHeader(FHeader)^.OffData_AB);
    FDataBufferIn := Pointer(PByte(FHeader) + PMappedRingBufferHeader(FHeader)^.OffData_BA);

    Result := True;
  except
    FreeAndNil(FSharedMemory);
  end;
end;
{$POP}

procedure TMappedRingBuffer.Close;
begin
  FHeader := nil;
  FDataBuffer := nil;
  FCapacity := 0;
  FElementSize := 0;
  FIsCreator := False;

  if Assigned(FMemoryMap) then
  begin
    FMemoryMap.Free;
    FMemoryMap := nil;
  end;

  if Assigned(FSharedMemory) then
  begin
    FSharedMemory.Free;
    FSharedMemory := nil;
  end;

  FIsShared := False;
end;

{$PUSH}
{$WARN 6058 OFF} // 局部屏蔽：inline 未内联提示
function TMappedRingBuffer.Push(const aData: Pointer): Boolean;
var
  Header: PMappedRingBufferHeader;
  LProdSeq, LConsSeq, LCachedCons: Int64;
  Index: UInt64;
  ExpectedSeq: Int64;
  SeqPtr: PInt64;
  DataPtr: Pointer;
begin
  Result := False;
  if not IsValid or (FMode = mrbConsumer) then Exit;

  Header := PMappedRingBufferHeader(FHeader);
  // 发送方向选择：Creator端使用AB，Open端使用BA
  if FIsCreator then
    LProdSeq := atomic_load_64(Header^.ProducerSeq_AB, mo_relaxed)
  else
    LProdSeq := atomic_load_64(Header^.ProducerSeq_BA, mo_relaxed);
  Index := UInt64(LProdSeq) and Header^.Mask;
  if FIsCreator then
    SeqPtr := PInt64(PByte(FHeader) + Header^.OffSeq_AB + Index * SizeOf(Int64))
  else
    SeqPtr := PInt64(PByte(FHeader) + Header^.OffSeq_BA + Index * SizeOf(Int64));

  // 槽位可用性检查：期望等于 LProdSeq
  ExpectedSeq := LProdSeq;
  if atomic_load_64(SeqPtr^, mo_acquire) <> ExpectedSeq then
  begin
    // 检查是否满：Prod - CachedCons >= Capacity
    if FIsCreator then
      LCachedCons := atomic_load_64(Header^.CachedConsumerSeq_AB, mo_relaxed)
    else
      LCachedCons := atomic_load_64(Header^.CachedConsumerSeq_BA, mo_relaxed);
    if (LProdSeq - LCachedCons) >= Int64(Header^.Capacity) then
    begin
      if FIsCreator then
        LConsSeq := atomic_load_64(Header^.ConsumerSeq_AB, mo_acquire)
      else
        LConsSeq := atomic_load_64(Header^.ConsumerSeq_BA, mo_acquire);
      if FIsCreator then
        atomic_store_64(Header^.CachedConsumerSeq_AB, LConsSeq, mo_relaxed)
      else
        atomic_store_64(Header^.CachedConsumerSeq_BA, LConsSeq, mo_relaxed);
      if (LProdSeq - LConsSeq) >= Int64(Header^.Capacity) then Exit(False);
    end
    else
      Exit(False);
  end;

  // 写入数据
  DataPtr := Pointer(PByte(FDataBuffer) + (Index * UInt64(FElementSize)));
  Move(aData^, DataPtr^, FElementSize);

  // 发布槽位：sequence = LProdSeq + 1（release）
  atomic_store_64(SeqPtr^, LProdSeq + 1, mo_release);
  // 推进生产者序号（relaxed）
  if FIsCreator then
    atomic_store_64(Header^.ProducerSeq_AB, LProdSeq + 1, mo_relaxed)
  else
    atomic_store_64(Header^.ProducerSeq_BA, LProdSeq + 1, mo_relaxed);

  Result := True;
end;

{$PUSH}
{$WARN 6058 OFF}
function TMappedRingBuffer.Pop(aData: Pointer): Boolean;
var
  Header: PMappedRingBufferHeader;
  LConsSeq, LProdSeq, LCachedProd: Int64;
  Index: UInt64;
  ExpectedSeq: Int64;
  SeqPtr: PInt64;
  DataPtr: Pointer;
begin
  Result := False;
  if not IsValid or (FMode = mrbProducer) then Exit;

  Header := PMappedRingBufferHeader(FHeader);
  // 接收方向选择：Creator端读取AB，Open端读取BA
  if FIsCreator then
    LConsSeq := atomic_load_64(Header^.ConsumerSeq_AB, mo_relaxed)
  else
    LConsSeq := atomic_load_64(Header^.ConsumerSeq_BA, mo_relaxed);
  Index := UInt64(LConsSeq) and Header^.Mask;
  if FIsCreator then
    SeqPtr := PInt64(PByte(FHeader) + Header^.OffSeq_AB + Index * SizeOf(Int64))
  else
    SeqPtr := PInt64(PByte(FHeader) + Header^.OffSeq_BA + Index * SizeOf(Int64));

  // 槽位可读性检查：期望等于 LConsSeq + 1
  ExpectedSeq := LConsSeq + 1;
  if atomic_load_64(SeqPtr^, mo_acquire) <> ExpectedSeq then
  begin
    // 检查是否空：CachedProd - Cons <= 0
    if FIsCreator then
      LCachedProd := atomic_load_64(Header^.CachedProducerSeq_AB, mo_relaxed)
    else
      LCachedProd := atomic_load_64(Header^.CachedProducerSeq_BA, mo_relaxed);
    if (LCachedProd - LConsSeq) <= 0 then
    begin
      if FIsCreator then
        LProdSeq := atomic_load_64(Header^.ProducerSeq_AB, mo_acquire)
      else
        LProdSeq := atomic_load_64(Header^.ProducerSeq_BA, mo_acquire);
      if FIsCreator then
        atomic_store_64(Header^.CachedProducerSeq_AB, LProdSeq, mo_relaxed)
      else
        atomic_store_64(Header^.CachedProducerSeq_BA, LProdSeq, mo_relaxed);
      if (LProdSeq - LConsSeq) <= 0 then Exit(False);
    end
    else
      Exit(False);
  end;

  // 读取数据
  DataPtr := Pointer(PByte(FDataBuffer) + (Index * UInt64(FElementSize)));
  Move(DataPtr^, aData^, FElementSize);

  // 释放槽位：sequence = LConsSeq + Capacity（release）
  atomic_store_64(SeqPtr^, LConsSeq + Int64(Header^.Capacity), mo_release);
  // 推进消费者序号
  if FIsCreator then
    atomic_store_64(Header^.ConsumerSeq_AB, LConsSeq + 1, mo_relaxed)
  else
    atomic_store_64(Header^.ConsumerSeq_BA, LConsSeq + 1, mo_relaxed);

  Result := True;
end;
{$POP}
{$POP}

{$PUSH}
{$WARN 6058 OFF}
function TMappedRingBuffer.Peek(aData: Pointer): Boolean;
var
  Header: PMappedRingBufferHeader;
  LConsSeq, LProdSeq, LCachedProd: Int64;
  Index: UInt64;
  ExpectedSeq: Int64;
  SeqPtr: PInt64;
  DataPtr: Pointer;
begin
  Result := False;
  if not IsValid or (FMode = mrbProducer) then Exit;

  Header := PMappedRingBufferHeader(FHeader);
  if FIsCreator then
    LConsSeq := atomic_load_64(Header^.ConsumerSeq_AB, mo_relaxed)
  else
    LConsSeq := atomic_load_64(Header^.ConsumerSeq_BA, mo_relaxed);
  Index := UInt64(LConsSeq) and Header^.Mask;
  if FIsCreator then
    SeqPtr := PInt64(PByte(FHeader) + Header^.OffSeq_AB + Index * SizeOf(Int64))
  else
    SeqPtr := PInt64(PByte(FHeader) + Header^.OffSeq_BA + Index * SizeOf(Int64));

  ExpectedSeq := LConsSeq + 1;
  if atomic_load_64(SeqPtr^, mo_acquire) <> ExpectedSeq then
  begin
    if FIsCreator then
      LCachedProd := atomic_load_64(Header^.CachedProducerSeq_AB, mo_relaxed)
    else
      LCachedProd := atomic_load_64(Header^.CachedProducerSeq_BA, mo_relaxed);
    if (LCachedProd - LConsSeq) <= 0 then
    begin
      if FIsCreator then
        LProdSeq := atomic_load_64(Header^.ProducerSeq_AB, mo_acquire)
      else
        LProdSeq := atomic_load_64(Header^.ProducerSeq_BA, mo_acquire);
      if FIsCreator then
        atomic_store_64(Header^.CachedProducerSeq_AB, LProdSeq, mo_relaxed)
      else
        atomic_store_64(Header^.CachedProducerSeq_BA, LProdSeq, mo_relaxed);
      if (LProdSeq - LConsSeq) <= 0 then Exit(False);
    end
    else
      Exit(False);
  end;

  DataPtr := Pointer(PByte(FDataBuffer) + (Index * UInt64(FElementSize)));
  Move(DataPtr^, aData^, FElementSize);

  Result := True;
end;
{$POP}

{$PUSH}
{$WARN 6058 OFF}
function TMappedRingBuffer.PushBatch(const aData: Pointer; aCount: UInt64): UInt64;
var
  WriteIdx, ReadIdx, AvailSpace, BatchSize: UInt64;
  i: UInt64;
  SrcPtr, DstPtr: Pointer;
begin
  Result := 0;
  if not IsValid or (FMode = mrbConsumer) or (aCount = 0) then Exit;

  WriteIdx := GetWriteIndex;
  ReadIdx := GetReadIndex;

  // 计算可用空间
  if WriteIdx >= ReadIdx then
    AvailSpace := FCapacity - (WriteIdx - ReadIdx) - 1
  else
    AvailSpace := ReadIdx - WriteIdx - 1;

  if aCount < AvailSpace then BatchSize := aCount else BatchSize := AvailSpace;
  if BatchSize = 0 then Exit;

  // 批量复制数据
  for i := 0 to BatchSize - 1 do
  begin
    SrcPtr := Pointer(PByte(aData) + i * FElementSize);
    DstPtr := Pointer(PByte(FDataBuffer) + ((WriteIdx + i) mod FCapacity) * FElementSize);
    Move(SrcPtr^, DstPtr^, FElementSize);
  end;

  // 原子更新写入索引
  SetWriteIndex((WriteIdx + BatchSize) mod FCapacity);

  Result := BatchSize;
end;

{$PUSH}
{$WARN 6058 OFF}
function TMappedRingBuffer.PopBatch(aData: Pointer; aCount: UInt64): UInt64;
var
  WriteIdx, ReadIdx, BatchSize: UInt64;
  i: UInt64;
  SrcPtr, DstPtr: Pointer;
begin
  Result := 0;
  if not IsValid or (FMode = mrbProducer) or (aCount = 0) then Exit;

  WriteIdx := GetWriteIndex;
  ReadIdx := GetReadIndex;

  // 计算已用空间并确定批量大小
  if WriteIdx >= ReadIdx then
  begin
    if aCount < (WriteIdx - ReadIdx) then
      BatchSize := aCount
    else
      BatchSize := WriteIdx - ReadIdx;
  end
  else
  begin
    if aCount < (FCapacity - (ReadIdx - WriteIdx)) then
      BatchSize := aCount
    else
      BatchSize := FCapacity - (ReadIdx - WriteIdx);
  end;
  if BatchSize = 0 then Exit;

  // 批量复制数据
  for i := 0 to BatchSize - 1 do
  begin
    SrcPtr := Pointer(PByte(FDataBuffer) + ((ReadIdx + i) mod FCapacity) * FElementSize);
    DstPtr := Pointer(PByte(aData) + i * FElementSize);
    Move(SrcPtr^, DstPtr^, FElementSize);
  end;

  // 原子更新读取索引
  SetReadIndex((ReadIdx + BatchSize) mod FCapacity);

  Result := BatchSize;
end;
{$POP}

procedure TMappedRingBuffer.Clear;
begin
  if not IsValid then Exit;
  SetWriteIndex(0);
  SetReadIndex(0);
end;

function TMappedRingBuffer.IsEmpty: Boolean;
begin
  Result := not IsValid or (GetWriteIndex = GetReadIndex);
end;

function TMappedRingBuffer.IsFull: Boolean;
var
  WriteIdx, ReadIdx: UInt64;
begin
  Result := False;
  if not IsValid then Exit;

  WriteIdx := GetWriteIndex;
  ReadIdx := GetReadIndex;
  Result := ((WriteIdx + 1) mod FCapacity) = ReadIdx;
end;

function TMappedRingBuffer.IsValid: Boolean;
begin
  Result := (FHeader <> nil) and (FDataBuffer <> nil) and
            (FCapacity > 0) and (FElementSize > 0) and
            ((FMemoryMap <> nil) or (FSharedMemory <> nil));
end;

end.
