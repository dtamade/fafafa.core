# fafafa.core strict L0 收口清单

> 当前 strict non-SIMD L0 的总边界仍以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准。
> 本页只负责给当前这一轮收口提供一份可合并前检查的 checklist，不替代模块 API 文档。

## 本轮目标

- 把当前 strict non-SIMD L0 收口为可合并状态。
- 补齐 `bits` / `layout` / `endian` / `contracts` / `span` 的 README / 文档 / 测试入口一致性。
- 确认 `option` / `result` / `atomic` / `mem.allocator.foundation` 在当前 L0 边界下回归通过。
- 只把经过批准的最小 `span` contract 纳入 strict L0，不扩大到 segmented span 或 `platform`。

## 当前 strict L0 实际范围

### 已纳入并已验证

- `fafafa.core.settings.inc`
- `fafafa.core.base`
- `fafafa.core.contracts`
- `fafafa.core.span`
- `fafafa.core.bits`
- `fafafa.core.layout`
- `fafafa.core.endian`
- `fafafa.core.option.base`
- `fafafa.core.option`
- `fafafa.core.result`
- `fafafa.core.result.facade`
- `fafafa.core.atomic.base`
- `fafafa.core.atomic.compat`
- `fafafa.core.atomic`
- `fafafa.core.mem.allocator.foundation`
- `fafafa.core.mem.allocator.base`
- `fafafa.core.mem.allocator.rtlAllocator`
- `fafafa.core.mem.allocator.callbackAllocator`

### 兼容层仍保留但不是 strict L0 source-of-truth

- `src/fafafa.core.math.intutil.pas`
- `src/fafafa.core.mem.layout.pas`
- `src/fafafa.core.bytes.pas` 中对 `endian` 的兼容别名

### 本轮明确 deferred

- `platform`
- `segmented span / span2`
- 所有 SIMD 相关能力与审查

## 本轮新增 / 收紧内容

### 新增 strict L0 helper

- `fafafa.core.contracts`
  - `ContractsRequire(aCondition, aMessage)`
  - `ContractsRequireAssigned(aCondition, aName)`

### 已统一的调用点

- `fafafa.core.option.base`
- `fafafa.core.option`
- `fafafa.core.result`
- `fafafa.core.mem.allocator.base`

### 保留原合同、不强行统一的点

- `fafafa.core.mem.allocator.callbackAllocator`
  - 继续保留原有 `EArgumentNil` 异常类型与既有消息合同
- `atomic` / `result.UnwrapUnchecked`
  - 继续使用内部 invariant / `Assert` 语义，不迁入 `contracts`

### 新纳入的最小视图 contract

- `fafafa.core.span`
  - 只承认 `TReadOnlySpan<T>` 的最小只读单段、不拥有内存合同
  - 当前稳定 API：`FromPointer`、`Count`、`IsEmpty`、`Get`、`TryGet`、`GetPtr`、`SubSpan`
  - 当前明确不纳入：`TReadOnlySpan2<T>`、`GetBlock`、deque 双段视图和容器 `SliceView` 裁剪语义

## README / 文档一致性结果

### 已对齐

- `tests/fafafa.core.bits/README.md`
- `tests/fafafa.core.layout/README.md`
- `tests/fafafa.core.endian/README.md`
- `tests/fafafa.core.contracts/README.md`
- `tests/fafafa.core.span/README.md`
- `docs/fafafa.core.span.md`

### 一致性原则

- README 顶部明确这是 strict non-SIMD L0 today contract 的测试入口。
- source-of-truth 明确包含：
  - `docs/fafafa.core.l0.foundation.md`
  - `docs/ARCHITECTURE_LAYERS.md`
  - 对应模块文档
  - 对应测试入口脚本 / testcase
- README 边界必须明确写出：
  - `span` 入口只覆盖最小单段只读 contract
  - `platform`、`span2` / segmented view 与 SIMD 不在当前入口范围内

## 验证结果

以下命令已在当前工作树中实际执行通过：

```bash
bash tests/fafafa.core.contracts/BuildOrTest.sh test
bash tests/fafafa.core.contracts/BuildOrTest.sh test-no-contracts
bash tests/fafafa.core.span/BuildOrTest.sh test
bash tests/fafafa.core.option/BuildOrTest.sh test
bash tests/fafafa.core.result/BuildOrTest.sh test
bash tests/fafafa.core.mem.allocator.foundation/BuildOrTest.sh test
bash tests/fafafa.core.atomic/BuildOrTest.sh test
STOP_ON_FAIL=1 bash tests/run_all_tests.sh fafafa.core.base fafafa.core.contracts fafafa.core.bits fafafa.core.layout fafafa.core.endian fafafa.core.span fafafa.core.option fafafa.core.result fafafa.core.atomic fafafa.core.mem.allocator.foundation
git diff --check
```

### 汇总结果

- strict L0 gate：`10/10 passed`
- `span` 单模块 gate：通过
- `contracts` 双模式 smoke：通过
- `git diff --check`：通过

## 合并前注意事项

- 当前工作树位于 `main`
- 当前这批改动应作为一个独立提交收口
- 由于当前就在 `main`，提交后无需再做分支合并到主线
- 这轮收口的正确下一步是提交当前工作树改动，而不是继续扩张到 `platform` / `span2` / SIMD

## 建议提交方式

### 推荐 commit 标题

```text
feat(core): admit minimal span into strict L0
```

### 推荐 commit 正文要点

- add `fafafa.core.span` as the minimal strict L0 read-only single-segment view contract
- keep `TReadOnlySpan2<T>` / `GetBlock` / container `SliceView` semantics in collections scope
- sync `span` docs, candidate review, architecture layers, and L0 closeout records
- rerun strict L0 gate including `fafafa.core.span`

### 推荐纳入本次提交的路径

- `src/fafafa.core.span.pas`
- `tests/fafafa.core.span/`
- `docs/fafafa.core.span.md`
- `docs/fafafa.core.l0.foundation.md`
- `docs/ARCHITECTURE_LAYERS.md`
- `docs/fafafa.core.l0.candidates.platform-span.review.md`
- `docs/fafafa.core.span.candidate.md`
- `docs/fafafa.core.l0.merge-closeout.md`

### 不应混入本次提交的范围

- `platform`
- `span2` / segmented view
- 所有 SIMD 改动
- 与 strict L0 收口无关的其他模块顺手修改

## 可合并性结论

按当前文本、测试与 gate 结果，这一轮 strict non-SIMD L0 已达到“可合并前收口完成”的状态。

这里的“可合并”指：

- 代码与文档边界已经收紧
- 测试入口与 README 已对齐
- strict L0 gate 已通过
- `span` 已以批准过的最小 cut 进入 L0

这里的“可合并”不指：

- 已自动发起 merge
- 已批准继续扩张 L0 范围
