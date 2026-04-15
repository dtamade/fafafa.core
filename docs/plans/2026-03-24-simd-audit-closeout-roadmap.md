# 2026-03-24 SIMD Audit Closeout Roadmap

> Status: completed historical batch.
>
> This document records the Batch 69/70 closeout scope that was valid on 2026-03-24.
> It is no longer the active queue for the later SIMD worktrees.
> For current SIMD priorities, use `backlog.md` as the queue truth source and the
> SIMD owner's current worktree-local notes as the execution state.

## 目标

把当前 `fafafa.core.simd` 的 capability / dispatch / public ABI 合同审查收口到 merge-ready。

本轮不再无限扩展“继续深审”，而是把剩余工作收敛成两个批次：

- Batch 69: `GetCurrentBackend` 在 repeated `SetVectorAsmEnabled(...)` 下的并发 toggle/read guard
- Batch 70: snapshot boundary 文档化 + stable-state parity 护栏 + fresh release closeout

## Batch 69: `GetCurrentBackend` toggle/read guard

### 要做什么

- 在 `tests/fafafa.core.simd/fafafa.core.simd.concurrent.testcase.pas` 新增
  `Test_Concurrent_CurrentBackend_VectorAsmToggle_ReadConsistency`
- writer 持续做 repeated `SetVectorAsmEnabled(True/False)`
- reader 持续读取 `GetCurrentBackend`
- 只允许看到：
  - vector-asm enabled 下的完整 active backend
  - vector-asm disabled 下的完整 fallback/重选 backend

### 判定标准

- 如果 fresh targeted suite 直接 green：
  - 不改生产代码
  - 把这条问题收口为 guard gap，而不是实现 bug
- 如果 fresh targeted suite red：
  - 只允许做最小生产修复
  - 修完后必须回跑 targeted suite

### 本轮结果

- 2026-03-24 fresh release targeted suite 直接 green
- 结论：当前 `GetCurrentBackend -> GetActiveBackend -> current published dispatch snapshot`
  读取链已经守住 repeated vector-asm toggle 下的 helper-level read consistency
- 本批没有生产代码改动

## Batch 70: snapshot boundary + stable-state parity closeout

### 要做什么

- 在 `docs/fafafa.core.simd.api.md` 明确 façade/helper 的 snapshot boundary
- 在 `docs/fafafa.core.simd.publicabi.md` 明确 public API table 的 snapshot boundary
- 新增 deterministic stable-state parity tests，显式守住：
  - `GetCurrentBackend`
  - `GetCurrentBackendInfo`
  - `GetDispatchTable`
  - `GetSimdPublicApi`
  - `TryGetSimdBackendPodInfo(current_backend)`
  在控制面 API 返回后、且没有并发 control-plane mutation 时必须收敛到同一稳定态

### 明确边界

- 单个 helper/getter 调用返回的是一份 published snapshot
- 单次调用内部不应暴露 torn / half-rebuilt state
- 但在并发 control-plane mutation 下，不承诺两个独立 helper 调用之间存在跨调用原子配对
- 一旦 `RegisterBackend(...)` / `SetActiveBackend(...)` / `ResetToAutomaticBackend(...)` /
  `SetVectorAsmEnabled(...)` 已经返回，且没有新的并发 control-plane 写入，外部应观察到稳定态收敛

## 收口验收标准

- Batch 69 targeted suite PASS
- Batch 70 targeted suites PASS
- fresh release `check` PASS
- fresh release `gate` PASS
- 当时的执行镜像已同步
- worktree 最终 clean

## 2026-03-27 Readout

- Batch 69/70 should now be read as a closed closeout record, not the current active roadmap.
- Current active SIMD queue has already moved to `SIMD-B21(candidate)` in `backlog.md`.
- The "worktree 最终 clean" requirement above applied to this closeout batch itself.
  The current worktree may legitimately be dirty again while later batches are in flight.

## 本轮不作为阻塞项

- Windows native fresh evidence
- `arm64` / `riscv64` asm-ready 主机 evidence
- 超出当前 snapshot-boundary / stable-state parity 范围的新一轮无限深审
