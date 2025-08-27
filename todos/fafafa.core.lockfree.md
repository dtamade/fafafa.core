# todos · fafafa.core.lockfree（本轮计划）

## 近期迭代目标（本周）
1) 契约测试巩固
- 运行 tests/fafafa.core.lockfree/Contracts* 与 test_*interface* 工程，生成当前基线报告
- 若失败：先修 scripts/BuildOrTest.bat 路径与 search path，确保 `{$I ../../src/fafafa.core.settings.inc}`
- 已完成：修复 MM HashMap 构造异常消息，契约断言通过（tests/fafafa.core.lockfree/BuildOrTest.bat test 全绿）。


2) settings.inc 单源化提案
- 不动源码：在报告中确认“发布阶段复制 release/src/fafafa.core.settings.inc”流程
- 后续 PR：删除 release/src 的手改内容，交由脚本生成

3) 原子/内存序加固（已完成 2025-08-16）
- 修正 tagged_ptr 强 CAS 的 var 传参错误
- MPSC（Michael-Scott）与 Treiber 栈读路径改为 acquire 原子读取

4) HashMap 一致性（已完成 2025-08-16）
- OA HashMap.Remove 改为 KeysEqual，统一比较路径

5) CODEPAGE 清理（已完成 2025-08-16）
- 移除 src/fafafa.core.lockfree.util.pas 的 {$CODEPAGE UTF8}

6) 接口演进（下一轮）
- 定义 IQueue/IStack 小接口与能力标注接口；提供门面工厂，现有实现适配接入
- Map 增加 PutEx/RemoveEx 返回旧值/状态枚举；补接口层契约用例

5) 性能回归矩阵
- 在 tests/fafafa.core.lockfree/Run_Micro_* 批处理内，加入 PAD/BO 开关组合
- 输出 logs/*.csv，更新 docs/fafafa.core.lockfree.performance-report.md 的“基准脚本位置”

## 中期目标（下一迭代）
- IQueue/IStack/IMap 接口 HY 双轨固化：TE 适配器与 GI 原型
- HP/EBR 原型：play/fafafa.core.lockfree 下最小可用示例 + 压测

## 注意事项
- 不更改外观 API（门面与别名）
- 小步提交，每步保持可构建与可回滚
- 性能开关默认关闭，仅在基准/压力测试中开启



## 本轮基线验证更新（自动记录）
- 日期：2025-08-18
- 动作：tests/fafafa.core.lockfree/BuildOrTest.bat test
- 结果：50/0/0 通过，heaptrc 未发现泄漏
- 备注：编译日志中的泛型 forward 声明错误为 lazbuild 输出残留，执行阶段构建成功且测试运行正常


## 本轮追加计划（2025-08-18 晚）
- 退避策略
  - 在 TTreiberStack 中落地“自适应退避”（已完成），下一步抽象 BackoffPolicy 接口，推广到各结构。
- 阻塞策略
  - 设计 IBlockingPolicy（条件等待/事件+退避组合），先包裹在适配层，不侵入核心结构。
- 能力接口
  - 起草 IBounded/ICloseable/INonBlocking/IBlocking/IBatchOps 与 ISpsc/IMpsc/IMpmc 标记接口。
- 测试
  - 增加能力矩阵最小用例：SPSC/MPSC/MPMC × 非阻塞/阻塞 × Close/Drain（先在 ifaces_factories.testcase.pas 内补）。


## 本轮修订记录（2025-08-19）
- 修复：mapex.adapters 中的工厂前向声明引发的泛型 CRC 不匹配，统一工厂到 factories。
- 修复：factories 中泛型 record/class 的 interface 节声明语法，消除 “generics without specialization” 报错。
- 基线：tests/fafafa.core.lockfree/BuildOrTest.bat test → 50/0/0 通过。

## 下一步（短期）
- [ ] 更新示例与文档引用（NewOAHashMapExWithComparer 等定位到 factories）
- [ ] ifaces_factories 独立 runner 纳入 BuildOrTest 入口（保持用户一键构建）
- [ ] 微基准：BlockingPolicy/BackoffPolicy 组合矩阵跑一轮并汇总入 report
