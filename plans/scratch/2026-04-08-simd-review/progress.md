# SIMD Review Progress

## 2026-04-08

- 读取 `using-superpowers`、`writing-plans`、`planning-with-files`、`code-reviewer` 技能，确定本轮工作方式。
- 通过语义检索获取 SIMD 文档与源码分层概览，确认存在成熟文档面与大量测试/辅助脚本。
- 发现仓库根 `task_plan.md/findings.md/progress.md` 已归档，因此改用 `plans/scratch/2026-04-08-simd-review/` 记录本轮审查。
- 已读取 `docs/fafafa.core.simd.map.md`、`maintenance.md`、`handoff.md`、`checklist.md` 与 `backlog.md` 中的 SIMD 条目。
- 当前高概率 active 闭环问题已缩到“evidence freshness / freeze-status readiness”，而不是大规模功能空洞。
- 已确认当前 worktree 中存在未提交的 SIMD 相关源文件改动，下一阶段以 diff review + 针对性验证为主。
- 已完成 release 验证：`check`、`TTestCase_DispatchAPI`、`TTestCase_DirectDispatch` 全部通过。
- 已完成 `gate`，结果 PASS。
- 已完成 `freeze-status`，结果 FAIL，失败项聚焦在 `qemu-cpuinfo-nonx86-evidence` 被跳过与 Windows evidence 过期。

## 2026-05-08

- 对齐当前工作树真实状态：当前未提交源码改动集中在 `dispatchapi testcase`、Windows wine runtime probe 脚本，以及本轮 SIMD 真实故障修复线。
- 确认此前 gate 假红已清理后，`full test` 暴露了真实实现问题，不能再把 SIMD 视为“只差证据新鲜度”。
- release 验证现状：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework`
  - 结果：FAIL
  - 当前最小错误：`TTestCase_SimdConcurrentPublicAbi.Test_Concurrent_PublicAbiBackendText_RegisterBackend_ReadConsistency: Access violation`
- 已定位首个真实根因方向：
  - `public_abi.impl.inc` 中 backend text getter 使用无锁全局 `AnsiString` cache 发布 `PAnsiChar`
  - 并发 `RegisterBackend(...)` 切长文本时，reader 持有的裸指针没有稳定 snapshot ownership
- 当前正在实施第一批修复：
  - 把 backend name/description text getter 改为直接基于 dispatch published snapshot / immutable default text 返回稳定指针
  - 先收掉 text getter 这一条最小失败面，再继续看 runtime snapshot 与 IEEE754 rounding
- 本轮接口/实现审查补充了机器检查：
  - `python3 tests/fafafa.core.simd/check_interface_implementation_completeness.py --strict`
  - 结果：`dispatch_slots_total=558`，`P0/P1/P2=0`
  - 结论：接口到 dispatch/backend/tests 的“有无覆盖”层面已基本收口，但该检查仍是启发式扫描，不证明语义正确。
- 本轮 contract 检查通过：
  - `python3 tests/fafafa.core.simd/check_dispatch_contract_signature.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_public_abi_signature.py --summary-line`
  - 结论：dispatch contract 与 public ABI 形状当前未漂移。
- 本轮最小并发验证通过：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework`
  - 结果：`[TEST] OK`、`[LEAK] OK`
  - 结论：public ABI backend text 的生命周期问题已从当前最小失败面收口。
- 本轮最小 IEEE754 验证仍失败：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IEEE754EdgeCases,TTestCase_AVX2RoundTruncIEEE754`
  - 结果：5 failures，已缩到 `SSE2 F64x2/F64x4 round/floor/trunc` 语义不一致
  - 代表失败：
    - `SSE2 F64x2[0] Round(NaN)`
    - `AVX2 vs SSE2 RoundF64x4[0] finite compare`
    - `AVX2 vs SSE2 FloorF64x4[0] finite compare`
    - `AVX2 vs SSE2 RoundF64x4[1] finite compare`
    - `AVX2 vs SSE2 TruncF64x4[1] zero sign bit`
- 代码审查结论更新：
  - `src/fafafa.core.simd.sse2.pas` 中 `SSE2Floor/Ceil/Round/TruncF64x2` 仍直接走 `Math.Floor/Ceil/Round/Trunc` 标量语义，且 `F64x4` x64 快路径仍保留旧的 `cvttpd2dq/cvtdq2pd` 汇编方案。
  - `F32x8/F32x16` 已改为委托更小宽度实现，当前失败已不再落在这两组函数上。
  - façade/runtime/cpuinfo 的 canonical 与 legacy alias 仍并存，测试已覆盖一致性，但接口优雅度仍受 alias 面积拖累。
- 本轮实现修复已继续落地：
  - `src/fafafa.core.simd.sse2.pas` 已补入 `F64x2/F64x4` lane 级 IEEE754 rounding helpers，并统一 `signed zero` 归一化语义。
  - `src/fafafa.core.simd.sse2.wide_emulation.inc` 已把 `F64x8` rounding 家族统一委托到更小宽度实现，避免重复分叉语义。
  - `tests/fafafa.core.simd.cpuinfo.x86/buildOrTest.bat` 已补齐 Windows batch success-criteria 合同：支持 `LAZBUILD` 为 batch wrapper，且在 compile/link summary 已出现时接受非零返回并输出 `WARN ... compile/link summary is present`。
- 本轮验证补充完成：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test`
  - 结果：`[TEST] OK`、`[LEAK] OK`
  - `bash tests/test_windows_simd_cpuinfo_x86_batch_build_success_criteria.sh`
  - 结果：`[PASS] windows SIMD cpuinfo.x86 batch build success criteria verified`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - 结果：PASS
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：PASS，`filtered run_all check chain` 为 5/5 通过
- 当前阶段结论：
  - stable interface completeness：绿
  - stable implementation behavior：绿
  - 剩余未做的是 release 级 strict closeout/证据刷新，不是当前 stable surface 的接口或基础实现缺口
- 本轮继续补强接口/实现证据时，新增了 `GetCurrentRuntimeSnapshot` 的直接并发回归：
  - `TTestCase_SimdConcurrentFramework.Test_Concurrent_RuntimeSnapshot_VectorAsmToggle_ReadConsistency`
- 这条新回归第一次 fresh 运行直接抓到真实实现问题：
  - 可观察到 `CurrentBackend/CurrentBackendInfo/BestDispatchableBackend` 来自 AVX2
  - 但 `DispatchableBackends` 同时来自 `vector-asm disabled` 的 `[sbScalar]`
  - 说明此前 `runtime snapshot` 仍可能发布 mixed snapshot，而不只是 helper 间“多次独立调用可能跨代”的文档边界问题
- 根因已定位并修复在 `src/fafafa.core.simd.runtime.pas`：
  - 旧实现只在发布前校验 `Dispatch` 指针是否仍匹配 target
  - 当 `SetVectorAsmEnabled(True/False)` 在构建期间发生多次往返、最终又回到同一 active dispatch 指针时，旧检查可能放过跨代拼接的 snapshot
  - 新实现把 `dispatch-changed hook` 驱动的 `target version` 一起纳入 runtime cache 发布条件，要求“版本未变 + dispatch 指针未漂移”才允许发布
- 修复后验证已完成：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentFramework`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test`
  - `python3 tests/fafafa.core.simd/check_interface_implementation_completeness.py --strict`
  - `python3 tests/fafafa.core.simd/check_dispatch_contract_signature.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_public_abi_signature.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前 release closeout 收口状态更新：
  - `git push origin main` 已完成，远端 `main` 已对齐到 `9859f520`，GH Windows evidence 可以消费当前 SIMD HEAD。
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-via-gh SIMD-20260508-152` 已真实触发 GitHub Actions dispatch。
  - 本次 GH run `25544888689` 未进入 Windows job 执行，直接失败于账户额度/账单限制，而不是 SIMD 构建或测试失败。
  - 随后 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight` 已 fail-close 返回 `RECENT_BILLING_BLOCK`，说明当前 blocker 已被预检稳定记住。
- 当前 stop-point：
  - Linux/QEMU/mainline gate 已绿，`freeze-status` 仍只红在 Windows evidence freshness/source-newer-than-evidence。
  - 要继续完成 Task 4/5，必须先恢复 GitHub Actions Billing/额度，或者提供一份基于当前 `9859f520` 的 fresh Windows evidence 供 `win-evidence-via-gh <batch-id> <run-id>` / manual finalize 消费。
- SIMD worktree 收口状态更新：
  - 已确认当前 `simd` 主线改动已经落在 `main`，不再需要把历史 `simd` worktree 当成“待合并主线”处理。
  - 已移除 4 个干净历史 worktree：`codex/simd-closeout-20260416`、`codex/simd-closeout-20260426-final`、`codex/simd-mainline-absorb-20260427`、`codex/simd-mainline-integration-20260429`。
  - 已 prune 掉失效的临时 `simd/win-evidence-20260419-152` worktree 管理记录。
  - 已删除 2 个已完全并入 `main` 的本地辅助分支：`simd-win-evidence-runtime-20260320`、`win-evidence-main-update`。
  - 后续进一步卫生清理已完成：
    - `codex/simd-mainline-integration-20260503-frontier` 的本地独有 3 个提交已先推到远端，再移除 worktree 目录
    - `simd-foundation` 与 `codex/simd-mainline-integration-20260503-frontier` 的未提交状态都已先归档到 stash：
      - `stash@{1}` = `archive-before-worktree-cleanup: simd-foundation 2026-05-08`
      - `stash@{0}` = `archive-before-worktree-cleanup: codex/simd-mainline-integration-20260503-frontier 2026-05-08`
    - 两个 worktree 的分支都继续保留：
      - `simd-foundation` -> `origin/simd-foundation`
      - `codex/simd-mainline-integration-20260503-frontier` -> `origin/codex/simd-mainline-integration-20260503-frontier`
- 当前 `git worktree list` 只剩：
  - `main`
  - 非 SIMD 的 `l0-mainline`
- 结论：当前 `simd` 已完成主线收口与相关仓库卫生清理；剩余可恢复入口已经明确保存在分支与 stash 中。

## 2026-05-11 AVX2 Compare Thin Wrapper Follow-up

- 当前继续收窄 AVX2 整数 compare 调用链：`CmpGe` 不再通过 `CmpLt` 二次转发，而是直接使用 `MASK_ALL_SET xor CmpGt(b, a)`。
- 这让 `CmpLt/CmpLe/CmpGe` 都只围绕 `CmpGt` 这一套真比较语义展开，浮点 compare 语义继续保持独立。
- 为了避免搬动大块函数体，只给后定义的 `CmpGt` 补了 forward declarations；随后 `git diff --check` 与 Release `gate` 都重新通过。

## 2026-05-11 AVX2 I64x2 Min/Max Selection Consolidation

- 继续扫 AVX2 后发现 `MinI64x2 / MaxI64x2 / MinU64x2 / MaxU64x2` 只是在重复同一段 mask-driven lane selection。
- 已新增 `AVX2SelectI64x2ByMaskRaw`，让四个 typed wrapper 只负责各自的 signed/unsigned compare 语义，选择动作回到单一实现。
- `git diff --check` 和 Release `gate` 已通过，当前 batch 已收口。
- 继续往 AVX2 里扫过一轮后，没有再冒出新的同构重复体，`Wave 3A` 可以收口了。

## 2026-05-09

- 按当前 `SIMD` 方案重新核对了 `src/fafafa.core.simd.sse2.pas`、`src/fafafa.core.simd.intrinsics.sse2.pas`、`src/fafafa.core.simd.intrinsics.x86.sse2.pas` 与现有 experimental/structure 护栏，确认此前仓库文档虽然强调 stable/experimental 边界，但还缺少 SSE2 归属的明确真相表。
- 已新增三张结构真相表：
  - `docs/SIMD_BACKEND_TRUTH.md`
  - `docs/SIMD_INTRINSICS_DISPOSITION.md`
  - `docs/SIMD_SSE2_MIGRATION_MAP.md`
- 已把三张真相表接入现有入口文档：
  - `docs/fafafa.core.simd.map.md`
  - `docs/fafafa.core.simd.maintenance.md`
  - `docs/fafafa.core.simd.handoff.md`
  - `docs/fafafa.core.simd.interface.md`
  - `src/fafafa.core.simd.README.md`
  - `src/fafafa.core.simd.STABLE`
- 已把关键单元注释统一到本轮冻结口径：
  - `src/fafafa.core.simd.sse2.pas` 标成 `thin backend adapter`
  - `src/fafafa.core.simd.intrinsics.sse2.pas` 标成 `transitional compatibility wrapper`
  - `src/fafafa.core.simd.intrinsics.x86.sse2.pas` 标成 `raw ISA leaf target`
  - `src/fafafa.core.simd.intrinsics.pas` 去掉“统一主入口/自动 backend 选择”式误导描述
- `tests/fafafa.core.simd/check_sse2_structure.py` 已扩展，不再只看 include/register 结构，还会检查：
  - 三张真相表是否存在且行集未漂移
  - `simd.sse2` 是否反向依赖 `intrinsics.sse2`
  - `intrinsics.x86.sse2` 是否泄漏 `TVec*` / `TMask*` / dispatch / runtime control-plane 语义
  - `SIMD_SSE2_MIGRATION_MAP.md` 的 A/B/C 分桶是否仍保留关键 sentinel
- 本轮验证已完成：
  - `python3 tests/fafafa.core.simd/check_sse2_structure.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_intrinsics_experimental_status.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 在真相表之外，已补一页专门回答“为什么这里不是两层、为什么不能直接 façade -> intrinsics”的实施基线：
  - `docs/SIMD_LAYERING_IMPLEMENTATION.md`
- 这页新文档已经把三层目标形态、adapter 与 raw leaf 的职责分账、SSE2 的样板归属、以及后续迁移纪律单独写死。
- 现有入口文档已同步指向这页新基线：
  - `docs/fafafa.core.simd.map.md`
  - `docs/fafafa.core.simd.maintenance.md`
  - `docs/fafafa.core.simd.handoff.md`
  - `docs/fafafa.core.simd.interface.md`
  - `src/fafafa.core.simd.README.md`
- 审查后已发现上一版主文档仍有 3 个设计矛盾：
  - 把 `fafafa.core.simd.*` 前缀写得过宽，容易把 `dispatch` 误判成 adapter
  - 把“SSE2 当前只迁 128-bit”误写成全仓库全局规则
  - 没把 `active leaf / experimental isolated / transitional` 写成真正的依赖准入规则
- 现已重写 `docs/SIMD_LAYERING_IMPLEMENTATION.md`：
  - 改成“3 个逻辑层 + 4 类单元 + 4 种 intrinsics 状态”的结构
  - 明确 `namespace != layer`
  - 明确全局 raw leaf 可覆盖 `TM128/TM256/TM512`
  - 明确“只迁 128-bit”只是 SSE2 当前局部 frontier
  - 明确 default stable backend adapter 只允许新增依赖 `active leaf`
- 配套规则已同步进：
  - `docs/SIMD_INTRINSICS_DISPOSITION.md`
  - `docs/SIMD_SSE2_MIGRATION_MAP.md`
  - `docs/fafafa.core.simd.maintenance.md`
- 本轮最小一致性验证已完成：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_sse2_structure.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_intrinsics_experimental_status.py --summary-line`
  - 结果：全部通过
- 继续做“文档是否真正全局反映 SIMD 架构”的复核时，已对照：
  - `src/fafafa.core.simd.pas`
  - `src/fafafa.core.simd.direct.pas`
  - `src/fafafa.core.simd.public_abi.intf.inc`
  - `src/fafafa.core.simd.public_abi.impl.inc`
  - `src/fafafa.core.simd.STABLE`
  - `docs/fafafa.core.simd.publicabi.md`
- 复核后确认三层骨架本身没错，但上一版主文档还缺两个必须显式安置的真实代码面：
  - `public ABI wrapper`
  - `direct dispatch companion`
- 本轮已补齐这些口径：
  - `docs/SIMD_LAYERING_IMPLEMENTATION.md` 现在明确写成“三个核心层 + control/publication seam + companion surfaces + 四种 intrinsics 状态”
  - `docs/fafafa.core.simd.interface.md` 已同步注明 `public ABI wrapper` 与 `fafafa.core.simd.direct` 的接口定位
  - `docs/fafafa.core.simd.maintenance.md` 已同步注明这两个面属于第一层附近的 companion surfaces，不是 backend adapter
  - `src/fafafa.core.simd.architecture.md` 与 `src/fafafa.core.simd.README.md` 的高层图也已同步降歧，避免旧图继续把实现口径简化回“高级 API / dispatch / backend / infra”四块
- 补齐后再次验证：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_sse2_structure.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_intrinsics_experimental_status.py --summary-line`
  - 结果：全部通过
- 继续从“整个模块最优雅终态”视角复核时，又确认 `dataplane` 已经不是局部 helper：
  - `simd.pas` façade fast-path 会从 `dataplane` 取 bound pointers
  - `public_abi.impl.inc` 会从 `dataplane` 取 bound API 成员
  - `direct.pas` 直接读取 `dataplane` snapshot
- 因此本轮又进一步把文档总口径升级为：
  - `public surface`
  - `control/publication seam`
  - `companion surfaces`
  - `backend adapters`
  - `raw leaves`
- 这次额外同步的文档包括：
  - `docs/SIMD_LAYERING_IMPLEMENTATION.md`
  - `docs/fafafa.core.simd.interface.md`
  - `docs/fafafa.core.simd.maintenance.md`
  - `docs/fafafa.core.simd.map.md`
  - `docs/fafafa.core.simd.handoff.md`
  - `docs/fafafa.core.simd.checklist.md`
  - `src/fafafa.core.simd.README.md`
  - `src/fafafa.core.simd.architecture.md`
  - `src/fafafa.core.simd.STABLE`
- 这轮文档升级后的轻量验证已完成：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_sse2_structure.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_intrinsics_experimental_status.py --summary-line`
  - 结果：全部通过
- 用户随后明确目标不是“收 `SSE2` 计划”，而是“把整个 simd 模块重构好，不要冗余，正确架构”。
- 因此本轮记录已从 `SSE2-first` pivot 到 whole-module 视角：
  - `SSE2` 保留为高债务试点 family
  - 不再把 `SSE2` 的局部迁移策略当成整个模块的总规划
- 已新增全局总纲：
  - `docs/plans/2026-05-09-simd-global-architecture-refactor-plan.md`
- 这份总纲当前明确了：
  - 全模块终态：`public/control surface -> control/publication seam -> companion surfaces -> backend adapters -> raw leaves`
  - “不要冗余”不是删层，而是消灭真相源冗余、语义冗余、入口冗余、状态冗余
  - ISA family 按 `正样板 / 高债务 / adapter-only / opt-in experimental` 四类分波次推进
- `docs/fafafa.core.simd.map.md` 已补入口，后续新会话如果要做“整个 simd 怎么重构”，不再需要先从 `SSE2` 子问题切入。
- 进一步检查后，确认这份总纲当时还不够 execution-ready，原因不是方向错，而是缺两块：
  - 全 ISA `family matrix`
  - 文档 source-of-truth 分工与各 Wave 退出条件
- 本轮已继续补完：
  - 新增 `docs/plans/2026-05-09-simd-family-matrix.md`
  - 在 `docs/plans/2026-05-09-simd-global-architecture-refactor-plan.md` 中补入：
    - 文档分工表
    - 当前完善度判断
    - `Wave 1~4` 的退出条件补充
- `map` 已同步增加 family matrix 入口，因此当前 whole-module refactor 文档链已变成：
  - `global plan` 负责总纲
  - `family matrix` 负责执行排程
  - `layering implementation` 负责架构裁决
  - `backend truth` / `intrinsics disposition` 负责状态表
- 继续往下补后，当前剩余的 4 份 family-level 子计划也已经落盘：
  - `docs/plans/2026-05-09-simd-avx2-active-leaf-sample.md`
  - `docs/plans/2026-05-09-simd-x86-incremental-qualification-plan.md`
  - `docs/plans/2026-05-09-simd-neon-qualification-plan.md`
  - `docs/plans/2026-05-09-simd-riscvv-qualification-plan.md`
- 这一步的意义是把 whole-module 计划从“有总纲、有矩阵”推进到“每个主要波次都已有可执行入口”，后续不再需要从聊天里追问 `AVX2/NEON/RISCVV/x86 incremental` 分别该怎么做。
- 用户进一步指出真正的摩擦点是“总计划虽全，但下次开会话不知道从哪开始”。
- 因此本轮又补了一份单页执行索引：
  - `docs/plans/2026-05-10-simd-execution-index.md`
- 这页专门回答：
  - 下次开会话先看什么
  - 当前默认执行队列是什么
  - 选某个 family 后应该进哪份文档
  - baseline 先跑哪几条
  - 改完后只更新哪几处
- 用户随后又明确提出新的实施摩擦：
  - 已完成的 plan 和互相冲突的 plan 如果继续堆在 `docs/plans/`，会干扰下一轮执行
- 因此当前又进入一轮 `SIMD plan hygiene`：
  - 新增 `docs/plans/2026-05-10-simd-plan-status-index.md`
  - 开始把 `docs/plans/*simd*` 明确分成 `active / historical baseline / superseded historical plan`
  - 目标不是先删文件，而是先把 active 执行链压成唯一主线
- 在 `plan hygiene` 之后，当前 active 文档链还剩最后一个实施层缺口：
  - `Wave 2 / seam hardening` 虽然是默认第一波，但还没有一份 fresh active 作战单
- 因此本轮继续新增：
  - `docs/plans/2026-05-10-simd-wave2-seam-hardening-plan.md`
- 这份文档当前负责把第一波真正落到实施口径：
  - 只碰 `dispatch / dataplane / public ABI / direct / façade fast-path`
  - 不夹带 family migration
  - 写死 baseline、红线、目标文件、verification lane 和完成标准

## 2026-05-10 Wave 2 Seam Hardening Batch 1

- 已先用 release 策略重新确认当前 baseline：
  - 继承上一轮串行 `gate` 绿态
  - 本轮再跑 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- 已完成第一批代码收口：
  - `src/fafafa.core.simd.public_abi.impl.inc`
    - 删除 `g_SimdPublicApiTargetDispatchPtr`
    - 删除 `InvalidateSimdPublicApiBinding`
    - `TSimdPublicApiBindingState` 新增 `DataPlane`
    - 绑定复用从“按 dispatch 指针”改为“按 dataplane snapshot 指针”
    - `PublicAbi*` fallback 从 `GetDispatchTable` 改为读取当前已发布 `dataplane` 槽位
  - `src/fafafa.core.simd.pas`
    - 去掉 public ABI 的独立 dispatch hook 接线
  - `tests/fafafa.core.simd/fafafa.core.simd.dataplane.testcase.pas`
    - same-dispatch rebind 测试新增 public API table 复用断言
- 已完成本轮 release 验证：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DataPlane`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_RuntimeAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前 stop-point：
  - Wave 2 已从文档阶段进入真实实现阶段
  - Batch 1 已把 public ABI 从第二条 truth/publication path 收回
  - 下一批可继续审视 façade fast-path mirror 语义，或再收 `TryGetSimdBackendPodInfo` / metadata query 与 dataplane/publication 的边界
- 2026-05-11: 当前 seam audit 发现 `src/fafafa.core.simd.pas` 里仍有大量 façade wrapper 直接走 `GetDispatchTable`；已统一改为 `GetCurrentSimdDataPlaneDispatch`，让 façade 更明确地从 published dataplane seam 读绑定。
- 2026-05-11: 继续把 `src/fafafa.core.simd.public_abi.impl.inc` 的 backend pod info 查询改为读取 `GetCurrentSimdDataPlaneDispatch`，避免 public ABI 继续显式抓 control-plane current dispatch。
- 2026-05-11: Release 验证已通过：`check`、`TTestCase_DataPlane,TTestCase_PublicAbi`、`TTestCase_DispatchAPI,TTestCase_RuntimeAPI`、`TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework`、`gate`。
- 2026-05-11: 继续收口 `api` / `ops` / `arrays` 的 dispatch 读取路径，全部改为 `GetDirectDispatchTable`，并移除 `SIMD_USE_DIRECT_DISPATCH` 的旧开关说明；`check`、SIMD targeted suites、`TTestMathArray`、`gate` 都已通过。
- 2026-05-11: 新增 `dispatch-read-scope` 机器护栏，限制 `GetDispatchTable` 直读只保留在 `dispatch` / `dataplane` / `runtime` 内部单元；`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check` 已通过，摘要为 `scanned_files=157 allowed_files=3 allowed_hits=6 forbidden_hits=0`。
- 2026-05-11: 开始 AVX2 lane helper consolidation，把 `SelectF32x4 / ExtractF32x4 / InsertF32x4 / SelectF64x2` 的重复边界逻辑收回到 scalar reference helper，保留 AVX2 owned dispatch slot，不再让 backend 重写同义算法。
- 2026-05-11: AVX2 lane helper consolidation 已完成 release 验证：`git diff --check`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate` 全部通过。
- 2026-05-11: 顺手清掉 `tests/fafafa.core.simd/__pycache__/` 下被误跟踪的 `.pyc` 编译产物，避免测试缓存继续进入版本库。
- 2026-05-11: 开始 SSE2 lane helper consolidation，把 `SelectF32x4 / ExtractF32x4 / InsertF32x4` 收回到 scalar reference helper；`SSE2SelectF64x2` 与 wide-emulation 路径暂不动，因为语义并不完全同构。
- 2026-05-11: SSE2 lane helper consolidation 已完成 release 验证：`git diff --check`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate` 全部通过。
- 2026-05-11: 开始 SSE2 wide-emulation boundary normalization，把 18 个 wide extract/insert helper 从 wrap-around 索引收回到 scalar clamp 语义，避免 SSE2 wide emulation 和其余 helper 契约分叉。
- 2026-05-11: SSE2 wide-emulation boundary normalization 已完成 release 验证：`git diff --check`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate` 全部通过。
- 2026-05-11: SSE4.1 blend kernel consolidation 已完成：`SSE41SelectF32x4` 现在只是 bitmask wrapper，内部统一委托 `SSE41BlendVF32x4` 作为单一 native blend kernel。
- 2026-05-11: SSE4.1 blend kernel consolidation 已完成 release 验证：`git diff --check`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate` 全部通过。
- 2026-05-11: 继续扫 SSE4.1 时识别到 `SSE41MulI32x4 / SSE41MulU32x4` 共用同一 `PMULLD` kernel，准备把它们收成单一 shared helper，并顺手清掉 `SSE4.1` 文件里的历史任务标记。
- 2026-05-11: `SSE4.1` 的 `PMULLD` 双份实现已收成单一 shared kernel，历史标记也已清理；`git diff --check`、Release `check`、Release `gate` 全部通过。
- 2026-05-11: `RISCVV` facade fallback 继续向 scalar 真源收口，`Select/Extract/Insert` 里与 `Scalar*` 完全同合同的边界逻辑已统一委托出去。
- 2026-05-11: `RISCVV` facade scalar-reference consolidation 已通过 `git diff --check` 和 Release `gate`。
- 2026-05-11: `RISCVV` facade scalar-reference consolidation 也通过了 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`。

## 2026-05-11 Runtime State Simplification

- `src/fafafa.core.simd.runtime.pas` 这轮移除了只服务 `IsBackendRegisteredInBinary` 的内部 `RegisteredFlags`，改为直接从已发布的 `RegisteredBackends` snapshot 推导注册成员资格。
- `runtime` 的几个读路径已收进共用的 published-snapshot helper，避免 `GetCurrentBackend` / `GetCurrentBackendInfo` / `GetRegisteredBackendList` / `GetDispatchableBackendList` / `GetBestDispatchableBackend` 各自重复写一遍“查缓存 -> 刷新 -> 再查一次”的模板。
- fresh 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_RuntimeAPI,TTestCase_DispatchAPI,TTestCase_DataPlane,TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- Wave 2 已完成，`cpuinfo` legacy alias 与 `framework` 转发层确认只是兼容薄壳，不再作为当前默认整改目标；下一步默认进入 `Wave 3A / AVX2`。

## 2026-05-11 AVX2 Sample Noise Cleanup

- 这轮不改 AVX2 语义，只把 `src/fafafa.core.simd.avx2.pas` 和 `src/fafafa.core.simd.avx2.register.inc` 里的历史 `NEW / Iteration / milestone` 标记收掉，保留真正有用的 section header 与语义说明。
- 目标是让 AVX2 更像稳定样板，而不是演进日志。
- 已完成验证：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_AVX2IntrinsicsFallback`
- 当前判断：
  - AVX2 仍然是 Wave 3A 正样板
  - 没有新增功能债，只做阅读噪音收敛

## 2026-05-11 AVX2 Dword/Word Multiply Kernel Consolidation

- 继续扫 AVX2 时确认 `MulI32x4 / MulU32x4` 与 `MulI16x8 / MulU16x8` 只是同码低位乘法的 signed/unsigned 双份实现。
- 本轮把这两组重复实现收进 `AVX2MulDwordVecRaw` / `AVX2MulWordVecRaw`，typed wrapper 仍保留原 dispatch 入口与签名。
- 已完成验证：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前判断：
  - AVX2 仍然保持样板角色
  - 下一轮优先继续扫同类同码重复实现，而不是动已经稳定的 dispatch 结构

## 2026-05-11 AVX2 128-bit Bitwise Kernel Consolidation

- 继续扫 AVX2 的 128-bit integer bitwise 组时，确认 `And / Or / Xor / Not / AndNot` 在 signed/unsigned、不同 lane width 上本来就是同一套 `vpand / vpor / vpxor / vpandn / all-ones-xor` 语义。
- 这次把 `I32x4/U32x4`、`I16x8/U16x8`、`I8x16/U8x16`、`I64x2/U64x2` 的 bitwise 实现统一收进共享 raw helper，保留 typed wrapper 和 dispatch 入口。
- 已完成验证：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前判断：
  - AVX2 的内部重复实现密度明显下降
  - 下一轮继续按“同码共享 kernel”找剩余冗余，而不是重开架构大拆

## 2026-05-11 AVX2 CmpEq Family Consolidation

- 继续扫 AVX2 的 `CmpEq` 族时，确认 `I32x4/U32x4`、`I16x8/U16x8`、`I8x16/U8x16`、`I64x2/U64x2` 只是同宽 compare + mask extraction 的重复实现。
- `F32x4/F64x2` 仍然保留独立语义；`Lt/Gt/Le/Ge/Ne` 也不在这批，因为它们还带着 swap / not / unsigned-adjust 的差异。
- 准备把这批 Eq 收成 width-specific raw helper，再让 typed wrappers 只保留签名和 dispatch 入口。
- 已完成验证：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_DirectDispatch`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`

## 2026-05-11 AVX2 256-bit CmpEq Consolidation

- 继续扫 256-bit compare 时，确认 `I32x8/U32x8`、`I64x4/U64x4` 也只是同宽 compare + mask extraction 的重复实现。
- `F32x8/F64x4` 保留独立浮点 compare 语义，不纳入这批。
- 下一步要把 256-bit dword/qword compare 收进 shared raw helper，然后让 wide-emulation wrapper 自然继承底层结果。
- 已完成验证：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_DirectDispatch`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`

## 2026-05-11 AVX2 Integer CmpNe Consolidation

- 继续扫整数 `CmpNe` 时，确认它就是 `CmpEq` 的反相薄壳，没必要再维护一套 compare + not + mask extraction。
- 浮点 `CmpNe` 不在这批，保持原样。
- 下一步优先收 `I32x4/U32x4`、`I16x8/U16x8`、`I8x16/U8x16`、`I64x2/U64x2`、`I32x8/U32x8`、`I64x4/U64x4` 的整数 `CmpNe`。
- 已完成 release 验证，当前门禁为绿，接下来继续按“同语义共享 helper”扫 AVX2 里剩余的重复实现。

## 2026-05-11 AVX2 Integer CmpLe/CmpGe Thin Wrapper Consolidation

- 继续扫整数 `CmpLe/CmpGe` 时，确认它们就是 `CmpGt/CmpLt` 的反相薄壳，没必要再维护两套 compare + NOT + mask extraction。
- 浮点 `CmpLe/CmpGe` 不在这批，保持原样。
- 这一批已把 `I32x4/U32x4`、`I16x8/U16x8`、`I8x16/U8x16`、`I64x2/U64x2`、`I32x8/U32x8`、`I64x4/U64x4` 的整数 `CmpLe/CmpGe` 统一收口。
- 已完成 release 验证，当前门禁为绿，下一步继续扫 AVX2 里剩余的重复实现面。

## 2026-05-11 X86 Incremental Noise Cleanup

- 这轮继续把 `src/fafafa.core.simd.sse3.pas`、`src/fafafa.core.simd.sse3.register.inc`、`src/fafafa.core.simd.ssse3.pas`、`src/fafafa.core.simd.ssse3.register.inc` 里的 `NEW / Task 5.1 / milestone` 标记收掉。
- 目标是让 `SSE3 / SSSE3` 的实现和注册文件与 AVX2 一样，剩下真正的语义与结构，而不是演进批次痕迹。
- 已完成验证：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- 当前判断：
  - 这仍然是低风险噪音收敛，不是功能改动
  - `SSE3 / SSSE3` 的 truth 链没有新增重复实现
- 进一步审计确认 `SSSE3MinI8x16 / SSSE3MaxI8x16` 只剩 direct helper 兼容面，不再有 owned duplicate override。

## 2026-05-11 X86 Incremental Redundancy Collapse

- 重新检查 `SSSE3` 后发现 `MinI8x16 / MaxI8x16` 只是 SSE2 compare+blend 的重复实现，不是 SSSE3 独占能力。
- 当前正在把这两个 dispatch override 收回成 inherited `SSE3/SSE2` core slots，同时保留 `SSSE3MinI8x16 / SSSE3MaxI8x16` direct helper 作为 compatibility wrapper。
- 已同步修改 source/test/docs 的预期口径。
- 本轮 release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-smoke-x86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-11 Public ABI Metadata Query Cleanup

- `TryGetSimdBackendPodInfo` 里 active / registered 两个分支原先重复维护了同一组 dispatch 派生字段，本轮收成一个局部 helper，减少 metadata query 的重复模板。
- 这次改动不改变 public ABI 语义，只是让 `public_abi.impl.inc` 的控制流更直接，避免同一套 capability / dispatchable / priority 赋值散在两个分支里。
- 已完成验证：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`

## 2026-05-11 AVX512 Frontier Reconfirmation

- 重新核对 `src/fafafa.core.simd.avx512.wide_loadstore.inc`、`src/fafafa.core.simd.avx512.f32x16_math.inc`、`src/fafafa.core.simd.avx512.f64x8_math.inc`、`src/fafafa.core.simd.avx512.facade.inc`、`src/fafafa.core.simd.avx512.register.inc` 后，没有找到可继续合并的 thin-wrapper 或重复实现。
- `SelectF32x16 / SelectF64x8 / ClampF32x16 / ClampF64x8` 仍然是 native AVX-512 最优实现，不应为了“更少代码”降成 scalar/AVX2 wrapper。
- `Utf8Validate / MemReverse / MemDiffRange / BytesIndexOf` 继续保持为故意继承的 AVX2 slots，不是 AVX512 缺口。
- 当前判断：`AVX512` 保持 hold green，下一轮重复实现清理不要把它当成新目标。

## 2026-05-11 SSE4.2 String Helper Consolidation

- 继续扫 x86 incremental family 时，确认 `FindFirstOf_SSE42` 与 `FindFirstNotOf_SSE42` 是同单元内的真实重复 scanner：chunk loop、length cap、index 回算都重复，只有 `PCMPESTRI` polarity 和空集合语义不同。
- 已新增 `FindFirstPcmpestri_SSE42` 作为共享 scanner，两个 public direct helper 只保留各自入口语义。
- 新增 `TTestCase_BackendSmoke.Test_SSE42_StringSearchHelpers`，覆盖跨 16-byte chunk 的 `FindFirstOf`、空 needle/set 语义，以及 `FindFirstNotOf` 全部命中集合时必须返回 `-1`。
- 测试首次抓到 `FindFirstNotOf_SSE42` 把 `PCMPESTRI` negative polarity 的 chunk-boundary sentinel 当成真实 not-in-set 命中的问题；当前已通过 `ecx < chunk_len` 检查修复。
- 已完成 release 验证：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_BackendSmoke`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-11 NEON Scalar Fallback Consolidation

- 已确认 `NEON` 的 non-ASM fallback 里仍有可合并的 exact-contract 重复体，主要集中在 `scalar.utility.inc` 和 `scalar.autowrap.inc`。
- 目标是把这批 fallback 收回 `Scalar*` 真源，只保留真正的 asm-owned 或语义不同的实现。
- 当前已把这一批作为新的 in-progress 批次写进 scratch，下一步直接动代码和 checker。
- 已完成代码收口、checker 收口和 release 验证：`check_nonx86_helper_semantics.py --summary-line`、`BuildOrTest.sh check`、`BuildOrTest.sh impl-audit-nonx86`、`BuildOrTest.sh gate` 全绿。

## 2026-05-11 NEON Scalar Fallback Core Arithmetic Consolidation

- 继续扫 `NEON` fallback 时，发现 `scalar_fallback.inc` 开头的 F32/F64/I32 基础算术仍在手写同合同 scalar loop。
- 当前批次将这些基础算术 wrapper 改成直接委托 `Scalar*`，并在 helper checker 中锁住。
- 这批现在已经收口完成，`check_nonx86_helper_semantics.py --summary-line`、`BuildOrTest.sh check`、`BuildOrTest.sh impl-audit-nonx86`、`BuildOrTest.sh gate` 串行全绿。
- 过程中曾把 `check` 和 `gate` 并行到同一输出目录，触发了一次临时 build 失败；已确认是验证方式冲突，不是代码问题。

## 2026-05-11 Central SIMD Comment Noise Cleanup

- 已把 `simd.pas`、`dispatch.pas`、`sse2.register.inc`、`sse2.wide_emulation.inc` 里的历史施工标记收掉，保持行为不变。
- 随后单独处理 `scalar.pas`：移除 `NEW / Task / Iteration / P*`、`✅` 和无意义 inline `Added` 注释，只保留真实的边界、性能与语义说明。
- `scalar.pas` 仍是 mixed CRLF/LF 文件，本批没有做整文件行尾归一；只把改动行转成 LF，避免把注释清理变成行尾噪音重构。
- 已完成验证：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`

## 2026-05-11 SSE2 Root Comment Noise Cleanup

- `src/fafafa.core.simd.sse2.pas` 已按稳定 backend adapter 边界完成注释噪音收敛。
- 本批只移除 `✅ / NEW / P* / Task / Iteration / 2026-02-05` 这类历史标记，保留 safety、performance、ISA 限制、仿真策略等真实说明。
- 没有物理拆分 `sse2.pas`，没有改 ASM leaf、函数签名或 dispatch wiring。
- 已完成验证：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_sse2_structure.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`

## 2026-05-11 SSE2 Narrow Compare Thin Wrapper Consolidation

- 继续扫 `src/fafafa.core.simd.sse2.pas` 时，确认 `I16x8/I8x16/U16x8/U8x16` 的 `CmpLe/CmpGe/CmpNe` 都是在重复 `CmpGt/CmpEq + mask 反相` 的同构 ASM。
- 本批只收 exact-contract 重复：`Le := all-set xor Gt(a,b)`、`Ge := all-set xor Gt(b,a)`、`Ne := all-set xor Eq(a,b)`；`Eq/Gt` 仍保留为真实 SSE2 compare 实现。
- 对 `I16x8/U16x8` 没有做新的 lane-normalization，只按当前 `TMask8` contract 翻转现有 wrapper 返回值，避免把“去重”混成语义改造。
- 已完成验证：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_NarrowIntegerOps`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`

## 2026-05-11 SSE2 Integer Compare Thin Wrapper Completion

- 继续顺着整数 compare 家族往下扫，确认 `I32x4/U32x4` 的 `Lt` 也只是 `Gt(b, a)` 的同合同重复体，没有必要继续保留完整 ASM。
- 这次把 `I32x4/U32x4` 的 `Lt` 收成参数交换薄壳，并把 `Le/Ge/Ne` 统一成 `MASK4_ALL_SET xor ...`，让 `SSE2` 整数比较家族的收口模式和 `AVX2` 保持一致。
- 现在 `SSE2` 的整数 compare 只保留 `Eq/Gt` 作为真比较体，其他关系都走薄封装，代码面更整齐，也更容易继续扫下一批重复实现。
- 已完成验证：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_NarrowIntegerOps`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`

## 2026-05-11 SSE2 128-bit Bitwise Kernel Consolidation

- 继续扫 `src/fafafa.core.simd.sse2.pas` 时，确认 `And / Or / Xor / Not / AndNot` 在 `I32x4/U32x4`、`I16x8/U16x8`、`I8x16/U8x16` 上都是同一组 128-bit `pand / por / pxor / pandn / all-ones-xor` 语义。
- 已新增 `SSE2AndVecRaw`、`SSE2OrVecRaw`、`SSE2XorVecRaw`、`SSE2NotVecRaw`、`SSE2AndNotVecRaw`，这些 family 的 typed wrapper 现在只保留签名并委托共享 kernel。
- active `I64x2` 的 bitwise 也收回共享 raw helper，并补上 `SSE2AndNotI64x2` dispatch override，避免 `AndNotI64x2` 留在 base scalar fallback。
- 发现 `src/fafafa.core.simd.sse2.i64x2_compare.inc` 没有任何 include 引用，里面是不会进构建的旧 compare/bitwise 片段；本轮已删除，避免后续架构判断被死文件误导。
- 已完成验证：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_sse2_structure.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_NarrowIntegerOps`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 删除孤立文件后复验：`git diff --check`、`check_sse2_structure.py --summary-line`、Release `check`

## 2026-05-11 SSE2 Shift Raw Helper Consolidation

- 已用 Release 策略重新确认当前 baseline：`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check` 通过。
- 当前批次开始收 `SSE2` shift 家族：先新增 `word / dword / qword` 128-bit raw helper，再让 128-bit typed wrapper 与 wide-emulation 256/512-bit wrapper 统一复用这些 helper。
- 本批实现已完成：128-bit `I16x8/I32x4/U16x8/U32x4` shift wrapper 改为调用共享 raw helper，wide-emulation 的 `I32x16/I64x4/U64x4/I64x8` 等 128-bit chunk 展开也统一调用同一批 helper。
- 已完成验证：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_sse2_structure.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_NarrowIntegerOps`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`

## 2026-05-11 RISCVV Integer MinMax Fallback Consolidation

- `riscvv.facade.inc` 的 non-ASM integer `Min/Max` 还在手写逐 lane 循环，和 `ScalarMin/Max*` 完全同合同；这次把 `U32x8/I16x8/I8x16/U16x8/U32x4/U8x16` 这组 fallback 全部收回 scalar truth。
- `RISCVV` asm 路径里的 `vmin/vmax/vminu/vmaxu` 实现没有动，register ownership 也没有改，仍然保持 backend-owned contract。
- `check_nonx86_helper_semantics.py` 已加上这 12 个 RISCVV fallback 的 source-side 断言，防止同合同重复实现回流。
- 已完成 release 验证：`git diff --check`、`FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-smoke-nonx86`、`... impl-audit-nonx86`、`... check`、`... gate` 全绿。

## 2026-05-11 RISCVV Facade Arithmetic/Bitwise/Compare Consolidation

- 已把 `RISCVV` non-ASM facade 里一批 exact-contract 重复体收回 `Scalar*` 真源，覆盖 `I32x4 / I64x2 / I32x8 / U32x8` 的 arithmetic、bitwise、compare，以及 `I32x4 / I32x8` 的 min/max。
- 这批改动只动 `riscvv.facade.inc` 的 fallback body，不动 `register.inc` 的 slot ownership，也不碰 asm path。
- `check_nonx86_helper_semantics.py` 已同步增加 source-side 断言，后面如果有人把这些 wrapper 改回循环，checker 会直接报出来。
- Release 验证已完成，确认这批去冗余没有把 contract 搞歪：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-smoke-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`

## 2026-05-11 NEON Scalar Math/Utility Forwarder Consolidation

- 继续扫 `NEON` fallback 时，发现 `scalar.utility/math/ext_math/autowrap` 里还有一批 exact-contract scalar loop：`SplatF32x4`、`Abs/SqrtF32x4`、`Fma/Rcp/RsqrtF32x4`，以及 fallback-only wide `Abs/Fma`。
- 已把这些 wrapper 全部收回对应 `Scalar*` 真源，减少 NEON fallback 自己维护第二份逐 lane 参考实现。
- `Min/Max`、rounding、floor/ceil/trunc、clamp 这类浮点语义敏感路径本批没有动，后续必须先证明 NaN / signed-zero 语义再收口。
- `check_nonx86_helper_semantics.py` 已补新增 forwarder 的 source-side 断言，当前 summary 为 `NONX86_HELPER_SEMANTICS_SUMMARY checks=176 status=ok`。
- 已完成 release 验证：`git diff --check`、`py_compile`、helper checker、`impl-smoke-nonx86`、`impl-audit-nonx86`、Release `check`、Release `gate` 全绿。

## 2026-05-11 NEON Scalar Floor/Ceil Wide Forwarder Consolidation

- 继续扫 `NEON` fallback 时，确认宽向量 `Floor/Ceil` 的 `F32x8 / F32x16 / F64x4 / F64x8` 都只是 `ScalarFloor/Ceil*` 的同合同重复壳。
- 已把这些宽向量 wrapper 收回 scalar truth，保留 `F32x4 / F64x2` 和 `Round/Trunc/Clamp` 作为后续语义敏感边界。
- `check_nonx86_helper_semantics.py` 新增了 8 个 source-side 断言，当前 summary 为 `NONX86_HELPER_SEMANTICS_SUMMARY checks=184 status=ok`。
- release 验证已完成：`git diff --check`、`py_compile`、helper checker、`impl-smoke-nonx86`、`impl-audit-nonx86`、Release `check`、Release `gate` 全绿。

## 2026-05-11 SSSE3 Raw-Leaf Wording Harmonization

- 发现 `SSSE3` 在 active x86 文档里有一处口径漂移：部分入口把它写成“待补 raw leaf”，但 family matrix 已明确它是 adapter-only in practice。
- 已把这些 active 文档统一改成 `adapter-only / no dedicated raw leaf target`，避免后续把不存在的 leaf 目标当成 TODO。
- 同时发现 `execution index` 底部仍把已完成的 `Wave 2 / seam hardening` 写成“代码实施还没开始”；已按顶部完成状态同步移除。
- 复核已完成：`rg` 没有再发现 active-doc 里的 `SSSE3` 待补 raw leaf 或 `Wave 2` 未开始冲突，`git diff --check` 通过。

## 2026-05-11 SSE2 Retire Target Baseline

- `Wave 5` 里最后那块收口文档现在要落成单独的 `SSE2 retire target` baseline，而不是继续散落在总纲里。
- 这份文档会负责冻结 C 桶，明确 `SSE2` 哪些对象永远留在 adapter，哪些对象只有在 raw leaf 迁移证据齐全后才可能进入 retire bucket。
- 已新增 `docs/plans/2026-05-09-simd-sse2-retire-target-plan.md`，并把它接入 `plan-status-index`、`execution-index`、`global architecture plan`、`family matrix` 与 `SIMD_SSE2_MIGRATION_MAP.md`。
- 验证已完成：`prettier --write`、`git diff --check`、`python3 tests/fafafa.core.simd/check_sse2_structure.py --summary-line`、`python3 tests/fafafa.core.simd/check_intrinsics_experimental_status.py --summary-line` 全部通过。

## 2026-05-11 Experimental Hold Future Trigger Baseline

- `Wave 5` 还需要一份 `experimental hold future trigger` baseline，专门冻结 `AES / SHA / AVX / FMA3 / SVE / SVE2 / LASX` 的重新开线条件。
- 这份文档不是要把这些 family 提前 promote，而是把“什么时候值得重开一个 family 的单独计划”写成统一规则，避免后续临场判断。
- 已新增 `docs/plans/2026-05-09-simd-experimental-hold-future-trigger-plan.md`，并把它接入 `plan-status-index`、`execution-index`、`global architecture plan` 与 `family matrix`。
- 验证已完成：`prettier --write`、`git diff --check`、`python3 tests/fafafa.core.simd/check_sse2_structure.py --summary-line`、`python3 tests/fafafa.core.simd/check_intrinsics_experimental_status.py --summary-line` 全部通过。

## 2026-05-11 X86 Raw Parity Baseline

- `SSE3 / SSE4.1 / SSE4.2 / AVX-512` 的共享 raw parity baseline 已单独落成，不再让 smoke 叙述继续承担 parity 决策。
- 已把这份 baseline 接入 `plan-status-index`、`execution-index`、`global plan`、`family matrix` 与 `x86 incremental qualification plan`，让 `Wave 3C` 明确分工为 qualification + parity freeze。
- 这次只是在文档链上收口，没有碰代码实现；当前轻量验证仍是绿的：`git diff --check`、`check_sse2_structure.py --summary-line`、`check_intrinsics_experimental_status.py --summary-line`。

## 2026-05-11 NEON Scalar Vector Math Forwarder Consolidation

- 继续扫 `NEON` fallback 时，确认 `scalar.vector_math.inc` 里的 `DotF32x4 / DotF32x3 / CrossF32x3 / LengthF32x4 / LengthF32x3 / NormalizeF32x4 / NormalizeF32x3` 都只是 `Scalar*` 真源的同合同重复体。
- 本批只收 non-ASM fallback，不动 `neon.pas` 的 ARM64 asm 实现，也不改 register ownership；`NormalizeF32x3` 已特别核对 `w=0` 语义与 scalar truth 一致。
- `check_nonx86_helper_semantics.py` 已补 7 个 source-side 断言，当前 summary 为 `NONX86_HELPER_SEMANTICS_SUMMARY checks=191 status=ok`。
- release 验证已完成：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-smoke-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-11 AVX2 256-bit Dword Shared Kernel Consolidation

- `AVX2` 的 `I32x8/U32x8` 里，`Add/Sub/Mul/And/Or/Xor/Not/AndNot/ShiftLeft/ShiftRight(logical)` 都是同一条 dword 位语义的重复体，适合收成共享 raw kernel。
- 这次把共享 kernel 放进 `avx2.i32x8_family.inc`，typed wrapper 只保留类型入口和 dispatch 绑定点；`Cmp*`、`Min/Max`、`ShiftRightArithI32x8` 仍保留独立实现。
- release 验证已通过：`TTestCase_VecI32x8`、`TTestCase_VecU32x8`、`TTestCase_DispatchAPI`、`TTestCase_DirectDispatch`、`check`、`gate` 全绿。

## 2026-05-11 AVX2 256-bit Qword Shared Kernel Consolidation

- `AVX2` 的 `I64x4/U64x4` 里，`Add/Sub/And/Or/Xor/Not/ShiftLeft/ShiftRight(logical)` 都是同一条 qword 位语义的重复体，signed/unsigned 只改变类型解释，不改变 bit pattern。
- 已在 `avx2.i32x8_family.inc` 新增 qword raw helper，并让 `src/fafafa.core.simd.avx2.pas` 的 `I64x4/U64x4` typed wrapper 只保留 dispatch 入口签名。
- 本批没有碰 `Cmp*`、`Min/Max`、unsigned compare trick，也没有引入新的 dispatch / register ownership。
- 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_DirectDispatch,TTestCase_DataPlane`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 注意：第一次把 `check` 和 `gate` 并发起跑时，`check` 因争同一输出目录返回 `rc=2`；串行重跑后通过，归类为调度假红，不是代码回归。

## 2026-05-11 AVX2 128-bit Arithmetic/Shift Shared Kernel Consolidation

- 继续把 `AVX2` 里 128-bit 整数的 `Add/Sub/ShiftLeft/ShiftRight(logical)` 收成共享 raw helper：`I32x4/U32x4`、`I16x8/U16x8` 以及 `I8x16/U8x16` 的 add/sub 都不再各自维护完整 asm body。
- 已新增 `AVX2AddDwordVecRaw`、`AVX2SubDwordVecRaw`、`AVX2AddWordVecRaw`、`AVX2SubWordVecRaw`、`AVX2AddByteVecRaw`、`AVX2SubByteVecRaw`、`AVX2ShiftLeftDwordVecRaw`、`AVX2ShiftRightDwordVecRaw`、`AVX2ShiftLeftWordVecRaw`、`AVX2ShiftRightWordVecRaw`。
- `src/fafafa.core.simd.avx2.pas` 的 `I32x4/U32x4`、`I16x8/U16x8`、`I8x16/U8x16` 相关入口现在都只剩 thin wrapper；`ShiftRightArith*`、`Cmp*`、`Min/Max` 仍保持原语义边界。
- 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_NarrowIntegerOps,TTestCase_AVX2VectorAsm,TTestCase_DispatchAPI,TTestCase_DirectDispatch,TTestCase_DataPlane`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-11 SIMD Active Plan Status Sync

- 重新核对当前代码与 active plan 后，确认 `execution-index` 里 `Wave 3C / Wave 4A / Wave 4B` 仍写成默认起手会误导后续会话；实际默认执行队列应切到 `Wave 5 / retire + redundancy cleanup`。
- 已同步修正 `docs/plans/2026-05-10-simd-execution-index.md` 与 `docs/plans/2026-05-09-simd-global-architecture-refactor-plan.md`，把 `Wave 4` 的 non-x86 代码批次写成已落地，把 `Wave 5` 写成当前默认 cleanup wave。
- 这轮没有继续开新代码批次，因为当前没有再找到一块可安全收口、又不碰语义敏感边界的重复实现；下一步要么进 Wave 5 的 evidence-backed cleanup，要么等 fresh red 再回到 family plan。

## 2026-05-11 Current Session Checkpoint

- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test` PASS。
- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate` PASS。
- `bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight` 现在返回 `RECENT_BILLING_BLOCK`，所以 fresh Windows evidence refresh 目前被 GitHub billing 挡住了，不是 SIMD 代码回归。
- 本轮代码侧已经没有新的可见 blocker，剩余 release gap 只有外部 evidence freshness。
- `tests/fafafa.core.simd/__pycache__` 已清理，当前工作树只保留真实源码与计划改动。

## 2026-05-11 Family Decision Baseline

- 重新扫了一遍 family matrix 和 execution/status index 后，确认真正还在反复制造噪音的不是源码重复体，而是 family-level `promote / hold / future-trigger` 决策还散在多个入口里。
- 已新增 `docs/plans/2026-05-11-simd-family-decision-baseline.md`，把 `SSE3 / SSE4.1 / SSE4.2 / AVX-512`、`NEON / RISCVV`、`AES / SHA / AVX / FMA3 / SVE / SVE2 / LASX` 的默认判断一次性冻住。
- 已同步回填 `docs/plans/2026-05-09-simd-family-matrix.md`、`docs/plans/2026-05-10-simd-execution-index.md` 与 `docs/plans/2026-05-10-simd-plan-status-index.md`，让后续会话先看单页基线，再看 family matrix。
- 这批只做文档层治理，没有继续开新代码 batch；当前 SIMD 的源码层重复体收口已经够了，后续若要继续只能等 fresh red 或新的高价值 exact-contract 重复体。

## 2026-05-11 AVX512 Placeholder Helper Consolidation

- 已把 `src/fafafa.core.simd.intrinsics.avx512.pas` 里的 `load / loadu / store / storeu / set1 / add / sub / mul / div / mask_add / maskz_add` 收成局部 helper，避免 placeholder math 层再维护重复搬运体和同宽循环。
- 当前这刀只动文件内重复实现，没有扩大公开 surface，也没有碰 `load/store` 或初始化门控。
- 复验时 `git diff --check` 曾发现 `storeu` 与 `setzero` 之间有孤立 CR 空行导致 trailing whitespace；已清理并复跑通过。
- 验证已完成：`git diff --check`、`tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check`、Release `check`、Release `gate` 全部通过。

## 2026-05-11 Generic Intrinsics Load/Set Helper Consolidation

- 已确认 `src/fafafa.core.simd.intrinsics.pas` 还保留着一组明显的 placeholder duplicate body，当前先收 `load/store` 和 `set1_epi*` 的公共壳。
- 这批是当前还能在本机验证的通用入口，适合作为下一刀，不碰 compare / min-max / shift / floating math 的语义边界。
- 文件本身还是混合换行，下一步会一起整理成 LF，避免让格式噪音继续挂在通用入口上。

## 2026-05-11 Runtime Getter Snapshot Fallback Closure

- `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate` 在 `TTestCase_SimdConcurrentFramework` 抓到了真实 red：`current backend info mixed snapshot` 和 `dispatchable helper mixed snapshot`。
- 回头对照 runtime 代码后确认，问题不在刚改的 placeholder helper，而在 `GetCurrentBackendInfo` / dispatchable helper 的 fallback 还会直接回到 active state 或 nil。
- 已把 runtime getter fallback 收紧到 `GetCurrentRuntimeSnapshot`，并先用 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrentFramework` 做了 targeted 验证，结果已回绿。
- full Release `gate` 已回绿，说明这条 fallback 收口在完整门禁链路下没有再冒 mixed snapshot。

## 2026-05-11 AVX Placeholder Helper Consolidation

- 已把 `src/fafafa.core.simd.intrinsics.avx.pas` 里的 `load/store/set1` 以及一组纯占位 `cmp/blend/shuffle/permute/unpack/test/extract/insert` 重复体收成 helper。
- 这批仍然只保留 experimental placeholder 语义，没有扩大公开 surface，也没有碰真正的数值实现分支。
- `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check`、Release `check`、Release `gate` 已通过，helper 收口没有破坏 experimental 门禁。

## 2026-05-11 SSE3/SSE41 Experimental Intrinsics Cleanup

- 已修复 `src/fafafa.core.simd.intrinsics.sse3.pas` 的 `sse3_loaddup_pd`，恢复真实的 `PDouble(Ptr)^` 读取，不再把 load 语句吞进注释。
- 已修复 `src/fafafa.core.simd.intrinsics.sse41.pas` 的 `sse41_dp_pd`、`sse41_round_ps`、`sse41_insert_ps`，把 comment-swallow 和缺失逻辑补回。
- 已新增并注册 `TTestCase_SimdIntrinsicsExperimentalX86`，覆盖 `sse3_loaddup_pd` / `sse41_dp_pd` / `sse41_round_ps` / `sse41_insert_ps`。
- 验证结果：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1 bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test --suite=TTestCase_SimdIntrinsicsExperimentalX86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-11 SSE4.1 Min/Max Helper Consolidation

- 已把 `sse41_max_epi8 / max_epi32 / max_epu16 / max_epu32` 与对应 `min_*` 的重复逐 lane if/else 收成类型专属私有 helper：
  - `SSE41MinMaxI8x16`
  - `SSE41MinMaxI32x4`
  - `SSE41MinMaxU16x8`
  - `SSE41MinMaxU32x4`
- 公开 placeholder wrapper 继续保留原函数名和 signed/unsigned lane contract，只变成 thin shell，不提升 experimental surface。
- 已新增 `Test_SSE41_MinMax_SignedAndUnsigned`，覆盖 signed `epi8/epi32` 与 unsigned `epu16/epu32` 的代表性 min/max 路径。
- 验证结果：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1 bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test --suite=TTestCase_SimdIntrinsicsExperimentalX86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-11 SSE4.1 Blend Helper Consolidation

- 已把 `sse41_blend_ps / blend_pd / blendv_ps / blendv_pd / blendv_epi8` 的重复 lane selection 收成私有 helper：
  - `SSE41BlendF32x4`
  - `SSE41BlendF64x2`
  - `SSE41BlendVF32x4`
  - `SSE41BlendVF64x2`
  - `SSE41BlendVE8x16`
- 公开 wrapper 继续保留原函数名与 imm8 / sign-bit mask contract，只收敛重复选择体，不扩大 surface。
- 已新增 `Test_SSE41_Blend_ImmediateAndVariableMasks`，覆盖 immediate mask、float sign-mask 与 byte sign-mask 的代表性路径。
- 验证结果：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1 bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test --suite=TTestCase_SimdIntrinsicsExperimentalX86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-11 SSE4.1 Insert/Extract Lane Clamp Consolidation

- 已把 `SSE41InsertF32x4 / SSE41ExtractF32x4` 共享的 lane clamp 收成私有 `SSE41ClampF32x4Index` helper。
- 公开 dispatch 签名不变，只把边界截断逻辑集中到一处，避免 insert/extract 各自维护同一段 saturation 代码。
- 已把 `Test_SSE41_RepresentativeSemanticParity_WithScalar_IfDispatchable` 补成 SSE4.1 insert/extract 代表性 parity，覆盖低位和高位 clamp。
- 验证结果：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-11 SSE4.1 Rounding Helper Consolidation

- 已把 `sse41_round_ps / sse41_round_pd / sse41_round_ss / sse41_round_sd` 的重复 rounding case 收成单一私有 `SSE41RoundScalar` helper。
- `round_ps/pd` 继续负责逐 lane 处理，`round_ss/sd` 继续保留高 lane 原样，只替换 lane0，语义没变但重复 case 变少了。
- 已补实验性回归：
  - `Test_SSE41_RoundPd_Mode2_UpdatesEachLane`
  - `Test_SSE41_RoundSsSd_PreserveUnmodifiedLanes`
- 验证结果：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1 bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test --suite=TTestCase_SimdIntrinsicsExperimentalX86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-11 SSE4.1 Conversion Helper Consolidation

- 已把 `sse41_cvtepi*` / `sse41_cvtepu*` 的重复 signed / unsigned lane-extension loop 收成私有 helper：
  - `SSE41ExtendSignedI8/I16/I32`
  - `SSE41ExtendUnsignedU8/U16/U32`
- 12 个公开 placeholder wrapper 仍保留原函数名和 lane contract，只把重复 loop 收回 helper，不扩大 experimental surface。
- 已新增 `Test_SSE41_ConvertExtends_SignedAndUnsigned`，覆盖 signed sign-extension 与 unsigned zero-extension 的代表性路径。
- 验证结果：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1 bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test --suite=TTestCase_SimdIntrinsicsExperimentalX86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-11 SSE4.1 Normalize Helper Consolidation

- 已把 `SSE41NormalizeF32x4 / SSE41NormalizeF32x3` 共享的 length divide 和 zero-vector fallback 收成私有 `SSE41NormalizeByLength` helper。
- `F32x4` 继续保留完整四 lane normalize contract，`F32x3` 仍然在归一化后强制把 `w` lane 清零；只是现在两条 wrapper 不再各自维护同一段分支。
- 这批修复过程中先漏掉了两个 wrapper 的 `var`，导致编译断点很明确；补回后重新跑 release gate 已经绿了。
- 验证结果：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-11 AVX2 Normalize Helper Consolidation

- 已把 `AVX2LengthF32x4 / AVX2LengthF32x3` 的 zero-w + horizontal length 逻辑收成私有 `AVX2LengthWithOptionalZeroW` helper。
- 已把 `AVX2NormalizeF32x4 / AVX2NormalizeF32x3` 的 length divide 和 zero-vector fallback 收成私有 `AVX2NormalizeByLength` helper。
- 四个公开 dispatch wrapper 签名不变，`F32x3` 仍然在 length 与 normalize 两侧维持 `w` lane 清零 contract。
- 验证结果：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_AVX2VectorAsm`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-11 SSE3 Normalize Helper Consolidation

- 已把 `SSE3LengthF32x4 / SSE3LengthF32x3` 的 zero-w + horizontal length 逻辑收成私有 `SSE3LengthWithOptionalZeroW` helper。
- 已把 `SSE3NormalizeF32x4 / SSE3NormalizeF32x3` 的 length divide 和 zero-vector fallback 收成私有 `SSE3NormalizeByLength` helper。
- 公开 dispatch wrapper 签名不变；`F32x3` 的 `w` lane 清零仍保留在 helper policy 里。
- 验证结果：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_DirectDispatch`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-11 SSE2 F32 Vector Math Helper Consolidation

- 已把 `SSE2LengthF32x4 / SSE2LengthF32x3` 与 `SSE2NormalizeF32x4 / SSE2NormalizeF32x3` 收成 `SSE2LengthWithOptionalZeroW` 与 `SSE2NormalizeByLength` 两个私有 helper，保留了 `F32x3` 的 `w=0` 语义。
- `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 里的 `Test_SSE2_F32VectorMath_Use_NonScalar_Impl_And_Keep_Parity` 现在直接覆盖 `LengthF32x4/F32x3`、`NormalizeF32x4/F32x3`、zero-vector 与 `w` lane 行为。
- 顺手删除了未被任何 `include` 引用的 `src/fafafa.core.simd.sse2.vector_math.inc` 镜像文件，避免仓库里继续留一份误导性的旧重复源。
- 先前 `check` 曾因为新 helper 的 `inline` 标记冒出 hints；去掉 `inline` 后已复验通过。
- 验证结果：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_DirectDispatch`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-11 NEON Scalar Memory/Reduction Forwarder Consolidation

- 重新扫 `NEON` non-ASM fallback 后，确认 `neon.scalar.memory.inc` 的 `F32x4` load/store 和 `neon.scalar.reduction.inc` 的 `F32x4` reduce add/mul 仍在手写第二份同合同逻辑。
- 这批已经收成 `Scalar*` 真源转发，`ReduceMin/ReduceMax` 与整数 reduction 保持 local，因为它们不属于这次 exact-contract 去重面。
- 同步把这条线补进 `check_nonx86_helper_semantics.py`，避免后面再有人把这几组 fallback 写回手写壳。
- release 复验已完成：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-12 Public ABI Dataplane Doc Guard

- 继续按 `Wave 5 / retire + redundancy cleanup` 检查 active 文档与代码 truth，发现 `docs/fafafa.core.simd.publicabi.md` 仍保留“兜底路径回读当前 dispatch table”的旧口径。
- 当前代码事实已经是 `public ABI wrapper` 绑定并兜底到 published `dataplane`，所以这句话会误导后续把 public ABI 写回第二条 publication/control 路径。
- 已把 active public ABI 文档改成 dataplane fallback 口径，并让 `check_dispatch_read_scope.py` 同时检查这份 active 文档不能再出现 `fallback/兜底 -> dispatch table` 的旧描述。
- 已完成初步验证：
  - `python3 -m py_compile tests/fafafa.core.simd/check_dispatch_read_scope.py`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh dispatch-read-scope`
  - 结果：通过，`active_doc_issues=0`
- 已完成 release 收口：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-12 RISCVV Integer Fallback Forwarder Expansion

- 接上当前 `Wave 5 / retire + redundancy cleanup`，继续收 `RISCVV` non-ASM facade 里的 exact-contract integer fallback。
- `src/fafafa.core.simd.riscvv.facade.inc` 已把新增一批 arithmetic / bitwise / not / 小范围 mul / andnot 循环改为直接委托 `Scalar*` 真源。
- `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 已同步新增 source-side 断言，避免这批 fallback 再回到手写逐 lane 循环。
- 已完成轻量验证：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - 结果：通过，`NONX86_HELPER_SEMANTICS_SUMMARY checks=251 status=ok`
- 已完成 release 级收口：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 生成的 `__pycache__` 已清理，当前工作树只保留目标改动。

## 2026-05-12 RISCVV Integer Compare Forwarder Expansion

- 继续沿 `Wave 5 / retire + redundancy cleanup` 扫 `RISCVV` facade 的 exact-contract 重复体，这次收的是 integer compare 而不是 arithmetic。
- `src/fafafa.core.simd.riscvv.facade.inc` 已把 `I16x8/I8x16/I32x16/I64x4/I64x8/U16x8/U32x4/U64x4/U8x16` 的 compare wrapper 改成直调 `ScalarCmp*`。
- `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 已同步新增 compare forwarder 断言，summary 变成 `checks=304`。
- 已完成 release 级收口：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-12 RISCVV I32x16 MinMax Tail Completion

- 继续扫 RISCVV integer min/max 后，确认当前只剩 `RISCVVMinI32x16 / RISCVVMaxI32x16` 两个手写 loop。
- 已把这两个 wrapper 改成 `ScalarMinI32x16 / ScalarMaxI32x16` 直调，并把 checker 期待值扩到 `checks=306`。
- 已完成 release 级收口：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-12 RISCVV I32x16 Arithmetic/Bitwise Tail Completion

- 接上 `Wave 5 / retire + redundancy cleanup`，继续收 `RISCVV` no-ASM facade 中最后一段明显的 `I32x16` integer duplicate。
- `src/fafafa.core.simd.riscvv.facade.inc` 已把 `Add/Sub/Mul/And/Or/Xor/Not/AndNotI32x16` 从逐 lane loop 改为对应 `Scalar*I32x16` 直调。
- `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 已新增这 8 个 forwarder 的 source-side 断言，预期 summary 从 `checks=306` 扩到 `checks=314`。
- 轻量验证与 release 级收口已完成：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过，`checks=314 status=ok`

## 2026-05-12 RISCVV Wide Float Arithmetic Forwarder Consolidation

- 继续沿 `Wave 5 / retire + redundancy cleanup` 扫 `RISCVV` no-ASM facade，本批只收 `F32x16/F64x8` 的基础四则运算 fallback。
- `src/fafafa.core.simd.riscvv.facade.inc` 已把 `Add/Sub/Mul/DivF32x16` 和 `Add/Sub/Mul/DivF64x8` 改成对应 `Scalar*` 直调。
- `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 已新增这 8 个 forwarder 断言，预期 summary 从 `checks=314` 扩到 `checks=322`。
- 轻量验证与 release 级收口已完成：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过，`checks=322 status=ok`

## 2026-05-12 RISCVV Narrow Float Arithmetic/Compare Forwarder Consolidation

- 继续沿 `Wave 5 / retire + redundancy cleanup` 扫 `RISCVV` no-ASM facade，本批只收 `F32x4/F64x2` 的基础 arithmetic / compare fallback。
- `src/fafafa.core.simd.riscvv.facade.inc` 已把 `Add/Sub/Mul/Div` 与 `CmpEq/Lt/Gt/Le/Ge/NeF32x4/F64x2` 改成对应 `Scalar*` 直调。
- `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 已新增这 20 个 forwarder 断言，预期 summary 从 `checks=322` 扩到 `checks=342`。
- release 级复验已完成，`git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 均通过，当前批次已可收口。

## 2026-05-12 RISCVV Mid Float Arithmetic/Compare Forwarder Consolidation

- 下一批已经定位：`F32x8/F64x4` 的 arithmetic loop，以及 `F32x8/F64x4/F64x8/F32x16` 的 compare loop。
- 这些函数都有现成 `Scalar*` helper，可继续按 exact-contract 收回。
- `src/fafafa.core.simd.riscvv.facade.inc` 已把这 32 个 fallback 改成对应 `Scalar*` 直调，`check_nonx86_helper_semantics.py` 已把 summary 扩到 `checks=374`。
- release 级复验已完成：`git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 均通过。

## 2026-05-12 RISCVV Abs/Sqrt Forwarder Consolidation

- 下一批已经定位：`F32x4/F64x2/F32x8/F64x4/F32x16/F64x8` 的 `Abs/Sqrt` unary loop。
- 这些函数都有现成 `Scalar*` helper，可继续按 exact-contract 收回。
- `src/fafafa.core.simd.riscvv.facade.inc` 已把这 12 个 fallback 改成对应 `Scalar*` 直调，`check_nonx86_helper_semantics.py` 已把 summary 扩到 `checks=386`。
- release 级复验已完成：`git diff --check`、`py_compile`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 均通过。

## 2026-05-12 RISCVV Fma/Rcp/Rsqrt Forwarder Consolidation

- 接上 `Wave 5 / retire + redundancy cleanup`，继续收 `RISCVV` no-ASM facade 里剩余的 exact-contract ext math 重复体。
- `src/fafafa.core.simd.riscvv.facade.inc` 已把 `F32x4/F64x2/F32x8/F64x4/F32x16/F64x8` 的 `Fma` 以及 `F32x4` 的 `Rcp/Rsqrt` 改成直接委托 `Scalar*` 真源；`RcpF64x4` 仍保留本地实现。
- `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 已把这批 source-side forwarder 收进护栏，summary 扩到 `checks=394`。
- release 级验证已完成：`git diff --check`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 全部通过。

## 2026-05-12 RISCVV Floor/Ceil Forwarder Consolidation

- 接上 `Wave 5 / retire + redundancy cleanup`，继续收 `RISCVV` no-ASM facade 里还能安全合并的 exact-contract `Floor/Ceil` 重复体。
- `src/fafafa.core.simd.riscvv.facade.inc` 已把 `F32x4/F64x2/F32x8/F64x4/F32x16/F64x8` 的 `Floor/Ceil` 改成直接委托 `ScalarFloor/Ceil*` 真源；`Round/Trunc/Clamp` 先保留。
- `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 已把这批 source-side forwarder 收进护栏，summary 扩到 `checks=406`。
- release 级验证已完成：`git diff --check`、helper checker、`impl-audit-nonx86`、Release `check`、Release `gate` 全部通过。

## 2026-05-12 RISCVV Splat Forwarder Consolidation

- 接上 `Wave 5 / retire + redundancy cleanup`，继续收 `RISCVV` no-ASM facade 里剩余的纯构造器重复体。
- `src/fafafa.core.simd.riscvv.facade.inc` 已把 `SplatF32x4/F32x8/F32x16/F64x2/F64x4/F64x8/I64x4` 改成直接委托对应 `ScalarSplat*` 真源。
- `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 已新增这 7 个 forwarder 的 source-side 断言，summary 从 `checks=406` 扩到 `checks=413`。
- 轻量验证与 release 级收口已完成：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过，`NONX86_HELPER_SEMANTICS_SUMMARY checks=413 status=ok`

## 2026-05-12 RISCVV Zero Forwarder Consolidation

- 接上 `Wave 5 / retire + redundancy cleanup`，继续收 `RISCVV` no-ASM facade 里剩余的 `Zero` 纯构造器重复体。
- `src/fafafa.core.simd.riscvv.facade.inc` 已把 `ZeroF32x4/F32x8/F32x16/F64x2/F64x4/F64x8/I64x4` 改成直接委托对应 `ScalarZero*()` 真源。
- `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 已新增这 7 个 forwarder 的 source-side 断言，summary 从 `checks=413` 扩到 `checks=420`。
- 中途 helper checker 报过一次 `RISCVVZeroF32x4 missing fragment: Result := ScalarZeroF32x4();`，原因是首轮写成了无参标识符形式；已统一改为 `ScalarZero*()` 后通过。
- 轻量验证与 release 级收口已完成：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过，`NONX86_HELPER_SEMANTICS_SUMMARY checks=420 status=ok`

## 2026-05-12 RISCVV Shift Forwarder Consolidation

- 继续沿 `Wave 5 / retire + redundancy cleanup` 收 `RISCVV` no-ASM facade 里的 shift 重复体，把 11 个 `ShiftLeft/ShiftRight/ShiftRightArith` wrapper 收回 `ScalarShift*` 真源。
- `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 已把这 11 个 forwarder 收进 source-side 护栏，summary 从 `checks=420` 扩到 `checks=431`。
- 这批仍然不碰 `RcpF64x4`、rounding、clamp、Min/Max、asm path 或 `riscvv.register.inc` 的 slot ownership。
- 轻量验证与 release 级收口已完成：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过，`NONX86_HELPER_SEMANTICS_SUMMARY checks=431 status=ok`

## 2026-05-12 RISCVV I32x4 Shift Forwarder Consolidation

- 继续沿 `Wave 5 / retire + redundancy cleanup` 收 `RISCVV` no-ASM facade 里剩余的 `I32x4` shift 重复体，把 `ShiftLeft/ShiftRight/ShiftRightArith` 收回 `ScalarShift*` 真源。
- `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 已把这 3 个 forwarder 收进 source-side 护栏，summary 从 `checks=431` 扩到 `checks=434`。
- 这批仍然不碰 `Cmp*`、`Min/Max`、`Select/Extract/Insert`、asm path 或 `riscvv.register.inc` 的 slot ownership。
- 轻量验证与 release 级收口已完成：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过，`NONX86_HELPER_SEMANTICS_SUMMARY checks=434 status=ok`

## 2026-05-12 RISCVV Mask Helper Forwarder Consolidation

- 继续沿 `Wave 5 / retire + redundancy cleanup` 收 `RISCVV` no-ASM facade 里剩余的 mask helper 重复体，把 `Mask2/Mask4/Mask8/Mask16` 的 `All/Any/None/PopCount/FirstSet` 收回 `ScalarMask*` 真源。
- `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 已把这 20 个 forwarder 收进 source-side 护栏，summary 从 `checks=434` 扩到 `checks=454`。
- 这批仍然不碰 bitwise mask ops、select、extract/insert、asm path 或 `riscvv.register.inc` 的 slot ownership。
- 轻量验证与 release 级收口已完成：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过，`NONX86_HELPER_SEMANTICS_SUMMARY checks=454 status=ok`

## 2026-05-12 RISCVV Vector Math Exact Forwarder Consolidation

- 继续沿 `Wave 5 / retire + redundancy cleanup` 收 `RISCVV` no-ASM facade 里的 exact vector-math 重复体，把 `DotF32x4/F32x3`、`CrossF32x3`、`LengthF32x4/F32x3` 收回 `Scalar*` 真源。
- `NormalizeF32x4/F32x3` 先保留，因为 RISCVV 当前阈值是 `1e-10`，scalar 阈值是 `0.0`，不能按重复体直接合并。
- `DotF64x2/F64x4` 经 release 测试确认不能直接 scalar forward，已回退到本地实现；`check_nonx86_helper_semantics.py` 最终只收了 5 个 forwarder，summary 从 `checks=454` 扩到 `checks=459`。
- 轻量验证与 release 级收口已完成：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过，`NONX86_HELPER_SEMANTICS_SUMMARY checks=459 status=ok`

## 2026-05-12 Facade Hot-Path Dispatch Mirror

- 接上用户强调的“架构层级之间的调用要注意 inline / hot path”，本批不打开 family migration，也不继续扫 RISCVV 重复体。
- 现状确认：`dispatch` 仍是 control-plane truth，`dataplane` 仍是 published binding seam；但 `src/fafafa.core.simd.pas` 还有大量普通 façade wrapper 每次调用 `GetCurrentSimdDataPlaneDispatch`，热路径层级比当前目标多一跳。
- 本批目标：在 `simd.pas` 内维护一个只读 `PSimdDispatchTable` mirror，来源只允许是 `GetCurrentSimdDataPlane^.Dispatch`，并由 dispatch hook invalidate；普通 façade wrapper 改读本地 mirror。
- 已落地：`g_FastSimdDispatchPtr` 由 `RebindSimdFacadeFastPaths` 从 `PSimdDataPlane.Dispatch` 发布，dispatch hook invalidate 时同步清空；普通 façade wrapper 已统一改读 `GetSimdFacadeDispatchFastPath`。
- 已扩展机器护栏：`check_dispatch_read_scope.py` 除了继续封住消费者直读 `GetDispatchTable`，还会检查 `simd.pas` 不回退到 `GetCurrentSimdDataPlaneDispatch`，并要求本地 dispatch mirror 关键片段存在。
- Release 验证已完成：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_dispatch_read_scope.py`
  - `python3 tests/fafafa.core.simd/check_dispatch_read_scope.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DataPlane,TTestCase_DirectDispatch,TTestCase_DispatchAPI,TTestCase_RuntimeAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework,TTestCase_DirectDispatchConcurrent`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过；dispatch-read-scope summary 为 `forbidden_hits=0 active_doc_issues=0 facade_issues=0`。

## 2026-05-12 NEON Comment Hygiene

- 当前最适合做的卫生项不是再动实现，而是把 NEON include 里的项目过程标记清掉：`Task 6.2`、`Iteration 2.4`、`P2/P3/P4`、`✅` 这类噪音会让文件看起来像任务日志而不是稳定实现。
- 本批只清理 `src/fafafa.core.simd.neon.compare.inc`、`src/fafafa.core.simd.neon.scalar.utility.inc`、`src/fafafa.core.simd.neon.scalar.reduction.inc` 的注释标题，不改任何 NEON 函数体和调用链。
- 已完成清理：`✅`、`Task 6.2`、`Iteration 2.4`、`P2/P3/P4` 这类过程标记已从 NEON include 注释里移除，剩余标题改为中性语义标题。
- 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - 结果：通过，无新的 warning/hint 或门禁回退。

## 2026-05-12

- 开始做 `simd` 冗余卫生专项盘点，重点区分文档/计划层的重复 truth source 与源码层的真实重复实现。
- 当前初判：文档计划层的重复与交叉引用问题明显高于源码层，后续先把 active spine / historical baseline / superseded / deletion candidate 分类清楚。
- 已复核 `docs/plans/2026-05-10-simd-plan-status-index.md`、`execution index`、`global plan`、`family matrix`，确认当前 active spine 已经集中到 2026-05-09/10/11 链路。
- 已抽查旧顶层文档：`SIMD_MODULE_ANALYSIS`、`SIMD_COMPREHENSIVE_AUDIT_REPORT`、`SIMD_QUALITY_ITERATION_*`、`SIMD_ITERATIVE_OPTIMIZATION_PLAN` 都已自标为 internal/historical snapshot，不应再作为活真相源。
- 已做源码重复层初扫：当前最明显的是 `NEON/RISCVV` fallback 的大量 `Scalar*` thin forwarder，真实未收的重复实现体不多，剩余本地 loop 多数卡在 NaN / signed-zero / clamp / min-max 等语义敏感边界。
- 本批调查已收口：文档侧以 active spine + historical snapshot 分层为主，源码侧没有发现新的大面积 duplicate truth source；后续若再动，只应针对有 replacement/parity/checker 的 exact-contract fallback。
- 按建议已继续收口文档卫生：`docs/INDEX.md` 的过时 `docs/simd/` 导流已修正，`src/fafafa.core.simd.next-steps.md` 正式迁入 `docs/legacy/simd/`，原路径改为兼容占位。
- 当前新增一批历史快照归档，目标是把顶层 `SIMD_*` / `NEON_*` 历史分析、审计、迭代报告全部从活入口挪走，只保留占位和 legacy 导流。
- `docs/legacy/simd/README.md` 已补齐，当前活入口现在只指向索引页，不再把历史快照目录当成散落文件夹看待。
