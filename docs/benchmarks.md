# 基准测试与性能分析路线图 (benchmarks.md)

本文档规划了为 `fafafa.collections` 库建立一个系统化、可重复的基准测试框架的详细步骤。目标是用科学的数据来度量、证明和驱动性能优化。

---

## 阶段一: 框架搭建与初步测试

*目标: 建立基准测试的基础设施，并对核心容器 `TVec` 进行性能评估。*

- [ ] **1.1. 设计一个简单的基准测试框架**
    - [ ] **功能需求**:
        - **高精度计时**: 使用 `TStopWatch` 或平台特定的高精度计时器。
        - **多次运行与统计**: 对每个测试场景运行多次，并计算平均值、中位数、标准差等。
        - **防止编译器过度优化**: 确保被测试的代码不会被编译器优化掉（例如，将结果累加到一个 volatile 变量中）。
    - [ ] **实现**: 创建一个 `TBenchmark` 辅助类，提供 `Register` 和 `Run` 方法。

- [ ] **1.2. 创建基准测试项目**
    - [ ] 在 `tests` 目录下创建一个新的 Lazarus 项目 `benchmarks.lpi`。

- [ ] **1.3. 编写 `TVec` 的基准测试**
    - [ ] **场景**:
        - **`Add`**: 在末尾连续添加 N 个元素。
        - **`Insert`**: 在头部、中部、尾部插入元素。
        - **`Delete`**: 从头部、中部、尾部删除元素。
        - **`Iteration`**: 使用 `for..in` 循环遍历。
    - [ ] **对比对象**:
        - `fafafa.collections.TVec<T>`
        - `FPC RTL Generics.Collections.TList<T>`
        - (如果适用) `FGL.TFPGList<T>`

- [ ] **1.4. 建立初始性能报告**
    - [ ] 将测试结果以 Markdown 表格的形式输出到控制台或文件中。

---

## 阶段二: 扩展测试覆盖范围

*目标: 将基准测试推广到所有主要的数据结构和算法。*

- [ ] **2.1. 编写关联式容器的基准测试**
    - [ ] **场景**: 随机/顺序的 `Add`, `Remove`, `ContainsKey`。
    - [ ] **对比对象**:
        - `THashMap` vs `TTreeMap`
        - `THashMap` vs `FPC RTL TDictionary`

- [ ] **2.2. 编写算法的基准测试**
    - [ ] **场景**: 对不同大小的 `TVec` 进行 `Sort`。
    - [ ] **对比对象**:
        - 我们的 `Algorithms.Sort`
        - `TVec.Sort` (如果它有内置的)
        - `FPC RTL TList.Sort`

- [ ] **2.3. 编写内存分配器的基准测试**
    - [ ] **场景**: 模拟高频、小对象的分配与释放。
    - [ ] **对比对象**:
        - `RtlMemAllocator` (基线)
        - `TPoolAllocator`
        - `TArenaAllocator`

---

## 阶段三: 自动化与可视化

*目标: 让性能测试成为开发流程中一个自动化的、易于解读的环节。*

- [ ] **3.1. 集成到持续集成 (CI) 流程 (如果未来有)**
    - [ ] 每次代码提交后自动运行基准测试，并检测性能退化。

- [ ] **3.2. 结果可视化**
    - [ ] 调研简单的命令行绘图工具或脚本库 (如 Python 的 Matplotlib)，将测试结果生成为柱状图或折线图。
    - [ ] 将图表嵌入到项目的文档或 `README.md` 中，直观地展示我们库的性能优势。

---

## Term Paste Backends 微基准（legacy vs ring）

- 构建与运行
  - Windows: tests/fafafa.core.term\benchmarks\build_benchmarks.bat
  - 运行: tests/fafafa.core.term\bin\benchmark_paste_backends.exe [N]
- 场景
  - 依次对 legacy 与 ring 后端执行：append N 次 + trim_keep_last
  - 可选参数 keep_last、max_bytes 代表治理策略组合
- 读取
  - 输出包含每个后端的追加耗时与修剪耗时，以及最终 count/total_bytes
- 解读建议
  - ring 在大 N 下应显著优于 legacy（append/trim 均摊 O(1)）
  - 若开启 max_bytes 与 auto_keep_last，ring 仍维持稳定复杂度；推荐 N=200k 起做比较
- 推荐阈值（经验值）
  - 低/中等频率粘贴：keep_last=128，max_bytes=1m
  - 高频/大体量粘贴：keep_last=64..128，max_bytes=1m..2m


- 示例输出（Windows，本地一次跑样）：

```
Benchmark paste backends with N=200000
: append x200000 in 10 ms; count=200000 total=1400000
: trim_keep_last(0) in 0 ms; count=200000 total=1400000
ring: append x200000 in 14 ms; count=200000 total=1400000
ring: trim_keep_last(0) in 0 ms; count=200000 total=1400000
ring: append x200000 in 10 ms; count=50204 total=3514428
ring: trim_keep_last(128) in 0 ms; count=128 total=8996
```

- 简短解读
  - append: legacy 与 ring 在当前小字符串与本机条件下差距很小；在更大 N / 更复杂场景（混合长短 paste）ring 更稳定
  - trim_keep_last: ring 的 O(1) 均摊在大 N 下优势突出；配合 auto_keep_last 与 max_bytes 时可避免 O(n) 重建开销
