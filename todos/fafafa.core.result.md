# fafafa.core.result TODO（迭代清单）

- [x] 运行 tests/fafafa.core.result/buildOrTest.bat test 并修复编译/测试失败
- [x] 增补组合子：MapOr、MapOrElse、Inspect、InspectErr（含指针重载）
- [x] 提供 Match/Fold 与谓词：ResultMatch/ResultFold/ResultIsOkAnd/ResultIsErrAnd
- [x] ToDebugString 调试输出
- [ ] ToString 输出增强：Ok(v)/Err(e) 友好的调试文本（受限于泛型 T/E 的 ToString 能力）
- [ ] 计划 Option<T> 模块（互转 Some/None）
- [x] 文档：加入错误示例/最佳实践；与 fafafa.core.test 结合示例

下一步（短期）
- [x] Examples：添加 example_result_basics 与 example_chaining
- [x] Plays：添加快速验证 example_result_play（替换为 examples 下两个最小示例）
- [x] 在 docs 增补 Match/Fold/Predicates 片段

后续（可选）
- [ ] 方法式镜像：为 And/Or/Contains*/FilterOrElse/ResultToTry/Transpose 提供宏控方法式 API
- [ ] API 索引表维护：在 docs 顶部加入分组索引表
- [ ] 变体布局宏说明：加一段风险提示与类型限制示例
