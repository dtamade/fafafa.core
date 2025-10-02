# TDuration Unit Constants - Usage Examples

## Overview

The `TDuration` type now provides convenient unit constants that make duration creation more intuitive and readable. These constants are similar to those found in Go's `time.Duration` and Rust's `std::time::Duration`.

## Available Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `TDuration.Nanosecond` | 1 ns | One nanosecond |
| `TDuration.Microsecond` | 1000 ns | One microsecond |
| `TDuration.Millisecond` | 1,000,000 ns | One millisecond |
| `TDuration.Second` | 1,000,000,000 ns | One second |
| `TDuration.Minute` | 60,000,000,000 ns | One minute (60 seconds) |
| `TDuration.Hour` | 3,600,000,000,000 ns | One hour (3600 seconds) |

## Basic Usage

### Simple Duration Creation

```pascal
var
  d: TDuration;
begin
  // Create a 5 second timeout
  d := TDuration.Second * 5;
  
  // Create a 500 millisecond delay
  d := TDuration.Millisecond * 500;
  
  // Create a 2 minute timeout
  d := TDuration.Minute * 2;
end;
```

### Combining Units

```pascal
var
  d: TDuration;
begin
  // 1 hour, 30 minutes, 45 seconds
  d := TDuration.Hour + TDuration.Minute * 30 + TDuration.Second * 45;
  
  // 2.5 minutes = 2 minutes + 30 seconds
  d := TDuration.Minute * 2 + TDuration.Second * 30;
  
  // 1.5 seconds = 1500 milliseconds
  d := TDuration.Second + TDuration.Millisecond * 500;
end;
```

## Practical Examples

### HTTP Request Timeout

```pascal
function FetchURL(const URL: string; Timeout: TDuration): string;
var
  Client: THTTPClient;
begin
  Client := THTTPClient.Create;
  try
    Client.Timeout := Timeout;
    Result := Client.Get(URL);
  finally
    Client.Free;
  end;
end;

// Usage
var
  HTML: string;
begin
  // Set a 30 second timeout
  HTML := FetchURL('https://example.com', TDuration.Second * 30);
end;
```

### Retry Logic with Exponential Backoff

```pascal
function RetryWithBackoff(Operation: TOperation; MaxRetries: Integer): Boolean;
var
  Retry: Integer;
  Delay: TDuration;
begin
  for Retry := 0 to MaxRetries - 1 do
  begin
    if Operation.Execute then
      Exit(True);
    
    // Exponential backoff: 100ms, 200ms, 400ms, 800ms, ...
    Delay := TDuration.Millisecond * 100 * (1 shl Retry);
    Sleep(Delay.AsMs);
  end;
  Result := False;
end;
```

### Rate Limiting

```pascal
type
  TRateLimiter = class
  private
    FLastCall: TInstant;
    FMinInterval: TDuration;
  public
    constructor Create(CallsPerSecond: Integer);
    procedure Wait;
  end;

constructor TRateLimiter.Create(CallsPerSecond: Integer);
begin
  FMinInterval := TDuration.Second div CallsPerSecond;
  FLastCall := TInstant.Zero;
end;

procedure TRateLimiter.Wait;
var
  Now: TInstant;
  Elapsed: TDuration;
begin
  Now := SystemClock.Now;
  if not FLastCall.IsZero then
  begin
    Elapsed := Now.DurationSince(FLastCall);
    if Elapsed < FMinInterval then
      Sleep((FMinInterval - Elapsed).AsMs);
  end;
  FLastCall := SystemClock.Now;
end;

// Usage: limit to 10 requests per second
var
  Limiter: TRateLimiter;
begin
  Limiter := TRateLimiter.Create(10);
  try
    Limiter.Wait;  // Will sleep if needed to maintain rate
    MakeAPICall;
  finally
    Limiter.Free;
  end;
end;
```

### Cache Expiration

```pascal
type
  TCacheEntry<T> = record
    Value: T;
    ExpiresAt: TInstant;
  end;

function CreateCacheEntry<T>(const Value: T; TTL: TDuration): TCacheEntry<T>;
begin
  Result.Value := Value;
  Result.ExpiresAt := SystemClock.Now.Add(TTL);
end;

function IsExpired<T>(const Entry: TCacheEntry<T>): Boolean;
begin
  Result := SystemClock.Now.IsAfter(Entry.ExpiresAt);
end;

// Usage: cache with 5 minute TTL
var
  Entry: TCacheEntry<string>;
begin
  Entry := CreateCacheEntry('cached data', TDuration.Minute * 5);
  
  // Later...
  if IsExpired(Entry) then
    WriteLn('Cache entry has expired');
end;
```

### Timer Scheduling

```pascal
// Schedule a task to run after a delay
procedure ScheduleTask(Task: TProc; Delay: TDuration);
begin
  TTimer.ScheduleOnce(Delay, Task);
end;

// Usage examples
begin
  // Run after 3 seconds
  ScheduleTask(@MyTask, TDuration.Second * 3);
  
  // Run after 500 milliseconds
  ScheduleTask(@MyTask, TDuration.Millisecond * 500);
  
  // Run after 1.5 minutes
  ScheduleTask(@MyTask, TDuration.Minute + TDuration.Second * 30);
end;
```

### Performance Benchmarking

```pascal
procedure BenchmarkOperation;
var
  Start: TInstant;
  Elapsed: TDuration;
  ThresholdSlow: TDuration;
begin
  ThresholdSlow := TDuration.Millisecond * 100;  // 100ms threshold
  
  Start := SystemClock.Now;
  PerformOperation;
  Elapsed := SystemClock.Now.DurationSince(Start);
  
  WriteLn(Format('Operation took: %.2f ms', [Elapsed.AsSecF * 1000]));
  
  if Elapsed > ThresholdSlow then
    WriteLn('WARNING: Operation was slow!');
end;
```

## Comparison with Legacy API

### Before (Using FromXxx methods)

```pascal
var
  timeout: TDuration;
begin
  timeout := TDuration.FromSec(30);                    // 30 seconds
  timeout := TDuration.FromMs(500);                    // 500 milliseconds
  timeout := TDuration.FromSec(60 * 5);                // 5 minutes (manual calculation)
  timeout := TDuration.FromMs(1000 + 500);             // 1.5 seconds (manual calculation)
end;
```

### After (Using Unit Constants)

```pascal
var
  timeout: TDuration;
begin
  timeout := TDuration.Second * 30;                    // 30 seconds - clearer intent
  timeout := TDuration.Millisecond * 500;              // 500 milliseconds
  timeout := TDuration.Minute * 5;                     // 5 minutes - no calculation needed
  timeout := TDuration.Second + TDuration.Millisecond * 500;  // 1.5 seconds - composable
end;
```

## Benefits

1. **Improved Readability**: Code intent is clearer with explicit units
2. **Composability**: Easy to combine different time units
3. **Type Safety**: Compile-time checking ensures correct usage
4. **Consistency**: Follows patterns from modern languages (Go, Rust)
5. **No Overhead**: Constants are inlined, generating optimal code

## Implementation Notes

- All constants are implemented as class functions marked `inline`
- Zero runtime overhead - compiler optimizes to direct integer values
- Constants can be freely combined using arithmetic operators
- Overflow protection is inherited from `TDuration` arithmetic operations

## Related APIs

- `TDuration.FromSec/FromMs/FromUs/FromNs` - Alternative construction methods
- `TDuration.Zero` - Special zero duration constant
- Arithmetic operators (`+`, `-`, `*`, `div`) - For combining durations
- Comparison operators (`<`, `>`, `=`, etc.) - For comparing durations

## See Also

- [TDuration API Reference](../api/tduration.md)
- [Time Module Overview](../guides/time_overview.md)
- [Performance Guide](../guides/performance.md)
