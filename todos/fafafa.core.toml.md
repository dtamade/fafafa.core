# fafafa.core.toml 开发计划与待办

更新时间：2025-08-15
负责人：Augment Agent

## 近期计划（短闭环）
1) 对齐 Writer 输出策略
   - [x] 默认含空格（`key = value`）；`twfSpacesAroundEquals` 作为显式控制标志保留（当前与默认一致）。
   - [x] docs/fafafa.core.toml.addendum.md 已对齐“默认含空格”的描述与示例。
2) Writer 增量完善
   - [ ] 更复杂的嵌套/混合结构快照用例，覆盖 Pretty+SortKeys 组合。
   - [ ] 时间类型 Writer 输出固定 RFC3339 形态验证。
3) Reader 健壮性
   - [ ] 边界错误定位一致性回归（SetError/SetErrorAtStart 策略文档化）。
4) 性能与工程化
   - [ ] 大文档基准与回归脚本（可复用 tests/BuildOrTest.bat）。

## 备注
- 继续保持接口优先、小步快跑与稳定回归。
