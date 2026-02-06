# 0 Warnings/Hints：FS + SIMD 构建洁净化（Design）

## 背景 / 问题陈述
在 Linux 下运行 `STOP_ON_FAIL=1 bash tests/run_all_tests.sh` 时，回归在 `fafafa.core.fs` 模块停止：

- `tests/fafafa.core.fs/BuildOrTest.sh` 的 `check_build_log` 规则要求：**构建日志中来自 `src/` 的 Warning/Hint 必须为 0**。
- 当前构建 `tests/fafafa.core.fs/tests_fs.lpi` 会触发多处 Hint/Warning（包括但不限于 atomic、simd、math、os、fs 子单元），导致模块失败。
- 同样，`tests/fafafa.core.simd/BuildOrTest.sh check` 也要求 SIMD 单元 0 Warning/Hint，目前也会失败。

目标不是“压制输出”，而是让受严格检查的模块在现有工具链（FPC 3.3.1 / Lazarus lazbuild）下实现 **真正的 0 Warning/Hint**（必要时允许对已知无害的低层警告做 *最小、明确* 的抑制）。

## 约束
- 不拆分 `fafafa.core.collections` 的大单元（只允许在原单元内优化/修复）。
- 保持公共 API 稳定：不做破坏性签名变更。
- 优先修复真实缺陷（未初始化结果、未初始化局部变量、可移植性问题），仅对已知无害/难以修复的低层告警做局部 `{$WARN ... OFF}`。

## 方案选项（Brainstorming）
### 方案 A：放宽/移除模块脚本的 Warning/Hint 检查
- 优点：最快通过测试。
- 缺点：违背仓库“0 warnings/hints 即失败”的 CI 约束；会掩盖真实问题与回归风险。
- 结论：不推荐。

### 方案 B：大范围关闭编译器 Warning/Hint（项目级/全局）
- 优点：实现简单。
- 缺点：全局掩盖问题；不符合“洁净构建”的质量目标；后续维护成本高。
- 结论：不推荐。

### 方案 C（推荐）：逐项消除 Warning/Hint
- 做法：
  - 对“控制流分析看不懂”的初始化（如 `Move/FillChar/SetLength` 写入 `Result`、系统调用填充 record 等）补充显式初始化，消除 5093/5060/5057/5091。
  - 修复可移植性告警（指针/整数转换，避免 signed 比较），消除 4055/4082。
  - 移除未使用 `uses`，消除 5023。
  - 对 SIMD 内联汇编的 7121（operand-size 预期差异）：
    - 优先改写为不触发警告的等价指令（如 `movsd` → `vmovsd` 或 `movlpd`、直接写 `[result]` 等）；
    - 若仍存在且确认无害，则在 **具体单元内** 局部 `{$WARN 7121 OFF}`（避免全局关闭）。
- 优点：与 CI 目标一致；减少潜在未定义行为；对其他模块也有正向收益。
- 风险：涉及低层代码（SIMD/FS/OS），需要分批验证，避免引入行为回归。

## 影响范围（初始清单）
以 `tests/fafafa.core.fs` 构建日志为基准，优先清理以下单元：
- `src/fafafa.core.simd.avx2.pas` / `src/fafafa.core.simd.sse2.pas`（7121/5060）
- `src/fafafa.core.simd.memutils.pas`（5024）
- `src/fafafa.core.atomic.pas`（5024/5028）
- `src/fafafa.core.math.internal.pas`、`src/fafafa.core.math.dispatch.pas`（5060/5057/5023）
- `src/fafafa.core.os.unix.inc`（5057）
- `src/fafafa.core.env.pas`（3124）
- `src/fafafa.core.fs.*`（5093/4055/4082/5023/5026/5091）

## 验证策略
- 快速回归：`bash tests/fafafa.core.simd/BuildOrTest.sh check`、`bash tests/fafafa.core.fs/BuildOrTest.sh check`
- 逐步推进：每批修复后回跑上述 check；通过后再跑 `STOP_ON_FAIL=1 bash tests/run_all_tests.sh` 寻找下一个失败模块。

