# fafafa.core.mem

`fafafa.core.mem` 当前负责内存操作、allocator 生态和几类可直接复用的池实现。strict L0 只保留其中的 allocator contract；这个根文档只负责定锚 source-of-truth、模块边界和阅读顺序，不再继续承担“第二套大全手册”。

## 当前 source-of-truth

按下面顺序理解当前 mem 域：

1. `src/fafafa.core.mem.allocator.base.pas`
2. `src/fafafa.core.mem.allocator.foundation.pas`
3. `src/fafafa.core.mem.pas`
4. `src/fafafa.core.mem.allocator.pas`
5. `src/fafafa.core.mem.memPool.pas`
6. `src/fafafa.core.mem.stackPool.pas`
7. `src/fafafa.core.mem.pool.slab.pas`
8. `src/fafafa.core.mem.interfaces.pas`
9. `src/fafafa.core.mem.stats.pas`
10. `tests/fafafa.core.mem.allocator.foundation/README.md`
11. `tests/fafafa.core.mem/README.md`
12. `examples/fafafa.core.mem/README.md`

## 当前模块结构

当前长期有效的结构可以按职责理解：

- 门面与基础操作
  - `fafafa.core.mem`
  - `fafafa.core.mem.alloc`
  - `fafafa.core.mem.aligned`
  - `fafafa.core.mem.layout`
  - `fafafa.core.mem.error`
- 分配器合同与实现
  - `fafafa.core.mem.allocator.base`
  - `fafafa.core.mem.allocator.foundation`
  - `fafafa.core.mem.allocator`
  - `fafafa.core.mem.allocator.rtlAllocator`
  - `fafafa.core.mem.allocator.callbackAllocator`
  - `fafafa.core.mem.allocator.crtAllocator`
  - `fafafa.core.mem.allocator.mimalloc`
  - `fafafa.core.mem.manager.*`
- 池与 arena
  - `fafafa.core.mem.memPool`
  - `fafafa.core.mem.stackPool`
  - `fafafa.core.mem.pool.slab`
  - `fafafa.core.mem.blockpool*`
  - `fafafa.core.mem.arena.growable`
  - `fafafa.core.mem.pool.fixed*`
  - `fafafa.core.mem.pool.objectPool`
- 只读统计与适配
  - `fafafa.core.mem.stats`
  - `fafafa.core.mem.interfaces`
  - `fafafa.core.mem.adapter*`
  - `fafafa.core.mem.pool.adapter`

## 当前推荐入口

如果你要直接使用模块：

1. 先看 [`docs/fafafa.core.mem.quickstart.md`](./fafafa.core.mem.quickstart.md)
2. 再看 [`docs/fafafa.core.mem.guide.md`](./fafafa.core.mem.guide.md)
3. 需要理解组织方式时看 [`docs/fafafa.core.mem.architecture.md`](./fafafa.core.mem.architecture.md)

如果你只关心 strict L0 allocator contract：

1. 回到 `docs/fafafa.core.l0.foundation.md`
2. 再看 `src/fafafa.core.mem.allocator.base.pas`
3. 最后用 `tests/fafafa.core.mem.allocator.foundation/README.md` 确认当前 low-level facade 的验证入口

如果你要验证现状：

1. 看 `tests/fafafa.core.mem/README.md`
2. 再看 `examples/fafafa.core.mem/README.md`

如果你要追历史材料：

1. 看 `archive/reports/docs-root/` 下以 `fafafa.core.mem.*` 命名的历史快照
2. 重点关注 `summary`、`final-status`、`final-verification`、`test-summary` 这类阶段性材料，不要把它们当 current-entry

## 当前公开语义

- `fafafa.core.mem` 根门面偏向基础操作和分配器再导出。
- `fafafa.core.mem.allocator.base` 是 strict L0 allocator contract 的 source-of-truth。
- `fafafa.core.mem.allocator.foundation` 是 mem 域低层 convenience facade，不再定义 strict L0 边界。
- `fafafa.core.mem.allocator` 保留为兼容 / 扩展聚合入口，可继续暴露可选后端。
- `TMemPool`、`TStackPool`、`TSlabPool` 仍是当前最直接的池实现入口。
- `fafafa.core.mem.interfaces` 是接口化预研，不应被误读为“所有池都已经统一切换到接口优先”。
- `fafafa.core.mem.stats` 只提供只读快照，不应改变池行为。
- 并发池与分片池需要直接使用对应子单元，不应默认由根门面代替全部场景。

## 当前验证入口

- Windows:
  - `tests\\fafafa.core.mem\\BuildOrTest.bat test`
  - `examples\\fafafa.core.mem\\BuildAndRun.bat release run`
- Linux/macOS:
  - `bash tests/fafafa.core.mem/BuildOrTest.sh`
  - `./examples/fafafa.core.mem/BuildAndRun.sh release run`

说明：

- `tests/fafafa.core.mem/BuildOrTest.sh` 当前实际构建的是 `tests_mem_allocator_only.lpi`。
- `tests/fafafa.core.mem/BuildOrTest.bat` 当前构建的是 `tests_mem.lpi` 的 Debug 产物。
- 脚本行为存在平台差异；需要精确判断时，以 `tests/fafafa.core.mem/README.md` 的脚本边界为准。

## 当前边界

- 当前长期有效的 mem 域重点是内存操作、分配器合同、池实现、只读统计和适配层。
- allocator contract 与低层 backend 仍由 `tests/fafafa.core.mem.allocator.foundation/` 单独回归，但这个入口现在代表 mem 域低层 facade，而不是 strict L0 本体。
- `memory map`、共享内存、跨进程映射这类能力，当前框架层面的长期入口优先放在 `fs` 子域理解；mem 侧旧实现和旧示例更适合当专项材料或历史背景。
- `archive/reports/docs-root/` 下的 mem 完成报告、测试报告、生产级结论都只能当历史快照，不再直接代表今天的模块状态。
- 任何固定通过率、固定性能收益、固定“生产就绪”结论，都不应绕开源码和当前 tests/examples 入口单独传播。
