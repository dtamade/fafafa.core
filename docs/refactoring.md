# `fafafa.core` 模块化重构路线图 (refactoring.md)

本文档为 `fafafa.core` 库的模块化重构提供具体的、阶段性的**行动计划**。所有架构与设计原则请参阅 `gemini.md`。

---

## 阶段一: 奠定框架基石

*目标: 创建最底层的、被所有其他模块依赖的基础单元。*

- [X] **1.1. 创建数学工具单元**: `src/fafafa.core.math.pas`

  - @desc: 包含不依赖外部 `Math` 单元的、最基础的数学辅助函数 (`Min`, `Max`, `Ceil` 等)。这是依赖关系金字塔的塔尖。
- [ ] **1.2. 创建框架基础单元**: `src/fafafa.core.base.pas`

  - @desc: 包含框架最顶层的异常基类 `ECore` 和其他通用异常 (`EParamNil`, `EInvalidOperation` 等)。
- [X] **1.3. 创建内存工具单元**: `src/fafafa.core.mem.utils.pas`

  - @desc: 包含 `MemCopy`, `MemFill`, `IsOverlap` 等内存操作函数。
- [X] **1.4. 编写初始单元测试**

  - [X] 创建 `tests/test_math.pas`。
  - [X] 创建 `tests/test_base.pas` (占位测试已存在，目前无需更多)。
  - [X] 创建 `tests/test_mem_utils.pas`。
  - [X] **编译并运行测试**，确保框架的基石 100% 正常工作。

---

## 阶段二: 构建核心模块

*目标: 基于框架基石，创建核心的功能模块。*

- [X] **2.1. 创建分配器模块**: `src/fafafa.core.mem.allocator.pas`

  - @desc: 包含 `IAllocator` 接口, `TAllocator` 抽象基类, `TRtlAllocator`, `TCrtAllocator` 和 `TCallbackAllocator` 具体实现。
- [X] 2.2. 编写测试单元: tests/test_mem_allocator.pas, 每个类 编成一个 testcase
- [ ] 2.3. 创建泛型元素管理器:  IElementManager src/fafafa.core.collections.elementManager.pas

  - [ ] 包含 IElementManager 接口, TElementManager 实现
  - [ ] 编写测试
- [ ] **2.4. 创建集合基础模块**: `src/fafafa.core.collections.base.pas`

  - @desc: 包含 `ICollection<T>` 接口, `TCollection<T>` 抽象基类, 以及集合专属的异常。

---

## 后续阶段 (整合与扩展)

- [ ] **3.1. 创建具体的容器单元** (e.g., `fafafa.core.collections.vec.pas`)。
- [ ] **3.2. 创建主入口单元** (`fafafa.core.pas`) 作为门面。
- [ ] **3.3. 配置构建系统与测试项目**。
- [ ] **3.4. 代码审查与合并**。
