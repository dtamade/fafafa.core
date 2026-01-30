# CI for fafafa.core.lockfree
> 当前策略：CI 暂时不自动运行，仅保留手动触发（workflow_dispatch）。如需恢复自动触发，请将 matrix 工作流的 on: 改回 push/pull_request。


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
      - 'src/**'
      - 'tests/fafafa.core.fs/**'
      - 'scripts/test-fs-only.bat'
      - '.github/workflows/fs-tests.yml'
  pull_request:
    paths:
      - 'src/**'
      - 'tests/fafafa.core.fs/**'

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

### 一键脚本
- Windows（PowerShell）：`scripts/run-tests-ci.ps1`（默认 --ci --fail-on-skip --top-slowest=5，自动设置报告默认路径）
- Linux/macOS（Bash）：`scripts/run-tests-ci.sh`（同上）

### 可选运行 LockFree 示例（严格工厂 demo）
- PowerShell：scripts\run-tests-ci.ps1 -IncludeLockfreeExamples
- Bash：INCLUDE_LOCKFREE_EXAMPLES=1 ./scripts/run-tests-ci.sh

说明：
- 该选项会调用 examples/fafafa.core.lockfree/BuildOrRun.* run，构建并运行 example + bench + strict demo
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

