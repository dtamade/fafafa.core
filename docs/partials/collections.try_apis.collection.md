## Try* APIs on TCollection

Non-throwing boolean-return variants for bulk operations. Useful when you prefer error-as-value over exceptions.

- TryLoadFrom(const aSrc: Pointer; aElementCount: SizeUInt): Boolean
  - False: aSrc=nil and count>0; overlap; any internal failure
  - True: count=0 clears the collection; otherwise loads
- TryAppend(const aSrc: Pointer; aElementCount: SizeUInt): Boolean
  - False: aSrc=nil; overflow on Count+count; overlap; any internal failure
  - True: count=0 is a no-op and returns True; otherwise appends
- TryLoadFrom(const aSrc: TCollection): Boolean
  - False: aSrc=nil; aSrc=Self; not IsCompatible(aSrc); internal failure
  - True: empty aSrc clears and returns True; otherwise loads
- TryAppend(const aSrc: TCollection): Boolean
  - False: aSrc=nil; aSrc=Self; not IsCompatible(aSrc); overflow; internal failure
  - True: empty aSrc is a no-op and returns True; otherwise appends

Notes:
- Exception-throwing variants (Append/LoadFrom) remain unchanged
- These APIs live on TCollection; container interfaces may provide thin wrappers later for convenience

Examples

````pascal
var V: specialize IVec<Integer>; ok: Boolean;
V := specialize MakeVec<Integer>(0, nil, nil);
// pointer overlap
ok := (V as TCollection).TryAppend(V.GetMemory, 1);
AssertFalse(ok);

// collection empty append
ok := (V as TCollection).TryAppend((specialize MakeArr<Integer>()) as TCollection);
AssertTrue(ok);
````

