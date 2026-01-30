# ⚠️ DEPRECATED（已归档）

此路线图包含较多历史设想与旧命名，可能与当前实现不一致，仅作参考。

- LockFree 模块文档：`docs/fafafa.core.lockfree.md`
- Atomic 模块文档：`docs/fafafa.core.atomic.md`

---

# fafafa.core.lockfree 实施路线图

## 🎯 **总体策略：渐进式现代化**

### **核心理念**
- **保持向后兼容**：现有代码继续工作
- **分阶段升级**：逐步引入 Boost 启发的改进
- **性能优先**：每个改进都要有明确的性能提升
- **安全第一**：彻底解决内存安全问题

## 📅 **详细实施计划**

### **Phase 1: 基础设施建设 (Week 1-3)**

#### **Week 1: 原子操作增强**
```pascal
// 目标：实现 Boost 风格的原子操作接口
unit fafafa.core.atomic;

type
  TMemoryOrder = (moRelaxed, moAcquire, moRelease, moAcqRel, moSeqCst);
  
  TTaggedPtr = record
    Ptr: Pointer;
    Tag: QWord;
  end;

// 128位原子操作（关键改进）
function AtomicLoad128(AAddr: Pointer): TTaggedPtr;
function AtomicStore128(AAddr: Pointer; AValue: TTaggedPtr);
function AtomicCompareExchange128(AAddr: Pointer; ANew, AExpected: TTaggedPtr): Boolean;

// 精确内存序控制
function AtomicLoad64(AAddr: Pointer; AOrder: TMemoryOrder = moSeqCst): QWord;
procedure AtomicStore64(AAddr: Pointer; AValue: QWord; AOrder: TMemoryOrder = moSeqCst);
```

#### **Week 2: Freelist 内存管理**
```pascal
// 目标：实现统一的无锁内存池
generic TLockFreeFreelist<T> = class
private
  FHead: TTaggedPtr;
  FAllocatedCount: Integer;
  FDeallocatedCount: Integer;
  
public
  constructor Create(AInitialSize: Integer = 0);
  destructor Destroy; override;
  
  // 核心接口
  function Allocate: Pointer;
  procedure Deallocate(APtr: Pointer);
  
  // 批量操作
  procedure Reserve(ACount: Integer);
  procedure Shrink;
  
  // 统计信息
  function GetAllocatedCount: Integer;
  function GetDeallocatedCount: Integer;
  function GetMemoryUsage: Integer;
end;
```

#### **Week 3: 配置系统框架**
```pascal
// 目标：实现编译时配置能力
type
  TLockFreeConfig = record
    UseFreelist: Boolean;
    EnableStatistics: Boolean;
    EnableDebugChecks: Boolean;
    DefaultCapacity: Integer;
  end;

const
  DefaultConfig: TLockFreeConfig = (
    UseFreelist: True;
    EnableStatistics: {$IFDEF DEBUG}True{$ELSE}False{$ENDIF};
    EnableDebugChecks: {$IFDEF DEBUG}True{$ELSE}False{$ENDIF};
    DefaultCapacity: 1024;
  );
```

### **Phase 2: 核心数据结构重构 (Week 4-7)**

#### **Week 4: TTreiberStack V2**
```pascal
// 目标：彻底解决 ABA 问题
generic TTreiberStackV2<T> = class
private
  FTop: TTaggedPtr;
  FFreelist: specialize TLockFreeFreelist<TNode>;
  FConfig: TLockFreeConfig;
  
public
  constructor Create(AConfig: TLockFreeConfig = DefaultConfig);
  
  // ABA 安全的操作
  function Push(const AItem: T): Boolean;
  function Pop(out AItem: T): Boolean;
  
  // 批量操作（Boost 启发）
  function PushRange(const AItems: array of T): Integer;
  function PopRange(out AItems: array of T): Integer;
  
  // 高级功能
  procedure Reserve(ACount: Integer);
  function GetMemoryUsage: Integer;
end;
```

#### **Week 5: TSPSCQueue V2**
```pascal
// 目标：精确内存序优化
generic TSPSCQueueV2<T> = class
private
  FBuffer: array of T;
  FCapacity: Integer;
  FMask: Integer;
  
  // 使用精确内存序的位置指针
  FWritePos: QWord;  // 只有生产者写入，使用 relaxed
  FReadPos: QWord;   // 只有消费者写入，使用 relaxed
  
public
  // Boost 风格的接口
  function Push(const AItem: T): Boolean;
  function Pop(out AItem: T): Boolean;
  
  // 批量操作
  function PushRange(const AItems: array of T): Integer;
  function PopRange(out AItems: array of T): Integer;
  
  // 非阻塞状态查询
  function IsEmpty: Boolean;
  function IsFull: Boolean;
  function GetSize: Integer;
end;
```

#### **Week 6-7: TAdvancedLockFreeHashMap V2**
```pascal
// 目标：使用 freelist 和改进的冲突解决
generic TAdvancedLockFreeHashMapV2<K, V> = class
private
  type
    PEntry = ^TEntry;
    TEntry = record
      Key: K;
      Value: V;
      Hash: Cardinal;
      Next: TTaggedPtr;  // 链式解决冲突
    end;
    
  var
    FBuckets: array of TTaggedPtr;
    FFreelist: specialize TLockFreeFreelist<TEntry>;
    FSize: Integer;
    FCapacity: Integer;
    
public
  // Boost 风格的接口
  function Insert(const AKey: K; const AValue: V): Boolean;
  function Find(const AKey: K; out AValue: V): Boolean;
  function Erase(const AKey: K): Boolean;
  
  // 批量操作
  function InsertRange(const AItems: array of TPair<K,V>): Integer;
  
  // 迭代器支持
  function GetEnumerator: TEnumerator;
  
  // 内存管理
  procedure Reserve(ACapacity: Integer);
  procedure Rehash;
  function GetLoadFactor: Single;
end;
```

### **Phase 3: 高级特性 (Week 8-10)**

#### **Week 8: 性能监控系统**
```pascal
// 目标：Boost 风格的性能分析
type
  TLockFreeMetrics = record
    OperationCount: QWord;
    ContentionCount: QWord;
    MemoryAllocations: QWord;
    MemoryDeallocations: QWord;
    AverageLatency: Double;
    MaxLatency: QWord;
  end;

generic TPerformanceMonitor<T> = class
private
  FMetrics: TLockFreeMetrics;
  FStartTime: QWord;
  
public
  procedure BeginOperation;
  procedure EndOperation;
  procedure RecordContention;
  
  function GetMetrics: TLockFreeMetrics;
  procedure ResetMetrics;
  
  // 实时性能报告
  procedure PrintReport;
  procedure SaveReport(const AFileName: string);
end;
```

#### **Week 9: 调试和诊断工具**
```pascal
// 目标：内存安全检查和调试支持
{$IFDEF DEBUG}
type
  TLockFreeDebugger = class
  private
    FAllocatedPointers: THashSet;
    FOperationHistory: TList;
    
  public
    procedure TrackAllocation(APtr: Pointer);
    procedure TrackDeallocation(APtr: Pointer);
    procedure CheckMemoryLeaks;
    
    // ABA 检测
    procedure DetectABAPattern;
    
    // 死锁检测
    procedure DetectLivelock;
  end;
{$ENDIF}
```

#### **Week 10: 文档和示例**
- 完整的 API 文档
- 性能基准测试
- 最佳实践指南
- 迁移指南

### **Phase 4: 性能验证 (Week 11-12)**

#### **Week 11: 基准测试**
```pascal
// 目标：与 Boost.Lockfree 性能对比
program BenchmarkComparison;

procedure BenchmarkStack;
var
  LBoostStyle: specialize TTreiberStackV2<Integer>;
  LOriginal: specialize TTreiberStack<Integer>;
  LStartTime: QWord;
  I: Integer;
begin
  // 测试 1M 次 push/pop 操作
  WriteLn('=== Stack Performance Comparison ===');
  
  // 原始实现
  LOriginal := specialize TTreiberStack<Integer>.Create;
  LStartTime := GetTickCount64;
  for I := 1 to 1000000 do
  begin
    LOriginal.Push(I);
    LOriginal.Pop(I);
  end;
  WriteLn('Original: ', GetTickCount64 - LStartTime, ' ms');
  
  // Boost 启发的实现
  LBoostStyle := specialize TTreiberStackV2<Integer>.Create;
  LStartTime := GetTickCount64;
  for I := 1 to 1000000 do
  begin
    LBoostStyle.Push(I);
    LBoostStyle.Pop(I);
  end;
  WriteLn('Boost-inspired: ', GetTickCount64 - LStartTime, ' ms');
end;
```

#### **Week 12: 优化和调优**
- 基于基准测试结果的性能优化
- 内存使用优化
- 编译器特定优化

## 🎯 **成功指标**

### **性能目标**
- **TTreiberStack**: 提升 30% 吞吐量，100% ABA 安全
- **TSPSCQueue**: 提升 20% 吞吐量，减少 50% 延迟抖动
- **THashMap**: 提升 40% 吞吐量，减少 60% 内存碎片

### **质量目标**
- **内存安全**: 零内存泄漏，零野指针访问
- **线程安全**: 通过所有并发测试
- **API 兼容**: 95% 向后兼容

### **可维护性目标**
- **代码覆盖率**: 90% 以上
- **文档完整性**: 100% API 文档化
- **示例丰富性**: 每个数据结构至少 3 个使用示例

## 🚀 **立即行动计划**

### **本周任务**
1. **创建新的 atomic 单元**
2. **实现 TTaggedPtr 和基础 128位操作**
3. **开始 TLockFreeFreelist 的设计**

### **下周任务**
1. **完成 freelist 实现**
2. **开始 TTreiberStackV2 的开发**
3. **设计性能测试框架**

这个路线图确保我们能够：
- **安全地**引入 Boost 的先进理念
- **渐进地**提升性能和安全性
- **系统地**解决现有问题
- **可持续地**维护和扩展代码库
