# fafafa.core.simd 极简行动清单

这页只回答两件事：现在应该做什么，以及现在不要做什么。

## 现在应该做什么

### 1. 先读这三个文件

- `docs/fafafa.core.simd.map.md`
- `docs/fafafa.core.simd.maintenance.md`
- `docs/fafafa.core.simd.handoff.md`
- `docs/fafafa.core.simd.closeout.md`

### 2. 改代码前先定位层级

先问自己：你要改的是哪一层？

- 主入口：`simd.pas` / `api.pas`
- 运行时选择：`dispatch.pas` / `cpuinfo.pas`
- 后端注册：多数看 `*.register.inc`；`SSE2` 直接看 `sse2.pas`
- 后端快路径：`*.facade.inc`
- 向量族实现：`*.family.inc`

### 3. 日常改动先跑快门禁

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh check
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch
bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

上面这组里：

- `check`：编译卫生 + 基础 runner parity；现在还会 fresh 编译 `NEON/RISCVV` 的 opt-in `--list-suites` 路径，专门防止 non-x86 opt-in compile drift 再次躲过默认门禁
- 两个 `--suite`：最关键的 dispatch / direct 回归
- `gate`：日常改动使用的快门禁 / 基础门禁
- 如果你改了 `TSimdBackendInfo` / `TSimdDispatchTable` 的声明本身，再额外跑：

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh contract-signature
```

- 如果你改了 public ABI wrapper 的声明、ABI 常量或 `publicabi_smoke.h` mirror，再额外跑：

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh publicabi-signature
```

### 4. 准备 closeout / release 再跑完整门禁

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict
```

`gate-strict` 会在 `gate` 的基础上额外打开 repeat、coverage/wiring strict、non-x86 / evidence 等更重的检查，更适合发布前或阶段性收口时运行。
当前默认 `gate` 已包含 `contract-signature` 与 `publicabi-signature` 结构护栏；如果仓库内 dispatch contract 或 public ABI wrapper 漂移，会直接在 gate 红掉。
当前默认 `check/gate` 也会把 non-x86 opt-in smoke 放到隔离子目录 `nonx86.optin/neon`、`nonx86.optin/riscvv` 下做 fresh `--list-suites` 编译验证；如果只想单独复验这层，也可以直接跑：

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh nonx86-optin-list-suites
```

如果你手里已经有真实 `arm64` / `riscv64` 原生主机，而不是 QEMU / x86_64 compile-only 环境，native execution evidence 现在有正式入口：

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh native-evidence
```

当前 collector 默认会先跑 `DispatchAPI + PublicAbi`，并在 suite 出现在 `--list-suites` 时继续补跑
`TTestCase_NonX86IEEE754` 与 `TTestCase_NonX86BackendParity`；如果某个构建配置下 suite 不存在，
summary 里会显式记成 `SKIP`，避免把“没采到”误读成“已经验证过”。当前 artifact 还会额外写
`environment.txt` 与 `source_revision.txt`，用于记录 host/FPC/backend 与 `git_commit/git_ref_hint` 来源锚点。

若要走 GitHub Actions 原生证据路径，当前仓库已有两条 workflow：
- `.github/workflows/simd-arm64-neon-evidence.yml`：`workflow_dispatch` + `workflow_call`，hosted `ubuntu-24.04-arm`；`simd-nightly-closeout` 会复用这条 lane
- `.github/workflows/simd-riscvv-native-evidence.yml`：`workflow_dispatch` + `workflow_call`，需要 self-hosted `Linux+riscv64` runner
  - 注意：`gh workflow run ...` 只有在该 workflow 已被 GitHub 按仓库 default branch 注册后才能成功；如果 helper 明确报 `Workflow is not registered on GitHub Actions`，优先先把 workflow 同步到 default branch，或直接复用现成 `run-id`

需要显式切到 backend-asm / direct-fpc 采集时，可再加：

```bash
SIMD_NATIVE_EVIDENCE_RUNNER=direct-fpc \
SIMD_NATIVE_EVIDENCE_ENABLE_BACKEND_ASM=1 \
bash tests/fafafa.core.simd/BuildOrTest.sh native-evidence riscvv
```

如果想直接通过 GitHub Actions 触发并把 artifact 下载回本地，可使用：

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh native-evidence-via-gh neon
bash tests/fafafa.core.simd/BuildOrTest.sh native-evidence-via-gh riscvv
```

默认 dispatch 路径会先检查本地 worktree 干净，且 remote ref 与本地一致；如果你只是想复用现成 artifact，直接传 `run-id` 旁路即可。
helper 下载成功后会打印 `summary.md`、`dispatch_publicabi.log`，以及存在时的 `source_revision.txt` 路径。
如果你要把 artifact 来源锚死到某个 commit/ref，可额外设置：

```bash
SIMD_NATIVE_EVIDENCE_EXPECT_COMMIT=<full-sha> \
SIMD_NATIVE_EVIDENCE_EXPECT_REF=<ref-name> \
SIMD_NATIVE_EVIDENCE_REQUIRE_SOURCE_REVISION=1 \
bash tests/fafafa.core.simd/BuildOrTest.sh native-evidence-via-gh neon 12345678901
```

注意：较老的历史 artifact 可能早于 `source_revision.txt` 产物支持；这类 run 仍可作功能性参考，但不能满足严格 source-revision 校验。

若已知现成 `run-id`，也可复用旧 run：

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh native-evidence-via-gh neon 12345678901
bash tests/fafafa.core.simd/BuildOrTest.sh native-evidence-via-gh riscvv 12345678901
```

如果你想在本地继续复验 `freeze-status` 或 `win-closeout-finalize`，`restore-nightly-evidence` 的输入应是原始 artifact 目录，例如 `simd-linux-evidence`、`simd-windows-b07-evidence`，以及可选的 `simd-arm64-neon-evidence` / `simd-riscvv-native-evidence`；不要把聚合后的 `simd-freeze-audit` 当成 restore 输入。

例如，先恢复 canonical `logs/`：

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh restore-nightly-evidence \
  /tmp/simd-linux-evidence \
  /tmp/simd-windows-b07-evidence \
  /tmp/simd-arm64-neon-evidence
```

`perf-smoke` 默认仍是显式开关；若要把它纳入 closeout 门禁，请设置 `SIMD_GATE_PERF_SMOKE=1`，或直接走 `evidence-linux`。若 active backend 仍落在 `Scalar`，当前会直接失败，因为这意味着没有拿到可用于 closeout 的 SIMD 性能证据。

如果你是在同一台机器上并发跑多个 `SIMD` helper，或者只是想做不落默认产物目录的 dry-run，优先设置 `SIMD_OUTPUT_ROOT`。

```bash
SIMD_OUTPUT_ROOT=/tmp/simd-run-123 bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict
```

或者：

```bash
SIMD_OUTPUT_ROOT=/tmp/simd-run-123 bash tests/fafafa.core.simd/BuildOrTest.sh evidence-linux
```

这不会替代 Windows 实机 evidence；它只是把 `bin2/lib2/logs` 改写到隔离目录，方便预演与并发回归。
当前 shell gate 链路里的 `cpuinfo` / `cpuinfo.x86` / `publicabi` / `nonx86.optin` 子 runner 也会自动落到隔离根下的对应子目录；`run_all_tests` 过滤链里尊重 `SIMD_OUTPUT_ROOT` 的 simd 模块则会进一步落到 `run_all/<module>/`。
如果需要回收这批隔离产物，直接执行同根 `SIMD_OUTPUT_ROOT=/tmp/simd-run-123 bash tests/fafafa.core.simd/BuildOrTest.sh clean`；主 runner 现在会把顶层 `bin/lib`、这些子目录以及 `run_all/` 一并清掉。
真正的 Windows 收口主线应优先使用 `win-evidence-via-gh`。
若走手工 Windows 实机路径，则必须先跑 `FAFAFA_BUILD_MODE=Release SIMD_QEMU_PLATFORMS='linux/arm/v7 linux/arm64 linux/riscv64' SIMD_GATE_QEMU_NONX86_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1 SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_EVIDENCE=0 SIMD_GATE_QEMU_CPUINFO_NONX86_FULL_REPEAT=0 SIMD_GATE_QEMU_ARCH_MATRIX_EVIDENCE=0 SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate`，再执行 `win-closeout-finalize`。

## 现在不要做什么

### 1. 不要继续硬拆 `SSE2`

`src/fafafa.core.simd.sse2.pas` 现在是明确的稳定边界。

### 2. 不要再拆测试文件

测试文件拆分尝试已经回滚，后续保持单文件更稳。

### 3. 不要把 `gate` 当成发布放行的唯一依据

`gate` 是快门禁，不是发布门禁。

### 4. 不要跨多个 backend 同时大改

优先做小范围、按需修改。

## 如果看到这些错误

- `Text file busy`：先确认是不是旧 runner / 旧产物；当前 `cpuinfo` QEMU 路径已切到 target-specific 输出 + runtime copy，若仍出现，多半是外部挂载或并发环境问题
- `Function nesting > 31`：先恢复到最近稳定状态，不要继续叠加拆分
- `backend_slot_counts` 下降：先检查脚本有没有跟上 `{$I ...}` include

## 一句话版本

现在最值得做的是：小范围修正 + 文档同步；最不值得做的是：继续激进拆分 `SSE2` 或测试文件。
