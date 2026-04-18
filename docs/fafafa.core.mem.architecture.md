# fafafa.core.mem 架构说明

这份文档只描述当前还成立的组织方式，不再复述旧阶段的规模统计或“终极完成”语气。

## 当前 source-of-truth

1. `src/fafafa.core.mem.pas`
2. `src/fafafa.core.mem.allocator.foundation.pas`
3. `src/fafafa.core.mem.allocator.pas`
4. `src/fafafa.core.mem.memPool.pas`
5. `src/fafafa.core.mem.stackPool.pas`
6. `src/fafafa.core.mem.pool.slab.pas`
7. `src/fafafa.core.mem.stats.pas`
8. `src/fafafa.core.mem.interfaces.pas`

## 当前分层

```text
fafafa.core.mem
├── facade
│   └── fafafa.core.mem
├── allocators
│   ├── strict L0
│   │   ├── fafafa.core.mem.allocator.foundation
│   │   ├── fafafa.core.mem.allocator.base
│   │   ├── fafafa.core.mem.allocator.rtlAllocator
│   │   └── fafafa.core.mem.allocator.callbackAllocator
│   └── compatibility / optional
│       ├── fafafa.core.mem.allocator
│       ├── fafafa.core.mem.allocator.crtAllocator
│       └── fafafa.core.mem.allocator.mimalloc
├── pools
│   ├── fafafa.core.mem.memPool
│   ├── fafafa.core.mem.stackPool
│   ├── fafafa.core.mem.pool.slab
│   ├── fafafa.core.mem.blockpool*
│   └── fafafa.core.mem.pool.fixed*
├── add-ons
│   ├── fafafa.core.mem.stats
│   ├── fafafa.core.mem.interfaces
│   ├── fafafa.core.mem.adapter*
│   └── fafafa.core.mem.stack_scope_helpers
└── optional / specialized
    ├── fafafa.core.mem.mimalloc*
    ├── fafafa.core.mem.memoryMap
    ├── fafafa.core.mem.mapped*
    └── fafafa.core.mem.pool.objectPool
```

## 当前设计取向

- 根门面负责定锚，不负责把所有内存相关能力都重新包装一遍。
- `fafafa.core.mem.allocator.foundation` 负责 strict L0 allocator 入口；`fafafa.core.mem.allocator` 负责兼容 / 扩展聚合。
- 具体池类型仍直接放在各自单元里；使用者应根据场景显式 `uses`。
- `stats` 维持只读快照角色，避免把观测逻辑和池行为耦合到一起。
- `interfaces` 只承担补充合同，不应倒推出“现有实现已经全部接口化”。

## 当前依赖方向

从低到高可大致理解为：

1. `alloc` / `layout` / `error`
2. `allocator.*`
3. `memPool` / `stackPool` / `pool.slab` / `blockpool*`
4. `stats` / `adapter*` / `stack_scope_helpers`
5. 示例、测试和补充文档

## 当前边界

- 并发池、分片池是专门子单元，不应由根门面默认抽象掉差异。
- `memory map`、共享内存和跨进程映射，今天的长期框架入口优先放在 `fs` 域理解；mem 侧旧实现更适合作为专项或历史材料。
- `docs/mem/reports/` 中的报告只能解释某个开发阶段，不再定义当前架构。
