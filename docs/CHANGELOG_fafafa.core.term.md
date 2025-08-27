# Changelog – fafafa.core.term

## [Unreleased]

### Added
- Helper APIs: `term_mouse_sgr_enable` / `term_mouse_drag_enable` / `term_focus_enable`（含 aTerm 重载）
- Tests: 协议开关 ANSI 输出断言（焦点/粘贴/同步输出），Windows Quick Edit 守卫黑盒；事件收集边界（连续移动尾合并、跨批次、长序列、容量裁剪）
- Example: `examples/fafafa.core.term/05_input_best_practices.lpr`
  - PeekKey / FlushInput 演示
  - 鼠标滚轮 + 修饰键、焦点、尺寸变更事件打印
  - try/finally 关闭 mouse/drag/SGR/focus，防止终端残留
  - Unix 支持 `--esc-timeout=XX` 动态调参
- Unix 解析健壮性：
  - 数字参数限长（MAX_DIGITS），避免异常超长
  - SGR 鼠标解析增加边界与短超时补读（EnsureNextByte）
  - 可配置超时接口：`term_unix_get_escape_timeout_ms` / `term_unix_set_escape_timeout_ms`
- 文档：
  - TERMINAL_LIBRARY_GUIDE.md 增加“输入最佳实践”“解析超时策略（Unix）”“终端差异与排查（含 Windows 专项与 Mermaid 示意图）”
  - fafafa.core.term.md 增补“粘贴存储治理的组合语义（auto_keep_last + max_bytes）”

### Changed
- 示例与文档推荐组合：SGR(1006) + 按钮/拖动(1002) + 焦点(1004) 的启用方式

### Fixed
- 粘贴存储：当开启 auto_keep_last 且追加新文本导致超出 max_bytes 时，若“新文本本身不超过上限”，优先仅保留该最新条
- ESC/CSI 半包导致的解析粘连，通过轻量超时补读避免影响后续输入



### 2025-08-22
- Paste 存储后端：behind-a-flag 引入 ring（环形）实现，可通过环境变量切换
  - 默认 legacy：数组存储 + 批量修剪
  - 可选 ring：环形存储，append/trim 均摊 O(1)
  - 开关：FAFAFA_TERM_PASTE_BACKEND=ring（或在运行时调用 term_paste_use_backend('ring')）
- 语义一致化：
  - term_paste_set_max_bytes 在 ring/legacy 下均“立即生效”（可能触发立刻回收）
  - 单条超过 max_bytes 的粘贴会被丢弃（最终存储为空），以严格满足上限
- 失败注入与诊断：
  - 新增测试用失败注入：FAFAFA_TERM_FORCE_PLATFORM_FAIL=1 时，term_default_create_or_get 返回失败
  - term_last_error 在上述场景写入诊断信息（例如 'forced platform creation failure'）
- Windows 输出回退：
  - 可通过 FAFAFA_TERM_WIN_FORCE_WRITEFILE=1 强制使用 WriteFile（默认 WriteConsoleW）
