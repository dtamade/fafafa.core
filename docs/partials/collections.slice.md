## Slice/SliceView

- SliceView: preferred, safe read-only view
  - TReadOnlySlice<T>: holds owner IArray<T> + start + count
  - Methods: Count/IsEmpty/Get/TryGet/GetPtr/SubSlice
  - Pointer validity: GetPtr returns a short-lived pointer; any resize/append/insert on the owner invalidates it
- Removed legacy Slice (Ptr+Count)
  - Rationale: avoid long-lived raw pointer misuse and encourage safe accessors
  - Migration: use SliceView and Get/TryGet/GetPtr; for FFI, extract a short-lived pointer from SliceView.GetPtr(0) when needed

### Examples

- Create a slice view and read values

````pascal
var A: specialize TArray<Integer>; S: specialize TReadOnlySlice<Integer>;
A := specialize TArray<Integer>.Create([1,2,3,4]);
S := A.SliceView(1, 2); // [2,3]
AssertEquals(2, S.Get(0));
AssertEquals(3, S.Get(1));
````

- Sub-slice

````pascal
var S2 := S.SubSlice(1,1); // [3]
AssertEquals(1, S2.Count);
AssertEquals(3, S2.Get(0));
````

- Short-lived pointer use

````pascal
var p := S.GetPtr(0); // do short, immediate read-only use
// do NOT retain across A.Resize/Append/Insert
````

