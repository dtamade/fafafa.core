# TVec 快速上手与容量管理指南

本指南介绍 TVec 的默认增长策略、容量管理 API、对齐包装策略与典型用法。

## 默认增长策略（1.5x）
- TVec 默认采用 `TFactorGrowStrategy(1.5)`（懒加载单例）。
- 相比 2 的幂增长，1.5x 在内存占用与重分配次数之间更均衡，适合通用场景。
- 如需位运算友好或缓存对齐偏好，可在创建后启用“对齐包装”。

## 容量管理 API（IVec 暴露）
- Shrink：精确收缩到 Count。
- ShrinkTo(aCapacity)：精确收缩到指定容量（不小于 Count）。
- ShrinkToFit：带滞回的收缩，只有当 `Capacity > max(2*Count, 128)` 时才收缩到 Count，避免抖动。
- FreeBuffer：释放底层缓冲（SetCapacity(0)），适用于需要显式归还内存的场景。
- EnableAlignedGrowth(aAlignElements=64)：将当前增长策略包裹成“对齐包装”策略，使扩容后的容量对齐到 aAlignElements 的元素边界（内部转换为字节并至少 64B）。

## 常见用法示例
```pascal
uses
  fafafa.core.collections.vec;

type
  TIntVec = specialize TVec<Integer>;
var
  V: TIntVec;
begin
  V := TIntVec.Create;
  try
    // 默认 1.5x 策略
    V.Push(1);
    V.Push(2);

    // 启用对齐包装（64 个元素为粒度；至少 64B）
    V.EnableAlignedGrowth(64);

    // 预留与收缩
    V.Reserve(1024);
    V.ShrinkToFit; // 仅在容量远超需求时生效

    // 强制释放缓冲
    V.FreeBuffer;
  finally
    V.Free;
  end;
end;
```

## 迁移建议
- 旧版本可能使用 2 的幂增长；若依赖这种容量形状（如哈希表对齐），可以：
  - 构造完成后调用 `EnableAlignedGrowth(align)`；或
  - 显式设置 `TPowerOfTwoGrowStrategy` 作为 GrowStrategy。
- 若希望 ShrinkToFit 更激进/更保守，可在项目层设定统一阈值（当前为 `max(2*Count, 128)`）。

## 测试与基准
- 测试入口：`src/tests/run_tests.lpr`（已包含容量管理、对齐策略、溢出防护用例）。
- 基准工具：
  - `src/tests/tools/vec_bench.lpr`：push 对比（默认 vs 对齐）。
  - `src/tests/tools/vec_bench_ext.lpr`：push/insert_front/insert_mid，支持 `--n`、`--aligned-elements`、`--cases`、`--csv`。
  - 脚本（Windows）：`src/tests/tools/run_vec_bench_ext.bat` 编译并输出 CSV 到 `report/benchmarks`。
  - 脚本（Linux/macOS）：`src/tests/tools/run_vec_bench_ext.sh` 编译并输出 CSV 到 `report/benchmarks`。

## 参考
- 源码：`src/fafafa.core.collections.vec.pas`
- 策略：`src/fafafa.core.collections.base.pas`（TFactorGrowStrategy、TAlignedWrapperStrategy 等）
- 变更记录：`docs/CHANGELOG_fafafa.core.collections.vec.md`

