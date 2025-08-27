# fafafa.core.mem 模块 — 本轮工作总结报告

## 进度与已完成项
- 现状梳理：确认 `src/fafafa.core.mem.*` 模块与完整测试、示例、文档均已就位，接口与门面职责清晰
- 单测修复+验证（Windows/x86_64）：
  - 修复 `tests/fafafa.core.mem/test_mem_utils.pas` 文件末尾游离断言引发的语法错误（封装为 `Test_AlignAndCopy_Exceptions`）
  - 对齐行为一致化：在 `src/fafafa.core.mem.utils.pas` 的 `AlignUp/AlignDown` 补充“非 2 的幂”抛 `EInvalidArgument`
  - 执行 `tests/fafafa.core.mem/BuildAndTest.bat` 全量跑通
  - 结果：Number of run tests: 126; Errors: 0; Failures: 0；heaptrc 0 泄漏

## 问题与解决方案
- 问题：主测试单元末尾存在第二个 `implementation` 关键字，编译器报语法错误
  - 方案：删除重复的 `implementation` 标记
- 问题：`AssertException(EArgumentNil, ...)` 无法解析类型标识
  - 方案：引用命名空间 `fafafa.core.base` 并使用 `EArgumentNil`（或全名）
- 问题：初始化区出现两段 `initialization`，且报错定位在注册行
  - 方案：合并到一段 `initialization` 内连续注册 `RegisterTest(...)`

## 现状评估
- 门面 `fafafa.core.mem` 已聚合：内存操作（utils）、分配器（allocator）、三类核心池（Mem/Stack/Slab）
- 本轮补齐：门面新增重导出 AlignDown/AlignDownUnChecked（与 utils 对齐，零行为变更），并补 1 条门面用例验证
- 高级/增强功能已拆分为独立单元（objectPool、ringBuffer、enhanced*、mapped*），未被门面导出，职责边界合理
- 宏配置集中于 `src/fafafa.core.settings.inc`，支持 CRT memcpy/memmove 可选开关与 inline 开关
- 文档与示例较完整：有架构、使用、目录结构说明与示例工程

## 后续计划（下一轮）
1) API/异常一致性与边界测试补强
   - 对齐非 2 的幂应抛 `EInvalidArgument`（已覆盖）
   - 超大尺寸导致运算溢出抛 `EOutOfRange` 的覆盖率补强（Copy/Compare/IsOverlap 等）
2) 性能回归基线
   - 基于现有 examples/benchmark 与 slabPool 性能测试用例，固化一组“快速/完整”基线
   - 结合设置宏（CRT 后端、INLINE）在 Win/Linux 下采样
3) 对齐分配最小封装（提案，待确认）
   - 新增 `fafafa.core.mem.aligned`（AllocAligned/FreeAligned）作为独立单元；Windows 走 _aligned_malloc/_aligned_free，Unix 走 posix_memalign，否则回退 over-allocate
   - 门面可暂不导出，先以文档与示例引导
4) 文档微调
   - 在 `docs/fafafa.core.mem.md` 增加“门面导出范围”“对齐操作/对齐分配建议”与“平台差异”示例

## 建议
- 保持“门面导出三件套（Mem/Stack/Slab）”的收敛策略；高级功能按需独立 `uses`
- 默认关闭 CRT 内存后端于 Windows，仅在 Linux/特定场景下开启并记录基线差异
- 所有内存 API 明确 size=0 的幂等行为（当前实现为空操作/返回 nil），并在使用文档显式强调



## 2025-08-24 本轮增量
- 新增模块：src/fafafa.core.mem.pool.fixed.pas（固定块内存池，参考 objectPool 接口范式，统一实现 IPool: Acquire/Release/Reset）
- 接口一致性：对齐 allocator 门面，统一使用 IAllocator（默认 GetRtlAllocator）；移除历史 TAllocator 依赖
- 功能特性：
  - 预分配固定块，O(1) Acquire（自由栈）/O(1) Release（已实现，当前通过线性索引定位；下一轮优化为 O(1) 反查）
  - Reset 重建自由栈；Free(nil) no-op；双重释放检测
- 风险与计划：Release 目前通过线性查找块索引，最坏 O(n)，下一轮引入“侵入式索引/连续 Arena + 指针到索引映射”实现 O(1)


## 2025-08-24 增量小结（Allocator 门面健壮性）
- 变更：将 mimalloc 相关导出置于编译宏 FAFAFA_CORE_MIMALLOC_ALLOCATOR 下（默认关闭）
  - 调整位置：src/fafafa.core.mem.allocator.pas 中的 uses/type/函数声明与实现
  - 目的：避免默认构建对 mimalloc 动态库的隐式依赖；按需开启、可控交付
  - 兼容性：测试工程未纳入 mimalloc 用例（test_mimalloc_smoke.pas 未加入 .lpi），因此无破坏
- 问题与原因：
  - 在未提供 mimalloc.dll 的环境中，门面默认导出 GetMimallocAllocator 可能引发链接/运行期问题
  - 解决：将导出与 uses 条件化；由唯一配置文件 src/fafafa.core.settings.inc 控制
- 后续建议：
  1) 新增可选“全局内存管理器安装器”单元（manager.mimalloc），基于 FPC TMemoryManager/SetMemoryManager 封装 mi_malloc 系列
     - 风险提示：与 heaptrc 不兼容；需在 uses 表首位初始化
  2) 为启用宏情形补充冒烟测试（按需加入 LPI）：test_mimalloc_smoke.pas
  3) 示例补充：动态库缺失时的降级与报错指引


- 新增可选单元：src/fafafa.core.mem.manager.mimalloc.pas
  - 提供 InstallMimallocMemoryManager/UninstallMimallocMemoryManager/IsMimallocMemoryManagerInstalled
  - 基于 FPC TMemoryManager 封装 mi_malloc/calloc/realloc/free（在用户指针前写入 size 以支持 MemSize/FreeMemSize 校验）
  - 仅在 FAFAFA_CORE_MIMALLOC_ALLOCATOR 定义时参与编译
  - 明确与 heaptrc 不兼容，需在 uses 首位初始化
- 新增测试：tests/fafafa.core.mem/test_mimalloc_manager_optional_smoke.pas（未加入 .lpi，按需启用）


## Plays 验证与使用（内存管理器安装器 Smoke）

- 目的：在不启用 heaptrc 的前提下，独立进程内安装/卸载全局内存管理器并做一次 GetMem/ReAllocMem/FreeMem 验证；用于快速烟囱检查，不替代单元测试
- 位置与一键脚本：
  - RTL：plays/fafafa.core.mem.manager.rtl/buildOrRun.bat
  - CRT：plays/fafafa.core.mem.manager.crt/buildOrRun.bat
  - mimalloc：plays/fafafa.core.mem.manager.mimalloc/buildOrRun.bat
- 运行方式：直接双击或在仓库根执行相对路径脚本；脚本会用 lazbuild Debug 构建后运行对应 exe

- 成功/失败反馈（统一约定）：
  - 成功：打印 “... manager play OK”，退出码 0
  - 失败：打印 “... play failed: <异常>”，退出码 100（分配失败时可能为 1/2）
  - 宏未启用（CRT/mimalloc）：打印 “... allocator macro disabled”，退出码 0
  - 脚本会将退出码原样返回到 shell

- 重要注意：
  - 与 heaptrc 互斥：安装器会替换全局 MemoryManager；plays 不启用 heaptrc；tests 保持 heaptrc 打开、且不调用安装器
  - 宏开关：
    - mimalloc：FAFAFA_CORE_MIMALLOC_ALLOCATOR（src/fafafa.core.settings.inc）
    - CRT：FAFAFA_CORE_CRT_ALLOCATOR（src/fafafa.core.settings.inc）
  - mimalloc DLL 放置（Windows）：需要 mimalloc.dll（或 mimalloc-redirect.dll）在可执行同目录；脚本会尝试从 tmp_build\mimalloc.dll 复制到 bin
  - 静态链接（可选）：FPC 仅支持 MinGW 生成的 import lib（如 libmimalloc.dll.a）；需提供 -Fl 搜索目录并启用 {$DEFINE FAFAFA_CORE_MIMALLOC_STATIC}，推荐默认使用延迟加载方案
