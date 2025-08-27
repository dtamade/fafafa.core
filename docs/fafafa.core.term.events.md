# fafafa.core.term 事件语义与合并策略

本页阐述 term_events_collect 的推荐行为、事件合并策略与测试建议。

## 1. 事件分类（示例）
- 键盘：KeyDown/KeyUp（含扩展键）、Text（UTF-8/UTF-32 输入）
- 鼠标：Move、Down/Up、Wheel、Drag（可选）
- 终端：Resize、Focus（可选）

## 2. 采集策略（阻塞/超时）
- 阻塞模式：term_events_collect(Timeout=-1) 阻塞直到至少 1 个事件
- 超时模式：Timeout>=0；推荐小于帧预算（如 8–16ms）
- 空转优化：若采样为空，允许 sleep 小间隔释放 CPU

## 3. 合并策略（推荐）
- 鼠标移动（Move）合并：
  - 合并窗口：同一采样周期内的连续 Move 仅保留最后一个（或限 N 个）
  - 边界：若期间夹杂按键/点击/滚轮，则切断合并
- 鼠标滚轮（Wheel）合并：
  - 连续同方向滚轮事件可聚合为累计 delta，限定最大聚合量
  - 方向变化或中断事件（键盘/点击）终止聚合
- 尺寸变化（Resize）：
  - 允许压缩多次 Resize，仅输出最终尺寸；但应保证至少 1 个 Resize 传达发生

## 4. 测试建议
- 事件顺序：保持先后顺序；合并仅在同类且无关键事件间隔的情况下发生
- 可重复性：为合成事件提供 deterministic 输入序列，避免时序偶然性
- 合并断言：
  - 移动：给定 5 次移动 + 1 次键按下 → 预期产出 1 次移动（最后坐标）+ 键事件
  - 滚轮：给定 4 次向上滚轮 → 预期合并为 1 次 delta=+4（或上限值）
- 阻塞采样：设置较小 Timeout，多帧采样收集再断言

## 5. 兼容与降级
- 若后端无法稳定提供原子事件流，应保证：
  - 不崩溃、不丢关键（点击/键盘）事件
  - 合并策略可禁用（回退到逐条事件）

## 6. 运行期开关（Feature Toggles）
- 支持通过环境变量启停合并/去抖策略，默认均为开启。
- 摘要
  - 环境变量（默认开；设置为 0/false 关闭）：
    - FAFAFA_TERM_COALESCE_MOVE：控制“鼠标移动合并”
    - FAFAFA_TERM_COALESCE_WHEEL：控制“滚轮同向合并”
    - FAFAFA_TERM_DEBOUNCE_RESIZE：控制“尺寸变化去抖”
  - 运行时 API（可随时覆盖环境变量的默认值）：
    - term_set_coalesce_move / term_get_coalesce_move
    - term_set_coalesce_wheel / term_get_coalesce_wheel
    - term_set_debounce_resize / term_get_debounce_resize
- 详情：partials/term.events.feature_toggles.md

---
与 docs/fafafa.core.term.ui_loop.md 配合阅读，以便在帧循环中合理消费与绘制。
