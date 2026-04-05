# fafafa.core.simd 收尾与回归矩阵

这份文档给下一位维护者一个直接可用的结论：**现在模块是什么状态、日常改动该跑什么、发布前该补什么、还有哪些债没收完。**

如果你只想看最短版本：

- 公开 façade 和 dispatch contract 边界可以按 stable surface 理解
- backend 成熟度并不完全相同，`sbRISCVV` 仍按 experimental / 受限成熟度看待
- experimental intrinsics 默认入口链已经隔离
- adapter wiring 现在有更强的自动校验，但还没有走到“自动生成 Pascal 代码”的程度
- façade 层现在区分了 `supported-on-cpu` 与 `dispatchable-in-this-binary` 两种后端视图

## 这一轮收了什么

这轮收尾主要完成了 5 组工作：

1. **文档 landing / API 名称纠偏**
   - 统一了 README、模块总览、API 文档的阅读入口
   - 修正了 `VecF32x4LoadAligned` / `VecF32x4StoreAligned` 等公开 façade 名称
   - 把历史草案文档明确标成“不要当真相源”

2. **cpuinfo 测试绿灯语义修正**
   - 把 `AssertTrue(..., True)` 形式的伪 skip 改成显式 skip
   - 避免“没测到”被统计成正常通过

3. **`cpuinfo.x86` 样本驱动测试增强**
   - 新增 vendor / brand / AVX / AVX2 / AVX-512 gating 的样本驱动测试
   - 抽出最小 pure helper seam，降低对当前宿主机的依赖

4. **stable / experimental 边界收口**
   - 明确 stable 的是公开 façade 与 in-repo dispatch contract，而不是“每个 backend 都一样成熟”
   - 明确 `sbRISCVV` 仍是 experimental / 受限成熟度 backend
   - 明确 experimental intrinsics 默认不属于 stable surface

5. **adapter wiring 校验增强**
   - `backend.adapter.map.inc` 现在被明确为 adapter-managed slots 的事实真相源
   - `adapter-sync` 除了校验 `backend.iface <-> backend.adapter`，还会校验：
     - 映射里引用的 slot 是否真实存在于 `TSimdDispatchTable`
     - 这些 slot 是否被 `FillBaseDispatchTable` 覆盖

6. **dispatch contract hard guard**
   - `check_dispatch_contract_signature.py` 会对 `TSimdBackendInfo` / `TSimdDispatchTable` 的声明签名做 machine-readable 校验
   - `gate` 默认已带上 `contract-signature` step，用来防止仓库内 dispatch contract 被无意改坏
7. **public ABI hard guard**
   - `check_public_abi_signature.py` 会对 public ABI wrapper 的 Pascal 声明、ABI 常量、backend/capability ID 映射，以及 `publicabi_smoke.h` consumer contract 做 machine-readable 校验
   - `gate` / `gate-strict` 默认已带上 `publicabi-signature` step，用来防止 public ABI wrapper 被无意改坏

## 现在可以怎么理解这个模块

先把几个边界分开：

- **稳定面**：`fafafa.core.simd` / `fafafa.core.simd.api` 对外公开的 façade，以及 `TSimdDispatchTable` 这类已明确写进稳定约束的 in-repo dispatch contract 边界
- **实现面**：`dispatch`、`cpuinfo`、各 backend 单元、`backend.iface` / `backend.adapter`
- **实验面**：experimental intrinsics，以及 `sbRISCVV` 这类仍在受限成熟度区间的 backend

这意味着：

- 正常使用者可以把公开 API 当作稳定入口
- 当前 `TSimdDispatchTable` 可以按仓库内稳定 contract 理解，但不应被当成 public binary ABI
- `cpuinfo` 的 `GetSupportedBackendList` / `GetBestSupportedBackend` 是 `supported_on_cpu` 视图的推荐入口
- `GetAvailableBackends` / `GetBestBackendOnCPU` 继续保留，但只按兼容别名理解
- façade 层的 `GetRegisteredBackendList` / `IsBackendRegisteredInBinary` 反映的是 `registered` 视图
- façade 层的 `GetAvailableBackendList` / `GetDispatchableBackendList` 反映的是 `dispatchable` 视图
- `GetCurrentBackend` / `GetCurrentBackendInfo` 反映的是 `active` 视图
- 维护者不能把“façade stable”误读成“所有 backend 都同样成熟、同样覆盖、同样适合发布级承诺”
- 默认门禁会保护主链路，但不会自动替你证明“所有 experimental 路径都已发布级保证”

## 推荐回归命令矩阵

### Linux / macOS

#### 日常改动

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh check
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch
bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

这组命令适合：
- 文档同步
- façade 小修
- dispatch / cpuinfo 的局部修改
- backend 小范围修正

#### `cpuinfo` 便携路径

Run:
```bash
bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test --suite=TTestCase_PlatformSpecific
bash tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh test --suite=TTestCase_LazyCPUInfo
```

#### `cpuinfo.x86` 样本驱动路径

Run:
```bash
bash tests/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh test --suite=TTestCase_SampleDriven
bash tests/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh test --suite=TTestCase_Global
```

#### adapter wiring / experimental boundary

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh adapter-sync
bash tests/fafafa.core.simd/BuildOrTest.sh experimental-intrinsics
```

#### 发布前 / closeout

Run:
```bash
bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict
```

`gate-strict` 是发布门禁，不是日常快门禁。它会补上更重的 repeat 与结构一致性路径。
当前默认口径会强制 coverage / wiring / interface-completeness / adapter-sync / `cpuinfo-lazy-repeat` / `qemu-cpuinfo-nonx86-evidence` / Windows evidence 等发布前检查；仍然保持显式可选的只包括 `qemu-nonx86-evidence`、`qemu-cpuinfo-nonx86-full-evidence`、`qemu-cpuinfo-nonx86-full-repeat`、`qemu-arch-matrix-evidence` 与 `perf-smoke`，需要通过对应 `SIMD_GATE_*` 开关开启。

如果你是在 Linux 上做 dry-run、对比不同脚本口径，或者同一轮里要并发跑 `gate` / `gate-strict` / `evidence-linux`，建议显式设置 `SIMD_OUTPUT_ROOT`，避免互相覆盖默认 `bin2/lib2/logs`。

Run:
```bash
SIMD_OUTPUT_ROOT=/tmp/simd-closeout-123 bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict
```

或者：
```bash
SIMD_OUTPUT_ROOT=/tmp/simd-closeout-123 bash tests/fafafa.core.simd/BuildOrTest.sh evidence-linux
```

这类隔离运行适合预演和并发回归，但**不会替代** Windows 实机 evidence。真正收口应优先走 `win-evidence-via-gh` / `win-closeout-finalize` 主线；`finalize-win-evidence` 只保留给拆分诊断或低层脚本调用。
`perf-smoke`、`qemu-nonx86-evidence`、`qemu-cpuinfo-nonx86-full-evidence`、`qemu-cpuinfo-nonx86-full-repeat` 与 `qemu-arch-matrix-evidence` 仍保留为显式可选项；如果你要把这些重证据也纳入发布门禁，可先设置对应 `SIMD_GATE_*` 开关再运行。
它也会把 `wiring-sync`、`interface-completeness`、`adapter-sync` 这类结构一致性检查一起带上。

### Windows

#### 日常改动

Run:
```bat
tests\fafafa.core.simd\buildOrTest.bat check
tests\fafafa.core.simd\buildOrTest.bat test --suite=TTestCase_DispatchAPI
tests\fafafa.core.simd\buildOrTest.bat test --suite=TTestCase_DirectDispatch
tests\fafafa.core.simd\buildOrTest.bat gate
```

#### `cpuinfo` 便携路径

Run:
```bat
tests\fafafa.core.simd.cpuinfo\buildOrTest.bat test --suite=TTestCase_PlatformSpecific
tests\fafafa.core.simd.cpuinfo\buildOrTest.bat test --suite=TTestCase_LazyCPUInfo
```

#### `cpuinfo.x86` 样本驱动路径

Run:
```bat
tests\fafafa.core.simd.cpuinfo.x86\buildOrTest.bat test --suite=TTestCase_SampleDriven
tests\fafafa.core.simd.cpuinfo.x86\buildOrTest.bat test --suite=TTestCase_Global
```

#### adapter wiring / experimental boundary

Run:
```bat
tests\fafafa.core.simd\buildOrTest.bat adapter-sync
tests\fafafa.core.simd\buildOrTest.bat experimental-intrinsics
```

#### 发布前 / closeout

Run:
```bat
tests\fafafa.core.simd\buildOrTest.bat gate-strict
```

## 建议最小提交面

如果现在的目标是“先把 Linux 侧 closeout 相关修复稳定落地”，而不是一次性把所有 `SIMD` 文档/历史整理都带上，建议按下面三类处理：

### 必须保留

- **运行时修复**：`src/fafafa.core.simd.intrinsics.sse.pas`、`src/fafafa.core.simd.intrinsics.mmx.pas`、`tests/fafafa.core.simd/fafafa.core.simd.bench.pas`、`tests/fafafa.core.simd.intrinsics.sse/fafafa.core.simd.intrinsics.sse.testcase.pas`
- **门禁与 evidence helper**：`tests/fafafa.core.simd/BuildOrTest.sh`、`tests/fafafa.core.simd/buildOrTest.bat`、`tests/fafafa.core.simd/run_backend_benchmarks.sh`、`tests/fafafa.core.simd/collect_linux_simd_evidence.sh`、`tests/fafafa.core.simd/docker/run_multiarch_qemu.sh`
- **gate / freeze 语义**：`tests/fafafa.core.simd/generate_gate_summary_sample.py`、`tests/fafafa.core.simd/export_gate_summary_json.py`、`tests/fafafa.core.simd/rehearse_freeze_status.sh`、`tests/fafafa.core.simd/evaluate_simd_freeze_status.py`
- **`cpuinfo` 子 runner 隔离**：`tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh`、`tests/fafafa.core.simd.cpuinfo/buildOrTest.bat`、`tests/fafafa.core.simd.cpuinfo.x86/BuildOrTest.sh`、`tests/fafafa.core.simd.cpuinfo.x86/buildOrTest.bat`

### 可以后移

- `docs/fafafa.core.simd.md`
- `src/fafafa.core.simd.README.md`
- 其他偏阅读地图 / 维护叙事增强、但不直接影响 closeout 路径是否可跑通的文档整理

### 必须等 Windows 实证

- Windows evidence 真正通过 verifier 之前，不要把 release candidate checklist / completeness matrix / closeout roadmap 里的 Windows 项自动勾成完成
- 截至 `2026-03-10`（batch `SIMD-20260310-152`）Windows evidence 已闭环；当前可以按 **cross-platform freeze 条件满足** 理解（后续若改 contract/public ABI 仍需重收证据）

## 还有哪些债没收完

这些不是“现在坏了”，而是后续最值得继续清理的地方：

1. **`dispatch / adapter` 还没走到真正的单一代码生成**
   - 现在已经有更强 checker
   - 但还没有做到“由一份源自动生成 Pascal 接线代码”

2. **`sbRISCVV` 仍是 experimental / 受限成熟度**
   - 口径已经统一
   - 但成熟度本身并没有因为文档收口而改变

3. **Windows 实机证据仍应继续补**
   - Windows 脚本口径已经对齐
   - 但脚本文案对齐不等于所有 Windows 实机场景都已重新验证

   Windows 实机 evidence 过 verifier 时，日志至少要包含这些字段：
   - `Source: collect_windows_b07_evidence.bat`
   - `HostOS: Windows_NT`
   - `CmdVer: Microsoft Windows ...`
   - `Working dir: C:\\...`（Windows 风格路径）

   Windows 日志一旦到位，按这个顺序收口：

   Run:
   ```bat
   tests\fafafa.core.simd\buildOrTest.bat evidence-win-verify
   ```

   Then run the required fail-close cross gate:
   ```bash
   FAFAFA_BUILD_MODE=Release SIMD_QEMU_PLATFORMS='linux/arm/v7 linux/arm64 linux/riscv64' SIMD_GATE_QEMU_NONX86_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1 SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT=0 SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=0 SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate
   ```

   Then:
   ```bash
   FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize SIMD-YYYYMMDD-152
   ```

   这里不能直接从 `evidence-win-verify` 跳到 `win-closeout-finalize`，因为 native batch evidence 不会生成 fresh `gate_summary.md/json`；如果少了这步 cross gate，`freeze-status` 现在会以 `cross_gate_not_older_than_windows_evidence` 明确拒绝，而不是再误吃旧摘要给出假绿。

   如果你只是在拆分诊断 closeout helper，才单独使用：

   ```bash
   bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence
   bash tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh --apply --batch-id SIMD-YYYYMMDD-152
   ```

4. **非 x86 / QEMU 证据链仍然是发布前话题**
   - 日常快门禁不会默认把这些重路径都打开
   - closeout 时仍然应该靠 `gate-strict` 和对应 evidence 路径补强

5. **`perf-smoke` 仍是环境敏感证据**
   - 适合在固定机器 / 固定基线下显式开启
   - 不再作为默认 `gate-strict` 阻塞项；需要时请设置 `SIMD_GATE_PERF_SMOKE=1`

## 2026-04-02 Closeout Addendum

- Windows 实机 evidence 已在 `SIMD-20260402-152` 批次闭环，并通过 `win-evidence-via-gh` 旁路归档到 canonical `logs/`；对应 GitHub Actions run id 为 `23889752534`。
- 全量 closeout 口径已在 Linux 侧重跑：
  ```bash
  FAFAFA_BUILD_MODE=Release \
  SIMD_PERF_VECTOR_ASM=auto \
  SIMD_GATE_PERF_SMOKE=1 \
  SIMD_GATE_QEMU_NONX86_EVIDENCE=1 \
  SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1 \
  SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=1 \
  SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT=1 \
  SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=1 \
  SIMD_QEMU_CPUINFO_REPEAT_ROUNDS=3 \
  bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict
  ```
- 结果：canonical `tests/fafafa.core.simd/logs/gate_summary.md` 已刷新为 `gate PASS @ 2026-04-02 23:31:59`，且 `perf-smoke`、`qemu-nonx86-evidence`、`qemu-cpuinfo-nonx86-evidence`、`qemu-cpuinfo-nonx86-full-evidence`、`qemu-cpuinfo-nonx86-full-repeat`、`qemu-arch-matrix-evidence` 全 PASS。
- 强约束冻结判定已复验：
  ```bash
  SIMD_FREEZE_REQUIRE_QEMU_CPUINFO_NONX86_EVIDENCE=1 \
  SIMD_FREEZE_REQUIRE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=1 \
  SIMD_FREEZE_REQUIRE_QEMU_CPUINFO_NONX86_FULL_REPEAT=1 \
  SIMD_FREEZE_REQUIRE_CPUINFO_LAZY_REPEAT=1 \
  FAFAFA_BUILD_MODE=Release \
  bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status
  ```
- 结果：`tests/fafafa.core.simd/logs/freeze_status.json` 现为 `ready=true`、`freeze_ready=true`、`mainline_ready=true`、`cross_ready=true`。
- 2026-04-03 又补跑了一轮 compiler-ready `qemu-nonx86-experimental-asm`：`linux/arm64`、`linux/riscv64` 全 PASS，且 `qemu-experimental-baseline-check --latest` 为 `errors=0, warnings=0`，`qemu-experimental-report --latest` 显示 `parsed_errors=0`。
- 2026-04-03 fresh ARM64 NEON native evidence 已补齐过一轮历史 run：GitHub Actions run `23911571289`（head `3836e4cee60f0a78858d9605a0a8ee9a6cdf86e7`）产出的 artifact `simd-arm64-neon-evidence/native-evidence-neon-20260402-164750/` 中，`DispatchAPI + PublicAbi` 已恢复为 `[TEST] OK`，对应当时那轮 native wide-float slot wiring 修复。注意：这条 run 早于 `source_revision.txt` 产物锚点支持，当前严格来源校验应以 2026-04-05 addendum 里的新 run 为准。
- 2026-04-05 RISCVV native evidence 的执行载体也已补齐：仓库新增 `.github/workflows/simd-riscvv-native-evidence.yml`。它是 enhanced evidence carrier，但是否能直接 `workflow_dispatch` 还取决于 GitHub 是否已在 default branch 注册该 workflow；当前 fresh artifact 仍待 native runner / workflow registration 闭环。
- 2026-04-03 同步完成了一轮 fresh Linux/Windows evidence refresh：Windows batch `SIMD-20260403-152`（GitHub Actions run `23914427193`）已通过 verifier；回灌的 fail-close `gate` 已刷新为 `gate PASS @ 2026-04-03 02:13:10`，随后 `freeze-status` 再次回到 `ready=true`、`mainline_ready=true`、`cross_ready=true`。
- 后续只有在 dispatch contract / public ABI / Windows evidence payload 变化时，才需要重收 Windows closeout evidence。`native-evidence` 与 `qemu-nonx86-experimental-asm` 继续作为增强证据，不纳入当前 freeze 硬门禁。

## 2026-04-05 Closeout Addendum

- `gate` / `gate-strict` 的 `adapter-sync` python-only 分支已做真正的 checker-only 收敛：
  - Linux shell runner 新增 `run_backend_adapter_sync_checker_only()`，`gate_step_adapter_sync_python_only()` 不再隐式回调 `build_project`
  - Windows batch runner 同步切到 `:adapter_sync_checker_only`
  - `tests/fafafa.core.simd/BuildOrTest.sh` 现有 runtime guard，专门防止 python-only 路径再次偷偷触发第二次 Lazarus build
- 这次修复的实际收益是把 `gate` / `gate-strict` 的 adapter-sync 步骤收敛成真正的“结构对账”，不再因为重复 build 把偶发 linker 问题伪装成 adapter-sync 失败。
- `cpuinfo` 的 QEMU closeout 链也完成了一轮实质性 hardening：
  - 根因是 `tests/fafafa.core.simd.cpuinfo/BuildOrTest.sh` 之前把不同 target 都编到共享 `bin/` 路径，QEMU bind-mount 执行时会放大成 `Text file busy` / 可执行映射不稳定
  - 当前 runner 已改为 target-specific `bin/${TRIPLET}` / `lib/${TRIPLET}`，并为 QEMU 场景启用 `SIMD_CPUINFO_RUNTIME_COPY=1`
  - `tests/fafafa.core.simd/BuildOrTest.sh` 也新增了 `check_cpuinfo_qemu_isolation_guard()`，避免这条隔离契约再次回退
- ARM64 NEON enhanced evidence 已补到带 source anchor 的 fresh run：
  - GitHub Actions run `23995214071`
  - head commit：`bb061475c721d776690721a7751dff099ca6597e`
  - helper 现支持 `SIMD_NATIVE_EVIDENCE_EXPECT_COMMIT`、`SIMD_NATIVE_EVIDENCE_EXPECT_REF`、`SIMD_NATIVE_EVIDENCE_REQUIRE_SOURCE_REVISION`
  - 复验时可以强制要求 artifact 内存在 `source_revision.txt`，并校验 `git_commit/git_ref_hint`
  - 历史 run `23911571289` 仍可保留作功能性参考，但它早于 `source_revision.txt` 产物锚点，不再适合作严格来源校验样本
- RISCVV native evidence 的现状需要明确分成“两层”：
  - 仓库内 workflow 文件已经存在：`.github/workflows/simd-riscvv-native-evidence.yml`
  - 但 GitHub Actions 当前还没有把它注册进 default branch 的 workflow 列表，所以 `gh workflow run simd-riscvv-native-evidence.yml --ref simd-foundation` 会返回 404
  - helper 现在会把这个场景解释成明确配置问题：`Workflow is not registered on GitHub Actions`
  - 这不是实现逻辑失败，而是 workflow 注册/托管条件未满足；因此 RISCVV enhanced evidence 继续保留为非 freeze 硬门禁项
- 2026-04-05 还补了一轮 fresh closeout 验证：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict`
  - 结果：canonical `tests/fafafa.core.simd/logs/gate_summary.md` 已刷新为 `gate PASS @ 2026-04-05 15:48:03`
  - 关键 cross 证据：`qemu-cpuinfo-nonx86-evidence PASS @ 2026-04-05 15:48:03`，对应摘要 `tests/fafafa.core.simd/logs/qemu-multiarch-20260405-154057-1022104/summary.md`
  - 随后 `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status` 也再次返回 `ready=True`、`mainline-ready=True`、`cross-ready=True`
- 2026-04-05 还对 optional heavy CPUInfo QEMU 路径补做了 fresh replay：
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh qemu-cpuinfo-nonx86-full-evidence`
  - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh qemu-cpuinfo-nonx86-full-repeat`
  - 结果：`tests/fafafa.core.simd/logs/qemu-multiarch-20260405-161147-1097510/summary.md` 与 `tests/fafafa.core.simd/logs/qemu-multiarch-20260405-161729-1111280/summary.md` 均显示 `linux/arm/v7`、`linux/arm64`、`linux/riscv64` 全 PASS，说明隔离 hardening 对 heavy path 也成立
- `freeze-status --json` 的 stdout 合同也已补正：
  - `tests/fafafa.core.simd/evaluate_simd_freeze_status.py --json` 现在只向 stdout 输出纯 JSON
  - 人类可读的 `[FREEZE] ...` 摘要改走 stderr，不再破坏自动化直接 `json.loads(stdout)` 的消费路径
- `freeze-status` 的手工 Windows closeout 语义也进一步收紧：
  - 新增 required check：`cross_gate_not_older_than_windows_evidence`
  - 含义：cross gate 对应的 `gate_summary.md` 不得早于当前 `windows_b07_gate.log`
  - 这样即使源码没变、旧 gate 仍在 freshness 窗口内，只要你少跑了那一步 fail-close cross gate，`freeze-status` 也会 fail-close，而不是沿用旧 cross gate 假装当前 Windows evidence 已纳入冻结判定
- `freeze-status` 现在还会拒绝 stale closeout summary：
  - 新增 required check：`windows_closeout_not_older_than_windows_evidence`
  - 含义：`windows_b07_closeout_summary.md` 必须晚于或等于当前 `windows_b07_gate.log`
  - 这样即使 summary 文本仍然写着 `- Result: PASS`、verifier 也仍然通过，只要 summary 没有在最新 Windows evidence 之后重新生成，freeze 仍会 fail-close
- canonical Windows closeout 摘要也已通过 `bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize SIMD-20260403-152` 重新写回：
  - `tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md`
  - 生成时间：`2026-04-05 15:26:32 +0800`
- 当前 freeze baseline 没变：freshest Windows closeout baseline 仍是 2026-04-03 的 `SIMD-20260403-152` + fail-close cross gate；2026-04-05 这一轮主要是 Linux gate 重验、QEMU cpuinfo 隔离 hardening 与 native-evidence helper 契约补强，不需要重复收 Windows 证据。

## 收口后的主线优先级

如果现在继续推进，不建议再把“所有 benchmark 里不够好看的一行”都当成主线。当前更合理的排序是：

1. **保留并复用已确认 ROI 的 fast-path**
   - `VecI16x32Add`
   - `VecU8x64Max`

2. **只做低成本观察**
   - `VecU32x16Mul`
   - 理由：门面开销已经压平到接近持平，不再是明确事故

3. **降级观察，不再主动深挖**
   - `VecU64x8Add`
   - `VecF32x4Add`
   - 理由：一个 raw 仍弱于 scalar，一个连小粒度 raw 都不具备当前轮次 ROI

4. **继续真正会影响发布质量的主线**
   - stable boundary 收口
   - evidence contract 统一
   - 真相源文档与 runbook 一致性

## 维护时最容易踩的坑

- 把 `gate` 当成发布放行的唯一依据
- 把 stable façade 误读成“所有 backend 都同等稳定”
- 在 `backend.adapter.map.inc` 之外重复维护 adapter 映射
- 改了 dispatch slot，却忘了看 adapter-sync / base-fill 覆盖
- 在 `SSE2` 上继续激进物理拆分

## 一句话交接

今天这个模块更像这样：**公开 API 已经比以前更稳定、更可读、更可验证；但 backend 成熟度仍有层次，experimental 路径仍要单独看待。**
