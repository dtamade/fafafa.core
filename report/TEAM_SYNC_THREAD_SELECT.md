# 团队同步｜线程模块 Select 默认“非轮询”切换

## 背景与目标
- 将 Select 从“轮询 + 短 WaitFor”升级为“非轮询（OnComplete 回调聚合）”，降低忙等、提升响应
- 默认在“编译器支持匿名引用”前提下启用；保留宏一键回退，确保可控和跨平台稳定

## 默认行为与回退
- 默认：支持匿名引用时启用非轮询 Select（OnComplete 回调聚合）
- 回退：构建时定义 FAFAFA_THREAD_SELECT_FORCE_POLLING 可强制回到“轮询 + 短 WaitFor”
- 兼容：不支持匿名引用的平台/编译器自动维持轮询（与历史一致）

## 质量与验证
- 线程模块全量测试：N=83 E=0 F=0
- 内存：heaptrc 未见泄漏（0 未释放块）
- 条件编译：已修复不同宏组合下的局部变量声明，避免编译错误

## CI 与 Bench（概览）
- 并行验证：Thread Select (Non-Polling, Macro)
  - Windows/Linux 并行构建与测试；上传 JUnit 报告（tests.junit.xml）
- 手动基准：Thread Select Bench (Manual)
  - 输出 bench_summary（MD/CSV）与图表（PNG），并聚合趋势（trend.md/csv）
- 每周趋势：Thread Select Bench (Scheduled)
  - 每周跑一次；自动生成趋势图与“Weekly Thread Select Bench Report” issue
- 每月发布：Bench Monthly Release (Auto)
  - 每月生成 bench-monthly-YYYYMM 预发布；上传图表/汇总并自动更新文档链接到该 tag
- 安全：所有重型/敏感工作流仅在 upstream 仓库执行（已加 owner 守卫与并发控制）

## 发布与文档固定链接（最佳实践）
1) 触发基准（手动）：Actions → Thread Select Bench (Manual)
2) 打包发布（手动）：Actions → Release Bundle (Bench Artifacts)（输入 tag，如 vX.Y.Z）
3) 固定链接：Actions → Update Docs with Release Asset Links（输入相同 tag）
4) 每周观察：查看自动生成的 “Weekly Thread Select Bench Report” issue

## 操作指南（Step-by-step）
- 本地测试：tests\\fafafa.core.thread\\BuildOrTest.bat test
- 示例：examples\\fafafa.core.thread\\BuildOrRun.bat run
- 基准：examples\\fafafa.core.thread\\bin\\example_thread_select_bench.exe 200
- CI 工作流入口：GitHub Actions（见“关键工作流/脚本”）

## 观察与决策建议
- 建议连续两周（≥10 次）观察 NonPolling vs Polling 的 Delta%（越低越好）
- 若 NonPolling 平均提升 ≥10% 且波动稳定：维持默认
- 若个别平台退化或波动大：在该平台构建注入 -dFAFAFA_THREAD_SELECT_FORCE_POLLING 临时回退

## 文档入口
- docs/fafafa.core.thread.md
  - “Select 行为切换与宏”“基准测试与结果解读”“图表固定链接建议”
- report/fafafa.core.thread.md
  - “默认行为更新（Select）”
- report/fafafa.core.thread.select-plan.md
  - 验证计划（目标/策略/验收/回退）
- README.md
  - CI 指南（工作流与产物说明）
- CONTRIBUTING.md
  - Release Checklist（发布与文档固定链接步骤）

## 关键工作流/脚本
- .github/workflows/thread-select-nonpolling.yml
- .github/workflows/thread-select-bench.yml
- .github/workflows/thread-select-bench-scheduled.yml
- .github/workflows/bench-monthly-release.yml
- .github/workflows/release-bundle.yml
- .github/workflows/update-docs-release-links.yml
- scripts/aggregate_select_bench.sh
- scripts/plot_select_bench.py
- scripts/update_docs_release_links.py

## 宏与设置（参考）
- 默认切换宏：未定义 FAFAFA_THREAD_SELECT_FORCE_POLLING 时，自动定义 FAFAFA_THREAD_SELECT_NONPOLLING（匿名引用可用时生效）
- 回退宏：FAFAFA_THREAD_SELECT_FORCE_POLLING 强制使用轮询实现

## 版本与合并建议
- 版本：建议 minor 升级
- PR 说明：包含默认切换、回退宏、CI/Bench、文档更新与测试结果
- 门禁：Windows/Linux 默认测试（非轮询）、非轮询并行验证通过；Bench 可保留手动，不设为必过

## 问题反馈
- 请在新建 issue 时带上标签：performance, bench, thread-select
- 如定位到平台差异或兼容问题，可先用回退宏快速规避，再补充信息复现

