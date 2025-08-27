# fafafa.core.mem 模块 — 开发计划日志

## 本轮完成
- 修复 `test_mem_utils` 语法错误（游离断言），封装为 `Test_AlignAndCopy_Exceptions`
- 对齐实现与文档一致化：`AlignUp/AlignDown` 遇到非 2 的幂对齐抛 `EInvalidArgument`
- 跑通 `tests/fafafa.core.mem/BuildAndTest.bat`：Number of run tests: 126; Errors: 0; Failures: 0；0 泄漏

## 下一步可执行计划
1. 对齐分配最小封装（需确认）
   - 新增独立单元 `fafafa.core.mem.aligned`（AllocAligned/FreeAligned），平台优先走原生 API；回退 over-allocate
   - 少量冒烟测试（Windows + Linux 各 1 例），不纳入门面
2. 边界与异常测试补强（紧随其后）
   - 继续补强超大尺寸溢出路径（Copy/Compare/IsOverlap 等）
3. 文档对齐
   - 在 `docs/fafafa.core.mem.md` 增加对齐建议与平台差异说明

## 里程碑
- M1：异常/边界覆盖 > 95%，所有用例稳定通过
- M2：性能基线首版落地（对比报告入 `report/latest/`）
- M3：接口优先示例完善，examples 可一键构建运行

## 依赖与风险
- Windows CRT 内存后端不稳定的性能表现；需以 Linux 为主做对比
- CI 集成尚未统一，JUnit 输出接口需要后续在 test runner 层汇总

