## Collections Best Practices

### TL;DR
- Use TVecDeque for ring-buffer style workloads; its capacity is always normalized to a power of two for fast masking and wrap-around.
- Inject growth strategies via SetGrowStrategy/SetGrowStrategyI, but expect final capacity to be power-of-two after normalization.
- Wrap your base growth policy with TAlignedWrapperStrategy for cache-line (64B) or page alignment before VecDeque's power-of-two normalization.
- If you need exact capacities without power-of-two normalization, use TVec instead of TVecDeque.
- Allocator can be nil to fall back to default; keep hot paths allocation-free when possible.

Quick run examples:
- Windows: examples\fafafa.core.collections.vecdeque\BuildOrTest_Examples.bat
- Linux/macOS: examples/fafafa.core.collections.vecdeque/BuildOrTest_Examples.sh

### Choosing the right structure
- TVecDeque<T>
  - Pros: O(1) amortized push/pop front/back, bitmask index, fast wrap-around
  - Capacity invariant: capacity > 0 and capacity is power-of-two
  - Best for: queues, deques, producer/consumer buffers, rolling windows
  - Minimal examples: examples/fafafa.core.collections.vecdeque/BuildOrTest_Examples.(bat|sh)
- TVec<T>
  - Pros: Arbitrary growth policy honored exactly (no power-of-two coercion)
  - Best for: dense arrays, vector-like semantics, exact memory sizing
  - Minimal examples: examples/fafafa.core.collections.vec/BuildOrTest_Examples.(bat|sh)

### Growth strategy recipes
- Throughput-focused (general purpose)
  - Base: TGoldenRatioGrowStrategy.GetGlobal (1.618×)
  - Wrapper: TAlignedWrapperStrategy(Base, 64)  // cache line alignment
  - VecDeque then normalizes to power-of-two (two-level alignment)
- IO/Page-friendly blocks
  - Base: factor-based (1.5×/2×) or golden ratio
  - Wrapper: TAlignedWrapperStrategy(Base, 4096)  // 4 KiB pages
  - VecDeque final: power-of-two capacity >= required
- Huge-page friendly blocks
  - Base: GoldenRatio or factor-based
  - Wrapper: TAlignedWrapperStrategy(Base, 2*1024*1024)  // 2 MiB huge pages
  - VecDeque final: power-of-two capacity >= required
- Deterministic doubling
  - Base: TPowerOfTwoGrowStrategy.GetGlobal or custom factor-2 strategy
  - Optional: TAlignedWrapperStrategy(Base, 64)
  - VecDeque: remains power-of-two; often equals base
- Exact increments (avoid fragmentation, predictable usage)
  - TVec only: TExactGrowStrategy (or Reserve/ReserveExact calls)
  - Avoid on TVecDeque if you expect cache-friendly bitmasking

### Alignment quick-picks
- 64B (cacheline): general CPU cache friendliness; small slices, frequent access
- 4KiB (page): IO buffers, file/mmap/page-aligned operations, DMA-friendly ranges
- 2MiB (huge pages): large buffers with long-lived, streaming or compute-heavy workloads; watch memory footprint

### Cross-platform alignment notes
- Windows: allocation granularity commonly 64KiB; aligning to 64KiB can help with VirtualAlloc region alignment and fragmentation control
- Linux: typical pages 4KiB; huge pages 2MiB require OS setup (e.g., hugetlbfs or transparent huge pages)
- macOS: typical page 4KiB; huge page availability is system/OS dependent
- Guidance: prefer 64B for general CPU locality; 4KiB for I/O or mmapped buffers; 2MiB only when you have large, long-lived buffers and the OS actually backs them; always profile

### How to apply policies
- Interface-based strategy injection (recommended)
  - Use factory functions (e.g., `GoldenRatioGrow`) to get `IGrowthStrategy`
  - Wrap with `TAlignedWrapperStrategy` for alignment if needed
  - All strategies are reference-counted via interfaces

Example:

```pascal
uses fafafa.core.collections.base, fafafa.core.collections.vecdeque;

var
  D: specialize TVecDeque<Integer>;
begin
  D := specialize TVecDeque<Integer>.Create;
  try
    // TAlignedWrapperStrategy accepts IGrowthStrategy directly
    // Lifetime is managed by interface reference counting
    D.SetGrowStrategy(TAlignedWrapperStrategy.Create(GoldenRatioGrow, 64));
    // ... use deque
  finally
    D.Free;
  end;
end.
```

### Invariants and safeguards
- Lower bound: TGrowthStrategy.GetGrowSize ensures Result >= required
- VecDeque normalization: final capacity is power-of-two and >= required
- Aligned wrapper:
  - Requires non-nil base strategy
  - AlignSize must be a non-zero power-of-two (raises on invalid)
- SetGrowStrategy(nil) or SetGrowStrategyI(nil) falls back to default policy

### Allocator and memory tips
- Pass nil allocator to use the library default (platform-optimized)
- For latency-sensitive paths, pre-reserve capacity (Reserve/ReserveExact) to minimize reallocations
- Consider WarmupMemory on large buffers before tight loops to reduce first-touch penalties

### When not to over-optimize
- If your dataset is small or short-lived, the default policy + VecDeque normalization is often sufficient
- Profile before choosing large alignments (e.g., 4 KiB) that might increase overall memory footprint

### Testing suggestions
- Trigger multiple growth steps and assert:
  - capacity is power-of-two
  - capacity >= Count (or required)
- Swap strategies at runtime (SetGrowStrategy / SetGrowStrategyI) and re-assert invariants
- For TVec, assert exact capacity behavior and no implicit power-of-two rounding

