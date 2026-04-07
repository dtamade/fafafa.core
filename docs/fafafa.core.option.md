# fafafa.core.option — 可选类型（Option<T>）

> 当前 strict L0 语义以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准。
> `fafafa.core.option.base` + `fafafa.core.option` 属于 strict non-SIMD L0，可空语义应停留在这一层，不下沉服务型能力。
> 用法示例请看 `docs/fafafa.core.option.guide.md`；若示例与源码冲突，以源码和当前测试入口为准。

## 当前 source-of-truth

1. `docs/fafafa.core.l0.foundation.md`
2. `docs/ARCHITECTURE_LAYERS.md`
3. `src/fafafa.core.option.base.pas`
4. `src/fafafa.core.option.pas`
5. `tests/fafafa.core.option/README.md`
6. `tests/fafafa.core.option/BuildOrTest.sh`

## 目标

- 提供零依赖、跨平台、零额外分配的 `Option<T>`（`Some` / `None`）。
- 保持 Rust 风格的显式可空语义，同时贴合 FPC 泛型与闭包能力。
- 让 `base`、`result`、`collections` 之上的模块都能共享同一套值级缺失表达，而不是各自发明 nil / sentinel 约定。

## 当前 API 面

- `TOption<T>` 核心构造与查询：
  - `Some`
  - `None`
  - `IsSome`
  - `IsNone`
  - `IsSomeAnd`
  - `Contains`
- `TOption<T>` 取值与调试：
  - `Unwrap`
  - `UnwrapOr`
  - `UnwrapOrElse`
  - `UnwrapOrDefault`
  - `Expect`
  - `TryUnwrap`
  - `Inspect`
  - `ToDebugString`
- `TOption<T>` 逻辑组合：
  - `Or_`
  - `And_`
  - `Xor_`
- 顶层组合子：
  - `OptionMap`
  - `OptionAndThen`
  - `OptionMapOr`
  - `OptionMapOrElse`
  - `OptionFilter`
  - `OptionFlatten`
  - `OptionZip`
  - `OptionZipWith`
- 与 `Result` 互转：
  - `OptionToResult`
  - `OptionToResultElse`
  - `ResultToOption`
  - `ResultErrOption`
  - `ResultTransposeOption`
  - `OptionTransposeResult`
- 构造 helper：
  - `OptionFromBool`
  - `OptionFromString`
  - `OptionFromValue`
  - `OptionFromInterface`

详细签名与泛型参数顺序以 `src/fafafa.core.option.base.pas` 和 `src/fafafa.core.option.pas` 为准。

## 当前行为约定

- `Unwrap` / `Expect` 在 `None` 上会抛出 `EOptionUnwrapError`。
- 回调参数按惰性语义处理，只有在实际需要调用时才要求非 nil；若 nil 回调被调用，会抛出 `EArgumentNil('<Name> is nil')`。
- `ToDebugString` 的 printer 允许为 nil，此时输出占位符 `Some(?)`。

## 当前边界

- 这里定义的是值级 optional contract，不是容器、服务、配置系统或对象生命周期管理框架。
- strict L0 只保留 `fafafa.core.option.base` + `fafafa.core.option` 这一层；更高层的 nullable policy 不应回流到这里。
- tutorial、迁移示例和使用范式请放在 `docs/fafafa.core.option.guide.md`，不要再把阶段性进度、覆盖率宣传或路线图堆回根文档。

## 测试

- Linux/macOS：`bash tests/fafafa.core.option/BuildOrTest.sh test`
- Windows：`tests\\fafafa.core.option\\BuildOrTest.bat test`
- 当前测试入口锁定构造、查询、解包、逻辑组合、顶层组合子和 `Result` 互转语义。

## 关联文档

- `docs/fafafa.core.option.guide.md`：用法与示例
- `docs/fafafa.core.result.md`：`Result<T, E>` 合同
- `docs/fafafa.core.aliases.md`：常用别名与泛型辅助

