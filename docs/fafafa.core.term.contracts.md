# fafafa.core.term 核心合约（Contracts）

本页约定了终端模块在调用与状态上的关键契约，帮助编写可靠的上层代码与测试。

## 1. 生命周期（term_init / term_done）

- term_init 成功后：
  - 建立当前终端上下文 term_current，可进行写入与能力探测
  - 可能切换/保存底层模式（如 Windows ConsoleMode）
- term_done 必须与 term_init 成对调用：
  - 负责恢复被修改的底层状态（ConsoleMode、Quick Edit 等）
  - 释放句柄/缓冲，避免资源泄漏
- 作用域范式（推荐）：
  ```pascal
  term_init; try
    // …使用 term_*
  finally
    term_done;
  end;
  ```

## 2. 基础属性（term_size / term_name / color depth）

- term_size(out W, H): Boolean
  - 成功返回 True，且 W>0 且 H>0
  - 若返回 False 或尺寸为 0，应视为终端尚未就绪
- term_name: string
  - 非空且不应为 "unknown"；否则视为环境不明确
- 颜色深度（term_color_depth/term_support_color）
  - 若能力不确定，应返回保守值或 False

## 3. 事件与输入（term_events_collect）

- 事件收集应满足：
  - 不丢失：按时间顺序产出；滚轮/移动合并策略在文档中明确
  - 可阻塞：提供阻塞/超时版以降低空转
  - 线程安全：若不支持并发，文档中应明确“单线程调用”限制
- Windows 输入路径：
  - 使用 ReadConsoleInputW，保证 Unicode 与扩展键的准确性
  - 鼠标启用时临时关闭 Quick Edit，退出时恢复

## 4. 功能开关与恢复（protocol toggles）

- 支持检测：term_support_* 判定后才调用对应 enable/disable
- 恢复契约：
  - 任意 enable 成功后，disable 必须可幂等恢复
  - 测试中在 finally 中恢复：
    ```pascal
    if term_support_alternate_screen then begin
      CheckTrue(term_alternate_screen_enable(True));
      // …测试…
    finally
      term_alternate_screen_disable;
    end;
    ```

## 5. 交互环境假设（AssumeInteractive）

- 多重判据（任一不满足即视为非交互）：
  1) IsATTY 为真（若可用）
  2) term_init 成功
  3) term_size(W,H) 为正
  4) term_name 非空且非 "unknown"
- 在测试中：
  - if not TestEnv_AssumeInteractive(Self) then Exit;
  - 需要 term_current 的代码块必须包裹 term_init/term_done

## 6. 错误与降级

- term_* 返回 False 时，视为“能力不可用/暂不可用”，上层应降级或跳过
- 避免用异常作为常规分支；异常仅用于不变量被破坏或参数非法


## 7. 线程安全与错误模型（新增）

- 错误模型
  - 能失败的 API 推荐引入 (ok:boolean, code:term_errcode_t, msg:string) 或 term_result_t；现有 Boolean 返回保持兼容
  - term_last_error 仅用于调试场景，不保证并发；不建议作为业务分支依据
- 线程安全
  - 输出与事件 API 默认在单线程上下文使用；如需并发，调用方负责同步或使用后续提供的序列化接口
- 配置优先级
  - 编译期默认 < 环境变量（init 时读取一次） < 运行时 Setter（即时生效）
  - 建议提供 term_get_effective_config 快照导出

## 8. 事件合并与去抖（新增）

- Collect(frame_budget) 边界
  - 鼠标 move：同帧内合并，跨 Collect 不合并
  - 滚轮：方向反转或被按键/点击分隔则切段
  - Resize：去抖期间仅保留最后一个尺寸；遇到非 Resize 事件立即停止去抖并产出当前保留的尺寸

## 9. UI 帧式 diff 策略（新增）

- 后端能力检测：若后端实现了 IUiBackendV2（如内存后端），默认采用“整行重绘优先”以保证第二帧一致性
- 可通过环境变量开关覆盖（参见下节）

## 10. 诊断与控制开关（新增）

- FAFAFA_TERM_UI_FORCE_LINE_REDRAW=1|0
  - 1：强制整行重绘；0：按阈值与差异段规则
  - 默认：仅 IUiBackendV2 后端视为 1，其它后端按原逻辑
- FAFAFA_TERM_TRACE=info|debug（建议后续实现）
  - 打开内部关键路径的诊断日志，不改变行为，仅便于现场排查

## 7. 线程安全与错误模型（新增）

- 错误模型
  - 能失败的 API 推荐引入 (ok:boolean, code:term_errcode_t, msg:string) 或 term_result_t；现有 Boolean 返回保持兼容
  - term_last_error 仅用于调试场景，不保证并发；不建议作为业务分支依据
- 线程安全
  - 输出与事件 API 默认在单线程上下文使用；如需并发，调用方负责同步或使用后续提供的序列化接口
- 配置优先级
  - 编译期默认 < 环境变量（init 时读取一次） < 运行时 Setter（即时生效）
  - 建议提供 term_get_effective_config 快照导出

## 8. 事件合并与去抖（新增）

- Collect(frame_budget) 边界
  - 鼠标 move：同帧内合并，跨 Collect 不合并
  - 滚轮：方向反转或被按键/点击分隔则切段
  - Resize：去抖期间仅保留最后一个尺寸；遇到非 Resize 事件立即停止去抖并产出当前保留的尺寸

## 9. UI 帧式 diff 策略（新增）

- 后端能力检测：若后端实现了 IUiBackendV2（如内存后端），默认采用“整行重绘优先”以保证第二帧一致性
- 可通过环境变量开关覆盖（参见下节）

## 10. 诊断与控制开关（新增）

- FAFAFA_TERM_UI_FORCE_LINE_REDRAW=1|0
  - 1：强制整行重绘；0：按阈值与差异段规则
  - 默认：仅 IUiBackendV2 后端视为 1，其它后端按原逻辑
- FAFAFA_TERM_DIFF_LINE_THRESHOLD=0..1
  - 行内差异阈值（默认 0.35）；设置负值可恢复默认
- FAFAFA_TERM_TRACE=info|debug（建议后续实现）
  - 打开内部关键路径的诊断日志，不改变行为，仅便于现场排查

---
本页作为“契约基线”，后续变更应同步更新，确保上层与测试的一致性。
