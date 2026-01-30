# Terminal Library Quick Reference

> See also: Collections
> - Collections API 索引：docs/API_collections.md
> - TVec 模块文档：docs/fafafa.core.collections.vec.md
> - 集合系统概览：docs/fafafa.core.collections.md

# 终端库快速参考


## Sink 快速切换（Runner/Benchmark）

- Windows PowerShell
  - $env:FAFAFA_TEST_USE_SINK_CONSOLE='1'; tests\fafafa.core.test\bin\tests.exe --summary-only
  - $env:FAFAFA_BENCH_USE_SINK_JSON='1'; tests\fafafa.core.benchmark\bin\tests_benchmark.exe --report=json --outfile=out\bench.json

- Linux/macOS bash
  - FAFAFA_TEST_USE_SINK_CONSOLE=1 ./tests/fafafa.core.test/bin/tests --summary-only
  - FAFAFA_BENCH_USE_SINK_JSON=1 ./tests/fafafa.core.benchmark/bin/tests_benchmark --report=json --outfile=out/bench.json


## Paste 最佳实践速查（终端模块）
- docs/partials/term.paste.best_practices.md

注：Benchmark JSON Sink 已与默认 JSON Reporter 位等，可安全启用；时间戳统一 UTC Z。

## 快速导入 Quick Import

```pascal
uses
  fafafa.core.term.ansi,    // ANSI 序列支持
  fafafa.core.term.style;   // 文本样式管理
```

## 常用函数 Common Functions

### 🎨 基本颜色 Basic Colors

```pascal
// 基本颜色文本
term_text_red('红色文本')
term_text_green('绿色文本')
term_text_blue('蓝色文本')
term_text_yellow('黄色文本')
term_text_magenta('洋红文本')
term_text_cyan('青色文本')
term_text_white('白色文本')
term_text_black('黑色文本')
```

### 📝 文本样式 Text Styles

```pascal
// 基本样式
term_text_bold('粗体文本')
term_text_italic('斜体文本')
term_text_underline('下划线文本')
term_text_strikethrough('删除线文本')
term_text_blink('闪烁文本')
term_text_reverse('反转文本')
```

### 🚨 预设消息样式 Preset Message Styles

```pascal
// 消息类型
term_text_error('错误消息')      // 红色粗体
term_text_warning('警告消息')    // 黄色粗体
term_text_success('成功消息')    // 绿色粗体
term_text_info('信息消息')       // 蓝色
term_text_highlight('高亮文本')  // 反转显示
```

### 🌈 高级颜色 Advanced Colors

```pascal
// 256 色调色板
term_text_colored('彩色文本', 196)  // 使用颜色索引

// RGB 真彩色
term_text_rgb('彩色文本', 255, 100, 50)  // R, G, B 值
```

## 高级样式管理 Advanced Style Management

### 创建自定义样式 Create Custom Style

```pascal
var
  LStyle: term_text_style_t;
begin
  // 创建基础样式
  LStyle := term_style_create;

  // 添加样式属性
  term_style_add(LStyle, ts_bold);
  term_style_add(LStyle, ts_underline);

  // 设置颜色
  term_style_set_fg_rgb(LStyle, 255, 0, 0);  // 红色前景
  term_style_set_bg_16(LStyle, 0);           // 黑色背景

  // 应用样式
  WriteLn(term_text_styled('自定义样式文本', LStyle));
end;
```

### 样式类型 Style Types

```pascal
ts_normal        // 正常
ts_bold          // 粗体
ts_dim           // 暗淡
ts_italic        // 斜体
ts_underline     // 下划线
ts_blink         // 闪烁
ts_reverse       // 反转
ts_strikethrough // 删除线
```

## ANSI 序列直接使用 Direct ANSI Usage

### 光标控制 Cursor Control

```pascal
// 移动光标到指定位置
Write(ansi_cursor_move_to_position(10, 5));

// 光标移动
Write(ansi_cursor_move_up(2));
Write(ansi_cursor_move_down(3));
Write(ansi_cursor_move_left(1));
Write(ansi_cursor_move_right(4));

// 保存/恢复光标位置
Write(ansi_cursor_save_position);
Write(ansi_cursor_restore_position);
```

### 屏幕控制 Screen Control

```pascal
// 清屏操作
Write(ansi_clear_screen);
Write(ansi_clear_line);
Write(ansi_clear_to_end_of_line);
Write(ansi_clear_to_start_of_line);
```

### 直接颜色设置 Direct Color Setting

```pascal
// 16 色
Write(ANSI_FG_RED);      // 红色前景
Write(ANSI_BG_BLUE);     // 蓝色背景

// 256 色
Write(ansi_fg_color_256(196));  // 亮红色前景
Write(ansi_bg_color_256(21));   // 亮蓝色背景

// RGB 真彩色
Write(ansi_fg_color_rgb(255, 100, 0));  // 橙色前景
Write(ansi_bg_color_rgb(0, 50, 100));   // 深蓝色背景

// 重置
Write(ANSI_RESET);  // 重置所有样式和颜色
```

## 常用颜色索引 Common Color Indices

### 16 色索引 16-Color Indices
```
0=黑色  1=红色  2=绿色  3=黄色
4=蓝色  5=洋红  6=青色  7=白色
8=亮黑  9=亮红  10=亮绿 11=亮黄
12=亮蓝 13=亮洋红 14=亮青 15=亮白
```

### 常用 256 色索引 Common 256-Color Indices
```
196=亮红   46=亮绿   21=亮蓝   226=亮黄
208=橙色   129=紫色  51=亮青   201=粉红
```

## 性能提示 Performance Tips

### ✅ 推荐做法 Recommended

```pascal
// 缓存常用样式
var
  ErrorStyle: term_text_style_t;
begin
  ErrorStyle := term_style_create;
  term_style_add(ErrorStyle, ts_bold);
  term_style_set_fg_16(ErrorStyle, 1);

  // 重复使用
  WriteLn(term_text_styled('错误1', ErrorStyle));
  WriteLn(term_text_styled('错误2', ErrorStyle));
end;

// 使用简单函数处理基本需求
WriteLn(term_text_red('简单红色文本'));
```

### ❌ 避免做法 Avoid

```pascal
// 避免重复创建相同样式
for i := 1 to 100 do
begin
  LStyle := term_style_create;  // 低效！
  term_style_add(LStyle, ts_bold);
  WriteLn(term_text_styled('文本', LStyle));
end;

// 避免过度嵌套
WriteLn(term_text_bold(term_text_red(term_text_underline('文本'))));  // 复杂！
```

## 示例代码 Example Code

### 彩色表格 Colored Table

```pascal
WriteLn(term_text_bold('姓名') + '        ' +
        term_text_bold('状态') + '      ' +
        term_text_bold('颜色'));
WriteLn('Alice       ' + term_text_success('成功') + '     ' + term_text_green('绿色'));
WriteLn('Bob         ' + term_text_error('错误') + '       ' + term_text_red('红色'));
WriteLn('Charlie     ' + term_text_warning('警告') + '     ' + term_text_yellow('黄色'));
```

### 进度指示器 Progress Indicator

```pascal
Write('进度: ');
for i := 1 to 10 do
begin
  if i <= 7 then
    Write(term_text_green('█'))
  else
    Write(term_text_red('░'));
end;
WriteLn(' 70%');
```

### 彩色渐变 Color Gradient

```pascal
Write('渐变: ');
for i := 0 to 10 do
begin
  LRed := Round(255 * i / 10);
  LBlue := 255 - LRed;
  Write(term_text_rgb('█', LRed, 0, LBlue));
end;
WriteLn;
```

## 故障排除 Troubleshooting

### 常见问题 Common Issues

1. **颜色不显示**：确保终端支持 ANSI 转义序列
2. **编译错误**：检查是否正确导入了所需模块
3. **样式不生效**：确保在文本后调用了重置函数

### 调试技巧 Debug Tips

```pascal
// 检查 ANSI 序列
WriteLn('序列: "' + ansi_fg_color_256(196) + '"');

// 验证样式
LStyle := term_style_create;
WriteLn('样式序列: "' + term_style_apply(LStyle) + '"');
```

---

**快速开始**：复制上面的代码示例，修改文本内容，立即开始使用！


# Runner & Scripts Quick Reference

Audience: developers running tests locally; minimal, copy-paste friendly.

## Runner Flags (tests.exe)
- Discovery & listing
  - --list, --list-json[=p], --list-json-pretty
  - --list-sort=alpha|none, --list-sort-case
  - --filter=substr, --filter-ci
- Execution & output
  - --ci, --summary, --quiet, --fail-on-skip, --top-slowest=N
  - --junit=path, --json=path
- Notes: list-json defaults to alpha sort, case-insensitive

## Environment Defaults
- FAFAFA_TEST_JUNIT_FILE  Default path for --junit when not provided
- FAFAFA_TEST_JSON_FILE   Default path for --json when not provided

## Exit Codes
- 0: pass; 1: fail or skip with --fail-on-skip; 2: runner error (e.g., file write)

## Helper Scripts
- One-click run
  - Windows: scripts/run-tests-ci.ps1  (-FailOnSkip, -TopSlowest=N)
  - Bash:    scripts/run-tests-ci.sh   (FAIL_ON_SKIP=1/0, TOP_SLOWEST=N)
- List tests (stable JSON)
  - Windows: scripts/list-tests.ps1 (-Filter, -CI, -Pretty, -Sort alpha|none, -SortCase, -DebugRaw)
  - Bash:    scripts/list-tests.sh  (PRETTY_JSON=1, SORT_MODE=alpha|none, SORT_CASE=1, DEBUG_RAW=1; $1 as Filter)

Examples
- PS:   powershell -File scripts\list-tests.ps1 -CI -Pretty
- Bash: PRETTY_JSON=1 SORT_MODE=none SORT_CASE=1 ./scripts/list-tests.sh core

Troubleshooting
- Use -DebugRaw (PS) / DEBUG_RAW=1 (Bash) to print primary/fallback status
- Verify tests.exe -l prints XML; check stderr for errors if exit code is 2
