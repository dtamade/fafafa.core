# fafafa.core.color

## 概述
- 提供跨平台、与终端/UI 友好的颜色类型与转换工具：RGBA/HSV/HSL、sRGB<->Linear、WCAG 对比度、终端降级映射（xterm256/ANSI16）。
- 目标：解耦颜色算法与终端模块，使 UI/Term 共用一致的颜色语义层。

## 设计原则
- 与现有模块风格保持一致（facade + 纯函数为主）。
- 优先跨平台，避免平台特定 API。
- 参考现代语言生态（Rust palette、Go image/color、Java AWT/Color），接口扁平、职责单一。

## 核心类型
- color_rgba_t: RGBA 8-bit，r,g,b,a 字节顺序（默认 a=255）。
- color_hue_t/color_percent_t：色相与百分比范围，保证边界安全。
- 命名色常量：COLOR_BLACK/WHITE/RED/...（typed-const 形式，跨模块可直接使用）。
  - CSS 小集：SILVER/MAROON/OLIVE/NAVY/TEAL/PURPLE/FUCHSIA/LIME/AQUA/BROWN/PINK/CORAL/GOLD/SKYBLUE/INDIGO/DODGERBLUE 等。

## API（稳定集）
- 构造：color_rgb/rgba，color_to_hex/color_from_hex。
- 转换：color_from_hsv/hsl，color_to_hsv/hsl。
- sRGB<->Linear：srgb_u8_to_linear，linear_to_srgb_u8。
- 亮度/对比度：color_luminance，color_contrast_ratio（WCAG 2.1）。
- 合成：color_blend_over（sRGB 空间），color_blend_over_linear（线性光域，推荐用于物理正确合成）。
- 前景色建议：color_suggest_fg_for_bg，color_suggest_fg_for_bg_default（从黑/白中选对比度更高者）。
- 终端降级：color_rgb_to_xterm256，color_rgb_to_ansi16（与 fafafa.core.term 算法一致）；反向映射：color_xterm256_to_rgb，color_ansi16_to_rgb（注意为近似中心值/灰阶带近似）。
- OKLab/OKLCH 转换：color_to_oklab/oklch，color_from_oklab/oklch；oklab↔oklch 互转。
- 色域策略（OKLCH→sRGB）：gamut_mapping_t（GMT_Clip/GMT_PreserveHueDesaturate）；color_from_oklch_gamut(lch, strategy)。
- 插值：color_mix_srgb，color_mix_linear，color_mix_oklab，color_mix_oklch（支持 hue 最短路径）。
- 调色板：palette_interp_mode_t（PIM_SRGB/LINEAR/OKLAB/OKLCH），palette_sample(a,b,t,mode[,shortestHuePath])；palette_sample_multi(colors,t,mode[,shortestHuePath])；palette_sample_multi_with_positions(colors,positions,t,mode[,shortestHuePath, normalizePositions])。
- 调色板（结构化 API）：color_palette_t；palette_init_even / palette_init_with_positions / palette_sample_struct（内部重用 multi/with_positions 实现）。
- 调色板（策略对象化）：IPaletteStrategy / TPaletteStrategy；CreateEven/WithPositions、Sample(t)、Serialize() 与 palette_strategy_deserialize()；适合共享与序列化持久化。

- 调色板（策略对象化：Setters 与编辑/校验）
  - 运行时 Setters：SetMode/SetShortestHuePath/SetNormalizePositions/SetColors/SetPositions
  - 编辑与校验：AppendColor/InsertColor/RemoveAt/Clear/Validate
  - 序列化：Serialize()（positions 使用小数点）；反序列化：palette_strategy_deserialize()（接受逗号并转换为点号）

### 解析与可访问性注意事项（重要）
- color_from_hex 目前仅支持 6 位 #RRGGBB/RRGGBB；非法输入将返回黑色
- 推荐使用 color_try_from_hex(s, out c):Boolean 以避免静默失败
- color_contrast_ratio 忽略 alpha，若需要比较半透明前景，请先对背景进行合成（color_blend_over）后再计算
- color_suggest_fg_for_bg 会在黑/白中选择对比度更高者，当前不强制满足传入的最小对比度阈值；若需强制策略请在上层进行颜色调整或后续使用“enforced”变体
- 新增 API：color_from_hex_rgba / color_try_from_hex_rgba，支持 #RGB/#RGBA/#RRGGBBAA/0x 前缀（失败返回 False 或回退为不透明黑）
- 新增 API：color_lighten_oklch / color_darken_oklch（仅调整 OKLCH 的 L，保持 a/alpha 不变）



## 与 fafafa.core.term 的关系
- 该模块抽取了 term 中的颜色降级逻辑等算法，供 UI/term 复用。
- 后续可在 term 中用本模块替换重复实现，降低耦合。

## 最佳实践
- 合成空间：
  - UI/绘制建议使用 color_blend_over_linear（线性光域），减少伽马压缩带来的偏色/发灰；保留 color_blend_over 作为 sRGB 空间的快速近似。
- 色域策略（OKLCH→sRGB）：
  - 默认裁剪（Clip）至 [0,255]。已提供策略枚举（PreserveHueDesaturate）：在保持色相与明度的前提下降饱和回到 sRGB，且采用“最大在域内的 C”二分搜索，尽量减少去饱和程度。
  - 若需要严格一致性，请将整个流水线在 OKLCH/OKLab 内进行插值/调整，最后一步再映射到 sRGB。
- 性能：
  - srgb_u8_to_linear 使用 256 项查表（保持与公式等价）；linear_to_srgb_u8 保持精准公式实现。
  - 终端映射使用表驱动常量（xterm256 立方体中心值、灰阶带近似），适合高频路径。

- 策略示例：OKLCH → sRGB（Clip vs PreserveHueDesaturate）
  - 需求：保持色相与明度，尽量减少色偏，将越界高饱和度色回到 sRGB。
  - 代码示例：

    ```pascal
    var lch: color_oklch_t; cClip, cPreserve: color_rgba_t;
    begin
      lch.L := 0.7; lch.C := 0.5; lch.h := 350; // 可能越界的高饱和度色
      // 传统裁剪（与 color_from_oklch 等价）
      cClip := color_from_oklch_gamut(lch, GMT_Clip);
      // 保持色相降饱和（二分降低 C 直至入域）
      cPreserve := color_from_oklch_gamut(lch, GMT_PreserveHueDesaturate);
      // 提示：cPreserve 与 cClip 通常在视觉上更接近输入的色相
    end;
    ```

  - 注意：
    - Preserve 采用固定 L/h、仅降低 C 的策略，能较好地保持色相；但接近色域边界时 L/h 可能存在微小偏移（数值迭代与矩阵运算误差）。
    - 若需要更强的“感知保持”，可考虑在上层用 OKLab/OKLCH 进行插值/混合，并减少越界的概率。


## 示例
```pascal
uses fafafa.core.color;
var c, fg, a, b, m, p: color_rgba_t; idx: Byte; arr: array[0..2] of color_rgba_t;
begin
  c := color_from_hsv(200, 60, 90);
  WriteLn(color_to_hex(c));
  idx := color_rgb_to_xterm256(c.r, c.g, c.b);
  fg := color_suggest_fg_for_bg_default(c);
  // OKLCH 最短路径插值
  a := color_from_oklch((L:0.7; C:0.1; h:350));
  b := color_from_oklch((L:0.7; C:0.1; h:10));
  m := color_mix_oklch(a, b, 0.5, True);
  // Palette 统一采样（双点）
  p := palette_sample(a, b, 0.5, PIM_OKLCH, True);
  // Palette 统一采样（多点，等分）
  arr[0] := COLOR_RED; arr[1] := COLOR_GREEN; arr[2] := COLOR_BLUE;
  p := palette_sample_multi(arr, 0.6, PIM_SRGB);
  // Palette 统一采样（多点，非均匀 positions，支持归一化）
  p := palette_sample_multi_with_positions(arr, [10.0, 20.0, 70.0], 15.0, PIM_SRGB, False, True);
  WriteLn('xterm256=', idx, ' fg=', color_to_hex(fg), ' mix=', color_to_hex(m), ' palette=', color_to_hex(p));
end.
```


### 策略对象化示例（Pascal）
```pascal
uses fafafa.core.color;
var arr: array[0..2] of color_rgba_t; S,D: IPaletteStrategy; t: Single; c1,c2: color_rgba_t; json: string;
begin
  arr[0] := COLOR_RED; arr[1] := COLOR_GREEN; arr[2] := COLOR_BLUE;
  // 构造策略（positions + OKLCH + 最短路径）
  S := TPaletteStrategy.CreateWithPositions(PIM_OKLCH, arr, [0.0, 0.2, 1.0], True, False);
  t := 0.2; c1 := S.Sample(t);
  // 序列化
  json := S.Serialize;
  // 反序列化
  if palette_strategy_deserialize(json, D) then begin

### 从文件加载策略（最佳实践）
```pascal
uses SysUtils, fafafa.core.color;
var s: string; PS: IPaletteStrategy;
begin
  s := ReadFileToString('examples'+PathDelim+'fafafa.core.color'+PathDelim+'palette_strategy.json');
  // 若无 ReadFileToString，可参考示例中的 ReadAllText 简易实现
  PS := palette_strategy_from_text(s);
  if PS<>nil then begin
    WriteLn('Loaded strategy, count=', PS.Count);
    WriteLn(color_to_hex(PS.Sample(0.2)));
  end;
end.
```
提示：示例工程 palette_demo.lpr 已包含 ReadAllText 简易实现，并默认加载 examples/fafafa.core.color/palette_strategy.json。

#### 带错误信息的加载（推荐）
```pascal
uses SysUtils, fafafa.core.color;
var s, err: string; P: IPaletteStrategy;
begin
  s := ReadFileToString('examples'+PathDelim+'fafafa.core.color'+PathDelim+'palette_strategy.json');
  if not palette_strategy_from_text_ex(s, P, err) then
    WriteLn('Load strategy error: ', err)
  else
    WriteLn('Load strategy ok: count=', P.Count);
end.
```
```

### 示例策略 JSON（数值枚举与备用方案）
- 数值枚举形式（当前解析器支持）：
```json
{"mode":3,"shortest":1,"usePos":1,"norm":0,"colors":["#FF0000","#00FF00","#0000FF"],"positions":[0,0.2,1]}
```
- 备用策略（已随示例提供：examples/fafafa.core.color/palette_strategy_alt.json）：
```json
{"mode":0,"shortest":0,"usePos":1,"norm":1,"colors":["#202020","#FFD700","#FF8C00"],"positions":[0,0.5,1]}
```
- 可读性更高的方案（模式名字符串）：
```json
{"mode":"OKLCH","shortest":true,"usePos":true,"norm":false,
 "colors":["#FF0000","#00FF00","#0000FF"],"positions":[0,0.2,1]}
```
说明：当前轻量解析器仅支持数值枚举（0=sRGB,1=Linear,2=OKLab,3=OKLCH）。若需使用模式名字符串，可在上层先将字符串映射为数值再调用反序列化，或扩展解析器以直接接受字符串模式名。


    c2 := D.Sample(t);
    // c1 与 c2 应近似相等（每通道差 <= 1）
  end;
end.
```

### Clip vs Preserve 对照（OKLCH→sRGB）
- 运行：examples\fafafa.core.color\RunClipVsPreserve.bat
- 示例程序：examples/fafafa.core.color/example_clip_vs_preserve.lpr
- 参考输出：examples/fafafa.core.color/clip_vs_preserve_sample.txt
- 说明：Clip 为直接裁剪；PreserveHueDesaturate 通过二分搜索“最大在域内的 C”以更好保持色相与明度。

## 验证与基线
- In-gamut 判定（测试使用）：采用 OKLCH→OKLab→线性→sRGB 的浮点路径（不夹取），并使用内缩安全范围 (1e-5, 1-1e-5) 判断每通道是否在域内，避免边界样本因数值误差被误分类。
- 等值容差（in-gamut 样本）：在 sRGB 量化与矩阵浮点误差下，将“等值”定义为每通道绝对差 ≤ 1。建议贡献者在新的 in-gamut 等值断言中采用同样容差以保持一致性。
- Preserve 策略性质断言（out-of-gamut 样本）：验证转换后 RGB 入域、OKLCH 的 L/h 近似保持（例如 L≤0.02、h≤2°），且色度 C 不增（允许极小数值误差）。
- 运行与报告：
  - 构建与运行：tests/fafafa.core.color/BuildOrTest.bat test
  - 文本日志：bin/tests_color_last_run.txt；XML 报告：bin/tests_color.xml

## 后续扩展
- Named colors/主题色板（扩展更多 CSS 常量）；OKLab/OKLCH；色盲模拟；调色板生成与和谐方案。
- 提供在不满足阈值时的“备选策略”，如保持 hue 的同时提升对比度。

## 示例与一键脚本
- 可运行示例：
  - 工程：examples/fafafa.core.color/palette_demo.lpi
  - 主程序：examples/fafafa.core.color/palette_demo.lpr
- 一键脚本：
  - Windows 批处理：examples\fafafa.core.color\RunDemo.bat
  - Windows PowerShell：examples\fafafa.core.color\RunDemo.ps1
  - Unix/macOS：examples/fafafa.core.color/run_demo.sh
- 快速运行：
  - CMD：examples\fafafa.core.color\RunDemo.bat
  - PowerShell：./examples/fafafa.core.color/RunDemo.ps1
  - Unix/macOS：bash examples/fafafa.core.color/run_demo.sh
- 输出日志：examples/fafafa.core.color/palette_demo.log
- 说明：示例仅依赖本模块（src/fafafa.core.color.pas），不改动 term 模块。


