# HashMap.GetKeys High() Underflow Bug Fix Report

**Date**: 2025-11-03
**Priority**: P1 (Critical)
**Status**: ✅ Fixed & Verified

## Issue Summary

Critical access violation bug in `HashMap.GetKeys()` when called on empty maps, causing cascading failures in `TMultiMap.Clear()` and `TMultiMap.GetKeys()`.

## Root Cause Analysis

### Problem
In Free Pascal, calling `High(arr)` on an empty array (`Length(arr) = 0`) returns -1. When the loop index is typed as `SizeUInt` (unsigned), this -1 is interpreted as `18,446,744,073,709,551,615`, causing:

```pascal
for i := 0 to High(EmptyArray) do  // Loops 18 quintillion times!
  // Access violation on first iteration
```

### Affected Code Patterns
```pascal
// ❌ UNSAFE - causes underflow on empty arrays
for i := 0 to High(arr) do
  DoSomething(arr[i]);

// ✅ SAFE - Low() returns 0, High() returns -1, loop doesn't execute
for i := Low(arr) to High(arr) do
  DoSomething(arr[i]);

// ✅ SAFE - explicit length check
if Length(arr) > 0 then
  for i := 0 to High(arr) do
    DoSomething(arr[i]);
```

## Files Modified

### 1. `src/fafafa.core.collections.hashmap.pas`

**Location**: Line 857-877 (new method)

**Change**: Added `GetKeys()` method with empty map guard

```pascal
function THashMap.GetKeys: TKeyArray;
var
  i, idx: SizeUInt;
begin
  SetLength(Result, FCount);

  // CRITICAL FIX: Check if map is empty or uninitialized
  if (FCapacity = 0) or (FCount = 0) then
    Exit;  // Return empty array

  idx := 0;
  for i := 0 to FCapacity - 1 do
  begin
    if FBuckets[i].State = Ord(bsOccupied) then
    begin
      Result[idx] := FBuckets[i].Key;
      Inc(idx);
    end;
  end;
end;
```

**Rationale**: Prevents accessing `FBuckets` when capacity is 0 or when map is logically empty.

### 2. `src/fafafa.core.collections.multimap.pas`

**Location**: Line 329-343 (GetKeys)

**Change**: Added empty array guard

```pascal
function TMultiMap.GetKeys: TKeyArray;
var
  Keys: TInternalMap.TKeyArray;
  i: SizeUInt;
begin
  Keys := FMap.GetKeys;
  SetLength(Result, Length(Keys));

  // CRITICAL FIX: Check if Keys array is empty to avoid High() underflow
  if Length(Keys) = 0 then
    Exit;  // Return empty array

  for i := 0 to High(Keys) do
    Result[i] := Keys[i];
end;
```

**Location**: Line 341-367 (Clear)

**Change**: Added early return for empty maps

```pascal
procedure TMultiMap.Clear;
var
  i: SizeUInt;
  Keys: TKeyArray;
  Vec: TValueVec;
begin
  // CRITICAL FIX: Check if map is empty first to avoid High() underflow
  if FMap.IsEmpty then
  begin
    FTotalValueCount := 0;
    Exit;
  end;

  // Get all keys first
  Keys := FMap.GetKeys;

  // Free all Vec instances (but don't modify map yet)
  for i := 0 to High(Keys) do
  begin
    if FMap.TryGetValue(Keys[i], Vec) then
      Vec.Free;
  end;

  // Now clear the map (Vecs are already freed)
  FMap.Clear;
  FTotalValueCount := 0;
end;
```

## Test Results

### TMultiMap Test Suite
```
✅ 54/54 tests passed
✅ 0 memory leaks (0 unfreed blocks)

Tests:
  ✅ TestBasicOperations (17 assertions)
  ✅ TestRemove (11 assertions)
  ✅ TestTryGetValues (4 assertions)
  ✅ TestGetKeys (2 assertions)  ← Fixed!
  ✅ TestClear (5 assertions)    ← Fixed!
  ✅ TestStringKeys (5 assertions)
  ✅ TestDuplicateValues (3 assertions)
  ✅ TestLargeDataset (7 assertions)
```

### Regression Tests

| Module | Tests | Memory | Status |
|--------|-------|--------|--------|
| TMultiMap | 54/54 | 0 leaks | ✅ Pass |
| TLinkedHashMap | 12/12 | 0 leaks | ✅ Pass |
| Collections Base | 2/2 | 0 leaks | ✅ Pass |

**Total**: 68/68 tests passed, 0 memory leaks

## Impact Analysis

### Fixed Scenarios
1. **Empty Map GetKeys**: `HashMap.GetKeys()` on empty map no longer crashes
2. **Empty MultiMap Clear**: `TMultiMap.Clear()` on empty map safe
3. **Empty MultiMap Destroy**: Destructor works correctly with no leaks
4. **Empty MultiMap GetKeys**: Returns empty array safely

### Behavioral Changes
- **None**: All changes are defensive guards for edge cases
- **Performance**: Negligible (single comparison per call)
- **API**: No breaking changes, fully backward compatible

## Verification

### Manual Testing
```pascal
var
  M: TMultiMap<Integer, String>;
begin
  M := TMultiMap<Integer, String>.Create;
  try
    // Previously crashed, now safe:
    M.Clear;                    // ✅ No crash
    Assert(Length(M.GetKeys) = 0);  // ✅ Works
  finally
    M.Free;                     // ✅ No leaks
  end;
end;
```

### HeapTrc Output
```
1784 memory blocks allocated : 125131
1784 memory blocks freed     : 125131
0 unfreed memory blocks : 0  ← Perfect!
```

## Future Work

### Code Review Needed
Identified 100+ occurrences of `for i := 0 to High(arr)` pattern in codebase:

**Potentially Vulnerable Files**:
- `src/fafafa.core.collections.orderedset.pas` (lines 314, 335, 359, 373)
- `src/fafafa.core.mem.mappedSlabPool.pas` (multiple instances)
- `src/fafafa.core.sync.rwlock.base.pas` (lines 582, 597, 606)
- `src/fafafa.core.fs.path.pas` (lines 698, 1009)

**Recommended Action**: Audit each occurrence and add guards where arrays can be empty.

### Pattern to Check
```pascal
// Look for:
for i := 0 to High(arr) do

// Where arr can be:
// 1. Result of a function returning dynamic array
// 2. Uninitialized/default value
// 3. Explicitly emptied (SetLength(arr, 0))
```

## Lessons Learned

### Best Practices
1. **Always use `Low()` with `High()`** for loops when possible
2. **Add explicit `Length()` checks** before `0 to High()` loops
3. **Test empty container edge cases** systematically
4. **Use HeapTrc** for memory validation in all tests

### Code Guidelines
```pascal
// ✅ Preferred patterns:

// Pattern 1: Low/High pair (safest)
for i := Low(arr) to High(arr) do
  Process(arr[i]);

// Pattern 2: Explicit length check
if Length(arr) > 0 then
  for i := 0 to High(arr) do
    Process(arr[i]);

// Pattern 3: Early return
if Length(arr) = 0 then Exit;
for i := 0 to High(arr) do
  Process(arr[i]);
```

## Conclusion

Successfully fixed critical High() underflow bug affecting HashMap-based collections. All tests pass with zero memory leaks. The fix is minimal, safe, and fully backward compatible.

**Status**: Ready for commit and code review
