# SIMD Windows 实机后回填模板（Batch 模板）

更新时间：2026-03-20

## 使用方式

1. 在 Windows 实机执行：
   - `tests\fafafa.core.simd\buildOrTest.bat evidence-win-verify`
2. 在 Linux/macOS（或 WSL）先回灌 fail-close cross gate：
   - `FAFAFA_BUILD_MODE=Release SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
3. 再执行一键收口：
   - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize <BATCH_ID>`
4. 如只想重生摘要而不执行 freeze/apply，才单独使用：
   - `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence`
5. 打开摘要文件（默认）：
   - `tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md`
6. 按下方模板替换占位符后，回填到对应文档。

可选（先打印三命令闭环）:
- `bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-3cmd <BATCH_ID>`

说明：
- native batch evidence 不会生成 fresh `gate_summary.md/json`，所以不能从 `evidence-win-verify` 直接跳到 `finalize-win-evidence` 或 `win-closeout-finalize`。
- 真正决定 `cross-ready=True` 的是 Linux/WSL 侧这条 fail-close cross gate。

占位符说明：
- `<WINDOWS_DATE>`：Windows 实机执行日期（例如 `2026-02-10`）
- `<EVIDENCE_LOG_PATH>`：证据日志路径（通常 `tests/fafafa.core.simd/logs/windows_b07_gate.log`）
- `<CLOSEOUT_SUMMARY_PATH>`：摘要路径（通常 `tests/fafafa.core.simd/logs/windows_b07_closeout_summary.md`）

---

## 1) roadmap 回填模板

目标文件：`docs/plans/2026-02-09-simd-unblock-closeout-roadmap.md`

```markdown
### Windows 实机证据（<WINDOWS_DATE>）

- 状态：已采集，待 freeze-status 复核
- Evidence Log: `<EVIDENCE_LOG_PATH>`
- Closeout Summary: `<CLOSEOUT_SUMMARY_PATH>`
- 结论：仅当 `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status` 返回 `ready=True` 时，才能将 P0 改为已关闭。
```

---

## 2) completeness matrix 回填模板

目标文件：`tests/fafafa.core.simd/docs/simd_completeness_matrix.md`

```markdown
- Windows 实机证据：已归档（<WINDOWS_DATE>）
  - Log: `<EVIDENCE_LOG_PATH>`
  - Summary: `<CLOSEOUT_SUMMARY_PATH>`
  - 验证：`verify_windows_b07_evidence` PASS
```

---

## 3) progress 回填模板

目标文件：`progress.md`

```markdown
### 批次
- `<BATCH_ID>`

### 执行动作
- 在 Windows 实机完成 `buildOrTest.bat evidence-win-verify`。
- 生成并归档收口摘要：`finalize-win-evidence`。
- 回填 roadmap / matrix / progress，关闭跨平台证据缺口。

### 命令与结果
| Command | Result |
|---|---|
| `tests\fafafa.core.simd\buildOrTest.bat evidence-win-verify` | PASS |
| `bash tests/fafafa.core.simd/BuildOrTest.sh finalize-win-evidence` | PASS |

### 关键证据
- Log: `<EVIDENCE_LOG_PATH>`
- Summary: `<CLOSEOUT_SUMMARY_PATH>`

### 阶段状态
- 以 freeze-status 为准：仅 `ready=True` 视为跨平台冻结条件满足。
```

---

## 4) task_plan 回填模板

目标文件：`task_plan.md`

```markdown
### Batch <BATCH_DONE_ID>（阶段完成）
- [x] 形成 Windows 实机后回填模板并固化到计划文档
- [x] 明确 roadmap/matrix/progress 的标准回填块
- [x] 将下一批聚焦为“实机执行 + 冻结收口”

### Batch <BATCH_NEXT_ID>（下一步）
- [ ] Windows 实机执行 `buildOrTest.bat evidence-win-verify` 并归档日志
- [ ] 执行 `finalize-win-evidence` 生成收口摘要
- [ ] 回填 roadmap/matrix/progress 并更新最终跨平台冻结结论
```

---

## 5) findings 回填模板

目标文件：`findings.md`

```markdown
## Batch <BATCH_ID> Findings

### 变更
- 完成 Windows 实机证据链执行与归档。
- 生成 `windows_b07_closeout_summary.md`，形成可审计证据摘要。

### 验证
- `buildOrTest.bat evidence-win-verify` ✅
- `finalize-win-evidence` ✅

### 结论
- 仅当 `bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status` 返回 `ready=True` 时，才可判定“跨平台冻结条件满足、阻塞清零”。
```

## 6) 自动回填（推荐）

如果希望减少手工回填，可直接使用自动回填脚本：

- 仅生成片段（不改文件）：
  - `bash tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh`
- 自动回填目标文档（幂等）：
  - `bash tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh --apply`

注意：
- 指定批次号后自动回填（推荐）：
  - `bash tests/fafafa.core.simd/apply_windows_b07_closeout_updates.sh --apply --batch-id <BATCH_ID>`
- `--apply` 默认拒绝 simulated summary，避免误把预演结果写入正式文档。
- 仅测试脚本时可显式加 `--allow-simulated`（且会跳过结构化状态置 `[x]`）。
