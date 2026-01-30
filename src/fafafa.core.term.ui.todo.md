# fafafa.core.term.ui 开发计划与进度

## 当前状态（2025-08-12）

### 模块现状总览
- 门面单元已存在：`src/fafafa.core.term.ui.pas`
  - 对外暴露 Facade：Render/HandleEvent 运行入口（termui_run/termui_run_node）、Surface 便捷操作（clear/goto/write/fill）、节点接口转出（IUiNode、TVBoxNode、THBoxNode、TPanelNode、TBannerNode、TStatusBarNode）。
- 底层 UI 依赖：`src/ui/`
  - `ui_app.pas`：事件循环、备用屏切换、鼠标启用、按需重绘（Invalidate）。
  - `ui_surface.pas`：双缓冲、全帧 diff 输出、0 基坐标 -> 终端 1 基坐标转换、填充/写入/矩形绘制、基础视图堆栈（PushView/PopView）。
  - `ui_node.pas`：简单布局与组件（栈式根、Banner、StatusBar、Panel、VBox/HBox）。
  - `ui_style.pas`：主题与样式（深/浅主题 token、简单的 Fg/Bg 应用/重置）。
- term 底层：`src/fafafa.core.term*.pas` 功能完整（事件、光标、颜色、备用屏、鼠标等）。
- Tests：已有 `tests/fafafa.core.term/`，暂无 `tests/fafafa.core.term.ui/`。
- Docs：暂无 `docs/fafafa.core.term.ui.md`。

### 已发现问题/潜在风险
1) ui_surface.pas 疑似代码残片
   - 在 `BufEnsureSize` 结束位置附近存在未闭合/错位的大括号与游离语句，需梳理结构并修复（见 80~105 行）。
2) TPanelNode.Render 暂时用 `'*'` 填充，便于观察范围；后续应切回可配置 `FCh`（默认空格）以符合 UI 语义。
3) 视图堆栈（Viewport + Origin）裁剪路径需覆盖所有写入 API；UiWrite/UiWriteLn 目前直写后端，建议统一走 BackBuffer + FrameEnd 以确保裁剪一致与最少输出。
4) 终端能力降级路径
   - 目前直接使用 24bit 颜色 API；需对 `term_support_ansi/term_support_color_24bit` 等能力探测后降级（改为 16/256 色或忽略）。
5) 事件循环退出策略
   - `UiAppRunNode` 里对 Q 键做了全局退出（demo 友好）；需要在文档中提示或提供可配置开关。
6) 编码/宽字符
   - facade 以 UnicodeString 写入，需确保底层 term_write 支持 UCS2/UTF-16 到终端的编码安全；Windows Terminal/ConHost 差异需在 term 层完成适配（项目已有 FAFAFA_TERM_INPUT_WIDE 宏）。

---

## 架构与设计准则（对齐竞品模型）
- 接口优先、无状态渲染（借鉴 tui-rs/Immediate 模式）
- 渲染帧括号：UiFrameBegin/UiFrameEnd；最少 diff 输出；0 基 UI 坐标；
- 组件只负责内部布局与绘制，不直接与终端交互，统一走 UiSurface；
- 主题/样式以 Token 为主，组件允许局部覆盖；
- 事件以 term_event_t 为统一源，节点按需消费；
- 跨平台：
  - Windows：使用 Win32 Console/VT 序列（Windows 10+）路径；
  - Linux/macOS：VT100/ANSI + termios；
  - 鼠标/备用屏/颜色在 term 层进行能力判定与降级。

不变量（Invariants）
- 一切屏幕输出必须发生在 UiFrameBegin..UiFrameEnd 内（除清屏/光标隐藏显示外）。
- UI 公开 API 均采用 0 基坐标，最终统一转换。
- 渲染时不得移动全局光标（由 FrameEnd 收尾定位）。
- BackBuffer 始终保持与当前终端尺寸一致；尺寸变更自动失效并重建。

---

## TDD 计划

测试工程：`tests/fafafa.core.term.ui/`
- 创建 lazbuild 项目（Debug），输出到 `bin/`，中间产物到 `lib/`，提供 BuildOrTest.bat/.sh。
- 使用 fpcunit，分层组织：
  1) Global（TTestCase_Global）：
     - Test_termui_clear/goto/write/write_at/fill_line/fill_rect：验证调用序列、边界裁剪（引入测试 Hook 或内存后端）。
     - Test_termui_run_entrance：Render/HandleEvent 调用时序（模拟注入：计数与最后一次参数）。
  2) Node：
     - TTestCase_TVBoxNode：固定项/弹性项分配、Padding/Gap、极小窗口下的 clamp 行为。
     - TTestCase_THBoxNode：同上（横向）。
     - TTestCase_TPanelNode：填充字符与背景色 API 调用次数（可先仅验证不越界/不崩溃）。
  3) Style：
     - TTestCase_StyleTheme: Dark/Light 生成的 token 是否稳定，Apply/Reset 是否调用了预期的 UiSetFg/Bg/AttrReset。

注意：
- 所有含中文输出的测试单元头部加 `{$CODEPAGE UTF8}`；
- 异常测试使用 AssertException + `{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}` 宏；
- 初期可引入“渲染计数假后端”（play 下临时）验证调用时序，然后逐步替换为更强的快照式验证。

---

## 近期任务拆解（迭代 1）
1) 门面 API 整理（本轮完成）
   - termui_* 函数命名/参数统一为 term_size_t；
   - 文档化 0 基坐标约定与 BackBuffer 差异化输出。
2) 建立 Tests 骨架
   - 目录/项目/脚本；
   - 最小化用例：Render 被调用一次、SizeChange 导致 Invalidate 后再次渲染、Q 退出；
3) 清理与修复
   - ui_surface.pas 残片修复（BufEnsureSize 结构）；
   - TPanelNode.Render 使用 FCh；
   - UiWrite/UiWriteLn 路径与 BackBuffer 策略文档化（短期保守，不大改）。
4) 示例与文档
   - examples/fafafa.core.term.ui：最小示例（StackRoot + Banner + VBox + StatusBar）；
   - docs/fafafa.core.term.ui.md：架构、API、限制、示例；

---

## 路线图（后续）
- 视图系统完善：PushView/PopView 覆盖所有绘制路径；滚动容器示例（已有 ui_controls_scrollcontainer.pas 可对接）。
- 输入控件：TextInput/CommandPalette/ListView 等 controls 的演示与门面映射（已有 src/ui/ui_controls_*.pas）。
- 终端能力降级：24bit -> 256/16；ANSI 不可用时尽量避免多余操作。
- 性能：行级 diff -> 段级 diff（已具雏形），统计输出字节数与帧时长基准。

---

## 风险与对策
- 终端兼容性：通过 term 层 `term_support_*` 进行守卫与降级。
- 窗口抖动/改动：FrameBegin 时重建 BackBuffer，UiGotoLineCol 做边界夹取。
- 编码：Windows/Unix 差异由 term 层封装；UI 层只使用 UnicodeString。

---

## 本轮总结（Round-1）
- 已完成：现状梳理、问题定位、门面 API 清点、TDD 计划与任务拆解。
- 遇到的问题：发现 ui_surface.pas 残片；组件填充字符临时实现与文档/行为不一致；裁剪路径需统一。
- 解决方案：纳入迭代 1 的“修复与清理”；先完成 Tests 骨架确保回归保护。
- 下一步：创建 tests 骨架与 BuildOrTest 脚本；清理残片并回归；补示例与文档。
