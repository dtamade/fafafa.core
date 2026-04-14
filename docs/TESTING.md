## 测试执行指南（Windows bat / Linux/macOS sh）

本仓库的各子模块在 tests/ 目录下提供独立的测试脚本。为提高可见性与一致性，新增了统一的“全仓测试”脚本，分别适配 Windows 与 Linux/macOS：

- Windows（批处理）：tests/run_all_tests.bat
- Linux/macOS（Shell）：tests/run_all_tests.sh

它们会递归扫描子模块测试脚本并执行，输出各模块日志与最终汇总。

从本轮开始，`run_all_tests.{sh,bat}` 在真正执行模块测试前，还会先做一次 `src/` 源码树 hygiene preflight：

- Linux/macOS：`bash tests/check_repo_hygiene.sh`
- Windows：`tests\check_repo_hygiene.bat`

如果 `src/` 下残留 `.o`、`.ppu`、`.bak` 一类编译/备份产物，统一入口会先失败，避免把生成物噪音带进后续审查和搜索。

---

### 先决条件

- Windows：
  - 安装并能通过命令行调用的 Lazarus/FPC（lazbuild/fpc 在 PATH 上，或通过 tests/tools/lazbuild.bat 间接调用）
  - 适配的目标工具链（x86_64-win64 等），与项目各 tests/\*.lpi 配置一致
- Linux/macOS：
  - 可执行的 sh/bash 环境
  - 对应平台的 FPC/Lazarus 工具链（若运行依赖 .sh 的子模块）

提示：部分测试运行时间较长或涉及 I/O，请在本地机器先用“关键模块”快速回归，再做全量。

---

### strict L0 的 Windows runtime 复核

如果你是在 Linux x64 上做 strict non-SIMD L0 的日常维护，默认不要手工拼命令，直接从下面这个单入口开始：

```bash
bash tests/run_strict_l0_maintenance_loop.sh
```

这个入口会固定串起：

1. `bash tests/check_strict_l0_docs_consistency.sh`
2. strict L0 聚合 gate
3. `git diff --check`
4. `bash tests/test_windows_strict_l0_batch_runtime_matrix.sh`
5. `bash tests/test_windows_strict_l0_native_closeout_stack.sh`

只有当 strict L0 发生非文档代码/测试变化，或者有人明确要求 exact `HEAD` / merge commit 证据时，才继续走 GitHub Actions Windows native evidence 主路径。

如果当前目标不是日常维护，而是 mainline closeout，一次性把 Linux maintenance、Windows exact evidence 和 current-state docs 串起来，当前单入口是：

```bash
bash tests/run_strict_l0_mainline_closeout.sh
```

只打印 closeout 命令链：

```bash
bash tests/run_strict_l0_mainline_closeout.sh --print-commands
```

完成收证后需要覆盖 current-state 审计、legacy closeout 和记工单 handoff 时：

```bash
bash tests/run_strict_l0_mainline_closeout.sh --apply-docs
```

如果你已经手头有 run id，只需要单独回填文档，也可以直接执行：

```bash
bash tests/update_strict_l0_current_state_docs.sh --apply --main-sha <main-sha> --linux-run-id <linux-run-id> --linux-run-sha <linux-run-sha> --windows-run-id <windows-run-id> --windows-run-sha <windows-run-sha> --windows-local-batch-id <batch-id>
```

如果你当前关心的不是 CI/evidence，而是“这 4 个残留历史 L0 refs 现在能不能删”，不要手工猜，先跑：

```bash
bash tests/audit_strict_l0_retained_refs.sh
```

这个脚本只做 non-destructive audit：它会基于 `merge-base` 和 `git cherry -v HEAD <ref>` 给出 `same-tip`、`retain-unique-history`、`candidate-delete` 之类的判定，但不会直接执行删除。

如果你当前关心的是“先吸收哪一类 retained history 最划算”，先跑：

```bash
bash tests/report_strict_l0_retained_refs_inventory.sh
```

这个脚本会把 4 条 retained refs 的 unique history 按 `archive docs`、`current docs`、`code/tests`、`examples/build` 分类，并给出 `absorb-archive-first`、`review-code-before-absorb` 之类的建议，方便先做低风险吸收。

如果你已经准备做下一波吸收，想先看代表性 unique commits 和路径样本，再跑：

```bash
bash tests/report_strict_l0_retained_refs_inventory.sh --details
```

这个模式会额外打印每条 retained ref 的 `sample_unique_commits=` 和各 bucket 的 representative path samples，方便快速判断这波应该先吸 docs、examples 还是先停在 code/test review。

第六波之后，`--details` 的 code/tests drift 会继续细分成：

- `sample_src_paths=`
- `sample_test_source_paths=`
- `sample_test_code_paths=`
- `sample_test_script_paths=`
- `sample_test_doc_paths=`
- `sample_test_runtime_record_paths=`
- `sample_test_control_paths=`
- `sample_ci_workflow_paths=`
- `sample_test_artifact_paths=`
- `sample_test_output_artifact_paths=`
- `sample_test_binary_artifact_paths=`

同时它还会直接给出：

- `next_focus=`

这样你可以先判断这条 retained ref 暴露出来的 `code_or_tests` 到底是：

- 真实还要 review 的 `src/` 差异
- 真实还要 review 的测试代码 / 测试脚本 / 测试 README
- 只是 runtime records（例如 `last-run.txt`、`performance-data/*.txt`）
- 只是 control files（例如 `.gitignore`）
- 只是 control-plane / workflow 变化
- 还是根本不该继续混回 today contract 的 output / binary test artifacts

第六波之后，`test_source_paths=` 也明确只统计真实 test source surface，不再把 runtime records 或 control files 混进去。

第五波之后，`--details` 的 examples/build drift 还会继续细分成：

- `sample_example_source_paths=`
- `sample_build_script_paths=`
- `sample_generated_output_paths=`
- `sample_test_artifact_paths=`

这样你可以先判断这条 retained ref 暴露出来的到底是：

- 还值得 review 的 example source
- 只是 current-entry 该补 README 的 build scripts
- 还是根本不该再混回 today contract 的生成产物 / 测试产物

`next_focus=` 的 today contract 目前固定为：

- `archive-docs-first`
- `test-hygiene-first`
- `source-review-first`
- `current-docs-first`

其中 `sidecar` / `tail` 这种仍然混着 archive docs 与 test residue 的 retained refs，当前会继续保留 `recommendation=` 的高层吸收建议，同时用 `next_focus=test-hygiene-first` 把下一跳 code/test triage 写死。

第七波之后，`--details` 的 docs residue 还会继续细分成：

- `sample_docs_root_entry_paths=`
- `sample_docs_module_paths=`
- `sample_docs_topic_paths=`
- `sample_docs_guide_paths=`
- `sample_docs_archive_pointer_paths=`
- `sample_docs_collections_dated_paths=`
- `sample_docs_legacy_paths=`
- `sample_docs_report_topic_paths=`
- `sample_docs_absorb_candidate_paths=`

这样你可以继续判断 retained refs 里暴露出来的 docs residue 到底是：

- 仍然活跃的 root/module/topic/guide current-entry
- 已经有稳定 landing zone 的 archive pointer
- 已经该回到 legacy 语境的 collections dated docs
- 已经落在 legacy 下的历史 L0 文档
- 还是仍然属于 live report topic 的主题文档

第七波之后，`docs_absorb_candidate_paths=` 的 today contract 固定为：

- archive pointers
- collections dated docs
- legacy docs

也就是说，`sidecar/tail` 在继续保持 `next_focus=test-hygiene-first` 的同时，它们后续最值得优先吸收的低风险 docs residue 也已经不是未知数了。

第八波之后，`--details` 还会继续给出：

- `test_hygiene_candidate_paths=`
- `sample_test_hygiene_candidate_paths=`
- `source_review_candidate_paths=`
- `sample_source_review_candidate_paths=`

这两个 bucket 的 today contract 固定为：

- `test_hygiene_candidate_paths=`
  - runtime records
  - control files
  - output artifacts
  - binary artifacts
- `source_review_candidate_paths=`
  - `src`
  - real test source
  - CI workflow
  - examples/build drift

这意味着 retained-refs triage 的 today 顺序进一步固定为：

1. 先看 `recommendation=`
2. 再看 `next_focus=`
3. 如果是 `test-hygiene-first`，优先看 `test_hygiene_candidate_paths=`
4. 如果是 `source-review-first`，优先看 `source_review_candidate_paths=`
5. docs residue 则继续看 `docs_absorb_candidate_paths=`
6. 最后再用对应 `sample_*` 看 representative paths

也就是说，`sidecar/tail` 的第一跳不再只是一个方向标签，而是已经有显式的 hygiene candidate surface；`closeout/rescue` 的 source-review-first 也不再需要人工把 `src` / test source / CI / examples-build 重新拼起来。

第九波之后，这批 hygiene surface 里已经有一段被真实吸收到主线：

- `tests/fafafa.core.archiver/last-run.txt`
- `tests/fafafa.core.atomic/tests_atomic`
- `tests/fafafa.core.atomic/atomic_heaptrc_full_output.txt`
- `tests/fafafa.core.sync.barrier/*_output.txt`
- `tests/fafafa.core.fs/performance-data/latest.txt`
- `tests/fafafa.core.fs/performance-data/perf_*latest.txt`
- 一批 dated perf snapshots

对应目录现在已有局部 `.gitignore`，这些 runtime/output/binary residue 不再应该被重新跟踪。

如果你当前遇到的是 `next_focus=source-review-first`，除了 inventory 之外，继续使用：

```bash
bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh
```

这条命令会继续显式输出：

- `review_candidate_paths=`
- `src_review_paths=`
- `test_code_review_paths=`
- `test_script_review_paths=`
- `test_doc_review_paths=`
- `ci_review_paths=`
- `examples_build_review_paths=`
- `simd_out_of_scope_paths=`
- `dangerous_delete_paths=`
- `reject_wholesale_absorb=`

也就是说，第九波之后的 retained-refs triage 进一步固定为：

1. inventory `--details` 负责看方向与 candidate surface
2. `test-hygiene-first` 先吃真实 hygiene residue
3. `source-review-first` 立刻跑 shortlist
4. 只要看到 `dangerous_delete_paths>0` 或 `reject_wholesale_absorb=yes`，就拒绝整包吸收
5. `simd_out_of_scope_paths=` 则继续交回 SIMD owner，而不是混进 L0 波次

第十波之后，`closeout` 里那 6 个 `test_doc_review_paths=` 也已经完成一次 fresh 人工复核：它们不是应当吸收到主线的补强内容，而是会反向删掉 current-entry 里已经建立好的 maintenance / exact-evidence 说明。因此当前增加了一个显式 no-downgrade 护栏：

```bash
bash tests/test_strict_l0_retained_refs_closeout_test_docs_no_downgrade_contract.sh
```

这条 contract 的 today 语义固定为：

- `tests/fafafa.core.atomic/README.md` 继续把 heaptrc / logs 视为本地运行期产物，而不是 tracked 支持材料
- `tests/fafafa.core.endian/README.md`
- `tests/fafafa.core.layout/README.md`
- `tests/fafafa.core.mem.allocator.foundation/README.md`
- `tests/fafafa.core.platform/README.md`
- `tests/fafafa.core.span/README.md`

都必须继续保留：

- Linux x64 strict L0 日常维护入口：`bash tests/run_strict_l0_maintenance_loop.sh`
- exact Windows native evidence 只接受 GitHub Actions 或真实 Windows runner

第 2026-04-14 波之后，`sidecar/tail` 还新增了一条 post-merge pairwise overlap 入口：

```bash
bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh
```

这条命令的 today contract 是：

- 它不替代 inventory，也不替代 `closeout/rescue` 的 shortlist
- 它只回答 `sidecar/tail` 这两条 ref 在 merged-main 之后：
  - shared merge-base 是什么
  - 各自还剩多少 exclusive commits
  - 各自 exclusive paths 更像 docs / src / test code / runner 还是 worker/control-plane
  - `sidecar_safe_delete_now=` / `tail_safe_delete_now=` 当前是否为 `yes`

它会继续显式输出：

- `sidecar_tail_merge_base=`
- `sidecar_only_commit_count=`
- `tail_only_commit_count=`
- `sidecar_safe_delete_now=`
- `tail_safe_delete_now=`
- `pairwise_decision=`
- `pairwise_cleanup_readiness=`

也就是说，第 2026-04-14 波之后：

1. `bash tests/report_strict_l0_retained_refs_inventory.sh --details` 继续负责 absorb class / candidate surface
2. `bash tests/report_strict_l0_retained_refs_source_review_shortlist.sh` 继续只处理 `closeout/rescue`
3. `bash tests/report_strict_l0_retained_refs_sidecar_tail_overlap.sh` 继续只处理 `sidecar/tail` 的 post-merge delete readiness / exclusive batch 判断

同时，这一波又真实吸掉了一小段 sidecar hygiene residue，并通过下面这条 contract 锁住：

```bash
bash tests/test_strict_l0_retained_refs_sidecar_hygiene_contract.sh
```

它当前固定验证：

- `tests/fafafa.core.env/.gitignore`
- `tests/fafafa.core.mem.manager.rtl/.gitignore`
- `tests/fafafa.core.env/build_log.txt`
- `tests/fafafa.core.env/fpcdebug.txt`
- `tests/fafafa.core.mem.manager.rtl/mem_manager_heaptrc_output.txt`

已经不再属于主线 tracked surface。

如果你当前关心的是 strict non-SIMD L0 在 Windows 路径上的复核，不要直接从“原生 `.bat` 构建完全对称”这个前提出发。当前仓库已经分成四条不同的复核链路：

- 最小 Win64 `.exe` runtime smoke
  - Linux/macOS：`bash tests/test_windows_strict_l0_wine_smoke.sh`
- 最小 `.bat` runtime-only smoke
  - Linux/macOS：`bash tests/test_windows_strict_l0_batch_runtime_smoke.sh`
- 扩展 `.bat` runtime-only parity matrix
  - Linux/macOS：`bash tests/test_windows_strict_l0_batch_runtime_matrix.sh`
- native Windows `.bat` build-path parity matrix
  - Windows：`tests\test_windows_strict_l0_batch_native_matrix.bat`
  - Windows evidence collector：`tests\collect_windows_strict_l0_native_evidence.bat`
  - Windows evidence verifier：`tests\verify_windows_strict_l0_native_evidence.bat tests\_windows_l0_native_evidence\<batch-id>`
  - Linux/macOS artifact verifier：`bash tests/verify_windows_strict_l0_native_evidence.sh [snapshot-root] [expected-commit] [expected-ref]`
  - Linux/macOS GH preflight：`bash tests/preflight_windows_strict_l0_native_evidence_gh.sh`
  - Linux/macOS GH helper：`bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh [batch-id] [run-id]`
  - Linux/macOS CI enablement helper：`bash tests/print_windows_strict_l0_native_ci_enablement_3cmd.sh [batch-id]`
  - Linux/macOS 复制即跑 helper：`bash tests/print_windows_strict_l0_native_closeout_3cmd.sh [batch-id]`
  - Linux/macOS aggregate closeout stack：`bash tests/test_windows_strict_l0_native_closeout_stack.sh`

当前建议顺序：

1. 先跑 `bash tests/run_strict_l0_maintenance_loop.sh`
2. 如果要做 `main` 上的一波 closeout，再跑 `bash tests/run_strict_l0_mainline_closeout.sh`
3. 如果只想拆开看 Windows runtime 复核，再跑 `bash tests/test_windows_strict_l0_wine_smoke.sh`
4. 再跑 `bash tests/test_windows_strict_l0_batch_runtime_smoke.sh`
5. 最后跑 `bash tests/test_windows_strict_l0_batch_runtime_matrix.sh`
6. 如果要补齐最终 Windows build-path 证据，再到专用 Windows 主机执行 `tests\test_windows_strict_l0_batch_native_matrix.bat`
7. 如果要把 dedicated-host 结果收成标准 artifact，再执行 `tests\collect_windows_strict_l0_native_evidence.bat`
8. 如果要从 Linux/macOS 触发或复用 GitHub Actions Windows run，再执行 `bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh`
9. 如果 workflow 还没注册到 default branch，先执行 `bash tests/print_windows_strict_l0_native_ci_enablement_3cmd.sh`
10. 如果你只想先拿到 today source-of-truth 的复制即跑命令，再执行 `bash tests/print_windows_strict_l0_native_closeout_3cmd.sh`
11. 如果要一次性复核当前本地所有 native evidence 契约与 GH preflight 状态，再执行 `bash tests/test_windows_strict_l0_native_closeout_stack.sh`

如果你要在 GitHub Actions 上重复这条 Linux x64 维护回路，当前 manual/reusable workflow 是：

- `.github/workflows/l0-linux-maintenance.yml`

这三条链路解决的是不同问题：

- `wine_smoke`
  - 确认最小 strict L0 Win64 `.exe` 能交叉构建并在 `wine` 下运行
- `batch_runtime_smoke`
  - 确认最早暴露差异的 4 个 `.bat` 入口在 `FAFAFA_SKIP_BUILD=1` 下能跳过构建并消费预构建 `.exe`
- `batch_runtime_matrix`
  - 确认当前 strict L0 的 12 个 `.bat` 入口都已经具备同样的 runtime-only parity
- `batch_native_matrix`
  - 确认同一组 12 个 `.bat` 入口在真实 Windows `lazbuild.exe` 条件下完成 native build + native test，而不是 runtime-only skip-build
- `native_evidence_collector`
  - 把 native matrix 的结果、模块日志、环境信息和 source revision 固化成可归档 evidence 包
- `native_evidence_via_github_actions`
  - 从 Linux/macOS 侧执行 `gh` preflight、dispatch/download，并调用 `verify_windows_strict_l0_native_evidence.sh` 对下载回来的 evidence 包做 shell 侧 contract 校验
- `native_ci_enablement_3cmd`
  - 只负责把“如何先把 workflow 注册到 default branch main”打印成最短操作链
- `native_closeout_3cmd`
  - 只负责打印当前 strict L0 Windows native evidence 的复制即跑入口，不会伪造真实 Windows pass evidence

当前 today 状态：

- workflow 已经注册在 default branch 上
- GitHub Actions run `24224880061` 已在真实 Windows runner 上 fresh 收到 strict L0 native evidence `12/12` PASS
- 因此，如果今天在 Linux x64 上要复核 strict L0 Windows 证据，默认先走 `bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh`
- `print_windows_strict_l0_native_ci_enablement_3cmd.sh` 现在主要用于 workflow registration 漂移或 GH 环境异常排障，不再是当前主路径

当前 matrix 覆盖：

- `base`
- `contracts`
- `bits`
- `layout`
- `endian`
- `span`
- `option`
- `result`
- `platform`
- `atomic`
- `mem.allocator.foundation`
- `mem allocator-only`

如果你还要确认为什么 native Windows `.bat` build-path 还没有记成完成，再补下面这条 preflight：

- Linux/macOS：`bash tests/test_windows_lazbuild_smoke_preflight.sh`

这条 preflight 的意义不是让当前环境“变绿”，而是把缺少真实 Windows `lazbuild.exe` 的情况收敛成固定失败码和明确恢复命令。也就是说：

- 当前仓库已经完成 Windows runtime smoke 和 `.bat` runtime-only parity
- 当前还没有完成的，是 native Windows `lazbuild.exe` 条件下的 `.bat` build-path parity
- 如果 `bash tests/preflight_windows_strict_l0_native_evidence_gh.sh` 返回 `code=21`，含义通常是当前 shell / runner 没有可用的 `gh` 登录态；先补认证，再继续判断 workflow 可见性
- 如果 gh 已认证后 `bash tests/preflight_windows_strict_l0_native_evidence_gh.sh` 返回 `code=24`，含义通常是 `gh` API / 查询 / 解析层的 fail-close；先顺序重试，必要时检查当前网络、GitHub 状态页、`gh auth status` 与 rate-limit，再决定是否继续 dispatch
- 如果 gh 已认证后 `bash tests/preflight_windows_strict_l0_native_evidence_gh.sh` 仍返回 `code=22`，含义通常是 workflow registration 漂移或当前 GH 环境看不到 default-branch workflow；这属于 fail-close 诊断，不代表仓库 today 状态回退成“native parity 未接通”
- Windows exact evidence 仍然只接受 GitHub Actions 或真实 Windows host artifact；Linux x64 本地只能做 contract 复核

如果你已经切到专用 Windows 主机，请直接参考：

- `docs/plans/2026-04-09-l0-native-windows-matrix-runbook.md`

如果你当前只有 Linux x64，请先参考：

- `docs/plans/2026-04-10-l0-windows-ci-enablement.md`

这条 native lane 的约束很严格：

- 它固定覆盖当前 strict L0 的 12 个 `.bat` 入口
- 它不会设置 `FAFAFA_SKIP_BUILD=1`
- 它会先校验 `tools\lazbuild.bat` 是否找到了真实 Windows `lazbuild.exe`
- 只有这条 lane 在真实 Windows 主机 fresh 通过之后，native `.bat` build-path parity 才能记成完成
- 如果你要交付 evidence 包而不是只看终端输出，优先跑 `tests\collect_windows_strict_l0_native_evidence.bat`
- 如果你要从 Linux/macOS 收集 hosted Windows artifact，`run_windows_strict_l0_native_evidence_via_github_actions.sh` 只能帮助 dispatch/download/复核 artifact；native parity 仍然只以 Windows-host collector + verifier 的 fresh 结果为准
- 如果你已经手工拿到了 artifact 或 snapshot 目录，也可以直接执行 `bash tests/verify_windows_strict_l0_native_evidence.sh <snapshot-root> [expected-commit] [expected-ref]`

---

### 快速回归（建议每次提交前）

仅运行常用关键模块，并在第一个失败处停止：

- Windows（推荐）：
  - 在仓库根目录执行：
    - `set STOP_ON_FAIL=1 && tests\run_all_tests.bat fafafa.core.collections`
    - （更快，仅 Vec/VecDeque）：`set STOP_ON_FAIL=1 && tests\run_all_tests.bat fafafa.core.collections.vec fafafa.core.collections.vecdeque`

- Linux/macOS（推荐）：
  - 在仓库根目录执行：
    - `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.collections`
    - （更快，仅 Vec/VecDeque）：`STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.collections.vec fafafa.core.collections.vecdeque`

说明：

- 参数为“模块名”，由 `tests/` 下的**相对目录路径**推导：路径分隔符（`/` 或 `\`）会被转换为 `.`
  - 例：`tests/fafafa.core.json` → `fafafa.core.json`
  - 例：`tests/fafafa.core.collections/vec` → `fafafa.core.collections.vec`
- 过滤兼容：仍支持传入叶子目录名（如 `vec`），以及前缀组过滤（如 `fafafa.core.collections` 会命中 `fafafa.core.collections.*`）
- 环境变量 STOP_ON_FAIL=1 代表“失败即停”，便于快速定位第一个失败点

---

### 全量回归（每日/版本发布前）

- Windows：`tests\run_all_tests.bat`
- Linux/macOS：`bash tests/run_all_tests.sh`

不传参时，脚本会递归扫描并尝试执行所有符合规范的测试脚本：

- Windows：`BuildOrTest.bat` / `BuildAndTest.bat`
- Linux/macOS：`BuildOrTest.sh` / `BuildAndTest.sh`

建议在 CI 或夜间任务中执行全量回归，便于收敛问题。

---

### 输出位置与返回码

- 汇总文件：
  - Windows：`tests/run_all_tests_summary.txt`
  - Linux/macOS：`tests/run_all_tests_summary_sh.txt`
- 日志目录：
  - Windows：`tests/_run_all_logs/*.log`
  - Linux/macOS：`tests/_run_all_logs_sh/*.log`
- 返回码：
  - 0：所有选中模块执行成功
  - 1：存在失败模块（或 STOP_ON_FAIL 触发提前结束）
  - 2：传入了过滤参数，但 0 命中（用于避免“假绿”）

在控制台看不到明细时，请优先查看上述日志与汇总文件。

---

### 过滤与失败即停

- 仅运行指定模块（示例为 4 个关键模块）：
  - Windows：`tests\run_all_tests.bat fafafa.core.collections.vec fafafa.core.collections.vecdeque`
  - Linux/macOS：`bash tests/run_all_tests.sh fafafa.core.collections.vec fafafa.core.collections.vecdeque`
- 失败即停：
  - Windows：`set STOP_ON_FAIL=1 && tests\run_all_tests.bat ...`
  - Linux/macOS：`STOP_ON_FAIL=1 bash tests/run_all_tests.sh ...`

---

### 常见问题（FAQ）

1. 控制台没有输出，但返回码为 0/非 0，如何查看详情？

- 查看汇总与日志：
  - Windows：`tests/run_all_tests_summary.txt`、`tests/_run_all_logs/*.log`
  - Linux/macOS：`tests/run_all_tests_summary_sh.txt`、`tests/_run_all_logs_sh/*.log`

2. 某些测试依赖 lazbuild 路径或工具链，构建失败？

- 确保 Lazarus/FPC 安装完备，并在 PATH 上；或按 tests/\*/BuildOrTest.bat 脚本内的工具路径调整
- 优先在本地先跑单一模块进行定位，例如：
  - `tests\fafafa.core.collections.arr\BuildOrTest.bat`

3. 跑全量太慢？

- 提交前仅跑关键模块（如 `fafafa.core.collections.vec` / `fafafa.core.collections.vecdeque`）
- 夜间/CI 跑全量，或分组并行（在 CI 编排层面并发多个 run_all_tests.sh/bat，分别过滤不同模块）

4. 是否有“测试规范命名”？

- 子模块测试脚本建议采用以下之一：`BuildOrTest.bat` / `BuildAndTest.bat`（Windows），`BuildOrTest.sh` / `BuildAndTest.sh`（Linux/macOS）
- 统一脚本会自动发现并执行上述命名脚本

5. `run_all_tests` 一开始就失败，并提示 `src` hygiene？

- 先直接运行：
  - Linux/macOS：`bash tests/check_repo_hygiene.sh`
  - Windows：`tests\check_repo_hygiene.bat`
- 如果输出列出了 `src/` 下的 `.o` / `.ppu` / `.bak`，先清理这些生成物，再重新执行 `run_all_tests`

---

### 建议的团队约定

- 每次提交前：关键模块 + 失败即停
- 每晚或合入前：全量回归
- 失败模块：提交日志到评审或 CI 附件，提升可复现性
- 新增测试：按规范命名子模块脚本，确保被统一脚本识别

---

### 典型命令速查

- Windows：
  - 关键模块（失败即停）：
    - `set STOP_ON_FAIL=1 && tests\run_all_tests.bat fafafa.core.collections`
  - 全量：
    - `tests\run_all_tests.bat`

- Linux/macOS：
  - 关键模块（失败即停）：
    - `STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.collections`
  - 全量：
    - `bash tests/run_all_tests.sh`
