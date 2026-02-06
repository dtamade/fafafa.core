# Backlog: fafafa.core 长期迭代维护

> 目标：把“长期维护工作”可视化、可迭代、可回溯。  
> 规则：每轮迭代只做 1–3 个条目；其余留在 backlog（避免 WIP 过多）。

## 工作方式（planning-with-files）
- 选题：从本 backlog 选 1–3 项 → 写入仓库根的 `task_plan.md`
- 过程：发现/结论 → `findings.md`；命令/输出/测试结果 → `progress.md`
- 收尾：将三文件归档到 `plans/archive/YYYY-MM-DD-<topic>/`，并在本条目下补归档链接

## Now（进行中）
- [ ] **P0 / tests**：确认并收敛 `run_all_tests` Runner 改进（过滤命中、0 命中失败、避免交互阻塞、Windows/Linus 一致）  
  参考：`docs/plans/2026-02-06-run-all-tests-runner-design.md`、`docs/plans/2026-02-06-run-all-tests-runner.md`
- [ ] **P0 / quality**：维持并扩展 “0 warnings/hints” 洁净构建覆盖面（至少 FS + SIMD）  
  参考：`docs/plans/2026-02-06-zero-warnings-hints-fs-simd-design.md`、`docs/plans/2026-02-06-zero-warnings-hints-fs-simd.md`

## Next（下一步）
- [ ] **P0 / sync**：继续 Layer1 验证：修复 `Condvar` / `Barrier` / `Once` / `Spin` 并补回归  
  参考：`WORKING.md`
- [ ] **P1 / repo**：梳理并最小化“运行产物进入版本库”的风险（例如已跟踪的 logs/reports）  
  说明：需要先评估哪些文件应该 `git rm --cached` + `.gitignore` 管控（避免误删有效基准数据）。

## Icebox（低优先级 / 待定）
- [ ] 维护文档与示例（按模块补齐最小可运行 example 与对应测试）
- [ ] CI 结构化输出（JUnit/JSON）统一化与稳定路径约定落地

## Done（已完成）
- （把每轮迭代归档链接追加在这里）

