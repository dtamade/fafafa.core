# CLAUDE.md

本文档为 Claude Code (claude.ai/code) 在此仓库中工作时提供指导。

## 项目概览

**fafafa.core** 是一个全面的 Free Pascal（Object Pascal）核心库，提供高性能数据结构、算法和实用工具。它包含集合类型（TVec、TVecDeque、THashMap 等）、密码学、SIMD 优化、文件系统操作、网络、JSON 处理、无锁数据结构等。

- **语言**: Free Pascal（Object Pascal）
- **编译器**: Free Pascal Compiler（fpc）
- **许可证**: MIT
- **文档**: `docs/` 目录中的详细文档

## 开发命令

## Layer 1 开发说明

Layer 1（`atomic` + `sync.*`）当前以单 Agent 顺序推进为准，避免引入“多窗口协作/工作树”等流程文档造成误导。

### 环境配置

**FPC/Lazarus 路径**:
```bash
# 编译器位置
/home/dtamade/freePascal/fpc
/home/dtamade/freePascal/lazbuild

# 将其添加到 PATH（可选）
export PATH="/home/dtamade/freePascal:$PATH"
```

### 构建

```bash
# 清理构建产物
./clean.sh
# 或
clean.bat

# 构建 SIMD 库（Windows）
build.bat

# 使用标准标志手动编译
fpc -O3 -XX -Fi./src -Fu./src <source_file.pas>

# 带完整路径的编译
/home/dtamade/freePascal/fpc -O3 -XX -Fi./src -Fu./src <source_file.pas>

# 使用 lazbuild 构建项目
/home/dtamade/freePascal/lazbuild project.lpi

# 参数说明:
# -O3: 优化级别 3
# -XX: 智能链接
# -Fi: 包含目录（头文件）
# -Fu: 单元目录（编译后的单元）
```

### 测试

**快速回归测试（推荐每次提交前）**:
```bash
# Windows
set STOP_ON_FAIL=1 && tests\run_all_tests.bat fafafa.core.collections.arr fafafa.core.collections.base fafafa.core.collections.vec fafafa.core.collections.vecdeque

# Linux/macOS
STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.collections.arr fafafa.core.collections.base fafafa.core.collections.vec fafafa.core.collections.vecdeque
```

**全量回归测试（每日或发布前）**:
```bash
# Windows
tests\run_all_tests.bat

# Linux/macOS
bash tests/run_all_tests.sh
```

**运行特定测试模块**:
```bash
# Windows
tests\fafafa.core.collections.arr\BuildOrTest.bat

# Linux/macOS
bash tests/fafafa.core.collections.arr/BuildOrTest.sh

# 或使用完整路径
/home/dtamade/freePascal/lazbuild tests/fafafa.core.collections.arr/BuildOrTest.lpi
```

**执行单个测试**:
```bash
# 编译并运行单个测试
fpc -O3 -Fi./src -Fu./src -oTestExecutable test_name.pas
./TestExecutable

# 使用完整路径
/home/dtamade/freePascal/fpc -O3 -Fi./src -Fu./src -oTestExecutable test_name.pas
```

**内存泄漏检测（HeapTrc）**:
```bash
# 使用堆跟踪编译
fpc -gh -gl -B -Fu./src -Fi./src -oTestLeak test_collection_leak.pas

# 运行测试
./TestLeak

# 检查输出是否包含 "0 unfreed memory blocks"

# 或使用完整路径
/home/dtamade/freePascal/fpc -gh -gl -B -Fu./src -Fi./src -oTestLeak test_collection_leak.pas
```

### 测试输出

- **汇总文件**: `tests/run_all_tests_summary.txt`（Windows）、`tests/run_all_tests_summary_sh.txt`（Linux/macOS）
- **日志目录**: `tests/_run_all_logs/`（Windows）、`tests/_run_all_logs_sh/`（Linux/macOS）
- **返回码**: 0 = 成功，非零 = 失败
- **HeapTrc 报告**: 控制台输出 + `tests/HASHMAP_HEAPTRC_REPORT.md`

### 测试分类

关键测试模块（优先运行这些进行快速验证）：
- `fafafa.core.collections.arr` - 数组集合
- `fafafa.core.collections.base` - 基础集合类型
- `fafafa.core.collections.vec` - Vec（动态数组）
- `fafafa.core.collections.vecdeque` - VecDeque（双端队列）

## 代码架构

### 核心模块

```
fafafa.core/
├── src/                          # 主要源代码
│   ├── fafafa.core.pas           # 主门面单元
│   ├── fafafa.core.collections.* # 集合类型（Vec、VecDeque、HashMap 等）
│   ├── fafafa.core.crypto.*      # 密码学（AES、GHASH、ChaCha20Poly1305 等）
│   ├── fafafa.core.simd.*        # SIMD 优化（SSE、AVX、NEON 等）
│   ├── fafafa.core.fs.*          # 文件系统操作
│   ├── fafafa.core.process.*     # 进程管理
│   ├── fafafa.core.json.*        # JSON 解析/序列化
│   ├── fafafa.core.lockfree.*    # 无锁数据结构
│   ├── fafafa.core.mem.*         # 内存管理
│   ├── fafafa.core.sync.*        # 同步原语
│   ├── fafafa.core.thread.*      # 线程
│   ├── fafafa.core.socket.*      # 套接字/网络
│   └── ...
│
├── tests/                        # 测试套件
│   ├── run_all_tests.bat/.sh     # 测试运行脚本
│   ├── fafafa.core.collections.* # 集合测试
│   ├── fafafa.core.crypto.*      # 密码学测试
│   ├── fafafa.core.mem.*         # 内存测试
│   └── ...
│
├── docs/                         # 文档
│   ├── Architecture.md           # 架构概览
│   ├── TESTING.md                # 测试指南
│   ├── API_Reference.md          # API 文档
│   ├── INDEX.md                  # 文档索引
│   ├── BestPractices*.md         # 最佳实践指南
│   └── ...
│
└── examples/                     # 示例程序
    ├── fafafa.core.collections/  # 集合示例
    ├── fafafa.core.crypto/       # 密码学示例
    ├── fafafa.core.fs/           # 文件系统示例
    └── ...
```

### 模块依赖关系

集合层次结构：
```
fafafa.core.collections.specialized
    ↓
fafafa.core.collections.vecdeque
    ↓
fafafa.core.collections.base
    ↓
fafafa.core.mem.allocator
    ↓
fafafa.core.base
```

内存管理模式：
```
TVec/THashMap/TVecDeque
    ↓ 使用
IMemoryAllocator（接口）
    ↓ 实现
TAllocator、TRtlAllocator、TCrtAllocator、TCallbackAllocator
```

### 关键设计模式

1. **基于接口的设计**: 核心模块使用接口（例如 `IAllocator`、`IJsonReader`）
2. **泛型/特化类型**: 集合使用 Free Pascal 泛型并提供特化实现以提升性能
3. **门面模式**: 主单元（例如 `fafafa.core.json`、`fafafa.core.crypto`）提供统一 API
4. **默认无锁**: 并发模块提供无锁结构（Treiber 栈、Michael-Scott 队列等）

### 数据结构

**集合类型**:
- `TVec<T>`: 带有增长策略的动态数组
- `TVecDeque<T>`: 使用环形缓冲区的双端队列
- `THashMap<TKey, TValue>`: 使用开放寻址的哈希映射
- `TList<T>`: 单向链表
- `TForwardList<T>`: 带有节点池的前向列表

**无锁结构**:
- `TLockFreeStack`: Treiber 栈（125M ops/sec）
- `TLockFreeMPSCQueue`: Michael-Scott 队列（31M ops/sec）
- `TLockFreeMPMCQueue`: 多生产者多消费者队列
- `TLockFreeSPSCQueue`: 单生产者单消费者队列

**内存管理**:
- `TAllocator` / `IAllocator`: 分配器接口模式
- `TEnhancedObjectPool`: 带清理的对象池
- `TMappedRingBuffer`: 无锁环形缓冲区

## 重要配置

### 编译器设置

```pascal
{$MODE OBJFPC}{$H+}
{$I fafafa.core.settings.inc}
```

标准编译标志：
- `-O3`: 最大优化
- `-XX`: 智能链接
- `-Fi./src`: 包含路径
- `-Fu./src`: 单元搜索路径
- `-gh`: 启用堆跟踪（用于泄漏检测）
- `-gl`: 为堆跟踪启用行信息

### 构建输出

- `.o`: 目标文件
- `.ppu`: 编译后的单元文件
- `lib/`: 编译后的库文件
- `out/`: 输出可执行文件

## Cursor 规则

位于 `.cursor/rules.general.mdc`：
- **Git 提交**: 必须使用中文
- **测试代码**: 异常测试必须用 `FAFAFA_COLLECTIONS_ANONYMOUS_REFERENCES` 条件宏包裹并使用 `AssertException`（请查看函数的 `@Exceptions` 部分）

## 重要文档

### 开发工作流

1. **修复工作流**:
   - 从 `ISSUE_TRACKER.csv` 选择问题
   - 阅读代码了解问题区域
   - 编写失败的测试用例（TDD 方法）
   - 实施修复
   - 运行测试确保全部通过
   - 创建修复报告（参见 `ISSUE_*_FIX_REPORT.md` 格式）
   - 提交合并

2. **测试要求**:
   - 每个修复必须有对应的测试用例
   - 提交前运行快速回归测试
   - 每日或发布前运行全量回归测试
   - 使用 HeapTrc 进行内存泄漏检测

### 最佳实践

1. **编码风格**:
   - 每个 `.pas` 文件必须以 `{$mode objfpc}` 开头
   - 对边界情况使用饱和策略（性能优先于异常）
   - 用 `// ✅` 标记修复点，便于后续审查
   - 保持向后兼容性

2. **测试策略**:
   - 边界测试: Low(Int64)、High(Int64)、0、-1
   - 并发测试: Timer/Clock 模块需要多线程压力测试
   - 回归测试: 每次修复后运行完整测试套件
   - 内存测试: 使用 HeapTrc 检测泄漏

3. **常见陷阱**:
   - Low(Int64) 取反溢出（已修复 - 参见 ISSUE-3）
   - RefCount 竞态条件（已修复 - 参见 ISSUE-6）
   - 编译时常量折叠: 除零测试使用运行时表达式
   - 锁顺序: 避免死锁，保持一致的获取顺序

## 关键资源

### 文档索引
- `docs/INDEX.md` - 主要文档索引
- `docs/README.md` - 通用项目文档
- `docs/TESTING.md` - 测试指南
- `docs/Architecture.md` - 架构详情
- `docs/QUICK_REFERENCE.md` - 快速命令参考

### 模块特定文档
- `docs/fafafa.core.collections.vec.md` - Vec 集合指南
- `docs/fafafa.core.json.md` - JSON 模块文档
- `docs/fafafa.core.crypto.aead.md` - 密码学指南
- `docs/fafafa.core.mem.md` - 内存管理指南

### 问题追踪
- `ISSUE_TRACKER.csv` - 完整问题列表（48+ 个问题）
- `ISSUE_BOARD.md` - 可视化问题看板
- `ISSUE_*_FIX_REPORT.md` - 单独修复报告

### 工作上下文
- `WORKING.md` - 当前工作状态和进度
- `WORK_SUMMARY_2025-10-02.md` - 每日工作总结

### 性能基准
- `benchmarks/` - 性能测试套件
- `docs/fafafa.core.benchmark.md` - 基准框架指南

## 常见任务

### 添加新测试

1. 在适当的 `tests/` 子目录中创建测试文件
2. 遵循命名约定: `Test_<module_name>_<feature>.pas`
3. 如果需要，添加到模块的 `BuildOrTest.bat/sh` 脚本
4. 运行: `fpc -O3 -Fi./src -Fu./src -oTestExecutable test_file.pas`

**使用完整路径**:
```bash
/home/dtamade/freePascal/fpc -O3 -Fi./src -Fu./src -oTestExecutable test_file.pas
```

### 运行内存泄漏检测

```bash
# 使用堆跟踪编译测试
fpc -gh -gl -B -Fu./src -Fi./src -oTestLeak test_hashmap_leak.pas

# 运行测试
./TestLeak

# 预期输出: "0 unfreed memory blocks"
# 完整报告位于: tests/HASHMAP_HEAPTRC_REPORT.md

# 使用完整路径编译
/home/dtamade/freePascal/fpc -gh -gl -B -Fu./src -Fi./src -oTestLeak test_hashmap_leak.pas
```

### 构建特定模块

```bash
# 示例: 构建集合模块
fpc -O3 -Fi./src -Fu./src -FElib src/fafafa.core.collections.vec.pas
fpc -O3 -Fi./src -Fu./src -FElib src/fafafa.core.collections.vecdeque.pas

# 构建密码学模块
fpc -O3 -Fi./src -Fu./src -FElib src/fafafa.core.crypto.aead.pas
fpc -O3 -Fi./src -Fu./src -FElib src/fafafa.core.crypto.hash.sha256.pas

# 使用完整路径
/home/dtamade/freePascal/fpc -O3 -Fi./src -Fu./src -FElib src/fafafa.core.collections.vec.pas
```

### 调试失败的测试

1. 检查测试汇总: `tests/run_all_tests_summary.txt`
2. 查看详细日志: `tests/_run_all_logs/<module>.log`
3. 重新运行单个模块: `tests/<module>/BuildOrTest.bat`
4. 检查测试输出中的特定失败消息

**使用 Lazarus 构建**:
```bash
# 如果测试项目是 .lpi 文件
/home/dtamade/freePascal/lazbuild tests/fafafa.core.collections.arr/TestProject.lpi --quiet

# 运行编译后的可执行文件
./tests/fafafa.core.collections.arr/TestProject
```

## 项目状态

- **P0 级 Bug**: 0（所有关键 bug 已修复）
- **P1 级 Bug**: 23（正在积极处理）
- **P2 级 Bug**: 12
- **P3 级 Bug**: 6
- **测试覆盖**: 110+ 个测试用例，目标 150+
- **内存安全**: HashMap 已验证（0 泄漏），其他集合正在验证中

## 性能亮点

- SPSC 无锁队列: **125M ops/sec**
- MPSC 无锁队列: **31.7M ops/sec**
- 使用 SIMD 优化（SSE、AVX、AVX2、AVX-512、NEON）
- 关键操作中的零分配热路径

## 平台支持

- **Windows**: 完全支持（build.bat、.bat 脚本）
- **Linux**: 完全支持（clean.sh、.sh 脚本）
- **macOS**: 完全支持（bash 脚本）
- **跨平台**: 所有核心模块均跨平台兼容

---

**注意**: 此库优先考虑性能和内存安全。在进行更改时，始终使用 HeapTrc 验证内存安全并保持 100% 的测试通过率。

---

# AI 开发协作规范

以下规范用于指导 AI 助手（Claude、Cursor 等）与人类开发者的协作流程。

## AI 报告管理规范

### 报告分类与存放位置

| 报告类型 | 存放目录 | 命名约定 |
|----------|----------|----------|
| 工作日志 | `archive/reports/working/` | `WORKING.md`（单一文件，持续更新） |
| 代码审查 | `archive/reports/code-reviews/` | `CODE_REVIEW_{MODULE}_{DATE}.md` |
| 问题修复 | `archive/reports/issues/` | `ISSUE_{ID}_FIX_REPORT.md` |
| 阶段总结 | `archive/reports/summaries/` | `{MODULE}_SUMMARY_{DATE}.md` |

### 报告生命周期

1. **创建**：在 `archive/reports/` 对应子目录创建，禁止在根目录创建
2. **更新**：工作进行中持续更新
3. **归档**：任务完成后保留在 archive 目录
4. **清理**：超过 6 个月的报告可压缩归档

### 禁止行为

- ❌ 在根目录创建报告文件（如 `CODE_REVIEW_*.md`、`*_REPORT.md`）
- ❌ 创建重复的报告文件
- ❌ 使用模糊的文件名（如 `temp.md`、`notes.md`、`working.md`）
- ❌ 创建空文件或占位文件

## AI 工作上下文交接

### 工作状态文件

维护单一的 `archive/reports/working/WORKING.md` 文件，格式如下：

```markdown
# 当前工作状态

## 最后更新
- 时间：YYYY-MM-DD HH:MM
- 会话：[简述当前任务]

## 进行中的任务
- [ ] 任务 1：描述 + 当前进度
- [ ] 任务 2：描述 + 当前进度

## 已完成的工作
- [x] 任务 A：简述完成内容
- [x] 任务 B：简述完成内容

## 已知问题
- 问题 1：描述 + 优先级 (P0/P1/P2)
- 问题 2：描述 + 优先级

## 下一步行动
1. 具体步骤 1
2. 具体步骤 2

## 关键文件
- `src/xxx.pas` - 修改原因
- `tests/xxx/` - 测试状态
```

### 会话开始检查清单

1. 阅读 `archive/reports/working/WORKING.md` 了解当前状态
2. 检查 `ISSUE_TRACKER.csv` 了解问题状态
3. 运行快速回归测试确认基线
4. 继续未完成的任务或开始新任务

### 会话结束检查清单

1. 更新 `WORKING.md` 记录当前状态
2. 确保所有测试通过
3. 记录已知问题和下一步行动
4. 如有重要变更，更新相关文档

## AI 代码审查清单

### 提交前必检项

- [ ] **编译通过**：`fpc -O3 -Fi./src -Fu./src <file>`
- [ ] **测试通过**：运行相关模块测试
- [ ] **内存安全**：HeapTrc 检测无泄漏
- [ ] **代码风格**：遵循 `{$mode objfpc}` 规范

### 功能正确性

- [ ] 逻辑符合需求描述
- [ ] 边界情况处理（Low/High/0/-1）
- [ ] 错误处理完整
- [ ] 线程安全（如适用）

### 代码质量

- [ ] 命名规范遵循项目约定
- [ ] 注释充分（公共 API 必须有文档注释）
- [ ] 复杂度合理（函数不超过 50 行）
- [ ] 无重复代码

### 性能考量

- [ ] 无不必要的内存分配
- [ ] 热路径优化
- [ ] 性能基准对比（如适用）

### 审查标记约定

- 使用 `// ✅` 标记修复点
- 使用 `// TODO:` 标记待办事项
- 使用 `// FIXME:` 标记已知问题
- 使用 `// HACK:` 标记临时解决方案

## 任务完成度标准

### 完成度级别

| 级别 | 百分比 | 标准 |
|------|--------|------|
| 骨架 | 20% | 代码结构完成，编译通过 |
| 基本 | 50% | 核心功能实现，基础测试通过 |
| 完整 | 80% | 所有功能实现，全量测试通过，文档完成 |
| 生产就绪 | 100% | 代码审查通过，性能基准验证，内存安全验证 |

### 任务状态标记

在 `ISSUE_TRACKER.csv` 中使用以下状态：

| 状态 | 含义 |
|------|------|
| `TODO` | 待开始 |
| `IN_PROGRESS` | 进行中（标注完成度百分比） |
| `REVIEW` | 待审查 |
| `DONE` | 已完成 |
| `BLOCKED` | 被阻塞（标注原因） |

### 完成确认流程

1. **自检**：对照代码审查清单
2. **测试**：运行相关测试套件
3. **内存**：HeapTrc 验证无泄漏
4. **文档**：更新相关文档
5. **记录**：更新 `WORKING.md` 和 `ISSUE_TRACKER.csv`
