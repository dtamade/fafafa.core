# Timer Backends: Heap Index Handle + Pluggable Backends (Sketch)

## Goals
- O(log N) cancel/update for timers via heap index handle
- Abstract timer queue backend: BinaryHeap (default), HashedWheel (optional)
- Preserve current public API (ITimer/ITimerScheduler), add minimal extensions only when necessary

## Current State (Binary Min-Heap via TList)
- Each timer (PTimerEntry) sits in FList (used as binary min-heap by Deadline)
- Cancel: lazy remove (skip on pop) — simple but O(N) in worst case for mid-heap removal
- Reset: currently supported for tkOnce by mutating Deadline (re-heapify not performed immediately)

## Part A: Heap Index Handle

### Idea
- Maintain an integer heap index for each timer entry and a back-pointer in the heap array
- Expose an internal handle (opaque to public API) allowing O(log N) operations:
  - cancel/remove: swap with last, pop, heapify down/up as needed
  - update deadline: decrease/increase key with bubble up/down

### Data Structure Changes
- Replace TList with a bespoke dynamic array `FHeap: array of PTimerEntry`
- Each PTimerEntry gains `HeapIndex: Integer` (=-1 when not in heap)
- Helper ops:
  - HeapifyUp(i), HeapifyDown(i)
  - MoveTo(i, j) updates `FHeap[j] := FHeap[i]` and `FHeap[j]^.HeapIndex := j`

### Operations
- Insert: push-back, HeapifyUp(last)
- PopMin: root -> result; last -> root; HeapifyDown(0)
- RemoveAt(i): last -> i; heapify up/down based on key compare; mark entry out-of-heap
- UpdateKey(i, newDeadline): set, then up/down depending on compare with old

### Concurrency & Safety
- All heap ops under FLock; timer thread is the sole consumer of pop
- ITimerRef.ResetAt/Cancel take FLock -> find HeapIndex -> update/remove O(log N)
- If not in heap (fired or cancelled), operations are no-ops as per semantics

### API Impact
- Public API remains unchanged; internal handle implicit via ITimerRef -> PTimerEntry
- Future: consider exposing a light `ITimerHandle` for advanced users (optional)

## Part B: Pluggable Backends

### Interface Sketch
```pascal
type
  ITimerQueueBackend = interface
    procedure Enqueue(E: PTimerEntry);
    function  PopDue(const NowI: TInstant; out Due: array of PTimerEntry): Integer; // batch pop due items
    function  PeekNextDeadline(out Dl: TInstant): Boolean;
    procedure Remove(E: PTimerEntry);
    procedure Update(E: PTimerEntry; const NewDeadline: TInstant);
    function  Count: Integer;
  end;
```

- BinaryHeapBackend: current behavior translated to the new interface
- HashedWheelBackend: bucketed wheel for coarse-grained large-scale timers
  - Wheel ticks at slice S; ring size R; manage cascading for long deadlines
  - Strength: O(1) amortized insert; batch due pop; lower per-op overhead at scale
  - Weakness: granularity S, deadlines rounded; not suitable for sub-ms precision

### Scheduler Integration
- `TTimerSchedulerImpl` holds `FQ: ITimerQueueBackend`
- Thread loop:
  - `PeekNextDeadline(Dl)` -> compute wait
  - On wake, `PopDue(NowI, out batch)` -> dispatch callbacks; for fixed-rate: re-enqueue with updated deadline; for fixed-delay: re-enqueue after callback
- Metrics per backend: enqueue/pop/update/remove counters, due drift histogram (optional)

## Migration Plan
1) Internal refactor: TList -> bespoke heap with HeapIndex (no public API change)
2) Extract ITimerQueueBackend; implement BinaryHeapBackend (feature parity)
3) Optional: implement HashedWheelBackend (behind factory or ctor param)
4) Benchmarks: N=1e3, 1e4, 1e5, 1e6 timers; latency/throughput vs heap backend
5) Tests: functional parity; race/edge cases; drift bounds; cancellation/update correctness

## Risks & Mitigations
- Complexity increase: keep BinaryHeap as default; guard optional backend via factory
- Precision vs throughput (wheel): document rounding behavior; provide knobs for S/R
- GC/ownership: maintain RefCount/Dead/InHeap semantics; careful dispose paths

## Open Questions
- Do we need batch APIs in public surface? (likely no; keep internal)
- Should we expose ITimerHandle? Start internal only; revisit after feedback
- Cross-platform timers integration (future): align with async/poller deadlines

