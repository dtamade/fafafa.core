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
- `cpuinfo` 的 `GetAvailableBackends` / `GetBestBackendOnCPU` 反映的是 `supported_on_cpu` 视图
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
默认它会强制 coverage / wiring / repeat / non-x86 / Windows evidence 等 closeout 检查；`perf-smoke` 仍是显式可选项，除非你设置 `SIMD_GATE_PERF_SMOKE=1`，或者走 `evidence-linux` 这条固定会把 perf 带进去的证据链。

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
`perf-smoke`、QEMU / Windows evidence 仍保留为显式可选项；如果你要把这些重证据也纳入发布门禁，可先设置对应 `SIMD_GATE_*` 开关再运行。
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

   Then:
   ```bash
   bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize SIMD-YYYYMMDD-152

   如果你只是在拆分诊断 closeout helper，才单独使用：

   ```bash
   bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence
   bash tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh --apply --batch-id SIMD-YYYYMMDD-152
   ```
   ```

4. **非 x86 / QEMU 证据链仍然是发布前话题**
   - 日常快门禁不会默认把这些重路径都打开
   - closeout 时仍然应该靠 `gate-strict` 和对应 evidence 路径补强

5. **`perf-smoke` 仍是环境敏感证据**
   - 适合在固定机器 / 固定基线下显式开启
   - 不再作为默认 `gate-strict` 阻塞项；需要时请设置 `SIMD_GATE_PERF_SMOKE=1`

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
