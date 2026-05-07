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
