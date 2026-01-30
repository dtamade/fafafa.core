# CHANGELOG - fafafa.core.collections.vec

## Unreleased


> Windows 一键脚本位置（符合目录规范）：
> - 测试：src/tests/run_all_tests_and_bench.bat（包含基准）
> - 仅基准：src/tests/tools/run_vec_bench_ext.bat

### Added
- TVec: ShrinkToFit（带滞回）与 FreeBuffer API。
  - ShrinkToFit：仅当 Capacity > max(2*Count, 128) 时收缩到 Count，避免频繁抖动。
  - FreeBuffer：SetCapacity(0) 强制释放底层缓冲。
- TVec: EnableAlignedGrowth(aAlignElements=64) 可选启用“对齐包装”增长策略。
  - 在当前增长策略外包 TAlignedWrapperStrategy，使扩容后的容量对齐到指定元素数的边界；内部会转换为字节并至少 64B。
  - 可与默认 1.5x 因子增长叠加：先计算增长容量，再向上对齐。
- IVec: 暴露容量管理扩展方法（Shrink、ShrinkTo、ShrinkToFit、FreeBuffer、EnableAlignedGrowth）。
- 元素管理层：TElementManager.AllocElements / ReallocElements 增加乘法溢出防护（aCount * ElementSize）。
- 测试：
  - test_vec_growth_and_shrink：默认 1.5x、ShrinkToFit 滞回、FreeBuffer。
  - test_vec_aligned_growth：验证 EnableAlignedGrowth 后容量对齐。
  - test_element_manager_overflow：溢出防护用例（期望 EOverflow）。
- 基准工具：
  - src/tests/tools/vec_bench.lpr（推入 push 基准，默认 vs 对齐包装）。
  - src/tests/tools/vec_bench_ext.lpr（可选 CSV 输出，支持 push / insert_front / insert_mid）。

### Changed
- 默认增长策略：由 TPowerOfTwoGrowStrategy 改为 TFactorGrowStrategy(1.5)。
  - 通过 TVec 内部懒加载单例提供默认策略，避免生命周期管理问题。

### Migration Notes
- 新默认策略可能改变容量扩张的轨迹（从 2 的幂 → 1.5x）。若依赖旧的容量形状（如位运算对齐需求），请在构造后调用 EnableAlignedGrowth(align) 或显式设置 PowerOfTwo 策略。
- ShrinkToFit 采用滞回阈值（max(2*Count, 128)），若需更激进/更保守，可考虑在项目层设定统一常量/配置。

### Examples
- 启用对齐包装：
```pascal
var v: specialize TVec<Integer>;
v := specialize TVec<Integer>.Create;
v.EnableAlignedGrowth(64); // 以 64 个元素为粒度对齐（至少 64B）
```
- 释放底层缓冲：
```pascal
v.FreeBuffer; // SetCapacity(0)
```
- 带滞回的收缩：
```pascal
v.ShrinkToFit; // 仅在容量显著超出需求时收缩
```

