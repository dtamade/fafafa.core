# fafafa.core.term UI 帧循环与双缓冲 diff（最小雏形）

本页提供一个基于 term_events_collect 的帧式 UI 循环与双缓冲 diff 的最小说明与模板。

## 1. 目标
- 流畅：将输入采样与渲染限制在每帧预算（如 16ms）
- 减少闪烁：使用双缓冲（front/back）并输出最小 diff
- 降低写入：仅输出差异字符/属性，合并移动/滚轮事件

## 2. 数据结构（简化示例）
- BackBuffer/FrontBuffer：二维字符 + 属性
- DirtyRegion：本帧需要刷新的矩形/行集合
- EventQueue：本帧采样到的事件（已合并）

## 3. 帧循环（伪代码）
```pascal
const FrameBudgetMs = 16;
var lastTick, now: QWord; remain: Integer;

while not quit do
begin
  lastTick := GetTickCount64;

  // 1) 采样输入（合并策略由 term 实现）
  term_events_collect(EventQueue, TimeoutMs := 0);

  // 2) 更新状态（根据事件修改 BackBuffer/状态机）
  HandleEvents(EventQueue);

  // 3) 生成 diff（Back vs Front），记录 DirtyRegion
  ComputeDiff(BackBuffer, FrontBuffer, DirtyRegion);

  // 4) 输出 diff（按行/块写出；避免多余定位）
  PaintDiff(DirtyRegion);

  // 5) 交换缓冲
  Swap(BackBuffer, FrontBuffer);

  // 6) 帧率控制（sleep 到预算）
  now := GetTickCount64;
  remain := FrameBudgetMs - Integer(now - lastTick);
  if remain > 0 then Sleep(remain);
end;
```

## 4. 双缓冲 diff 关键点
- 坐标系：统一左上(0,0)；跨平台时注意 Windows/Unix 差异
- 字符宽度：emoji/全宽字符的列宽处理（必要时以 UTF-32 渲染层封装）
- 光标策略：渲染后统一定位；必要时隐藏光标减少闪烁

## 5. 测试建议
- 纯算法层：
  - Diff 计算：给定 front/back 栈，断言 DirtyRegion 覆盖正确
  - Swap 语义：交换后 front 应与上一帧 back 一致
- 集成层（交互前置）：
  - if not TestEnv_AssumeInteractive(Self) then Exit;
  - 作用域内 term_init/term_done，帧循环限制迭代次数（如 10 帧）
  - 注入合成事件（移动/滚轮）验证 PaintDiff 最小写出行为（可计数）

## 6. 输出最小化策略
- 行合并：连续脏行合并写出
- 跳过空白：空白尾部不输出
- 属性分段：同属性段合并输出，减少切换

---
后续可引入基于 ratatui/bubbletea 的设计灵感：将状态更新与渲染分层，提供 Msg（事件）/Update（状态）/View（渲染）三段式接口。
