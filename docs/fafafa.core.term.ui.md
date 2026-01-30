# fafafa.core.term.ui

面向 Gemini CLI / Claude Code 体验的终端 UI 门面层。

## 设计目标
- 高密度信息面板、命令面板、聊天/代码流式内容、多列/分栏布局、键盘驱动交互、平滑渲染
- 跨平台（Windows/Unix），能力探测+降级（24bit/256/16、ANSI/备用屏）
- UI 0 基坐标、终端 1 基坐标；统一双缓冲；行内段级 diff 输出

## 模块关系
- term 底层：`fafafa.core.term*` 提供终端抽象与能力检测
- ui 基础：`src/ui/ui_surface.pas`（帧/裁剪/缓冲）、`src/ui/ui_app.pas`（事件循环）、`src/ui/ui_node.pas`（布局与控件）、`src/ui/ui_style.pas`（主题）
- 门面：`src/fafafa.core.term.ui.pas` 对外统一导出 API

## 关键 API（门面）
- 运行：
  - `termui_run(Render, HandleEvent)`：渲染与事件回调驱动
  - `termui_run_node(Root: IUiNode)`：以节点树为根进行渲染与事件分发
- 表面绘制：
  - `termui_clear/termui_goto/termui_write/termui_writeln`
  - `termui_fg24/termui_bg24/termui_attr_reset`
  - `termui_fill_line/termui_write_at/termui_fill_rect`
- 节点：
  - `IUiNode/TStackRootNode/TBannerNode/TStatusBarNode/TPanelNode/TVBoxNode/THBoxNode`

## 渲染与裁剪
- 使用 `UiFrameBegin/UiFrameEnd` 包裹一帧输出
- BackBuffer/FrontBuffer 按终端尺寸维护；UiFrameEnd 进行“行内段级 diff”输出
- PushView/PopView 支持视口与原点，统一裁剪与坐标转换

## 事件循环
- `UiAppRun/UiAppRunNode` 内部：
  - 备用屏（若支持）启用、鼠标（若支持）启用
  - resize 事件导致 Invalidate 重绘
  - Demo 下按键 Q 退出（可在产品中自定义）

## 主题
- `UiThemeUseDark/UiThemeUseLight` 切换主题
- 统一样式 token（StatusBar、List、Tabs 等）
- `UiStyleApply/UiStyleReset` 应用/重置

## 示例（规划）
- Chat/Code Demo：左侧会话列表/右侧消息区/底部输入/上方命令面板
- 滚动容器 + 虚拟化列表 + 多行输入

## 构建与测试
- 测试工程：`tests/fafafa.core.term.ui/`（fpcunit、Debug、bin/lib 输出）
- 运行脚本：`BuildOrTest.bat` / `BuildOrTest.sh`（依赖 `tools/lazbuild.bat` 配置）

## 后续路线
- 统一 `UiWrite/UiWriteLn` 到缓冲+裁剪路径
- VirtualList、TextInput、CommandPalette 控件
- Markdown/代码块渲染、流式增量输出



## 快速上手（Frame 渲染模式）

- 统一在 `termui_frame_begin`/`termui_frame_end` 内进行绘制；启用 BackBuffer + 行内段级 diff 输出
- 0 基坐标（line, col）传入 UI API，后端负责转换为终端 1 基坐标

示例：

```pascal
termui_frame_begin;
try
  if not term_size(w,h) then begin w := 80; h := 24; end;
  termui_set_attr(termui_attr_preset_info);
  termui_fill_line(0,' ', -1);
  termui_write_at(0,0,'demo - Q to quit');
  termui_attr_reset;
  if h>2 then begin
    termui_set_attr(termui_attr_preset_warn);
    termui_fill_rect(0,1,w,h-2,' ');
    termui_attr_reset;
  end;
  termui_set_attr(termui_attr_preset_error);
  termui_fill_line(h-1,' ', -1);
  termui_write_at(h-1,0,Format('Size: %d x %d',[w,h]));
  termui_attr_reset;
finally
  termui_frame_end;
end;
```

## 视口与裁剪（PushView/PopView）

- `termui_push_view(ViewX,ViewY,ViewW,ViewH, OriginX,OriginY)` 设置视口与局部原点；`termui_pop_view` 恢复
- 所有绘制 API 在 BackBuffer 模式下会自动进行视口裁剪与坐标转换
- 建议将子组件渲染封装在 `termui_with_view(...)` 中，保证作用域安全


### with_view 坐标模型与嵌套

- 坐标为“绝对 UI 坐标”：`termui_with_view(ViewX,ViewY,...)` 内部渲染过程仍以 0 基“全局 UI 坐标系”解释 `line,col`，并在输出前进行视口裁剪与原点平移。
- 若希望在子区域内以“相对坐标”编写渲染，可使用 `OriginX,OriginY` 参数（或在渲染逻辑中自行换算）。
- 视口可嵌套：外层 with_view 生效后，再进入内层 with_view，最终输出受两级裁剪共同限制。

示例（嵌套视口，绝对坐标用法）：

```pascal
termui_frame_begin;
try
  // 外层视口：X=2..7, Y=1..3
  termui_with_view(2, 1, 6, 3, 0, 0, @procedure
  begin
    // 内层视口：X=3..6, Y=2..3
    termui_with_view(3, 2, 4, 2, 0, 0, @procedure
    begin
      // 绝对 UI 坐标：在 (2,3) 行列附近绘制 'XYZ'
      termui_write_at(2, 3, 'XYZ');
    end);
  end);
finally
  termui_frame_end;
end;
```

说明：以上用法示例化表达绝对坐标。实际项目中，建议将 `Render` 抽为全局过程（非嵌套），以匹配 `TUiRenderProc` 类型（非方法过程变量）。

## BackBuffer 策略与直写限制

- 在帧模式中，UiSurface 维护 Front/Back 缓冲并按脏区与行内差异段落输出
- 无 BackBuffer（极端环境或未启用帧）时：
  - `termui_write_at/fill_rect/fill_line` 将直接定位光标并输出
  - `termui_write/writeln` 直写后端，不参与裁剪；不建议在复杂渲染路径中使用
- 最佳实践：复杂渲染统一在帧内完成，避免与直写混用

## 能力探测与降级（建议）

- 在 term 层进行能力判定（ANSI/TrueColor/备用屏/鼠标）：
  - `term_support_ansi`、`term_support_color_24bit`、`term_support_alternate_screen`、`term_support_mouse`
- UI 层按语义 API 使用颜色与属性。
- 当 TrueColor 不可用时，建议在 term 层将 24bit 映射为 256/16 色（下一迭代实现），保持 UI 调用不变

## 测试与调试（Hooks/Memory Backend）

- UiSurface 提供调试 Hook：可在测试中注入 `Write/Writeln/CursorLine/CursorCol/Size` 来统计调用与断言内容
- `ui_backend_memory` 适合做快照与段级 diff 的断言，确保输出与裁剪行为稳定

## 示例与工程

- 示例项目：`examples/fafafa.core.term.ui/`，可通过脚本一键构建/运行（Windows：BuildOrRun_ChatCode.bat）
- 测试工程：`tests/fafafa.core.term.ui/`，执行脚本 BuildOrTest.bat，或直接运行 bin/tests.exe --all
