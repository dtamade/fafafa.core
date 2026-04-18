# Changelog: fafafa.core.mem

## 2025-08-09
- 收敛门面职责：仅 mem.utils + mem.allocator + 基础池；不再从门面导出 enhanced*/objectPool/ringBuffer/memoryMap/mapped*。
- 禁用 IAllocator：门面不导出接口，示例与测试统一使用 TAllocator；TCallbackAllocator 统一 Init。
- 测试工程规范化：tests_mem.lpr 移除 helper/memoryMap/增强依赖，仅保留 FPCUnit 单元；Debug + -gh -gl 构建通过。
- 文档收口：docs/fafafa.core.mem.md 改为 TAllocator 用法；新增“模块边界与依赖说明”。
- 迁移规划：tests 下非单测示例与实验迁移至 examples/ 与 play/；下一步继续执行并验证。

