# fafafa.core.simd 极简行动清单

这页只回答两件事：现在应该做什么，以及现在不要做什么。

## 现在应该做什么

### 1. 先读这三个文件

- `docs/fafafa.core.simd.map.md`
- `docs/fafafa.core.simd.maintenance.md`
- `docs/fafafa.core.simd.handoff.md`
- `docs/fafafa.core.simd.closeout.md`

### 2. 改代码前先定位层级

先问自己：你要改的是哪一层？

- 主入口：`simd.pas` / `api.pas`
- 运行时选择：`dispatch.pas` / `cpuinfo.pas`
- 后端注册：`*.register.inc`
- 后端快路径：`*.facade.inc`
- 向量族实现：`*.family.inc`

### 3. 日常改动先跑快门禁

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh check
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch
bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

上面这组里：

- `check`：编译卫生 + 基础 runner parity
- 两个 `--suite`：最关键的 dispatch / direct 回归
- `gate`：日常改动使用的快门禁 / 基础门禁

### 4. 准备 closeout / release 再跑完整门禁

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh gate-strict
```

`gate-strict` 会在 `gate` 的基础上额外打开性能烟测、repeat、non-x86 / evidence 等更重的检查，更适合发布前或阶段性收口时运行。

## 现在不要做什么

### 1. 不要继续硬拆 `SSE2`

`src/fafafa.core.simd.sse2.pas` 现在是明确的稳定边界。

### 2. 不要再拆测试文件

测试文件拆分尝试已经回滚，后续保持单文件更稳。

### 3. 不要把 `gate` 当成发布放行的唯一依据

`gate` 是快门禁，不是发布门禁。

### 4. 不要跨多个 backend 同时大改

优先做小范围、按需修改。

## 如果看到这些错误

- `Text file busy`：先顺序重跑，再判断是不是代码回归
- `Function nesting > 31`：先恢复到最近稳定状态，不要继续叠加拆分
- `backend_slot_counts` 下降：先检查脚本有没有跟上 `{$I ...}` include

## 一句话版本

现在最值得做的是：小范围修正 + 文档同步；最不值得做的是：继续激进拆分 `SSE2` 或测试文件。
