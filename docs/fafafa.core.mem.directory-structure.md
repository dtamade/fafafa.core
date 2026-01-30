# fafafa.core.mem 目录结构说明

## 📁 当前目录结构（以仓库实际为准）

### 核心源码
```
src/
├── fafafa.core.mem.pas
├── fafafa.core.mem.memPool.pas
├── fafafa.core.mem.stackPool.pas
├── fafafa.core.mem.pool.slab.pas
├── fafafa.core.mem.pool.fixed.pas
├── fafafa.core.mem.pool.fixedSlab.pas
├── fafafa.core.mem.blockpool.pas
├── fafafa.core.mem.blockpool.*.pas
├── fafafa.core.mem.stats.pas
└── ...（其他 mem 子模块）
```

### 测试目录
```
tests/fafafa.core.mem/
├── tests_mem.lpi / tests_mem.lpr
├── BuildOrTest.bat / BuildOrTest.sh
├── BuildAndTest.bat
├── RunAllTests.bat
├── test_*.pas
├── bin/
└── lib/
```

### 示例目录
```
examples/fafafa.core.mem/
├── example_mem.lpr
├── example_mem_pool_basic.lpr
├── example_mem_pool_config.lpr
├── BuildAndRun.bat / BuildAndRun.sh
├── Build_examples.bat / Build_examples.sh
├── bin/
└── lib/
```

### 文档目录
```
docs/
├── fafafa.core.mem.md
├── fafafa.core.mem.quickstart.md
├── fafafa.core.mem.user-manual.md
├── fafafa.core.mem.usage-guide.md
├── fafafa.core.mem.architecture.md
├── fafafa.core.mem.nginx-slab.md
└── ...（其他 mem 相关文档）
```

## 🚀 使用方式

### 快速测试
```batch
# Windows
tests\fafafa.core.mem\BuildOrTest.bat test
```

```bash
# Linux/macOS
bash tests/fafafa.core.mem/BuildOrTest.sh
```

### 示例构建与运行
```batch
# Windows
examples\fafafa.core.mem\BuildAndRun.bat debug run
```

```bash
# Linux/macOS
./examples/fafafa.core.mem/BuildAndRun.sh debug run
```

### 性能对比（测试套件）
```batch
# Windows
tests\fafafa.core.mem\VerifyImprovements.bat
```

```bash
# Linux/macOS
tests/fafafa.core.mem/bin/tests_mem_debug --suite=TTestCase_SlabPool_PerformanceBenchmark --format=plain
```

## 📌 说明

- mem 模块门面仅导出基础内存操作与分配器；基础池需按需 `uses` 对应单元。
- 并发场景可使用 concurrent/sharded 版本（见 `src/fafafa.core.mem.blockpool.*` 与 `src/fafafa.core.mem.pool.slab.*`）。
- 统计快照使用 `fafafa.core.mem.stats`，示例见 quickstart/user-manual。
