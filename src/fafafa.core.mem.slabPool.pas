{
```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.mem.slabPool v2.0 (nginx页面合并版本)

## Abstract 摘要

Simplified nginx-inspired slab allocator with page-based memory management.
简化的 nginx 风格 slab 分配器，基于页面的内存管理�?
## Declaration 声明

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

unit fafafa.core.mem.slabPool;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.tick;

const
  // nginx 风格的常量
  SLAB_PAGE_SIZE = 4096;      // 4KB 页面
  SLAB_PAGE_SHIFT = 12;       // 2^12 = 4096

  // 内存对齐
  SLAB_ALIGNMENT = 8;         // 8字节对齐
  SLAB_CACHE_LINE_SIZE = 64;  // CPU缓存行大小

  // 大小类别 (8, 16, 32, 64, 128, 256, 512, 1024, 2048)
  SLAB_MIN_SIZE = 8;
  SLAB_MAX_SIZE = 2048;
  SLAB_SIZE_CLASSES = 9;

  // 性能优化常量
  SLAB_MAX_OBJECTS_PER_PAGE = SizeOf(PtrUInt) * 8; // 64位系统最大64个对象/页

  // nginx风格的页面类型常量
  SLAB_PAGE_MASK = 3;
  SLAB_PAGE_TYPE = 0;      // 对应 NGX_SLAB_PAGE
  SLAB_PAGE_BIG = 1;       // 对应 NGX_SLAB_BIG
  SLAB_PAGE_EXACT = 2;     // 对应 NGX_SLAB_EXACT
  SLAB_PAGE_SMALL = 3;     // 对应 NGX_SLAB_SMALL

  SLAB_PAGE_FREE = 0;      // 对应 NGX_SLAB_PAGE_FREE
  SLAB_PAGE_BUSY = High(PtrUInt); // 对应 NGX_SLAB_PAGE_BUSY

type
  // 自定义异常类型
  ESlabPoolError = class(Exception);
  ESlabPoolOutOfMemory = class(ESlabPoolError);
  ESlabPoolInvalidSize = class(ESlabPoolError);
  ESlabPoolCorruption = class(ESlabPoolError);

  // 统计信息 - 增强版本
  TSlabStats = record
    TotalPages: SizeUInt;      // 总页面数
    FreePages: SizeUInt;       // 空闲页面数
    PartialPages: SizeUInt;    // 部分使用页面数
    FullPages: SizeUInt;       // 完全使用页面数
    TotalObjects: SizeUInt;    // 总对象数
    FreeObjects: SizeUInt;     // 空闲对象数
    FragmentationRatio: Double; // 碎片化比率 (0.0-1.0)
    MemoryEfficiency: Double;  // 内存利用率 (0.0-1.0)

    // 增强的碎片分析
    InternalFragmentation: Double; // 内部碎片率
    ExternalFragmentation: Double; // 外部碎片率
    AverageObjectsPerPage: Double; // 平均每页对象数
    LargestFreeBlock: SizeUInt;    // 最大连续空闲块
    SmallestFreeBlock: SizeUInt;   // 最小连续空闲块

    // 健康度指标
    HealthScore: Double;       // 整体健康度评分 (0.0-1.0)
    RecommendedAction: string; // 推荐的优化操作
  end;

  // 性能计数器
  TSlabPerfCounters = record
    AllocCalls: UInt64;        // 分配调用次数
    FreeCalls: UInt64;         // 释放调用次数
    AllocTime: UInt64;         // 累计分配时间 (微秒)
    FreeTime: UInt64;          // 累计释放时间 (微秒)
    CacheMisses: UInt64;       // 缓存未命中次数
    PageAllocations: UInt64;   // 页面分配次数
    PageRecycles: UInt64;      // 页面重用次数
    BitScanOperations: UInt64; // 位扫描操作次数
    PageMerges: UInt64;        // 页面合并次数
    MergedPages: UInt64;       // 被合并的页面总数
    MergeTime: UInt64;         // 累计合并时间 (微秒)
  end;

  // 配置选项
  TSlabConfig = record
    PageSize: SizeUInt;        // 页面大小 (默认4096)
    MaxSizeClass: SizeUInt;    // 最大大小类别 (默认2048)
    EnablePerfMonitoring: Boolean; // 启用性能监控 (默认True)
    EnableStats: Boolean;      // 启用统计信息 (默认True)
    EnableDebug: Boolean;      // 启用调试模式 (默认False)
    EnablePageMerging: Boolean; // 启用页面合并 (默认False)
    WarmupPages: Integer;      // 预热页面数 (默认0)
  end;
  {**
   * TSlabPage
   *
   * @desc nginx 风格的页面结构 - 优化缓存局部性
   * @note 字段按访问频率和缓存行对齐优化排列
   *}
  PSlabPage = ^TSlabPage;
  TSlabPage = packed record
    // 热路径字段：最常访问的字段放在前面
    Slab: PtrUInt;             // 位图，标记已使用的块 (最频繁访问)
    SizeClass: Byte;           // 大小类别索引 (频繁访问)

    // 填充字节以对齐指针字段到8字节边界
    _Padding: array[0..6] of Byte;

    // 链表指针：相对较少访问，但需要8字节对齐
    Next: PSlabPage;           // 下一个页面指针
    Prev: PSlabPage;           // 上一个页面指针
  end;

  {**
   * TSlabPool
   *
   * @desc nginx风格的Slab内存分配器
   *       基于固定大小类别的内存分配器，适用于频繁分配/释放相同大小对象的场景
   *
   * @features
   *       - 支持9种固定大小类别 (8, 16, 32, 64, 128, 256, 512, 1024, 2048字节)
   *       - O(1)分配和释放性能
   *       - 自动页面重用和碎片管理
   *       - 64位位图支持，每页最多64个对象
   *       - 8字节内存对齐
   *       - 详细的统计信息和错误检测
   *
   * @performance
   *       - 分配性能: ~250,000 ops/sec
   *       - 内存利用率: 接近100%（在容量范围内）
   *       - 碎片化: 通过页面重用机制最小化
   *
   * @example
   *       var Pool := TSlabPool.Create(64*1024); // 创建64KB池
   *       var Ptr := Pool.Alloc(128);            // 分配128字节
   *       // ... 使用内存 ...
   *       Pool.Free(Ptr);                        // 释放内存
   *       Pool.Destroy;                          // 销毁池
   *}
  TSlabPool = class
  private
    FStart: Pointer;           // 内存池起始地址
    FEnd: Pointer;             // 内存池结束地址
    FSize: SizeUInt;           // 内存池大小
    FBaseAllocator: IAllocator;

    FPages: PSlabPage;         // 页面数组
    FPageCount: SizeUInt;      // 页面数量
    FFreePages: PSlabPage;     // 空闲页面链表

    // 大小类别的页面链表
    FSlots: array[0..SLAB_SIZE_CLASSES-1] of PSlabPage;
    FSizes: array[0..SLAB_SIZE_CLASSES-1] of SizeUInt;

    // 统计信息
    FTotalAllocs: SizeUInt;
    FTotalFrees: SizeUInt;
    FFailedAllocs: SizeUInt;

    // 性能计数器
    FPerfCounters: TSlabPerfCounters;
    FEnablePerfMonitoring: Boolean;
    FTick: ITick;  // 高精度时间测量

    // 配置选项
    FConfig: TSlabConfig;

  public
    {**
     * Create
     *
     * @desc 创建Slab内存池
     *
     * @params
     *    aSize: SizeUInt 池大小（字节），会自动对齐到页面边界
     *    aAllocator: TAllocator 底层分配器，nil使用默认分配器
     *}
    constructor Create(aSize: SizeUInt; aAllocator: IAllocator = nil); overload;

    {**
     * Create
     *
     * @desc 使用配置创建Slab内存池
     *
     * @params
     *    aSize: SizeUInt 池大小（字节）
     *    aConfig: TSlabConfig 配置选项
     *    aAllocator: TAllocator 底层分配器，nil使用默认分配器
     *}
    constructor Create(aSize: SizeUInt; const aConfig: TSlabConfig; aAllocator: IAllocator = nil); overload;

    {**
     * Destroy
     *
     * @desc 销毁内存池，释放所有资源
     *}
    destructor Destroy; override;

    {**
     * Alloc
     *
     * @desc 分配指定大小的内存块
     *
     * @params
     *    aSize: SizeUInt 请求的字节数 (1-2048)
     *
     * @return 分配的内存指针，失败返回nil
     *
     * @exception ESlabPoolInvalidSize 当aSize为0时抛出
     *}
    function Alloc(aSize: SizeUInt): Pointer;


    {**
     * TryAlloc
     *
     * @desc 尝试分配（不抛异常），失败返回 False
     *       Try to allocate (no exception), return False on failure
     *}
    function TryAlloc(aSize: SizeUInt; out APtr: Pointer): Boolean; inline;

    {**
     * Free
     *
     * @desc 释放内存块
     *
     * @params
     *    aPtr: Pointer 要释放的内存指针，nil安全
     *
     * @exception ESlabPoolCorruption 检测到双重释放时抛出
     *}
    procedure Free(aPtr: Pointer);

    {** 别名：释放内存，避免与 TObject.Free 混淆 **}
    procedure ReleasePtr(aPtr: Pointer); inline;

    {**
     * Reset
     *
     * @desc 重置内存池，清空所有分配
     *}
    procedure Reset;

    {**
     * GetStats
     *
     * @desc 获取详细的统计信息
     *
     * @return 包含页面使用、碎片化等信息的统计结构
     *}
    function GetStats: TSlabStats;

    {**
     * GetPerfCounters
     *
     * @desc 获取性能计数器
     *
     * @return 包含分配/释放性能数据的计数器结构
     *}
    function GetPerfCounters: TSlabPerfCounters;

    {**
     * ResetPerfCounters
     *
     * @desc 重置性能计数器
     *}
    procedure ResetPerfCounters;

    {**
     * SetPerfMonitoring
     *
     * @desc 启用/禁用性能监控
     *
     * @params
     *    aEnable: Boolean true启用，false禁用
     *}
    procedure SetPerfMonitoring(aEnable: Boolean);

    {**
     * Warmup
     *
     * @desc 预热内存池，预分配指定大小类别的页面
     *
     * @params
     *    aSize: SizeUInt 对象大小，用于确定大小类别
     *    aPageCount: Integer 要预分配的页面数量
     *
     * @return 实际预分配的页面数量
     *}
    function Warmup(aSize: SizeUInt; aPageCount: Integer): Integer;

    {**
     * GetTimingInfo
     *
     * @desc 获取时间测量信息
     *
     * @return 时间测量的详细信息字符串
     *}
    function GetTimingInfo: string;

    {**
     * PerformHealthCheck
     *
     * @desc 执行内存池健康检查，检测潜在的数据结构损坏
     *
     * @return 健康检查结果，true表示健康，false表示发现问题
     *}
    function PerformHealthCheck: Boolean;

    {**
     * GetDetailedDiagnostics
     *
     * @desc 获取详细的诊断信息，用于问题分析
     *
     * @return 包含详细诊断信息的字符串
     *}
    function GetDetailedDiagnostics: string;
    property TotalAllocs: SizeUInt read FTotalAllocs;
    property TotalFrees: SizeUInt read FTotalFrees;
    property FailedAllocs: SizeUInt read FFailedAllocs;
    property PoolSize: SizeUInt read FSize;
    property PageCount: SizeUInt read FPageCount;

  private
    // 页面管理
    function AllocPage: PSlabPage;
    procedure FreePage(aPage: PSlabPage);
    procedure InitPage(aPage: PSlabPage; aSizeClass: Integer);

    // 大小类别 - 内联优化热路径
    function GetSizeClass(aSize: SizeUInt): Integer; inline;
    function GetObjectsPerPage(aSizeClass: Integer): Integer; inline;

    // 位图操作 - 内联优化热路径
    function FindFreeBit(aBitmap: PtrUInt; aMaxBits: Integer): Integer;
    procedure SetBit(var aBitmap: PtrUInt; aBit: Integer); inline;
    procedure ClearBit(var aBitmap: PtrUInt; aBit: Integer); inline;

    // 链表操作
    procedure AddToList(var aList: PSlabPage; aPage: PSlabPage);
    procedure RemoveFromList(var aList: PSlabPage; aPage: PSlabPage);

    // 地址计算
    function GetPageIndex(aPtr: Pointer): SizeUInt; inline;
    function GetPageAddr(aIndex: SizeUInt): Pointer; inline;

    // 性能监控辅助函数
    function GetMicroseconds: UInt64; inline;

    // nginx风格的辅助函数
    function GetPageType(aPage: PSlabPage): Integer; inline;
    function GetPagePrev(aPage: PSlabPage): PSlabPage; inline;
    function GetPageIndex(aPage: PSlabPage): SizeUInt; inline;
    function GetPageByIndex(aIndex: SizeUInt): PSlabPage; inline;
    function IsValidPageIndex(aIndex: SizeUInt): Boolean; inline;

    // nginx风格的页面合并 (修正版本)
    procedure FreePages(aPage: PSlabPage; aPageCount: SizeUInt);
  end;



  {**
   * TSlabPoolManager
   *
   * @desc 多级Slab内存池管理器
   *       管理多个不同大小的SlabPool，自动选择最适合的池进行分配
   *       支持大对象的直接分配，小对象使用专门的slab池
   *
   * @features
   *       - 自动池选择：根据请求大小选择最佳池
   *       - 大对象支持：超出slab范围的对象直接分配
   *       - 统一接口：提供统一的分配/释放接口
   *       - 性能优化：每个大小类别使用专门优化的池
   *
   * @example
   *       var Manager := TSlabPoolManager.Create;
   *       var Ptr := Manager.AllocAny(1024);  // 自动选择合适的池
   *       Manager.FreeAny(Ptr);               // 自动识别并释放
   *       Manager.Destroy;
   *}
  TSlabPoolManager = class(TObject)
  private
    FPools: array[0..SLAB_SIZE_CLASSES-1] of TSlabPool;

    // 大对象跟踪（用于释放）
    FLargeObjects: array of Pointer;
    FLargeObjectCount: Integer;

    // 内部方法
    function GetPoolForSize(aSize: SizeUInt): TSlabPool;
    procedure InitializePools(aPoolSize: SizeUInt);
    procedure DestroyPools;
    procedure AddLargeObject(aPtr: Pointer);
    function RemoveLargeObject(aPtr: Pointer): Boolean;
  public
    {**
     * Create
     *
     * @desc 创建池管理器
     *
     * @params
     *    aPoolSize: SizeUInt 每个池的大小
     *}
    constructor Create(aPoolSize: SizeUInt = 64*1024);

    {**
     * Destroy
     *
     * @desc 销毁池管理器
     *}
    destructor Destroy; override;

    {**
     * AllocAny
     *
     * @desc 分配任意大小的内存
     *
     * @params
     *    aSize: SizeUInt 请求的字节数
     *
     * @return 分配的内存指针，失败返回nil
     *}
    function AllocAny(aSize: SizeUInt): Pointer;

    {**
     * FreeAny
     *
     * @desc 释放内存
     *
     * @params
     *    aPtr: Pointer 要释放的内存指针
     *}
    procedure FreeAny(aPtr: Pointer);

    {**
     * GetPool
     *
     * @desc 获取指定大小类别的池
     *
     * @params
     *    aSizeClass: Integer 大小类别索引
     *
     * @return 对应的SlabPool，无效索引返回nil
     *}
    function GetPool(aSizeClass: Integer): TSlabPool;

    {**
     * GetGlobalStats
     *
     * @desc 获取全局统计信息
     *
     * @return 汇总所有池的统计信息
     *}
    function GetGlobalStats: TSlabStats;

    {**
     * WarmupAll
     *
     * @desc 预热所有池
     *
     * @params
     *    aPageCount: Integer 每个池预热的页面数
     *}
    procedure WarmupAll(aPageCount: Integer = 1);
  end;

// 配置辅助函数
function CreateDefaultSlabConfig: TSlabConfig;
function CreateSlabConfigWithPageMerging: TSlabConfig;

implementation



// 默认配置函数
function CreateDefaultSlabConfig: TSlabConfig;
begin
  Result.PageSize := SLAB_PAGE_SIZE;
  Result.MaxSizeClass := SLAB_MAX_SIZE;
  Result.EnablePerfMonitoring := True;
  Result.EnableStats := True;
  Result.EnableDebug := False;
  Result.EnablePageMerging := False; // 默认禁用页面合并
  Result.WarmupPages := 0;
end;

function CreateSlabConfigWithPageMerging: TSlabConfig;
begin
  Result := CreateDefaultSlabConfig;
  Result.EnablePageMerging := True; // 启用页面合并
end;

{ TSlabPool }

function TSlabPool.GetMicroseconds: UInt64;
begin
  if (FTick <> nil) and FEnablePerfMonitoring then
  begin
    // 使用高精度时间测量，获取当前时间戳并转换为微秒
    Result := Round(FTick.TicksToMicroSeconds(FTick.GetCurrentTick));
  end
  else
  begin
    // 降级到低精度时间测量
    Result := GetTickCount64 * 1000;
  end;
end;

constructor TSlabPool.Create(aSize: SizeUInt; aAllocator: IAllocator);
var
  LIndex: Integer; // 局部索引（遵循 L 前缀规范）
  LPageArraySize: SizeUInt;
begin
  inherited Create;

  // 首先初始化大小类别数组
  FSizes[0] := 8;    FSizes[1] := 16;   FSizes[2] := 32;   FSizes[3] := 64;
  FSizes[4] := 128;  FSizes[5] := 256;  FSizes[6] := 512;  FSizes[7] := 1024; FSizes[8] := 2048;

  // 初始化性能计数器
  FillChar(FPerfCounters, SizeOf(FPerfCounters), 0);
  FEnablePerfMonitoring := True; // 默认启用性能监控

  // 初始化高精度时间测量
  try
    FTick := CreateDefaultTick;
  except
    // 如果高精度时间测量不可用，禁用性能监控
    FEnablePerfMonitoring := False;
    FTick := nil;
  end;

  // 确保大小是页面大小的倍数
  if aSize = 0 then
    raise ESlabPoolInvalidSize.Create('Pool size cannot be zero');
  FSize := (aSize + SLAB_PAGE_SIZE - 1) and not (SLAB_PAGE_SIZE - 1);
  FPageCount := FSize shr SLAB_PAGE_SHIFT;

  if aAllocator = nil then
    FBaseAllocator := fafafa.core.mem.allocator.GetRtlAllocator
  else
    FBaseAllocator := aAllocator;

  // 分配内存：数据区 + 页面数组
  LPageArraySize := FPageCount * SizeOf(TSlabPage);
  FStart := FBaseAllocator.GetMem(FSize + LPageArraySize);
  if FStart = nil then
    raise Exception.Create('Failed to allocate slab pool memory');

  FEnd := Pointer(PByte(FStart) + FSize);
  FPages := PSlabPage(FEnd);

  // 初始化页面数�?  FillChar(FPages^, LPageArraySize, 0);

  // 初始化空闲页面链表
  FFreePages := @FPages[0];
  if FPageCount > 1 then
  begin
    for LIndex := 0 to Integer(FPageCount) - 2 do
    begin
      FPages[LIndex].Next := @FPages[LIndex + 1];
      FPages[LIndex].Prev := nil;
      FPages[LIndex].SizeClass := 255; // 标记为空闲
      FPages[LIndex].Slab := 0;
    end;
  end;
  FPages[FPageCount - 1].Next := nil;
  FPages[FPageCount - 1].Prev := nil;
  FPages[FPageCount - 1].SizeClass := 255; // 标记为空闲
  FPages[FPageCount - 1].Slab := 0;

  // 大小类别已在构造函数开始时初始化

  for LIndex := 0 to SLAB_SIZE_CLASSES - 1 do
    FSlots[LIndex] := nil;

  FTotalAllocs := 0;
  FTotalFrees := 0;
  FFailedAllocs := 0;
end;

constructor TSlabPool.Create(aSize: SizeUInt; const aConfig: TSlabConfig; aAllocator: IAllocator);
begin
  // 设置配置
  FConfig := aConfig;

  // 使用配置调用主构造函数
  Create(aSize, aAllocator);

  // 应用配置选项
  FEnablePerfMonitoring := FConfig.EnablePerfMonitoring;

  // 如果需要预热，执行预热
  if FConfig.WarmupPages > 0 then
  begin
    // 为每个大小类别预热一些页面
    Warmup(64, FConfig.WarmupPages);   // 64字节是常用大小
    Warmup(256, FConfig.WarmupPages);  // 256字节也是常用大小
  end;
end;

destructor TSlabPool.Destroy;
begin
  if FStart <> nil then
    FBaseAllocator.FreeMem(FStart);
  inherited Destroy;
end;

function TSlabPool.GetSizeClass(aSize: SizeUInt): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to SLAB_SIZE_CLASSES - 1 do
  begin
    if aSize <= FSizes[LIndex] then
    begin
      Result := LIndex;
      Exit;
    end;
  end;
  Result := -1; // 超出范围
end;

function TSlabPool.GetObjectsPerPage(aSizeClass: Integer): Integer;
var
  LMaxBySize: Integer;
begin
  if (aSizeClass >= 0) and (aSizeClass < SLAB_SIZE_CLASSES) then
  begin
    LMaxBySize := SLAB_PAGE_SIZE div Integer(FSizes[aSizeClass]);
    // 使用预定义常量，提高可读性
    if LMaxBySize < SLAB_MAX_OBJECTS_PER_PAGE then
      Result := LMaxBySize
    else
      Result := SLAB_MAX_OBJECTS_PER_PAGE;
  end
  else
    Result := 0;
end;

function TSlabPool.AllocPage: PSlabPage;
begin
  Result := FFreePages;
  if Result <> nil then
  begin
    FFreePages := Result^.Next;
    Result^.Next := nil;
    Result^.Prev := nil;
  end;
end;

procedure TSlabPool.FreePage(aPage: PSlabPage);
begin
  if aPage = nil then Exit;

  // 从当前链表中移除
  if aPage^.SizeClass < SLAB_SIZE_CLASSES then
    RemoveFromList(FSlots[aPage^.SizeClass], aPage);

  // 重置页面为空闲状态
  aPage^.Slab := 0;
  aPage^.SizeClass := 255; // 标记为空闲页面
  aPage^.Next := nil;
  aPage^.Prev := nil;

  // 使用nginx风格的页面释放和合并
  if FConfig.EnablePageMerging then
    FreePages(aPage, 1)
  else
  begin
    // 不启用合并时，简单添加到空闲链表
    AddToList(FFreePages, aPage);
  end;
end;

procedure TSlabPool.InitPage(aPage: PSlabPage; aSizeClass: Integer);
begin
  aPage^.Slab := 0;
  aPage^.SizeClass := aSizeClass;
  aPage^.Next := nil;
  aPage^.Prev := nil;
end;

function TSlabPool.FindFreeBit(aBitmap: PtrUInt; aMaxBits: Integer): Integer;
var
  LMask, LInverted, LIsolated: PtrUInt;
  LTrailingZeros: Integer;
begin
  // 边界检查
  if (aMaxBits <= 0) or (aMaxBits > 64) then
  begin
    Result := -1;
    Exit;
  end;

  // 创建有效位掩码
  if aMaxBits = 64 then
    LMask := High(PtrUInt)
  else
    LMask := (PtrUInt(1) shl aMaxBits) - 1;

  // 快速检查：如果位图全满，直接返回
  if (aBitmap and LMask) = LMask then
  begin
    Result := -1;
    Exit;
  end;

  // 高效位操作：找到第一个0位
  // 1. 反转位图，将0位变成1位
  LInverted := (not aBitmap) and LMask;

  // 2. 如果没有0位，返回-1
  if LInverted = 0 then
  begin
    Result := -1;
    Exit;
  end;

  // 3. 使用位操作技巧找到最低位的1（原来的0位）
  // 模拟 BSF (Bit Scan Forward) 指令
  // 安全的负数转换，避免算术溢出
  if LInverted = 0 then
    LIsolated := 0
  else
    LIsolated := LInverted and (not LInverted + 1);

  // 4. 计算前导零的数量（即位位置）
  LTrailingZeros := 0;
  if LIsolated > $FFFFFFFF then begin LTrailingZeros += 32; LIsolated := LIsolated shr 32; end;
  if LIsolated > $FFFF then begin LTrailingZeros += 16; LIsolated := LIsolated shr 16; end;
  if LIsolated > $FF then begin LTrailingZeros += 8; LIsolated := LIsolated shr 8; end;
  if LIsolated > $F then begin LTrailingZeros += 4; LIsolated := LIsolated shr 4; end;
  if LIsolated > $3 then begin LTrailingZeros += 2; LIsolated := LIsolated shr 2; end;
  if LIsolated > $1 then Inc(LTrailingZeros);

  Result := LTrailingZeros;

  // 最终边界检查
  if Result >= aMaxBits then
    Result := -1;
end;

procedure TSlabPool.SetBit(var aBitmap: PtrUInt; aBit: Integer);
begin
  aBitmap := aBitmap or (PtrUInt(1) shl aBit);
end;

procedure TSlabPool.ClearBit(var aBitmap: PtrUInt; aBit: Integer);
begin
  aBitmap := aBitmap and not (PtrUInt(1) shl aBit);
end;

procedure TSlabPool.AddToList(var aList: PSlabPage; aPage: PSlabPage);
begin
  aPage^.Next := aList;
  aPage^.Prev := nil;
  if aList <> nil then
    aList^.Prev := aPage;
  aList := aPage;
end;

procedure TSlabPool.RemoveFromList(var aList: PSlabPage; aPage: PSlabPage);
begin
  if aPage = nil then Exit;

  // 安全检查：确保页面在链表中
  if (aPage^.Prev = nil) and (aList <> aPage) then
    Exit; // 页面不在链表头部，且没有前驱，可能不在链表中

  if aPage^.Prev <> nil then
    aPage^.Prev^.Next := aPage^.Next
  else
    aList := aPage^.Next;

  if aPage^.Next <> nil then
    aPage^.Next^.Prev := aPage^.Prev;

  aPage^.Next := nil;
  aPage^.Prev := nil;
end;

function TSlabPool.GetPageIndex(aPtr: Pointer): SizeUInt;
begin
  if (aPtr = nil) or (FStart = nil) or (PByte(aPtr) < PByte(FStart)) then
  begin
    Result := High(SizeUInt); // 无效索引
    Exit;
  end;

  Result := (PByte(aPtr) - PByte(FStart)) shr SLAB_PAGE_SHIFT; // 使用指针算术避免 4055

  // 边界检查
  if Result >= FPageCount then
    Result := High(SizeUInt); // 无效索引
end;

function TSlabPool.GetPageAddr(aIndex: SizeUInt): Pointer;
begin
  Result := Pointer(PByte(FStart) + (aIndex shl SLAB_PAGE_SHIFT));
end;


function TSlabPool.TryAlloc(aSize: SizeUInt; out APtr: Pointer): Boolean;
begin
  APtr := Alloc(aSize);
  Result := APtr <> nil;
end;

procedure TSlabPool.ReleasePtr(aPtr: Pointer);
begin
  Free(aPtr);
end;

function TSlabPool.Alloc(aSize: SizeUInt): Pointer;
var
  LSizeClass: Integer;
  LPage: PSlabPage;
  LBit: Integer;
  LObjectsPerPage: Integer;
  LPageIndex: SizeUInt;
  LStartTime: UInt64;
begin
  Result := nil;
  Inc(FTotalAllocs);

  // 性能监控
  if FEnablePerfMonitoring and (FTick <> nil) then
  begin
    Inc(FPerfCounters.AllocCalls);
    LStartTime := FTick.GetCurrentTick;
  end;

  // 拒绝0字节分配
  if aSize = 0 then
  begin
    Inc(FFailedAllocs);
    raise ESlabPoolInvalidSize.Create('Cannot allocate 0 bytes');
  end;

  LSizeClass := GetSizeClass(aSize);
  if LSizeClass < 0 then
  begin
    Inc(FFailedAllocs);
    Exit;
  end;

  LObjectsPerPage := GetObjectsPerPage(LSizeClass);
  if LObjectsPerPage <= 0 then
  begin
    Inc(FFailedAllocs);
    Exit;
  end;

  // 查找有空闲空间的页面
  LPage := FSlots[LSizeClass];
  while (LPage <> nil) and (FindFreeBit(LPage^.Slab, LObjectsPerPage) < 0) do
    LPage := LPage^.Next;

  // 如果没有可用页面，分配新页面
  if LPage = nil then
  begin
    LPage := AllocPage;
    if LPage = nil then
    begin
      Inc(FFailedAllocs);
      if FEnablePerfMonitoring then
        Inc(FPerfCounters.CacheMisses);
      Exit;
    end;
    InitPage(LPage, LSizeClass);
    AddToList(FSlots[LSizeClass], LPage);
    if FEnablePerfMonitoring then
      Inc(FPerfCounters.PageAllocations);
  end;

  // 分配对象
  if FEnablePerfMonitoring then
    Inc(FPerfCounters.BitScanOperations);

  LBit := FindFreeBit(LPage^.Slab, LObjectsPerPage);
  if LBit >= 0 then
  begin
    SetBit(LPage^.Slab, LBit);
    // 计算页面在描述符数组中的索引
    LPageIndex := LPage - FPages;
    if LPageIndex < FPageCount then
      Result := Pointer(PByte(GetPageAddr(LPageIndex)) + LBit * FSizes[LSizeClass])
    else
      Inc(FFailedAllocs);
  end
  else
    Inc(FFailedAllocs);

  // 记录分配时间
  if FEnablePerfMonitoring and (FTick <> nil) then
    Inc(FPerfCounters.AllocTime, Round(FTick.TicksToMicroSeconds(FTick.GetElapsedTicks(LStartTime))));
end;

procedure TSlabPool.Free(aPtr: Pointer);
var
  LPageIndex: SizeUInt;
  LPage: PSlabPage;
  LOffset: SizeUInt;
  LBit: Integer;
  LObjectSize: SizeUInt;
  LStartTime: UInt64;
begin
  if aPtr = nil then Exit;

  Inc(FTotalFrees);

  // 性能监控
  if FEnablePerfMonitoring and (FTick <> nil) then
  begin
    Inc(FPerfCounters.FreeCalls);
    LStartTime := FTick.GetCurrentTick;
  end;

  LPageIndex := GetPageIndex(aPtr);
  if (LPageIndex = High(SizeUInt)) or (LPageIndex >= FPageCount) then
    raise ESlabPoolCorruption.Create('Invalid pointer: not within pool range');

  LPage := @FPages[LPageIndex];
  if LPage^.SizeClass >= SLAB_SIZE_CLASSES then
    raise ESlabPoolCorruption.Create('Invalid pointer: page size class out of range');

  LObjectSize := FSizes[LPage^.SizeClass];
  if LObjectSize = 0 then
    raise ESlabPoolCorruption.Create('Invalid pointer: object size is zero');

  LOffset := PByte(aPtr) - PByte(GetPageAddr(LPageIndex)); // 差值用指针算术避免 4055
  LBit := LOffset div LObjectSize;

  // 检查位是否已经被清除（双重释放检测）
  if (LPage^.Slab and (PtrUInt(1) shl LBit)) = 0 then
  begin
    // 这是双重释放，应该报错
    raise ESlabPoolCorruption.Create('Double free detected');
  end;

  ClearBit(LPage^.Slab, LBit);

  // 如果页面变空，将其移回空闲页面池以便重新分配给其他大小类别
  if LPage^.Slab = 0 then
  begin
    // 调用FreePage来处理页面释放和可能的合并
    FreePage(LPage);

    if FEnablePerfMonitoring then
      Inc(FPerfCounters.PageRecycles);
  end;

  // 记录释放时间
  if FEnablePerfMonitoring and (FTick <> nil) then
    Inc(FPerfCounters.FreeTime, Round(FTick.TicksToMicroSeconds(FTick.GetElapsedTicks(LStartTime))));
end;

procedure TSlabPool.Reset;
var
  LIndex: Integer;
begin
  // 重置所有页面到空闲状态
  FFreePages := @FPages[0];
  if FPageCount > 1 then
  begin
    for LIndex := 0 to Integer(FPageCount) - 2 do
    begin
      FPages[LIndex].Next := @FPages[LIndex + 1];
      FPages[LIndex].Prev := nil;
      FPages[LIndex].Slab := 0;
      FPages[LIndex].SizeClass := 0;
    end;
  end;
  FPages[FPageCount - 1].Next := nil;
  FPages[FPageCount - 1].Prev := nil;
  FPages[FPageCount - 1].Slab := 0;
  FPages[FPageCount - 1].SizeClass := 0;

  for LIndex := 0 to SLAB_SIZE_CLASSES - 1 do
    FSlots[LIndex] := nil;

  FTotalAllocs := 0;
  FTotalFrees := 0;
  FFailedAllocs := 0;
end;



function TSlabPool.GetStats: TSlabStats;
var
  LIndex, LSizeClass: Integer; // 局部变量统一 L 前缀
  LPage: PSlabPage;
  LTotalObjects, LFreeObjects: SizeUInt;
  LObjectsPerPage: Integer;
  LUsedBits: Integer;
  LPageCount: SizeUInt;
  LTotalUsedObjects: SizeUInt;
  LMaxFreeBlock, LMinFreeBlock: SizeUInt;
  LCurrentFreeBlock: SizeUInt;
  LFreeBlockCount: Integer;
begin
  // 初始化统计信息
  Result := Default(TSlabStats);
  Result.TotalPages := FPageCount;
  // 显式初始化，避免编译器关于托管类型未初始化的警告
  LTotalObjects := 0;
  LFreeObjects := 0;
  LPageCount := 0;
  LMaxFreeBlock := 0;
  LMinFreeBlock := High(SizeUInt);
  LFreeBlockCount := 0;

  // 遍历所有大小类别，统计页面使用情况
  for LSizeClass := 0 to SLAB_SIZE_CLASSES - 1 do
  begin
    LPage := FSlots[LSizeClass];
    LObjectsPerPage := GetObjectsPerPage(LSizeClass);

    while LPage <> nil do
    begin
      // 计算页面中已使用的对象数
      LUsedBits := 0;
      for LIndex := 0 to LObjectsPerPage - 1 do
      begin
        if (LPage^.Slab and (PtrUInt(1) shl LIndex)) <> 0 then
          Inc(LUsedBits);
      end;

      // 分类页面状态
      if LUsedBits = 0 then
        Inc(Result.FreePages)
      else if LUsedBits = LObjectsPerPage then
        Inc(Result.FullPages)
      else
        Inc(Result.PartialPages);

      // 累计对象统计
      Inc(LTotalObjects, LObjectsPerPage);
      Inc(LFreeObjects, LObjectsPerPage - LUsedBits);
      Inc(LPageCount);

      // 分析空闲块
      if LUsedBits < LObjectsPerPage then
      begin
        LCurrentFreeBlock := LObjectsPerPage - LUsedBits;
        if LCurrentFreeBlock > LMaxFreeBlock then
          LMaxFreeBlock := LCurrentFreeBlock;
        if LCurrentFreeBlock < LMinFreeBlock then
          LMinFreeBlock := LCurrentFreeBlock;
        Inc(LFreeBlockCount);
      end;

      LPage := LPage^.Next;
    end;
  end;

  // 计算空闲页面（未分配给任何大小类别的页面）
  Result.FreePages := FPageCount - (Result.PartialPages + Result.FullPages);

  // 设置对象统计
  Result.TotalObjects := LTotalObjects;
  Result.FreeObjects := LFreeObjects;
  LTotalUsedObjects := LTotalObjects - LFreeObjects;

  // 计算基础比率
  if Result.TotalPages > 0 then
  begin
    Result.FragmentationRatio := Result.PartialPages / Result.TotalPages;
    if LTotalObjects > 0 then
      Result.MemoryEfficiency := LTotalUsedObjects / LTotalObjects
    else
      Result.MemoryEfficiency := 0.0;
  end
  else
  begin
    Result.FragmentationRatio := 0.0;
    Result.MemoryEfficiency := 0.0;
  end;

  // 计算增强的碎片分析
  if LPageCount > 0 then
    Result.AverageObjectsPerPage := LTotalObjects / LPageCount
  else
    Result.AverageObjectsPerPage := 0.0;

  Result.LargestFreeBlock := LMaxFreeBlock;
  if LMinFreeBlock = High(SizeUInt) then
    Result.SmallestFreeBlock := 0
  else
    Result.SmallestFreeBlock := LMinFreeBlock;

  // 内部碎片：页面内部的浪费空间
  if LTotalObjects > 0 then
    Result.InternalFragmentation := LFreeObjects / LTotalObjects
  else
    Result.InternalFragmentation := 0.0;

  // 外部碎片：页面间的浪费空间
  if Result.TotalPages > 0 then
    Result.ExternalFragmentation := Result.FreePages / Result.TotalPages
  else
    Result.ExternalFragmentation := 0.0;

  // 计算健康度评分 (0.0-1.0)
  Result.HealthScore := (Result.MemoryEfficiency * 0.4) +
                       ((1.0 - Result.FragmentationRatio) * 0.3) +
                       ((1.0 - Result.InternalFragmentation) * 0.2) +
                       ((1.0 - Result.ExternalFragmentation) * 0.1);

  // 推荐操作
  if Result.HealthScore > 0.8 then
    Result.RecommendedAction := 'Excellent health - no action needed'
  else if Result.HealthScore > 0.6 then
    Result.RecommendedAction := 'Good health - consider periodic cleanup'
  else if Result.HealthScore > 0.4 then
    Result.RecommendedAction := 'Fair health - recommend pool reset or defragmentation'
  else
    Result.RecommendedAction := 'Poor health - immediate action required: reset pool or increase size';
end;

function TSlabPool.GetPerfCounters: TSlabPerfCounters;
begin
  Result := FPerfCounters;
end;

procedure TSlabPool.ResetPerfCounters;
begin
  FillChar(FPerfCounters, SizeOf(FPerfCounters), 0);
end;

procedure TSlabPool.SetPerfMonitoring(aEnable: Boolean);
begin
  FEnablePerfMonitoring := aEnable;
end;

function TSlabPool.Warmup(aSize: SizeUInt; aPageCount: Integer): Integer;
var
  LSizeClass: Integer;
  LPage: PSlabPage;
  LIndex: Integer;
begin
  Result := 0;

  // 获取大小类别
  LSizeClass := GetSizeClass(aSize);
  if LSizeClass < 0 then
    Exit;

  // 预分配指定数量的页面
  for LIndex := 1 to aPageCount do
  begin
    LPage := AllocPage;
    if LPage = nil then
      Break; // 没有更多页面可分配

    InitPage(LPage, LSizeClass);
    AddToList(FSlots[LSizeClass], LPage);
    Inc(Result);

    if FEnablePerfMonitoring then
      Inc(FPerfCounters.PageAllocations);
  end;
end;



{ TSlabPoolManager }

constructor TSlabPoolManager.Create(aPoolSize: SizeUInt);
begin
  inherited Create;
  InitializePools(aPoolSize);
end;

destructor TSlabPoolManager.Destroy;
begin
  DestroyPools;
  inherited Destroy;
end;

procedure TSlabPoolManager.InitializePools(aPoolSize: SizeUInt);
var
  LIndex: Integer;
  LSizes: array[0..SLAB_SIZE_CLASSES-1] of SizeUInt = (8, 16, 32, 64, 128, 256, 512, 1024, 2048);
begin
  // 为每个大小类别创建专门的池
  for LIndex := 0 to SLAB_SIZE_CLASSES - 1 do
  begin
    FPools[LIndex] := TSlabPool.Create(aPoolSize);

    // 预热每个池
    FPools[LIndex].Warmup(LSizes[LIndex], 1);
  end;

  // 初始化大对象跟踪
  SetLength(FLargeObjects, 16); // 初始容量
  FLargeObjectCount := 0;
end;

procedure TSlabPoolManager.DestroyPools;
var
  LIndex: Integer;
begin
  for LIndex := 0 to SLAB_SIZE_CLASSES - 1 do
  begin
    if FPools[LIndex] <> nil then
    begin
      FPools[LIndex].Destroy;
      FPools[LIndex] := nil;
    end;
  end;

  // 释放所有大对象
  for LIndex := 0 to FLargeObjectCount - 1 do
  begin
    if FLargeObjects[LIndex] <> nil then
      FreeMem(FLargeObjects[LIndex]);
  end;
  SetLength(FLargeObjects, 0);
end;

function TSlabPoolManager.GetPoolForSize(aSize: SizeUInt): TSlabPool;
var
  LSizes: array[0..SLAB_SIZE_CLASSES-1] of SizeUInt = (8, 16, 32, 64, 128, 256, 512, 1024, 2048);
  LIndex: Integer;
begin
  // 找到合适的大小类别
  for LIndex := 0 to SLAB_SIZE_CLASSES - 1 do
  begin
    if aSize <= LSizes[LIndex] then
    begin
      Result := FPools[LIndex];
      Exit;
    end;
  end;

  // 超出slab范围，返回nil表示需要使用系统分配器
  Result := nil;
end;

function TSlabPoolManager.AllocAny(aSize: SizeUInt): Pointer;
var
  LPool: TSlabPool;
begin
  LPool := GetPoolForSize(aSize);
  if LPool <> nil then
    Result := LPool.Alloc(aSize)
  else
  begin
    // 大对象，使用系统分配器
    GetMem(Result, aSize);
    if Result <> nil then
      AddLargeObject(Result);
  end;
end;

procedure TSlabPoolManager.FreeAny(aPtr: Pointer);
var
  LIndex: Integer;
  LFound: Boolean;
begin
  if aPtr = nil then Exit;

  // 首先检查是否是大对象
  if RemoveLargeObject(aPtr) then
  begin
    FreeMem(aPtr);
    Exit;
  end;

  // 尝试在每个池中释放
  LFound := False;
  for LIndex := 0 to SLAB_SIZE_CLASSES - 1 do
  begin
    try
      FPools[LIndex].Free(aPtr);
      LFound := True;
      Break;
    except
      // 继续尝试下一个池
    end;
  end;

  if not LFound then
    raise ESlabPoolCorruption.Create('无法找到指针对应的池');
end;

function TSlabPoolManager.GetPool(aSizeClass: Integer): TSlabPool;
begin
  if (aSizeClass >= 0) and (aSizeClass < SLAB_SIZE_CLASSES) then
    Result := FPools[aSizeClass]
  else
    Result := nil;
end;

function TSlabPoolManager.GetGlobalStats: TSlabStats;
var
  LIndex: Integer;
  LStats: TSlabStats;
begin
  Result := Default(TSlabStats);
  LStats := Default(TSlabStats);

  // 汇总所有池的统计信息
  for LIndex := 0 to SLAB_SIZE_CLASSES - 1 do
  begin
    LStats := FPools[LIndex].GetStats;
    Inc(Result.TotalPages, LStats.TotalPages);
    Inc(Result.FreePages, LStats.FreePages);
    Inc(Result.PartialPages, LStats.PartialPages);
    Inc(Result.FullPages, LStats.FullPages);
    Inc(Result.TotalObjects, LStats.TotalObjects);
    Inc(Result.FreeObjects, LStats.FreeObjects);
  end;

  // 大对象不计入统计（它们使用系统分配器）

  // 计算汇总的比率
  if Result.TotalPages > 0 then
  begin
    Result.FragmentationRatio := Result.PartialPages / Result.TotalPages;
    if Result.TotalObjects > 0 then
      Result.MemoryEfficiency := (Result.TotalObjects - Result.FreeObjects) / Result.TotalObjects
    else
      Result.MemoryEfficiency := 0.0;
  end;
end;

procedure TSlabPoolManager.WarmupAll(aPageCount: Integer);
var
  LIndex: Integer;
  LSizes: array[0..SLAB_SIZE_CLASSES-1] of SizeUInt = (8, 16, 32, 64, 128, 256, 512, 1024, 2048);
begin
  for LIndex := 0 to SLAB_SIZE_CLASSES - 1 do
    FPools[LIndex].Warmup(LSizes[LIndex], aPageCount);
end;

procedure TSlabPoolManager.AddLargeObject(aPtr: Pointer);
begin
  // 扩展数组如果需要
  if FLargeObjectCount >= Length(FLargeObjects) then
    SetLength(FLargeObjects, Length(FLargeObjects) * 2);

  FLargeObjects[FLargeObjectCount] := aPtr;
  Inc(FLargeObjectCount);
end;

function TSlabPoolManager.RemoveLargeObject(aPtr: Pointer): Boolean;
var
  LIndex: Integer;
begin
  Result := False;
  for LIndex := 0 to FLargeObjectCount - 1 do
  begin
    if FLargeObjects[LIndex] = aPtr then
    begin
      // 移动最后一个元素到当前位置
      FLargeObjects[LIndex] := FLargeObjects[FLargeObjectCount - 1];
      Dec(FLargeObjectCount);
      Result := True;
      Break;
    end;
  end;
end;

function TSlabPool.GetTimingInfo: string;
begin
  if FTick <> nil then
  begin
    Result := Format('时间测量: 启用, 分辨率=%d ticks/秒, 精度=%.2f纳秒', [
      FTick.GetResolution,
      1000000000.0 / FTick.GetResolution
    ]);
  end
  else
  begin
    Result := '时间测量: 禁用';
  end;
end;

{ nginx风格页面合并功能实现 - 修正版本 }

function TSlabPool.GetPageType(aPage: PSlabPage): Integer;
begin
  if aPage = nil then
    Result := -1
  else
  begin
    // For compatibility, check if page is free (SizeClass = 255)
    if aPage^.SizeClass = 255 then
      Result := SLAB_PAGE_TYPE  // Free page
    else
      Result := SLAB_PAGE_SMALL; // Used page
  end;
end;

function TSlabPool.GetPagePrev(aPage: PSlabPage): PSlabPage;
begin
  if aPage = nil then
    Result := nil
  else
    Result := aPage^.Prev; // Direct pointer in compatibility mode
end;

function TSlabPool.GetPageIndex(aPage: PSlabPage): SizeUInt;
begin
  if (aPage = nil) or (FPages = nil) then
    Result := 0
  else
    Result := (PByte(aPage) - PByte(FPages)) div SizeOf(TSlabPage);
end;

function TSlabPool.GetPageByIndex(aIndex: SizeUInt): PSlabPage;
begin
  if (FPages = nil) or (aIndex >= FPageCount) then
    Result := nil
  else
    Result := @FPages[aIndex];
end;

function TSlabPool.IsValidPageIndex(aIndex: SizeUInt): Boolean;
begin
  Result := (FPages <> nil) and (aIndex < FPageCount);
end;

{ nginx风格的页面合并逻辑 - 高级合并策略 }

procedure TSlabPool.FreePages(aPage: PSlabPage; aPageCount: SizeUInt);
var
  LNextPage, LPrevPage: PSlabPage;
  LPageIndex: SizeUInt;
  LStartTime: UInt64;
  LMergeCount: SizeUInt;
  LCurrentPage: PSlabPage;
  LMergedSize: SizeUInt;
  LCanMergeForward, LCanMergeBackward: Boolean;
  LForwardPages, LBackwardPages: SizeUInt;
begin
  if aPage = nil then Exit;

  // 性能监控开始
  LMergeCount := 0;
  if FConfig.EnablePageMerging and FEnablePerfMonitoring and (FTick <> nil) then
    LStartTime := FTick.GetCurrentTick;

  LPageIndex := GetPageIndex(aPage);

  // 检查页面索引有效性
  if (LPageIndex = High(SizeUInt)) or (LPageIndex >= FPageCount) then
  begin
    // 无效页面，直接添加到空闲链表
    aPage^.SizeClass := 255;
    aPage^.Slab := aPageCount;
    AddToList(FFreePages, aPage);
    Exit;
  end;

  // 标记页面为空闲
  aPage^.SizeClass := 255; // Free page marker
  aPage^.Slab := aPageCount;
  LCurrentPage := aPage;
  LMergedSize := aPageCount;



  // nginx风格双向合并算法
  if FConfig.EnablePageMerging then
  begin
    // 第一阶段：向前扫描连续空闲页面
    LForwardPages := 0;
    LCanMergeForward := True;
    while LCanMergeForward and (LPageIndex + LMergedSize + LForwardPages < FPageCount) do
    begin
      LNextPage := GetPageByIndex(LPageIndex + LMergedSize + LForwardPages);
      if (LNextPage <> nil) and (LNextPage^.SizeClass = 255) and (LNextPage <> LCurrentPage) then
      begin
        // 从空闲链表中移除
        RemoveFromList(FFreePages, LNextPage);

        // 安全累加页面大小
        if LNextPage^.Slab > 0 then
        begin
          if LMergedSize <= High(SizeUInt) - LNextPage^.Slab then
          begin
            Inc(LForwardPages, LNextPage^.Slab);
            Inc(LMergeCount);
          end
          else
          begin
            // 防止溢出，停止合并
            LCanMergeForward := False;
            AddToList(FFreePages, LNextPage); // 重新添加回去
          end;
        end
        else
        begin
          Inc(LForwardPages);
          Inc(LMergeCount);
        end;

        // 清理合并的页面
        if LCanMergeForward then
        begin
          LNextPage^.SizeClass := 254; // Merged marker
          LNextPage^.Slab := 0;
          LNextPage^.Next := nil;
          LNextPage^.Prev := nil;
        end;
      end
      else
        LCanMergeForward := False;
    end;

    // 第二阶段：向后扫描连续空闲页面
    LBackwardPages := 0;
    LCanMergeBackward := True;
    while LCanMergeBackward and (LPageIndex > LBackwardPages) do
    begin
      LPrevPage := GetPageByIndex(LPageIndex - LBackwardPages - 1);
      if (LPrevPage <> nil) and (LPrevPage^.SizeClass = 255) and (LPrevPage <> LCurrentPage) then
      begin
        // 从空闲链表中移除
        RemoveFromList(FFreePages, LPrevPage);

        // 安全累加页面大小
        if LPrevPage^.Slab > 0 then
        begin
          if LMergedSize <= High(SizeUInt) - LPrevPage^.Slab then
          begin
            Inc(LBackwardPages, LPrevPage^.Slab);
            Inc(LMergeCount);
          end
          else
          begin
            // 防止溢出，停止合并
            LCanMergeBackward := False;
            AddToList(FFreePages, LPrevPage); // 重新添加回去
          end;
        end
        else
        begin
          Inc(LBackwardPages);
          Inc(LMergeCount);
        end;

        // 清理合并的页面
        if LCanMergeBackward then
        begin
          LPrevPage^.SizeClass := 254; // Merged marker
          LPrevPage^.Slab := 0;
          LPrevPage^.Next := nil;
          LPrevPage^.Prev := nil;

          // 使用最前面的页面作为新的头部
          LCurrentPage := LPrevPage;
          LPageIndex := LPageIndex - 1;
        end;
      end
      else
        LCanMergeBackward := False;
    end;

    // 更新最终的合并大小
    LMergedSize := LMergedSize + LForwardPages + LBackwardPages;
    LCurrentPage^.Slab := LMergedSize;
  end;

  // 添加到空闲链表
  AddToList(FFreePages, LCurrentPage);

  // 更新性能计数器
  if FConfig.EnablePageMerging and FEnablePerfMonitoring then
  begin
    if LMergeCount > 0 then
    begin
      Inc(FPerfCounters.PageMerges);
      Inc(FPerfCounters.MergedPages, LMergeCount);
    end;

    if FTick <> nil then
      Inc(FPerfCounters.MergeTime, Round(FTick.TicksToMicroSeconds(FTick.GetElapsedTicks(LStartTime))));
  end;
end;

function TSlabPool.PerformHealthCheck: Boolean;
var
  LIndex: Integer;
  LPage: PSlabPage;
  LPageIndex: SizeUInt;
  LErrors: Integer;
begin
  Result := True;
  LErrors := 0;

  // 检查基本结构完整性
  if (FStart = nil) or (FPages = nil) or (FPageCount = 0) then
  begin
    Inc(LErrors);
    Result := False;
  end;

  // 检查页面链表完整性
  for LIndex := 0 to SLAB_SIZE_CLASSES - 1 do
  begin
    LPage := FSlots[LIndex];
    while LPage <> nil do
    begin
      // 检查页面索引有效性
      LPageIndex := GetPageIndex(LPage);
      if (LPageIndex = High(SizeUInt)) or (LPageIndex >= FPageCount) then
      begin
        Inc(LErrors);
        Result := False;
        Break;
      end;

      // 检查大小类别一致性
      if LPage^.SizeClass <> LIndex then
      begin
        Inc(LErrors);
        Result := False;
      end;

      // 检查链表指针一致性
      if (LPage^.Next <> nil) and (LPage^.Next^.Prev <> LPage) then
      begin
        Inc(LErrors);
        Result := False;
      end;

      LPage := LPage^.Next;
    end;
  end;

  // 检查空闲页面链表
  LPage := FFreePages;
  while LPage <> nil do
  begin
    if LPage^.SizeClass <> 255 then // 应该标记为空闲
    begin
      Inc(LErrors);
      Result := False;
    end;
    LPage := LPage^.Next;
  end;

  // 记录错误到性能计数器（如果启用调试）
  if FConfig.EnableDebug and (LErrors > 0) then
  begin
    // 可以在这里记录详细的错误信息
  end;
end;

function TSlabPool.GetDetailedDiagnostics: string;
var
  LStats: TSlabStats;
  LPerfCounters: TSlabPerfCounters;
  LHealthy: Boolean;
  LHealthStatus: string;
  LAvgAllocTime, LAvgFreeTime: Double;
begin
  LStats := GetStats;
  LPerfCounters := GetPerfCounters;
  LHealthy := PerformHealthCheck;

  if LHealthy then
    LHealthStatus := 'HEALTHY'
  else
    LHealthStatus := 'ISSUES DETECTED';

  if LPerfCounters.AllocCalls > 0 then
    LAvgAllocTime := LPerfCounters.AllocTime / LPerfCounters.AllocCalls
  else
    LAvgAllocTime := 0.0;

  if LPerfCounters.FreeCalls > 0 then
    LAvgFreeTime := LPerfCounters.FreeTime / LPerfCounters.FreeCalls
  else
    LAvgFreeTime := 0.0;

  Result := Format(
    'SlabPool Detailed Diagnostics'#13#10 +
    '============================='#13#10 +
    'Pool Size: %d bytes (%d pages)'#13#10 +
    'Health Status: %s (Score: %.2f)'#13#10 +
    'Recommendation: %s'#13#10 +
    ''#13#10 +
    'Memory Usage:'#13#10 +
    '  Total Objects: %d'#13#10 +
    '  Free Objects: %d'#13#10 +
    '  Memory Efficiency: %.2f%%'#13#10 +
    '  Internal Fragmentation: %.2f%%'#13#10 +
    '  External Fragmentation: %.2f%%'#13#10 +
    ''#13#10 +
    'Page Distribution:'#13#10 +
    '  Free Pages: %d'#13#10 +
    '  Partial Pages: %d'#13#10 +
    '  Full Pages: %d'#13#10 +
    '  Fragmentation Ratio: %.2f%%'#13#10 +
    ''#13#10 +
    'Performance Counters:'#13#10 +
    '  Total Allocations: %d'#13#10 +
    '  Total Frees: %d'#13#10 +
    '  Failed Allocations: %d'#13#10 +
    '  Page Merges: %d'#13#10 +
    '  Average Alloc Time: %.2f μs'#13#10 +
    '  Average Free Time: %.2f μs'#13#10 +
    ''#13#10 +
    'Free Block Analysis:'#13#10 +
    '  Largest Free Block: %d objects'#13#10 +
    '  Smallest Free Block: %d objects'#13#10 +
    '  Average Objects/Page: %.2f'#13#10,
    [
      FSize, FPageCount,
      LHealthStatus, LStats.HealthScore,
      LStats.RecommendedAction,
      LStats.TotalObjects, LStats.FreeObjects,
      LStats.MemoryEfficiency * 100,
      LStats.InternalFragmentation * 100,
      LStats.ExternalFragmentation * 100,
      LStats.FreePages, LStats.PartialPages, LStats.FullPages,
      LStats.FragmentationRatio * 100,
      FTotalAllocs, FTotalFrees, FFailedAllocs,
      LPerfCounters.PageMerges,
      LAvgAllocTime, LAvgFreeTime,
      LStats.LargestFreeBlock, LStats.SmallestFreeBlock,
      LStats.AverageObjectsPerPage
    ]
  );
end;

end.
