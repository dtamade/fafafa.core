# Windows B07 证据闭环 Runbook（cross-ready）

更新时间：2026-03-06

## 目标

- 将 `freeze-status` 从 `cross-ready=False` 收口到 `cross-ready=True`。
- 完成 Windows 实机证据链归档并通过验证。

## 全局约束（Release-only）

- Linux/Git Bash/WSL 侧命令统一前缀：`FAFAFA_BUILD_MODE=Release`
- Windows PowerShell 先设置：`$env:FAFAFA_BUILD_MODE = 'Release'`
- Gate 回灌阶段启用 fail-close：`SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1`

## 推荐顺序（主路径）

优先走单入口 GH 路径：

1. GH/额度预检（Git Bash / WSL）  
   `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight`
2. 一条命令完成 dispatch + 下载 + 校验 + finalize（Git Bash / WSL）  
   `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-via-gh SIMD-YYYYMMDD-152`
3. 最终冻结确认（Git Bash / WSL）  
   `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`

说明：
- `win-evidence-via-gh` 会把批次快照写到 `tests/fafafa.core.simd/logs/windows-closeout/<batch-id>/`，并同步回写 canonical `logs/` 指针，方便 `freeze-status` 默认入口直接消费。
- `win-evidence-via-gh` 只消费远端 ref。如果本地还有未提交或未推送的 closeout 修复，请先提交并推到目标 ref；否则脚本会直接拒绝 dispatch，避免浪费一轮 Windows runner。

## 手工 Windows 实机路径（兜底）

1. GH/额度预检（Git Bash / WSL）  
   `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-preflight`
2. 采集 + 校验（Windows PowerShell）  
   `$env:FAFAFA_BUILD_MODE = 'Release'`  
   `tests\fafafa.core.simd\buildOrTest.bat evidence-win-verify`
3. 一键收口（Git Bash / WSL）  
   `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize SIMD-YYYYMMDD-152`
4. 最终冻结确认（Git Bash / WSL）  
   `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`

## 无 Windows 实机时（GH Windows Runner 路径）

1. 直接走 GH 收集 + 下载 + 校验 + closeout  
   `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-evidence-via-gh SIMD-YYYYMMDD-152`
2. 最终冻结确认（Git Bash / WSL）  
   `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`

说明：
- `win-evidence-via-gh` 内部会先执行 `win-evidence-preflight`（可通过 `SIMD_WIN_EVIDENCE_PREFLIGHT=0` 关闭）。
- 该路径依赖 `gh` 已登录，且仓库存在可用 workflow：`.github/workflows/simd-windows-b07-evidence.yml`。

## 快捷入口

- 输出“复制即跑”的 3 命令：
  `bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-3cmd SIMD-YYYYMMDD-152`
- 输出文档回填片段（会按实时 verifier 结果标注“已归档/待补齐”）：
  `bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-snippets`
- 注意：`apply_windows_b07_closeout_updates.sh --apply` 在 Windows 证据校验失败时会拒绝写入“已完成”状态。

## 分步兜底

当第 2 步失败需要拆分诊断时，按顺序执行：

0. `powershell -NoProfile -Command "$env:FAFAFA_BUILD_MODE='Release'"`
1. `tests\fafafa.core.simd\buildOrTest.bat evidence-win`
2. `tests\fafafa.core.simd\buildOrTest.bat verify-win-evidence`
3. `FAFAFA_BUILD_MODE=Release SIMD_GATE_REQUIRE_WINDOWS_EVIDENCE=1 bash tests/fafafa.core.simd/BuildOrTest.sh gate`
4. `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh win-closeout-finalize SIMD-YYYYMMDD-152`
5. `FAFAFA_BUILD_MODE=Release bash tests/fafafa.core.simd/BuildOrTest.sh freeze-status`

## 通过标准

- `tests/fafafa.core.simd/logs/windows_b07_gate.log` 存在且新鲜。
- `verify_windows_b07_evidence` 校验通过。
- `freeze-status` 显示：
  - `ready=True`
  - `mainline-ready=True`
  - `cross-ready=True`

## 常见阻塞

- `RECENT_BILLING_BLOCK`：先恢复 GitHub Billing/额度，再从预检重试。
- `windows_b07_gate.log` 过期：重新执行 `evidence-win-verify`。
- B07 关键头缺失（`Source/HostOS/CmdVer/Working dir`）：必须重新采集真实 Windows 日志，旧日志不可补写。
- closeout summary 与 verifier 不一致：执行 `win-closeout-finalize` 重新生成并应用。
- `win-closeout-snippets` 显示“待补齐”：说明实时 `verify_windows_b07_evidence` 未通过，需先完成 Windows 实机证据链。
