# Terminal Library User Guide
# 终端库用户指南

## 概述 Overview

这是一个功能强大的 Pascal 终端库，提供了完整的 ANSI 转义序列支持、高级文本样式管理和跨平台终端操作功能。

This is a powerful Pascal terminal library that provides complete ANSI escape sequence support, advanced text style management, and cross-platform terminal operations.

## 功能特性 Features

### ✅ 已实现功能 Implemented Features

1. **ANSI 转义序列支持 ANSI Escape Sequence Support**
   - 完整的 ANSI 序列常量定义
   - 光标控制、颜色设置、文本样式
   - 序列生成和解析功能

2. **高级文本样式管理 Advanced Text Style Management**
   - 样式类型系统（粗体、斜体、下划线等）
   - 颜色管理（16色、256色、24位真彩色）
   - 样式组合和应用
   - 便捷的文本格式化函数

3. **性能优化 Performance Optimization**
   - 高效的序列生成
   - 最小内存开销
   - 快速样式处理

## 模块结构 Module Structure

### 核心模块 Core Modules

1. **`fafafa.core.term.ansi`** - ANSI 转义序列模块
2. **`fafafa.core.term.style`** - 文本样式管理模块
3. **`fafafa.core.term`** - 主终端模块（基础架构）

## 快速开始 Quick Start

### 基本使用 Basic Usage

```pascal
program example;
{$mode objfpc}{$H+}

uses
  fafafa.core.term.ansi,
  fafafa.core.term.style;

begin
  // 基本颜色文本
  WriteLn(term_text_red('这是红色文本'));
  WriteLn(term_text_bold('这是粗体文本'));

  // 组合样式
  WriteLn(term_text_error('错误消息'));
  WriteLn(term_text_success('成功消息'));

  // RGB 真彩色
  WriteLn(term_text_rgb('彩色文本', 255, 100, 50));
end.
```

### 高级样式管理 Advanced Style Management

```pascal
var
  LStyle: term_text_style_t;
begin
  // 创建自定义样式
  LStyle := term_style_create;
  term_style_add(LStyle, ts_bold);
  term_style_add(LStyle, ts_underline);
  term_style_set_fg_rgb(LStyle, 255, 0, 0);

  // 应用样式
  WriteLn(term_text_styled('自定义样式文本', LStyle));
end;
```

## API 参考 API Reference

### ANSI 序列函数 ANSI Sequence Functions

#### 光标控制 Cursor Control
- `ansi_cursor_move_to_position(x, y: Integer): string`
- `ansi_cursor_move_up(lines: Integer): string`
- `ansi_cursor_move_down(lines: Integer): string`
- `ansi_cursor_save_position: string`
- `ansi_cursor_restore_position: string`

#### 颜色设置 Color Setting
- `ansi_fg_color_256(color: Byte): string`
- `ansi_bg_color_256(color: Byte): string`
- `ansi_fg_color_rgb(r, g, b: Byte): string`
- `ansi_bg_color_rgb(r, g, b: Byte): string`

#### 序列解析 Sequence Parsing
- `ansi_parse_sequence(sequence: string): ansi_sequence_info_t`
- `ansi_is_valid_sequence(sequence: string): Boolean`

### 文本样式函数 Text Style Functions

#### 基本样式 Basic Styles
- `term_text_bold(text: string): string`
- `term_text_italic(text: string): string`
- `term_text_underline(text: string): string`
- `term_text_strikethrough(text: string): string`

#### 颜色文本 Colored Text
- `term_text_red(text: string): string`
- `term_text_green(text: string): string`
- `term_text_blue(text: string): string`
- `term_text_yellow(text: string): string`
- `term_text_magenta(text: string): string`
- `term_text_cyan(text: string): string`

#### 高级格式化 Advanced Formatting
- `term_text_colored(text: string; color: Byte): string`
- `term_text_rgb(text: string; r, g, b: Byte): string`
- `term_text_styled(text: string; style: term_text_style_t): string`

#### 预设样式 Preset Styles
- `term_text_error(text: string): string` - 红色粗体
- `term_text_warning(text: string): string` - 黄色粗体
- `term_text_success(text: string): string` - 绿色粗体
- `term_text_info(text: string): string` - 蓝色
- `term_text_highlight(text: string): string` - 反转显示

### 样式管理函数 Style Management Functions

#### 样式创建 Style Creation
- `term_style_create: term_text_style_t`
- `term_style_create_simple(style: term_style_t): term_text_style_t`
- `term_style_create_colored(color: Byte): term_text_style_t`

#### 样式修改 Style Modification
- `term_style_add(var style: term_text_style_t; new_style: term_style_t)`
- `term_style_remove(var style: term_text_style_t; remove_style: term_style_t)`
- `term_style_set_fg_16(var style: term_text_style_t; color: Byte)`
- `term_style_set_bg_16(var style: term_text_style_t; color: Byte)`
- `term_style_set_fg_256(var style: term_text_style_t; color: Byte)`
- `term_style_set_bg_256(var style: term_text_style_t; color: Byte)`
- `term_style_set_fg_rgb(var style: term_text_style_t; r, g, b: Byte)`
- `term_style_set_bg_rgb(var style: term_text_style_t; r, g, b: Byte)`

#### 样式应用 Style Application
- `term_style_apply(style: term_text_style_t): string`
- `term_style_reset: string`

## 类型定义 Type Definitions

### 样式类型 Style Types

```pascal
term_style_t = (
  ts_normal,        // 正常
  ts_bold,          // 粗体
  ts_dim,           // 暗淡
  ts_italic,        // 斜体
  ts_underline,     // 下划线
  ts_blink,         // 闪烁
  ts_reverse,       // 反转
  ts_strikethrough  // 删除线
);

term_style_set_t = set of term_style_t;
```

### 颜色类型 Color Types

```pascal
term_color_type_t = (
  tct_default,      // 默认色
  tct_16_color,     // 16 色
  tct_256_color,    // 256 色
  tct_rgb_color     // RGB 真彩色
);
```

## 示例程序 Example Programs

库中包含了多个示例程序：

1. **`simple_ansi_test.lpr`** - ANSI 序列基础测试
2. **`text_style_test.lpr`** - 文本样式管理测试
3. **`simple_performance_test.lpr`** - 性能特征验证

## 性能特征 Performance Characteristics

根据性能测试结果：

- **ANSI 序列生成**：非常快速（1000次操作 < 1ms）
- **样式创建**：高效（1000次操作快速完成）
- **文本格式化**：良好性能（500次复杂操作顺利）
- **内存使用**：最小开销（每样式20字节）

## 最佳实践 Best Practices

### 输入最佳实践 Input Best Practices

- 快速窥视与清空缓冲：
  - ITerminalInput.PeekKey(out K): Boolean 可无损查看下一键
  - ITerminalInput.FlushInput 可清理缓冲，常用于模式切换或重置

- 鼠标启用与 SGR 模式：
  - 基本鼠标：term_mouse_enable(True/False)
  - 按钮/拖动：term_mouse_drag_enable(True/False)  // ?1002h/?1002l
  - SGR 鼠标：term_mouse_sgr_enable(True/False)    // ?1006h/?1006l
  - 建议以 try/finally 包裹，退出时关闭（防止终端残留状态）

- 括号粘贴（Bracketed Paste）：
  - 开关：term_paste_bracket_enable(True/False)  // ?2004h/?2004l（Unix 现代终端普遍支持；Windows 通常不支持）
  - 建议：启用后谨慎处理粘贴数据长度与控制字符，避免注入；必要时限制打印长度

- 模式守卫（推荐）：
  - 一次性启用多组模式，并在 finally 中统一还原，避免终端残留
  - Acquire/Done 范式（过程式接口）：
    - term_mode_guard_acquire_current([tm_mouse_button_drag, tm_mouse_sgr_1006, tm_focus_1004, tm_paste_2004])
    - try ... finally term_mode_guard_done(Guard); end;


- SGR 鼠标编码（1006）：
  - 形如 ESC [ < b ; x ; y (M|m)
  - 修饰位累加：+4=Shift, +8=Alt, +16=Ctrl, +32=Move, +64=Wheel
  - 滚轮方向：base&3 ∈ {0,1,2,3} → Up/Down/Left/Right；建议映射为瞬时 tms_press

- “~ 风格”带修饰键：
  - ESC [ <num> ; <mod> ~，mod 取值：
    - 2=Shift, 3=Alt, 4=Shift+Alt, 5=Ctrl, 6=Shift+Ctrl, 7=Alt+Ctrl, 8=Shift+Alt+Ctrl
  - 常见 <num>：Insert(2), Delete(3), PageUp(5), PageDown(6), Home(1/7), End(4/8), F5(15)…F12(24)

- 测试建议：
  - 断言修饰键字符串采用“包含式”而非“顺序严格”，提升跨平台稳定性
  - Unix 序列解析的单测用 {$IFDEF UNIX} 包裹，避免在 Windows runner 中误跑

### 粘贴存储治理与后端选择（最佳实践）

- 治理建议
  - 启动时一次性设置双限：term_paste_defaults(128, 1 shl 20) 或 term_paste_defaults_ex(..., 'tui')
  - 组合策略：auto_keep_last + max_bytes 同时启用，任一触发均回收
  - 超长单条：若单条 > max_bytes，最终存储为空（严格满足上限）；如需保留请提高上限或设为 0
- 后端选择（behind-a-flag）
  - 默认 legacy；可通过环境变量 FAFAFA_TERM_PASTE_BACKEND=ring 或运行时 term_paste_use_backend('ring') 启用环形后端
  - 不建议在高并发期间频繁切换
- 立即生效
  - term_paste_set_max_bytes 在 legacy/ring 下均“立即生效”，可能触发立刻回收
- 基准与推荐
  - 微基准：tests/fafafa.core.term/benchmarks/build_benchmarks.bat → bin/benchmark_paste_backends.exe [N]
  - 建议阈值：keep_last=128，max_bytes=1m（tui）；高频场景 keep_last=64..128，max_bytes=1m..2m
  - 解读：ring 在大 N / 频繁修剪下更稳定（append/trim 均摊 O(1)）
- 失败注入与诊断（仅测试/排障）
  - 设置 FAFAFA_TERM_FORCE_PLATFORM_FAIL=1 可模拟平台创建失败；term_last_error 写入诊断
  - Windows 输出回退：FAFAFA_TERM_WIN_FORCE_WRITEFILE=1 可强制 WriteFile 路径
- 参考
  - 速查分片：docs/partials/term.paste.best_practices.md

  - 详见 docs/fafafa.core.term.md#paste-后端选择与推荐配置 与 docs/benchmarks.md#term-paste-backends-微基准legacy-vs-ring


- 示例代码：见 examples/fafafa.core.term/05_input_best_practices.lpr

- 解析超时策略（Unix）：
  - 当解析 ESC/CSI 序列时，库会在短时间内轮询补读，避免半包导致的粘连。默认超时时间为 10ms。
  - 可按需调整：term_unix_set_escape_timeout_ms(20); // 返回旧值；<=0 使用默认
  - 建议：本地终端保持默认；串口/慢链路可适度调大；极致低延迟场景可适度调小。
  - 命令行演示（示例程序）：
    - Unix 下：./05_input_best_practices --esc-timeout=20
    - Windows 下：参数无效，保持默认





### 常见终端差异与排查 Terminal Differences & Troubleshooting

- 常见终端支持现状（简表）：
  - xterm/gnome-terminal/konsole/iTerm2/Alacritty/WezTerm/kitty：基本支持 SGR 鼠标(1006)、按钮/拖动(1002)、焦点事件(1004)、Bracketed Paste(2004)
  - tmux：需手动开启与透传
    - set -g mouse on
    - set -g focus-events on
    - set -g default-terminal "tmux-256color" 或 terminal-overrides 增强色彩/功能透传（按发行版建议）
  - GNU screen：鼠标与焦点支持有限；如需更好体验建议使用 tmux 或现代终端
  - WSL/Windows Terminal：推荐使用 Windows Terminal；传统 conhost 可能存在行为差异（确保未启用“旧版控制台”）

- 常见差异点与注意事项：
  - 修饰键：许多终端对 Alt 会发送前置 ESC（ESC-prefix），解析时需考虑
  - 鼠标模式：1000(X10) 仅点击；1002(按钮+拖动)；1003(任意移动，噪声大，一般不推荐)；1006(SGR 编码，推荐)
  - 焦点事件：1004 部分复用器（tmux/screen）默认关闭，需要显式开启
  - Keypad/Application 模式：不同终端/复用器在应用模式下的编码可能有差异

- 远程与慢链路：
  - ESC/CSI 半包与延迟更易发生；可按需调大解析超时（--esc-timeout=XX 或 term_unix_set_escape_timeout_ms）
  - 避免中间工具吞掉/改写序列（某些代理/日志工具）

- 快速自检步骤：
  - 查看 TERM：echo $TERM，应为 xterm-256color、tmux-256color 等现代类型
  - 开启 SGR 鼠标测试：printf '\e[?1006h\e[?1002h'; 然后在终端中移动/点击，配合 `cat -v` 观察是否产生 "<[...](M|m)" 序列
  - 还原：printf '\e[?1006l\e[?1002l'
  - 查看 terminfo：infocmp $TERM

- 回退策略建议：
  - 检测不支持 SGR 时，退回到 1002 或仅启用 1000（点击）；功能降级但保证可用
  - 始终使用 try/finally 关闭已开启的模式，避免终端残留状态

### Windows 兼容性与排查 Windows Compatibility & Troubleshooting

- 推荐组合：Windows Terminal + PowerShell 或 Windows Terminal + WSL
  - Windows Terminal/ConPTY 对 ANSI 支持更好，光标/颜色/SGR 鼠标/Bracketed Paste 等行为更一致
  - 传统 conhost 可能存在差异，尤其在旧版系统上

- 确保未启用“旧版控制台”：
  - 打开 cmd 属性 -> 取消勾选“使用旧版控制台”

- 字体与宽度：
  - 选择支持 Unicode、等宽渲染良好的字体（如 Cascadia Mono, Fira Code, JetBrains Mono）
  - 混合全角/半角字符时注意对齐（East Asian Ambiguous 宽度），建议在 UI 布局中避免依赖“视觉等宽”

- 颜色与主题：
  - Windows Terminal 支持 24-bit TrueColor；如需 256 色/真彩，优先使用 WT 而非旧 conhost
  - PowerShell 与 cmd 的配色方案可能不同，留意可读性

- 输入法与 Alt 行为：
  - 某些输入法会拦截组合键；如需原始键值，测试时建议暂时切换到英文输入法

#### Windows 能力矩阵（简要）

- ANSI/颜色：
  - Windows Terminal (ConPTY)：ANSI/CSI/TrueColor(24-bit) 支持较好；compatibles 将包含 tc_ansi/tc_color_16/256/24bit
  - 经典 conhost：ANSI 支持受限，颜色回退到 16 色；建议优先 WT
- 鼠标/焦点：
  - 鼠标：通过 ReadConsoleInput 产生 MOUSE_EVENT；启用/关闭由 mouse_enable 控制（ENABLE_MOUSE_INPUT）
  - 焦点：FOCUS_EVENT 固有支持；无需 1004 序列
- 粘贴（2004）：
  - 一般不支持 Bracketed Paste；程序可显式关闭 tm_paste_2004 或在能力检测失败时跳过
- 建议回退：
  - 若无 ANSI：避免依赖复杂 SGR；使用基本清屏/定位/文本输出
  - 鼠标不可用时退化为键盘操作；焦点事件可作为“激活状态”提示

示例：
- Windows Terminal 下推荐启用 [tm_mouse_button_drag, tm_mouse_sgr_1006, tm_focus_1004]；tm_paste_2004 视支持情况略过

  - Alt 键可能表现为 ESC 前缀（ESC + Key），解析时应兼容

- WSL 注意项：
  - 尽量在 Windows Terminal 中运行 WSL，避免不同终端行为混杂
  - WSL 与宿主的剪贴板/快捷键不同步，Bracketed Paste 行为可能因中间层不同而变化

- 常用自检：
  - 测试 ANSI：使用 `type` 或 `powershell -Command "Write-Host \e[31mRED\e[0m"`
  - 运行示例：examples\fafafa.core.term\bin\05_input_best_practices.exe
  - 若鼠标/焦点无效：确认 WT 设置中允许鼠标事件传递，并检查是否处于屏幕复制模式等


#### Windows 数据流示意（ConPTY vs conhost）

```mermaid
flowchart LR
  subgraph Modern[Modern path]
    A[Your app (05_input_best_practices.exe)\nANSI/CSI/SGR] --> B[ConPTY (pseudoconsole)]
    B --> C[Windows Terminal]
    C --> U[User display]
  end
  subgraph Legacy[Legacy path]
    A -. Console APIs/stdout .-> D[conhost.exe]
    D -.-> E[cmd.exe window]
    E -. Limited ANSI/quirks .-> U
  end
```

说明：
- ConPTY 路径更贴近类 Unix 的 PTY 字节流，ANSI/SGR/TrueColor 等一致性更好
- 旧版 conhost 可能对序列做转换/裁剪，导致行为差异；推荐优先使用 Windows Terminal


1. **缓存常用样式**：为频繁使用的样式创建变量
2. **使用简单函数**：对基本需求使用 `term_text_red()` 等简单函数
3. **批量操作**：可能时批量处理文本格式化
4. **避免嵌套**：避免过度嵌套样式调用

## 兼容性 Compatibility

- **编译器**：Free Pascal 3.0+
- **平台**：Windows, Linux, macOS
- **终端**：支持 ANSI 转义序列的现代终端

## 许可证 License

请参考项目根目录的许可证文件。

## 贡献 Contributing

欢迎贡献代码和改进建议！请遵循项目的编码规范。
