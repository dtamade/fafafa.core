# fafafa.core.simd 最终交接总结

这份文档给下一位维护者一个简短但完整的现状说明：现在这个模块已经整理到什么程度、哪些边界比较稳、接下来最值得做什么。

如果你只想看“现在该做什么”，再看 `docs/fafafa.core.simd.checklist.md`。

## 当前状态

`fafafa.core.simd` 已经完成一轮较大规模的“低风险结构收口”。

重点不是改变语义，而是把原来集中在少数超大 Pascal 单元里的内容，按现有注释边界拆成主单元 + include 片段的结构，降低 review 成本和定位成本。

当前已经完成的方向包括：

- 主入口层收口：`simd.pas` 的类型与框架包装已拆到 include。
- 派发层收口：`dispatch` 的 hook 管理、`cpuinfo` 的 backend 选择已拆出。
- 后端注册区收口：主要 backend 的 register / initialization 区块已拆出。
- 后端辅助区收口：`AVX2`、`AVX-512`、`NEON` 的 facade / fallback / family 已经拆到较细粒度。
- 测试文件保持稳定：测试文件拆分尝试已回滚，不再继续沿那条路推进。

## 现在哪些地方比较稳

如果只是继续维护，不想冒险，这些区域可以认为已经进入“相对稳态”：

- `src/fafafa.core.simd.pas`
- `src/fafafa.core.simd.dispatch.pas`
- `src/fafafa.core.simd.cpuinfo.pas`
- `src/fafafa.core.simd.avx2.pas`
- `src/fafafa.core.simd.avx512.pas`
- `src/fafafa.core.simd.neon.pas`
- 对应的 `*.register.inc` / `*.facade.inc` / `*.family.inc`

这些文件不是不能继续改，而是已经完成了最有价值的结构性整理。继续改动时，更多应该是“按需修正”而不是“继续为拆分而拆分”。

## 哪些地方暂时不要再硬拆

### `src/fafafa.core.simd.sse2.pas`

这是当前最明确的稳定边界。

原因不是它不能维护，而是继续做细颗粒物理拆分时，风险已经明显高于收益：

- 它同时承担 128-bit 基线实现与大量 256/512 仿真路径。
- 它里面混合了 fallback、宽向量仿真、mask/select、舍入、数学函数等多个主题。
- Pascal 对声明区 / 实现区 / include 插入位置比较敏感，继续切细容易触发编译器级问题。

结论很简单：

- 可以继续读、继续修、继续补文档。
- 但不建议再做高频物理拆分，除非先单独做一版 `SSE2` 重构设计。

## 验证基线

结构性改动之后，最值得优先跑的是这三条：

```bash
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DispatchAPI
bash tests/fafafa.core.simd/BuildOrTest.sh test --suite=TTestCase_DirectDispatch
bash tests/fafafa.core.simd/BuildOrTest.sh gate
```

它们分别覆盖：

- dispatch table 映射是否仍完整
- direct dispatch 是否仍跟随主 dispatch
- gate / completeness / adapter / wiring / coverage 是否还稳定

## 常见假失败

有些失败看起来像回归，其实只是运行方式问题。

### `Text file busy`

这通常是并发构建 / 运行同一个测试二进制导致的，不一定是代码问题。

处理方式：

- 顺序重跑同一命令
- 以顺序重跑结果为准

### `Function nesting > 31`

这通常表示 Pascal 文件的声明区 / 实现区 / include 边界被切坏了。

处理方式：

- 不要继续在坏状态上叠加拆分
- 先恢复到最近的稳定结构
- 再决定是否真的值得继续拆

## 后续最值得做的 3 件事

### 1. 保持文档同步

现在最有价值的工作，不是继续硬拆代码，而是让结构说明一直跟上代码现状。

优先维护：

- `docs/fafafa.core.simd.md`
- `src/fafafa.core.simd.README.md`
- `docs/fafafa.core.simd.maintenance.md`
- `docs/fafafa.core.simd.map.md`

### 2. 小范围、按需改动

如果未来要加功能或修 bug，建议只改真正需要动的层：

- 先看 `dispatch` / `cpuinfo`
- 再看对应 backend 的 `register.inc`
- 最后看对应 family / facade include

不要一上来就大范围横跨多个 backend 重排。

### 3. 如需继续重构，先写设计

尤其是 `SSE2` 这种已经接近边界的文件。

如果真的还想继续做结构性重构，最好先写一页短设计，说明：

- 为什么还要拆
- 想拆哪一层
- 预计回报是什么
- 风险怎么控

没有这个前置设计时，继续硬拆通常得不偿失。

## 一句话交接

当前 `SIMD` 子系统已经完成了大部分高价值、低风险的结构收口；继续维护时，优先做文档同步、小范围修正和按需阅读，不建议再对 `SSE2` 做激进物理拆分。
