# 开发计划：fafafa.core.args

更新时间：2025-08-19

## 现状
- 核心解析与子命令功能稳定，tests_fafafa.core.test 当前 95/95 通过。
- 文档覆盖关键行为（no- 前缀/StopAtDoubleDash/负数歧义/Windows 兼容/合并顺序）。

## 本轮完成（文档微调）
- 新增“与 GetOpt/CustApp 的对比与迁移”小节（docs/fafafa.core.args.md）：
  - 对比三者差异；提供从 GetOpt/CustApp 迁移到 TArgs/IRootCommand 的最小示例
- 更新工作总结报告（report/fafafa.core.args.md）：记录 Zero‑change 基线核验

## 下一步（建议）
1) 文档微调（可选）：补充一段“常见陷阱与规约”（如大小写、负数值、双横线）
2) 轻量增强（不破坏现状）：ENV 解析白/黑名单与类型提示；Usage 渲染可选项
3) 中期规划：ArgsArgvFromYaml（宏控），待依赖成熟

## 风险与注意
- 保持解析行为的单元测试覆盖；新增行为先补测试
- 严控性能路径上的字符串分配；必要时补微基准


## 已完成（2025-08-19）
- [x] Windows 宽字符 argv 收集（FAFAFA_ARGS_WIN_WIDE，默认启用）
- [x] 文档同步：平台/宏说明
- [x] ENV 过滤与值规范化扩展（ArgsArgvFromEnvEx + 新测试）
- [x] 全量回归：95/95 通过

## 下一步（建议）
- [ ] （可选）端到端测试：含中文/emoji 参数的子进程调用示例
- [x] 轻量增强：ENV 白/黑名单与类型提示（ArgsArgvFromEnvEx 已完成）
- [ ] 轻量增强：Usage 渲染选项扩展（不自动打印）
- [ ] （讨论）短选项紧贴值（-Ixxx）行为开关与交互边界
