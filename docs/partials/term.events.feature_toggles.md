# 运行期开关（事件合并/去抖）

本模块支持两类方式控制事件合并/去抖行为：
- 环境变量：在 term_init 时读取并设置默认值
- 运行时 API：在进程运行期间随时覆盖默认值（优先级更高）

环境变量
- FAFAFA_TERM_COALESCE_MOVE
  - 含义：控制“鼠标移动（tms_moved）合并”
  - 默认：开启（未设置变量时）
  - 关闭：设置为 "0" 或 "false"（大小写不敏感）

- FAFAFA_TERM_COALESCE_WHEEL
  - 含义：控制“滚轮同向合并（wheel_up/down/left/right）”
  - 默认：开启
  - 关闭：设置为 "0" 或 "false"

- FAFAFA_TERM_DEBOUNCE_RESIZE
  - 含义：控制“尺寸变化（tek_sizeChange）去抖（连续保留最后一条）”
  - 默认：开启
  - 关闭：设置为 "0" 或 "false"

运行时 API（可随时覆盖）
- term_set_coalesce_move(True/False) / term_get_coalesce_move
- term_set_coalesce_wheel(True/False) / term_get_coalesce_wheel
- term_set_debounce_resize(True/False) / term_get_debounce_resize

实现注意事项
- 工程集中在 src/fafafa.core.settings.inc 启用 {$MACRO ON} 以便集中配置；但在 fafafa.core.term 单元中（包含 settings.inc 之后）关闭值式宏展开 {$MACRO OFF}，防止值宏对 API 标识符造成替换干扰。
- 建议新增开关使用前缀 FAFAFA_TERM_FEATURE_* 或纯布尔宏，仅用于 {$IFDEF} 判断，避免与运行时 API 名重名。
- 运行期覆盖优先级：环境变量（term_init 读取） < 运行时 Setter/Getter（随调随改）。

备注
- 环境变量仅在 term_init 时读取；之后可用运行时 API 覆盖。
- 合并/去抖仅影响当前一次 term_events_collect 调用的输出序列，队列内部顺序不改变。
- 与容量限制共同作用：当输出数组容量不足时，多余事件会留给后续帧处理。

测试覆盖
- 单元测试：tests/fafafa.core.term/Test_term_events_feature_toggles.pas
  - Test_Coalesce_Move_On_Off：验证移动合并开关
  - Test_Coalesce_Wheel_On_Off：验证滚轮合并开关
  - Test_Debounce_Resize_On_Off：验证尺寸去抖开关
- 运行示例：tests_term.exe -a -p --format=plain（在 tests/fafafa.core.term 目录下）

示例（Windows PowerShell）
- 关闭滚轮合并：
  $env:FAFAFA_TERM_COALESCE_WHEEL = '0'
- 关闭移动合并：
  $env:FAFAFA_TERM_COALESCE_MOVE = 'false'
- 关闭 Resize 去抖：
  $env:FAFAFA_TERM_DEBOUNCE_RESIZE = '0'

示例（Windows CMD）
- set FAFAFA_TERM_COALESCE_WHEEL=0
- set FAFAFA_TERM_COALESCE_MOVE=false
- set FAFAFA_TERM_DEBOUNCE_RESIZE=0

