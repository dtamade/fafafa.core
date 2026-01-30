# fafafa.core.lockfree 最佳实践速查表（Cheatsheet）

本清单用于新老成员快速对齐：选型、原子语义、容量配置、退避/填充、接口使用、测试与构建等。

---

## 1) 数据结构选型（Quick Guide）
- 队列
  - 单生产者/单消费者：TSPSCQueue（最快；容量=2^k）
  - 多生产者/单消费者：TMichaelScottQueue（MPSC；无界；入队可推进）
  - 多生产者/多消费者：TPreAllocMPMCQueue（Vyukov；有界；高吞吐）
- 栈
  - 动态容量：TTreiberStack（链式；注意回收策略）
  - 固定容量/热点：TPreAllocStack（ABA 安全；预分配）
- 哈希表
  - OA（开放寻址）：读多写少、装载因子 ≤ 0.7、键值平凡类型
  - MM（分离链接）：插入/删除频繁、冲突高、稳定性优先（需显式 Hash/Comparer）

## 2) HashMap 最佳实践
- OA 默认兜底：Create(capacity, nil, nil) → SimpleHash + CompareMem
  - 仅平凡类型（无指针/无变长）适用；否则请显式 Hash/Comparer
- MM 不兜底：必须提供 Hash/Comparer（建议走门面/Builder 显式传参）
- 装载因子：OA 建议 ≤ 0.7；接近上限 Put 可能失败（幂等）
- 自定义相等性（如大小写不敏感）：显式 CaseInsensitiveHash/Equal + 契约测试锁定

## 3) 原子与内存序（跨平台安全）
- 读取快路径：atomic_load(..., acquire)
- 发布写入：atomic_store(..., release) / CAS 使用 acq_rel
- 指针读/写（链式结构 Next/Head/Tail）：读 acquire；发布 release/acq_rel
- 仅使用 fafafa.core.atomic，必要时 atomic_thread_fence(order)

## 4) 争用缓解（按需启用）
- 伪共享：FAFAFA_LOCKFREE_CACHELINE_PAD（MPMC 高并发下建议基准验证后开启）
- 退避：FAFAFA_LOCKFREE_BACKOFF（CAS 热点明显时；缺省 Sleep(0) 轻量让出）
- 有界重试：在 Put/Enqueue 冲突处小次数重试 + 让出，语义不变

## 5) 容量与内存
- 有界结构容量：固定为 2 的幂（SPSC/MPMC）
- 预分配结构：创建期分配内存；运行期避免动态分配（热路径零分配）
- Clear：最佳努力，不承诺强一致统计

## 6) API 使用（对齐 Rust/Go/Java）
- Try vs Blocking：优先 TryEnqueue/TryDequeue；需要等待用 EnqueueBlocking/DequeueBlocking(TimeoutMs)
- 关闭语义：Close/IsClosed；Close+Empty 时消费者返回 False
- 批量：EnqueueMany/DequeueMany/DrainTo 降低同步开销
- 容量观测：RemainingCapacity/Size 为 best-effort，不用于严格计量

## 7) 测试与质量
- 契约先行：IQueue/IStack/IMap 基本语义、幂等性、边界行为
- 并发用例：短小可重复；必要时引入重复/超时上限
- 泄漏检查：Debug + heaptrc，应为 0 泄漏
- 基准：只在决策点最小化跑分；以接口与缺陷发现为主
- 测试注册：使用闭包（reference to procedure），避免 `is nested`，防止 RegisterTests 返回后静态链失效 → docs/partials/testing.best_practices.md


## 8) 构建与配置
- 构建：tools/lazbuild.bat；tests/*/BuildOrTest.bat
- 全局宏：仅 src/fafafa.core.settings.inc（release/ 为镜像生成）
- 库单元：不输出中文、不加 {$CODEPAGE UTF8}（测试/示例可用）

## 9) 可维护性与演进
- 接口 + 工厂/Builder：便于替换实现与测试双轨
- 文档化默认：OA 默认兜底；MM 需显式 Hash/Comparer（避免回归）
- 回收策略（规划）：Treiber/HashMap 在高删除率场景评估 EBR/HP；先在 play/ 原型验证

---

### Do / Don’t
- Do：接口/工厂、契约测试、Try + 批量、按需 Pad/Backoff、2 的幂容量、零分配热路径
- Don’t：库单元中文/CODEPAGE、热路径用锁/动态分配、无依据的栅栏/退避

