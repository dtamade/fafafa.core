# 测试最佳实践（fafafa.core.test）

本项目自带的轻量测试框架（fafafa.core.test.*）支持通过 `Test('path', proc)` 注册测试用例，并在自定义 Runner 中统一执行与报告。为避免常见的生命周期陷阱，请遵循以下约定。

## 1. 使用“闭包”而非“nested proc”注册测试

- 推荐：`reference to procedure`（闭包）
- 不推荐：`is nested` 的过程类型

原因：`RegisterTests` 返回后，若将“nested proc”保存到全局数组并延迟调用，其静态链（static link）可能失效，调用时会引发访问违例（AV）。闭包会安全捕获上下文并延续其生命周期，避免该问题。

示例（推荐）：

```pascal
// 在 fafafa.core.test.core 中：
//   TTestProc = reference to procedure(const ctx: ITestContext);

Test('sample/ok', procedure(const ctx: ITestContext)
begin
  ctx.AssertTrue(True, 'it works');
end);
```

示例（不推荐）：

```pascal
// is nested 可能在 RegisterTests 返回后失效
Test('sample/bad', procedure is nested
begin
  // 该做法在延迟调用时可能 AV
end);
```

## 2. 断言与 Runner 的使用

- 使用 `ctx.AssertTrue/AssertEquals/...` 抛出 `ETestFailure`，Runner 会捕获并汇总。
- 如需仅打印日志而不失败，可用 `ctx.Log`。
- 跳过测试可用 `ctx.Skip`；前置条件不满足可用 `ctx.Assume`。

## 3. 最小可复现原则

- 当定位问题时，建议临时将用例拆分为最小步骤（例如：先构造、再单步操作、最后断言），逐步恢复，快速锁定问题所在路径。
- 调试输出请仅在排查期间临时添加，定位完成后应移除，以保持测试输出整洁稳定。

## 4. 与容器/迭代器配合的注意事项

- 迭代器应遵循“首次 MoveNext 定位到首元素”的语义；`Current` 在未定位或越界时应报错或返回 nil（视实现而定）。
- 针对有序容器（例如 TreeSet），建议添加遍历有序性用例、边界查询（lower/upper bound）用例，以及插入重复元素的幂等性用例。

## 5. 示例：TreeSet 用例结构

```pascal
Test('treeset/rb/smoke-create-insert', procedure(const ctx: ITestContext)
var
  S: specialize TRBTreeSet<Integer>;
begin
  S := specialize TRBTreeSet<Integer>.Create;
  try
    ctx.AssertTrue(S.Insert(1), 'insert 1');
    ctx.AssertTrue(S.Insert(2), 'insert 2');
    ctx.AssertTrue(S.ContainsKey(1), 'contains 1');
    ctx.AssertTrue(S.ContainsKey(2), 'contains 2');
    ctx.AssertTrue(not S.ContainsKey(3), 'not contains 3');
  finally
    S.Free;
  end;
end);
```

---

附注：本节与 `src/fafafa.core.test.core.pas` 文件中的注释相互呼应，统一强调“使用闭包注册测试”的规范，以避免回归。
