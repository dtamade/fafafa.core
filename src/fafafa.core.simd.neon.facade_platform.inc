// === Platform-Independent Facade Functions ===
// (These always use scalar fallback regardless of platform)

function MemDiffRange_NEON(a, b: Pointer; len: SizeUInt; out firstDiff, lastDiff: SizeUInt): Boolean;
begin
  Result := MemDiffRange_Scalar(a, b, len, firstDiff, lastDiff);
end;

procedure MemCopy_NEON(src, dst: Pointer; len: SizeUInt);
begin
  MemCopy_Scalar(src, dst, len);
end;

procedure MemSet_NEON(dst: Pointer; len: SizeUInt; value: Byte);
begin
  MemSet_Scalar(dst, len, value);
end;

procedure MemReverse_NEON(p: Pointer; len: SizeUInt);
begin
  MemReverse_Scalar(p, len);
end;

function Utf8Validate_NEON(p: Pointer; len: SizeUInt): Boolean;
begin
  Result := Utf8Validate_Scalar(p, len);
end;

function BytesIndexOf_NEON(haystack: Pointer; haystackLen: SizeUInt; needle: Pointer; needleLen: SizeUInt): PtrInt;
begin
  Result := BytesIndexOf_Scalar(haystack, haystackLen, needle, needleLen);
end;

