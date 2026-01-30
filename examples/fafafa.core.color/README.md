# fafafa.core.color palette_demo

一个最小可运行的控制台示例，用于对比四种插值空间（sRGB/Linear/OKLab/OKLCH）的中点效果，以及演示调色板多点采样（等分与非均匀 positions+归一化）。

## 先决条件
- 本仓库已能用 lazbuild 构建（Windows/Win64 环境）
- 无需改动 term，仅依赖 src/fafafa.core.color.pas

## 构建
建议使用项目随附的脚本（会自动定位 lazbuild）：

```
tools\lazbuild.bat --build-mode=Debug examples\fafafa.core.color\palette_demo.lpi
```

成功后会在 bin\ 目录生成 `palette_demo.exe`。

## 运行
```
bin\palette_demo.exe
```

示例将输出：
- Mix comparison (t=0.5)：分别打印 sRGB、Linear、OKLab、OKLCH 四种模式在 t=0.5 的混合结果（十六进制）
- Palette sampling：
  - 等分三节点调色板在 t=0.6 的采样（sRGB）
  - 非均匀 positions=[10,20,70]，t=15，在归一化开启（normalizePositions=True）下的采样

输出形如：
```
== Mix comparison (t=0.5) ==
sRGB  : #RRGGBBFF
Linear: #RRGGBBFF
OKLab : #RRGGBBFF
OKLCH : #RRGGBBFF

== Palette sampling ==
Equal 3-stop t=0.6 (sRGB): #RRGGBBFF
Positions [10,20,70], t=15 norm: #RRGGBBFF
```

注：色值仅示例；实际将随算法计算而变。

## 参考

## 策略对象化（可序列化/可共享）
- 示例使用：在 palette_demo.lpr 中演示了 TPaletteStrategy 的构造、Sample、Serialize、反序列化再 Sample 的过程
- 序列化样例（JSON-like，无转义）：
  ```
  {"mode":3,"shortest":1,"usePos":1,"norm":0,"colors":["#FF0000","#00FF00","#0000FF"],"positions":[0,0.2,1]}
  ```
- 说明：反序列化使用 palette_strategy_deserialize(s, out obj)。该格式主要用于快速持久化或跨模块共享，无需额外依赖。

- 文档：docs/fafafa.core.color.md（已含 OKLab/OKLCH、Palette、positions+normalizePositions 的说明与示例）
- 单元测试：tests/fafafa.core.color/*（包含进阶与性质测试，确保实现稳健）



## 一键运行脚本
- Palette Demo（推荐，自动构建并运行，输出保存到日志）：
  - examples\fafafa.core.color\RunDemo.bat
  - examples\fafafa.core.color\RunDemo.ps1
  - Unix/macOS：bash examples/fafafa.core.color/run_demo.sh

- Clip vs Preserve 对照（编译并运行展示两种策略的 RGB 差异）：
  - examples\\fafafa.core.color\\RunClipVsPreserve.bat
  - 参考输出样例：examples/fafafa.core.color/clip_vs_preserve_sample.txt

提示：在仓库根目录执行上述脚本，即可自动构建并运行对应示例。
