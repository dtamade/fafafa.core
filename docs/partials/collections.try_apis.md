## Try* APIs on TArray<T>

Non-throwing, boolean-return variants for common operations. Prefer when you want to avoid exception-driven control flow.

- TryGet(aIndex: SizeUInt; out aElement: T): Boolean
  - True: aIndex < Count, aElement receives value
  - False: index out of range; aElement unchanged
- TryPut(aIndex: SizeUInt; const aElement: T): Boolean
  - True: aIndex < Count, element written
  - False: index out of range; no write performed
- TryCopy(aSrcIndex, aDstIndex, aCount: SizeUInt): Boolean
  - True: 0<=src,dst and src+count<=Count and dst+count<=Count; copy executed (overlap-safe via existing Copy logic)
  - False: any range invalid; no copy performed

### Examples

````pascal
var A: specialize TArray<Integer>; v: Integer;
A := specialize TArray<Integer>.Create([1,2,3]);

AssertTrue(A.TryGet(1, v));  // v=2
AssertFalse(A.TryGet(10, v)); // v unchanged

AssertTrue(A.TryPut(0, 10));  // A[0]=10
AssertFalse(A.TryPut(5, 99));  // out-of-range, no-op

AssertTrue(A.TryCopy(0, 1, 2)); // copy [0..1] -> [1..2]
AssertFalse(A.TryCopy(3, 0, 5)); // invalid range, no-op
````

Notes:
- These APIs are available on TArray<T> implementation; IArray<T> remains unchanged (non-breaking).
