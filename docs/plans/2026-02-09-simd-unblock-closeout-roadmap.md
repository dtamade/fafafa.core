# SIMD Unblock Closeout & Next Attack Roadmap

更新时间：2026-03-10

## 1. 当前阻塞状态（结论先行）

- **接口阻塞已清零**：`docs/plans/2026-02-09-simd-interface-target-checklist.md` 中 `fafafa.core.simd` 门面接口未勾选项已归零（`[ ] = 0`）。
- **门禁稳定通过**：`VectorOps + check + DispatchAPI + perf-smoke + gate` 串行执行全绿（最新一次：2026-02-09 06:32:37）。
- **Linux 侧可发布候选**：依据 RC 清单，Linux 路径已达发布候选标准。
- **non-x86 收口完成（Linux）**：截至 2026-02-09，NEON/RISCVV 已完成 wiring + runtime parity 双层护栏（Batch106~110）。

## 2. 已完成闭环（对应开发阻塞）

### 2.1 接口清单闭环

Batch82 已补齐并验证以下 5 项：

1. `GetCurrentBackendInfo`
2. `GetAvailableBackendList`
3. `AllocateAligned`
4. `FreeAligned`
5. `IsPointerAligned`

新增测试：
- `TTestCase_VectorOps.Test_BackendInfoAndAlignedMemoryUtilities`
- 覆盖点：后端信息一致性、backend list 可用性、`nil` 对齐行为、默认/显式对齐分配、未对齐偏移断言、内存可写性。

## 3. 剩余阻塞与风险清单（按优先级）

### P0（已关闭）

- [x] **Windows 实机证据已归档**
  - 目标文件：`tests/fafafa.core.simd/logs/windows_b07_gate.log`
  - 关闭依据：`win-closeout-finalize` 已完成，`freeze-status` 已达 `cross-ready=True`。
  - 来源：`tests/fafafa.core.simd/docs/simd_release_candidate_checklist.md`

### P1（不阻塞开发，但建议尽快纳入流程）

- [ ] **Coverage strict-extra 尚未并入默认 gate**
  - 当前状态：默认 gate 已开启 coverage；strict-extra 仍需显式开启（或走 gate-strict）。
  - 风险：后续新增 intrinsics 的“细粒度扩展项”仍可能漏测。
  - 建议：CI nightly 固化 `SIMD_COVERAGE_STRICT_EXTRA=1`（或固定跑 gate-strict）。

- [ ] **证据链自动化尚未固化到 CI 产物**
  - 当前状态：`evidence-linux` 可用，但非默认产线步骤。
  - 风险：回归时证据收集依赖人工触发。

### P2（能力扩展，非当前阻塞）

- [ ] **非 x86 后端覆盖率仍偏低（历史审计项）**
  - NEON：~45%
  - RISC-V V：~35%
  - 建议：作为后续功能增强专题，不与当前 unblock 混做。

## 4. 下一阶段“逐一攻克”目标清单（可直接开干）

### Stage A（已完成，收口发布证据）

- [x] 按推荐顺序完成证据闭环：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight`
  - `tests\fafafa.core.simd\buildOrTest.bat evidence-win-verify`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh gate`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize SIMD-YYYYMMDD-152`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`
- [x] 归档 `windows_b07_gate.log` 到 `tests/fafafa.core.simd/logs/`
- [x] 更新 RC 清单 P0 项为 `[x]`

**DoD:** 跨平台证据链闭环（Linux + Windows）。

### Stage B（1 天，流程防回退）

- [ ] 在 CI（建议 nightly）启用：
  - `SIMD_GATE_COVERAGE=1`
  - `SIMD_COVERAGE_STRICT_EXTRA=1`
- [ ] 固化 `evidence-linux` 产物上传（含 `summary.md`）
- [ ] 验证 3 次连续通过（避免偶发波动）

**DoD:** 新增 intrinsics 漏测可在 gate 前被拦截。

### Stage C（2~4 天，能力增强，不阻塞主线）

- [ ] NEON 优先补齐：窄整数 + compare/mask 基础能力
- [ ] RISC-V V 优先补齐：mask 操作与基础比较
- [ ] 为新增实现补对应最小高价值测试（先 correctness，再 perf）

**DoD:** 非 x86 后端关键路径可用于基础生产场景。

## 5. 推荐执行策略

- 当前开发主线可继续推进（接口层阻塞已解除，Windows closeout 已收口）。
- Windows 实机证据已闭环，后续保持“一条命令采集、一条命令 finalize”的固定入口即可。
- 后端扩展按专题推进，不与门面接口清单混线，持续保持“小批次 + 固定门禁 + 文档回填”。

<!-- SIMD-WIN-CLOSEOUT-2026-03-10 -->
### Windows 实机证据（2026-03-10）

- 状态：已完成
- Evidence Log: tests/fafafa.core.simd/logs/windows_b07_gate.log
- Closeout Summary: tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md
- 结论：P0 “Windows 实机证据未归档” 已关闭。
