# CI for fafafa.core.lockfree

> 当前策略：CI 暂时不自动运行，仅保留手动触发（workflow_dispatch）。如需恢复自动触发，请将 matrix 工作流的 on: 改回 push/pull_request。

## strict L0 的 Windows 路径说明

当前 CI / 手工验证里，strict non-SIMD L0 的 Windows 相关检查要分成两类看：

- 已完成并可在 Linux + `wine` 环境复核的 runtime 证据
  - `bash tests/test_windows_strict_l0_wine_smoke.sh`
  - `bash tests/test_windows_strict_l0_batch_runtime_smoke.sh`
  - `bash tests/test_windows_strict_l0_batch_runtime_matrix.sh`
- 仍依赖真实 Windows Lazarus toolchain 的 native `.bat` build-path parity
  - 这部分当前仍需要可用的 Windows `lazbuild.exe`
  - fail-close preflight：
    - `bash tests/test_windows_lazbuild_smoke_preflight.sh`
    - `bash tests/preflight_windows_strict_l0_native_evidence_gh.sh`
  - 真正的 dedicated Windows host lane：
    - `tests\test_windows_strict_l0_batch_native_matrix.bat`
    - `tests\collect_windows_strict_l0_native_evidence.bat`
    - `tests\verify_windows_strict_l0_native_evidence.bat`
    - `bash tests/verify_windows_strict_l0_native_evidence.sh [snapshot-root] [expected-commit] [expected-ref]`
  - 这条 lane 固定覆盖 strict L0 的 12 个 `.bat` 入口，并明确拒绝 `FAFAFA_SKIP_BUILD=1`
  - 如果需要 hosted/manual workflow 入口，仓库内现在也有：
    - `.github/workflows/l0-windows-native-evidence.yml`
    - `bash tests/run_windows_strict_l0_native_evidence_via_github_actions.sh [batch-id] [run-id]`
  - `run_windows_strict_l0_native_evidence_via_github_actions.sh` 会先做 `gh` / workflow preflight、再 dispatch 或复用既有 run、下载 artifact，并调用 `verify_windows_strict_l0_native_evidence.sh` 在 Linux shell 上校验证据包结构
  - 如果 workflow 还没有注册到仓库 default branch，当前预期由 `preflight_windows_strict_l0_native_evidence_gh.sh` 以 `code=22` fail-close，而不是假装可以 dispatch
  - 在缺少该工具链时，预期通过 preflight / native lane 自身 fail-close，而不是把 native build parity 误记成已完成

当前推荐口径：

- 可以把 strict L0 的 Windows runtime smoke 和 `.bat` runtime-only parity 记成已完成
- 可以把 native lane 的脚本接线、collector/verifier、workflow wiring、via-GitHub-Actions helper、contract 和 fail-close 语义记成已完成
- 不要把 native Windows `.bat` build-path parity 记成已完成，除非 `tests\test_windows_strict_l0_batch_native_matrix.bat` 已经在真实 Windows `lazbuild.exe` 条件下 fresh 通过

# Minimal Windows CI: FS only

本节提供最小化的 Windows CI 入口，仅构建与运行 fafafa.core.fs 测试。

## 本地/CI 共用脚本

- 脚本：scripts/test-fs-only.bat
- 行为：调用 tests/fafafa.core.fs/BuildOrTest.bat test，输出日志到 tests/fafafa.core.fs/logs/last.txt，并以测试退出码返回

## GitHub Actions（示例）

```yaml
name: FS Tests (Windows)
on:
  push:
    paths:
      - "src/**"
      - "tests/fafafa.core.fs/**"
      - "scripts/test-fs-only.bat"
      - ".github/workflows/fs-tests.yml"
  pull_request:
    paths:
      - "src/**"
      - "tests/fafafa.core.fs/**"

jobs:
  fs-tests:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Lazarus (choco)
        run: |
          choco install lazarus -y
      - name: Run FS tests
        shell: cmd
        run: scripts\test-fs-only.bat
```

注意：

- 若仓库已有自定义 lazbuild 安装方式，请将“Install Lazarus (choco)”替换为项目已有步骤或使用缓存
- 该工作流仅作为示例，提交前可根据仓库策略调整触发路径与名称

## 测试 Runner 最佳实践（跨模块通用）

- 目标：统一 Runner 调用、产物路径与退出码策略，使 CI 与本地一致。
- 推荐约定：
  - 默认报告路径通过环境变量设置，CI 与本地均可复用：
    - FAFAFA_TEST_JUNIT_FILE=out/junit.xml
    - FAFAFA_TEST_JSON_FILE=out/report.json
  - CI 入口使用 --ci 或 --quiet --summary，避免控制台冗长输出
  - 将 skip 视为失败时加 --fail-on-skip
  - 输出最慢用例帮助定位性能回退：--top-slowest=5

### Windows（GitHub Actions 示例）

```yaml
- name: Run tests (Runner best practices)
  shell: pwsh
  env:
    FAFAFA_TEST_JUNIT_FILE: out/junit.xml
    FAFAFA_TEST_JSON_FILE: out/report.json
  run: |
    ./tests/fafafa.core.test/bin/tests.exe --ci --fail-on-skip --top-slowest=5
```

### Linux（GitHub Actions 示例）

```yaml
- name: Run tests (Runner best practices)
  env:
    FAFAFA_TEST_JUNIT_FILE: out/junit.xml
    FAFAFA_TEST_JSON_FILE: out/report.json
  run: |
    chmod +x tests/fafafa.core.test/bin/tests.exe || true
    ./tests/fafafa.core.test/bin/tests.exe --ci --fail-on-skip --top-slowest=5
```

### 用例清单（供编排器/矩阵）

- Windows：powershell -File scripts\list-tests.ps1 -Filter core -CI
- Linux/macOS：./scripts/list-tests.sh core
- 如需美化 JSON 或控制排序：
  - --list-json-pretty
  - --list-sort=alpha|none（默认 alpha）
  - --list-sort-case（大小写敏感）

更多细节见 docs/fafafa.core.test.md → 章节「Runner 环境变量与退出码策略」。

### SIMD QEMU 链路（推荐配置）

- 适用动作：
  - `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-nonx86-evidence`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-cpuinfo-nonx86-evidence`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh qemu-nonx86-experimental-asm`
  - `bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict`（配合 `SIMD_GATE_QEMU_NONX86_EVIDENCE=1` 与 `SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1`）
- 构建策略环境变量：
  - `SIMD_QEMU_BUILD_POLICY=if-missing`（默认，推荐）：仅当本地镜像不存在时构建，降低外部 registry 抖动影响
  - `SIMD_QEMU_BUILD_POLICY=always`：每次都重建镜像，适合强制冷启动验证
  - `SIMD_QEMU_BUILD_POLICY=skip`：跳过构建，要求本地镜像已存在

Linux/macOS 示例：

```bash
# 推荐：主线 gate / qemu 证据链路
SIMD_QEMU_BUILD_POLICY=if-missing \
SIMD_GATE_QEMU_NONX86_EVIDENCE=1 \
SIMD_GATE_QEMU_CPUINFO_NONX86_EVIDENCE=1 \
bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict

# CPUInfo 非 x86 专项（与 simd 主链拆分执行）
SIMD_QEMU_BUILD_POLICY=if-missing \
bash tests/fafafa.core.simd/BuildOrTest.sh qemu-cpuinfo-nonx86-evidence

# 说明：`cpuinfo-*` 的 QEMU 场景现在会在 runner 内部显式启用
# `SIMD_CPUINFO_RUNTIME_COPY=1`，并使用 target-specific `bin/<cpu>-<os>` /
# `lib/<cpu>-<os>`，避免 bind-mount 直执行导致的 `Text file busy` / 产物互踩。

# 真 asm 工具链专项（compiler-ready）
SIMD_QEMU_BUILD_POLICY=if-missing \
SIMD_QEMU_ENABLE_BACKEND_ASM=1 \
SIMD_QEMU_BACKEND_ASM_PROBE_MODE=0 \
SIMD_QEMU_PLATFORMS='linux/arm64 linux/riscv64' \
SIMD_QEMU_EXPERIMENTAL_ARM64_COMPILER_DEFINE='-dFAFAFA_SIMD_NEON_ASM_COMPILER_READY' \
SIMD_QEMU_EXPERIMENTAL_RISCV64_COMPILER_DEFINE='-dFAFAFA_SIMD_RISCVV_ASM_COMPILER_READY' \
bash tests/fafafa.core.simd/BuildOrTest.sh qemu-nonx86-experimental-asm

# 推荐紧跟 fresh lane 做基线与 blocker 报告
bash tests/fafafa.core.simd/BuildOrTest.sh qemu-experimental-baseline-check --latest
bash tests/fafafa.core.simd/BuildOrTest.sh qemu-experimental-report --latest

# 真机 non-x86 native evidence（只能在 arm64/riscv64 原生主机上跑）
bash tests/fafafa.core.simd/BuildOrTest.sh native-evidence

# collector 会先跑 DispatchAPI/PublicAbi，并在 suite 可见时继续采
# TTestCase_NonX86IEEE754 与 TTestCase_NonX86BackendParity；
# 若某个 suite 不在当前构建中，会在 summary 里显式标记 SKIP。
# 每个 native artifact 还会附带 `environment.txt` 与 `source_revision.txt`，
# 用于记录 host/FPC/backend 以及 `git_commit/git_ref_hint` 来源锚点。
#
# GitHub Actions:
# - ARM64 NEON: `.github/workflows/simd-arm64-neon-evidence.yml`（`workflow_dispatch` + `workflow_call`；hosted `ubuntu-24.04-arm`，nightly closeout 会复用）
# - RISCVV: `.github/workflows/simd-riscvv-native-evidence.yml`（`workflow_dispatch` + `workflow_call`；需要 self-hosted `Linux+riscv64` runner）
#
# 注意：`riscvv` 这条 lane 需要两层条件同时满足：
# 1. workflow 已在 default branch 注册；如果没有，`gh workflow run simd-riscvv-native-evidence.yml --ref <branch>` 会返回 `404`，
#    helper 会明确诊断成 `Workflow is not registered on GitHub Actions`。
# 2. repo 里还必须有匹配标签的 self-hosted runner；截至 2026-04-06，
#    `gh api repos/dtamade/fafafa.core/actions/runners` 仍返回 `{"total_count":0,"runners":[]}`，
#    helper 会对 queued run fail-close 成 `No matching self-hosted runner available for labels: self-hosted, Linux, riscv64`。

# 若要显式跑 backend-asm / direct-fpc 入口
SIMD_NATIVE_EVIDENCE_RUNNER=direct-fpc \
SIMD_NATIVE_EVIDENCE_ENABLE_BACKEND_ASM=1 \
bash tests/fafafa.core.simd/BuildOrTest.sh native-evidence riscvv

# 若本地已配置 gh，并且仓库有对应 native runner，可直接 dispatch/download
# backend 支持 neon / riscvv；默认 dispatch 会先检查本地 worktree 干净且 remote ref 与本地一致。
bash tests/fafafa.core.simd/BuildOrTest.sh native-evidence-via-gh neon
bash tests/fafafa.core.simd/BuildOrTest.sh native-evidence-via-gh riscvv

# 若已知现成 run-id，可复用旧 run；这条旁路只做 download，不会再触发 git hygiene / ref 一致性拒绝
bash tests/fafafa.core.simd/BuildOrTest.sh native-evidence-via-gh neon 12345678901
# helper 下载成功后会输出 `summary.md` / `dispatch_publicabi.log`，以及存在时的 `source_revision.txt` 路径
# 若要把复用 run 的源码来源锚死到指定 commit/ref，可额外设置：
# `SIMD_NATIVE_EVIDENCE_EXPECT_COMMIT`、`SIMD_NATIVE_EVIDENCE_EXPECT_REF`、`SIMD_NATIVE_EVIDENCE_REQUIRE_SOURCE_REVISION=1`

# restore-nightly-evidence 的输入应是原始 artifact 目录（例如 `simd-linux-evidence`、
# `simd-windows-b07-evidence`、可选 `simd-arm64-neon-evidence` / `simd-riscvv-native-evidence`），
# 不是聚合后的 `simd-freeze-audit` 包。
#
# 若已从 nightly workflow 下载 linux/windows/native artifacts，可先恢复 canonical logs/
# 再继续本地 freeze-status / win-closeout-finalize 复验
bash tests/fafafa.core.simd/BuildOrTest.sh restore-nightly-evidence \
  /tmp/simd-linux-evidence \
  /tmp/simd-windows-b07-evidence \
  /tmp/simd-arm64-neon-evidence

# restore helper 会保留 gate_summary.* / windows_b07_gate.log 的原始 mtime，
# 这样 freeze-status 仍按下载证据自身的时间判 freshness，不会把本地 restore 时刻误算成 fresh。
```

### 一键脚本

- Windows（PowerShell）：`scripts/run-tests-ci.ps1`（默认 --ci --fail-on-skip --top-slowest=5，自动设置报告默认路径）
- Linux/macOS（Bash）：`scripts/run-tests-ci.sh`（同上）

### 可选运行 LockFree 示例（严格工厂 demo）

- PowerShell：scripts\run-tests-ci.ps1 -IncludeLockfreeExamples
- Bash：INCLUDE_LOCKFREE_EXAMPLES=1 ./scripts/run-tests-ci.sh

说明：

- 该选项会调用 examples/fafafa.core.lockfree/BuildOrRun.\* run，构建并运行 example + bench + strict demo
- 默认关闭，建议按需触发以控制 CI 时长

- 在 GitHub Actions 中可直接调用上述脚本，或内联命令行

#### GitHub Actions 示例（启用 LockFree 示例）

- Windows（PowerShell）

```yaml
jobs:
  tests-win:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Lazarus (choco)
        run: choco install lazarus -y
      - name: Run tests + lockfree examples
        shell: pwsh
        run: |
          ./scripts/run-tests-ci.ps1 -IncludeLockfreeExamples
```

- Linux（Bash）

```yaml
jobs:
  tests-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install FPC/Lazarus (apt)
        run: |
          sudo apt-get update
          sudo apt-get install -y fp-compiler lazarus
      - name: Run tests + lockfree examples
        env:
          INCLUDE_LOCKFREE_EXAMPLES: 1
        run: |
          chmod +x scripts/run-tests-ci.sh
          ./scripts/run-tests-ci.sh
```

## Linux（最小化）

- 脚本：scripts/test-fs-only.sh
- 依赖安装：apt 安装 fp-compiler 和 lazarus（或替换为项目自定义安装）
- 工作流示例：.github/workflows/fs-tests-linux.yml

## 矩阵工作流（Windows + Linux）

- 单一工作流：.github/workflows/fs-tests-matrix.yml
- 策略：matrix.os = [windows-latest, ubuntu-latest]；fail-fast=false
- 自动选择平台对应脚本（.bat/.sh）

## 单平台工作流（手动触发）

- Windows 手动：.github/workflows/fs-tests.yml（名称：FS Tests (Windows Manual)）
- Linux 手动：.github/workflows/fs-tests-linux.yml（名称：FS Tests (Linux Manual)）
- 触发方式：在 GitHub 仓库 Actions 选项卡中选择对应工作流 → Run workflow
- 适用场景：定位平台特异问题、复现单平台不稳定用例、临时验证环境变化

此仓库包含 GitHub Actions 工作流，自动执行以下检查：

- Windows 下安装 Lazarus/FPC
- 构建 tests 与 example（Release 模式）
- 校验 0 warnings/hints（如出现则失败）
- 运行 tests/example（命令行自动结束）
- 生成并校验 docs/LOCKFREE_API.md 是否最新

工作流文件：`.github/workflows/lockfree-ci.yml`

本地手动执行步骤：

```bash
# 构建测试
lazbuild --build-mode=Release tests/fafafa.core.lockfree/tests_lockfree.lpi

# 构建示例
lazbuild --build-mode=Release examples/fafafa.core.lockfree/example_lockfree.lpi

# 运行
./bin/tests_lockfree.exe
./bin/example_lockfree.exe

# 生成 API 文档
python scripts/generate_lockfree_api_md.py
```

## settings.inc 单源守护

- 原则：仅维护 src/fafafa.core.settings.inc 为单一真源
- 发布：在打包/发布前执行同步脚本镜像到 release/src

示例（Windows CI/本地）：

```bat
call scripts\sync_settings_inc.bat || exit /b 1
```

- 工程检查：所有 LPI/LPR 的 SearchPaths 应包含 ../../src 以便 {$I fafafa.core.settings.inc}

- 校验（可选强制）：同步后做一次一致性校验，防止遗漏

Windows（PowerShell）：

```
$src = "src/fafafa.core.settings.inc"
$dst = "release/src/fafafa.core.settings.inc"
if (-not (Test-Path $dst)) { Write-Error "Missing $dst"; exit 1 }
if ((Get-FileHash $src).Hash -ne (Get-FileHash $dst).Hash) { Write-Error "settings.inc not synced"; exit 1 }
```

Linux（Bash）：

```
if [ ! -f release/src/fafafa.core.settings.inc ]; then echo "Missing release/src/fafafa.core.settings.inc" >&2; exit 1; fi
if ! cmp -s src/fafafa.core.settings.inc release/src/fafafa.core.settings.inc; then echo "settings.inc not synced" >&2; exit 1; fi
```

## Perf Summary（从日志生成摘要）

- 工作流：`.github/workflows/perf-summary.yml`
- 作用：不在 CI 中跑基准，仅对仓库中的 CSV 日志执行归一化与摘要生成
- 触发：
  - 手动 workflow_dispatch
  - 或当以下路径变更时自动触发：
    - `tests/fafafa.core.lockfree/logs/*.csv`
    - `scripts/normalize_micro_csv.ps1`
    - `scripts/summarize_quick_matrix.ps1`
- 产物（artifacts）：
  - `report/latest/*.md`
  - `tests/fafafa.core.lockfree/logs/*_normalized.csv`
- 本地快速路径：
  - `tests/fafafa.core.lockfree/Run_Micro_BatchMatrix_Quick.bat`（脚本末尾已自动归一化 + 摘要）

附注：HashMap 选型指南请参阅 docs/topics/lockfree/README_LOCKFREE.md（开放寻址 OA 与分离链接 MM 的差异与选择）。
