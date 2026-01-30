# Term Paste 最佳实践（治理与后端选择）

本分片汇总粘贴存储治理（limits/trim）与后端选择（legacy/ring）的推荐做法，供多文档引用。

## 启动期一次性设置（强烈推荐）
- 双限：term_paste_defaults(128, 1 shl 20) 或 term_paste_defaults_ex(128, 1 shl 20, 'tui')
- 目的：限制长期运行中的内存增长，提供稳定的回收行为
- 环境变量（仅在未显式设置时生效）：
  - FAFAFA_TERM_PASTE_KEEP_LAST
  - FAFAFA_TERM_PASTE_MAX_BYTES（支持 k/m/g 后缀）
  - FAFAFA_TERM_PASTE_TRIM_FASTPATH_DIV（默认 8）
  - 可禁用自动应用：FAFAFA_TERM_PASTE_DEFAULTS=off

## 组合策略与语义
- keep_last 与 max_bytes 可同时启用；任一触发即回收
- 当开启 auto_keep_last 且“新项字节数 ≤ max_bytes”，超出上限时优先“仅保留最新一条”
- 单条超限：若单条 > max_bytes，最终存储为空（严格满足上限）；需保留请提升上限或设为 0
- 统计：trim/clear 时总字节会同步维护；查询使用 term_paste_get_count/term_paste_get_total_bytes

## 后端选择（behind-a-flag）
- 默认 legacy（数组存储 + 批量修剪）
- 可选 ring（环形，append/trim 均摊 O(1)）：
  - 环境变量：FAFAFA_TERM_PASTE_BACKEND=ring
  - 运行时 API：term_paste_use_backend('ring')
  - 提示：避免在高并发期间频繁切换
- 立即生效：term_paste_set_max_bytes 在 legacy/ring 下均立即生效（可能触发立刻回收）

## 建议阈值（经验）
- CLI/一般交互：keep_last=64..128，max_bytes=512k..1m
- TUI/中等粘贴量：keep_last=128，max_bytes=1m
- 长驻/高峰场景：keep_last=128..256，max_bytes=1m..2m，trim_fastpath_div=4..8

## 微基准入口与解读
- 构建：tests/fafafa.core.term/benchmarks/build_benchmarks.bat
- 运行：bin/benchmark_paste_backends.exe [N]
- 解读：
  - ring 在大 N/频繁修剪时更稳定（append/trim 均摊 O(1)）
  - legacy 在大规模 trim_keep_last 场景可能出现较大重建开销

## 失败注入与诊断（测试/排障）
- 强制平台创建失败：FAFAFA_TERM_FORCE_PLATFORM_FAIL=1 → term_default_create_or_get 失败；term_last_error() 返回诊断
- Windows 输出回退：FAFAFA_TERM_WIN_FORCE_WRITEFILE=1 强制 WriteFile 路径（默认 WriteConsoleW）

## 引用
- 详解：docs/fafafa.core.term.md#paste-后端选择与推荐配置
- 微基准：docs/benchmarks.md#term-paste-backends-微基准legacy-vs-ring

