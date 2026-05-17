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

## 2026-05-15 NEON Narrow F64x2 Memory/Construction Slot Cleanup

- 接手上一批 `NEON Extract/Insert/Select` 收口后的真实工作树，确认当前未提交改动集中在：
  - `src/fafafa.core.simd.neon.register.inc`
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc`
  - `tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - 以及需在收口前清理的 `tests/fafafa.core.simd/__pycache__/`
- 先锁定当前最干净的下一簇 residual：
  - `NEONLoadF64x2`
  - `NEONStoreF64x2`
  - `NEONSplatF64x2`
  - `NEONZeroF64x2`
  - 它们当前全仓只命中 `neon.pas / neon.scalar.autowrap.inc / neon.register.inc`，没有其他 live source consumer
- 已落地的源码/测试收口：
  - 从 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 删除 4 个 no-asm dead wrapper
  - 把 `src/fafafa.core.simd.neon.register.inc` 中这 4 个 slot 改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定
  - `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 已把这 4 个名字改成 absent guard
  - `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 已从 `NEON` wrapper allowlist 删除这 4 个名字
  - `dispatchapi` 新增 `Test_NEON_NoAsmNarrowF64MemorySlots_Reuse_BaseScalar_When_Wrappers_Have_No_Live_SourceConsumers`
  - `dispatchapi` 两处通用 capability 断言也已同步收正：
    - `LoadF64x2 / SplatF64x2`
    - `ZeroF64x2`
- 本批串行 release 验证链已经 fresh 跑通：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- fresh 结果：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=629 status=ok`
  - `backend=neon assignments=342 asm_exact=248 asm_suffix_only=10 wrapper_only=84 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `backend=riscvv assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `check` 通过
  - Release `gate` 通过，尾部仍只诚实保留：
    - optional non-x86 native evidence verify skip
    - 历史 `windows_b07_gate.log` evidence verify fail -> optional `SKIP`
- 当前阶段结论：
  - `NEON` 当前 `wrapper_only` 已从上一批的 `88` 进一步降到 `84`
  - 这 4 个 narrow `F64x2` memory/construction slot 已不再占着 no-asm fake backend-owned truth

## 2026-05-15 NEON No-Asm F64x4 Wide Leaf Arithmetic Slot-Ownership Cleanup

- 接着上一批 `F64x2` residual 继续往下切，先用 `check_nonx86_register_truthfulness.py` 的内部分类把 `NEON wrapper_only=84` 拆成：
  - `('always', 'pascal_owned') = 36`
  - `('asm-only', 'pascal_owned') = 16`
  - `('no-asm', 'pascal_owned') = 32`
- 其中最干净、最像上一轮 wide-leaf arithmetic 模式的一簇是：
  - `AddF64x4`
  - `SubF64x4`
  - `MulF64x4`
  - `DivF64x4`
- 已确认它们的真实 source role：
  - `src/fafafa.core.simd.neon.pas` 里仍有真实 asm leaf
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc` 里的 no-asm body 只是两次 `NEON*F64x2`
  - `NEONAdd/Sub/Mul/DivF64x8` 仍继续消费这些 `F64x4` wrapper
  - 因而这批应“回收 no-asm slot ownership”，而不是“删除 wrapper”
- 已落地的代码/测试收口：
  - `src/fafafa.core.simd.neon.register.inc` 中 `Add/Sub/Mul/DivF64x4` 已改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc` 未删除对应 wrapper，继续保留 source companion
  - `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 已从 `NEON` allowlist 删除这 4 个名字
  - `Test_NEON_NoAsmWideLeafFloatArithmeticSlots_Keep_SourceCompanions_But_Reuse_BaseScalar` 已扩到 `F64x4`
  - 两处通用 `DispatchAPI` 宽浮点 capability 断言里，`Add/Sub/Mul/DivF64x4` 已从“总是 native”收正为 `AssertNeonReusesScalarOtherwiseNative(...)`
- 本批串行 release 验证链已经 fresh 跑通：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- fresh 结果：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=629 status=ok`
  - `backend=neon assignments=342 asm_exact=252 asm_suffix_only=10 wrapper_only=80 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `backend=riscvv assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `check` 通过
  - Release `gate` 通过，尾部仍只诚实保留：
    - optional non-x86 native evidence verify skip
    - 历史 `windows_b07_gate.log` evidence verify fail -> optional `SKIP`
- 当前阶段结论：
  - `NEON` 当前 `wrapper_only` 已从上一批的 `84` 进一步降到 `80`
  - `Add/Sub/Mul/DivF64x4` 已不再占着 no-asm fake backend-owned truth，同时 source companion 仍完整保留

## 2026-05-15 NEON No-Asm Wide Round/Trunc Slot-Ownership Cleanup

## 2026-05-17 Windows Closeout Billing Warning Rehearsal

- 当前 worktree 未提交收口批次只剩两处：
  - `tests/fafafa.core.simd/BuildOrTest.sh`
  - `tests/fafafa.core.simd/rehearse_windows_closeout_3cmd.sh`
- 这批改动不碰 SIMD 实现层，只补 `win-closeout-3cmd` 的 fail-close 自检：
  - 新增 `rehearse_windows_closeout_3cmd.sh`
  - `BuildOrTest.sh` 新增 `win-closeout-3cmd-rehearsal` 入口
  - `gate-summary-selfcheck` 现在会强制跑这条 rehearsal
  - `runner-parity` 现在也静态钉住 batch 侧 `RECENT_BILLING_BLOCK` warning 签名
- fresh 验证已完成：
  - `bash tests/fafafa.core.simd/rehearse_windows_closeout_3cmd.sh` -> `OK`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary-selfcheck` -> `OK`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh runner-parity` -> `OK`
- 当前结论没有变化：
  - repo 内 closeout 入口提示已收紧并具备自检
  - 真正剩余 blocker 仍是 `freeze-status` 里的 Windows external evidence：`RECENT_BILLING_BLOCK` + `windows_evidence_verify=FAIL`

## 2026-05-17 Active Closeout Docs Preflight Caveat Sync

## 2026-05-17 SSE Experimental Intrinsics Comment-Hygiene Closeout

- 在 `intrinsics umbrella` 收口后，没有立刻跳去 `mmx` 或 `intrinsics.x86.sse2` 的大残点，而是先把当前工作树里唯一未收口的
  `src/fafafa.core.simd.intrinsics.sse.pas`
  彻底收口。
- 这批保持严格 bounded：
  - 只把文件头、分节说明和逐函数说明里的 `U+FFFD` 损坏注释改成稳定 ASCII 注释
  - 不改任何函数签名
  - 不改任何实现逻辑
- fresh 验证已完成：
  - `python3` 逐文件计数：`src/fafafa.core.simd.intrinsics.sse.pas = 0`
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_intrinsics_comment_swallow.py --summary-line`
  - `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `INTR_HYGIENE_SUMMARY status=PASS hits=0`
  - `intrinsics.experimental` default / experimental 双模态 `check` 全绿
  - 其中 `SSE backend smoke` 明确通过，说明这次改动文件已被真实编译覆盖
  - 主 `simd` release `check` 全绿
- 当前阶段结论：
  - 这批确认只是 `SSE experimental intrinsics` 的源码文本卫生收口，不涉及行为修复
  - `sse.pas` 的 `U+FFFD` 已清零，且没有引入新的注释吞源码或编译回归

## 2026-05-17 MMX X86 Comment-Swallowed Instruction Recovery

- `sse.pas` 收口并提交后，fresh residual 扫描没有直接跳进 `intrinsics.x86.sse2` 大坑，而是先复核更小的 `src/fafafa.core.simd.intrinsics.mmx.pas`。
- 这次抓到的不是普通注释脏点，而是 5 处真实 x86 asm 指令被注释吞进同一行：
  - `mmx_movd_mm` 的 `mov eax, Ptr`
  - `mmx_movd_mm_store` 的 `movq mm0, qword ptr [Src]`
  - `mmx_movq_mm` 的 `mov eax, Ptr`
  - `mmx_movq_mm_store` 的 `movq mm0, qword ptr [Src]`
  - `mmx_paddb` 的 `movq mm0, qword ptr [a]`
- 这意味着在 x86 非 64 位路径上，原文件不是“只剩乱码”，而是已经可能出现：
  - 使用未初始化的 `eax`
  - 使用未初始化的 `mm0`
  - x86-only 路径静默偏离 x86_64 对应实现
- 本批正确收口方式保持 bounded：
  - `src/fafafa.core.simd.intrinsics.mmx.pas`
    - 恢复这 5 条被注释吞掉的 x86 指令
    - 把对应注释改成稳定单独行，避免再次吞指令
  - `tests/fafafa.core.simd/check_intrinsics_comment_swallow.py`
    - 补齐 `参数通过栈` 这一类 marker，让现有 intrinsics hygiene checker 能直接抓这类 x86 asm comment-swallow
- fresh 验证已完成：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_intrinsics_comment_swallow.py --summary-line`
  - `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `INTR_HYGIENE_SUMMARY status=PASS hits=0`
  - `intrinsics.experimental` default / experimental 双模态 `check` 全绿
  - `MMX backend smoke` 明确通过
  - 主 `simd` release `check` 全绿
- 当前阶段结论：
  - 这批修掉的是 `MMX` x86 专属路径的真实 source-level behavior bug，不只是注释卫生
  - 后续如果再出现同类“x86 参数说明注释把汇编指令吞掉”，现有 intrinsics hygiene checker 会直接 fail-close

## 2026-05-17 MMX Front-Half Comment-Hygiene Reduction

- 在 `mmx` x86 指令恢复批次提交后，没有马上去碰 `intrinsics.x86.sse2`，而是继续把同一个 `mmx` 文件切成更小的 comment-hygiene 子簇。
- 本批只处理 `src/fafafa.core.simd.intrinsics.mmx.pas` 前半段：
  - 文件头说明
  - interface 区分节说明
  - extra helper declaration 注释
  - `Load/Store`、`Set/Zero`、`mmx_paddb` 前的说明性注释
- 本批保持严格 bounded：
  - 不改任何函数签名
  - 不改任何汇编实现
  - 不扩 checker 逻辑
  - 只把 `1..340` 行范围里的损坏注释换成稳定 ASCII 注释
- fresh 验证已完成：
  - `python3` 计数：
    - `prefix_1_340=0`
    - `total=157`
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_intrinsics_comment_swallow.py --summary-line`
  - `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `INTR_HYGIENE_SUMMARY status=PASS hits=0`
  - `intrinsics.experimental` default / experimental 双模态 `check` 全绿
  - `MMX backend smoke` 继续通过
  - 主 `simd` release `check` 全绿
- 当前阶段结论：
  - 这批是 `mmx` 的 bounded text-hygiene 收口，不涉及语义修复
  - `mmx` 文件总残量已从 `245` 继续压到 `157`
  - 当前最干净的继续方向仍然是沿 `mmx` 剩余残点继续分段收口，而不是贸然切进 `intrinsics.x86.sse2`

## 2026-05-17 MMX Arithmetic Comment-Hygiene Reduction

- 在 `mmx` 前半段批次提交后，继续顺着同一文件下切，没有换目标，也没有扩大到整文件。
- 本批只处理 `src/fafafa.core.simd.intrinsics.mmx.pas` 的 `341..760` 行：
  - `paddw/paddd/paddq`
  - `paddsb/paddsw/paddusb/paddusw`
  - `psubb/psubw/psubd/psubq`
  - `psubsb/psubsw/psubusb/psubusw`
  - 这些算术函数前的说明性注释
- 本批保持严格 bounded：
  - 不改任何函数签名
  - 不改任何汇编实现
  - 只把这段算术注释中的 `U+FFFD` 损坏替换成稳定 ASCII 注释
- fresh 验证已完成：
  - `python3` 计数：
    - `range_341_760=0`
    - `total=102`
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_intrinsics_comment_swallow.py --summary-line`
  - `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `INTR_HYGIENE_SUMMARY status=PASS hits=0`
  - `intrinsics.experimental` default / experimental 双模态 `check` 全绿
  - `MMX backend smoke` 再次通过
  - 主 `simd` release `check` 全绿
- 当前阶段结论：
  - 这批继续属于 `mmx` 的 bounded text-hygiene 收口，不涉及行为修复
  - `mmx` 文件总残量已从 `157` 继续压到 `102`
  - 到这里 `mmx` 的 header / helper declaration / load-store / set-zero / arithmetic comment 段已经全部清干净

## 2026-05-17 MMX Mul Logical Compare Comment-Hygiene Reduction

- 在 `mmx` arithmetic 批次提交后，继续沿同一文件往下切，只处理 `mul/logical/compare` 这一个小簇。
- 本批只处理 `src/fafafa.core.simd.intrinsics.mmx.pas` 的 `761..1139` 行：
  - `pmullw/pmulhw/pmaddwd`
  - `pandn`
  - `pcmpeqb/pcmpeqw/pcmpeqd`
  - `pcmpgtb/pcmpgtw/pcmpgtd`
  - 对应说明性注释
- 本批保持严格 bounded：
  - 不改任何函数签名
  - 不改任何汇编实现
  - 只把这段里的损坏注释替换成稳定 ASCII 注释
- fresh 验证已完成：
  - `python3` 计数：
    - `range_761_1139=0`
    - `total=65`
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_intrinsics_comment_swallow.py --summary-line`
  - `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `INTR_HYGIENE_SUMMARY status=PASS hits=0`
  - `intrinsics.experimental` default / experimental 双模态 `check` 全绿
  - `MMX backend smoke` 继续通过
  - 主 `simd` release `check` 全绿
- 当前阶段结论：
  - 这批继续属于 `mmx` 的 bounded text-hygiene 收口，不涉及行为修复
  - `mmx` 文件总残量已从 `102` 继续压到 `65`
  - 当前剩余主要落在 `shift / pack / unpack / extra helper tail` 段

## 2026-05-17 MMX Shift Comment-Hygiene Reduction

- 在 `mmx` `mul/logical/compare` 批次提交后，继续沿同一文件下切，这次只处理 `shift` 段。
- 本批只处理 `src/fafafa.core.simd.intrinsics.mmx.pas` 的 `1143..1571` 行：
  - `psllw/pslld/psllq`
  - `psllw_imm/pslld_imm/psllq_imm`
  - `psrlw/psrld/psrlq`
  - `psrlw_imm/psrld_imm/psrlq_imm`
  - `psraw/psrad`
  - `psraw_imm/psrad_imm`
  - 对应说明性注释
- 本批保持严格 bounded：
  - 不改任何函数签名
  - 不改任何汇编实现
  - 只把这段里的损坏注释换成稳定 ASCII 注释
- fresh 验证已完成：
  - `python3` 计数：
    - `range_1143_1571=0`
    - `total=38`
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_intrinsics_comment_swallow.py --summary-line`
  - `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `INTR_HYGIENE_SUMMARY status=PASS hits=0`
  - `intrinsics.experimental` default / experimental 双模态 `check` 全绿
  - `MMX backend smoke` 继续通过
  - 主 `simd` release `check` 全绿
- 当前阶段结论：
  - 这批继续属于 `mmx` 的 bounded text-hygiene 收口，不涉及行为修复
  - `mmx` 文件总残量已从 `65` 继续压到 `38`
  - 当前剩余已经主要缩到 `pack/unpack + extra helper tail`

- 在 code batch 提交并推送后，继续按“只查 closeout 入口误导点”的边界做了一轮 active docs 审查。
- 新抓到的 residual 不是实现层，而是部分 active 文档仍把：
  - `closeout-release`
  - `win-evidence-via-gh`
  - 旧的 “Windows 实机证据已闭环”
  写得太像当前 `HEAD` 的无条件 readiness 结论。
- 已补的真相源同步：
  - `docs/fafafa.core.simd.handoff.md`
  - `docs/fafafa.core.simd.checklist.md`
  - `tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md`
  - `tests/fafafa.core.simd/docs/simd_completeness_matrix.md`
- 统一口径：
  - `closeout-release` 仍是官方入口，但当前必须先过 `win-evidence-preflight`
  - 若 latest preflight 仍为 `RECENT_BILLING_BLOCK`，则在 preflight 处 fail-close，状态记为 `code-green / release-evidence-blocked`
  - matrix 里的 “Windows 实机证据已闭环” 仅是历史归档事实，不是当前 `HEAD` 的 readiness signal
- fresh 轻量验证已完成：
  - `git diff --check`
  - `rg -n "RECENT_BILLING_BLOCK|code-green / release-evidence-blocked|历史归档事实|当前 HEAD 额外前提|fail-close 条件" ...`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh runner-parity`
  - 结果：全部通过

## 2026-05-17 Windows Runbook Header Stop-Note Sync

- 在 active docs 已补 caveat 后，又继续做了一轮“只查 Windows 专属 runbook 页头”的扫尾。
- `tests/fafafa.core.simd/docs/windows_b07_closeout_runbook.md` 原先仍像通用 `cross-ready` 指南：
  - 更新时间停在 `2026-04-16`
  - 顶部没有把 latest `RECENT_BILLING_BLOCK` 前置成当前 stop note
- 已收口：
  - 更新时间改到 `2026-05-17`
  - 页头新增 `当前停点（2026-05-17）`
  - 明确写死：在 Billing/额度恢复或切到真实 Windows runner 前，这页只按流程 runbook 理解，当前状态仍是 `code-green / release-evidence-blocked`
- fresh 轻量验证已完成：
  - `git diff --check`
  - `sed -n '1,18p' tests/fafafa.core.simd/docs/windows_b07_closeout_runbook.md`

## 2026-05-17 Closeout-Release Preflight Fail-Close Hardening

- 继续往下收后，锁定了一个真正落在主入口上的 residual：
  - `closeout-release` 虽然会先跑 `win-evidence-preflight`
  - 但在 `RECENT_BILLING_BLOCK` 时，只会直接失败退出，不会把“当前应停止 / 当前状态 / 下一步该跑什么”作为主入口语义明确打印出来
- 本批实现收口：
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - 新增 `win_preflight_latest_json_path`
    - 新增 `win_preflight_latest_is_recent_billing_block`
    - 新增 `print_closeout_release_preflight_block_note`
    - `run_closeout_release()` 现在在 preflight 返回 `31` 且 latest JSON 为 `RECENT_BILLING_BLOCK` 时，直接打印 stop note 与 next actions
  - 新增 `tests/fafafa.core.simd/rehearse_closeout_release_preflight_block.sh`
    - 用 stubbed shell 环境抽取 `run_closeout_release` 相关函数
    - 断言 preflight blocked 时：
      - 返回码仍是 `31`
      - 会打印 `STOP latest preflight is RECENT_BILLING_BLOCK`
      - 会打印 `code-green / release-evidence-blocked`
      - 不会继续跑 GH step / freeze step
  - `gate-summary-selfcheck` 现已纳入这条 rehearsal
- 这批过程中还顺手抓到并修掉一个真 bug：
  - 第一版实现里用了 `if ! run_win_evidence_preflight; then LPreflightRC=$?`
  - focused rehearsal 证明这样拿到的是 `!` 反转后的 `0`，stop note 根本不会触发
  - 已改成 `if run_win_evidence_preflight; then : else LPreflightRC=$?; ... fi`
- fresh 验证已完成：
  - `git diff --check`
  - `bash tests/fafafa.core.simd/rehearse_closeout_release_preflight_block.sh`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary-selfcheck`
  - 抽取式静态 guard：
    - `check_closeout_release_entrypoint_guard` -> `OK`

- 接着上一批 `F64x4` arithmetic residual 继续往下切，本轮先锁定 wide `Round/Trunc`：
  - `RoundF32x8`
  - `RoundF32x16`
  - `RoundF64x4`
  - `RoundF64x8`
  - `TruncF32x8`
  - `TruncF32x16`
  - `TruncF64x4`
  - `TruncF64x8`
- 先依据 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 复核 no-asm source graph：
  - `Round/TruncF32x8` 都只是两次 `*F32x4`
  - `Round/TruncF32x16` 直接展开到四个 `*F32x4`
  - `Round/TruncF64x8` 继续消费 `Round/TruncF64x4`
  - `Round/TruncF64x4` 再消费 `Round/TruncF64x2`
  - 因而 `F32x8/F32x16/F64x8` 属于 dead wrapper，`F64x4` 属于应保留的 source companion，`F64x2` 继续保持 backend-owned
- 已落地的源码/测试收口：
  - `src/fafafa.core.simd.neon.register.inc`
    - 把 `Round/TruncF32x8/F32x16/F64x4/F64x8` 改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc`
    - 删除 `NEONRoundF32x8`
    - 删除 `NEONRoundF32x16`
    - 删除 `NEONRoundF64x8`
    - 删除 `NEONTruncF32x8`
    - 删除 `NEONTruncF32x16`
    - 删除 `NEONTruncF64x8`
    - 保留 `NEONRoundF64x4`
    - 保留 `NEONTruncF64x4`
  - `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
    - 从 `NEON` allowlist 删除 wide `Round/Trunc` 名字，仅保留 `RoundF64x2` / `TruncF64x2`
  - `tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
    - 把被删除的 6 个 wrapper 改成 absent guard
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
    - 新增 `Test_NEON_NoAsmWideRoundTruncSlots_Keep_Only_Consumed_Companions_And_Reuse_BaseScalar`
    - 两处 wide `Round/Trunc` capability 断言从 `AssertNativeSlotNotScalar(...)` 收正为 `AssertNeonReusesScalarOtherwiseNative(...)`
- 本批 fresh 复验已经完成：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前结果：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=635 status=ok`
  - `backend=neon` truthfulness：`assignments=342 asm_exact=260 asm_suffix_only=10 wrapper_only=72 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `backend=riscvv` truthfulness：`assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `check` 通过
  - Release `gate` 通过，尾部仍只诚实保留：
    - optional non-x86 native evidence verify skip
    - 历史 `windows_b07_gate.log` evidence verify fail -> optional `SKIP`
- 当前阶段结论：
  - `NEON` 当前 `wrapper_only` 已从上一批的 `80` 进一步降到 `72`
  - `Round/TruncF32x8/F32x16/F64x8` 的 no-asm dead wrapper 已清掉
  - `Round/TruncF64x4` source companion 仍完整保留，但 published slot 已回到 base scalar truth

## 2026-05-15 NEON No-Asm Narrow F64 Compare/Simple Reduction Slot Cleanup

- 继续沿 fresh residual 往下切，这一批选择 8 个最干净的窄 `F64x2` compare/simple reduction slot：
  - `CmpEqF64x2`
  - `CmpGeF64x2`
  - `CmpGtF64x2`
  - `CmpLeF64x2`
  - `CmpLtF64x2`
  - `CmpNeF64x2`
  - `ReduceAddF64x2`
  - `ReduceMulF64x2`
- 选这批的理由已经核实为两点同时成立：
  - 它们在 `src/` 内只剩 `neon.pas / register.inc / scalar.autowrap.inc`，没有更宽 no-asm consumer
  - 其 no-asm body 与 `ScalarCmp*F64x2`、`ScalarReduceAdd/ReduceMulF64x2` 逐字同义，不像 `Clamp/Max/Min/ReduceMax/ReduceMinF64x2` 那样还保留本地 fallback 语义争议
- 已落地的源码/测试收口：
  - `src/fafafa.core.simd.neon.register.inc`
    - 把 `CmpEq/Ge/Gt/Le/Lt/NeF64x2` 改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定
    - 把 `ReduceAdd/ReduceMulF64x2` 改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc`
    - 删除 `NEONCmpEqF64x2`
    - 删除 `NEONCmpGeF64x2`
    - 删除 `NEONCmpGtF64x2`
    - 删除 `NEONCmpLeF64x2`
    - 删除 `NEONCmpLtF64x2`
    - 删除 `NEONCmpNeF64x2`
    - 删除 `NEONReduceAddF64x2`
    - 删除 `NEONReduceMulF64x2`
  - `tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
    - 把这 8 个名字改成 absent guard
  - `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
    - 从 `NEON` allowlist 删除 6 个 compare 与 `ReduceAdd/ReduceMulF64x2`
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
    - 新增 `Test_NEON_NoAsmNarrowF64CompareAndSimpleReductionSlots_Reuse_BaseScalar_When_Wrappers_Have_No_SourceConsumers`
- 本批 fresh 复验已经完成：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前结果：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=643 status=ok`
  - `backend=neon` truthfulness：`assignments=342 asm_exact=268 asm_suffix_only=10 wrapper_only=64 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `backend=riscvv` truthfulness：`assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `check` 通过
  - Release `gate` 通过，尾部仍只诚实保留：
    - optional non-x86 native evidence verify skip
    - 历史 `windows_b07_gate.log` evidence verify fail -> optional `SKIP`
- 当前阶段结论：
  - `NEON` 当前 `wrapper_only` 已从上一批的 `72` 进一步降到 `64`
  - 这 8 个 `F64x2` compare/simple reduction no-asm dead wrapper 已清掉
  - fresh residual 进一步收敛到仍带本地 fallback 语义或仍有 source companion 价值的 `F64` 家族

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

- 继续沿宽整数 façade 的 direct-evidence 缺口往下补后，本轮继续扩了 `TTestCase_IntegerFacadeGuards`，没有新增 runner/suite 结构，也没有修改任何生产实现：
  - `Test_VecI32x16_RemainingOps_Basic`
  - `Test_VecU32x16_RemainingOps_Basic`
  - `Test_VecI64x8_RemainingOps_Basic`
  - `Test_VecU64x8_RemainingOps_Basic`
- 这 4 条测试把此前主要只有 parity 旁证的公开 façade 操作补成了固定 `sbScalar` 的 direct guard，覆盖：
  - `I32x16`：`Add/Sub/Mul/And/Or/Xor/Not/ShiftLeft/ShiftRight/ShiftRightArith/Min/Max/Extract/Insert`
  - `U32x16`：`Add/Sub/Mul/And/Or/Xor/Not/ShiftLeft/ShiftRight/Min/Max`
  - `I64x8`：`Add/Sub/And/Or/Xor/Not`
  - `U64x8`：`Add/Sub/And/Or/Xor/Not/ShiftLeft/ShiftRight`
- 首次 targeted run 抓到 1 个测试层红灯，不是实现回归：
  - `TTestCase_IntegerFacadeGuards.Test_VecU32x16_RemainingOps_Basic`
  - `VecU32x16Sub lane 0` 期望没有显式收成 `UInt32`，把 `0 - High(UInt32)` 错按负值解释
  - 修正为 `UInt32(...)` 后立即转绿
- 本轮 Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IntegerFacadeGuards`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口前已清理 `tests/fafafa.core.simd/__pycache__/`，避免把 Python 缓存目录带进提交。

- 继续把宽整数剩余公开 façade 往 `sbScalar` direct evidence 收口后，本轮再次扩了 `TTestCase_IntegerFacadeGuards`，仍然没有新增 runner/suite，也没有修改任何生产实现：
  - `Test_VecI16x32_RemainingOps_Basic`
  - `Test_VecI8x64_RemainingOps_Basic`
  - `Test_VecU8x64_RemainingOps_Basic`
- 这 3 条测试把此前主要只有 parity 旁证的公开 façade 操作补成了固定 `sbScalar` 的 direct guard，覆盖：
  - `I16x32`：`Add/Sub/And/Or/Xor/Not/ShiftLeft/ShiftRight/ShiftRightArith/Min/Max`
  - `I8x64`：`Add/Sub/And/Or/Xor/Not/Min/Max`
  - `U8x64`：`Add/Sub/And/Or/Xor/Not/Min/Max`
- 本轮先后两次尝试 `mcp__ace_tool__search_context` 都超时了，因此没有在同一条失败路径上反复等待，而是改用本地 `rg/sed` 直接核 API 与测试覆盖。
- 首次 targeted run 抓到 1 个测试层红灯，不是实现回归：
  - `TTestCase_IntegerFacadeGuards.Test_VecI16x32_RemainingOps_Basic`
  - `VecI16x32ShiftLeft lane 0` 期望没有显式收回 16-bit lane，直接拿了更宽的移位结果
  - 修正为 `Word(...)` 后立即转绿
- 本轮 Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IntegerFacadeGuards`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
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

## 2026-05-12 Deep Review Refresh

- 继续沿 scratch 主线做“缺失与冗余”复核，没有重开架构争论，先重新对齐：
  - `plans/scratch/2026-04-08-simd-review/findings.md`
  - `plans/scratch/2026-04-08-simd-review/task_plan.md`
  - `docs/plans/2026-05-10-simd-plan-status-index.md`
  - `docs/plans/2026-05-10-simd-execution-index.md`
  - `docs/plans/2026-05-11-simd-family-decision-baseline.md`
  - `docs/plans/2026-05-09-simd-experimental-hold-future-trigger-plan.md`
- 重新抽查当前 alias 面和 active/historical 文档入口：
  - `src/fafafa.core.simd.framework.intf.inc`
  - `src/fafafa.core.simd.cpuinfo.pas`
  - `docs/SIMD_MODULE_ANALYSIS.md`
  - `docs/NEON_ASM_IMPLEMENTATION_STATUS.md`
  - `docs/NEON_MATH_OPTIMIZATION_ITERATION_2.5.md`
  - `docs/SIMD_COMPREHENSIVE_AUDIT_REPORT.md`
- 当前 live 机器护栏复验：
  - `python3 tests/fafafa.core.simd/check_intrinsics_experimental_status.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_dispatch_read_scope.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - 结果：全部通过
- 当前 non-x86 implementation audit fresh 复验：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - 结果：PASS
  - 关键摘要：
    - `helper-semantics` OK
    - `wiring-sync` OK
    - `riscvv-abi-shape` OK
    - `register-truthfulness`（`neon` / `riscvv`）OK
    - `key-slot-audit` OK
    - `targeted-release-suites` OK
    - `native_evidence=skip`
- 当前 freeze 复验：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
  - 结果：FAIL
  - 真实阻塞已重新确认：
    - `qemu-cpuinfo-nonx86-evidence=SKIP`
    - `gate_summary.md` 旧于最新源码 `src/fafafa.core.simd.neon.compare.inc`
    - `windows_b07_gate.log` / `windows_b07_closeout_summary.md` stale
- 当前判断更新：
  - seam / intrinsics isolation / non-x86 helper semantics 没有新红点
  - 真正剩余缺失优先级已改写为：
    1. release evidence freshness
    2. canonical vs legacy alias visibility policy
    3. hold family future-trigger granularity
  - 真正剩余冗余优先级已改写为：
    1. API naming alias redundancy
    2. top-level historical placeholder docs 与 active truth docs 同目录并列造成的搜索噪音

## 2026-05-12 Plan Implementation

- 已按实施方案落地 alias visibility / historical placeholder / hold-family trigger / evidence blocker 文档收口，没有触碰 SIMD 行为语义。
- 已更新的 source/doc 主链包括：
  - `src/fafafa.core.simd.framework.intf.inc`
  - `src/fafafa.core.simd.cpuinfo.pas`
  - `docs/fafafa.core.simd.interface.md`
  - `docs/fafafa.core.simd.md`
  - `docs/fafafa.core.simd.cpuinfo.md`
  - `src/fafafa.core.simd.README.md`
  - `docs/plans/2026-05-09-simd-experimental-hold-future-trigger-plan.md`
  - `docs/plans/2026-05-11-simd-family-decision-baseline.md`
  - `docs/plans/2026-05-09-simd-family-matrix.md`
  - `docs/fafafa.core.simd.closeout.md`
  - `docs/fafafa.core.simd.checklist.md`
  - `docs/fafafa.core.simd.handoff.md`
  - `src/fafafa.core.simd.STABLE`
- 历史占位页也已统一成强导流模板，并在 `docs/legacy/simd/README.md` 明写“顶层单页只是 path-preserving stubs”。
- fresh verification 已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
- 验证结果更新：
  - `check`：PASS
  - `gate`：PASS
  - `freeze-status`：FAIL，但最新 gate artifact freshness 已回绿
  - 当前剩余红点只剩：
    - `qemu-cpuinfo-nonx86-evidence=SKIP`
    - stale Windows evidence (`windows_b07_gate.log` / `windows_b07_closeout_summary.md`)
- 当前判断：
  - 仓库内计划项已收口
  - `code-green / release-evidence-blocked` 仍是最准确状态
  - 下一步不该回头重开 SIMD 接口/结构争论，而应在条件允许时只刷新 QEMU CPUINFO + Windows evidence lane

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

## 2026-05-12 SIMD Source Reachability Hygiene

- 已对 `src/fafafa.core.simd*.inc` 做 transitive include 闭包复核，确认先前 `neon.scalar.compare/math/...` 那批并非死文件，而是经由 `fafafa.core.simd.neon.scalar_fallback.inc` 间接挂接。
- 已确认 `fafafa.core.simd.neon.scalar.wide_memory.inc` 虽然不在当前编译链，但仍被 `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 作为 audit-only 样本读取，因此保留。
- 已确认下列源码当前没有任何 live source 挂接路径，可直接删除：
  - `src/fafafa.core.simd.cpuinfo.x86.asm.pas`
  - `src/fafafa.core.simd.neon.scalar.wide_reduce.inc`
  - `src/fafafa.core.simd.sse2.ext_math.inc`
  - `src/fafafa.core.simd.sse2.f32x8_arith.inc`
  - `src/fafafa.core.simd.sse2.f32x8_compare.inc`
  - `src/fafafa.core.simd.sse2.facade_extra.inc`
  - `src/fafafa.core.simd.sse2.i64x2_arith.inc`
  - `src/fafafa.core.simd.sse2.mask.inc`
  - `src/fafafa.core.simd.sse2.memory.inc`
  - `src/fafafa.core.simd.sse2.saturating.inc`
- 上述 SSE2 `.inc` 都是与 `src/fafafa.core.simd.sse2.pas` 内现有实现重复的历史残片；`cpuinfo.x86.asm.pas` 则是无人使用且本身还带残缺占位代码的死单元。
- 已新增 `tests/fafafa.core.simd/check_simd_source_reachability.py`，并接入 `tests/fafafa.core.simd/BuildOrTest.sh check`，用于防止 future batch 再落入“文件存在但永远不进 live source 链”的影子实现。

## 2026-05-12 RISCVV Helper Include Forwarder Hygiene

- 本轮继续深审 `riscvv.helpers.inc`，先确认 checker 当前主要锁的是 `riscvv.facade.inc` forwarder，而 helper include 自身还没有 direct source-side 护栏。
- 已确认本批最稳的 exact-contract 重复体只有 8 个：
  - `RISCVVAddU64x2`
  - `RISCVVSubU64x2`
  - `RISCVVAndU64x2`
  - `RISCVVOrU64x2`
  - `RISCVVXorU64x2`
  - `RISCVVNotU64x2`
  - `RISCVVAndNotI64x2`
  - `RISCVVAndNotU64x2`
- 这些 helper 现在都改成直调 `Scalar*` 真源，去掉了 helper include 内第二份逐 lane truth source。
- `Min/Max`、unsigned `CmpLt/CmpGtU64x2`、shift、reduction、`Load/Store/Splat/Zero/Select` 这一轮都明确保留，不为了“看起来像 loop”就硬合并。
- `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 已新增 `RISCVV_HELPERS_FILE` 并直接读取 `src/fafafa.core.simd.riscvv.helpers.inc`，把这 8 个 helper wrapper 锁进 source-side 护栏。
- 轻量验证与 release 级收口已完成：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过，`NONX86_HELPER_SEMANTICS_SUMMARY checks=467 status=ok`

## 2026-05-12 RISCVV Helper Compare/Shift Forwarder Hygiene

- 先复核了两个候选方向：
  - `riscvv.helpers.inc` 剩余的 `U64x2` compare/minmax 与 `I64x2` shift
  - `avx512.i32x16_shift.inc` 的 invalid-count contract
- 结论是 `AVX512ShiftRightArithI32x16` 当前不属于“缺失护栏”：
  - 现有 `dispatchapi` 边界测试已经明确覆盖 `ShiftRightArithI32x16` 的 `c=-1/32/64`，以及 `ShiftLeftI32x16` 的 `c=64`。
  - 因而本批没有再去改 AVX-512 源码或追加重复测试。
- 已确认 `riscvv.helpers.inc` 里这 8 个 helper 与 scalar 侧完全同合同，且现有 dispatch/parity 测试已覆盖：
  - `RISCVVCmpEqU64x2`
  - `RISCVVCmpLtU64x2`
  - `RISCVVCmpGtU64x2`
  - `RISCVVMinU64x2`
  - `RISCVVMaxU64x2`
  - `RISCVVShiftLeftI64x2`
  - `RISCVVShiftRightI64x2`
  - `RISCVVShiftRightArithI64x2`
- 这些 helper 现在都改成直调 `ScalarCmp* / ScalarMin/Max* / ScalarShift*` 真源，继续收掉 helper include 内第二份逻辑。
- 本轮仍然明确不碰：
  - `U64x2` shift（当前没有现成同名 scalar helper）
  - reduction
  - `Load/Store/Splat/Zero/Select`
  - 其它未再次证明为 exact-contract 的路径
- `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 已把这 8 个 helper 加入 `riscvv_helper_scalar_forwarder_expectations`，summary 从 `checks=467` 扩到 `checks=475`。
- 轻量验证与 release 级收口已完成：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过，`NONX86_HELPER_SEMANTICS_SUMMARY checks=475 status=ok`

## 2026-05-12 Scalar AndNot Truth Closure

- 继续深审 `AndNot` 合同时，先把 `scalar / dispatch / facade / riscvv / tests` 五处对齐，确认仓库的公开口径始终是 `AndNot(a, b) = (NOT a) AND b`，与 `PANDN` 一致。
- 真实问题不止最初怀疑的 `U16x8`：
  - `src/fafafa.core.simd.scalar.pas` 中 `ScalarAndNotU16x8` 与 `ScalarAndNotU32x8` 都写成了 `a and (not b)`；
  - `ScalarAndNotI8x16` / `ScalarAndNotU8x16` 则根本缺失；
  - `FillBaseDispatchTable` 因此借用了 `DispatchAndNotI8x16/U16x8/U8x16` 三个本地 loop wrapper，把 scalar 真源漂移掩住了。
- 本轮已把这一簇问题一起收口：
  - 新增 `ScalarAndNotI8x16`、`ScalarAndNotU8x16`；
  - 修正 `ScalarAndNotU16x8`、`ScalarAndNotU32x8` 为 `(not a) and b`；
  - `FillBaseDispatchTable` 直接改回绑定 `ScalarAndNotI8x16/U16x8/U8x16`；
  - 删除 `dispatch.pas` 里仅为补洞存在的 `DispatchAndNotI8x16/U16x8/U8x16` 冗余实现。
- 本轮同时补上了此前缺失的直接语义测试，避免再只靠“backend 对 scalar table 复读”：
  - `TTestCase_NarrowIntegerOps.Test_VecI8x16_AndNot_Basic`
  - `TTestCase_NarrowIntegerOps.Test_VecU16x8_AndNot_Basic`
  - `TTestCase_NarrowIntegerOps.Test_VecU8x16_AndNot_Basic`
  - `TTestCase_VecU32x8.Test_VecU32x8_AndNot`
- release 级验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_NarrowIntegerOps,TTestCase_VecU32x8,TTestCase_DispatchAPI,TTestCase_NonX86BackendParity`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-12 Narrow Compare Direct Guard Coverage

- 继续沿 `narrowintegerops` 深审“缺失但被 parity 掩住”的直接 guard，先核对真实边界：
  - `I16x8/I8x16/U16x8/U8x16` 的 `CmpLe/CmpGe/CmpNe` 不属于 `src/fafafa.core.simd.pas` façade；
  - 它们属于 `dispatch/scalar` contract；
  - `U32x4` 的 `AndNot/CmpLe/CmpGe` 则有 façade 入口，适合直接补 façade 语义测试。
- `tests/fafafa.core.simd/fafafa.core.simd.narrowintegerops.testcase.pas` 已新增：
  - 12 条 dispatch-level 窄整型 compare 测试：`I16x8/I8x16/U16x8/U8x16` 的 `CmpLe/CmpGe/CmpNe`
  - 3 条 `U32x4` façade 测试：`AndNot/CmpLe/CmpGe`
- 复核后确认这批 dispatch-level compare 测试并不是“打当前随机 backend”：
  - `TTestCase_NarrowIntegerOps.SetUp` 本来就 `ForceBackend(sbScalar)`；
  - 因而这批新增测试实际是在对 `GetDispatchTable` 的 scalar active table 做直接 contract guard。
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_NarrowIntegerOps`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-13 Low-Width Integer Facade Guard Coverage

- 继续沿 direct-guard 缺口往下扫后，确认下一批最真实的空档在 128-bit 低宽整数 façade：
  - `VecI32x4AndNot/CmpEq/CmpLt/CmpGt/CmpLe/CmpGe/CmpNe`
  - `VecI64x2AndNot/CmpEq/CmpLt/CmpGt/CmpLe/CmpGe/CmpNe`
  - `VecU64x2AndNot/CmpEq/CmpLt/CmpGt`
- 这三组函数此前主要只在 `dispatchapi.testcase` 里做 façade-vs-dispatch parity，没有 family-local direct guard。
- 本轮已在 `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 新增 `TTestCase_IntegerFacadeGuards`：
  - `SetUp/TearDown` 固定 `ForceBackend(sbScalar)` / `ResetBackendSelection`
  - 6 条测试覆盖三组 façade 的 compare/AndNot 公开 contract
- 第一次 targeted run 直接暴露的不是语义问题，而是 runner contract：
  - 新 suite 已 `RegisterTest(...)`
  - 但 `fafafa.core.simd.test.lpr` 的 `ProcessAllSuites` 共享清单还没同步，导致 `--suite=TTestCase_IntegerFacadeGuards` 匹配不到任何测试
  - 现已把 `HandleSuite('TTestCase_IntegerFacadeGuards', ...)` 补进 runner，suite manifest 再次为绿
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IntegerFacadeGuards`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-13 I32x8 Facade Direct Guard Coverage

- 继续复核后，`I32x8` 被确认是当前公开整数 façade 里一个容易被误判为“已经够了”的残余点：
  - `tests/fafafa.core.simd/fafafa.core.simd.veci32x8.testcase.pas` 已覆盖 `AndNot + Eq/Lt/Gt/Le/Ge/Ne`
  - 但它的 `SetUp/TearDown` 不固定 `ForceBackend(sbScalar)` / `ResetBackendSelection`
  - 同目录 `vecu32x8` suite 则明确固定了 `sbScalar`
- 因而 `veci32x8` 当前更接近 `I64x8/vec512types` 的证据形态：有 family-local 测试，但不是 scalar-forced direct guard。
- 本轮继续复用 `TTestCase_IntegerFacadeGuards`，新增：
  - `Test_VecI32x8_AndNot_Basic`
  - `Test_VecI32x8_Compare_Basic`
- 这次特意没有去改 `veci32x8` 现有 suite 的 `SetUp/TearDown`，避免把旧 suite 从“默认后端 family-local 行为回归”改成另一种测试语义；我们只补一条独立的 scalar-forced contract 证据。
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IntegerFacadeGuards`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-13 I64x8 Facade Direct Guard Coverage

- 继续沿 wide integer façade 尾巴复核后，确认 `VecI64x8CmpEq/CmpLt/CmpGt/CmpLe/CmpGe/CmpNe` 仍是一个真实证据缺口：
  - `src/fafafa.core.simd.pas` 已公开暴露这组 `I64x8` compare；
  - 现有可见覆盖主要来自 `vec512types` 的 compare mask 测试和 `dispatchapi` parity；
  - 但 `vec512types` 没有 `ForceBackend/ResetBackendSelection`，也没有 `SetUp/TearDown`，因此不等价于 scalar-forced direct guard。
- 本轮继续复用 `TTestCase_IntegerFacadeGuards`，只新增 1 条 `I64x8` signed compare mask 测试，没有动实现、runner 或 checker。
- 定向 release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IntegerFacadeGuards`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - 结果：全部通过
- 中途误把 `check` 和 `gate` 并行跑了一次，重现了这个仓库已知的共享输出目录假红：
  - 并行 `gate` 在 build 阶段 `rc=2`
  - 改回串行后 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate` 最终为 `[GATE] OK`
  - 说明这次仍然只是测试证据补强，不是实现或 runner 回归

## 2026-05-13 512-bit Integer Compare Tail Guard Coverage

- 继续扫剩余公开整数 façade 后，确认新的真实尾巴已经从 `I64x8` 收窄到 3 组 512-bit compare contract：
  - `VecI16x32CmpEq/CmpLt/CmpGt`
  - `VecI8x64CmpEq/CmpLt/CmpGt`
  - `VecU8x64CmpEq/CmpLt/CmpGt`
- 这三组此前没有进入 `TTestCase_IntegerFacadeGuards`，也没有像 `I64x8` 那样的 family-local direct mask 测试；当前主要只有 `dispatchapi` 的 façade-vs-scalar parity。
- `narrowintegerops` 已经确认不构成这批 contract 的替代证据：
  - 它只固定 `sbScalar` 覆盖 `I16x8/I8x16/U16x8/U8x16/U32x4`
  - 不覆盖这 3 组 512-bit compare
- 本轮继续复用 `TTestCase_IntegerFacadeGuards`，新增：
  - `Test_VecI16x32_Compare_Basic`
  - `Test_VecI8x64_Compare_Basic`
  - `Test_VecU8x64_Compare_Unsigned`
- 这次没有再写硬编码大掩码常量，而是按 lane 数据动态累积期望 mask，避免 32/64-lane compare 测试继续堆砌易错常量。
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IntegerFacadeGuards`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-13 Mid/Wide Integer Facade Guard Coverage

- 继续深扫后，确认下一簇真实空档不是“没有 parity”，而是“只有 `dispatchapi` / multi-backend 旁证，没有强制 `sbScalar` 的 façade direct guard`：
  - `VecI64x4AndNot/CmpLe/CmpGe/CmpNe`
  - `VecI32x16AndNot/CmpEq/CmpLt/CmpGt/CmpLe/CmpGe/CmpNe`
  - `VecU32x16AndNot/CmpEq/CmpLt/CmpGt/CmpLe/CmpGe/CmpNe`
- 这批没有再新建 suite，而是继续扩 `TTestCase_IntegerFacadeGuards`，保持：
  - `SetUp` 固定 `ForceBackend(sbScalar)`
  - `TearDown` 固定 `ResetBackendSelection`
  - 新增 6 条测试，直接打 `I64x4`、`I32x16`、`U32x16` 的 façade contract
- 第一次 targeted build 暴露的不是实现回归，而是测试层命名歧义：
  - `VecI32x16CmpEq/Lt/Gt` 在 `simd.utils` 里也有同名 helper，返回 `TMaskI32x16`
  - 在通用 testcase 里若不加限定，会被解析到错误的 helper surface
  - 现已把 `I32x16` compare 调用显式限定为 `fafafa.core.simd.VecI32x16Cmp*`
- 这也说明当前更真实的风险点之一是“同名 helper 让 façade 测试误绑到 utils surface”，不是实现函数本身缺失。
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IntegerFacadeGuards`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-13 Wide Tail Integer Facade Guard Coverage

- 继续往下扫后，当前同类 direct-guard 空档已经缩成更尾部的 3 处 façade contract：
  - `VecU64x8CmpLe/CmpGe/CmpNe`
  - `VecI16x32AndNot`
  - `VecI8x64AndNot`
- 这三项在本轮之前都已经有 `dispatchapi` parity 证据，但还没有固定 `sbScalar` 的 direct guard；因此它们仍属于“证据缺口”，不是实现缺口。
- 本轮继续复用 `TTestCase_IntegerFacadeGuards`，没有增加 runner 结构，也没有改任何 SIMD 实现文件：
  - 新增 1 条 `U64x8` unsigned compare mask 测试
  - 新增 1 条 `I16x32` AndNot 逐 lane 语义测试
  - 新增 1 条 `I8x64` AndNot 逐 lane 语义测试
- 这批没有再遇到 `I32x16` 那种 helper 命名歧义，说明当前测试层主要风险已从“suite/命名合同”回落到单纯的 direct evidence completeness。
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IntegerFacadeGuards`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-13 U64x4 Facade Direct Guard Coverage

- 继续复核剩余 public façade 后，`U64x4` 这簇是当前最像“只剩 parity 旁证”的真实尾巴：
  - `VecU64x4CmpEq/CmpLt/CmpGt/CmpLe/CmpGe/CmpNe`
- 当前仓库里它已经有：
  - `dispatchapi` 的 dispatch/facade parity 与部分 expected-mask
  - `direct` 的多 backend parity
  - 但还没有固定 `ForceBackend(sbScalar)` 的 direct guard
- 本轮继续复用 `TTestCase_IntegerFacadeGuards`，只新增 1 条 `U64x4` unsigned compare mask 测试，没有动实现、runner 或 checker。
- 第一次 targeted run 暴露的仍然不是实现问题，而是测试预期写得太保守：
  - 当前样本分布下 lane0 和 lane3 都属于 `eq`
  - 因而 `Eq/Le/Ge` 的预期 mask 需要从单 lane 修正成包含 lane3 的版本
  - 修正后 targeted suite 立即转绿
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IntegerFacadeGuards`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-13 Wide Float Facade Guard Coverage

- 继续从“只剩 parity / operator / 默认后端旁证”的角度往下扫后，确认 512-bit 浮点 façade 还缺一层固定 `sbScalar` 的 direct guard：
  - `VecF32x16Add/Sub/Mul/Div`
  - `VecF32x16CmpEq/Lt/Le/Gt/Ge/Ne_Mask`
  - `VecF32x16Fma/Floor/Ceil/Round/Trunc/Clamp/Reduce*/Load/Store/Splat/Zero/Select`
  - `VecF64x8Add/Sub/Mul/Div`
  - `VecF64x8CmpEq/Lt/Le/Gt/Ge/Ne`
  - `VecF64x8Fma/Floor/Ceil/Round/Trunc/Clamp/Reduce*/Load/Store/Splat/Zero/Select`
- 关键判断已经钉实：
  - `vec512types` 没有固定 `sbScalar`
  - 它的 `Add/Sub/Mul` 主要走 operator surface
  - 它的 `F32x16` compare 走的是 `TMaskF32x16` vector-mask surface，不是公开 façade `_Mask`
  - `direct.testcase` 证明的是 façade-vs-direct parity，不是 explicit-output public façade guard
- 本轮没有去改 `vec512types` 的生命周期，也没有新增 family-local runner；而是直接在 `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 增加并列 suite：
  - `TTestCase_FloatFacadeGuards`
  - `SetUp/TearDown` 固定 `ForceBackend(sbScalar)` / `ResetBackendSelection`
  - 6 条测试覆盖 `F32x16/F64x8` 的算术、compare/reduce/select、extended math/load-store
- 首次 targeted run 红了 2 项，但都不是实现回归，而是测试期望写错：
  - `VecF32x16ReduceAdd` 实际应为 `13.5`
  - `VecF64x8ReduceAdd` 实际应为 `5.5`
- 修正期望后，这批验证已全部通过：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_FloatFacadeGuards`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-13 Wide Float Remaining API Guard Coverage

- 继续往下审查 `F32x16/F64x8` 后，确认还有一簇真实缺口没有进入 scalar direct guard：
  - `VecF32x16Abs/Sqrt/Min/Max/Extract/Insert`
  - `VecF64x8Abs/Sqrt/Min/Max`
- 这批已有的证据主要还是：
  - `dispatchapi.testcase` 的 façade-vs-scalar parity
  - 零散的 `vec512types` 默认后端覆盖
  - 但还没有固定 `ForceBackend(sbScalar)` 的 direct guard
- 本轮没有再开新 suite，而是继续扩现有 `TTestCase_FloatFacadeGuards`：
  - 新增 `Test_VecF32x16_RemainingMathAndExtractInsert_Basic`
  - 新增 `Test_VecF64x8_RemainingMath_Basic`
- 这次 targeted suite 没有暴露实现问题，也没有再出测试预期 bug，说明边界判断是准的：这批确实只是 public façade 证据收口。
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_FloatFacadeGuards`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-13 I64x4 U64x4 Remaining Ops Guard Coverage

- 继续深扫剩余整数 façade 后，确认 256-bit 的 `I64x4/U64x4` 仍留着一块典型的 direct-evidence 尾巴：
  - `I64x4`：`Add/Sub/And/Or/Xor/Not/ShiftLeft/ShiftRight/ShiftRightArith`
  - `U64x4`：`Add/Sub/And/Or/Xor/Not/ShiftLeft/ShiftRight`
- 这两簇在本轮之前并不是“没有测试”，而是主要停留在：
  - `dispatchapi.testcase` 的 façade-vs-scalar parity
  - `direct.testcase` 的 façade-vs-direct / backend parity
- 本轮继续复用 `TTestCase_IntegerFacadeGuards`，没有改 runner，也没有碰任何生产实现：
  - 新增 `Test_VecI64x4_RemainingOps_Basic`
  - 新增 `Test_VecU64x4_RemainingOps_Basic`
- 这次 targeted suite 没有暴露新的测试期望错误，也没有打到实现回归，说明边界判断是准的：这批就是 public façade 证据收口。
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IntegerFacadeGuards`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

- 我继续往前收的是几份 testcase 里已经变成“只差最后一步”的本地 restore helper 重复体：
  - `dataplane`
  - `publicabi`
  - `dispatchapi`
  - `concurrent`
  - `ieee754`
- 这轮先把边界卡清楚了：
  - 重复的是同一段 `SetVectorAsmEnabled(...) -> ResetToAutomaticBackend -> TrySetActiveBackend(...)`
  - 但各文件在 helper 外层包着的语义并不完全一样：
    - `publicabi / dispatchapi / concurrent` 还各自带断言文案或 fixture 语义
    - `dataplane / ieee754` 则更像函数式 local restore helper
  - 所以这轮不去新造更重的 testcase 基类，也不去删除本地 helper 名称，而是只把完全同构的 restore 体上提成公共实现
- 本轮最小修法因此是：
  - 在 `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 新增
    - `RestoreSavedBackendAndVectorAsmState(aOriginalVectorAsm, aOriginalBackend): Boolean`
  - 让以下本地 helper 改成薄转发或断言壳：
    - `RestoreDataPlaneLocalState(...)`
    - `RestoreIEEE754LocalState(...)`
    - `TTestCase_PublicAbi.RestorePublicAbiLocalState(...)`
    - `TDispatchAPIStatefulTestCase.RestoreDispatchApiLocalState(...)`
    - `TSimdStatefulTestCase.RestoreSimdLocalState(...)`
  - 也就是说，这轮只抽“共享 restore 体”，不碰各 suite 现有的 method-level control-plane 编排、hook rollback 或 IEEE754 数值测试意图
- 这轮 Release 收口证据：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - 当前 `simd` 测试层剩余的一类明显冗余，已经从“谁在保存 backend fixture”继续收缩到“谁还保留同构的 local restore helper 体”
  - 这一轮把最稳定的一批 restore 体成功上提后，后续再深挖时，更值得扫的是 `runtime` / `backend.consistency` 这类还没纳入统一 helper 策略的零散残点
  - `search_context` 在这组超窄查询上连续超时两次，因此这轮直接以 worktree 真实 diff 和 release gate 证据为准，没有再把收口卡在工具可用性上

- 我又继续往下扫了一层，这次先把候选分成了两类：
  - `runtime.testcase`
  - backend-only restore helper 残点
- 只读复核后确认：
  - `runtime.testcase` 的 finally 不只是“把 backend 值改回去”
  - 它还在区分“原本是 automatic best backend”还是“原本是 forced backend”
  - 因此它更像 control-plane 语义测试，不能为了去重直接替换成普通 restore helper
  - 真正还能继续统一的是 `dispatchslots` 与 `TTestCase_BackendVectorConsistency` 里那段 backend-only 恢复体
- 本轮最小修法因此是：
  - 在 `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 新增
    - `RestoreSavedBackendState(aOriginalBackend): Boolean`
  - 让现有 `RestoreSavedBackendAndVectorAsmState(...)` 复用这条 backend-only helper
  - `RestoreBackendVectorConsistencyLocalState(...)` 改成薄转发
  - `dispatchslots` 的 `RestoreDispatchSlotsLocalState(...)` 也改成薄转发，但额外保留
    - `GetActiveBackend = aOriginalBackend`
    这层 raw dispatch 语义校验
- 这轮 Release 收口证据：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAllSlots,TTestCase_BackendVectorConsistency`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - `simd` 测试层的 restore helper 去重现在已经覆盖了两层：`vector-asm + backend` 和 backend-only
  - `runtime.testcase` 这条线当前被归类为“有意保留的 control-plane restore”，不是遗漏
  - 如果下一轮还继续深挖，更值得复核的是 `backend.consistency.testcase` 这份 standalone helper 是否还能在不引入单元循环的前提下继续减薄

- 我继续扫剩余 restore helper 时，又确认出一条更小、更稳的 backend-only 残点：
  - `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas`
  - `RestoreOriginalActiveBackend(...)`
- 这轮先把边界卡清楚了：
  - 这条 helper 不带 `runtime` 那种“automatic vs forced backend”分支恢复语义
  - 也不带 `vector-asm` 或 synthetic hook state 生命周期
  - 它本质上就是 `ResetToAutomaticBackend -> TrySetActiveBackend(...)` 的本地复制体
- 本轮最小修法因此是：
  - 保留 `RestoreOriginalActiveBackend(...)` 这个本地语义名字
  - 只把实现改成薄转发到 `RestoreSavedBackendState(...)`
  - 不动任何 `publicabi` 调用点、断言文案和 hook 编排
- 本轮 Release 收口证据：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - backend-only restore helper 的重复体现在已经从 `dispatchslots`、`backend vector consistency` 继续收到了 `publicabi`
  - `runtime.testcase` 仍然被归类为“刻意保留的 control-plane restore”
  - 下一轮若继续深挖，最值得评估的还是 `backend.consistency.testcase` 的 standalone helper 是否值得抽成更小的共享单元，以及这样做是否值得引入新的组织复杂度

- 我继续往下做时，确认了 `backend.consistency` 这条线的真正阻塞不是“helper 还没看见”，而是依赖方向：
  - `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 反向 `uses` `backend.consistency.testcase`
  - 因而 `backend.consistency.testcase` 无法直接依赖 `testcase.pas` 里的公共 helper，否则会形成单元循环
- 这轮最小而正确的修法因此升级成了一个 test-only 结构收口：
  - 新增 `tests/fafafa.core.simd/fafafa.core.simd.fixturehelpers.pas`
  - 单元里只承载稳定的 fixture helper：
    - `TSimdSavedBackendState`
    - `SaveActiveBackendState(...)`
    - `RestoreSavedBackendState(...)`
    - `RestoreSavedBackendAndVectorAsmState(...)`
  - `testcase.pas` 现保留原 helper 名称，但实现转成调用 `fixturehelpers`
  - `backend.consistency.testcase.pas` 则改复用 `fixturehelpers`，删除本地底层 save/restore 实现，只保留自己那层 `GetActiveBackend` 断言与异常语义
- 这轮 Release 收口证据：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAllSlots,TTestCase_BackendVectorConsistency,TTestCase_PublicAbi,TTestCase_DataPlane,TTestCase_DispatchAPI,TTestCase_SimdConcurrent,TTestCase_SimdConcurrentPublicAbi,TTestCase_IEEE754_F64`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - `simd` 测试层这条去冗余主线现在已经从“收 testcase-local 样板”推进到“抽共享 helper 单元，解除循环导致的隔离”
  - `backend.consistency` 不再是因为组织结构而无法共用 helper 的特例
  - 下一步如果还要继续深挖，重点应转成一次 completion audit：重新核所有显式 restore helper、保留的 `runtime` control-plane finally，以及是否还存在值得修的结构性重复，而不是盲目再抽象一层

- 在 completion audit 前，我又补了一刀很小但明确的残点：
  - `tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas`
  - `TDirectDispatchStatefulTestCase.RestoreFixtureDirectDispatchState`
- 这轮先把边界卡清楚了：
  - 这条 helper 里重复的仍是已经共享化的 backend/vector-asm restore 主体
  - `direct` 自己真正独有的是 `RebindDirectDispatch`
  - 所以这轮不动 helper 名称、不动 rebind 顺序、不动断言，只收共享主体
- 本轮最小修法因此是：
  - `RestoreFixtureDirectDispatchState` 改成
    - `RestoreSavedBackendAndVectorAsmState(FSavedVectorAsm, FSavedBackend)`
    - 然后 `RebindDirectDispatch`
    - 然后保持原断言
- 本轮 Release 收口证据：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - `direct` 这条 restore helper 残点现在也已经并入 shared fixture helper 体系
  - 当前显式保留下来的 restore helper，越来越多已经是“语义壳”而不是“实现复制体”
  - 下一步更有价值的是补一轮发布级 completion audit，重新核 `freeze-status`、non-x86 native evidence 和是否还存在未覆盖的真实问题

## 2026-05-14 Fixture Backend Restore Symmetry

- 这轮没有回头去刷 `UnsignedVectorTypes` / `RustStyleAliases` / `Memutils`，也没有机械给 `PublicAbi`、`SSE2Contracts`、`dataplane`、`concurrent` 套 `sbScalar`。
- 改成逐个核对高价值 suite 的 fixture 生命周期后，抓到了新的真实泄漏：
  - 多个 suite 会保存/恢复 `vector asm`
  - 却不会恢复进入测试前的 `GetCurrentBackend`
  - `publicabi.testcase` 更严重，`ResetPublicAbiSyntheticHookState` 会把状态强行打回 `vector asm=False + automatic`
- 本轮最小修复只动测试夹具：
  - `fafafa.core.simd.publicabi.testcase.pas`：`TTestCase_PublicAbi` 增加 `FSavedVectorAsm/FSavedBackend`，`TearDown` 在 synthetic hook reset 后恢复原始 backend 选择
  - `fafafa.core.simd.sse2contracts.testcase.pas`：`TTestCase_SSE2Contracts` 增加 `FOldBackend`
  - `fafafa.core.simd.dataplane.testcase.pas`：`TTestCase_DataPlane` 增加 fixture 级 `SetUp/TearDown`
  - `fafafa.core.simd.concurrent.testcase.pas`：提取 `TSimdStatefulTestCase`，统一为 `TTestCase_SimdConcurrent*` 四个 suite 保存/恢复原始 `vector asm + backend`
- 首次 Release 定向 suite 编译时先暴露一个测试层小问题，不是设计回退：
  - `publicabi.testcase` 的 `TearDown` 早于 `RestoreOriginalActiveBackend` helper 定义，FPC 报 `Identifier not found`
  - 已改成在 `TearDown` 中直接做 `ResetToAutomaticBackend + TrySetActiveBackend(savedBackend)`，避免再引入 `forward` 噪音
- 本轮 Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi,TTestCase_DataPlane,TTestCase_SSE2Contracts,TTestCase_SimdConcurrent,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework,TTestCase_SimdConcurrentRegistration`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 IEEE754 Fixture State Restore Symmetry

- 继续全量扫描 mixed/high-value suite 的全局状态修改点后，本轮把落点收窄到了 `tests/fafafa.core.simd/fafafa.core.simd.ieee754.testcase.pas`。
- 交叉核对发现，上一批虽然已经修了 `FSavedExceptionMask`，但还残留一层 backend/vector-asm 泄漏：
  - `TTestCase_IEEE754_F64.SetUp` 会强制 `sbScalar`
  - `TTestCase_IEEE754EdgeCases`、`TTestCase_AVX2RoundTruncIEEE754`、`TTestCase_NonX86IEEE754` 在测试内部会切 `vector asm/backend`
  - 但 suite 结束时只会回到 `automatic`，不会恢复进入测试前的真实 backend 选择
- 本轮最小修复仍然只动测试夹具：
  - `TTestCase_IEEE754_F64`、`TTestCase_IEEE754EdgeCases`、`TTestCase_AVX2RoundTruncIEEE754` 各自增加 `FSavedVectorAsm/FSavedBackend`
  - `TTestCase_NonX86IEEE754` 补了 fixture 级 `SetUp/TearDown`
  - 恢复逻辑统一为：先 `SetVectorAsmEnabled(saved)`，再 `ResetToAutomaticBackend`，必要时 `TrySetActiveBackend(savedBackend)`；其中前三个 exception-mask suite 再恢复 `FSavedExceptionMask`
- 本轮 Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IEEE754_F64,TTestCase_IEEE754EdgeCases,TTestCase_AVX2RoundTruncIEEE754,TTestCase_NonX86IEEE754`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 Direct Fixture State Restore Symmetry

- 继续从 control-plane 高价值 suite 往下扫后，本轮把落点收窄到了 `tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas`。
- 交叉核对发现：
  - `TTestCase_DirectDispatch` 与 `TTestCase_DirectDispatchConcurrent` 都没有 fixture 级 `SetUp/TearDown`
  - 大量方法内部会切 `TrySetActiveBackend(...)`、`SetActiveBackend(sbScalar)`、`SetVectorAsmEnabled(True/False)`
  - 但退出时通常只做 `ResetToAutomaticBackend`
  - 因而会把进入测试前的强制 backend 选择静默丢掉
- 本轮最小修复只动测试夹具，不去改几十个 test body：
  - 提取 `TDirectDispatchStatefulTestCase`
  - 统一保存/恢复进入测试前的 `vector asm + current backend`
  - 让 `TTestCase_DirectDispatch` 与 `TTestCase_DirectDispatchConcurrent` 都继承它
- 本轮 Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 Backend Consistency Helper State Restore

- direct 批次提交后，继续沿“真实 fixture / helper 状态恢复不对称”往下扫，下一处高价值落点是：
  - `tests/fafafa.core.simd/fafafa.core.simd.backend.consistency.testcase.pas`
  - 以及它在 `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 里的 wrapper `TTestCase_BackendVectorConsistency`
- 本轮先确认到两个同类泄漏面：
  - 7 个 helper-style consistency 测试函数结束时都只 `ResetToAutomaticBackend`
  - `TTestCase_BackendVectorConsistency.Test_VectorOps_Consistency` 结束时也只 `ResetToAutomaticBackend`
- 本轮修复与加固：
  - 在 `backend.consistency.testcase` 提取 `SaveBackendConsistencyState/RestoreBackendConsistencyState`
  - 让 `TestF32x4Arithmetic/TestF32x4Math/TestF32x4Comparison/TestF32x4Reduction/TestI32x4Arithmetic/TestI32x4Bitwise/TestFacadeMemOps` 全部恢复进入前 backend
  - 让 `TTestCase_BackendVectorConsistency.Test_VectorOps_Consistency` 恢复进入前 backend
  - 新增 `Test_VectorOps_Helper_Preserves_PreviousForcedBackend`
  - 新增 `Test_VectorOps_Consistency_Preserves_PreviousForcedBackend`
- 本轮中途遇到两个小收口问题并已解决：
  - helper 单元没有 `GetCurrentBackend`，应改用 `dispatch` 层的 `GetActiveBackend`
  - 新增回归测试初版漏了 `try`，编译器直接在定向 suite 把语法问题挡住，随后已修正
- 本轮 Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_BackendVectorConsistency`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-14 DispatchAPI Fixture State Restore

- `backend.consistency` 批次收口后，继续沿“真实状态恢复不对称”向下深挖，本轮把目标收窄到了 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 的 `TTestCase_DispatchAPI`。
- 交叉核对后确认：
  - 这个类没有 fixture 级 `SetUp/TearDown`
  - 大量测试方法会保存 `LOldVectorAsm` 并反复跑 `TrySetActiveBackend/ResetToAutomaticBackend/SetVectorAsmEnabled`
  - 但离开测试时通常只回到 `automatic` 或只恢复 `vector asm`
  - 因而会把进入测试前的强制 backend 选择静默丢掉
- 本轮选择了高杠杆修法，而不是逐个改大量 `finally`：
  - 提取 `TDispatchAPIStatefulTestCase`
  - 统一在 `SetUp` 保存进入测试前的 `vector asm + current backend`
  - 统一在 `TearDown` 恢复进入测试前状态
  - 让 `TTestCase_DispatchAPI` 继承该基类
- 本轮 Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-14 DispatchAPI Companion Classes Fixture State Restore

- `TTestCase_DispatchAPI` 收口提交后，继续审 `dispatchapi.testcase` 里剩下的 companion 类，确认还有 4 支高价值泄漏面：
  - `TTestCase_X86MaskedFmaContract`
  - `TTestCase_RISCVVMaskedOpsContract`
  - `TTestCase_RISCVFallbackDispatchContract`
  - `TTestCase_NonX86BackendParity`
- 交叉核对发现它们都还在：
  - 裸继承 `TTestCase`
  - 内部切 `SetVectorAsmEnabled(True/False)`、`TrySetActiveBackend(...)` 或 `ResetToAutomaticBackend`
  - 但没有统一 fixture 级恢复进入测试前 backend/vector-asm 状态
- 本轮修法保持最小：
  - 不再新建第二套状态基类
  - 直接让这 4 个类复用现有 `TDispatchAPIStatefulTestCase`
- 本轮 Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_X86MaskedFmaContract,TTestCase_RISCVVMaskedOpsContract,TTestCase_RISCVFallbackDispatchContract,TTestCase_NonX86BackendParity`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-14 DispatchSlots Fixture Backend Restore

- 在 `dispatchapi` companion 类收口后，继续窄扫剩余裸 `TTestCase` + backend 切换热点，下一处真实漏点收敛到了 `tests/fafafa.core.simd/fafafa.core.simd.dispatchslots.testcase.pas`。
- 交叉核对确认：
  - `TTestCase_DispatchAllSlots` 没有 fixture 级 `SetUp/TearDown`
  - 多个测试会 `TrySetActiveBackend(LBackend)` 或直接 `ResetToAutomaticBackend`
  - 但结束时只回 `automatic`，无法恢复进入测试前的强制 backend 选择
- 本轮修法保持最小：
  - 直接在 `TTestCase_DispatchAllSlots` 增加 `FSavedBackend`
  - 在 `SetUp/TearDown` 统一保存/恢复进入测试前 backend
- 本轮 Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAllSlots`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-14 Float Utility Facade Tail Guard Coverage

- 继续顺着浮点 façade 往下扫后，当前最真实的尾巴不再是整族算术/compare，而是 utility 面的 direct-evidence 缺口：
  - `F64x2`：`Dot`
  - `F32x8`：`Dot/Select/Extract/Insert`
  - `F64x4`：`Rcp/Dot/Select/Extract/Insert`
- 这批在本轮之前并不是“没有测试”，而是停留在几类旁证或半直调状态：
  - `dispatchapi.testcase` 的 façade-vs-scalar parity
  - `direct.testcase` 的 façade-vs-direct parity
  - `vecf32x8/vecf64x4` family-local suite 虽然固定了 `sbScalar`，但 utility 面还混着 `dispatch table` 或 `Scalar*` helper 直调
  - 首轮补丁还额外暴露了一个源码真相：`F32x8/F64x4` 根本没有公开的 `Load/Store/Splat/Zero` façade，因此这些不应再被当成 public-surface 缺口
- 因而这批缺口仍然是证据层，不是实现层；本轮改动保持很窄：
  - 在 `TTestCase_FloatFacadeGuards` 现有 `F64x2` compare/reduce/select guard 里补上 `VecF64x2Dot`
  - 在 `vecf32x8` suite 新增 `Test_VecF32x8_PublicUtilityFacade_Basic`
  - 在 `vecf64x4` suite 新增 `Test_VecF64x4_PublicUtilityFacade_Basic`
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_FloatFacadeGuards,TTestCase_VecF32x8,TTestCase_VecF64x4`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 F32x4 Utility Facade Tail Guard Coverage

- 继续顺着浮点 façade 往下扫后，`F32x4` 暴露出另一种“看起来测得很多、其实 utility 尾巴还没收实”的边界：
  - `TTestCase_VectorOps` 已固定 `sbScalar`，但只覆盖基础算术、基础 math、`Load/Store/Splat/Compare/Dot/Length/Normalize`
  - `Zero/LoadAligned/StoreAligned/Select` 仍主要停留在 `dispatchapi.testcase` 的 façade parity
  - `Extract/Insert` 则主要停留在 `ShuffleSWizzle` 与 `EdgeCases` 这种非 scalar-direct 测试面
- 这批缺口依旧是证据层，不是实现层；这次不需要再开新 suite，直接复用已经固定 `sbScalar` 的 `TTestCase_VectorOps` 最稳：
  - 新增 `Test_VecF32x4_UtilityFacade_Basic`
  - 覆盖 `VecF32x4Zero`
  - 覆盖 `VecF32x4LoadAligned/StoreAligned`
  - 覆盖 `VecF32x4Select`
  - 覆盖 `VecF32x4Extract/Insert`
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_VectorOps`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 Shuffle Swizzle Facade Scalarization

- 继续沿 `F32x4` utility public surface 往下扫后，发现下一块高价值尾巴不是单个 API，而是整簇 `shuffle/swizzle`：
  - `VecF32x4Shuffle/Shuffle2/Blend`
  - `VecF64x2Blend`
  - `VecI32x4Shuffle/Blend`
  - 以及同一 suite 里的 `Unpack/Broadcast/Reverse/Rotate/Insert/Extract`
- 这批之前最大的问题不是“没测”，而是“测了但没被 fixed-`sbScalar` 钉成 façade direct contract”：
  - `TTestCase_ShuffleSWizzle` 自己覆盖已经很全
  - 但 suite 没有 `SetUp/TearDown`
  - `dispatchapi/direct` 也没有把这簇补成同等级的 scalar-direct 证据
- 因而这批最小、最优雅的收口方式不是再造新测试，而是把现有 suite 自身 scalarize：
  - 给 `TTestCase_ShuffleSWizzle` 增加 `SetUp/TearDown`
  - 在 `SetUp` 固定 `ForceBackend(sbScalar)`
  - 在 `TearDown` 调 `ResetBackendSelection`
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_ShuffleSWizzle`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 Gather Scatter Facade Scalarization

- 继续沿“现有 suite 覆盖很全、但还没进入 fixed-`sbScalar` façade direct contract”的路径往下扫后，`GatherScatter` 成了下一块高价值尾巴：
  - `VecF32x4Gather`
  - `VecI32x4Gather`
  - `VecF32x4Scatter`
  - `VecI32x4Scatter`
  - 以及同一 suite 里的 `ZeroIndex/LargeStride` 边界
- 这批之前最大的问题同样不是“没测”，而是“测了但 suite 没被固定到 scalar 真源语义”：
  - `TTestCase_GatherScatter` 自己已经覆盖顺序、跨步、随机、负值、零索引和大跨步
  - 但 suite 没有 `SetUp/TearDown`
  - `dispatchapi/direct` 里也没有同等级的 scalar-direct façade 证据可替代
- 因而这批最小、最优雅的收口方式仍然不是新造测试，而是把现有 suite 自身 scalarize：
  - 给 `TTestCase_GatherScatter` 增加 `SetUp/TearDown`
  - 在 `SetUp` 固定 `ForceBackend(sbScalar)`
  - 在 `TearDown` 调 `ResetBackendSelection`
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_GatherScatter`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 Math Functions Facade Scalarization

- 继续沿“现有 suite 覆盖很全、但还没进入 fixed-`sbScalar` façade direct contract”的路径往下扫后，`MathFunctions` 成了下一块高价值尾巴：
  - `VecF32x4Sin`
  - `VecF32x4Cos`
  - `VecF32x4SinCos`
  - `VecF32x4Tan`
  - `VecF32x4Exp/Exp2`
  - `VecF32x4Log/Log2/Log10`
  - `VecF32x4Pow`
  - `VecF32x4Asin/Acos/Atan/Atan2`
- 这批之前最大的问题同样不是“没测”，而是“测了但 suite 没被固定到 scalar 真源语义”：
  - `TTestCase_MathFunctions` 自己已经覆盖这一整簇公开 math façade 的常规 contract
  - 但 suite 没有 `SetUp/TearDown`
  - 其余测试面对这簇主要还是 `edgecases` 的特例旁证，不等价于 fixed-`sbScalar` 的 façade direct guard
- 因而这批最小、最优雅的收口方式依旧不是新造测试，而是把现有 suite 自身 scalarize：
  - 给 `TTestCase_MathFunctions` 增加 `SetUp/TearDown`
  - 在 `SetUp` 固定 `ForceBackend(sbScalar)`
  - 在 `TearDown` 调 `ResetBackendSelection`
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_MathFunctions`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 Advanced Algorithms Facade Scalarization

- 继续沿“现有 suite 覆盖很全、但还没进入 fixed-`sbScalar` façade direct contract”的路径往下扫后，`AdvancedAlgorithms` 成了下一块高价值尾巴：
  - `SortNet4I32/SortNet4F32/SortNet8I32`
  - `PrefixSumI32x4/PrefixSumF32x4`
  - `PrefixSumArrayI32/PrefixSumArrayF32`
  - `StrFindChar`
- 这批之前最大的问题同样不是“没测”，而是“测了但 suite 没被固定到 scalar 真源语义”：
  - `TTestCase_AdvancedAlgorithms` 自己已经覆盖这簇公开算法 façade 的常规 contract
  - 但 suite 没有 `SetUp/TearDown`
  - 其余测试面对这簇主要还是 `edgecases` 的特例旁证或 release checklist 旁证，不等价于 fixed-`sbScalar` 的 façade direct guard
- 因而这批最小、最优雅的收口方式依旧不是新造测试，而是把现有 suite 自身 scalarize：
  - 给 `TTestCase_AdvancedAlgorithms` 增加 `SetUp/TearDown`
  - 在 `SetUp` 固定 `ForceBackend(sbScalar)`
  - 在 `TearDown` 调 `ResetBackendSelection`
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_AdvancedAlgorithms`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 Global Facade Scalarization

- 继续沿“现有 suite 覆盖很全、但还没进入 fixed-`sbScalar` façade direct contract”的路径往下扫后，`Global` 成了下一块高价值尾巴：
  - `MemEqual/MemFindByte/MemDiffRange/MemCopy/MemSet/MemReverse`
  - `SumBytes/MinMaxBytes/CountByte`
  - `Utf8Validate/AsciiIEqual/ToLowerAscii/ToUpperAscii`
  - `BytesIndexOf`
  - `BitsetPopCount`
- 这批之前最大的问题同样不是“没测”，而是“测了但 suite 没被固定到 scalar 真源语义”：
  - `TTestCase_Global` 自己已经覆盖这簇公开全局 façade 的常规 contract
  - 但 suite 没有 `SetUp/TearDown`
  - 跨 backend 的语义旁证虽然存在，但主要由 `TTestCase_BackendConsistency` 负责，不等价于 `Global` 自己的 scalar-direct contract
- 因而这批最小、最优雅的收口方式依旧不是新造测试，而是把现有 suite 自身 scalarize：
  - 给 `TTestCase_Global` 增加 `SetUp/TearDown`
  - 在 `SetUp` 固定 `ForceBackend(sbScalar)`
  - 在 `TearDown` 调 `ResetBackendSelection`
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_Global`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 Type Conversion Facade Scalarization

- 继续沿“现有 suite 覆盖很全、但还没进入 fixed-`sbScalar` façade direct contract”的路径往下扫后，`TypeConversion` 成了下一块高价值尾巴：
  - `VecF32x4IntoBits/VecI32x4FromBitsF32`
  - `VecF64x2IntoBits/VecI64x2FromBitsF64`
  - `VecF32x4CastToI32x4/VecI32x4CastToF32x4`
  - `VecF64x2CastToI64x2/VecI64x2CastToF64x2`
  - `VecI16x8WidenLoI32x4/VecI16x8WidenHiI32x4/VecI32x4NarrowToI16x8`
  - `VecF32x4ToF64x2Lo/VecF64x2ToF32x4`
- 这批之前最大的问题同样不是“没测”，而是“测了但 suite 没被固定到 scalar 真源语义”：
  - `TTestCase_TypeConversion` 自己已经覆盖这簇公开转换 façade 的常规 contract
  - 但 suite 没有 `SetUp/TearDown`
  - 其余测试面对这簇主要仍是零散的 family/edgecase 旁证，不等价于 fixed-`sbScalar` 的 façade direct guard
- 因而这批最小、最优雅的收口方式依旧不是新造测试，而是把现有 suite 自身 scalarize：
  - 给 `TTestCase_TypeConversion` 增加 `SetUp/TearDown`
  - 在 `SetUp` 固定 `ForceBackend(sbScalar)`
  - 在 `TearDown` 调 `ResetBackendSelection`
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_TypeConversion`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 Vector Mask Facade Scalarization

- 继续沿“现有 suite 覆盖很全、但还没进入 fixed-`sbScalar` façade direct contract”的路径往下扫后，`VectorMaskTypes` 成了下一块高价值尾巴：
  - `MaskF32x4AllTrue/AllFalse/Set/Test/ToBitmask/Any/All/None`
  - `MaskF32x4` 的 `and/or/xor/not`
  - `MaskI32x4AllTrue/ToBitmask`
  - `MaskF64x2AllTrue/ToBitmask`
  - `MaskF32x4Select`
- 这批之前最大的问题同样不是“没测”，而是“测了但 suite 没被固定到 scalar 真源语义”：
  - `TTestCase_VectorMaskTypes` 自己已经覆盖这簇公开 mask façade 的常规 contract
  - 但 suite 没有 `SetUp/TearDown`
  - 其余测试面对这簇主要仍是零散的 type/layout 或功能旁证，不等价于 fixed-`sbScalar` 的 façade direct guard
- 因而这批最小、最优雅的收口方式依旧不是新造测试，而是把现有 suite 自身 scalarize：
  - 给 `TTestCase_VectorMaskTypes` 增加 `SetUp/TearDown`
  - 在 `SetUp` 固定 `ForceBackend(sbScalar)`
  - 在 `TearDown` 调 `ResetBackendSelection`
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_VectorMaskTypes`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 Large Data Global Facade Scalarization

- 继续深扫剩余未 scalarize suite 后，本轮先没有去碰 `UnsignedVectorTypes`，因为它主要是：
  - `TVecU32x4/U16x8/U8x16/U64x2/U32x8/U16x16/U8x32` 的 typedef/layout/raw-access
  - backend 语义价值偏低
- 相比之下，`LargeData` 虽然名字更像集成边界，但它实际覆盖的是公开全局 façade 的大尺寸 contract：
  - `MemEqual`
  - `SumBytes`
  - `MemFindByte`
  - `CountByte`
  - 并且命中了 1MB、非对齐、odd-size 等高价值边界
- 所以这批之前最大的问题同样不是“没测”，而是“测了但 suite 没被固定到 scalar 真源语义”：
  - `TTestCase_LargeData` 自己已经覆盖这簇公开全局 façade 的边界 contract
  - 但 suite 没有 `SetUp/TearDown`
  - 因而它更像普通边界回归，不等价于 fixed-`sbScalar` 的 façade direct guard
- 因而这批最小、最优雅的收口方式依旧不是新造测试，而是把现有 suite 自身 scalarize：
  - 给 `TTestCase_LargeData` 增加 `SetUp/TearDown`
  - 在 `SetUp` 固定 `ForceBackend(sbScalar)`
  - 在 `TearDown` 调 `ResetBackendSelection`
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_LargeData`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 Saturating Arithmetic Facade Scalarization

- 继续按“真实 public contract 价值”而不是机械补 suite 的原则重排后，本轮没有去碰：
  - `dispatch/dataplane/publicabi/runtime/concurrent` 这类控制面/并发面
  - `UnsignedVectorTypes`、`memutils aliases`、`vec512types` 这类夹杂较多 typedef/layout/alias 断言的 suite
- 本轮优先锁定 `SaturatingArithmetic`，因为它直接覆盖的是公开饱和算术 façade：
  - `VecI8x16SatAdd/SatSub`
  - `VecI16x8SatAdd/SatSub`
  - `VecU8x16SatAdd/SatSub`
  - `VecU16x8SatAdd/SatSub`
  - 并且命中了正常值、上溢/下溢、边界值三类 contract
- 所以这批之前最大的问题同样不是“没测”，而是“测了但 suite 没被固定到 scalar 真源语义”：
  - `TTestCase_SaturatingArithmetic` 自己已经覆盖这簇公开 façade 的边界 contract
  - 但 suite 没有 `SetUp/TearDown`
  - 因而它更像普通行为回归，不等价于 fixed-`sbScalar` 的 façade direct guard
- 因而这批最小、最优雅的收口方式依旧不是新造测试，而是把现有 suite 自身 scalarize：
  - 给 `TTestCase_SaturatingArithmetic` 增加 `SetUp/TearDown`
  - 在 `SetUp` 固定 `ForceBackend(sbScalar)`
  - 在 `TearDown` 调 `ResetBackendSelection`
- 首轮定向验证先撞到一个 testcase 依赖问题：
  - 编译失败点：`fafafa.core.simd.saturating.testcase.pas`
  - 错误：`Identifier not found "sbScalar"`
  - 原因：suite 原本没引入 `sbScalar` 所在依赖
  - 修复：补齐 `fafafa.core.simd.base` 与 `fafafa.core.simd.dispatch`，不改测试语义
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SaturatingArithmetic`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-13 I32x8 I64x2 U64x2 Remaining Ops Guard Coverage

- 继续从“公开 façade 还没被固定 `sbScalar` 的 direct guard 钉住”往下扫后，这一批最值钱的缺口落在：
  - `I32x8`：`Add/Sub/Mul/And/Or/Xor/Not/ShiftLeft/ShiftRight/ShiftRightArith/Min/Max/Extract/Insert`
  - `I64x2`：`Add/Sub/And/Or/Xor/Not/ShiftLeft/ShiftRight/ShiftRightArith/Min/Max/Extract/Insert`
  - `U64x2`：`Add/Sub/And/Or/Xor/Not/Min/Max`
- 这三簇在本轮之前并不是“没有测试”，而是各自停留在不同强度的旁证上：
  - `I32x8`：`veci32x8` family-local suite 覆盖很全，但 `SetUp/TearDown` 不固定 `sbScalar`
  - `I64x2/U64x2`：主要是 `dispatchapi.testcase` 与 `direct.testcase` 的 façade parity
- 本轮继续复用 `TTestCase_IntegerFacadeGuards`，没有改 runner，也没有碰任何生产实现：
  - 新增 `Test_VecI32x8_RemainingOps_Basic`
  - 新增 `Test_VecI64x2_RemainingOps_Basic`
  - 新增 `Test_VecU64x2_RemainingOps_Basic`
- 这次 targeted suite 没有再暴露测试期望 bug，也没有打出实现回归，说明这批边界判断同样是准的：补的是 public façade 的 scalar direct evidence，不是实现修复。
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IntegerFacadeGuards`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 I32x4 Remaining Ops Guard Coverage

- 继续深扫 128-bit 整数 façade 后，`I32x4` 成了当前最自然的下一块尾部缺口：
  - `Add/Sub/Mul/And/Or/Xor/Not/ShiftLeft/ShiftRight/ShiftRightArith/Min/Max/Extract/Insert`
- 这簇在本轮之前并不是“没有测试”，而是主要停留在：
  - `dispatchapi.testcase` 的 façade-vs-scalar parity
  - 以及零散的 non-scalar/main-suite 行为测试
- 现有 `TTestCase_IntegerFacadeGuards` 在 `I32x4` 上此前只覆盖：
  - `AndNot + CmpEq/Lt/Gt/Le/Ge/Ne`
- 因而这批缺口仍然是证据层，不是实现层；本轮继续复用 `TTestCase_IntegerFacadeGuards`，没有改 runner，也没有碰任何生产实现：
  - 新增 `Test_VecI32x4_RemainingOps_Basic`
- 这次 targeted suite 依旧没有打出测试期望 bug，也没有暴露实现回归，说明 `I32x4` 这批也是纯 public façade scalar-direct evidence 收口。
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IntegerFacadeGuards`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 F64x2 Direct Float Facade Guard Coverage

- 继续从“公开 façade 还没被固定 `sbScalar` 的 direct guard 钉住”往下扫后，`F64x2` 成了当前浮点面最明显的一块尾部缺口：
  - `Add/Sub/Mul/Div`
  - `CmpEq/Lt/Le/Gt/Ge/Ne`
  - `ReduceAdd/ReduceMin/ReduceMax/ReduceMul`
  - `Load/Store/Splat/Zero/Select`
  - `Abs/Sqrt/Min/Max/Extract/Insert`
- 这簇在本轮之前并不是“没有测试”，而是分散停留在三类不同强度的旁证上：
  - `TTestCase_VectorOps` 固定 `sbScalar`，但只覆盖 `Floor/Ceil/Round/Trunc/Fma`
  - `TTestCase_OperatorOverloads` 固定 `sbScalar`，但只覆盖 `+/-/*//`
  - `dispatchapi.testcase` / `direct.testcase` 已有不少 façade parity，但它们都不等价于 public façade 的 scalar-direct contract guard
- 因而这批缺口仍然是证据层，不是实现层；本轮继续复用 `TTestCase_FloatFacadeGuards`，没有改 runner，也没有碰任何生产实现：
  - 新增 `Test_VecF64x2_Arithmetic_Basic`
  - 新增 `Test_VecF64x2_CompareReduceSelect_Basic`
  - 新增 `Test_VecF64x2_ExtendedMathAndLoadStore_Basic`
  - 新增 `Test_VecF64x2_RemainingMathAndExtractInsert_Basic`
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_FloatFacadeGuards`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 Vec512 Object Mask Facade Guard Extraction

- 继续深扫 `vec512types` 时，这一簇第一次明确暴露出“不能机械 scalarize 整个 suite”的问题：
  - `TTestCase_Vec512Types` 同时混有类型/布局断言、已被其它 guard 覆盖的 512-bit façade 算术，以及少量真正还缺 fixed-`sbScalar` 直证据的对象掩码 façade
  - 因而这批不适合像 `MathFunctions/GatherScatter/VectorMaskTypes` 那样直接给原 suite 整体加 `SetUp/TearDown`
- 交叉核对后，当前更像真实剩余缺口的是返回 `TMaskF32x16` 的对象掩码 façade，而不是 plain mask 或算术 façade：
  - `MaskF32x16AllTrue`
  - `MaskF32x16AllFalse`
  - `MaskF32x16ToBitmask`
  - `MaskF32x16Any/All/None`
  - `VecF32x16CmpEq`
  - `VecF32x16CmpLt`
  - `MaskF32x16` 逻辑运算
  - `MaskF32x16Select`
- 本轮采用“移动职责而不是复制 testcase”的最小方案：
  - 在 `fafafa.core.simd.vec512types.testcase.pas` 新增 `TTestCase_Vec512MaskFacadeGuards`
  - 给新 suite 增加 `SetUp/TearDown`
  - 在 `SetUp` 固定 `ForceBackend(sbScalar)`
  - 在 `TearDown` 调 `ResetBackendSelection`
  - 把上述 8 个对象掩码/对象比较方法从 `TTestCase_Vec512Types` 迁入新 suite
  - 原 `TTestCase_Vec512Types` 保留类型/布局与旧有混合职责，不额外复制测试
- 这批还顺手做了一个小卫生修复：
  - `vec512types.testcase` 原本没有引入 `fafafa.core.simd.dispatch`
  - 新 suite 需要 `sbScalar`，因此补齐 `fafafa.core.simd.dispatch` 依赖
- 首轮定向验证没有打出 façade 逻辑错误，而是暴露了 runner 集成缺口：
  - `TTestCase_Vec512MaskFacadeGuards` 已在 testcase 单元里 `RegisterTest(...)`
  - 但 `tests/fafafa.core.simd/fafafa.core.simd.test.lpr` 采用手写 `HandleSuite(...)` 清单，而不是自动枚举所有注册 suite
  - 所以第一次跑 `--suite=TTestCase_Vec512MaskFacadeGuards` 时出现 `suite filter matched no tests`
  - 最小修复是把新 suite 补进主 runner 的 `ProcessAllSuites` 清单，而不是回退 suite 拆分方案
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_Vec512MaskFacadeGuards`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 ImageProc Facade Scalarization

- 继续筛剩余候选时，这一轮没有去碰：
  - `UnsignedVectorTypes` / `RustStyleAliases`
  - `Memutils`
  - `dispatch/dataplane/publicabi/runtime/concurrent`
- 原因很明确：
  - 前两类主要是 typedef/layout/alias/tooling contract，backend 语义密度低
  - 后一类则是控制面/并发面，根本不该机械套进 `sbScalar`
- 交叉核对后，当前更高价值的缺口落在 `TTestCase_ImageProc`：
  - 它覆盖的是一整簇真实公开图像 API：
    - `CreateImage/FreeImage`
    - `GetPixelRGB/SetPixelRGB`
    - `ImageAdd/ImageSubtract/ImageMultiply/ImageBlend`
    - `RGBToGrayscale/GrayscaleToRGB`
    - `ApplyBrightness/ApplyContrast/ApplyGamma`
    - `ApplyConvolution3x3/ApplyGaussianBlur/ApplySharpen/ApplyEdgeDetection`
  - 但 suite 的 `SetUp/TearDown` 之前只负责 fixture 初始化和 blend alpha mode 恢复，没有固定 backend 语义
- 复核 testcase 形状后，没有发现任何一条测试显式依赖“自动 backend 选择”：
  - 它们断言的是公开图像 API 的结果 contract
  - 没有断言 backend 文本、自动降级、dispatch path 或多 backend 差异
  - 因而这批最优雅的收口方式仍然不是复制 testcase，而是直接 scalarize 现有 suite
- 本轮最小改动保持很窄：
  - 在 `fafafa.core.simd.imageproc.testcase.pas` 增加 `fafafa.core.simd.base` / `fafafa.core.simd.dispatch` 依赖
  - 在 `SetUp` 中加入 `ForceBackend(sbScalar)`
  - 在 `TearDown` 中加入 `ResetBackendSelection`
  - 保留原有 `TImage` fixture 生命周期和 `SetImageBlendAlphaMode` 恢复逻辑不动
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_ImageProc`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 Builder Facade Scalarization

- 继续筛剩余候选时，这一轮仍然没有去碰：
  - `UnsignedVectorTypes` / `RustStyleAliases`
  - `Memutils`
  - `dispatch/dataplane/publicabi/runtime/concurrent`
- 原因保持一致：
  - 前两类主要是 typedef/layout/alias/tooling contract，backend 语义密度低
  - `Memutils` 更偏 aligned allocation/tooling contract
  - 最后一类则是控制面/并发面，根本不该机械套进 `sbScalar`
- 交叉核对后，当前更高价值的缺口落在 `TTestCase_Builder`：
  - 它覆盖的是 `TVecF32x4Builder` 这一层真实 public fluent API：
    - `FromValues/Splat/Load/Build`
    - `Add/Mul/MulScalar/AddScalar`
    - `Normalize/Clamp/Lerp`
    - `ReduceAdd/ReduceMin/ReduceMax`
  - 但 suite 的 `SetUp/TearDown` 之前只是空壳，没有固定 backend 语义
- 复核 testcase 形状后，没有发现任何一条测试显式依赖“自动 backend 选择”：
  - 它们断言的是公开 builder façade 的结果 contract
  - 没有断言 backend 文本、自动降级、dispatch path 或 runtime snapshot
  - 因而这批最优雅的收口方式仍然不是复制 testcase，而是直接 scalarize 现有 suite
- 本轮最小改动保持很窄：
  - 不新增 suite
  - 不修改 runner manifest
  - 只在 `fafafa.core.simd.testcase.pas` 的 `TTestCase_Builder.SetUp/TearDown` 中加入 `ForceBackend(sbScalar)` / `ResetBackendSelection`
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_Builder`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 EdgeCases Scalarization

- 继续筛剩余候选时，这一轮仍然没有去碰：
  - `UnsignedVectorTypes` / `RustStyleAliases`
  - `Memutils`
  - `dispatch/dataplane/publicabi/runtime/concurrent`
- 原因保持一致：
  - 前两类主要是 typedef/layout/alias/tooling contract，backend 语义密度低
  - `Memutils` 更偏 aligned allocation/tooling contract
  - 最后一类则是控制面/并发面，根本不该机械套进 `sbScalar`
- 交叉核对后，当前更高价值的缺口落在 `TTestCase_EdgeCases`：
  - 它覆盖的是一组真实 contract 的边界语义：
    - `VecF32x4` 的 NaN / Infinity / div-by-zero
    - `SortNet4F32` 的 NaN 排序约定
    - `VecI32x4` / `PrefixSumI32` 的 overflow 语义
    - `MemEqual/MemFindByte/SumBytes` 的极端非对齐/跨页场景
    - `VecF32x4Extract/Insert` 与 `MaskF32x4Test` 的 index saturation
  - suite 的 `SetUp/TearDown` 原本只负责 FPU exception mask 生命周期，没有固定 backend 语义
- 复核 testcase 形状后，没有发现任何一条测试显式依赖“自动 backend 选择”：
  - 它们断言的是公开 façade 与 utility contract 的边界结果
  - 没有断言 backend 文本、自动降级、dispatch path 或 runtime snapshot
  - 虽然混有少量 `utils` helper 边界，但固定 `sbScalar` 不会改变这些 contract 的测试目标
- 本轮最小改动保持很窄：
  - 不新增 suite
  - 不修改 runner manifest
  - 保留原有 FPU exception mask 保存/恢复逻辑
  - 只在 `fafafa.core.simd.edgecases.testcase.pas` 的 `SetUp/TearDown` 中叠加 `ForceBackend(sbScalar)` / `ResetBackendSelection`
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_EdgeCases`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 VecI32x8 Family Scalarization

- 继续筛剩余候选时，这一轮仍然没有去碰：
  - `UnsignedVectorTypes` / `RustStyleAliases`
  - `Memutils`
  - `dispatch/dataplane/publicabi/runtime/concurrent`
  - `PublicAbi` / `SSE2Contracts`
- 原因继续保持明确：
  - 前三类主要是 typedef/layout/alias/tooling contract，或控制面/并发面
  - `PublicAbi` 是 published ABI/control-plane suite
  - `SSE2Contracts` 是 backend-owned / scalar-parity contract，不应机械套进 `sbScalar`
- 交叉核对后，当前更高价值的缺口落在 `TTestCase_VecI32x8`：
  - 它是独立的 public 256-bit family suite，覆盖：
    - `Add/Sub/Mul/Neg`
    - `And/Or/Xor/Not/AndNot`
    - `ShiftLeft/ShiftRight`
    - `CmpEq/Lt/Gt/Le/Ge/Ne`
    - `Min/Max`
    - `Splat/Zero/LoadStore/SizeOf`
    - overflow / max-min 边界
  - 其 `SetUp/TearDown` 原本仍写成“确保默认后端”，没有固定 backend 语义
- 复核 testcase 形状后，没有发现任何一条测试显式依赖“自动 backend 选择”：
  - 它们断言的是公开 `VecI32x8` façade 的结果 contract
  - 没有断言 backend 文本、自动降级、dispatch path 或 runtime snapshot
  - 这也让它和已经 scalarized 的 `VecU32x8` / `VecF32x8` / `VecF64x4` 形成一致口径
- 本轮最小改动保持很窄：
  - 不新增 suite
  - 不修改 runner manifest
  - 只补 `fafafa.core.simd.base` 依赖
  - 只在 `fafafa.core.simd.veci32x8.testcase.pas` 的 `SetUp/TearDown` 中加入 `ForceBackend(sbScalar)` / `ResetBackendSelection`
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_VecI32x8`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 IEEE754 Fixture Mask Restore

- 这轮没有继续机械给 mixed suite 套 `sbScalar`，而是转去复核 `ieee754.testcase` 的真实 fixture 风险。
- 交叉核对后确认，下面三组 suite 都存在同一类状态泄漏：
  - `TTestCase_IEEE754_F64`
  - `TTestCase_IEEE754EdgeCases`
  - `TTestCase_AVX2RoundTruncIEEE754`
- 它们在 `SetUp` 里都会执行：
  - `SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision])`
- 但在本轮之前，它们的 `TearDown` 只做：
  - `ResetToAutomaticBackend`
  - 没有把原始 FPU exception mask 恢复回去
- 这和仓库里其它已知安全模式不一致：
  - `TTestCase_EdgeCases` 已经有 `FSavedExceptionMask`
  - `vecf32x8.testcase` 与 `testcase.pas` 里多处局部异常值测试也都是 `oldMask/savedMask -> SetExceptionMask(oldMask)` 的成对恢复
- 因而这轮修的是一个真实 fixture bug，而不是证据层口径问题：
  - 给上述三个 suite 各自增加 `FSavedExceptionMask`
  - `SetUp` 里先 `GetExceptionMask`
  - 再 `SetExceptionMask([...])`
  - `TearDown` 里保留 `ResetToAutomaticBackend`
  - 再补 `SetExceptionMask(FSavedExceptionMask)`
- 这轮刻意没有改 mixed suite 的语义设计：
  - `IEEE754EdgeCases` 里仍然允许单个 test 自己切 `sbScalar/sbSSE2/sbAVX2`
  - `AVX2RoundTruncIEEE754` 仍然是 AVX2/SSE2/scalar 对照链
  - 本批只修 fixture 生命周期，不改测试目标
- Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IEEE754_F64,TTestCase_IEEE754EdgeCases,TTestCase_AVX2RoundTruncIEEE754`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 Simd.TestCase Stateful Fixture Consolidation

- 继续沿 `tests/fafafa.core.simd/fafafa.core.simd.testcase.pas` 往下深审后，确认当前最高价值缺口已经不再是 alias/type 噪音，而是主 testcase 文件里大面积重复且不对称的 fixture：
  - `TTestCase_Global`
  - `TTestCase_BackendSmoke`
  - `TTestCase_AVX2VectorAsm`
  - `TTestCase_AVX512VectorAsm`
  - `TTestCase_VectorOps`
  - `TTestCase_IntegerFacadeGuards`
  - `TTestCase_FloatFacadeGuards`
  - `TTestCase_LargeData`
  - `TTestCase_OperatorOverloads`
  - `TTestCase_VectorMaskTypes`
  - `TTestCase_TypeConversion`
  - `TTestCase_Builder`
  - `TTestCase_GatherScatter`
  - `TTestCase_ShuffleSWizzle`
  - `TTestCase_MathFunctions`
  - `TTestCase_AdvancedAlgorithms`
- 这些类原先要么在 `SetUp` 里 `ForceBackend(sbScalar)`、退出时只 `ResetBackendSelection`，要么会切 `vector asm/backend` 后只回 `automatic`，没有恢复进入测试前真实状态。
- 本轮没有去碰任何生产实现，而是在同一文件里抽了 3 个共享 fixture：
  - `TSimdBackendStatefulTestCase`
  - `TScalarBackendStatefulTestCase`
  - `TSimdVectorAsmBackendStatefulTestCase`
- 具体改动落点：
  - `Global` 改为继承 `TScalarBackendStatefulTestCase`
  - `BackendSmoke` 改为继承 `TSimdBackendStatefulTestCase`
  - `AVX2VectorAsm` / `AVX512VectorAsm` 改为继承 `TSimdVectorAsmBackendStatefulTestCase`，并通过 `RefreshVectorAsmBackendRegistration` 覆盖各自的 `RegisterAVX2Backend/RegisterAVX512Backend`
  - 一串 scalar façade suite 全部改为继承 `TScalarBackendStatefulTestCase`
  - 删除各自重复的 `SetUp/TearDown`
- 过程中还复现并确认了一个非代码回归的 runner 陷阱：
  - 并行起多个 `BuildOrTest.sh test --suite=...` 会共享同一个 `bin2/lib2` 输出树
  - 实际会出现：
    - `Text file busy`
    - `build rc=2`
  - 这是 runner 并发竞争，不是本批代码错误；后续验证已全部切回串行
- 本轮 Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_Global`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_BackendSmoke`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_AVX2VectorAsm`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IntegerFacadeGuards`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 Scalarized Small Suites Backend Restore

- 继续往剩余 `simd` 测试树深扫后，发现还有一批分散的小 suite 虽然已经 fixed 到 `sbScalar`，但 fixture 仍是旧式只回 automatic：
  - `TTestCase_EdgeCases`
  - `TTestCase_VecF32x8`
  - `TTestCase_VecF64x4`
  - `TTestCase_VecI32x8`
  - `TTestCase_VecU32x8`
  - `TTestCase_NarrowIntegerOps`
  - `TTestCase_ImageProc`
  - `TTestCase_SaturatingArithmetic`
  - `TTestCase_Vec512MaskFacadeGuards`
- 这批修法保持很窄，没有去抽新 shared unit，而是直接按各文件自身语义补 `FSavedBackend`：
  - `SetUp` 统一 `GetDispatchTable` -> 保存 `GetCurrentBackend` -> 再 `ForceBackend(sbScalar)`
  - `TearDown` 保留各自已有清理逻辑，再 `ResetBackendSelection`，必要时 `TrySetActiveBackend(FSavedBackend)`，最后断言恢复成功
- 两个特殊文件已按本地语义保序处理：
  - `EdgeCases` 继续保留原有 `FSavedExceptionMask` 恢复
  - `ImageProc` 继续先恢复 `ImageBlendAlphaMode` 并 `FreeImage(...)`，再恢复 backend
- 本轮 Release 定向验证已完整串行跑完 9 个受影响 suite：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_EdgeCases`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_VecF32x8`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_VecF64x4`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_VecI32x8`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_VecU32x8`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_NarrowIntegerOps`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_ImageProc`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SaturatingArithmetic`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_Vec512MaskFacadeGuards`
- 本轮完整 Release 收口也已通过：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

- 继续沿 `direct.testcase` 做 method-level 深审后，确认当前真实残余不是类级 fixture 缺失，而是大量 test body 的局部 `finally` 仍只 `ResetToAutomaticBackend`，会抹掉进入测试前的 forced backend 语义。
- 在 `tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas` 提取了 `RestoreFixtureDirectDispatchState`，统一恢复 `FSavedVectorAsm + FSavedBackend` 并 `RebindDirectDispatch`；随后把 `TTestCase_DirectDispatch` 里成批 `finally ResetToAutomaticBackend` 收口到这个 helper。
- `Test_DirectDispatchTable_Rebind_AfterForceBackend` 与 `Test_DirectDispatchTable_AutoRebind_AfterDispatchSetActiveBackend` 现在会在路径结束后显式断言：backend 已恢复到进入测试前选择，`GetDirectDispatchTable` 与 `GetDispatchTable` 重新同步。
- `Test_DirectDispatchTable_WideIntegerHelperMatrix_Parity` 的局部 `LOldVectorAsm` 样板已删除，因为共享 helper 已统一处理 `vector asm + backend + direct rebind` 的恢复顺序。
- 本轮 Release 定向验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatchConcurrent`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 中途我误把 `TTestCase_DirectDispatchConcurrent` 和 Release `check` 同时启动了一次；这轮没有触发 `Text file busy/rc=2`，但最终验证仍全部改回串行，并再次清理了 `tests/fafafa.core.simd/__pycache__/`。

- 继续往 `publicabi.testcase` 深审后，确认它虽然已经有类级 `FSavedVectorAsm/FSavedBackend`，但外层 `finally` 里仍残留一大批完全同构的 `SetVectorAsmEnabled(LOldVectorAsm); ResetToAutomaticBackend;` 样板。
- 本轮在 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 提取了 `RestorePublicAbiLocalState`，并让 `TearDown` 也复用它；随后先替换掉第一批 exact-pattern 外层 finally。
- 这批已覆盖的路径包括：
  - `Test_PublicApi_VectorAsmRoundTrip_Reuses_PreviouslyPublishedMetadataTable`
  - `Test_PublicApi_ActiveBackendId_Tracks_RegisterSlot_After_ReRegister`
  - `Test_PublicApi_StableState_Tracks_CurrentBackend_After_ControlPlaneSwitches`
  - `Test_PublicApi_FailedHookMutation_*`
  - `Test_PublicApi_RollbackRestore_*`
  - 一批 `HookLateForce/AutomaticReset` 路径
- 本轮 Release 验证已完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- `gate` 中与本批直接相关的覆盖也都通过了：
  - `public ABI smoke`
  - `TTestCase_PublicAbi,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework`
  - `filtered run_all check chain`
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`；`publicabi.testcase` 后段仍有几处带额外语义的复杂 finally，可作为下一批继续深审入口。

- 随后继续在同一文件做第二次收口，把剩余的 simple exact-pattern 外层 finally 也统一切到 `RestorePublicAbiLocalState`，覆盖了 `DataPlane_Parity`、后段 `SetVectorAsmEnabled_*`、`RegisterBackend_*` 和几条带 table-capture 清理的 restore-path 测试。
- 第二次修改后的复验链也已重新串行跑完：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 结果：全部通过
- 这一轮之后，`publicabi.testcase` 里简单两行式的 `LOldVectorAsm + ResetToAutomaticBackend` 外层 finally 已清空；下一批若继续沿 public ABI 深审，应只剩那些夹杂额外 hook/restore 语义的复杂块需要逐段审读。

- 继续往 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 深审后，确认这个文件并不缺 fixture，真实残余是 `TSimdStatefulTestCase` 之下很多 test body 外层 `finally` 仍重复写 `SetVectorAsmEnabled(LOldVectorAsm); ResetToAutomaticBackend;`。
- 期间两次尝试 `mcp__ace_tool__.search_context` 都在 120s 超时，因此这批直接切回本地源码实证：用 `sed/rg` 定位 `TSimdStatefulTestCase` 的 `SetUp/TearDown` 与 14 个 simple exact-pattern 命中，再避免盲改内部轮次级恢复块。
- 本轮在 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 提取了 `RestoreSimdLocalState`，并让 `TearDown` 也复用它；随后把以下路径的 simple outer finally 统一切到 `RestoreSimdLocalState(LOldVectorAsm, FSavedBackend)`：
  - `TTestCase_SimdConcurrentPublicAbi` 的 register/vector-asm 读写一致性测试
  - `TTestCase_SimdConcurrentFramework` 的 current-backend/current-backend-info/backend-ops/runtime-snapshot/dispatchable-helper 读写一致性测试
  - `TTestCase_SimdConcurrentRegistration.Test_Concurrent_RegisteredBackendList_FirstRegistration_ReadConsistency`
  - `TTestCase_SimdConcurrent.Test_Concurrent_DispatchMixed_ControlPlane`
- 本轮刻意没有扫掉：
  - 只恢复 `LOldVectorAsm` 的纯 toggle 测试
  - 每轮内部用来做下一步断言的 `ResetToAutomaticBackend` 状态机块
- 本轮 Release 定向验证已串行完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrent,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework,TTestCase_SimdConcurrentRegistration`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交；下一批若继续沿 `concurrent.testcase` 深审，应优先逐段看内部状态机块，而不是继续做全局机械替换。

- 继续横向扫描整个 `tests/fafafa.core.simd/` 后，发现当前最厚的残余样板已经转到 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`：
  - 文件本身已有 `TDispatchAPIStatefulTestCase`
  - 但 method-level outer finally 仍成批手写 `vector asm + automatic reset`
  - 前半段多为 `SetVectorAsmEnabled(LOldVectorAsm); ResetToAutomaticBackend;`
  - 后半段 SSE2/AVX/SSE3/SSSE3/SSE4.x parity 区则常写成反序 `ResetToAutomaticBackend; SetVectorAsmEnabled(LOldVectorAsm);`
- 本轮在 `dispatchapi.testcase` 提取了 `RestoreDispatchApiLocalState`，并让 `TearDown` 也复用它；随后分两步收口：
  - 第一步收前半段 control-plane / metadata 区的 26 处 exact-pattern outer finally
  - 第二步收后半段 SSE2/AVX/SSE3/SSSE3/SSE4.x parity 区 8 处反序 outer finally
- 这次没有盲扫所有 `ResetToAutomaticBackend`：
  - 内层 rollback / hook 状态机块仍保留原位
  - 只恢复 `LOldVectorAsm`、本身不切 backend 的纯结构/审计 test 不动
- 本轮两次 Release 验证都已串行跑完，最终以最后一次为准：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- `dispatchapi.testcase` 里明确的两行式 outer finally 形态现在都已清空：
  - `SetVectorAsmEnabled(LOldVectorAsm); ResetToAutomaticBackend;`
  - `ResetToAutomaticBackend; SetVectorAsmEnabled(LOldVectorAsm);`
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`；下一批如果继续沿 `dispatchapi.testcase` 深审，重点应转向那些不是两行式样板、而是夹带局部 rollback / backend mutation 语义的复杂恢复块。

- 在上面两簇两行式清空后，我继续沿 `TTestCase_DispatchAPI` 本体逐段复核，确认还残留第三类更隐蔽的 procedure-level outer finally：只写 `SetVectorAsmEnabled(LOldVectorAsm);`，但同样没有复用 `FSavedBackend`。
- 这批没有扩 scope 到 companion 类，而是只把 `TTestCase_DispatchAPI` 本体里明确的 15 处 pure `vector-asm-only` outer finally 统一切到 `RestoreDispatchApiLocalState(LOldVectorAsm, FSavedBackend)`。
- 这次刻意不碰的范围仍保持不变：
  - companion 类里需要逐段判断的局部恢复语义
  - 纯 toggle / structural 审计路径
  - 内层 rollback / backend mutation 状态机块
- 这轮 Release 验证已重新串行跑完：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`；但继续复核后确认这个 stop-point 还不够准，`dispatchapi` 后段 capability/override 路径和两条 companion mask-contract 里其实还残留另一簇 pure `vector asm` outer finally。

- 随后我继续沿这些后段命中往下收，确认这批新的 simple outer finally 残余分成两块：
  - `TTestCase_RISCVVMaskedOpsContract` 2 处 mask capability/public-ABI contract
  - `TTestCase_DispatchAPI` 后段 `AVX512/NEON/RISCVV/AVX2/SSE3/SSSE3/SSE4.x` capability/override 路径 18 处
- 这次仍然没有去碰内部 helper finally，而是只把这些明确的顶层 outer finally 统一切到 `RestoreDispatchApiLocalState(LOldVectorAsm, FSavedBackend)`。
- 本轮 Release 验证再次串行跑完：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`；当前 `dispatchapi.testcase` 剩余的裸 `SetVectorAsmEnabled(LOldVectorAsm)` 命中已经缩到长方法内部 helper / nested procedure 的局部 finally，不再是顶层 test outer finally。

- 继续沿同一文件逐段核对后，确认 `dispatchapi.testcase` 剩余的顶层裸 `SetVectorAsmEnabled(LOldVectorAsm)` 其实都集中在 `TTestCase_NonX86BackendParity`，一共 16 处。
- 这批仍然沿最小修法处理：
  - 不新建 helper
  - 直接复用现有 `RestoreDispatchApiLocalState(LOldVectorAsm, FSavedBackend)`
  - 对 `FreeAligned(...)`、局部 buffer 复位等本地清理语句保持原顺序
- 本轮 Release 定向验证已串行跑完：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_NonX86BackendParity`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`；现在 `dispatchapi.testcase` 里顶层 test outer finally 的裸 `SetVectorAsmEnabled(LOldVectorAsm)` 已经清零，剩余命中只在内部 helper / nested procedure 局部 finally。

- 在上面那批 pure `vector asm` outer finally 收完后，我继续沿 `TTestCase_NonX86BackendParity` 逐段复核，确认同一类 companion parity 测试里还残留 12 处顶层 `finally ResetToAutomaticBackend;`。
- 这批仍然没有扩 scope 到生产实现或内部 helper，而是把这 12 处统一切到 `RestoreDispatchApiLocalState(FSavedVectorAsm, FSavedBackend)`，让顶层 restore contract 直接回到进入测试前保存的 `vector asm + backend`。
- `Test_WideInteger_FuzzSeed_Parity_IfAvailable` 的 `RandSeed := LOriginalSeed;` 继续保留在 helper 之前，没有改变随机种子恢复顺序。
- 这轮复验仍按串行 release 链执行：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_NonX86BackendParity`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 这批之后，`TTestCase_NonX86BackendParity` 顶层 outer finally 中的 `ResetToAutomaticBackend` 已清零；`dispatchapi.testcase` 剩余的 `ResetToAutomaticBackend` 主要落在复杂 rollback/backend mutation/helper 状态机块，下一批需要改成逐段读语义，而不是继续盲扫。

- 继续按“复杂块逐段读语义”往下审后，我把 `dispatchapi.testcase` 剩余的 `ResetToAutomaticBackend` 命中重新分了类，确认还有一批是真正的尾声冗余：
  - `RegisterBackend(..., LOriginalTable)` 已经把表恢复回去
  - 后面马上 `end;` / 交给 outer finally / 交给 fixture `TearDown`
  - 中间没有新的断言依赖 automatic 状态
- 本轮因此只删除了这 20 处尾声重复 reset，没有去碰 setup reset、中途 hook reset、或手工探针路径。
- 受影响的主要路径包括：
  - `TrySetActiveBackend_*` hook mutation / rollback restore
  - `RegisterBackend_*` metadata / snapshot round-trip
  - `BenchmarkActivation_Rejects_CpuSupportedButNonDispatchable_Backend`
  - 多条 `Vec*Facade_Tracks_CurrentDispatchTable_After_ReRegister`
- 这轮 release 验证已串行完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断更清楚了：`dispatchapi.testcase` 剩余的 `ResetToAutomaticBackend` 已主要不是“尾声 cleanup 噪音”，而是测试前置条件或中途状态机语义点；下一批如果继续收，应优先审 `7999/8006/9316/9329` 这一类跨 hook/跨 test probe 的边界，而不是再扫普通尾声。

- 继续按这组复杂点往下审时，我确认 `7999/8006` 里的真正高价值不是再删一个 cleanup reset，而是 `9305` 这条 cross-test probe：
  - 手工 `Create` 了 `TTestCase_DispatchAPI`
  - 直接调了 `Test_TrySetActiveBackend_RollbackRestore_Success_Preserves_ForcedSelection`
  - 却没有显式跑 inner `SetUp/TearDown`
- 被调的 inner test 自己又在 finally 里用到了 `RestoreDispatchApiLocalState(LOldVectorAsm, FSavedBackend)`，所以这条 probe 原本其实在隐式依赖测试类零值，并且靠块尾 `ResetToAutomaticBackend` 收拾现场。
- 本轮把这条 probe 改成了显式 fixture 契约：
  - 新增 `LInnerSetupDone`
  - `LCase.SetUp`
  - 调用 inner `Test_*`
  - `LCase.TearDown`
  - `LCase.Free`
  - 同时删掉原来的块尾 `ResetToAutomaticBackend`
- 这轮 release 验证已串行完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_RISCVFallbackDispatchContract,TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前结论更新：`dispatchapi.testcase` 里下一类更值得继续查的，不再是普通 reset 形状，而是“测试是否把 fixture 当 helper 用”这类跨 test/probe 边界。

- 继续往 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 深审后，确认这轮最值得收的已经不是再扫 `ResetToAutomaticBackend`，而是 helper 化之后残留的 `RestoreOriginalActiveBackend(...)` 双恢复尾声。
- 逐段复核后，已定位 9 处真正的冗余点，它们都满足同一个条件：
  - 先 `RestoreOriginalActiveBackend(...)`
  - 后面要么直接 `end;`
  - 要么马上再走 `RestorePublicAbiLocalState(...)`
  - 中间没有新的断言依赖“先恢复回原 backend”的状态
- 本轮因此只删除这 9 处尾声双恢复，没有去碰仍带后续断言依赖的调用点；`RestoreOriginalActiveBackend(...)` 在该文件里现在只保留 1 处真实需要的命中：
  - `Test_PublicApi_Table_Refreshes_AfterBackendSwitch`
  - 因为它在 finally 后还要断言 active backend 追踪恢复后的 backend
- 本轮 Release 验证已串行完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断更新：
  - `publicabi.testcase` 里简单 outer finally 与双恢复尾声都已经大幅收敛
  - 下一批若继续沿 public ABI 深审，应优先逐段看剩余 hook/state-machine 复杂 finally 是否真的存在断言依赖，而不是继续按形状删恢复语句
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

- 继续沿 `publicabi.testcase` 逐段看剩余恢复点后，我确认新的高价值并不在 hook/state-machine 中途 reset，而是在 capability/pod-info 用例那 14 处顶层 pure `SetVectorAsmEnabled(LOldVectorAsm)` outer finally。
- 这些用例都会通过 `SetVectorAsmEnabled(True/False)` 触发 runtime rebuild 和 active backend 重选，但尾声只恢复 `vector asm`，没有回到类级 `FSavedBackend`；因此它们和前几批 `dispatchapi/publicabi` 的顶层恢复不对称问题是同一类。
- 本轮因此没有去碰复杂 hook 路径，而是把这 14 处统一切到 `RestorePublicAbiLocalState(LOldVectorAsm, FSavedBackend)`，覆盖：
  - `x86` capability bits 路径
  - `AVX2/AVX512` capability bits 路径
  - `NEON/RISCVV` capability bits 路径
- 本轮 Release 验证继续按串行链完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断再次收紧：
  - `publicabi.testcase` 顶层 pure `vector asm` outer finally 已清零
  - 剩余更值得继续查的，只会是确实夹带 hook/rollback/failure 语义的复杂 reset/restore 块，而不是普通 capability/pod-info 尾声样板
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

- 继续沿 `publicabi.testcase` 的复杂 hook/rollback/failure 路径往下看后，我这轮没有再机械扫 `ResetToAutomaticBackend`，而是收了两类更确定的 exact-contract 冗余：
  - 3 处空 `finally`
  - 7 条正常流已恢复原 table、但 outer finally 仍会重复 `RegisterBackend(...original...)` 的 duplicate table restore
- 这次保持了最小修法：
  - 空 `finally` 直接删壳
  - 对 `CachedTable_Cdecl_EntryPoints_Follow_CurrentDataPlane_After_ReRegister` 增加 `LOriginalTableRestored`
  - 对多条 `*TableCaptured` 路径在显式恢复原 table 成功后立刻清 capture 状态，保留 outer finally 只兜底异常路径
- 本轮 Release 验证继续按串行链完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - `publicabi.testcase` 里空壳与 duplicate table restore 又清掉一层
  - 下一轮更值得查的，已经缩到那些“中途 reset/restore 本身就是测试主题”的 hook/state-machine 块，要逐段看是否还有真实的尾声噪音或 fixture 边界问题
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

- 继续沿 complex failure 路径查异常兜底后，我补了一个真正的 fixture safety 漏点，而不是继续删普通噪音：
  - `Test_PublicApi_FailedHookMutation_DoesNotRevive_PreviouslyRequestedBackend_AfterRestore`
  - 之前只有正常流末尾的 `RegisterBackend(LRequestedBackend, LOriginalTable)`
  - 没有 `*TableCaptured` outer restore guard
- 本轮把它补齐成和同文件后段 hook/rollback 路径一致的模式：
  - 新增 `LRequestedTableCaptured`
  - 捕获原 table 后置 `True`
  - 正常恢复后置 `False`
  - outer finally 里在需要时兜底 `RegisterBackend(...)`
- 本轮 Release 验证继续按串行链完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断再次收紧：
  - `publicabi.testcase` 里既有的 easy cleanup 冗余已经进一步收口
  - 下一轮更值得继续挖的，是其它 complex hook/state-machine 路径里是否还存在少数“异常流没有 outer table restore guard”的漏点
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

- 继续沿 complex hook/state-machine 路径往下审后，我又收了一条不那么显眼的 duplicate restore：
  - `Test_PublicApi_RollbackRestore_Success_Preserves_ForcedSelection`
  - 成功流里已经先恢复了一轮 higher-priority backends
  - outer finally 还会再按 `GPublicAbiHookRollbackForceSuccessHigherCount` 跑一轮相同恢复
- 这次没有改 hook helper 的阶段语义，而是只在成功恢复完成后关掉 outer finally 的重复 restore 条件：
  - `LTargetTableCaptured := False`
  - `GPublicAbiHookRollbackForceSuccessHigherCount := 0`
- 本轮 Release 验证继续按串行链完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - `publicabi` 里 easy duplicate restore 和 failure restore guard 都在往下收
  - 下一轮更值得继续查的，是其它 multi-object hook/state-machine 路径里是否还有类似“normal path 已恢复，outer finally 还重复恢复”的隐藏点
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

- 继续把视野从 `publicabi` 放宽到整个 `tests/fafafa.core.simd` 后，我又收掉一批同类 fixture 恢复分叉，但这次落点在 `dataplane + ieee754`：
  - `dataplane.testcase` 的 `VectorAsmRoundTrip` finally 还只恢复 `vector asm + automatic`
  - `ieee754.testcase` 里 4 个 tearDown 和 6 个方法级 finally 也在重复同一旧形状
  - 其中 `NonX86_RoundTruncFloorCeil_NaNInf_IfAvailable` 的外层 finally 甚至只恢复了 `vector asm`
- 我先补了两个 helper：
  - `RestoreDataPlaneLocalState(...)`
  - `RestoreIEEE754LocalState(...)`
  然后把这些 tearDown / finally 全部统一到“恢复保存 backend”的语义。
- 中途踩到一个很具体的 Pascal 编译边界：
  - 顶层 helper 里直接写 `AssertTrue(...)`
  - Release build 立刻红在 `Identifier not found "AssertTrue"`
  - 说明顶层 helper 不在 `TTestCase` 方法作用域
  - 随后我把 helper 收成 `Boolean` 返回值，再由各个 tearDown / finally 自己断言，问题即消失
- 本轮 Release 验证按串行链完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DataPlane`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IEEE754EdgeCases`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_AVX2RoundTruncIEEE754`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_NonX86IEEE754`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IEEE754_F64`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - `publicabi` 之外剩余的“顶层只恢复 automatic / 只恢复 vector asm”的老形状又少了一批
  - 下一轮更值得继续查的，已经更像其它 companion testcase 里的少量 method-level restore 分叉，而不是 `publicabi` 那种复杂 hook/state-machine cleanup 噪音
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

- 我继续沿 companion testcase 小文件往下扫，又收了一批更小但更确定的 restore 分叉：
  - `dispatchslots.testcase` 的类级 tearDown 还是手写 backend restore
  - 同文件有 3 条方法尾声还只做 `ResetToAutomaticBackend`
  - `sse2contracts.testcase` 的 tearDown 也还保留着老式 `vector asm + automatic + backend` 手写恢复
- 这次没有扩到 `direct / concurrent`，而是只收最稳定的两份小文件：
  - 新增 `RestoreDispatchSlotsLocalState(...)`
  - 新增 `RestoreSSE2ContractsLocalState(...)`
  - 统一采用 helper 返回 `Boolean`、调用点 `AssertTrue(...)` 的形状，避免再踩顶层 helper 直接断言的 Pascal 作用域坑
- 本轮 Release 验证继续按串行链完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAllSlots`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SSE2Contracts`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - `dispatchslots / sse2contracts` 这类小 companion testcase 的 restore 样板又少了一层
  - 下一轮如果继续挖，更值得看的将是 `direct` 或 `concurrent` 里那些“局部 helper 已存在，但个别 method-level finally 仍留 old shape”的少数残点
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

- 我继续按上一轮的 stop-point 往下收，只动 `concurrent` 里最确定的两条残点：
  - `Test_Concurrent_VectorAsmToggle_DispatchReadConsistency`
  - `Test_Concurrent_VectorAsmToggle_MultiWriter_DispatchRead`
  它们的 outer finally 之前都还只恢复 `vector asm`。
- 这次没有扩到 `direct` 的全局过程 cleanup，因为那条需要单独补原始 backend 捕获；而 `concurrent` 这里已经有现成的 `RestoreSimdLocalState(...)`，直接复用最稳。
- 本轮改动非常小：
  - 两处 `SetVectorAsmEnabled(LOldVectorAsm)` 直接替换成 `RestoreSimdLocalState(LOldVectorAsm, FSavedBackend)`
  - 不改 worker 创建/释放、并发轮次、断言和 round-level `ResetToAutomaticBackend` 语义
- 本轮 Release 验证继续按串行链完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrent`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - `concurrent` 里最明显的 method-level old-shape finally 又少了两条
  - 下一轮更值得看的，基本就收缩到 `direct` 那个全局过程尾声 restore 分叉，以及 `concurrent` 里少数 round-level cleanup 是否还存在真正冗余
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

- 我继续按这个 stop-point 往下收，直接处理了 `direct` 里那条全局过程 cleanup 分叉：
  - `RunDirectDispatchConcurrentReRegisterSnapshotConsistency`
  - 之前 finally 只会恢复 scalar 原表、回到 automatic、然后 rebind direct dispatch
  - 没有回到调用前真实 backend
- 这次没有重构成新 helper，而是做最小闭环：
  - 过程入口捕获 `LOriginalBackend := GetCurrentBackend`
  - finally 里恢复 scalar 原表后，如果当前 backend 不是原 backend，就 `TrySetActiveBackend(LOriginalBackend)`
  - 恢复失败时抛出明确异常，再 `RebindDirectDispatch`
- 本轮 Release 验证继续按串行链完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatchConcurrent`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - `direct / concurrent` 这一簇最显眼的 old-shape cleanup 又少了一层
  - 下一轮如果继续挖，就该从“简单 restore 分叉”切换到再判断剩余 `concurrent` round-level `ResetToAutomaticBackend` 是否是真正冗余，还是测试主题本身需要的控制面动作
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

- 我继续按“先挑最稳的 method-level 尾声残点”往下收，这一批没有去碰 `publicabi/dispatchapi` 的复杂 hook 状态机，而是只动两簇已经具备明确 restore 语义的基础测试：
  - `dispatchapi` 最前 4 条基础 API 测试
  - 根 `testcase` 的 backend-consistency wrapper / meta tests
- 这次的核心判断是：
  - `dispatchapi` 已经有 `RestoreDispatchApiLocalState(...)`，前 4 条老测试却还只回 automatic
  - `TTestCase_BackendVectorConsistency` 的两条“preserves previous forced backend”元测试内部语义没问题，但测试退出时把 backend 留在 automatic，不回到进入测试前状态
- 本轮最小修法：
  - `dispatchapi` 的 4 个 finally 统一改成 `RestoreDispatchApiLocalState(FSavedVectorAsm, FSavedBackend)`
  - 根 `testcase` 新增 `RestoreBackendVectorConsistencyLocalState(...)`
  - `Test_VectorOps_Consistency` 复用这个 helper 去掉手写 restore 样板
  - 两条 backend-consistency 元测试补 `LEntryBackend`，finally 中恢复进入态 backend
- 本轮 Release 验证继续按串行链完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_BackendVectorConsistency`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - `dispatchapi` 里最前面的基础 API 测试已经不再和后续 helper-based cleanup 形状分叉
  - backend-consistency 元测试也不再把 backend 漂移留在 automatic
  - 下一轮更值得继续看的，还是 `dispatchapi/publicabi` 剩余复杂路径里是否还有少量“方法尾声 or 异常流 restore 契约”残点，而不是 round-level 控制面动作
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

- 我继续沿 `dispatchapi` 残点往下收，但这轮仍然刻意避开复杂 hook/state-machine，改成收一批 backend-only / metadata tests：
  - `SetActiveBackend_Unavailable_FallsBackToScalar`
  - `BackendInfoAvailableFalse_IsNotSelectable`
  - `SupportedAliases_StayCpuOnly_WhenBackendBecomesNonDispatchable`
  - `RegisteredBackendDispatchTable_PreservesCanonicalTextMetadata_After_ReRegister`
  - `CurrentBackendInfo_PreservesCanonicalTextMetadata_After_ReRegister`
- 这次的判断依据很直接：
  - 这些测试内部确实需要 `ResetToAutomaticBackend` 或“当前 backend”语义来建立场景
  - 但测试结束后仍把 backend 恢复推迟给外层 `TearDown`，或者只回到 automatic
  - 所以中途控制面步骤不改，只补最外层退出态 restore
- 本轮最小修法：
  - 第一条 simple test 的 finally 直接改成 `RestoreDispatchApiLocalState(FSavedVectorAsm, FSavedBackend)`
  - 其余 4 条加 outer `try...finally`
  - 内层 `RegisterBackend(..., LOriginalTable)` 和 automatic/current-backend 断言不动
  - 顺手把一条旧变量名改成 `LOriginalBackend/LBeforeTry/LAfterAuto/LOriginalTable/LModifiedTable`
- 本轮 Release 验证继续按串行链完成：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - `dispatchapi` 里 backend-only / metadata 这簇旧 cleanup 形状又少了一层
  - 下一轮如果继续挖，更值得看的将是 `dispatchapi` 后段 facade/current-dispatch 跟踪测试，或 `publicabi` 中少量仍依赖 outer fixture 才恢复 saved state 的同类路径
- 本轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

- 我继续沿这个 stop-point 往下收，但这轮还是避开 `publicabi` 的复杂 hook/state-machine，只处理 `dispatchapi` 后段 9 条 facade/current-dispatch easy wins：
  - `VecF32x4ReduceFacade`
  - `VecF64x2ReduceFacade`
  - `VecF64x2MathFacade`
  - `VecF32VectorMathFacade`
  - `VecWideFloatDotFacade`
  - `VecF64x4ReduceFacade`
  - `VecF32x8ReduceFacade`
  - `VecF64x8ReduceFacade`
  - `VecF32x16ReduceFacade`
- 这次的判断边界保持不变：
  - 中途 `ResetToAutomaticBackend` 和 current-backend re-register 是测试主题步骤，不动
  - 内层 `RegisterBackend(LBackend, LOriginalTable)` 已经负责表回滚，不动
  - 只补最外层退出态，让测试方法自己恢复 `FSavedVectorAsm + FSavedBackend`
- 本轮最小修法：
  - 9 条测试都补 outer `try...finally`
  - finally 统一用 `RestoreDispatchApiLocalState(FSavedVectorAsm, FSavedBackend)`
  - synthetic reduce/math/dot slots、`GetDispatchTable^` 断言、facade 跟踪当前 dispatch table 的断言全部保持原样
- 这批 release 验证链已经先行跑过并全绿：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - `dispatchapi` 后段 facade/current-dispatch 这一簇 method-level old-shape cleanup 又少了一层
  - 下一轮如果继续深挖，首选还是 `publicabi` 中和 current-publication / facade tracking 对应的 easy wins；备选再回头扫 `dispatchapi` 更零散的 benchmark/AVX 特化 cleanup 残点
- 这轮提交前需要再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录跟着进入工作树。

- 我继续从 `dispatchapi` 切到 `publicabi`，但没有去碰 hook-heavy rollback state machine，而是先收 3 条 current-publication easy wins：
  - `Test_PublicApi_CachedTable_RemainsCallable_Across_Rebind`
  - `Test_PublicApi_CachedTable_Preserves_PreviousSnapshot_Metadata_Across_Rebind`
  - `Test_PublicApi_BackendPodInfo_Refreshes_WhenBackendBecomesNonDispatchable`
- 这次的核心判断是：
  - 前两条会在方法内切换 active backend / public ABI 当前发布态后直接退出
  - 第三条虽然会把被改写的 backend table 回滚回来，但 active backend 已因 unavailable 重注册发生 re-selection
  - 三者都仍把 saved-state 恢复留给类级 `TearDown`
- 本轮最小修法：
  - 3 条测试都补 outer `try...finally`
  - finally 统一调用 `RestorePublicAbiLocalState(FSavedVectorAsm, FSavedBackend)`
  - `BackendPodInfo_Refreshes_WhenBackendBecomesNonDispatchable` 保留内层 `RegisterBackend(LOriginalBackend, LOriginalTable)`，只让它继续负责表回滚
- 这轮还额外踩到一个工具层事实：
  - `ace-tool/search_context` 连续两次在 `publicabi` 审查上超时
  - 后续改成 `rg + nl -ba` 精确文件审查，避免在同一路径上空转
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - `publicabi` 最明显的 cached/current-publication method-exit restore 分叉又少了一层
  - 下一轮如果继续深挖，优先看 `publicabi` 里其余“内层已经闭合 table rollback、最外层仍缺 saved-state restore”的同类路径；如果没有再缩得很稳的候选，再回头扫 `dispatchapi` 更零散的 benchmark/AVX 特化 cleanup 残点
- 这轮提交前仍要再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录跟着进入工作树。

- 我继续按这个 stop-point 回到 `dispatchapi` 后段，这轮收的是一簇 cleanup 冗余/缺口混合的 easy wins：
  - 4 条 AVX512 tests 的 inner `ResetToAutomaticBackend` 与 outer `RestoreDispatchApiLocalState(...)` 重复收尾
  - `Test_DispatchChangedHooks_MultiSubscriber_Dedup_And_Remove` 的 finally 还只回 automatic
- 这次的关键判断边界是：
  - AVX512 tests 里被测语义是 mapping/parity/IEEE754 contract，本身不依赖“先回 automatic 再做后续断言”
  - hook 多订阅测试体内的 `ResetToAutomaticBackend` 仍然是被测通知步骤，不能删
  - 真正该改的是 method-exit cleanup，而不是中途 control-plane 动作
- 本轮最小修法：
  - 4 条 AVX512 tests 直接删掉 inner `finally ResetToAutomaticBackend`
  - 保留 outer `RestoreDispatchApiLocalState(LOldVectorAsm, FSavedBackend)` 作为唯一 method-exit cleanup
  - hook 多订阅测试的 finally 改成移除 hook 后调用 `RestoreDispatchApiLocalState(FSavedVectorAsm, FSavedBackend)`
- 这轮工具层也有一个重复现象：
  - `ace-tool/search_context` 针对这簇 `dispatchapi` 残点再次超时
  - 仍然改走 `nl -ba` 精确片段审查，没有继续在超时路径上空转
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - `dispatchapi` 后段 AVX512 特化 tests 的重复退出态 cleanup 又少了一层
  - hook 多订阅测试也不再把 saved-state 恢复推迟到 `TearDown`
  - 下一轮如果继续深挖，更适合再缩 `publicabi/dispatchapi` 里“中途 control-plane 步骤必须保留，但 finally 仍旧 old-shape”的零散残点，而不是机械清空所有 `ResetToAutomaticBackend`
- 这轮提交前仍要再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录跟着进入工作树。

- 我继续把搜索面扩到 `ieee754`，这轮没有去动 non-x86 loop 里的 reset，而是先收 `TTestCase_IEEE754EdgeCases` 里 3 条最稳的 method-exit old-shape finally：
  - `Test_F32x4_RoundTrunc_NaNInf_Scalar`
  - `Test_F32x4_RoundTrunc_NaNInf_SSE2`
  - `Test_Wide_RoundTrunc_NaNInf_Scalar`
- 这次的核心判断是：
  - 这 3 条都属于已有 `RestoreIEEE754LocalState(...)` helper 的 stateful testcase
  - finally 只是在方法退出时回 automatic，或者手写 `vector asm + automatic`，没有额外测试主题语义
  - 但 non-x86 property/loop tests 的 inner `ResetToAutomaticBackend` 更像每轮 backend 编排隔离，所以这轮刻意不动
- 本轮最小修法：
  - 3 条 tests 的 finally 全部切到 `AssertTrue(..., RestoreIEEE754LocalState(...))`
  - scalar tests 用 `FSavedVectorAsm + FSavedBackend`
  - SSE2 test 用 `oldVectorAsm + FSavedBackend`
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IEEE754EdgeCases`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - `ieee754.edgecases` 的 method-exit old-shape cleanup 又少了一层
  - 下一轮如果继续深挖，更值得先缩 `ieee754` 里那些已经明显是 method-exit old-shape、而不是 loop/iteration control-plane 的剩余 finally；其次再回到 `publicabi/dispatchapi` 看更零散的 easy wins
- 这轮提交前仍要再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录跟着进入工作树。

- 我继续往“测试文件级冗余 fixture”这一层收，没有碰生产实现，也暂时避开 `edgecases/imageproc/vec512types` 这类带额外清理语义的文件，只先处理 6 个纯 scalar fixture testcase：
  - `vecf32x8`
  - `veci32x8`
  - `vecu32x8`
  - `narrowintegerops`
  - `vecf64x4`
  - `saturating`
- 这轮的核心判断是：
  - 仓里已经有统一的 `TScalarBackendStatefulTestCase`
  - 上面 6 份 testcase 仍各自重复 `GetDispatchTable; FSavedBackend := GetCurrentBackend; ForceBackend(sbScalar);` 和对应 restore/assert 样板
  - 这属于纯测试夹具冗余，不需要再新造 helper，也不需要改任何测试语义
- 本轮最小修法：
  - 6 个 testcase 全部改为继承 `TScalarBackendStatefulTestCase`
  - 删除各自重复的 `FSavedBackend/SetUp/TearDown`
  - `vecf32x8` 与 `vecf64x4` 增加/保留 `fafafa.core.simd.scalar`，因为文件内部仍显式调用 `ScalarSplat/Clamp/Floor/...` helper 做期望值，不是单纯为了 backend 注册
- 这轮中途抓到一个很直接的编译层事实：
  - 初版顺手删掉 `vecf64x4`（以及潜在的 `vecf32x8`）里的 `fafafa.core.simd.scalar` 后，Release build 立即报 `Identifier not found "Scalar*F64x4"` 一串错误
  - 修正方式不是回退基类收敛，而是只恢复真正仍被测试体显式调用的 `scalar` unit 依赖
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_VecF32x8,TTestCase_VecI32x8,TTestCase_VecU32x8,TTestCase_NarrowIntegerOps,TTestCase_VecF64x4,TTestCase_SaturatingArithmetic`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - simd 测试层“每个小 testcase 都自带一份 scalar backend fixture”这类冗余又少了一层
  - 后续如果继续沿这个方向深挖，优先再看同类纯 fixture 文件；带 FPU exception mask、image 生命周期或 AVX512 guard 语义的 testcase 仍应单独审，不适合机械切基类
- 这轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

- 这轮已经把发布级 Linux 证据链重新收口到真实绿态，而不是继续停在 helper cleanup：
  - 先复核 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
  - 确认真红项缩到两组：
    - `linux_gate_summary`: 缺 terminal gate row
    - Windows evidence freshness / source-newer-than-evidence / closeout freshness
  - 随后按 release 策略串行重跑：
    - `FAFAFA_BUILD_MODE=Release SIMD_QEMU_PLATFORMS='linux/arm/v7 linux/arm64 linux/riscv64' SIMD_GATE_QEMU_NONX86_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1 SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT=0 SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=0 SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：
    - `tests/fafafa.core.simd/logs/gate_summary.md` 已补出 terminal row
    - `qemu-cpuinfo-nonx86-evidence` 在 `2026-05-14 20:25:03` PASS
    - `tests/fafafa.core.simd/logs/qemu-multiarch-20260514-201939-906920/summary.md` 中 `linux/arm/v7`、`linux/arm64`、`linux/riscv64` 全部 PASS
  - 再跑 `freeze-status` 后，Linux 侧已全部转绿，剩余红项只剩 Windows freshness

- 针对 Windows evidence，本轮把“脚本是否真能跑到 blocker”也查清了：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight`
  - 结果：`STATUS=PASS`，workflow=`simd-windows-b07-evidence.yml`，repo=`dtamade/fafafa.core`
  - 当前本地 `main` 仍相对 `origin/main` 为 `ahead 126`
  - 为了不把 126 个提交直接推上主干，本轮先把当前 `HEAD` 推到临时远端分支：
    - `simd-win-evidence-20260514-0cbc7204`
  - 另外补了本地同名分支，让 `SIMD_WIN_EVIDENCE_REF=simd-win-evidence-20260514-0cbc7204` 能被 `win-evidence-via-gh` 正确解析到当前提交

- 当前真正的剩余 blocker 也已经拿到直接证据，不再是猜测：
  - `FAFAFA_BUILD_MODE=Release SIMD_WIN_EVIDENCE_REF=simd-win-evidence-20260514-0cbc7204 bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-via-gh SIMD-20260514-152`
  - workflow dispatch 成功，run id=`25860032794`
  - 但 GitHub Actions 立刻失败，注释原文是：
    - `The job was not started because recent account payments have failed or your spending limit needs to be increased.`
  - `run_windows_b07_closeout_via_github_actions.sh` 已把它识别成 billing block，并以 `exit=31` fail-close
  - 结论：当前 `freeze-status` 无法继续靠本地修脚本/修测试变绿，必须等 GitHub 账单恢复，或改走真实可用的 Windows runner 再重新刷新 evidence

- 在 Windows freshness 外部阻塞明确之后，我继续回到 `simd` 测试层做剩余冗余扫描，并完成了一批更细粒度的“single-use exact wrapper” cleanup：
  - `dataplane.testcase` 中的 `RestoreDataPlaneLocalState(...)` 已删除，唯一调用点直接改为 `RestoreSavedBackendAndVectorAsmState(...)`
  - `publicabi.testcase` 中的 `RestoreOriginalActiveBackend(...)` 已删除，唯一调用点直接改为 `RestoreSavedBackendState(...)`
  - `backend.consistency.testcase` 中的 `SaveBackendConsistencyState(...)` 已删除，7 处调用点直接改为 `SaveActiveBackendState(...)`
  - `backend.consistency` 的 `RestoreBackendConsistencyState(...)` 保留，因为它还承担 `GetActiveBackend = saved backend` 的本地断言语义，不是纯复制体
- 这批的判断边界是：
  - 只删“单定义 + 单调用”或“纯 pass-through save wrapper”
  - 不删任何仍带 backend-active 断言、hook rollback、rebind 或 control-plane 语义的本地壳
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DataPlane,TTestCase_PublicAbi,TTestCase_BackendVectorConsistency`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

- 我在这条线上又往前推进了一个更小的单点 batch：`vec512types` 里的 `TTestCase_Vec512MaskFacadeGuards`。
- 这轮判断先刻意卡住边界：
  - `TTestCase_Vec512Types` 本身只是普通类型/算术 smoke，不需要 stateful fixture
  - 真正重复 scalar backend 样板的是 `TTestCase_Vec512MaskFacadeGuards`
  - 这个 guard suite 固定 `sbScalar` 的目的只是补 façade direct evidence，不夹带 vector-asm、FPU mask 或 image 生命周期
- 因而本轮最小修法就是：
  - 给文件引入 `fafafa.core.simd.testcase`
  - 把 `TTestCase_Vec512MaskFacadeGuards` 改成继承 `TScalarBackendStatefulTestCase`
  - 删除本地 `FSavedBackend/SetUp/TearDown`
  - 顺手移除只给旧夹具用的 `fafafa.core.simd.dispatch`
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_Vec512MaskFacadeGuards`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - `vec512types` 里 pure scalar façade guard 的重复 fixture 也已经收回统一基类
  - 下一轮如果继续沿 fixture 去重走，优先级更高的将是先复核 `edgecases/imageproc` 这类“确实 stateful，但还夹带额外清理语义”的文件，不能按这批的机械方式直接切
- 这轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

- 我继续往前收的是两份“不是纯 scalar fixture，但 backend 保存/恢复仍然重复”的 testcase：
  - `edgecases`
  - `imageproc`
- 这轮先把边界卡死了：
  - `edgecases` 还要保存/恢复 `TFPUExceptionMask`
  - `imageproc` 还要保存/恢复 `TImageBlendAlphaMode`，并负责 `FSrc1/FSrc2/FDest` 的释放
  - 所以不能像 `vecf32x8`/`vec512 mask guard` 那样直接把整个本地 lifecycle 全删掉
- 本轮最小修法因此拆成两种：
  - `TTestCase_EdgeCases` 改继承 `TSimdBackendStatefulTestCase`
    - backend 的 `GetDispatchTable/FSavedBackend/ResetBackendSelection/TrySetActiveBackend` 全部回到公共基类
    - 本地只保留 `FSavedExceptionMask`、`SetExceptionMask(...)` 和 `ForceBackend(sbScalar)`
  - `TTestCase_ImageProc` 改继承 `TScalarBackendStatefulTestCase`
    - backend force/restore 全部回到公共基类
    - 本地只保留 `FillChar(FSrc1/2/Dest)`、`Get/SetImageBlendAlphaMode` 和 `FreeImage(...)`
- 这轮也顺手缩掉了两个只服务旧 backend fixture 的 `uses`：
  - `edgecases` 去掉 `fafafa.core.simd.dispatch`
  - `imageproc` 去掉 `fafafa.core.simd.dispatch`
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_EdgeCases,TTestCase_ImageProc`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - `edgecases/imageproc` 这类“带额外清理语义的 stateful fixture”也已经能部分收回公共基类
  - 这证明后续剩余 testcase 不必二选一地“全保留旧样板”或“机械切到 scalar 基类”；可以按额外语义拆出更细粒度的去冗余
  - 下一轮如果继续沿这个方向深挖，更值得看的是仍在自带 backend fixture 的 `direct/dataplane/runtime/sse2contracts` 这类 testcase，先判断哪些已经有自定义基类、哪些还能继续往公共基类收
- 这轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

- 我继续往前收的是两份“backend 保存/恢复可以回到公共基类，但 vector-asm 开关仍需 testcase 本地维护”的 testcase：
  - `dataplane`
  - `sse2contracts`
- 这轮先把边界卡清楚了：
  - 两个 testcase 旧样板都同时保存 `FOldBackend + FOldVectorAsm`
  - 但仓内现成的 `TSimdBackendStatefulTestCase` 已经完整提供 `GetDispatchTable -> save current backend -> TearDown restore saved backend`
  - 真正 testcase 专属的剩余状态只有 `vector-asm` 开关
  - 同时 `TSimdVectorAsmBackendStatefulTestCase` 虽然也现成，但它受 `{$IFDEF UNIX}{$IFDEF CPUX86_64}` 条件约束，而且要求实现 `RefreshVectorAsmBackendRegistration`，对这两份文件来说过重
- 本轮最小修法因此是：
  - `TTestCase_DataPlane` 改继承 `TSimdBackendStatefulTestCase`
  - `TTestCase_SSE2Contracts` 改继承 `TSimdBackendStatefulTestCase`
  - 两个文件都引入 `fafafa.core.simd.testcase`
  - 删除本地 `FOldBackend`
  - `SetUp` 只保留 `FOldVectorAsm := IsVectorAsmEnabled`
  - `TearDown` 只做 `SetVectorAsmEnabled(FOldVectorAsm); inherited TearDown; AssertTrue(... IsVectorAsmEnabled = FOldVectorAsm)`
  - `dataplane` 内那条方法级 local restore 也从 `RestoreDataPlaneLocalState(LOldVectorAsm, FOldBackend)` 收回到 `RestoreDataPlaneLocalState(LOldVectorAsm, FSavedBackend)`，避免继续依赖已删除的本地 backend 缓存
- 这轮也顺手验证了一个结构事实：
  - `TSimdBackendStatefulTestCase.SetUp` 已负责 `GetDispatchTable`
  - 所以这两份 testcase 不需要再本地重复调用一次
  - backend 的恢复契约也可以完全由公共基类断言，不必再各自保留一套 `ResetToAutomaticBackend / TrySetActiveBackend / AssertTrue`
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SSE2Contracts,TTestCase_DataPlane`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - `dataplane/sse2contracts` 这类“backend + vector-asm 双状态” testcase 也已经能按更细粒度拆出公共与专属生命周期
  - 这说明后续继续深挖时，不必急着把所有 vector-asm testcase 都硬套进 `TSimdVectorAsmBackendStatefulTestCase`
  - 更稳的做法仍然是先看 testcase 是否真的只剩 `vector-asm` 专属状态，再决定是否保留本地字段
- 这轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

- 我继续往前收的是两份“各自维护一个本地 stateful 基类，但 backend 生命周期其实已经和公共基类同构”的 testcase：
  - `concurrent`
  - `direct`
- 这轮先把边界卡清楚了：
  - `concurrent` 的 `TSimdStatefulTestCase` 重复了 `GetDispatchTable + save backend + TearDown restore backend`，额外本地状态只剩 `FSavedVectorAsm`
  - `direct` 的 `TDirectDispatchStatefulTestCase` 也重复了同一套 backend fixture，只是在 fixture restore 时额外需要 `RebindDirectDispatch`
  - `dispatchslots` 虽然也像候选，但它保存的是 `GetActiveBackend`，不是 `GetCurrentBackend`，这轮先不混进来
- 本轮最小修法因此是：
  - `TSimdStatefulTestCase` 改继承 `TSimdBackendStatefulTestCase`
  - `TDirectDispatchStatefulTestCase` 改继承 `TSimdBackendStatefulTestCase`
  - 两个文件都引入 `fafafa.core.simd.testcase`
  - 删除各自本地的 `FSavedBackend`
  - `SetUp` 不再本地重复 `GetDispatchTable / GetCurrentBackend`
  - `concurrent` 的 `TearDown` 改成只恢复 `FSavedVectorAsm`，然后 `inherited TearDown`，最后断言 vector-asm 已回到进入态
  - `direct` 的 `TearDown` 也改成同样顺序，但在 `inherited TearDown` 后追加 `RebindDirectDispatch`
- 这轮还刻意保留了两类本地 helper 语义不动：
  - `RestoreSimdLocalState(...)` 继续服务 `concurrent` 里方法级 local restore
  - `RestoreFixtureDirectDispatchState` 继续服务 `direct` 里方法级 restore 与 rebind
  - 也就是说，这轮只抽“类级 backend lifecycle”，不去碰并发编排或 direct dispatch 语义
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrent,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework,TTestCase_SimdConcurrentRegistration,TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - simd 测试层已经不只是“单 testcase 自带一份 fixture”，连文件内自建的局部 stateful 基类也可以继续向公共 backend 基类收口
  - `dispatchslots` 之所以还没动，不是遗漏，而是它当前保存/恢复的是 active-backend 语义，必须先把 `GetActiveBackend` 与 `GetCurrentBackend` 的边界核死
  - 下一轮更合适的方向就是专门复核 `dispatchslots` 这条 active/current 语义线，而不是继续盲目扩散到更多文件
- 这轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

- 我继续往前收的是 `dispatchslots` 这份一直刻意没碰的 suite。
- 这轮先补齐了最关键的语义证据：
  - `GetActiveBackend` 来自当前 published dispatch table 的 `Backend`
  - `runtime` 里的 `BuildSimdRuntimePublishedState` 在有 dispatch 时也是直接把 `CurrentBackend := LDispatch^.Backend`
  - 也就是说，这份 suite 外层 fixture 若只保存/恢复 backend，`GetCurrentBackend` 与 `GetActiveBackend` 在当前实现里对齐到同一个 published dispatch backend truth
- 因而这轮最小修法就成立了：
  - 文件引入 `fafafa.core.simd.testcase`
  - `TTestCase_DispatchAllSlots` 改继承 `TSimdBackendStatefulTestCase`
  - 删除本地 `FSavedBackend`
  - 删除只服务类级 fixture 的 `SetUp/TearDown`
  - 保留 `RestoreDispatchSlotsLocalState(...)` 和测试体里的 `GetActiveBackend / TrySetActiveBackend / ResetToAutomaticBackend`，继续把 raw dispatch 语义断言留在 suite 内部
- 这轮修法的关键不是“又少一份样板”，而是边界终于明确了：
  - 外层 fixture 可以用公共 backend lifecycle
  - suite 内部真正关心的 active-backend / dispatch-level 语义仍然保持原样，不被 façade/runtime 名称替换掉
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAllSlots`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - `dispatchslots` 这条 active/current 语义线已经拿到足够证据，因此也成功收回公共 backend 基类
  - 这意味着本轮从 pure scalar fixture、复杂 stateful fixture、本地局部基类，到 raw dispatch slot suite，已经把一整串 backend lifecycle 冗余连续压下去了
  - 下一轮若继续深挖，更值得找的是剩余仍保留 testcase-local backend fixture 的零散文件，而不是再回头怀疑 `dispatchslots`
- 这轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

- 我继续往前收的是 `publicabi` 和 `dispatchapi` 这两份 hook-heavy 测试文件里的类级 backend fixture。
- 这轮先把边界卡清楚了：
  - 两份文件都还有一层本地 stateful 基类
  - 这层基类都重复了 `GetDispatchTable -> save current backend -> TearDown restore backend`
  - testcase 专属剩余状态都只还有 `FSavedVectorAsm`
  - `publicabi` 额外还需要在 `TearDown` 前先 `ResetPublicAbiSyntheticHookState`
  - `dispatchapi` 则保留方法级 `RestoreDispatchApiLocalState(...)` 供测试体自己做 local cleanup
- 本轮最小修法因此是：
  - `TTestCase_PublicAbi` 改继承 `TSimdBackendStatefulTestCase`
  - `TDispatchAPIStatefulTestCase` 改继承 `TSimdBackendStatefulTestCase`
  - 两个文件都引入 `fafafa.core.simd.testcase`
  - 删除本地 `FSavedBackend`
  - `SetUp` 不再本地重复 `GetDispatchTable / GetCurrentBackend`
  - `publicabi` 的 `TearDown` 改成：
    - 先 `ResetPublicAbiSyntheticHookState`
    - 再恢复 `FSavedVectorAsm`
    - 再 `inherited TearDown`
    - 最后断言 vector-asm 已回到进入态
  - `dispatchapi` 的 `TearDown` 改成：
    - 先恢复 `FSavedVectorAsm`
    - 再 `inherited TearDown`
    - 最后断言 vector-asm 已回到进入态
- 这轮也刻意保留了两类本地 helper 不动：
  - `RestorePublicAbiLocalState(...)` 继续服务 `publicabi` 内部的方法级 restore
  - `RestoreDispatchApiLocalState(...)` 继续服务 `dispatchapi` 内部的方法级 restore
  - 也就是说，这轮只抽掉“类级 backend lifecycle”，不去碰 hook state machine、本地 synthetic rollback 语义或 method-exit helper
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi,TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - `publicabi/dispatchapi` 这两个 hook-heavy 主 testcase 也已经收回公共 backend 基类
  - 说明这条 cleanup 线已经从轻量 scalar suite 一路推进到最复杂的 control-plane/hook-heavy suite，并且仍保持 release gate 绿色
  - 下一轮如果继续沿 fixture 去重收口，最自然的剩余目标就是 `ieee754` 里仍然各自保存 `FSavedBackend` 的多套 testcase
- 这轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

- 我继续往前收的是 `ieee754` 这份还保留 4 套本地 backend fixture 的 testcase 文件：
  - `TTestCase_IEEE754_F64`
  - `TTestCase_IEEE754EdgeCases`
  - `TTestCase_AVX2RoundTruncIEEE754`
  - `TTestCase_NonX86IEEE754`
- 这轮先把边界卡清楚了：
  - 4 个 testcase 都重复了 `GetDispatchTable + save current backend + TearDown restore backend`
  - 但它们的 testcase 专属状态并不一样：
    - `F64 / EdgeCases / AVX2RoundTrunc` 还各自保存 `TFPUExceptionMask`
    - `F64` 还会在 `SetUp` 里额外强制 `sbScalar`
    - `NonX86IEEE754` 没有 exception mask，但仍要保留方法级 `RestoreIEEE754LocalState(...)`
  - 所以这轮不去新造“IEEE754 专属公共基类”，也不顺手改 `F64` 的 scalar 强制方式，只抽掉类级 backend lifecycle
- 本轮最小修法因此是：
  - 4 个 testcase 全部改继承 `TSimdBackendStatefulTestCase`
  - 文件引入 `fafafa.core.simd.testcase`
  - 删除 4 处本地 `FSavedBackend`
  - `SetUp` 不再本地重复 `GetDispatchTable / GetCurrentBackend`
  - 3 个带 exception mask 的 testcase 在 `TearDown` 里统一改成：
    - 先恢复 `FSavedVectorAsm`
    - 再 `inherited TearDown`
    - 再恢复 `FSavedExceptionMask`
    - 最后断言 vector-asm 已回到进入态
  - `NonX86IEEE754` 的 `TearDown` 则只恢复 `FSavedVectorAsm` 后 `inherited TearDown`，再断言 vector-asm 状态
  - `F64` 仍保留本地 `SetActiveBackend(sbScalar)`，不把这轮扩大成“切 `TScalarBackendStatefulTestCase` + 同步调整语义”的另一种改动
- 这轮也刻意保留了 `RestoreIEEE754LocalState(...)` 不动：
  - 它还在大量方法级 local restore 中使用
  - 所以这轮依然只抽“类级 backend lifecycle”，不去碰 method-level round/trunc/floor/ceil 编排语义
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IEEE754_F64,TTestCase_IEEE754EdgeCases,TTestCase_AVX2RoundTruncIEEE754,TTestCase_NonX86IEEE754`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 当前判断继续更新：
  - `ieee754` 这块的类级 backend fixture 现在也已经全部收回公共基类
  - 这意味着当前 `simd` 测试层里最大的一串 backend lifecycle 重复体已经基本从 scalar guard、dispatch/public ABI/control-plane，到 IEEE754 专项都连续压过了一遍
  - 下一轮更值得做的是重新全量扫一遍 `tests/fafafa.core.simd/*.pas`，确认还剩哪些真正有必要保留的本地 fixture，而不是继续按直觉点名文件
- 这轮收口后已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-14 Freeze Snapshot Fallback Hardening

- 这轮没有继续碰 `src/` 或 testcase 冗余，而是转去修一个 completion audit 暴露出来的 closeout 语义坑：
  - 普通 `BuildOrTest.sh gate` 默认会 `reset_gate_summary`
  - 所以一旦 fresh cross gate 之后又跑了普通 fast gate，canonical `tests/fafafa.core.simd/logs/gate_summary.md` 会被覆盖
  - 旧版 `evaluate_simd_freeze_status.py` 又只看这一份 canonical 摘要，因此会把已通过的 `qemu-cpuinfo-nonx86-evidence` / `evidence-verify` 错判回缺失
- 这轮先把真实边界查清了：
  - 问题不只是“latest gate run 选择太死”，更是“closeout gate 摘要没有稳定快照入口”
  - `logs/windows-closeout/<batch-id>/` 已经是 Windows closeout 批次快照目录，但此前不稳定保留实际 freeze 使用的 `gate_summary.md`
- 因而本轮最小修法分成两段：
  - `evaluate_simd_freeze_status.py`
    - 未显式设置 `SIMD_FREEZE_GATE_SUMMARY_FILE` 时，同时扫描 canonical `logs/gate_summary.md` 与 `logs/windows-closeout/*/gate_summary.md`
    - 先按 terminal gate 时间排序
    - 只有在“最新 gate 的基础步骤仍 PASS，但缺的是 closeout 证据步骤（如 `qemu-cpuinfo-nonx86-evidence` / `evidence-verify`）”时，才允许 fallback 到最近一份满足当前 freeze 约束的 closeout snapshot
    - 如果最新 gate 连基础步骤都不绿，仍旧 fail-close，不会拿旧 snapshot 掩盖真实回归
  - `run_windows_b07_closeout_finalize.sh`
    - 现在会把实际 freeze 使用的 `gate_summary.md/json` 一并保存到 batch 目录
    - 这样后续即使 canonical 摘要被新的 fast gate 覆盖，`freeze-status` 仍有稳定 closeout snapshot 可选
- 本轮还补了一条新的 rehearsal：
  - `case_batch_fallback`
  - 场景是：最新 canonical gate 只有 fast-gate 基础步骤，缺 `qemu-cpuinfo-nonx86-evidence` / `evidence-verify`
  - 但 `windows-closeout/<batch-id>/gate_summary.md` 里保留着更早一轮完整 closeout gate
  - 预期结果：`freeze-status` 继续 `ready=True`，并明确打印 fallback 选中的 closeout snapshot
- 本轮验证链：
  - `python3 -m py_compile tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
  - `bash -n tests/fafafa.core.simd/run_windows_b07_closeout_finalize.sh`
  - `bash -n tests/fafafa.core.simd/rehearse_freeze_status.sh`
  - `git diff --check`
  - `bash tests/fafafa.core.simd/rehearse_freeze_status.sh`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
  - 结果：
    - rehearsal 全绿，并新增 `case_batch_fallback_rc=0`
    - 真实仓库 `freeze-status` 仍只红 Windows freshness / source-newer-than-windows / closeout freshness，没有引入新的 Linux 假红

## 2026-05-14 Shared VectorAsm Fixture Base Extraction

- 这轮继续做测试层冗余审查时，没有再去碰 `publicabi/dispatchapi/ieee754` 这些重控制面，而是挑了两份还留着轻量重复体的小型 suite：
  - `tests/fafafa.core.simd/fafafa.core.simd.dataplane.testcase.pas`
  - `tests/fafafa.core.simd/fafafa.core.simd.sse2contracts.testcase.pas`
- 这两份文件都还在手写同一套 fixture 生命周期：
  - `FOldVectorAsm := IsVectorAsmEnabled`
  - `TearDown` 时 `SetVectorAsmEnabled(FOldVectorAsm)`
  - 最后断言 `IsVectorAsmEnabled = FOldVectorAsm`
- 现有公共层里虽然已经有 `TSimdVectorAsmBackendStatefulTestCase`，但它比这两份 suite 需要的语义更厚：
  - 它不仅恢复 vector-asm 状态
  - 还要求子类提供 `RefreshVectorAsmBackendRegistration`
  - 这个 refresh 语义只对 `AVX2/AVX512 vectorasm` 专项成立，不该强加给 `dataplane` / `sse2contracts`
- 因而本轮最小修法不是把这两份 suite 强塞进现有厚基类，而是先把层次补对：
  - 在 `fafafa.core.simd.testcase.pas` 新增 `TSimdVectorAsmStatefulTestCase`
    - 只负责保存/恢复 `IsVectorAsmEnabled`
    - 把恢复动作抽成可 override 的 `RestoreVectorAsmState`
  - 让现有 `TSimdVectorAsmBackendStatefulTestCase` 继承这个新薄基类
    - 仅在 override 的 `RestoreVectorAsmState` 里追加 `RefreshVectorAsmBackendRegistration`
  - `TTestCase_DataPlane` 与 `TTestCase_SSE2Contracts` 直接改继承 `TSimdVectorAsmStatefulTestCase`
    - 删除本地 `FOldVectorAsm`
    - 删除重复的 `SetUp/TearDown`
- 这批层次调整的价值在于：
  - `vector-asm state restore` 与 `backend re-registration` 终于被拆成两个清晰层次
  - 后续再遇到只需要“保存/恢复 vector-asm 状态”的 suite，就不必再复制 `FOldVectorAsm` 壳，也不用误依赖 `AVX2/AVX512` 那套 refresh 语义
  - 同时现有 `AVX2/AVX512 vectorasm` 专项的生命周期没有被削弱，只是改成挂在更准确的子类上
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DataPlane,TTestCase_SSE2Contracts`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 这轮过程中我一开始把 `test/check/gate` 并发发出去了，考虑到共享输出目录存在临时互扰风险，随后特别核对了真实结果；这次没有出现 `Text file busy` 或 `rc=1/2` 假红，最终三条验证都实绿。

## 2026-05-14 EdgeCases Scalar Fixture Alignment

- 继续往 `tests/fafafa.core.simd` 里扫剩余 fixture 冗余时，`edgecases.testcase` 暴露出一处很干净的小残点：
  - suite 本身始终要求 `sbScalar`
  - 但类还继承 `TSimdBackendStatefulTestCase`
  - 然后在 `SetUp` 里手动再做一次 `ForceBackend(sbScalar)`
- 复核 `fafafa.core.simd.testcase.pas` 后已确认：
  - `TScalarBackendStatefulTestCase.SetUp` 本身就会在保存 backend 后统一 `ForceBackend(sbScalar)`
  - `TTestCase_EdgeCases` 自己真正额外需要保留的只有 `TFPUExceptionMask` 的保存/恢复
  - 因此这不是语义特殊，而是单纯没对齐到现成公共基类
- 本轮最小修法已落地：
  - `TTestCase_EdgeCases` 改继承 `TScalarBackendStatefulTestCase`
  - 删除 `SetUp` 末尾重复的 `ForceBackend(sbScalar)`
  - FPU exception mask 的 save/restore 逻辑不动
- 这批调整的意义不在于少一行代码，而是把 test fixture 语义表达得更准确：
  - 读者一看类层次就知道这是 scalar-only suite
  - 后续如果继续扫剩余 testcase，也更容易区分“真的需要自定义 backend 编排”和“只是历史重复”
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_EdgeCases`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 这轮 `gate` 明确按串行收口；前面并发验证里出现过 `nonx86 opt-in/riscvv rc=2` 的共享输出目录假红，所以这次没有把它当代码回归处理。

## 2026-05-14 Concurrent Fixture Base Alignment

- 继续扫剩余 `FSavedVectorAsm` / `SetUp/TearDown` 冗余时，`concurrent.testcase` 的基类壳非常突出：
  - `TSimdStatefulTestCase` 仍继承 `TSimdBackendStatefulTestCase`
  - 自己再定义一份 `FSavedVectorAsm`
  - `SetUp/TearDown` 仅做 `IsVectorAsmEnabled` 的保存/恢复
  - 但这些动作现在已经被公共 `TSimdVectorAsmStatefulTestCase` 完整承载
- 复核后确认：
  - `TSimdStatefulTestCase` 真正的 suite-specific 语义只有 `RestoreSimdLocalState(...)`
  - 这个 helper 会在测试中间态恢复时追加“backend 已恢复”的断言
  - 它和 `SetUp/TearDown` 的重复 vector-asm 生命周期不是一回事
- 本轮最小修法已落地：
  - `TSimdStatefulTestCase` 改继承 `TSimdVectorAsmStatefulTestCase`
  - 删除本地 `FSavedVectorAsm`
  - 删除重复 `SetUp/TearDown`
  - 保留 `RestoreSimdLocalState(...)` 与所有调用点不变
- 这批改动覆盖到 3 组并发 suite，但仍属于测试 infrastructure 对齐，不是并发逻辑改写：
  - `TTestCase_SimdConcurrent`
  - `TTestCase_SimdConcurrentPublicAbi`
  - `TTestCase_SimdConcurrentFramework`
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrent,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 这轮也再次验证了一个判断：
  - 当前 `tests/fafafa.core.simd` 里最值得继续清的，已经不再是大块逻辑重复，而是这种“共享 fixture 基类已经存在，但个别 suite 还保留旧生命周期壳”的尾部残点。

## 2026-05-14 DispatchAPI Fixture Base Alignment

- 顺着同一条 `FSavedVectorAsm` 线继续扫，`dispatchapi.testcase` 里又出现了几乎同构的一层基类壳：
  - `TDispatchAPIStatefulTestCase` 仍继承 `TSimdBackendStatefulTestCase`
  - 本地再保存一份 `FSavedVectorAsm`
  - `SetUp/TearDown` 只做 `IsVectorAsmEnabled` 的保存/恢复
  - 但 suite-specific 的真正语义只在 `RestoreDispatchApiLocalState(...)`
- 复核后确认这个点和 `concurrent` 的边界一致：
  - 公共 fixture 生命周期可以交给 `TSimdVectorAsmStatefulTestCase`
  - `RestoreDispatchApiLocalState(...)` 继续保留，负责测试中途恢复时的 backend-restore 断言
  - 不需要也不应该去动 `DispatchHook*`、public smoke、non-x86 audit、wide family parity 等被测逻辑
- 本轮最小修法已落地：
  - `TDispatchAPIStatefulTestCase` 改继承 `TSimdVectorAsmStatefulTestCase`
  - 删除本地 `FSavedVectorAsm`
  - 删除重复 `SetUp/TearDown`
  - 保留 `RestoreDispatchApiLocalState(...)` 与所有调用点不变
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 到这里可以更明确地说：
  - `TSimdVectorAsmStatefulTestCase` 现在已经不仅服务 `dataplane/sse2contracts`
  - 它也接住了 `concurrent` 和 `dispatchapi` 这两块更重的测试入口
  - 后续如果再看 `publicabi/direct/ieee754`，就可以用更严格的标准判断它们剩下的本地 fixture 是否真的还有额外语义

## 2026-05-14 PublicAbi Fixture Base Alignment

- 沿着同一条基类对齐思路继续往下看，`publicabi.testcase` 也暴露出同类重复壳：
  - `TTestCase_PublicAbi` 仍继承 `TSimdBackendStatefulTestCase`
  - 本地再保存 `FSavedVectorAsm`
  - `SetUp/TearDown` 手工做 vector-asm 保存/恢复
  - 但真正额外的 suite-specific 行为只有 `ResetPublicAbiSyntheticHookState` 的前后包裹顺序，以及 `RestorePublicAbiLocalState(...)` 的 backend-restore 断言
- 复核后确认这条可以安全下沉：
  - `SetUp` 里去掉手工 `FSavedVectorAsm := IsVectorAsmEnabled` 后，不影响 hook reset 顺序
  - `TearDown` 里先 `ResetPublicAbiSyntheticHookState`，再交给 `TSimdVectorAsmStatefulTestCase.TearDown` 恢复 vector-asm / backend，时序仍与原设计一致
  - 所有 `RestorePublicAbiLocalState(...)` 调用点继续显式传入中间态保存的 `LOldVectorAsm` 或 fixture 级 `FSavedVectorAsm`
- 本轮最小修法已落地：
  - `TTestCase_PublicAbi` 改继承 `TSimdVectorAsmStatefulTestCase`
  - 删除本地 `FSavedVectorAsm`
  - `SetUp/TearDown` 只保留 hook-state reset
  - `RestorePublicAbiLocalState(...)` 与被测 public ABI 行为不动
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 到这里，`TSimdVectorAsmStatefulTestCase` 已经实接：
  - `dataplane`
  - `sse2contracts`
  - `concurrent`
  - `dispatchapi`
  - `publicabi`
- 这意味着下一轮再继续扫时，风险边界已经明显抬高：
  - `direct` 还带 `RebindDirectDispatch`
  - `ieee754` 还混着 exception/rounding 编排
  - 不再适合按“同构生命周期壳”直接机械收口

## 2026-05-14 Direct Fixture Base Alignment

- 在 `publicabi` 收完之后，回头复核 `direct.testcase`，确认它虽然比前几批多一个 `RebindDirectDispatch`，但这层额外语义和公共 lifecycle 仍然是可分离的：
  - `SetUp` 只是在保存 `FSavedVectorAsm`
  - `RestoreFixtureDirectDispatchState(...)` 的 suite-specific 语义是“restore backend/vector-asm 后立即 rebind direct table，并断言 backend 恢复成功”
  - `TearDown` 的 suite-specific 语义则是“公共 restore 完成后，再做一次 `RebindDirectDispatch`”
- 这意味着本轮最小修法可以继续保持在 fixture 基类层：
  - `TDirectDispatchStatefulTestCase` 改继承 `TSimdVectorAsmStatefulTestCase`
  - 删除本地 `FSavedVectorAsm`
  - 删除重复 `SetUp`
  - `TearDown` 只保留 `inherited TearDown` 之后的 `RebindDirectDispatch`
  - `RestoreFixtureDirectDispatchState(...)` 完全不动
- 这样做的价值是：
  - direct suite 继续保有它真正需要的 rebind contract
  - 但 `vector-asm` 生命周期不再维护第二份壳
  - 当前公共 `TSimdVectorAsmStatefulTestCase` 的抽象边界因此又多覆盖了一条更特殊的测试入口
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 到这里可以更细地给剩余候选分层：
  - `direct` 这种“公共 lifecycle + suite-specific post-restore action”仍然是可安全下沉的
  - `ieee754` 则已经不只是 post-restore action，而是把 exception mask、scalar forcing、rounding 路径编排一起揉进 fixture，必须单独重新拆

## 2026-05-14 IEEE754 Fixture Base Alignment

- 重新逐段核对 `ieee754.testcase` 后，确认这里的冗余虽然风险更高，但仍然主要落在 fixture 生命周期，而不在具体测试体：
  - `TTestCase_IEEE754_F64`、`TTestCase_IEEE754EdgeCases`、`TTestCase_AVX2RoundTruncIEEE754` 都在重复
    - `FSavedVectorAsm`
    - `FSavedExceptionMask`
    - `SetUp/TearDown`
  - 其中真正的 suite-specific 差异只有：
    - `F64` 额外在 `SetUp` 里 `SetActiveBackend(sbScalar)`
    - `NonX86IEEE754` 根本不需要异常 mask，只是在重复 `vector-asm` lifecycle
- 因而这轮没有把基类抽到全局 `testcase.pas`，而是采取更稳的本地化修法：
  - 在 `ieee754.testcase.pas` 内新增 `TIEEE754MaskedVectorAsmStatefulTestCase`
  - 让它统一处理 `GetExceptionMask/SetExceptionMask` 与公共 `TSimdVectorAsmStatefulTestCase` 生命周期
  - `F64` 只保留自己的 `SetActiveBackend(sbScalar)` override
  - `EdgeCases` / `AVX2RoundTrunc` 直接复用这个本地基类
  - `NonX86IEEE754` 直接改继承 `TSimdVectorAsmStatefulTestCase`
- 这轮验证里还抓到一个和代码本身无关的环境瞬态：
  - 首次 `Release gate` 在 build 阶段报 `Can't call the linker ... /usr/bin/ld.bfd error code: -7`
  - 但定向 `ieee754` 四套件与 Release `check` 已先绿
  - 串行重跑同一条 `gate` 后完整 PASS，说明这是本机链接器瞬态，不是本轮代码回归
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IEEE754_F64,TTestCase_IEEE754EdgeCases,TTestCase_AVX2RoundTruncIEEE754,TTestCase_NonX86IEEE754`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：最终全部通过
- 到这里，`ieee754` 这组原本最像“别碰”的 fixture 冗余，也已经在不动测试语义的前提下完成了结构收口。

## 2026-05-14 VectorAsm Backend Setup Sharing

- 继续沿着“共享 fixture 已经存在，但个别 suite 还保留旧生命周期壳”的线往下扫，`fafafa.core.simd.testcase.pas` 里 `AVX2/AVX512 vectorasm` 两组很突出：
  - 都继承 `TSimdVectorAsmBackendStatefulTestCase`
  - 都还保留一份本地 `SetUp`
  - 内容完全同构，都是：
    - `SetVectorAsmEnabled(True)`
    - 重新注册目标 backend 刷新 dispatch table
    - `ForceBackend(...)`
- 复核后确认这不是 suite-specific 编排，而是共享 contract 没有完全提升：
  - `TSimdVectorAsmBackendStatefulTestCase` 已经承载 restore 后的 `RefreshVectorAsmBackendRegistration`
  - 但 setup 侧的“开启 vector asm + refresh + force target backend” 还散落在 `AVX2` / `AVX512` 各自的 suite 里
  - 两个 suite 真正独有的只剩：
    - 目标 backend 枚举值
    - 具体 `Register*Backend` 实现
- 本轮最小修法已落地：
  - `TSimdVectorAsmBackendStatefulTestCase` 新增抽象 `GetVectorAsmTargetBackend`
  - 新增共享 `SetUp`
  - `TTestCase_AVX2VectorAsm` / `TTestCase_AVX512VectorAsm` 删除本地重复 `SetUp`
  - 分别只实现 `GetVectorAsmTargetBackend` 和 `RefreshVectorAsmBackendRegistration`
- 这批的意义不是“少了几行代码”，而是把 vectorasm backend-stateful 基类的 contract 补完整了：
  - restore 阶段负责恢复 vector asm 状态并重新注册目标 backend
  - setup 阶段负责开启 vector asm、刷新注册并强制目标 backend
  - suite 本身只保留 backend-specific 的最小差异面
- 本轮 Release 验证链：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_AVX2VectorAsm,TTestCase_AVX512VectorAsm`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮也再次确认一个边界：
  - `tests/fafafa.core.simd` 当前最明显的机械 fixture 冗余已经基本收口
  - 下一步更值得做的，不会再是继续机械删 `SetUp/TearDown`
  - 而应转向“哪些本地 fixture/helper 仍然真的承载必要语义、哪些源码/测试层还有更深的结构冗余或缺失”

## 2026-05-14 Fixture Helper Truth-Source Consolidation

- 在 `vectorasm` 共享 setup 收口之后，继续从“机械 fixture 去重”往更深一层看，发现 `tests/fafafa.core.simd` 里还留着一个 infrastructure 级重复来源：
  - `fafafa.core.simd.fixturehelpers` 已经是真正的 backend/vector-asm save-restore helper 单元
  - 但 `fafafa.core.simd.testcase` 还在对外再包一层同名 `RestoreSavedBackendState` / `RestoreSavedBackendAndVectorAsmState`
  - 多个 suite 通过 `testcase` 间接调用，导致测试基础设施里同一语义有两层入口
- 复核后确认这层 `testcase` façade 没有附加任何本地语义：
  - 不是带断言的 restore helper
  - 不是按 suite 编排的 lifecycle contract
  - 只是完全直通 `fixturehelpers`
- 本轮最小修法已落地：
  - 删除 `fafafa.core.simd.testcase.pas` 里的同名 façade 声明与实现
  - 以下调用者直接 `uses fafafa.core.simd.fixturehelpers`
    - `dataplane`
    - `direct`
    - `dispatchapi`
    - `publicabi`
    - `concurrent`
    - `ieee754`
    - `dispatchslots`
  - `backend.consistency` 原本就直接依赖 `fixturehelpers`，无需改动
- 这批比前面几轮更像“真相源收敛”而不是“局部生命周期清理”：
  - 以后 save/restore 语义只需要在 `fixturehelpers` 看一处
  - `testcase` 继续只承担 suite/base-class infrastructure，不再顺带扮演 helper re-export façade
  - 读代码时也更容易区分“共享状态基类”和“共享状态函数 helper”
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DataPlane,TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent,TTestCase_DispatchAPI,TTestCase_PublicAbi,TTestCase_SimdConcurrent,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework,TTestCase_IEEE754_F64,TTestCase_IEEE754EdgeCases,TTestCase_AVX2RoundTruncIEEE754,TTestCase_NonX86IEEE754,TTestCase_DispatchAllSlots`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 这轮也进一步证明：
  - 当前更值得继续抓的，不只是 testcase 层的 `SetUp/TearDown`
  - 还包括这种“共享 helper 已独立存在，但旧 façade 还留在另一个基础设施单元里”的历史残留

## 2026-05-14 Runtime Backend Fixture Alignment

- 在 helper 真相源收敛之后，继续扫剩余“还在手工维护 backend 生命周期”的点，`runtime.testcase` 很突出：
  - `TTestCase_RuntimeAPI` 仍直接继承 `TTestCase`
  - 其中 3 个控制面测试各自手工保存/恢复原 backend
  - 但 suite 本身并不需要 vector-asm、hook reset、rebind、exception mask 之类额外 fixture 语义
- 复核后确认它已经满足公共 backend fixture 的边界：
  - `TSimdBackendStatefulTestCase` 正是保存/恢复 backend 选择的共享 contract
  - 这些测试真正关心的是 runtime/facade 在切换与 reset 过程中的观测结果
  - finally 里的 restore 只是 cleanup，不是被测行为的一部分
- 本轮最小修法已落地：
  - `TTestCase_RuntimeAPI` 改继承 `TSimdBackendStatefulTestCase`
  - `runtime.testcase` 增加 `uses fafafa.core.simd.testcase`
  - `Test_RuntimeControlPlane_SwitchAndReset_Match_LegacyFacade`
  - `Test_FacadeRuntimeControlPlane_Wrappers_Interoperate_With_Legacy_Aliases`
  - `Test_RuntimeSnapshot_Switch_Tracks_ControlPlane_And_Dispatch`
    以上 3 个测试删除手工保存/恢复 backend 的 finally cleanup
- 这轮还顺手抓到一个纯本地回归：
  - 首轮 Release 定向 build 报 `Syntax error, "identifier" expected but "BEGIN" found`
  - 根因是删掉局部 cleanup 变量后留下空 `var` 段
  - 删掉陈旧 `var` 后，同一条 Release 验证链立刻恢复全绿
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_RuntimeAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 这批说明当前还有一类值得继续深挖的残点：
  - suite 已经符合公共 fixture 边界
  - 但仍保留历史手工 cleanup finally
  - 这种点虽然不如前面的 `vectorasm` 和 `fixturehelpers` 显眼，但继续收掉能让 test infrastructure 的层次更稳定

## 2026-05-14 Verified Restore Helper Consolidation

- 继续沿着“helper 自身是否还存在重复验证壳”往下挖，发现这次的高价值残点不在基类继承，而在 restore helper 的最后一厘米：
  - `dispatchslots` 有 `RestoreSavedBackendState(...) and (GetActiveBackend = aOriginalBackend)`
  - `backend vector consistency` 有 `RestoreSavedBackendState(...) and (GetCurrentBackend = aOriginalBackend)`
  - `ieee754` 甚至还留着一个纯直通 `RestoreSavedBackendAndVectorAsmState(...)` 的局部 wrapper
  - `concurrent/publicabi/dispatchapi/dataplane` 则在各自的 restore 入口里重复写同样的布尔拼接
- 复核后确认这类点已经不该继续留在各 suite：
  - 它们不再携带 suite-specific 编排
  - 差异只剩“restore 哪类状态”和“用哪个 backend getter 校验”
  - 这正适合下沉回 `fixturehelpers` 作为更低层的共享 helper contract
- 本轮最小修法已落地：
  - `fafafa.core.simd.fixturehelpers` 新增
    - `RestoreSavedBackendStateAndVerify`
    - `RestoreSavedBackendAndVectorAsmStateAndVerify`
  - 通过 `TSimdBackendReader` callback 把 “校验 current 还是 active backend” 交给调用点决定
  - `dispatchslots` 删除 `RestoreDispatchSlotsLocalState`
  - `testcase` 删除 `RestoreBackendVectorConsistencyLocalState`
  - `ieee754` 删除 `RestoreIEEE754LocalState`
  - `backend.consistency` 改用共享 verified helper，再保留自己的异常消息
  - `concurrent/dataplane/dispatchapi/publicabi` 改直接调用共享 verified helper
- 这批的价值比单纯删 wrapper 更大：
  - helper 层现在也区分清楚了“restore”与“restore + verify”两个 contract
  - 以后再看测试 restore 逻辑，不需要在多个 testcase 单元里分辨哪一份布尔拼接才是标准写法
  - 同时也让 `ieee754` 这类之前遗留的小 wrapper 不再继续绕一层本地名字
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_BackendVectorConsistency,TTestCase_DispatchAllSlots,TTestCase_DataPlane,TTestCase_DispatchAPI,TTestCase_PublicAbi,TTestCase_SimdConcurrent,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework,TTestCase_IEEE754_F64,TTestCase_IEEE754EdgeCases,TTestCase_AVX2RoundTruncIEEE754,TTestCase_NonX86IEEE754`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 到这里，`simd` 测试层的冗余治理已经从“fixture 基类去重”推进到了“helper contract 去重”：
  - 下一轮更值得看的，应该是还带 suite-local 后处理动作的 restore helper 是否真的必要
  - 或者生产/测试 seam 上是否还残留类似的 verification thin wrapper

## 2026-05-14 Direct Restore Helper Alignment

- 在 verified restore helper 已经落地后，继续回扫 `direct.testcase`，发现还剩最后两段“restore 本体仍手写、但 suite-specific 语义其实只剩 rebind”的残点：
  - `TDirectDispatchStatefulTestCase.RestoreFixtureDirectDispatchState`
  - `RunDirectDispatchConcurrentReRegisterSnapshotConsistency` 的 finally cleanup
- 复核后确认这两处都不再适合保留自定义 restore 主体：
  - `RestoreFixtureDirectDispatchState` 真正特有的只剩 `RebindDirectDispatch`
  - 并发 cleanup 真正特有的只剩 `RegisterBackend(sbScalar, LOriginalTable)` 后仍要把 direct table 重新 bind 回当前 backend
  - backend/vector-asm restore 与“restore 后 backend getter 必须回到原值”的 contract 已经由 `fixturehelpers` 提供
- 本轮最小修法已落地：
  - `RestoreFixtureDirectDispatchState` 改为：
    - 先 `RebindDirectDispatch`
    - 再断言 `RestoreSavedBackendAndVectorAsmStateAndVerify(FSavedVectorAsm, FSavedBackend, @GetCurrentBackend)`
  - `RunDirectDispatchConcurrentReRegisterSnapshotConsistency` 的 cleanup 改为：
    - 保留 `RegisterBackend(sbScalar, LOriginalTable)`
    - 用 `RestoreSavedBackendStateAndVerify(LOriginalBackend, @GetCurrentBackend)` 替代原来的 `ResetToAutomaticBackend + TrySetActiveBackend` 手写流程
    - 保留末尾 `RebindDirectDispatch`
- 这批的意义不是继续机械删 helper 名字，而是把 `direct` 的边界再压清一层：
  - `direct` 自己负责 direct table 的 suite-local 后处理动作
  - `fixturehelpers` 负责 restore state 与 restore 后的 backend 校验
  - 这样读 `direct.testcase` 时，不再需要在本地 helper 里重新分辨哪部分是 cleanup contract，哪部分只是历史遗留写法
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-14 Backend Fixture Restore Contract Alignment

- 在 `direct` 批次提交后，继续做精确扫描，发现真正更值钱的残点其实已经不在单个 suite，而在公共 backend fixture 本身：
  - `TSimdBackendStatefulTestCase.TearDown` 还保留着最老式的 `ResetBackendSelection + TrySetActiveBackend + getter compare` restore 流程
  - `publicabi.testcase` 里还留着 stable path 上唯一一处裸 `RestoreSavedBackendState(LOriginalBackend)`
- 复核后确认这两处都应该回接 verified helper：
  - `fixturehelpers` 既然已经定义了 backend restore + verify 的统一 contract，共享基类就不该继续维护另一份标准写法
  - `publicabi` 那个 finally cleanup 也应该升级成“恢复并确认 backend 已回原值”，否则它会成为唯一绕开 verify 的残点
- 本轮最小修法已落地：
  - `TSimdBackendStatefulTestCase.TearDown`
    - 删除手写 `ResetBackendSelection / TrySetActiveBackend / and (GetCurrentBackend = FSavedBackend)`
    - 改为 `RestoreSavedBackendStateAndVerify(FSavedBackend, @GetCurrentBackend)`
  - `TTestCase_PublicAbi.Test_PublicApi_ActiveBackendId_Tracks_RuntimeSelection`
    - finally cleanup 改为 `RestoreSavedBackendStateAndVerify(LOriginalBackend, @GetCurrentBackend)`
- 这批的收益比继续删某个 local helper 更高：
  - 共享基类自身不再和 `fixturehelpers` 竞争“backend restore 的标准写法”
  - `publicabi` 也不再保留 stable path 上最后一个未校验 restore caller
  - 之后再看测试层 restore 逻辑时，backend-only 这条 contract 已经基本只有一种写法
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_RuntimeAPI,TTestCase_PublicAbi`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-14 DispatchSlots Redundant Finally Cleanup Removal

- 继续精确下探 backend-restore 冗余时，`dispatchslots.testcase` 暴露出一个更干净的删除点：
  - `TTestCase_DispatchAllSlots` 本身继承的就是 `TSimdBackendStatefulTestCase`
  - 但有 3 个测试在方法尾部 still 手工执行 `RestoreSavedBackendStateAndVerify(FSavedBackend, @GetActiveBackend)`
  - 这些 restore 不参与任何中途断言，只是在测试结束前重复做一遍 teardown 已经承诺的事情
- 复核后确认这 3 处都属于真正冗余，而不是 suite-specific 语义：
  - `Test_AllSelectableBackends_AllDispatchSlots_Assigned`
  - `Test_BackendAdapter_ActiveBackend_RoundTrip_NoNilAndCorePointersStable`
  - `Test_BackendAdapter_RegisteredBackendOps_PreserveCanonicalTextMetadata_After_ReRegister`
  - 第三个测试里真正必须保留的是 `RegisterBackend(LBackend, LOriginalTable)` 对注册表文本元数据的回滚，不是 backend selection 的额外 restore
- 本轮最小修法已落地：
  - 删除上述 3 处末尾的 backend restore finally
  - 保留所有 dispatch slot / roundtrip / canonical metadata 断言
  - `dispatchslots.testcase` 也同步移除了不再使用的 `fafafa.core.simd.fixturehelpers`
- 这批的价值在于，它不是把手工 restore 换一种写法，而是直接删掉了与共享 contract 重叠的一层：
  - backend teardown 的真相源继续只保留在 `TSimdBackendStatefulTestCase`
  - `dispatchslots` 不再额外维护一份“测试结束时也要自己 restore”的局部约定
  - 读这个 suite 时，更容易区分“必要的 register rollback”和“已经由基类兜底的 backend selection restore”
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAllSlots`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-15 Concurrent Tail Restore Cleanup Removal

- 在 `dispatchslots` 之后继续沿“方法尾部 restore 是否只是重复 teardown contract”往下扫，`concurrent.testcase` 给出了更大一块高价值冗余：
  - `TSimdStatefulTestCase.RestoreSimdLocalState(...)` 是一个只包一层消息文案的本地 helper
  - 它的全部调用点都出现在 `finally` 的最后一行
  - 调用之后测试立即结束，没有任何一次是“恢复后还要继续观测同一测试内状态”
- 复核后确认，这类 restore 已经完全被 `TSimdVectorAsmStatefulTestCase.TearDown` 覆盖：
  - 该基类本来就负责恢复 backend + vector-asm
  - `concurrent` 自己真正需要保留的 only 是线程释放、`RegisterBackend(..., LOriginalTable/LRestoreTable)` 这类 rollback
  - 因而 `RestoreSimdLocalState(...)` 本身和所有尾部调用都属于真冗余，而不是“换一种写法的 cleanup”
- 本轮最小修法已落地：
  - 删除 `TSimdStatefulTestCase.RestoreSimdLocalState(...)` 声明与实现
  - 删除 `concurrent.testcase` 对 `fafafa.core.simd.fixturehelpers` 的依赖
  - 删除 16 处方法尾部 `RestoreSimdLocalState(LOldVectorAsm, FSavedBackend)` 调用
  - 保留所有线程 `Free`、backend register rollback、本地失败消息拼接和并发语义断言
- 这批的价值在于，它比 `dispatchslots` 更进一步：
  - 不只是删 3 个重复 finally
  - 而是整块移除了一个只服务于尾部 cleanup 的 suite-local wrapper
  - 同时也让 `concurrent` 文件更清楚地区分了“资源/注册表 rollback”和“已由公共 fixture 兜底的 backend/vectorasm restore”
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_SimdConcurrent,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework,TTestCase_SimdConcurrentRegistration`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-15 PublicAbi Tail Restore Cleanup Removal

- 顺着 `concurrent` 的判断标准继续扫 `publicabi.testcase` 后，证据更直接：
  - `RestorePublicAbiLocalState(...)` 的每一个调用点后面都是直接 `end;`
  - 没有任何一次是在恢复后还要继续做 same-test 观察
  - 这说明它已经彻底退化成“测试尾部再手工跑一遍公共 teardown contract”
- 复核后确认这批可以整体删除，而不是再一处处换 helper：
  - `TTestCase_PublicAbi` 本身继承 `TSimdVectorAsmStatefulTestCase`
  - `TTestCase_PublicAbi.TearDown` 负责 hook state reset，再调用 inherited 恢复 backend/vector-asm
  - 文件里与真正 suite 语义相关的 still 是 register rollback、hook flags rollback、以及个别 backend-only restore，不是 `RestorePublicAbiLocalState(...)` 本身
- 本轮最小修法已落地：
  - 删除 `RestorePublicAbiLocalState(...)` 声明与实现
  - 删除全部 42 处尾部 `RestorePublicAbiLocalState(FSavedVectorAsm/LOldVectorAsm, FSavedBackend)` 调用
  - 保留文件里唯一仍有意义的 `RestoreSavedBackendStateAndVerify(LOriginalBackend, @GetCurrentBackend)` 直调，以及所有 hook/register rollback
- 这批的价值在于，它把 `publicabi` 的 restore contract 也收回成了单一路径：
  - `publicabi` 不再维护自己的“尾部 local restore”壳
  - 读这个文件时，更容易把 `public ABI` 真正关心的 metadata/public-table/control-plane 断言，与共享 fixture cleanup 区分开
  - 也进一步证明了“如果调用后立刻结束测试，这层 local restore 大概率该删”的标准在不同 suite 上都成立
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-15 DispatchApi Tail Restore Cleanup Removal

- 继续沿 `publicabi/concurrent` 的判定标准往下扫后，`dispatchapi.testcase` 的证据也已经足够强：
  - `TDispatchAPIStatefulTestCase.RestoreDispatchApiLocalState(...)` 只是调用 `RestoreSavedBackendAndVectorAsmStateAndVerify(...)` 再包一层断言消息
  - 文件内对 `fixturehelpers` 的唯一直接使用也只有这一个 wrapper
  - 调用点共 117 处：`RestoreDispatchApiLocalState(FSavedVectorAsm, FSavedBackend)` 31 处，`RestoreDispatchApiLocalState(LOldVectorAsm, FSavedBackend)` 86 处
- 这轮额外做了机械扫描来避免误删“恢复后继续观察”的场景：
  - 大多数调用点后面直接 `end;`
  - 少数 spot check 只跟 `FreeAligned(LAligned/LAlignedBlock)`、局部变量清零、或 `if LChecked = 0 then ...` 这类与恢复状态无关的尾部语句
  - 没有发现任何一处是在恢复后继续依赖 `backend/vector-asm` 状态做同测断言
- 本轮最小修法已落地：
  - 删除 `TDispatchAPIStatefulTestCase.RestoreDispatchApiLocalState(...)` 声明与实现
  - 删除 `dispatchapi.testcase` 对 `fafafa.core.simd.fixturehelpers` 的依赖
  - 删除全部 117 处尾部 `RestoreDispatchApiLocalState(FSavedVectorAsm/LOldVectorAsm, FSavedBackend)` 调用
  - 保留所有 hook reset、register rollback、non-x86 parity、capability、dispatch/public ABI smoke 相关断言与资源释放
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口前已清理 `tests/fafafa.core.simd/__pycache__/`，避免把 Python 缓存目录带进提交。

## 2026-05-15 DataPlane And IEEE754 Tail Verified-Restore Cleanup

- 在 `dispatchapi` 提交后继续全局扫描，发现 stable `vector-asm` 派生 suite 里还剩两类 direct verified helper caller：
  - `dataplane.testcase` 1 处
  - `ieee754.testcase` 10 处
- 这批没有 local wrapper，但控制流形状和前面的冗余批次一致：
  - 都在 `TSimdVectorAsmStatefulTestCase` 派生类中
  - 都位于 `finally` 尾部
  - 调用后统一直接 `end;`
  - 没有任何一处是在恢复后继续依赖 backend/vector-asm 状态做同一测试内的后续断言
- 额外扫描后还确认了一个可直接收口的信号：
  - `dataplane` 与 `ieee754` 两个文件对 `fafafa.core.simd.fixturehelpers` 的唯一依赖，就是这些尾部 `RestoreSavedBackendAndVectorAsmStateAndVerify(...)` 调用
  - 这意味着删掉 direct caller 后，连 `uses` 也可以一起清理，不会留下半退役依赖
- 本轮最小修法已落地：
  - 删除 `dataplane.testcase` 中 1 处尾部 verified-restore 调用
  - 删除 `ieee754.testcase` 中 10 处尾部 verified-restore 调用
  - 同步删除两文件对 `fafafa.core.simd.fixturehelpers` 的依赖
  - 保留 dataplane snapshot round-trip 断言、IEEE754 的 SSE2/AVX2/non-x86 特殊值与 property-like 断言
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DataPlane,TTestCase_IEEE754EdgeCases,TTestCase_AVX2RoundTruncIEEE754,TTestCase_NonX86IEEE754`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 本轮收口前已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免把 Python 缓存目录带进提交。

## 2026-05-15 Direct Tail Restore Split Cleanup

- 在 `dataplane + ieee754` 之后继续回扫时，`direct.testcase` 暴露出一个更细的混合场景：
  - `RestoreFixtureDirectDispatchState(...)` helper 本身仍有本地语义，因为它把 `RebindDirectDispatch` 和 verified restore 绑在了一起
  - 但它的调用点并不都还需要这层语义
- 机械扫描后确认：
  - 共 28 处调用里，只有 2 处 finally 之后还继续读取 `GetDispatchTable / GetDirectDispatchTable`
  - 这 2 处正是 `Test_DirectDispatchTable_Rebind_AfterForceBackend` 和 `Test_DirectDispatchTable_AutoRebind_AfterDispatchSetActiveBackend`
  - 其余 26 处要么调用后直接 `end;`，要么只剩 `FreeAligned(...)` 这种资源释放
- 因而这批不是“删 helper”，而是“按 caller 语义拆分”：
  - 保留 2 处真正需要 post-restore direct-table 观测的调用
  - 删除其余 26 处尾部 `RestoreFixtureDirectDispatchState(...)`
  - `TDirectDispatchStatefulTestCase.TearDown` 继续负责 inherited restore 后的 `RebindDirectDispatch`
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-15 Backend Consistency Setup Helper Consolidation

- 继续往下扫时，确认“尾部 restore 冗余”这条线已经基本榨干，下一块更值得收的是 `backend.consistency.testcase` free helper 的 setup/skip boilerplate。
- 这批重复体集中在以下 helper：
  - `TestF32x4Arithmetic`
  - `TestF32x4Math`
  - `TestF32x4Comparison`
  - `TestF32x4Reduction`
  - `TestI32x4Arithmetic`
  - `TestI32x4Bitwise`
  - `TestFacadeMemOps`
- 这些 helper 之前都重复一整段相同前置流程：
  - 填充 `TConsistencyTestResult` 默认值
  - `SaveActiveBackendState(LOriginalState)`
  - `IsBackendRegistered(backend)` 的 skip 处理
  - `TrySetActiveBackend(backend)` 的 skip 处理
- 本轮最小修法已落地：
  - 新增 `InitBackendConsistencyResult(...)`
  - 新增 `BeginBackendConsistencyTest(...)`
  - 让上面 7 个 helper 都改用共享入口
  - `BeginBackendConsistencyTest(...)` 继续保留 `TrySetActiveBackend(...)`，避免 backend fallback 被误算成可用
  - skip 早退路径现在会先 `RestoreBackendConsistencyState(aOriginalState)`，不再把已保存 backend 状态泄漏给后续 case
- 这批的价值和前面几轮不同：
  - 不是删尾部 cleanup
  - 而是把 free helper 层的 canonical setup/skip contract 收回一处
  - 让 `backend.consistency` 更容易区分“共享前置逻辑”和“每个向量族自己的断言主体”
- 本轮 Release 验证链：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_BackendVectorConsistency`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-15 Backend Consistency Name And Matrix Truth Consolidation

- `backend.consistency` 的 setup/skip 合同收平后，我继续扫 meta/helper 层，发现剩下一块已经产生真实可见问题的分叉：
  - `RunAllConsistencyTests(...)` 会跑 `SSE3/SSSE3/SSE4.1/SSE4.2`
  - 但 `PrintTestSummary(...)` 没给这些 backend 名称映射
  - 结果 consistency 摘要在这些 tier 上会输出 `Unknown`
- 进一步复核后确认，这不是单个 `case` 漏项，而是同一主题分裂成多份 test-only truth source：
  - `backend.consistency.testcase` 自己维护了一份 backend 执行列表
  - `PrintTestSummary(...)` 单独维护了一份 backend name 映射
  - `TTestCase_BackendVectorConsistency.Test_VectorOps_Consistency` 又内嵌了另一份 `BackendName(...)`
  - helper meta-test 还复制了一份 backend candidate 列表
- 本轮最小修法已落地：
  - 在 `backend.consistency.testcase` interface 新增 `CONSISTENCY_BACKENDS`
  - 新增 `GetConsistencyBackendName(...)`
  - `RunAllConsistencyTests(...)` 改为共享 backend 常量 + `TConsistencyTestFunc` array 驱动，不再手写 9 个 backend × 7 个 helper 调用骨架
  - `PrintTestSummary(...)` 改用 `GetConsistencyBackendName(...)`
  - `TTestCase_BackendVectorConsistency.Test_VectorOps_Consistency` 删除本地 `BackendName(...)`，统一复用共享 helper
  - 新增 `Test_VectorOps_BackendName_Coverage`，锁住 `SSE4.1/SSE4.2/AVX-512/RISC-V V` 等容易漂移的名称不会再次回落成 `Unknown`
- 这批的价值不只是去重：
  - 它修掉了真实摘要 bug
  - 同时把 backend consistency 的“执行矩阵 + 失败输出名称”收回同一真相源
  - 让后续继续扩测试时，不需要再手改多处 backend/name 列表才能保持一致
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_BackendVectorConsistency`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-15 Backend Consistency Meta-Test Candidate Reuse

- `backend consistency` 的名称/矩阵真相源统一后，我继续顺链往下扫，发现还有一个很轻但不该继续保留的副本：
  - `Test_VectorOps_Helper_Preserves_PreviousForcedBackend` 还在本地维护 `CBackendCandidates`
  - helper sanity failure 也还只输出 `Ord(LTargetBackend)`，没有复用共享 backend 名称 helper
- 本轮最小修法已落地：
  - 删除本地 `CBackendCandidates`
  - 改为直接遍历 `CONSISTENCY_BACKENDS`
  - helper sanity failure 信息改为 `GetConsistencyBackendName(LTargetBackend)`，不再只给 backend 编号
- 这批虽然很小，但价值是把刚刚统一好的 test-only truth source 真正收到底：
  - 不只是执行矩阵和摘要复用
  - 连 meta-test 的候选 backend 选择和失败信息也回到同一来源
  - 这样后续再扩 backend 或调整命名时，不会在 meta-test 上重新冒出一份旧副本
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_BackendVectorConsistency`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-15 Backend Consistency Dispatch-Truth Name And Report Helper Reuse

- 我继续顺着 `backend consistency` 的 control/report 面往下扫，确认还剩一份更底层的本地真相源：
  - `GetConsistencyBackendName(...)` 自己仍然维护一份 backend name `case` 表
  - 但 `dispatch.GetBackendInfo(...)` 已经对 registered/unregistered backend 统一返回 canonical metadata
- 同时也看到一个容易继续漂移的小壳：
  - `PrintTestSummary(...)` 和 `TTestCase_BackendVectorConsistency.Test_VectorOps_Consistency`
  - 都各自用 `Pos('skipped', LowerCase(...))` 解释 result
  - 都各自拼 failure line / max diff 文案
- 本轮最小修法已落地：
  - `GetConsistencyBackendName(...)` 改为薄封装 `GetBackendInfo(aBackend).Name`
  - 新增 `IsConsistencyTestSkipped(...)`
  - 新增 `FormatConsistencyFailureText(...)`
  - `PrintTestSummary(...)` 改复用这两个 helper
  - `TTestCase_BackendVectorConsistency.Test_VectorOps_Consistency` 也改复用同一套 result-interpretation helper
- 这批的价值在于把 `backend consistency` 的“名称真相源 + 结果解释壳”都继续收平：
  - backend label 不再在 tests 里另存一份
  - summary 和 root wrapper 不再各自判断 skip / 各自拼 fail 文案
  - 后续如果 result record 语义调整，日志和单测失败面会一起跟着改，而不是再出现两套解释
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_BackendVectorConsistency`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过

## 2026-05-15 Smoke Tool Canonical Name Reuse And Standalone Build Fix

- 我继续把审查面从大 testcase 扫到独立 smoke 工具后，确认有两处小但真实的问题：
  - `fafafa.core.simd.dispatch_preinit_smoke.pas`
  - `fafafa.core.simd.public_smoke.pas`
  - 两文件都留着本地 `BackendName(...)` 薄壳；`public_smoke` 另外缺 `{$mode objfpc}{$H+}`，raw `fpc` 编译会直接挂在 `Result` 关键字上
- 本轮最小修法已落地：
  - `dispatch_preinit_smoke` 删除本地 `BackendName(...)`，失败文案直接使用 `GetBackendInfo(...).Name`
  - `public_smoke` 补 `{$mode objfpc}{$H+}` 与 `fafafa.core.simd.dispatch`
  - `public_smoke` 删除本地 `BackendName(...)`，统一直读 `GetBackendInfo(...).Name`
  - 顺手把 `public_smoke` 的参数/局部变量命名收回仓库规范：`aMessage`、`LCpuInfo`、`LBackend`、`LExpectedBackend`
- 这轮验证中途先撞到一个非代码回归的 hygiene 陷阱：
  - 早先 raw `fpc` 独立编译 `public_smoke` 时把 `.o/.ppu` 落进了 `src/`
  - 导致首轮 `Release gate` 在最后 `run_all` 链的 `src tree hygiene` 检查红掉
  - 清理 `src/*.o`、`src/*.ppu`、`tests/fafafa.core.simd/__pycache__/` 与临时 `public_smoke` 二进制后，问题消失
- 这轮重新按不污染源码树的方式完成了独立 smoke 证据：
  - `git diff --check`
  - `fpc -B -Fu./tests/fafafa.core.simd -Fu./src -FE"$tmpdir" -FU"$tmpdir" ./tests/fafafa.core.simd/fafafa.core.simd.public_smoke.pas`
  - 运行结果：
    - `CPU vendor: GenuineIntel`
    - `CPU model: Intel(R) Xeon(R) CPU E5-2680 v4 @ 2.40GHz`
    - `Backend: 6 (AVX2)`
    - `[PASS] Default backend is AVX2`
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过；最终 `gate` 明确恢复到：
    - `src tree hygiene: no .o/.ppu/.bak artifacts`
    - `Run-all summary: Passed 5 / Failed 0`
    - `[GATE] OK`

## 2026-05-15 Bench Canonical Backend Label Reuse

- 在 smoke 工具收口并提交后，我继续沿“小型 runner/utility 的本地 metadata 真相源”往下扫，定位到 `fafafa.core.simd.bench`：
  - `GetBenchmarkBackendName(...)` 仍维护一份 backend 名称表
  - `GetBackendName` 只是再包一层 `GetActiveBackend`
- 复核调用面后确认，这两层 helper 只服务两类展示/诊断文本：
  - `TryActivateBenchmarkBackend(...)` 的 unavailable / non-dispatchable / fallback 文案
  - `PrintBenchResults(...)` 的 benchmark 标题 backend 标签
- 本轮最小修法已落地：
  - 删除 `GetBenchmarkBackendName(...)`
  - 删除 `GetBackendName`
  - `TryActivateBenchmarkBackend(...)` 全部改为直接使用 `GetBackendInfo(...).Name`
  - `PrintBenchResults(...)` 标题改为直接显示 `GetBackendInfo(GetActiveBackend).Name`
- 这批没有碰 benchmark 本体：
  - `WARMUP_ITERATIONS / MIN_ITERATIONS / TARGET_TIME_MS`
  - `PUBLIC_ABI_HOT_INNER / WIDE_VECTOR_INNER`
  - 结果 record、格式化输出和测量顺序都保持不变
- 本轮 Release 验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过；最终 `gate` 继续保持：
    - `Run-all summary: Passed 5 / Failed 0`
    - `[GATE] OK`

## 2026-05-15 Standalone Program Entry Contract Repair

- 在 `bench` 收口后，我继续扫 repo 里残留的独立 program/lpi，确认这一层也有真实入口问题：
  - `test_backend_ops.pas` 与 `test_simd_boundary.pas` 都缺 `{$I ../../src/fafafa.core.settings.inc}`
  - `test_backend_ops.lpi` 竟然把主单元写成了 `fafafa.core.simd.test.lpr`
- 这不是静态猜测，我先直接做了真构建验证：
  - `lazbuild -B tests/fafafa.core.simd/test_backend_ops.lpi`
  - 修复前它实际去编的是整套 `fafafa.core.simd.test.lpr`
  - 最终报出的也是主 testcase 里的无关错误，而不是 `test_backend_ops` 自身入口错误
- 本轮入口合同修复已落地：
  - `test_backend_ops.pas` 补 `{$I ../../src/fafafa.core.settings.inc}`
  - `test_simd_boundary.pas` 补 `{$I ../../src/fafafa.core.settings.inc}`
  - `test_backend_ops.lpi` 主单元改回 `test_backend_ops.pas`
  - `test_simd_boundary.pas` 把不存在于当前 `uses` 面的 `NegInfinity` 改成 `-posInf`
  - `test_simd_boundary.pas` 的 banner/summary 文案显式收成 `UTF8String(...)`
- 这轮独立入口验证是分层做的：
  - `git diff --check`
  - 临时目录 `fpc` 编译并运行 `test_backend_ops.pas`
  - 结果：`Passed: 15`、`Failed: 0`、`All tests PASSED!`
  - 临时目录 `fpc` 编译并运行 `test_simd_boundary.pas`
  - 结果：44 条边界断言全部通过
  - 输出落盘后用 `python3` 直接按 UTF-8 解码验证，确认 `SIMD 边界测试 - Rust 级别代码质量验证`、`测试汇总`、`失败: 0` 等文案不再被降成 `?`
  - `lazbuild -B tests/fafafa.core.simd/test_backend_ops.lpi`
  - 结果：主编译参数中的 project source 已正确变成 `test_backend_ops.pas`，并成功生成 `bin/test_backend_ops`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - 结果：通过，说明这批独立入口修补没有反向污染主 SIMD 检查链

## 2026-05-15 DispatchAPI Canonical Backend Name Reuse Batch 1

- 继续沿“test-only 本地名字表”这条线深查时，我回到 `fafafa.core.simd.dispatchapi.testcase.pas`，先接住上一批已经落下的文件级 helper：
  - `DispatchApiBackendName(const aBackend: TSimdBackend): string`
  - 实现是 `GetBackendInfo(aBackend).Name`
- 这次没有盲目全文件替换，而是先确认当前一簇 4 个 procedure 的局部 `BackendName(...)` 只拼断言消息，不参与 capability 逻辑：
  - `Test_BackendCapabilities_DoNotUnderclaim_Shuffle`
  - `Test_X86_BackendCapabilities_DoNotUnderclaim_MaskedOps`
  - `Test_BackendCapabilities_Clear_IntegerOps_When_VectorAsmDisabled`
  - `Test_X86_BackendCapabilities_Keep_MaskedOps_When_VectorAsmDisabled`
- 确认边界后，本轮最小修法已落地：
  - 删除这 4 个 procedure 内部各自的 `BackendName(...)`
  - `ObserveRepresentativeSlot(...)` 与后续 `AssertTrue/AssertFalse` 文案统一改用 `DispatchApiBackendName(LBackend)`
  - `IsX86MaskedOpsBackend(...)`、`IsVectorAsmGatedX86Backend(...)` 等真正承载 backend membership 的 helper 保持不动
- 本轮 release 验证链已完整跑通：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- `check`/`gate` 期间还再次验证了这批改动没有破坏当前 SIMD 快门禁主链：
  - `ADAPTER_SYNC_SUMMARY ... issues=0`
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=475 status=ok`
  - `DISPATCH_READ_SCOPE ... forbidden_hits=0`
  - `Run-all summary: Passed 5 / Failed 0`
  - `[GATE] OK`
- 当前这一批收口后，`dispatchapi.testcase` 里剩余局部 `BackendName(...)` 已缩到下一簇：
  - 约 `10613/10788/10821/10925/10962`
  - 文件级 `NonX86BackendName(...)` 暂不混入本批，留给后续 non-x86 小批次处理

## 2026-05-15 DispatchAPI Canonical Backend Name Reuse Batch 2

- 我继续接着上一批的“下一簇”往下做，这次没有扩大到别的文件，还是只处理 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`。
- 先逐段复核后确认，这 5 个过程里的局部 `BackendName(...)` 也都只是断言消息源：
  - `Test_X86_BackendCapabilities_Clear_Shuffle_When_VectorAsmDisabled`
  - `Test_NonX86_DispatchTable_WiringChecklist_Grouped`
  - `Test_X86_DispatchTable_WiringChecklist_Grouped`
  - `Test_NonX86_DispatchTable_WiringChecklist`
  - `Test_NonX86_NativeWideFloorCeil_Slots_NotScalar_IfAvailable`
- 真正的测试语义边界仍保持原状：
  - `IsShuffleCapabilityGatedBackend(...)` 继续负责 x86 gated backend 判定
  - `LBackends[...]` 继续定义 x86 / non-x86 checklist 覆盖集合
  - `{$IFNDEF FAFAFA_SIMD_TEST_NEON_ASM_COMPILED}` / `{$IFNDEF FAFAFA_SIMD_TEST_RISCVV_ASM_COMPILED}` 继续决定 native wide slot 测试是否参与
- 本轮最小修法已落地：
  - 删除这 5 个过程各自的局部 `BackendName(...)`
  - 所有断言消息统一改走 `DispatchApiBackendName(LBackend)`
  - 文件级 `NonX86BackendName(...)` 先不动，留给后续 non-x86 parity 批次单独审查
- 改完后做了精确复核：
  - `rg -n "function BackendName\\(|function NonX86BackendName\\(|DispatchApiBackendName\\(" tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - 结果显示：当前这个文件已不再有局部 `function BackendName(...)`，只剩文件级 `DispatchApiBackendName(...)` 与 `NonX86BackendName(...)`
- 本轮 release 验证链已完整通过：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 这轮还额外看到与本批非常相关的门禁继续保持稳定：
  - `DISPATCH_READ_SCOPE ... forbidden_hits=0`
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=475 status=ok`
  - `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=20 issues=0 status=ok`
  - `WIRING_SYNC_SUMMARY legacy=60 grouped=60 helper=60 missing=0 extra=0 ...`
  - `Run-all summary: Passed 5 / Failed 0`
  - `[GATE] OK`
- 当前这一批收口后，`dispatchapi.testcase` 的 procedure-local backend 名称表已经清零。
- 下一个合理切入点已经变成：
  - 文件级 `NonX86BackendName(...)`
  - 以及它所服务的 `TTestCase_NonX86BackendParity` 那一组 non-x86 消息壳是否还能进一步下沉到 canonical metadata

## 2026-05-15 NonX86BackendName Thin Wrapper Dedup

- 在上一批把 `dispatchapi.testcase` 的 procedure-local `BackendName(...)` 清空之后，我继续顺着同一条线往下查到文件级 `NonX86BackendName(...)`。
- 这次没有选择把调用点全量改成 `DispatchApiBackendName(...)`，因为实际调用面已经扩到了整组 `TTestCase_NonX86BackendParity`：
  - `slot-not-scalar`
  - `dispatch-table parity`
  - `facade parity`
  - `lane-tag / shift parity`
  - 调用量大，但 helper 本体仍然纯
- 复核后确认它没有额外 label policy 语义，只是消息文案 helper：
  - backend 覆盖集合仍由各测试自己的 `LBackends[...]` 决定
  - `NEON/RISCVV asm compiled` 参与条件仍由编译宏控制
  - active backend 切换和 dispatch-table/facade 调用仍是测试语义真源
- 因此本轮采用了更稳的最小修法：
  - 保留 `NonX86BackendName(...)` 这个对 non-x86 测试更可读的 helper 名
  - 但把其实现从本地 `case sbNEON/sbRISCVV` 名称表改成 `Result := DispatchApiBackendName(aBackend);`
- 本轮针对性验证也扩到了真正受影响的两组 suite：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_NonX86BackendParity`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 这轮继续验证到的相关门禁仍保持稳定：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=475 status=ok`
  - `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=20 issues=0 status=ok`
  - `WIRING_SYNC_SUMMARY legacy=60 grouped=60 helper=60 missing=0 extra=0 ...`
  - `Run-all summary: Passed 5 / Failed 0`
  - `[GATE] OK`
- 当前这条 `dispatchapi/nonx86 parity` 名称真相源线已经收平：
  - `DispatchApiBackendName(...)` 作为 canonical 薄封装
  - `NonX86BackendName(...)` 只作为语义别名，不再维护自己的 backend 名称表

## 2026-05-15 PublicAbi Canonical Backend Label Reuse

- 我继续把 SIMD 测试层的“消息真相源冗余”往下扫到 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas`。
- 这轮没有扩大到 `public ABI` 逻辑本体，而是先确认当前 diff 只涉及失败消息：
  - `Test_PublicApi_BackendPodInfo_Flags_AreSelfConsistent`
  - `Test_PublicApi_BackendPodInfo_CapabilityBits_DoNotUnderclaim_Shuffle`
  - `Test_PublicApi_BackendPodInfo_CapabilityBits_DoNotUnderclaim_X86MaskedOps`
  - `Test_PublicApi_BackendPodInfo_CapabilityBits_Clear_X86Shuffle_WhenVectorAsmDisabled`
  - `Test_PublicApi_BackendPodInfo_CapabilityBits_Keep_X86IntegerOps_When_AlwaysOn_NarrowSlots_Remain_NonScalar`
  - `Test_PublicApi_BackendPodInfo_CapabilityBits_Keep_X86MaskedOps_WhenVectorAsmDisabled`
- 实际修法保持最小：
  - 在 implementation 区新增 `PublicAbiBackendName(const aBackend: TSimdBackend): string`
  - 实现直接复用 `GetBackendInfo(aBackend).Name`
  - 把上述断言里原来的 `IntToStr(Ord(LBackend))` 全部替换为 `PublicAbiBackendName(LBackend)`
- 这轮还碰到一个工具级小阻塞，但没有让它拖慢主线：
  - `mcp__ace_tool__.search_context` 返回 `ACE_TOKEN` 失效
  - 我没有在同一路径上反复重试，而是直接退回 `git diff` + `rg/sed` 做局部复核
- 当前这批 release 验证已串行跑完：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- `gate` 里和本批最相关的链路也都继续为绿：
  - `PUBLIC_ABI_SIGNATURE ... [PUBLIC-ABI] OK`
  - `BuildOrTest.sh ../fafafa.core.simd.publicabi/BuildOrTest.sh test` smoke 通过
  - `TTestCase_PublicAbi,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework` 通过
  - `Run-all summary: Passed 5 / Failed 0`
  - `[GATE] OK`
- 当前这一批收口后，`publicabi.testcase` 的 backend 失败消息已经不再回落到 ordinal 编号；下一步可以继续找别的测试面里是否还存在类似“仅服务 report shell 的本地 truth source”。

## 2026-05-15 IEEE754 Canonical Backend Label Reuse

- `publicabi` 批次提交后，我继续做下一轮 SIMD 测试层深查，先按 “只收 report shell，不碰语义” 的标准筛了一圈。
- 快速计数后，两个明显候选是：
  - `dispatchslots.testcase`：562 处 backend ordinal 文案
  - `ieee754.testcase`：76 处 backend ordinal 文案
- 我先选了 diff 更小、语义更纯的 `ieee754.testcase`，并逐段复核确认：
  - `IntToStr(Ord(LBackend))` 只出现在 `AssertSingleSemantics` / `AssertDoubleSemantics` / invariant 断言的首个上下文字符串参数
  - 不参与任何 `Round/Trunc/Floor/Ceil` 计算
  - 不参与 `expected/actual` 生成
  - 不参与 backend 集合或 lane/case 选择
- 这轮实际修法保持极小：
  - 新增文件级 `IEEE754BackendName(const aBackend: TSimdBackend): string`
  - 实现直接复用 `GetBackendInfo(aBackend).Name`
  - 把 `TTestCase_IEEE754EdgeCases` 与 `TTestCase_AVX2RoundTruncIEEE754` 涉及的 5 组集中块中 76 处 backend ordinal 文案统一替换成该 helper
- 先做的精确自检结果：
  - `rg -n "IntToStr\\(Ord\\(LBackend\\)\\)|IntToStr\\(Ord\\(aBackend\\)\\)" tests/fafafa.core.simd/fafafa.core.simd.ieee754.testcase.pas`
  - 结果：无匹配，说明 `ieee754.testcase` 中这批 backend ordinal 文案已清零
- 本轮 release 验证链已完整通过：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IEEE754EdgeCases,TTestCase_AVX2RoundTruncIEEE754`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- `gate` 里的相关主链也继续保持稳定：
  - `TTestCase_PublicAbi,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework` 通过
  - `ADAPTER_SYNC_SUMMARY ... issues=0`
  - `Run-all summary: Passed 5 / Failed 0`
  - `[GATE] OK`
- 这轮结束后，下一块最明显的同类目标已经更清楚了：
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchslots.testcase.pas`
  - 该文件仍保留大面积 `Backend=` + ordinal 的 slot-assigned / canonical-metadata 断言文案

## 2026-05-15 DispatchSlots Canonical Backend Label Reuse

- `ieee754` 批次提交后，我继续按“同类高密度 report shell 优先”往下审查，直接接住了上一条已经标出的 `dispatchslots.testcase`。
- 先做的不是改代码，而是把这 562 处 backend ordinal 文案分布拆清楚：
  - 557 处集中在 `AssertAllDispatchSlotsAssigned(const aBackend, const aDispatch)` 的 slot checklist
  - 5 处在 `Test_BackendAdapter_UnregisteredBackendOps_PreserveCanonicalMetadata`
- 复核后确认这批仍然只是消息层：
  - slot 是否绑定仍由每条 `Assigned(aDispatch^....)` 决定
  - metadata 期望值仍由 `GetBackendInfo(LBackend)` 生成
  - backend ordinal 只参与断言消息前缀
- 这轮实际修法保持最小而且偏“可审查友好”：
  - 新增文件级 `DispatchSlotsBackendName(const aBackend: TSimdBackend): string`
  - 实现直接复用 `GetBackendInfo(aBackend).Name`
  - `AssertAllDispatchSlotsAssigned(...)` 新增 `LBackendSlotPrefix := 'Backend=' + DispatchSlotsBackendName(aBackend) + ' slot '`
  - 557 条 slot 断言统一改用这个共享前缀
  - `Test_BackendAdapter_UnregisteredBackendOps_PreserveCanonicalMetadata` 再补一个 `LBackendName`，把剩余 5 条消息也统一到同一真相源
- 做完后的精确自检结果：
  - `rg -n "IntToStr\\(Ord\\((L|a)Backend\\)\\)" tests/fafafa.core.simd/fafafa.core.simd.dispatchslots.testcase.pas`
  - 结果：无匹配，说明这份文件里的 backend ordinal 文案已清零
- 本轮 release 验证链已完整通过：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAllSlots`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- `gate` 里和这批最相关的主链也继续为绿：
  - `ADAPTER_SYNC_SUMMARY ... missing_dispatch_slot_defs=0 missing_fill_base_assignments=0`
  - `DISPATCH_CONTRACT_SIGNATURE ... [DISPATCH-CONTRACT] OK`
  - `Run-all summary: Passed 5 / Failed 0`
  - `[GATE] OK`
- 到这里，这一条“backend ordinal 只服务断言消息”的高密度测试层收口线已经又往前推进了一大步：
  - `publicabi.testcase`
  - `ieee754.testcase`
  - `dispatchslots.testcase`
  这三份文件的 backend 诊断文案都已经收回 canonical metadata

## 2026-05-15 DirectDispatch Canonical Backend Label Reuse

- `dispatchslots` 批次提交后，我继续做一次余量盘点，按文件聚合 backend ordinal 文案：
  - `direct.testcase`：493
  - `dispatchapi.testcase`：13
  - `fafafa.core.simd.testcase`：1
- 因为 `direct.testcase` 的余量远高于其他文件，所以我优先继续把这一大块收口。
- 先做的局部复核确认了这批仍然只是消息层：
  - `Direct dispatch table should be assigned for backend ...`
  - `Direct ... parity backend ...`
  - `aLabel + ' lane ... backend ...'`
  - `backend=... case=...`
  这些都只是断言上下文文本，不参与 direct/facade 结果或 backend 切换逻辑
- 这轮实际修法保持简单：
  - 新增文件级 `DirectBackendName(const aBackend: TSimdBackend): string`
  - 实现直接复用 `GetBackendInfo(aBackend).Name`
  - 通过机械替换把整份文件里所有 `+ IntToStr(Ord(LBackend))` / `+ IntToStr(Ord(aBackend))` 统一收成 `+ DirectBackendName(...)`
- 自检结果很直接：
  - `rg -n "IntToStr\\(Ord\\((L|a)Backend\\)\\)" tests/fafafa.core.simd/fafafa.core.simd.direct.testcase.pas`
  - 结果：无匹配，说明 `direct.testcase` 里的 backend ordinal 文案已经清零
- 本轮 release 验证链已完整通过：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch,TTestCase_DirectDispatchConcurrent`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- `gate` 里与本批最相关的 direct 主链也继续为绿：
  - `TTestCase_DirectDispatch` 通过
  - `TTestCase_DirectDispatchConcurrent` 通过
  - `DISPATCH_CONTRACT_SIGNATURE ... [DISPATCH-CONTRACT] OK`
  - `Run-all summary: Passed 5 / Failed 0`
  - `[GATE] OK`
- 到这一步，高密度测试层 backend ordinal 收口已经覆盖 4 份主文件：
  - `publicabi.testcase`
  - `ieee754.testcase`
  - `dispatchslots.testcase`
  - `direct.testcase`
- 当前这条线剩余的尾巴已经缩得很小了，只剩：
  - `dispatchapi.testcase` 约 13 处
  - `fafafa.core.simd.testcase` 1 处

## 2026-05-15 Backend Ordinal Tail Cleanup

- `direct` 批次提交后，我立刻做了一次目录级余量盘点，结果只剩最后 14 处 backend ordinal 文案：
  - `dispatchapi.testcase`：13
  - `simd.testcase`：1
- 这次没有再引入新 helper，而是直接复用文件里已经存在的 canonical helper：
  - `dispatchapi.testcase` 统一改用 `DispatchApiBackendName(LBackend)`
  - `simd.testcase` 那 1 处直接改用 `GetConsistencyBackendName(LBackend)`
- 这轮最重要的自检不是单文件，而是整目录：
  - `rg -n "IntToStr\\(Ord\\((L|a)Backend\\)\\)" tests/fafafa.core.simd --glob '*.pas'`
  - 结果：空
  - 这说明当前 `tests/fafafa.core.simd` 下 Pascal 测试文件里的 backend ordinal 消息壳已经全部清零
- 本轮定向 release 验证链已完整通过：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI,TTestCase_NonX86BackendParity,TTestCase_BackendVectorConsistency`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- `gate` 里和这批最相关的链路也继续保持稳定：
  - `TTestCase_DispatchAPI` 通过
  - `TTestCase_DirectDispatch` / `TTestCase_DirectDispatchConcurrent` 继续通过
  - `DISPATCH_CONTRACT_SIGNATURE ... [DISPATCH-CONTRACT] OK`
  - `WIRING_SYNC_SUMMARY ... missing=0 extra=0`
  - `Run-all summary: Passed 5 / Failed 0`
  - `[GATE] OK`
- 到这里，这条“backend ordinal 仅作断言消息壳”的测试层清理线已经在 `tests/fafafa.core.simd` 范围内完全收平：
  - `publicabi.testcase`
  - `ieee754.testcase`
  - `dispatchslots.testcase`
  - `direct.testcase`
  - `dispatchapi.testcase` tail
  - `simd.testcase` tail

## 2026-05-15 Concurrent Canonical Backend Label Reuse

- 在目录级 backend ordinal grep 已经清零后，我继续往 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 深审，确认这里还残留一类不会被前一条 grep 捕获的诊断壳冗余：
  - `Format(... backend=%d ...)`
  - backend array 直接输出 ordinal
  - mixed snapshot 错误输出 `got=%d expectedA=%d expectedB=%d`
  - synthetic first-registration metadata 仍拼 ordinal
- 这次没有碰并发 worker 行为、状态机或 round-level cleanup，只做 report shell 收口：
  - 新增 `ConcurrentBackendName(const aBackend: TSimdBackend): string`
  - `DescribeBackendInfoLocal` 改为输出 backend name
  - `DescribeBackendArrayLocal` 改为输出 backend name 数组
  - `DescribeRuntimeSnapshotLocal` 改为输出 backend/best 的 canonical name
  - mixed snapshot 错误文本改为 `got=<name> expectedA=<name> expectedB=<name>`
  - `ConcurrentFirstRegister_*` synthetic metadata 改为 backend name
- 同时明确保留了真正承载行为语义的 `Ord(...)`：
  - backend expected/actual 数值断言没动
  - RNG seed 里的 `QWord(Ord(LBackend))` 没动
- 接手这批前，Release `TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework,TTestCase_DirectDispatchConcurrent` 和 Release `check` 已经是绿的；本轮把剩下的 closeout 补完整：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过
- 这次 `gate` 里最相关的链路继续为绿：
  - `TTestCase_PublicAbi,TTestCase_SimdConcurrentPublicAbi,TTestCase_SimdConcurrentFramework`
  - `TTestCase_DirectDispatchConcurrent`
  - `Run-all summary: Passed 5 / Failed 0`
  - `[GATE] OK`

## 2026-05-15 Public Smoke Canonical Backend Output

- 在 `concurrent` 提交后，我继续往独立 program 入口审，找到一个新的、很容易被主 runner 掩盖的 user-facing 冗余：
  - `tests/fafafa.core.simd/fafafa.core.simd.public_smoke.pas`
  - 独立运行前的真实输出是 `Backend:    6 (AVX2)`
- 我没有先改文件，而是先做了 standalone 真运行验证：
  - 临时目录 `fpc` 编译 `fafafa.core.simd.public_smoke.pas`
  - 直接运行生成的 `fafafa.core.simd.public_smoke`
  - 输出证明确实还在同时暴露 ordinal 和 canonical name
- 本轮收口范围很窄，只动 user-facing backend label：
  - 新增 `PublicSmokeBackendName(const aBackend: TSimdBackend): string`
  - `Backend:` 标题行改成只输出 canonical backend name
  - default-backend 失败文案与 PASS 文案统一复用同一 helper
- 修完后再次独立编译运行，输出已收成：
  - `CPU vendor: GenuineIntel`
  - `CPU model:  Intel(R) Xeon(R) CPU E5-2680 v4 @ 2.40GHz`
  - `Backend:    AVX2`
  - `[PASS] Default backend is AVX2`
- 为了确认这批 standalone 收口没有反向扰动主链，我又补了一遍：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - 结果：全部通过；`dispatch preinit smoke`、source reachability、suite manifest、non-x86 opt-in list-suites 也继续为绿

## 2026-05-15 Public Smoke Check Coverage Wiring

- 在 `public_smoke` 输出收口并提交后，我继续追了一层更真实的问题：它还是没被 `BuildOrTest check` 自动覆盖。
- 先做的是接线真相核对，而不是直接改：
  - `BuildOrTest.sh` / `buildOrTest.bat` 都没有 `public_smoke` runner
  - shell 的 `check` 实际执行落点在底部 `case "${ACTION}" in ... check)` 分支
  - 我第一次把 `run_public_smoke` 调用只补到前面的辅助块里，`Release check` 仍然会绿，但日志里完全没有 `[PUBLIC-SMOKE]`
- 定位清楚后，这次修的是最小必要接线：
  - shell 增加 `PUBLIC_SMOKE_SRC`、`public_smoke_output_root()`、`run_public_smoke()`
  - batch 增加 `PUBLIC_SMOKE_SRC`、`:run_public_smoke_internal`
  - shell/bat 的 `check` 都接入 `public_smoke`
  - shell/bat 的 `clean` 都补 `public.smoke` child output root 清理
- 修正真正执行落点后，再跑 fresh Release `check`，日志里已经真实出现：
  - `[PUBLIC-SMOKE] Building standalone smoke: /home/dtamade/projects/fafafa.core/tests/fafafa.core.simd/fafafa.core.simd.public_smoke.pas`
  - `[PUBLIC-SMOKE] Running standalone smoke: /home/dtamade/projects/fafafa.core/tests/fafafa.core.simd/public.smoke/bin/fafafa.core.simd.public_smoke`
  - `CPU vendor: GenuineIntel`
  - `CPU model:  Intel(R) Xeon(R) CPU E5-2680 v4 @ 2.40GHz`
  - `Backend:    AVX2`
  - `[PASS] Default backend is AVX2`
- 同一次 `Release check` 里，后续链路也继续为绿：
  - `dispatch preinit smoke` OK
  - `experimental intrinsics isolation` OK
  - 说明这次不只是修了一个 standalone 程序，而是把它真正纳入了日常 SIMD 检查闭环

## 2026-05-15 BackendOps And Boundary Check Coverage Wiring

- 在 `public_smoke` 接进 `check/gate` 之后，我继续往同类 standalone 程序审，先重新做 fresh 独立真运行：
  - `test_backend_ops.pas`：`Passed: 15`、`Failed: 0`
  - `test_simd_boundary.pas`：`通过: 44`、`失败: 0`
- 这说明这两个入口的真实问题不是程序本体坏了，而是它们仍然没有进入自动闭环。
- 本轮接线改动集中在两个脚本：
  - `tests/fafafa.core.simd/BuildOrTest.sh`
  - `tests/fafafa.core.simd/buildOrTest.bat`
- shell 侧新增：
  - `BACKEND_OPS_SRC`
  - `SIMD_BOUNDARY_SRC`
  - `backend.ops` / `simd.boundary` child output root
  - `run_backend_ops_smoke()`
  - `run_simd_boundary_smoke()`
- batch 侧也同步补了对应内部 runner 和 `clean` 清理路径。
- shell 的两条真实执行路径都已经接上：
  - `gate_step_build_check()`
  - `case "${ACTION}" in ... check)`
- fresh Release `check` 的关键日志证据：
  - `[BACKEND-OPS] Building standalone program: /home/dtamade/projects/fafafa.core/tests/fafafa.core.simd/test_backend_ops.pas`
  - `Passed: 15`
  - `[SIMD-BOUNDARY] Building standalone program: /home/dtamade/projects/fafafa.core/tests/fafafa.core.simd/test_simd_boundary.pas`
  - `通过: 44`
  - 随后 `PUBLIC-SMOKE` 与 `DISPATCH-PREINIT` 也继续通过
- fresh Release `gate` 的 `1/6 Build + check SIMD module` 中也已经真实出现：
  - `BACKEND-OPS`
  - `SIMD-BOUNDARY`
  - `PUBLIC-SMOKE`
  - `DISPATCH-PREINIT`
  - 最终 `Run-all summary: Passed 5 / Failed 0`
  - `[GATE] OK`
- 当前这批的实情我也在这里留档：
  - shell 侧 `check/gate` 已经被真实 release 运行覆盖
  - batch 侧改动本轮没有真实 Windows 执行证据，仍属于 source-aligned but not runtime-proved 状态

## 2026-05-15 Daily Standalone Runner Guard

- 在 `backend_ops / simd_boundary` 接进 daily coverage 并提交后，我继续往脚本工具层补一层“防回退”机制，而不是立刻去做更大范围的 runner 重构。
- 先对照了现有先例：
  - `check_dispatch_preinit_smoke_runner_guard()`
  - 它已经证明这种 grep/source-safe guard 很适合在 Linux 主链里提前抓 shell/bat 漂移
- 本轮新增了：
  - `check_daily_standalone_runner_guard()`
- 这条 guard 现在会同时校验：
  - shell/bat 里是否还保留 `BACKEND_OPS_SRC`
  - shell/bat 里是否还保留 `SIMD_BOUNDARY_SRC`
  - 对应 output root 和 runner 定义是否还在
  - `check` / `gate build-check` 的调用点是否还在
  - `test_backend_ops.pas` / `test_simd_boundary.pas` 的关键 sentinel 是否还在
- fresh Release `check` 的关键证据：
  - `[CHECK] OK (daily standalone runner guard present)`
  - 同一次 `check` 后半段继续真实跑完：
    - `BACKEND-OPS`
    - `SIMD-BOUNDARY`
    - `PUBLIC-SMOKE`
    - `DISPATCH-PREINIT`
- 这意味着当前不仅 daily coverage 已经接上，而且这个 coverage 自身也开始被脚本自检守护了。

## 2026-05-15 Standalone Guard Coverage Tightening

- 继续加强审查时，我没有回头重新扫 backend label 或 runner 本体，而是专门追“guard 还有没有遗漏面”。
- 先确认出的真实缺口有三处：
  - `check_daily_standalone_runner_guard()` 没覆盖 `public_smoke`
  - `check_isolated_clean_coverage()` 没覆盖 `public.smoke/backend.ops/simd.boundary`
  - `check_dispatch_preinit_smoke_runner_guard()` 没守住 batch 的 `DISPATCH_PREINIT_OUTPUT_ROOT` / root override
- 这轮改动只落在 `tests/fafafa.core.simd/BuildOrTest.sh`，没有再去扩大接口面：
  - 把 `public_smoke` 纳入 `check_daily_standalone_runner_guard()`
  - 给 `public_smoke` 增加源文件 sentinel，确保仍然输出 canonical backend name，而不是把 ordinal 又带回来
  - 给 daily standalone batch guard 补 `public_smoke/backend_ops/simd_boundary` 的 clean 路径与 root override 合同
  - 给 `check_isolated_clean_coverage()` 补齐三条 child output 清理路径
  - 给 `check_dispatch_preinit_smoke_runner_guard()` 补 `DISPATCH_PREINIT_OUTPUT_ROOT` 与 root override 模式
- 中间有一个 guard 书写层的小坑被 fresh Release `check` 立刻抓出来：
  - 我第一次把 `public_smoke` sentinel 写成了 shell 单引号嵌单引号形式
  - bash 在解析数组字面量时把引号吃掉，导致 `grep` 实际匹配串失真
  - 这个问题没有进入最终结果，因为我已经把那三条模式改成双引号字符串后重新跑绿
- 重新验证后的关键证据：
  - `git diff --check` 通过
  - Release `check` 里真实出现：
    - `[CHECK] OK (isolated clean coverage present)`
    - `[CHECK] OK (dispatch preinit smoke guard present)`
    - `[CHECK] OK (daily standalone runner guard present)`
    - `BACKEND-OPS` → `Passed: 15`
    - `SIMD-BOUNDARY` → `通过: 44`
    - `PUBLIC-SMOKE` → `Backend:    AVX2`
    - `DISPATCH-PREINIT` → `OK`
  - Release `gate` 最终真实通过：
    - `Run-all summary ... Passed: 5 Failed: 0`
    - `[GATE] OK`
- 我还试着用 `wine` 做最小 batch runtime proof 探针：
  - `wine cmd /c echo HI` 正常
  - 临时 wrapper 能让 `where fpc` 看到 `fpc.bat`
  - 但 `fpc -iTP` 这一步没有给出可靠完成结果，且伴随 `wine` 剪贴板超时噪音
  - 我已经清理掉 `/tmp/simd-wine-probe.*` 和相关进程，没有把临时探针残留在 repo 里

## 2026-05-15 Windows Evidence Contract Tightening

- 我继续往下追的是证据层，而不是 SIMD 实现层：
  - 旧 `tests/fafafa.core.simd/logs/windows_b07_gate.log` 仍是 2026-04-18 的老 shape
  - 它没有 `BACKEND-OPS / SIMD-BOUNDARY / PUBLIC-SMOKE / DISPATCH-PREINIT`
  - 但旧 verifier 还会把它判成 `OK`
- 这轮修的是证据合同本身：
  - `verify_windows_b07_evidence.sh`
  - `verify_windows_b07_evidence.bat`
  - `collect_windows_b07_evidence.bat`
  - `simulate_windows_b07_evidence.sh`
  - `rehearse_freeze_status.sh`
  - `BuildOrTest.sh` 里的对应 source-safe guard
- 我把采集脚本改成了更真实的 current contract：
  - `1/6 Build + check SIMD module` 直接走 `buildOrTest.bat check`
  - `Optional public ABI smoke`
  - `2/6` 到 `6/6` 的 current gate 文案
  - 四个 standalone runner 的 build/run 痕迹会进入证据日志
- 最关键的验证结果：
  - `bash tests/fafafa.core.simd/verify_windows_b07_evidence.sh tests/fafafa.core.simd/logs/windows_b07_gate.log` 现在会 fail
  - `wine cmd /c ...verify_windows_b07_evidence.bat ...windows_b07_gate.log` 也会 fail
  - 合成的 current-contract Windows log 在 shell 和 batch verifier 下都能通过
  - `bash tests/fafafa.core.simd/rehearse_freeze_status.sh` 继续 OK
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate` 也继续 OK，但旧 Windows evidence 会被降级成 optional `SKIP`
- 这意味着现在 Windows evidence 终于不再误报“够新够全”：
  - 没有新接入的 standalone coverage，就不该被当成当前证据
  - 旧日志只能作为历史快照，不能再充当现成的 release proof

## 2026-05-15 Gate Label Harmonization

- 我再做了一刀纯 contract 对齐：
  - shell `BuildOrTest.sh gate` 里原来还留着 `3/6 SIMD AVX2 fallback suite`
  - batch/evidence/rehearsal 早就已经是 `3/6 SIMD AVX2 stable vector suites`
- 这次只改了一行 shell 文案，不动 gate 逻辑：
  - 把 shell 的 `3/6` step label 也统一成 `stable vector suites`
  - 让 shell/batch/evidence/rehearsal 对同一条门禁说同一种话
- 再次验证的结果：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate` 继续 `OK`
  - gate 日志里已经出现新的 `3/6 SIMD AVX2 stable vector suites`
  - `verify_windows_b07_evidence.{sh,bat}` 仍然会把旧 `windows_b07_gate.log` 判成 fail
- 这一步只是收敛命名，不是放松合同：
  - 同一条 gate 的口径现在更一致了
- 2026-05-15 继续复核 GH preflight：
  - `gh auth status` 正常，workflow 也能解析到 `simd-windows-b07-evidence.yml`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight`
  - 结果：`RECENT_BILLING_BLOCK`
  - 结论：fresh Windows evidence 仍是外部账单/额度阻塞，不继续做本地无效重试

## 2026-05-15 RISCVV I64x2 MinMax Helper Exact-Contract Consolidation

- 在确认 `win-evidence-preflight` 仍被外部 billing 阻塞之后，这一轮没有再在外部 blocker 上空转，而是回到 `RISCVV helper` 的真实残余，继续找最小安全的 exact-contract redundancy。
- 先重新核了当前边界：
  - `dispatchapi` 里仍明确守着 `DotF64x2/DotF64x4` 不能直接 scalar forward；
  - `Round/Trunc` 在 register/source-shape 上仍属于需要谨慎的 float 语义面；
  - 之前 scratch findings 也已经把 `Round/Trunc/Clamp`、`NormalizeF32x4/F32x3` 标成不能机械合并。
- 因此本批只改了两处 helper 真源去重：
  - `src/fafafa.core.simd.riscvv.helpers.inc`
  - `RISCVVMinI64x2 -> ScalarMinI64x2(a, b)`
  - `RISCVVMaxI64x2 -> ScalarMaxI64x2(a, b)`
- 对应的 source-side guard 也一起补上了：
  - `tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - 新增 `RISCVVMinI64x2` / `RISCVVMaxI64x2` 两条期望
- 这批的串行验证我按当前仓库纪律完整跑了一轮：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 结果：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=477 status=ok`
  - `impl-audit-nonx86` 通过
  - Release `check` 通过
  - Release `gate` 通过
  - `gate` 末尾旧 Windows evidence 仍被诚实降级为 optional `SKIP`，没有误报成当前证据

## 2026-05-15 RISCVV AndNot Helper Exact-Contract Consolidation

- `2dcc183f` 提交完 `Min/MaxI64x2` 之后，我继续往 `riscvv.helpers.inc` 里扫下一刀，不重开大范围分析，只找“已有 scalar 真源、但 helper 还在维护第二份逻辑”的同级别尾巴。
- 快速复核后确认：
  - `Neg/Load/Store/Splat/Zero/Select/Reduce` 这批多数没有现成同名 scalar helper，或者会把本轮收口扩到更宽合同面；
  - 目前最值钱且风险仍然可控的只剩 3 个 `AndNot` helper。
- 本批改动如下：
  - `RISCVVAndNotI8x16 -> ScalarAndNotI8x16(a, b)`
  - `RISCVVAndNotU16x8 -> ScalarAndNotU16x8(a, b)`
  - `RISCVVAndNotU8x16 -> ScalarAndNotU8x16(a, b)`
  - `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 同步新增这 3 条 helper expectation
- 复验链继续按串行纪律执行：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前已知结果：
  - helper summary 已升到 `NONX86_HELPER_SEMANTICS_SUMMARY checks=480 status=ok`
  - `impl-audit-nonx86` 通过，`RISCVV ABI shape` 仍是 `direct_functions=123 / suspicious_a0_loads=0`
  - Release `check` 已再次跑绿
  - Release `gate` 已再次跑绿；末尾旧 Windows evidence 仍被诚实降级为 optional `SKIP`

## 2026-05-15 RISCVV I64x4 Arithmetic-Shift Helper Exact-Contract Consolidation

- 第二个小提交之后，我再做了一次“有没有最后一个同级别尾巴”的边界扫描。
- 结论很清楚：
  - `RISCVVShiftRightArithI64x4` 仍然是已有 scalar 真源、helper 还手写着第二份完全同合同逻辑的最后一条；
  - 相邻的 `U64x2 shift`、`Reduce*`、`Select*` 这批要么没有现成 scalar helper，要么会把工作扩到更宽合同面，因此不再继续顺手扩大。
- 本批改动非常小：
  - `RISCVVShiftRightArithI64x4 -> ScalarShiftRightArithI64x4(a, shift)`
  - `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 补 1 条 helper expectation
- 当前已知复验结果：
  - `git diff --check` 通过
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=481 status=ok`
  - `impl-audit-nonx86` 通过
  - Release `check` 已再次跑绿
  - Release `gate` 已再次跑绿；末尾旧 Windows evidence 继续被诚实降级为 optional `SKIP`

## 2026-05-15 RISCVV CmpNeU32x4 Internal Contract Drift Fix

- 在上一批 helper exact-contract 收口后，我没有继续机械扫 `reduce/select`，而是改成针对剩余 internal helper 做“签名和真实消费面”复核。
- 这次抓到的真实问题不是冗余，而是内部合同漂移：
  - `RISCVVCmpNeU32x4` 在 `riscvv.pas` asm 路径里返回 `TMask4`
  - 但在 `riscvv.helpers.inc` no-ASM fallback 里却返回了 `TVecU32x4`
- 我继续往下核了消费面，确认这条线当前不是公开 surface：
  - `dispatch.pas` 没有 `CmpNeU32x4` 槽位
  - `riscvv.register.inc` 没有给它赋值
  - `riscvv.facade.inc` 没有公开同名 façade
  - `sse2.register.inc` 还明确注释 `CmpNeU32x4 not in dispatch table`
- 因此这批修的是“内部 helper 也必须自洽”，而不是“补一个新公开 API”：
  - `RISCVVCmpNeU32x4` fallback 返回类型改回 `TMask4`
  - loop 逻辑改成 mask-bit accumulation，而不是再写 vector-lane all-ones
  - `check_nonx86_helper_semantics.py` 同步加了签名 + 关键语义片段断言
- fresh 验证结果：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前结果：
  - helper summary 升到 `NONX86_HELPER_SEMANTICS_SUMMARY checks=482 status=ok`
  - `impl-audit-nonx86` 继续为绿
  - Release `check` 继续为绿
  - Release `gate` 继续为绿，旧 Windows evidence 仍然只是 optional `SKIP`

## 2026-05-15 RISCVV Dead Load/Store/Splat/Zero Residue Removal

- 继续按“先看真实消费面，再决定删还是收”的方式往下审 `RISCVV`，这次把目标锁到 `I32x4/I64x2` 的 `Load/Store/Splat/Zero` 8 个候选 internal residue。
- 第一轮全仓检索已经把结论压得很清楚：
  - 这 8 个名字只剩 `src/fafafa.core.simd.riscvv.pas` 和 `src/fafafa.core.simd.riscvv.helpers.inc` 两处定义；
  - 没有 `dispatch/register/facade/tests/docs` 消费面。
- 因此这批不是“helper exact-contract consolidation”，而是“dead dual-track residue removal”：
  - 从 `riscvv.pas` 删除 8 个 asm dead entry；
  - 从 `riscvv.helpers.inc` 删除 8 个 fallback dead entry。
- 为了把这个事实变成长期护栏，我同步改了 `tests/fafafa.core.simd/check_nonx86_helper_semantics.py`：
  - 新增 `require_routine_absent(...)`
  - 对这 8 个 `RISCVVLoad/Store/Splat/ZeroI32x4/I64x2` 逐条要求 source-side 缺席
- 本批 fresh 验证：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前结果：
  - helper summary 升到 `NONX86_HELPER_SEMANTICS_SUMMARY checks=498 status=ok`
  - `impl-audit-nonx86` 继续为绿
  - Release `check` 继续为绿
  - Release `gate` 继续为绿
  - `gate` 末尾仍然只把旧 `windows_b07_gate.log` 诚实降级为 optional `SKIP`
- 收口前已清理 `tests/fafafa.core.simd/__pycache__/`，避免把 Python 缓存目录带进提交。

## 2026-05-15 RISCVV Dead Shift/Reduce/Select Residue Removal

- 在第一组 `Load/Store/Splat/Zero` dead residue 清完并提交后，继续往 `RISCVV` 的内部尾巴扫第二组候选：
  - `U64x2 shift`
  - `I32x4/U32x4 reduce`
  - `I64x2/I32x8/I32x16 select`
- fresh 全仓/接线复核后，结论比上一轮更明确：
  - 这 10 组名字没有 `register/facade/dispatch/simd.pas/tests` 消费面；
  - 只剩 `src/fafafa.core.simd.riscvv.pas` 和 `src/fafafa.core.simd.riscvv.helpers.inc` 双轨定义。
- 因此这批不是“没有 scalar 真源先留着”，而是第二组明确的 dead residue：
  - 从 `riscvv.pas` 删除 10 组 asm/wrapper dead entry；
  - 从 `riscvv.helpers.inc` 删除 10 组 fallback dead entry。
- 为了防回流，`tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 继续扩了 source-side 缺席护栏：
  - `RISCVVShiftLeftU64x2`
  - `RISCVVShiftRightU64x2`
  - `RISCVVReduceAddI32x4`
  - `RISCVVReduceMinI32x4`
  - `RISCVVReduceMaxI32x4`
  - `RISCVVReduceMinU32x4`
  - `RISCVVReduceMaxU32x4`
  - `RISCVVSelectI64x2`
  - `RISCVVSelectI32x8`
  - `RISCVVSelectI32x16`
- 本批 fresh 验证：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前结果：
  - helper summary 升到 `NONX86_HELPER_SEMANTICS_SUMMARY checks=518 status=ok`
  - `riscvv_abi_shape` 仍为绿，`direct_functions` 自然收缩到 `121`
  - `impl-audit-nonx86` 继续为绿
  - Release `check` 继续为绿
  - Release `gate` 继续为绿
  - `gate` 末尾仍然只把旧 `windows_b07_gate.log` 诚实降级为 optional `SKIP`
- 收口前再次清理了 `tests/fafafa.core.simd/__pycache__/`，避免缓存目录污染提交。

## 2026-05-15 RISCVV Dead Neg Residue Removal

- 在第二组 `U64x2 shift / I32x4,U32x4 reduce / I64x2,I32x8,I32x16 select` 清完并提交后，我没有立刻扩到别的 backend，而是先做了一轮“RISCVV 还有没有剩余非 Asm 内部残留”的收尾扫描。
- fresh 扫描方法：
  - 枚举 `src/fafafa.core.simd.riscvv.pas` 与 `src/fafafa.core.simd.riscvv.helpers.inc` 里的全部 `RISCVV*` 例程
  - 过滤掉 `*Asm`
  - 再与 `riscvv.facade.inc / riscvv.register.inc / dispatch.pas / simd.pas / tests / docs / plans` 做文本交叉
- 结果只剩：
  - `RISCVVNegF32x4`
  - `RISCVVNegF64x2`
- 继续追面后确认它们也是 dead residue：
  - 仅在 `riscvv.pas` 与 `riscvv.helpers.inc` 各留一份定义
  - 没有 `register/facade/dispatch/simd.pas/tests` 消费面
- 因此本批继续做第三组死残留清理：
  - 从 `riscvv.pas` 删除 `NegF32x4/NegF64x2` 的 asm + wrapper
  - 从 `riscvv.helpers.inc` 删除对应 fallback
  - `check_nonx86_helper_semantics.py` 把这 2 个名字加入 absent 护栏
- 本批 fresh 验证：
  - `git diff --check`
  - `rg -n \"RISCVVNegF32x4|RISCVVNegF64x2\" src tests docs plans`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前结果：
  - helper summary 升到 `NONX86_HELPER_SEMANTICS_SUMMARY checks=522 status=ok`
  - `impl-audit-nonx86` 继续为绿
  - `riscvv_abi_shape` 继续为绿，`direct_functions=121`
  - Release `check` 继续为绿
  - Release `gate` 继续为绿
  - 额外残留扫描结果已到 `RESIDUE_COUNT=0`
  - `gate` 末尾仍然只把旧 `windows_b07_gate.log` 诚实降级为 optional `SKIP`

## 2026-05-15 NEON Dead Compare/Reduction/MinMax Residue Removal

- `RISCVV` 非 `Asm` internal residue 清到 `0` 之后，下一刀没有跳去新主题，而是沿同一口径继续扫 `NEON` 的零调用尾巴。
- fresh 复核后确认，本批只删真正没有消费面的 9 组名字：
  - `NEONCmpNeU32x4`
  - `NEONReduce(Add/Min/Max)I32x4`
  - `NEONReduce(Add/Min/Max)U32x4`
  - `NEONMinI64x2`
  - `NEONMaxI64x2`
- 这些名字当前都没有 `register/facade/runtime/simd.pas/tests` 接线，因此本批不是“补能力”，而是“删错误保留的 dead residue”：
  - 从 `src/fafafa.core.simd.neon.compare.inc` 删除 compare/reduction 入口
  - 从 `src/fafafa.core.simd.neon.scalar.reduction.inc` 删除对应 fallback
  - 从 `src/fafafa.core.simd.neon.scalar.utility.inc` 删除 `Min/MaxI64x2`
- `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 已同步补齐缺席护栏：
  - 新增 `NEON_COMPARE_FILE`
  - 把上述名字全部纳入 `require_routine_absent(...)`
- 本批 fresh 验证：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前结果：
  - helper summary 升到 `NONX86_HELPER_SEMANTICS_SUMMARY checks=537 status=ok`
  - `impl-audit-nonx86` 继续为绿
  - Release `check` 继续为绿
  - Release `gate` 继续为绿
  - `NEON` 非 `_ASM` 零调用残留只剩 7 个 wrapper/combine 内部支撑函数，不再属于这类 dead residue
  - `gate` 末尾仍然只把旧 `windows_b07_gate.log` 诚实降级为 optional `SKIP`
- 收口前会继续清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-15 NEON Single-Use Compare Wrapper Inline Cleanup

- 在上一批 `NEON` dead residue 清完并提交后，我没有把“剩下的 7 个 helper”继续粗暴当成一类，而是先拆成：
  - 3 个高复用 `CombineMask*`
  - 4 个单点 compare thin wrapper
- fresh 交叉检索结果很清楚：
  - `NEONCombineMask2To4/4To8/8To16` 在 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 内被大量宽比较函数复用，必须保留
  - `NEONCmpLeU64x2Wrapper`、`NEONCmpGeU64x2Wrapper`、`NEONCmpNeU64x2Wrapper`、`NEONCmpNeU32x4Wrapper` 只是单行反相壳，而且各自只服务一个聚合调用点
- 因此本批继续收冗余，但不误删 live support：
  - 从 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 删除 4 个 wrapper 定义
  - 把 `NEONCmpGeU64x4`、`NEONCmpLeU64x4`、`NEONCmpNeU32x8`、`NEONCmpNeU64x4` 改成直接在 `NEONCombineMask*` 调用点内联表达式
  - `NEONCombineMask2To4/4To8/8To16` 原样保留
- `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 已同步加上这 4 个名字的缺席护栏，避免后续把同类 wrapper 又绕回来。
- 本批 fresh 验证：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前结果：
  - helper summary 升到 `NONX86_HELPER_SEMANTICS_SUMMARY checks=541 status=ok`
  - `impl-audit-nonx86` 继续为绿
  - Release `check` 继续为绿
  - Release `gate` 继续为绿
  - `run_all` 仍为 5/5 通过
  - `gate` 末尾仍然只把 non-x86 native evidence root 缺失和旧 `windows_b07_gate.log` 诚实降级为 optional `SKIP`
- 收口前会再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-15 NEON Wide Float Memory Utility Asm Binding Repair

- 已完成对 `NEON` wide-float memory/utility slot 的 asm 接线补修。
- 已在 `src/fafafa.core.simd.neon.register.inc` 的 asm 分支补上 16 条 direct binding。
- 已在 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 增加 source-shape + runtime expectation 测试。
- 已跑通 `git diff --check`、`impl-audit-nonx86`、Release `check`、Release `gate`。
- `gate` 末尾仍仅把旧 `windows_b07_gate.log` 作为 optional `SKIP`，没有新回归。

## 2026-05-15 NEON Wide Float Asm Shadowing Fix

- 继续深审上一批 wide-float asm 接线时，发现前一版只补了前半段 `_ASM` binding，但没注意到 `neon.register.inc` 后半段还有 16 条无条件 `@NEON...` rebinding，会把前面的 `_ASM` 再覆盖掉。
- fresh 全仓检索后确认，这 16 个 `NEONLoad/Store/Splat/Zero F32x8/F32x16/F64x4/F64x8` wrapper 只剩 `scalar.autowrap.inc + register.inc` 两处，没有其他真实消费面，因此一旦去掉 rebinding，它们就是纯 dead code。
- 本批已完成：
  - 从 `src/fafafa.core.simd.neon.register.inc` 删除后半段 16 条 wrapper rebinding
  - 从 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 删除对应 16 个 dead scalar-forwarder wrapper
  - 从 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 补上“_ASM binding 存在 + 后段 wrapper rebinding 缺席 + dead wrapper 缺席”的 source-side 护栏
  - 从 `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 补上这 16 个名字的 absent guard
- 本批 fresh 验证：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight`
- 当前结果：
  - helper summary 升到 `NONX86_HELPER_SEMANTICS_SUMMARY checks=557 status=ok`
  - `impl-audit-nonx86` 继续为绿
  - `NEON` register truth 变为 `assignments=411 asm_exact=224 asm_suffix_only=10 wrapper_only=177 scalar_passthrough=0 no_def=0 miswired=0 strict=1`
  - Release `check` 继续为绿
  - Release `gate` 继续为绿
  - `freeze-status` 现在确认 Linux gate 新鲜，但仍红在 `qemu-cpuinfo-nonx86-evidence=SKIP` 和历史 Windows evidence stale/verify fail
  - `win-evidence-preflight` 继续返回 `RECENT_BILLING_BLOCK`，说明当前剩余 closeout gap 还是外部 GH billing / Windows evidence 刷新问题
- 收口前会清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-15 Register Truthfulness Shadowing Guard Upgrade

- 继续沿着上一批 `NEON` shadowing 的真实 bug 深挖后，确认当前更高价值的工作不是再扫一轮局部 wrapper，而是把这类“slot 前后被不同 target 重绑”的问题变成通用 checker 护栏。
- `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 已完成升级：
  - `--fixture` 新增 `shadowed`
  - 新增 `contexts_overlap(...)`
  - report 现在会保留每条 assignment record，并对同一 slot 做 overlapping-context rebinding 检查
  - human 输出新增 `conflicting assign`
  - miswired 条目现在会附带 `conflicts=...`
- 已新增 fixture：
  - `tests/fafafa.core.simd/fixtures/nonx86_register_truthfulness/shadowed/mock.backend.register.inc`
  - `tests/fafafa.core.simd/fixtures/nonx86_register_truthfulness/shadowed/mock.backend.pas`
  - 该 fixture 稳定复现“asm-only 先绑一个 target，always 再盖另一个 target”的冲突模式
- 本批 fresh 复验：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --fixture good --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --fixture bad --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --fixture shadowed --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前结果：
  - `git diff --check` 通过，`py_compile` 通过
  - `fixture good`：`miswired=0 conflicting assign=0`，继续 PASS
  - `fixture bad`：继续 FAIL，`miswired=2 conflicting assign=0`
  - `fixture shadowed`：新增 FAIL，`miswired=2 conflicting assign=2`，并稳定报出 `overlapping-slot-rebinding`
  - `backend=neon`：`assignments=411 asm_exact=224 asm_suffix_only=10 wrapper_only=177 scalar_passthrough=0 no_def=0 miswired=0 conflicting assign=0`
  - `backend=riscvv`：`assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 conflicting assign=0`
  - `impl-audit-nonx86` 继续为绿，summary 为 `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `check` 继续为绿
  - Release `gate` 继续为绿，`run_all` 为 `5/5` 通过
  - `gate` 尾部结论保持不变：non-x86 native evidence root 缺失仍是 optional `SKIP`，旧 `windows_b07_gate.log` 仍因历史内容不满足当前 pattern 而 optional `SKIP`

## 2026-05-15 NEON No-Asm Float Compare Scalar-Forwarder Cleanup

- 继续从 `wrapper_only` 余量往下扫后，锁定了一个更成体系的 `NEON` 冗余面：
  - no-asm 分支里有 24 个 `CmpEq/Ge/Gt/Le/Lt/Ne × {F32x16,F32x8,F64x4,F64x8}` slot 仍被绑到 `NEON...`
  - 但对应 wrapper 在 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 里全部只是 `ScalarCmp...` 单行转发
  - `F64x2` compare 仍是本地 loop，不属于这批
- 本批已完成：
  - 从 `src/fafafa.core.simd.neon.register.inc` 删除这 24 条 no-asm compare assignment
  - 从 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 删除对应 24 个 dead scalar-forwarder wrapper
  - 从 `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 收紧 `ALLOWED_WRAPPER_SLOTS_BY_BACKEND['neon']`
  - 从 `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 补上这 24 个 absent guard
  - 从 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_NEON_NoAsmFloatCompareSlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`
- 本批 fresh 复验：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_register_truthfulness.py tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前结果：
  - helper summary 升到 `NONX86_HELPER_SEMANTICS_SUMMARY checks=581 status=ok`
  - `backend=neon` truthfulness 变为 `assignments=387 asm_exact=224 asm_suffix_only=10 wrapper_only=153 scalar_passthrough=0 no_def=0 miswired=0 conflicting assign=0`
  - 相比上一批 `assignments=411 / wrapper_only=177`，正好少掉这 24 个 no-asm float compare scalar-forwarder assignment
  - `backend=riscvv` 保持 `assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 conflicting assign=0`
  - `impl-audit-nonx86` 继续为绿，summary 为 `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `check` 继续为绿
  - Release `gate` 继续为绿，`run_all` 仍为 `5/5` 通过
  - `gate` 尾部结论没有变化：non-x86 native evidence root 缺失仍是 optional `SKIP`，旧 `windows_b07_gate.log` 仍是历史 Windows evidence 的 optional `SKIP`

## 2026-05-15 NEON Wide Rcp/Reduction Scalar-Forwarder Cleanup

- 接着上一批 compare cleanup 继续扫 `NEON wrapper_only` 余量后，锁定了 17 个仍然占着 slot 的 wide scalar-forwarder：
  - `RcpF64x4`
  - `ReduceAdd/Max/Min/Mul × {F32x16,F32x8,F64x4,F64x8}`
  - 它们在 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 里全部只是 `Scalar*` 单行转发
  - `F64x2` reductions 仍是本地实现，所以保留
- 这批还同步修正了一条过度乐观的 asm-path 测试口径：
  - `TTestCase_NonX86BackendParity.Test_NativeF64ReduceAddSeedParity_WithVectorAsm_IfAvailable`
  - 现在对 `NEON` 改为要求 `ReduceAddF64x4/F64x8` 诚实复用 scalar slot
  - 对 `RISCVV` 仍保留 native-slot 断言
- 本批已完成：
  - 从 `src/fafafa.core.simd.neon.register.inc` 删除这 17 条 wide `Rcp/Reduce` assignment
  - 从 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 删除对应 17 个 dead scalar-forwarder wrapper
  - 从 `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 收紧 `ALLOWED_WRAPPER_SLOTS_BY_BACKEND['neon']`
  - 从 `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 补上这 17 个 absent guard
  - 从 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_NEON_WideRcpAndReductionSlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`
  - 并同步修正 `Test_NativeF64ReduceAddSeedParity_WithVectorAsm_IfAvailable` 的 ownership 断言
- 本批 fresh 复验：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_register_truthfulness.py tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_NonX86BackendParity`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前结果：
  - helper summary 升到 `NONX86_HELPER_SEMANTICS_SUMMARY checks=598 status=ok`
  - `backend=neon` truthfulness 变为 `assignments=370 asm_exact=224 asm_suffix_only=10 wrapper_only=136 scalar_passthrough=0 no_def=0 miswired=0 conflicting assign=0`
  - 相比上一批 `assignments=387 / wrapper_only=153`，正好少掉这 17 个 wide scalar-forwarder assignment
  - `backend=riscvv` 保持 `assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 conflicting assign=0`
  - `impl-audit-nonx86` 继续为绿，summary 为 `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `check` 继续为绿
  - Release `gate` 继续为绿，`run_all` 仍为 `5/5` 通过
  - `gate` 尾部结论仍没有变化：non-x86 native evidence root 缺失仍是 optional `SKIP`，旧 `windows_b07_gate.log` 仍是历史 Windows evidence 的 optional `SKIP`

## 2026-05-15 NEON No-Asm Abs/Wide FloorCeil Scalar-Forwarder Cleanup

- 继续沿 `NEON wrapper_only` 往下扫后，这一批锁定的是 13 个 no-asm `Abs/Floor/Ceil` scalar-forwarder：
  - `Abs × {F32x16,F32x8,F64x2,F64x4,F64x8}`
  - `Ceil × {F32x16,F32x8,F64x4,F64x8}`
  - `Floor × {F32x16,F32x8,F64x4,F64x8}`
- 已确认这 13 个名字在 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 里都只是单行 `Scalar*` 转发，因此继续挂在 `NEON` register 上只会制造虚假的 backend-owned truth。
- 本批特意停手的两个例外也已复核清楚：
  - `NEONCeilF64x2`
  - `NEONFloorF64x2`
- 这两个函数在 no-asm 路径里仍保留 backend-local loop，所以继续留在 `register` 中，不和 wide family 一起删。
- 本批已完成：
  - 从 `src/fafafa.core.simd.neon.register.inc` 删除 13 条 no-asm assignment
  - 从 `src/fafafa.core.simd.neon.scalar.autowrap.inc` 删除对应 13 个 dead wrapper
  - 从 `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 收紧 `ALLOWED_WRAPPER_SLOTS_BY_BACKEND['neon']`
  - 从 `tests/fafafa.core.simd/check_nonx86_helper_semantics.py` 把这 13 个名字改成 absent guard
  - 从 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 新增 `Test_NEON_NoAsmAbsAndWideFloorCeilSlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`
  - 并同步把两条旧的 `wide Floor/Ceil` ownership 测试收正为“NEON 复用 scalar，否则 native”
- 本批 fresh 复验：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_register_truthfulness.py tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_NonX86BackendParity`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前结果：
  - helper summary 维持 `NONX86_HELPER_SEMANTICS_SUMMARY checks=598 status=ok`
  - `backend=neon` truthfulness 变为 `assignments=357 asm_exact=224 asm_suffix_only=10 wrapper_only=123 scalar_passthrough=0 no_def=0 miswired=0 conflicting assign=0`
  - 相比上一批 `assignments=370 / wrapper_only=136`，正好少掉这 13 个 `Abs/Floor/Ceil` scalar-forwarder assignment
  - `backend=riscvv` 保持 `assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 conflicting assign=0`
  - `impl-audit-nonx86` 继续为绿，summary 为 `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `check` 继续为绿
  - Release `gate` 继续为绿，`run_all` 为 `5/5` 通过
  - `gate` 尾部仍然只把 non-x86 native evidence root 缺失和历史 `windows_b07_gate.log` 诚实降级为 optional `SKIP`
- 收口前已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-15 NEON No-Asm FMA Scalar-Forwarder Cleanup

- 继续沿 `NEON wrapper_only` 收口时，这一批锁定的是 `Fma` 家族：
  - `FmaF32x4`
  - `FmaF32x16`
  - `FmaF32x8`
  - `FmaF64x2`
  - `FmaF64x4`
  - `FmaF64x8`
- 这批和前两批不一样的地方已经先复核清楚：
  - no-asm 版本在 `src/fafafa.core.simd.neon.scalar.ext_math.inc` / `scalar.autowrap.inc` 里都只是 exact `ScalarFma*` forwarder
  - 但同名函数在 `src/fafafa.core.simd.neon.pas` 里仍有真实 asm 实现
- 所以本批没有简单删除所有 `register` assignment，而是改成更精确的 asm-only ownership：
  - `src/fafafa.core.simd.neon.register.inc`
    - `table.FmaF32x4 := @NEONFmaF32x4;`
    - `table.FmaF32x16 := @NEONFmaF32x16;`
    - `table.FmaF32x8 := @NEONFmaF32x8;`
    - `table.FmaF64x2 := @NEONFmaF64x2;`
    - `table.FmaF64x4 := @NEONFmaF64x4;`
    - `table.FmaF64x8 := @NEONFmaF64x8;`
    - 现都改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定
  - `src/fafafa.core.simd.neon.scalar.ext_math.inc`
    - 删除 `NEONFmaF32x4`
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc`
    - 删除 `NEONFmaF32x16/F32x8/F64x2/F64x4/F64x8`
- 这样 no-asm build 会直接继承 `FillBaseDispatchTable` 的 scalar `Fma` slot，而 asm build 仍保留真实 backend-local `Fma` 实现。
- 本批还补了一条专门的 no-asm runtime/source 回归：
  - `TTestCase_DispatchAPI.Test_NEON_NoAsmFMASlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`
  - 这条测试在 no-asm 编译下断言：
    - `scalar.ext_math.inc` / `scalar.autowrap.inc` 中 6 个 dead wrapper 缺席
    - `register.inc` 里 asm binding source 仍然存在
    - 运行时 `sbNEON` 的 6 个 `Fma` slot 全部复用 scalar slot
- 脚本护栏同步更新：
  - `check_nonx86_helper_semantics.py` 已把这 6 个名字改成 absent guard
  - `check_nonx86_register_truthfulness.py` 已移除 wide `Fma` allowlist
- 本批 fresh 复验：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_register_truthfulness.py tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前结果：
  - helper summary 维持 `NONX86_HELPER_SEMANTICS_SUMMARY checks=598 status=ok`
  - `backend=neon` truthfulness 变为 `assignments=357 asm_exact=229 asm_suffix_only=10 wrapper_only=118 scalar_passthrough=0 no_def=0 miswired=0 conflicting assign=0`
  - 相比上一批 `assignments=357 asm_exact=224 wrapper_only=123`，正好把 5 个 wide `Fma` slot 从 `wrapper_only` 收进了 `asm_exact`
  - `backend=riscvv` 保持 `assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 conflicting assign=0`
  - `impl-audit-nonx86` 继续为绿，summary 为 `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `check` 继续为绿
  - Release `gate` 继续为绿，`run_all` 为 `5/5` 通过
  - `gate` 尾部仍然只把 non-x86 native evidence root 缺失和历史 `windows_b07_gate.log` 诚实降级为 optional `SKIP`
- 收口前已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-15 NEON No-Asm Narrow Reciprocal Scalar-Forwarder Cleanup

- 继续沿 `NEON` no-asm ownership 深挖后，这一批只收最小安全簇：
  - `RcpF32x4`
  - `RsqrtF32x4`
- 已确认这 2 个名字的 no-asm 版本在 `src/fafafa.core.simd.neon.scalar.ext_math.inc` 里只是：
  - `Result := ScalarRcpF32x4(a);`
  - `Result := ScalarRsqrtF32x4(a);`
- 同时，它们在 `src/fafafa.core.simd.neon.pas` 里仍有真实 asm owner：
  - `NEONRcpF32x4`
  - `NEONRsqrtF32x4`
- 和 `NEONAddF32x4` / `NEONSqrtF32x4` 不同的是，这 2 个名字没有被宽向量 no-asm 组合路径复用，所以这批可以采用最干净的 `Fma` 式修法：
  - `src/fafafa.core.simd.neon.register.inc`
    - 把 `table.RcpF32x4 := @NEONRcpF32x4;`
    - `table.RsqrtF32x4 := @NEONRsqrtF32x4;`
    - 都改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定
  - `src/fafafa.core.simd.neon.scalar.ext_math.inc`
    - 删除 `NEONRcpF32x4`
    - 删除 `NEONRsqrtF32x4`
- 这样 asm build 仍保留真实 reciprocal owner，no-asm build 则直接继承 `FillBaseDispatchTable` 的 scalar slot。
- 本批还补了一条专门的 no-asm runtime/source 回归：
  - `TTestCase_DispatchAPI.Test_NEON_NoAsmNarrowReciprocalSlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`
  - 这条测试在 no-asm 编译下断言：
    - `scalar.ext_math.inc` 里 2 个 dead wrapper 缺席
    - `register.inc` 里 asm binding source 仍在
    - 运行时 `sbNEON` 的 `RcpF32x4/RsqrtF32x4` slot 全部复用 scalar slot
- `check_nonx86_helper_semantics.py` 也已同步把这 2 个名字改成 absent guard。
- 本批 fresh 复验：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前结果：
  - helper summary 维持 `NONX86_HELPER_SEMANTICS_SUMMARY checks=598 status=ok`
  - `backend=neon` truthfulness 继续为 `assignments=357 asm_exact=229 asm_suffix_only=10 wrapper_only=118 scalar_passthrough=0 no_def=0 miswired=0 conflicting assign=0`
  - 这批没有再压低 summary 数字，但 runtime/source truth 已被新测试直接钉住
  - `backend=riscvv` 保持 `assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 conflicting assign=0`
  - `impl-audit-nonx86` 继续为绿，summary 为 `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `check` 继续为绿
  - Release `gate` 继续为绿，`run_all` 为 `5/5` 通过
  - `gate` 尾部仍然只把 non-x86 native evidence root 缺失和历史 `windows_b07_gate.log` 诚实降级为 optional `SKIP`
- 收口前已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-15 NEON No-Asm F32x8 Arithmetic Dead-Wrapper Cleanup

- 继续沿 `NEON` no-asm ownership 深挖后，这一批改收 `Add/Sub/Mul/DivF32x8`：
  - `src/fafafa.core.simd.neon.scalar_fallback.inc` 里这 4 个 no-asm 版本都只是 exact `Scalar*F32x8` forwarder
  - `src/fafafa.core.simd.neon.pas` 里仍有真实 asm owner
  - 全仓源码检索确认没有更宽 no-asm 路径继续消费这 4 个名字，所以它们已经是 dead wrapper
- 本批实现收正：
  - `src/fafafa.core.simd.neon.register.inc`
    - 把 `Add/Sub/Mul/DivF32x8` 改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定
  - `src/fafafa.core.simd.neon.scalar_fallback.inc`
    - 删除 `NEONAddF32x8`
    - 删除 `NEONSubF32x8`
    - 删除 `NEONMulF32x8`
    - 删除 `NEONDivF32x8`
  - `tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
    - 把这 4 个名字从 routine expectation 改成 absent guard
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
    - 新增 `Test_NEON_NoAsmWideF32x8ArithmeticSlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`
    - 同时把两处通用 `Add/Sub/Mul/DivF32x8` capability 断言从“总是 native”收正为“NEON 复用 scalar，否则仍要求 native”
- 本批 fresh 复验：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前结果：
  - helper summary 继续为 `NONX86_HELPER_SEMANTICS_SUMMARY checks=598 status=ok`
  - `backend=neon` truthfulness 维持 `assignments=357 asm_exact=229 asm_suffix_only=10 wrapper_only=118 scalar_passthrough=0 no_def=0 miswired=0 conflicting assign=0`
  - `backend=riscvv` 维持 `assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 conflicting assign=0`
  - `impl-audit-nonx86` 继续为绿，summary 为 `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `check` 继续为绿
  - Release `gate` 继续为绿，`run_all` 为 `5/5` 通过
  - `gate` 尾部仍然只把 non-x86 native evidence root 缺失和历史 `windows_b07_gate.log` 诚实降级为 optional `SKIP`
- 收口前已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-15 NEON No-Asm Wide Leaf Float Arithmetic Slot-Ownership Cleanup

- 继续沿 `NEON` no-asm ownership 深挖后，这一批改收 wide leaf arithmetic slot：
  - `Add/Sub/Mul/DivF32x16`
  - `Add/Sub/Mul/DivF64x8`
- 这批与上一批 `F32x8` 的关键区别已经确认：
  - `F32x8` wrapper 在 no-asm source graph 里已经是 dead leaf，所以能删
  - `F32x16/F64x8` wrapper 在 asm build 里仍然是宽向量组合 owner，所以 source companion 必须保留
  - 但 no-asm runtime 仍不该继续把这些 slot 发布成伪 `NEON` native
- 本批实现收正：
  - `src/fafafa.core.simd.neon.register.inc`
    - 把 `Add/Sub/Mul/DivF32x16`
    - 以及 `Add/Sub/Mul/DivF64x8`
    - 都改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc`
    - 不删 wrapper，继续保留 8 个 source companion
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
    - 新增 `Test_NEON_NoAsmWideLeafFloatArithmeticSlots_Keep_SourceCompanions_But_Reuse_BaseScalar`
    - 同时把两处通用 capability 断言从“总是 native”收正为“NEON 复用 scalar，否则仍要求 native”
- 本批 fresh 复验：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前结果：
  - `DispatchAPI` 继续为绿
  - `backend=neon` truthfulness 维持 `assignments=357 asm_exact=229 asm_suffix_only=10 wrapper_only=118 scalar_passthrough=0 no_def=0 miswired=0 conflicting assign=0`
  - `backend=riscvv` 维持 `assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 conflicting assign=0`
  - `impl-audit-nonx86` 继续为绿，summary 为 `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `check` 继续为绿
  - Release `gate` 继续为绿，`run_all` 为 `5/5` 通过
  - `gate` 尾部仍然只把 non-x86 native evidence root 缺失和历史 `windows_b07_gate.log` 诚实降级为 optional `SKIP`
- 收口前已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-15 NEON No-Asm Wide Sqrt Slot-Ownership Cleanup

- 继续沿 `NEON` no-asm ownership 深挖后，这一批改收 wide `Sqrt` slot：
  - `SqrtF32x8`
  - `SqrtF32x16`
  - `SqrtF64x4`
  - `SqrtF64x8`
- 这批先把真实分类拆清楚，没有把“删 wrapper”和“slot 回 scalar”混成一件事：
  - `NEONSqrtF32x8/F32x16/F64x8` 在 no-asm 下都是 dead wrapper，可以删除
  - `NEONSqrtF64x4` 仍被 `NEONSqrtF64x8` 的 no-asm source graph 消费，所以只能保留为 source companion，不能一并删除
- 本批实现收正：
  - `src/fafafa.core.simd.neon.register.inc`
    - 把 `table.SqrtF32x8 := @NEONSqrtF32x8;`
    - `table.SqrtF32x16 := @NEONSqrtF32x16;`
    - `table.SqrtF64x4 := @NEONSqrtF64x4;`
    - `table.SqrtF64x8 := @NEONSqrtF64x8;`
    - 都改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc`
    - 删除 `NEONSqrtF32x8`
    - 删除 `NEONSqrtF32x16`
    - 保留 `NEONSqrtF64x4`
    - 删除 `NEONSqrtF64x8`
  - `tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
    - 把 `NEONSqrtF32x8/F32x16/F64x8` 改成 absent guard
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
    - 新增 `Test_NEON_NoAsmWideSqrtSlots_Keep_Only_Consumed_Companions_And_Reuse_BaseScalar`
    - 同时把两处通用 `SqrtF32x8/F32x16/F64x4/F64x8` capability 断言从“总是 native”收正为“NEON 复用 scalar，否则仍要求 native”
- 本批 fresh 复验：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前结果：
  - helper summary 更新为 `NONX86_HELPER_SEMANTICS_SUMMARY checks=601 status=ok`
  - `backend=neon` truthfulness 更新为 `assignments=357 asm_exact=233 asm_suffix_only=10 wrapper_only=114 scalar_passthrough=0 no_def=0 miswired=0 conflicting assign=0`
  - `backend=riscvv` 保持 `assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 conflicting assign=0`
  - `impl-audit-nonx86` 继续为绿，summary 为 `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `check` 继续为绿
  - Release `gate` 已明确到尾屏 `GATE OK`
  - `gate` 尾部仍只诚实保留两项 optional skip：
    - non-x86 native evidence root not present
    - 历史 `windows_b07_gate.log` evidence verify 失败但仍为 optional
- 收口前会再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-15 NEON No-Asm Wide MinMax Slot-Ownership Cleanup

- 继续沿 `NEON` no-asm ownership 深挖后，这一批改收 wide `Min/Max` slot：
  - `MinF32x8`
  - `MaxF32x8`
  - `MinF32x16`
  - `MaxF32x16`
  - `MinF64x4`
  - `MaxF64x4`
  - `MinF64x8`
  - `MaxF64x8`
- 这批动手前先做了本地 Pascal probe，没有直接照 `Sqrt` 套模板：
  - 对比了 `Math.Min/Max`
  - 与 no-asm 本地 `if a < b then a else b` / `if a > b then a else b`
  - 覆盖了 `NaN/±0/相等值`
  - 结果一致，因此 wide `Min/Max` 不再是语义例外，可以安全把 no-asm published slot 收回 scalar
- 这批最终分类是：
  - `NEONMin/MaxF32x8`：dead wrapper，可删
  - `NEONMin/MaxF32x16`：asm build 仍需的 source wrapper，保留
  - `NEONMin/MaxF64x4/F64x8`：source graph 或 asm build 仍需的 wrapper，保留
- 本批实现收正：
  - `src/fafafa.core.simd.neon.register.inc`
    - 把 `Min/MaxF32x8/F32x16/F64x4/F64x8` 都改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定
    - `Min/MaxF64x2` 保持 backend-owned
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc`
    - 删除 `NEONMinF32x8`
    - 删除 `NEONMaxF32x8`
    - 保留 `NEONMin/MaxF32x16/F64x4/F64x8`
  - `tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
    - 把 `NEONMinF32x8/NEONMaxF32x8` 改成 absent guard
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
    - 新增 `Test_NEON_NoAsmWideMinMaxSlots_Keep_Necessary_Wrappers_But_Reuse_BaseScalar`
    - 同时把两处通用 `Min/MaxF32x8/F32x16/F64x4/F64x8` capability 断言从“总是 native”收正为“NEON 复用 scalar，否则仍要求 native”
- 本批 fresh 复验：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前结果：
  - helper summary 更新为 `NONX86_HELPER_SEMANTICS_SUMMARY checks=603 status=ok`
  - `backend=neon` truthfulness 更新为 `assignments=357 asm_exact=237 asm_suffix_only=10 wrapper_only=110 scalar_passthrough=0 no_def=0 miswired=0 conflicting assign=0`
  - `backend=riscvv` 保持 `assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 conflicting assign=0`
  - `impl-audit-nonx86` 继续为绿，summary 为 `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `check` 继续为绿
  - Release `gate` 已明确到尾屏 `GATE OK`
  - `gate` 尾部仍只诚实保留两项 optional skip：
    - non-x86 native evidence root not present
    - 历史 `windows_b07_gate.log` evidence verify 失败但仍为 optional
- 收口前会再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-15 NEON No-Asm Wide Clamp Slot-Ownership Cleanup

- 继续沿 `NEON` no-asm ownership 深挖后，这一批改收 wide `Clamp` slot，但没有机械照搬 `Sqrt/MinMax`：
  - `ClampF32x8`
  - `ClampF32x16`
  - `ClampF64x2`
  - `ClampF64x4`
  - `ClampF64x8`
- 先用本地 Pascal probe 把关键语义差异做实，再决定收法：
  - `ScalarClampF64x2(NaN, 0, 10)` 会折到 `10.0`
  - no-asm `NEONClampF64x2` 会保留 `NaN`
  - `ScalarClampF64x2(-0, 0, 0)` 会归一成 `+0`
  - no-asm `NEONClampF64x2` 会保留 `-0`
  - 结论：`F64x2` 不是 scalar truth，`F64x4/F64x8` 也不能一起回 scalar
- 这批最终分类：
  - `NEONClampF32x8/F32x16`：dead wrapper，可删，slot 应回 scalar
  - `NEONClampF64x2`：本地 fallback 叶子，继续 backend-owned
  - `NEONClampF64x4/F64x8`：继续消费 `F64x2` 本地 fallback，继续 backend-owned
- 本批实现收正：
  - `src/fafafa.core.simd.neon.register.inc`
    - 把 `ClampF32x8/F32x16` 改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定
    - 保留 `ClampF64x2/F64x4/F64x8` 的 backend-owned 绑定
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc`
    - 删除 `NEONClampF32x8`
    - 删除 `NEONClampF32x16`
    - 保留 `NEONClampF64x2/F64x4/F64x8`
  - `tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
    - 把 `NEONClampF32x8/F32x16` 改成 absent guard
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
    - 新增 `Test_NEON_NoAsmWideClampSlots_Reuse_BaseScalar_Only_For_F32Forwarders_And_Keep_F64LocalFallback`
    - 同时把两处通用 `ClampF32x8/F32x16` capability 断言从“总是 native”收正为“NEON 复用 scalar，否则仍要求 native”
- 本批 fresh 复验：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前结果：
  - helper summary 更新为 `NONX86_HELPER_SEMANTICS_SUMMARY checks=605 status=ok`
  - `backend=neon` truthfulness 更新为 `assignments=357 asm_exact=239 asm_suffix_only=10 wrapper_only=108 scalar_passthrough=0 no_def=0 miswired=0 conflicting assign=0`
  - `backend=riscvv` 保持 `assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 conflicting assign=0`
  - `impl-audit-nonx86` 继续为绿，summary 为 `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `check` 继续为绿
  - Release `gate` 已明确到尾屏 `GATE OK`
  - `gate` 尾部仍只诚实保留两项 optional skip：
    - non-x86 native evidence root not present
    - 历史 `windows_b07_gate.log` evidence verify 失败但仍为 optional
- 收口前已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入提交。

## 2026-05-15 Register Truthfulness Allowlist Hygiene Tightening

- 续接上一批 `Clamp` 收口后，先核对当前工作树，确认本轮开始时源码仍干净，只有 `tests/fafafa.core.simd/__pycache__/` 需要在收口前清理。
- 继续深挖 `NEON wrapper_only` 余量时，发现更高价值的缺口已经不在 backend 代码，而在 `check_nonx86_register_truthfulness.py` 自己：
  - 当前 `NEON` allowlist 有 `134` 项
  - 当前真实 `wrapper_only` 只有 `108` 个唯一 slot
  - `unused_allowlist=26`
  - `RISCVV` 则是 `26/26` 完全对齐
- 这说明 checker 还在对一批已经修掉的 `NEON` slot 过度宽容，属于“检查器比源码现实更松”的残余冗余。
- 已完成代码修正：
  - 从 `ALLOWED_WRAPPER_SLOTS_BY_BACKEND['neon']` 删除 26 个 stale allowlist 名字：
    - `ClampF32x8/F32x16`
    - `LoadF32x8/F32x16/F64x4/F64x8`
    - `MinF32x8/F64x4`
    - `MaxF32x8/F64x4`
    - `SplatF32x8/F32x16/F64x4/F64x8`
    - `SqrtF32x8/F32x16/F64x4/F64x8`
    - `StoreF32x8/F32x16/F64x4/F64x8`
    - `ZeroF32x8/F32x16/F64x4/F64x8`
  - checker report 新增：
    - `allowed_wrapper_slot_count`
    - `current_wrapper_only_slot_count`
    - `current_wrapper_only_slots`
    - `unused_allowlist_count`
    - `unused_allowlist_slots`
  - `render_summary_line` 与 human report 都已输出 `unused_allowlist`
  - `ok/exit_code` 现在同时要求：
    - `miswired_count == 0`
    - `unused_allowlist_count == 0`
- 这次收口的目标不是压低 `wrapper_only` 数字，而是把 allowlist 卫生也变成自动门禁，防止以后再出现“代码已修，豁免名单却没收”的假绿。
- 本批 fresh 复验已经完成：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前结果：
  - `backend=neon` truthfulness：`assignments=357 asm_exact=239 asm_suffix_only=10 wrapper_only=108 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `backend=riscvv` truthfulness：`assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `check` 继续为绿
  - Release `gate` 继续为绿，尾部结论不变：
    - non-x86 native evidence root not present -> optional `SKIP`
    - 历史 `windows_b07_gate.log` evidence verify 失败 -> optional `SKIP`

## 2026-05-15 NEON No-Asm Narrow I16/U16 Shift Slot-Ownership Cleanup

- 在 `NEON` allowlist hygiene 收口后，先做了两类定量复核：
  - `ALLOWED_ALWAYS_ASM_HELPER_SLOTS_BY_BACKEND` 当前没有 stale 豁免，`riscvv` 的 `9/9` 仍对齐
  - `NEON wrapper_only` 分组里只剩 5 个 `no-asm + scalar_forwarder`
- 这 5 个 narrow shift slot 是：
  - `ShiftLeftI16x8`
  - `ShiftLeftU16x8`
  - `ShiftRightArithI16x8`
  - `ShiftRightI16x8`
  - `ShiftRightU16x8`
- 全仓检索确认：
  - 它们只出现在 `neon.register.inc`、`neon.scalar.autowrap.inc` 和 `neon.pas`
  - no-asm 下都只是 exact `ScalarShift*` forwarder
  - 没有任何更宽 no-asm source consumer
  - asm build 里仍有真实 owner
- 本批实现收正：
  - `src/fafafa.core.simd.neon.register.inc`
    - 把这 5 个 slot 改成 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 绑定
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc`
    - 删除 `NEONShiftLeftI16x8`
    - 删除 `NEONShiftLeftU16x8`
    - 删除 `NEONShiftRightArithI16x8`
    - 删除 `NEONShiftRightI16x8`
    - 删除 `NEONShiftRightU16x8`
  - `tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
    - 把这 5 个名字改成 absent guard
  - `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
    - 从 `NEON` wrapper allowlist 删除这 5 个旧名字
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
    - 新增 `Test_NEON_NoAsmNarrowI16U16ShiftSlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders`
- 本批 fresh 复验已经完成：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前结果：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=610 status=ok`
  - `backend=neon` truthfulness：`assignments=357 asm_exact=244 asm_suffix_only=10 wrapper_only=103 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `backend=riscvv` truthfulness：`assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `check` 继续为绿
  - Release `gate` 继续为绿，尾部仍只诚实保留：
    - non-x86 native evidence root not present -> optional `SKIP`
    - 历史 `windows_b07_gate.log` evidence verify 失败 -> optional `SKIP`
- 这批完成后，`NEON` 当前 `wrapper_only` 里已经不再剩 `no-asm + scalar_forwarder` 残余。

## 2026-05-15 Register Truthfulness Mixed-Body Classification Fix

- 继续往 `check_nonx86_register_truthfulness.py` 本身深挖后，抓到的不是新的 backend 残余，而是 checker 对 mixed body 的真实误判：
  - worktree 当前未提交内容集中在 `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
  - 新增 fixture 目录为 `tests/fafafa.core.simd/fixtures/nonx86_register_truthfulness/mixed/`
  - 另有 `tests/fafafa.core.simd/__pycache__/` 需要在提交前清理
- 已定位旧逻辑的精确缺口：
  - `collect_symbol_facts(...)` 会为同名非 assembler 定义积累多份 `bodies`
  - 旧版 `detect_wrapper_kind(...)` 直接把所有 body 拼成一个字符串
  - 因此只要任一 body 含有 `Scalar*` 调用，整个 target 就会被压成 `scalar_forwarder`
- 真实 witness 已在源码中坐实：
  - `src/fafafa.core.simd.neon.pas` 里的 `NEONSelectF32x4` 是本地 per-lane Pascal 实现
  - `src/fafafa.core.simd.neon.scalar.utility.inc` 里的同名 `NEONSelectF32x4` 只是 `ScalarSelectF32x4` forwarder
  - 旧逻辑会把它误判成 `('wrapper_only', 'scalar_forwarder', None)`；修正后当前分类已回到 `('wrapper_only', 'pascal_owned', None)`
- 本批代码修正已落地：
  - `parse_args()` 的 `--fixture` 选项已扩到 `good/bad/shadowed/mixed`
  - 新增 `classify_wrapper_body(...)`
  - `detect_wrapper_kind(...)` 改成逐 body 归类，并采用：
    - 任一 `pascal_owned` 即整体 `pascal_owned`
    - 否则若存在 asm helper body，则为 `asm_helper_forwarder`
    - 仅当所有 body 都是 scalar forwarder 时，才为 `scalar_forwarder`
  - 新增 `fixtures/nonx86_register_truthfulness/mixed/mock.backend.pas`
  - 新增 `fixtures/nonx86_register_truthfulness/mixed/mock.backend.register.inc`
- `mixed` fixture 的当前行为已符合预期：
  - 仍然 FAIL
  - 但失败原因现在是 `wrapper-only-bound-inside-asm-block`
  - 不再因为 body 拼接误判成 scalar-forwarder 相关路径
- 本批 fresh 复验已经完成：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --fixture good --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --fixture bad --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --fixture shadowed --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --fixture mixed --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 当前结果：
  - `NEONSelectF32x4` 当前已回到 `wrapper_only + pascal_owned`
  - `NEON` wrapper-only 分组当前为：
    - `('always', 'pascal_owned') = 36`
    - `('asm-only', 'pascal_owned') = 16`
    - `('asm-only', 'scalar_forwarder') = 15`
    - `('no-asm', 'pascal_owned') = 36`
  - 相比修复前，`asm-only + scalar_forwarder` 已从 `16` 降到 `15`
  - `backend=neon` truthfulness 继续保持：`assignments=357 asm_exact=244 asm_suffix_only=10 wrapper_only=103 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `backend=riscvv` truthfulness 继续保持：`assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `check` / `gate` 继续为绿
  - `gate` 尾部仍只诚实保留：
    - non-x86 native evidence root not present -> optional `SKIP`
    - 历史 `windows_b07_gate.log` evidence verify 失败 -> optional `SKIP`
- 收口前已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 缓存目录进入本批 commit。

## 2026-05-15 NEON Extract/Insert/Select Scalar-Only Slot Cleanup

- 接手上一批 mixed-body checker 修复后的真实工作树，确认未提交改动集中在：
  - `src/fafafa.core.simd.neon.register.inc`
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc`
  - `tests/fafafa.core.simd/check_nonx86_helper_semantics.py`
  - `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
- 先对 `dispatchapi` 做作用域收口：
  - 修正 `Test_NativeNarrowHelperSurfaceParity_WithVectorAsm_IfAvailable` 的本地 `AssertBackendOwnedSlotIfExpected`
  - 修正 `Test_NativeWideInsertHelperParity_WithVectorAsm_IfAvailable` 的本地 `AssertBackendOwnedFloatSlotIfExpected`
  - 修正 `Test_NativeNarrowIntegerCoreParity_WithVectorAsm_IfAvailable` 与 `Test_NativeNarrowIntegerHelperParity_WithVectorAsm_IfAvailable` 的本地 `AssertBackendOwnedSlotIfExpected`
  - 把新 testcase 收尾里误用的 `InvalidateSimdDataPlane` 改成公开 `RebindSimdDataPlane`，并补上 `fafafa.core.simd.dataplane` uses
- 先做快速静态复核：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_helper_semantics.py tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
  - 结果：通过
- 再做 checker 真值链：
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - 结果：
    - `NONX86_HELPER_SEMANTICS_SUMMARY checks=625 status=ok`
    - `backend=neon assignments=342 asm_exact=244 asm_suffix_only=10 wrapper_only=88 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
    - `backend=riscvv assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
- 串行 release 验证链全部通过：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 本批关键结果：
  - mixed-body 修正后残余的 `NEON asm-only + scalar_forwarder` 15 个 slot 已全部收掉
  - `backend=neon wrapper_only` 从 `103` 降到 `88`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip ... status=ok`
  - Release `gate` 继续 `OK`，尾部仍只诚实保留 optional non-x86 native evidence skip 与历史 `windows_b07_gate.log` evidence skip
- 收口前已清理 `tests/fafafa.core.simd/__pycache__/`

## 2026-05-15 NEON No-Asm Narrow F64 Sqrt Slot Cleanup

- 继续沿上一批 compare/simple reduction 收口后的真实工作树推进，先确认未提交改动集中在：
  - `src/fafafa.core.simd.neon.register.inc`
  - `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - 以及提交前要清理的 `tests/fafafa.core.simd/__pycache__/`
- 为避免并发重开 SIMD 测试链，这一批先守住已有 `gate` 会话单线程重跑，并补做源码级复核：
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc` 中 `NEONSqrtF64x2` 是逐 lane `Sqrt`
  - `NEONSqrtF64x4` 则仍通过两次 `NEONSqrtF64x2` 组装
  - `src/fafafa.core.simd.scalar.pas` 中 `ScalarSqrtF64x2/ScalarSqrtF64x4` 与其同义
  - 但 `ScalarFloor/Ceil/Round/TruncF64x2` 明确带 `NaN/Inf` guard，且 `Round/Trunc` 还要做 signed-zero 归一化
  - no-asm `NEONFloor/Ceil/Round/TruncF64x2` 只是直接 `Floor/Ceil/Round/Trunc`
  - 因此这批只能先收 `SqrtF64x2`，不能顺手把 `Ceil/Floor/Round/TruncF64x2` 也一起回 scalar
- 已完成代码修正：
  - `src/fafafa.core.simd.neon.register.inc`
    - 把 `table.SqrtF64x2 := @NEONSqrtF64x2;` 收进 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}`
    - `table.SqrtF64x4 := @NEONSqrtF64x4;` 继续保持 asm-only 绑定
  - `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
    - 从 `ALLOWED_WRAPPER_SLOTS_BY_BACKEND['neon']` 删除 `SqrtF64x2`
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
    - 新增 `Test_NEON_NoAsmNarrowF64SqrtSlot_Keep_SourceCompanion_But_Reuse_BaseScalar`
    - 断言 `NEONSqrtF64x2/NEONSqrtF64x4` wrapper 仍在 source 中
    - 断言 asm binding source 仍保留
    - 断言 no-asm 下 `sbNEON.SqrtF64x2` 与 `sbNEON.SqrtF64x4` 都复用 scalar slot
- 本批 targeted 复验已完成：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- 结果：
  - `backend=neon assignments=342 asm_exact=269 asm_suffix_only=10 wrapper_only=63 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - `backend=riscvv assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
  - 相比上一批 `wrapper_only=64`，这一批正好只再减少 1 个 slot，即 `SqrtF64x2`
- 这一批还额外踩到一个卫生坑：
  - 为了 probe `Ceil/FloorF64x2` 语义差异，临时 `fpc` 编译一度把 `.o/.ppu` 落进 `src/`
  - 这会让 `gate` 的 `6/6 Filtered run_all check chain` 直接在源码树卫生处失败
  - 已使用 `find src -maxdepth 1 \( -name '*.o' -o -name '*.ppu' \) -print -delete` 清理
- 在清理完卫生产物后，继续守住同一个 `gate` 会话串行重跑，最终尾屏通过：
  - `run_all` 过滤链结果为 `Total: 5 Passed: 5 Failed: 0`
  - Release `gate` 最终 `GATE OK`
  - `gate` 尾部仍只诚实保留：
    - non-x86 native evidence root not present -> optional `SKIP`
    - 历史 `windows_b07_gate.log` evidence verify 失败 -> optional `SKIP`

## 2026-05-16 NEON No-Asm Narrow F64 Round-Family Slot/Fallback Alignment

- 接着上一批 `SqrtF64x2` 收口继续扫 residual 时，先重新核了 `src/` 里的真实消费图，发现 `Ceil/Floor` 和 `Round/Trunc` 不能再混看：
  - `NEONRoundF64x4` / `NEONTruncF64x4` 仍在 `autowrap` 中通过两次 `NEONRound/TruncF64x2` 组装
  - `NEONFloor/CeilF64x4/F64x8` 的 no-asm wrapper 已经不存在，只剩 asm 叶子
  - 因此 `NEONFloor/CeilF64x2` 已没有任何 no-asm source consumer，而 `NEONRound/TruncF64x2` 仍是 live source companion
- 在这层 source role 拆清后，本批实现分成了两段：
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc`
    - 删除 dead `NEONCeilF64x2`
    - 删除 dead `NEONFloorF64x2`
    - 把 `NEONRoundF64x2` 改成 `Result := ScalarRoundF64x2(a);`
    - 把 `NEONTruncF64x2` 改成 `Result := ScalarTruncF64x2(a);`
  - `src/fafafa.core.simd.neon.register.inc`
    - 把 `table.Ceil/Floor/Round/TruncF64x2 := @NEON...` 全部收进 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}`
    - 同时更新注释，把这组 slot 的 no-asm published truth 改成“复用 scalar，只有 asm build 才发布 backend-owned leaf”
  - `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
    - 从 `ALLOWED_WRAPPER_SLOTS_BY_BACKEND['neon']` 删除 `CeilF64x2/FloorF64x2/RoundF64x2/TruncF64x2`
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
    - 新增 `Test_NEON_NoAsmNarrowF64RoundFamilySlots_Keep_Only_Necessary_SourceCompanions_And_Reuse_BaseScalar`
    - 断言 `NEONCeil/FloorF64x2` dead wrapper 已消失
    - 断言 `NEONRound/TruncF64x2` 仍在且源码中已精确对齐 `ScalarRound/TruncF64x2`
    - 断言 `NEONRound/TruncF64x4` 仍消费窄 companion
    - 断言 no-asm runtime 下 `sbNEON` 的 `Ceil/Floor/Round/TruncF64x2` slot 全部复用 scalar
- 本批静态与 checker 复核：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - 结果：
    - `backend=neon assignments=342 asm_exact=273 asm_suffix_only=10 wrapper_only=59 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
    - `backend=riscvv assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
- 本批 release 复验链也全部通过：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IEEE754EdgeCases`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 本批关键结果：
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip ... status=ok`
  - Release `gate` 最终 `GATE OK`
  - `run_all` 过滤链结果仍为 `Total: 5 Passed: 5 Failed: 0`
  - `NEON wrapper_only` 从上一批的 `63` 再降到 `59`

## 2026-05-16 NEON No-Asm Narrow F64 Min/Max Slot/Fallback Alignment

- 接着上一批 `Round/TruncF64x2` 收口继续扫 `F64` residual 时，先重新核对了 `Max/Min` 与 `ReduceMax/ReduceMin` 的 source role：
  - `NEONMax/MinF64x4` 仍通过 `NEONMax/MinF64x2` 组装，所以 `Max/MinF64x2` 只能保留为 source companion
  - `ReduceMax/ReduceMinF64x2` 仍是另一条高风险 reduction 语义链，本批不混入
- 已完成代码修正：
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc`
    - `NEONMaxF64x2` 改成 `Result := ScalarMaxF64x2(a, b);`
    - `NEONMinF64x2` 改成 `Result := ScalarMinF64x2(a, b);`
  - `src/fafafa.core.simd.neon.register.inc`
    - `table.MaxF64x2 := @NEONMaxF64x2;`
    - `table.MinF64x2 := @NEONMinF64x2;`
    - 以上 2 个绑定都已收进 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}`
  - `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
    - 从 `ALLOWED_WRAPPER_SLOTS_BY_BACKEND['neon']` 删除 `MaxF64x2/MinF64x2`
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
    - 新增 `Test_NEON_NoAsmNarrowF64MinMaxSlots_Keep_SourceCompanion_But_Reuse_BaseScalar`
    - 断言 `NEONMax/MinF64x2` wrapper 仍在且 body 已精确对齐 `ScalarMax/MinF64x2`
    - 断言 `NEONMax/MinF64x4` 仍继续消费窄 companion
    - 断言 no-asm runtime 下 `sbNEON.Max/MinF64x2` slot 全部复用 scalar
- 本批静态与 checker 复核：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - 结果：
    - `backend=neon assignments=342 asm_exact=275 asm_suffix_only=10 wrapper_only=57 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
    - `backend=riscvv assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
- 本批 release 复验链全部通过：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IEEE754EdgeCases`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 本批关键结果：
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip ... status=ok`
  - Release `gate` 最终 `GATE OK`
  - `run_all` 过滤链结果仍为 `Total: 5 Passed: 5 Failed: 0`
  - `NEON wrapper_only` 从上一批的 `59` 再降到 `57`
  - 收口前已清理 `tests/fafafa.core.simd/__pycache__/`

## 2026-05-16 NEON No-Asm Narrow F64 Extrema Reduction Slot Cleanup

- 接着上一批 `Min/MaxF64x2` 收口继续扫 `F64` residual 时，先重新核了 `ReduceMax/ReduceMinF64x2` 的 source role：
  - 这两个名字在 `src/` 里只剩 `neon.pas + register.inc + scalar.autowrap.inc`
  - 不像 `Max/MinF64x2`，它们没有任何更宽 no-asm consumer
  - 因此只要语义能和 scalar truth 对齐，这批就应直接删 wrapper，而不是保留 source companion
- 为了避免把 `Math.Max/Min` 的细节想当然，本批先做了一个最小本地 Pascal probe：
  - `NaN,3` -> scalar/no-asm 都是 `3`
  - `3,NaN` -> scalar/no-asm 都是 `NaN`
  - `+0,-0` -> scalar/no-asm 都保留 `-0`
  - `-0,+0` -> scalar/no-asm 都保留 `+0`
  - `eq5,eq5` -> scalar/no-asm 都是 `5`
- 已完成代码修正：
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc`
    - 删除 dead `NEONReduceMaxF64x2`
    - 删除 dead `NEONReduceMinF64x2`
  - `src/fafafa.core.simd.neon.register.inc`
    - `table.ReduceMaxF64x2 := @NEONReduceMaxF64x2;`
    - `table.ReduceMinF64x2 := @NEONReduceMinF64x2;`
    - 以上 2 个绑定都已收进 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}`
  - `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
    - 从 `ALLOWED_WRAPPER_SLOTS_BY_BACKEND['neon']` 删除 `ReduceMaxF64x2/ReduceMinF64x2`
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
    - 新增 `Test_NEON_NoAsmNarrowF64ExtremaReductionSlots_Reuse_BaseScalar_When_Wrappers_Have_No_SourceConsumers`
    - 断言 `NEONReduceMax/ReduceMinF64x2` dead wrapper 已从 source 消失
    - 断言 asm binding source 仍保留
    - 断言 no-asm runtime 下 `sbNEON.ReduceMax/ReduceMinF64x2` slot 复用 scalar
  - `tests/fafafa.core.simd/fafafa.core.simd.ieee754.testcase.pas`
    - 新增 `Test_F64_ReduceMinMax_SpecialCases`
    - 把当前 scalar `ReduceMin/MaxF64x2` 的 `NaN` 与 `+0/-0` 次序语义固定成 suite 证据
- 本批静态与 checker 复核：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - 结果：
    - `backend=neon assignments=342 asm_exact=277 asm_suffix_only=10 wrapper_only=55 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
    - `backend=riscvv assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
- 本批 release 复验链全部通过：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IEEE754_F64`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 本批关键结果：
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip ... status=ok`
  - Release `gate` 最终 `GATE OK`
  - `run_all` 过滤链结果仍为 `Total: 5 Passed: 5 Failed: 0`
  - `NEON wrapper_only` 从上一批的 `57` 再降到 `55`
  - 收口前已清理 `tests/fafafa.core.simd/__pycache__/` 与本地临时 Pascal probe

## 2026-05-16 NEON No-Asm F64 Sqrt/Round/Trunc Dead-Wrapper Cleanup

- 继续沿 `NEON` no-asm `F64` residual 审查时，先全仓复核 `NEONRound/Sqrt/TruncF64x2/F64x4`：
  - 命中只剩 `src/fafafa.core.simd.neon.scalar.autowrap.inc`
  - `src/fafafa.core.simd.neon.register.inc`
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - `src/fafafa.core.simd.neon.pas` 的 asm owner
- 结论确认：
  - `F64x4` no-asm wrapper 已不再被任何更宽 no-asm graph 消费
  - 因而 `F64x2` companion 也同时失去 live source-consumer
  - 这一簇不再是“保留 companion、收回 slot ownership”，而是完整的 dead-wrapper 删除批
- 已完成代码改动：
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc`
    - 删除 `NEONRoundF64x2`
    - 删除 `NEONRoundF64x4`
    - 删除 `NEONSqrtF64x2`
    - 删除 `NEONSqrtF64x4`
    - 删除 `NEONTruncF64x2`
    - 删除 `NEONTruncF64x4`
  - `src/fafafa.core.simd.neon.register.inc`
    - 把误导性的 `Round/Trunc` 注释改成“no-asm wrappers are fully dead; only asm builds publish backend-owned bindings”
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
    - 4 个 dedicated 护栏改名并收正为 dead-wrapper 口径
    - `NarrowF64Sqrt`
    - `NarrowF64RoundFamily`
    - `WideSqrt`
    - `WideRoundTrunc`
    - 断言统一改成：
      - wrapper absent in `autowrap`
      - asm binding source still present in `register.inc`
      - no-asm runtime slot equals scalar slot
- 本批静态与 checker 验证：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - 结果：
    - `backend=neon assignments=342 asm_exact=277 asm_suffix_only=10 wrapper_only=55 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
    - `backend=riscvv assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
- 本批 Release 验证全部通过：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IEEE754EdgeCases`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 本批关键结果：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=643 status=ok`
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `gate` 最终 `GATE OK`
  - `run_all` 过滤链结果仍为 `Total: 5 Passed: 5 Failed: 0`
  - 收口前已再次清理 `tests/fafafa.core.simd/__pycache__/`

## 2026-05-16 NEON No-Asm Wide Integer Compare Slot-Ownership Cleanup

- 继续沿 `NEON` no-asm residual 审查时，这次先把 wide integer compare 单独拎出来复核，而不是继续混在旧的大整数 fallback 护栏里：
  - `CmpEq/Ge/Gt/Le/Lt/Ne`
  - `I32x8/I32x16`
  - `I64x4/I64x8`
  - `U32x8/U64x4`
  - 共 36 个 slot
- 已确认旧真相问题：
  - `src/fafafa.core.simd.neon.register.inc` 之前无条件绑定这 36 个 `table.Cmp* := @NEONCmp*`
  - `src/fafafa.core.simd.neon.scalar.autowrap.inc` 的 wide compare no-asm body 只是组合更窄 helper，没有独立 backend-local truth
  - `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 之前也只是把它们整个塞进 generic `NEON` wrapper allowlist
- 已完成代码修正：
  - `src/fafafa.core.simd.neon.register.inc`
    - 将这 36 个 wide compare 绑定全部收进 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}`
    - 注释改成“wrapper 仍保留 source companion 角色，但 published slot ownership 只有 asm build 才成立”
  - `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
    - 旧的 `NEON_WIDE_COMPARE_WRAPPER_SLOTS` 已改成 `NEON_WIDE_COMPARE_ASM_ONLY_WRAPPER_SLOTS`
    - 新增 `ALLOWED_ASM_ONLY_WRAPPER_SLOTS_BY_BACKEND['neon']`
    - `wrapper_only` 规则已收正为：
      - generic allowlist 继续允许既有 asm-only float wrapper
      - wide compare 这 36 个名字只允许在 asm-only 上下文命中
    - report 现在也会单独输出 `allowed_asm_only_wrapper_slot_count/current_asm_only_wrapper_slot_count`
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
    - 新增 `Test_NEON_NoAsmWideIntegerCompareSlots_Keep_SourceCompanions_But_Reuse_BaseScalar`
    - 新护栏固定三层 truth：
      - wide compare wrapper/source companion 仍在 `autowrap`
      - asm binding source 仍在 `register.inc`
      - no-asm runtime 下 `sbNEON.Cmp*` slot 全部复用 scalar
    - 旧 `Test_NEON_NoAsmIntegerFallbackSlots_Reuse_BaseScalar_When_Wrappers_Are_Not_BackendOwned` 里的 compare 断言已全部拆出，不再混成“大整数 fallback”一锅
- 本批中途出现的唯一真实偏差：
  - 首轮 checker 规则收得太窄，把 16 个既有的 NEON `asm-only wrapper_only` float slot 一并报成 miswired
  - 已立即收正为“asm-only 时，generic allowlist 和 compare 专属 asm-only allowlist 都可合法命中”
- 本批静态与 checker 复核：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - 结果：
    - `backend=neon assignments=342 asm_exact=277 asm_suffix_only=10 wrapper_only=55 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
    - `backend=riscvv assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 scalar_passthrough=0 no_def=0 miswired=0 unused_allowlist=0 strict=1`
- 本批 release 复验链全部通过：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 本批关键结果：
  - `NONX86_IMPL_AUDIT_SUMMARY steps=6 native_evidence=skip targeted_output_root=/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd status=ok`
  - Release `gate` 最终 `GATE OK`
  - `run_all` 过滤链结果仍为 `Total: 5 Passed: 5 Failed: 0`
  - 这批没有继续降低 `wrapper_only` 数量，但把 36 个 wide compare slot 的 no-asm published ownership 真相纠正回了 scalar
  - 收口前已再次清理 `tests/fafafa.core.simd/__pycache__/`

## 2026-05-16 Non-x86 Wrapper Context Truthfulness Checker Hardening

- 接手当前工作树时，未提交改动已只剩：
  - `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
  - 以及需清理的 `tests/fafafa.core.simd/__pycache__/`
- 先把 `__pycache__` 清掉，确保这批提交只承载 checker 自身的真值加固，不混入 Python 产物。
- 这批继续深审时，发现前面几轮虽然已经把不少 `NEON`/`RISCVV` published ownership 收正了，但 checker 自身仍有语义盲区：
  - 旧版只知道“generic wrapper allowlist”与“asm-only allowlist”
  - 不知道 `wrapper_only` 还存在合法的 `no-asm` 分支
  - 也不能把 `always` 与 `asm-only` 的 companion wrapper 区分开
- 已完成的 checker 收紧：
  - 新增 `NEON_FACADE_ASM_ONLY_WRAPPER_SLOTS`
  - 新增 `RISCVV_SELECT_ASM_ONLY_WRAPPER_SLOTS`
  - 新增 `NEON_NO_ASM_ONLY_WRAPPER_SLOTS`
  - 新增 `RISCVV_EXTRACT_NO_ASM_ONLY_WRAPPER_SLOTS`
  - 旧 allowlist 已拆成三类：
    - `ALLOWED_ALWAYS_WRAPPER_SLOTS_BY_BACKEND`
    - `ALLOWED_ASM_ONLY_WRAPPER_SLOTS_BY_BACKEND`
    - `ALLOWED_NO_ASM_ONLY_WRAPPER_SLOTS_BY_BACKEND`
  - `build_reason_list()` 现在会按 assignment `context` 精确判断 `wrapper_only` 是否合规
  - human/json report 现在也会直接输出 `always wrapper ok / asm-only wrapper ok / no-asm wrapper ok`
- 这批明确编码进去的新真相：
  - `NEON ClampF64x2/F64x4/F64x8` 是合法 `no-asm wrapper-only`
  - `RISCVV Extract*` 是合法 `no-asm wrapper-only`
  - `NEON` wide float/select/andnot 与 wide integer compare 是合法 `asm-only wrapper-only`
  - `RISCVV SelectF32x8/SelectF64x4/SelectI32x4` 是合法 `asm-only wrapper-only`
- 当前这批的 fresh strict 结果已与源码真相对齐：
  - `backend=neon assignments=342 asm_exact=277 asm_suffix_only=10 wrapper_only=55 miswired=0 unused_allowlist=0`
  - `backend=neon context split: always=0 asm-only=52 no-asm=3`
  - `backend=riscvv assignments=473 asm_exact=330 asm_suffix_only=117 wrapper_only=26 miswired=0 unused_allowlist=0`
  - `backend=riscvv context split: always=14 asm-only=3 no-asm=9`
- 沿用本批源码状态下刚完成的复验结果：
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：全部通过；`gate` 最终仍是 `GATE OK`
- 当前阶段结论：
  - 这批没有改 backend/source 行为，只是把 non-x86 truthfulness checker 从“两态 allowlist”收紧成“三态上下文模型”
  - 这样后续继续扫 residual 时，不会再把 `ClampF64*`、`RISCVV Extract*` 之类合法 wrapper-only 错当问题，也不会把真正的 branch-owned 漏洞藏在过宽的豁免里

## 2026-05-16 RISCVV Helper-Owned Exact-Scalar Slot Ownership Guard

- 收完上一批 checker 三态模型之后，继续往 `RISCVV always wrapper-only=14` 深挖，优先排除了已明确有专门护栏的 `DotF64x2/F64x4`。
- 进一步对照 `src/fafafa.core.simd.riscvv.helpers.inc`、`src/fafafa.core.simd.riscvv.register.inc` 与现有 `DispatchAPI` 测试后，定位到新的真实缺口：
  - `AndNotI64x2/MinI64x2/MaxI64x2/AndNotU64x2/CmpEqU64x2/CmpLtU64x2/CmpGtU64x2/MinU64x2/MaxU64x2/AndNotI8x16/AndNotU16x8/AndNotU8x16`
  - 这些 slot 在 no-asm source 里都是 exact scalar helper forwarder
  - 但 register 仍有意保持 backend-owned 绑定
  - 现有 suite 之前只覆盖了其中个别 representative slot，没有把这整簇 policy 固定成 dedicated truth
- 已完成代码修正：
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
    - 新增 `Test_RISCVV_HelperOwnedExactScalarSlots_Stay_BackendOwned`
    - 该测试同时固定三层事实：
      - `helpers.inc` 里 12 个 slot 的 exact scalar helper body 仍存在
      - `register.inc` 里 12 个 slot 仍保持 `table.* := @RISCVV*` backend-owned 绑定
      - runtime `sbRISCVV` dispatch table 上 12 个 slot 仍不复用 scalar 指针
- 本批 `Release` 串行验证已 fresh 跑通：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- 关键结果：
  - `TTestCase_DispatchAPI` 通过
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=643 status=ok`
  - `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=20 issues=0 status=ok`
  - Release `check` 通过
  - Release `gate` 通过，最终 `GATE OK`
  - 尾部仍只保留两个已知 optional 项：
    - non-x86 native evidence verify skip
    - 历史 `windows_b07_gate.log` evidence verify optional skip
- 当前阶段结论：
  - 这批仍然没有改 backend 行为，而是补上了 `RISCVV` 一簇 exact-scalar helper-owned slot 的缺失护栏
  - 下一轮如果继续深审，优先目标应是继续找“还有哪些 non-x86 ownership policy 只存在于 allowlist/口头理解、但没有 dedicated source+register+runtime 证据”的簇，而不是回头重开已经固定边界的 `ClampF64*`

## 2026-05-16 Non-x86 Key-Slot Audit Coverage Expansion

- 按改进后的工作法，这一批没有再先跑全量 gate，而是先做最小验证：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --summary-line`
- 第一轮最小验证就立刻抓到真实收尾漏点：
  - `NameError: name 'KEY_SLOTS' is not defined`
  - 原因是把脚本改成 `KEY_SLOTS_BY_BACKEND` 后，`collect_expected_slot_modes_from_dispatchapi()` 里还残留了一处旧变量引用
- 修掉这处残留后，再跑同一组最小验证，`key-slot-audit` 已成功把新 truth 吃进去：
  - `backend=neon ok slots=10`
  - `backend=riscvv ok slots=22`
  - `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=32 issues=0 status=ok`
  - 输出中已直接列出：
    - `AndNotI64x2`
    - `MinI64x2`
    - `MaxI64x2`
    - `AndNotU64x2`
    - `CmpEqU64x2`
    - `CmpLtU64x2`
    - `CmpGtU64x2`
    - `MinU64x2`
    - `MaxU64x2`
    - `AndNotI8x16`
    - `AndNotU16x8`
    - `AndNotU8x16`
- 之后只补跑了新方法下的最小必要 `Release` 验证：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - 结果通过
  - 其中 `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=32 issues=0 status=ok`
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=643 status=ok`
- 当前阶段结论：
  - 这批把我们刚补上的 `RISCVV` helper-owned ownership truth，正式抬进了 Python 常规门禁
  - 也是这轮里第一次明确验证了新工作法有效：先最小验证，立刻抓漏，再最小补验，不再先跑整轮 `gate`

## 2026-05-16 RISCVV Select Key-Slot Explicit Ownership Coverage

- 继续沿同一条 `RISCVV` ownership 审查线往下切时，先没有再大面积扫 `Extract*`，而是直接核对当前最像真缺口的一簇：
  - `SelectF32x8`
  - `SelectF64x4`
  - `SelectI32x4`
- 先用现有源码与测试事实收敛判断：
  - `check_nonx86_register_truthfulness.py` 已明确把这 3 个 slot 归类成合法 `asm-only wrapper-only`
  - `dispatchapi` dedicated `RISCVV` wide fallback test 里之前只显式钉住了 `SelectF64x4`
  - `check_nonx86_key_slot_audit.py` 之前完全没把这 3 个 slot 当 key-slot
- 已完成的最小修复：
  - `tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`
    - 把 `SelectF32x8/SelectF64x4/SelectI32x4` 纳入 `KEY_SLOTS_BY_BACKEND['riscvv']`
    - 同步纳入 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['riscvv']`
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
    - 在 `Test_RISCVV_WideFallbackOnlySlots_Reuse_BaseScalar_When_Wrappers_Are_Only_ScalarForwarders` 中补齐这 3 个 slot 的 `AssertRegisterOwnsBackendSlot`
    - 同时补齐 runtime ownership 断言：asm-compiled 时必须 backend-owned，否则回退 scalar
- 本批按新工作法执行的最小验证链：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `backend=riscvv ok slots=25`
  - `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=35 issues=0 status=ok`
  - Release `TTestCase_DispatchAPI` 通过
  - Release `check` 通过
- 当前阶段结论：
  - 这批没有改 backend 行为，而是把 `RISCVV Select*` 这 3 个关键位点从“allowlist 隐性知识”提升成了 Python 审计与 dedicated testcase 的显性真相
  - 收口前仍需清理 `tests/fafafa.core.simd/__pycache__/`，避免把 Python 产物带进提交

## 2026-05-16 RISCVV Extract Companion Ownership Coverage

- 接着上一批 `Select*` 再往下切时，没有直接假设 `Extract*` 该复用同一种修法，而是先把真实 source role 读清：
  - `src/fafafa.core.simd.riscvv.facade.inc`
    - `RISCVVExtractF32x8/F32x16/F64x2/F64x4/I32x4/I32x8/I32x16/I64x2/I64x4`
    - no-asm 侧全部是 exact `ScalarExtract*` companion wrapper
  - `src/fafafa.core.simd.riscvv.pas`
    - 同名 wrapper 在 asm-enabled 侧继续做索引饱和并调用 `RISCVVExtract*Asm`
  - `src/fafafa.core.simd.riscvv.register.inc`
    - 每个 `Extract*` 都保留显式 `{$IFDEF RISCVV_ASSEMBLY}` / `{$ELSE}` 双分支绑定
- 这说明真实 policy 不是“应退回 scalar”，而是：
  - asm 侧保持 helper-backed wrapper
  - no-asm 侧保持 exact scalar companion wrapper
  - published runtime slot 继续 backend-owned
- 第一轮最小验证没有先跑 `Release`，而是只跑：
  - `python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend riscvv --summary-line`
- 这一条立刻抓到真实审计缺口：
  - `backend=riscvv issues=9`
  - `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=riscvv slots=34 issues=9 status=fail`
  - 问题不是 register 漏绑，而是旧 key-slot audit 模型把这些合法 `no-asm scalar_forwarder companion wrapper` 误判成异常
- 已完成的代码收口：
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
    - 新增 `Test_RISCVV_ExtractSlots_Keep_NoAsmCompanionWrappers_And_RuntimeOwnership`
    - 固定四层真相：
      - facade no-asm source 仍是 exact `ScalarExtract*`
      - asm source 仍调用 `RISCVVExtract*Asm`
      - register source 仍保留双分支 wrapper 绑定
      - runtime `sbRISCVV` dispatch slot 仍不同于 scalar 指针
  - `tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`
    - 把 9 个 `Extract*` 纳入 `KEY_SLOTS_BY_BACKEND['riscvv']`
    - 把新 testcase 纳入 `EXPECTATION_PROCEDURES['riscvv']`
    - 把这 9 个 slot 纳入 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['riscvv']`
    - 新增 `ALLOWED_BACKEND_OWNED_NO_ASM_SCALAR_WRAPPER_SLOTS_BY_BACKEND['riscvv']`
    - 让 key-slot audit 显式接受这类 mixed-context 合法形态
- 修完审计模型后重新执行的最小验证链：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend riscvv --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `backend=riscvv ok slots=34`
  - `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=44 issues=0 status=ok`
  - Release `TTestCase_DispatchAPI` 通过
  - Release `check` 通过
- 当前阶段结论：
  - 这批没有改 backend 行为，而是把 `RISCVV Extract*` 从“审计模型误报区”收成了显式、可执行、可复验的 ownership truth
  - 收口前已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免把 Python 产物带进提交

## 2026-05-16 RISCVV Dot Key-Slot Audit Lift

- 继续沿同一条 `wrapper_only` 审查线做 residual 对账时，先用一条很小的只读对比确认当前剩余 gap：
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --json --strict`
  - 对照当前 `KEY_SLOTS_BY_BACKEND['riscvv']`
  - 结果：`missing_from_key=['DotF64x2', 'DotF64x4']`
- 这说明当前 `riscvv wrapper_only` policy 位点里，还没进入 `key-slot audit` 常规门禁的只剩 `DotF64x2/F64x4`。
- 因为这两个名字已经有现成 dedicated truth source，所以本批不再扩展 Pascal 测试：
  - `TTestCase_DispatchAPI.Test_RISCVV_FacadeSlots_Reuse_BaseScalar_When_Wrappers_Are_ScalarPassThrough`
    - 已显式固定 `AssertRegisterOwnsBackendSlot('DotF64x2/F64x4', ...)`
    - 已显式固定 runtime `AssertSlotKeepsBackendOwnership('DotF64x2/F64x4', ...)`
- 本批只做了脚本级提升：
  - `tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`
    - 把 `DotF64x2/ DotF64x4` 纳入 `KEY_SLOTS_BY_BACKEND['riscvv']`
    - 同步纳入 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['riscvv']`
- 按脚本批次执行的最小验证链：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend riscvv --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `backend=riscvv ok slots=36`
  - `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=46 issues=0 status=ok`
  - Release `check` 通过
- 当前阶段结论：
  - 这批没有改 backend 行为，也没有新建 testcase，只是把最后一对 `RISCVV Dot*` `wrapper_only` policy 位点正式抬进了 `check` 常规门禁
  - 收口前已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 产物带进提交

## 2026-05-16 NEON Clamp Key-Slot Audit Lift

- 按改进后的工作法，这一批先没有再跑 `gate` 或 Pascal suite，而是先用两条最小证据确认 gap：
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --json --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend neon --summary-line`
- 第一条直接确认当前 `NEON` 的 residual 已经缩到：
  - `current_no_asm_wrapper_slots = ['ClampF64x2', 'ClampF64x4', 'ClampF64x8']`
  - 也就是 `wrapper_only=55` 里唯一 3 个 `no-asm wrapper-only`
- 第二条则确认旧 key-slot audit 还停在：
  - `backend=neon ok slots=10`
  - `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon slots=10 issues=0 status=ok`
  - 说明这 3 个 `ClampF64*` 还没有进常规 `check`
- 已完成的最小修复：
  - `tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`
    - 把 `ClampF64x2/F64x4/F64x8` 纳入 `KEY_SLOTS_BY_BACKEND['neon']`
    - 把 `Test_NEON_NoAsmWideClampSlots_Reuse_BaseScalar_Only_For_F32Forwarders_And_Keep_F64LocalFallback` 纳入 `EXPECTATION_PROCEDURES['neon']`
    - 让解析器识别 `AssertAsmBindingStillPresent`
    - 把 `AssertAsmBindingStillPresent` 映射为 `backend_owned`
    - 对 `ClampF64x2/F64x4/F64x8` 开启 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['neon']`
- 本批按脚本批次执行的最小验证链：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend neon --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `backend=neon ok slots=13`
  - `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=49 issues=0 status=ok`
  - Release `check` 通过
- 当前阶段结论：
  - 这批仍然没有改 backend 行为，也没有新建 Pascal testcase，只是把 `NEON ClampF64*` 这 3 个合法 policy 位点正式抬进了 `check` 常规门禁
  - 收口前已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免把 Python 产物带进提交

## 2026-05-16 NEON Wide MinMax Key-Slot Audit Lift

- 继续按“先差异对账、再选最小簇”的工作法往下切时，先没有直接改代码，而是先算清当前 `NEON` 还剩哪些 `wrapper_only` 没进 `key-slot audit`：
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --json --strict`
  - 配合当前 `KEY_SLOTS_BY_BACKEND['neon']` 对账后，确认剩余 `missing_from_key=52`
  - 其中最小且已有现成 dedicated truth source 的一簇是：
    - `MaxF32x16`
    - `MaxF64x8`
    - `MinF32x16`
    - `MinF64x8`
- 已确认现成 truth source 充分存在：
  - `Test_NEON_NoAsmWideMinMaxSlots_Keep_Necessary_Wrappers_But_Reuse_BaseScalar`
  - 已显式固定 `AssertAsmBindingStillPresent(...)`
  - 也已显式固定 runtime `AssertSlotReusesScalar(...)`
- 本批已完成的最小修复：
  - `tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`
    - 把 `MaxF32x16/MaxF64x8/MinF32x16/MinF64x8` 纳入 `KEY_SLOTS_BY_BACKEND['neon']`
    - 把 `Test_NEON_NoAsmWideMinMaxSlots_Keep_Necessary_Wrappers_But_Reuse_BaseScalar` 纳入 `EXPECTATION_PROCEDURES['neon']`
    - 对这 4 个 slot 开启 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['neon']`
- 本批按脚本批次执行的最小验证链：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend neon --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `backend=neon ok slots=17`
  - `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=53 issues=0 status=ok`
  - Release `check` 通过
- 当前阶段结论：
  - 这批仍然没有改 backend 行为，也没有新建 Pascal testcase，只是把 `NEON wide Min/Max` 这 4 个合法 `asm-only wrapper-only` 位点正式抬进了 `check` 常规门禁
  - 收口前已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免把 Python 产物带进提交

## 2026-05-16 NEON Wide Leaf Float Arithmetic Key-Slot Audit Lift

- 继续沿 `NEON asm-only wrapper-only` residual 往下切时，先没有重新扫所有 testcase，而是直接锁定已知最小的现成 dedicated truth source 簇：
  - `AddF32x16`
  - `AddF64x8`
  - `SubF32x16`
  - `SubF64x8`
  - `MulF32x16`
  - `MulF64x8`
  - `DivF32x16`
  - `DivF64x8`
- 已确认现成 truth source 充分存在：
  - `Test_NEON_NoAsmWideLeafFloatArithmeticSlots_Keep_SourceCompanions_But_Reuse_BaseScalar`
  - 已显式固定 `AssertAsmBindingStillPresent(...)`
  - 也已显式固定 runtime `AssertSlotReusesScalar(...)`
- 本批已完成的最小修复：
  - `tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`
    - 把 `Add/Sub/Mul/DivF32x16` 与 `Add/Sub/Mul/DivF64x8` 纳入 `KEY_SLOTS_BY_BACKEND['neon']`
    - 把 `Test_NEON_NoAsmWideLeafFloatArithmeticSlots_Keep_SourceCompanions_But_Reuse_BaseScalar` 纳入 `EXPECTATION_PROCEDURES['neon']`
    - 对这 8 个 slot 开启 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['neon']`
- 本批按脚本批次执行的最小验证链：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend neon --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `backend=neon ok slots=25`
  - `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=61 issues=0 status=ok`
  - Release `check` 通过
- 当前阶段结论：
  - 这批仍然没有改 backend 行为，也没有新建 Pascal testcase，只是把 `NEON wide leaf float arithmetic` 这 8 个合法 `asm-only wrapper-only` 位点正式抬进了 `check` 常规门禁
  - 收口前已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免把 Python 产物带进提交

## 2026-05-16 NEON SelectF32x4 Dedicated Truth Lift

- 继续沿 `NEON` residual 往下切时，没有直接跳去 32 个 integer-compare，而是先核对单点 `SelectF32x4`：
  - `check_nonx86_register_truthfulness.py` 已把它归类为 `asm-only wrapper-only`
  - `src/fafafa.core.simd.neon.pas` 中 asm-enabled `NEONSelectF32x4` 不直接转 `ScalarSelectF32x4`
  - `src/fafafa.core.simd.neon.scalar.utility.inc` 中 no-asm `NEONSelectF32x4` 则明确转到 `ScalarSelectF32x4`
  - `src/fafafa.core.simd.neon.register.inc` 中 `table.SelectF32x4 := @NEONSelectF32x4;` 仅在 `{$IFDEF FAFAFA_SIMD_NEON_ASM_ENABLED}` 下发布
- 这说明当前缺口不是 backend 行为错误，而是 dedicated truth source 还不够收敛：
  - 原 testcase 只检查 asm source
  - runtime/register 事实分散在 generic capability / representative parity 测试里
  - `key-slot audit` 不能直接消费
- 本批已完成的最小修复：
  - 扩展 `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
    - `Test_NEON_SelectF32x4_AsmEnabledSource_Does_Not_ScalarForward`
    - 现在同时固定：
      - asm source 不直接 scalar-forward
      - no-asm scalar companion 仍存在
      - register asm-only binding 仍存在
      - runtime `sbNEON` slot 在 asm-compiled 时 backend-owned、否则回落 scalar
  - `tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`
    - 把 `SelectF32x4` 纳入 `KEY_SLOTS_BY_BACKEND['neon']`
    - 把该 dedicated testcase 纳入 `EXPECTATION_PROCEDURES['neon']`
    - 对 `SelectF32x4` 开启 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['neon']`
- 本批按 Pascal 批次执行的最小验证链：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend neon --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `backend=neon ok slots=26`
  - `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=62 issues=0 status=ok`
  - Release `TTestCase_DispatchAPI` 通过
  - Release `check` 通过
- 当前阶段结论：
  - 这批没有改 backend 行为，而是把 `SelectF32x4` 从“分散 truth”收成了 dedicated truth source，并正式接进 `check` 常规门禁
  - 收口前已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免把 Python 产物带进提交

## 2026-05-16 NEON AndNot Ownership Lift

- 继续沿 `NEON` residual 往下切时，先没有直接进入 32 个 wide integer compare，而是先锁定更小的一簇：
  - `AndNotI8x16`
  - `AndNotU16x8`
  - `AndNotU8x16`
- 已确认这 3 个 slot 的真实结构是：
  - `check_nonx86_register_truthfulness.py` 中都属于 `asm-only wrapper-only`
  - `src/fafafa.core.simd.neon.compare.inc` 中是 backend-local composition，不是 scalar-forward
  - `src/fafafa.core.simd.neon.register.inc` 中在 asm-enabled 下显式发布相应 slot
- 当前缺口不在 backend 行为，而在 dedicated truth source 不够集中：
  - 旧测试里只有 generic parity / presence 断言
  - `key-slot audit` 没有可直接消费的 dedicated source
- 本批已完成的最小修复：
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
    - 新增 `Test_NEON_AndNotSlots_Keep_AsmOwnedCompositions_And_RuntimeOwnership`
    - 固定 compare source 中 backend-local composition
    - 固定 register asm-only binding
    - 固定 runtime asm-compiled 时 backend-owned、否则回落 scalar
  - `tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`
    - 把 `AndNotI8x16/AndNotU16x8/AndNotU8x16` 纳入 `KEY_SLOTS_BY_BACKEND['neon']`
    - 把该 dedicated testcase 纳入 `EXPECTATION_PROCEDURES['neon']`
    - 对这 3 个 slot 开启 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['neon']`
- 本批按 Pascal 批次执行的最小验证链：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend neon --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `backend=neon ok slots=29`
  - `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=65 issues=0 status=ok`
  - Release `TTestCase_DispatchAPI` 通过
  - Release `check` 通过
- 当前阶段结论：
  - 这批没有改 backend 行为，而是把 `AndNotI8x16/U16x8/U8x16` 从分散 truth 收成了 dedicated truth source，并正式接进 `check` 常规门禁
  - 收口前已再次清理 `tests/fafafa.core.simd/__pycache__/`，避免把 Python 产物带进提交

## 2026-05-16 NEON Wide Integer Compare Key-Slot Audit Lift

- `AndNot*` 提交后，我先没有继续分散找小点，而是重新做了一次对账：
  - `python3 ...check_nonx86_register_truthfulness.py --backend neon --json --strict`
  - 结果显示 `NEON missing_from_key=36`
  - 且这 36 个名字全部属于 `CmpEq/CmpGe/CmpGt/CmpLe/CmpLt/CmpNe` 六大家族
- 继续对照现有 testcase 后，确认这次可以高效一点：
  - `Test_NEON_NoAsmWideIntegerCompareSlots_Keep_SourceCompanions_But_Reuse_BaseScalar`
  - 已经现成固定 source companion、关键 composition witness、register asm binding、runtime scalar-reuse
  - 因而这批不需要再改 Pascal testcase，也不需要拆成六个小批次
- 本批已完成的最小修复：
  - `tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`
    - 把 36 个 `Cmp*` slot 全部纳入 `KEY_SLOTS_BY_BACKEND['neon']`
    - 把 `Test_NEON_NoAsmWideIntegerCompareSlots_Keep_SourceCompanions_But_Reuse_BaseScalar` 纳入 `EXPECTATION_PROCEDURES['neon']`
    - 对这 36 个 slot 全部开启 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS['neon']`
- 本批按脚本批次执行的最小验证链：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend neon --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `backend=neon ok slots=65`
  - `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=101 issues=0 status=ok`
  - Release `check` 通过
- 当前阶段结论：
  - 这批没有改 backend 行为，而是把 `NEON wide integer compare` 这整簇 36 个合法 `asm-only wrapper-only` 位点一次性正式接进了 `check` 常规门禁
  - 按当前 checker 模型，`NEON missing_from_key` 已经清零
  - 收口前仍会清理 `tests/fafafa.core.simd/__pycache__/`，避免 Python 产物带进提交

## 2026-05-16 Non-x86 Key-Slot Cluster Dedup

- 提交 `57ae0ed0 test(simd): lift neon wide compare key-slot audit` 后，我先没有继续机械深挖新 slot，而是按改进后的工作法做了一轮只读 completion audit：
  - `git status --short --branch`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --json --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --json --strict`
- completion audit 先确认了两个关键事实：
  - 当前 `NEON` wrapper-only 已稳定为 `55`，`RISCVV` 为 `26`
  - allowlist 已无冗余项，`key-slot` coverage 线也已收口
- 在这个前提下，新一轮最真实的问题不再是“还有哪个 slot 没接进门禁”，而是 `check_nonx86_key_slot_audit.py` 自己开始出现结构性重复：
  - 同一簇 slot 名字在 `KEY_SLOTS_BY_BACKEND` 与 `REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS` 里重复维护
  - `RISCVV Extract*` 还额外在 mixed-context 例外集里再次手填
- 本批已完成的最小修复：
  - `tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`
    - 新增 `combine_slot_groups(...)`
    - 抽出 `NEON_*` 与 `RISCVV_*` 共享 key-slot tuple 簇
    - 让 `KEY_SLOTS_BY_BACKEND`、`REQUIRE_EXPLICIT_DISPATCHAPI_ASSERTS`、`ALLOWED_BACKEND_OWNED_NO_ASM_SCALAR_WRAPPER_SLOTS_BY_BACKEND` 复用共享真源
- 这批的目标不是改计数，而是压低 checker 自己的 drift 风险：
  - 以后再扩某一簇 ownership slot 时，不需要在多块常量里重复手改同一批名字
  - 如果 summary 保持不变，就说明这次只做了结构去冗余，没有碰审计语义
- 本批 fresh 验证链已完成：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_nonx86_key_slot_audit.py`
  - `python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `backend=neon ok slots=65`
  - `backend=riscvv ok slots=36`
  - `NONX86_KEY_SLOT_AUDIT_SUMMARY backends=neon,riscvv slots=101 issues=0 status=ok`
  - Release `check` 通过
- 当前阶段结论：
  - 这批确认只是 checker 结构去冗余，没有改动任何 non-x86 ownership 语义
  - 下一轮再继续审查时，可以优先找新的真实缺口，而不是在这份脚本里继续手工同步同一批 slot 名字

## 2026-05-16 Check Optional Non-x86 Opt-In Listing

- 收完 `03caabc6 test(simd): dedupe nonx86 key-slot clusters` 后，我先没有回头继续扫 slot，而是专门查了 `check` 为什么在纯 Python 审查批次里仍然偏重：
  - `sed -n '6580,6715p' tests/fafafa.core.simd/BuildOrTest.sh`
  - `sed -n '250,330p' tests/fafafa.core.simd/buildOrTest.bat`
- 读出来的真实问题很直接：
  - shell 与 batch 的 `check` 都无条件执行 `nonx86-optin-list-suites`
  - 但同一段里 `wiring-sync` / `experimental` 已经有现成 optional env 分支
  - 这让纯 checker / Python / scratch 批次也会被强行拖进 `neon/riscvv` opt-in 构建
- 本批已完成的最小修复：
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - 给 `run_nonx86_optin_list_suites` 增加 `SIMD_CHECK_NONX86_OPTIN` 开关
    - 默认未设时继续执行，设为 `0` 时显式跳过并输出提示
  - `tests/fafafa.core.simd/buildOrTest.bat`
    - 同步加入相同语义的 `%SIMD_CHECK_NONX86_OPTIN%` 分支
- 这批的目标不是减少默认覆盖面，而是把“窄批次可以显式跳过重路径”这件事编码进脚本：
  - 默认行为不变
  - 但后续若只改 Python checker，就不必总为 `nonx86 opt-in list-suites` 付费
- 本批 fresh 验证链已完成：
  - `git diff --check`
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - `FAFAFA_BUILD_MODE=Release SIMD_CHECK_NONX86_OPTIN=0 bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - 辅助环境探测：`command -v cmd.exe || command -v wine || command -v pwsh || command -v powershell`
- fresh 结果：
  - shell 脚本语法检查通过
  - Release `check` 明确输出 `[CHECK] SKIP optional non-x86 opt-in suite listing (set SIMD_CHECK_NONX86_OPTIN=1 to enable)`
  - 同一条 Release `check` 最终通过
  - 本机存在 `/usr/bin/wine`，但本轮未实际执行 Windows `buildOrTest.bat check`，因此 batch 侧验证仍是静态对照而非运行时实证
- 当前阶段结论：
  - 这批把纯审查批次的一个真实重路径收成了 optional lane
  - 默认覆盖面没变，但以后做 Python/checker 小批次时可以显式跳过这段 non-x86 opt-in 构建

## 2026-05-16 Windows Check Non-x86 Audit Parity

- 在把 `SIMD_CHECK_NONX86_OPTIN` 收口后，我继续看 `check` 的真实剩余问题，没有再回头扫 slot，而是专门对照了 shell/batch 的 `check` 主线：
  - `sed -n '6580,6725p' tests/fafafa.core.simd/BuildOrTest.sh`
  - `sed -n '245,325p' tests/fafafa.core.simd/buildOrTest.bat`
  - `rg -n 'helper_semantics|key_slot_audit|riscvv_abi|source_reachability' tests/fafafa.core.simd/BuildOrTest.sh tests/fafafa.core.simd/buildOrTest.bat`
- 对出来的真实差异比预期更具体：
  - batch `check` 不只是没跑 `helper-semantics`
  - 连 shell 默认主线里的 `key-slot-audit`、`riscvv-abi-shape`、`source-reachability` 也一起掉线了
- 本批已完成的最小修复：
  - `tests/fafafa.core.simd/buildOrTest.bat`
    - 新增 `:nonx86_helper_semantics_check`
    - 新增 `:key_slot_audit_check_internal`
    - 新增 `:riscvv_abi_shape_check`
    - 新增 `:source_reachability_check`
    - 并把这 4 条接回 `check` 主线，位置与 shell `check` 的逻辑顺序保持一致
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - 扩充 `check_windows_runner_parity()` 的 required source-safe pattern
    - 让 Linux 主链以后能自动盯住 batch 这 4 条 non-x86 审查不再掉线
- 这批的目标不是让 shell/batch 完全同实现，而是把 Windows `check` 的真实漏看面补回来：
  - shell 继续用现有 bash/python helper
  - batch 用原生 `py/python` 路径直接执行同一批 checker
  - 避免把“补齐覆盖面”误做成“再引入一层桥接依赖”
- 本批 fresh 验证链已完成：
  - `git diff --check`
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - `FAFAFA_BUILD_MODE=Release SIMD_CHECK_NONX86_OPTIN=0 bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - 辅助静态对照：`rg -n "call :nonx86_helper_semantics_check|call :key_slot_audit_check_internal|call :riscvv_abi_shape_check|call :source_reachability_check|set \"HELPER_SEMANTICS_SCRIPT=|set \"KEY_SLOT_AUDIT_SCRIPT=|set \"RISCVV_ABI_SHAPE_SCRIPT=|set \"SOURCE_REACHABILITY_SCRIPT=" tests/fafafa.core.simd/buildOrTest.bat`
- fresh 结果：
  - shell 语法检查通过
  - Release `check` 继续通过
  - 日志里 `windows runner parity signatures present` 与 `Python checker runtime guard present` 都为绿
  - `helper-semantics / key-slot-audit / riscvv-abi / source-reachability` 四条 non-x86 审查在同一条 Release `check` 下继续全部通过
  - batch 文件中的新调用点与脚本变量也已静态对照命中
- 当前阶段结论：
  - 这批把 Windows `check` 的一个真实 non-x86 审查漏看面补回来了
  - 现在 Linux 主链至少会守住 batch 侧这 4 条路径不再悄悄掉线
  - 仍待后续补的是 Windows 实机运行时证据，而不是源码或 source-safe parity 本身

## 2026-05-16 Targeted Python Audit Actions Exposure

- 这批我主动把方法收窄成一个小闭环，只处理 runner 操作面：
  - 先 `git status --short --branch` 确认工作树干净，分支为 `main...origin/main [ahead 223]`
  - 再只读核对 `BuildOrTest.sh` / `buildOrTest.bat` / scratch 当前状态
  - 目标不再是“继续泛化深审”，而是把 3 个已经成熟的 Python 审查暴露成直接 action
- 读出来的真实缺口：
  - `BuildOrTest.sh` 里有：
    - `run_nonx86_helper_semantics_check`
    - `run_source_reachability_check`
    - `run_riscvv_abi_shape_check`
  - 但没有对应公开 case
  - `buildOrTest.bat` 虽然已有内部 label，但没有顶部 dispatch / usage 暴露
  - 这导致后续要跑单条 Python 审查时，仍常常被迫绕回整条 `check`
- 本批已完成的代码修改：
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - 新增公开 action：
      - `helper-semantics`
      - `source-reachability`
      - `riscvv-abi-shape`
    - usage/help 同步补齐
    - `check_windows_runner_parity()` 的 required pattern 同步更新，纳入新 action 与新 usage
  - `tests/fafafa.core.simd/buildOrTest.bat`
    - 顶部 dispatch 新增：
      - `helper-semantics`
      - `source-reachability`
      - `riscvv-abi-shape`
    - 新增公开 label：
      - `:helper_semantics`
      - `:source_reachability`
      - `:riscvv_abi_shape`
    - usage/help 同步补齐
- 本批中途唯一一次真实返工也已被收住：
  - 首轮跑 `Release check` 时，直接抓到 `check_windows_runner_parity()` 还在匹配旧 usage 行
  - 我没有继续扩散排查，而是只补这条 parity required pattern，再重跑
  - 第二轮 `Release check` 恢复全绿，说明这次返工是 runner guard 自身滞后，不是功能设计问题
- 本批 fresh 验证链：
  - `git diff --check`
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh helper-semantics`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh source-reachability`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh riscvv-abi-shape`
  - `FAFAFA_BUILD_MODE=Release SIMD_CHECK_NONX86_OPTIN=0 bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `find tests/fafafa.core.simd -type d -name __pycache__ -print`
  - `rm -rf tests/fafafa.core.simd/__pycache__`
- fresh 结果：
  - `NONX86_HELPER_SEMANTICS_SUMMARY checks=643 status=ok`
  - `SIMD_SOURCE_REACHABILITY_SUMMARY tracked_includes=84 reachable_includes=83 allowed_unreachable=1 unexpected_unreachable=0 missing_include_refs=0`
  - `RISCVV_ABI_SHAPE_SUMMARY direct_functions=121 explicit_checks=10 missing_result_store=0 suspicious_a0_loads=0 status=ok`
  - `Release check` 通过，并恢复 `windows runner parity signatures present`
- 当前阶段结论：
  - 这批把后续继续深审时最常见的一类低效路径收成了单条 action
  - 以后继续审 non-x86 Python checker 时，可以先直接跑目标 action，再按需决定是否补一条整链 `check`

## 2026-05-16 Windows Closeout Wrapper Parity

- 这批我继续保持小闭环，没有再回头扫 backend/source，而是先审计 shell/batch 的公开 action 差集：
  - `python3 - <<'PY' ...` 提取 `BuildOrTest.sh` case action 与 `buildOrTest.bat` 顶部 dispatch action
  - `rg -n "gate-summary-selfcheck|evidence-linux|native-evidence|verify-nonx86-native-evidence|restore-nightly-evidence|win-evidence-via-gh|win-closeout-dryrun|win-closeout-snippets|freeze-status|freeze-status-linux|freeze-status-rehearsal" tests/fafafa.core.simd/buildOrTest.bat tests/fafafa.core.simd/BuildOrTest.sh`
- 差集证据很直接：
  - shell-only 里最值钱、且明显不该长期缺失的一组是：
    - `win-evidence-via-gh`
    - `win-closeout-dryrun`
    - `win-closeout-snippets`
    - `freeze-status`
    - `freeze-status-linux`
    - `freeze-status-rehearsal`
  - 它们都已经在 shell usage/help 与 closeout 文档流里作为公开入口存在
  - 但 batch 顶部 dispatch、usage/help 还没有对应入口
- 本批已完成的代码修改：
  - `tests/fafafa.core.simd/buildOrTest.bat`
    - 新增顶部 dispatch：
      - `win-evidence-via-gh`
      - `win-closeout-dryrun`
      - `win-closeout-snippets`
      - `freeze-status`
      - `freeze-status-linux`
      - `freeze-status-rehearsal`
    - usage/help 同步补齐
    - 新增对应 `bash %ROOT%BuildOrTest.sh ...` wrapper label
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - `check_windows_runner_parity()` 中把这 6 条从 `LAllowedShellOnly` 移除
    - 新增 required pattern：
      - batch 顶部 dispatch
      - batch usage 行
      - batch help 行
      - batch wrapper label / run-line
- 这批的关键修法不是“让 batch 自己实现 freeze-status”，而是明确保持单一实现面：
  - Windows batch 只做公开桥接
  - 真实实现仍然由 shell runner 承担
  - 这样能收正操作面，又不引入第二套 closeout 逻辑
- 本批 fresh 验证链：
  - `git diff --check`
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - action 差集脚本 fresh 对比
  - `bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-dryrun`
  - `FAFAFA_BUILD_MODE=Release SIMD_CHECK_NONX86_OPTIN=0 bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - action 差集已缩到：
    - shell-only：`evidence-linux`、`gate-summary-selfcheck`、`native-evidence`、`restore-nightly-evidence`、`verify-nonx86-native-evidence`、`verify-win-evidence`，外加 batch 内联处理的 `debug/release`
    - batch-only：`evidence-win`
  - `win-closeout-dryrun` 轻量烟测通过：
    - `[CLOSEOUT] DRYRUN OK: simulated summary stayed preview-only`
  - `Release check` 通过，且 `windows runner parity signatures present` 继续为绿
- 当前阶段结论：
  - 这批把 Windows closeout 路径里一组真实缺失的公开入口补回来了
  - 同时也把这组入口重新纳回 parity guard 的真相源
  - 仍待后续补的是 Windows 实机运行时证据，不是 runner action 表本身

## 2026-05-16 Remaining Evidence Action Parity

- closeout/freeze wrapper parity 提交后，我没有直接停，而是继续用 fresh action diff 看 runner 还剩什么尾巴：
  - `python3 - <<'PY' ...` 提取 shell case action 与 batch 顶部 dispatch action
  - fresh 结果已经收缩成：
    - shell-only：`evidence-linux`、`gate-summary-selfcheck`、`native-evidence`、`restore-nightly-evidence`、`verify-nonx86-native-evidence`，外加 `debug/release/verify-win-evidence`
    - batch-only：`evidence-win`
- 这说明 runner 公开操作面的缺口已经缩成最后一组同构 evidence/selfcheck action，适合再做一个小批次一口气收掉。
- 本批已完成的代码修改：
  - `tests/fafafa.core.simd/buildOrTest.bat`
    - 新增顶部 dispatch：
      - `gate-summary-selfcheck`
      - `evidence-linux`
      - `native-evidence`
      - `verify-nonx86-native-evidence`
      - `restore-nightly-evidence`
    - usage/help 同步补齐
    - 新增对应 `bash %ROOT%BuildOrTest.sh ...` wrapper label
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - `LAllowedShellOnly` 继续收缩，只保留 `import-nonx86-native-evidence`
    - `check_windows_runner_parity()` 新增这 5 条的 required dispatch / usage / help / run-line pattern
- 这批的一个重要事实判断是：
  - runner parity 现在不该再被表述成“shell/batch 大致一致”
  - 它已经可以更准确地描述为：
    - 公开 action 表几乎完全一致
    - 剩余差异只在 batch 内联控制流或 Windows alias 上
- 本批 fresh 验证链：
  - `git diff --check`
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - fresh action diff
  - `bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary-selfcheck`
  - `FAFAFA_BUILD_MODE=Release SIMD_CHECK_NONX86_OPTIN=0 bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - action diff 已缩到：
    - shell-only：`debug`、`release`、`verify-win-evidence`
    - batch-only：`evidence-win`
  - `gate-summary-selfcheck` 通过：
    - `[GATE-SUMMARY-SELFCHECK] OK`
  - `Release check` 通过，`windows runner parity signatures present` 继续为绿
- 当前阶段结论：
  - 这批把 runner parity 的最后一组 evidence/selfcheck 公开入口也补齐了
  - 现在若继续深审 runner，更值得看的不再是“还有哪些 action 没暴露”，而是剩余内联/特例是否还应该保持特例

## 2026-05-16 Batch Inline Action Normalization

- evidence/selfcheck wrapper parity 提交后，我继续做了最后一次 fresh action diff：
  - `python3 - <<'PY' ...` 对比 shell case action 与 batch 顶部 `goto` action
  - fresh 结果已经不是“缺少动作”，而是“还有几条内联分支”：
    - shell-only：`debug`、`release`、`verify-win-evidence`
    - batch-only：`evidence-win`
- 这说明 runner parity 线已经不该继续按“补 action”思路推进，而应该把 batch 顶部最后几条内联特例标准化成显式 label dispatch。
- 本批已完成的代码修改：
  - `tests/fafafa.core.simd/buildOrTest.bat`
    - `debug` 改成 `goto :debug_action`
    - `release` 改成 `goto :release_action`
    - `verify-win-evidence` 改成 `goto :verify_win_evidence`
    - `evidence-win-verify` 改成 `goto :evidence_win_verify`
    - 原有逻辑整体迁移到对应 label，行为不变
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - `check_windows_runner_parity()` required pattern 改为匹配新的 `goto` 结构
    - 同步补上 `:debug_action` / `:release_action` / `:verify_win_evidence` / `:evidence_win_verify` 的 label 或关键脚本变量线索
- 这批的关键收益不在功能新增，而在调度面彻底收平：
  - batch 顶部公开 action 表现在终于可以用同一类规则扫描
  - parity guard 对 `verify-win-evidence` 不再依赖特殊 inline 模式
  - action diff 的结果也可以更干净地表达“只剩 alias”
- 本批 fresh 验证链：
  - `git diff --check`
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - fresh action diff
  - `FAFAFA_BUILD_MODE=Release SIMD_CHECK_NONX86_OPTIN=0 bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - action diff 已收敛为：
    - `remaining shell_only: []`
    - `remaining batch_only: ['evidence-win', 'evidence-win-verify']`
  - `Release check` 继续通过，`windows runner parity signatures present` 仍为绿
- 当前阶段结论：
  - runner parity 现在已经真正进入“只剩 Windows alias”的状态
  - 如果还继续深审这条线，下一步应该判断 `evidence-win` / `evidence-win-verify` 是否值得长期保留为 alias，而不是继续改 dispatch 结构

## 2026-05-16 Runner Parity Quick Path

- 先回到仓库现状核对后，确认当前工作树在这条线上的上一批改动已经落进 `HEAD`，不能再假设还有“未提交 runner parity 补丁”。
- 按改进后的工作法，这次没有再拿 `BuildOrTest.sh check` 做顺带证明，而是先确认真实问题：
  - fresh action diff 仍是 `remaining shell_only: []`
  - `remaining batch_only: ['evidence-win', 'evidence-win-verify']`
  - 但 `BuildOrTest.sh` 的 `check_windows_runner_parity()` 已明确把它们视作 `LAllowedWindowsOnly`
  - `windows_b07_closeout_runbook.md`、`simd_release_candidate_checklist.md`、`evaluate_simd_freeze_status.py`、`print_windows_b07_closeout_3cmd.sh`、`apply_windows_b07_closeout_updates.sh` 也都还在真实消费
- 因而本轮没有去删除 alias，而是补一个真正能提速的轻量入口：
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - 新增 `runner-parity)` case
    - 新增 `run_runner_parity()`，只执行 `check_windows_runner_parity()` 与 `check_cpuinfo_runner_parity()`
    - 同步把 usage/help 补入 `runner-parity`
  - `tests/fafafa.core.simd/buildOrTest.bat`
    - 新增顶部 dispatch：`if /I "%ACTION%"=="runner-parity" goto :runner_parity`
    - 新增 `:runner_parity` wrapper，经 `bash %ROOT%BuildOrTest.sh runner-parity` 代理执行
    - 同步补齐 usage/help
- 本轮轻量验证链：
  - `git diff --check`
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - fresh action diff
  - `bash tests/fafafa.core.simd/BuildOrTest.sh runner-parity`
- fresh 结果：
  - `remaining shell_only: []`
  - `remaining batch_only: ['evidence-win', 'evidence-win-verify']`
  - `[CHECK] OK (windows runner parity signatures present)`
  - `[CHECK] OK (cpuinfo runner parity signatures present)`
  - `[CHECK] OK (runner parity quick path)`
- 当前阶段结论：
  - 这批没有改 SIMD 功能逻辑，而是把 runner parity 证明从 `check` 大链里拆成了一个专用 fast path
  - `evidence-win` / `evidence-win-verify` 继续保留为有意的 Windows-only alias；以后审这条线应优先跑 `runner-parity`，而不是再拿大链做静态问题的证明

## 2026-05-16 Runner Parity Call-Site Unification

- 在 `runner-parity` fast path 落地后，我又回头对 `BuildOrTest.sh` 做了一次更窄的调用面复核，确认还有一层真实冗余残留：
  - `check` case 仍手写 `check_windows_runner_parity` + `check_cpuinfo_runner_parity`
  - `gate_step_build_check()` 也仍手写同一对调用
- 这说明上一批虽然已经给了专用 action，但主门禁还没有真正收敛到“只剩一个 runner parity 入口”。
- 本轮已完成的源码收口：
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - `gate_step_build_check()` 里的 runner parity 旧调用已改为 `run_runner_parity || return $?`
    - `check` case 里的成对旧调用已改为单次 `run_runner_parity`
    - 其余 guard 顺序保持不动，只是把同一条 runner 证明链收口到单入口
- 本轮轻量验证链：
  - `git diff --check`
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh runner-parity`
- fresh 结果：
  - `[CHECK] OK (windows runner parity signatures present)`
  - `[CHECK] OK (cpuinfo runner parity signatures present)`
  - `[CHECK] OK (runner parity quick path)`
- 当前阶段结论：
  - runner parity 现在不只是“有了 fast path action”，而是 `check` / gate build-check / 显式 action 三处都统一吃同一个封装入口
  - 这批继续没有改 SIMD 功能逻辑，但把一处真实的调用面冗余收平了，也降低了以后主门禁忘同步 `run_runner_parity()` 的漂移风险

## 2026-05-16 Gate Build-Check Static Guard Parity

- 把 `run_runner_parity()` 调用面统一后，我继续对 `check` case 和 `gate_step_build_check()` 做了精确清单比对，确认新的真实缺口不是“谁在调 runner parity”，而是 gate 的 build-check 阶段少跑了一组低成本静态护栏：
  - `run_nonx86_helper_semantics_check`
  - `run_nonx86_key_slot_audit_check`
  - `run_windows_cpuinfo_x86_batch_build_success_criteria_smoke`
  - `run_source_reachability_check`
  - `run_sse2_structure_check`
- 同时也确认这不是误报：
  - `run_intrinsics_experimental_status` 本来就在 gate 后半段作为独立 step 存在
  - `run_register_truthfulness_check "1"` 也在 gate wiring 后单独建步
  - 但上面这 5 条此前确实没有任何 gate step 覆盖
- 本轮已完成的源码收口：
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - 在 `gate_step_build_check()` 中补入 `run_nonx86_helper_semantics_check`
    - 补入 `run_nonx86_key_slot_audit_check`
    - 补入 `run_windows_cpuinfo_x86_batch_build_success_criteria_smoke`
    - 补入 `run_source_reachability_check`
    - 补入 `run_sse2_structure_check`
  - 其余 gate phase 不做结构改写，先只收 coverage 缺口
- 本轮验证链：
  - `git diff --check`
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- fresh 结果：
  - gate 通过
  - build-check 段现在已实际输出：
    - `NONX86_HELPER_SEMANTICS_SUMMARY ... status=ok`
    - `NONX86_KEY_SLOT_AUDIT_SUMMARY ... status=ok`
    - `SIMD_SOURCE_REACHABILITY_SUMMARY ... status=ok`
    - `SSE2_STRUCTURE_SUMMARY ... status=ok`
    - `[PASS] windows SIMD cpuinfo.x86 batch build success criteria verified`
- 当前阶段结论：
  - 这批没有改 SIMD 生产逻辑，而是把 gate 真正补回了一组先前未覆盖的静态护栏
  - 现在 `gate` 的 build-check 段与 `check` 在这组低成本审查上的口径明显更接近了，不再出现 “check 绿但 gate 根本没看过这些护栏” 的 coverage 漏洞

## 2026-05-16 Shared Static Build-Check Core

- 在补完 gate build-check 的静态护栏后，我又做了一次 fresh 清单比对，确认结构性根因已经收敛得足够干净，可以直接去重：
  - `check` 与 `gate_step_build_check()` 的共同静态 core 现在已经完全同构
  - 剩余差异只剩 check/gate 各自有意保留的 optionals，不再夹着隐蔽 coverage 差异
- 本轮已完成的源码收口：
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - 新增 `run_static_build_check_core()`
    - 把 `run_runner_parity`、所有 shared runner/output/py-check guard、`helper-semantics`、`key-slot-audit`、`riscvv-abi-shape`、`windows cpuinfo.x86 batch success-criteria smoke`、`register/include/source/sse2` 静态检查，以及 `backend_ops/simd_boundary/public_smoke/dispatch_preinit` smoke 统一收到这一个 helper
    - `gate_step_build_check()` 改为 `build/check log + run_static_build_check_core + run_nonx86_optin_list_suites`
    - `check` case 改为 `build/check log + adapter-sync echo + run_static_build_check_core + check-only optionals`
- 本轮验证链：
  - `git diff --check`
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - `FAFAFA_BUILD_MODE=Release SIMD_CHECK_NONX86_OPTIN=0 bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- fresh 结果：
  - release `check` 通过
  - release `gate` 通过
  - 说明这次不是“减少重复时不小心漏调用”，而是共同静态 core 真正被两个主入口共享
- 当前阶段结论：
  - 这批继续没有改 SIMD 生产逻辑，但把同一段静态 build-check 证明链正式收成了单一真相源
  - 后续再审 runner/static guard drift 时，主风险点已经从“两份清单可能忘同步”降到了“共享 helper 内部是否正确”这一处

## 2026-05-16 IEEE754 Empty Finally Cleanup

- 这轮先收工作方法，而不是先扩扫描面：
  - 不再重复跑 `gate`
  - 不再继续在 runner/build-check 线上做没有新证据的深挖
  - 先挑一个可在一轮内完成的小问题
- fresh 复核后，`tests/fafafa.core.simd/fafafa.core.simd.ieee754.testcase.pas` 暴露出一组高置信度冗余：
  - 10 处 top-level 空 `finally`
  - 多处伴随未使用的 `oldVectorAsm/LOldVectorAsm` 捕获
  - 所有仍保留的 `finally` 命中则都带真实 `ResetToAutomaticBackend`
- 本轮已完成的源码收口：
  - 删除 `TTestCase_IEEE754EdgeCases` 里 `Test_F32x4_RoundTrunc_NaNInf_{Scalar,SSE2}` 与 `Test_Wide_RoundTrunc_NaNInf_{Scalar,SSE2}` 的空 `finally`
  - 删除 `TTestCase_AVX2RoundTruncIEEE754` 里 5 个 AVX2/Scalar/SSE2 对比测试的空 `finally`
  - 删除 `TTestCase_NonX86IEEE754.Test_NonX86_NarrowF64x2_RoundTruncFloorCeil_Finite_IfAvailable` 的 outer 空 `finally`
  - 同步删掉这些路径中已失效的 `oldVectorAsm/LOldVectorAsm` 局部变量与赋值
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_IEEE754EdgeCases --suite=TTestCase_AVX2RoundTruncIEEE754 --suite=TTestCase_NonX86IEEE754`
- fresh 结果：
  - `git diff --check` 通过
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批是一次纯测试层冗余清理，没有改 SIMD 生产逻辑
  - `ieee754.testcase` 里最显眼的“空壳 cleanup”已经清掉；若下一轮还继续沿这条线深审，应优先看剩余 non-empty `finally` 是否还有局部重复，而不是再扫空块

## 2026-05-16 DataPlane Empty Finally Cleanup

- 本轮严格按改进后的工作法执行，没有重新打开 `gate` 或大范围扫描，而是直接收工作树里唯一一个未提交的 `dataplane` 小改动。
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.dataplane.testcase.pas`
  - 位置：`TTestCase_DataPlane.Test_DataPlane_VectorAsmRoundTrip_Reuses_PreviouslyPublishedSnapshot`
  - 内容：删除未使用的 `LOldVectorAsm` 及其赋值；删除纯空 outer `try/finally`
- 之所以可以安全删除，不是凭形状判断，而是基于 fresh 基类链复核：
  - `TSimdVectorAsmStatefulTestCase.TearDown` 仍会恢复 `FSavedVectorAsm`
  - `TSimdBackendStatefulTestCase.TearDown` 仍会恢复 `FSavedBackend`
  - 所以这个用例不需要额外 method-local restore
- 本轮验证链：
  - `git status --short --branch` 先确认工作树只剩这一处未提交改动
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DataPlane`
- fresh 结果：
  - `## main...origin/main [ahead 232]`
  - `git diff --check` 通过
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批已经形成完整小闭环，可以直接提交
  - 后续如果继续深审 `simd`，应保持同样节奏：只挑已证实的局部冗余点，小验证后立即收口

## 2026-05-16 PublicAbi Early Empty Finally Cleanup

- 本轮没有重新跑慢链，也没有重新开全库审查，而是直接沿上一轮的高确定性冗余线继续前进。
- 候选筛选过程：
  - 先用 `rg -n -U "finally\\s*\\n\\s*end;"` 收窄剩余空 `finally` 热点，确认主要集中在 `dispatchapi/direct/publicabi`
  - 再结合 `rg -n "LOldVectorAsm"` 与已有 nonx86 build 日志里的 `assigned but never used` 提示，把下一刀缩到 `publicabi.testcase` 前部两处最简单命中
  - 明确避开更大的 `dispatchapi` 和后段 hook/rollback 复杂测试
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas`
  - 用例 1：`Test_PublicApi_Table_Uses_Stable_Cdecl_EntryPoints_AfterBackendSwitch`
  - 用例 2：`Test_PublicApi_VectorAsmRoundTrip_Reuses_PreviouslyPublishedMetadataTable`
  - 内容：删除未使用的 `LOldVectorAsm` 及其赋值；删除纯空 outer `try/finally`
- 安全依据：
  - `TTestCase_PublicAbi` 继承 `TSimdVectorAsmStatefulTestCase`
  - `TSimdVectorAsmStatefulTestCase.TearDown` 仍负责恢复 `FSavedVectorAsm`
  - `TSimdBackendStatefulTestCase.TearDown` 仍负责恢复 `FSavedBackend`
  - 因而这两处都不需要额外 method-local restore
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批已经形成完整小闭环，可以直接提交
  - 当前工作法是有效的：缩候选面、只改高确定性命中、用单 suite release 验证后立即收口

## 2026-05-16 PublicAbi CapabilityBits Empty Finally Cleanup

- 这一批继续沿同一文件推进，没有重新打开大范围搜索，只在 `publicabi.testcase` 已读过的前部 capability-bits 区段继续深挖。
- 候选筛选过程：
  - 基于前一批已经确认的基类恢复前提，继续读 `1394..1815` 一段
  - 用 `rg -n -U "finally\\s*\\n\\s*end;"` 与 `rg -n "LOldVectorAsm"` 的交集确认这是一串连续同形态命中
  - 逐段肉眼复核，确认没有 hook/rollback/mutation 之类需要 method-local restore 的特殊流程
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas`
  - 成组清理 9 个 capability-bits 用例中的未使用 `LOldVectorAsm`
  - 同时删除这些用例的纯空 outer `try/finally`
- 安全依据：
  - `TTestCase_PublicAbi` 继承 `TSimdVectorAsmStatefulTestCase`
  - `TearDown` 仍会统一恢复 vector-asm/backend 状态
  - 这批方法本体只做 capability bit 和 dispatch slot 断言，不包含额外 restore 责任
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批已经形成完整小闭环，可以直接提交
  - 当前节奏依然正确：在一个已读透的文件段内连续收掉同形态冗余，比重新扫别的大文件更高效

## 2026-05-16 PublicAbi NEON RISCVV Empty Finally Cleanup

- 这一批继续保持“同文件、同验证链、只收同类命中”的节奏，没有重新打开别的 suite。
- 候选筛选过程：
  - 继续读取 `publicabi.testcase` 的 capability-bits 后续区段
  - 用语义而不是命中数量分层：只保留 5 个 `NEON/RISCVV` 同类命中，明确跳过后续带真实 `RegisterBackend` restore 的 refresh 测试
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas`
  - 删除 5 个 `NEON/RISCVV` 用例中的未使用 `LOldVectorAsm`
  - 删除这些用例的纯空 outer `try/finally`
- 安全依据：
  - `TTestCase_PublicAbi` 仍由 `TSimdVectorAsmStatefulTestCase.TearDown` 统一恢复状态
  - 本批用例只做 capability bit / runtime rebuild 断言
  - 后续真正带 restore 的测试已被显式排除在本批之外
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批已经形成完整小闭环，可以直接提交
  - 当前工作法继续有效：先分出“真正空壳 cleanup”和“包着真实 restore 的 finally”，再动手，效率和安全性都更高

## 2026-05-16 PublicAbi PostCapability Empty Finally Cleanup

- 这一批继续不换文件、不换 suite，只在 `publicabi.testcase` 后续区段里继续做分层清理。
- 候选筛选过程：
  - 先读取 `2091..2403` 一带真实代码，而不是仅看 `rg` 命中
  - 明确区分“外层 finally 为空，但内层 finally 已负责真实 restore”的方法
  - 与“外层 finally 本身带条件 restore”的方法
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas`
  - 清理 4 个方法中的未使用 `LOldVectorAsm`
  - 删除这 4 个方法的纯空 outer `try/finally`
- 安全依据：
  - `TTestCase_PublicAbi` 仍由基类统一恢复 vector-asm/backend 状态
  - 这批方法的真实 backend/hook restore 已留在内层 finally
  - 后续外层 finally 带 `if ... then RegisterBackend(...)` 的方法已被显式排除
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批已经形成完整小闭环，可以直接提交
  - 当前方法继续证明有效：先用语义分层切掉高风险命中，再收同类空壳 cleanup，避免误删真实 restore

## 2026-05-16 PublicAbi Automatic Restore Empty Finally Cleanup

- 这一批继续在 `publicabi.testcase` 单文件内推进，没有改验证路径，也没有切换到其他 suite。
- 候选筛选过程：
  - 先读 `2946..3201` 一带完整方法体
  - 只保留 automatic/vector-asm late-force 这组“外层 finally 为空、内层 finally 已承担 hook cleanup”的方法
  - 明确把 previous-forced preserve 那串留到下一轮再单独分层
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas`
  - 清理 5 个 automatic/vector-asm late-force 方法中的未使用 `LOldVectorAsm`
  - 删除这 5 个方法的纯空 outer `try/finally`
- 安全依据：
  - 本批方法的真实 hook remove / flag reset 仍在内层 finally
  - 其余状态恢复仍由基类 `TearDown` 统一负责
  - 语义更重的 previous-forced preserve 路径已被显式排除
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批已经形成完整小闭环，可以直接提交
  - 当前工作法继续有效：保持同一文件、同一 suite、同一语义边界，推进速度和安全性都更稳

## 2026-05-16 PublicAbi Previous Forced Empty Finally Cleanup

- 这一批继续不换文件、不换 suite，只在 previous-forced preserve 这段里继续做语义分层。
- 候选筛选过程：
  - 先通读 `3183..3454` 一带完整方法体，而不是只凭 `rg` 命中
  - 只保留 4 个“外层 finally 为空、内层 finally 已承担 hook cleanup”的方法
  - 明确把外层 finally 还带 `LPreviousTableCaptured` 条件 restore 的 `RegisterBackend` 路径排除
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas`
  - 清理 4 个 previous-forced/`RegisterBackend` late-force 方法中的未使用 `LOldVectorAsm`
  - 删除这 4 个方法的纯空 outer `try/finally`
- 安全依据：
  - 真实 hook remove / stage reset 仍留在内层 finally
  - 外层 finally 仅在被确认为空壳时才删除
  - 复杂的 table-capture restore 路径已显式跳过
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批已经形成完整小闭环，可以直接提交
  - 当前方法继续有效：同一文件里先把“真空壳 cleanup”收干净，再把带条件 restore 的剩余点单独看，能明显降低误删风险

## 2026-05-16 PublicAbi Remaining Empty Finally Cleanup Repair

- 这一批先没有继续扩 `dispatchapi/direct/concurrent`，而是回到 `publicabi.testcase` 当前编译失败现场，按“先修结构、再复验”的方式收口。
- 真实现场确认：
  - 当前工作树只剩 `tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 在改
  - 编译失败根因不是行为回归，而是上轮删除 empty `finally` 时，在 2 个方法里留下了孤立 outer `try`
- 这轮实际处理的 4 个方法：
  - `Test_PublicApi_CachedTable_RemainsCallable_Across_Rebind`
  - `Test_PublicApi_CachedTable_Preserves_PreviousSnapshot_Metadata_Across_Rebind`
  - `Test_PublicApi_BackendPodInfo_Refreshes_WhenBackendBecomesNonDispatchable`
  - `Test_PublicApi_RollbackRestore_ReSelects_RequestedBackend_Before_Return`
- 已完成的源码收口：
  - 删除前 2 个方法里的纯空 outer `try/finally`
  - 修平后 2 个方法里误留下的 outer `try`
  - 删除 `Test_PublicApi_RollbackRestore_ReSelects_RequestedBackend_Before_Return` 中未使用的 `LOldVectorAsm`
  - 保留内层真实 restore 不变：
    - `RegisterBackend(LOriginalBackend, LOriginalTable)`
    - `RemoveDispatchChangedHook(...)`
    - hook flag / stage reset
- 这轮额外做的卫生确认：
  - `git diff --check` 通过
  - `rg -n -U "finally\\s*\\n\\s*end;" tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 无命中
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批仍然只是 `publicabi` 测试层冗余/结构修复，没有改 SIMD 生产实现
  - `publicabi.testcase` 这条“纯空 finally”线在当前文件里已经基本收干净；下一步如果继续深审，应只看那些外层 finally 还承担条件 restore 的剩余路径

## 2026-05-16 PublicAbi Remaining Dead VectorAsm Capture Cleanup

- 这一批继续不换文件、不换 suite，也没有重新打开 `gate`；只针对 `publicabi.testcase` 里剩余的死状态捕获做清理。
- 候选筛选过程：
  - 先用 `rg -n "LOldVectorAsm"` 找到剩余命中
  - 再按方法体核对这些命中都只剩“声明 + 赋值”，没有任何读取
  - 同时确认这些方法的 outer `finally` 仍承担条件 `RegisterBackend(...)` restore，所以这轮明确不改 `finally` 结构
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas`
  - 删除 9 个 `publicabi` 方法中的 `LOldVectorAsm` 局部变量
  - 删除对应的 `LOldVectorAsm := IsVectorAsmEnabled` 赋值
  - 保留所有 inner/outer `finally` 与 hook / table restore 逻辑不变
- 这轮额外做的卫生确认：
  - `rg -n "LOldVectorAsm" tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas` 已无命中
  - `git diff --check` 通过
- 本轮验证链：
  - `rg -n "LOldVectorAsm" tests/fafafa.core.simd/fafafa.core.simd.publicabi.testcase.pas`
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_PublicAbi`
- fresh 结果：
  - `LOldVectorAsm` 搜索无输出
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批依旧只是 `publicabi` 测试层冗余清理，没有改 SIMD 生产实现
  - `publicabi.testcase` 当前文件里，“空 finally”与“死 vector-asm 状态捕获”这两条高确定性冗余线都已经收干净

## 2026-05-16 DispatchApi Front Empty Finally And Dead VectorAsm Cleanup

- 这一批开始把同样的方法扩到 `dispatchapi.testcase`，但仍然坚持只吃前段高确定性命中，没有打开中后段的大块 parity/NEON lane。
- 候选筛选过程：
  - 先用 `rg -n -U "finally\\s*\\n\\s*end;"` 找出 `dispatchapi` 的空壳 `finally`
  - 再按 `990..1675` 区间逐段读真实方法体
  - 明确区分：
    - 纯空 outer `finally`，可直接删壳
    - outer `finally` 仍承担条件 `RegisterBackend(...)` restore，只能删 `LOldVectorAsm`
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - 删除 5 个简单 API 用例中的纯空 outer `try/finally`
  - 删除 4 个 hook/rollback 用例中的纯空 outer `try/finally`
  - 删除 8 个 rollback / previous-forced 用例中的未使用 `LOldVectorAsm`
  - 保留所有 inner `finally` 与条件 restore 不变
- 本轮额外做的卫生确认：
  - `git diff --check` 通过
  - `rg -n "LOldVectorAsm" ...dispatchapi.testcase.pas | sed -n '1,40p'` 显示前段残留已后移到下一批区间，不是本批遗留
  - `rg -n -U "finally\\s*\\n\\s*end;" ...dispatchapi.testcase.pas | sed -n '1,40p'` 也显示最前段一批命中已被消掉，下一批候选起点后移到 `1684`
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批依旧只是 `dispatchapi` 测试层冗余清理，没有改 SIMD 生产实现
  - 当前高确定性下一跳已经很清楚：`dispatchapi` 候选区间后移到 `1684` 之后，可以继续沿同样边界做下一批

## 2026-05-16 DispatchApi Mid Empty Finally And Dead VectorAsm Cleanup

- 这一批继续留在 `dispatchapi.testcase`，没有切到 `direct` 或 `concurrent`，只把候选区间推进到 `1684..2328`。
- 候选筛选过程：
  - 先读取 `1684..2328` 的真实方法体
  - 明确区分：
    - outer `finally` 真空壳，可直接删除
    - outer `finally` 仍承担 `if ...Captured then RegisterBackend(...)` restore，只删 `LOldVectorAsm`
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - 删除 10 个方法中的纯空 outer `try/finally`
  - 删除 12 个方法中的未使用 `LOldVectorAsm`
  - 保留所有 inner `finally`、hook cleanup、条件 table restore 不变
- 这轮额外做的卫生确认：
  - `git diff --check` 通过
  - `rg -n "LOldVectorAsm|finally$" ...dispatchapi.testcase.pas | sed -n '1,120p'` 显示高确定性候选已经继续后移到 `2363/2374` 一带
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批依旧只是 `dispatchapi` 测试层冗余清理，没有改 SIMD 生产实现
  - `dispatchapi` 当前最值当的下一批入口已经进一步后移到 `2363/2374` 之后，可继续沿相同 fail-close 边界推进

## 2026-05-16 DispatchApi Metadata And Snapshot Empty Finally Cleanup

- 这一批继续不换文件、不换 suite，只把候选区间推进到 `2277..2810` 的 metadata / snapshot consistency 簇。
- 候选筛选过程：
  - 先逐段读 `2277..2810` 的真实方法体
  - 识别出两类命中：
    - outer `finally` 本身为空，真实 restore 在内层 `finally`
    - `LOldVectorAsm` 只声明和赋值、没有任何读取
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - 删除 7 个方法中的纯空 outer `try/finally`
  - 删除 4 个方法中的未使用 `LOldVectorAsm`
  - 保留所有内层 `RegisterBackend(...)` restore 与 metadata/snapshot 断言不变
- 这轮额外做的卫生确认：
  - `git diff --check` 通过
  - `rg -n "LOldVectorAsm|finally$" ...dispatchapi.testcase.pas | sed -n '140,240p'` 显示下一批高确定性候选继续后移到了 `2815+`
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批依旧只是 `dispatchapi` 测试层冗余清理，没有改 SIMD 生产实现
  - `dispatchapi` 现在的下一个高确定性入口已继续后移到 `2815+` 一带

## 2026-05-16 DispatchApi Facade Dispatch Tracking Empty Finally Cleanup

- 这一批继续留在 `dispatchapi.testcase`，没有切到新的 suite，只把候选区间推进到 `2796..3445` 的 facade/current-dispatch tracking 簇。
- 候选筛选过程：
  - 先逐段读取 `2796..3445`
  - 确认 `CurrentBackendHelpers_StayAligned_After_ControlPlaneSwitches` 的 `LOldVectorAsm` 未读取，outer `finally` 为空
  - 确认 9 个 façade tracking 测试都由内层 `RegisterBackend(...)` restore，outer `finally` 纯空
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - 删除 10 个方法中的纯空 outer `try/finally`
  - 删除 1 个方法中的未使用 `LOldVectorAsm`
  - 保留所有内层 `RegisterBackend(...)` restore、dispatch/facade 跟踪断言与 synthetic slot 断言不变
- 这轮额外做的卫生确认：
  - `git diff --check` 通过
  - `rg -n "LOldVectorAsm|finally$" ...dispatchapi.testcase.pas | sed -n '160,260p'` 显示高确定性候选继续后移到 `3447+`
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批依旧只是 `dispatchapi` 测试层冗余清理，没有改 SIMD 生产实现
  - `dispatchapi` 当前最值当的下一批入口已继续后移到 `3447+`

## 2026-05-16 DispatchApi SSE2 Impl Audit Empty Finally Cleanup

- 这一批继续留在 `dispatchapi.testcase`，没有切到 `direct`、`concurrent` 或生产实现，只把候选区段推进到 `5128..5459` 的 SSE2 实现审计簇。
- 候选筛选过程：
  - 先逐段读取 `5128..5459`
  - 确认 `Mul`、`I64x2 Compare`、`F32VectorMath` 这 3 条 SSE2 测试都带未读取的 `LOldVectorAsm`
  - 确认三者的 outer `finally` 都为空，真实资源释放只在内层 `LSourceLines.Free` 或普通流程控制里完成，没有任何 backend/table restore
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - 删除 3 个方法中的纯空 outer `try/finally`
  - 删除 3 个方法中的未使用 `LOldVectorAsm`
  - 保留所有 SSE2 source-shape 审计、dispatch/backend 断言与 parity 断言不变
- 这轮额外做的卫生确认：
  - `git diff --check` 通过
  - 再次复读 `5128..5462`，确认现在只剩内层真实释放逻辑与正常断言流
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批依旧只是 `dispatchapi` 测试层冗余清理，没有改 SIMD 生产实现
  - 当前方法已经收口到“小区段审计 -> 单簇修复 -> 单 suite release 验证 -> 立刻提交”，适合后续继续按同样节奏推进

## 2026-05-16 DispatchApi RISCVV And AVX512 Empty Finally Cleanup

- 这一批继续留在 `dispatchapi.testcase`，没有切到 `direct`、`concurrent` 或生产实现，只把候选区段推进到 `9358..10471` 的 `RISCVV/AVX512` 审计与 parity 簇。
- 候选筛选过程：
  - 先用 `rg -nUP "finally\\n\\s*end;"` 精确抓空 outer `finally`
  - 再逐段读取 `9358..10471`
  - 确认 1 条 `RISCVV` rounding register-source 测试和 4 条 `AVX512` mapping/shift/IEEE754 parity 测试都带未读取的 `LOldVectorAsm`
  - 确认这 5 条方法的 outer `finally` 全为空，真实资源释放只在内层 `LSourceLines.Free` 或正常流程里完成，没有任何 backend/table restore
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - 删除 5 个方法中的纯空 outer `try/finally`
  - 删除 5 个方法中的未使用 `LOldVectorAsm`
  - 保留所有 register-source、mapping、shift-boundary、IEEE754 与 reduction parity 断言不变
- 这轮额外做的卫生确认：
  - `git diff --check` 通过
  - 再次复读 `9358..10480`，确认现在只剩内层真实释放逻辑与正常断言流
  - 轻量后续定位显示，下一个高确定性入口已经后移到 `10570..10943` 的 capability/FMA 簇
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批依旧只是 `dispatchapi` 测试层冗余清理，没有改 SIMD 生产实现
  - `dispatchapi` 当前最值当的下一批入口已进一步后移到 `10570..10943` 的 backend-capability / AVX2-FMA 合同测试簇

## 2026-05-16 DispatchApi Capability And AVX2 FMA Empty Finally Cleanup

- 这一批继续留在 `dispatchapi.testcase`，没有切到 `direct`、`concurrent` 或生产实现，只把候选区段推进到 `10549..10944` 的 backend-capability / AVX2-FMA 合同测试簇。
- 候选筛选过程：
  - 先用 `rg -nUP "finally\\n\\s*end;"` 精确抓空 outer `finally`
  - 再逐段读取 `10549..10944`
  - 确认 5 条 capability 测试和 3 条 AVX2-FMA 合同测试都带未读取的 `LOldVectorAsm`
  - 确认这 8 条方法的 outer `finally` 全为空，没有任何 backend/table restore，也没有真实清理逻辑
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - 删除 8 个方法中的纯空 outer `try/finally`
  - 删除 8 个方法中的未使用 `LOldVectorAsm`
  - 保留所有 capability、masked/int/shuffle contracts、FMA witness 与 public ABI 能力位断言不变
- 这轮额外做的卫生确认：
  - `git diff --check` 通过
  - 再次复读 `10549..10944`，确认现在只剩正常断言流
  - 轻量后续定位显示，下一个高确定性入口已经后移到 `10946+` 的 `AVX2_WideFma_ExactInputs_FollowsHalfComposition` 一带，需要再区分 source-shape 内层释放和 outer 壳是否为空
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批依旧只是 `dispatchapi` 测试层冗余清理，没有改 SIMD 生产实现
  - `dispatchapi` 当前最值当的下一批入口已进一步后移到 `10946+` 的 AVX2 wide-FMA / source-shape 合同测试簇

## 2026-05-16 DispatchApi WideFma WideSelect And BackendCapability Empty Finally Cleanup

- 这一批继续留在 `dispatchapi.testcase` 及其同文件内相邻 contract testcase，没有切到 `direct`、`runtimeapi` 或生产实现，只把候选区段推进到 `10946..11435` 的 AVX2 wide-FMA / wide-select / RISCVV masked-ops / AVX512 capability 混合合同簇。
- 候选筛选过程：
  - 先逐段读取 `10946..11435`
  - 明确区分 `AVX2` wide/source-shape 测试里的内层 `LSourceLines.Free` 和外层空壳 `finally`
  - 确认 2 条 `AVX2` wide 测试、1 条 `X86MaskedFmaContract`、2 条 `RISCVVMaskedOpsContract`、3 条 `AVX512` capability 测试都带未读取的 `LOldVectorAsm`
  - 确认这 8 条方法的 outer `finally` 全为空，没有任何 backend/table restore、hook cleanup 或其他真实清理逻辑
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - 删除 8 个方法中的纯空 outer `try/finally`
  - 删除 8 个方法中的未使用 `LOldVectorAsm`
  - 保留所有内层 `LSourceLines.Free`、wide-FMA half-composition 断言、wide-select parity、hardware-FMA absence、RISCVV masked-ops/public-ABI 与 AVX512 capability rebuild 断言不变
- 这轮额外做的卫生确认：
  - 再次复读 `10946..11435`，确认现在只剩内层真实释放逻辑与正常断言流
  - 轻量后续定位显示，下一个高确定性入口已经后移到 `11438+` 的后续 backend-capability / public-ABI 合同区段，需要继续区分纯空 outer 壳和真实 restore
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批依旧只是 `dispatchapi` 与同文件 contract testcase 的测试层冗余清理，没有改 SIMD 生产实现
  - `dispatchapi` 当前最值当的下一批入口已进一步后移到 `11438+` 的后续 backend-capability / public-ABI 合同区段

## 2026-05-16 DispatchApi Neon Riscvv And AVX2 Shuffle Capability Empty Finally Cleanup

- 这一批继续留在 `dispatchapi.testcase`，没有切到 `direct`、`runtimeapi` 或生产实现，只把候选区段推进到 `11485..11825` 的 `NEON` / `RISCVV` backend-capability 与 `AVX2` shuffle/public-ABI 合同测试簇。
- 候选筛选过程：
  - 逐段读取 `11485..11825`
  - 确认 1 条 `NEON` capability rebuild、4 条 `RISCVV` capability expose/rebuild、4 条 `AVX2` shuffle/public-ABI 合同测试都带未读取的 `LOldVectorAsm`
  - 确认这 9 条方法的 outer `finally` 全为空，没有任何 backend/table restore、hook cleanup 或其他真实清理逻辑
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - 删除 9 个方法中的纯空 outer `try/finally`
  - 删除 9 个方法中的未使用 `LOldVectorAsm`
  - 保留所有 `NEON` / `RISCVV` capability expose/clear、`AVX2` shuffle fallback、slot-native 与 public ABI 位断言不变
- 这轮额外做的卫生确认：
  - 再次复读 `11485..11825`，确认现在只剩正常断言流
  - 轻量后续定位显示，下一个高确定性入口已经后移到 `12026+` 的后续 AVX2 facade/public-ABI/source-shape 合同区段，需要继续区分内层真实释放与 outer 空壳
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批依旧只是 `dispatchapi` 测试层冗余清理，没有改 SIMD 生产实现
  - `dispatchapi` 当前最值当的下一批入口已进一步后移到 `12026+` 的 AVX2 facade/public-ABI/source-shape 合同区段

## 2026-05-16 DispatchApi X86 Override Reuse And Semantic Parity Empty Finally Cleanup

- 这一批继续留在 `dispatchapi.testcase`，没有切到 `direct`、`runtimeapi` 或生产实现，只把候选区段推进到 `11960..12580` 的 x86 override-reuse/source-shape 与 runtime semantic parity 合同测试簇。
- 候选筛选过程：
  - 逐段读取 `11960..12580`
  - 明确区分前 3 条 override/source-shape 审计里的内层 `LSourceLines.Free` 和外层空壳 `finally`
  - 确认 3 条 x86 override-reuse 测试和 4 条 x86 semantic parity 测试都带未读取的 `LOldVectorAsm`
  - 确认这 7 条方法的 outer `finally` 全为空，没有任何 backend/table restore、hook cleanup 或其他真实清理逻辑
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - 删除 7 个方法中的纯空 outer `try/finally`
  - 删除 7 个方法中的未使用 `LOldVectorAsm`
  - 保留所有 `LSourceLines.Free`、override-reuse/source-shape、dispatchable runtime parity 与 backend/slot 断言不变
- 这轮额外做的卫生确认：
  - 再次复读 `11960..12580`，确认现在只剩内层真实释放逻辑与正常断言流
  - 轻量后续定位显示，下一个高确定性入口已经后移到 `12583+` 的后续 AVX512 facade/source-shape 合同区段，需要继续区分内层真实释放与 outer 空壳
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批依旧只是 `dispatchapi` 测试层冗余清理，没有改 SIMD 生产实现
  - `dispatchapi` 当前最值当的下一批入口已进一步后移到 `12583+` 的 AVX512 facade/source-shape 合同区段

## 2026-05-16 DispatchApi AVX512 PassThrough And X86 Shuffle Capability Empty Finally Cleanup

- 这一批继续留在 `dispatchapi.testcase`，没有切到 `direct`、`runtimeapi` 或生产实现，只把候选区段推进到 `12548..12692` 的 AVX512 pass-through/source-shape 与 x86 shuffle capability rebuild 合同测试簇。
- 候选筛选过程：
  - 逐段读取 `12548..12692`
  - 明确区分 `AVX512` pass-through/source-shape 审计里的内层 `LSourceLines.Free` 和外层空壳 `finally`
  - 确认 1 条 `AVX512` source-shape/pass-through 测试和 1 条 x86 grouped capability rebuild 测试都带未读取的 `LOldVectorAsm`
  - 确认这 2 条方法的 outer `finally` 全为空，没有任何 backend/table restore、hook cleanup 或其他真实清理逻辑
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - 删除 2 个方法中的纯空 outer `try/finally`
  - 删除 2 个方法中的未使用 `LOldVectorAsm`
  - 保留所有 `LSourceLines.Free`、pass-through wrapper/source-shape、cloned-slot 复用与 x86 shuffle capability clear 断言不变
- 这轮额外做的卫生确认：
  - 再次复读 `12548..12692`，确认现在只剩内层真实释放逻辑与正常断言流
  - 轻量后续定位显示，下一个高确定性入口已经后移到 `12997+` 的后续 AVX2/AVX512 runtime parity 合同区段
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批依旧只是 `dispatchapi` 测试层冗余清理，没有改 SIMD 生产实现
  - `dispatchapi` 当前最值当的下一批入口已进一步后移到 `12997+` 的 AVX2/AVX512 runtime parity 合同区段

## 2026-05-16 DispatchApi NonX86 Wide Slot Contract Empty Finally Cleanup

- 这一批继续留在 `dispatchapi.testcase` 与相邻 `TTestCase_NonX86BackendParity`，没有切到 `direct`、`runtimeapi` 或生产实现，只把候选区段推进到 `12945..13340` 的 non-x86 wide slot 合同测试簇。
- 候选筛选过程：
  - 逐段读取 `12945..13340`
  - 确认 2 条 non-x86 wide-slot 测试都带未读取的 `LOldVectorAsm`
  - 确认这 2 条方法的 outer `finally` 全为空，没有任何 backend/table restore、hook cleanup 或其他真实清理逻辑
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - 删除 2 个方法中的纯空 outer `try/finally`
  - 删除 2 个方法中的未使用 `LOldVectorAsm`
  - 保留所有 wide slot native/scalar-reuse 例外断言与 `LCheckedBackends` 逻辑不变
- 这轮额外做的卫生确认：
  - 再次复读 `12945..13340`，确认现在只剩正常断言流
  - 轻量后续定位显示，下一个高确定性入口已经后移到 `13343+` 的后续 non-x86 runtime parity 合同区段
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批依旧只是 `dispatchapi` 测试层冗余清理，没有改 SIMD 生产实现
  - `dispatchapi` 当前最值当的下一批入口已进一步后移到 `13343+` 的后续 non-x86 runtime parity 合同区段

## 2026-05-16 NonX86 Runtime Parity Empty Finally Cleanup

- 这一批继续留在 `TTestCase_NonX86BackendParity`，没有切到 `direct`、`runtimeapi` 或生产实现，只把候选区段推进到 `13343..14054` 的 non-x86 runtime parity 合同测试簇。
- 候选筛选过程：
  - 逐段读取 `13343..14054`
  - 确认 3 条 non-x86 runtime parity 测试都带未读取的 `LOldVectorAsm`
  - 确认这 3 条方法的 outer `finally` 全为空，没有任何 backend/table restore、hook cleanup 或其他真实清理逻辑
  - 同时确认相邻 `Test_NativeAlignedLoadAndZeroParity_WithVectorAsm_IfAvailable` 和 `Test_NativeWideIntegerMemoryEdgeParity_WithVectorAsm_IfAvailable` 含 `FreeAligned(...)`，不纳入本批
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - 删除 3 个方法中的纯空 outer `try/finally`
  - 删除 3 个方法中的未使用 `LOldVectorAsm`
  - 保留所有 dispatch-table / facade parity、slot-native 断言与 `LCheckedBackends` 逻辑不变
- 这轮额外做的卫生确认：
  - 再次复读 `13343..14054`，确认现在只剩正常断言流
  - 轻量后续定位显示，下一个高确定性入口已经后移到 `14056+`，但必须先跳过带 `FreeAligned(...)` 的真实清理测试
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批依旧只是 `dispatchapi` / `TTestCase_NonX86BackendParity` 的测试层冗余清理，没有改 SIMD 生产实现
  - 下一步应继续沿 `14056+` 往后找，但先跳过含 `FreeAligned(...)` 的真实清理测试，再收同级空壳

## 2026-05-16 NonX86 Wide Splat Dot Reduce Normalize Empty Finally Cleanup

- 这一批继续留在 `TTestCase_NonX86BackendParity`，没有切到 `direct`、`runtimeapi` 或生产实现，只把候选区段推进到 `14232..14865` 的 non-x86 wide/runtime parity 合同测试簇。
- 候选筛选过程：
  - 逐段读取 `14232..14865`
  - 确认 4 条测试都带未读取的 `LOldVectorAsm`
  - 确认这 4 条方法的 outer `finally` 全为空，没有任何 backend/table restore、hook cleanup 或其他真实清理逻辑
  - 同时确认相邻 `Test_NativeVectorMathParity_WithVectorAsm_IfAvailable` 的 `finally` 非空，不纳入本批
  - 同时延续前一批判断，`14056..14230` 的 `FreeAligned(...)` 真实清理测试继续排除
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - 删除 4 个方法中的纯空 outer `try/finally`
  - 删除 4 个方法中的未使用 `LOldVectorAsm`
  - 保留所有 splat/dot/reduce/normalize parity、NEON scalar-reuse 例外断言与 `LCheckedBackends` 逻辑不变
- 这轮额外做的卫生确认：
  - 再次复读 `14232..14865`，确认现在只剩正常断言流
  - 下一步若继续沿同一文件往后推进，应从 `14866+` 开始，但仍要先排除任何非空 `finally` 与真实资源释放
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批依旧只是 `dispatchapi` / `TTestCase_NonX86BackendParity` 的测试层冗余清理，没有改 SIMD 生产实现
  - 下一步若继续，应从 `14866+` 往后找，并继续跳过任何非空 `finally` 与真实资源释放测试

## 2026-05-16 NonX86 Helper And Core Parity Empty Finally Cleanup

- 这一批继续留在 `TTestCase_NonX86BackendParity`，没有切到 `direct`、`runtimeapi` 或生产实现，但为了提速，把 `14847..16921` 这段连续的 helper/core parity 空壳一次性收掉。
- 候选筛选过程：
  - 先逐段读取 `14847..15863`，确认前 5 条方法都同时带未读取 `LOldVectorAsm` 和空 outer `finally`
  - 再轻量外扩到 `15865..16921`，确认 `MinimalDispatchParity`、`ExtendedFloatParity`、`NarrowAndNotParity`、`DotParity`、`I16x32_CoreParity`、`I8x64_CoreParity`、`U32x16_U64x8_CoreParity` 这 7 条方法虽然没有 `LOldVectorAsm`，但 outer `finally` 同样完全为空
  - 同时把本轮停点固定在 `16923+`，不把 `WideInteger_FuzzSeed` 及其后续更长的 fuzz/mask/wide integer 段带进来
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - 删除 12 个方法中的纯空 outer `try/finally`
  - 删除前 5 个方法中的未使用 `LOldVectorAsm`
  - 保留所有 helper/core parity、slot presence、lane/mask/shift 断言与 `LChecked/LCheckedBackends` 逻辑不变
- 这轮额外做的卫生确认：
  - 改完后再用 `rg` 复核，目标区段已不再残留 `LOldVectorAsm` 或空 `finally`
  - 当前下一步若继续，应从 `16923+` 的 `WideInteger_FuzzSeed_Parity_IfAvailable` 往后推进，并继续先排除任何真实清理或非空 `finally`
- 本轮验证链：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
- fresh 结果：
  - `[BUILD] OK`
  - `[TEST] OK`
  - `[LEAK] OK`
- 当前阶段结论：
  - 这批依旧只是 `dispatchapi` / `TTestCase_NonX86BackendParity` 的测试层冗余清理，没有改 SIMD 生产实现
  - 下一步若继续，应从 `16923+` 的 `WideInteger_FuzzSeed_Parity_IfAvailable` 往后找，并继续先排除任何真实清理或非空 `finally`

## 2026-05-16 NonX86 Mask And Shift Empty Finally Cleanup

- 这一批继续留在 `TTestCase_NonX86BackendParity`，没有切到 `direct`、`runtimeapi` 或生产实现，只把候选区段推进到 `17092..19067` 的 compare/mask/shift/minmax parity 测试簇。
- 候选筛选过程：
  - 先逐段复核 `Test_WideInteger_FuzzSeed_Parity_IfAvailable`，确认它的 `finally` 会恢复 `RandSeed`，因此明确排除
  - 再确认 `WideCompareMaskParity`、`I32x4_BitwiseShiftParity`、`WideSignedBitwiseShiftParity`、`WideIntegerArithmeticMinMaxParity` 这 4 条方法都只剩空 outer `finally`
  - 这 4 条测试都只做 backend 注册/激活筛选、compare/mask helper、exact shift probe、bitwise/arithmetic/minmax parity 与 facade/helper 合同断言，没有任何 restore、hook cleanup 或资源释放
- 已完成的源码改动：
  - 文件：`tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas`
  - 删除 4 个方法中的纯空 outer `try/finally`
  - 为 `WideInteger_FuzzSeed` 补回与 `RandSeed` restore 配对的真实 outer `try`，不改任何 compare/mask/shift/minmax 断言逻辑
- 这轮额外做的卫生确认：
  - 改完后再次复读目标区段，确认 `WideInteger_FuzzSeed` 的真实恢复还在，同时把 `WideCompareMaskParity` 里残留的空 outer `try` 一并清掉
  - 首次 release 复验失败，`tests/fafafa.core.simd/logs/build.txt` 报 `fafafa.core.simd.dispatchapi.testcase.pas(17085,5) Fatal: (2003) Syntax error, "EXCEPT" expected but "END" found`；根因是补回 `FuzzSeed` outer `try` 时多留了一个 `end;`
  - 删除多余 `end;` 后再次执行固定最小验证，`git diff --check` 通过，且 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI` 返回 `[BUILD] OK`、`[TEST] OK`、`[LEAK] OK`
  - 当前下一步若继续，应从 `19069` 之后的收尾区域重新确认是否还存在同级空壳；若没有，就需要重新换一个更高价值入口，而不是机械扫尾

## 2026-05-16 Completion Audit Reset

- 接手上一轮后，先停止继续扫 `dispatchapi.testcase` 的空壳 `finally`，改按真正的 release closeout 判据收口。
- 当前工作树真实状态复核：
  - `git status --short --branch` 为 `## main...origin/main [ahead 257]`
  - 额外出现了一个未跟踪生成物：`tests/fafafa.core.simd/__pycache__/`
- 先对齐了当前 high-signal 证据：
  - `git diff --check`
  - Release `TTestCase_DispatchAPI`
  - `check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - `check_nonx86_key_slot_audit.py`
  - `check_nonx86_helper_semantics.py`
  - `check_nonx86_wiring_sync.py`
  - Release `check`
  - 结果都已是绿
- 随后回到 `freeze-status` 真判据，当前剩余红点被重新压缩为两类：
  - Linux/QEMU 侧：`qemu-cpuinfo-nonx86-evidence=SKIP`
  - Windows closeout 侧：freshness / source-newer-than-evidence / verify / closeout freshness
- 这意味着当前更真实的 stop-point 已经不是“继续扫源码冗余”，而是：
  - 先跑 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh qemu-cpuinfo-nonx86-evidence`
  - 再跑 `bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight`
  - 如果 Windows 仍是外部阻塞，就按 blocker 收口，不再继续本地盲修

- 按这个小闭环继续向前推进后，最新实证已经进一步收口：
  - 首次直接跑 `qemu-cpuinfo-nonx86-evidence` 时，`linux/arm/v7`、`linux/arm64`、`linux/riscv64` 都在 Docker API 处 `permission denied`
  - 这一步确认 Linux blocker 不是 SIMD 代码回归，而是本地 Docker 权限
  - 申请提权后，同一条 `qemu-cpuinfo-nonx86-evidence` 在 3 个平台上全部 PASS
- 为了把这份 QEMU 证据写回 canonical `gate_summary.md`，随后按 `freeze-status` 给出的官方命令重跑了：
  - `FAFAFA_BUILD_MODE=Release SIMD_QEMU_PLATFORMS='linux/arm/v7 linux/arm64 linux/riscv64' SIMD_GATE_QEMU_NONX86_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1 SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT=0 SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=0 SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - 结果：主链 gate steps 与 QEMU CPUInfo evidence 已全部 PASS；整个 gate 只因旧 `windows_b07_gate.log` 的 `evidence-verify` 失败而返回非零
- 最新 `freeze-status` 复核结果：
  - `linux_gate_required_steps_mainline: PASS`
  - `linux_qemu_cpuinfo_nonx86_evidence: PASS`
  - `linux_qemu_cpuinfo_nonx86_evidence_platforms: PASS`
  - 当前唯一剩余 cross red item 是 `cross_gate_required_steps: evidence-verify=FAIL`
  - 其余红点全部来自旧 Windows evidence freshness / source-newer-than-evidence / verify / closeout freshness
- Windows 侧也补做了当前真预检：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight`
  - 结果：`[PREFLIGHT] STATUS=PASS CODE=OK EXIT=0`
  - 说明当前不是 workflow 入口、账单预检或 24h 内失败 run 在阻塞
- 随后直接尝试：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-via-gh SIMD-20260516-152`
  - 结果并不是平台拒绝，而是本地脚本 fail-close：`Refuse dispatch: local worktree has uncommitted changes.`
  - 因而当前最真实的下一步已经缩到 repo hygiene：清掉本轮 scratch 改动与 `tests/fafafa.core.simd/__pycache__/`，提交后再重试 GH Windows evidence

- 为了把这个 hygiene 挡板彻底排除：
  - 已删除 `tests/fafafa.core.simd/__pycache__/`
  - 已确认 `git diff --check` 通过
  - 已提交本轮 scratch closeout：`731cc0d7 docs(simd): record closeout audit reset state`
  - 已推送 `origin/main`，远端 `main` 从 `cf395b0f` 前进到 `731cc0d7`
- 随后再次执行：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-via-gh SIMD-20260516-152`
  - 首次重试因为 remote ref 仍落后于本地 `HEAD` 被脚本拒绝；推送后再次重试成功 dispatch
  - GitHub Actions run id：`25967172435`
- 这次终于拿到了远端最终结论：
  - `win-evidence-preflight` 在 dispatch 前仍是 `STATUS=PASS CODE=OK EXIT=0`
  - 但 run `25967172435` 在 `Prepare Windows SIMD Source` 阶段 4 秒内失败
  - 注解：`The job was not started because recent account payments have failed or your spending limit needs to be increased`
  - `Collect Windows B07 Evidence` job 根本没有真正启动
  - wrapper 最终以 `Billing/runner block detected (exit=31)` 收口
- 因而本轮 closeout audit 的最终 stop-point 已非常明确：
  - Linux/QEMU/mainline-required steps 已全部 fresh 变绿
  - 当前 freeze-status 剩余红项全部来自旧 Windows evidence 还没法被新 run 刷新
  - 根因不是本地 SIMD 实现、runner parity 或 closeout 方法，而是 GitHub Actions billing/runner 外部阻塞

## 2026-05-17 Closeout Doc Truth-Sync

- 继续加强 SIMD 审查时，没有重新打开生产实现或 family policy，而是先检查 active closeout 文档是不是还在说旧真相。
- 先对比了 active docs 与脚本真行为：
  - `docs/fafafa.core.simd.closeout.md`
  - `docs/fafafa.core.simd.checklist.md`
  - `docs/fafafa.core.simd.implementation-matrix.md`
  - `tests/fafafa.core.simd/BuildOrTest.sh`
- 这轮确认的真实 doc drift 是：
  - 文档还把 `qemu-nonx86-evidence` 和 `qemu-cpuinfo-nonx86-evidence` 混写成同一类 “Linux QEMU 已完成”
  - 但脚本当前明确是双轨：
    - `closeout-host-local` / `gate-strict` 主要消费 `qemu-nonx86-evidence`
    - canonical `gate` / `freeze-status` / `win-closeout-finalize` 另外要求 `qemu-cpuinfo-nonx86-evidence`
  - 顶层 stop-point 也还停在旧的 `2026-05-08` / `qemu-cpuinfo-nonx86-evidence=SKIP` 口径，没有反映 `2026-05-16` Linux CPUInfo cross evidence 已补绿、Windows blocker 已具体收敛到 GH run `25967172435`
- 已完成的文档修正：
  - `docs/fafafa.core.simd.closeout.md`
    - 顶部 stop-point 更新到 `2026-05-17`
    - 明确 Linux 侧 `qemu-cpuinfo-nonx86-evidence` 已在 `2026-05-16 20:43:40` PASS
    - 明确 Windows blocker 是 GH run `25967172435` 的 billing / spending limit 失败
    - 补写 `qemu-nonx86-evidence` 与 `qemu-cpuinfo-nonx86-evidence` 的双轨语义
    - 顺手修正了顶部重复的 interface completeness 结果行，以及 “完成了 5 组工作” 和实际 8 组条目的数量漂移
  - `docs/fafafa.core.simd.checklist.md`
    - 顶部 stop-point 更新到 `2026-05-17`
    - 明确 `closeout-host-local` 绿不等于 `freeze-status` 绿
    - 补入 `qemu-cpuinfo-nonx86-evidence` / canonical cross gate 的单独命令与说明
  - `docs/fafafa.core.simd.implementation-matrix.md`
    - 在 current focus 增加一条 guard：不要把 `qemu-nonx86-evidence` 和 `qemu-cpuinfo-nonx86-evidence` 混成同一条 lane
- 本轮最小验证：
  - `git diff --check`
  - `rg -n "2026-05-17 当前收口判断|25967172435|qemu-cpuinfo-nonx86-evidence|closeout-host-local.*qemu-nonx86-evidence|code-green / release-evidence-blocked" docs/fafafa.core.simd.closeout.md docs/fafafa.core.simd.checklist.md docs/fafafa.core.simd.implementation-matrix.md`
  - 结果：通过；active 文档里的关键事实和双轨语义已能直接搜到
- 当前阶段结论：
  - 这批仍然没有改 SIMD 生产实现
  - 修掉的是 active truth-source 文档的真实歧义和 stop-point 漂移
  - 下次继续 closeout 时，不会再因为旧文档把 `closeout-host-local`、`qemu-nonx86-evidence`、`qemu-cpuinfo-nonx86-evidence`、`freeze-status` 误读成一条链

## 2026-05-17 SSE2 Transitional Non-x86 Fail-Close

- 这轮不再重开 Windows evidence，也不再泛扫 `dispatchapi`；先把范围压到 `intrinsics.sse2 transitional debt` 的一个真实契约问题上。
- 已复核：
  - `src/fafafa.core.simd.intrinsics.sse2.pas`
  - `tests/fafafa.core.simd.intrinsics.experimental/fafafa.core.simd.intrinsics.experimental.testcase.pas`
  - `docs/SIMD_SSE2_MIGRATION_MAP.md`
  - `docs/SIMD_INTRINSICS_DISPOSITION.md`
  - `docs/plans/2026-05-09-simd-sse2-retire-target-plan.md`
- 当前结论：
  - x86 experimental 路径有真实测试和 raw include；
  - non-x86 experimental 路径没有 runtime 证据，却仍暴露大量 placeholder body；
  - 下一步应把 non-x86 runtime 收成 fail-close，而不是继续给 placeholder 补伪语义。
- 已完成收口：
  - `src/fafafa.core.simd.intrinsics.sse2.pas` 新增 `EnsureExperimentalSse2TargetSupported`
  - non-x86 placeholder 段新增注释，明确它只保留 compile scaffolding
  - `docs/SIMD_INTRINSICS_DISPOSITION.md` 与 `docs/SIMD_SSE2_MIGRATION_MAP.md` 已同步到相同口径
- 最小验证结果：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_sse2_structure.py --summary-line`
  - `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test`
  - `FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1 bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test`
  - 结果：全部通过；默认拒绝链和 x86 opt-in 实验链都未被误伤

## 2026-05-17 AVX Hold-Lane Truth Sync

- 继续沿 experimental intrinsics 的高确定性边界推进，没有回到 stable adapter 或 Windows closeout。
- 已复核：
  - `src/fafafa.core.simd.intrinsics.avx.pas`
  - `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh`
  - `docs/SIMD_INTRINSICS_DISPOSITION.md`
  - `docs/plans/2026-05-09-simd-family-matrix.md`
  - `docs/plans/2026-05-09-simd-experimental-hold-future-trigger-plan.md`
- 当前结论：
  - `intrinsics.avx` 现在没有任何仓库内 bridge consumer，旧源文件头口径已经漂移；
  - family matrix 当前也把 `AVX` verification lane 写成了 “experimental-intrinsics isolation only”，但实际还存在 `check_avx_backend_smoke`；
  - 下一步应把源码头注释、non-x86 runtime 边界和 active docs 一起收正。
- 已完成收口：
  - `src/fafafa.core.simd.intrinsics.avx.pas` 新增 `EnsureExperimentalAvxTargetSupported`
  - `AVX` 源文件头已去掉 “internal bridge for AVX2-focused tests” 的陈旧口径
  - `docs/SIMD_INTRINSICS_DISPOSITION.md` 与 `docs/plans/2026-05-09-simd-family-matrix.md` 已同步到当前 truth
- 最小验证结果：
  - `git diff --check`
  - `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test`
  - `FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1 bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test`
  - 结果：全部通过；`check_avx_backend_smoke`、默认拒绝链与 x86 opt-in 实验链都未被误伤

## 2026-05-17 X86 Experimental Lane Fail-Close Batch

- 继续沿同类问题批量收口，没有切回 stable adapter 或 release closeout。
- 已复核：
  - `src/fafafa.core.simd.intrinsics.sse3.pas`
  - `src/fafafa.core.simd.intrinsics.sse41.pas`
  - `src/fafafa.core.simd.intrinsics.sse42.pas`
  - `src/fafafa.core.simd.intrinsics.avx512.pas`
  - `src/fafafa.core.simd.intrinsics.fma3.pas`
  - `tests/fafafa.core.simd/check_intrinsics_experimental_status.py`
  - `docs/SIMD_INTRINSICS_DISPOSITION.md`
- 当前结论：
  - 这 5 个单元和已收口的 `SSE2/AVX` 属于同一类 x86-only experimental lane；
  - 之前缺的是 target-specific runtime guard，不是 generic experimental guard；
  - 下一步应把 guard 和 checker 一起收口，避免以后又回退成“只剩 opt-in 宏，但 non-x86 还能静默运行 placeholder”。
- 已完成收口：
  - `src/fafafa.core.simd.intrinsics.sse3.pas`
  - `src/fafafa.core.simd.intrinsics.sse41.pas`
  - `src/fafafa.core.simd.intrinsics.sse42.pas`
  - `src/fafafa.core.simd.intrinsics.avx512.pas`
  - `src/fafafa.core.simd.intrinsics.fma3.pas`
  - `tests/fafafa.core.simd/check_intrinsics_experimental_status.py`
  - `docs/SIMD_INTRINSICS_DISPOSITION.md`
  现在都已同步到 “x86-only experimental runtime / non-x86 fail-close” 口径。
- 最小验证结果：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_intrinsics_experimental_status.py --summary-line`
  - `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test`
  - `FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1 bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test`
  - 结果：全部通过；新的静态护栏、默认拒绝链和 x86 opt-in 实验链都未被误伤

## 2026-05-17 AES SHA Hold-Lane Truth Sync

- 这轮没有继续改代码，而是收一处 hold family 的 active docs 真相漂移。
- 已复核：
  - `docs/SIMD_INTRINSICS_DISPOSITION.md`
  - `docs/plans/2026-05-09-simd-family-matrix.md`
  - `docs/plans/2026-05-09-simd-experimental-hold-future-trigger-plan.md`
  - `tests/fafafa.core.simd.intrinsics.experimental/fafafa.core.simd.intrinsics.experimental.testcase.pas`
- 当前结论：
  - `AES/SHA` 现在不只是 isolation-only；
  - 当前真实 lane 还包含 default-reject + placeholder semantics 实验测试；
  - 但这条 lane 只是在锁 experimental contract，不是 stable leaf / stable adapter contract。

## 2026-05-17 SVE SVE2 LASX Hold-Family Runtime Fail-Close

- 继续沿 hold-family 小闭环推进，没有回到 Windows evidence、stable adapter 或大范围 redundancy 扫描。
- 已复核：
  - `src/fafafa.core.simd.cpuinfo.pas`
  - `src/fafafa.core.simd.intrinsics.sve.pas`
  - `src/fafafa.core.simd.intrinsics.sve2.pas`
  - `src/fafafa.core.simd.intrinsics.lasx.pas`
  - `tests/fafafa.core.simd/check_intrinsics_experimental_status.py`
  - `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh`
  - `docs/SIMD_INTRINSICS_DISPOSITION.md`
  - `docs/plans/2026-05-09-simd-family-matrix.md`
  - `docs/plans/2026-05-09-simd-experimental-hold-future-trigger-plan.md`
- 当前结论：
  - `SVE/SVE2/LASX` 原先都只有 generic experimental guard，没有 target-specific runtime qualification；
  - 这会让 non-qualified host 在打开 experimental define 后也静默装载 hold-family placeholder semantics；
  - `cpuinfo` 已足够先把 `SVE/SVE2` 收紧到 base-`SVE` 资格，`LASX` 则至少要先对非 `LoongArch64` 主机 fail-close。
- 已完成收口：
  - `src/fafafa.core.simd.cpuinfo.pas` 新增 `HasSVE`
  - `src/fafafa.core.simd.intrinsics.sve.pas`
  - `src/fafafa.core.simd.intrinsics.sve2.pas`
  - `src/fafafa.core.simd.intrinsics.lasx.pas`
  - `tests/fafafa.core.simd/check_intrinsics_experimental_status.py`
  - `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh`
  - `docs/SIMD_INTRINSICS_DISPOSITION.md`
  - `docs/plans/2026-05-09-simd-family-matrix.md`
  - `docs/plans/2026-05-09-simd-experimental-hold-future-trigger-plan.md`
  现在都已同步到 “hold family + target-specific runtime fail-close” 口径。
- 本批串行验证已经 fresh 跑通：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_intrinsics_experimental_status.py --summary-line`
  - `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test`
  - `FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1 bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test`
- fresh 结果：
  - `INTRINSICS_EXPERIMENTAL_SUMMARY ... missing_x86_runtime_fail_close=0 missing_hold_runtime_fail_close=0`
  - 默认态 experimental intrinsics test：`[TEST] OK`、`[LEAK] OK`
  - experimental=1：`SVE/SVE2/LASX runtime reject smoke` 在当前 `x86_64` 主机全部 `[CHECK] OK`
  - experimental=1 主测试程序：`[TEST] OK`、`[LEAK] OK`
- 当前阶段结论：
  - 这批没有把 `SVE/SVE2/LASX` promote 进 stable lane
  - 修掉的是 hold-family experimental runtime 在 non-qualified host 上“误装载”的边界漏洞
  - 当前仍保留一个诚实 residual：`LASX` 还没有 feature-level `cpuinfo` gate，文档已明确记账

## 2026-05-17 NEON RVV Qualification-Leaf Runtime Fail-Close

- 继续按小闭环推进，没有切去 stable adapter、Windows closeout 或 LoongArch cpuinfo 扩面。
- 已复核：
  - `src/fafafa.core.simd.intrinsics.neon.pas`
  - `src/fafafa.core.simd.intrinsics.rvv.pas`
  - `tests/fafafa.core.simd/check_intrinsics_experimental_status.py`
  - `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh`
  - `docs/SIMD_INTRINSICS_DISPOSITION.md`
  - `docs/plans/2026-05-09-simd-family-matrix.md`
- 当前结论：
  - `intrinsics.neon/rvv` 之前仍允许 non-qualified host 在 experimental=1 下静默装载；
  - 这和当前 `experimental isolated` / qualification-family truth 不一致；
  - 应该把 leaf runtime 收紧到 `cpuinfo` 已确认的 `NEON/RVV` 主机，但不去碰 `simd.neon/simd.riscvv` 的 adapter lane 判据。
- 已完成收口：
  - `src/fafafa.core.simd.intrinsics.neon.pas`
  - `src/fafafa.core.simd.intrinsics.rvv.pas`
  - `tests/fafafa.core.simd/check_intrinsics_experimental_status.py`
  - `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh`
  - `docs/SIMD_INTRINSICS_DISPOSITION.md`
  - `docs/plans/2026-05-09-simd-family-matrix.md`
  现在都已同步到 “qualification-family leaf runtime 只在对应 ISA 主机放行” 口径。
- 本批串行验证已经 fresh 跑通：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_intrinsics_experimental_status.py --summary-line`
  - `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test`
  - `FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1 bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test`
- fresh 结果：
  - `INTRINSICS_EXPERIMENTAL_SUMMARY ... missing_qualification_runtime_fail_close=0`
  - 默认态 experimental intrinsics test：`[TEST] OK`、`[LEAK] OK`
  - experimental=1：`NEON/RVV` runtime reject smoke 在当前 `x86_64` 主机全部 `[CHECK] OK`
  - experimental=1 主测试程序：`[TEST] OK`、`[LEAK] OK`
- 当前阶段结论：
  - 这批仍然没有 promote `NEON/RISCVV`
  - 修掉的是 qualification-family experimental leaf 在 non-qualified host 上“误装载”的边界漏洞
  - `NEON/RISCVV` adapter qualification lane 与 leaf runtime qualification 现在比之前更清楚地分开了

## 2026-05-17 SVE2 Exact Runtime Qualification

- 继续按小闭环推进，没有去碰 `LASX cpuinfo`、non-x86 adapter promote 或 broader ARM feature taxonomy。
- 已复核：
  - `src/fafafa.core.simd.cpuinfo.base.pas`
  - `src/fafafa.core.simd.cpuinfo.arm.pas`
  - `src/fafafa.core.simd.cpuinfo.pas`
  - `src/fafafa.core.simd.intrinsics.sve2.pas`
  - `tests/fafafa.core.simd/check_intrinsics_experimental_status.py`
  - `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh`
  - `docs/SIMD_INTRINSICS_DISPOSITION.md`
  - `docs/plans/2026-05-09-simd-family-matrix.md`
  - `docs/plans/2026-05-09-simd-experimental-hold-future-trigger-plan.md`
- 当前结论：
  - `SVE2` 的真实 residual 不是缺 reject，而是 reject 条件还停在 base-`SVE`
  - 本机头文件给出了 `HWCAP2_SVE2` 直接证据，因此这条可以落成真实实现，而不是继续停在文档近似
  - `intrinsics.sve2` 对 `intrinsics.sve` 的依赖会让非 `AArch64` 主机先命中上游 `SVE` fail-close；smoke 需要诚实接受这条验证细节
- 已完成收口：
  - `src/fafafa.core.simd.cpuinfo.base.pas`
  - `src/fafafa.core.simd.cpuinfo.arm.pas`
  - `src/fafafa.core.simd.cpuinfo.pas`
  - `src/fafafa.core.simd.intrinsics.sve2.pas`
  - `tests/fafafa.core.simd/check_intrinsics_experimental_status.py`
  - `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh`
  - `docs/SIMD_INTRINSICS_DISPOSITION.md`
  - `docs/plans/2026-05-09-simd-family-matrix.md`
  - `docs/plans/2026-05-09-simd-experimental-hold-future-trigger-plan.md`
  现在都已同步到 “`SVE2` 需要 `cpuinfo` 报告 `SVE2`” 的精确资格口径。
- 本批串行验证已经 fresh 跑通：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_intrinsics_experimental_status.py --summary-line`
  - `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test`
  - `FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1 bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test`
- fresh 结果：
  - `INTRINSICS_EXPERIMENTAL_SUMMARY ... missing_hold_runtime_fail_close=0 missing_qualification_runtime_fail_close=0`
  - 默认态 experimental intrinsics test：`[TEST] OK`、`[LEAK] OK`
  - experimental=1：`SVE2` runtime reject smoke 已 `[CHECK] OK`
  - experimental=1 主测试程序：`[TEST] OK`、`[LEAK] OK`
- 当前阶段结论：
  - 这批没有把 `SVE2` promote 进 stable lane
  - 修掉的是 `SVE2` experimental leaf 从 base-`SVE` 近似资格到 exact `SVE2` 资格的残余漏洞
  - 当前最像下一刀真实 blocker 的仍是 `LASX` 没有 feature-level `cpuinfo` gate

## 2026-05-17 LASX Cpuinfo Feature-Level Qualification

- 继续按“小闭环、真判据、真验证”推进，这一批只围绕 `LASX` 最后那条 feature-level qualification 残余，没有重开 broader simd 扫描。
- 已复核：
  - `src/fafafa.core.settings.inc`
  - `src/fafafa.core.simd.cpuinfo.base.pas`
  - `src/fafafa.core.simd.cpuinfo.pas`
  - `src/fafafa.core.simd.cpuinfo.lazy.pas`
  - `src/fafafa.core.simd.cpuinfo.diagnostic.pas`
  - `src/fafafa.core.simd.intrinsics.lasx.pas`
  - `tests/fafafa.core.simd.cpuinfo/*`
  - `tests/fafafa.core.simd/check_intrinsics_experimental_status.py`
  - `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh`
- 已完成收口：
  - `src/fafafa.core.settings.inc` 新增 `SIMD_LOONGARCH_AVAILABLE`
  - `src/fafafa.core.simd.cpuinfo.base.pas` 新增 `caLoongArch` 与 `TLoongArchFeatures`
  - `src/fafafa.core.simd.cpuinfo.loongarch.pas` 新增最小 LoongArch cpuinfo 叶子，只建模 `HasLASX` + raw `LinuxHWCAP`
  - `src/fafafa.core.simd.cpuinfo.pas` / `lazy.pas` / `diagnostic.pas` 已接入 `HasLASX`
  - `src/fafafa.core.simd.intrinsics.lasx.pas` 现在要求 `cpuinfo` 报告 `LASX`
  - `tests/fafafa.core.simd.cpuinfo` 已补 `LoongArch` 快速语义检查，non-x86 cache parity 也已纳入 `caLoongArch`
  - `docs/SIMD_INTRINSICS_DISPOSITION.md`、`docs/plans/2026-05-09-simd-family-matrix.md`、`docs/plans/2026-05-09-simd-experimental-hold-future-trigger-plan.md`、`docs/fafafa.core.simd.cpuinfo.md` 已同步
  - `docs/fafafa.core.simd.closeout.md` 已补回 `check_nonx86_helper_semantics.py` 要求的 closeout 片段
- 本批 fresh 验证已经串行跑通：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_intrinsics_experimental_status.py --summary-line`
  - `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test`
  - `FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1 bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test`
  - `bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `INTRINSICS_EXPERIMENTAL_SUMMARY ... missing_hold_runtime_fail_close=0 missing_qualification_runtime_fail_close=0`
  - 默认态/experimental 态 `intrinsics.experimental` 测试均 `[TEST] OK`
  - `LASX runtime reject smoke` 在当前 `x86_64` 主机 `[CHECK] OK`
  - `cpuinfo` 测试 `[TEST] OK`
  - `simd check` 最终恢复 `[CHECK] OK`
- 当前阶段结论：
  - `LASX` 现在不再停留在“只要是 `LoongArch64` experimental host 就放行”的近似 contract
  - 这批仍然没有 promote `LASX` 进入 stable adapter / backend lane
  - 当前收口的是 experimental leaf 的 feature-level qualification，不是 stable family 决策变化

## 2026-05-17 Experimental X86 Header Truth Sync And Python Cache Hygiene

- 本轮明确改工作方法：
  - 不再继续大范围 SIMD 泛扫
  - 先用当前 `git status` 和 x86 hold-lane 复核挑一个最小真问题
  - 只做与问题严格匹配的修复和验证
- 已复核：
  - `.gitignore`
  - `src/fafafa.core.simd.intrinsics.avx.pas`
  - `src/fafafa.core.simd.intrinsics.sse3.pas`
  - `src/fafafa.core.simd.intrinsics.sse41.pas`
  - `src/fafafa.core.simd.intrinsics.sse42.pas`
  - `src/fafafa.core.simd.intrinsics.avx512.pas`
  - `src/fafafa.core.simd.intrinsics.fma3.pas`
  - `docs/SIMD_INTRINSICS_DISPOSITION.md`
  - `docs/plans/2026-05-09-simd-family-matrix.md`
- 当前结论：
  - x86 hold-lane 当前没有新的 runtime qualification 漏口
  - 但 `sse3/sse41/sse42/avx512/fma3` 的源码头说明明显落后于 disposition/runtime 真相
  - `.gitignore` 缺 `__pycache__/` 规则，当前已出现 `tests/fafafa.core.simd/__pycache__/` worktree 噪音
- 已完成收口：
  - `src/fafafa.core.simd.intrinsics.sse3.pas`
  - `src/fafafa.core.simd.intrinsics.sse41.pas`
  - `src/fafafa.core.simd.intrinsics.sse42.pas`
  - `src/fafafa.core.simd.intrinsics.avx512.pas`
  - `src/fafafa.core.simd.intrinsics.fma3.pas`
  - `.gitignore`
  现在都已同步到“experimental x86 intrinsics lane + non-x86 runtime fail-close intentional”的显式口径，并把 Python cache 噪音纳入忽略规则。
- 已完成最小验证与卫生收口：
  - 已清掉现有 `tests/fafafa.core.simd/__pycache__/`
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_intrinsics_experimental_status.py --summary-line`
  - `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test`
  - `FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1 bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test`
- fresh 结果：
  - `INTRINSICS_EXPERIMENTAL_SUMMARY ... missing_x86_runtime_fail_close=0 missing_hold_runtime_fail_close=0 missing_qualification_runtime_fail_close=0`
  - 默认态/experimental 态 `intrinsics.experimental` 测试均 `[TEST] OK`
  - `check_intrinsics_comment_swallow.py --summary-line` 在两轮构建前检查均 `PASS`
  - `SSE3/AVX/AVX512/FMA3` x86 backend smoke 继续为绿，`NEON/RVV/SVE/SVE2/LASX` fail-close smoke 也继续为绿
- 当前阶段结论：
  - 这批没有重开 family promote 或 stable contract 讨论
  - 修掉的是一类真实但低成本的 truth drift 和工作树噪音源
  - 这一批收口后，下一轮仍应继续找“有直接证据的小问题”，而不是回到整面泛扫

## 2026-05-17 SIMD Generated Artifact Hygiene Cleanup

- 延续“小闭环”方法，没有去重跑大 gate，先用目录真相找下一个高价值小问题。
- 已复核：
  - `tests/fafafa.core.simd/.gitignore`
  - `tests/fafafa.core.simd/bin2-smoke/link60.res`
  - `tests/fafafa.core.simd/bin2-smoke/ppas.sh`
  - `tests/fafafa.core.simd/qemu_fafafa.core.simd.test_20260220-232704_195.core`
  - `tests/fafafa.core.simd/simd_test`
  - `tests/fafafa.core.simd/docker/run_rvv_opcode_smoke.sh`
  - `git log --diff-filter=A -- ...`
- 当前结论：
  - 这 4 个文件都属于生成产物，不是源码/fixture
  - `simd_test` 和 `qemu_...core` 的存在尤其会误导后续审查，把生成二进制和 crash 现场伪装成仓库内容
  - 本地 `.gitignore` 对这类产物的防护不完整，是它们能再次误入版本库的直接原因
- 已完成收口：
  - 删除 `tests/fafafa.core.simd/simd_test`
  - 删除 `tests/fafafa.core.simd/qemu_fafafa.core.simd.test_20260220-232704_195.core`
  - 删除 `tests/fafafa.core.simd/bin2-smoke/link60.res`
  - 删除 `tests/fafafa.core.simd/bin2-smoke/ppas.sh`
  - 更新 `tests/fafafa.core.simd/.gitignore`
  现在 `bin2-smoke`、无扩展名测试二进制和 core dump 都被明确划回“生成物/垃圾”而不是 repo 资产。
- 下一步做最小验证：
  - `git diff --check`
  - 复核 `git status --short` 中只剩预期删除/ignore 改动
  - 跑 1-2 条静态 SIMD 审查脚本确认这批卫生清理没有影响 checker 工作流
- 已完成最小验证：
  - `git diff --check`
  - `git check-ignore -v --no-index tests/fafafa.core.simd/simd_test tests/fafafa.core.simd/foo.core tests/fafafa.core.simd/bin2-smoke/dummy`
  - `python3 tests/fafafa.core.simd/check_simd_source_reachability.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_intrinsics_experimental_status.py --summary-line`
- fresh 结果：
  - 工作树只剩 `.gitignore` / scratch 更新和 4 个预期删除
  - ignore 命中：
    - `/simd_test`
    - `/*.core`
    - `/bin2-smoke/`
  - `SIMD_SOURCE_REACHABILITY_SUMMARY ... unexpected_unreachable=0 missing_include_refs=0`
  - `INTRINSICS_EXPERIMENTAL_SUMMARY ... missing_x86_runtime_fail_close=0 missing_hold_runtime_fail_close=0 missing_qualification_runtime_fail_close=0`
- 当前阶段结论：
  - 这批没有改动 SIMD 语义或测试 contract
  - 收掉的是仓库内已经被提交的生成垃圾和对应 ignore 漏口
  - 这能直接降低后续 SIMD 审查时的假信号和仓库体积噪音

## 2026-05-17 Register Truthfulness Gate Promotion

- 继续按“小闭环”推进，没有继续盲扫源码，而是从 fresh `Release check` 输出里抓门禁残余。
- 已复核：
  - `tests/fafafa.core.simd/BuildOrTest.sh`
  - `tests/fafafa.core.simd/buildOrTest.bat`
  - `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check` 的现状日志
- 当前结论：
  - 默认 `check` 里的 `[REG-TRUTH] SKIP ...` 不是设计必需，而是遗留 gating
  - `register truthfulness` 当前已经是纯静态 Python 审查，不依赖 opt-in backend 编译
  - 因而这是一条真实的默认门禁覆盖缺口，值得直接提升到主链
- 已完成收口：
  - `tests/fafafa.core.simd/BuildOrTest.sh`
  - `tests/fafafa.core.simd/buildOrTest.bat`
  - `plans/scratch/2026-04-08-simd-review/*`
  现在 shell/batch 的 `register truthfulness` 都默认同时审 `neon` + `riscvv`，`gate` 也不再把它当成 opt-in skip。
- 已完成 release 验证：
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- fresh 结果：
  - 默认 `check` 不再输出 `[REG-TRUTH] SKIP ...`
  - `check` 中已真实执行：
    - `NONX86_REGISTER_TRUTHFULNESS_SUMMARY backend=neon ... strict=0`
    - `NONX86_REGISTER_TRUTHFULNESS_SUMMARY backend=riscvv ... strict=0`
  - `gate` 中已真实执行：
    - `NONX86_REGISTER_TRUTHFULNESS_SUMMARY backend=neon ... strict=1`
    - `NONX86_REGISTER_TRUTHFULNESS_SUMMARY backend=riscvv ... strict=1`
  - release `gate` 最终继续 `[GATE] OK`
  - 仍然诚实保留旧的 optional Windows evidence verify skip，不属于本批回归
- 当前阶段结论：
  - 这批不是后端语义修复，而是默认门禁覆盖面的真实补强
  - 现在 non-x86 register ownership truth 已经进入日常 `check/gate` 主链，而不是只有 opt-in 环境下才会被看到

## 2026-05-17 Metadata Query Scope Guard

- 继续按“小闭环”推进，没有重开 family 级大扫，而是沿着 publication seam 往下收一层 metadata-query 边界。
- 已复核：
  - `src/fafafa.core.simd.runtime.pas`
  - `src/fafafa.core.simd.public_abi.impl.inc`
  - `src/fafafa.core.simd.backend.adapter.pas`
  - `tests/fafafa.core.simd/check_dispatch_read_scope.py`
  - `tests/fafafa.core.simd/BuildOrTest.sh`
  - `tests/fafafa.core.simd/buildOrTest.bat`
- 当前结论：
  - 现在只有 `dispatch-read-scope` 在守 `GetDispatchTable`
  - `GetBackendInfo` / `TryGetRegisteredBackendDispatchTable` / backend text getters 这条 metadata-query 边界还没被默认门禁固化
  - 当前 production 命中虽仍干净，但这属于“目前没漂、以后没人守”的真实 coverage gap
- 已完成收口：
  - 新增 `tests/fafafa.core.simd/check_metadata_query_scope.py`
  - shell/batch 都新增 `metadata-query-scope` action
  - 默认 `check` 已接入该 checker
  - `docs/fafafa.core.simd.maintenance.md` 已补这条新护栏说明
- 已完成最小验证：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_metadata_query_scope.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - 新 checker 直接输出 `METADATA_QUERY_SCOPE scanned_files=146 symbols=4 allowed_hits=18 forbidden_hits=0`
  - release `check` 中已真实执行：
    - `[METADATA-SCOPE] Running: python3 ... check_metadata_query_scope.py --summary-line --json-file ...`
    - `METADATA_QUERY_SCOPE scanned_files=146 symbols=4 allowed_hits=18 forbidden_hits=0`
  - 整体 release `check` 继续通过
- 当前阶段结论：
  - 这批依然不是 SIMD 语义修复，而是 seam-level 审查护栏补强
  - 现在不仅 `GetDispatchTable` 受默认门禁约束，metadata-query helper 的 production 边界也已经进入日常 `check` 主链

## 2026-05-17 Dataplane Consumer Scope Guard

- 继续按“小闭环”推进，没有重开新的 SIMD 语义面，而是顺着已有 `dispatch-read-scope` / `metadata-query-scope` 再补一层 dataplane consumer 边界固化。
- 已复核：
  - `src/fafafa.core.simd.dataplane.pas`
  - `src/fafafa.core.simd.public_abi.impl.inc`
  - `src/fafafa.core.simd.pas`
  - `src/fafafa.core.simd.direct.pas`
  - `tests/fafafa.core.simd/BuildOrTest.sh`
  - `tests/fafafa.core.simd/buildOrTest.bat`
- 当前结论：
  - production 命中面虽然仍干净，但默认 `check` 还没有 guard 去固定 `GetCurrentSimdDataPlane` / `GetCurrentSimdDataPlaneDispatch` / `RebindSimdDataPlane` 的消费边界
  - 这是一条真实的 seam-level coverage gap，不是当前 dataplane 语义 bug
- 已完成收口：
  - 新增 `tests/fafafa.core.simd/check_dataplane_consumer_scope.py`
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - 默认 `check` 已接入 `run_dataplane_consumer_scope`
    - shell action / usage / runner parity 自检字符串已补齐 `dataplane-consumer-scope`
  - `tests/fafafa.core.simd/buildOrTest.bat`
    - 已新增 `dataplane-consumer-scope` action
    - `:check` 主链已接入 `call :dataplane_consumer_scope`
    - usage 文本与 Python runtime fail-close 都已同步
  - `docs/fafafa.core.simd.maintenance.md`
    - 已把 `dataplane-consumer-scope` 补进默认 `check` 护栏说明
- 已完成最小验证：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_dataplane_consumer_scope.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - 新 checker 直接输出：
    - `DATAPLANE_CONSUMER_SCOPE scanned_files=146 symbols=3 allowed_hits=17 forbidden_hits=0`
  - release `check` 中已真实执行：
    - `[DATAPLANE-SCOPE] Running: python3 ... check_dataplane_consumer_scope.py --summary-line --json-file ...`
    - `DATAPLANE_CONSUMER_SCOPE scanned_files=146 symbols=3 allowed_hits=17 forbidden_hits=0`
  - `windows runner parity signatures present`
  - 整体 release `check` 最终继续通过
- 当前阶段结论：
  - 这批依然不是 SIMD 算法或 backend 语义修复
  - 收掉的是默认门禁对 `dataplane` publication-consumer seam 的最后一条明显漏口

## 2026-05-17 Direct Dispatch Scope Guard

- 继续按“小闭环”推进，没有回头重开 family 面，而是顺着 `direct dispatch companion` 再补一层默认门禁固化。
- 已复核：
  - `src/fafafa.core.simd.api.pas`
  - `src/fafafa.core.simd.arrays.pas`
  - `src/fafafa.core.simd.ops.pas`
  - `src/fafafa.core.simd.direct.pas`
  - `docs/SIMD_LAYERING_IMPLEMENTATION.md`
  - `docs/fafafa.core.simd.maintenance.md`
  - `tests/fafafa.core.simd/check_dispatch_read_scope.py`
  - `tests/fafafa.core.simd/BuildOrTest.sh`
  - `tests/fafafa.core.simd/buildOrTest.bat`
- 当前结论：
  - `GetDirectDispatchTable` 当前 production 命中面只有 `api/arrays/ops/direct` 四个文件，已经天然形成 companion fast-path 边界
  - 但默认 `check` 还没有 guard 去固定这条边界
  - 这是一条真实的 seam-level coverage gap，不是当前 direct/runtime 语义 bug
- 已完成收口：
  - 新增 `tests/fafafa.core.simd/check_direct_dispatch_scope.py`
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - 默认 `check` 已接入 `run_direct_dispatch_scope`
    - shell action / usage / runner parity 自检字符串已补齐 `direct-dispatch-scope`
  - `tests/fafafa.core.simd/buildOrTest.bat`
    - 已新增 `direct-dispatch-scope` action
    - `:check` 主链已接入 `call :direct_dispatch_scope`
    - usage 文本与 Python runtime fail-close 都已同步
  - `docs/fafafa.core.simd.maintenance.md`
    - 已把 `direct-dispatch-scope` 补进默认 `check` 护栏说明
- 已完成最小验证：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_direct_dispatch_scope.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - 新 checker 直接输出：
    - `DIRECT_DISPATCH_SCOPE symbol=GetDirectDispatchTable scanned_files=146 allowed_files=4 allowed_hits=70 forbidden_hits=0`
  - release `check` 中已真实执行：
    - `[DIRECT-SCOPE] Running: python3 ... check_direct_dispatch_scope.py --summary-line --json-file ...`
    - `DIRECT_DISPATCH_SCOPE symbol=GetDirectDispatchTable scanned_files=146 allowed_files=4 allowed_hits=70 forbidden_hits=0`
  - `windows runner parity signatures present`
  - 整体 release `check` 最终继续通过
- 当前阶段结论：
  - 这批依然不是 SIMD 算法或 backend 语义修复
  - 收掉的是默认门禁对 `direct dispatch companion` 使用边界的明显漏口

## 2026-05-17 Check Default Wiring-Sync Promotion

- 继续按“小闭环”推进，没有回头重开架构讨论，而是专门复核 `check` 主链里还剩什么真缺口。
- 已复核：
  - `tests/fafafa.core.simd/check_nonx86_wiring_sync.py`
  - `tests/fafafa.core.simd/BuildOrTest.sh`
  - `tests/fafafa.core.simd/buildOrTest.bat`
  - `docs/fafafa.core.simd.maintenance.md`
  - `tests/fafafa.core.simd/docs/intrinsics_coverage_workflow.md`
  - `docs/plans/2026-02-09-simd-nonx86-interface-target-checklist.md`
- 当前结论：
  - `gate` 早已默认包含 `wiring-sync`
  - 真正残留的覆盖缺口是 `check` 仍把它放在 `SIMD_CHECK_WIRING_SYNC=1` 的 opt-in 分支里
  - 但这条 checker 本身只是纯 Python 静态对账，不引入新的 Pascal 构建；direct strict run 与启用后的 Release `check` 都已证明它足够成熟
- 已完成收口：
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - `check` 已改成默认执行 `wiring-sync`
    - 仅在 `SIMD_CHECK_WIRING_SYNC=0` 时显式跳过
    - shell 里的 Windows batch parity 签名已同步改成 `if /I not "%SIMD_CHECK_WIRING_SYNC%"=="0" (`
  - `tests/fafafa.core.simd/buildOrTest.bat`
    - `check` 主链已改成默认执行 `wiring-sync`
    - 仅在 `%SIMD_CHECK_WIRING_SYNC%` 为 `0` 时跳过
  - 活跃文档与 scratch 真相已同步：
    - `docs/fafafa.core.simd.maintenance.md`
    - `tests/fafafa.core.simd/docs/intrinsics_coverage_workflow.md`
    - `docs/plans/2026-02-09-simd-nonx86-interface-target-checklist.md`
    - `plans/scratch/2026-04-08-simd-review/{task_plan,findings,progress}.md`
- 已完成最小验证：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_nonx86_wiring_sync.py --summary-line --strict-extra`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - strict checker 直接输出：
    - `WIRING_SYNC_SUMMARY legacy=60 grouped=60 helper=60 missing=0 extra=0 markers_missing=0 strict_extra=1 shared_legacy=1 shared_grouped=1`
  - release `check` 中已真实执行：
    - `[CHECK] wiring-sync`
    - `WIRING_SYNC_SUMMARY legacy=60 grouped=60 helper=60 missing=0 extra=0 markers_missing=0 strict_extra=0 shared_legacy=1 shared_grouped=1`
  - 整体 Release `check` 最终继续通过
- 当前阶段结论：
  - 这批依然不是 SIMD 算法或 backend 语义修复
  - 收掉的是默认 `check` 对 `wiring-sync` 的最后一处明显漏口

## 2026-05-17 Freeze Gate-Summary Fallback

- 继续按“小闭环”推进，这次不再扫算法面，而是直接核对 `freeze-status` 为什么和 active closeout 文档出现了真漂移。
- 已复核：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
  - `tests/fafafa.core.simd/logs/gate_summary.md`
  - `tests/fafafa.core.simd/BuildOrTest.sh`
  - `tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
  - `docs/fafafa.core.simd.closeout.md`
  - `docs/fafafa.core.simd.checklist.md`
- 当前结论：
  - `2026-05-16` 的 cross gate 的确证明过 `qemu-cpuinfo-nonx86-evidence` 可为 PASS
  - 但 `2026-05-17` 的 routine `gate` 又把 `logs/gate_summary.md` 刷成了 fast-gate 摘要，里面这一步回到 `SKIP`
  - `freeze-status` 虽然已有 fallback 机制，但当前只扫描 `logs/windows-closeout/<batch>/gate_summary.md`；仓库里没有这类 batch gate summary，且 routine gate 覆盖前也没自动备份，所以 closeout truth 会被最新 fast-gate 冲掉
- 已完成收口：
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - 新增 gate summary 覆盖前自动备份，目标目录为 `logs/rehearsal/backups/`
    - 备份同时保留同基名 `.json`（若存在）
  - `tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
    - `discover_gate_summary_candidates()` 已把 `logs/rehearsal/backups/gate_summary.backup.*.md` 纳入候选
    - fallback 说明文字已从“closeout gate snapshot”收正成更准确的通用“gate snapshot”
  - active 文档与 scratch 真相已同步：
    - `docs/fafafa.core.simd.closeout.md`
    - `docs/fafafa.core.simd.checklist.md`
    - `plans/scratch/2026-04-08-simd-review/{task_plan,findings,progress}.md`
- 预期收益：
  - 日常 `gate` 仍保持原有成本，不必强行把 `qemu-cpuinfo-nonx86-evidence` 抬进所有 routine run
  - 但 `freeze-status` 不会再因为“最后一次 gate 恰好是 fast-gate”而把较早的 closeout truth 完全遗失

## 2026-05-17 Linux CPUInfo Evidence Refresh Closeout

- 这轮不再重开 SIMD 结构/实现泛审查，只把当前唯一高价值的 closeout 证据跑完。
- 已完成的 canonical gate：
  - `FAFAFA_BUILD_MODE=Release SIMD_QEMU_PLATFORMS='linux/arm/v7 linux/arm64 linux/riscv64' SIMD_GATE_QEMU_NONX86_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1 SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT=0 SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=0 SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=0 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- fresh 结果：
  - `linux/arm/v7`、`linux/arm64`、`linux/riscv64` 的 QEMU CPUInfo evidence 全部 PASS
  - qemu summary: `/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd/logs/qemu-multiarch-20260517-103904-1404563/summary.md`
  - gate summary: `/home/dtamade/projects/fafafa.core/tests/fafafa.core.simd/logs/gate_summary.md`
  - gate 最终 `[GATE] OK`
- 随后已复核：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux`
  - 结果：`ready=True`、`mainline-ready=True`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
  - 结果：`ready=False`，但红项只剩：
    - `cross_gate_required_steps: evidence-verify=SKIP`
    - `windows_b07_gate.log` freshness / source-newer-than-windows-evidence / verify
    - `windows_b07_closeout_summary.md` freshness / verify
- 当前阶段结论：
  - Linux CPUInfo QEMU cross evidence 已重新补绿
  - 当前 stop-point 已明确收敛到 Windows evidence 外部阻塞，而不是 SIMD 代码或 Linux closeout 回归

## 2026-05-17 Freeze Next-Action Billing Fail-Close

- 继续按“小闭环”推进，这次不再去重跑 GH dispatch，而是先确认 `freeze-status` 的 next-actions 有没有继续误导。
- 已复核：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight`
  - 结果：`STATUS=FAIL CODE=RECENT_BILLING_BLOCK EXIT=31`
  - `tests/fafafa.core.simd/logs/win_preflight_latest.json`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
- 当前结论：
  - fresh preflight 已明确给出 recent GitHub billing/spending-limit blocker
  - 旧版 `freeze-status` 仍会推荐 `win-evidence-via-gh`、`tests\fafafa.core.simd\buildOrTest.bat evidence-win-verify`、fail-close cross gate 和 `win-closeout-finalize`，这些在当前 blocker 下都不是高价值动作
- 已完成收口：
  - `tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
    - 新增 `windows_preflight_latest` 检查项，直接展示 `logs/win_preflight_latest.json` 的最新状态
    - 若 preflight fresh 命中 `RECENT_BILLING_BLOCK`，next-actions 改为：
      - 先处理 GitHub Billing / 或切到真实 Windows runner
      - 重新 `win-evidence-preflight`
      - `win-closeout-3cmd` 手工收口路径
    - 不再继续推荐 `win-evidence-via-gh`、stale Windows verify、fail-close gate、`win-closeout-finalize`
- 最小验证：
  - `python3 -m py_compile tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux`
- fresh 结果：
  - full `freeze-status` 现在会显示：
    - `windows_preflight_latest: status=FAIL, code=RECENT_BILLING_BLOCK`
  - full `freeze-status` 的 next-actions 现在只剩：
    - `Resolve GitHub Billing & plans or switch to a real Windows runner; current preflight reports RECENT_BILLING_BLOCK`
    - `bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight`
    - `bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-3cmd SIMD-20260517-152`
  - `freeze-status-linux` 继续保持 `ready=True`
- 当前阶段结论：
  - 这批收掉的不是 SIMD 算法或 backend 语义问题
  - 收掉的是 Windows evidence 外部阻塞下，`freeze-status` 仍给出错误行动建议的 runner 效率缺口

## 2026-05-17 Implementation Matrix Sync Guard

- 继续按“小闭环”推进，这次不再重新扫 SIMD 算法或 closeout 外部 blocker，只收口上一轮半成品的 `implementation-matrix-sync` checker 批次。
- 接手现场后先确认当前工作树只脏在这 5 个文件：
  - `docs/fafafa.core.simd.checklist.md`
  - `docs/fafafa.core.simd.maintenance.md`
  - `tests/fafafa.core.simd/BuildOrTest.sh`
  - `tests/fafafa.core.simd/buildOrTest.bat`
  - `tests/fafafa.core.simd/check_implementation_matrix_sync.py`
- 首轮验证：
  - `python3 -m py_compile tests/fafafa.core.simd/check_implementation_matrix_sync.py`
  - `python3 tests/fafafa.core.simd/check_implementation_matrix_sync.py --summary-line`
  - 结果：语法通过，但 summary 直接报 `issues=83 status=fail`
- 首个硬失败根因已锁定：
  - checker 误把 `check_nonx86_key_slot_audit.py` 的全量 key-slot 期望当成了 active implementation matrix 必须逐行覆盖的范围
  - 这会把 working ledger 强行膨胀成总台账，制造大量假红
- 已完成修法：
  - `tests/fafafa.core.simd/check_implementation_matrix_sync.py`
    - 显式锁定当前 22 条 non-x86 active rows
    - 显式锁定当前 10 条 x86 bounded-frontier row prefixes
    - non-x86 只检查 active rows 的缺失/多余/contract mismatch
    - 为 `RISCVV.ShiftLeftU32x8` / `ShiftRightU32x8` 加入本地 manual contract，因为它们的真相源在 facade，不在 `key-slot-audit`
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - 新增 `implementation-matrix-sync` action / log path / usage / `check` 主链接线
  - `tests/fafafa.core.simd/buildOrTest.bat`
    - 同步新增 `implementation-matrix-sync` action / usage / `check` 主链接线
  - `docs/fafafa.core.simd.maintenance.md`
  - `docs/fafafa.core.simd.checklist.md`
    - 已同步写明 `check` 现在包含 `implementation-matrix-sync`
- 修后验证：
  - `python3 -m py_compile tests/fafafa.core.simd/check_implementation_matrix_sync.py`
  - `python3 tests/fafafa.core.simd/check_implementation_matrix_sync.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `git diff --check`
- fresh 结果：
  - 独立 checker：
    - `IMPLEMENTATION_MATRIX_SYNC nonx86_slots=22 x86_rows=10 issues=0 status=ok`
  - Release `check`：
    - 新增 `[IMPL-MATRIX] Summary: nonx86_slots=22 x86_rows=10 issues=0 status=ok`
    - 整体最终返回 `0`
  - `git diff --check` 通过
- 当前阶段结论：
  - 这批收掉的是真正的默认门禁缺口，而不是再开一轮 broad SIMD 审查
  - `docs/fafafa.core.simd.implementation-matrix.md` 现在终于受默认 `check` fail-close 保护，而且规则面与 active ledger 真边界一致

## 2026-05-17 SIMD Tracked Res Artifact Hygiene

- 继续按“小闭环”推进，这次没有再扫算法或外部 evidence，而是直接清理 `simd` 子树里还被 Git 跟踪的 `.res` 生成物。
- 已复核：
  - `git ls-files tests/fafafa.core.simd tests/fafafa.core.simd.* | rg '\.res$'`
  - `file tests/fafafa.core.simd/fafafa.core.simd.test.res tests/fafafa.core.simd/test_backend_ops.res tests/fafafa.core.simd.intrinsics.mmx/fafafa.core.simd.intrinsics.mmx.test.res`
  - `tests/fafafa.core.simd/fafafa.core.simd.test.lpr`
  - `tests/fafafa.core.simd/test_backend_ops.pas`
  - `tests/fafafa.core.simd.intrinsics.mmx/fafafa.core.simd.intrinsics.mmx.test.lpr`
  - `tests/fafafa.core.simd/.gitignore`
  - `tests/fafafa.core.simd.intrinsics.mmx/BuildOrTest.sh`
- 当前结论：
  - `simd` 相关被跟踪的 `.res` 只剩 3 个
  - 三者都显示为 `Microsoft Visual C binary resource file`
  - 对应源码入口都没有 `{$R *.res}` 引用，因此它们不应继续作为 repo 资产存在
- 已完成收口：
  - `tests/fafafa.core.simd/.gitignore`
    - 新增 `/*.res`
  - `tests/fafafa.core.simd.intrinsics.mmx/.gitignore`
    - 新增局部 ignore：`/bin/`、`/lib/`、`/logs/`、`/*.res`
  - 从 Git 索引移除：
    - `tests/fafafa.core.simd/fafafa.core.simd.test.res`
    - `tests/fafafa.core.simd/test_backend_ops.res`
    - `tests/fafafa.core.simd.intrinsics.mmx/fafafa.core.simd.intrinsics.mmx.test.res`
- Release/runner 验证：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.intrinsics.mmx/BuildOrTest.sh test`
  - `git diff --check`
- fresh 结果：
  - 主 `simd check` 继续通过，说明删掉 tracked `fafafa.core.simd.test.res` / `test_backend_ops.res` 不会破坏主 runner
  - MMX runner 继续 `[BUILD] OK`、`[TEST] OK`、`[LEAK] OK`
  - `fafafa.core.simd.test.res` 与 `fafafa.core.simd.intrinsics.mmx.test.res` 可被正常重建，但因为 ignore 已补齐，不再回流成未跟踪噪音
  - `test_backend_ops.res` 删除后没有重新生成，且主 `check` 仍通过，进一步证明它不是必需源码资产
- 当前阶段结论：
  - 这批收掉的是 `simd` 子树里仍被版本库持有的资源二进制垃圾
  - 它没有改变 SIMD 语义，但显著降低了后续 review 与构建后的噪音面

## 2026-05-17 Intrinsics Coverage Evidence Normalization

- 继续按“小闭环”推进，这次不再碰算法面，也不去追外部 Windows blocker，只把当前遗留的 `coverage` 半成品批次一次收口。
- 接手现场后先确认工作树只脏在 4 个文件：
  - `docs/fafafa.core.simd.maintenance.md`
  - `tests/fafafa.core.simd/BuildOrTest.sh`
  - `tests/fafafa.core.simd/buildOrTest.bat`
  - `tests/fafafa.core.simd/check_intrinsics_coverage.py`
- 这批的目标很窄：
  - 让 `coverage` 默认产出稳定的 `txt/json` 证据
  - 让 shell / batch runner 都输出可抓取的 summary line
  - 避免下次再从 stdout 手工摘 coverage 结果
- 已落地的收口：
  - `tests/fafafa.core.simd/check_intrinsics_coverage.py`
    - 新增 `--summary-line`
    - 新增 `--json-file`
    - 统一生成可复用 JSON payload
    - 输出 `INTRINSICS_COVERAGE_SUMMARY ...`
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - 新增 `COVERAGE_LOG` / `COVERAGE_JSON_LOG`
    - `run_coverage()` 现在会把 checker 输出落到 `tests/fafafa.core.simd/logs/intrinsics_coverage.{txt,json}`
    - shell 侧会自动回显解析后的 summary
  - `tests/fafafa.core.simd/buildOrTest.bat`
    - `coverage` action 同步补齐 `--summary-line --json-file`
  - `docs/fafafa.core.simd.maintenance.md`
    - 已写明 `coverage` 默认产物路径
- fresh 验证已完成：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh coverage`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `coverage` 返回：
    - `INTRINSICS_COVERAGE_SUMMARY modules=5 missing_required=0 missing_optional=0 extra=0 strict_extra=0 require_avx2=0 require_experimental=0 status=ok`
  - Release `check` 继续通过，说明这次 runner 证据规范化没有引入新的 shell/batch 漂移
- 当前阶段结论：
  - 这批收掉的是“coverage 证据输出不够稳定”的 runner 卫生问题
  - 它不改变 SIMD 实现语义，但把 `intrinsics coverage` 从一次性控制台输出提升成了可复用、可落盘、可抓取的标准证据

## 2026-05-17 Task2/Task3 Doc Truth Resync

- 继续按“小闭环”推进，这次没有再碰实现代码，而是直接收口一条已经被当前实证推翻的文档恢复点漂移。
- 先做的不是改文档，而是补证据确认这确实是“文档假待办”：
  - `python3 tests/fafafa.core.simd/check_implementation_matrix_sync.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh implementation-matrix-sync`
  - `ls tests/fafafa.core.simd/logs/qemu-multiarch-20260419-012508-1690172/summary.md tests/fafafa.core.simd/logs/qemu-multiarch-20260419-013630-1748481/summary.md`
- fresh 结果：
  - `IMPLEMENTATION_MATRIX_SYNC nonx86_slots=22 x86_rows=10 issues=0 status=ok`
  - active `implementation-matrix` 已明确写明 `Task 2 / Task 3` 都有 `2026-04-19 fresh evidence`
  - 两个 2026-04-19 QEMU summary 文件都真实存在
- 随后确认到 3 处旧状态彼此冲突：
  - `docs/fafafa.core.simd.checklist.md` 还指导“`Task 3` 暂时保留 `pending fresh Task 3 run`”
  - `docs/fafafa.core.simd.closeout.md` 的 `Task 2 / Task 3 closeout facts` 还停在 `2026-04-14 fresh`
  - `plans/scratch/.../task_plan.md` 还残留上一批 docs truth-sync 已 commit 之后的 `in_progress`
- 已落地的收口：
  - checklist 改成“当前已回填完成”的维护顺序，不再默认把 `Task 3` 写回 `pending`
  - closeout 的 `Task 2 / Task 3` fresh 事实改用 `2026-04-19` summary
  - scratch `task_plan` 里上一批已经提交的 docs truth-sync 已正式收成 `completed`
- 当前阶段结论：
  - 这批收掉的是恢复点与活跃文档的真相漂移，不是 SIMD 实现 bug
  - 它能直接减少下次继续审查时的误导性“旧 pending / 旧 in_progress”噪音

## 2026-05-17 Windows Alias Help Truth Sync

- 继续按“小闭环”推进，这次没有再追 runner dispatch 结构，而是专门核 `evidence-win` / `evidence-win-verify` 这两个剩余 Windows alias 现在到底算不算问题。
- 先做的是真相判定，而不是改文档：
  - `sed -n '948,970p' tests/fafafa.core.simd/BuildOrTest.sh`
  - `rg -n "evidence-win|evidence-win-verify|verify-win-evidence" ...`
  - `sed -n '150,172p' tests/fafafa.core.simd/buildOrTest.bat`
- 读下来后确认：
  - `BuildOrTest.sh` 的 parity guard 已明确把这两个名字定性为 `Windows-only` alias
  - batch usage 已公开它们，但 help 之前没有单独解释
  - active closeout 文档也用了 `evidence-win-verify`，却没说明它和 `verify-win-evidence` 的 canonical 关系
- 已落地的收口：
  - `tests/fafafa.core.simd/buildOrTest.bat`
    - help 新增 `evidence-win`
    - help 新增 `evidence-win-verify`
  - `docs/fafafa.core.simd.closeout.md`
    - 补写 `evidence-win-verify` 是 Windows native batch 路径上的刻意 alias
    - 明确 canonical verifier 名字仍是 `verify-win-evidence`
  - `docs/fafafa.core.simd.maintenance.md`
    - 明确 runner parity 当前只允许这两条 Windows-only batch alias
- fresh 验证已完成：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh runner-parity`
  - `git diff --check`
  - `rg -n "Windows-only|evidence-win-verify|verify-win-evidence" ...`
- fresh 结果：
  - `[CHECK] OK (windows runner parity signatures present)`
  - `[CHECK] OK (cpuinfo runner parity signatures present)`
  - `[CHECK] OK (runner parity quick path)`
  - diff 整洁，help/runbook 新说明都已命中
- 当前阶段结论：
  - 这批收掉的不是行为 bug，而是“有意例外没被 help/runbook 讲清楚”的认知噪音
  - 下次再看到这两个 alias，就不会再把它们误判成待清理 drift action

## 2026-05-17 Windows Closeout Help Surface Fill

- 继续沿同一条 help surface 线往下切，这次不碰 alias 真相，而是只补 canonical Windows closeout 动作自己的 help 缺口。
- 先做了一个很窄的只读核对：
  - `sed -n '146,190p' tests/fafafa.core.simd/buildOrTest.bat`
  - 小脚本把 action 表和 `echo   ...` help surface 做了一个轻量比对
- 核对结果说明：
  - 全量 help 缺口当然还有不少
  - 但当前最值得先收的一簇，是 5 条 canonical Windows closeout 动作：
    - `win-evidence-preflight`
    - `verify-win-evidence`
    - `finalize-win-evidence`
    - `win-closeout-3cmd`
    - `win-closeout-finalize`
  - 它们都已经公开在 usage/action 表里，却没被 help block 单独解释
- 已落地的收口：
  - `tests/fafafa.core.simd/buildOrTest.bat`
    - help 新增 `win-evidence-preflight`
    - help 新增 `verify-win-evidence`
    - help 新增 `finalize-win-evidence`
    - help 新增 `win-closeout-3cmd`
    - help 新增 `win-closeout-finalize`
- fresh 验证已完成：
  - `git diff --check`
  - `rg -n "win-evidence-preflight  |verify-win-evidence  |finalize-win-evidence  |win-closeout-3cmd  |win-closeout-finalize  " tests/fafafa.core.simd/buildOrTest.bat`
  - 小脚本确认这 5 条 action 都已进入 help surface
- 当前阶段结论：
  - 这批补的是 batch help completeness，而不是 runner 行为或 SIMD 实现
  - 现在 Windows closeout 这条主线在 batch help 里终于不再被 alias 抢走可见性

## 2026-05-17 Daily Audit Help Surface Guard

- 继续按“小闭环”推进，这次把目标从 Windows closeout 帮助文案收回到更高频的日常审查主线。
- 先用一个很窄的小脚本确认当前 help 缺口到底值不值得单独做一批：
  - `cpuinfo-lazy-repeat`
  - `implementation-matrix-sync`
  - `interface-completeness`
  - `dispatch-read-scope`
  - `dataplane-consumer-scope`
  - `direct-dispatch-scope`
  - `metadata-query-scope`
  - `contract-signature`
  - `publicabi-signature`
  - `publicabi-smoke`
  - `adapter-sync-pascal`
  - `adapter-sync`
  - `coverage`
  - `wiring-sync`
  - `experimental-intrinsics`
  - `experimental-intrinsics-tests`
- 结果说明这不是“挑刺式文档修补”：
  - 这 16 条都已经在 usage/action 表里公开
  - 但 batch help block 还没把它们讲出来
  - 更关键的是，现有 `runner-parity` 也没守住这组 help 文案
- 已落地的收口：
  - `tests/fafafa.core.simd/buildOrTest.bat`
    - 新增上述 16 条日常审查/contract/coverage help 描述
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - `check_windows_runner_parity()` required pattern 同步纳入这组 help 文案
- fresh 验证已完成：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh runner-parity`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `runner-parity` 继续 `[CHECK] OK`
  - Release `check` fresh 通过，关键 `helper/key-slot/implementation-matrix/scope/signature/wiring` 等主链也继续为绿
- 当前阶段结论：
  - 这批收掉的不是实现 bug，而是“日常审查主线已经成形，但 batch help 与 parity guard 还没同步跟上”的 repo 内卫生缺口
  - 现在这 16 条高频动作不只存在于 action 表里，也开始被帮助文案和主检查链一起守住

## 2026-05-17 Evidence Help Surface Completion

- 继续沿同一条 help completeness 线推进，但这次不再拆簇，而是把最后剩下的一整簇 evidence/perf/QEMU/gate-summary 入口一次性收完。
- 先做的仍然是只读确认，而不是直接改：
  - 重新跑 action-vs-help 轻量脚本
  - fresh 结果为 `MISSING_HELP_COUNT 23`
  - 剩余项全部落在 evidence / summary / QEMU / perf 这同一簇
- 这让我可以把动作一次性收平，而不用再继续切成很多小碎批：
  - `import-nonx86-native-evidence`
  - `closeout-host-local-from-import`
  - `parity-suites`
  - `gate-summary*`
  - `perf-smoke`
  - `nonx86-optin-list-suites`
  - `nonx86-ieee754`
  - `backend-bench`
  - `qemu*`
  - `riscvv-opcode-lane`
  - `qemu-experimental-*`
- 已落地的收口：
  - `tests/fafafa.core.simd/buildOrTest.bat`
    - 补齐这一整簇 help 文案
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - shell help 同步补齐
    - `check_windows_runner_parity()` required pattern 同步纳入对应 batch help 行
- 这次我刻意没有再重跑整条 Release `check`，因为改动只在 help/parity 文案层：
  - 改成了 3 条更高性价比的验证
  - `bash tests/fafafa.core.simd/BuildOrTest.sh runner-parity`
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - help 缺口计数脚本
- fresh 结果：
  - `runner-parity` 继续 `[CHECK] OK`
  - `bash -n` 通过
  - `MISSING_HELP_COUNT 0`
- 当前阶段结论：
  - `buildOrTest.bat` 的 help surface 现在和公开 action 表终于对齐完毕
  - 这条 runner/help 审查线可以从“还在补漏”转成“后续只防回退”

## 2026-05-17 Windows Closeout Truth-Sync Follow-up

- 这轮没有再去打开实现层，而是专门做了一次 repo 内 truth-sync 审查：
  - 先 fresh 读取 `freeze-status`
  - 再对照 `docs/fafafa.core.simd.closeout.md`
  - 再对照 `docs/fafafa.core.simd.handoff.md`
  - 再对照 `tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md`
  - 再对照 `tests/fafafa.core.simd/docs/simd_completeness_matrix.md`
- 真正抓到的缺口不是 gate 行为，而是“历史 Windows 已归档”与“当前 HEAD 仍 cross-ready”被混写：
  - `freeze-status.json` 真实仍是 `freeze_ready=false / cross_ready=false`
  - 但 active closeout 文档后段还残留了“当前可以按 cross-platform freeze 条件满足理解”
  - RC checklist / completeness matrix 里的 `[x] Windows 实机证据已归档` 也缺少“这只是历史归档，不等于当前 HEAD 仍是 green”的提示
- 这批最小修法刻意不去碰 evaluator：
  - 保留历史归档标记，避免把现有 `freeze-status` optional doc check 结构打坏
  - 只在 active 文档上补明示注释：历史闭环 != 当前 HEAD 仍 cross-ready
  - 同时把 handoff 的当前状态从旧的 `qemu-cpuinfo-nonx86-evidence=SKIP` 更新成 `Windows freshness / verify + RECENT_BILLING_BLOCK`
- 因而这批收掉的不是实现 bug，而是会误导下一轮判断的 closeout 叙事漂移：
  - 当前最准确的交接口径继续是 `code-green / release-evidence-blocked`

## 2026-05-17 Freeze-Status Optional Doc Signal Clarification

- 在补完 active 文档注释后，又顺手看了一眼 `freeze-status` 自己的输出文本。
- 这里还残留一个较小但真实的误导点：
  - `roadmap_windows_closed`
  - `rc_windows_closed`
  - `matrix_windows_closed`
  - 这三项虽然本来就是 optional check，但 detail 文案仍然只写成了 `checkbox is [x]` / `row is [x]` / `marks ... archived`
- 这会把“历史归档标记”说得太像“当前 readiness 信号”，和刚修掉的文档漂移属于同一类认知噪音。
- 这批最小修法只改 detail 文案，不改任何判定逻辑：
  - 明确写成 `historical Windows archive marker`
  - 明确补上 `not a current readiness signal`
- fresh `freeze-status` 复验后，主结论没有变化：
  - 当前仍是 `ready=False / cross-ready=False`
  - 但 optional doc check 的输出现在不再那么容易被误读成“当前已经放行”

## 2026-05-17 Active Entry Docs Stop-Point Sync

- 在 closeout/handoff/checklist 已经写清当前状态之后，`docs/fafafa.core.simd.md`、`src/fafafa.core.simd.README.md` 和 `docs/fafafa.core.simd.maintenance.md` 这三个第一入口文档还缺一个共同问题：
  - 它们会把人顺滑地带到 `closeout-release`
  - 但没有在入口处明确写出“当前并不是实现层未收口，而是 `code-green / release-evidence-blocked`”
- 这会让下一位维护者很容易做两种低效动作：
  - 重新打开 SIMD 泛审查
  - 或者直接把 `closeout-release` 当成当前环境下一定能走通的无条件主线
- 这批最小修法只补入口停点提示，不改任何命令或 gate：
  - `docs/fafafa.core.simd.md` 新增当前停点摘要
  - `src/fafafa.core.simd.README.md` 在 `closeout-release` 入口旁补上当前外部 blocker 提示
  - `docs/fafafa.core.simd.maintenance.md` 补上“默认不要再重开实现层泛审查”的最新口径
- 这批价值在于把“当前该继续做什么”前移到最先被读到的文档，而不是只躲在 checklist/handoff/closeout 这些更深层入口里

## 2026-05-17 Post-Summary-Refresh Red-Item Truth Sync

- 在把 `windows_b07_closeout_summary.md` 刷成当前 honest FAIL 之后，又出现了一处很典型的“修完一个事实，顶部摘要忘了跟着变”的文档漂移：
  - `docs/fafafa.core.simd.closeout.md`
  - `docs/fafafa.core.simd.checklist.md`
  - `docs/fafafa.core.simd.handoff.md`
  - 顶部都还把 `windows_b07_closeout_summary.md` 写成当前红项的一部分
- 但 latest `freeze-status` 已经不是这个状态了：
  - `windows_closeout_summary: PASS`
  - `windows_closeout_freshness: PASS`
  - 真正剩下的还是 `windows_b07_gate.log` freshness / verifier，以及 `RECENT_BILLING_BLOCK`
- 这批最小修法只收当前状态摘要：
  - 把 `windows_b07_closeout_summary.md` 从“当前红项”里移除
  - 显式补一句：summary 已经刷新成当前 verifier FAIL 对应的 honest summary
- 这样下一位维护者读顶部摘要时，就不会再把“summary 还旧”错当成当前 blocker

## 2026-05-17 Local Wine Runner Audit

- 这轮没有直接接受“只剩纯外部 blocker”这个说法，而是专门审了一次本机能不能替代 GH/实机 Windows runner：
  - `command -v wine` 命中 `/usr/bin/wine`
  - `wine cmd /c exit 0` 可用
  - `bash tests/test_windows_simd_cpuinfo_x86_batch_build_success_criteria.sh` 为 PASS
- 但把这条路推进到真实 Windows evidence 时，失败点也很明确：
  - `FAFAFA_BUILD_MODE=Release wine cmd /c "tests\\fafafa.core.simd\\buildOrTest.bat evidence-win-verify"` 进入了 batch capture
  - `windows_b07_gate.log` 能写出 `HostOS: Windows_NT`、`CmdVer: Microsoft Windows 10.0.19043`
  - 真正失败在 gate 第 1 步 build：Wine 里的 `cmd` 不能直接执行 fallback 的 `lazbuild`
  - `tests/fafafa.core.simd/logs/build.txt` 真实错误是：
    - `Can't recognize '"lazbuild" --build-mode=Release ...' as an internal or external command`
- 我又继续做了两轮更小的桥接实验，目的都是验证能不能把 Linux `lazbuild` 借给 Wine batch 用：
  - `wine cmd /c "\"Z:\\usr\\bin\\lazbuild\" --help"` 不可行
  - `wine cmd /c start /unix /usr/bin/true` 返回 0，但 `start /wait /unix /usr/bin/lazbuild --help` 没有形成可用的可复验通路
  - 临时 `wine_lazbuild.bat` wrapper 也没有变成稳定可用的 bridge
- 当前最保守、最不误导的结论是：
  - 本机 Wine 足够支撑“Windows batch success-criteria smoke”
  - 但在当前环境下，还不足以替代真实 Windows evidence runner
  - 因而 latest closeout 主线的剩余 blocker 继续应按 `GH Billing / 实机 Windows runner` 理解，而不是继续在 Wine 适配层空转

## 2026-05-17 Runner-Parity Allowlist Staleness Guard

- 继续按“小闭环”推进，这次不再重新扫 closeout 文档，也不再碰外部 Windows blocker，只审 `runner-parity` 自己有没有 stale 例外。
- 机器对账先确认了当前真实 action 差集：
  - shell-only = `[]`
  - windows-only = `evidence-win`, `evidence-win-verify`
- 由此抓到一个真实 residual：
  - `tests/fafafa.core.simd/BuildOrTest.sh` 的 `check_windows_runner_parity()` 里，`LAllowedShellOnly` 还残留 `import-nonx86-native-evidence`
  - 但这个 action 现在已经有 batch 对应入口，不再是 shell-only
  - 如果继续保留这个过时 allowlist，将来就可能把同名回归静默放过
- 已落地的最小修法：
  - 把 `LAllowedShellOnly` 收紧为空
  - 新增 allowlist 自检：
    - shell-only allowlist 项若已出现在 batch action 集，直接 fail-close
    - windows-only allowlist 项若已出现在 shell action 集，直接 fail-close
- fresh 轻量验证已完成：
  - `git diff --check`
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh runner-parity`
  - Python 对账脚本复核差集仍为：
    - `shell_only=`
    - `windows_only=evidence-win,evidence-win-verify`
- 当前阶段结论：
  - 这批收掉的不是实现 bug，而是 `runner-parity` 自己的例外白名单漂移
  - 现在 allowlist 不仅要“存在”，还必须继续符合单边事实，后续更不容易因为历史例外放松护栏

## 2026-05-17 Check Default Register-Truthfulness Strict Upgrade

- `runner-parity` 收口后，继续按“默认门禁是否还留宽松口子”的边界往下查。
- 新抓到的 residual 不是 checker 算法缺陷，而是默认门禁口径还没完全跟上当前 truth：
  - shell `check` 里仍是 `run_register_truthfulness_check "0"`
  - batch `check` 里也仍是 `call :register_truthfulness_check 0`
  - 但同一仓库里的手工 checklist、`impl-audit-nonx86` 与近期 closeout 记录，已经普遍把 `register-truthfulness --strict` 当成真实口径
- 先做了 fresh 可行性复核，而不是直接改：
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend neon --summary-line --strict`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
  - 结果两边都为 `miswired=0 unused_allowlist=0 strict=1`
- 已落地的最小修法：
  - `tests/fafafa.core.simd/BuildOrTest.sh`：`check` 默认改为 strict
  - `tests/fafafa.core.simd/buildOrTest.bat`：同步改为 strict
  - `docs/fafafa.core.simd.maintenance.md`：明确 `check` 当前包含 `register-truthfulness --strict`
- fresh 验证已完成：
  - `git diff --check`
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh runner-parity`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - fresh `check` 日志里两条 summary 已变成：
    - `backend=neon ... strict=1`
    - `backend=riscvv ... strict=1`
- 当前阶段结论：
  - 这批收掉的是默认 `check` 对 `register-truthfulness` 的宽松模式残留
  - 现在日常 `check` 与当前 closeout truth 更一致，新增 always-context wrapper drift 更早会被 fail-close

## 2026-05-17 Runner-Parity Check-Lane Coverage Fill

- 在把默认 `check` 的 `register-truthfulness` 升到 strict 之后，我继续追了一步：`runner-parity` 自己有没有真的守住这条默认 lane。
- 复核后确认当前还有一个更窄但真实的 guard gap：
  - `check_windows_runner_parity()` 已经守 action/help/alias，也守了 `nonx86-optin` 与 `wiring-sync` 的 batch 分支
  - 但它还没有钉住默认 `check` 里最近几次刚收正过的几条关键信号：
    - batch `Backend adapter sync (python-only)`
    - `call :register_truthfulness_check 1`
    - experimental isolation 分支
  - 这意味着将来即使 batch `check` 把这些线悄悄改回旧口径，`runner-parity` 也可能继续报绿
- 已落地的最小修法：
  - 在 `tests/fafafa.core.simd/BuildOrTest.sh` 的 `check_windows_runner_parity()` required pattern 集里，新增：
    - adapter-sync python-only 这组 batch `check` 行
    - `call :register_truthfulness_check 1`
    - experimental isolation 分支与调用
- fresh 验证已完成：
  - `git diff --check`
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh runner-parity`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `runner-parity` 继续 `[CHECK] OK`
  - Release `check` 继续通过
  - 说明这次补的是 parity 守卫覆盖，而不是又引入新行为
- 当前阶段结论：
  - 这批收掉的不是 batch `check` 的执行缺口，而是 `runner-parity` 对默认 `check` lane 的覆盖缺口
  - 以后如果 batch 把这几条默认静态 guard 悄悄改回去，parity guard 会更早 fail-close

## 2026-05-17 Runner-Parity Default Check Coverage Completion

- 在上一批补完 `adapter-sync / register-truthfulness / experimental` 后，我没有直接当作完结，而是对 batch `:check` 与 parity required pattern 又做了一次机器对账。
- fresh 对账说明同类 residual 还剩一簇：
  - `call :dataplane_consumer_scope`
  - `call :dispatch_read_scope`
  - `call :sse2_structure_check`
  - `call :suite_manifest_check`
  - `if /I "%SIMD_CHECK_NONX86_OPTIN%"=="0" (`
  - `call :run_backend_ops_internal`
  - `call :run_simd_boundary_internal`
  - `call :run_public_smoke_internal`
  - `call :run_dispatch_preinit_smoke_internal`
  - `call "%ROOT%buildOrTest.bat" implementation-matrix-sync`
- 这些并不是新功能，而是 batch 默认 `check` 里已经存在、但 parity 之前没真正钉住的一簇关键静态 guard / standalone smoke。
- 已落地的最小修法：
  - 在 `tests/fafafa.core.simd/BuildOrTest.sh` 的 `check_windows_runner_parity()` required pattern 集里，把这组高价值默认 `check` 位点一并补齐
  - 刻意没有把整段 `:check` 原样硬编码，只收最值得 fail-close 的 guard / smoke / ledger 位点
- fresh 验证已完成：
  - `git diff --check`
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh runner-parity`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `runner-parity` 继续 `[CHECK] OK`
  - Release `check` 继续通过
  - 说明这批补的是 parity 覆盖深度，而不是执行逻辑变更
- 当前阶段结论：
  - `runner-parity` 对默认 `check` lane 的覆盖现在比上一批更完整
  - 同类“batch 已经收正、parity 还没跟上”的 easy residual 已经明显收缩

## 2026-05-17 Batch Usage Synopsis Parity Refresh

- 在默认 `check` 覆盖补齐之后，我继续只看 `runner/check/gate/help` 一致性，没有回到实现层。
- fresh 复核发现一个更窄的 help residual：
  - shell usage synopsis 已列出 `riscvv-opcode-lane`
  - batch usage synopsis 仍漏掉它
  - `check_windows_runner_parity()` 的 expected synopsis 也沿用了这条 stale 文本
- 已落地的最小修法：
  - 在 `tests/fafafa.core.simd/buildOrTest.bat` 的总 synopsis 中补上 `riscvv-opcode-lane`
  - 在 `tests/fafafa.core.simd/BuildOrTest.sh` 的 `check_windows_runner_parity()` required synopsis 中同步补上同一项
- 这批只碰 help/parity 文本，不碰执行分支；验证仍按 release closeout 习惯走 `git diff --check`、`bash -n`、`runner-parity`。

## 2026-05-17 Structural Synopsis Parity Check

- 在补完 `riscvv-opcode-lane` synopsis 漂移之后，我没有停在“再维护一条更长的 expected string”，而是顺手把这类冗余守卫削掉一层。
- 已落地的最小修法：
  - 在 `tests/fafafa.core.simd/BuildOrTest.sh` 增加 shell/batch synopsis action 提取器
  - `check_windows_runner_parity()` 不再依赖整条硬编码 `Usage:` synopsis 作为唯一事实源
  - 改成把 shell/batch 各自的 `Usage:` action 集与真实 action 路由集合做双向对账
- 这次收掉的是守卫冗余，而不是功能冗余：
  - 以后新增 action 若只改了路由、没改 synopsis，会直接报红
  - 以后 synopsis 若残留 stale action，也会直接报红
- 验证仍按 release closeout 习惯走 `git diff --check`、`bash -n`、`runner-parity`。

## 2026-05-17 Structural Detailed-Help Parity Check

- 在 synopsis 守卫结构化之后，我继续把同一条链再往下压一层，对账“真实 action 路由集”与“详细帮助 action 集”。
- fresh 结果说明 batch 侧基本齐，但 shell 侧仍留着真实缺口：很多 action 已有实现与 synopsis，却没有对应的详细帮助行。
- 已落地的最小修法：
  - 在 shell usage/help 段补齐缺失的真实 action 说明
  - 在 `tests/fafafa.core.simd/BuildOrTest.sh` 增加 shell/batch detailed-help action 提取器
  - `check_windows_runner_parity()` 现在不仅校验 synopsis，还会校验 detailed help 的 action 覆盖与 stale 项
  - 只把 `clean/build/check/test/test-concurrent-repeat/debug/release` 这组基础入口保留在显式 no-help allowlist 中
- 这样以后会直接 fail-close 两类问题：
  - 新 action 落地了，但详细帮助没跟上
  - 详细帮助里残留了已经不存在的 action
- 验证仍按 release closeout 习惯走 `git diff --check`、`bash -n`、`runner-parity`。

## 2026-05-17 CPUInfo X86 Batch Parity Coverage

- 主 runner 这条线稳定后，我没有把 `cpuinfo runner parity` 想当然地当成也够用了，而是直接回看它到底覆盖了哪些文件。
- fresh 结果很明确：
  - 之前它只扫两个 shell runner
  - 没有把 `tests/fafafa.core.simd.cpuinfo.x86/buildOrTest.bat` 这条真实 Windows runner 纳入 parity
- 已落地的最小修法：
  - 在 `check_cpuinfo_runner_parity()` 里加入 `cpuinfo.x86` batch runner
  - 保留原有 shell 关键模式检查
  - 新增对 x86 batch 的 `--list-suites` 归一化、Invalid option / leak fail-close 模式检查
  - 新增 `cpuinfo.x86` shell/batch action 集与 synopsis 集的结构化对账
- 在 fresh 验证时又顺手收掉一个实现细节：
  - Windows synopsis action 提取器统一先做 `\r` stripping
  - 这样 `cpuinfo.x86` 这种 CRLF batch 文件不会再把最后一个 action 误判成 `release\r`
- 这样以后 `cpuinfo.x86` batch 的 action 面或 synopsis 面如果漂移，也会直接进主 `runner-parity` fail-close。

## 2026-05-17 Optional Windows Evidence Verify Skip Cleanup

- 在 `runner-parity`、`check` 都重新收绿后，我继续往上一层跑了 release `gate`，这次不是为了再补字符串，而是看真实门禁还有没有 UX/guard 质量问题。
- fresh 结果暴露出一个新的 residual：
  - optional Windows evidence verify 在 stale/incomplete log 上会先打印 verifier 的 `Missing pattern:` 明细
  - 然后才说这次 evidence verify 是 optional `SKIP`
- 已落地的最小修法：
  - required Windows evidence 模式不变，仍保留完整 verifier 输出和 fail-close 行为
  - optional 模式改为先捕获 verifier 输出
  - pass 时仍回显 verifier 输出
  - fail 时改成只打印一条干净的 stale/incomplete skip 提示，并把 skip 原因写进 gate summary
- 这样门禁信号会更清晰：
  - required 失败时仍有完整细节
  - optional skip 时不再用一串 verifier missing 明细淹没真正结论

## 2026-05-17 Freeze Status Mainline Fallback Recovery

- 在上一批 optional evidence skip 清噪收口后，我继续按 release 路径看 `freeze-status`，fresh 现象是：
  - cross 模式又退回了 `mainline-ready=False`
  - 但仓库里实际存在更早的 backup gate snapshot，里面 `qemu-cpuinfo-nonx86-evidence=PASS`
  - 所以这不是实现回归，而是 `freeze-status` 的 gate 选择链还在误消费“最新 fast gate”
- 直接把真实 logs 喂给 Python 选择器后，确认了两件事：
  - Python 选择器本身已经能选中 `/logs/rehearsal/backups/gate_summary.backup.20260517-155349-449.md`
  - 真正短路 fallback discovery 的是 shell wrapper：`run_freeze_status()` 默认也在强塞 `SIMD_FREEZE_GATE_SUMMARY_FILE=<logs/gate_summary.md>`
- 已落地修法：
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - `run_freeze_status()` 只有在调用者显式给了 `SIMD_FREEZE_GATE_SUMMARY_FILE` / `SIMD_GATE_SUMMARY_FILE` 时才传 override
  - `tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
    - cross 模式下如果最新 snapshot 只覆盖了 base steps，但历史里存在 `mainline-ready` 的更强 snapshot，会回退到那个 backup / closeout snapshot
  - `tests/fafafa.core.simd/rehearse_freeze_status.sh`
    - 新增 `case_mainline_fallback`，守住“cross 仍未 ready，但 mainline-ready 不能被 fast gate 冲掉”的边界
- 已验证：
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - `bash -n tests/fafafa.core.simd/rehearse_freeze_status.sh`
  - `python3 -m py_compile tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-rehearsal`
    - `case_mainline_fallback_rc=1`
    - `[FREEZE-REHEARSAL] OK`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
    - `ready=False, mainline-ready=True, cross-ready=False`
    - 输出明确指向 `selected fallback backup gate snapshot ... because latest snapshot ... only covers base-required steps`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-linux`
    - 仍保持 `ready=True, mainline-ready=True`
- 当前真实剩余项已经更收敛：
  - `windows_preflight_latest` 仍是 `RECENT_BILLING_BLOCK`
  - `windows_evidence_verify` 仍因为现有 `windows_b07_gate.log` 不完整而 FAIL
  - 也就是说，Linux mainline truth 已恢复，剩下红项重新只剩 Windows closeout/evidence 这条链

## 2026-05-17 Prevent Invalid GH Windows Artifact From Poisoning Canonical Evidence

- 在继续深看 Windows closeout/evidence 链时，我把当前 canonical `tests/fafafa.core.simd/logs/windows_b07_gate.log` 打开核对，发现它不是一份“缺几行细节”的接近完成日志，而是一份明确失败的 batch：
  - `[BUILD] FAILED ... Can't recognize '"lazbuild"' ...`
  - `[B07] GATE_EXIT_CODE=1`
- 进一步读 `tests/fafafa.core.simd/run_windows_b07_closeout_via_github_actions.sh` 后，确认了真正原因：
  - 脚本下载 artifact 后，会先把 `windows_b07_gate.log` / `gate_summary` 回写到 canonical logs
  - 然后才跑 `verify_windows_b07_evidence.sh`
  - 所以只要 GH artifact 是坏的，脚本虽然会 verify fail 退出，但 canonical 指针已经被污染
- 已落地修法：
  - 先只把 artifact evidence / gate summary 落到 batch snapshot
  - 先对 batch evidence 跑 verifier
  - 只有 verifier PASS 后，才把 `windows_b07_gate.log` promote 到 canonical `logs/`
  - Windows artifact 自带的 `gate_summary.{md,json}` 不再在 verify 前覆写 canonical；canonical gate summary 继续优先信后续 Linux cross backfill gate
- 已验证：
  - `bash -n tests/fafafa.core.simd/run_windows_b07_closeout_via_github_actions.sh`
  - 本地 stub 复现：
    - 伪造一个 explicit run-id 的 GH artifact 下载场景
    - artifact 内只有一份明显无效的 `windows_b07_gate.log`
    - 结果脚本 `RC=1`，batch snapshot 被写入，canonical `windows_b07_gate.log` 保持原 sentinel 内容不变
  - 也就是说，坏 artifact 现在只会停留在 batch 目录，不会再把顶层 canonical evidence 指针搞脏

## 2026-05-17 Windows Batch lazbuild Invocation Hardening

- 在确认 canonical evidence 被污染的同时，我继续追当前顶层 `windows_b07_gate.log` 的失败根因，日志里的关键失败已经很具体：
  - `Can't recognize '"lazbuild" --build-mode=Release ...' as an internal or external command`
- 回看 Windows batch runner 后，发现 SIMD 这一支内部还不统一：
  - `tests/fafafa.core.simd/buildOrTest.bat`
  - `tests/fafafa.core.simd.intrinsics.sse/buildOrTest.bat`
  - `tests/fafafa.core.simd.intrinsics.mmx/buildOrTest.bat`
  - 这 3 个 runner 仍是直接执行 `" %LAZBUILD_EXE% " ...`
  - 但 `tests/fafafa.core.simd.cpuinfo.x86/buildOrTest.bat` 已经在用更稳的 `call "%LAZBUILD_EXE%" ...`
- 已落地修法：
  - 把上面 3 个 SIMD Windows batch runner 的 `lazbuild` 调起方式统一改成 `call "%LAZBUILD_EXE%" ...`
  - 目的不是“批量风格统一”，而是先收掉当前真实坏日志已经命中的那条 Windows PATH fallback 易碎点
- 已验证：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh runner-parity`
    - `[CHECK] OK (windows runner parity signatures present)`
    - `[CHECK] OK (cpuinfo runner parity signatures present)`
    - `[CHECK] OK (runner parity quick path)`
  - `git diff --check`
- 当前限制：
  - 由于沙箱内 `wine cmd` 运行受限，我没法在这轮里补一条真正的 Windows/CMD 级执行复现
  - 但这批修法有直接的坏日志证据支撑，并且与当前已稳定的 `cpuinfo.x86` batch 调起方式保持一致

## 2026-05-17 Freeze Status Windows Failure Hint Prioritization

- 在 Windows closeout/evidence 链继续收口时，我没有再去追一堆 `Missing pattern:`，而是先回到 `freeze-status` 当前真正暴露给人的信号质量问题：
  - 之前 `windows_evidence_verify` fail 时，detail 基本就是 verifier 第一坨 missing-pattern 输出
  - 但当前 canonical `windows_b07_gate.log` 明明已经把 root cause 写得更直接：Windows batch 在主 build 阶段就因为 `"lazbuild"` 调起失败而 `GATE_EXIT_CODE=1`
- 已落地修法：
  - `tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
    - 新增 Windows log root-cause hint 提取
    - 优先识别 `BUILD FAILED`、`Can't recognize`、`GATE_EXIT_CODE!=0`
    - `windows_evidence_verify` fail detail 现在改为：
      - `root-cause hint: ...`
      - `verifier failed rc=...`
      - `first verifier issue: ...`
  - `tests/fafafa.core.simd/rehearse_freeze_status.sh`
    - 新增 `case_windows_hint`
    - 专门守住“失败提示先给根因 hint，再给 verifier 首条 issue”的边界
- 已验证：
  - `python3 -m py_compile tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
  - `bash -n tests/fafafa.core.simd/rehearse_freeze_status.sh`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-rehearsal`
    - `[FREEZE-REHEARSAL] OK`
    - `case_windows_hint_rc=1`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
    - `windows_evidence_verify` 现在会先输出：
      - `root-cause hint: Can't recognize '"lazbuild"' ...`
      - 然后才补 `first verifier issue: [EVIDENCE] Missing pattern: [GATE] OK`
- 当前阶段结论：
  - `freeze-status` 现在已经把 Windows evidence 的真实 hot path 抬出来了
  - 剩余 cross 红项依然没变：
    - `windows_preflight_latest = RECENT_BILLING_BLOCK`
    - `windows_evidence_verify = FAIL`
  - 但至少下一轮继续收 Windows 链时，不会再先被 verifier 噪音带偏

## 2026-05-17 Closeout-Release Cached Billing-Block Fallback Verified

- 继续沿当前最高价值 residual 往下收时，我没有再扩回 SIMD 泛审查，而是只盯一个问题：
  - `win-evidence-preflight` 明明还能 fresh 打出 `RECENT_BILLING_BLOCK`
  - 但 `closeout-release` 顶层入口在 live workflow query 抖动时，仍会直接以 `WORKFLOW_QUERY_FAILED(24)` 退出
- 这轮先确认真实现象：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight`
    - `STATUS=FAIL CODE=RECENT_BILLING_BLOCK EXIT=31`
    - workflow run `25967172435`
  - 一次真实 `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh closeout-release SIMD-20260517-152`
    - 仍先暴露出 `WORKFLOW_QUERY_FAILED EXIT=24`
    - 说明问题不在 SIMD 实现，而在顶层 preflight / cached truth 的衔接
- 已落地修法：
  - `tests/fafafa.core.simd/preflight_windows_b07_evidence_gh.sh`
    - 新增 `resolve_repo_from_remote()` / `resolve_repo_name()`
    - `gh repo view` 失败时，回退到 `git remote origin` 解析 `owner/repo`
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - 新增 `win_preflight_latest_has_fresh_billing_block_cache()`
    - `run_closeout_release()` 在 live preflight 前先记住 fresh cache 状态
    - 若 live preflight 返回 `24` 且旧 cache 是 fresh `RECENT_BILLING_BLOCK`，则直接打印 warning，复用 cached truth，并按 `31` fail-fast 停止
  - `tests/fafafa.core.simd/rehearse_win_preflight_repo_fallback.sh`
    - 新增 focused rehearsal，专门守 repo resolve fallback
  - `tests/fafafa.core.simd/rehearse_closeout_release_preflight_block.sh`
    - 新增 cached billing-block fallback case
- 已验证：
  - `git diff --check`
  - `bash -n tests/fafafa.core.simd/preflight_windows_b07_evidence_gh.sh`
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - `bash -n tests/fafafa.core.simd/rehearse_win_preflight_repo_fallback.sh`
  - `bash -n tests/fafafa.core.simd/rehearse_closeout_release_preflight_block.sh`
  - `bash tests/fafafa.core.simd/rehearse_win_preflight_repo_fallback.sh`
    - `[PREFLIGHT-REPO-FALLBACK] OK`
  - `bash tests/fafafa.core.simd/rehearse_closeout_release_preflight_block.sh`
    - `[CLOSEOUT-RELEASE-PREFLIGHT-REHEARSAL] OK`
  - 真实复验：
    - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh closeout-release SIMD-20260517-152`
    - 现在会先看到 live `WORKFLOW_QUERY_FAILED EXIT=24`
    - 随后正确输出：
      - `WARN live preflight query failed rc=24; reusing fresh cached RECENT_BILLING_BLOCK result`
      - `STOP latest preflight is RECENT_BILLING_BLOCK`
    - 进程最终 `exit=31`
- 当前真实位置：
  - `closeout-release` 顶层 operator truth 已收正，不再把 query noise 误报成主状态
  - Linux/mainline 仍是绿的
  - cross 仍未闭环，但剩余 blocker 已重新收敛成外部 Windows evidence/billing，可继续按真实 Windows runner 或 billing 恢复后再刷 fresh evidence

## 2026-05-17 Preserve Win-Preflight Latest Truth When Live Query Fails

- 在上一批把 `closeout-release` 顶层入口收成 `24 -> cached 31` 之后，我又做了一次真实 completion audit，结果发现还有一条更细的 truth-split：
  - standalone `win-evidence-preflight` 可以 fresh 打出 `RECENT_BILLING_BLOCK`
  - 但 `closeout-release` 里的 live preflight 若再次撞到 `WORKFLOW_QUERY_FAILED`
  - 它虽然已经会在 stdout 上按 cached billing-block 停机
  - 却仍会把 `tests/fafafa.core.simd/logs/win_preflight_latest.json` 覆写成 `WORKFLOW_QUERY_FAILED`
  - 于是 `freeze-status` 下一次又会把 `windows_preflight_latest` 对外报成 query error
- 这轮只收这个 residual，没有再扩 scope。
- 已落地修法：
  - `tests/fafafa.core.simd/preflight_windows_b07_evidence_gh.sh`
    - 新增 `PREFLIGHT_DIAGNOSTIC_{JSON,MD}_FILE`
    - `write_report()` 现在支持显式输出目标文件
    - 新增 `latest_report_is_recent_billing_block()`
    - 当新结果是 `WORKFLOW_QUERY_FAILED`、且当前 latest 仍是 fresh `RECENT_BILLING_BLOCK` 时：
      - 保留 `win_preflight_latest.{json,md}` 不变
      - 把这次瞬时 query failure 写入 `win_preflight_latest.diagnostic.{json,md}`
      - stdout 明确打印 `preserving latest RECENT_BILLING_BLOCK report`
  - `tests/fafafa.core.simd/rehearse_win_preflight_preserve_latest_on_query_failure.sh`
    - 新增 focused rehearsal，专门守“latest truth 不被 query noise 覆写”这条边界
- 已验证：
  - `git diff --check`
  - `bash -n tests/fafafa.core.simd/preflight_windows_b07_evidence_gh.sh`
  - `bash -n tests/fafafa.core.simd/rehearse_win_preflight_preserve_latest_on_query_failure.sh`
  - `bash tests/fafafa.core.simd/rehearse_win_preflight_preserve_latest_on_query_failure.sh`
    - `[PREFLIGHT-PRESERVE-LATEST] OK`
  - 真实链路复验：
    - `bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight`
      - fresh 返回 `RECENT_BILLING_BLOCK EXIT=31`
    - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh closeout-release SIMD-20260517-152`
      - live preflight 再次返回 `WORKFLOW_QUERY_FAILED EXIT=24`
      - 但现在会明确打印：
        - `preserving latest RECENT_BILLING_BLOCK report; writing transient diagnostic sidecar`
      - 顶层仍正确 `exit=31`
    - `cat tests/fafafa.core.simd/logs/win_preflight_latest.json`
      - latest 仍保持 `code=RECENT_BILLING_BLOCK`
    - `cat tests/fafafa.core.simd/logs/win_preflight_latest.diagnostic.json`
      - diagnostic sidecar 记录 `code=WORKFLOW_QUERY_FAILED`
    - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
      - `windows_preflight_latest` 重新稳定显示 `RECENT_BILLING_BLOCK`
      - next-actions 重新收敛成：
        - 处理 GitHub Billing / 切真实 Windows runner
        - `win-evidence-preflight`
        - `win-closeout-3cmd`
- 当前阶段结论：
  - `closeout-release` 与 `freeze-status` 现在共享同一份 Windows blocked truth
  - repo 内还能继续修的 preflight/evidence 信号链残差又收掉了一层
  - 当前剩余 cross 红点重新只剩外部 Windows evidence freshness 与现有坏 `windows_b07_gate.log` 的真实替换，而不是 latest preflight truth 再次漂移

## 2026-05-17 Standalone Win-Preflight Stdout Now Matches Preserved Billing Truth

- 在上一批把 latest report 保住之后，我没有停在“文件落盘正确”这个 proxy signal，而是继续看 direct operator surface：
  - 如果 standalone `win-evidence-preflight` 自己的 stdout / exit code 还停在 `WORKFLOW_QUERY_FAILED(24)`
  - 那么实际手跑这个入口的人，依然会和 `closeout-release` / `freeze-status` 看到两套不同真相
- 这轮因此继续只收这一个 residual：
  - `tests/fafafa.core.simd/preflight_windows_b07_evidence_gh.sh`
    - 新增 `PREFLIGHT_CACHE_MAX_AGE_HOURS="${SIMD_WIN_PREFLIGHT_CACHE_MAX_AGE_HOURS:-2}"`
    - preserve 分支不再沿用 24h billing window，而是与 `closeout-release` 的 fresh-cache 语义对齐
    - 当 live query 失败但 latest 仍是 fresh `RECENT_BILLING_BLOCK` 时：
      - stdout 直接输出 `STATUS=FAIL CODE=RECENT_BILLING_BLOCK EXIT=31`
      - 说明 live query failure 只作为 diagnostic sidecar 保留
      - 进程 `exit=31`
  - `tests/fafafa.core.simd/rehearse_win_preflight_preserve_latest_on_query_failure.sh`
    - 正例：fresh billing-block cache + live query failure => stdout 也必须是 `RECENT_BILLING_BLOCK EXIT=31`
    - 反例：stale billing-block cache + live query failure => 仍应保持 `WORKFLOW_QUERY_FAILED EXIT=24`
  - active docs：
    - `docs/fafafa.core.simd.closeout.md`
    - `docs/fafafa.core.simd.checklist.md`
    - 已补上 diagnostic sidecar 与 preserved stdout truth 口径
- 已验证：
  - `git diff --check`
  - `bash -n tests/fafafa.core.simd/preflight_windows_b07_evidence_gh.sh`
  - `bash -n tests/fafafa.core.simd/rehearse_win_preflight_preserve_latest_on_query_failure.sh`
  - `bash tests/fafafa.core.simd/rehearse_win_preflight_preserve_latest_on_query_failure.sh`
    - fresh case:
      - `STATUS=FAIL CODE=RECENT_BILLING_BLOCK EXIT=31`
      - diagnostic sidecar 记录 `WORKFLOW_QUERY_FAILED`
    - stale case:
      - `STATUS=FAIL CODE=WORKFLOW_QUERY_FAILED EXIT=24`
  - 真实复验：
    - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh closeout-release SIMD-20260517-152`
      - 这次 again 命中 live query 抖动
      - 但 preflight stdout 已直接输出：
        - `STATUS=FAIL CODE=RECENT_BILLING_BLOCK EXIT=31`
        - `live query failed (WORKFLOW_QUERY_FAILED) but preserving fresh cached RECENT_BILLING_BLOCK operator truth`
      - `closeout-release` 随后继续按 `code-green / release-evidence-blocked` 收口
    - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
      - `windows_preflight_latest` 仍稳定显示 `RECENT_BILLING_BLOCK`
      - next-actions 继续只剩 billing / 实机 runner / `win-closeout-3cmd`
- 当前阶段结论：
  - standalone preflight、closeout-release、freeze-status 三个主要 operator surface 现在已经对齐到同一份 Windows blocked truth
  - 当前 remaining gap 继续只剩外部 Windows runner/billing 与 fresh green evidence，而不是 repo 内 preflight truth 再次分裂

## 2026-05-17 Clear Stale Preflight Diagnostic Sidecars On Normal Main-Report Writes

- 在上一批把 standalone preflight 的 stdout truth 收正后，我继续按 artifact 级 completion audit 看真实 logs，发现还有一个小但真实的 hygiene residual：
  - preserved branch 写出的
    - `tests/fafafa.core.simd/logs/win_preflight_latest.diagnostic.json`
    - `tests/fafafa.core.simd/logs/win_preflight_latest.diagnostic.md`
  - 在后续 direct preflight 已经直接返回 `RECENT_BILLING_BLOCK` 后，还会继续残留
  - 这不会影响主状态判断，但会给后续人工诊断留下“旁边还挂着一份过期 query failure”的噪音
- 已落地修法：
  - `tests/fafafa.core.simd/preflight_windows_b07_evidence_gh.sh`
    - 新增 `clear_diagnostic_sidecar()`
    - normal `pass_with()` 先清掉 stale diagnostic sidecar
    - normal `fail_with()` main-report path 在写 latest report 前也先清掉 stale diagnostic sidecar
    - preserve 分支仍保留 sidecar，不改
  - `tests/fafafa.core.simd/rehearse_win_preflight_preserve_latest_on_query_failure.sh`
    - 新增 direct billing-block case
    - 明确要求：前一轮 preserved case 生成的 diagnostic sidecar，必须在 direct billing-block case 被清掉
    - 继续保留 stale-cache negative case，保证不是所有 `24` 都会被 billing-block truth 吞掉
- 已验证：
  - `git diff --check`
  - `bash -n tests/fafafa.core.simd/preflight_windows_b07_evidence_gh.sh`
  - `bash -n tests/fafafa.core.simd/rehearse_win_preflight_preserve_latest_on_query_failure.sh`
  - `bash tests/fafafa.core.simd/rehearse_win_preflight_preserve_latest_on_query_failure.sh`
    - preserved case: 生成 diagnostic sidecar
    - direct billing-block case: 清掉 stale diagnostic sidecar
    - stale-cache case: 仍返回 `WORKFLOW_QUERY_FAILED EXIT=24`
  - 真实复验：
    - 先看到旧 sidecar 仍存在
    - 再跑 `bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight`
      - direct 返回 `RECENT_BILLING_BLOCK EXIT=31`
    - 随后确认：
      - `tests/fafafa.core.simd/logs/win_preflight_latest.diagnostic.json` 不存在
      - `tests/fafafa.core.simd/logs/win_preflight_latest.diagnostic.md` 不存在
- 当前阶段结论：
  - preflight latest truth / stdout truth / transient diagnostic sidecar 这三层现在都已经各归其位
  - repo 内还能继续收的 Windows preflight artifact hygiene 又少了一条
  - 当前 remaining gap 继续只剩外部 Windows billing/runner 与 fresh green evidence，而不是本地 preflight artifact 再残留旧噪音

## 2026-05-17 Mark Windows Failure Log And Closeout Summary Stale When Producer Inputs Are Newer

- 在把 preflight sidecar 清干净之后，我继续对真实 `freeze-status` 做 completion audit，发现还有一条更靠近 evidence truth 的残差：
  - 当前 `windows_b07_gate.log` 虽然还满足 age freshness
  - `linux_sources_not_newer_than_windows_evidence` 也还是 PASS
  - 但真正负责生成它的 `tests/fafafa.core.simd/buildOrTest.bat` 已经比它更新
  - 所以这份 Windows 失败 log 其实是 pre-runner-fix 的 historical failure，而不是当前 runner truth
- 已落地修法：
  - `tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
    - 新增 `WINDOWS_EVIDENCE_LOG_INPUT_RELATIVE_PATHS`
    - 新增 `iter_windows_evidence_log_input_candidates()`
    - 新增 `candidate_paths_not_newer_than_artifact_check()`
    - 真实 `freeze-status` 现在会多一条 required check：
      - `windows_evidence_inputs_not_newer_than_log`
    - 若 producer inputs 比 `windows_b07_gate.log` 新：
      - `windows_evidence_verify` 改为 `stale evidence log: ... historical verifier detail: ...`
      - `windows_closeout_summary` 也改为 `stale summary: ...`
  - `tests/fafafa.core.simd/rehearse_freeze_status.sh`
    - 新增 `case_windows_producer_newer`
    - 专门守住“producer files 新于 Windows log 时，log/summary 都必须降格为 stale historical evidence”的边界
  - active docs：
    - `docs/fafafa.core.simd.closeout.md`
    - `docs/fafafa.core.simd.checklist.md`
    - 已同步写明 stale producer drift 的判断规则
- 已验证：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
  - `bash -n tests/fafafa.core.simd/rehearse_freeze_status.sh`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-rehearsal`
    - `[FREEZE-REHEARSAL] OK`
    - `case_windows_producer_newer_rc=1`
  - 真实复验：
    - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
    - 现在新增：
      - `FAIL windows_evidence_inputs_not_newer_than_log`
    - 并且旧的 Windows evidence/summary 都已被正确降格：
      - `FAIL windows_evidence_verify: stale evidence log: newer Windows evidence producer input exists; historical verifier detail: ...`
      - `FAIL windows_closeout_summary: stale summary: newer Windows evidence producer input exists; rerun evidence-win-verify / closeout before trusting ...`
- 当前阶段结论：
  - `freeze-status` 现在不再把 pre-runner-fix 的 Windows 失败日志误当成当前实现真相
  - repo 内 Windows evidence truth 解释又收正了一层
  - 当前 remaining gap 继续只剩外部 Windows billing/runner 恢复后刷新 fresh evidence，而不是继续围着这份历史失败日志打转

## 2026-05-17 Refreshed Current Wine Batch Evidence After The LAZBUILD Invocation Fix

- 在上一批把 stale historical evidence 边界收清后，我没有停在“解释更准确了”，而是又直接重跑了一次真实本机 Windows batch evidence：
  - `wine cmd /c tests\\fafafa.core.simd\\buildOrTest.bat evidence-win-verify`
- 这次 fresh evidence 有两个关键结果：
  - canonical `tests/fafafa.core.simd/logs/windows_b07_gate.log` 已被刷新到新的 mtime
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status` 里：
    - `windows_evidence_freshness = PASS`
    - `windows_evidence_inputs_not_newer_than_log = PASS`
  - 说明“旧 log 落后于当前 runner”的 stale 问题，在当前 `HEAD` 上已经不再命中
- 这轮同时还补了一条真实 batch runner 修法：
  - `tests/fafafa.core.simd/buildOrTest.bat`
  - `tests/fafafa.core.simd.intrinsics.sse/buildOrTest.bat`
  - `tests/fafafa.core.simd.intrinsics.mmx/buildOrTest.bat`
  - `tests/fafafa.core.simd.cpuinfo.x86/buildOrTest.bat`
  - 现在对 `LAZBUILD_EXE` 分成 3 类：
    - `.bat/.cmd` wrapper：继续用 `call`
    - 存在的可执行路径：直接执行
    - bare command：直接执行
  - 目的：
    - 不再把 bare `lazbuild` 拼成 `'"lazbuild"'`
    - 同时不回退 `LAZBUILD` 指向 batch wrapper 的兼容能力
- 已验证：
  - `git diff --check`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh runner-parity`
    - `[CHECK] OK (windows runner parity signatures present)`
    - `[CHECK] OK (cpuinfo runner parity signatures present)`
    - `[CHECK] OK (runner parity quick path)`
  - 真实 Wine batch：
    - `wine cmd /c tests\\fafafa.core.simd\\buildOrTest.bat evidence-win-verify`
    - 新鲜 `windows_b07_gate.log` 里的失败已经从旧的 `'"lazbuild"'` 变成：
      - `Can't recognize 'lazbuild --build-mode=Release ...'`
  - 真实 `freeze-status`：
    - `windows_evidence_inputs_not_newer_than_log = PASS`
    - `windows_evidence_verify` 继续 FAIL，但当前根因已经更新为 fresh Wine batch 当前失败，而不是 stale historical evidence
    - `windows_closeout_summary` 重新回到 `summary matches verifier FAIL`
- 当前阶段结论：
  - repo-local 的 batch quoting / `call` 误导已经被继续压缩
  - 当前最新 Windows log 终于重新代表“现行 runner 下的真实失败”
  - 但这份 fresh failure 也同时证明：本机 Wine 仍不能把 Linux 侧 bare `lazbuild` 直接当成 Windows batch 可执行命令
  - 因而当前 remaining gap 再次收敛成：
    - 外部 GitHub Billing / Windows runner 可用性
    - 或一个真正稳定的 Wine-to-Unix lazbuild bridge
  - 在没有后者稳定通路前，继续深挖 Wine 适配层的收益已经明显低于直接拿真实 Windows runner

## 2026-05-17 Mark Closeout Summary Stale When Fresh Current Windows Log Is Newer

- 在 fresh current Windows log 已经刷回来之后，我继续做 completion audit，发现 `freeze-status` 还有最后一个相邻 truth-split：
  - `windows_b07_gate.log` 已经是 17:27 的 current log
  - 但 `windows_b07_closeout_summary.md` 还是 12:34 的旧 summary
  - 之前 summary 逻辑只看 `- Result: FAIL`，所以它还会被误判成 `summary matches verifier FAIL`
- 已落地修法：
  - `tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
    - 新增 `artifact_not_older_than_reference_check()`
    - 真实 `freeze-status` 现在多一条 required check：
      - `windows_closeout_summary_not_older_than_log`
    - 若 summary 旧于当前 log：
      - `windows_closeout_summary_not_older_than_log = FAIL`
      - `windows_closeout_summary = FAIL`，detail 为：
        - `stale summary: closeout summary is older than current windows evidence log`
      - next-actions 增加：
        - `bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence`
  - `tests/fafafa.core.simd/rehearse_freeze_status.sh`
    - 新增 `case_closeout_summary_older`
    - 专门守住“log 已刷新，但 summary 还旧”这条边界
  - active docs：
    - `docs/fafafa.core.simd.closeout.md`
    - `docs/fafafa.core.simd.checklist.md`
    - 已同步到“fresh current log + stale closeout summary”的新口径
- 已验证：
  - `python3 -m py_compile tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
  - `bash -n tests/fafafa.core.simd/rehearse_freeze_status.sh`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-rehearsal`
    - `[FREEZE-REHEARSAL] OK`
    - `case_closeout_summary_older_rc=1`
  - 真实复验：
    - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
    - 现在新增：
      - `FAIL windows_closeout_summary_not_older_than_log`
      - `FAIL windows_closeout_summary: stale summary: closeout summary is older than current windows evidence log`
    - next-actions 也已补上：
      - `bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence`
- 当前阶段结论：
  - fresh current Windows log / stale closeout summary / external billing blocker 这三层现在终于被 `freeze-status` 分开说清楚了
  - repo 内还能继续修的 Windows evidence truth-splitting 又少了一条
  - 当前 remaining gap 继续只剩：
    - GitHub Billing / Windows runner 可用性
    - 或真正稳定的 Wine-to-Unix lazbuild bridge

## 2026-05-17 Wine Local Lazbuild Preflight Fail-Close

- 继续按“只收一个 residual”的边界审了当前 fresh Windows evidence 失败链，没有再回到 SIMD 算法层。
- 这轮先把 Wine 环境事实钉死了：
  - `wine cmd /c where lazbuild` -> `File not found`
  - `wine cmd /c where bash` -> `File not found`
  - `wine cmd /c echo %PATH%` 只含 `C:\windows...`
  - `cmd` 虽然能 `dir Z:\opt\fpcupdeluxe\lazarus\lazbuild`，但不能直接执行 Linux ELF
- 结论因此更明确：
  - 当前 fresh `Can't recognize 'lazbuild ...'` 的上一层真实原因，不是 SIMD 代码，不是 batch quoting 再次回退，而是 Wine `cmd.exe` 根本拿不到可执行的 native Windows `lazbuild.exe`
- 已落地的最小修法：
  - `tests/fafafa.core.simd/buildOrTest.bat`
    - 在 `:build` 前新增 `:ensure_lazbuild_available`
    - 若 `cmd.exe` 解析不到 `LAZBUILD`：
      - 提前写入 `[BUILD] TOOLCHAIN BLOCK: ...`
      - 给出“安装 native Windows `lazbuild.exe` 或设置 Windows wrapper”的明确 hint
      - Wine 场景下再额外提示：`cmd.exe` 不继承 Unix PATH，也不能直接执行 Linux ELF lazbuild
    - 不再等到真正 build 命令展开后，才留下一句模糊的 `Can't recognize ...`
  - `tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
    - `extract_windows_log_failure_hint()` 现在会优先抓 `TOOLCHAIN BLOCK`
    - 让 `freeze-status` 能把这类环境级 blocker 直接收进 `root-cause hint`
- 当前预期收益：
  - 后续再跑本机 Wine evidence 时，会更早 fail-close
  - `freeze-status` 不再只回显“命令没识别”的尾部症状，而能更直接指出“cmd.exe 下没有可用的 Windows lazbuild toolchain”
- 已验证：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
  - `wine cmd /c tests\\fafafa.core.simd\\buildOrTest.bat evidence-win-verify`
    - 新鲜 `windows_b07_gate.log` 现在直接落出：
      - `[BUILD] TOOLCHAIN BLOCK: cmd.exe cannot resolve LAZBUILD command "lazbuild"`
      - `Hint: install native Windows lazbuild.exe or set LAZBUILD to a Windows .exe/.bat/.cmd wrapper visible to cmd.exe`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence`
    - 结果仍为 verifier `FAIL`，但 `windows_b07_closeout_summary.md` 已同步到 current log
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
    - `windows_evidence_verify` 现在变成：
      - `root-cause hint: [BUILD] TOOLCHAIN BLOCK: cmd.exe cannot resolve LAZBUILD command "lazbuild"`
    - `windows_closeout_summary_not_older_than_log = PASS`
    - `windows_closeout_summary = PASS summary matches verifier FAIL`
- 当前阶段结论：
  - repo-local 现在已经把“Wine 本机为什么跑不通 Windows evidence”说到了 toolchain 级别，而不是停在 `Can't recognize ...` 的尾部症状
  - 当前 remaining gap 继续只剩外部条件：
    - `RECENT_BILLING_BLOCK`
    - 真实 Windows runner / native Windows `lazbuild.exe`

## 2026-05-17 Closeout 3cmd Native-Lazbuild Requirement Sync

- 在上一批把 `TOOLCHAIN BLOCK` 落进 current Windows log 之后，我继续审查 active closeout 入口，确认还有一个相邻误导点：
  - `win-closeout-3cmd` 已经说了 “Wine 不算真实 Windows evidence runner”
  - 但手工 Windows 路径的 `2.1 tests\\fafafa.core.simd\\buildOrTest.bat evidence-win-verify`
  - 还没有把“必须具备 native Windows `lazbuild.exe` / Windows wrapper”说成硬前提
- 这会留下一个很现实的误导空间：
  - 读者虽然知道 Wine 不算最终 evidence runner
  - 但仍可能把 `2.1` 误解成“任何能开 `cmd.exe` 的环境都能先跑”
  - 结果又回到刚收掉的 `TOOLCHAIN BLOCK`
- 已落地的最小修法：
  - `tests/fafafa.core.simd/print_windows_b07_closeout_3cmd.sh`
    - `2.1` 现在明确写成：
      - 前提：本机能直接执行 native Windows `lazbuild.exe`
      - 不要拿 Wine/cmd 冒充实机
    - 同时给出显式 override 片段：
      - `$env:LAZBUILD = 'C:\Lazarus\lazbuild.exe'`
    - 说明区再补一条硬约束：
      - `LAZBUILD` 必须解析到 native Windows `.exe/.bat/.cmd`
      - 不要指向 `Z:\opt\...` 这种 Wine 可见但 `cmd.exe` 不能执行的 Linux ELF
  - `tests/fafafa.core.simd/rehearse_windows_closeout_3cmd.sh`
    - blocked/pass 两个 case 都新增断言
    - 强制要求 helper 输出里必须保留：
      - `native Windows \`lazbuild.exe\``
      - `LAZBUILD` override snippet
- 已验证：
  - `git diff --check`
  - `bash tests/fafafa.core.simd/rehearse_windows_closeout_3cmd.sh`
    - `[WIN-CLOSEOUT-3CMD-REHEARSAL] OK`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-3cmd SIMD-20260517-152`
    - helper 输出已带上 native Windows lazbuild requirement 与 `LAZBUILD` override
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary-selfcheck`
    - `[GATE-SUMMARY-SELFCHECK] OK`
- 当前阶段结论：
  - active closeout helper 现在已经把“手工 Windows 实机路径的 toolchain 前提”说清楚了
  - 当前 remaining gap 仍然没有变化，继续只剩外部条件：
    - `RECENT_BILLING_BLOCK`
    - 真实 Windows runner / native Windows `lazbuild.exe`

## 2026-05-17 Freeze Status Next-Action Toolchain Sync

- 继续做 completion audit 后，又看到一个最后的小残差：
  - `freeze-status` 虽然已经能在 `windows_evidence_verify` 里显示 `TOOLCHAIN BLOCK`
  - 但 `next-actions` 之前仍主要是泛化的：
    - `win-evidence-preflight`
    - `win-closeout-3cmd`
  - 这意味着读者仍要先通读 detail，才会意识到当前不是“再试一次 batch”，而是“先解决 Windows lazbuild toolchain”
- 已落地的最小修法：
  - `tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
    - 新增 `WINDOWS_TOOLCHAIN_ACTION`
    - 新增 `is_windows_toolchain_block(...)`
    - 当 `windows_evidence_verify` detail 命中 `TOOLCHAIN BLOCK` 时：
      - `next-actions` 会主动插入：
        - `Provide a real Windows runner with native Windows lazbuild.exe, or set LAZBUILD to a Windows .exe/.bat/.cmd wrapper; Wine/cmd cannot execute Linux lazbuild`
    - 这条动作会在：
      - 当前有 `RECENT_BILLING_BLOCK` 的路径里保留
      - 非 billing-block 的普通 Windows closeout 路径里也保留
  - `tests/fafafa.core.simd/rehearse_freeze_status.sh`
    - 新增 `case_windows_toolchain_action`
    - 专门守住“有 toolchain block 时，next-actions 必须出现 native Windows lazbuild / real runner 指令”
- 已验证：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status-rehearsal`
    - `[FREEZE-REHEARSAL] OK`
    - `case_windows_toolchain_action_rc=1`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
    - 当前真实 `next-actions` 已变成：
      - `Resolve GitHub Billing & plans or switch to a real Windows runner...`
      - `Provide a real Windows runner with native Windows lazbuild.exe, or set LAZBUILD to a Windows .exe/.bat/.cmd wrapper; Wine/cmd cannot execute Linux lazbuild`
      - `bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight`
      - `bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-3cmd SIMD-20260517-152`
- 当前阶段结论：
  - `freeze-status` 现在不只是“把失败看懂”，而是已经把当前 Windows 链的真实动作顺序说到了 toolchain 层
  - 当前 repo-local 可继续收的 Windows closeout 误导项已经非常少了

## 2026-05-17 Active Closeout Docs Native-Lazbuild Sync

- 在把 helper / `freeze-status` 的 toolchain 诊断都收紧之后，我又做了一轮 active docs/entry audit，确认还有一批“会被直接拿来照着跑”的入口仍然写得太乐观：
  - `docs/fafafa.core.simd.handoff.md`
  - `docs/fafafa.core.simd.closeout.md`
  - `docs/fafafa.core.simd.checklist.md`
  - `tests/fafafa.core.simd/docs/windows_b07_closeout_runbook.md`
  - `tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md`
  - `tests/fafafa.core.simd/docs/simd_completeness_matrix.md`
  - `tests/fafafa.core.simd/buildOrTest.bat` 里的 `win_closeout_3cmd`
  - `tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh`
- 这些入口之前虽然大多已经承认 “Wine 不算真实 Windows evidence runner”，但还没把“`evidence-win-verify` 只能跑在 real Windows + native Windows `LAZBUILD`”写成硬前提。
- 已落地的最小修法：
  - 所有 active closeout 入口统一补上：
    - 手工 Windows 路径只应运行在真实 Windows runner / Windows 实机
    - `LAZBUILD` 必须解析到 native Windows `.exe/.bat/.cmd`
    - 不要把 `LAZBUILD` 指到 `Z:\opt\...` 这种 Wine 可见但 `cmd.exe` 不能执行的 Linux ELF
  - `tests/fafafa.core.simd/buildOrTest.bat`
    - `win_closeout_3cmd` 现在也直接打印：
      - `Requirement: native Windows lazbuild.exe / Windows wrapper only`
      - `Example override: set LAZBUILD=C:\Lazarus\lazbuild.exe`
  - `apply_windows_b07_closeout_updates.sh`
    - 在拒绝 apply 时，也会同步提示：要用 real Windows runner / Windows host with native Windows `LAZBUILD`
- 已验证：
  - `git diff --check`
  - `bash -n tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-3cmd SIMD-20260517-152`
    - shell helper 输出已带 `native Windows \`lazbuild.exe\`` 与 `$env:LAZBUILD` override
  - `wine cmd /c tests\\fafafa.core.simd\\buildOrTest.bat win-closeout-3cmd SIMD-20260517-152`
    - batch 自带输出也已带：
      - `Requirement: native Windows lazbuild.exe / Windows wrapper only`
      - `Example override: set LAZBUILD=C:\Lazarus\lazbuild.exe`
  - `rg -n -F ...` 对 active docs / helper / updater 的同步扫描已命中上述关键字
- 当前阶段结论：
  - active closeout 入口现在已经统一说清楚“manual Windows path 的真实前提条件”
  - 这意味着当前再有人沿 repo 内指导继续踩到 Wine/bare `lazbuild`，更大概率就是外部环境没满足，而不是仓库内 guidance 还在误导

## 2026-05-17 Windows Closeout Guard Selfcheck Sync

- 在把 active docs / batch helper 都同步到 `native Windows LAZBUILD` 前提后，我又补做了一轮 control-plane audit，发现 `tests/fafafa.core.simd/BuildOrTest.sh` 自带的 Windows manual closeout guard 还没把这条新前提纳入 machine-check。
- 这意味着如果未来有人又把相关提示改松了，repo 的 selfcheck 之前并不会报红，仍有回退风险。
- 已落地的最小修法：
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - `L3CmdRequired` / `LRunbookRequired` / `LCloseoutDocRequired` / `LHandoffRequired` / `LReleaseChecklistRequired` / `LCompletenessMatrixRequired`
    - 以及 helper runtime `LRequired`
    - 现在都额外要求命中：
      - `native Windows \`lazbuild.exe\``
      - `C:\Lazarus\lazbuild.exe` override
      - 或对应的 native Windows `.exe/.bat/.cmd` requirement
- 已验证：
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh runner-parity`
    - `[CHECK] OK (runner parity quick path)`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary-selfcheck`
    - `[GATE-SUMMARY-SELFCHECK] OK`
  - `git diff --check`
- 当前阶段结论：
  - 这条 `native Windows LAZBUILD` 前提现在不仅写进了文档和输出，还被 repo 内 selfcheck 正式守住
  - 当前 repo-local 的 Windows closeout guidance / guard / next-action 已基本形成单一口径

## 2026-05-17 Active Status Truth Sync And Evidence Refresh

- 在继续做 completion audit 时，我又抓到一个更高优先级的 active truth drift：
  - `docs/fafafa.core.simd.checklist.md` 顶部仍把 `windows_b07_closeout_summary.md` 写成 stale summary
  - `docs/fafafa.core.simd.handoff.md` 里也还挂着旧的 `2026-05-17 12:42:40` Windows evidence 时间线
  - 这两条都已经落后于当前实际 closeout 状态
- 已落地的最小修法：
  - `docs/fafafa.core.simd.checklist.md`
    - 改成当前真实状态：
      - `windows_b07_closeout_summary.md` 已经是 current FAIL summary
      - 当前真正剩余的是 `RECENT_BILLING_BLOCK` + `native Windows lazbuild` toolchain block
  - `docs/fafafa.core.simd.handoff.md`
    - 将最新 evidence 时间线改成：
      - `windows_b07_gate.log` fresh 到 `2026-05-17 17:49:15`
      - 当时对应的 closeout summary mtime 为 `2026-05-17 17:50:02`
    - 同时把当前 `freeze-status` 的真实 next-actions 也写明
- 这轮还顺手触发并收口了一个“当前真实状态变化”：
  - 因为前一批刚改过 `tests/fafafa.core.simd/buildOrTest.bat`
  - `freeze-status` 一度重新变成：
    - `windows_evidence_inputs_not_newer_than_log = FAIL`
    - `windows_evidence_verify = stale evidence log`
    - `windows_closeout_summary = stale summary`
  - 这不是新 bug，而是 producer input (`buildOrTest.bat`) 新于 canonical Windows log 后，stale rule 正常生效
- 已执行的真实刷新：
  - `wine cmd /c tests\\fafafa.core.simd\\buildOrTest.bat evidence-win-verify`
    - fresh canonical `windows_b07_gate.log` 刷到 `2026-05-17 18:10:01`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence`
    - current `windows_b07_closeout_summary.md` 刷到 `2026-05-17 18:10:40`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
    - 当前再次回到：
      - `windows_evidence_inputs_not_newer_than_log = PASS`
      - `windows_evidence_verify = FAIL`（root-cause 仍是 `TOOLCHAIN BLOCK`）
      - `windows_closeout_summary = PASS summary matches verifier FAIL`
- 已验证：
  - `git diff --check`
  - `rg -n -F -e "旧时间线" -e "12:42:40" -e "stale summary" docs/fafafa.core.simd.checklist.md docs/fafafa.core.simd.handoff.md`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
- 当前阶段结论：
  - active 顶层状态文档已经重新和 current freeze truth 对齐
  - canonical Windows evidence 现在也重新处于 fresh current FAIL，而不是 stale historical FAIL

## 2026-05-17 Windows Closeout Summary Root-Cause Sync

- 继续做 completion audit 时，我发现 `windows_b07_closeout_summary.md` 虽然已经是 current summary，但它本身的信息密度还不够：
  - 主要只是在堆 verifier 缺失项
  - 没有把真正的 `TOOLCHAIN BLOCK` 提炼成单独的失败边界
  - 也没有把“需要 native Windows `LAZBUILD` / real Windows runner”写成显式动作
- 这会导致一个问题：
  - `freeze-status` 已经能说清 root cause
  - 但如果维护者直接打开 `windows_b07_closeout_summary.md`
  - 仍然要自己从大段 `[EVIDENCE] Missing pattern` 里倒推真正边界
- 已落地的最小修法：
  - `tests/fafafa.core.simd/finalize_windows_b07_closeout.sh`
    - 现在额外提取：
      - `First Verifier Issue`
      - `Root Cause Hint`
      - `Recommended Action`
    - 若当前 log 命中 `TOOLCHAIN BLOCK` / `Can't recognize lazbuild`
      - summary 会新增 `## Failure Boundary`
      - 并明确给出：
        - `Provide a real Windows runner with native Windows lazbuild.exe...`
  - `tests/fafafa.core.simd/rehearse_windows_closeout_summary.sh`
    - 新增 fail-case rehearsal
    - 专门守住 `TOOLCHAIN BLOCK -> Failure Boundary -> Recommended Action` 这条 summary 生成链
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - `gate-summary-selfcheck` 现在也会执行这条新的 summary rehearsal
- 已验证：
  - `bash -n tests/fafafa.core.simd/finalize_windows_b07_closeout.sh`
  - `bash -n tests/fafafa.core.simd/rehearse_windows_closeout_summary.sh`
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - `bash tests/fafafa.core.simd/rehearse_windows_closeout_summary.sh`
    - `[WIN-CLOSEOUT-SUMMARY-REHEARSAL] OK`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary-selfcheck`
    - `[GATE-SUMMARY-SELFCHECK] OK`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence`
    - 当前 canonical `windows_b07_closeout_summary.md` 已刷新到 `2026-05-17 18:17:54`
    - 其中现在已包含：
      - `First Verifier Issue: [EVIDENCE] Missing pattern: [GATE] OK`
      - `## Failure Boundary`
      - `Root Cause Hint: [BUILD] TOOLCHAIN BLOCK: cmd.exe cannot resolve LAZBUILD command "lazbuild"`
      - `Recommended Action: Provide a real Windows runner with native Windows lazbuild.exe...`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
    - 当前仍是 `ready=False`
    - 但 `windows_closeout_summary_not_older_than_log = PASS`
    - `windows_closeout_summary = PASS summary matches verifier FAIL`
- 当前阶段结论：
  - current Windows closeout summary 现在已经从“低信号 FAIL 摘要”提升成“可直接交接的失败边界摘要”
  - 这条 Windows closeout 证据链在 repo 内的 operator-facing 文档 / helper / guard / summary 四层口径现在已经基本统一

## 2026-05-17 Windows Closeout Snippet Failure-Boundary Sync

- 在把 `windows_b07_closeout_summary.md` 升级成高信号摘要后，我又继续往下看了一层 operator surface：
  - `win-closeout-snippets` / `apply_windows_b07_closeout_updates.sh`
  - 之前在 FAIL 状态下仍只会输出“待补齐 / FAIL / BLOCKED”这种泛化片段
  - 没有把 summary 里已经存在的 `Root Cause Hint / Recommended Action` 继续带出来
- 这会留下一个明显的不对称：
  - 直接看 summary 的人能看到 `TOOLCHAIN BLOCK`
  - 但拿 snippets 去汇报/交接的人，仍然只会得到低信号的“Windows 证据未通过”
- 已落地的最小修法：
  - `tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh`
    - 现在会从 summary 里提取：
      - `Root Cause Hint`
      - `Recommended Action`
    - 当 verifier 不是 PASS 时：
      - roadmap snippet 新增：
        - `当前失败边界`
        - `建议动作`
      - matrix snippet 新增：
        - `当前失败边界`
        - `建议动作`
      - progress snippet 新增：
        - `Failure Boundary`
        - `Recommended Action`
  - `tests/fafafa.core.simd/rehearse_windows_closeout_summary.sh`
    - 在已有 summary rehearsal 的基础上，继续调用 snippet script
    - 强制要求 snippets 里也必须带出：
      - `当前失败边界：[BUILD] TOOLCHAIN BLOCK: ...`
      - `建议动作：Provide a real Windows runner with native Windows lazbuild.exe...`
- 已验证：
  - `bash -n tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh`
  - `bash -n tests/fafafa.core.simd/rehearse_windows_closeout_summary.sh`
  - `bash tests/fafafa.core.simd/rehearse_windows_closeout_summary.sh`
    - `[WIN-CLOSEOUT-SUMMARY-REHEARSAL] OK`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-snippets`
    - 当前 real snippet 已直接带出：
      - `当前失败边界：[BUILD] TOOLCHAIN BLOCK: cmd.exe cannot resolve LAZBUILD command "lazbuild"`
      - `建议动作：Provide a real Windows runner with native Windows lazbuild.exe...`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary-selfcheck`
    - `[GATE-SUMMARY-SELFCHECK] OK`
- 当前阶段结论：
  - 现在不止 `freeze-status` 和 summary，连 closeout snippets 也已经能把当前失败边界直接说清楚
  - 这条 Windows closeout operator surface 在 repo 内已经基本形成了同一套高信号失败表达

## 2026-05-17 QEMU Retry Rehearsal Runner Parity Sync

- 把范围继续压到当前 worktree 唯一剩下的 runner surface residual：
  - `tests/fafafa.core.simd/BuildOrTest.sh`
  - `tests/fafafa.core.simd/buildOrTest.bat`
- 真实缺口不是 SIMD 实现逻辑，而是：
  - shell 侧已经公开了 `qemu-cpuinfo-retry-rehearsal`
  - batch 侧之前还没把 route / usage / help / fail-close label 同步齐
  - 这会让 `runner-parity` 虽然大体收口，但仍留着一个隐藏的 Windows surface 漏口
- 已落地的最小修法：
  - `BuildOrTest.sh`
    - `check_windows_runner_parity()` 必检字符串新增：
      - `qemu-cpuinfo-retry-rehearsal` route
      - help line
      - fail-close line
      - running line
  - `buildOrTest.bat`
    - 新增 action route
    - usage synopsis / help 文案补齐
    - 新增 `:qemu_cpuinfo_retry_rehearsal`
      - 无 `bash` 时 fail-close
      - 有 `bash` 时 delegate 到 shell runner
- 已验证：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh runner-parity`
    - `[CHECK] OK (windows runner parity signatures present)`
    - `[CHECK] OK (cpuinfo runner parity signatures present)`
    - `[CHECK] OK (runner parity quick path)`
  - `git diff --check`
  - `wine cmd /c tests\\fafafa.core.simd\\buildOrTest.bat qemu-cpuinfo-retry-rehearsal qemu-cpuinfo-nonx86-evidence`
    - `[RETRY-REHEARSAL] FAILED (bash runtime not found; qemu-cpuinfo-retry-rehearsal requires bash to preserve shell parity)`
- 当前阶段结论：
  - repo 内最后这个 `qemu retry rehearsal` 的 shell/batch parity surface 已收口
  - 当前 SIMD closeout 还没完成的原因，继续只剩外部 Windows blocker：
    - `windows_preflight_latest = RECENT_BILLING_BLOCK`
    - `windows_evidence_verify = TOOLCHAIN BLOCK: cmd.exe cannot resolve LAZBUILD command "lazbuild"`

## 2026-05-17 Fresh Windows Evidence Refresh After Runner-Parity Commit

- 在 `qemu retry rehearsal` parity batch 推送后，我继续做了 fresh completion audit：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
  - 第一轮直接抓到一个新的真实 residual：
    - `windows_evidence_inputs_not_newer_than_log = FAIL`
    - 原因不是旧历史日志，而是刚提交的 `tests/fafafa.core.simd/buildOrTest.bat` 新于当前 `windows_b07_gate.log`
- 这条 residual 不该留着误导后续 closeout，所以我直接刷新了当前 Windows evidence：
  - `wine cmd /c tests\\fafafa.core.simd\\buildOrTest.bat evidence-win-verify`
  - fresh `windows_b07_gate.log` 现已刷新到 `2026-05-17 20:03:08`
  - 失败边界继续稳定落在：
    - `[BUILD] TOOLCHAIN BLOCK: cmd.exe cannot resolve LAZBUILD command "lazbuild"`
- 随后做了 summary / freeze 复核：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence`
    - `[CLOSEOUT] FAILED: verifier rc=1`
    - 但 `windows_b07_closeout_summary.md` 已刷新到 `2026-05-17 20:03:19`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
    - `windows_evidence_inputs_not_newer_than_log = PASS`
    - `windows_closeout_summary_not_older_than_log = PASS`
    - `windows_closeout_summary = PASS summary matches verifier FAIL`
    - 红项重新收敛为：
      - `windows_preflight_latest = RECENT_BILLING_BLOCK`
      - `windows_evidence_verify = TOOLCHAIN BLOCK: cmd.exe cannot resolve LAZBUILD command "lazbuild"`
- 当前阶段结论：
  - 这次 runner parity commit 没有再留下 repo 内部的 stale evidence 副作用
  - 当前 `freeze-status` 已重新回到“mainline 绿、cross 只红在外部 Windows blocker”的诚实状态

## 2026-05-17 Wine Host-Side Unix Bridge Probe Boundary

- 在把 `freeze-status` 红项重新收敛回纯外部 Windows blocker 之后，我没有立刻停，而是继续审了一层：
  - 既然 `buildOrTest.bat` 已支持 `LAZBUILD=.bat/.cmd` wrapper
  - 当前本机 Wine 环境里，是否还能靠 host-side Unix bridge 把 `cmd.exe -> lazbuild` 再推进一步
- 这轮 probe 的 fresh 事实如下：
  - Linux 侧 `lazbuild` 本身可用：
    - `command -v lazbuild` -> `/opt/fpcupdeluxe/lazarus/lazbuild`
    - `lazbuild --version` -> `4.99`
  - 但 `wine cmd /c where bash` 返回 `File not found`
  - `wine start '/?'` 证实 Wine `start` 确实声明支持 `/wait` 与 `/unix`
  - 但 fresh probe：
    - `wine cmd /c start /wait /unix /bin/touch ...`
    - `wine start /wait /unix /bin/touch ...`
    - `wine start /wait /unix /opt/fpcupdeluxe/lazarus/lazbuild --version`
    - 全部只返回 `rc=159`，且没有产出预期 side effect / 输出
  - `/tmp/wine_start_probe2`、`/tmp/wine_start_probe3` 最终都没有生成
- 当前阶段结论：
  - 在当前本机 Wine 环境里，`where bash` 与 `start /unix` 都没有形成可用的 `LAZBUILD` bridge
  - 因而这条“host-side Unix bridge”不该再作为 closeout 下一步尝试，而应明确记成当前外部环境边界

## 2026-05-17 Bash-Gate Opt-In Fallback Warning Sync

- 在确认 host-side Unix bridge 不成立后，我继续扫 Windows closeout operator surface，发现 `collect_windows_b07_evidence.bat` 还有一条低信号残差：
  - 当显式请求 `SIMD_WIN_EVIDENCE_USE_BASH_GATE=1`
  - 但 `cmd.exe` 实际又不满足 bash gate 前提时
  - 当前日志只会写 `prerequisites are incomplete`
- 这句太弱，容易让后续排查继续误判成“再补一补就能让 Wine 接通 bash gate”。
- 已落地的最小修法：
  - `collect_windows_b07_evidence.bat`
    - fallback warning 改成直接说明：
      - `cmd.exe cannot satisfy the current bash-gate prerequisites`
      - `current local Wine probes did not yield a working host-side Unix bridge`
  - `tests/fafafa.core.simd/docs/windows_b07_closeout_runbook.md`
    - 把 `SIMD_WIN_EVIDENCE_USE_BASH_GATE=1` 收紧成：
      - 仅限 `cmd.exe` 真能解析 `bash` 的环境
      - 当前本机 Wine 不属于这种环境
  - 新增 `rehearse_win_bash_gate_fallback_warning.sh`
    - 并挂进 `gate-summary-selfcheck`
    - 守住 collect script warning + runbook caveat 两处 truth
- 已验证：
  - `git diff --check`
  - `bash tests/fafafa.core.simd/rehearse_win_bash_gate_fallback_warning.sh`
    - `[WIN-BASH-GATE-FALLBACK-REHEARSAL] OK`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh gate-summary-selfcheck`
    - `[GATE-SUMMARY-SELFCHECK] OK`
  - `wine cmd /c 'set SIMD_WIN_EVIDENCE_USE_BASH_GATE=1&& tests\fafafa.core.simd\buildOrTest.bat evidence-win'`
    - 当前 real B07 log 已带出：
      - `SIMD_WIN_EVIDENCE_USE_BASH_GATE=1 requested, but cmd.exe cannot satisfy the current bash-gate prerequisites`
      - `current local Wine probes did not yield a working host-side Unix bridge`
  - 随后已重新跑 canonical evidence / summary：
    - `wine cmd /c tests\\fafafa.core.simd\\buildOrTest.bat evidence-win-verify`
    - `bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence`
    - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
  - fresh `freeze-status` 再次显示：
    - `windows_evidence_inputs_not_newer_than_log = PASS`
    - `windows_closeout_summary_not_older_than_log = PASS`
    - 剩余红项继续只剩：
      - `windows_preflight_latest = RECENT_BILLING_BLOCK`
      - `windows_evidence_verify = TOOLCHAIN BLOCK: cmd.exe cannot resolve LAZBUILD command "lazbuild"`
- 当前阶段结论：
  - `SIMD_WIN_EVIDENCE_USE_BASH_GATE=1` 这条 fallback 现在已经不会再把本机 Wine 描述成“还差一点点就能接通”的候选路径
  - 这批也没有重新引入 repo 内 stale Windows evidence 假红

## 2026-05-17 3cmd Helper Bash-Gate Caveat Sync

- completion audit 继续往下看后，又抓到一个更细的 operator residual：
  - runbook 与 collect warning 已经说明：
    - `SIMD_WIN_EVIDENCE_USE_BASH_GATE=1` 只适用于 `cmd.exe` 真能解析 `bash`` 的环境
    - 当前本机 Wine 不属于这种环境
  - 但 shell 侧 `print_windows_b07_closeout_3cmd.sh` 还没把这句 caveat 带出来
- 这会留下一个小但真实的 split：
  - 看 runbook / batch warning 的人，知道不要再把 Wine 当 bash-gate 逃生口
  - 直接跑 `win-closeout-3cmd` 的人，却还看不到这层边界
- 已落地的最小修法：
  - `tests/fafafa.core.simd/print_windows_b07_closeout_3cmd.sh`
    - 现已明确补上：
      - 若显式试 `SIMD_WIN_EVIDENCE_USE_BASH_GATE=1`
      - 也只限 `cmd.exe` 真能解析 `bash` 的环境
      - 当前本机 Wine 不属于这种环境
  - `tests/fafafa.core.simd/rehearse_windows_closeout_3cmd.sh`
    - blocked/pass 两种 case 现在都强制检查这句 caveat
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - `check_windows_manual_closeout_guard()` 的 `L3CmdRequired` / `LRunbookRequired` 也已把新 caveat 纳入必检

## 2026-05-17 Active Closeout Docs Bash-Gate Caveat Sync

- completion audit 再往 active docs 收一层时，发现：
  - `docs/fafafa.core.simd.closeout.md`
  - `docs/fafafa.core.simd.handoff.md`
  还没有显式带上 “`SIMD_WIN_EVIDENCE_USE_BASH_GATE=1` 也不适用于当前本机 Wine” 这句 caveat。
- 这会留下一个典型的 active-doc split：
  - shell helper / runbook / batch warning 已经同步到了最新边界
  - 但 active closeout / handoff 文档读起来还像只是在讲 “Wine 不能 finalize”
  - 没把 “不要再把 Wine 当 bash-gate 逃生口” 这层也说死
- 已落地的最小修法：
  - `docs/fafafa.core.simd.closeout.md`
    - 在 `evidence-win-verify` 手工路径前提条件里补入：
      - `SIMD_WIN_EVIDENCE_USE_BASH_GATE=1` 仅限 `cmd.exe` 真能解析 `bash` 的环境
      - 当前本机 Wine 不属于这种环境
  - `docs/fafafa.core.simd.handoff.md`
    - 同步补入相同 caveat
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - `LCloseoutDocRequired` / `LHandoffRequired`
    - 以及 `check_windows_closeout_helper_runtime_guard()` 的 helper runtime pattern
    - 全部已把这句 caveat 纳入必检

## 2026-05-17 Checklist/Matrix Closeout Caveat Sync

- completion audit 再继续收 operator-facing closeout docs 时，确认还有一层 residual：
  - `tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md`
  - `tests/fafafa.core.simd/docs/simd_completeness_matrix.md`
  - `docs/fafafa.core.simd.checklist.md`
  - `docs/plans/2026-02-09-simd-windows-closeout-checklist.md`
  仍然在强调“真实 Windows runner / native `LAZBUILD`”，但还没把
  `SIMD_WIN_EVIDENCE_USE_BASH_GATE=1` 的当前适用边界显式写死。
- 这会留下一个更细的文档 split：
  - runbook / helper / handoff 已经说清楚本机 Wine 不是 bash-gate escape hatch
  - checklist / matrix / historical closeout template 却还可能让后续会话把这条 opt-in 误读成可继续尝试的候选路径
- 已落地的最小修法：
  - 上述 4 份文档都已补入相同 caveat：
    - 只有 `cmd.exe` 真能解析 `bash` 的环境，才允许显式试 `SIMD_WIN_EVIDENCE_USE_BASH_GATE=1`
    - 当前本机 Wine 不属于这种环境，不要把它当成 host-side Unix bridge 逃生口
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - `LCloseoutChecklistRequired`
    - `LReleaseChecklistRequired`
    - `LCompletenessMatrixRequired`
    - `LTopChecklistRequired`
    - 已同步把这句 caveat 纳入 `closeout-guard` 必检

## 2026-05-17 Secondary Closeout Plan Caveat Sync

- 在 checklist/matrix 收平后，再往次级 closeout 文档看一层，仍有一个相同类型 residual：
  - `docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md`
  - `docs/plans/2026-03-09-simd-full-platform-completeness.md`
  - `docs/plans/2026-02-09-simd-windows-postrun-fill-template.md`
  仍然只强调 real Windows runner / native Windows `LAZBUILD`，但没把
  `SIMD_WIN_EVIDENCE_USE_BASH_GATE=1` 的当前适用边界写死。
- 已落地的最小修法：
  - 上述 3 份文档都补入相同 caveat：
    - 只有 `cmd.exe` 真能解析 `bash` 的环境，才允许显式试 `SIMD_WIN_EVIDENCE_USE_BASH_GATE=1`
    - 当前本机 Wine 不属于这种环境，不要把它当成 host-side Unix bridge 逃生口
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - `LCloseoutRoadmapRequired`
    - `LCloseoutTemplateRequired`
    - `LFullPlatformPlanRequired`
    - 也已同步把这层 caveat 纳入 `closeout-guard`

## 2026-05-17 Freeze-Status Cross-Gate Redundancy Trim

- 继续往真实 residual 收时，发现当前 `freeze-status` 里有一条更像“冗余噪音”的 shaping 问题：
  - `cross_gate_required_steps` 需要保留，因为它代表 fail-close cross gate 还没补跑
  - 但它在 `evidence-verify=SKIP` 之后，又继续复述 `latest standalone windows_evidence_verify=FAIL/PASS`
  - 这会让同一个 Windows 缺口在 stdout/JSON 里被双层描述
- 已落地的最小修法：
  - `evaluate_simd_freeze_status.py`
    - 保留 `cross_gate_required_steps=FAIL` 语义不变
    - 但把补充文案改成：
      - 若 standalone verifier 失败：直接指向 `windows_evidence_verify` 看当前 root cause
      - 若 standalone verifier 已 PASS：强调仍需 fresh rerun fail-close cross gate
  - `rehearse_freeze_status.sh`
    - 新增断言：mainline fallback case 必须指向 `windows_evidence_verify`
  - active docs：
    - `docs/fafafa.core.simd.checklist.md`
    - `docs/fafafa.core.simd.closeout.md`
    - `docs/fafafa.core.simd.handoff.md`
    - 已同步说明：`cross_gate_required_steps` 现在只表示 gate enforcement 缺口，不再重复承担 root-cause 说明

## 2026-05-17 Ready-Green But GH Preflight-Fail Was Still A Potential Contradiction

- 继续从 `freeze-status` 的真实判定链往下审时，又确认了一个更硬的潜在矛盾：
  - `windows_preflight_latest` 当前是 `required=False`
  - 因此未来如果手工 Windows 证据链已经 fresh PASS，且 fail-close cross gate 也已 PASS，`ready=True` 依然可能成立
  - 但旧逻辑仍会把 latest `RECENT_BILLING_BLOCK` 直接显示成 `windows_preflight_latest: FAIL`
- 这会留下一个不应该出现的组合：
  - 总状态已经 `ready=True`
  - stdout / JSON 里却还残留一个 `FAIL`
  - 而它其实只是在说 “GH 路径当前不可用”，不再是 current readiness blocker
- 已落地的最小修法：
  - `evaluate_simd_freeze_status.py`
    - 若 cross-platform `freeze_ready=True`
    - 且 `windows_preflight_latest` 仍为 `FAIL`
    - 则把该项降格成 `SKIP`，并明确写成：
      - GH preflight path remains blocked/noisy
      - but required Windows evidence + fail-close cross gate are already green
      - so this is not a current readiness signal
  - `rehearse_freeze_status.sh`
    - 新增 `case_ready_preflight_blocked`
    - 证明：即使 latest preflight 是 fresh `RECENT_BILLING_BLOCK`，只要 required Windows checks 已全绿，`freeze-status` 也必须输出 `ready=True` 且把 `windows_preflight_latest` 降格成 `SKIP`
  - active docs：
    - `docs/fafafa.core.simd.closeout.md`
    - `docs/fafafa.core.simd.checklist.md`
    - 已同步这条新的 readiness discipline

## 2026-05-17 RISCVV Wide Select Asm-Only Wrapper Cleanup

- 继续按“小批次只收一个 residual”的方式切回 non-x86 源码层，先审 `RISCVV` 的 3 个 `asm-only wrapper`：
  - `SelectF32x8`
  - `SelectF64x4`
  - `SelectI32x4`
- fresh 证据先钉住了它们当前的真实形状：
  - `src/fafafa.core.simd.riscvv.register.inc` 只在 `{$IFDEF RISCVV_ASSEMBLY}` 下给这 3 个 slot 绑 `@RISCVVSelect*`
  - no-asm 路径原本已经复用 `FillBaseDispatchTable` 的 base scalar slot
  - asm build 下对应函数体不是 RVV asm leaf，也不是 helper-owned contract，只是和 scalar 完全同语义的本地 loop
  - 这 3 个 slot 也不承担 `scShuffle` 的最小代表性 contract；`RISCVV` 的 shuffle capability 仍由 `SelectF32x4 / InsertF32x4 / ExtractF32x4` 这组 128-bit representative shuffle leaf 支撑
- 因而这批被判定为“真可减冗余”而不是“有意保留 backend-owned ownership”：
  - 删掉了 `src/fafafa.core.simd.riscvv.pas` 里的 `RISCVVSelectF32x8/F64x4/I32x4` dead wrapper
  - 删掉了 `src/fafafa.core.simd.riscvv.facade.inc` 里的同名 no-asm companion wrapper
  - `src/fafafa.core.simd.riscvv.register.inc` 不再在 asm 分支里显式绑定这 3 个 slot，改为继续复用 base scalar
  - `tests/fafafa.core.simd/check_nonx86_register_truthfulness.py` 去掉了这 3 个 `asm-only wrapper` allowlist 豁免
  - `tests/fafafa.core.simd/fafafa.core.simd.dispatchapi.testcase.pas` 的真相断言已改成：
    - 这 3 个 wrapper 应该被视为 dead wrapper removed
    - register source 应继续复用 base scalar
    - runtime dispatch slot 也应复用 base scalar
- fresh 验证结果：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_nonx86_register_truthfulness.py --backend riscvv --summary-line --strict`
    - `backend=riscvv assignments=470 asm_exact=330 asm_suffix_only=117 wrapper_only=23 ...`
    - `asm-only wrapper ok: 0`
  - `python3 tests/fafafa.core.simd/check_nonx86_helper_semantics.py --summary-line`
    - `NONX86_HELPER_SEMANTICS_SUMMARY checks=643 status=ok`
  - `python3 tests/fafafa.core.simd/check_nonx86_key_slot_audit.py --backend riscvv`
    - `SelectF32x8/SelectF64x4/SelectI32x4` 已切到 `reuse_base_scalar`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
    - `NONX86_IMPL_AUDIT_SUMMARY ... status=ok`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
    - 串行重跑后 `[BUILD] OK / [TEST] OK / [LEAK] OK`
- 过程中还确认了一个验证纪律问题：
  - 不要并行跑两个会编译同一个 `fafafa.core.simd.test.lpi` 的 release 命令
  - 并行时会争抢同一套 build 输出目录，造成假失败；这次单独 `DispatchAPI` 的首次 link fail 就是这种竞争，不是源码回归

## 2026-05-17 BuildOrTest Output-Root Lock For Concurrent False-Fail

- 接着上一批 residual，没有再扩散到新的 family，而是直接收 `tests/fafafa.core.simd/BuildOrTest.sh` 的并发假失败。
- fresh 复现先确认了问题真实存在：
  - 并发运行
    - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
    - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - 结果：
    - `test --suite=TTestCase_DispatchAPI` 首次直接 `[BUILD] FAILED rc=2`
    - 同时 `impl-audit-nonx86` 仍能继续完成
  - 结合 `nonx86_impl_audit_output_root()` 固定返回 `tests/fafafa.core.simd`，可确认这不是源码回归，而是两个 release 动作共享同一套 `bin2/lib2/logs` 产物导致的竞争。
- 已落地的最小修法：
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - 新增 `current_output_root_lock_file()` / `output_root_lock_is_held_here()` / `with_output_root_lock()`
    - 锁文件固定为 `${OUTPUT_ROOT}/logs/.simd-output-root.lock`
    - 新增 `action_requires_output_root_lock()`，把会构建/运行同一 `OUTPUT_ROOT` 热路径的 action 纳入顶层串行化
    - 把最外层 `case "${ACTION}" in ...` 收进 `dispatch_action()`，由顶层统一决定是否先拿锁
    - 通过 `SIMD_OUTPUT_ROOT_LOCK_HELD_FILE` / `SIMD_OUTPUT_ROOT_LOCK_HELD_ROOT` 传播“当前已持有哪一个 output-root 锁”，避免 `impl-audit-nonx86 -> BuildOrTest.sh test` 这类递归调用发生二次加锁死锁
    - 若环境缺少 `flock`，脚本会显式输出 `WARN` 后维持旧行为，不会把 Windows/MSYS 直接打死
- fresh 验证已完成：
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - `git diff --check`
  - 再次并发运行同一组命令：
    - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI`
    - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh impl-audit-nonx86`
  - fresh 结果：
    - 第一条命令先输出：
      - `[LOCK] Waiting for output-root lock ...`
      - `[LOCK] Acquired output-root lock ...`
      - `[BUILD] OK / [TEST] OK / [LEAK] OK`
      - `[LOCK] Released output-root lock ...`
    - 第二条命令起初只输出：
      - `[LOCK] Waiting for output-root lock ...`
      - 随后在前者释放后才继续执行并最终
      - `NONX86_IMPL_AUDIT_SUMMARY ... status=ok`
      - `[LOCK] Released output-root lock ...`
- 当前阶段结论：
  - 之前那类“共享 `OUTPUT_ROOT` 时的假红”现在已从热路径收口为显式串行化
  - 这批修的是 runner 健壮性，不是 SIMD 实现语义本身；non-x86 checker 与 targeted release suites 仍保持绿态

## 2026-05-17 Freeze-Status Isolation Guard Truth Resync

- 接着上一批 runner 健壮性收口，我没有重新发散扫源码，而是直接追了 fresh `Release check` 里新冒出来的一条真红：
  - `[CHECK] Freeze-status runner missing isolation pattern: LGateSummaryFile="${SIMD_FREEZE_GATE_SUMMARY_FILE:-${SIMD_GATE_SUMMARY_FILE:-${GATE_SUMMARY_LOG}}}"`
- 复核 `run_freeze_status()` 与 scratch 历史结论后，已确认这不是 wrapper regression，而是 `check_freeze_status_output_isolation()` 自己落后于当前真实合同：
  - `run_freeze_status()` 现在只在显式提供 `SIMD_FREEZE_GATE_SUMMARY_FILE` / `SIMD_GATE_SUMMARY_FILE` 时才传 override
  - 这正是 `Freeze Status Wrapper Was Short-Circuiting Gate Fallback Discovery` 那批修复后的预期行为
  - 旧的静态 guard 却仍然要求“默认强制导出 `SIMD_FREEZE_GATE_SUMMARY_FILE=<gate_summary.md>`”，于是把当前正确实现误报成缺 pattern
- 已落地的最小修法：
  - `tests/fafafa.core.simd/BuildOrTest.sh`
    - `check_freeze_status_output_isolation()` 的 `LRunnerRequired` 已改成匹配当前真实 wrapper 合同：
      - `LGateSummaryOverride="${SIMD_FREEZE_GATE_SUMMARY_FILE:-${SIMD_GATE_SUMMARY_FILE:-}}"`
      - `if [[ -n "${LGateSummaryOverride}" ]]; then`
      - `LGateSummaryFile="${LGateSummaryOverride}"`
      - 仅在 override 分支里导出 `SIMD_FREEZE_GATE_SUMMARY_FILE="${LGateSummaryFile}"`
      - 并要求普通分支保留直接 `python3 ... --json-file ...` 调用
    - `LRunnerForbidden` 新增旧的 unconditional fallback 模式：
      - `LGateSummaryFile="${SIMD_FREEZE_GATE_SUMMARY_FILE:-${SIMD_GATE_SUMMARY_FILE:-${GATE_SUMMARY_LOG}}}"`
- fresh 验证已完成：
  - `bash -n tests/fafafa.core.simd/BuildOrTest.sh`
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
  - fresh 结果：
    - 之前的 `Freeze-status runner missing isolation pattern` 已消失
    - `check` 中现在明确重新出现：
      - `[CHECK] OK (freeze-status output isolation present)`
    - 整条 `Release check` 最终重新通过，同时继续保留：
      - `METADATA_QUERY_SCOPE ... OK`
      - `DATAPLANE_CONSUMER_SCOPE ... OK`
      - `DIRECT_DISPATCH_SCOPE ... OK`
      - `NONX86_REGISTER_TRUTHFULNESS_SUMMARY ... strict=1`
- 当前阶段结论：
  - 这批修的是默认门禁 guard 真相漂移，不是 `freeze-status` 生产逻辑本身
  - `run_freeze_status()` 现在继续保留“无 override 时允许 Python fallback discovery”的正确行为，而 `check` 不会再把这条正确合同误报成缺陷

## 2026-05-17 Experimental Intrinsics Dual-Mode Check And SVE2 Reject-Boundary Repair

- 继续按“一个 bounded residual 一次收口”的方式，把注意力放到 `intrinsics experimental` fail-close lane。
- fresh current-state audit 先确认：
  - `sse2/avx/sse3/sse41/sse42/avx512/fma3` 已有 experimental 宏 guard + non-x86 x86-only runtime fail-close 文案
  - `neon/rvv/sve/sve2/lasx` 已有 qualification runtime fail-close 文案
  - `check_intrinsics_experimental_status.py` 也已静态覆盖这些 token
- 但 runner 层还有两个 residual：
  - `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check` 默认只跑 `experimental=0`，不会自动带上 `experimental=1` 的 runtime reject smoke
  - `check_sve2_runtime_fail_close()` 还接受旧的宽松 token：`sve2|sve`
- 先把 runner 收紧后，fresh 立刻抓到真实问题：
  - `SVE2` runtime reject smoke 失败
  - 实际异常来自 `fafafa.core.simd.intrinsics.sve`
  - 说明 `sve2` 的 reject 边界被 `sve` initialization 抢先吞掉
- 已落地的代码/文档收口：
  - `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh`
    - 新增 `run_check_current_mode()` / `run_check_all_modes()`
    - `check` 现在默认先跑 `experimental=0` 再跑 `experimental=1`
    - 显式 `FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1 bash ... check` 仍只跑当前模式
    - `SVE2` runtime reject token 已收紧为只接受 `sve2`
  - `src/fafafa.core.simd.intrinsics.sve.base.pas`
    - 新增 shared type unit，只承载 `TSVEVector/TSVEPredicate`
  - `src/fafafa.core.simd.intrinsics.sve.pas`
    - 改为复用 `sve.base`
  - `src/fafafa.core.simd.intrinsics.sve2.pas`
    - 不再 `uses sve`，只复用 `sve.base`
  - `docs/SIMD_INTRINSICS_DISPOSITION.md`
    - 新增 `fafafa.core.simd.intrinsics.sve.base` 行
    - 同步 `sve2` 的共享类型说明
  - `tests/fafafa.core.simd/check_sse2_structure.py`
    - `EXPECTED_INTRINSICS_DISPOSITION` 已补齐 `fafafa.core.simd.intrinsics.sve.base`
- fresh 验证已完成：
  - `bash -n tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh`
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_intrinsics_experimental_status.py --summary-line`
  - `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check`
  - `FAFAFA_SIMD_EXPERIMENTAL_INTRINSICS=1 bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check`
  - `python3 tests/fafafa.core.simd/check_sse2_structure.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `intrinsics.experimental` 默认 `check` 现在会自动跑到 `experimental=1` runtime reject smoke
  - `SVE2` runtime reject smoke 已回到 `[CHECK] OK`
  - `INTRINSICS_EXPERIMENTAL_SUMMARY ... missing_* = 0`
  - `SSE2_STRUCTURE_SUMMARY ... intrinsics_disposition_rows=21 ... repo_intrinsics_units_count=21 ... failure_count=0 status=ok`
  - 主 `Release check` 返回 `0`
- 当前阶段结论：
  - 这批不仅补强了 experimental lane 的验证覆盖，还修掉了一个真实单元边界错误
  - `SVE2` 现在会为自己的 qualification contract fail-close，不再被 `sve` initialization 抢先吞边界

## 2026-05-17 Experimental X86 Intrinsics Representative Behavior Tests

- 继续按“小批次只补一个 residual”推进，这次不改实现层，而是补 `intrinsics experimental` x86 行为覆盖缺口。
- fresh 审查先确认当前测试面：
  - `aes/sha`：已有 default reject + placeholder semantics
  - `sse3/sse41`：已有部分行为断言
  - `sse42/avx/avx512/fma3`：基本只有 compile smoke，没有把当前 placeholder/算子合同守成 suite
- 已落地的测试补强集中在：
  - `tests/fafafa.core.simd.intrinsics.experimental/fafafa.core.simd.intrinsics.experimental.testcase.pas`
    - `Test_SSE42_StringCompareCmpGtAndCrcPlaceholderSemantics`
    - `Test_AVX_PlaceholderCopyAndMovemaskSemantics`
    - `Test_AVX512_AddAndMaskPlaceholderSemantics`
    - `Test_FMA3_FusedAndAlternatingPlaceholderSemantics`
  - 同步把对应 units 接进 experimental x86 test `uses`：
    - `sse42`
    - `avx`
    - `avx512`
    - `fma3`
- 这批测试锁住的当前合同包括：
  - `sse42`
    - `cmpestrm/cmpistrm` 返回全零 mask
    - `cmpestri/cmpistri` 返回 `16`
    - `cmpestrc/o/s`、`cmpistrc/o/s` 返回 `False`
    - `cmpestrz/cmpistrz` 返回 `True`
    - `cmpgt_epi64` lane compare
    - CRC32 placeholder 多项式的固定结果
  - `avx`
    - `cmp/blend/permute/unpack` 当前 placeholder 继续 `copy-a`
    - `extractf128/insertf128` lane 读写
    - `movemask_ps/pd`
    - `testz/testc/testnzc` 当前固定布尔结果
  - `avx512`
    - `add_ps512`
    - `mask_add_ps512`
    - `maskz_add_ps512`
  - `fma3`
    - `fmadd_ps`
    - `fmadd_ss` 保留高 lanes
    - `fmaddsub_ps256` 奇偶 lane 交替
    - `fmsubadd_pd256` 奇偶 lane 交替
- fresh 验证已完成：
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_intrinsics_experimental_status.py --summary-line`
  - `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh test-all`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh experimental-intrinsics-tests`
- fresh 结果：
  - default mode `experimental=0`：
    - build + backend smoke + default suite 全绿
  - experimental mode `experimental=1`：
    - x86 backend smoke 全绿
    - `NEON/RVV/SVE/SVE2/LASX` runtime reject smoke 全绿
    - experimental test suite 全绿，`[LEAK] OK`
  - 主 runner 的 `experimental-intrinsics-tests` 集成入口也返回 `0`
- 当前阶段结论：
  - 这批把 `sse42/avx/avx512/fma3` 从“只有 compile smoke”补成了有代表性 lane/placeholder 合同测试
  - 后续再动这些 experimental units 时，不会再因为没有行为护栏而静默漂移

## 2026-05-17 AES/SHA Experimental Contract Truth-Sync

- 继续按“小批次只收一个误判点”推进，这次专门核 `aes/sha` 是否缺 `x86-only runtime fail-close`。
- fresh current-state audit 先确认：
  - `src/fafafa.core.simd.intrinsics.aes/sha.pas` 当前都只有 experimental opt-in guard，没有 `only qualified on x86/x86_64`
  - `docs/plans/2026-05-09-simd-family-matrix.md`
  - `docs/plans/2026-05-09-simd-experimental-hold-future-trigger-plan.md`
  - `docs/SIMD_INTRINSICS_DISPOSITION.md`
    都把 `AES/SHA` 写成 hold family，且只锁 `default-reject + placeholder semantics`
  - 对照组 `sse3/sse41/sse42/avx/avx512/fma3` 才是明确的 `x86-only runtime fail-close`
- 结论不是“实现漏了 fail-close”，而是：
  - `AES/SHA` 当前合同本来就和上面那批不同
  - 它们目前有意保持 `cross-host opt-in` placeholder semantics，不把 non-x86 runtime reject 写成现合同
  - 真正的问题是 active truth source 的措辞不够显式，容易在后续审查里被误判成缺口
- 已落地的真相同步：
  - `src/fafafa.core.simd.intrinsics.aes.pas`
  - `src/fafafa.core.simd.intrinsics.sha.pas`
    - 注释明确写出 `placeholder semantics remain opt-in across hosts`
    - 明确说明当前不追加 `x86-only runtime fail-close`
  - `tests/fafafa.core.simd/check_intrinsics_experimental_status.py`
    - 新增 `DEFAULT_OPT_IN_ACROSS_HOSTS_TOKENS`
    - 把 `AES/SHA` 的 `cross-host opt-in` 合同也纳入静态 checker
  - `docs/SIMD_INTRINSICS_DISPOSITION.md`
    - 把 `AES/SHA` role 改成 `x86 ...-themed placeholder leaf`
    - 明确当前合同不是 `x86-only runtime fail-close`
  - `docs/plans/2026-05-09-simd-family-matrix.md`
  - `docs/plans/2026-05-09-simd-experimental-hold-future-trigger-plan.md`
    - 同步写死 `cross-host opt-in` 基线，避免 future reopen 讨论时又把它误当成漏项
- fresh 验证已完成：
  - `git diff --check`
  - `python3 -m py_compile tests/fafafa.core.simd/check_intrinsics_experimental_status.py`
  - `python3 tests/fafafa.core.simd/check_intrinsics_experimental_status.py --summary-line`
  - `python3 tests/fafafa.core.simd/check_sse2_structure.py --summary-line`
  - `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `missing_cross_host_opt_in=0`
  - `INTRINSICS_EXPERIMENTAL_SUMMARY ... missing_* = 0`
  - `SSE2_STRUCTURE_SUMMARY ... failure_count=0 status=ok`
  - `intrinsics.experimental` 双模态 `check` 全绿
  - 主 `Release check` 全绿
- 当前阶段结论：
  - 这批修掉的是 `AES/SHA` experimental 合同的真相歧义，不是 runtime 行为缺陷
  - 之后再审 `AES/SHA` 时，checker 和 active docs 都会明确告诉我们：当前合同是 `cross-host opt-in placeholder`，不是“漏了 x86 fail-close”

## 2026-05-17 Active Experimental Intrinsics Comment-Encoding Hygiene

- 在继续找下一刀真实 residual 时，fresh 扫描发现当前 active experimental intrinsics 里还有一类很实际的卫生问题：
  - 多个文件的注释区直接包含 `U+FFFD`
  - 不是终端显示问题，而是源码文本里真的存在 replacement character
- 为了避免又扩成“大面积全文清洗”，这批只切 6 个当前 active audit lane 会直接读到的 experimental leaf：
  - `src/fafafa.core.simd.intrinsics.avx.pas`
  - `src/fafafa.core.simd.intrinsics.neon.pas`
  - `src/fafafa.core.simd.intrinsics.rvv.pas`
  - `src/fafafa.core.simd.intrinsics.sve.pas`
  - `src/fafafa.core.simd.intrinsics.sve2.pas`
  - `src/fafafa.core.simd.intrinsics.lasx.pas`
- 这些文件的 `U+FFFD` 位点都落在注释区，不涉及可执行语义；因此正确修法是：
  - 把损坏的简介/占位说明/平台 stub 注释收成稳定 ASCII 注释
  - 不改函数签名
  - 不改 runtime guard
  - 不改 placeholder 语义
- 已落地的收口：
  - 6 个文件里的 `U+FFFD` 注释都已清零
  - `AVX/NEON/RVV/SVE/SVE2/LASX` 的文件头现在都统一成可读的 experimental placeholder 简介
  - `RVV/LASX` 的 lane-count inline comments、`SVE/SVE2` 的 placeholder implementation 注释、`NEON`/平台 stub 注释也已一并修正
- fresh 验证已完成：
  - `python3` 逐文件计数：6 个目标文件 `U+FFFD=0`
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_intrinsics_comment_swallow.py --summary-line`
  - `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `fafafa.core.simd.intrinsics.avx/neon/rvv/sve/sve2/lasx.pas = 0`
  - `INTR_HYGIENE_SUMMARY status=PASS hits=0`
  - `intrinsics.experimental` 双模态 `check` 全绿
  - 主 `Release check` 全绿
- 当前阶段结论：
  - 这批修掉的是 active experimental intrinsics 注释文本损坏，不是实现逻辑缺陷
  - 但它确实能直接提升后续审查、grep、diff review 的可读性，避免再被乱码污染判断

## 2026-05-17 X86 Experimental Intrinsics Comment-Encoding Hygiene Follow-up

- 延续上一批 active experimental intrinsics 注释卫生清理后，fresh 扫描继续在 x86 侧发现同类真实残点：
  - `src/fafafa.core.simd.intrinsics.avx2.pas`
  - `src/fafafa.core.simd.intrinsics.avx512.pas`
  - `src/fafafa.core.simd.intrinsics.fma3.pas`
  - `src/fafafa.core.simd.intrinsics.sse2.pas`
  - `src/fafafa.core.simd.intrinsics.sse3.pas`
  - `src/fafafa.core.simd.intrinsics.sse41.pas`
  - `src/fafafa.core.simd.intrinsics.sse42.pas`
- 这些位点同样全部落在简介、placeholder 说明、shift/string/CRC/thread-sync 一类注释区，不涉及函数签名、runtime guard 或 placeholder 行为本身。
- 本批的收口动作保持严格 bounded：
  - 只把损坏的 `U+FFFD` 注释替换成稳定 ASCII 注释
  - 不改实现体
  - 不改测试合同
  - 不改 experimental isolation / fail-close 语义
- 过程中先扫出 `7` 个目标文件里只剩 `sse2` 还有最后 `1` 个 `U+FFFD`；随后把 `simd_slli_epi32` 上方的残余注释也清零。
- fresh 验证已完成：
  - `python3` 逐文件计数：`avx2/avx512/fma3/sse2/sse3/sse41/sse42 = 0`
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_intrinsics_comment_swallow.py --summary-line`
  - `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `INTR_HYGIENE_SUMMARY status=PASS hits=0`
  - `intrinsics.experimental` 双模态 `check` 全绿
  - 主 `Release check` 全绿
- 当前阶段结论：
  - 这批继续修掉的是 x86 experimental intrinsics 的源码文本损坏，不是行为缺陷
  - 到这里这 7 个 x86 目标文件的 `U+FFFD` 已全部归零，active 审查面不再被乱码残点打断

## 2026-05-17 CPUInfo i386 Feature-Detector Delegation Sync

- 在继续做小批次审查时，fresh 扫描没有先去碰 `intrinsics.x86.sse2` 那个大坑，而是改挑更值当的 active `cpuinfo` 残点。
- 在 `src/fafafa.core.simd.cpuinfo.x86.i386.pas` 里抓到一个真实逻辑风险：
  - 坏注释把 `if not XCR0HasAVX512(xcr0) then` 吞进了 `//` 行内
  - 后面的 `begin ... end` 因而变成无条件执行
  - 结果就是 `AVX-512` 的 XCR0 门槛屏蔽在 `i386` 手写实现里发生了 source drift
- 对照 `src/fafafa.core.simd.cpuinfo.x86.base.pas` 与 `src/fafafa.core.simd.cpuinfo.x86.x86_64.pas` 后确认：
  - `x86.base` 已经有正确共享的 `X86FeaturesFromCPUID(...)` 门槛逻辑
  - `x86_64` 也已经委托到这条 helper
  - 真正的问题不是“少一个 if”，而是 `i386` 还保留一份手写重复版，既冗余又被坏注释带偏
- 已落地的收口：
  - `src/fafafa.core.simd.cpuinfo.x86.i386.pas`
    - `DetectX86Features` 改为和 `x86_64` 同样采集 leaf 数据后统一委托 `X86FeaturesFromCPUID(...)`
    - 顺手清掉会误导审查的损坏注释
  - `tests/fafafa.core.simd.cpuinfo.x86/check_x86_feature_detector_sync.py`
    - 新增静态 checker，锁定 `i386/x86_64` 两个平台实现都必须委托共享 helper
    - 同时要求 `DetectX86Features` 不再保留手写 `Result.Has...` feature assembly
  - `tests/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh`
  - `tests/fafafa.core.simd.cpuinfo.x86/buildOrTest.bat`
    - `check` 动作都已接入这个 checker
- fresh 验证已完成：
  - `python3 -m py_compile tests/fafafa.core.simd.cpuinfo.x86/check_x86_feature_detector_sync.py`
  - `python3 tests/fafafa.core.simd.cpuinfo.x86/check_x86_feature_detector_sync.py --summary-line`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh test`
- fresh 结果：
  - `CPUINFO_X86_SYNC_SUMMARY files=2 delegate_ok=2 manual_assigns=0 issues=0`
  - `cpuinfo.x86` release `check` 通过
  - `cpuinfo.x86` release `test` 通过，`[LEAK] OK`
- 当前阶段结论：
  - 这批同时修掉了一个真实 source drift / potential behavior bug，以及一处 `i386` vs `x86_64` 的 feature assembly 冗余分叉
  - 后续即使当前主机只跑 `x86_64`，`cpuinfo.x86` 的 `check` 也会静态守住 `i386` 不再偷偷偏离共享 helper

## 2026-05-17 Active API/CPUInfo Comment-Encoding Hygiene

- 在 `cpuinfo.i386` source drift 那批收口后，继续按“小批次只切 active 文件”往前推，没有去开 `intrinsics.x86.sse2` 的大坑。
- fresh 扫描锁定当前最值当的 active 文本卫生残点：
  - `src/fafafa.core.simd.api.pas`
  - `src/fafafa.core.simd.cpuinfo.lazy.pas`
  - `src/fafafa.core.simd.cpuinfo.x86.base.pas`
  - `src/fafafa.core.simd.cpuinfo.x86.x86_64.pas`
- 这些文件里剩余的 `U+FFFD` 都落在注释区：
  - facade/API 简介
  - lazy cpuinfo 的 singleton / arch detect / SSE/AVX/AVX512 注释
  - x86 shared helper 说明
  - x86_64 facade API 注释
- 本批保持严格 bounded：
  - 只把损坏注释换成稳定 ASCII 注释
  - 不改函数签名
  - 不改 runtime 逻辑
  - 不额外扩成新的编码检查工具链
- fresh 验证已完成：
  - `python3` 逐文件计数：4 个目标文件 `U+FFFD=0`
  - `git diff --check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `cpuinfo` release `check` 通过
  - `cpuinfo.x86` release `check` 通过
  - 主 `simd` release `check` 通过
- 当前阶段结论：
  - 这批继续修掉的是 active `api/cpuinfo` 线上的源码文本损坏，不是行为缺陷
  - 到这里这 4 个 active 文件的 `U+FFFD` 已全部归零，后续审查 `facade/cpuinfo` 时不再被损坏注释干扰

## 2026-05-17 Intrinsics Umbrella Declaration Recovery

- 继续往剩余 residual 收口时，没有先去开 `mmx` 或 `intrinsics.x86.sse2` 的大坑，而是先锁定 `src/fafafa.core.simd.intrinsics.pas` 这个更小但更危险的 active umbrella 文件。
- fresh 审查直接抓到一处比普通乱码更实在的边界问题：
  - `simd_add_ps` 的注释后面把 `simd_add_pd` 和 `simd_mul_ps` 两个 interface 声明吞进了同一行 comment
  - 结果是 implementation 里有函数体，但 interface 没有正确导出完整 API
  - 现有 `comment swallow` checker 之所以没报，是因为它此前根本没覆盖 `intrinsics.pas`
- 本批的正确收口不是“只改注释文本”，而是同时修三件事：
  - `src/fafafa.core.simd.intrinsics.pas`
    - 把被吞掉的 `simd_add_pd` / `simd_mul_ps` interface 声明恢复成独立函数声明
    - 顺手清掉这个文件剩余的 `U+FFFD` 注释残点
  - `tests/fafafa.core.simd/check_intrinsics_comment_swallow.py`
    - 把 `src/fafafa.core.simd.intrinsics.pas` 纳入 hygiene checker 覆盖
  - `tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh`
    - 新增 `intrinsics umbrella smoke`
    - 用真实 compile smoke 直接引用 `simd_add_ps/simd_add_pd/simd_mul_ps/simd_mul_pd`，证明 interface 现在可见
- fresh 验证已完成：
  - `python3` 逐文件计数：`src/fafafa.core.simd.intrinsics.pas = 0`
  - `git diff --check`
  - `python3 tests/fafafa.core.simd/check_intrinsics_comment_swallow.py --summary-line`
  - `bash tests/fafafa.core.simd.intrinsics.experimental/BuildOrTest.sh check`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh check`
- fresh 结果：
  - `INTR_HYGIENE_SUMMARY status=PASS hits=0`
  - `intrinsics umbrella smoke` 在 default / experimental 双模态都编译通过
  - `intrinsics.experimental` 双模态 `check` 全绿
  - 主 `simd` release `check` 全绿
- 当前阶段结论：
  - 这批修掉的是 umbrella API 的真实 interface 漂移，不只是注释可读性问题
  - 之后如果再出现同类“注释吞掉 function declaration”，现有 hygiene checker 和 umbrella smoke 都会直接 fail-close 抓出来
