# fafafa.core.mem 内存管理模块设计蓝图 (memory.md)

本文档是 `fafafa.core.mem` 模块的统一设计蓝图，负责定义内存分配的抽象接口、提供多种高性能的内存分配器实现、支持内存映射文件，并建立一套健壮、灵活的内存管理基础设施。

---

## 核心设计哲学

*   **接口驱动**: 所有分配器都必须实现统一的 `IMemAllocator` 接口。
*   **性能导向**: 提供针对不同场景（如大量小对象、临时计算、大文件I/O）高度优化的策略。
*   **可组合性**: 分配器可以像乐高积木一样被组合和包装。
*   **资源生命周期绑定**: 通过带清理回调的池，将内存生命周期与外部资源（如句柄）的生命周期安全地绑定在一起。
*   **安全性与调试**: 提供工具来帮助开发者捕获常见的内存错误。

---

## 阶段一: 核心接口与基础分配器

*目标: 奠定整个内存管理系统的基石。*

- [ ] **1.1. 最终确定 `IMemAllocator` 接口**
    - `unit fafafa.core.mem.allocator.pas`
    - `IMemAllocator = interface(IInterface)`
        - `function Allocate(aSize: SizeUInt; aAlignment: SizeUInt = DEFAULT_ALIGNMENT): Pointer;`: 分配带指定对齐的内存。
        - `procedure Deallocate(aPtr: Pointer);`
        - `function Reallocate(aPtr: Pointer; aNewSize: SizeUInt; aAlignment: SizeUInt): Pointer;`
        - `function GetName: string;`
    - @remark: `aAlignment` 必须是 2 的幂。`Reallocate` 也增加了对齐参数。

- [ ] **1.2. 实现 `TRtlAllocator`**
    - @desc: 包装 FPC 的 `GetMem` / `FreeMem`。它将作为默认的“上游”分配器。

- [ ] **1.3. 设计全局分配器管理器 `TMemory`**
    - `unit fafafa.core.mem.pas`
    - `class property Default: IMemAllocator read GetDefault write SetDefault;`
    - `class function GetRtl: IMemAllocator;`

---

## 阶段二: 高性能分配器

*目标: 实现针对特定场景优化的高性能分配器。*

- [ ] **2.1. 实现 `TPoolAllocator` (池分配器)**
    - @desc: 用于快速分配和释放大量、**固定大小**内存块。
    - **API 详解**: `constructor Create(aElementSize, aElementsPerChunk, aAlignment: SizeUInt; ...)`。`Reallocate` 不被支持。

- [ ] **2.2. 实现 `TCleanupPoolAllocator` (带清理回调的区域分配器)**
    - @desc: 借鉴 Nginx `ngx_pool_t` 的思想，用于管理一个任务/请求的完整生命周期。
    - **核心机制**: 内部使用指针碰撞法快速分配，并维护一个清理回调列表。`destructor` 或 `Reset` 会逆序调用所有回调来释放外部资源。
    - **详细接口设计 (`fafafa.core.mem.cleanuppool.pas`)**:
        ```pascal
        type
          TCleanupProc = procedure(aData: Pointer);
          TCleanupPoolAllocator = class(TInterfacedObject, IMemAllocator)
          public
            constructor Create(aInitialSize: SizeUInt; ...);
            function AddCleanupHandler(aHandler: TCleanupProc; aData: Pointer): Pointer;
            procedure Reset;
          end;
        ```

---

## 阶段三: 内存映射 I/O

*目标: 提供对内存映射文件的高性能访问能力。*

- [ ] **3.1. 设计 `TMemoryMap` 类**
    - `unit fafafa.core.mem.map.pas`
    - @desc: 提供一个跨平台的接口，用于将文件映射到内存中进行高性能读写。
    - **核心机制**: 封装 Windows 的 `CreateFileMapping`/`MapViewOfFile` 和 POSIX 的 `mmap`。
    - **详细接口设计**:
        ```pascal
        type
          TMapProtection = (mpRead, mpReadWrite, mpWriteCopy);
          TMapFlags = set of (mfShared, mfPrivate);

          TMemoryMap = class
          public
            constructor Create(const aFilePath: string; aProtection: TMapProtection; aFlags: TMapFlags; aOffset: Int64; aSize: SizeUInt);
            destructor Destroy; override;

            procedure Flush(aIsAsync: Boolean = False);
            procedure Lock;
            procedure Unlock;

            property BaseAddress: Pointer read GetBaseAddress;
            property Size: SizeUInt read GetSize;
          end;
        ```

---

## 阶段四: 分配器适配器与调试工具

*目标: 创建可以包装、修改或增强其他分配器行为的工具。*

- [ ] **4.1. 实现 `TDebugAllocator` (调试分配器)**
    - @desc: 包装器，用于捕获内存越界、泄漏和双重释放。

- [ ] **4.2. 实现 `TThreadSafeAllocator` (线程安全适配器)**
    - @desc: 使用锁机制为另一个非线程安全的分配器增加线程安全性。

- [ ] **4.3. 实现 `TFallbackAllocator` (回退分配器)**
    - @desc: 组合两个分配器，当主分配器失败时，尝试从次级分配器分配。

---

## 阶段五: 单元测试与集成

*目标: 确保所有内存模块的正确性、健壮性，并将其集成到上层模块中。*

- [ ] **5.1. 编写详尽的单元测试**
    - [ ] `testcase_poolallocator.pas`
    - [ ] `testcase_cleanuppool.pas`
    - [ ] `testcase_memmap.pas`
    - [ ] `testcase_debugallocator.pas`

- [ ] **5.2. 容器集成**
    - [ ] 确保所有容器的构造函数都能接受一个可选的 `IMemAllocator` 实例。
