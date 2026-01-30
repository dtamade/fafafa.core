# lockfree 子系统 CODEPAGE 清理完成说明

本说明用于确认并记录 lockfree 子系统内 {$CODEPAGE UTF8} 指令的清理完成情况与验证方式。

## 范围
- 源码：src/fafafa.core.lockfree.*（michaelScottQueue、mpmcQueue、stack、hashmap、openAddressing 等）
- 测试：tests/fafafa.core.lockfree 下所有 .lpr
- 工程：tests/fafafa.core.lockfree 下所有 .lpi 的 IncludeFiles 对齐至包含 ../../src

## 结果
- 已移除的示例：
  - src/fafafa.core.lockfree.pas
  - src/fafafa.core.lockfree.mpmcQueue.pas
  - src/fafafa.core.lockfree.michaelScottQueue.pas
  - tests/fafafa.core.lockfree/test_all_lockfree.lpr
  - tests/fafafa.core.lockfree/test_atomic.lpr
  - tests/fafafa.core.lockfree/debug_hashmap_test.lpr
  - tests/fafafa.core.lockfree/test_interface_adapters.lpr
  - tests/fafafa.core.lockfree/test_direct_interface.lpr
- 全仓检索确认：已清理 tests 下残留的 {$CODEPAGE UTF8}，源码单元保持无 {$CODEPAGE} 指令；测试程序如需中文输出请在入口程序按需添加

## 验证
- 使用 contracts_runner（TE 默认）
  - 构建：成功
  - 运行：返回码 0（成功）
  - 备注：runner 输出已增加完成提示，便于查看

## 风险与回退
- 风险：若某处历史文件依赖 {$CODEPAGE} 进行源码解释（极低概率），可能出现编译器解析差异
- 回退：按 git 历史逐文件回滚或快速恢复指令；当前验证未见异常

## 后续建议
- 保持 tests 下 .lpi 的 IncludeFiles 包含 ../../src 作为新增工程规范
- 并发用例：通过独立宏逐步恢复冒烟用例，非必要不全量开启



## 可选：并发冒烟用例
- 在 tests/fafafa.core.lockfree/test_config.inc 中，打开如下宏可启用极小并发用例：

```
{$DEFINE FAFAFA_CORE_ENABLE_CONCURRENCY_SMOKE}
```

- 当前覆盖：
  - IQueue.SPSC 冒烟（入 100、出 100）
  - IStack.Treiber 冒烟（Push 1..50、逆序 Pop）
  - IMap.MM 冒烟（Put 1..50，逐个 TryGet 校验）

- 注意：
  - 默认关闭（宏被注释），以保持最干净默认构建
  - 不启用大并发宏 FAFAFA_CORE_ENABLE_CONCURRENCY_TESTS，避免扩展用例带来的不稳定因素
