# 开发计划日志 - fafafa.core.mem.pool.fixed

## 今日更新
- 新增 ZeroOnAlloc 功能：
  - 构造参数 TFixedPoolConfig.ZeroOnAlloc 控制；
  - Alloc 时按需 FillChar 清零；
  - 初次构造时若开启会对整段 Arena 清零（保持确定性）。
- 单元测试（两轮）：
  - 第1轮：增加 Test_ZeroOnAlloc_ClearsMemory；修复 Runner 注册；修正接口生命周期陷阱
  - 第2轮：补充 TryAlloc 成功/失败；构造参数非法；Release 异常（错位、对齐越界、双重释放），现总计 18 项全通过

## 待办（短期）
- [ ] 增加极端参数覆盖：BlockSize=SizeOf(Pointer)；大块（>= 4096）；容量临界值溢出路径。
- [ ] 增加 TryAlloc 行为测试（成功/失败路径）。
- [ ] 增加 ReleasePtr 边界异常路径测试（错位指针、跨块指针、边界指针）。
- [ ] 在 docs/CHANGELOG_fafafa.core.mem.md 记录变更。

## 中期计划
- [ ] 增加 Debug 模式可选污化释放（填充 0xA5），配合 heaptrc 提升 UAF 发现率（保持默认关闭）。
- [ ] 加入简单并发测试（在后续引入线程安全包装后）。
- [ ] 与 fixedSlab 的集成示例：对象分配对比样例与基准。

