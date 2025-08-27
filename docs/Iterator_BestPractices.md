# Iterator Best Practices (TPtrIter)

This document defines unified best practices for designing and using pointer iterators (TPtrIter) across fafafa.core.collections.*.

## Goals
- Zero-allocation by default
- Container-owned iterator logic
- Predictable, efficient MoveNext/GetCurrent contract
- No memory leaks even on early exits

## 1) Design Principles
- Zero allocation is the default
  - Store iterator state directly in the record or in `aIter.Data`.
  - Do not heap-allocate iterator state (no GetMem/FreeMem in iterator path).
- Container owns the iterator
  - Container constructs the iterator and implements callbacks `GetCurrent`/`MoveNext` (and optional `MovePrev`).
  - Callers consume elements only; they never manage iterator memory.
- Unified behavior
  - First MoveNext: set `Started := True` and initialize `Data`; return `Count > 0`.
  - Subsequent MoveNext: advance `Data`; return whether not past-the-end.
  - GetCurrent: map `Data` to the element location and return a pointer.

## 2) State Storage Conventions
- Sequential containers (Array/Vec/VecDeque)
  - `aIter.Data` stores the logical index (SizeUInt, 0-based).
  - GetCurrent maps logical index → physical index (direct/mask/mod), then returns the element pointer.
- Linked containers (ForwardList/List)
  - `aIter.Data` stores the current node pointer.
  - GetCurrent returns the address of the node's payload (`@Node^.Data`).
- Avoid heap allocation for iterator state. If truly necessary (rare), see Safety Net below.

## 3) Loop Patterns
- Full traversal
  - `while Iter.MoveNext do` process `Iter.GetCurrent`.
- Bounded copy (may short-circuit)
  - Guard with a counter (e.g., `LCopied < aCount`) and early-exit naturally. No finalization needed.
- Skip offset (StartIndex)
  - Consume `aStartIndex` steps with MoveNext before the main loop.

Example (bounded copy pattern):

```
LCopied := 0;
Iter := Src.PtrIter;
while (LCopied < aCount) and Iter.MoveNext do
begin
  Dst.Put(Index, PElement(Iter.GetCurrent)^);
  Inc(Index);
  Inc(LCopied);
end;
```

## 4) Bounds and Exceptions
- Avoid throwing in GetCurrent/MoveNext on normal paths (perf-sensitive). Return False/nil to indicate end/invalid.
- Perform public API range checks (Read/Write/Insert, etc.) outside iterator hot paths.
- Optional debug assertions may be used (e.g., `SizeUInt(Data) <= FCount`).

## 5) Using Iterators in Container Methods
- Prefer iterators over temporary sub-collections/slices.
- For self-copy/overlap cases, check `IsOverlap` prior to writing or route to safe paths.
- For short-circuit operations, rely on zero-allocation semantics—no teardown required.

## 6) Performance Guidance
- Zero-alloc iterator is default for minimal overhead and better locality.
- Prefer mask (`FCapacityMask`) over modulo when possible.
- Mark iterator callbacks `inline` via project settings/macros to reduce call overhead.

## 7) Optional Safety Net (only if future scenarios require)
- If any iterator must hold external/heavy resources (discouraged), extend TPtrIter with:
  - `FinalizeProc: procedure(aIter: PPtrIter) of object` (optional)
  - `Done: procedure` (idempotent; calls FinalizeProc if assigned)
- Usage convention: callers wrap in `try..finally` and call `Iter.Done` in finally.
- Current containers should remain zero-allocation and not require Done.

## 8) Testing & Validation Checklist
- Unit tests
  - Empty/single/multiple elements traversal
  - Bounded copy (short-circuit) — ensures no leaks and correct results
  - Offset skipping combined with bounded copy
  - Wraparound scenarios (VecDeque)
- Regression
  - Full suite + heaptrc: expect `0 unfreed memory blocks`
- Play projects
  - Keep quick smoke tests for Insert/Write/Remove and offset/limit variants

## 9) Migration from Allocating Iterators
- Replace struct-based heap state with logical index in `aIter.Data` (SizeUInt) or node pointer for linked lists.
- Remove GetMem/FreeMem; delete all loop-tail frees.
- Adjust `GetCurrent/MoveNext` to the unified pattern.
- Run full regression + heaptrc.

## 10) Anti-Patterns
- Heap-allocating iterator state and relying on "complete traversal" for releasing it.
- Forgetting short-circuit paths when using allocating iterators (eliminated by zero-alloc design).
- Doing complex work or throwing exceptions in iterator callbacks.
- Holding external handles inside iterator state.

## Notes
- Current status (2025-08-18): Array/Vec/ForwardList/VecDeque are zero-allocation; unified semantics applied.
- VecDeque implements mask-based physical index mapping for performance when capacity is power-of-two.

## 11) Reverse Iteration Best Practices
- 直接反向：从“未开始”状态可直接调用 MovePrev，从尾部开始反向遍历
- 到达 end(nil) 之后：多数实现不保证在同一迭代器实例上还能回退，建议获取一个新的迭代器再进行反向遍历
- OrderedMap Keys/Values 示例：见 docs/partials/collections.orderedmap.keys_values.md


