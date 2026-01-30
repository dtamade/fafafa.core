# TODOs

Note: This file is deprecated and kept for historical context.
Authoritative, active TODOs have been consolidated under `todos/`.
Please update and track tasks in the corresponding `todos/*.md` files.

- [ ] 评估在下一个小版本将 JSON Writer 默认切换至 V2（结构化 cleanup 数组）
  - 观察期：至少 1 个小版本周期
  - 影响评估：是否存在依赖旧 message 拼接的外部解析器
  - 迁移策略：
    - 发布说明明确字段变更（新增 cleanup 数组）
    - 提供环境变量或配置开关以临时回退到旧行为（必要时）
  - 验证：
    - 增加/完善针对 JSON V2 的结构化断言测试
    - 真实项目集成验证（如 CI）

# fafafa.collections 项目任务清单 (todo.md)

此文件用于跟踪项目的宏伟蓝图和日常的临时任务。

---

## 长期计划与核心路线图

*此部分为高级规划，指向详细的 `.md` 设计文档。*

* **[迭代器框架]**: 实现一个双层、高性能、STL 风格的迭代器框架。

  * **详细计划**: `iter.md`
* **[关联式容器]**: 设计并实现 `THashMap`, `THashSet`, `TTreeMap`, `TTreeSet`。

  * **详细计划**: `associative.md`
* **[通用算法]**: 创建一个基于迭代器的、与容器无关的通用算法库。

  * **详细计划**: `algorithms.md`
* **[高级内存管理]**: 提供池分配器、区域分配器和调试分配器。

  * **详细计划**: `memory.md`
* **[性能基准测试]**: 建立一个系统化、可重复的基准测试框架。

  * **详细计划**: `benchmarks.md`

---

## 临时想法与草稿区

*此区域用于存放临时的、未经整理的想法和日常任务。*

* [ ]

# fafafa.core 项目任务清单 (TODO)

此文件用于记录和跟踪 `fafafa.collections` 项目的待办事项、功能计划和优化点。

## 第一优先级：API 统一与重构

- [ ]

## 第二优先级：新功能与测试

- [ ]

## 第三优先级：底层优化与健壮性

- [ ]

## 第四优先级：文档与代码规范

- [ ]

## 长期目标

- [ ] **建立性能基准测试框架:**
  - [ ] 创建独立的性能基准测试项目。
  - [ ] 实现对核心操作（分配、复制、重分配）的性能测试。
  - [ ] 量化对比 `Checked` vs `UnChecked` 以及不同内存分配器实现的性能。
- [ ] **撰写开发手册:** 编写一本名为《FreePascal 现代编程指南》的电子书，详细介绍 `fafafa.collections` 的使用方法、设计理念和高级技巧，并包含完整的类库代码文档。
