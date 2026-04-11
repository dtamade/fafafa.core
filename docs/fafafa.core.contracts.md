# fafafa.core.contracts — strict L0 前置条件 Helper

> 当前 strict L0 边界以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准；后续推进顺序以 `docs/fafafa.core.l0.roadmap.md` 为准。
> `fafafa.core.contracts` 属于 strict non-SIMD L0，只负责统一前置条件 helper，不承载内部 invariant/assert 语义。

## 当前 source-of-truth

1. `docs/fafafa.core.l0.foundation.md`
2. `docs/fafafa.core.l0.roadmap.md`
3. `docs/ARCHITECTURE_LAYERS.md`
4. `src/fafafa.core.contracts.pas`
5. `tests/fafafa.core.contracts/README.md`
6. `tests/fafafa.core.contracts/BuildOrTest.sh`
7. `tests/fafafa.core.contracts/BuildOrTest.bat`

## 目标

- 提供 strict L0 可复用的前置条件 helper。
- 统一 `EArgumentNil` / `EInvalidArgument` 的抛出入口，避免各模块散落重复样板。
- 保持 RTL-only + L0-only 依赖面，不把业务错误、state invariant 或 debug assert 拉进来。

## 当前 API

- `ContractsRequire(aCondition, aMessage)`
  - 在 `FAFAFA_CORE_CONTRACTS` 开启时，`aCondition=False` 抛 `EInvalidArgument(aMessage)`
- `ContractsRequireAssigned(aCondition, aName)`
  - 在 `FAFAFA_CORE_CONTRACTS` 开启时，`aCondition=False` 抛 `EArgumentNil('<name> is nil')`

## 当前边界

- 这里定义的是 precondition helper，不是通用 assertion 框架。
- `atomic` / `result.UnwrapUnchecked` 一类内部 invariant 继续使用 `Assert` 或模块自身语义，不迁到这里。
- `fafafa.core.platform` / `fafafa.core.span` 已各自拥有独立的 strict L0 contract 文档；这里不代替它们给出准入结论，也不回收它们的模块语义。

## 测试

- Linux/macOS：`bash tests/fafafa.core.contracts/BuildOrTest.sh test`
- Linux/macOS（NoContracts smoke）：`bash tests/fafafa.core.contracts/BuildOrTest.sh test-no-contracts`
- Windows：`tests\\fafafa.core.contracts\\BuildOrTest.bat test`
