# Benchmarks — Iterator Dispatch

- 比较多态虚调用 vs 方法指针回调的迭代开销
- 控制迭代次数在 1e7 以内，避免运行时间过长
- 构建：
  - lazbuild --build-mode=Release iterator_dispatch.lpr
  - fpc -O2 -S2 -MObjFPC -Fu../../src -FEbin -FUlib iterator_dispatch.lpr

