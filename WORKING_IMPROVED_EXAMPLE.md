# 当前工作状态

## 最后更新
- 时间：2026-01-20 14:30
- 当前阶段：Layer 1（atomic + sync.*）Gate 0 - 工程基础设施修复
- 工作方式：主线单 Agent 顺序推进

## 当前任务（正在做）
- **L1-G0-01**：清理 src/ 目录的构建产物（127 个 *.o/*.ppu）
  - 状态：进行中 🔄
  - 开始时间：2026-01-20 14:00
  - 预计完成：今天
  - 阻塞问题：无

## 下一步行动（按优先级）
1. 完成 L1-G0-01 的验证（`find src -name '*.o' -o -name '*.ppu' | wc -l` 必须为 0）
2. 开始 L1-G0-02：补齐 Layer1 tests 的 Linux 入口脚本
3. 修正 L1-G0-03：tests/fafafa.core.sync.barrier/buildOrTest.sh 的假绿问题

## 最近完成的工作
- [x] L1-G0-00：生成现状清单 ✅ 2026-01-20 13:00
  - 扫描了 106 个源码文件、46 个测试目录
  - 生成了详细的现状快照表格
  - 文档：见本文件"现状快照"部分

## 已知问题（Top 3）
1. **P0**：src/ 有 127 个构建产物（违反工程规范）→ L1-G0-01 处理中
2. **P0**：Linux 测试脚本缺失导致回归不可信 → L1-G0-02 待处理
3. **P0**：Windows 测试脚本有 pause 会卡住 CI → L1-G0-04 待处理

完整问题列表：见 [Layer 1 审查摘要](#layer-1-审查摘要2026-01-20)

## 关键文档链接
- 📋 [完整任务清单](#layer-1-开发任务清单单-agent按-gate-顺序执行)（Gate 0-4，共 30+ 任务）
- 📊 [现状快照](#现状快照2026-01-20-实扫用于对照改动)（测试/示例目录覆盖表）
- 🔧 [脚本模板](#脚本与工程模板复制粘贴减少-claude-写错)（BuildOrTest.sh/bat）
- 📖 [执行规范](#执行规范给-claude-code用来防粗心)（硬规则 + 验证步骤）

## 进度概览
```
Gate 0（工程基础）: ▓▓░░░░░░░░ 20% (2/9 完成)
Gate 1（Atomic）:   ░░░░░░░░░░  0% (0/2 完成)
Gate 2（Sync）:     ░░░░░░░░░░  0% (0/12 完成)
Gate 3（Named）:    ░░░░░░░░░░  0% (0/3 完成)
Gate 4（集成）:     ░░░░░░░░░░  0% (0/2 完成)
```

---

## Layer 1 总体目标（Definition of Done）
- [ ] src/ 中 *.o/*.ppu 数量为 0
- [ ] Linux/macOS：Layer1 测试可被 run_all_tests.sh 发现并完整运行
- [ ] Windows：run_all_tests.bat 可无交互运行
- [ ] Layer1 examples：每个目录都有 BuildOrRun.sh + BuildOrRun.bat
- [ ] Layer1 benchmarks：脚本默认无交互，结果保存到 results/
- [ ] 关键语义文档齐全

---

<details>
<summary>📊 Layer 1 审查摘要（2026-01-20）- 点击展开</summary>

### 范围与规模
- `src/`：Layer1 源码 106 个 .pas（atomic + sync.*）
- `tests/`：Layer1 测试目录 46 个
- `examples/`：Layer1 示例目录 13 个
- `benchmarks/`：Layer1 基准目录 4 个
- `docs/`：Layer1 文档文件 31 个

### 关键风险（必须先解决）
**P0：回归不可信 / 漏测 / 自动化阻塞**
- src/ 存在 127 个 *.o/*.ppu（违反工程规范）
- Linux/macOS：run_all_tests.sh 只发现 BuildOrTest.sh，但多数 sync 测试目录缺此脚本
- Windows：多处 BuildOrTest.bat 含 pause，会导致 CI 挂死
- tests/fafafa.core.sync.barrier/buildOrTest.sh 使用 || true 吞掉失败

**P1：工程规范不一致**
- Layer1 examples 缺 BuildOrRun.sh（多数只有 .bat）
- Layer1 tests 中 16 个目录缺 .lpi
- 多个 .lpi 的输出目录配置不规范（未输出到 bin/）

</details>

<details>
<summary>🔧 快速扫描命令 - 点击展开</summary>

### Linux/macOS（bash）
```bash
# 1) src 是否被污染
find src -name '*.o' -o -name '*.ppu' | wc -l

# 2) Layer1 tests: 哪些目录缺 BuildOrTest.sh
find tests -maxdepth 1 -type d \( -name 'fafafa.core.atomic*' -o -name 'fafafa.core.sync*' \) -print | sort | \
while read -r d; do
  has_lpi="$(find "$d" -maxdepth 1 -name '*.lpi' -print -quit)"
  if [ -n "$has_lpi" ] && [ ! -f "$d/BuildOrTest.sh" ] && [ ! -f "$d/BuildAndTest.sh" ]; then
    echo "$d"
  fi
done

# 3) 哪些脚本吞失败/交互
rg -n "\\|\\|\\s*true\\b" tests/fafafa.core.atomic* tests/fafafa.core.sync* --glob '*.sh' || true
rg -n "^\\s*(read\\b|pause\\b)" tests/fafafa.core.atomic* tests/fafafa.core.sync* --glob '*.{sh,bat}' || true
```

### Windows（PowerShell）
```powershell
# 1) src 是否被污染
Get-ChildItem -Recurse -Path src -Include *.o,*.ppu | Measure-Object | % Count

# 2) pause 阻塞点
Select-String -Path tests\fafafa.core.atomic*\*.bat, tests\fafafa.core.sync*\*.bat -Pattern '^\s*pause\b'
```

</details>

---

## Layer 1 开发任务清单（单 Agent，按 Gate 顺序执行）

### Gate 0：让工程与回归链"可信"（P0）

- [x] **L1-G0-00**：生成现状清单 ✅ 2026-01-20
- [ ] **L1-G0-01**：清理并阻止 src/ 产物回流 🔄 进行中
- [ ] **L1-G0-02**：补齐 Layer1 tests 的 Linux 入口脚本（31 个目录）
- [ ] **L1-G0-03**：修正"会假绿"的测试脚本
- [ ] **L1-G0-04**：让 Windows 回归可无交互运行（9 个脚本）
- [ ] **L1-G0-05**：补齐 Layer1 tests 中缺 .lpi 的目录（16 个）
- [ ] **L1-G0-06**：清理 Layer1 测试目录"重复/嵌套模块"
- [ ] **L1-G0-07**：对齐 Layer1 的 .lpi 输出目录（30+ 个文件）
- [ ] **L1-G0-08**：全面扫描并消除脚本的交互/吞失败
- [ ] **L1-G0-09**：补齐 .gitignore（防止产物回流）

<details>
<summary>Gate 1-4 任务清单（点击展开）</summary>

### Gate 1：Atomic 模块（P1）
- [ ] **L1-A-01**：性能基线与脚本无交互
- [ ] **L1-A-02**：示例工程化

### Gate 2：Sync 模块（P1）
- [ ] **L1-S-00** 到 **L1-S-12**（12 个任务）

### Gate 3：Sync.named（P2）
- [ ] **L1-N-01** 到 **L1-N-03**（3 个任务）

### Gate 4：最终集成回归（P0）
- [ ] **L1-F-01**：Layer1 过滤回归
- [ ] **L1-F-02**：全量回归（发布前）

完整任务详情见原 WORKING.md 文件。

</details>

---

<details>
<summary>📋 现状快照（2026-01-20 实扫）- 点击展开</summary>

### Layer1 tests：入口脚本覆盖（按目录）

| tests 目录 | .lpi | BuildOrTest.sh | BuildOrTest.bat | 下一步动作 |
|---|---:|---:|---:|---|
| tests/fafafa.core.atomic/ | ✅ | ✅ | ✅ | 去 pause（L1-G0-04） |
| tests/fafafa.core.sync/ | ✅ | ✅ | ✅ | 去 pause（L1-G0-04） |
| tests/fafafa.core.sync.barrier/ | ✅ | 改名 + 去 \|\| true | 改名 | L1-G0-03 + L1-G0-02 |
| ... | ... | ... | ... | ... |

（完整表格见原 WORKING.md）

### .lpi 输出异常清单（必须修复）

tests（30+ 个文件）：
- tests/fafafa.core.sync.barrier/fafafa.core.sync.barrier.test.lpi
- tests/fafafa.core.sync.builder/fafafa.core.sync.builder.test.lpi
- ...

（完整清单见原 WORKING.md）

</details>

<details>
<summary>🔧 脚本与工程模板 - 点击展开</summary>

### BuildOrTest.sh（tests 模块推荐模板）
```bash
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

ACTION="${1:-test}"
PROJECT_LPI="${PROJECT_LPI:-<REPLACE_ME>.lpi}"
TEST_BIN="${TEST_BIN:-bin/<REPLACE_ME>}"

LAZBUILD_BIN="${LAZBUILD:-lazbuild}"

if ! command -v "${LAZBUILD_BIN}" >/dev/null 2>&1; then
  echo "[ERROR] lazbuild not found in PATH" >&2
  exit 1
fi

# Deterministic outputs
rm -rf ./bin ./lib/*-*/
mkdir -p ./bin ./lib

echo "[BUILD] ${LAZBUILD_BIN} --build-mode=Debug ${PROJECT_LPI}"
"${LAZBUILD_BIN}" --build-mode=Debug "${PROJECT_LPI}"

if [[ "${ACTION}" == "test" || "${ACTION}" == "run" ]]; then
  echo "[RUN] ${TEST_BIN}"
  if [[ -x "${TEST_BIN}" ]]; then
    "${TEST_BIN}" --all --format=plain
  elif [[ -x "${TEST_BIN}.exe" ]]; then
    "${TEST_BIN}.exe" --all --format=plain
  else
    echo "[ERROR] test executable not found: ${TEST_BIN}[.exe]" >&2
    exit 100
  fi
else
  echo "[INFO] build-only mode (${ACTION})"
fi
```

（更多模板见原 WORKING.md）

</details>

<details>
<summary>📖 执行规范（给 Claude Code）- 点击展开</summary>

### 硬规则（违反就会返工）
1. **一次只做一个 Task ID**
2. **默认无交互**：脚本不得 pause/read 阻塞
3. **禁止吞失败**：不得使用 || true
4. **输出目录铁律**：.lpi 必须输出到 bin/ + lib/$(TargetCPU)-$(TargetOS)/
5. **禁止提交构建产物**
6. **脚本命名必须精确**：BuildOrTest.sh/bat（大小写敏感）

### 统一任务完成检查
- git diff --name-only：确认只改了任务范围内的文件
- bash tests/run_all_tests.sh <module>：跑被改动的模块
- find src -name '*.o' -o -name '*.ppu' | wc -l：必须为 0

（完整规范见原 WORKING.md）

</details>
