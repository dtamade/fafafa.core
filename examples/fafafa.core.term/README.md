# Examples – fafafa.core.term

本目录收录经整理的、可长期维护的示例程序。历史上的 `play/plays` 中与 term 相关的演示已逐步迁移至此。

- 如何构建（仓库根目录执行）
  - Windows: 运行 `examples/fafafa.core.term/build_examples.bat` 或 `BuildOrRun_CoreExamples.bat`
  - Linux/macOS: 运行 `examples/fafafa.core.term/build_examples.sh`

- 示例导航（节选）
  - 01_size_clear.lpr：尺寸、清屏
  - 02_color_write.lpr：颜色与输出
  - 03_alt_screen_demo.lpr：备用屏
  - 05_input_best_practices.lpr：输入最佳实践（鼠标/焦点/括号粘贴 + finally 恢复；清理 ?1002/?1003）
  - 06_input_monitor.lpr：输入监视（支持命令行开关；尝试 any‑motion ?1003）
  - 07_frame_loop_demo.lpr：帧式循环 + 模式守卫 + 同步输出（?2026）；边框 auto/ascii/box 策略
  - events_collect_budget_compare.lpr：演示 budget=0 与 8ms 的差异（队列消费/拉取、Move/Resize 合并）
  - events_collect_statusbar.lpr：状态栏实时显示（收集数量、最后事件、鼠标位置、FPS；ESC 退出）
  - events_collect_statusbar_dynamic.lpr：动态预算 + 底部状态栏（b 切换 0/8ms；显示 events/last/mouse/FPS）


  - mouse_input_demo.lpr：鼠标事件显示（启停对称，清理 ?1002/?1003）
  - advanced_test.lpr：通用能力快速自检

  - WINCH/尺寸变化：
    - resize_layout_demo.lpr：SignalCenter 回调 + 帧内去抖（16ms）
    - example_winch_channel.lpr：Channel(capacity=1) 背压 + 只保留最新
    - example_win_winch_poll.lpr（Windows）：窗口事件 + 帧内去抖（16ms）
    - example_winch_portable.lpr：跨平台入口（Unix 用 Channel；Windows 用轮询）


### WINCH（终端尺寸变更）处理片段（推荐）

- 仅选一种消费模式（回调 或 WaitNext/Channel），不要混用；UI 帧内做 16–33ms 合并；WINCH 队列建议 qdpDropOldest。

```pascal
uses fafafa.core.signal, fafafa.core.term;

const DEBOUNCE_MS = 16;
var tok: Int64 = 0; pending: Boolean = False; lastTs: QWord = 0;

procedure OnWinch(const S: TSignal);
begin
  pending := True;
  lastTs := GetTickCount64;
end;

procedure InitWinch;
var C: ISignalCenter;
begin
  C := SignalCenter; C.Start;
  C.ConfigureQueue(256, qdpDropOldest);
  tok := C.Subscribe([sgWinch], @OnWinch);
end;

procedure TickFrame;
var nowTs: QWord; W,H: Integer;
begin
  if pending then
  begin
    nowTs := GetTickCount64;
    if nowTs - lastTs >= DEBOUNCE_MS then
    begin
      pending := False;
      if term_size(W,H) then
        ; // TODO: 依据新尺寸刷新布局/缓冲
    end;
  end;
end;

procedure FiniWinch;
begin
  if tok <> 0 then SignalCenter.Unsubscribe(tok);
  tok := 0;
end;
```

- 更多建议见：docs/partials/signal.best_practices.md

## 操作提示与观察点

### events_collect_budget_compare.lpr
- 运行：bin/events_collect_budget_compare.exe
- 按键：
  - b：在 budget=0 与 8ms 之间切换
  - h：显示帮助；ESC：退出
- 观察：
  - budget=0：仅消费队列，不触发 pull；收集条目通常较少
  - budget=8：在预算时间内持续拉取；鼠标移动合并、尺寸变化去抖清晰可见
- 截图占位：
  - images/events_collect_budget_compare_1.png
  - images/events_collect_budget_compare_2.png

### events_collect_statusbar_dynamic.lpr
- 运行：bin/events_collect_statusbar_dynamic.exe [--budget=N]
  - 例如：--budget=0 仅消费队列；默认 8
- 按键：
  - b：在 0/8ms 间切换
  - h：显示帮助；ESC：退出
- 状态栏指标：events 数、最后事件类型、鼠标位置、FPS、当前预算
- 截图占位：
  - images/events_collect_statusbar_dynamic_1.png
  - images/events_collect_statusbar_dynamic_2.png


- 目录约定
  - 长期维护的示例统一放置于 `examples/fafafa.core.term`
  - 临时性实验（play/plays）建议迁至此目录或删除


- 终端差异与最佳实践
  - Windows Terminal 常见差异：对 any‑motion（?1003）支持不稳定，移动事件往往需要按键（按钮按下）配合；本仓示例已在退出时确保 ?1002/?1003 关闭
  - 边框字符 auto/ascii/box：示例在 Windows Terminal 下会降级为 ASCII，以避免 box‑drawing 显示异常；按 b 可切换策略
  - 鼠标/焦点/粘贴等模式：统一通过 term_mode_guard 或成对启停 API 管理，finally 中对称关闭，防止控制台状态残留



## 可构建与运行的示例（当前）
- example_term.exe：完整特性演示
- basic_example.exe：基础终端控制
- keyboard_example.exe：键盘输入处理
- text_editor.exe：简易文本编辑器
- progress_simple_demo.exe：进度条与旋转器
- theme_demo.exe：主题系统演示
- unicode_demo.exe：Unicode 支持演示
- widgets_demo.exe：基础部件演示

以上可通过 build_examples.bat 一键构建，产物位于 bin/。

## 暂时跳过的示例
- menu_system.lpr（依赖 UI 菜单抽象，待补）
- layout_demo.lpr（依赖布局抽象：ITerminalLayout、MakeRect、ldVertical/ldHorizontal）
- recorder_demo.lpr（依赖记录/回放抽象：ITerminalRecorder）

待相关抽象补齐后，将恢复构建并更新本说明。

## 构建说明
- Windows：运行 examples/fafafa.core.term/build_examples.bat
- 如果安装 Lazarus：脚本会优先调用 tools/lazbuild.bat 处理 .lpi 项目

## 备注
- Windows 控制台已通过 ReadConsoleInputW 路径保证宽字符输入
- 鼠标启用期间示例采用模式守卫，退出自动恢复 Quick Edit
- 少量编译告警（隐式字符串转换、inline 未内联）不影响运行
