# 开发计划日志 - fafafa.core.color

## 现状
- 最小可用版本已提交：RGBA 基础、HSV/HSL、sRGB↔Linear、对比度、终端降级。
- 已新增：命名色常量（子集）与前景色建议 API（默认阈值 4.5）。

## 下一步
- term 整合：已完成 HEX、RGB→256/16、HSV/HSL；继续以 color 模块为单一事实源替换零散辅助（暂不继续侵入 term）。
- 增加：
  - Named colors 常量集：已加入 CSS 小集与别名；继续扩展或拆分至单独单元按需加载
  - OKLab/OKLCH 转换与插值：已完成转换与 color_mix_oklab/oklch 插值；后续增加性质测试
  - 自定义调色板结构与插值/采样 API（支持 sRGB/Linear/OKLab/OKLCH）
  - 对比度提升辅助（当前黑/白二选一；后续考虑更智能策略）
- UI 层：后续按需引入 color_suggest_fg_for_bg_default，不主动修改 term。

## 测试计划
- 随机性质测试：HSV/HSL 往返误差统计（允许阈值）。
- WCAG 对比度基线用例：黑/白、灰阶、常见组合。
- 与 term 的回归一致性：映射结果在边界处条件断言。



## 本轮追加（2025-08-24）
- OKLCH PreserveHueDesaturate 参数微调：maxIters 24→28，epsilon 1e-6→1e-5；收敛后 C 极小内缩 1e-5。
- 新增性质测试：oklch.gamut.props.extra（随机越界、Hue 环绕），oklch.gamut.props.edge（极端 C、高/低 L）。
- 回归：tests_color 79/79 全绿，heaptrc 0 泄漏。

## 下一步建议
- 若无主观差异诉求，保持当前参数；如需更平滑，可考虑在 C 附近对 L 做局部微调（成本较高，暂缓）。
- Palette 策略序列化/编辑 API 小幅易用性增强（保持不侵入 term）。
