# SIMD non-x86 接口目标清单（NEON / RISCVV）

更新时间：2026-02-10

## 1) 目标与范围

- 目标：把 non-x86（`sbNEON` / `sbRISCVV`）的 dispatch 能力收敛为“有清单、有护栏、可持续回归”的状态。
- 范围：只聚焦阻塞开发的高价值接口族：
  - 算术（Arithmetic）
  - 比较（Compare）
  - 掩码（Mask）
  - 规约（Reduce）
  - 窄整数（Narrow Integer）

## 2) 双层验证策略（固定执行）

1. **Wiring 层（无硬件依赖）**
   - 使用 `TryGetRegisteredBackendDispatchTable` 校验“已注册后端”的槽位绑定完整性。
2. **Runtime 层（可用即测）**
   - 使用 `TrySetActiveBackend`，对可用后端做跨后端语义一致性 smoke。

## 3) P0 清单（当前主攻）

| 接口族 | 目标槽位（代表集） | 验证方式 | 当前状态 |
|---|---|---|---|
| F32x4 Core | `AddF32x4`, `CmpLtF32x4`, `ReduceAddF32x4` | Runtime + Wiring | ✅ |
| Mask Core | `Mask2All`, `Mask4All`, `Mask8All`, `Mask16All` | Wiring | ✅ |
| Narrow Signed | `AddI16x8`, `CmpEqI16x8`, `AndNotI8x16` | Wiring | ✅ |
| Narrow Unsigned | `AddU16x8`, `CmpEqU16x8`, `AndNotU16x8`, `AddU8x16`, `CmpEqU8x16`, `AndNotU8x16` | Wiring | ✅ |

对应测试：
- `Test_VecF32x4_CoreOps_DispatchCrossBackendParity`
- `Test_NonX86_MinimalDispatchParity_IfAvailable`
- `Test_NonX86_DispatchTable_WiringChecklist`

## 4) P1 清单（下一批按项攻克）

### 4.1 Narrow Compare 全系（I16x8 / I8x16 / U16x8 / U8x16）
- [x] `CmpLt`
- [x] `CmpLe`
- [x] `CmpGt`
- [x] `CmpGe`
- [x] `CmpNe`

### 4.2 Narrow Arithmetic/Bitwise 补齐断言
- [x] `Sub`
- [x] `Min`
- [x] `Max`
- [x] `And/Or/Xor/Not`
- [x] `SatAdd/SatSub`（`I8/I16/U8/U16`）
- [x] `Shift(I16/U16)` + `AndNot(I16/I8/U16/U8)`
- [x] `Mul(I16/U16)` + `Shift high-count(>=16)`
- [x] `Shift invalid-count(<0 / >>lane)` consistency
- [x] `Compare+Mask` fixed-seed fuzz parity
- [x] `Mem/Text` fixed-seed fuzz parity（offset/len 扰动）
- [x] `Narrow+Reduce` fixed-seed fuzz parity
- [x] `Wiring` grouped-batch assertions（slot group based）

### 4.3 Mask 扩展
- [x] `Mask2/4/8/16`: `Any/None/PopCount/FirstSet`

### 4.4 Reduce 扩展（F32x4）
- [x] `ReduceAdd`
- [x] `ReduceMin`
- [x] `ReduceMax`
- [x] `ReduceMul`



## 4.5 Runtime Parity（可用即测）

- [x] `Narrow bitwise + F32x4 Reduce` 与 Scalar 结果一致（`Test_NonX86_NarrowBitwiseReduce_RuntimeParity_IfAvailable`）
- [x] `Narrow arithmetic + F32x4 Reduce` 与 Scalar 结果一致（含 `ReduceAdd`）
- [x] `Saturating arithmetic(I8/I16/U8/U16)` 与 Scalar 结果一致（`Test_NonX86_SaturatingArithmetic_EdgeMatrix_RuntimeParity_IfAvailable`）
- [x] `Narrow shift + andnot` 与 Scalar 结果一致（`Test_NonX86_NarrowShiftAndNot_EdgeMatrix_RuntimeParity_IfAvailable`）
- [x] `Narrow mul + high-shift-count` 与 Scalar 结果一致（`Test_NonX86_NarrowMulShiftHighCount_RuntimeParity_IfAvailable`）
- [x] `Narrow shift invalid-count` 与 Scalar 结果一致（`Test_NonX86_ShiftInvalidCount_RuntimeParity_IfAvailable`）
- [x] `Compare+Mask` 固定种子随机矩阵与 Scalar 一致（`Test_NonX86_CompareMask_FuzzSeed_RuntimeParity_IfAvailable`）
- [x] `Mem/Text` 固定种子随机矩阵与 Scalar 一致（`Test_NonX86_MemText_FuzzSeed_RuntimeParity_IfAvailable`）
- [x] `Narrow+Reduce` 固定种子随机矩阵与 Scalar 一致（`Test_NonX86_NarrowReduce_FuzzSeed_RuntimeParity_IfAvailable`）
- [x] Wiring grouped-batch assertions（`Test_NonX86_DispatchTable_WiringChecklist_Grouped`，即 `Wiring` 分组批量断言已落地）
- [x] `Narrow Compare` 与 Scalar mask 结果一致
- [x] `Mask2/4/8/16` 函数行为与 Scalar 一致



### 4.6 Wiring 自动对账
- [x] `check_nonx86_wiring_sync.py`：自动核对 legacy/grouped/checklist 三方一致性
- [x] `BuildOrTest.sh wiring-sync`：本地一键执行对账
- [x] strict mode：`SIMD_WIRING_SYNC_STRICT_EXTRA=1 bash tests/fafafa.core.simd/BuildOrTest.sh wiring-sync`
- [x] check 可选强约束：`SIMD_CHECK_WIRING_SYNC=1 bash tests/fafafa.core.simd/BuildOrTest.sh check`
- [x] gate 可选强约束：`SIMD_GATE_WIRING_SYNC=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
- [x] Windows runner action：`buildOrTest.bat wiring-sync`（脚本级对齐，待 Windows 实机复核）
- [x] Windows runner gate/check 开关：`SIMD_GATE_WIRING_SYNC=1` / `SIMD_CHECK_WIRING_SYNC=1`
- [x] gate 摘要：`BuildOrTest.sh gate-summary` + `logs/gate_summary.md`
- [x] wiring-sync 产物：`logs/wiring_sync.txt` + `logs/wiring_sync.json`
- [x] gate 摘要包含失败链路（step + status + detail），便于快速回溯
- [x] gate 摘要包含 `DurationMs/Event`（慢步骤与失败事件可观测）
- [x] gate 摘要包含 `Artifacts`（日志路径可直接回溯）
- [x] gate-summary 支持 `SIMD_GATE_SUMMARY_FILTER=FAIL|SLOW`（Linux）
- [x] gate-summary 支持 `SIMD_GATE_SUMMARY_JSON=1` 导出机器可读摘要（Linux）
- [x] Windows gate-summary 支持 `SIMD_GATE_SUMMARY_FILTER=FAIL|SLOW`（脚本层）
- [x] Windows gate-summary 支持 `SIMD_GATE_SUMMARY_JSON=1`（依赖 Python，脚本层）
- [x] gate-summary 样本生成 action（Linux/Windows 脚本层）：`gate-summary-sample`
- [x] gate-summary 阈值演练 action（Linux/Windows 脚本层）：`gate-summary-rehearsal`
- [x] gate-summary 非侵入式注入 action（Linux/Windows 脚本层）：`gate-summary-inject`
- [x] gate-summary 一键回滚 action（Linux/Windows 脚本层）：`gate-summary-rollback`
- [x] gate-summary 备份列表 action（Linux/Windows 脚本层）：`gate-summary-backups`
- [x] gate step detail 支持 `SIMD_GATE_SUMMARY_MAX_DETAIL` 截断，避免超长摘要
- [x] gate 失败传播为 fail-fast：首个失败 step 立即终止，并在 summary 记录 `failed-step=*`

## 5) DoD（冻结标准）

- P0 全部 ✅ 且 `DispatchAPI + coverage + gate` 连续稳定通过。
- P1 关键子集（Compare/Mask/NarrowArithmetic/Reduce/Saturating/ShiftAndNot/MulHighShift/InvalidShift/FuzzParity/MemTextFuzz/NarrowReduceFuzz/WiringGrouped）已完成，且无回归。
- Windows 实机证据后续按独立收口任务补齐（当前不阻塞 Linux 迭代）。


## 6) 冻结判定（Linux）

- 结论：截至 2026-02-10，non-x86 路径在 Linux 已满足冻结条件。
- 证据：`DispatchAPI + coverage + gate` 多轮稳定通过，且清单 `P0/P1 + Runtime Parity` 全部勾选。
- 残余项：仅 Windows 实机证据待补（不阻塞当前 Linux 主线开发）。
