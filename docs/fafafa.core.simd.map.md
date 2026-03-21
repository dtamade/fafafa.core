# fafafa.core.simd 阅读地图

如果你只想在 1 分钟内知道这个模块该从哪里读起，看这页就够了。

## 第一层：对外入口

从这里开始，先理解模块对外承诺什么：

- `src/fafafa.core.simd.README.md`
- `docs/fafafa.core.simd.md`
- `src/fafafa.core.simd.pas`
- `src/fafafa.core.simd.api.pas`

## 第二层：运行时选择

如果你关心“为什么会选中这个 backend”，看这里：

- `src/fafafa.core.simd.dispatch.pas`
- `src/fafafa.core.simd.cpuinfo.pas`
- `src/fafafa.core.simd.backend.priority.pas`

配套 include：

- `src/fafafa.core.simd.dispatch.hooks.intf.inc`
- `src/fafafa.core.simd.dispatch.hooks.impl.inc`
- `src/fafafa.core.simd.cpuinfo.backends.impl.inc`

## 第三层：后端入口

想知道某个后端“注册了什么能力”，多数情况下优先看 `*.register.inc`；`SSE2` 例外，直接看 `src/fafafa.core.simd.sse2.pas`：

- `src/fafafa.core.simd.sse2.pas`
- `src/fafafa.core.simd.avx2.register.inc`
- `src/fafafa.core.simd.avx512.register.inc`
- `src/fafafa.core.simd.neon.register.inc`
- `src/fafafa.core.simd.riscvv.register.inc`

## 第四层：后端快路径

想看 mem/text/search/bitset 之类的快路径，优先看 `*.facade.inc`：

- `src/fafafa.core.simd.avx2.facade.inc`
- `src/fafafa.core.simd.avx512.facade.inc`
- `src/fafafa.core.simd.neon.facade_asm.inc`
- `src/fafafa.core.simd.neon.facade_scalar.inc`
- `src/fafafa.core.simd.neon.facade_platform.inc`
- `src/fafafa.core.simd.riscvv.facade.inc`

## 第五层：按向量族读实现

想看具体向量族实现时，再去读 family include：

- `avx512.f32x16_*`
- `avx512.f64x8_*`
- `avx512.i32x16_*`
- `avx512.i64x8_*`
- `avx512.*_family.inc`
- `avx2.f32x8_*`
- `avx2.f64x4_*`
- `avx2.i32x8_family.inc`
- `neon.scalar.*.inc`

## 一条经验

如果你是第一次定位问题，优先顺序通常是：

1. `simd.pas`
2. `dispatch.pas`
3. `cpuinfo.pas`
4. 对应 backend 的注册入口（多数是 `register.inc`，`SSE2` 直接看 `sse2.pas`）
5. 对应 backend 的 `facade.inc`
6. 最后才看具体 family 实现

这样最不容易在大量汇编和 fallback 代码里迷路。

## 一条红线

不要默认“主文件就是唯一真实位置”。

这个模块现在的常态是：

- 主文件负责组织
- include 负责承载大块实现

如果你没先看 include，通常很容易误判影响面。
