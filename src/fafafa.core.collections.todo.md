# fafafa.core.collections 模块 TODO 与规划

## 目标与定位
- 作为 fafafa.core 集合体系的门面单元与统一入口：聚合导出核心接口、增长策略、常用容器与工厂函数
- 统一“面向接口”的抽象 + 统一的迭代/算法协议，向 Rust Vec/VecDeque、Go slice/Container、Java Collections & Deque 靠拢
- 保持跨平台、零依赖于 UI/终端；尽可能纯算法/内存友好

## 现状盘点（本轮）
- 存在的子模块：arr/vec/vecdeque/forwardList/list/deque/stack/queue/node/elementManager/base 已较完整
- src/fafafa.core.collections.pas 已实现门面导出与工厂：MakeArr<T>/MakeVec<T>/MakeVecDeque<T>（其余工厂规划中）
- 新增门面级统一测试工程 tests/fafafa.core.collections/，基础工厂用例已通过并完成泄漏检查
- docs/collections.md 有迭代器与统一设计蓝图，需对齐完善
- settings 宏位于 src/fafafa.core.settings.inc（全局唯一），已有匿名引用/内联/增长策略等相关宏

## 基线研究要点（竞品对齐与约束）
- Rust
  - Vec: reserve 与 reserve_exact、shrink_to_fit 语义明确；增长策略应可配置且可被精确控制
  - VecDeque: 无拷贝的头尾 Push/Pop；切片视图与范围操作
- Go
  - slice append 触发倍增增长（实现细节随版本浮动）；强调“容量(cap)/长度(len)”区分
- Java
  - Deque 接口（ArrayDeque/LinkedList 实现）约束 API 行为一致性；迭代器/Fail-Fast 语义
- FreePascal
  - for..in 枚举器模式：GetEnumerator 返回 record，需具备 MoveNext/Current；FPCUnit 的异常断言与 UTF-8 输出注意事项

## 门面单元设计草案（不落实现，仅计划）
- 类型再导出
  - 统一 re-export：
    - 接口/基类：ICollection、IGenericCollection<T>、TGenericCollection<T>
    - 增长策略：TGrowthStrategy 及 TCustom/TDoubling/TFixed/TFactor/TPowerOfTwo/TGoldenRatio/TAlignedWrapper
    - 常用容器：TVec<T>、TVecDeque<T>、TForwardList<T>、TDeque<T>、TQueue<T>、TStack<T>、TList<T>
    - 基础组件：TElementManager<T>、节点 node 基元
- 工厂函数（返回接口/基类类型，隐藏实现细节）
  - NewVec<T>(Capacity?, Allocator?, GrowStrategy?)
  - NewVecDeque<T>(...)
  - NewForwardList<T>(...)
  - NewDeque/Queue/Stack/List(...)
- 类型别名（宏控制以避免代码膨胀）
  - {$IFDEF FAFAFA_CORE_TYPE_ALIASES} 常用 specialization 的 alias
- 错误与行为约束
  - 区分 Try* 与抛异常版本；Exact 与 Strategy 版本明确

## TDD 计划（第一阶段）
1) 门面编译与 API 可见性测试
   - tests/fafafa.core.collections/
     - Test_fafafa_core_collections.pas：
       - 引用单一单元 uses fafafa.core.collections;
       - 编译期验证公共类型别名/工厂声明可见；
       - 运行期 smoke（调用空实现工厂 -> 暂时返回 nil 或 mock，先红再绿）
   - BuildOrTest.bat/.sh（Debug + 泄漏检测）
2) 工厂函数最小实现（返回真实容器实例，但通过接口抽象暴露）
   - 先覆盖 Vec + VecDeque；其余延伸到 ForwardList/Queue/Stack/List
3) shrink/reserve/reserveExact 语义一致性测试（对齐 Rust 语义）
4) 文档与示例
   - docs/fafafa.core.collections.md：门面职责、API、组装方式
   - examples/fafafa.core.collections/：最简示例（仅门面 uses + 工厂）

## 任务拆解（短期迭代）
- [ ] T1: 门面单元 API 草案（接口导出/声明 + 工厂声明）
- [ ] T2: 门面测试工程骨架（lpi/lpr + TestCase + BuildOrTest 脚本）
- [ ] T3: NewVec/NewVecDeque 最小实现（红->绿）
- [ ] T4: docs 初稿与示例骨架
- [ ] T5: 统一异常信息与 AssertException 测试模板（结合宏 FAFAFA_CORE_ANONYMOUS_REFERENCES）

## 风险与注意
- 泛型 specialization 膨胀风险：alias 需受宏控制
- for..in 与接口/类实现之间的可见性问题：保持与 base/vec 现有风格一致
- 跨平台构建脚本路径/相对目录一致性（bin/lib 输出分离）

## 本轮结论
- 门面单元需要尽快补齐 API 与对外统一入口；优先实现 Vec/VecDeque 的工厂路径
- 先落测试再实现，保证 100% 覆盖与异常路径覆盖



## 2025-08-10 进展记录 #1
- 门面工厂已实现：MakeArr<T>/MakeVec<T>/MakeVecDeque<T>
- 新增门面级测试工程并通过：tests/fafafa.core.collections/（4个用例，全绿，无泄漏）
- 调整 tests_collections.lpi 输出到 tests/.../bin，脚本一致
- 坚持“arr/vec 源和测试不改风格”的约束，仅门面拼装

### 后续计划（短期）
- 扩充门面工厂：MakeForwardList/MakeDeque/MakeQueue/MakeStack/MakeList
- 门面级最小示例与文档初稿
- 生成 arr/vec 公开接口覆盖对照清单（仅记录，不更改源码风格）


## 2025-08-11 进展记录 #2
- 调研并验证门面测试工程：tests/fafafa.core.collections 可一键构建运行（Debug），4 用例全绿、无内存泄漏
- 盘点子模块与文档现状，确定短期优先事项
- 规划下一阶段测试（容量/分配器/增长策略语义验证）与文档/示例骨架

### 下一步（短期）
- [ ] 扩展门面工厂到 ForwardList/List/Deque/Queue/Stack（在宏 FAFAFA_COLLECTIONS_FACADE 下）
- [ ] 为 MakeVec/MakeVecDeque/MakeArr 增加语义测试（容量/分配器/增长策略）
- [ ] 起草 docs/fafafa.core.collections.md 与 examples/fafafa.core.collections/



## 2025-08-12 调研与规划记录 #3
- 在线调研（FreePascal 集合生态）
  - Lazarus Wiki: Data Structures, Containers, Collections（Classes/FGL/Generics.Collections/fcl-stl 对比）
  - Castle Engine: Modern Object Pascal（建议优先使用 Generics.Collections；对比 FGL 与 fcl-stl）
  - 结合本仓现状：我们已自研 arr/vec/vecdeque/forwardList 等，更偏向统一的接口/增长策略/分配器抽象
- 竞品对齐结论（面向行为语义）
  - Reserve / ReserveExact：对齐 Rust 语义（前者保证 >= Count+add；后者尽量精确但允许实现按对齐增长）
  - VecDeque：保证头尾 O(1) push/pop；通过 IVec 接口访问容量/增长策略；策略可运行时替换
  - Allocator：工厂层透传，容器对外暴露 GetAllocator 用于测试与诊断
  - 门面工厂：维持 Make* 命名（MakeVec/MakeVecDeque/MakeArr/...）；隐藏具体类，返回接口
- 现状同步
  - 工厂族已实现：MakeArr/MakeVec/MakeVecDeque/MakeForwardList/MakeList/MakeDeque/MakeQueue/MakeStack
  - tests/fafafa.core.collections/ 已具备基础用例（编译与运行均通过，泄漏检查已配置）
  - settings：{$DEFINE FAFAFA_COLLECTIONS_FACADE} 默认启用；匿名函数宏按 FPC 版本条件启用
- 待办（下一轮优先级）
  - [ ] 门面层语义测试补强：
    - Vec/VecDeque：Reserve/ReserveExact/shrink/reserve-path 上下界与边界值
    - GrowthStrategy：PowerOfTwo/Factor/GoldenRatio 的容量演进断言
    - Allocator：自定义分配器透传与释放路径
  - [ ] 文档骨架：docs/fafafa.core.collections.md（职责/API/工厂/示例）
  - [ ] 示例骨架：examples/fafafa.core.collections/（最小用法）
- 风险与注意
  - 泛型 specialization 膨胀：类型别名通过 FAFAFA_CORE_TYPE_ALIASES 受控
  - 版本兼容：匿名函数仅在 FPC >= 3.3.1 打开；默认语义需兼容 3.2.2
  - 跨平台：继续保持纯算法/内存模块，不引入平台特有 API



## 2025-08-13 调研与规划记录 #4
- 在线调研：FPC 集合（FGL、fcl-stl、Generics.Collections）、FPCUnit 规范、for..in 枚举器、以及 Rust/Go/Java 集合语义对比
- 现状：门面工厂已基本覆盖（Arr/Vec/VecDeque/ForwardList/List/Deque/Queue/Stack）；统一测试工程可作为语义测试承载
- 决策：
  - 保持 Make* 工厂返回接口（隐藏实现类），分配器/增长策略贯通；库单元避免中文输出
  - 在门面层补充 Reserve/ReserveExact/shrink 与 GrowthStrategy/Allocator 透传的语义测试
- 下一步：
  - [ ] 门面 API 审计与导出类型清单补全（必要时仅文档化别名，避免 specialization 膨胀）
  - [ ] 强化测试：容量增长曲线、边界条件（0/1/大值）、自定义 Allocator 生命周期
  - [ ] docs/fafafa.core.collections.md 与 examples 骨架


## 2025-08-12 快速排错记录 #4
- 构建与冒烟
  - 门面 tests_collections: 10/10 通过，泄漏 0
  - arr: 333/333 通过，泄漏 0
  - vec: 408/408 通过，泄漏 0
  - vecdeque: 简易用例运行有逆序/段校验 FAIL 日志；完整测试工程编译失败（测试单元后段存在语法/重复声明问题）
- 最小修复
  - Test_vecdeque.pas: 将 uses DateUtils 移至 implementation，修复 "BEGIN expected but USES found"
- 发现的问题
  - vecdeque Reverse/切片在环绕场景下存在不一致（日志：R[i] 期望/实际不符；Back segment mismatch）
  - tests_vecdeque.lpi 对应的 Test_vecdeque.pas 末段存在重复/不匹配声明与过长字符串，导致编译失败
- 建议的快速修复顺序（不动深度语义）
  1) 先以简易用例定位 vecdeque Reverse 在跨环与分段的索引映射问题（修正 Deque 内部 reverse 路径，不触碰其他路径）
  2) 规范化 full 测试单元：去除重复声明/修复超长字符串，保证可编译；暂不扩展断言
  3) 后续统一到收尾阶段再做深度语义回归
- 待办（快修优先）
  - [ ] 修复 vecdeque Reverse 在跨环场景的索引映射与写回算法
  - [ ] 清理 Test_vecdeque.pas 尾段的重复声明/无效实现，恢复 full suite 可编译



## 2025-08-13 调研与规划记录 #5
- 在线调研（基于既有知识与历史资料对齐）：
  - FreePascal 集合生态：FGL、fcl-stl、Generics.Collections（Delphi 兼容），for..in 迭代器需 record + MoveNext/Current；FPCUnit 适配良好；lazbuild 构建 LPI 项目
  - 对标语义：
    - Rust: Vec/VecDeque 的 reserve/reserve_exact、shrink_to_fit 行为；可插拔增长策略
    - Go: slice cap/len 分离；append 触发增长
    - Java: Deque 接口一致性（ArrayDeque/LinkedList 实现）；迭代器语义保持
- 仓库现状快速审计：
  - 门面单元 src/fafafa.core.collections.pas 已实现 MakeArr/MakeVec/MakeVecDeque 等多数工厂，返回接口抽象
  - tests/fafafa.core.collections/ 已具备一键构建脚本与覆盖门面工厂及语义用例
  - 增长策略/Allocator 抽象在 base 中较完善
- 当前问题与观察：
  - 本地尝试执行 BuildOrTest.bat 未捕获到控制台输出（需要再次确认终端工具捕获）
  - VecDeque 的更深语义测试（环绕/反转/切片）仍待补齐；已在其他测试集中提到潜在问题
- 下一步（高优先级）：
  1) 复核门面层 IFDEF 结构完整性，保障不同宏组合下编译稳定
  2) 强化门面语义测试：Reserve/ReserveExact/Shrink/Allocator/GrowthStrategy 边界值
  3) 起草 docs/fafafa.core.collections.md（职责/API/工厂/示例），建立 examples 骨架
  4) 针对 VecDeque 的跨环 Reverse/切片路径做最小复核与快修（不扩散影响）
