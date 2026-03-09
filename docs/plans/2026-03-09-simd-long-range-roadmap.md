# SIMD Long-Range Roadmap Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把 `fafafa.core.simd` 从“已完成一轮 closeout + 局部 QEMU/RISCVV 收敛”推进到“长期可持续开发、证据链稳定、stable/experimental 边界清晰、可持续发布”的状态。

**Architecture:** 这条路线不再按零散 bug 推进，而是按“稳定面封板 → experimental 边界独立 → 专项后端硬化 → freeze/CI 升级 → 发布收尾”的顺序推进。核心原则是：stable/public surface 与 experimental backend 分开验收、分开声明、分开证据链，避免为了证明 experimental 路径而污染主线门禁。

**Tech Stack:** FreePascal/Lazarus、FPCUnit、Bash/Batch、GitHub Actions、Docker/QEMU multiarch、Windows real-host evidence、file-based planning (`task_plan.md` / `findings.md` / `progress.md`).

---

## 为什么现在必须切换到路线图开发

当前项目已经不适合继续用“看到一个错就补一个点”的方式推进，原因很明确：

- SIMD 模块已经同时包含 stable façade、dispatch/cpuinfo、x86/NEON/RISCVV backend、QEMU evidence、Windows real-host evidence
- 不同能力面的成熟度不一致，尤其是 `sbRISCVV` 与 AArch64 experimental asm
- `freeze-status`、QEMU evidence、Windows evidence、RC checklist、closeout docs 已经形成一个状态机，而不是单个脚本
- 继续碎片修复，只会让“主线是否稳定”和“实验路径是否进展”这两件事彼此污染

所以接下来必须坚持：

1. 一次只推进一个阶段
2. 每个阶段都写清楚退出标准
3. stable 路径与 experimental 路径分开验收
4. 所有结论都回填到文档和 planning files

---

## 当前基线（2026-03-09）

### 已经完成的基线

- Linux 主线 `gate-strict` 通过
- Windows real-host evidence 已验证并可恢复到本地，`freeze-status` 当前为 `ready=True`
- fresh `qemu-arch-matrix-evidence` 已 PASS：
  - `tests/fafafa.core.simd/logs/qemu-multiarch-20260309-092825-2802652/summary.md`
- fresh `qemu-cpuinfo-nonx86-full-evidence` 已 PASS：
  - `tests/fafafa.core.simd/logs/qemu-multiarch-20260309-085950-2782967/summary.md`
- fresh `riscvv-opcode-lane` 已实现：
  - compile-only PASS
  - stable smoke PASS（`TTestCase_Global` + `TTestCase_DispatchAPI`）
  - bench 默认 SKIP（显式 opt-in）
  - 证据：`tests/fafafa.core.simd/logs/rvv-opcode-lane-20260309-091241/summary.md`

### 当前真实口径

- **Stable/public surface**：Linux + x86/arm/riscv 的 QEMU 证据链已闭环
- **Windows closeout**：仍然是 freeze gate 的真实必需证据
- **`sbRISCVV`**：仍然是 experimental backend，但已经从“口径混乱”收敛为“有 dedicated evidence lane 的 experimental backend”
- **AArch64 experimental asm**：仍然没有形成发布级/可依赖的 experimental evidence，目前只适合作为后续专项阶段

---

## 总体阶段图

### Phase 0：锁住现有成果（已完成）

**目标**
- 不再丢失当前 stable/public surface 的闭环成果

**退出标准**
- `gate-strict` PASS
- `freeze-status` = `ready=True`
- fresh `qemu-arch-matrix-evidence` PASS
- fresh `qemu-cpuinfo-nonx86-full-evidence` PASS
- fresh `riscvv-opcode-lane` compile + stable smoke PASS

**证据命令**
- `bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict`
- `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
- `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-arch-matrix-evidence`
- `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-cpuinfo-nonx86-full-evidence`
- `bash tests/fafafa.core.simd/BuildOrTest.sh riscvv-opcode-lane`

---

### Phase 1：升级 freeze / CI 的完成定义（下一阶段，最高优先级）

**目标**
- 让“full-platform complete”变成一个有状态机、有 required 项、有 fresh evidence 入口的正式概念，而不是口头描述

**本阶段要做什么**
- 给 `freeze-status` 增加 full-platform 视角（新 mode 或新 evaluator）
- required 集合纳入：
  - latest `qemu-arch-matrix-evidence`
  - latest `qemu-cpuinfo-nonx86-full-evidence`
  - latest `riscvv-opcode-lane`（至少 compile + stable smoke）
- 在 handoff / closeout / matrix / RC checklist 中统一口径
- 明确 `bench` 对 RVV lane 是 opt-in，不是默认 required

**不要做什么**
- 不要在本阶段继续扩张 NEON experimental asm
- 不要把所有 experimental intrinsics 都塞进 release freeze

**退出标准**
- 有一个明确的“full-platform ready”判断入口
- 文档里 stable/experimental 的 required 项说法一致
- 本地/CI 跑出来的状态能直接回答“是不是 full-platform complete”

**关键文件**
- `tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
- `docs/fafafa.core.simd.handoff.md`
- `docs/fafafa.core.simd.closeout.md`
- `tests/fafafa.core.simd/docs/simd_completeness_matrix.md`
- `tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md`

**验收命令**
- `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
- `python3 tests/fafafa.core.simd/evaluate_simd_freeze_status.py --mode full-platform`（建议新增）

---

### Phase 2：AArch64 / NEON experimental lane 专项硬化

**目标**
- 把现在 `qemu-nonx86-experimental-asm` 里 arm64 暴露的 NEON/FPC 方言问题从“噪声”变成一个独立可维护的专项 lane

**本阶段要做什么**
- 梳理 `src/fafafa.core.simd.neon.pas` 里当前与 FPC 3.3.1 / GAS 不兼容的 asm 片段
- 分离“stable 路径不依赖”和“experimental lane 专属”代码
- 建立 dedicated arm64 experimental lane（不要和 stable QEMU lane 混在一起）
- 决定是：
  - 真修 AArch64 asm 方言
  - 还是暂时把不兼容实现换成更明确的 scalar fallback / narrower fast path

**不要做什么**
- 不要在 stable arch-matrix 里强开 experimental arm64 asm
- 不要把 dedicated RVV lane 的成功口径照抄到 NEON 上

**退出标准**
- arm64 experimental asm 有单独 lane
- lane 的失败/成功不再污染 stable arch-matrix
- `run_multiarch_qemu.sh` 与 docs 对这条 lane 的口径一致

**关键文件**
- `src/fafafa.core.simd.neon.pas`
- `tests/fafafa.core.simd/docker/run_multiarch_qemu.sh`
- `tests/fafafa.core.simd/BuildOrTest.sh`

---

### Phase 3：RISCVV 从“能编 + smoke”推进到“可维护 experimental backend”

**目标**
- 不急着宣布 RISCVV stable，而是先把它建设成一个真正可维护、可验证、可逐步扩展的 experimental backend

**本阶段要做什么**
- 继续收敛 `src/fafafa.core.simd.riscvv.pas` 的 FPC/GAS 方言兼容问题
- 逐步减少 dispatch fallback mismatch，优先保证：
  - register / load-store / select / compare 等高频 slot 的签名正确
  - façade fallback 始终安全
- 把 `bench` 从默认 SKIP 提升为“显式 opt-in 可运行”
- 给 RVV lane 增加更明确的阶段级状态：
  - compile-only
  - stable smoke
  - bench opt-in
  - broad runtime coverage（后续）

**不要做什么**
- 不要把“compile-only PASS”包装成“RISCVV fully complete”
- 不要为了追求 bench 绿，破坏 stable/public surface

**退出标准**
- `riscvv-opcode-lane` 的 summary 与真实行为完全一致
- dedicated lane 的 compile / smoke / bench 层级说明稳定
- backend 注册与 fallback 行为可预测

**关键文件**
- `src/fafafa.core.simd.riscvv.pas`
- `tests/fafafa.core.simd/docker/run_riscvv_opcode_lane.sh`
- `tests/fafafa.core.simd/BuildOrTest.sh`

---

### Phase 4：CI 分层与成本控制

**目标**
- 建立“快门禁 / 稳态门禁 / 重证据 lane / experimental lane”四层 CI，而不是把所有事情塞进同一个入口

**建议分层**
- **Fast Gate**：`check` + `DispatchAPI` + `gate`
- **Stable Release Gate**：`gate-strict` + Windows evidence + fresh stable QEMU evidence
- **Heavy Evidence Lanes**：QEMU arch matrix、CPUInfo non-x86 full evidence、Windows real-host closeout
- **Experimental Lanes**：RVV opcode/smoke、NEON experimental asm、future bench lanes

**退出标准**
- 每条 lane 都有明确职责
- 人类和 CI 都知道“失败了代表什么”
- 不会再出现“一个 experimental 失败把 stable 结论搞乱”的情况

---

### Phase 5：发布候选与声明治理

**目标**
- 让对外声明、handoff、closeout、RC checklist、freeze evaluator 全部使用一致措辞

**对外建议措辞**
- `fafafa.core.simd` stable/public surface: **cross-platform ready + QEMU stable/public-surface evidence aligned**
- `sbRISCVV`: **experimental backend with dedicated compile + stable-smoke evidence**
- AArch64 experimental asm: **under hardening, not part of stable release claim**

**退出标准**
- 没有文档继续把“QEMU non-x86 还是未来项”写成旧状态
- 没有文档把 `sbRISCVV` 写成 stable backend
- handoff / closeout / checklist / freeze script 说法一致

---

## 持续开发协议（以后怎么长期推进）

从这份路线图开始，后续工作统一按下面方式执行：

1. **先选阶段，再做任务**
   - 不再接受没有阶段归属的碎片修复
2. **每轮只推进一个明确主题**
   - 例如“只做 Phase 1 freeze evaluator 升级”
3. **每轮都必须给证据路径**
   - 命令、summary、docs 回填缺一不可
4. **所有新结论都落盘**
   - `task_plan.md`
   - `findings.md`
   - `progress.md`
   - 对应 `docs/plans/*.md`
5. **stable 与 experimental 分开汇报**
   - 不混说
   - 不混验收
   - 不混 freeze required 集合

---

## 我建议的立即顺序

如果现在继续由我往下做，顺序应该是：

1. **先做 Phase 1**：full-platform freeze / evaluator 升级
2. **再做 Phase 2**：AArch64 experimental asm 专项 lane
3. **然后做 Phase 3**：RISCVV bench / broader runtime hardening
4. **最后做 Phase 4/5**：CI 分层与发布声明治理

这是当前最稳、也最不容易重新碎片化的顺序。

---

## 这份路线图的使用方式

- 你如果只想知道“下一步做什么”，直接看“我建议的立即顺序”
- 你如果要开新执行会话，就让执行方从 **Phase 1** 开始
- 你如果想避免再次碎片开发，就要求所有新工作必须先说明：
  - 属于哪个 Phase
  - 本轮退出标准是什么
  - 哪个 summary / doc 会被更新

