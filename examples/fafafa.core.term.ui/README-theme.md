# term.ui 共享颜色策略演示（主题切换）

本示例（example_term_ui.lpr）支持从颜色模块的 JSON-like 配置加载共享调色板策略，并在运行时切换：

- 启动时：加载 examples/fafafa.core.color/palette_strategy.json
- 按 R：重新加载 palette_strategy.json（热重载）
- 按 S：切换到备用策略 examples/fafafa.core.color/palette_strategy_alt.json

状态栏会显示当前加载状态（OK 或错误原因），状态栏的前景色来自共享策略的采样（t=0.2）。

提示：策略 JSON 为轻量 JSON-like 文本，支持：
- mode：调色空间（数字枚举：0=sRGB,1=Linear,2=OKLab,3=OKLCH）
- shortest：OKLCH 插值是否走最短路径（1/0）
- usePos：是否启用 positions（1/0）
- norm：positions 是否归一化（1/0）
- colors：字符串数组（#RRGGBB）
- positions：数值数组（小数点），反序列化时也接受逗号形式

如需严格 JSON 支持，可在上层替换为标准 JSON 解析器；目前示例为零依赖实现。
