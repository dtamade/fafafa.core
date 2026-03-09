// === Fallback Functions ===

function MemDiffRange_AVX512(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
begin
  // 使用 AVX2 实现
  Result := MemDiffRange_AVX2(a, b, len, firstDiff, lastDiff);
end;

function BytesIndexOf_AVX512(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;
begin
  // 使用 AVX2 实现
  Result := BytesIndexOf_AVX2(haystack, haystackLen, needle, needleLen);
end;

