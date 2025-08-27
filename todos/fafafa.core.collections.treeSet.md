# 开发计划日志 · fafafa.core.collections.treeSet

日期：2025-08-20
负责人：Augment Agent

## 目标（本阶段）
- 建立 TreeSet（RB）测试工程，验证现有 TRBTreeSet<T> 功能与契约
- 对齐测试规范（UTF8、Debug、heaptrc、bin/lib 输出）

## 待办清单
- [ ] 新建测试工程骨架 tests/fafafa.core.collections.treeSet/
  - [ ] tests_treeSet.lpi/.lpr
  - [ ] Test_TRBTreeSet_Complete.pas（标准 TTestCase）
  - [ ] BuildOrTest.bat（Windows）/BuildOrTest.sh（Linux）
- [ ] 覆盖用例：
  - [ ] Test_Create_Destroy
  - [ ] Test_Insert_Contains_Duplicate
  - [ ] Test_Ordered_Iteration
  - [ ] Test_LowerBound_UpperBound
  - [ ] Test_AppendUnChecked_Serialize
  - [ ] Test_Clear_Zero_Reverse_NoEffect
- [ ] 门面对齐（可选）：MakeTreeSet<T> 工厂声明与实现

## 备注
- 暂不涉及 CI；仅本地 lazbuild 构建与执行
- 参考：tests/fafafa.core.collections.vecdeque/ 的 lpi/lpr 与 BuildOrTest 脚本

