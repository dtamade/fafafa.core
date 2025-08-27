# fafafa.core.time Industrial-grade Spec (v0.1)

## Scope & Goals
- Provide a modern, cross-platform timing layer: TDuration, TInstant (monotonic), TDeadline; clocks: IMonotonicClock, ISystemClock, IClock
- Single source of truth for relative time: monotonic clock for any measuring/timeout
- Clear separation of absolute time (NowUTC/NowLocal) vs relative time (TDuration/TInstant)
- Stable, minimal, testable APIs with predictable behavior under jitter and platform nuances

## Platform targets
- Windows: QueryPerformanceCounter (QPC); precision ns, jitter budget <= 2 ms for sleeps >= 10 ms
- Linux: clock_gettime(CLOCK_MONOTONIC), nanosleep
- macOS: mach_absolute_time + mach_timebase_info

## API stability (frozen in v0.1)
- Types: TDuration, TInstant, TDeadline
- Clocks: IMonotonicClock, ISystemClock (NowUTC, NowLocal), IClock
- Top-level: DefaultMonotonicClock/DefaultSystemClock/DefaultClock; SleepFor/SleepUntil/NowInstant/NowUTC/NowLocal
- Utilities: TimeIt, FormatDurationHuman; SleepUntilWithSlack, SleepForCancelable, SleepUntilCancelable
- Any additions should be backward-compatible

## Semantics
- TDuration: signed ns; saturating add/sub; Compare/Min/Max; Clamp
- TInstant: uint64 ns since monotonic epoch; Compare/Min/Max; Add(Duration) with saturation at range ends
- TDeadline: When:Instant; Remaining/RemainingClampedZero; FromNow/FromNowMs/FromNowSec
- ISystemClock: NowUTC (true UTC), NowLocal (wall clock)
- Monotonic is the only source for measuring time intervals and implementing timeouts

## Sleep semantics
- SleepFor(D<=0): no-op (True)
- SleepUntil(T<=Now): no-op
- SleepUntilWithSlack(T, Slack): if Remaining > Slack then SleepFor(Remaining - Slack)
- Cancelable sleeps: cooperative check with slices
  - SleepForCancelable: default slice 10 ms
  - SleepUntilCancelable: step up to 50 ms, min(Remaining, step)
  - Return False if cancellation requested; True on natural completion

## Error handling & edge cases
- Durations: detect signed overflow; saturate to min/max Int64
- Instants: additions saturate to range
- Convert absolute times only via DateUtils; avoid DST/zone pitfalls by keeping UTC for storage/logging

## Performance targets
- NowInstant (monotonic) call: < 150 ns on x64 release (guideline)
- Sleep jitter (>=10 ms): <= 2 ms typical on desktop OS
- Low allocation/GC: zero heap allocations in core paths

## Testing matrix
- Unit tests: arithmetic, comparisons, formatting, parsing (after introduced), sleep semantics (base/cancelable/slack)
- Platform guards: conditional tests for Windows/Linux/macOS specifics
- Time jitter tolerant assertions (thresholded checks)
- Memory: heaptrc no leaks

## Documentation
- "UTC vs Local Best Practices"
- "Sleep Best Practices": Slack and cancelable patterns
- Migration guide: from GetTickCount64/millisecond integers to TDuration/TInstant/TDeadline

## Roadmap items (next)
- ParseDuration(text)->TDuration; configurable FormatDurationHuman (units/thresholds/precision/abbr)
- ITimer/ITimerScheduler (one-shot/periodic) with slack & cancellation; min-heap scheduler
- Benchmarks: NowInstant, Sleep accuracy, TimeIt overhead

