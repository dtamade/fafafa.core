# fafafa.core.lockfree 接口抽象与 HY 策略草案

本草案确立 IQueue/IStack/IMap 的接口外观、内存模型与能力标注，采用 HY（Hybrid）双轨：
- TE：类型擦除接口 + 泛型包装（已在 contracts_runner 中实现并用于契约）
- GI：泛型接口（FPC 3.3.1+），作为未来方向与高级用户选项

不改变现有门面与具体类型；通过适配层/工厂实现面向接口编程。

---

## 1. 设计目标与原则
- 稳定、小而稳的接口集，Try/Boolean 为主，不抛异常（参数错误除外）
- 面向差异能力（Bounded/ConcurrencyModel/Capabilities），不强求统一实现行为
- 内存序与可见性语义明确：写入对读取保证 release→acquire 可见；读路径可 relaxed，但最终由 CAS/Acquire 收敛
- 先契约后实现：tests/contracts 下推进契约与适配，避免直接触及 src

## 2. 能力标注与差异建模
- ConcurrencyModel = (cmSPSC|cmMPSC|cmMPMC)
- Bounded: Boolean（固定容量容器）
- Capabilities: set （例：SupportsPeek、SupportsClear、SupportsStats、SupportsLoadFactor、SupportsResize、SupportsBatch）

## 3. GI（泛型接口）签名（FPC 3.3.1+）
以下为目标签名（示意，非立即落地到 src）。

```pascal
// FPC 3.3.1+ 才支持 generic interfaces
// {$IF FPC_FULLVERSION >= 030301}

generic IQueue<T> = interface
  function Enqueue(constref Item: T): Boolean;
  function TryDequeue(out Item: T): Boolean;
  function TryPeek(out Item: T): Boolean;
  function IsEmpty: Boolean;
  function Size: SizeInt;             // 最佳努力
  function Capacity: SizeInt;         // 不支持时返回 -1
  function Bounded: Boolean;
end;

generic IStack<T> = interface
  function Push(constref Item: T): Boolean;
  function TryPop(out Item: T): Boolean;
  function TryPeek(out Item: T): Boolean;
  function IsEmpty: Boolean;
  function Size: SizeInt;             // 最佳努力
  function Capacity: SizeInt;         // 不支持时返回 -1
  function Bounded: Boolean;
end;

generic IMap<K,V> = interface
  function Put(constref K: K; constref V: V; out Replaced: Boolean): Boolean;
  function TryGetValue(constref K: K; out V: V): Boolean;
  function Remove(constref K: K; out OldValue: V): Boolean;
  function ContainsKey(constref K: K): Boolean;
  procedure Clear;
  function Size: SizeInt;
end;

// {$IFEND}
```

说明：
- Return True 表示操作成功；Replaced 表示 Put 覆盖旧值（如实现不可区分可置 False）
- Capacity 不支持时返回 -1；Size 为最佳努力
- Map 的 Remove(out OldValue) 若实现无法提供旧值，可返回 False 或采用双查策略在适配层填充

## 4. TE（类型擦除）映射（已在 tests 中实现最小集）
- IQueueInt/IStackInt/IMapIntStr（整数/整数→字符串）作为最小可运行契约
- 具体桥接：
  - Queue：TSPSCQueue<T>（SPSC，Bounded）/TMichaelScottQueue<T>（MPSC）/TPreAllocMPMCQueue<T>（MPMC，Bounded）
  - Stack：TTreiberStack<T>（Unbounded）/TPreAllocStack<T>（Bounded）
  - Map：TLockFreeHashMap<K,V>（OA）/TMichaelHashMap<K,V>（MM）

## 5. 内存模型（简述）
- Queue/Stack：
  - 写侧：写入数据 → 发布（release）指示（如序列号/next/counter）
  - 读侧：获取（acquire）后读取数据，保证写入可见
- Map：
  - 插入后，键值对对读侧 acquire 可见；删除采用逻辑删除，回收策略后续可选 HP/EBR 原型

## 6. 条件编译与集成建议
- HY 策略：
  - 默认使用 TE 适配与契约（兼容 FPC 3.2）
  - GI 通过 FAFAFA_IFACE_GI 开关启用，仅在 FPC 3.3.1+ 环境下用于实验性契约
- contracts_runner 独立构建，不进入默认 BuildOrTest 流程

## 7. 现实现映射表（简）
- Queue
  - TSPSCQueue<T> → cmSPSC, Bounded=True
  - TMichaelScottQueue<T> → cmMPSC, Bounded=False
  - TPreAllocMPMCQueue<T> → cmMPMC, Bounded=True
- Stack
  - TTreiberStack<T> → Bounded=False
  - TPreAllocStack<T> → Bounded=True
- Map
  - OA（TLockFreeHashMap）→ 支持 LoadFactor/Capacity、开放寻址/探测路径
  - MM（TMichaelHashMap）→ 分离链接、逻辑删除，TryResize 未来增强

## 8. 落地路径
- 阶段 1（本次）：提交本草案与 GI 占位（tests），不改 src
- 阶段 2：扩充契约覆盖（批量 API、能力断言）；runner 独立
- 阶段 3：按需验证 GI 契约；评估将部分具体类型 implements GI 的可行性（保持兼容）



---

## 9. 已落地的最小接口与工厂（宏默认关闭）

本仓库已提供一组最小泛型接口与工厂（默认不参与主线构建，通过宏启用）：
- ILockFreeQueue<T> + 能力标注接口 ILockFreeQueueSPSC/MPSC/MPMC
- ILockFreeStack<T>
- ILockFreeMapEx<K,V>：非破坏扩展接口，新增 PutEx/RemoveEx 返回旧值/状态
- 工厂：NewSpscQueue/NewMpscQueue/NewMpmcQueue/NewTreiberStack/NewPreallocStack
- MapEx 适配器（OA）：TMapExOAAdapter<K,V> + NewOAHashMapEx/WithComparer

启用方式（建议在独立工程中启用，避免影响主线）：
- 在独立 .lpr 内加入：
  {$DEFINE FAFAFA_CORE_IFACE_FACTORIES}
- 或使用 lazbuild 直接编译该独立 .lpr

### 快速使用示例（SPSC/MPMC/Stack）
```pascal
var Qs := specialize NewSpscQueue<Integer>(1024);
var Qm := specialize NewMpmcQueue<Integer>(1024);
var S  := specialize NewTreiberStack<Integer>;
```

### MapEx（非破坏扩展）示例
```pascal
var M  : specialize ILockFreeMapEx<string, Integer>;
var Old: Integer;
var R  : TMapPutResult;
M := specialize NewOAHashMapExWithComparer<string,Integer>(64, @CaseInsensitiveHash, @CaseInsensitiveEqual);
R := M.PutEx('Key', 1, Old);      // mprInserted, Old=0
R := M.PutEx('KEY', 2, Old);      // mprUpdated,   Old=1
```

### 为什么使用 Ex 接口 + 适配器
- 保持现有实现/对外 API 完全不变
- 通过“适配器”提供增强语义（返回旧值/状态），满足上层“少一次查询”的需求
- 便于渐进迁移；实现细节可被替换而不影响调用方

## 10. 测试与构建建议
- 主线测试：tests/fafafa.core.lockfree/BuildOrTest.bat test（不启用接口宏）
- 接口/工厂独立工程（建议用 .lpr 直接构建，避免 LPI MainUnit 识别差异）：
  - 构建并运行（在项目根目录，用 cmd 规避 PowerShell 解析问题）：
    cmd /c "D:\devtools\lazarus\trunk\lazarus\lazbuild.exe tests\fafafa.core.lockfree\fafafa.core.lockfree.ifaces_factories.test.lpr && tests\fafafa.core.lockfree\bin\lockfree_ifaces_factories_tests.exe"
- 若需在任意工程启用接口/工厂，请先评估宏对现有引用的影响；推荐以“独立工程 + 宏启用”的方式逐步集成
