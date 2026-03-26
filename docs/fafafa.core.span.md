# fafafa.core.span — 最小只读单段视图合同

> 当前 strict L0 语义以 `docs/fafafa.core.l0.foundation.md` 和 `docs/ARCHITECTURE_LAYERS.md` 为准。
> `fafafa.core.span` 属于 strict non-SIMD L0，负责一个足够小、可长期稳定复用的只读单段视图表达层。

## 当前 source-of-truth

1. `docs/fafafa.core.l0.foundation.md`
2. `docs/ARCHITECTURE_LAYERS.md`
3. `src/fafafa.core.span.pas`
4. `tests/fafafa.core.span/README.md`
5. `tests/fafafa.core.span/BuildOrTest.sh`
6. `tests/fafafa.core.span/fafafa.core.span.testcase.pas`

## 当前切法

- `fafafa.core.span` 不是把 `fafafa.core.collections.slice` 原样搬进 L0。
- 当前只承认最小 cut：
  - 只读
  - 单段
  - 不拥有内存
  - 只表达视图 contract
- 这样做的目的，是先把最基础、最稳定的部分独立出来，给 `collections`、`bytes` 和其他上层模块复用。

## 目标

- 提供一个只依赖 RTL + `fafafa.core.base` 的基础视图合同。
- 统一“外部内存 + 长度”的只读表达方式。
- 保持 API 面足够小，避免把容器策略、分段布局和高层行为一起拖进 L0。

## 当前 API

- `generic TReadOnlySpan<T> = record`
  - `FromPointer(aPtr, aCount)`
  - `Count`
  - `IsEmpty`
  - `Get`
  - `TryGet`
  - `GetPtr`
  - `SubSpan`

## 当前行为

- `FromPointer` 只封装外部指针和元素数量，不接管内存所有权。
- `Get` / `GetPtr` 对越界访问抛出严格异常：
  - `Span.Get: index out of range`
  - `Span.GetPtr: index out of range`
- `SubSpan` 对非法范围抛出：
  - `Span.SubSpan: range out of bounds`
- `SubSpan(aIndex, 0)` 返回空 span。

## 当前边界

- 这里只定义最小只读单段 span contract。
- 不纳入：
  - `TReadOnlySpan2<T>`
  - `GetBlock`
  - deque / ring-buffer 双段视图
  - 容器 `SliceView` 的裁剪行为
- `collections.slice` 仍然保留 collections 域 today semantics，尤其是双段视图与容器相关语义。

## 测试

- Linux/macOS：`bash tests/fafafa.core.span/BuildOrTest.sh test`
- Windows：`tests\\fafafa.core.span\\BuildOrTest.bat test`
- 当前测试入口会锁定空视图、元素读取、地址读取、`SubSpan`、越界异常消息和零长度子视图行为。
