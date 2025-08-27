# Collections Examples (TVec / TVecDeque)
> See also: docs/EXAMPLES.md#集合模块示例总表（TVec-/-TVecDeque） · docs/fafafa.core.collections.md



This folder indexes minimal, runnable examples for collections in fafafa.core.

## Quick run
- Windows (VecDeque): examples\fafafa.core.collections.vecdeque\BuildOrTest_Examples.bat
- Linux/macOS (VecDeque): examples/fafafa.core.collections.vecdeque/BuildOrTest_Examples.sh
- Windows (Vec): examples\fafafa.core.collections.vec\BuildOrTest_Examples.bat
- Linux/macOS (Vec): examples/fafafa.core.collections.vec/BuildOrTest_Examples.sh

## TVecDeque examples
- example_growth_object_based_min.lpr
  - Object-based strategy injection: GoldenRatio -> TAlignedWrapperStrategy(64B) -> SetGrowStrategy
  - Ensures final capacity is power-of-two and >= Count
- example_growth_interface_based_min.lpr
  - Interface-based strategy injection: TGrowthStrategyInterfaceView -> SetGrowStrategyI
  - Same invariants as above
- example_growth_page_aligned_min.lpr
  - Page-aligned growth (4KiB) + power-of-two normalization
- example_growth_hugepage_aligned_min.lpr
  - Huge-page alignment (2MiB) + power-of-two normalization; requires OS support
- example_growth_page_aligned_portable_min.lpr
  - Chooses 64KiB alignment on Windows and 4KiB elsewhere

## TVec examples
- example_exact_and_reserveexact_min.lpr
  - Exact growth policy with TExactGrowStrategy + ReserveExact
  - Demonstrates non-power-of-two growth and precise capacity control
- example_ensure_vs_capacity/example_ensure_vs_capacity.lpr
  - Shows Ensure/Reserve interactions and capacity checks

## Notes
- All examples validate invariants at runtime and print OK on success
- For best performance, prefer cacheline (64B) alignment for general workloads; choose 4KiB/2MiB when dealing with IO or very large, long‑lived buffers and after profiling
- See docs/partials/collections.best_practices.md for strategy combinations and cross-platform alignment notes

