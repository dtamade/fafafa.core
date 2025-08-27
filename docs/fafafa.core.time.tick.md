# fafafa.core.time.tick（迁移与改良）

本模块是原 `fafafa.core.tick` 的时间测量功能在 time 命名空间下的归位与增强版本。

- 目标：提供纳秒级、跨平台、低开销的时间测量接口，用于基准测试与性能分析
- 核心接口：ITick、ITickProvider；工厂：CreateDefaultTick/CreateTickProvider
- 新增便捷：TStopwatch、TimeItTick（与 fafafa.core.time 的 TDuration 协同）
- 兼容性：旧单元仍存在（带编译期提示），建议逐步迁移到 `fafafa.core.time.tick`

## 使用示例
```pascal
uses fafafa.core.time.tick, fafafa.core.time;

var sw: TStopwatch;
begin
  sw := TStopwatch.StartNew;      // 基于默认 ITick
  DoWork();
  sw.Stop;
  Writeln('elapsed(ns)=', sw.ElapsedNs);
  Writeln('elapsed(ms)=', sw.ElapsedDuration.AsMs);
end;
```

## 与 fafafa.core.time 的关系
- time.tick 专注“测量层”，不引入 Sleep/Deadline 等高层语义
- time 语义层保留 TimeIt（基于单调时钟）；tick 提供 TimeItTick（基于 ITick）
- 两者互补：业务语义优先用 time；微基准优先用 time.tick

## 后续改良路线
- 平台补齐：macOS 支持（mach_absolute_time）
- 常量去重：抽取公共常量单元，time 与 time.tick 共用
- Invariant TSC 标识、校准时长可观测；更多微基准工具（多次测量、去抖动）

