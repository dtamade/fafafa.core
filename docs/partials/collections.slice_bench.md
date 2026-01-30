## SliceView vs direct Get/ForEach: micro-benchmark notes

Intent: understand overheads and when to prefer each.

- Direct Get in a tight loop (for i := 0 to A.Count-1 do v := A.Get(i))
  - Pros: minimal indirection, best for simple linear scans
  - Cons: repeated virtual/interface calls if using IArray<T>
- ForEach (Func/Method/RefFunc)
  - Pros: concise, can enable inlining of per-element work; no manual indexing
  - Cons: callback overhead; best when per-element work dominates
- SliceView
  - Pros: bounds-checked windowing; SubSlice composition; TryGet/GetPtr provide flexible access
  - Cons: accessing via S.Get(i) adds (owner + start) indirection; marginal overhead vs direct Get

Rule of thumb:
- For hot inner loops where the window is entire array: direct Get or ForEach
- For algorithms that operate on subranges frequently and compose windows: SliceView improves clarity and safety with negligible overhead in most real workloads
- For raw memory interop, use GetPtr short-lived pointers, but do not retain across resizing operations

Suggested methodology to measure (pseudo-code):

````pascal
const N = 4*1024*1024;
var A: specialize TArray<Integer>; i, sum: Int64; S: specialize TReadOnlySlice<Integer>;
A := specialize TArray<Integer>.Create(N); A.Fill(0, N, 1);

// 1) Direct Get
sum := 0; startTimer; for i := 0 to A.Count-1 do Inc(sum, A.Get(i)); stopTimer('DirectGet');

// 2) ForEach
sum := 0; startTimer; A.ForEach(
  function(const v: Integer; aData: Pointer): Boolean begin Inc(sum, v); exit(true); end, nil
); stopTimer('ForEach');

// 3) SliceView window
S := A.SliceView(128, N-256);
sum := 0; startTimer; for i := 0 to S.Count-1 do Inc(sum, S.Get(i)); stopTimer('SliceViewGet');
````

Notes:
- Run in Release with optimizations and no range checks for fair comparison
- Pin CPU frequency if possible; repeat runs and report median

